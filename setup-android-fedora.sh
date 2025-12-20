#!/bin/bash
# =============================================================================
# Setup Android SDK for .NET on Fedora 43
# =============================================================================
# Uses official Fedora repositories only
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo "=============================================="
echo "  Android SDK Setup for Fedora"
echo "=============================================="
echo ""

# =============================================================================
# Step 1: Find available Java packages in Fedora repos
# =============================================================================
echo "Step 1: Checking available Java versions..."

# List available java packages
echo "Available Java packages in Fedora repos:"
dnf search java-*-openjdk-devel 2>/dev/null | grep -E "^java-[0-9]+-openjdk-devel" | head -10 || true

# Fedora 43 may have different Java versions available
# Android SDK works with JDK 17, 21, or even 11
# Let's find what's available

JAVA_PKG=""
JAVA_VER=""

for version in 17 21 11; do
    # Try different package name formats
    for pkg in "java-${version}-openjdk-devel" "java-${version}-openjdk"; do
        if dnf info "$pkg" &>/dev/null; then
            JAVA_PKG="$pkg"
            JAVA_VER="$version"
            log "Found available: $pkg"
            break 2
        fi
    done
done

# If specific versions not found, try the generic latest
if [ -z "$JAVA_PKG" ]; then
    if dnf info java-latest-openjdk-devel &>/dev/null; then
        JAVA_PKG="java-latest-openjdk-devel"
        JAVA_VER="latest"
        log "Found available: java-latest-openjdk-devel"
    fi
fi

if [ -z "$JAVA_PKG" ]; then
    error "Could not find a suitable Java JDK package"
    echo ""
    echo "Please check available packages with:"
    echo "  dnf search openjdk-devel"
    echo ""
    echo "And install manually, e.g.:"
    echo "  sudo dnf install java-21-openjdk-devel"
    exit 1
fi

# =============================================================================
# Step 2: Install Java JDK
# =============================================================================
echo ""
echo "Step 2: Installing $JAVA_PKG..."

if rpm -q "$JAVA_PKG" &>/dev/null || rpm -q "${JAVA_PKG%-devel}" &>/dev/null; then
    log "$JAVA_PKG already installed"
else
    log "Installing $JAVA_PKG..."
    sudo dnf install -y "$JAVA_PKG"
fi

# Also ensure we have the full JDK (with jar, javac, etc)
# On Fedora 43, the -devel package might be named differently
if ! command -v jar &>/dev/null; then
    warn "jar command not found, trying to install full JDK..."
    # Try installing the headless and devel variants
    sudo dnf install -y java-*-openjdk-headless java-*-openjdk-devel 2>/dev/null || true
fi

# =============================================================================
# Step 3: Find JAVA_HOME
# =============================================================================
echo ""
echo "Step 3: Locating JAVA_HOME..."

# Find the Java installation
JAVA_HOME=""

# Method 1: Use alternatives
if [ -z "$JAVA_HOME" ]; then
    JAVA_BIN=$(readlink -f "$(which java)" 2>/dev/null)
    if [ -n "$JAVA_BIN" ]; then
        # Go up from bin/java to the JDK root
        JAVA_HOME=$(dirname "$(dirname "$JAVA_BIN")")
    fi
fi

# Method 2: Search common locations
if [ -z "$JAVA_HOME" ] || [ ! -d "$JAVA_HOME" ]; then
    for jvm in /usr/lib/jvm/java-*-openjdk*; do
        if [ -d "$jvm" ] && [ -f "$jvm/bin/java" ]; then
            JAVA_HOME="$jvm"
            break
        fi
    done
fi

# Method 3: Use java-config if available
if [ -z "$JAVA_HOME" ] || [ ! -d "$JAVA_HOME" ]; then
    JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 | grep 'java.home' | awk '{print $3}')
fi

if [ -z "$JAVA_HOME" ] || [ ! -d "$JAVA_HOME" ]; then
    error "Could not determine JAVA_HOME"
    echo "Please set JAVA_HOME manually"
    exit 1
fi

log "JAVA_HOME=$JAVA_HOME"

# Check for required tools
if [ -f "$JAVA_HOME/bin/jar" ]; then
    log "Found jar tool"
elif [ -f "$JAVA_HOME/../bin/jar" ]; then
    # Sometimes java.home points to jre, go up one level
    JAVA_HOME=$(dirname "$JAVA_HOME")
    log "Adjusted JAVA_HOME=$JAVA_HOME"
else
    warn "jar tool not found in JAVA_HOME"
    echo "This might cause issues with Android builds"
fi

# =============================================================================
# Step 4: Install .NET Android workload
# =============================================================================
echo ""
echo "Step 4: Installing .NET Android workload..."

if dotnet workload list 2>/dev/null | grep -q "android"; then
    log "Android workload already installed"
else
    log "Installing Android workload (this may take several minutes)..."
    sudo dotnet workload install android --skip-sign-check
fi

# =============================================================================
# Step 5: Setup environment variables
# =============================================================================
echo ""
echo "Step 5: Setting up environment variables..."

# Android SDK location (installed by workload)
ANDROID_HOME="$HOME/.android/sdk"

# The workload installs SDK to different locations, let's find it
for path in \
    "$HOME/.android/sdk" \
    "$HOME/.local/share/Android/Sdk" \
    "$HOME/Android/Sdk" \
    "$HOME/.dotnet/packs/Microsoft.Android.Sdk.Linux"*/tools; do
    if [ -d "$path" ]; then
        ANDROID_HOME="$path"
        log "Found Android SDK at: $ANDROID_HOME"
        break
    fi
done

# Create environment file
ENV_FILE="$HOME/.android-env.sh"
cat > "$ENV_FILE" << EOF
# Android SDK environment for .NET development
# Source this: source ~/.android-env.sh

export JAVA_HOME="$JAVA_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="\$ANDROID_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF

log "Created $ENV_FILE"

# Add to .bashrc if not present
if ! grep -q "android-env.sh" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Android SDK for .NET" >> "$HOME/.bashrc"
    echo '[ -f ~/.android-env.sh ] && source ~/.android-env.sh' >> "$HOME/.bashrc"
    log "Added to .bashrc"
fi

# Source for current session
export JAVA_HOME="$JAVA_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# =============================================================================
# Step 6: Accept Android SDK licenses
# =============================================================================
echo ""
echo "Step 6: Accepting Android SDK licenses..."

mkdir -p "$ANDROID_HOME/licenses"

# Write license acceptance files
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license"
echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"
echo -e "\nd975f751698a77b662f1254ddbeed3901e976f5a" >> "$ANDROID_HOME/licenses/android-sdk-license"

log "License files created"

# =============================================================================
# Step 7: Test the build
# =============================================================================
echo ""
echo "Step 7: Testing Android build..."

cd ~/src/dotnet/MyDesktopApplication 2>/dev/null || cd .

if [ -f "src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj" ]; then
    log "Building Android project..."
    echo ""
    
    if dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj 2>&1; then
        echo ""
        echo "=============================================="
        echo -e "  ${GREEN}Android Setup Complete!${NC}"
        echo "=============================================="
    else
        echo ""
        warn "Build had issues - see output above"
        echo ""
        echo "Common fixes:"
        echo "  1. Restart terminal and try again"
        echo "  2. Run: source ~/.android-env.sh"
        echo "  3. Check JAVA_HOME: echo \$JAVA_HOME"
    fi
else
    warn "Android project not found in current directory"
fi

echo ""
echo "Environment configured:"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  ANDROID_HOME=$ANDROID_HOME"
echo ""
echo "For new terminals, run: source ~/.android-env.sh"
echo "Or restart your terminal."

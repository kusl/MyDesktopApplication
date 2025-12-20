#!/bin/bash
# =============================================================================
# Setup Android SDK for .NET MAUI/Avalonia on Fedora
# =============================================================================
# Uses Fedora DNF packages where possible, downloads Android SDK via dotnet
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
# Step 1: Install Java JDK 17 (required by Android SDK)
# =============================================================================
# Android SDK requires JDK 17 (not 25 which you have)
echo "Step 1: Installing Java JDK 17..."

if ! rpm -q java-17-openjdk-devel &>/dev/null; then
    log "Installing java-17-openjdk-devel..."
    sudo dnf install -y java-17-openjdk-devel
else
    log "java-17-openjdk-devel already installed"
fi

# Set JAVA_HOME to JDK 17
JAVA17_HOME="/usr/lib/jvm/java-17-openjdk"

if [ -d "$JAVA17_HOME" ]; then
    log "Found JDK 17 at $JAVA17_HOME"
else
    # Try to find it
    JAVA17_HOME=$(dirname $(dirname $(readlink -f $(which java) 2>/dev/null || echo "/usr/lib/jvm/java-17-openjdk/bin/java"))) 
    if [[ "$JAVA17_HOME" != *"17"* ]]; then
        JAVA17_HOME=$(ls -d /usr/lib/jvm/java-17-openjdk* 2>/dev/null | head -1)
    fi
    
    if [ -z "$JAVA17_HOME" ] || [ ! -d "$JAVA17_HOME" ]; then
        error "Could not find JDK 17. Please install it manually."
        exit 1
    fi
    log "Found JDK 17 at $JAVA17_HOME"
fi

# Verify jar exists
if [ ! -f "$JAVA17_HOME/bin/jar" ]; then
    error "JDK 17 installation incomplete - missing 'jar' tool"
    error "Try: sudo dnf reinstall java-17-openjdk-devel"
    exit 1
fi

log "JDK 17 verified (jar tool found)"

# =============================================================================
# Step 2: Install Android workload via dotnet
# =============================================================================
echo ""
echo "Step 2: Installing .NET Android workload..."

# Check if already installed
if dotnet workload list | grep -q "android"; then
    log "Android workload already installed"
else
    log "Installing Android workload (this may take a few minutes)..."
    dotnet workload install android
fi

# =============================================================================
# Step 3: Set up Android SDK via dotnet
# =============================================================================
echo ""
echo "Step 3: Setting up Android SDK..."

ANDROID_HOME="$HOME/.android/sdk"
mkdir -p "$ANDROID_HOME"

# The Android workload should have installed command-line tools
# Let's trigger the SDK download by doing a restore
log "Triggering Android SDK download via restore..."

# Create a temp project to trigger SDK download
TEMP_DIR=$(mktemp -d)
cat > "$TEMP_DIR/temp.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <OutputType>Exe</OutputType>
  </PropertyGroup>
</Project>
EOF

# Set JAVA_HOME for the restore
export JAVA_HOME="$JAVA17_HOME"

# This will download Android SDK components
dotnet restore "$TEMP_DIR/temp.csproj" 2>/dev/null || true
rm -rf "$TEMP_DIR"

# Find where Android SDK was installed
POSSIBLE_SDK_PATHS=(
    "$HOME/.android/sdk"
    "$HOME/.local/share/Android/Sdk"
    "$HOME/Android/Sdk"
    "/usr/lib/android-sdk"
)

for path in "${POSSIBLE_SDK_PATHS[@]}"; do
    if [ -d "$path/platforms" ] || [ -d "$path/platform-tools" ]; then
        ANDROID_HOME="$path"
        log "Found Android SDK at $ANDROID_HOME"
        break
    fi
done

# =============================================================================
# Step 4: Create environment setup script
# =============================================================================
echo ""
echo "Step 4: Creating environment configuration..."

ENV_FILE="$HOME/.android-env.sh"

cat > "$ENV_FILE" << EOF
# Android SDK environment variables for .NET development
# Source this file: source ~/.android-env.sh

export JAVA_HOME="$JAVA17_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="\$ANDROID_HOME"
export PATH="\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF

log "Created $ENV_FILE"

# Also add to .bashrc if not already there
if ! grep -q "android-env.sh" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Android SDK for .NET development" >> "$HOME/.bashrc"
    echo "[ -f ~/.android-env.sh ] && source ~/.android-env.sh" >> "$HOME/.bashrc"
    log "Added to .bashrc"
fi

# Source it now
source "$ENV_FILE"

# =============================================================================
# Step 5: Accept Android SDK licenses
# =============================================================================
echo ""
echo "Step 5: Accepting Android SDK licenses..."

# Find sdkmanager
SDKMANAGER=""
for sm in "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
          "$ANDROID_HOME/cmdline-tools/bin/sdkmanager" \
          "$ANDROID_HOME/tools/bin/sdkmanager"; do
    if [ -f "$sm" ]; then
        SDKMANAGER="$sm"
        break
    fi
done

if [ -n "$SDKMANAGER" ] && [ -f "$SDKMANAGER" ]; then
    log "Found sdkmanager at $SDKMANAGER"
    yes | "$SDKMANAGER" --licenses 2>/dev/null || true
    log "Licenses accepted"
else
    warn "sdkmanager not found - licenses may need manual acceptance"
    # Create licenses directory manually
    mkdir -p "$ANDROID_HOME/licenses"
    echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license"
    echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"
    log "Created license files manually"
fi

# =============================================================================
# Step 6: Test the build
# =============================================================================
echo ""
echo "Step 6: Testing Android build..."

# Export for current session
export JAVA_HOME="$JAVA17_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

cd ~/src/dotnet/MyDesktopApplication

log "Building Android project..."
if dotnet build src/MyDesktopApplication.Android -v q 2>&1 | tail -5; then
    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}Android Setup Complete!${NC}"
    echo "=============================================="
else
    echo ""
    warn "Build may have issues - check output above"
    echo ""
    echo "If you see SDK errors, try:"
    echo "  source ~/.android-env.sh"
    echo "  dotnet build src/MyDesktopApplication.Android"
fi

echo ""
echo "Environment variables set:"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  ANDROID_HOME=$ANDROID_HOME"
echo ""
echo "For new terminal sessions, run:"
echo "  source ~/.android-env.sh"
echo ""
echo "Or restart your terminal."

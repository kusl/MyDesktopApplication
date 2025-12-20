#!/bin/bash
set -e

echo "=============================================="
echo "  Android SDK Setup for Fedora"
echo "=============================================="
echo ""

# Configuration
ANDROID_SDK_ROOT="$HOME/.android/sdk"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# Step 1: Install Java 21 JDK
echo "Step 1: Installing Java 21 JDK..."

JAVA_PKG=""
for pkg in java-21-openjdk-devel java-25-openjdk-devel java-latest-openjdk-devel; do
    if dnf info "$pkg" &>/dev/null; then
        JAVA_PKG="$pkg"
        break
    fi
done

if [ -z "$JAVA_PKG" ]; then
    echo "✗ No suitable Java JDK found"
    exit 1
fi

echo "✓ Using: $JAVA_PKG"

if ! rpm -q "$JAVA_PKG" &>/dev/null; then
    echo "Installing $JAVA_PKG..."
    sudo dnf install -y "$JAVA_PKG"
else
    echo "✓ $JAVA_PKG already installed"
fi

# Step 2: Find JAVA_HOME with jar tool
echo ""
echo "Step 2: Finding JAVA_HOME..."

JAVA_HOME=""
for jvm in /usr/lib/jvm/java-21-openjdk /usr/lib/jvm/java-25-openjdk /usr/lib/jvm/java-latest-openjdk; do
    if [ -f "$jvm/bin/jar" ]; then
        JAVA_HOME="$jvm"
        break
    fi
done

if [ -z "$JAVA_HOME" ]; then
    echo "✗ Could not find JDK with jar tool"
    exit 1
fi

echo "✓ JAVA_HOME=$JAVA_HOME"
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

# Step 3: Install required tools
echo ""
echo "Step 3: Installing required tools..."
sudo dnf install -y unzip wget curl

# Step 4: Download and install Android SDK command-line tools
echo ""
echo "Step 4: Setting up Android SDK..."

mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

# Check if cmdline-tools already exists
if [ ! -f "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
    echo "Downloading Android command-line tools..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    wget -q --show-progress "$CMDLINE_TOOLS_URL" -O cmdline-tools.zip
    unzip -q cmdline-tools.zip
    
    # The zip extracts to 'cmdline-tools', we need to move it to 'latest'
    rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    mv cmdline-tools "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    
    cd -
    rm -rf "$TEMP_DIR"
    
    echo "✓ Command-line tools installed"
else
    echo "✓ Command-line tools already installed"
fi

# Step 5: Set up environment
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Step 6: Accept licenses
echo ""
echo "Step 5: Accepting Android SDK licenses..."

# Create license directory
mkdir -p "$ANDROID_HOME/licenses"

# Accept licenses non-interactively
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses 2>/dev/null || true

# Also create license files directly (backup method)
echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license"
echo "84831b9409646a918e30573bab4c9c91346d8abd" >> "$ANDROID_HOME/licenses/android-sdk-license"
echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> "$ANDROID_HOME/licenses/android-sdk-license"

echo "✓ Licenses accepted"

# Step 7: Install required SDK components
echo ""
echo "Step 6: Installing Android SDK components..."
echo "This may take a few minutes..."

# Install platform-tools, build-tools, and platform (API 35 is current stable)
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install \
    "platform-tools" \
    "build-tools;35.0.0" \
    "platforms;android-35" \
    2>&1 | grep -E "(Installing|Done|Warning|Error)" || true

echo "✓ SDK components installed"

# Step 8: Install .NET Android workload
echo ""
echo "Step 7: Installing .NET Android workload..."

if dotnet workload list 2>/dev/null | grep -q "android"; then
    echo "✓ Android workload already installed"
else
    dotnet workload install android
    echo "✓ Android workload installed"
fi

# Step 9: Create environment file
echo ""
echo "Step 8: Creating environment file..."

ENV_FILE="$HOME/.android-env.sh"
cat > "$ENV_FILE" << EOF
# Android Development Environment
# Source this file: source ~/.android-env.sh

export JAVA_HOME="$JAVA_HOME"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF

echo "✓ Created $ENV_FILE"

# Source environment for current session
source "$ENV_FILE"

# Step 10: Verify installation
echo ""
echo "Step 9: Verifying installation..."

echo "  JAVA_HOME: $JAVA_HOME"
echo "  ANDROID_HOME: $ANDROID_HOME"

if [ -f "$JAVA_HOME/bin/jar" ]; then
    echo "  ✓ jar tool found"
else
    echo "  ✗ jar tool NOT found"
fi

if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    echo "  ✓ sdkmanager found"
else
    echo "  ✗ sdkmanager NOT found"
fi

if [ -d "$ANDROID_HOME/platforms/android-35" ]; then
    echo "  ✓ Android platform 35 installed"
else
    echo "  ! Android platform 35 not found (will be downloaded during build)"
fi

if [ -d "$ANDROID_HOME/build-tools/35.0.0" ]; then
    echo "  ✓ Build tools 35.0.0 installed"
else
    echo "  ! Build tools not found (will be downloaded during build)"
fi

# Step 11: Test build
echo ""
echo "Step 10: Testing Android build..."

ANDROID_PROJ="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"

if [ -f "$ANDROID_PROJ" ]; then
    echo "Building: $ANDROID_PROJ"
    echo ""
    
    if dotnet build "$ANDROID_PROJ" \
        -p:JavaSdkDirectory="$JAVA_HOME" \
        -p:AndroidSdkDirectory="$ANDROID_HOME" \
        2>&1; then
        echo ""
        echo "✓ Android build successful!"
    else
        echo ""
        echo "! Build failed - see errors above"
        echo ""
        echo "Try these steps:"
        echo "  1. source ~/.android-env.sh"
        echo "  2. dotnet build $ANDROID_PROJ"
    fi
else
    echo "! Android project not found at $ANDROID_PROJ"
fi

echo ""
echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "Environment:"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  ANDROID_HOME=$ANDROID_HOME"
echo ""
echo "SDK Components installed:"
ls -d "$ANDROID_HOME/platforms"/* 2>/dev/null | xargs -n1 basename || echo "  (none yet)"
echo ""
echo "For new terminals, run:"
echo "  source ~/.android-env.sh"
echo ""
echo "Or add to ~/.bashrc permanently:"
echo "  echo 'source ~/.android-env.sh' >> ~/.bashrc"
echo ""

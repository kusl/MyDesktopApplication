#!/bin/bash
set -e

echo "=============================================="
echo "  Android SDK Setup for Fedora"
echo "=============================================="
echo ""

# Step 1: Install Java 21 JDK (the -devel package includes jar tool)
echo "Step 1: Installing Java 21 JDK..."
echo "Available Java JDK packages:"

# Check what's available
if dnf info java-21-openjdk-devel &>/dev/null; then
    JAVA_PKG="java-21-openjdk-devel"
    JAVA_DIR="java-21-openjdk"
elif dnf info java-25-openjdk-devel &>/dev/null; then
    JAVA_PKG="java-25-openjdk-devel"
    JAVA_DIR="java-25-openjdk"
elif dnf info java-latest-openjdk-devel &>/dev/null; then
    JAVA_PKG="java-latest-openjdk-devel"
    JAVA_DIR="java-latest-openjdk"
else
    echo "✗ No suitable Java JDK found in Fedora repos"
    exit 1
fi

echo "✓ Using: $JAVA_PKG"

# Install if not already installed
if ! rpm -q "$JAVA_PKG" &>/dev/null; then
    echo "Installing $JAVA_PKG..."
    sudo dnf install -y "$JAVA_PKG"
else
    echo "✓ $JAVA_PKG already installed"
fi

# Step 2: Find the correct JAVA_HOME with jar tool
echo ""
echo "Step 2: Finding JAVA_HOME with jar tool..."

# Priority order: java-21-openjdk, then java-25-openjdk, then java-latest-openjdk
JAVA_HOME=""
for jvm_dir in /usr/lib/jvm/java-21-openjdk /usr/lib/jvm/java-25-openjdk /usr/lib/jvm/java-latest-openjdk; do
    if [ -f "$jvm_dir/bin/jar" ]; then
        JAVA_HOME="$jvm_dir"
        echo "✓ Found jar at: $jvm_dir/bin/jar"
        break
    fi
done

if [ -z "$JAVA_HOME" ]; then
    # Fallback: search all JVMs
    for jvm in /usr/lib/jvm/java-*-openjdk; do
        if [ -f "$jvm/bin/jar" ]; then
            JAVA_HOME="$jvm"
            echo "✓ Found jar at: $jvm/bin/jar"
            break
        fi
    done
fi

if [ -z "$JAVA_HOME" ]; then
    echo "✗ Could not find a JDK with jar tool"
    echo "  You need to install a JDK package (not JRE)"
    echo "  Try: sudo dnf install java-21-openjdk-devel"
    exit 1
fi

echo "✓ JAVA_HOME=$JAVA_HOME"

# Verify jar exists
if [ ! -f "$JAVA_HOME/bin/jar" ]; then
    echo "✗ jar not found at $JAVA_HOME/bin/jar"
    exit 1
fi

# Step 3: Install .NET Android workload
echo ""
echo "Step 3: Installing .NET Android workload..."
if dotnet workload list 2>/dev/null | grep -q "android"; then
    echo "✓ Android workload already installed"
else
    echo "Installing android workload..."
    dotnet workload install android
fi

# Step 4: Find Android SDK
echo ""
echo "Step 4: Finding Android SDK..."

# The Android workload installs SDK to ~/.android/sdk or uses ANDROID_HOME
ANDROID_SDK=""
if [ -d "$HOME/.android/sdk" ]; then
    ANDROID_SDK="$HOME/.android/sdk"
elif [ -d "$HOME/Android/Sdk" ]; then
    ANDROID_SDK="$HOME/Android/Sdk"
elif [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    ANDROID_SDK="$ANDROID_HOME"
fi

# If no SDK found, let .NET handle it (it auto-downloads during build)
if [ -z "$ANDROID_SDK" ]; then
    echo "! Android SDK not found in standard locations"
    echo "  .NET will download it automatically during first build"
    ANDROID_SDK="$HOME/.android/sdk"
    mkdir -p "$ANDROID_SDK"
fi

echo "✓ ANDROID_HOME=$ANDROID_SDK"

# Step 5: Create environment file
echo ""
echo "Step 5: Creating environment file..."

ENV_FILE="$HOME/.android-env.sh"
cat > "$ENV_FILE" << EOF
# Android Development Environment
# Source this file: source ~/.android-env.sh

export JAVA_HOME="$JAVA_HOME"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF

echo "✓ Created $ENV_FILE"

# Source it now
export JAVA_HOME="$JAVA_HOME"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Step 6: Accept licenses
echo ""
echo "Step 6: Accepting Android SDK licenses..."

LICENSE_DIR="$ANDROID_SDK/licenses"
mkdir -p "$LICENSE_DIR"

# These are the standard license acceptance hashes
echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$LICENSE_DIR/android-sdk-license"
echo "84831b9409646a918e30573bab4c9c91346d8abd" >> "$LICENSE_DIR/android-sdk-license"
echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> "$LICENSE_DIR/android-sdk-license"
echo "d975f751698a77b662f1254ddbeed3901e976f5a" > "$LICENSE_DIR/android-sdk-arm-dbt-license"

echo "✓ License files created"

# Step 7: Test build
echo ""
echo "Step 7: Testing Android build..."

# Find Android project
ANDROID_PROJ=""
if [ -f "src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj" ]; then
    ANDROID_PROJ="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"
fi

if [ -n "$ANDROID_PROJ" ]; then
    echo "Building: $ANDROID_PROJ"
    echo ""
    
    # Build with explicit JavaSdkDirectory
    if dotnet build "$ANDROID_PROJ" -p:JavaSdkDirectory="$JAVA_HOME" -p:AndroidSdkDirectory="$ANDROID_SDK" 2>&1; then
        echo ""
        echo "✓ Android build successful!"
    else
        echo ""
        echo "! Build had issues - see output above"
        echo ""
        echo "Try running:"
        echo "  source ~/.android-env.sh"
        echo "  dotnet build $ANDROID_PROJ"
    fi
else
    echo "! No Android project found to test"
fi

echo ""
echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "Environment configured:"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  ANDROID_HOME=$ANDROID_SDK"
echo ""
echo "For new terminals, run:"
echo "  source ~/.android-env.sh"
echo ""
echo "Or add to ~/.bashrc:"
echo "  echo 'source ~/.android-env.sh' >> ~/.bashrc"
echo ""

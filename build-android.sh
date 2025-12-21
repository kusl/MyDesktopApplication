#!/bin/bash
set -e

echo "Building Android project..."
echo ""

# Kill any stuck aapt2 processes first
pkill -f aapt2 2>/dev/null || true

# Source Android environment
[ -f ~/.android-env.sh ] && source ~/.android-env.sh

# Build with single-threaded aapt2 to avoid deadlocks
dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
    -p:_Aapt2DaemonMaxInstanceCount=1 \
    -p:AndroidAapt2CompileExtraArgs="--no-crunch" \
    -v minimal \
    "$@"

echo ""
echo "✓ Android build complete!"

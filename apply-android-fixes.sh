#!/bin/bash
# =============================================================================
# Apply Android Build Fixes - Single Script to Rule Them All
# =============================================================================
# Run this script to apply all fixes for the Android aapt2 daemon hang issue.
# This maintains a SINGLE unified solution - no desktop/android splitting!
# =============================================================================

set -e
cd ~/src/dotnet/MyDesktopApplication

echo "=============================================="
echo "  Applying Android Build Fixes"
echo "=============================================="

# -----------------------------------------------------------------------------
# Step 1: Kill stuck processes
# -----------------------------------------------------------------------------
echo ""
echo "[1/6] Killing stuck processes..."
pkill -9 -f "aapt2" 2>/dev/null || true
pkill -9 -f "VBCSCompiler" 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
sleep 1
echo "  ✓ Done"

# -----------------------------------------------------------------------------
# Step 2: Clean build artifacts
# -----------------------------------------------------------------------------
echo ""
echo "[2/6] Cleaning build artifacts..."
rm -rf bin obj
find . -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "obj" -exec rm -rf {} + 2>/dev/null || true
echo "  ✓ Done"

# -----------------------------------------------------------------------------
# Step 3: Update Directory.Build.props with aapt2 fixes
# -----------------------------------------------------------------------------
echo ""
echo "[3/6] Updating Directory.Build.props..."

cat > Directory.Build.props << 'EOF'
<Project>
  <PropertyGroup>
    <!-- Target Framework Configuration -->
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    
    <!-- Central Package Management -->
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    
    <!-- Code Quality -->
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <WarningsAsErrors>NU1605</WarningsAsErrors>
    <NoWarn>$(NoWarn);CS1591</NoWarn>
    
    <!-- Build Configuration -->
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest</AnalysisLevel>
  </PropertyGroup>

  <!-- ANDROID AAPT2 DAEMON FIX - Prevents infinite hangs on Linux -->
  <PropertyGroup Condition="$(TargetFramework.Contains('android'))">
    <AndroidUseAapt2Daemon>false</AndroidUseAapt2Daemon>
    <_Aapt2DaemonMaxInstanceCount>1</_Aapt2DaemonMaxInstanceCount>
    <AndroidAapt2CompileExtraArgs>--no-crunch</AndroidAapt2CompileExtraArgs>
    <UseInterpreter Condition="'$(Configuration)' == 'Debug'">true</UseInterpreter>
    <AndroidResourceDesignerMaxParallelism>1</AndroidResourceDesignerMaxParallelism>
  </PropertyGroup>

  <!-- Common metadata -->
  <PropertyGroup>
    <Authors>Kushal</Authors>
    <Company>MyDesktopApplication</Company>
    <Copyright>Copyright © 2025</Copyright>
    <RepositoryType>git</RepositoryType>
  </PropertyGroup>
</Project>
EOF
echo "  ✓ Done"

# -----------------------------------------------------------------------------
# Step 4: Update Android .csproj
# -----------------------------------------------------------------------------
echo ""
echo "[4/6] Updating Android project..."

mkdir -p src/MyDesktopApplication.Android

cat > src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <OutputType>Exe</OutputType>
    <SupportedOSPlatformVersion>24</SupportedOSPlatformVersion>
    <ApplicationId>com.mydesktopapplication.app</ApplicationId>
    <ApplicationVersion>1</ApplicationVersion>
    <ApplicationDisplayVersion>1.0</ApplicationDisplayVersion>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Avalonia.Android" />
  </ItemGroup>
</Project>
EOF
echo "  ✓ Done"

# -----------------------------------------------------------------------------
# Step 5: Create/Update GitHub Actions workflow
# -----------------------------------------------------------------------------
echo ""
echo "[5/6] Updating GitHub Actions workflow..."

mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop, 'feature/**' ]
  pull_request:
    branches: [ main, develop ]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_SKIP_FIRST_TIME_EXPERIENCE: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true
  AndroidUseAapt2Daemon: false
  _Aapt2DaemonMaxInstanceCount: 1

jobs:
  build:
    name: Build & Test (All Platforms)
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    - uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '21'
    - uses: android-actions/setup-android@v3
      with:
        packages: platforms;android-35|build-tools;35.0.0

    - name: Restore
      run: dotnet restore

    - name: Build (Desktop + Android)
      run: |
        pkill -9 -f aapt2 || true
        dotnet build --configuration Release --no-restore \
          -p:AndroidUseAapt2Daemon=false \
          -p:_Aapt2DaemonMaxInstanceCount=1
      timeout-minutes: 15

    - name: Test
      run: dotnet test --configuration Release --no-build --verbosity normal
EOF
echo "  ✓ Done"

# -----------------------------------------------------------------------------
# Step 6: Build and verify
# -----------------------------------------------------------------------------
echo ""
echo "[6/6] Building solution..."

# Configure Java if available
for jdk in /usr/lib/jvm/java-{21,17,11}-openjdk; do
    if [ -d "$jdk" ]; then
        export JAVA_HOME="$jdk"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "Using Java: $JAVA_HOME"
        break
    fi
done

dotnet restore --verbosity minimal

echo ""
echo "Building with aapt2 daemon disabled..."
if timeout 300 dotnet build --verbosity minimal; then
    echo ""
    echo "=============================================="
    echo "  ✓ Build completed successfully!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  dotnet test                                    # Run tests"
    echo "  dotnet run --project src/MyDesktopApplication.Desktop  # Run app"
    echo ""
    echo "If Android builds hang in the future:"
    echo "  pkill -9 -f aapt2 && dotnet build"
else
    echo ""
    echo "=============================================="
    echo "  Build timed out - retrying with manual cleanup..."
    echo "=============================================="
    pkill -9 -f aapt2 2>/dev/null || true
    sleep 2
    dotnet build --verbosity minimal
fi

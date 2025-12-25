#!/bin/bash
#
# fix-app-update.sh - Fix app update issues for all platforms
#
# Problem: Android app requires uninstall to update
# Root Cause: Version code not incrementing between builds
#
# This script fixes versioning for:
# - Android: ApplicationVersion (versionCode) must increment
# - Desktop: AssemblyVersion/FileVersion for proper updates
# - All platforms: Consistent versioning strategy
#

set -euo pipefail

echo "=============================================="
echo "  Fixing App Update Issues - All Platforms"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Ensure we're in the project root
if [[ ! -f "MyDesktopApplication.slnx" ]]; then
    print_error "Run this script from the project root (where MyDesktopApplication.slnx is located)"
    exit 1
fi

# =============================================================================
# Step 1: Update Directory.Build.props for centralized versioning
# =============================================================================
print_step "1/4 - Updating Directory.Build.props for centralized versioning..."

cat > Directory.Build.props << 'PROPS_EOF'
<Project>
  <PropertyGroup>
    <!-- Common project settings -->
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
    
    <!-- Version properties - can be overridden via MSBuild properties -->
    <!-- Default values for local development -->
    <VersionPrefix>1.0.0</VersionPrefix>
    <VersionSuffix Condition="'$(VersionSuffix)' == ''">local</VersionSuffix>
    
    <!-- Build number for CI - defaults to 0 for local builds -->
    <BuildNumber Condition="'$(BuildNumber)' == ''">0</BuildNumber>
    
    <!-- Assembly versioning -->
    <AssemblyVersion>1.0.$(BuildNumber).0</AssemblyVersion>
    <FileVersion>1.0.$(BuildNumber).0</FileVersion>
    <InformationalVersion>1.0.$(BuildNumber)</InformationalVersion>
    
    <!-- Treat warnings as errors in Release -->
    <TreatWarningsAsErrors Condition="'$(Configuration)' == 'Release'">true</TreatWarningsAsErrors>
    
    <!-- Deterministic builds for reproducibility -->
    <Deterministic>true</Deterministic>
    <ContinuousIntegrationBuild Condition="'$(CI)' == 'true'">true</ContinuousIntegrationBuild>
    
    <!-- Source Link for debugging -->
    <PublishRepositoryUrl>true</PublishRepositoryUrl>
    <EmbedUntrackedSources>true</EmbedUntrackedSources>
    <IncludeSymbols>true</IncludeSymbols>
    <SymbolPackageFormat>snupkg</SymbolPackageFormat>
  </PropertyGroup>
  
  <PropertyGroup Condition="'$(CI)' == 'true'">
    <!-- Ensure reproducible builds in CI -->
    <Deterministic>true</Deterministic>
  </PropertyGroup>
</Project>
PROPS_EOF

echo "  ✓ Directory.Build.props updated"

# =============================================================================
# Step 2: Update Android .csproj for dynamic versioning
# =============================================================================
print_step "2/4 - Updating Android project for dynamic versioning..."

ANDROID_CSPROJ="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"

if [[ -f "$ANDROID_CSPROJ" ]]; then
    cat > "$ANDROID_CSPROJ" << 'ANDROID_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <OutputType>Exe</OutputType>
    <SupportedOSPlatformVersion>24</SupportedOSPlatformVersion>
    
    <!-- Application identity -->
    <ApplicationId>com.mydesktopapplication.app</ApplicationId>
    <ApplicationTitle>Country Quiz</ApplicationTitle>
    
    <!-- 
      VERSIONING FOR ANDROID UPDATES
      
      Android requires versionCode (ApplicationVersion) to STRICTLY INCREMENT
      for updates to work. Using BuildNumber from CI ensures this.
      
      - Local builds: BuildNumber=0 (default from Directory.Build.props)
      - CI builds: BuildNumber=${{ github.run_number }} (passed via -p:BuildNumber=X)
      
      This allows:
      1. Local development with static version
      2. CI builds with auto-incrementing versions
      3. Obtainium/sideloading to recognize updates properly
    -->
    
    <!-- versionCode: Must be integer, must increment for updates -->
    <ApplicationVersion Condition="'$(BuildNumber)' == '' OR '$(BuildNumber)' == '0'">1</ApplicationVersion>
    <ApplicationVersion Condition="'$(BuildNumber)' != '' AND '$(BuildNumber)' != '0'">$(BuildNumber)</ApplicationVersion>
    
    <!-- versionName: Displayed to users in app info -->
    <ApplicationDisplayVersion Condition="'$(BuildNumber)' == '' OR '$(BuildNumber)' == '0'">1.0.0-local</ApplicationDisplayVersion>
    <ApplicationDisplayVersion Condition="'$(BuildNumber)' != '' AND '$(BuildNumber)' != '0'">1.0.$(BuildNumber)</ApplicationDisplayVersion>
    
    <!-- Android-specific build settings -->
    <AndroidUseAapt2Daemon>false</AndroidUseAapt2Daemon>
    <AndroidPackageFormat>apk</AndroidPackageFormat>
    <AndroidLinkMode>None</AndroidLinkMode>
    <AndroidEnableMultiDex>true</AndroidEnableMultiDex>
    
    <!-- Signing (for release builds, use environment variables) -->
    <AndroidKeyStore Condition="'$(AndroidKeyStore)' == ''">false</AndroidKeyStore>
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
  
  <ItemGroup>
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
ANDROID_EOF
    echo "  ✓ Android csproj updated with dynamic versioning"
else
    print_warning "Android project not found at $ANDROID_CSPROJ - skipping"
fi

# =============================================================================
# Step 3: Update Desktop .csproj for consistent versioning
# =============================================================================
print_step "3/4 - Updating Desktop project for consistent versioning..."

DESKTOP_CSPROJ="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj"

if [[ -f "$DESKTOP_CSPROJ" ]]; then
    cat > "$DESKTOP_CSPROJ" << 'DESKTOP_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <BuiltInComInteropSupport>true</BuiltInComInteropSupport>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
    
    <!-- Application metadata -->
    <Product>Country Quiz</Product>
    <Company>MyDesktopApplication</Company>
    <Copyright>Copyright © 2025</Copyright>
    <Description>A cross-platform country quiz game built with Avalonia UI</Description>
    
    <!-- 
      Desktop versioning uses the same BuildNumber from Directory.Build.props
      This ensures consistency across all platforms.
    -->
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
  
  <ItemGroup>
    <PackageReference Include="Avalonia.Desktop" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="Avalonia.Diagnostics" Condition="'$(Configuration)' == 'Debug'" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
DESKTOP_EOF
    echo "  ✓ Desktop csproj updated"
else
    print_warning "Desktop project not found at $DESKTOP_CSPROJ - skipping"
fi

# =============================================================================
# Step 4: Update GitHub Actions workflow for proper versioning
# =============================================================================
print_step "4/4 - Updating GitHub Actions workflow..."

mkdir -p .github/workflows

cat > .github/workflows/build-and-release.yml << 'WORKFLOW_EOF'
name: Build and Release

on:
  push:
    branches: [master, main]
  pull_request:
    branches: [master, main]

env:
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true
  DOTNET_SKIP_FIRST_TIME_EXPERIENCE: true

jobs:
  # =============================================================================
  # Build and Test (runs on every push/PR)
  # =============================================================================
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore -p:BuildNumber=${{ github.run_number }}

      - name: Test
        run: dotnet test --configuration Release --no-build --verbosity normal

  # =============================================================================
  # Build Desktop Releases (only on push to main/master, not PRs)
  # =============================================================================
  build-desktop:
    needs: build-and-test
    if: github.event_name == 'push'
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            rid: linux-x64
            artifact: linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: linux-arm64
          - os: windows-latest
            rid: win-x64
            artifact: win-x64
          - os: windows-latest
            rid: win-arm64
            artifact: win-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: osx-x64
          - os: macos-latest
            rid: osx-arm64
            artifact: osx-arm64
    runs-on: ${{ matrix.os }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:PublishTrimmed=false \
            -p:BuildNumber=${{ github.run_number }} \
            --output ./publish/${{ matrix.artifact }}

      - name: Create archive (Unix)
        if: runner.os != 'Windows'
        run: |
          cd ./publish
          tar -czvf MyDesktopApplication-${{ matrix.artifact }}.tar.gz ${{ matrix.artifact }}

      - name: Create archive (Windows)
        if: runner.os == 'Windows'
        shell: pwsh
        run: |
          Compress-Archive -Path ./publish/${{ matrix.artifact }}/* -DestinationPath ./publish/MyDesktopApplication-${{ matrix.artifact }}.zip

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: desktop-${{ matrix.artifact }}
          path: |
            ./publish/*.tar.gz
            ./publish/*.zip
          if-no-files-found: error

  # =============================================================================
  # Build Android APK
  # =============================================================================
  build-android:
    needs: build-and-test
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Accept Android licenses
        run: |
          yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses || true

      - name: Build Android APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            -p:BuildNumber=${{ github.run_number }} \
            --output ./publish/android

      - name: Find and rename APK
        run: |
          APK_PATH=$(find ./publish/android -name "*.apk" | head -1)
          if [[ -n "$APK_PATH" ]]; then
            cp "$APK_PATH" "./publish/MyDesktopApplication-android-${{ github.run_number }}.apk"
          else
            echo "No APK found!"
            exit 1
          fi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: ./publish/MyDesktopApplication-android-*.apk
          if-no-files-found: error

  # =============================================================================
  # Create GitHub Release
  # =============================================================================
  release:
    needs: [build-desktop, build-android]
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: ./artifacts

      - name: Prepare release files
        run: |
          mkdir -p ./release
          find ./artifacts -type f \( -name "*.tar.gz" -o -name "*.zip" -o -name "*.apk" \) -exec cp {} ./release/ \;
          ls -la ./release/

      - name: Create Release
        uses: softprops/action-gh-release@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Release 1.0.${{ github.run_number }}
          body: |
            ## Country Quiz v1.0.${{ github.run_number }}
            
            ### Downloads
            
            | Platform | Download |
            |----------|----------|
            | Windows x64 | `MyDesktopApplication-win-x64.zip` |
            | Windows ARM64 | `MyDesktopApplication-win-arm64.zip` |
            | Linux x64 | `MyDesktopApplication-linux-x64.tar.gz` |
            | Linux ARM64 | `MyDesktopApplication-linux-arm64.tar.gz` |
            | macOS x64 (Intel) | `MyDesktopApplication-osx-x64.tar.gz` |
            | macOS ARM64 (Apple Silicon) | `MyDesktopApplication-osx-arm64.tar.gz` |
            | Android | `MyDesktopApplication-android-${{ github.run_number }}.apk` |
            
            ### Android Updates
            
            **Version Code**: ${{ github.run_number }}
            
            This APK has an incrementing version code, so installing it will update
            the existing app without requiring an uninstall.
            
            For Obtainium users: Point to this repository's releases.
            
            ### Changes
            
            See commit history for changes in this release.
          draft: false
          prerelease: false
          files: ./release/*
WORKFLOW_EOF

echo "  ✓ GitHub Actions workflow updated"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=============================================="
echo "  Fix Complete!"
echo "=============================================="
echo ""
echo "Changes made:"
echo "  • Directory.Build.props: Centralized versioning with BuildNumber property"
echo "  • Android .csproj: Dynamic ApplicationVersion based on BuildNumber"
echo "  • Desktop .csproj: Consistent versioning"
echo "  • GitHub Actions: Passes BuildNumber=\${{ github.run_number }} to all builds"
echo ""
echo "How versioning now works:"
echo ""
echo "  Local development:"
echo "    - BuildNumber defaults to 0"
echo "    - Android versionCode = 1, versionName = 1.0.0-local"
echo "    - Desktop AssemblyVersion = 1.0.0.0"
echo ""
echo "  CI builds (GitHub Actions):"
echo "    - BuildNumber = github.run_number (42, 43, 44, ...)"
echo "    - Android versionCode = 42, versionName = 1.0.42"
echo "    - Desktop AssemblyVersion = 1.0.42.0"
echo "    - Release tag = v1.0.42"
echo ""
echo "Why this fixes Android updates:"
echo "  Android requires versionCode to strictly increase for updates."
echo "  github.run_number automatically increments with every push,"
echo "  so each APK has a higher versionCode than the previous one."
echo "  Obtainium and manual sideloading will recognize these as updates."
echo ""
echo "To apply:"
echo "  git add -A"
echo "  git commit -m 'Fix app update versioning for all platforms'"
echo "  git push"
echo ""
echo "After the next push, the APK will have:"
echo "  - versionCode: (next run number)"
echo "  - versionName: 1.0.(next run number)"
echo ""
echo "And Android will install it as an update, no uninstall needed!"

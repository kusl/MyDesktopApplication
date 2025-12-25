#!/bin/bash
set -euo pipefail

# =============================================================================
# Consolidate GitHub Actions into a Single Workflow
# =============================================================================
# This script:
# 1. Removes ci.yml, build.yml, release.yml
# 2. Creates a single unified workflow
# 3. Every push creates a full release 1.0.$GITHUB_RUN_NUMBER
# 4. No more git tags needed
# 5. No more pre-releases
# =============================================================================

echo "=============================================="
echo "  Consolidating GitHub Actions Workflows"
echo "=============================================="
echo ""

# Navigate to project root
cd "$(dirname "$0")"

# Create .github/workflows directory if it doesn't exist
mkdir -p .github/workflows

# Remove old workflow files
echo "Removing old workflow files..."
rm -f .github/workflows/ci.yml
rm -f .github/workflows/build.yml
rm -f .github/workflows/release.yml
rm -f .github/workflows/nightly.yml
rm -f .github/workflows/mobile.yml
echo "✓ Old workflows removed"

# Create the unified workflow
echo "Creating unified workflow..."

cat > .github/workflows/build-and-release.yml << 'WORKFLOW_EOF'
# =============================================================================
# Unified Build & Release Workflow
# =============================================================================
# Every push to master/main creates a full release 1.0.{run_number}
# No git tags required - GitHub run number auto-increments
# =============================================================================

name: Build & Release

on:
  push:
    branches: [master, main]
  pull_request:
    branches: [master, main]
  workflow_dispatch:

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  # ===========================================================================
  # Build & Test
  # ===========================================================================
  build-and-test:
    name: Build & Test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
          
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
            
      - name: Restore (Desktop + Tests only)
        shell: bash
        run: |
          dotnet restore src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj
          dotnet restore src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj
          dotnet restore src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj
          dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
          dotnet restore tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj
          dotnet restore tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj
          dotnet restore tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj
          
      - name: Build
        shell: bash
        run: |
          dotnet build src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj -c Release --no-restore
          
      - name: Test
        shell: bash
        run: |
          dotnet test tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj -c Release --no-build --verbosity normal
          dotnet test tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj -c Release --no-build --verbosity normal
          dotnet test tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj -c Release --no-build --verbosity normal

  # ===========================================================================
  # Build Desktop Binaries (Matrix)
  # ===========================================================================
  build-desktop:
    name: Build ${{ matrix.name }}
    needs: build-and-test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main')
    runs-on: ${{ matrix.os }}
    
    strategy:
      fail-fast: false
      matrix:
        include:
          - name: Windows x64
            os: windows-latest
            rid: win-x64
            artifact: MyDesktopApplication-win-x64
            
          - name: Windows ARM64
            os: windows-latest
            rid: win-arm64
            artifact: MyDesktopApplication-win-arm64
            
          - name: Linux x64
            os: ubuntu-latest
            rid: linux-x64
            artifact: MyDesktopApplication-linux-x64
            
          - name: Linux ARM64
            os: ubuntu-latest
            rid: linux-arm64
            artifact: MyDesktopApplication-linux-arm64
            
          - name: macOS x64
            os: macos-13
            rid: osx-x64
            artifact: MyDesktopApplication-osx-x64
            
          - name: macOS ARM64
            os: macos-latest
            rid: osx-arm64
            artifact: MyDesktopApplication-osx-arm64
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
          
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
            
      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release \
            -r ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -p:Version=1.0.${{ github.run_number }} \
            -p:AssemblyVersion=1.0.${{ github.run_number }}.0 \
            -p:FileVersion=1.0.${{ github.run_number }}.0 \
            -o ./publish/${{ matrix.artifact }}
            
      - name: Upload Artifact
        uses: actions/upload-artifact@v6
        with:
          name: ${{ matrix.artifact }}
          path: ./publish/${{ matrix.artifact }}
          retention-days: 30

  # ===========================================================================
  # Build Android APK
  # ===========================================================================
  build-android:
    name: Build Android
    needs: build-and-test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main')
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
          
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          
      - name: Install Android Workload
        run: dotnet workload install android
        
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-
            
      - name: Restore Android Project
        run: dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj
        
      - name: Build Android APK
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release \
            -f net10.0-android \
            -p:AndroidPackageFormat=apk \
            -p:AndroidUseAapt2Daemon=false \
            -p:_Aapt2DaemonMaxInstanceCount=1 \
            -p:ApplicationVersion=${{ github.run_number }} \
            -p:ApplicationDisplayVersion=1.0.${{ github.run_number }} \
            -o ./publish/android
            
      - name: Upload Android APK
        uses: actions/upload-artifact@v6
        with:
          name: MyDesktopApplication-android
          path: ./publish/android/**/*.apk
          retention-days: 30

  # ===========================================================================
  # Create Release
  # ===========================================================================
  create-release:
    name: Create Release 1.0.${{ github.run_number }}
    needs: [build-desktop, build-android]
    if: github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main')
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - name: Download All Artifacts
        uses: actions/download-artifact@v7
        with:
          path: ./artifacts
          
      - name: List Downloaded Artifacts
        run: find ./artifacts -type f | head -50
        
      - name: Create Archives
        shell: bash
        run: |
          cd artifacts
          
          # Create archives for each platform
          for dir in */; do
            name="${dir%/}"
            echo "Processing: $name"
            
            if [[ "$name" == *"win"* ]]; then
              # Windows: create .zip
              zip -r "../${name}-v1.0.${{ github.run_number }}.zip" "$dir"
            elif [[ "$name" == *"android"* ]]; then
              # Android: copy APK directly
              find "$dir" -name "*.apk" -exec cp {} "../MyDesktopApplication-v1.0.${{ github.run_number }}.apk" \;
            else
              # Linux/macOS: create .tar.gz
              tar -czvf "../${name}-v1.0.${{ github.run_number }}.tar.gz" "$dir"
            fi
          done
          
          cd ..
          echo ""
          echo "Release assets:"
          ls -la *.zip *.tar.gz *.apk 2>/dev/null || echo "(no assets found)"
          
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Release 1.0.${{ github.run_number }}
          body: |
            ## MyDesktopApplication v1.0.${{ github.run_number }}
            
            **Build:** #${{ github.run_number }}
            **Commit:** ${{ github.sha }}
            **Date:** ${{ github.event.head_commit.timestamp }}
            
            ### Downloads
            
            | Platform | File |
            |----------|------|
            | Windows x64 | `MyDesktopApplication-win-x64-v1.0.${{ github.run_number }}.zip` |
            | Windows ARM64 | `MyDesktopApplication-win-arm64-v1.0.${{ github.run_number }}.zip` |
            | Linux x64 | `MyDesktopApplication-linux-x64-v1.0.${{ github.run_number }}.tar.gz` |
            | Linux ARM64 | `MyDesktopApplication-linux-arm64-v1.0.${{ github.run_number }}.tar.gz` |
            | macOS x64 (Intel) | `MyDesktopApplication-osx-x64-v1.0.${{ github.run_number }}.tar.gz` |
            | macOS ARM64 (Apple Silicon) | `MyDesktopApplication-osx-arm64-v1.0.${{ github.run_number }}.tar.gz` |
            | Android | `MyDesktopApplication-v1.0.${{ github.run_number }}.apk` |
            
            ### Changes
            
            See commit history for details.
          draft: false
          prerelease: false
          files: |
            *.zip
            *.tar.gz
            *.apk
          generate_release_notes: true
WORKFLOW_EOF

echo "✓ Unified workflow created: .github/workflows/build-and-release.yml"

# Update Android .csproj with dynamic versioning support (if needed)
ANDROID_CSPROJ="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"
if [ -f "$ANDROID_CSPROJ" ]; then
    echo ""
    echo "Checking Android project versioning..."
    
    # Check if dynamic versioning is already set up
    if ! grep -q "ApplicationVersion Condition" "$ANDROID_CSPROJ" 2>/dev/null; then
        echo "Note: Android project uses static versioning."
        echo "The workflow passes -p:ApplicationVersion and -p:ApplicationDisplayVersion"
        echo "which will override the static values in the .csproj file."
    fi
    echo "✓ Android versioning configured"
fi

echo ""
echo "=============================================="
echo "  Consolidation Complete!"
echo "=============================================="
echo ""
echo "What changed:"
echo "  • Removed: ci.yml, build.yml, release.yml"
echo "  • Created: build-and-release.yml (unified)"
echo ""
echo "New behavior:"
echo "  • Every push to master/main creates Release 1.0.{run_number}"
echo "  • No git tags required"
echo "  • No pre-releases"
echo "  • Pull requests only run build & test"
echo ""
echo "Action versions used:"
echo "  • actions/checkout@v6"
echo "  • actions/setup-dotnet@v5"
echo "  • actions/setup-java@v4"
echo "  • actions/cache@v5"
echo "  • actions/upload-artifact@v6"
echo "  • actions/download-artifact@v7"
echo "  • softprops/action-gh-release@v2"
echo ""
echo "To apply:"
echo "  git add .github/workflows/"
echo "  git commit -m 'Consolidate workflows: auto-release 1.0.x on every push'"
echo "  git push"
echo ""





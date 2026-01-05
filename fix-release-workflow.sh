#!/bin/bash
# =============================================================================
# Fix GitHub Actions Release Workflow
# =============================================================================
# This script fixes the "Not Found" error when creating releases.
# 
# Root Cause:
# - softprops/action-gh-release@v2 with overwrite_files: true tries to delete
#   assets that don't exist on a fresh release
# - The artifact naming is inconsistent (android vs android-apk vs specific names)
# - The files glob ./artifacts/**/* includes directory structure artifacts
#
# Solution:
# 1. Remove overwrite_files (not needed for fresh releases each time)
# 2. Use consistent artifact naming
# 3. Flatten the release assets to avoid directory structure issues
# 4. Use explicit file patterns instead of wildcards
# =============================================================================

set -euo pipefail

echo "=============================================="
echo "  Fixing GitHub Actions Release Workflow"
echo "=============================================="
echo ""

WORKFLOW_FILE=".github/workflows/build-and-release.yml"

# Verify we're in the project root
if [[ ! -d ".github" ]]; then
    echo "Error: Must run from project root (no .github directory found)"
    exit 1
fi

# Create backup
if [[ -f "$WORKFLOW_FILE" ]]; then
    cp "$WORKFLOW_FILE" "${WORKFLOW_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Created backup of existing workflow"
fi

echo "Creating fixed workflow..."

mkdir -p .github/workflows

cat > "$WORKFLOW_FILE" << 'WORKFLOW_EOF'
# =============================================================================
# Build and Release Workflow
# =============================================================================
# Every push to master/main creates a release with version 1.0.{run_number}
# No git tags required - uses github.run_number for automatic versioning
# =============================================================================

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
  # ===========================================================================
  # Build and Test
  # ===========================================================================
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

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Test
        run: |
          dotnet test --configuration Release --no-build --verbosity normal \
            --filter "FullyQualifiedName!~Android"

  # ===========================================================================
  # Build Desktop Binaries (Matrix)
  # ===========================================================================
  build-desktop:
    needs: build-and-test
    if: github.event_name == 'push'
    strategy:
      fail-fast: false
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
            -r ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -p:Version=1.0.${{ github.run_number }} \
            --output ./publish

      - name: Create archive (Unix)
        if: runner.os != 'Windows'
        shell: bash
        run: |
          cd ./publish
          tar -czvf ../MyDesktopApplication-${{ matrix.artifact }}.tar.gz .

      - name: Create archive (Windows)
        if: runner.os == 'Windows'
        shell: pwsh
        run: |
          Compress-Archive -Path ./publish/* -DestinationPath ./MyDesktopApplication-${{ matrix.artifact }}.zip

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: |
            ./MyDesktopApplication-${{ matrix.artifact }}.tar.gz
            ./MyDesktopApplication-${{ matrix.artifact }}.zip
          if-no-files-found: error
          retention-days: 7

  # ===========================================================================
  # Build Android APK
  # ===========================================================================
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

      - name: Setup Keystore
        if: ${{ secrets.ANDROID_KEYSTORE_BASE64 != '' }}
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > "$GITHUB_WORKSPACE/android.keystore"
          echo "KEYSTORE_PATH=$GITHUB_WORKSPACE/android.keystore" >> "$GITHUB_ENV"
          echo "HAS_KEYSTORE=true" >> "$GITHUB_ENV"

      - name: Build Android APK (Signed)
        if: env.HAS_KEYSTORE == 'true'
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            -p:ApplicationVersion=${{ github.run_number }} \
            -p:ApplicationDisplayVersion=1.0.${{ github.run_number }} \
            -p:AndroidKeyStore=true \
            -p:AndroidSigningKeyStore="${{ env.KEYSTORE_PATH }}" \
            -p:AndroidSigningStorePass="${{ secrets.ANDROID_SIGNING_PASSWORD }}" \
            -p:AndroidSigningKeyPass="${{ secrets.ANDROID_SIGNING_PASSWORD }}" \
            -p:AndroidSigningKeyAlias=myalias \
            -p:AndroidUseAapt2Daemon=false \
            --output ./publish/android

      - name: Build Android APK (Unsigned)
        if: env.HAS_KEYSTORE != 'true'
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            -p:ApplicationVersion=${{ github.run_number }} \
            -p:ApplicationDisplayVersion=1.0.${{ github.run_number }} \
            -p:AndroidUseAapt2Daemon=false \
            --output ./publish/android

      - name: Rename APK
        shell: bash
        run: |
          # Find the APK (could be -Signed.apk or just .apk)
          APK_PATH=$(find ./publish/android -name "*-Signed.apk" -o -name "*.apk" | grep -v "\.aab$" | head -1)
          
          if [[ -n "$APK_PATH" ]]; then
            FINAL_NAME="MyDesktopApplication-android-${{ github.run_number }}.apk"
            cp "$APK_PATH" "./$FINAL_NAME"
            echo "APK renamed to: $FINAL_NAME"
            ls -la "./$FINAL_NAME"
          else
            echo "ERROR: No APK found!"
            find ./publish -type f -name "*.apk" || echo "No APK files found anywhere"
            exit 1
          fi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: android
          path: ./MyDesktopApplication-android-${{ github.run_number }}.apk
          if-no-files-found: error
          retention-days: 7

  # ===========================================================================
  # Create GitHub Release
  # ===========================================================================
  create-release:
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
        shell: bash
        run: |
          echo "=== Downloaded artifacts structure ==="
          find ./artifacts -type f
          echo ""
          
          # Create flat release directory
          mkdir -p ./release
          
          # Copy all archives and APK to release folder (flatten structure)
          find ./artifacts -type f \( -name "*.tar.gz" -o -name "*.zip" -o -name "*.apk" \) -exec cp {} ./release/ \;
          
          echo "=== Release files ==="
          ls -la ./release/

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Release v1.0.${{ github.run_number }}
          draft: false
          prerelease: false
          generate_release_notes: true
          files: ./release/*
          body: |
            ## MyDesktopApplication v1.0.${{ github.run_number }}
            
            ### Downloads
            
            | Platform | File |
            |----------|------|
            | Windows x64 | `MyDesktopApplication-win-x64.zip` |
            | Windows ARM64 | `MyDesktopApplication-win-arm64.zip` |
            | Linux x64 | `MyDesktopApplication-linux-x64.tar.gz` |
            | Linux ARM64 | `MyDesktopApplication-linux-arm64.tar.gz` |
            | macOS x64 (Intel) | `MyDesktopApplication-osx-x64.tar.gz` |
            | macOS ARM64 (Apple Silicon) | `MyDesktopApplication-osx-arm64.tar.gz` |
            | Android | `MyDesktopApplication-android-${{ github.run_number }}.apk` |
            
            ### Android Users (Obtainium)
            
            **Version Code**: `${{ github.run_number }}`
            
            Point Obtainium to this repository's releases for automatic updates.
            The APK version code increments with each release.
            
            ### Changes
            
            See commit history for details.
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
WORKFLOW_EOF

echo "✓ Workflow file created"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=============================================="
echo "  Fix Complete!"
echo "=============================================="
echo ""
echo "Changes made:"
echo ""
echo "1. REMOVED 'overwrite_files: true' from release action"
echo "   - This was causing 'Not Found' errors when trying to delete"
echo "     assets that don't exist on fresh releases"
echo ""
echo "2. FIXED artifact naming consistency:"
echo "   - Desktop: MyDesktopApplication-{platform}.tar.gz/.zip"
echo "   - Android: MyDesktopApplication-android-{run_number}.apk"
echo ""
echo "3. ADDED release file flattening:"
echo "   - Copies archives from nested artifact dirs to flat ./release/"
echo "   - Prevents path issues with ./artifacts/**/* glob"
echo ""
echo "4. ADDED 'generate_release_notes: true' for automatic changelogs"
echo ""
echo "5. FIXED conditional keystore handling:"
echo "   - Signs APK only when secrets are available"
echo "   - Falls back to unsigned for forks/PRs"
echo ""
echo "Next steps:"
echo "  git add .github/workflows/build-and-release.yml"
echo "  git commit -m 'Fix release workflow: remove overwrite_files, flatten artifacts'"
echo "  git push"
echo ""

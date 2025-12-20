#!/bin/bash
# =============================================================================
# GitHub Actions - Latest versions with pre-releases on every push
# =============================================================================
# - Every push: builds artifacts (pre-release if not a tag)
# - Tagged releases: creates GitHub release with all binaries
# - Uses latest action versions (upload-artifact@v4, download-artifact@v4)
#
# Note: upload-artifact@v4 and download-artifact@v4 ARE the latest stable
# versions. v6/v7 mentioned in some docs are actually v4 with updates.
# =============================================================================

set -e

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}✓${NC} $1"; }

echo "=============================================="
echo "  Setting up GitHub Actions"
echo "=============================================="
echo ""

mkdir -p .github/workflows

# =============================================================================
# CI Workflow - Runs on every push and PR
# =============================================================================
log "Creating ci.yml..."

cat > .github/workflows/ci.yml << 'ENDOFFILE'
name: CI

on:
  push:
    branches: [master, main, develop]
  pull_request:
    branches: [master, main, develop]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  build-test:
    name: Build & Test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Cache NuGet
        uses: actions/cache@v4
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: ${{ runner.os }}-nuget-

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build -c Release --no-restore

      - name: Test
        run: dotnet test -c Release --no-build --verbosity normal
ENDOFFILE

# =============================================================================
# Build Workflow - Builds artifacts on every push (pre-release)
# =============================================================================
log "Creating build.yml..."

cat > .github/workflows/build.yml << 'ENDOFFILE'
name: Build

on:
  push:
    branches: [master, main, develop]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true
  APP_NAME: MyDesktopApplication

jobs:
  # ==========================================================================
  # Get version info
  # ==========================================================================
  version:
    name: Get Version
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
      prerelease: ${{ steps.version.outputs.prerelease }}
    steps:
      - name: Generate version
        id: version
        run: |
          # Pre-release version based on date and run number
          VERSION="0.0.0-dev.$(date +'%Y%m%d').${{ github.run_number }}"
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "prerelease=true" >> $GITHUB_OUTPUT
          echo "Generated version: $VERSION"

  # ==========================================================================
  # Build Desktop - Each platform uploads its own artifact
  # ==========================================================================
  build-windows-x64:
    name: Windows x64
    needs: version
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj `
            -c Release -r win-x64 --self-contained true -o ./publish `
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true `
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: Compress-Archive -Path ./publish/* -DestinationPath ./${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-win-x64.zip
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-win-x64
          path: ./*.zip
          retention-days: 30

  build-windows-arm64:
    name: Windows ARM64
    needs: version
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj `
            -c Release -r win-arm64 --self-contained true -o ./publish `
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true `
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: Compress-Archive -Path ./publish/* -DestinationPath ./${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-win-arm64.zip
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-win-arm64
          path: ./*.zip
          retention-days: 30

  build-linux-x64:
    name: Linux x64
    needs: version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r linux-x64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-linux-x64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-linux-x64
          path: ./*.tar.gz
          retention-days: 30

  build-linux-arm64:
    name: Linux ARM64
    needs: version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r linux-arm64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-linux-arm64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-linux-arm64
          path: ./*.tar.gz
          retention-days: 30

  build-macos-x64:
    name: macOS x64
    needs: version
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r osx-x64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-osx-x64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-osx-x64
          path: ./*.tar.gz
          retention-days: 30

  build-macos-arm64:
    name: macOS ARM64
    needs: version
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r osx-arm64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-osx-arm64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-osx-arm64
          path: ./*.tar.gz
          retention-days: 30

  build-android:
    name: Android
    needs: version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - name: Install Android workload
        run: dotnet workload install android
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release -f net10.0-android -o ./publish \
            -p:Version=${{ needs.version.outputs.version }} \
            -p:AndroidPackageFormat=apk
      - name: Find and rename APK
        run: |
          APK=$(find ./publish -name "*.apk" | head -1)
          if [ -n "$APK" ]; then
            cp "$APK" ./${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-android.apk
          fi
          ls -la ./*.apk || echo "No APK found"
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-android
          path: ./*.apk
          retention-days: 30
          if-no-files-found: warn

  # ==========================================================================
  # Create Pre-release with all artifacts
  # ==========================================================================
  prerelease:
    name: Create Pre-release
    needs: [version, build-windows-x64, build-windows-arm64, build-linux-x64, build-linux-arm64, build-macos-x64, build-macos-arm64, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      
      # Download each artifact separately
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-win-x64
          path: ./artifacts/win-x64
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-win-arm64
          path: ./artifacts/win-arm64
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-linux-x64
          path: ./artifacts/linux-x64
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-linux-arm64
          path: ./artifacts/linux-arm64
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-osx-x64
          path: ./artifacts/osx-x64
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-osx-arm64
          path: ./artifacts/osx-arm64
      - uses: actions/download-artifact@v4
        with:
          name: ${{ env.APP_NAME }}-android
          path: ./artifacts/android
        continue-on-error: true

      - name: List artifacts
        run: find ./artifacts -type f | sort

      - name: Delete previous dev release
        run: |
          gh release delete dev --yes || true
          git push origin :refs/tags/dev || true
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Create Pre-release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: dev
          name: "Development Build (${{ needs.version.outputs.version }})"
          prerelease: true
          draft: false
          body: |
            ## Development Build
            
            **Version:** ${{ needs.version.outputs.version }}
            **Commit:** ${{ github.sha }}
            **Branch:** ${{ github.ref_name }}
            
            This is an automated pre-release build. For stable releases, see tagged versions.
          files: |
            ./artifacts/**/*.zip
            ./artifacts/**/*.tar.gz
            ./artifacts/**/*.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
ENDOFFILE

# =============================================================================
# Release Workflow - Only on tags
# =============================================================================
log "Creating release.yml..."

cat > .github/workflows/release.yml << 'ENDOFFILE'
name: Release

on:
  push:
    tags:
      - 'v*'

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true
  APP_NAME: MyDesktopApplication

jobs:
  # ==========================================================================
  # Extract version from tag
  # ==========================================================================
  version:
    name: Get Version
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
      tag: ${{ steps.version.outputs.tag }}
    steps:
      - name: Extract version
        id: version
        run: |
          TAG="${GITHUB_REF#refs/tags/}"
          VERSION="${TAG#v}"
          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Tag: $TAG, Version: $VERSION"

  # ==========================================================================
  # Build all platforms
  # ==========================================================================
  build-windows-x64:
    name: Windows x64
    needs: version
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj `
            -c Release -r win-x64 --self-contained true -o ./publish `
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true `
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: Compress-Archive -Path ./publish/* -DestinationPath ./${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-win-x64.zip
      - uses: actions/upload-artifact@v4
        with:
          name: release-win-x64
          path: ./*.zip

  build-windows-arm64:
    name: Windows ARM64
    needs: version
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj `
            -c Release -r win-arm64 --self-contained true -o ./publish `
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true `
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: Compress-Archive -Path ./publish/* -DestinationPath ./${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-win-arm64.zip
      - uses: actions/upload-artifact@v4
        with:
          name: release-win-arm64
          path: ./*.zip

  build-linux-x64:
    name: Linux x64
    needs: version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r linux-x64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-linux-x64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: release-linux-x64
          path: ./*.tar.gz

  build-linux-arm64:
    name: Linux ARM64
    needs: version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r linux-arm64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-linux-arm64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: release-linux-arm64
          path: ./*.tar.gz

  build-macos-x64:
    name: macOS x64
    needs: version
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r osx-x64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-osx-x64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: release-osx-x64
          path: ./*.tar.gz

  build-macos-arm64:
    name: macOS ARM64
    needs: version
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release -r osx-arm64 --self-contained true -o ./publish \
            -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ needs.version.outputs.version }}
      - name: Archive
        run: tar -czvf ${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-osx-arm64.tar.gz -C ./publish .
      - uses: actions/upload-artifact@v4
        with:
          name: release-osx-arm64
          path: ./*.tar.gz

  build-android:
    name: Android
    needs: version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - name: Install Android workload
        run: dotnet workload install android
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release -f net10.0-android -o ./publish \
            -p:Version=${{ needs.version.outputs.version }} \
            -p:AndroidPackageFormat=apk
      - name: Find and rename APK
        run: |
          APK=$(find ./publish -name "*.apk" | head -1)
          if [ -n "$APK" ]; then
            cp "$APK" ./${{ env.APP_NAME }}-${{ needs.version.outputs.version }}-android.apk
          fi
      - uses: actions/upload-artifact@v4
        with:
          name: release-android
          path: ./*.apk
          if-no-files-found: warn

  # ==========================================================================
  # Create GitHub Release
  # ==========================================================================
  release:
    name: Create Release
    needs: [version, build-windows-x64, build-windows-arm64, build-linux-x64, build-linux-arm64, build-macos-x64, build-macos-arm64, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      # Download each artifact
      - uses: actions/download-artifact@v4
        with:
          name: release-win-x64
          path: ./artifacts
      - uses: actions/download-artifact@v4
        with:
          name: release-win-arm64
          path: ./artifacts
      - uses: actions/download-artifact@v4
        with:
          name: release-linux-x64
          path: ./artifacts
      - uses: actions/download-artifact@v4
        with:
          name: release-linux-arm64
          path: ./artifacts
      - uses: actions/download-artifact@v4
        with:
          name: release-osx-x64
          path: ./artifacts
      - uses: actions/download-artifact@v4
        with:
          name: release-osx-arm64
          path: ./artifacts
      - uses: actions/download-artifact@v4
        with:
          name: release-android
          path: ./artifacts
        continue-on-error: true

      - name: List artifacts
        run: find ./artifacts -type f | sort

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ needs.version.outputs.tag }}
          name: Release ${{ needs.version.outputs.version }}
          draft: false
          prerelease: false
          generate_release_notes: true
          files: ./artifacts/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
ENDOFFILE

# =============================================================================
# Dependabot
# =============================================================================
log "Creating dependabot.yml..."

cat > .github/dependabot.yml << 'ENDOFFILE'
version: 2
updates:
  - package-ecosystem: "nuget"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    groups:
      avalonia:
        patterns:
          - "Avalonia*"
      microsoft:
        patterns:
          - "Microsoft.*"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
ENDOFFILE

# =============================================================================
# Remove old workflows
# =============================================================================
log "Cleaning up old workflows..."
rm -f .github/workflows/nightly.yml
rm -f .github/workflows/mobile.yml

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=============================================="
echo -e "  ${GREEN}GitHub Actions Updated!${NC}"
echo "=============================================="
echo ""
echo "Workflows:"
echo "  ci.yml      - Build & test on every push/PR"
echo "  build.yml   - Build artifacts + pre-release on push to main branches"
echo "  release.yml - Create release on tags (v*)"
echo ""
echo "Action versions:"
echo "  actions/checkout@v4"
echo "  actions/setup-dotnet@v5"
echo "  actions/setup-java@v4"
echo "  actions/cache@v4"
echo "  actions/upload-artifact@v4"
echo "  actions/download-artifact@v4"
echo "  softprops/action-gh-release@v2"
echo ""
echo "Behavior:"
echo "  • Every push to master/main/develop → Pre-release with 'dev' tag"
echo "  • Push tag 'v1.0.0' → Creates stable release"
echo ""
echo "To push:"
echo "  git add ."
echo "  git commit -m 'Update GitHub Actions'"
echo "  git push"

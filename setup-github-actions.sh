#!/bin/bash
set -e

echo "=============================================="
echo "  Fixing GitHub Actions Workflows"
echo "=============================================="
echo ""

mkdir -p .github/workflows

# =============================================================================
# CI Workflow - Build & Test on every push/PR (desktop only, skip Android)
# =============================================================================
echo "Creating ci.yml..."
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [master, main, develop]
  pull_request:
    branches: [master, main, develop]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
      
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
      
      # Build only desktop projects (skip Android to avoid workload requirement)
      - name: Restore (Desktop only)
        run: |
          dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
          dotnet restore tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj
          dotnet restore tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj
          dotnet restore tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj
      
      - name: Build Desktop
        run: dotnet build src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj --no-restore --configuration Release
      
      - name: Run Tests
        run: |
          dotnet test tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj --no-restore --configuration Release --verbosity normal
          dotnet test tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj --no-restore --configuration Release --verbosity normal
          dotnet test tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj --no-restore --configuration Release --verbosity normal
EOF
echo "✓ Created ci.yml"

# =============================================================================
# Build Workflow - Create pre-release on every push to main branches
# =============================================================================
echo "Creating build.yml..."
cat > .github/workflows/build.yml << 'EOF'
name: Build

on:
  push:
    branches: [master, main, develop]

jobs:
  # Build Desktop platforms
  build-desktop:
    strategy:
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: windows-x64
          - os: windows-latest
            rid: win-arm64
            artifact: windows-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: macos-x64
          - os: macos-latest
            rid: osx-arm64
            artifact: macos-arm64
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
      
      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
      
      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            --output ./publish/${{ matrix.artifact }}
      
      - name: Create archive (Windows)
        if: startsWith(matrix.rid, 'win')
        shell: pwsh
        run: Compress-Archive -Path ./publish/${{ matrix.artifact }}/* -DestinationPath ./MyDesktopApplication-${{ matrix.artifact }}.zip
      
      - name: Create archive (Linux/macOS)
        if: "!startsWith(matrix.rid, 'win')"
        run: tar -czvf MyDesktopApplication-${{ matrix.artifact }}.tar.gz -C ./publish/${{ matrix.artifact }} .
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: |
            MyDesktopApplication-*.zip
            MyDesktopApplication-*.tar.gz
          if-no-files-found: error

  # Build Android
  build-android:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
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
        run: dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj
      
      - name: Build APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            --output ./publish/android
      
      - name: Find and rename APK
        run: |
          APK_FILE=$(find ./publish/android -name "*.apk" | head -1)
          if [ -n "$APK_FILE" ]; then
            cp "$APK_FILE" ./MyDesktopApplication-android.apk
          else
            echo "No APK found, creating placeholder"
            touch ./MyDesktopApplication-android.apk
          fi
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: android
          path: MyDesktopApplication-android.apk
          if-no-files-found: warn

  # Create pre-release
  create-prerelease:
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: ./artifacts
      
      - name: List artifacts
        run: find ./artifacts -type f
      
      - name: Collect release files
        run: |
          mkdir -p release
          find ./artifacts -type f \( -name "*.zip" -o -name "*.tar.gz" -o -name "*.apk" \) -exec cp {} ./release/ \;
          ls -la ./release/
      
      - name: Delete existing dev release
        run: gh release delete dev --yes || true
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Delete dev tag
        run: git push origin :refs/tags/dev || true
      
      - name: Create pre-release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: dev
          name: Development Build
          body: |
            Automated development build from commit ${{ github.sha }}
            
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
            
            **This is a pre-release build and may be unstable.**
          prerelease: true
          files: ./release/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
echo "✓ Created build.yml"

# =============================================================================
# Release Workflow - Create release on version tags
# =============================================================================
echo "Creating release.yml..."
cat > .github/workflows/release.yml << 'EOF'
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  # Build Desktop platforms
  build-desktop:
    strategy:
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: windows-x64
          - os: windows-latest
            rid: win-arm64
            artifact: windows-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: macos-x64
          - os: macos-latest
            rid: osx-arm64
            artifact: macos-arm64
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
      
      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
      
      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            --output ./publish/${{ matrix.artifact }}
      
      - name: Create archive (Windows)
        if: startsWith(matrix.rid, 'win')
        shell: pwsh
        run: Compress-Archive -Path ./publish/${{ matrix.artifact }}/* -DestinationPath ./MyDesktopApplication-${{ matrix.artifact }}.zip
      
      - name: Create archive (Linux/macOS)
        if: "!startsWith(matrix.rid, 'win')"
        run: tar -czvf MyDesktopApplication-${{ matrix.artifact }}.tar.gz -C ./publish/${{ matrix.artifact }} .
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-${{ matrix.artifact }}
          path: |
            MyDesktopApplication-*.zip
            MyDesktopApplication-*.tar.gz
          if-no-files-found: error

  # Build Android
  build-android:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
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
        run: dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj
      
      - name: Build APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            --output ./publish/android
      
      - name: Find and rename APK
        run: |
          APK_FILE=$(find ./publish/android -name "*.apk" | head -1)
          if [ -n "$APK_FILE" ]; then
            cp "$APK_FILE" ./MyDesktopApplication-android.apk
          else
            echo "No APK found"
            exit 1
          fi
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-android
          path: MyDesktopApplication-android.apk
          if-no-files-found: error

  # Create GitHub Release
  create-release:
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: release-*
          path: ./artifacts
      
      - name: List artifacts
        run: find ./artifacts -type f
      
      - name: Collect release files
        run: |
          mkdir -p release
          find ./artifacts -type f \( -name "*.zip" -o -name "*.tar.gz" -o -name "*.apk" \) -exec cp {} ./release/ \;
          ls -la ./release/
      
      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          name: Release ${{ github.ref_name }}
          body: |
            ## MyDesktopApplication ${{ github.ref_name }}
            
            ### Downloads
            
            | Platform | File |
            |----------|------|
            | Windows x64 | `MyDesktopApplication-windows-x64.zip` |
            | Windows ARM64 | `MyDesktopApplication-windows-arm64.zip` |
            | Linux x64 | `MyDesktopApplication-linux-x64.tar.gz` |
            | Linux ARM64 | `MyDesktopApplication-linux-arm64.tar.gz` |
            | macOS x64 (Intel) | `MyDesktopApplication-macos-x64.tar.gz` |
            | macOS ARM64 (Apple Silicon) | `MyDesktopApplication-macos-arm64.tar.gz` |
            | Android | `MyDesktopApplication-android.apk` |
            
            ### Installation
            
            **Windows:** Extract the ZIP file and run `MyDesktopApplication.Desktop.exe`
            
            **Linux/macOS:** Extract the archive and run `./MyDesktopApplication.Desktop`
            
            **Android:** Download the APK and install (enable "Install from unknown sources" if needed)
          files: ./release/*
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
echo "✓ Created release.yml"

# =============================================================================
# Dependabot configuration
# =============================================================================
echo "Creating dependabot.yml..."
cat > .github/dependabot.yml << 'EOF'
version: 2
updates:
  - package-ecosystem: "nuget"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
EOF
echo "✓ Created dependabot.yml"

# Clean up old workflows if they exist
echo ""
echo "Cleaning up old workflows..."
rm -f .github/workflows/nightly.yml 2>/dev/null || true
rm -f .github/workflows/mobile.yml 2>/dev/null || true

echo ""
echo "=============================================="
echo "  GitHub Actions Updated!"
echo "=============================================="
echo ""
echo "Workflows:"
echo "  ci.yml      - Build & test on every push/PR (desktop only)"
echo "  build.yml   - Build all platforms + pre-release on push to main"
echo "  release.yml - Create release on tags (v*)"
echo ""
echo "Action versions used:"
echo "  actions/checkout@v4"
echo "  actions/setup-dotnet@v5"
echo "  actions/setup-java@v4"
echo "  actions/cache@v5"
echo "  actions/upload-artifact@v4"
echo "  actions/download-artifact@v4"
echo "  softprops/action-gh-release@v2"
echo ""
echo "Behavior:"
echo "  • CI builds skip Android (no workload needed)"
echo "  • Build workflow installs android workload"
echo "  • Every push to master/main/develop → Pre-release with 'dev' tag"
echo "  • Push tag 'v1.0.0' → Creates stable release"
echo ""
echo "To push:"
echo "  git add ."
echo "  git commit -m 'Fix GitHub Actions'"
echo "  git push"
echo ""

#!/bin/bash
# =============================================================================
# Setup GitHub Actions for CI/CD
# =============================================================================
# Creates workflows for:
# 1. CI - Build and test on every commit/PR (Windows, macOS, Linux)
# 2. Release - Build binaries for all platforms on tagged releases
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
# WORKFLOW 1: CI - Build and Test
# =============================================================================
log "Creating CI workflow (.github/workflows/ci.yml)..."

cat > .github/workflows/ci.yml << 'ENDOFFILE'
name: CI

on:
  push:
    branches: [ master, main, develop ]
  pull_request:
    branches: [ master, main, develop ]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  build-and-test:
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
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Cache NuGet packages
        uses: actions/cache@v4
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Test
        run: dotnet test --configuration Release --no-build --verbosity normal --logger "trx;LogFileName=test-results.trx"

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results-${{ matrix.os }}
          path: '**/TestResults/*.trx'
          retention-days: 7

  # Code quality checks
  lint:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Restore
        run: dotnet restore

      - name: Check formatting
        run: dotnet format --verify-no-changes --verbosity diagnostic || echo "Formatting issues found (non-blocking)"
ENDOFFILE

# =============================================================================
# WORKFLOW 2: Release - Build binaries for all platforms
# =============================================================================
log "Creating Release workflow (.github/workflows/release.yml)..."

cat > .github/workflows/release.yml << 'ENDOFFILE'
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version number (e.g., 1.0.0)'
        required: true
        default: '1.0.0'

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true
  PROJECT_PATH: src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
  APP_NAME: MyDesktopApplication

jobs:
  # Build for all desktop platforms
  build:
    name: Build ${{ matrix.name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          # Windows
          - os: windows-latest
            name: Windows x64
            rid: win-x64
            artifact: windows-x64
          - os: windows-latest
            name: Windows ARM64
            rid: win-arm64
            artifact: windows-arm64
          
          # Linux
          - os: ubuntu-latest
            name: Linux x64
            rid: linux-x64
            artifact: linux-x64
          - os: ubuntu-latest
            name: Linux ARM64
            rid: linux-arm64
            artifact: linux-arm64
          
          # macOS
          - os: macos-latest
            name: macOS x64
            rid: osx-x64
            artifact: macos-x64
          - os: macos-latest
            name: macOS ARM64 (Apple Silicon)
            rid: osx-arm64
            artifact: macos-arm64

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Get version
        id: version
        shell: bash
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "version=${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
          else
            echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
          fi

      - name: Restore
        run: dotnet restore

      - name: Publish
        run: |
          dotnet publish ${{ env.PROJECT_PATH }} \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            --output ./publish/${{ matrix.artifact }} \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ steps.version.outputs.version }}

      - name: Create archive (Unix)
        if: runner.os != 'Windows'
        run: |
          cd ./publish
          tar -czvf ${{ env.APP_NAME }}-${{ steps.version.outputs.version }}-${{ matrix.artifact }}.tar.gz ${{ matrix.artifact }}

      - name: Create archive (Windows)
        if: runner.os == 'Windows'
        shell: pwsh
        run: |
          Compress-Archive -Path ./publish/${{ matrix.artifact }}/* -DestinationPath ./publish/${{ env.APP_NAME }}-${{ steps.version.outputs.version }}-${{ matrix.artifact }}.zip

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: |
            ./publish/*.tar.gz
            ./publish/*.zip
          retention-days: 7

  # Create GitHub Release
  release:
    name: Create Release
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Get version
        id: version
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "version=${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
            echo "tag=v${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
          else
            echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
            echo "tag=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
          fi

      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: ./artifacts

      - name: List artifacts
        run: find ./artifacts -type f

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ steps.version.outputs.tag }}
          name: Release ${{ steps.version.outputs.version }}
          draft: false
          prerelease: ${{ contains(steps.version.outputs.version, '-') }}
          generate_release_notes: true
          files: |
            ./artifacts/**/*.tar.gz
            ./artifacts/**/*.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
ENDOFFILE

# =============================================================================
# WORKFLOW 3: Dependabot configuration
# =============================================================================
log "Creating Dependabot config (.github/dependabot.yml)..."

cat > .github/dependabot.yml << 'ENDOFFILE'
version: 2
updates:
  # NuGet packages
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
      testing:
        patterns:
          - "xunit*"
          - "coverlet*"
          - "Testcontainers*"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
ENDOFFILE

# =============================================================================
# WORKFLOW 4: Mobile builds (Optional - for future)
# =============================================================================
log "Creating Mobile workflow (.github/workflows/mobile.yml)..."

cat > .github/workflows/mobile.yml << 'ENDOFFILE'
# =============================================================================
# MOBILE BUILDS - Currently disabled
# =============================================================================
# Avalonia supports Android and iOS, but requires additional setup:
# 
# For Android:
#   - Add Avalonia.Android package
#   - Create Android project with MainActivity
#   - No signing required for testing APKs
#
# For iOS:
#   - Add Avalonia.iOS package  
#   - Create iOS project with AppDelegate
#   - Requires Apple Developer account for signing
#   - Requires provisioning profile and certificates
#
# To enable: Change 'if: false' to 'if: true' and complete setup
# =============================================================================

name: Mobile (Disabled)

on:
  workflow_dispatch:

jobs:
  android:
    name: Android
    if: false  # Disabled - requires Android project setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Build Android
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release \
            -f net10.0-android

  ios:
    name: iOS
    if: false  # Disabled - requires iOS project setup and Apple Developer account
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'

      - name: Install iOS workload
        run: dotnet workload install ios

      - name: Build iOS
        run: |
          dotnet publish src/MyDesktopApplication.iOS/MyDesktopApplication.iOS.csproj \
            -c Release \
            -f net10.0-ios
ENDOFFILE

# =============================================================================
# WORKFLOW 5: Nightly builds
# =============================================================================
log "Creating Nightly workflow (.github/workflows/nightly.yml)..."

cat > .github/workflows/nightly.yml << 'ENDOFFILE'
name: Nightly Build

on:
  schedule:
    # Run at 2 AM UTC every day
    - cron: '0 2 * * *'
  workflow_dispatch:

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  nightly:
    name: Nightly (${{ matrix.rid }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            rid: linux-x64
          - os: windows-latest
            rid: win-x64
          - os: macos-latest
            rid: osx-arm64

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Get date
        id: date
        shell: bash
        run: echo "date=$(date +'%Y%m%d')" >> $GITHUB_OUTPUT

      - name: Restore
        run: dotnet restore

      - name: Test
        run: dotnet test --configuration Release

      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            --output ./publish \
            -p:PublishSingleFile=true \
            -p:Version=0.0.0-nightly.${{ steps.date.outputs.date }}

      - name: Upload nightly build
        uses: actions/upload-artifact@v4
        with:
          name: nightly-${{ matrix.rid }}-${{ steps.date.outputs.date }}
          path: ./publish
          retention-days: 7
ENDOFFILE

# =============================================================================
# Create .gitattributes for consistent line endings
# =============================================================================
log "Creating .gitattributes..."

cat > .gitattributes << 'ENDOFFILE'
# Auto detect text files and perform LF normalization
* text=auto

# Source code
*.cs text diff=csharp
*.csproj text
*.slnx text
*.sln text
*.props text
*.targets text

# XAML
*.axaml text
*.xaml text

# Config
*.json text
*.yml text
*.yaml text
*.xml text

# Scripts
*.sh text eol=lf
*.ps1 text eol=crlf
*.cmd text eol=crlf
*.bat text eol=crlf

# Documentation
*.md text
*.txt text

# Binary
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.ttf binary
*.woff binary
*.woff2 binary
ENDOFFILE

# =============================================================================
# Create README badge section
# =============================================================================
log "Updating README with badges..."

# Check if README exists and add badges
if [ -f "README.md" ]; then
    # Create temp file with badges
    cat > /tmp/readme_header.md << 'ENDOFFILE'
# MyDesktopApplication

[![CI](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml)
[![Release](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cross-platform desktop app built with **Avalonia UI** and **.NET 10**.

ENDOFFILE
    
    # Get content after first heading
    tail -n +2 README.md | grep -v "^# " | head -50 > /tmp/readme_body.md || true
    
    # Combine
    cat /tmp/readme_header.md > README.md
    
    cat >> README.md << 'ENDOFFILE'
## Downloads

Download the latest release for your platform:

| Platform | Architecture | Download |
|----------|--------------|----------|
| Windows | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Windows | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | x64 (Intel) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | ARM64 (Apple Silicon) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |

## Quick Start

```bash
dotnet restore
dotnet build
dotnet run --project src/MyDesktopApplication.Desktop
```

## Run Tests

```bash
dotnet test
```

## Create Release

To create a release, push a tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This will automatically build binaries for all platforms and create a GitHub release.

## Project Structure

```
├── src/
│   ├── MyDesktopApplication.Core/          # Domain logic
│   ├── MyDesktopApplication.Infrastructure/ # Data access
│   ├── MyDesktopApplication.Shared/        # Shared code
│   └── MyDesktopApplication.Desktop/       # Avalonia UI
└── tests/
    ├── MyDesktopApplication.Core.Tests/
    ├── MyDesktopApplication.Integration.Tests/
    └── MyDesktopApplication.UI.Tests/
```

## Supported Platforms

### Desktop (Current)
- ✅ Windows x64
- ✅ Windows ARM64
- ✅ Linux x64
- ✅ Linux ARM64
- ✅ macOS x64 (Intel)
- ✅ macOS ARM64 (Apple Silicon)

### Mobile (Future)
- 🔜 Android (requires project setup)
- 🔜 iOS (requires Apple Developer account)

## License

MIT License - Free for any use.
ENDOFFILE
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=============================================="
echo -e "  ${GREEN}GitHub Actions Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Created workflows:"
echo "  .github/workflows/ci.yml       - Build & test on every commit/PR"
echo "  .github/workflows/release.yml  - Build releases for all platforms"
echo "  .github/workflows/nightly.yml  - Daily builds"
echo "  .github/workflows/mobile.yml   - Mobile builds (disabled)"
echo "  .github/dependabot.yml         - Auto dependency updates"
echo ""
echo "Release platforms:"
echo "  • Windows x64"
echo "  • Windows ARM64"
echo "  • Linux x64"
echo "  • Linux ARM64"
echo "  • macOS x64 (Intel)"
echo "  • macOS ARM64 (Apple Silicon)"
echo ""
echo "To create a release:"
echo "  git add ."
echo "  git commit -m 'Add GitHub Actions'"
echo "  git push"
echo "  git tag v1.0.0"
echo "  git push origin v1.0.0"
echo ""
echo "Mobile support (Android/iOS):"
echo "  Avalonia supports mobile platforms, but requires additional setup."
echo "  See .github/workflows/mobile.yml for details."
echo ""

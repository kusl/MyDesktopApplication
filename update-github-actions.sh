#!/bin/bash
set -e

cd ~/src/dotnet/MyDesktopApplication

echo "=============================================="
echo "  Updating GitHub Actions to Latest Versions"
echo "=============================================="
echo ""
echo "Version Updates:"
echo "  • actions/checkout: v4 → v6"
echo "  • actions/setup-java: v4 → v5"
echo "  • actions/upload-artifact: v4 → v6"
echo "  • actions/download-artifact: v4 → v7"
echo "  • actions/setup-dotnet: v4 → v5"
echo "  • actions/cache: v4 → v5"
echo "  • softprops/action-gh-release: v1 → v2"
echo ""

mkdir -p .github/workflows

# =============================================================================
# CI Workflow - Runs on every push/PR (build + test only, no artifacts)
# =============================================================================
echo "Creating ci.yml..."

cat > .github/workflows/ci.yml << 'WORKFLOW'
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
  build-and-test:
    name: Build & Test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]

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
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Restore (Desktop only)
        run: |
          dotnet restore src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj
          dotnet restore src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj
          dotnet restore src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj
          dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
          dotnet restore tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj
          dotnet restore tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj
          dotnet restore tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj

      - name: Build
        run: |
          dotnet build src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj --no-restore --configuration Release

      - name: Test
        run: |
          dotnet test tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj --no-restore --configuration Release --verbosity normal
          dotnet test tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj --no-restore --configuration Release --verbosity normal
          dotnet test tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj --no-restore --configuration Release --verbosity normal
WORKFLOW

echo "✓ Created ci.yml"

# =============================================================================
# Build Workflow - Creates pre-release on every push to main branches
# =============================================================================
echo "Creating build.yml..."

cat > .github/workflows/build.yml << 'WORKFLOW'
name: Build

on:
  push:
    branches: [master, main, develop]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  # Desktop builds for all platforms
  build-desktop:
    name: Build Desktop (${{ matrix.rid }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: MyDesktopApplication-win-x64
          - os: windows-latest
            rid: win-arm64
            artifact: MyDesktopApplication-win-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: MyDesktopApplication-linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: MyDesktopApplication-linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: MyDesktopApplication-osx-x64
          - os: macos-latest
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
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            --output ./publish/${{ matrix.artifact }}

      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: ${{ matrix.artifact }}
          path: ./publish/${{ matrix.artifact }}
          retention-days: 7

  # Android build
  build-android:
    name: Build Android
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-

      - name: Build Android APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            --output ./publish/android

      - name: Upload Android artifact
        uses: actions/upload-artifact@v6
        with:
          name: MyDesktopApplication-android
          path: ./publish/android/*.apk
          retention-days: 7
          if-no-files-found: warn

  # Create pre-release with all artifacts
  pre-release:
    name: Create Pre-release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Download all artifacts
        uses: actions/download-artifact@v7
        with:
          path: ./artifacts
          merge-multiple: false

      - name: Create archives
        run: |
          mkdir -p ./release
          cd ./artifacts
          
          # Create zip for Windows
          for dir in MyDesktopApplication-win-*; do
            if [ -d "$dir" ]; then
              zip -r "../release/${dir}.zip" "$dir"
            fi
          done
          
          # Create tar.gz for Linux/macOS
          for dir in MyDesktopApplication-linux-* MyDesktopApplication-osx-*; do
            if [ -d "$dir" ]; then
              tar -czvf "../release/${dir}.tar.gz" "$dir"
            fi
          done
          
          # Copy Android APK
          if [ -d "MyDesktopApplication-android" ]; then
            cp MyDesktopApplication-android/*.apk ../release/ 2>/dev/null || true
          fi

      - name: Delete existing dev release
        run: |
          gh release delete dev --yes || true
          git push origin :refs/tags/dev || true
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Create dev pre-release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: dev
          name: Development Build
          prerelease: true
          files: ./release/*
          body: |
            ## 🚧 Development Build
            
            This is an automatically generated pre-release from the latest commit on `${{ github.ref_name }}`.
            
            **Commit:** ${{ github.sha }}
            **Date:** ${{ github.event.head_commit.timestamp }}
            
            ### Downloads
            - **Windows x64:** MyDesktopApplication-win-x64.zip
            - **Windows ARM64:** MyDesktopApplication-win-arm64.zip
            - **Linux x64:** MyDesktopApplication-linux-x64.tar.gz
            - **Linux ARM64:** MyDesktopApplication-linux-arm64.tar.gz
            - **macOS x64:** MyDesktopApplication-osx-x64.tar.gz
            - **macOS ARM64:** MyDesktopApplication-osx-arm64.tar.gz
            - **Android:** com.mycompany.mydesktopapplication.apk
            
            ⚠️ **This is a development build and may be unstable.**
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
WORKFLOW

echo "✓ Created build.yml"

# =============================================================================
# Release Workflow - Creates stable release on git tag
# =============================================================================
echo "Creating release.yml..."

cat > .github/workflows/release.yml << 'WORKFLOW'
name: Release

on:
  push:
    tags:
      - 'v*'

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  # Desktop builds for all platforms
  build-desktop:
    name: Build Desktop (${{ matrix.rid }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: MyDesktopApplication-win-x64
          - os: windows-latest
            rid: win-arm64
            artifact: MyDesktopApplication-win-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: MyDesktopApplication-linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: MyDesktopApplication-linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: MyDesktopApplication-osx-x64
          - os: macos-latest
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
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            --output ./publish/${{ matrix.artifact }}

      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: ${{ matrix.artifact }}
          path: ./publish/${{ matrix.artifact }}
          retention-days: 90

  # Android build
  build-android:
    name: Build Android
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-

      - name: Build Android APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            --output ./publish/android

      - name: Upload Android artifact
        uses: actions/upload-artifact@v6
        with:
          name: MyDesktopApplication-android
          path: ./publish/android/*.apk
          retention-days: 90
          if-no-files-found: warn

  # Create release with all artifacts
  release:
    name: Create Release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Download all artifacts
        uses: actions/download-artifact@v7
        with:
          path: ./artifacts
          merge-multiple: false

      - name: Create archives
        run: |
          mkdir -p ./release
          cd ./artifacts
          
          # Create zip for Windows
          for dir in MyDesktopApplication-win-*; do
            if [ -d "$dir" ]; then
              zip -r "../release/${dir}.zip" "$dir"
            fi
          done
          
          # Create tar.gz for Linux/macOS
          for dir in MyDesktopApplication-linux-* MyDesktopApplication-osx-*; do
            if [ -d "$dir" ]; then
              tar -czvf "../release/${dir}.tar.gz" "$dir"
            fi
          done
          
          # Copy Android APK
          if [ -d "MyDesktopApplication-android" ]; then
            cp MyDesktopApplication-android/*.apk ../release/ 2>/dev/null || true
          fi

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: ./release/*
          generate_release_notes: true
          body: |
            ## 📦 Release ${{ github.ref_name }}
            
            ### Downloads
            
            | Platform | Architecture | Download |
            |----------|--------------|----------|
            | Windows | x64 | MyDesktopApplication-win-x64.zip |
            | Windows | ARM64 | MyDesktopApplication-win-arm64.zip |
            | Linux | x64 | MyDesktopApplication-linux-x64.tar.gz |
            | Linux | ARM64 | MyDesktopApplication-linux-arm64.tar.gz |
            | macOS | x64 (Intel) | MyDesktopApplication-osx-x64.tar.gz |
            | macOS | ARM64 (Apple Silicon) | MyDesktopApplication-osx-arm64.tar.gz |
            | Android | APK | com.mycompany.mydesktopapplication.apk |
            
            ### Installation
            
            **Windows:** Extract the zip and run `MyDesktopApplication.Desktop.exe`
            
            **Linux:** Extract the tar.gz and run `./MyDesktopApplication.Desktop`
            
            **macOS:** Extract the tar.gz and run the application
            
            **Android:** Install the APK on your device
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
WORKFLOW

echo "✓ Created release.yml"

# =============================================================================
# Update dependabot.yml
# =============================================================================
echo "Updating dependabot.yml..."

cat > .github/dependabot.yml << 'DEPENDABOT'
version: 2
updates:
  # NuGet packages
  - package-ecosystem: "nuget"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    groups:
      avalonia:
        patterns:
          - "Avalonia*"
      testing:
        patterns:
          - "xunit*"
          - "NSubstitute*"
          - "Bogus*"
      ef-core:
        patterns:
          - "Microsoft.EntityFrameworkCore*"
          - "Npgsql*"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
DEPENDABOT

echo "✓ Updated dependabot.yml"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=============================================="
echo "  GitHub Actions Updated Successfully!"
echo "=============================================="
echo ""
echo "Action Version Summary:"
echo "  ┌────────────────────────────┬──────┬──────┐"
echo "  │ Action                     │ Old  │ New  │"
echo "  ├────────────────────────────┼──────┼──────┤"
echo "  │ actions/checkout           │ v4   │ v6   │"
echo "  │ actions/setup-dotnet       │ v4   │ v5   │"
echo "  │ actions/setup-java         │ v4   │ v5   │"
echo "  │ actions/cache              │ v4   │ v5   │"
echo "  │ actions/upload-artifact    │ v4   │ v6   │"
echo "  │ actions/download-artifact  │ v4   │ v7   │"
echo "  │ softprops/action-gh-release│ v1   │ v2   │"
echo "  └────────────────────────────┴──────┴──────┘"
echo ""
echo "Breaking Changes Addressed:"
echo "  • upload-artifact v6: Now uses Node.js 24"
echo "  • download-artifact v7: Now uses Node.js 24"
echo "  • download-artifact v4+: Artifacts are immutable, using pattern + merge-multiple"
echo "  • setup-java v5: Added 'distribution' parameter (using temurin)"
echo ""
echo "Workflow Behavior:"
echo "  • ci.yml: Runs on every push/PR (build + test only)"
echo "  • build.yml: Creates 'dev' pre-release on push to main branches"
echo "  • release.yml: Creates stable release on git tags (v*)"
echo ""
echo "To apply changes:"
echo "  git add .github/"
echo "  git commit -m 'Update GitHub Actions to latest versions'"
echo "  git push"

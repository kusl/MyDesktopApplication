#!/bin/bash

# This script fixes the Android keystore path issue in the GitHub Actions workflow.
# 
# Problem: The workflow creates android.keystore in the repository root, but the 
# Android build can't find it because:
# 1. The path in the build command is relative to where dotnet build runs
# 2. When building the entire solution, the working directory context changes
#
# Solution: Use an absolute path via $GITHUB_WORKSPACE and ensure the keystore
# is properly set up BEFORE the build step with correct path resolution.

set -e

WORKFLOW_FILE=".github/workflows/build-and-release.yml"

if [[ ! -f "$WORKFLOW_FILE" ]]; then
    echo "Error: $WORKFLOW_FILE not found"
    exit 1
fi

# Create backup
cp "$WORKFLOW_FILE" "${WORKFLOW_FILE}.backup"

# Write the complete corrected workflow file
cat > "$WORKFLOW_FILE" << 'WORKFLOW_EOF'
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

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Setup Keystore
        run: |
          # Create keystore from secret, or create a dummy one for PR builds
          if [[ -n "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" ]]; then
            echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > "$GITHUB_WORKSPACE/android.keystore"
            echo "KEYSTORE_PATH=$GITHUB_WORKSPACE/android.keystore" >> "$GITHUB_ENV"
            echo "SIGNING_PASSWORD=${{ secrets.ANDROID_SIGNING_PASSWORD }}" >> "$GITHUB_ENV"
          else
            # For PRs from forks or when secrets aren't available, create a dummy keystore
            keytool -genkey -v -keystore "$GITHUB_WORKSPACE/android.keystore" \
              -alias myalias -keyalg RSA -keysize 2048 -validity 1 \
              -storepass dummypassword -keypass dummypassword \
              -dname "CN=Dummy, OU=Dummy, O=Dummy, L=Dummy, ST=Dummy, C=US" \
              2>/dev/null || true
            echo "KEYSTORE_PATH=$GITHUB_WORKSPACE/android.keystore" >> "$GITHUB_ENV"
            echo "SIGNING_PASSWORD=dummypassword" >> "$GITHUB_ENV"
          fi
          echo "Keystore created at: $GITHUB_WORKSPACE/android.keystore"
          ls -la "$GITHUB_WORKSPACE/android.keystore"

      - name: Restore
        run: dotnet restore

      - name: Build
        run: |
          dotnet build --configuration Release --no-restore \
            -p:BuildNumber=${{ github.run_number }} \
            -p:AndroidKeyStore=true \
            -p:AndroidSigningKeyStore="${{ env.KEYSTORE_PATH }}" \
            -p:AndroidSigningStorePass="${{ env.SIGNING_PASSWORD }}" \
            -p:AndroidSigningKeyPass="${{ env.SIGNING_PASSWORD }}" \
            -p:AndroidSigningKeyAlias=myalias

      - name: Test
        run: dotnet test --configuration Release --no-build --verbosity normal

  # =============================================================================
  # Build Desktop Releases
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
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            -r ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -p:BuildNumber=${{ github.run_number }} \
            --output ./publish

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: ./publish/
          retention-days: 30

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

      - name: Setup Keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > "$GITHUB_WORKSPACE/android.keystore"
          echo "Keystore created at: $GITHUB_WORKSPACE/android.keystore"
          ls -la "$GITHUB_WORKSPACE/android.keystore"

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
        run: yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses || true

      - name: Build and Sign Android APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            -p:BuildNumber=${{ github.run_number }} \
            --output ./publish/android \
            -p:AndroidKeyStore=true \
            -p:AndroidSigningKeyStore="$GITHUB_WORKSPACE/android.keystore" \
            -p:AndroidSigningStorePass="${{ secrets.ANDROID_SIGNING_PASSWORD }}" \
            -p:AndroidSigningKeyPass="${{ secrets.ANDROID_SIGNING_PASSWORD }}" \
            -p:AndroidSigningKeyAlias=myalias

      - name: Find and rename APK
        run: |
          APK_PATH=$(find ./publish/android -name "*-Signed.apk" | head -1)
          if [[ -z "$APK_PATH" ]]; then
            APK_PATH=$(find ./publish/android -name "*.apk" | head -1)
          fi
          
          if [[ -n "$APK_PATH" ]]; then
            cp "$APK_PATH" "./publish/MyDesktopApplication-android-${{ github.run_number }}.apk"
            echo "APK renamed to: MyDesktopApplication-android-${{ github.run_number }}.apk"
          else
            echo "No APK found!"
            find ./publish -type f -name "*.apk" || echo "No APK files anywhere"
            exit 1
          fi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: android
          path: ./publish/MyDesktopApplication-android-${{ github.run_number }}.apk
          retention-days: 30

  # =============================================================================
  # Create Release
  # =============================================================================
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

      - name: List artifacts
        run: find ./artifacts -type f

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Release v1.0.${{ github.run_number }}
          draft: false
          prerelease: false
          files: |
            ./artifacts/**/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
WORKFLOW_EOF

echo "✓ Updated $WORKFLOW_FILE"
echo ""
echo "Key changes made:"
echo "  1. Using \$GITHUB_WORKSPACE for absolute keystore path"
echo "  2. Storing keystore path and password in GITHUB_ENV for use in build step"
echo "  3. Proper conditional handling for PR builds vs push builds"
echo ""
echo "Next steps:"
echo "  1. Verify your GitHub secrets are set:"
echo "     - ANDROID_KEYSTORE_BASE64"
echo "     - ANDROID_SIGNING_PASSWORD"
echo "  2. Commit and push this change"
echo "  3. The build should now find the keystore correctly"

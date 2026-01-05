#!/bin/bash
# =============================================================================
# Fix Android Signing for CI Unified Build
# =============================================================================
# 
# Problem:
# The Android project has AndroidKeyStore=True unconditionally, which causes
# the AndroidSignPackage task to require KeyPass even during plain `dotnet build`
# in the build-and-test CI job where no signing password is provided.
#
# Error: MSB4044: The "AndroidSignPackage" task was not given a value for 
#        the required parameter "KeyPass"
#
# Solution:
# Make signing conditional on whether AndroidSigningPassword is provided.
# This way:
# - build-and-test job: builds Android without signing (validates code compiles)
# - build-android job: passes password via -p:AndroidSigningPassword=..., 
#                      signing happens
#
# This maintains "One Team, One Build" - everyone runs the same dotnet build,
# but signing only happens when explicitly requested via the password parameter.
# =============================================================================

set -euo pipefail

echo "=============================================="
echo "  Fixing Android Signing Configuration"
echo "=============================================="
echo ""

CSPROJ="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"

# Verify we're in the project root
if [[ ! -f "$CSPROJ" ]]; then
    echo "ERROR: Cannot find $CSPROJ"
    echo "Please run this script from the repository root."
    exit 1
fi

# Backup the original file
cp "$CSPROJ" "${CSPROJ}.backup"
echo "Created backup: ${CSPROJ}.backup"

# Create the new csproj content with conditional signing
# The key change: AndroidKeyStore is only True when AndroidSigningPassword is provided
cat > "$CSPROJ" << 'CSPROJ_CONTENT'
<Project Sdk="Microsoft.NET.Sdk">
  <!-- =================================================================== -->
  <!-- SIGNING CONFIGURATION                                               -->
  <!-- Signing is ONLY enabled when AndroidSigningPassword is provided.    -->
  <!-- This allows:                                                        -->
  <!-- - CI build-and-test: validates code compiles without signing        -->
  <!-- - CI build-android: signs when password is passed                   -->
  <!-- - Local debug: uses hardcoded password for convenience              -->
  <!-- =================================================================== -->
  
  <!-- Debug builds: use hardcoded password for local development -->
  <PropertyGroup Condition="'$(Configuration)' == 'Debug'">
    <AndroidSigningPassword>android</AndroidSigningPassword>
  </PropertyGroup>
  
  <!-- Only enable signing when password is provided -->
  <PropertyGroup Condition="'$(AndroidSigningPassword)' != ''">
    <AndroidKeyStore>True</AndroidKeyStore>
    <AndroidSigningKeyStore>../../android.keystore</AndroidSigningKeyStore>
    <AndroidSigningKeyAlias>myalias</AndroidSigningKeyAlias>
    <AndroidSigningKeyPass>$(AndroidSigningPassword)</AndroidSigningKeyPass>
    <AndroidSigningStorePass>$(AndroidSigningPassword)</AndroidSigningStorePass>
  </PropertyGroup>
  
  <!-- Explicitly disable signing when no password provided -->
  <PropertyGroup Condition="'$(AndroidSigningPassword)' == ''">
    <AndroidKeyStore>False</AndroidKeyStore>
  </PropertyGroup>
  
  <!-- =================================================================== -->
  <!-- MAIN PROJECT CONFIGURATION                                          -->
  <!-- =================================================================== -->
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <OutputType>Exe</OutputType>
    <SupportedOSPlatformVersion>24</SupportedOSPlatformVersion>
    <ApplicationId>com.mydesktopapplication.app</ApplicationId>
    
    <!-- Dynamic versioning from CI -->
    <ApplicationVersion Condition="'$(BuildNumber)' == ''">1</ApplicationVersion>
    <ApplicationVersion Condition="'$(BuildNumber)' != ''">$(BuildNumber)</ApplicationVersion>
    <ApplicationDisplayVersion Condition="'$(BuildNumber)' == ''">1.0.0-local</ApplicationDisplayVersion>
    <ApplicationDisplayVersion Condition="'$(BuildNumber)' != ''">1.0.$(BuildNumber)</ApplicationDisplayVersion>
    
    <!-- =================================================================== -->
    <!-- CRITICAL FIX FOR MONO CLASS-INIT CRASH                             -->
    <!-- The crash "klass->instance_size == instance_size" happens when     -->
    <!-- there's a mismatch between AOT-compiled code and runtime.          -->
    <!-- Disabling AOT for Debug prevents this crash.                       -->
    <!-- =================================================================== -->
    <RunAOTCompilation Condition="'$(Configuration)' == 'Debug'">false</RunAOTCompilation>
    
    <!-- Disable aapt2 daemon to prevent CI hangs -->
    <AndroidUseAapt2Daemon>false</AndroidUseAapt2Daemon>
    
    <!-- Use AppCompat theme for Avalonia compatibility -->
    <AndroidEnableAppCompatTheme>true</AndroidEnableAppCompatTheme>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
  
  <ItemGroup>
    <PackageReference Include="Avalonia.Android" />
  </ItemGroup>
</Project>
CSPROJ_CONTENT

echo "Updated $CSPROJ with conditional signing configuration"
echo ""
echo "=============================================="
echo "  Changes Made"
echo "=============================================="
echo ""
echo "1. AndroidKeyStore is now CONDITIONAL:"
echo "   - True  ONLY when AndroidSigningPassword is provided"
echo "   - False when AndroidSigningPassword is empty/missing"
echo ""
echo "2. This means:"
echo "   - CI build-and-test: 'dotnet build' works WITHOUT signing"
echo "   - CI build-android:  'dotnet publish -p:AndroidSigningPassword=...' DOES sign"
echo "   - Local Debug:       Uses hardcoded 'android' password (for local testing)"
echo "   - Local Release:     Works unsigned unless you pass -p:AndroidSigningPassword=android"
echo ""
echo "=============================================="
echo "  Why This Is The Correct Fix"
echo "=============================================="
echo ""
echo "The error was:"
echo "  MSB4044: The 'AndroidSignPackage' task was not given a value for"
echo "           the required parameter 'KeyPass'"
echo ""
echo "This happened because:"
echo "  - AndroidKeyStore=True was set unconditionally"
echo "  - This forces MSBuild to run the signing task on every Release build"
echo "  - The build-and-test job runs 'dotnet build --configuration Release'"
echo "  - No keystore or password was provided -> FAILURE"
echo ""
echo "Now:"
echo "  - AndroidKeyStore=False by default (when no password provided)"
echo "  - Build completes successfully, producing unsigned APK"
echo "  - The build-android job passes -p:AndroidSigningPassword=..."
echo "  - This sets AndroidKeyStore=True and signing happens"
echo ""
echo "=============================================="
echo "  Verification Commands"
echo "=============================================="
echo ""
echo "Test locally:"
echo "  # This should work - no signing, matches CI build-and-test"
echo "  dotnet build --configuration Release"
echo ""
echo "  # This should work - with signing, matches CI build-android"
echo "  dotnet publish src/MyDesktopApplication.Android -c Release -p:AndroidSigningPassword=android"
echo ""
echo "  # Debug always works (uses hardcoded password)"
echo "  dotnet build --configuration Debug"
echo ""
echo "Backup saved to: ${CSPROJ}.backup"
echo "If issues arise, restore with: cp ${CSPROJ}.backup $CSPROJ"

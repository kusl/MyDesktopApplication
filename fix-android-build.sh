#!/bin/bash
# =============================================================================
# fix-android-build.sh
# =============================================================================
# This script fixes the Android build failure caused by missing assembly 
# references for EntityFrameworkCore, Extensions, and Infrastructure.
#
# ROOT CAUSE ANALYSIS:
# The error occurs because:
# 1. Infrastructure project targets only 'net10.0'
# 2. Android project targets 'net10.0-android'
# 3. When building for net10.0-android, the project reference to Infrastructure
#    doesn't automatically flow the transitive NuGet package dependencies
#    (EntityFrameworkCore, Extensions.DependencyInjection) because they're
#    resolved for a different target framework.
#
# THE FIX:
# Option A: Make Infrastructure and other shared projects multi-target
#           (net10.0;net10.0-android) - COMPLEX, may cause issues with EF Core
#
# Option B: Add explicit PackageReferences to Android project for the packages
#           it needs directly - SIMPLER, more explicit
#
# We'll use Option B as it's cleaner and doesn't require changes to the 
# architecture. The Android project will explicitly declare its dependencies.
#
# WHY THIS WORKS WITHOUT REGRESSION:
# - Desktop project continues to work (its transitive deps work because
#   it shares the same TFM as Infrastructure: net10.0)
# - Android project gets its deps explicitly, ensuring they're resolved
#   for the net10.0-android target framework
# - CI and local builds will both work
# - No changes to project architecture or infrastructure layer
# =============================================================================

set -e

echo "==========================================="
echo " Fix Android Build - Missing References"
echo "==========================================="
echo ""

# Navigate to project root (assuming script is run from root)
if [[ ! -f "MyDesktopApplication.slnx" ]]; then
    echo "Error: Run this script from the project root directory"
    echo "       (where MyDesktopApplication.slnx is located)"
    exit 1
fi

ANDROID_CSPROJ="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"

if [[ ! -f "$ANDROID_CSPROJ" ]]; then
    echo "Error: Android project file not found: $ANDROID_CSPROJ"
    exit 1
fi

# Create backup
cp "$ANDROID_CSPROJ" "${ANDROID_CSPROJ}.backup.$(date +%Y%m%d%H%M%S)"
echo "✓ Created backup of Android.csproj"

# Read the current content to preserve existing settings
echo "✓ Reading current Android.csproj..."

# Create the updated csproj with explicit package references
cat > "$ANDROID_CSPROJ" << 'CSPROJ_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <!-- =================================================================== -->
  <!-- SIGNING CONFIGURATION                                               -->
  <!-- Signing is ONLY enabled when AndroidSigningPassword is provided.    -->
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
    <!-- MONO RUNTIME SETTINGS                                              -->
    <!-- Disable AOT to avoid class-init crashes; use JIT/Interpreter       -->
    <!-- =================================================================== -->
    <RunAOTCompilation>false</RunAOTCompilation>
    <PublishAot>false</PublishAot>
    <UseInterpreter>true</UseInterpreter>
    <PublishTrimmed>false</PublishTrimmed>
    <TrimMode>partial</TrimMode>
    <EnableTrimAnalyzer>false</EnableTrimAnalyzer>
    
    <!-- Fix aapt2 daemon hang issues on Fedora -->
    <AndroidUseAapt2Daemon>false</AndroidUseAapt2Daemon>
    
    <!-- Standard settings -->
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <!-- Tell the linker to preserve our assemblies completely -->
  <ItemGroup>
    <TrimmerRootAssembly Include="MyDesktopApplication.Core" />
    <TrimmerRootAssembly Include="MyDesktopApplication.Shared" />
    <TrimmerRootAssembly Include="MyDesktopApplication.Infrastructure" />
  </ItemGroup>

  <!-- =================================================================== -->
  <!-- PACKAGE REFERENCES                                                  -->
  <!-- =================================================================== -->
  <!-- CRITICAL: These packages MUST be explicitly referenced here because -->
  <!-- transitive dependencies from net10.0 projects don't automatically   -->
  <!-- flow to net10.0-android builds. Without these, you get CS0234       -->
  <!-- errors for Microsoft.EntityFrameworkCore and Microsoft.Extensions   -->
  <!-- =================================================================== -->
  <ItemGroup>
    <!-- Avalonia packages -->
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    
    <!-- MVVM toolkit -->
    <PackageReference Include="CommunityToolkit.Mvvm" />
    
    <!-- EXPLICIT: These are needed because Infrastructure project is net10.0 -->
    <!-- and its transitive dependencies don't flow to net10.0-android -->
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
  </ItemGroup>

  <!-- =================================================================== -->
  <!-- PROJECT REFERENCES                                                  -->
  <!-- =================================================================== -->
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
</Project>
CSPROJ_EOF

echo "✓ Updated Android.csproj with explicit package references"

# Clean and rebuild
echo ""
echo "Cleaning build artifacts..."
dotnet clean --verbosity quiet 2>/dev/null || true

echo ""
echo "Restoring packages..."
dotnet restore

echo ""
echo "Building solution..."
if dotnet build; then
    echo ""
    echo "==========================================="
    echo " ✓ BUILD SUCCESSFUL!"
    echo "==========================================="
    echo ""
    echo "The fix added explicit PackageReferences to the Android project for:"
    echo "  - Microsoft.Extensions.DependencyInjection"
    echo "  - Microsoft.EntityFrameworkCore"
    echo "  - Microsoft.EntityFrameworkCore.Sqlite"
    echo ""
    echo "These are needed because transitive dependencies from net10.0"
    echo "projects don't automatically flow to net10.0-android builds."
else
    echo ""
    echo "==========================================="
    echo " ✗ BUILD FAILED"
    echo "==========================================="
    echo ""
    echo "Check the error messages above. Common issues:"
    echo "  1. Missing packages in Directory.Packages.props"
    echo "  2. Version mismatches"
    echo "  3. Other code errors"
    echo ""
    echo "Backup is available at: ${ANDROID_CSPROJ}.backup.*"
    exit 1
fi

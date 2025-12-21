#!/bin/bash
set -e

cd ~/src/dotnet/MyDesktopApplication

echo "Fixing Android theme configuration..."

# Update Android csproj to include Fluent theme package
cat > src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj << 'CSPROJ'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <SupportedOSPlatformVersion>21</SupportedOSPlatformVersion>
    <OutputType>Exe</OutputType>
    <ApplicationId>com.mycompany.mydesktopapplication</ApplicationId>
    <ApplicationVersion>1</ApplicationVersion>
    <ApplicationDisplayVersion>1.0</ApplicationDisplayVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    
    <!-- Workarounds for aapt2 hanging issues -->
    <AndroidUseAapt2>true</AndroidUseAapt2>
    <AndroidAapt2CompileExtraArgs>--no-crunch</AndroidAapt2CompileExtraArgs>
    <_Aapt2DaemonMaxInstanceCount>1</_Aapt2DaemonMaxInstanceCount>
    
    <!-- Use interpreted mode for faster dev builds -->
    <UseInterpreter Condition="'$(Configuration)' == 'Debug'">true</UseInterpreter>
    <RunAOTCompilation Condition="'$(Configuration)' == 'Debug'">false</RunAOTCompilation>
    <AndroidEnableProfiledAot>false</AndroidEnableProfiledAot>
    <AndroidLinkMode Condition="'$(Configuration)' == 'Debug'">None</AndroidLinkMode>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
</Project>
CSPROJ

echo "✓ Updated Android csproj with Avalonia.Themes.Fluent"

# Test build
echo ""
echo "Testing build..."
./build-android.sh

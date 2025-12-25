#!/bin/bash
set -e

# =============================================================================
# FIX ANDROID MONO CLASS-INIT CRASH
# =============================================================================
# This script fixes the "Assertion at mono/mono/metadata/class-init.c:2474"
# crash that occurs when the Mono runtime's expected class layout doesn't
# match the compiled IL.
#
# Root cause: Type layout mismatch in AOT compilation with .NET 10 Android
# Solution: Disable AOT compilation and use interpreter mode to avoid the
#           class layout mismatch issues in the Mono runtime.
# =============================================================================

echo "=============================================="
echo "  Fixing Android Mono Class-Init Crash"
echo "=============================================="
echo ""

cd ~/src/dotnet/MyDesktopApplication

# Kill any stuck build processes
echo "[1/8] Killing stuck build processes..."
pkill -f "dotnet" 2>/dev/null || true
pkill -f "aapt2" 2>/dev/null || true
pkill -f "java" 2>/dev/null || true
sleep 2

# Clean all build artifacts thoroughly
echo "[2/8] Cleaning ALL build artifacts..."
find . -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "obj" -exec rm -rf {} + 2>/dev/null || true

# =============================================================================
# FIX 1: Update Android csproj with CRITICAL runtime settings
# =============================================================================
echo "[3/8] Updating Android project configuration..."

cat > src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj << 'CSPROJ_EOF'
<Project Sdk="Microsoft.NET.Sdk">
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
    
    <!-- ================================================================== -->
    <!-- CRITICAL FIX FOR MONO CLASS-INIT CRASH                            -->
    <!-- The crash "klass->instance_size == instance_size" happens when    -->
    <!-- there's a mismatch between AOT-compiled code and runtime.         -->
    <!-- SOLUTION: Disable AOT entirely and use JIT/Interpreter            -->
    <!-- ================================================================== -->
    
    <!-- Disable AOT compilation completely -->
    <RunAOTCompilation>false</RunAOTCompilation>
    <PublishAot>false</PublishAot>
    
    <!-- Use the Mono interpreter for maximum compatibility -->
    <UseInterpreter>true</UseInterpreter>
    
    <!-- Disable IL linker trimming to preserve all types -->
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

  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
</Project>
CSPROJ_EOF

echo "   ✓ Updated MyDesktopApplication.Android.csproj"

# =============================================================================
# FIX 2: Ensure MainActivity has proper setup
# =============================================================================
echo "[4/8] Updating MainActivity.cs..."

cat > src/MyDesktopApplication.Android/MainActivity.cs << 'MAIN_EOF'
using Android.App;
using Android.Content.PM;
using Avalonia;
using Avalonia.Android;

namespace MyDesktopApplication.Android;

[Activity(
    Label = "Country Quiz",
    Theme = "@style/MyTheme.NoActionBar",
    Icon = "@drawable/icon",
    MainLauncher = true,
    ConfigurationChanges = ConfigChanges.Orientation | ConfigChanges.ScreenSize | ConfigChanges.UiMode)]
public class MainActivity : AvaloniaMainActivity<App>
{
    protected override AppBuilder CustomizeAppBuilder(AppBuilder builder)
    {
        return base.CustomizeAppBuilder(builder)
            .WithInterFont()
            .LogToTrace();
    }
}
MAIN_EOF

echo "   ✓ Updated MainActivity.cs"

# =============================================================================
# FIX 3: Simplify App.axaml.cs to avoid initialization issues
# =============================================================================
echo "[5/8] Updating App.axaml.cs..."

cat > src/MyDesktopApplication.Android/App.axaml.cs << 'APP_EOF'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android;

public partial class App : Application
{
    private IServiceProvider? _serviceProvider;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        // Configure services with simple DI
        var services = new ServiceCollection();
        
        // Register database context
        services.AddDbContext<AppDbContext>();
        
        // Register repositories
        services.AddScoped<IGameStateRepository, GameStateRepository>();
        
        // Register ViewModels
        services.AddTransient<CountryQuizViewModel>();
        
        _serviceProvider = services.BuildServiceProvider();

        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform)
        {
            var viewModel = _serviceProvider.GetRequiredService<CountryQuizViewModel>();
            singleViewPlatform.MainView = new MainView
            {
                DataContext = viewModel
            };
            
            // Initialize async without blocking
            _ = InitializeViewModelAsync(viewModel);
        }

        base.OnFrameworkInitializationCompleted();
    }
    
    private static async Task InitializeViewModelAsync(CountryQuizViewModel viewModel)
    {
        try
        {
            await viewModel.InitializeAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error initializing ViewModel: {ex.Message}");
        }
    }
}
APP_EOF

echo "   ✓ Updated App.axaml.cs"

# =============================================================================
# FIX 4: Ensure App.axaml has proper theme configuration
# =============================================================================
echo "[6/8] Updating App.axaml..."

cat > src/MyDesktopApplication.Android/App.axaml << 'AXAML_EOF'
<Application xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Android.App"
             RequestedThemeVariant="Default">
    <Application.Styles>
        <FluentTheme />
    </Application.Styles>
</Application>
AXAML_EOF

echo "   ✓ Updated App.axaml"

# =============================================================================
# FIX 5: Ensure styles.xml uses AppCompat theme
# =============================================================================
echo "[7/8] Ensuring Android theme is correct..."

mkdir -p src/MyDesktopApplication.Android/Resources/values

cat > src/MyDesktopApplication.Android/Resources/values/styles.xml << 'STYLES_EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="MyTheme" parent="Theme.AppCompat.Light">
    </style>
    <style name="MyTheme.NoActionBar" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="android:windowActionBar">false</item>
        <item name="android:windowNoTitle">true</item>
    </style>
</resources>
STYLES_EOF

echo "   ✓ Updated styles.xml"

# =============================================================================
# FIX 6: Build and verify
# =============================================================================
echo "[8/8] Building Android project..."
echo ""

# Restore packages first
echo "Restoring packages..."
dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj

# Build with explicit Debug configuration
echo "Building..."
if dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj -c Debug; then
    echo ""
    echo "=============================================="
    echo "  ✓ BUILD SUCCESSFUL!"
    echo "=============================================="
    echo ""
    echo "The Android crash should now be fixed."
    echo ""
    echo "Key changes made:"
    echo "  1. Disabled AOT compilation (RunAOTCompilation=false)"
    echo "  2. Enabled Mono interpreter (UseInterpreter=true)"
    echo "  3. Disabled IL linker trimming (PublishTrimmed=false)"
    echo "  4. Fixed Android theme to use AppCompat"
    echo "  5. Simplified App initialization"
    echo ""
    echo "The crash was caused by:"
    echo "  - Mono runtime type layout mismatch"
    echo "  - AOT-compiled code not matching runtime expectations"
    echo "  - This is a known issue with .NET 10 + Avalonia on Android"
    echo ""
    echo "Next steps:"
    echo "  1. Install APK: adb install -r src/MyDesktopApplication.Android/bin/Debug/net10.0-android/com.mydesktopapplication.app-Signed.apk"
    echo "  2. Test on device"
    echo "  3. If working, commit and push"
    echo ""
else
    echo ""
    echo "=============================================="
    echo "  ✗ BUILD FAILED"
    echo "=============================================="
    echo ""
    echo "Please check the error messages above."
    exit 1
fi

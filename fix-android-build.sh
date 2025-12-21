#!/bin/bash
set -e

# Fix Android Build Issues for MyDesktopApplication
# This script addresses the aapt2 hanging issue and sets up proper build configuration

cd ~/src/dotnet/MyDesktopApplication

echo "=============================================="
echo "  Fixing Android Build Configuration"
echo "=============================================="

# Step 1: Kill any stuck processes
echo ""
echo "Step 1: Cleaning up stuck processes..."
pkill -f aapt2 2>/dev/null || true
pkill -f VBCSCompiler 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
echo "✓ Processes cleaned"

# Step 2: Clean build artifacts
echo ""
echo "Step 2: Cleaning build artifacts..."
rm -rf bin obj
rm -rf src/*/bin src/*/obj
rm -rf tests/*/bin tests/*/obj
echo "✓ Build artifacts cleaned"

# Step 3: Update Directory.Build.props to exclude Android from default build
echo ""
echo "Step 3: Updating Directory.Build.props..."

cat > Directory.Build.props << 'PROPS'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <AnalysisLevel>latest</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>

  <!-- Company/Project metadata -->
  <PropertyGroup>
    <Authors>Your Name</Authors>
    <Company>Your Company</Company>
    <Product>MyDesktopApplication</Product>
    <Copyright>Copyright © 2025</Copyright>
  </PropertyGroup>
</Project>
PROPS

echo "✓ Directory.Build.props updated"

# Step 4: Update the solution to NOT include Android by default
echo ""
echo "Step 4: Checking solution configuration..."

# Create a desktop-only solution if it doesn't exist
if [ ! -f "MyDesktopApplication.Desktop.slnx" ]; then
    cat > MyDesktopApplication.Desktop.slnx << 'SLNX'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <Project Path="src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
    <Project Path="src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
    <Project Path="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" />
  </Folder>
</Solution>
SLNX
    echo "✓ Created desktop-only solution: MyDesktopApplication.Desktop.slnx"
fi

# Step 5: Update Android csproj with workarounds for aapt2 issues
echo ""
echo "Step 5: Updating Android project configuration..."

mkdir -p src/MyDesktopApplication.Android

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
    
    <!-- Reduce parallelism to avoid aapt2 daemon deadlocks -->
    <_Aapt2DaemonMaxInstanceCount>1</_Aapt2DaemonMaxInstanceCount>
    
    <!-- Use interpreted mode for faster dev builds -->
    <UseInterpreter Condition="'$(Configuration)' == 'Debug'">true</UseInterpreter>
    <RunAOTCompilation Condition="'$(Configuration)' == 'Debug'">false</RunAOTCompilation>
    
    <!-- Faster incremental builds -->
    <AndroidEnableProfiledAot>false</AndroidEnableProfiledAot>
    <AndroidLinkMode Condition="'$(Configuration)' == 'Debug'">None</AndroidLinkMode>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Avalonia.Android" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
</Project>
CSPROJ

echo "✓ Android csproj updated with aapt2 workarounds"

# Step 6: Create/update Android source files
echo ""
echo "Step 6: Creating Android source files..."

# MainActivity.cs
cat > src/MyDesktopApplication.Android/MainActivity.cs << 'CS'
using Android.App;
using Android.Content.PM;
using Avalonia;
using Avalonia.Android;

namespace MyDesktopApplication.Android;

[Activity(
    Label = "MyDesktopApplication",
    Theme = "@style/MyTheme.NoActionBar",
    Icon = "@drawable/icon",
    MainLauncher = true,
    ConfigurationChanges = ConfigChanges.Orientation | ConfigChanges.ScreenSize | ConfigChanges.UiMode)]
public class MainActivity : AvaloniaMainActivity<App>
{
    protected override AppBuilder CustomizeAppBuilder(AppBuilder builder)
    {
        return base.CustomizeAppBuilder(builder)
            .WithInterFont();
    }
}
CS

# App.cs
cat > src/MyDesktopApplication.Android/App.cs << 'CS'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using MyDesktopApplication.Android.Views;

namespace MyDesktopApplication.Android;

public class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform)
        {
            singleViewPlatform.MainView = new MainView();
        }

        base.OnFrameworkInitializationCompleted();
    }
}
CS

# App.axaml
cat > src/MyDesktopApplication.Android/App.axaml << 'AXAML'
<Application xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Android.App">
    <Application.Styles>
        <FluentTheme />
    </Application.Styles>
</Application>
AXAML

# Create Views directory
mkdir -p src/MyDesktopApplication.Android/Views

# MainView.axaml
cat > src/MyDesktopApplication.Android/Views/MainView.axaml << 'AXAML'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Android.Views.MainView">
    <StackPanel Margin="20" Spacing="20" VerticalAlignment="Center">
        <TextBlock Text="MyDesktopApplication"
                   FontSize="28"
                   FontWeight="Bold"
                   HorizontalAlignment="Center" />
        
        <TextBlock Text="Running on Android!"
                   FontSize="18"
                   HorizontalAlignment="Center"
                   Foreground="Gray" />
        
        <Button x:Name="CounterButton"
                Content="Click Me: 0"
                HorizontalAlignment="Center"
                Padding="20,10"
                Click="OnCounterClick" />
    </StackPanel>
</UserControl>
AXAML

# MainView.axaml.cs
cat > src/MyDesktopApplication.Android/Views/MainView.axaml.cs << 'CS'
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    private int _counter;
    private Button? _counterButton;

    public MainView()
    {
        InitializeComponent();
        _counterButton = this.FindControl<Button>("CounterButton");
    }

    private void InitializeComponent()
    {
        AvaloniaXamlLoader.Load(this);
    }

    private void OnCounterClick(object? sender, RoutedEventArgs e)
    {
        _counter++;
        if (_counterButton != null)
        {
            _counterButton.Content = $"Click Me: {_counter}";
        }
    }
}
CS

echo "✓ Android source files created"

# Step 7: Create Android resources
echo ""
echo "Step 7: Creating Android resources..."

mkdir -p src/MyDesktopApplication.Android/Resources/values
mkdir -p src/MyDesktopApplication.Android/Resources/drawable

# strings.xml
cat > src/MyDesktopApplication.Android/Resources/values/strings.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MyDesktopApplication</string>
</resources>
XML

# styles.xml
cat > src/MyDesktopApplication.Android/Resources/values/styles.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="MyTheme" parent="@android:style/Theme.Material.Light.DarkActionBar">
    </style>
    <style name="MyTheme.NoActionBar" parent="@android:style/Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@android:color/background_light</item>
    </style>
</resources>
XML

# Simple icon (placeholder - vector drawable)
cat > src/MyDesktopApplication.Android/Resources/drawable/icon.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#3F51B5"
        android:pathData="M0,0h108v108h-108z"/>
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M54,27 L81,81 L27,81 Z"/>
</vector>
XML

# AndroidManifest.xml
cat > src/MyDesktopApplication.Android/AndroidManifest.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application 
        android:allowBackup="true" 
        android:icon="@drawable/icon" 
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/MyTheme.NoActionBar">
    </application>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.INTERNET" />
</manifest>
XML

echo "✓ Android resources created"

# Step 8: Create helper scripts
echo ""
echo "Step 8: Creating helper scripts..."

# Script to build Android only
cat > build-android.sh << 'SCRIPT'
#!/bin/bash
set -e

echo "Building Android project..."
echo ""

# Kill any stuck aapt2 processes first
pkill -f aapt2 2>/dev/null || true

# Source Android environment
[ -f ~/.android-env.sh ] && source ~/.android-env.sh

# Build with single-threaded aapt2 to avoid deadlocks
dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
    -p:_Aapt2DaemonMaxInstanceCount=1 \
    -p:AndroidAapt2CompileExtraArgs="--no-crunch" \
    -v minimal \
    "$@"

echo ""
echo "✓ Android build complete!"
SCRIPT
chmod +x build-android.sh

# Script to build desktop only (fast)
cat > build-desktop.sh << 'SCRIPT'
#!/bin/bash
set -e
dotnet build MyDesktopApplication.Desktop.slnx "$@"
SCRIPT
chmod +x build-desktop.sh

# Script to run all tests
cat > run-tests.sh << 'SCRIPT'
#!/bin/bash
set -e
dotnet test MyDesktopApplication.Desktop.slnx "$@"
SCRIPT
chmod +x run-tests.sh

echo "✓ Helper scripts created"

# Step 9: Test desktop build
echo ""
echo "Step 9: Testing desktop build..."
if dotnet build MyDesktopApplication.Desktop.slnx -v quiet; then
    echo "✓ Desktop build succeeded!"
else
    echo "✗ Desktop build failed"
    exit 1
fi

# Step 10: Test tests
echo ""
echo "Step 10: Running tests..."
if dotnet test MyDesktopApplication.Desktop.slnx --no-build -v quiet; then
    echo "✓ All tests passed!"
else
    echo "✗ Some tests failed"
fi

echo ""
echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "Quick commands:"
echo "  ./build-desktop.sh    - Build desktop projects (fast)"
echo "  ./build-android.sh    - Build Android project"
echo "  ./run-tests.sh        - Run all tests"
echo "  dotnet run --project src/MyDesktopApplication.Desktop"
echo ""
echo "The Android build now uses:"
echo "  - Single-threaded aapt2 (avoids daemon deadlocks)"
echo "  - --no-crunch flag (faster resource compilation)"
echo "  - Interpreted mode for debug builds (faster startup)"
echo ""
echo "If Android still hangs, try:"
echo "  pkill -f aapt2 && ./build-android.sh"
echo ""

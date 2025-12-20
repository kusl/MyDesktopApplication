#!/bin/bash
set -e

echo "=============================================="
echo "  Fixing Android Project Code"
echo "=============================================="
echo ""

# Fix MainActivity.cs
echo "Fixing MainActivity.cs..."
cat > src/MyDesktopApplication.Android/MainActivity.cs << 'EOF'
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
EOF
echo "✓ MainActivity.cs fixed"

# Fix App.cs
echo "Fixing App.cs..."
cat > src/MyDesktopApplication.Android/App.cs << 'EOF'
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
        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewLifetime)
        {
            singleViewLifetime.MainView = new MainView();
        }

        base.OnFrameworkInitializationCompleted();
    }
}
EOF
echo "✓ App.cs fixed"

# Fix App.axaml
echo "Fixing App.axaml..."
cat > src/MyDesktopApplication.Android/App.axaml << 'EOF'
<Application xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Android.App">
    <Application.Styles>
        <FluentTheme />
    </Application.Styles>
</Application>
EOF
echo "✓ App.axaml fixed"

# Fix MainView.axaml
echo "Fixing MainView.axaml..."
cat > src/MyDesktopApplication.Android/Views/MainView.axaml << 'EOF'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Android.Views.MainView">
    
    <StackPanel Margin="20" Spacing="20" VerticalAlignment="Center">
        <TextBlock Text="Welcome to Avalonia on Android!"
                   FontSize="24"
                   FontWeight="Bold"
                   HorizontalAlignment="Center" />
        
        <TextBlock Text="This is a cross-platform .NET application."
                   FontSize="16"
                   HorizontalAlignment="Center"
                   TextWrapping="Wrap" />
        
        <Button Content="Click Me!"
                HorizontalAlignment="Center"
                Padding="20,10"
                Click="OnButtonClick" />
        
        <TextBlock x:Name="CounterText"
                   Text="Counter: 0"
                   FontSize="18"
                   HorizontalAlignment="Center" />
    </StackPanel>
</UserControl>
EOF
echo "✓ MainView.axaml fixed"

# Fix MainView.axaml.cs
echo "Fixing MainView.axaml.cs..."
cat > src/MyDesktopApplication.Android/Views/MainView.axaml.cs << 'EOF'
using Avalonia.Controls;
using Avalonia.Interactivity;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    private int _counter = 0;

    public MainView()
    {
        InitializeComponent();
    }

    private void OnButtonClick(object? sender, RoutedEventArgs e)
    {
        _counter++;
        CounterText.Text = $"Counter: {_counter}";
    }
}
EOF
echo "✓ MainView.axaml.cs fixed"

# Ensure the csproj has correct references
echo "Updating MyDesktopApplication.Android.csproj..."
cat > src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <SupportedOSPlatformVersion>21</SupportedOSPlatformVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <ApplicationId>com.mydesktopapplication.android</ApplicationId>
    <ApplicationVersion>1</ApplicationVersion>
    <ApplicationDisplayVersion>1.0</ApplicationDisplayVersion>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
</Project>
EOF
echo "✓ csproj fixed"

# Create drawable folder and icon if it doesn't exist
echo "Setting up Android resources..."
mkdir -p src/MyDesktopApplication.Android/Resources/drawable

# Create a simple icon placeholder if it doesn't exist
if [ ! -f "src/MyDesktopApplication.Android/Resources/drawable/icon.png" ]; then
    # Create a minimal valid PNG (1x1 blue pixel)
    echo -n -e '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' > src/MyDesktopApplication.Android/Resources/drawable/icon.png
    echo "✓ Created placeholder icon"
fi

# Ensure styles.xml exists
cat > src/MyDesktopApplication.Android/Resources/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="MyTheme" parent="@android:style/Theme.Material.Light.DarkActionBar">
    </style>
    <style name="MyTheme.NoActionBar" parent="@android:style/Theme.Material.Light.NoActionBar">
        <item name="android:windowActionBar">false</item>
        <item name="android:windowNoTitle">true</item>
    </style>
</resources>
EOF
echo "✓ styles.xml updated"

# Ensure strings.xml exists
cat > src/MyDesktopApplication.Android/Resources/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MyDesktopApplication</string>
</resources>
EOF
echo "✓ strings.xml updated"

# Ensure AndroidManifest.xml is correct
cat > src/MyDesktopApplication.Android/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:icon="@drawable/icon"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/MyTheme.NoActionBar">
    </application>
    <uses-permission android:name="android.permission.INTERNET" />
</manifest>
EOF
echo "✓ AndroidManifest.xml updated"

echo ""
echo "=============================================="
echo "  Testing Build"
echo "=============================================="
echo ""

# Source environment if available
if [ -f "$HOME/.android-env.sh" ]; then
    source "$HOME/.android-env.sh"
fi

# Try to build
echo "Building Android project..."
if dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj 2>&1; then
    echo ""
    echo "✓ Android build successful!"
else
    echo ""
    echo "! Build had issues - check output above"
fi

echo ""
echo "=============================================="
echo "  Done!"
echo "=============================================="

#!/bin/bash
set -e

cd ~/src/dotnet/MyDesktopApplication

echo "Fixing MainActivity.cs..."

# Fix MainActivity.cs - remove WithInterFont() call
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
            .LogToTrace();
    }
}
CS

echo "✓ Fixed MainActivity.cs"

# Test build
echo ""
echo "Testing build..."
./build-android.sh

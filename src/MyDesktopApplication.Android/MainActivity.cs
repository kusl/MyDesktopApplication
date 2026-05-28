using Android.Content.PM;
using Avalonia.Android;

namespace MyDesktopApplication.Android;

[Activity(
    Label = "Country Quiz",
    Theme = "@style/MyTheme.NoActionBar",
    Icon = "@drawable/icon",
    MainLauncher = true,
    ConfigurationChanges = ConfigChanges.Orientation | ConfigChanges.ScreenSize | ConfigChanges.UiMode)]
public class MainActivity : AvaloniaMainActivity
{
}

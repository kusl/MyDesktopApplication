#!/bin/bash
set -e

cd ~/src/dotnet/MyDesktopApplication

echo "Fixing Android namespace conflicts..."

# Fix App.cs - use fully qualified Avalonia.Application
cat > src/MyDesktopApplication.Android/App.cs << 'CS'
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using MyDesktopApplication.Android.Views;

namespace MyDesktopApplication.Android;

public class App : Avalonia.Application
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

echo "✓ Fixed App.cs"

# Fix MainView.axaml.cs - use fully qualified Avalonia.Controls.Button
cat > src/MyDesktopApplication.Android/Views/MainView.axaml.cs << 'CS'
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    private int _counter;
    private Avalonia.Controls.Button? _counterButton;

    public MainView()
    {
        InitializeComponent();
        _counterButton = this.FindControl<Avalonia.Controls.Button>("CounterButton");
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

echo "✓ Fixed MainView.axaml.cs"

# Test build
echo ""
echo "Testing build..."
./build-android.sh

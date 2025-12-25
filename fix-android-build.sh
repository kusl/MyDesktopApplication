#!/bin/bash
# Fix Android build errors by removing duplicate App.cs and fixing namespace conflicts
# Run from: ~/src/dotnet/MyDesktopApplication

set -e
cd "$(dirname "$0")"

echo "=== Fixing Android Build Errors ==="
echo ""

# Error 1: CS0260 - Duplicate App class (App.cs and App.axaml.cs both define App)
# Solution: Delete App.cs since App.axaml.cs is the proper code-behind for App.axaml
echo "1. Removing duplicate App.cs file..."
if [ -f "src/MyDesktopApplication.Android/App.cs" ]; then
    rm -f "src/MyDesktopApplication.Android/App.cs"
    echo "   ✓ Deleted App.cs (App.axaml.cs is the correct code-behind)"
else
    echo "   ✓ App.cs already removed"
fi

# Error 2: CS0104 - Ambiguous 'Application' reference
# Solution: Use fully qualified Avalonia.Application in App.axaml.cs
echo ""
echo "2. Fixing App.axaml.cs with fully qualified names..."
cat > "src/MyDesktopApplication.Android/App.axaml.cs" << 'EOF'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.ViewModels;
using MyDesktopApplication.Android.Views;

namespace MyDesktopApplication.Android;

// Use fully qualified Avalonia.Application to avoid conflict with Android.App.Application
public partial class App : Avalonia.Application
{
    private ServiceProvider? _serviceProvider;
    
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override async void OnFrameworkInitializationCompleted()
    {
        // Set up dependency injection
        var services = new ServiceCollection();
        
        // Get the Android-specific data directory for SQLite
        var dataDir = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);
        var dbPath = System.IO.Path.Combine(dataDir, "mydesktopapp.db");
        
        services.AddInfrastructure(dbPath);
        services.AddTransient<CountryQuizViewModel>();
        
        _serviceProvider = services.BuildServiceProvider();

        // Ensure database is created
        await _serviceProvider.EnsureDatabaseCreatedAsync();

        if (ApplicationLifetime is ISingleViewApplicationLifetime singleView)
        {
            var vm = _serviceProvider.GetRequiredService<CountryQuizViewModel>();
            await vm.InitializeAsync();
            
            singleView.MainView = new MainView
            {
                DataContext = vm
            };
        }

        base.OnFrameworkInitializationCompleted();
    }
}
EOF
echo "   ✓ Fixed App.axaml.cs"

# Fix 3: Fix MainView.axaml.cs - use fully qualified Button type
echo ""
echo "3. Fixing MainView.axaml.cs with fully qualified names..."
cat > "src/MyDesktopApplication.Android/Views/MainView.axaml.cs" << 'EOF'
using Avalonia.Controls;
using Avalonia.Interactivity;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
    }

    // Use fully qualified Avalonia.Controls.Button to avoid conflict with Android.Widget.Button
    private void OnCountry1Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.SelectCountry1Command.Execute(null);
        }
    }

    private void OnCountry2Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.SelectCountry2Command.Execute(null);
        }
    }

    private void OnNextQuestionClick(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.NextQuestionCommand.Execute(null);
        }
    }
}
EOF
echo "   ✓ Fixed MainView.axaml.cs"

# Clean and rebuild
echo ""
echo "4. Cleaning build artifacts..."
dotnet clean --verbosity quiet 2>/dev/null || true

echo ""
echo "5. Building solution..."
dotnet build

echo ""
echo "=== Fix Complete ==="

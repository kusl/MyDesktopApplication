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

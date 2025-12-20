using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Data.Core.Plugins;
using Avalonia.Markup.Xaml;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Desktop.ViewModels;
using MyDesktopApplication.Desktop.Views;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Infrastructure.Data;
using System;
using System.Linq;

namespace MyDesktopApplication.Desktop;

public partial class App : Application
{
    public static IServiceProvider? Services { get; private set; }

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            // Avoid duplicate validations from both Avalonia and CommunityToolkit
            DisableAvaloniaDataAnnotationValidation();

            // Setup dependency injection
            var services = new ServiceCollection();
            ConfigureServices(services);
            Services = services.BuildServiceProvider();

            // Initialize database
            InitializeDatabase();

            // Create main window
            var mainViewModel = Services.GetRequiredService<MainWindowViewModel>();
            desktop.MainWindow = new MainWindow
            {
                DataContext = mainViewModel
            };
        }

        base.OnFrameworkInitializationCompleted();
    }

    private static void ConfigureServices(IServiceCollection services)
    {
        // Add infrastructure (database, repositories)
        services.AddInfrastructure();

        // Add ViewModels
        services.AddTransient<MainWindowViewModel>();
        services.AddTransient<HomeViewModel>();
        services.AddTransient<SettingsViewModel>();
    }

    private static void InitializeDatabase()
    {
        using var scope = Services!.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        context.Database.EnsureCreated();
    }

    private static void DisableAvaloniaDataAnnotationValidation()
    {
        var toRemove = BindingPlugins.DataValidators
            .OfType<DataAnnotationsValidationPlugin>()
            .ToArray();

        foreach (var plugin in toRemove)
        {
            BindingPlugins.DataValidators.Remove(plugin);
        }
    }
}

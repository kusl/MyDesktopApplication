using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android;

public partial class App : Avalonia.Application
{
    public static IServiceProvider? Services { get; private set; }

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        // Set up dependency injection (runs once for the application).
        var services = new ServiceCollection();

        // Get the Android-specific database path.
        var dbPath = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "countryquiz.db");

        // Register DbContext.
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlite($"Data Source={dbPath}"));

        // Register repositories.
        services.AddScoped<IGameStateRepository, GameStateRepository>();

        // Register ViewModels.
        services.AddTransient<CountryQuizViewModel>();

        var serviceProvider = services.BuildServiceProvider();
        Services = serviceProvider;

        // Initialize the database synchronously here so the view factory
        // (which Android may call multiple times) never races on schema creation.
        using (var scope = serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            dbContext.Database.EnsureCreated();
        }

        // Avalonia 12: Android uses IActivityApplicationLifetime with a
        // MainViewFactory (Func<Control>) instead of a single MainView instance,
        // because the activity can be created more than once during the app lifetime.
        if (ApplicationLifetime is IActivityApplicationLifetime activityLifetime)
        {
            activityLifetime.MainViewFactory = CreateMainView;
        }

        base.OnFrameworkInitializationCompleted();
    }

    private static Control CreateMainView()
    {
        var viewModel = Services!.GetRequiredService<CountryQuizViewModel>();

        var view = new MainView
        {
            DataContext = viewModel
        };

        // Kick off async view-model initialization without blocking the UI thread.
        // Avalonia marshals the continuation back appropriately for bound properties.
        _ = viewModel.InitializeAsync();

        return view;
    }
}

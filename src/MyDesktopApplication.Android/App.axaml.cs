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

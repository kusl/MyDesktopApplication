using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Observability;
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
        var dbPath = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "countryquiz.db");

        var services = new ServiceCollection();
        services.AddInfrastructure(dbPath);
        services.AddObservability();
        services.AddTransient<CountryQuizViewModel>();

        var serviceProvider = services.BuildServiceProvider();
        Services = serviceProvider;
        serviceProvider.StartObservability();

        using (var scope = serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            dbContext.Database.EnsureCreated();
        }

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

        _ = viewModel.InitializeAsync();

        return view;
    }
}

using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android;

public class App : Avalonia.Application
{
    private IServiceProvider? _services;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override async void OnFrameworkInitializationCompleted()
    {
        var services = new ServiceCollection();

        var dbPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "countryquiz.db");

        services.AddInfrastructure(dbPath);
        services.AddTransient<CountryQuizViewModel>();

        _services = services.BuildServiceProvider();

        await DependencyInjection.InitializeDatabaseAsync(_services);

        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewLifetime)
        {
            var vm = _services.GetRequiredService<CountryQuizViewModel>();
            var mainView = new MainView { DataContext = vm };
            singleViewLifetime.MainView = mainView;

            _ = vm.InitializeAsync();
        }

        base.OnFrameworkInitializationCompleted();
    }
}

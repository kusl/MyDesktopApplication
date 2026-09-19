using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Desktop.Views;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Desktop;

public partial class App : Avalonia.Application
{
    private IServiceProvider? _services;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override async void OnFrameworkInitializationCompleted()
    {
        var services = new ServiceCollection();
        services.AddInfrastructure();
        services.AddTransient<CountryQuizViewModel>();

        _services = services.BuildServiceProvider();

        await DependencyInjection.InitializeDatabaseAsync(_services);

        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            var vm = _services.GetRequiredService<CountryQuizViewModel>();
            desktop.MainWindow = new MainWindow { DataContext = vm };
        }

        base.OnFrameworkInitializationCompleted();
    }
}

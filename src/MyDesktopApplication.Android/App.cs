using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Data.Core.Plugins;
using Avalonia.Markup.Xaml;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Shared.ViewModels;
using System.Linq;

namespace MyDesktopApplication.Android;

public partial class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform)
        {
            // Disable Avalonia's data annotation validation to avoid conflicts
            var toRemove = BindingPlugins.DataValidators
                .OfType<DataAnnotationsValidationPlugin>()
                .ToArray();
            foreach (var plugin in toRemove)
            {
                BindingPlugins.DataValidators.Remove(plugin);
            }

            singleViewPlatform.MainView = new MainView
            {
                DataContext = new MainViewModel()
            };
        }

        base.OnFrameworkInitializationCompleted();
    }
}

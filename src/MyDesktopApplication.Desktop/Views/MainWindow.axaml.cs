using Avalonia.Controls;
using Avalonia.Interactivity;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        AddHandler(Button.ClickEvent, OnButtonClick, RoutingStrategies.Bubble);

        Loaded += async (_, _) =>
        {
            if (DataContext is CountryQuizViewModel vm)
            {
                await vm.InitializeAsync();
            }
        };
    }

    private void OnButtonClick(object? sender, RoutedEventArgs e)
        => (DataContext as CountryQuizViewModel)?.OnButtonPressed();
}

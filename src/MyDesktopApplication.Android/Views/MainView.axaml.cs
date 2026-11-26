using Avalonia.Controls;
using Avalonia.Interactivity;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
        AddHandler(Avalonia.Controls.Button.ClickEvent, OnButtonClick, RoutingStrategies.Bubble);
    }

    private void OnButtonClick(object? sender, RoutedEventArgs e)
        => (DataContext as CountryQuizViewModel)?.OnButtonPressed();
}

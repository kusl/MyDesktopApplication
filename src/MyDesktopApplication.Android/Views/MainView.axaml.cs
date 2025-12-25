using Avalonia.Controls;
using Avalonia.Interactivity;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
    }

    // Use fully qualified Avalonia.Controls.Button to avoid conflict with Android.Widget.Button
    private void OnCountry1Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.SelectCountry1Command.Execute(null);
        }
    }

    private void OnCountry2Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.SelectCountry2Command.Execute(null);
        }
    }

    private void OnNextQuestionClick(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.NextQuestionCommand.Execute(null);
        }
    }
}

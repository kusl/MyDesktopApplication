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

    private void OnCountry1Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            // SelectCountryCommand takes a string parameter ("1" or "2")
            vm.SelectCountryCommand.Execute("1");
        }
    }

    private void OnCountry2Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.SelectCountryCommand.Execute("2");
        }
    }

    private void OnNextClick(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            // The command is NextRoundCommand, not NextQuestionCommand
            vm.NextRoundCommand.Execute(null);
        }
    }
}

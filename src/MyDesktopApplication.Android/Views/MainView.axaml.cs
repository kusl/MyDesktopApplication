using Avalonia.Controls;
using Avalonia.Interactivity;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    private int _counter = 0;

    public MainView()
    {
        InitializeComponent();
    }

    private void OnButtonClick(object? sender, RoutedEventArgs e)
    {
        _counter++;
        CounterText.Text = $"Counter: {_counter}";
    }
}

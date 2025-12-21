using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    private int _counter;
    private Avalonia.Controls.Button? _counterButton;

    public MainView()
    {
        InitializeComponent();
        _counterButton = this.FindControl<Avalonia.Controls.Button>("CounterButton");
    }

    private void InitializeComponent()
    {
        AvaloniaXamlLoader.Load(this);
    }

    private void OnCounterClick(object? sender, RoutedEventArgs e)
    {
        _counter++;
        if (_counterButton != null)
        {
            _counterButton.Content = $"Click Me: {_counter}";
        }
    }
}

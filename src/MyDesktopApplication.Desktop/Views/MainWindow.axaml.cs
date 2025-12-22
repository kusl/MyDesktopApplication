using Avalonia.Controls;

namespace MyDesktopApplication.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        // Initialize the ViewModel when the window loads
        Loaded += async (_, _) =>
        {
            if (DataContext is ViewModels.MainWindowViewModel vm)
            {
                await vm.InitializeAsync();
            }
        };
    }
}

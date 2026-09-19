using Avalonia.Controls;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        // Initialize the ViewModel when the window loads
        Loaded += async (_, _) =>
        {
            if (DataContext is CountryQuizViewModel vm)
            {
                await vm.InitializeAsync();
            }
        };
    }
}

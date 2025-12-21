using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Desktop.ViewModels;

public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
}

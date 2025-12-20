using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// Base class for all ViewModels
/// </summary>
public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;

    [ObservableProperty]
    private string? _errorMessage;

    protected void ClearError() => ErrorMessage = null;
    protected void SetError(string message) => ErrorMessage = message;
}

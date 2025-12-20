using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Base class for all ViewModels - shared between Desktop and Android
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

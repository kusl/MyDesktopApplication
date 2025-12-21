using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
    
    /// <summary>
    /// Clears any error message.
    /// </summary>
    protected void ClearError()
    {
        ErrorMessage = null;
    }
    
    /// <summary>
    /// Sets an error message.
    /// </summary>
    protected void SetError(string message)
    {
        ErrorMessage = message;
    }
    
    /// <summary>
    /// Sets error from an exception.
    /// </summary>
    protected void SetError(Exception ex)
    {
        ErrorMessage = ex.Message;
    }
    
    /// <summary>
    /// Returns true if there's an error message.
    /// </summary>
    public bool HasError => !string.IsNullOrEmpty(ErrorMessage);
}

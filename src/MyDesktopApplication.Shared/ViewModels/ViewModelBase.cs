using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Base class for all ViewModels with common functionality
/// </summary>
public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
    
    [ObservableProperty]
    private bool _hasError;
    
    /// <summary>
    /// Clears any error state
    /// </summary>
    protected void ClearError()
    {
        ErrorMessage = null;
        HasError = false;
    }
    
    /// <summary>
    /// Sets an error message
    /// </summary>
    protected void SetError(string message)
    {
        ErrorMessage = message;
        HasError = true;
    }
    
    /// <summary>
    /// Executes an async operation with busy state management
    /// </summary>
    protected async Task ExecuteBusyAsync(Func<Task> operation)
    {
        if (IsBusy) return;
        
        try
        {
            IsBusy = true;
            ClearError();
            await operation();
        }
        catch (Exception ex)
        {
            SetError(ex.Message);
        }
        finally
        {
            IsBusy = false;
        }
    }
}

using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Base class for all ViewModels providing common functionality
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
    /// Sets an error message and marks HasError as true
    /// </summary>
    protected void SetError(string message)
    {
        ErrorMessage = message;
        HasError = true;
    }
    
    /// <summary>
    /// Clears any error state
    /// </summary>
    protected void ClearError()
    {
        ErrorMessage = null;
        HasError = false;
    }
    
    /// <summary>
    /// Executes an action with busy indicator and error handling
    /// </summary>
    protected async Task ExecuteAsync(Func<Task> action, string? errorContext = null)
    {
        if (IsBusy) return;
        
        try
        {
            IsBusy = true;
            ClearError();
            await action();
        }
        catch (Exception ex)
        {
            var context = errorContext ?? "An error occurred";
            SetError($"{context}: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }
    
    /// <summary>
    /// Executes a function with busy indicator and error handling
    /// </summary>
    protected async Task<T?> ExecuteAsync<T>(Func<Task<T>> action, string? errorContext = null)
    {
        if (IsBusy) return default;
        
        try
        {
            IsBusy = true;
            ClearError();
            return await action();
        }
        catch (Exception ex)
        {
            var context = errorContext ?? "An error occurred";
            SetError($"{context}: {ex.Message}");
            return default;
        }
        finally
        {
            IsBusy = false;
        }
    }
}

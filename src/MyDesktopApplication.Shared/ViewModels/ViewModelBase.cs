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
    /// Clears the error message and marks HasError as false
    /// </summary>
    protected void ClearError()
    {
        ErrorMessage = null;
        HasError = false;
    }

    /// <summary>
    /// Executes an async operation with busy state management and error handling
    /// </summary>
    protected async Task ExecuteAsync(Func<Task> operation, string? errorContext = null)
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
            SetError(errorContext != null
                ? $"{errorContext}: {ex.Message}"
                : ex.Message);
        }
        finally
        {
            IsBusy = false;
        }
    }

    /// <summary>
    /// Executes an async operation that returns a result
    /// </summary>
    protected async Task<T?> ExecuteAsync<T>(Func<Task<T>> operation, string? errorContext = null)
    {
        if (IsBusy) return default;

        try
        {
            IsBusy = true;
            ClearError();
            return await operation();
        }
        catch (Exception ex)
        {
            SetError(errorContext != null
                ? $"{errorContext}: {ex.Message}"
                : ex.Message);
            return default;
        }
        finally
        {
            IsBusy = false;
        }
    }
}

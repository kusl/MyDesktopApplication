using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Main ViewModel shared between Desktop and Android
/// </summary>
public partial class MainViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _greeting = "Welcome to Avalonia!";

    [ObservableProperty]
    private int _counter;

    [ObservableProperty]
    private ObservableCollection<TodoItem> _todoItems = [];

    [ObservableProperty]
    private string _newTodoTitle = string.Empty;

    [RelayCommand]
    private void IncrementCounter()
    {
        Counter++;
        Greeting = Counter switch
        {
            1 => "You clicked once!",
            < 5 => $"You clicked {Counter} times",
            < 10 => $"Wow, {Counter} clicks! Keep going!",
            _ => $"Amazing! {Counter} clicks!"
        };
    }

    [RelayCommand]
    private async Task LoadDataAsync()
    {
        IsBusy = true;
        ClearError();
        try
        {
            // Simulate loading
            await Task.Delay(1000);
        }
        catch (System.Exception ex)
        {
            SetError($"Failed to load: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private void AddTodo()
    {
        if (string.IsNullOrWhiteSpace(NewTodoTitle))
            return;

        var todo = new TodoItem { Title = NewTodoTitle.Trim() };
        TodoItems.Add(todo);
        NewTodoTitle = string.Empty;
    }

    [RelayCommand]
    private void ToggleTodo(TodoItem? todo)
    {
        if (todo is null)
            return;

        if (todo.IsCompleted)
            todo.MarkIncomplete();
        else
            todo.MarkComplete();
    }
}

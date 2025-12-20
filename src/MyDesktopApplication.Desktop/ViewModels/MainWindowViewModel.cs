using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// Desktop MainWindow ViewModel - extends shared MainViewModel with desktop-specific features
/// </summary>
public partial class MainWindowViewModel : ViewModelBase
{
    private readonly ITodoRepository? _todoRepository;

    [ObservableProperty]
    private string _greeting = "Welcome to Avalonia with .NET 10!";

    [ObservableProperty]
    private int _counter;

    [ObservableProperty]
    private ViewModelBase? _currentPage;

    [ObservableProperty]
    private ObservableCollection<TodoItem> _todoItems = [];

    [ObservableProperty]
    private string _newTodoTitle = string.Empty;

    // Constructor with DI (for runtime)
    public MainWindowViewModel(ITodoRepository todoRepository)
    {
        _todoRepository = todoRepository;
        _ = LoadTodosAsync();
    }

    // Parameterless constructor (for design-time and testing)
    public MainWindowViewModel()
    {
        _todoRepository = null;
    }

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
        try
        {
            await LoadTodosAsync();
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private async Task AddTodoAsync()
    {
        if (string.IsNullOrWhiteSpace(NewTodoTitle))
            return;

        var todo = new TodoItem { Title = NewTodoTitle.Trim() };
        
        if (_todoRepository is not null)
            await _todoRepository.AddAsync(todo);
        
        TodoItems.Add(todo);
        NewTodoTitle = string.Empty;
    }

    [RelayCommand]
    private async Task ToggleTodoAsync(TodoItem? todo)
    {
        if (todo is null)
            return;

        if (todo.IsCompleted)
            todo.MarkIncomplete();
        else
            todo.MarkComplete();

        if (_todoRepository is not null)
            await _todoRepository.UpdateAsync(todo);
    }

    [RelayCommand]
    private void NavigateToHome()
    {
        CurrentPage = new HomeViewModel();
    }

    [RelayCommand]
    private void NavigateToSettings()
    {
        CurrentPage = new SettingsViewModel();
    }

    private async Task LoadTodosAsync()
    {
        if (_todoRepository is null) return;
        
        var todos = await _todoRepository.GetAllAsync();
        TodoItems = new ObservableCollection<TodoItem>(todos);
    }
}

public partial class HomeViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _title = "Home";

    [ObservableProperty]
    private string _message = "Welcome to the home page!";
}

public partial class SettingsViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _title = "Settings";

    [ObservableProperty]
    private bool _darkMode;

    [ObservableProperty]
    private string _version = "1.0.0";
}

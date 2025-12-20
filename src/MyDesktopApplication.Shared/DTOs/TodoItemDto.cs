using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.DTOs;

/// <summary>
/// Data transfer object for TodoItem, used in ViewModels
/// </summary>
public partial class TodoItemDto : ObservableObject
{
    public Guid Id { get; set; }

    [ObservableProperty]
    private string _title = string.Empty;

    [ObservableProperty]
    private string? _description;

    [ObservableProperty]
    private bool _isCompleted;

    [ObservableProperty]
    private DateTime? _dueDate;

    [ObservableProperty]
    private int _priority;

    public bool IsOverdue => DueDate.HasValue && DueDate.Value < DateTime.UtcNow && !IsCompleted;
}

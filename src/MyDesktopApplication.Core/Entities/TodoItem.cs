namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a todo item in the application
/// </summary>
public class TodoItem : EntityBase
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? DueDate { get; set; }
    public Priority Priority { get; set; } = Priority.Normal;

    /// <summary>
    /// Marks the todo item as completed
    /// </summary>
    public void MarkComplete()
    {
        IsCompleted = true;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Marks the todo item as incomplete
    /// </summary>
    public void MarkIncomplete()
    {
        IsCompleted = false;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Returns true if the item is past its due date and not completed
    /// </summary>
    public bool IsOverdue => DueDate.HasValue && DueDate.Value < DateTime.UtcNow && !IsCompleted;
}

public enum Priority
{
    Low = 0,
    Normal = 1,
    High = 2,
    Critical = 3
}

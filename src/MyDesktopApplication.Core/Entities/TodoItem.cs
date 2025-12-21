namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a todo item in the application
/// </summary>
public class TodoItem : EntityBase
{
    public required string Title { get; set; }
    public string? Description { get; set; }
    public int Priority { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? DueDate { get; set; }
    
    /// <summary>
    /// Marks the todo item as complete
    /// </summary>
    public void MarkComplete()
    {
        IsCompleted = true;
        CompletedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// Marks the todo item as incomplete
    /// </summary>
    public void MarkIncomplete()
    {
        IsCompleted = false;
        CompletedAt = null;
    }
}

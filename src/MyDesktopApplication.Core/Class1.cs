namespace MyDesktopApplication.Core;

/// <summary>
/// Sample entity - replace with your domain entities
/// </summary>
public class TodoItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public void MarkComplete() => IsCompleted = true;
    public void MarkIncomplete() => IsCompleted = false;
}

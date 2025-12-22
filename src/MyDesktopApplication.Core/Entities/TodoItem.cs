namespace MyDesktopApplication.Core.Entities;

public class TodoItem : EntityBase
{
    public required string Title { get; set; }
    public string? Description { get; set; }
    public int Priority { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? DueDate { get; set; }
    
    public void MarkComplete()
    {
        IsCompleted = true;
        CompletedAt = DateTime.UtcNow;
    }
    
    public void MarkIncomplete()
    {
        IsCompleted = false;
        CompletedAt = null;
    }
}

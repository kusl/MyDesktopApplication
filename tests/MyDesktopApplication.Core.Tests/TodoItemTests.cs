using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

/// <summary>
/// Unit tests for TodoItem entity using plain xUnit assertions.
/// No FluentAssertions - it requires payment for commercial use.
/// </summary>
public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_ShouldHaveDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem();

        // Assert using plain xUnit
        Assert.NotEqual(Guid.Empty, todo.Id);
        Assert.Equal(string.Empty, todo.Title);
        Assert.False(todo.IsCompleted);
        Assert.Equal(Priority.Normal, todo.Priority);
        Assert.Null(todo.Description);
        Assert.Null(todo.DueDate);
        
        // Check timestamp is recent (within 1 second)
        var timeDiff = DateTime.UtcNow - todo.CreatedAt;
        Assert.True(timeDiff.TotalSeconds < 1, "CreatedAt should be recent");
    }

    [Fact]
    public void MarkComplete_ShouldSetIsCompletedToTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };
        Assert.False(todo.IsCompleted);

        // Act
        todo.MarkComplete();

        // Assert
        Assert.True(todo.IsCompleted);
    }

    [Fact]
    public void MarkComplete_ShouldUpdateTimestamp()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test" };
        var originalUpdatedAt = todo.UpdatedAt;
        
        // Small delay to ensure timestamp changes
        System.Threading.Thread.Sleep(10);

        // Act
        todo.MarkComplete();

        // Assert
        Assert.True(todo.UpdatedAt >= originalUpdatedAt);
    }

    [Fact]
    public void MarkIncomplete_ShouldSetIsCompletedToFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test", IsCompleted = true };
        Assert.True(todo.IsCompleted);

        // Act
        todo.MarkIncomplete();

        // Assert
        Assert.False(todo.IsCompleted);
    }

    [Fact]
    public void IsOverdue_WhenPastDueDateAndNotCompleted_ShouldReturnTrue()
    {
        // Arrange
        var todo = new TodoItem
        {
            Title = "Overdue",
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = false
        };

        // Assert
        Assert.True(todo.IsOverdue);
    }

    [Fact]
    public void IsOverdue_WhenFutureDueDate_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem
        {
            Title = "Future",
            DueDate = DateTime.UtcNow.AddDays(1),
            IsCompleted = false
        };

        // Assert
        Assert.False(todo.IsOverdue);
    }

    [Fact]
    public void IsOverdue_WhenCompleted_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem
        {
            Title = "Done",
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = true
        };

        // Assert
        Assert.False(todo.IsOverdue);
    }

    [Fact]
    public void IsOverdue_WhenNoDueDate_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "No deadline", DueDate = null };

        // Assert
        Assert.False(todo.IsOverdue);
    }

    [Theory]
    [InlineData(Priority.Low)]
    [InlineData(Priority.Normal)]
    [InlineData(Priority.High)]
    [InlineData(Priority.Critical)]
    public void Priority_ShouldAcceptAllValues(Priority priority)
    {
        // Arrange & Act
        var todo = new TodoItem { Title = "Test", Priority = priority };

        // Assert
        Assert.Equal(priority, todo.Priority);
    }

    [Fact]
    public void Title_ShouldBeSettable()
    {
        // Arrange
        var todo = new TodoItem();

        // Act
        todo.Title = "My Task";

        // Assert
        Assert.Equal("My Task", todo.Title);
    }

    [Fact]
    public void Description_ShouldBeSettable()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test" };

        // Act
        todo.Description = "This is a description";

        // Assert
        Assert.Equal("This is a description", todo.Description);
    }
}

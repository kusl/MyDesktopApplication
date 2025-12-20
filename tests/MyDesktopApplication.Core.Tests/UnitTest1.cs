using FluentAssertions;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_ShouldHaveDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem();

        // Assert
        todo.Id.Should().NotBeEmpty();
        todo.Title.Should().BeEmpty();
        todo.IsCompleted.Should().BeFalse();
        todo.Priority.Should().Be(Priority.Normal);
        todo.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void MarkComplete_ShouldSetIsCompletedToTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        todo.MarkComplete();

        // Assert
        todo.IsCompleted.Should().BeTrue();
        todo.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void MarkIncomplete_ShouldSetIsCompletedToFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test", IsCompleted = true };

        // Act
        todo.MarkIncomplete();

        // Assert
        todo.IsCompleted.Should().BeFalse();
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
        todo.IsOverdue.Should().BeTrue();
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
        todo.IsOverdue.Should().BeFalse();
    }

    [Fact]
    public void IsOverdue_WhenNoDueDate_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "No deadline" };

        // Assert
        todo.IsOverdue.Should().BeFalse();
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
        todo.Priority.Should().Be(priority);
    }
}

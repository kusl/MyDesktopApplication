using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void MarkComplete_SetsIsCompletedTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };
        
        // Act
        todo.MarkComplete();
        
        // Assert
        todo.IsCompleted.ShouldBeTrue();
        todo.CompletedAt.ShouldNotBeNull();
    }
    
    [Fact]
    public void MarkIncomplete_SetsIsCompletedFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };
        todo.MarkComplete();
        
        // Act
        todo.MarkIncomplete();
        
        // Assert
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }
    
    [Fact]
    public void NewTodoItem_HasDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem { Title = "Test" };
        
        // Assert
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
        todo.Priority.ShouldBe(0);
        todo.DueDate.ShouldBeNull();
    }
}

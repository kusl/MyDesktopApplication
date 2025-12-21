using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_HasDefaultValues()
    {
        var todo = new TodoItem { Title = "Test" };
        
        todo.Title.ShouldBe("Test");
        todo.IsCompleted.ShouldBeFalse();
        todo.Priority.ShouldBe(0);
        todo.Id.ShouldNotBe(Guid.Empty);
    }
    
    [Fact]
    public void MarkComplete_SetsIsCompletedTrue()
    {
        var todo = new TodoItem { Title = "Test" };
        
        todo.MarkComplete();
        
        todo.IsCompleted.ShouldBeTrue();
        todo.CompletedAt.ShouldNotBeNull();
    }
    
    [Fact]
    public void MarkIncomplete_SetsIsCompletedFalse()
    {
        var todo = new TodoItem { Title = "Test", IsCompleted = true };
        
        todo.MarkIncomplete();
        
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }
}

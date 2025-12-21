using Xunit;
using Shouldly;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void TodoItem_ShouldInitialize_WithDefaults()
    {
        var item = new TodoItem { Title = "Test" };
        
        item.Id.ShouldNotBe(Guid.Empty);
        item.Title.ShouldBe("Test");
        item.IsCompleted.ShouldBeFalse();
        item.CompletedAt.ShouldBeNull();
        item.Priority.ShouldBe(0);
    }

    [Fact]
    public void MarkComplete_ShouldSetIsCompletedAndCompletedAt()
    {
        var item = new TodoItem { Title = "Test" };
        
        item.MarkComplete();
        
        item.IsCompleted.ShouldBeTrue();
        item.CompletedAt.ShouldNotBeNull();
    }

    [Fact]
    public void MarkIncomplete_ShouldClearIsCompletedAndCompletedAt()
    {
        var item = new TodoItem { Title = "Test" };
        item.MarkComplete();
        
        item.MarkIncomplete();
        
        item.IsCompleted.ShouldBeFalse();
        item.CompletedAt.ShouldBeNull();
    }

    [Fact]
    public void Priority_ShouldBeSettable()
    {
        var item = new TodoItem { Title = "Test", Priority = 5 };
        
        item.Priority.ShouldBe(5);
    }
}

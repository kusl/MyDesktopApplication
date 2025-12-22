using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_ShouldBeIncomplete()
    {
        var todo = new TodoItem { Title = "Test" };

        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }

    [Fact]
    public void MarkComplete_ShouldSetCompletedAtAndIsCompleted()
    {
        var todo = new TodoItem { Title = "Test" };

        todo.MarkComplete();

        todo.IsCompleted.ShouldBeTrue();
        todo.CompletedAt.ShouldNotBeNull();
    }

    [Fact]
    public void MarkIncomplete_ShouldClearCompletedAt()
    {
        var todo = new TodoItem { Title = "Test" };
        todo.MarkComplete();

        todo.MarkIncomplete();

        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }
}

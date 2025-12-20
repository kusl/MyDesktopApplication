namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void MarkComplete_SetsIsCompletedToTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test" };
        
        // Act
        todo.MarkComplete();
        
        // Assert
        Assert.True(todo.IsCompleted);
    }

    [Fact]
    public void NewTodoItem_HasDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem();
        
        // Assert
        Assert.NotEqual(Guid.Empty, todo.Id);
        Assert.False(todo.IsCompleted);
        Assert.Equal(string.Empty, todo.Title);
    }
}

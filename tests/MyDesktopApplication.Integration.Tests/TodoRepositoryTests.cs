using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

namespace MyDesktopApplication.Integration.Tests;

/// <summary>
/// Integration tests for TodoRepository using SQLite in-memory database.
/// SQLite in-memory is more realistic than EF InMemory provider.
/// </summary>
public class TodoRepositoryTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AppDbContext _context;
    private readonly TodoRepository _repository;

    public TodoRepositoryTests()
    {
        // SQLite in-memory requires the connection to stay open
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new AppDbContext(options);
        _context.Database.EnsureCreated();
        
        _repository = new TodoRepository(_context);
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task AddAsync_ShouldPersistTodo()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        var result = await _repository.AddAsync(todo);

        // Assert
        Assert.NotEqual(Guid.Empty, result.Id);
        
        var saved = await _repository.GetByIdAsync(result.Id);
        Assert.NotNull(saved);
        Assert.Equal("Test Todo", saved.Title);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        // Act
        var result = await _repository.GetByIdAsync(Guid.NewGuid());

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnAllTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Todo 1" });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2" });
        await _repository.AddAsync(new TodoItem { Title = "Todo 3" });

        // Act
        var result = await _repository.GetAllAsync();

        // Assert
        Assert.Equal(3, result.Count);
    }

    [Fact]
    public async Task GetCompletedAsync_ShouldReturnOnlyCompletedTodos()
    {
        // Arrange
        var completed = new TodoItem { Title = "Done", IsCompleted = true };
        var pending = new TodoItem { Title = "Pending", IsCompleted = false };
        await _repository.AddAsync(completed);
        await _repository.AddAsync(pending);

        // Act
        var result = await _repository.GetCompletedAsync();

        // Assert
        Assert.Single(result);
        Assert.Equal("Done", result[0].Title);
    }

    [Fact]
    public async Task GetPendingAsync_ShouldReturnOnlyPendingTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Done", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Pending 1", IsCompleted = false });
        await _repository.AddAsync(new TodoItem { Title = "Pending 2", IsCompleted = false });

        // Act
        var result = await _repository.GetPendingAsync();

        // Assert
        Assert.Equal(2, result.Count);
        Assert.All(result, todo => Assert.False(todo.IsCompleted));
    }

    [Fact]
    public async Task GetOverdueAsync_ShouldReturnOverdueTodos()
    {
        // Arrange
        var overdue = new TodoItem 
        { 
            Title = "Overdue", 
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = false 
        };
        var future = new TodoItem 
        { 
            Title = "Future", 
            DueDate = DateTime.UtcNow.AddDays(1),
            IsCompleted = false 
        };
        var completedOverdue = new TodoItem 
        { 
            Title = "Done", 
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = true 
        };
        
        await _repository.AddAsync(overdue);
        await _repository.AddAsync(future);
        await _repository.AddAsync(completedOverdue);

        // Act
        var result = await _repository.GetOverdueAsync();

        // Assert
        Assert.Single(result);
        Assert.Equal("Overdue", result[0].Title);
    }

    [Fact]
    public async Task UpdateAsync_ShouldModifyExistingTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "Original" });
        todo.Title = "Updated";

        // Act
        await _repository.UpdateAsync(todo);

        // Assert - get fresh from database
        var updated = await _repository.GetByIdAsync(todo.Id);
        Assert.NotNull(updated);
        Assert.Equal("Updated", updated.Title);
    }

    [Fact]
    public async Task DeleteAsync_ShouldRemoveTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "To Delete" });
        var id = todo.Id;

        // Act
        await _repository.DeleteAsync(todo);

        // Assert
        var deleted = await _repository.GetByIdAsync(id);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task ExistsAsync_WhenExists_ShouldReturnTrue()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "Exists" });

        // Act
        var exists = await _repository.ExistsAsync(todo.Id);

        // Assert
        Assert.True(exists);
    }

    [Fact]
    public async Task ExistsAsync_WhenNotExists_ShouldReturnFalse()
    {
        // Act
        var exists = await _repository.ExistsAsync(Guid.NewGuid());

        // Assert
        Assert.False(exists);
    }
}

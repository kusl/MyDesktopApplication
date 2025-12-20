using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

namespace MyDesktopApplication.Integration.Tests;

public class TodoRepositoryTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly TodoRepository _repository;

    public TodoRepositoryTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _repository = new TodoRepository(_context);
    }

    public void Dispose()
    {
        _context.Dispose();
    }

    [Fact]
    public async Task AddAsync_ShouldPersistTodo()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        var result = await _repository.AddAsync(todo);

        // Assert
        result.Id.Should().NotBeEmpty();
        var saved = await _repository.GetByIdAsync(result.Id);
        saved.Should().NotBeNull();
        saved!.Title.Should().Be("Test Todo");
    }

    [Fact]
    public async Task GetCompletedAsync_ShouldReturnOnlyCompletedTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Done", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Pending", IsCompleted = false });

        // Act
        var completed = await _repository.GetCompletedAsync();

        // Assert
        completed.Should().HaveCount(1);
        completed[0].Title.Should().Be("Done");
    }

    [Fact]
    public async Task GetPendingAsync_ShouldReturnOnlyPendingTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Done", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Pending", IsCompleted = false });

        // Act
        var pending = await _repository.GetPendingAsync();

        // Assert
        pending.Should().HaveCount(1);
        pending[0].Title.Should().Be("Pending");
    }

    [Fact]
    public async Task UpdateAsync_ShouldModifyExistingTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "Original" });
        todo.Title = "Updated";

        // Act
        await _repository.UpdateAsync(todo);

        // Assert
        var updated = await _repository.GetByIdAsync(todo.Id);
        updated!.Title.Should().Be("Updated");
    }

    [Fact]
    public async Task DeleteAsync_ShouldRemoveTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "To Delete" });

        // Act
        await _repository.DeleteAsync(todo);

        // Assert
        var deleted = await _repository.GetByIdAsync(todo.Id);
        deleted.Should().BeNull();
    }
}

using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;
using Shouldly;
using Xunit;

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

    [Fact]
    public async Task AddAsync_ShouldAddTodoItem()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        await _repository.AddAsync(todo);
        var items = await _repository.GetAllAsync();

        // Assert
        items.ShouldContain(t => t.Title == "Test Todo");
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnAllItems()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Todo 1" });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2" });

        // Act
        var items = await _repository.GetAllAsync();

        // Assert
        items.Count().ShouldBe(2);
    }

    [Fact]
    public async Task GetIncompleteAsync_ShouldReturnOnlyIncomplete()
    {
        // Arrange
        var complete = new TodoItem { Title = "Complete" };
        complete.MarkComplete();
        await _repository.AddAsync(complete);
        await _repository.AddAsync(new TodoItem { Title = "Incomplete" });

        // Act
        var items = await _repository.GetIncompleteAsync();

        // Assert
        items.Count().ShouldBe(1);
        items.First().Title.ShouldBe("Incomplete");
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}

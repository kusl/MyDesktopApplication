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
    
    public void Dispose()
    {
        _context.Dispose();
    }
    
    [Fact]
    public async Task AddAsync_AddsTodoItem()
    {
        var todo = new TodoItem { Title = "Test Todo" };
        
        var result = await _repository.AddAsync(todo);
        
        result.ShouldNotBeNull();
        result.Id.ShouldNotBe(Guid.Empty);
        result.Title.ShouldBe("Test Todo");
    }
    
    [Fact]
    public async Task GetCompletedAsync_ReturnsOnlyCompletedItems()
    {
        await _repository.AddAsync(new TodoItem { Title = "Todo 1", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2", IsCompleted = false });
        await _repository.AddAsync(new TodoItem { Title = "Todo 3", IsCompleted = true });
        
        var completed = await _repository.GetCompletedAsync();
        
        completed.Count.ShouldBe(2);
        completed.All(t => t.IsCompleted).ShouldBeTrue();
    }
    
    [Fact]
    public async Task GetIncompleteAsync_ReturnsOnlyIncompleteItems()
    {
        await _repository.AddAsync(new TodoItem { Title = "Todo 1", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2", IsCompleted = false });
        await _repository.AddAsync(new TodoItem { Title = "Todo 3", IsCompleted = false });
        
        var incomplete = await _repository.GetIncompleteAsync();
        
        incomplete.Count.ShouldBe(2);
        incomplete.All(t => !t.IsCompleted).ShouldBeTrue();
    }
}

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
    public async Task AddAsync_SavesTodoItem()
    {
        var todo = new TodoItem { Title = "Test Todo" };
        
        await _repository.AddAsync(todo);
        await _context.SaveChangesAsync();
        
        var saved = await _context.TodoItems.FirstOrDefaultAsync();
        saved.ShouldNotBeNull();
        saved.Title.ShouldBe("Test Todo");
    }
    
    [Fact]
    public async Task GetByIdAsync_ReturnsCorrectItem()
    {
        var todo = new TodoItem { Title = "Find Me" };
        _context.TodoItems.Add(todo);
        await _context.SaveChangesAsync();
        
        var found = await _repository.GetByIdAsync(todo.Id);
        
        found.ShouldNotBeNull();
        found.Title.ShouldBe("Find Me");
    }
    
    [Fact]
    public async Task GetAllAsync_ReturnsAllItems()
    {
        _context.TodoItems.AddRange(
            new TodoItem { Title = "Todo 1" },
            new TodoItem { Title = "Todo 2" },
            new TodoItem { Title = "Todo 3" }
        );
        await _context.SaveChangesAsync();
        
        var all = await _repository.GetAllAsync();
        
        all.Count().ShouldBe(3);
    }
    
    public void Dispose()
    {
        _context.Dispose();
    }
}

using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

/// <summary>
/// TodoItem-specific repository implementation
/// </summary>
public class TodoRepository : Repository<TodoItem>, ITodoRepository
{
    public TodoRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<TodoItem>> GetCompletedAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => t.IsCompleted)
            .OrderByDescending(t => t.UpdatedAt)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<TodoItem>> GetPendingAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => !t.IsCompleted)
            .OrderBy(t => t.DueDate)
            .ThenByDescending(t => t.Priority)
            .ToListAsync(ct);

    /// <summary>
    /// Gets all incomplete (not completed) todo items - alias for GetPendingAsync
    /// </summary>
    public async Task<IReadOnlyList<TodoItem>> GetIncompleteAsync(CancellationToken ct = default)
        => await GetPendingAsync(ct);

    public async Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => !t.IsCompleted && t.DueDate != null && t.DueDate < DateTime.UtcNow)
            .OrderBy(t => t.DueDate)
            .ToListAsync(ct);
}

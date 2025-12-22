using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// TodoItem-specific repository interface
/// </summary>
public interface ITodoRepository : IRepository<TodoItem>
{
    Task<IReadOnlyList<TodoItem>> GetCompletedAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetPendingAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetIncompleteAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default);
}

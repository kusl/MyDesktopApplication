using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// Repository interface specific to TodoItems
/// </summary>
public interface ITodoRepository : IRepository<TodoItem>
{
    Task<IReadOnlyList<TodoItem>> GetCompletedAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetPendingAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default);
}

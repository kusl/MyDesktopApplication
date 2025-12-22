using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// Repository interface for GameState entities.
/// Inherits from IRepository to get UpdateAsync and other base methods.
/// </summary>
public interface IGameStateRepository : IRepository<GameState>
{
    Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default);
    Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default);
    Task ResetAsync(string userId, CancellationToken ct = default);
}

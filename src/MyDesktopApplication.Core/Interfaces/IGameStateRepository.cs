using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// Repository interface for game state persistence.
/// </summary>
public interface IGameStateRepository
{
    Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default);
    Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default);
    Task SaveAsync(GameState gameState, CancellationToken ct = default);
    Task ResetAsync(string userId, CancellationToken ct = default);
}

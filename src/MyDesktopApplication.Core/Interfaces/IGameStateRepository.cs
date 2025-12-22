using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// Repository interface for GameState entities.
/// Inherits from IRepository&lt;GameState&gt; to provide UpdateAsync, AddAsync, etc.
/// </summary>
public interface IGameStateRepository : IRepository<GameState>
{
    /// <summary>
    /// Gets or creates a game state for the specified user.
    /// </summary>
    Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default);
    
    /// <summary>
    /// Gets a game state by user ID, or null if not found.
    /// </summary>
    Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default);
    
    /// <summary>
    /// Resets the game state for the specified user.
    /// </summary>
    Task ResetAsync(string userId, CancellationToken ct = default);
}

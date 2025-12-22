using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

public interface IGameStateRepository : IRepository<GameState>
{
    Task<GameState> GetOrCreateAsync(string userId, CancellationToken cancellationToken = default);
    Task SaveAsync(GameState gameState, CancellationToken cancellationToken = default);
}

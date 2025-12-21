using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

public interface IGameStateRepository
{
    Task<GameState> GetOrCreateAsync(CancellationToken ct = default);
    Task SaveAsync(GameState state, CancellationToken ct = default);
}

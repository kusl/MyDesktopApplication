using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

public class GameStateRepository : Repository<GameState>, IGameStateRepository
{
    public GameStateRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default)
    {
        var state = await DbSet.FirstOrDefaultAsync(g => g.UserId == userId, ct);
        if (state == null)
        {
            state = new GameState { UserId = userId };
            await AddAsync(state, ct);
        }
        return state;
    }

    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await DbSet.FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }

    public async Task SaveAsync(GameState gameState, CancellationToken ct = default)
    {
        // If the entity is new (Id is empty Guid), add it; otherwise update it
        if (gameState.Id == Guid.Empty)
        {
            await AddAsync(gameState, ct);
        }
        else
        {
            await UpdateAsync(gameState, ct);
        }
    }

    public async Task ResetAsync(string userId, CancellationToken ct = default)
    {
        var state = await GetOrCreateAsync(userId, ct);
        state.Reset();
        await UpdateAsync(state, ct);
    }
}

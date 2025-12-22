using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

/// <summary>
/// GameState-specific repository implementation.
/// Inherits from Repository&lt;GameState&gt; to get UpdateAsync, AddAsync, etc.
/// </summary>
public class GameStateRepository : Repository<GameState>, IGameStateRepository
{
    public GameStateRepository(AppDbContext context) : base(context)
    {
    }

    /// <inheritdoc />
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

    /// <inheritdoc />
    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await DbSet.FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }

    /// <inheritdoc />
    public async Task ResetAsync(string userId, CancellationToken ct = default)
    {
        var state = await GetOrCreateAsync(userId, ct);
        state.Reset();
        await UpdateAsync(state, ct);
    }
}

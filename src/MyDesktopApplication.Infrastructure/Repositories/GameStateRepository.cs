using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Observability;

namespace MyDesktopApplication.Infrastructure.Repositories;

public class GameStateRepository : Repository<GameState>, IGameStateRepository
{
    private readonly ILogger<GameStateRepository> _logger;

    public GameStateRepository(AppDbContext context, ILogger<GameStateRepository>? logger = null)
        : base(context)
    {
        _logger = logger ?? NullLogger<GameStateRepository>.Instance;
    }

    public async Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default)
    {
        using var activity = AppTelemetry.ActivitySource.StartActivity("GameState.GetOrCreate");
        activity?.SetTag("user.id", userId);

        var state = await DbSet.FirstOrDefaultAsync(g => g.UserId == userId, ct);
        if (state == null)
        {
            state = new GameState { UserId = userId };
            await AddAsync(state, ct);
            activity?.SetTag("gamestate.created", true);
            _logger.LogInformation("Created new game state for user {UserId}", userId);
        }
        else
        {
            activity?.SetTag("gamestate.created", false);
            _logger.LogDebug("Loaded game state for user {UserId} with score {Score}", userId, state.CurrentScore);
        }

        return state;
    }

    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await DbSet.FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }

    public async Task SaveAsync(GameState gameState, CancellationToken ct = default)
    {
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
        using var activity = AppTelemetry.ActivitySource.StartActivity("GameState.Reset");
        activity?.SetTag("user.id", userId);

        var state = await GetOrCreateAsync(userId, ct);
        state.Reset();
        await UpdateAsync(state, ct);
        _logger.LogInformation("Reset game state for user {UserId}", userId);
    }
}

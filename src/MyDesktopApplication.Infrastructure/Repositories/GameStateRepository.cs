using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

/// <summary>
/// Repository for persisting game state to the database.
/// </summary>
public class GameStateRepository : IGameStateRepository
{
    private readonly AppDbContext _context;

    public GameStateRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await _context.GameStates
            .AsNoTracking()
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }

    public async Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default)
    {
        var existing = await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
        
        if (existing != null)
            return existing;

        var newState = new GameState
        {
            UserId = userId,
            Score = 0,
            CurrentStreak = 0,
            BestStreak = 0,
            TotalAnswered = 0,
            TotalCorrect = 0,
            SelectedQuestionType = "Population"
        };
        
        _context.GameStates.Add(newState);
        await _context.SaveChangesAsync(ct);
        return newState;
    }

    public async Task SaveAsync(GameState gameState, CancellationToken ct = default)
    {
        var existing = await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == gameState.UserId, ct);
        
        if (existing == null)
        {
            _context.GameStates.Add(gameState);
        }
        else
        {
            existing.Score = gameState.Score;
            existing.CurrentStreak = gameState.CurrentStreak;
            existing.BestStreak = gameState.BestStreak;
            existing.TotalAnswered = gameState.TotalAnswered;
            existing.TotalCorrect = gameState.TotalCorrect;
            existing.SelectedQuestionType = gameState.SelectedQuestionType;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        
        await _context.SaveChangesAsync(ct);
    }

    public async Task ResetAsync(string userId, CancellationToken ct = default)
    {
        var state = await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
        
        if (state != null)
        {
            state.Reset();
            state.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(ct);
        }
    }
}

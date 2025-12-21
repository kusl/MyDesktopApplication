using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

/// <summary>
/// Repository for GameState persistence
/// </summary>
public class GameStateRepository : Repository<GameState>, IGameStateRepository
{
    public GameStateRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await Context.GameStates
            .AsNoTracking()
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }

    public async Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default)
    {
        var existing = await Context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
            
        if (existing != null)
            return existing;

        // Create new - UserId now has default value so no CS9035 error
        var newState = new GameState
        {
            UserId = userId,
            CurrentScore = 0,
            HighScore = 0,
            CurrentStreak = 0,
            BestStreak = 0,
            CorrectAnswers = 0,
            TotalQuestions = 0,
            TotalCorrect = 0,
            TotalAnswered = 0,
            SelectedQuestionType = 0
        };

        await Context.GameStates.AddAsync(newState, ct);
        await Context.SaveChangesAsync(ct);
        
        return newState;
    }

    public async Task UpdateGameStateAsync(GameState gameState, CancellationToken ct = default)
    {
        Context.GameStates.Update(gameState);
        await Context.SaveChangesAsync(ct);
    }
}

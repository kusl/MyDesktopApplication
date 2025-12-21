using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

public class GameStateRepository : IGameStateRepository
{
    private readonly AppDbContext _context;
    
    public GameStateRepository(AppDbContext context)
    {
        _context = context;
    }
    
    public async Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default)
    {
        var state = await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
        
        if (state == null)
        {
            state = new GameState { UserId = userId };
            _context.GameStates.Add(state);
            await _context.SaveChangesAsync(ct);
        }
        
        return state;
    }
    
    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }
    
    public async Task SaveAsync(GameState gameState, CancellationToken ct = default)
    {
        if (gameState.Id == Guid.Empty)
        {
            _context.GameStates.Add(gameState);
        }
        else
        {
            _context.GameStates.Update(gameState);
        }
        
        await _context.SaveChangesAsync(ct);
    }
    
    public async Task ResetAsync(string userId, CancellationToken ct = default)
    {
        var state = await GetOrCreateAsync(userId, ct);
        state.Reset();
        await _context.SaveChangesAsync(ct);
    }
}

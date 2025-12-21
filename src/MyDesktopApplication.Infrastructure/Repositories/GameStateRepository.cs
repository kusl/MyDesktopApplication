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
    
    public async Task<GameState> GetOrCreateAsync(CancellationToken ct = default)
    {
        var state = await _context.GameStates.FirstOrDefaultAsync(ct);
        if (state == null)
        {
            state = new GameState();
            _context.GameStates.Add(state);
            await _context.SaveChangesAsync(ct);
        }
        return state;
    }
    
    public async Task SaveAsync(GameState state, CancellationToken ct = default)
    {
        state.UpdatedAt = DateTime.UtcNow;
        _context.GameStates.Update(state);
        await _context.SaveChangesAsync(ct);
    }
}

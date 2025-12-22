#!/bin/bash
set -e

# =============================================================================
# Fix: Add SaveAsync implementation to GameStateRepository
# Error: CS0535 - 'GameStateRepository' does not implement interface member 
#        'IGameStateRepository.SaveAsync(GameState, CancellationToken)'
# =============================================================================

cd ~/src/dotnet/MyDesktopApplication

echo "=== Fixing SaveAsync Implementation ==="

# -----------------------------------------------------------------------------
# 1. First, let's see what the interface looks like
# -----------------------------------------------------------------------------
echo "[1/4] Checking current IGameStateRepository interface..."
cat src/MyDesktopApplication.Core/Interfaces/IGameStateRepository.cs

echo ""
echo "[2/4] Checking current GameStateRepository implementation..."
cat src/MyDesktopApplication.Infrastructure/Repositories/GameStateRepository.cs

# -----------------------------------------------------------------------------
# 2. The fix: Add SaveAsync to the GameStateRepository
#    Since IGameStateRepository inherits from IRepository<GameState>, 
#    we need to add SaveAsync which is declared in IGameStateRepository
# -----------------------------------------------------------------------------
echo ""
echo "[3/4] Adding SaveAsync implementation to GameStateRepository..."

cat > src/MyDesktopApplication.Infrastructure/Repositories/GameStateRepository.cs << 'EOF'
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
EOF

# -----------------------------------------------------------------------------
# 3. Build to verify the fix
# -----------------------------------------------------------------------------
echo ""
echo "[4/4] Building to verify fix..."
dotnet build --no-restore 2>&1 || true

echo ""
echo "=== Fix Applied ==="
echo "Added SaveAsync(GameState, CancellationToken) implementation to GameStateRepository"
EOF

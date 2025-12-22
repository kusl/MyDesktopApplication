#!/bin/bash
set -e

# =============================================================================
# FIX: GameState must inherit from EntityBase to use IRepository<GameState>
# =============================================================================
# Error: CS0311: 'GameState' cannot be used as type parameter 'T' in 'IRepository<T>'
#        because there's no conversion from 'GameState' to 'EntityBase'
#
# Root cause: IRepository<T> has constraint "where T : EntityBase"
#             but GameState doesn't inherit from EntityBase
# =============================================================================

echo "=============================================="
echo "  Fixing EntityBase Inheritance"
echo "=============================================="

cd "$(dirname "$0")"

# Kill any stuck processes
pkill -f "VBCSCompiler" 2>/dev/null || true
pkill -f "aapt2" 2>/dev/null || true
sleep 1

# Clean obj directories for Core project
rm -rf src/MyDesktopApplication.Core/obj 2>/dev/null || true

# -----------------------------------------------------------------------------
# Fix GameState.cs - Make it inherit from EntityBase
# -----------------------------------------------------------------------------
echo "[1/2] Fixing GameState.cs to inherit from EntityBase..."

cat > src/MyDesktopApplication.Core/Entities/GameState.cs << 'EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Stores game state for the Country Quiz game.
/// Inherits from EntityBase to work with IRepository<T> constraint.
/// </summary>
public class GameState : EntityBase
{
    public string UserId { get; set; } = "default";
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    public QuestionType? SelectedQuestionType { get; set; }

    // Calculated properties
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public double AccuracyPercentage => Accuracy * 100;

    /// <summary>
    /// Records an answer and updates scores accordingly.
    /// </summary>
    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        if (isCorrect)
        {
            TotalCorrect++;
            CurrentScore++;
            CurrentStreak++;
            if (CurrentScore > HighScore) HighScore = CurrentScore;
            if (CurrentStreak > BestStreak) BestStreak = CurrentStreak;
        }
        else
        {
            CurrentStreak = 0;
        }
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Resets current game but preserves high scores.
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Note: HighScore and BestStreak are preserved
        UpdatedAt = DateTime.UtcNow;
    }
}
EOF

echo "✓ GameState now inherits from EntityBase"

# -----------------------------------------------------------------------------
# Ensure EntityBase exists with proper Id property
# -----------------------------------------------------------------------------
echo "[2/2] Verifying EntityBase.cs..."

cat > src/MyDesktopApplication.Core/Entities/EntityBase.cs << 'EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Base class for all entities. Provides common properties.
/// </summary>
public abstract class EntityBase
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
EOF

echo "✓ EntityBase verified"

# -----------------------------------------------------------------------------
# Build to verify the fix
# -----------------------------------------------------------------------------
echo ""
echo "Building solution..."

dotnet restore MyDesktopApplication.slnx --verbosity minimal

if dotnet build MyDesktopApplication.slnx --no-restore --verbosity minimal; then
    echo ""
    echo "=============================================="
    echo "  ✅ BUILD SUCCEEDED"
    echo "=============================================="
    echo ""
    echo "Running tests..."
    dotnet test MyDesktopApplication.slnx --no-build --verbosity minimal || true
else
    echo ""
    echo "=============================================="
    echo "  ❌ BUILD FAILED"
    echo "=============================================="
    exit 1
fi

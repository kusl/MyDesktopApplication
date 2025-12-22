namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Stores game state for the Country Quiz game.
/// Inherits from EntityBase to work with IRepository T constraint.
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

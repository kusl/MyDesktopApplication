namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents the persistent game state for a user
/// </summary>
public class GameState : EntityBase
{
    /// <summary>
    /// User identifier (default for single-player)
    /// </summary>
    public string UserId { get; set; } = "default";

    /// <summary>
    /// Current score in the active session
    /// </summary>
    public int CurrentScore { get; set; }

    /// <summary>
    /// Highest score ever achieved
    /// </summary>
    public int HighScore { get; set; }

    /// <summary>
    /// Current consecutive correct answers
    /// </summary>
    public int CurrentStreak { get; set; }

    /// <summary>
    /// Best streak ever achieved
    /// </summary>
    public int BestStreak { get; set; }

    /// <summary>
    /// Total number of correct answers
    /// </summary>
    public int TotalCorrect { get; set; }

    /// <summary>
    /// Total number of questions answered
    /// </summary>
    public int TotalAnswered { get; set; }

    /// <summary>
    /// When the user last played
    /// </summary>
    public DateTime? LastPlayedAt { get; set; }

    /// <summary>
    /// Calculated accuracy percentage
    /// </summary>
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered * 100 : 0;

    /// <summary>
    /// Records an answer and updates statistics
    /// </summary>
    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        if (isCorrect)
        {
            TotalCorrect++;
            CurrentScore++;
            CurrentStreak++;
            if (CurrentScore > HighScore)
            {
                HighScore = CurrentScore;
            }
            if (CurrentStreak > BestStreak)
            {
                BestStreak = CurrentStreak;
            }
        }
        else
        {
            CurrentStreak = 0;
        }
        LastPlayedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Resets the current session (keeps high scores)
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
    }
}

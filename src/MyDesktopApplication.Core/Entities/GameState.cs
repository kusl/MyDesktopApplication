namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Game state for tracking quiz progress and scores
/// </summary>
public class GameState : EntityBase
{
    public required string UserId { get; set; }
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    public int SelectedQuestionType { get; set; }
    public DateTime? LastPlayedAt { get; set; }

    public void RecordCorrectAnswer()
    {
        CurrentScore++;
        CurrentStreak++;
        TotalCorrect++;
        TotalAnswered++;
        
        if (CurrentScore > HighScore)
            HighScore = CurrentScore;
        
        if (CurrentStreak > BestStreak)
            BestStreak = CurrentStreak;
        
        LastPlayedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void RecordWrongAnswer()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalAnswered++;
        LastPlayedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Keep HighScore and BestStreak
        UpdatedAt = DateTime.UtcNow;
    }

    public double AccuracyPercentage => 
        TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered * 100 : 0;
}

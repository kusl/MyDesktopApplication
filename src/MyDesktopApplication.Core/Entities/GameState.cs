namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents the persistent game state for a user
/// </summary>
public class GameState : EntityBase
{
    public string UserId { get; set; } = "default";
    
    // Current session scores
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    
    // Streak tracking
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    
    // Statistics
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    
    // Selected question type
    public int SelectedQuestionType { get; set; }
    
    // Calculated properties
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public string AccuracyPercentage => $"{Accuracy:P0}";
    
    /// <summary>
    /// Records an answer and updates all relevant statistics
    /// </summary>
    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        
        if (isCorrect)
        {
            CurrentScore++;
            TotalCorrect++;
            CurrentStreak++;
            
            if (CurrentScore > HighScore)
                HighScore = CurrentScore;
            
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
        }
        else
        {
            CurrentStreak = 0;
        }
    }
    
    /// <summary>
    /// Resets the current session (keeps high score and best streak)
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
    }
    
    /// <summary>
    /// Completely resets all statistics
    /// </summary>
    public void ResetAll()
    {
        CurrentScore = 0;
        HighScore = 0;
        CurrentStreak = 0;
        BestStreak = 0;
        TotalCorrect = 0;
        TotalAnswered = 0;
    }
}

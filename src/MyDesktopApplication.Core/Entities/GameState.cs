namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Tracks game state including scores, streaks, and question preferences
/// </summary>
public class GameState : EntityBase
{
    public string UserId { get; set; } = string.Empty;
    
    // Score tracking
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    
    // Question tracking
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    
    // Selected question type for filtering
    public QuestionType? SelectedQuestionType { get; set; }
    
    // Calculated properties
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public double AccuracyPercentage => Accuracy * 100;
    
    /// <summary>
    /// Records an answer and updates all relevant statistics
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
    /// Resets the current game (keeps high scores)
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
    }
    
    /// <summary>
    /// Resets everything including high scores
    /// </summary>
    public void ResetAll()
    {
        CurrentScore = 0;
        HighScore = 0;
        CurrentStreak = 0;
        BestStreak = 0;
        TotalCorrect = 0;
        TotalAnswered = 0;
        SelectedQuestionType = null;
    }
}

namespace MyDesktopApplication.Core.Entities;

public class GameState : EntityBase
{
    public string UserId { get; set; } = "default";
    
    // Score tracking
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    
    // Statistics
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    
    // Selected question type (persisted)
    public QuestionType? SelectedQuestionType { get; set; }
    
    // Calculated properties
    public double Accuracy => TotalAnswered > 0 
        ? (double)TotalCorrect / TotalAnswered 
        : 0;
    
    public double AccuracyPercentage => Accuracy * 100;
    
    /// <summary>
    /// Records an answer and updates all related scores
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
    /// Resets current game while preserving high scores
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Keep HighScore and BestStreak
    }
    
    /// <summary>
    /// Resets all statistics including high scores
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

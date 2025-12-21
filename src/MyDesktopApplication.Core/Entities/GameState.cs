namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents the persistent game state for a user.
/// </summary>
public class GameState : EntityBase
{
    public string UserId { get; set; } = "default";
    public int Score { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public int TotalAnswered { get; set; }
    public int TotalCorrect { get; set; }
    public string SelectedQuestionType { get; set; } = "Population";
    
    // Calculated properties
    public int TotalQuestions => TotalAnswered;
    public int CorrectAnswers => TotalCorrect;
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public double AccuracyPercentage => Accuracy * 100;
    
    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        if (isCorrect)
        {
            TotalCorrect++;
            Score++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
        }
        else
        {
            CurrentStreak = 0;
        }
    }
    
    public void Reset()
    {
        Score = 0;
        CurrentStreak = 0;
        TotalAnswered = 0;
        TotalCorrect = 0;
        // Preserve BestStreak and SelectedQuestionType
    }
}

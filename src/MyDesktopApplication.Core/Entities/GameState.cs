namespace MyDesktopApplication.Core.Entities;

public class GameState
{
    public int Id { get; set; }
    public string UserId { get; set; } = "default";
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    public QuestionType? SelectedQuestionType { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public double AccuracyPercentage => Accuracy * 100;

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

    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Note: HighScore and BestStreak are preserved
        UpdatedAt = DateTime.UtcNow;
    }
}

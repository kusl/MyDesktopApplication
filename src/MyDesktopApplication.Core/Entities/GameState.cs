namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Game state for tracking quiz progress and scores.
/// Used by CountryQuizViewModel for persistent game data.
/// </summary>
public class GameState : EntityBase
{
    // UserId is NOT required - use default value to avoid CS9035 error
    public string UserId { get; set; } = "default";
    
    // Score tracking
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    
    // Statistics used by CountryQuizViewModel
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    
    // Question type selection
    public int SelectedQuestionType { get; set; }
    public DateTime? LastPlayedAt { get; set; }

    /// <summary>
    /// Accuracy as a percentage (0-100).
    /// Used by CountryQuizViewModel for stats display.
    /// </summary>
    public double Accuracy => TotalQuestions > 0 
        ? (double)CorrectAnswers / TotalQuestions * 100 
        : 0;

    /// <summary>
    /// Alternative accuracy calculation for compatibility.
    /// </summary>
    public double AccuracyPercentage => Accuracy;

    /// <summary>
    /// Record an answer - used by CountryQuizViewModel.
    /// </summary>
    public void RecordAnswer(bool isCorrect)
    {
        TotalQuestions++;
        TotalAnswered++;
        
        if (isCorrect)
        {
            CorrectAnswers++;
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
            CurrentScore = 0;
            CurrentStreak = 0;
        }
        
        LastPlayedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Record a correct answer - convenience method.
    /// </summary>
    public void RecordCorrectAnswer() => RecordAnswer(true);

    /// <summary>
    /// Record a wrong answer - convenience method.
    /// </summary>
    public void RecordWrongAnswer() => RecordAnswer(false);

    /// <summary>
    /// Reset current game but preserve high scores.
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Keep HighScore, BestStreak, CorrectAnswers, TotalQuestions for stats
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Full reset including statistics.
    /// </summary>
    public void FullReset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        HighScore = 0;
        BestStreak = 0;
        CorrectAnswers = 0;
        TotalQuestions = 0;
        TotalCorrect = 0;
        TotalAnswered = 0;
        UpdatedAt = DateTime.UtcNow;
    }
}

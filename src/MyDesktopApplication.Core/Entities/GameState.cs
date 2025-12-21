namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Persisted game state for the Country Quiz.
/// </summary>
public class GameState : EntityBase
{
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public string SelectedQuestionType { get; set; } = "Population";
    
    public double Accuracy => TotalQuestions > 0 
        ? Math.Round((double)CorrectAnswers / TotalQuestions * 100, 1) 
        : 0;
    
    public void Reset()
    {
        CorrectAnswers = 0;
        TotalQuestions = 0;
        CurrentStreak = 0;
        // Note: BestStreak is preserved across resets
    }
    
    public void RecordAnswer(bool isCorrect)
    {
        TotalQuestions++;
        if (isCorrect)
        {
            CorrectAnswers++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
            {
                BestStreak = CurrentStreak;
            }
        }
        else
        {
            CurrentStreak = 0;
        }
    }
}

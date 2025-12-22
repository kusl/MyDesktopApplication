using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void NewGameState_HasDefaultValues()
    {
        var state = new GameState();
        
        state.CurrentScore.ShouldBe(0);
        state.HighScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(0);
        state.TotalCorrect.ShouldBe(0);
        state.TotalAnswered.ShouldBe(0);
    }
    
    [Fact]
    public void RecordAnswer_CorrectAnswer_IncrementsScore()
    {
        var state = new GameState();
        
        state.RecordAnswer(true);
        
        state.CurrentScore.ShouldBe(1);
        state.HighScore.ShouldBe(1);
        state.CurrentStreak.ShouldBe(1);
        state.TotalCorrect.ShouldBe(1);
        state.TotalAnswered.ShouldBe(1);
    }
    
    [Fact]
    public void RecordAnswer_WrongAnswer_ResetsStreak()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        
        state.RecordAnswer(false);
        
        state.CurrentScore.ShouldBe(2);
        state.HighScore.ShouldBe(2);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(2);
    }
    
    [Fact]
    public void Reset_KeepsHighScoreAndBestStreak()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        
        state.Reset();
        
        state.CurrentScore.ShouldBe(0);
        state.HighScore.ShouldBe(3);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(3);
    }
    
    [Fact]
    public void Accuracy_CalculatedCorrectly()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(false);
        state.RecordAnswer(true);
        
        state.Accuracy.ShouldBe(0.75, tolerance: 0.01);
        state.AccuracyPercentage.ShouldBe("75%");
    }
}

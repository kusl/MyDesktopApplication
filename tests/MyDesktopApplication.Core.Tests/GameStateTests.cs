using MyDesktopApplication.Core.Entities;
using Shouldly;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void RecordCorrectAnswer_ShouldIncrementScoresAndStreak()
    {
        var state = new GameState { UserId = "test" };
        
        state.RecordCorrectAnswer();
        
        state.CurrentScore.ShouldBe(1);
        state.HighScore.ShouldBe(1);
        state.CurrentStreak.ShouldBe(1);
        state.BestStreak.ShouldBe(1);
        state.TotalCorrect.ShouldBe(1);
        state.TotalAnswered.ShouldBe(1);
    }

    [Fact]
    public void RecordWrongAnswer_ShouldResetCurrentScoreAndStreak()
    {
        var state = new GameState { UserId = "test" };
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        
        state.RecordWrongAnswer();
        
        state.CurrentScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.HighScore.ShouldBe(2); // Should preserve high score
        state.BestStreak.ShouldBe(2); // Should preserve best streak
    }

    [Fact]
    public void Reset_ShouldKeepHighScoreAndBestStreak()
    {
        var state = new GameState { UserId = "test" };
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        
        state.Reset();
        
        state.CurrentScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.HighScore.ShouldBe(3);
        state.BestStreak.ShouldBe(3);
    }

    [Fact]
    public void AccuracyPercentage_ShouldCalculateCorrectly()
    {
        var state = new GameState { UserId = "test" };
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        state.RecordWrongAnswer();
        state.RecordCorrectAnswer();
        
        state.AccuracyPercentage.ShouldBe(75.0);
    }
}

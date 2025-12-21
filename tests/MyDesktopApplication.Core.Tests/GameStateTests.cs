using Xunit;
using Shouldly;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void RecordAnswer_Correct_ShouldIncrementScoresAndStreak()
    {
        var state = new GameState { UserId = "test" };
        
        state.RecordAnswer(true);
        
        state.CurrentScore.ShouldBe(1);
        state.HighScore.ShouldBe(1);
        state.CurrentStreak.ShouldBe(1);
        state.BestStreak.ShouldBe(1);
        state.CorrectAnswers.ShouldBe(1);
        state.TotalQuestions.ShouldBe(1);
    }

    [Fact]
    public void RecordAnswer_Wrong_ShouldResetCurrentScoreAndStreak()
    {
        var state = new GameState { UserId = "test" };
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        
        state.RecordAnswer(false);
        
        state.CurrentScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.HighScore.ShouldBe(2);
        state.BestStreak.ShouldBe(2);
    }

    [Fact]
    public void Reset_ShouldKeepHighScoreAndBestStreak()
    {
        var state = new GameState { UserId = "test" };
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        
        state.Reset();
        
        state.CurrentScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.HighScore.ShouldBe(3);
        state.BestStreak.ShouldBe(3);
    }

    [Fact]
    public void Accuracy_ShouldCalculateCorrectly()
    {
        var state = new GameState { UserId = "test" };
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(false);
        state.RecordAnswer(true);
        
        state.Accuracy.ShouldBe(75.0);
    }
}

using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void NewGameState_ShouldHaveZeroScores()
    {
        var state = new GameState();

        state.CurrentScore.ShouldBe(0);
        state.HighScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(0);
    }

    [Fact]
    public void RecordAnswer_Correct_ShouldIncrementScoreAndStreak()
    {
        var state = new GameState();

        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(true);

        state.CurrentScore.ShouldBe(3);
        state.HighScore.ShouldBe(3);
        state.CurrentStreak.ShouldBe(3);
        state.BestStreak.ShouldBe(3);
    }

    [Fact]
    public void RecordAnswer_Incorrect_ShouldResetStreak()
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
    public void Reset_ShouldPreserveHighScoreAndBestStreak()
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
    public void Accuracy_ShouldCalculateCorrectly()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(false);
        state.RecordAnswer(true);

        state.Accuracy.ShouldBe(75.0);
    }
}

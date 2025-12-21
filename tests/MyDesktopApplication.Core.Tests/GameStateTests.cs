using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void RecordAnswer_CorrectAnswer_IncrementsScoreAndStreak()
    {
        var state = new GameState();
        
        state.RecordAnswer(true);
        
        state.CorrectAnswers.ShouldBe(1);
        state.TotalQuestions.ShouldBe(1);
        state.CurrentStreak.ShouldBe(1);
    }
    
    [Fact]
    public void RecordAnswer_IncorrectAnswer_ResetsStreak()
    {
        var state = new GameState { CurrentStreak = 5 };
        
        state.RecordAnswer(false);
        
        state.CurrentStreak.ShouldBe(0);
        state.TotalQuestions.ShouldBe(1);
    }
    
    [Fact]
    public void RecordAnswer_NewBestStreak_UpdatesBestStreak()
    {
        var state = new GameState { BestStreak = 3, CurrentStreak = 3 };
        
        state.RecordAnswer(true);
        
        state.BestStreak.ShouldBe(4);
        state.CurrentStreak.ShouldBe(4);
    }
    
    [Fact]
    public void Reset_PreservesBestStreak()
    {
        var state = new GameState 
        { 
            CorrectAnswers = 10, 
            TotalQuestions = 15, 
            CurrentStreak = 5, 
            BestStreak = 8 
        };
        
        state.Reset();
        
        state.CorrectAnswers.ShouldBe(0);
        state.TotalQuestions.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(8);
    }
    
    [Fact]
    public void Accuracy_CalculatesCorrectly()
    {
        var state = new GameState { CorrectAnswers = 7, TotalQuestions = 10 };
        
        state.Accuracy.ShouldBe(70.0);
    }
    
    [Fact]
    public void Accuracy_NoQuestions_ReturnsZero()
    {
        var state = new GameState();
        
        state.Accuracy.ShouldBe(0);
    }
}

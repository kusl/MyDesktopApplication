using FluentAssertions;
using MyDesktopApplication.Core.Entities;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void RecordAnswer_CorrectAnswer_IncrementsScoreAndStreak()
    {
        var state = new GameState();
        
        state.RecordAnswer(true);
        
        state.CorrectAnswers.Should().Be(1);
        state.TotalQuestions.Should().Be(1);
        state.CurrentStreak.Should().Be(1);
    }
    
    [Fact]
    public void RecordAnswer_IncorrectAnswer_ResetsStreak()
    {
        var state = new GameState { CurrentStreak = 5 };
        
        state.RecordAnswer(false);
        
        state.CurrentStreak.Should().Be(0);
        state.TotalQuestions.Should().Be(1);
    }
    
    [Fact]
    public void RecordAnswer_NewBestStreak_UpdatesBestStreak()
    {
        var state = new GameState { BestStreak = 3, CurrentStreak = 3 };
        
        state.RecordAnswer(true);
        
        state.BestStreak.Should().Be(4);
        state.CurrentStreak.Should().Be(4);
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
        
        state.CorrectAnswers.Should().Be(0);
        state.TotalQuestions.Should().Be(0);
        state.CurrentStreak.Should().Be(0);
        state.BestStreak.Should().Be(8);
    }
    
    [Fact]
    public void Accuracy_CalculatesCorrectly()
    {
        var state = new GameState { CorrectAnswers = 7, TotalQuestions = 10 };
        
        state.Accuracy.Should().Be(70.0);
    }
    
    [Fact]
    public void Accuracy_NoQuestions_ReturnsZero()
    {
        var state = new GameState();
        
        state.Accuracy.Should().Be(0);
    }
}

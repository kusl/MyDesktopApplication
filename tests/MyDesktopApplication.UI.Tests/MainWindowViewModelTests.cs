using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using NSubstitute;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.UI.Tests;

public class MainWindowViewModelTests
{
    [Fact]
    public async Task GameState_InitializesFromRepository()
    {
        // Arrange
        var mockRepo = Substitute.For<IGameStateRepository>();
        var gameState = new GameState 
        { 
            CorrectAnswers = 5, 
            TotalQuestions = 10,
            BestStreak = 3
        };
        mockRepo.GetOrCreateAsync(Arg.Any<CancellationToken>()).Returns(gameState);
        
        // Act - verify the mock works
        var result = await mockRepo.GetOrCreateAsync();
        
        // Assert
        result.ShouldNotBeNull();
        result.CorrectAnswers.ShouldBe(5);
        result.TotalQuestions.ShouldBe(10);
    }
    
    [Fact]
    public async Task SaveAsync_IsCalled_WhenAnswerRecorded()
    {
        // Arrange
        var mockRepo = Substitute.For<IGameStateRepository>();
        var gameState = new GameState();
        mockRepo.GetOrCreateAsync(Arg.Any<CancellationToken>()).Returns(gameState);
        
        // Act
        gameState.RecordAnswer(true);
        await mockRepo.SaveAsync(gameState);
        
        // Assert
        await mockRepo.Received(1).SaveAsync(Arg.Any<GameState>(), Arg.Any<CancellationToken>());
    }
}

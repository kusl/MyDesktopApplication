using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Integration.Tests;

/// <summary>
/// Integration tests that exercise <see cref="GameStateRepository"/> against a real
/// <see cref="AppDbContext"/> (EF Core in-memory provider). These run in milliseconds
/// so they are safe to run after every change.
/// </summary>
public class GameStateRepositoryTests
{
    private static DbContextOptions<AppDbContext> Options(string databaseName) =>
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName)
            .Options;

    [Fact]
    public async Task GetOrCreateAsync_CreatesNewState_WhenNoneExists()
    {
        await using var context = new AppDbContext(Options(Guid.NewGuid().ToString()));
        var repository = new GameStateRepository(context);

        var state = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);

        state.ShouldNotBeNull();
        state.UserId.ShouldBe("player-1");
        state.CurrentScore.ShouldBe(0);
        state.TotalAnswered.ShouldBe(0);
    }

    [Fact]
    public async Task GetOrCreateAsync_ReturnsSameState_OnSecondCall()
    {
        await using var context = new AppDbContext(Options(Guid.NewGuid().ToString()));
        var repository = new GameStateRepository(context);

        var first = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);
        var second = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);

        second.Id.ShouldBe(first.Id);
    }

    [Fact]
    public async Task RecordedAnswer_IsPersisted_AndReadableFromAFreshContext()
    {
        // Contexts that share an in-memory database name share the same store,
        // which lets us prove the write actually persisted (not just cached).
        var databaseName = Guid.NewGuid().ToString();

        await using (var context = new AppDbContext(Options(databaseName)))
        {
            var repository = new GameStateRepository(context);
            var state = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);
            state.RecordAnswer(isCorrect: true);
            await repository.UpdateAsync(state, TestContext.Current.CancellationToken);
        }

        await using (var context = new AppDbContext(Options(databaseName)))
        {
            var repository = new GameStateRepository(context);
            var reloaded = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);

            reloaded.CurrentScore.ShouldBe(1);
            reloaded.TotalCorrect.ShouldBe(1);
            reloaded.TotalAnswered.ShouldBe(1);
            reloaded.CurrentStreak.ShouldBe(1);
        }
    }

    [Fact]
    public async Task Reset_ClearsCurrentScore_ButKeepsHighScore()
    {
        var databaseName = Guid.NewGuid().ToString();

        await using (var context = new AppDbContext(Options(databaseName)))
        {
            var repository = new GameStateRepository(context);
            var state = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);
            state.RecordAnswer(isCorrect: true);
            state.RecordAnswer(isCorrect: true);
            await repository.UpdateAsync(state, TestContext.Current.CancellationToken);
        }

        await using (var context = new AppDbContext(Options(databaseName)))
        {
            var repository = new GameStateRepository(context);
            await repository.ResetAsync("player-1", TestContext.Current.CancellationToken);
        }

        await using (var context = new AppDbContext(Options(databaseName)))
        {
            var repository = new GameStateRepository(context);
            var reloaded = await repository.GetOrCreateAsync("player-1", TestContext.Current.CancellationToken);

            reloaded.CurrentScore.ShouldBe(0);
            reloaded.CurrentStreak.ShouldBe(0);
            reloaded.HighScore.ShouldBe(2);
            reloaded.BestStreak.ShouldBe(2);
        }
    }
}

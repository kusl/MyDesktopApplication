using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Shared.ViewModels;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.UI.Tests;

/// <summary>
/// Tests for the shared quiz ViewModel used by every platform head (Desktop, Android, ...).
/// </summary>
public class CountryQuizViewModelTests
{
    [Fact]
    public void NewViewModel_ShouldHaveInitialState()
    {
        var vm = new CountryQuizViewModel();

        vm.CurrentScore.ShouldBe(0);
        vm.HighScore.ShouldBe(0);
        vm.CurrentStreak.ShouldBe(0);
        vm.BestStreak.ShouldBe(0);
    }

    [Fact]
    public void QuestionTypes_ShouldContainAllTypes()
    {
        var vm = new CountryQuizViewModel();

        vm.QuestionTypes.Count.ShouldBe(8);
        vm.QuestionTypes.ShouldContain(QuestionType.Population);
        vm.QuestionTypes.ShouldContain(QuestionType.Area);
        vm.QuestionTypes.ShouldContain(QuestionType.Gdp);
    }

    [Fact]
    public void NextRound_ShouldSetCountries()
    {
        var vm = new CountryQuizViewModel();

        vm.NextRoundCommand.Execute(null);

        vm.Country1.ShouldNotBeNull();
        vm.Country2.ShouldNotBeNull();
        vm.Country1!.Name.ShouldNotBe(vm.Country2!.Name);
    }

    [Fact]
    public void SelectedQuestionType_DefaultsToPopulation()
    {
        var vm = new CountryQuizViewModel();
        vm.SelectedQuestionType.ShouldBe(QuestionType.Population);
    }

    [Fact]
    public void HasAnswered_DefaultsToFalse()
    {
        var vm = new CountryQuizViewModel();
        vm.HasAnswered.ShouldBeFalse();
    }

    [Fact]
    public void ScoreText_FormatsCorrectly()
    {
        var vm = new CountryQuizViewModel();
        vm.ScoreText.ShouldBe("0/0");
    }
}

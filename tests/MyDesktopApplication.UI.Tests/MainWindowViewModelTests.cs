using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Desktop.ViewModels;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.UI.Tests;

public class MainWindowViewModelTests
{
    [Fact]
    public void NewViewModel_ShouldHaveInitialState()
    {
        var vm = new MainWindowViewModel();

        vm.CurrentScore.ShouldBe(0);
        vm.HighScore.ShouldBe(0);
        vm.CurrentStreak.ShouldBe(0);
        vm.BestStreak.ShouldBe(0);
        vm.HasAnswered.ShouldBeFalse();
    }

    [Fact]
    public void QuestionTypes_ShouldContainAllTypes()
    {
        var vm = new MainWindowViewModel();

        vm.QuestionTypes.Count.ShouldBe(8);
        vm.QuestionTypes.ShouldContain(QuestionType.Population);
        vm.QuestionTypes.ShouldContain(QuestionType.Area);
        vm.QuestionTypes.ShouldContain(QuestionType.GdpTotal);
        vm.QuestionTypes.ShouldContain(QuestionType.GdpPerCapita);
        vm.QuestionTypes.ShouldContain(QuestionType.PopulationDensity);
        vm.QuestionTypes.ShouldContain(QuestionType.LiteracyRate);
        vm.QuestionTypes.ShouldContain(QuestionType.Hdi);
        vm.QuestionTypes.ShouldContain(QuestionType.LifeExpectancy);
    }

    [Fact]
    public void GenerateNewQuestion_ShouldSetCountries()
    {
        var vm = new MainWindowViewModel();

        vm.GenerateNewQuestionCommand.Execute(null);

        vm.Country1.ShouldNotBeNull();
        vm.Country2.ShouldNotBeNull();
        vm.Country1!.Name.ShouldNotBe(vm.Country2!.Name);
    }

    [Fact]
    public void SelectedQuestionType_DefaultsToPopulation()
    {
        var vm = new MainWindowViewModel();
        vm.SelectedQuestionType.ShouldBe(QuestionType.Population);
    }

    [Fact]
    public void ScoreText_ShouldBeFormatted()
    {
        var vm = new MainWindowViewModel();
        vm.ScoreText.ShouldBe("Score: 0");
    }

    [Fact]
    public void StreakText_ShouldBeFormatted()
    {
        var vm = new MainWindowViewModel();
        vm.StreakText.ShouldBe("Streak: 0");
    }

    [Fact]
    public void BestStreakText_ShouldBeFormatted()
    {
        var vm = new MainWindowViewModel();
        vm.BestStreakText.ShouldBe("Best: 0");
    }
}

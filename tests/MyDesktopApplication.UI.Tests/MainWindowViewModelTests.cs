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

        vm.Score.ShouldBe(0);
        vm.HighScore.ShouldBe(0);
        vm.Streak.ShouldBe(0);
        vm.BestStreak.ShouldBe(0);
    }

    [Fact]
    public void QuestionTypes_ShouldContainAllTypes()
    {
        var vm = new MainWindowViewModel();

        vm.QuestionTypes.Count.ShouldBe(8);
        vm.QuestionTypes.ShouldContain(QuestionType.Population);
        vm.QuestionTypes.ShouldContain(QuestionType.Area);
        vm.QuestionTypes.ShouldContain(QuestionType.Gdp);
    }

    [Fact]
    public void GenerateNewQuestion_ShouldSetCountryNames()
    {
        var vm = new MainWindowViewModel();
        
        // Wait briefly for initialization
        Thread.Sleep(100);
        vm.GenerateNewQuestionCommand.Execute(null);

        vm.Country1Name.ShouldNotBeNullOrEmpty();
        vm.Country2Name.ShouldNotBeNullOrEmpty();
        vm.Country1Name.ShouldNotBe(vm.Country2Name);
    }

    [Fact]
    public void SelectedQuestionType_DefaultsToPopulation()
    {
        var vm = new MainWindowViewModel();

        vm.SelectedQuestionType.ShouldBe(QuestionType.Population);
    }
}

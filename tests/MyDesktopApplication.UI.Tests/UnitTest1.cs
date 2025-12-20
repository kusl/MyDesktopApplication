using FluentAssertions;
using MyDesktopApplication.Desktop.ViewModels;

namespace MyDesktopApplication.UI.Tests;

public class MainWindowViewModelTests
{
    [Fact]
    public void IncrementCounter_ShouldIncreaseCounterByOne()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();
        var initialCount = viewModel.Counter;

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        viewModel.Counter.Should().Be(initialCount + 1);
    }

    [Fact]
    public void IncrementCounter_ShouldUpdateGreeting()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        viewModel.Greeting.Should().Be("You clicked once!");
    }

    [Fact]
    public void IncrementCounter_MultipleTimes_ShouldUpdateGreetingCorrectly()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        for (int i = 0; i < 5; i++)
            viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        viewModel.Counter.Should().Be(5);
        viewModel.Greeting.Should().Contain("5");
    }

    [Fact]
    public void NavigateToHome_ShouldSetCurrentPageToHomeViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToHomeCommand.Execute(null);

        // Assert
        viewModel.CurrentPage.Should().BeOfType<HomeViewModel>();
    }

    [Fact]
    public void NavigateToSettings_ShouldSetCurrentPageToSettingsViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToSettingsCommand.Execute(null);

        // Assert
        viewModel.CurrentPage.Should().BeOfType<SettingsViewModel>();
    }

    [Fact]
    public void NewViewModel_ShouldHaveDefaultValues()
    {
        // Act
        var viewModel = new MainWindowViewModel();

        // Assert
        viewModel.Counter.Should().Be(0);
        viewModel.Greeting.Should().Contain("Welcome");
        viewModel.IsBusy.Should().BeFalse();
        viewModel.CurrentPage.Should().BeNull();
    }
}

using MyDesktopApplication.Desktop.ViewModels;

namespace MyDesktopApplication.UI.Tests;

/// <summary>
/// Unit tests for MainWindowViewModel using plain xUnit assertions.
/// </summary>
public class MainWindowViewModelTests
{
    [Fact]
    public void Constructor_ShouldSetDefaultValues()
    {
        // Act
        var viewModel = new MainWindowViewModel();

        // Assert
        Assert.Equal(0, viewModel.Counter);
        Assert.Contains("Welcome", viewModel.Greeting);
        Assert.False(viewModel.IsBusy);
        Assert.Null(viewModel.CurrentPage);
        Assert.Empty(viewModel.TodoItems);
    }

    [Fact]
    public void IncrementCounter_ShouldIncreaseCounterByOne()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();
        var initialCount = viewModel.Counter;

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        Assert.Equal(initialCount + 1, viewModel.Counter);
    }

    [Fact]
    public void IncrementCounter_FirstClick_ShouldUpdateGreeting()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        Assert.Equal("You clicked once!", viewModel.Greeting);
    }

    [Fact]
    public void IncrementCounter_MultipleClicks_ShouldUpdateGreetingCorrectly()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act - click 3 times
        viewModel.IncrementCounterCommand.Execute(null);
        viewModel.IncrementCounterCommand.Execute(null);
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        Assert.Equal(3, viewModel.Counter);
        Assert.Contains("3", viewModel.Greeting);
    }

    [Fact]
    public void IncrementCounter_TenClicks_ShouldShowAmazingMessage()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act - click 10 times
        for (int i = 0; i < 10; i++)
        {
            viewModel.IncrementCounterCommand.Execute(null);
        }

        // Assert
        Assert.Equal(10, viewModel.Counter);
        Assert.Contains("Amazing", viewModel.Greeting);
    }

    [Fact]
    public void NavigateToHome_ShouldSetCurrentPageToHomeViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();
        Assert.Null(viewModel.CurrentPage);

        // Act
        viewModel.NavigateToHomeCommand.Execute(null);

        // Assert
        Assert.NotNull(viewModel.CurrentPage);
        Assert.IsType<HomeViewModel>(viewModel.CurrentPage);
    }

    [Fact]
    public void NavigateToSettings_ShouldSetCurrentPageToSettingsViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToSettingsCommand.Execute(null);

        // Assert
        Assert.NotNull(viewModel.CurrentPage);
        Assert.IsType<SettingsViewModel>(viewModel.CurrentPage);
    }

    [Fact]
    public void NavigateToHome_ThenSettings_ShouldReplaceCurrentPage()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToHomeCommand.Execute(null);
        var homePage = viewModel.CurrentPage;
        
        viewModel.NavigateToSettingsCommand.Execute(null);

        // Assert
        Assert.NotNull(viewModel.CurrentPage);
        Assert.IsType<SettingsViewModel>(viewModel.CurrentPage);
        Assert.NotSame(homePage, viewModel.CurrentPage);
    }
}

public class HomeViewModelTests
{
    [Fact]
    public void Constructor_ShouldSetDefaultTitle()
    {
        // Act
        var viewModel = new HomeViewModel();

        // Assert
        Assert.Equal("Home", viewModel.Title);
    }
}

public class SettingsViewModelTests
{
    [Fact]
    public void Constructor_ShouldSetDefaultValues()
    {
        // Act
        var viewModel = new SettingsViewModel();

        // Assert
        Assert.Equal("Settings", viewModel.Title);
        Assert.False(viewModel.DarkMode);
    }

    [Fact]
    public void DarkMode_ShouldBeSettable()
    {
        // Arrange
        var viewModel = new SettingsViewModel();

        // Act
        viewModel.DarkMode = true;

        // Assert
        Assert.True(viewModel.DarkMode);
    }
}

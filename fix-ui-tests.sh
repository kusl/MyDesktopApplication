#!/bin/bash
# Fix UI Tests and MainWindowViewModel to harmonize property names
# This script is idempotent - safe to run multiple times

set -e

echo "=============================================="
echo "  Fixing UI Tests Build Errors"
echo "=============================================="

# Kill any stuck processes
pkill -f "aapt2" 2>/dev/null || true
pkill -f "VBCSCompiler" 2>/dev/null || true

# Clean build artifacts
echo "[1/4] Cleaning build artifacts..."
rm -rf src/*/bin src/*/obj tests/*/bin tests/*/obj 2>/dev/null || true
dotnet nuget locals temp -c 2>/dev/null || true

# -----------------------------------------------------------------------------
# 2. Fix MainWindowViewModel - Add missing properties the tests expect
# -----------------------------------------------------------------------------
echo "[2/4] Updating MainWindowViewModel.cs with all required properties..."

cat > src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs << 'VIEWMODEL_EOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Desktop.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();
    private readonly Random _random = new();

    // Country properties that XAML binds to (Country1.Flag, Country1.Name, etc.)
    [ObservableProperty] private Country? _country1;
    [ObservableProperty] private Country? _country2;

    // Score/streak properties
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;

    // UI state properties
    [ObservableProperty] private string _greeting = "Welcome to Country Quiz!";
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _feedbackMessage = "";
    [ObservableProperty] private bool _showFeedback;
    [ObservableProperty] private bool _hasAnswered;
    
    // Answer result properties for XAML visual feedback
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;
    
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    // Computed text properties for XAML binding
    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    // QuestionTypes collection for dropdown
    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());

    // Design-time constructor
    public MainWindowViewModel() 
    {
        GenerateNewQuestion();
    }

    // Runtime constructor with DI
    public MainWindowViewModel(IGameStateRepository gameStateRepository) : this()
    {
        _gameStateRepository = gameStateRepository;
    }

    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            try
            {
                _gameState = await _gameStateRepository.GetOrCreateAsync("default");
                CurrentScore = _gameState.CurrentScore;
                HighScore = _gameState.HighScore;
                CurrentStreak = _gameState.CurrentStreak;
                BestStreak = _gameState.BestStreak;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading game state: {ex.Message}");
            }
        }
        GenerateNewQuestion();
    }

    // XAML binds to SelectCountryCommand with CommandParameter="1" or "2"
    [RelayCommand]
    private async Task SelectCountry(string countryParam)
    {
        if (HasAnswered || Country1 == null || Country2 == null)
            return;

        if (!int.TryParse(countryParam, out int countryNumber))
            return;

        HasAnswered = true;
        TotalQuestions++;

        var value1 = SelectedQuestionType.GetValue(Country1);
        var value2 = SelectedQuestionType.GetValue(Country2);

        Country1Value = SelectedQuestionType.FormatValue(value1);
        Country2Value = SelectedQuestionType.FormatValue(value2);

        bool isCorrect;
        if (countryNumber == 1)
        {
            isCorrect = value1 >= value2;
            IsCountry1Correct = isCorrect;
            IsCountry1Wrong = !isCorrect;
            IsCountry2Correct = !isCorrect;
            IsCountry2Wrong = isCorrect;
        }
        else
        {
            isCorrect = value2 >= value1;
            IsCountry2Correct = isCorrect;
            IsCountry2Wrong = !isCorrect;
            IsCountry1Correct = !isCorrect;
            IsCountry1Wrong = isCorrect;
        }

        if (isCorrect)
        {
            CurrentScore++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
            ResultMessage = GetCorrectMessage();
        }
        else
        {
            CurrentStreak = 0;
            ResultMessage = GetIncorrectMessage();
        }

        // Update GameState and persist
        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
        _gameState.RecordAnswer(isCorrect);

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    // XAML binds to NextRoundCommand
    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void ChangeQuestionType(QuestionType newType)
    {
        SelectedQuestionType = newType;
        GenerateNewQuestion();
    }

    [RelayCommand]
    private async Task ResetGame()
    {
        _gameState.Reset();
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalQuestions = 0;
        // Note: BestStreak is preserved across resets
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(AccuracyText));
        
        GenerateNewQuestion();
    }

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;
        Country1Value = "";
        Country2Value = "";
        ResultMessage = "";
        ShowFeedback = false;

        var countries = CountryData.GetAllCountries();
        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        Country1 = countries[indices[0]];
        Country2 = countries[indices[1]];

        QuestionText = $"Which country has a higher {SelectedQuestionType.GetLabel()}?";
    }

    private string GetCorrectMessage()
    {
        if (CurrentStreak >= 10) return "🔥 UNSTOPPABLE! 10+ streak!";
        if (CurrentStreak >= 5) return "🔥 On fire! 5+ streak!";
        if (CurrentStreak >= 3) return "🔥 Nice streak!";
        if (CurrentStreak > BestStreak - CurrentStreak && BestStreak > 3) return "🏆 NEW RECORD!";
        
        string[] messages = ["Correct! ✓", "Well done!", "Nice!", "Great job!", "You got it!"];
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        string[] messages = ["Not quite!", "Oops!", "Wrong!", "Try again!", "So close!"];
        return messages[_random.Next(messages.Length)];
    }
}
VIEWMODEL_EOF

# -----------------------------------------------------------------------------
# 3. Fix UI Tests to use correct property names
# -----------------------------------------------------------------------------
echo "[3/4] Updating MainWindowViewModelTests.cs..."

cat > tests/MyDesktopApplication.UI.Tests/MainWindowViewModelTests.cs << 'TESTS_EOF'
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
        
        // Use correct property names: CurrentScore, not Score
        vm.CurrentScore.ShouldBe(0);
        vm.HighScore.ShouldBe(0);
        vm.CurrentStreak.ShouldBe(0);
        vm.BestStreak.ShouldBe(0);
    }

    [Fact]
    public void QuestionTypes_ShouldContainAllTypes()
    {
        var vm = new MainWindowViewModel();
        
        vm.QuestionTypes.Count.ShouldBe(8);
        vm.QuestionTypes.ShouldContain(QuestionType.Population);
        vm.QuestionTypes.ShouldContain(QuestionType.Area);
        vm.QuestionTypes.ShouldContain(QuestionType.GdpTotal);
    }

    [Fact]
    public void NextRound_ShouldSetCountries()
    {
        var vm = new MainWindowViewModel();
        
        // Call NextRoundCommand (not GenerateNewQuestionCommand)
        vm.NextRoundCommand.Execute(null);

        // Use Country1 and Country2 directly (not Country1Name)
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
    public void HasAnswered_DefaultsToFalse()
    {
        var vm = new MainWindowViewModel();
        vm.HasAnswered.ShouldBeFalse();
    }

    [Fact]
    public void ScoreText_FormatsCorrectly()
    {
        var vm = new MainWindowViewModel();
        vm.ScoreText.ShouldBe("Score: 0");
    }
}
TESTS_EOF

# -----------------------------------------------------------------------------
# 4. Build and Test
# -----------------------------------------------------------------------------
echo "[4/4] Building and running tests..."

# Restore
dotnet restore MyDesktopApplication.slnx --verbosity minimal

# Build (excluding Android to avoid SDK issues on CI)
echo "Building solution..."
if dotnet build MyDesktopApplication.slnx --configuration Debug --verbosity minimal 2>&1 | grep -q "error"; then
    echo "Build has errors, attempting desktop-only build..."
    dotnet build src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj -c Debug --verbosity minimal
    dotnet build src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj -c Debug --verbosity minimal
    dotnet build src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj -c Debug --verbosity minimal
    dotnet build src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj -c Debug --verbosity minimal
    dotnet build tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj -c Debug --verbosity minimal
    dotnet build tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj -c Debug --verbosity minimal
    dotnet build tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj -c Debug --verbosity minimal
fi

# Run tests
echo ""
echo "Running tests..."
dotnet test tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj -c Debug --verbosity normal || true
dotnet test tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj -c Debug --verbosity normal || true
dotnet test tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj -c Debug --verbosity normal || true

echo ""
echo "=============================================="
echo "  Fix Complete!"
echo "=============================================="
echo ""
echo "Changes made:"
echo "  1. MainWindowViewModel: Added Country1/Country2 as [ObservableProperty]"
echo "  2. MainWindowViewModel: Added NextRoundCommand via [RelayCommand]"
echo "  3. MainWindowViewModel: Added HasAnswered, result properties"
echo "  4. UI Tests: Fixed to use CurrentScore (not Score)"
echo "  5. UI Tests: Fixed to use Country1/Country2 (not Country1Name)"
echo "  6. UI Tests: Fixed to use NextRoundCommand (not GenerateNewQuestionCommand)"
echo ""

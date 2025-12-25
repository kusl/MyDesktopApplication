using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// ViewModel for the Desktop main window.
/// Implements the same quiz logic as CountryQuizViewModel for consistency.
/// </summary>
public partial class MainWindowViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();

    private Country? _country1;
    private Country? _country2;

    [ObservableProperty] private string _greeting = "Welcome to Country Quiz!";
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Flag = "";
    [ObservableProperty] private string _country2Flag = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;

    // Answer states - only highlight selected answer
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;

    // Scores
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;

    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());

    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    public MainWindowViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        GenerateNewQuestion();
    }

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
                CurrentStreak = _gameState.CurrentStreak;
                BestStreak = _gameState.BestStreak;
                HighScore = _gameState.HighScore;
                OnPropertyChanged(nameof(ScoreText));
                OnPropertyChanged(nameof(StreakText));
                OnPropertyChanged(nameof(BestStreakText));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading game state: {ex.Message}");
            }
        }
    }

    [RelayCommand]
    private async Task SelectCountry(string countryParam)
    {
        if (HasAnswered || _country1 == null || _country2 == null)
            return;

        if (!int.TryParse(countryParam, out int countryNumber))
            return;

        HasAnswered = true;
        TotalQuestions++;

        var value1 = SelectedQuestionType.GetValue(_country1);
        var value2 = SelectedQuestionType.GetValue(_country2);

        Country1Value = SelectedQuestionType.FormatValue(value1);
        Country2Value = SelectedQuestionType.FormatValue(value2);

        // FIX: Only highlight the selected answer
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;

        bool isCorrect;
        if (countryNumber == 1)
        {
            isCorrect = value1 >= value2;
            IsCountry1Correct = isCorrect;
            IsCountry1Wrong = !isCorrect;
        }
        else
        {
            isCorrect = value2 >= value1;
            IsCountry2Correct = isCorrect;
            IsCountry2Wrong = !isCorrect;
        }

        if (isCorrect)
        {
            CurrentScore++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
            if (CurrentScore > HighScore)
                HighScore = CurrentScore;
            ResultMessage = GetCorrectMessage();
        }
        else
        {
            CurrentStreak = 0;
            ResultMessage = GetIncorrectMessage();
        }

        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
        _gameState.HighScore = HighScore;
        _gameState.RecordAnswer(isCorrect);

        if (_gameStateRepository != null)
        {
            try
            {
                await _gameStateRepository.UpdateAsync(_gameState);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error saving game state: {ex.Message}");
            }
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private async Task ResetGame()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalQuestions = 0;

        _gameState.CurrentScore = 0;
        _gameState.CurrentStreak = 0;

        if (_gameStateRepository != null)
        {
            try
            {
                await _gameStateRepository.UpdateAsync(_gameState);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error resetting game state: {ex.Message}");
            }
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

        var indices = Enumerable.Range(0, _countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        _country1 = _countries[indices[0]];
        _country2 = _countries[indices[1]];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        Country1Flag = _country1.Flag;
        Country2Flag = _country2.Flag;

        QuestionText = $"Which country has a higher {SelectedQuestionType.GetLabel()}?";
    }

    private string GetCorrectMessage()
    {
        var messages = new[]
        {
            "Correct!",
            "Well done!",
            "Great job!",
            "Excellent!",
            CurrentStreak >= 5 ? $"{CurrentStreak} in a row!" : "Keep it up!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        return "Not quite! The correct answer is shown above.";
    }
}

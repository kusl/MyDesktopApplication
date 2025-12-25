using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game.
/// Shared between Desktop and Android platforms.
/// </summary>
public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();

    // Backing fields for country references (not observable - we expose flat properties)
    private Country? _country1;
    private Country? _country2;

    // Observable properties for UI binding
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Flag = "";
    [ObservableProperty] private string _country2Flag = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    
    // Answer state - FIX: Only highlight the selected answer
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;
    
    // Score tracking
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;
    
    // Question type selection
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;
    [ObservableProperty] private ObservableCollection<QuestionType> _questionTypes = new();

    // Computed properties for UI display
    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    /// <summary>
    /// Constructor with dependency injection for game state persistence.
    /// </summary>
    public CountryQuizViewModel(IGameStateRepository gameStateRepository) : this()
    {
        _gameStateRepository = gameStateRepository;
    }

    /// <summary>
    /// Parameterless constructor for design-time and default initialization.
    /// </summary>
    public CountryQuizViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        foreach (QuestionType qt in Enum.GetValues<QuestionType>())
        {
            QuestionTypes.Add(qt);
        }
        GenerateNewQuestion();
    }

    /// <summary>
    /// Initialize async - loads persisted game state from database.
    /// </summary>
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
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading game state: {ex.Message}");
            }
        }
    }

    /// <summary>
    /// Handle country selection.
    /// FIX: Only highlight the answer the user selected, not both answers.
    /// </summary>
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

        bool isCorrect;
        
        // FIX: Only highlight the selected answer
        // Reset all states first
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;

        if (countryNumber == 1)
        {
            // User selected Country 1
            isCorrect = value1 >= value2;
            // Only set state for Country 1 (the selected one)
            IsCountry1Correct = isCorrect;
            IsCountry1Wrong = !isCorrect;
            // Do NOT set Country 2 state - leave it unhighlighted
        }
        else
        {
            // User selected Country 2
            isCorrect = value2 >= value1;
            // Only set state for Country 2 (the selected one)
            IsCountry2Correct = isCorrect;
            IsCountry2Wrong = !isCorrect;
            // Do NOT set Country 1 state - leave it unhighlighted
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

        // Persist game state
        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
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

    /// <summary>
    /// Start a new round with new countries.
    /// </summary>
    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    /// <summary>
    /// Change the question type and generate a new question.
    /// </summary>
    [RelayCommand]
    private void ChangeQuestionType(QuestionType newType)
    {
        SelectedQuestionType = newType;
        GenerateNewQuestion();
    }

    /// <summary>
    /// Reset the game to initial state.
    /// </summary>
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

        // Pick two different random countries
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

    // FIX: Remove emojis - use plain text messages instead
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

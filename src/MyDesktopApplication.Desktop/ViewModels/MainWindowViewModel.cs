using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// ViewModel for the Desktop main window.
/// </summary>
public partial class MainWindowViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private GameState _gameState = new();
    private Country? _correctCountry;

    // --- Observable properties ---

    [ObservableProperty] private string _questionText = "Loading...";

    [ObservableProperty] private Country? _country1;
    [ObservableProperty] private Country? _country2;

    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";

    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    [ObservableProperty] private bool _isCorrectAnswer;
    [ObservableProperty] private int _selectedCountry; // 0=none, 1=country1, 2=country2

    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;

    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    // Reset confirmation overlay
    [ObservableProperty] private bool _isResetConfirmationVisible;

    // --- Computed properties for button coloring ---
    // CRITICAL: Only the SELECTED button gets colored. Unselected stays default.

    public bool IsCountry1Correct => HasAnswered && SelectedCountry == 1 && IsCorrectAnswer;
    public bool IsCountry1Wrong => HasAnswered && SelectedCountry == 1 && !IsCorrectAnswer;
    public bool IsCountry2Correct => HasAnswered && SelectedCountry == 2 && IsCorrectAnswer;
    public bool IsCountry2Wrong => HasAnswered && SelectedCountry == 2 && !IsCorrectAnswer;

    // Formatted text properties
    public string ScoreText => $"{_gameState.CurrentScore}/{_gameState.TotalAnswered}";
    public string StreakText => _gameState.CurrentStreak > 0 ? $"Streak: {_gameState.CurrentStreak}" : "";
    public string BestStreakText => _gameState.BestStreak > 0 ? $"Best: {_gameState.BestStreak}" : "";
    public string AccuracyText => _gameState.TotalAnswered > 0
        ? $"Accuracy: {_gameState.AccuracyPercentage:F1}%"
        : "Accuracy: --";

    public ObservableCollection<QuestionType> QuestionTypes { get; } =
        new(Enum.GetValues<QuestionType>());

    // --- Constructors ---

    public MainWindowViewModel()
    {
        GenerateNewQuestion();
    }

    public MainWindowViewModel(IGameStateRepository gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
    }

    // --- Initialization ---

    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            _gameState = await _gameStateRepository.GetOrCreateAsync("default");
            SyncScoresFromGameState();
        }
        GenerateNewQuestion();
    }

    private void SyncScoresFromGameState()
    {
        CurrentScore = _gameState.CurrentScore;
        HighScore = _gameState.HighScore;
        CurrentStreak = _gameState.CurrentStreak;
        BestStreak = _gameState.BestStreak;
        RefreshTextProperties();
    }

    private void RefreshTextProperties()
    {
        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    // --- Property change notifications for computed properties ---

    partial void OnHasAnsweredChanged(bool value) => RefreshButtonStates();
    partial void OnSelectedCountryChanged(int value) => RefreshButtonStates();
    partial void OnIsCorrectAnswerChanged(bool value) => RefreshButtonStates();

    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        _gameState.SelectedQuestionType = value;
        GenerateNewQuestion();
    }

    private void RefreshButtonStates()
    {
        OnPropertyChanged(nameof(IsCountry1Correct));
        OnPropertyChanged(nameof(IsCountry1Wrong));
        OnPropertyChanged(nameof(IsCountry2Correct));
        OnPropertyChanged(nameof(IsCountry2Wrong));
    }

    // --- Commands ---

    [RelayCommand]
    private async Task SelectCountryAsync(string countryNumberStr)
    {
        if (!int.TryParse(countryNumberStr, out var countryNumber)) return;
        if (HasAnswered || _correctCountry == null) return;

        HasAnswered = true;
        SelectedCountry = countryNumber;

        var selectedCountry = countryNumber == 1 ? Country1 : Country2;
        var isCorrect = selectedCountry?.Name == _correctCountry.Name;
        IsCorrectAnswer = isCorrect;

        _gameState.RecordAnswer(isCorrect);
        SyncScoresFromGameState();

        if (Country1 != null)
        {
            var v1 = SelectedQuestionType.GetValue(Country1);
            Country1Value = v1.HasValue ? SelectedQuestionType.FormatValue(v1) : "N/A";
        }
        if (Country2 != null)
        {
            var v2 = SelectedQuestionType.GetValue(Country2);
            Country2Value = v2.HasValue ? SelectedQuestionType.FormatValue(v2) : "N/A";
        }

        ResultMessage = isCorrect ? GetCorrectMessage() : GetIncorrectMessage();

        if (_gameStateRepository != null)
        {
            try { await _gameStateRepository.UpdateAsync(_gameState); }
            catch { /* Silently handle persistence failures */ }
        }
    }

    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    /// <summary>
    /// Shows the reset confirmation overlay instead of immediately resetting.
    /// </summary>
    [RelayCommand]
    private void RequestResetGame()
    {
        IsResetConfirmationVisible = true;
    }

    /// <summary>
    /// User confirmed: reset the game.
    /// </summary>
    [RelayCommand]
    private async Task ConfirmResetGameAsync()
    {
        IsResetConfirmationVisible = false;

        _gameState.Reset();
        SyncScoresFromGameState();
        GenerateNewQuestion();

        if (_gameStateRepository != null)
        {
            try { await _gameStateRepository.UpdateAsync(_gameState); }
            catch { /* Silently handle persistence failures */ }
        }
    }

    /// <summary>
    /// User cancelled: hide the confirmation overlay.
    /// </summary>
    [RelayCommand]
    private void CancelResetGame()
    {
        IsResetConfirmationVisible = false;
    }

    // --- Internals ---

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        SelectedCountry = 0;
        IsCorrectAnswer = false;
        ResultMessage = "";
        Country1Value = "";
        Country2Value = "";

        var countries = CountryData.GetAllCountries();
        if (countries.Count < 2)
        {
            QuestionText = "Not enough countries loaded.";
            return;
        }

        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        Country1 = countries[indices[0]];
        Country2 = countries[indices[1]];

        QuestionText = SelectedQuestionType.GetQuestion();

        var v1 = SelectedQuestionType.GetValue(Country1);
        var v2 = SelectedQuestionType.GetValue(Country2);
        _correctCountry = (v1 ?? 0) >= (v2 ?? 0) ? Country1 : Country2;
    }

    private string GetCorrectMessage()
    {
        if (_gameState.CurrentStreak >= 10) return "UNSTOPPABLE! 10+ streak!";
        if (_gameState.CurrentStreak >= 5) return $"On fire! {_gameState.CurrentStreak} in a row!";
        if (_gameState.CurrentStreak >= 3) return $"Great streak! {_gameState.CurrentStreak} correct!";

        var messages = new[] { "Correct!", "Well done!", "Nice one!", "You got it!", "Excellent!" };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        var messages = new[] { "Not quite!", "Oops!", "Close one!", "Now you know!", "Learn something new!" };
        return messages[_random.Next(messages.Length)];
    }
}

using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly IGameStateRepository _repository;
    private readonly Random _random = new();
    private GameState? _gameState;
    private Country? _correctCountry;
    
    [ObservableProperty]
    private string _questionText = "Loading...";
    
    [ObservableProperty]
    private Country? _country1;
    
    [ObservableProperty]
    private Country? _country2;
    
    [ObservableProperty]
    private string _scoreText = "0/0";
    
    [ObservableProperty]
    private string _streakText = "";
    
    [ObservableProperty]
    private string _bestStreakText = "";
    
    [ObservableProperty]
    private string _accuracyText = "";
    
    [ObservableProperty]
    private string _resultMessage = "";
    
    [ObservableProperty]
    private bool _hasAnswered;
    
    [ObservableProperty]
    private bool _isCorrectAnswer;
    
    [ObservableProperty]
    private int _selectedCountry; // 0 = none, 1 = country1, 2 = country2
    
    [ObservableProperty]
    private string _country1Value = "";
    
    [ObservableProperty]
    private string _country2Value = "";
    
    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;
    
    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());
    
    public CountryQuizViewModel(IGameStateRepository repository)
    {
        _repository = repository;
    }
    
    public async Task InitializeAsync()
    {
        IsBusy = true;
        try
        {
            _gameState = await _repository.GetOrCreateAsync();
            
            if (Enum.TryParse<QuestionType>(_gameState.SelectedQuestionType, out var qt))
            {
                SelectedQuestionType = qt;
            }
            
            UpdateScoreDisplay();
            await NextRoundAsync();
        }
        finally
        {
            IsBusy = false;
        }
    }
    
    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        if (_gameState != null)
        {
            _gameState.SelectedQuestionType = value.ToString();
            _ = SaveAndNextRoundAsync();
        }
    }
    
    private async Task SaveAndNextRoundAsync()
    {
        if (_gameState != null)
        {
            await _repository.SaveAsync(_gameState);
        }
        await NextRoundAsync();
    }
    
    private (Country, Country)? GetRandomPair()
    {
        var valid = CountryData.Countries
            .Where(c => SelectedQuestionType.GetValue(c) != null)
            .ToList();
        
        if (valid.Count < 2) return null;
        
        for (int i = 0; i < 100; i++)
        {
            var c1 = valid[_random.Next(valid.Count)];
            var c2 = valid[_random.Next(valid.Count)];
            var v1 = SelectedQuestionType.GetValue(c1);
            var v2 = SelectedQuestionType.GetValue(c2);
            
            // Ensure different countries AND different values (no ties)
            if (c1.Name != c2.Name && v1 != null && v2 != null && Math.Abs(v1.Value - v2.Value) > 0.001)
            {
                return (c1, c2);
            }
        }
        return null;
    }
    
    [RelayCommand]
    private async Task NextRoundAsync()
    {
        HasAnswered = false;
        SelectedCountry = 0;
        ResultMessage = "";
        Country1Value = "";
        Country2Value = "";
        
        var pair = GetRandomPair();
        if (pair == null)
        {
            QuestionText = "Not enough data for this question type.";
            return;
        }
        
        (Country1, Country2) = pair.Value;
        QuestionText = SelectedQuestionType.GetQuestion();
        
        var v1 = SelectedQuestionType.GetValue(Country1!);
        var v2 = SelectedQuestionType.GetValue(Country2!);
        _correctCountry = v1 > v2 ? Country1 : Country2;
    }
    
    [RelayCommand]
    private async Task SelectCountryAsync(int countryNumber)
    {
        if (HasAnswered || _gameState == null || _correctCountry == null) return;
        
        HasAnswered = true;
        SelectedCountry = countryNumber;
        
        var selectedCountry = countryNumber == 1 ? Country1 : Country2;
        var isCorrect = selectedCountry?.Name == _correctCountry.Name;
        IsCorrectAnswer = isCorrect;
        
        // Record answer
        var wasNewBest = _gameState.CurrentStreak == _gameState.BestStreak && isCorrect;
        _gameState.RecordAnswer(isCorrect);
        var isNewBest = _gameState.CurrentStreak == _gameState.BestStreak && _gameState.CurrentStreak > 1;
        
        // Show values
        if (Country1 != null)
        {
            var v1 = SelectedQuestionType.GetValue(Country1);
            Country1Value = v1.HasValue ? SelectedQuestionType.FormatValue(v1.Value) : "N/A";
        }
        if (Country2 != null)
        {
            var v2 = SelectedQuestionType.GetValue(Country2);
            Country2Value = v2.HasValue ? SelectedQuestionType.FormatValue(v2.Value) : "N/A";
        }
        
        // Build result message
        var message = isCorrect 
            ? MotivationalMessages.GetCorrectMessage()
            : MotivationalMessages.GetIncorrectMessage();
        
        if (isCorrect && isNewBest && !wasNewBest && _gameState.CurrentStreak >= 3)
        {
            message += "\n" + MotivationalMessages.GetNewBestMessage(_gameState.BestStreak);
        }
        else if (isCorrect && _gameState.CurrentStreak >= 3)
        {
            var streakMsg = MotivationalMessages.GetStreakMessage(_gameState.CurrentStreak);
            if (!string.IsNullOrEmpty(streakMsg))
            {
                message += "\n" + streakMsg;
            }
        }
        
        ResultMessage = message;
        UpdateScoreDisplay();
        
        await _repository.SaveAsync(_gameState);
    }
    
    [RelayCommand]
    private async Task ResetGameAsync()
    {
        if (_gameState == null) return;
        
        _gameState.Reset();
        await _repository.SaveAsync(_gameState);
        
        ResultMessage = MotivationalMessages.GetResetMessage();
        UpdateScoreDisplay();
        await NextRoundAsync();
    }
    
    private void UpdateScoreDisplay()
    {
        if (_gameState == null) return;
        
        ScoreText = $"{_gameState.CorrectAnswers}/{_gameState.TotalQuestions}";
        StreakText = _gameState.CurrentStreak > 0 ? $"🔥 {_gameState.CurrentStreak}" : "";
        BestStreakText = _gameState.BestStreak > 0 ? $"⭐ Best: {_gameState.BestStreak}" : "";
        AccuracyText = _gameState.TotalQuestions > 0 
            ? $"{_gameState.Accuracy}% {MotivationalMessages.GetAccuracyComment(_gameState.Accuracy)}"
            : "";
    }
}

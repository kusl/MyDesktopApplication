using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game
/// </summary>
public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();

    // FIX 1: Expose Country objects so View bindings like 'Country1.Flag' work
    [ObservableProperty] 
    private Country? _country1;
    
    [ObservableProperty] 
    private Country? _country2;

    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    
    // Visual feedback properties
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;
    
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;
    
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;
    [ObservableProperty] private ObservableCollection<QuestionType> _questionTypes = new();

    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    public CountryQuizViewModel(IGameStateRepository gameStateRepository) : this()
    {
        _gameStateRepository = gameStateRepository;
    }

    public CountryQuizViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        foreach (QuestionType qt in Enum.GetValues<QuestionType>())
        {
            QuestionTypes.Add(qt);
        }

        GenerateNewQuestion();
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
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading game state: {ex.Message}");
            }
        }
    }

    // FIX 2: Change parameter to string to match XAML CommandParameter="1"
    [RelayCommand]
    private async Task SelectCountry(string countryParam) 
    {
        // FIX for MVVMTK0034: Use public properties (Country1, Country2) instead of backing fields
        if (HasAnswered || Country1 == null || Country2 == null)
            return;

        // Parse the string parameter to int safely
        if (!int.TryParse(countryParam, out int countryNumber)) return;

        HasAnswered = true;
        TotalQuestions++;

        // FIX for MVVMTK0034: Use public properties here too
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
        
        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
        _gameState.RecordAnswer(isCorrect);

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.SaveAsync(_gameState);
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

    // FIX 3: Add the missing ResetGame command
    [RelayCommand]
    private async Task ResetGame()
    {
        _gameState.Reset();
        
        CurrentScore = _gameState.CurrentScore;
        CurrentStreak = _gameState.CurrentStreak;
        // BestStreak is preserved in Reset(), so we keep it UI synced
        BestStreak = _gameState.BestStreak;

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.SaveAsync(_gameState);
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));

        GenerateNewQuestion();
    }

    [RelayCommand]
    private void ChangeQuestionType(QuestionType newType)
    {
        SelectedQuestionType = newType;
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

        var indices = Enumerable.Range(0, _countries.Count).OrderBy(_ => _random.Next()).Take(2).ToList();
        
        // Setting these ObservableProperties now updates the UI correctly
        Country1 = _countries[indices[0]];
        Country2 = _countries[indices[1]];

        QuestionText = $"Which country has a higher {SelectedQuestionType.GetLabel()}?";
    }

    private string GetCorrectMessage()
    {
        var messages = new[]
        {
            "🎉 Correct!", "✅ Well done!", "👏 Great job!", "🌟 Excellent!",
            CurrentStreak >= 5 ? $"🔥 {CurrentStreak} in a row!" : "💪 Keep it up!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        return "❌ Not quite! The correct answer is shown above.";
    }
}

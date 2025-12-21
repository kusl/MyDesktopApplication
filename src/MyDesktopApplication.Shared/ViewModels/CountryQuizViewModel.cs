using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game.
/// </summary>
public partial class CountryQuizViewModel : ObservableObject
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private Country? _country1;
    private Country? _country2;
    private GameState _gameState = new();
    private string _selectedQuestionType = "Population";
    
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private string _motivationalMessage = "";
    [ObservableProperty] private bool _showResult;
    [ObservableProperty] private bool _isCorrect;
    [ObservableProperty] private int _score;
    [ObservableProperty] private int _streak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private double _accuracy;
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";

    public ObservableCollection<string> QuestionTypes { get; } = new()
    {
        "Population", "Area", "GDP", "GDP per Capita", 
        "Density", "Literacy", "HDI", "Life Expectancy"
    };

    public string SelectedQuestionType
    {
        get => _selectedQuestionType;
        set
        {
            if (SetProperty(ref _selectedQuestionType, value))
            {
                GenerateNewQuestion();
            }
        }
    }

    public CountryQuizViewModel() : this(null) { }

    public CountryQuizViewModel(IGameStateRepository? gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
        _ = InitializeAsync();
    }

    private async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            _gameState = await _gameStateRepository.GetOrCreateAsync("default");
            UpdateScoreDisplay();
        }
        GenerateNewQuestion();
    }

    private void GenerateNewQuestion()
    {
        var countries = CountryData.Countries.ToList();
        var idx1 = _random.Next(countries.Count);
        int idx2;
        do { idx2 = _random.Next(countries.Count); } while (idx2 == idx1);

        _country1 = countries[idx1];
        _country2 = countries[idx2];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        QuestionText = GetQuestionText();
        ShowResult = false;
        ResultMessage = "";
        MotivationalMessage = "";
        Country1Value = "";
        Country2Value = "";
    }

    private string GetQuestionText() => SelectedQuestionType switch
    {
        "Population" => "Which country has a higher population?",
        "Area" => "Which country is larger by area?",
        "GDP" => "Which country has a higher GDP?",
        "GDP per Capita" => "Which country has a higher GDP per capita?",
        "Density" => "Which country has a higher population density?",
        "Literacy" => "Which country has a higher literacy rate?",
        "HDI" => "Which country has a higher Human Development Index?",
        "Life Expectancy" => "Which country has a higher life expectancy?",
        _ => "Which country has a higher population?"
    };

    private double GetValue(Country country) => SelectedQuestionType switch
    {
        "Population" => country.Population,
        "Area" => country.Area,
        "GDP" => country.Gdp,
        "GDP per Capita" => country.GdpPerCapita,
        "Density" => country.Density,
        "Literacy" => country.Literacy,
        "HDI" => country.Hdi,
        "Life Expectancy" => country.LifeExpectancy,
        _ => country.Population
    };

    private string FormatValue(double value) => SelectedQuestionType switch
    {
        "Population" => value >= 1_000_000_000 ? $"{value / 1_000_000_000:F2}B" :
                        value >= 1_000_000 ? $"{value / 1_000_000:F1}M" :
                        value >= 1_000 ? $"{value / 1_000:F1}K" : $"{value:N0}",
        "Area" => $"{value:N0} km²",
        "GDP" => value >= 1_000_000_000_000 ? $"${value / 1_000_000_000_000:F2}T" :
                 value >= 1_000_000_000 ? $"${value / 1_000_000_000:F1}B" : $"${value / 1_000_000:F0}M",
        "GDP per Capita" => $"${value:N0}",
        "Density" => $"{value:N1}/km²",
        "Literacy" => $"{value:F1}%",
        "HDI" => $"{value:F3}",
        "Life Expectancy" => $"{value:F1} years",
        _ => value.ToString("N0")
    };

    [RelayCommand]
    private async Task SelectCountry1Async()
    {
        await ProcessAnswerAsync(1);
    }

    [RelayCommand]
    private async Task SelectCountry2Async()
    {
        await ProcessAnswerAsync(2);
    }

    private async Task ProcessAnswerAsync(int selection)
    {
        if (_country1 == null || _country2 == null || ShowResult) return;

        var val1 = GetValue(_country1);
        var val2 = GetValue(_country2);
        var correct = val1 > val2 ? 1 : 2;

        IsCorrect = selection == correct;
        _gameState.RecordAnswer(IsCorrect);

        Country1Value = FormatValue(val1);
        Country2Value = FormatValue(val2);

        if (IsCorrect)
        {
            ResultMessage = "✓ Correct!";
            MotivationalMessage = GetCorrectMessage(_gameState.CurrentStreak, _gameState.BestStreak);
        }
        else
        {
            ResultMessage = "✗ Incorrect";
            MotivationalMessage = GetIncorrectMessage();
        }

        ShowResult = true;
        UpdateScoreDisplay();

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.SaveAsync(_gameState);
        }
    }

    private string GetCorrectMessage(int streak, int bestStreak)
    {
        if (streak == bestStreak && streak > 1)
            return $"🏆 NEW RECORD! {streak} in a row!";
        if (streak >= 10) return $"🔥🔥🔥 UNSTOPPABLE! {streak} streak!";
        if (streak >= 5) return $"🔥🔥 On fire! {streak} in a row!";
        if (streak >= 3) return $"🔥 Hot streak! {streak} correct!";
        return new[] { "Great job!", "Well done!", "You got it!", "Excellent!", "Nice one!" }[_random.Next(5)];
    }

    private string GetIncorrectMessage()
    {
        return new[] { 
            "Keep trying!", "You'll get the next one!", 
            "Learning every day!", "Don't give up!", "Almost had it!" 
        }[_random.Next(5)];
    }

    private void UpdateScoreDisplay()
    {
        Score = _gameState.Score;
        Streak = _gameState.CurrentStreak;
        BestStreak = _gameState.BestStreak;
        Accuracy = _gameState.AccuracyPercentage;
    }

    [RelayCommand]
    private void NextQuestion()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private async Task ResetAsync()
    {
        _gameState.Reset();
        UpdateScoreDisplay();
        GenerateNewQuestion();

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.SaveAsync(_gameState);
        }
    }
}

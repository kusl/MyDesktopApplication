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
    
    [ObservableProperty]
    private string _greeting = "Welcome to Country Quiz!";
    
    [ObservableProperty]
    private int _currentScore;
    
    [ObservableProperty]
    private int _highScore;
    
    [ObservableProperty]
    private int _currentStreak;
    
    [ObservableProperty]
    private int _bestStreak;
    
    [ObservableProperty]
    private string _questionText = "Loading...";
    
    [ObservableProperty]
    private string _feedbackMessage = "";
    
    [ObservableProperty]
    private bool _showFeedback;
    
    [ObservableProperty]
    private ObservableCollection<string> _answerOptions = new();
    
    [ObservableProperty]
    private Country? _currentCountryA;
    
    [ObservableProperty]
    private Country? _currentCountryB;
    
    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;
    
    public MainWindowViewModel()
    {
        // Design-time constructor
    }
    
    public MainWindowViewModel(IGameStateRepository gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
    }
    
    /// <summary>
    /// Initializes the ViewModel by loading game state
    /// </summary>
    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            _gameState = await _gameStateRepository.GetOrCreateAsync("default");
            UpdateScoresFromGameState();
        }
        
        GenerateNewQuestion();
    }
    
    private void UpdateScoresFromGameState()
    {
        CurrentScore = _gameState.CurrentScore;
        HighScore = _gameState.HighScore;
        CurrentStreak = _gameState.CurrentStreak;
        BestStreak = _gameState.BestStreak;
    }
    
    private void GenerateNewQuestion()
    {
        var countries = CountryData.GetAllCountries();
        var random = new Random();
        
        // Pick two different random countries
        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => random.Next())
            .Take(2)
            .ToList();
        
        CurrentCountryA = countries[indices[0]];
        CurrentCountryB = countries[indices[1]];
        
        QuestionText = GetQuestionText();
        
        AnswerOptions.Clear();
        AnswerOptions.Add(CurrentCountryA.Name);
        AnswerOptions.Add(CurrentCountryB.Name);
        
        ShowFeedback = false;
    }
    
    private string GetQuestionText()
    {
        return SelectedQuestionType switch
        {
            QuestionType.Population => "Which country has a larger population?",
            QuestionType.Area => "Which country has a larger area?",
            QuestionType.GdpTotal=> "Which country has a higher GDP?",
            QuestionType.GdpPerCapita => "Which country has a higher GDP per capita?",
            QuestionType.PopulationDensity => "Which country has a higher population density?",
            QuestionType.LiteracyRate => "Which country has a higher literacy rate?",
            QuestionType.Hdi => "Which country has a higher Human Development Index?",
            QuestionType.LifeExpectancy => "Which country has a higher life expectancy?",
            _ => "Which country has a larger population?"
        };
    }
    
    private double GetValue(Country country)
    {
        return SelectedQuestionType switch
        {
            QuestionType.Population => country.Population,
            QuestionType.Area => country.Area,
            QuestionType.GdpTotal=> country.GdpTotal,
            QuestionType.GdpPerCapita => country.GdpPerCapita,
            QuestionType.PopulationDensity => country.PopulationDensity,
            QuestionType.LiteracyRate => country.LiteracyRate,
            QuestionType.Hdi => country.Hdi,
            QuestionType.LifeExpectancy => country.LifeExpectancy,
            _ => country.Population
        };
    }
    
    [RelayCommand]
    private async Task SelectAnswer(string answer)
    {
        if (CurrentCountryA == null || CurrentCountryB == null)
            return;
        
        var valueA = GetValue(CurrentCountryA);
        var valueB = GetValue(CurrentCountryB);
        
        var correctCountry = valueA >= valueB ? CurrentCountryA : CurrentCountryB;
        var isCorrect = answer == correctCountry.Name;
        
        _gameState.RecordAnswer(isCorrect);
        UpdateScoresFromGameState();
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }
        
        FeedbackMessage = isCorrect 
            ? GetCorrectMessage() 
            : GetIncorrectMessage(correctCountry.Name);
        ShowFeedback = true;
        
        // Wait a moment then show next question
        await Task.Delay(1500);
        GenerateNewQuestion();
    }
    
    private string GetCorrectMessage()
    {
        var messages = new[]
        {
            "Correct! 🎉",
            "Well done! 👏",
            "You got it! ✨",
            "Excellent! 🌟",
            "Right on! 💪"
        };
        
        if (CurrentStreak >= 5)
            return $"🔥 {CurrentStreak} in a row! Amazing!";
        
        return messages[new Random().Next(messages.Length)];
    }
    
    private string GetIncorrectMessage(string correctAnswer)
    {
        return $"Not quite. The answer was {correctAnswer}. Keep going! 💪";
    }
    
    [RelayCommand]
    private async Task ResetGame()
    {
        _gameState.Reset();
        UpdateScoresFromGameState();
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }
        
        GenerateNewQuestion();
    }
}

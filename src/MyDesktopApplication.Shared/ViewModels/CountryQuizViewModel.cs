using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game
/// </summary>
public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private Country? _currentCountry;
    private QuestionType _currentQuestionType;
    private readonly List<Country> _countries;
    
    [ObservableProperty]
    private string _questionText = string.Empty;
    
    [ObservableProperty]
    private string _option1 = string.Empty;
    
    [ObservableProperty]
    private string _option2 = string.Empty;
    
    [ObservableProperty]
    private string _option3 = string.Empty;
    
    [ObservableProperty]
    private string _option4 = string.Empty;
    
    [ObservableProperty]
    private string _feedbackMessage = string.Empty;
    
    [ObservableProperty]
    private bool _showFeedback;
    
    [ObservableProperty]
    private bool _isCorrectAnswer;
    
    [ObservableProperty]
    private int _currentScore;
    
    [ObservableProperty]
    private int _highScore;
    
    [ObservableProperty]
    private int _currentStreak;
    
    [ObservableProperty]
    private int _bestStreak;
    
    [ObservableProperty]
    private int _totalCorrect;
    
    [ObservableProperty]
    private int _totalAnswered;
    
    [ObservableProperty]
    private QuestionType? _selectedQuestionType;
    
    public double AccuracyPercentage => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered * 100 : 0;
    
    public CountryQuizViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        GenerateNewQuestion();
    }
    
    [RelayCommand]
    private void SelectAnswer(string answer)
    {
        if (_currentCountry == null) return;
        
        var correctValue = GetValue(_currentQuestionType, _currentCountry);
        var correctAnswer = FormatValue(_currentQuestionType, correctValue);
        var isCorrect = answer == correctAnswer;
        
        TotalAnswered++;
        OnPropertyChanged(nameof(AccuracyPercentage));
        
        if (isCorrect)
        {
            TotalCorrect++;
            CurrentScore++;
            CurrentStreak++;
            
            if (CurrentScore > HighScore)
                HighScore = CurrentScore;
            
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
            
            FeedbackMessage = GetCorrectMessage(CurrentStreak, BestStreak);
            IsCorrectAnswer = true;
        }
        else
        {
            CurrentStreak = 0;
            FeedbackMessage = $"Wrong! The correct answer was {correctAnswer}.";
            IsCorrectAnswer = false;
        }
        
        ShowFeedback = true;
    }
    
    [RelayCommand]
    private void NextQuestion()
    {
        ShowFeedback = false;
        GenerateNewQuestion();
    }
    
    [RelayCommand]
    private void ResetGame()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalCorrect = 0;
        TotalAnswered = 0;
        ShowFeedback = false;
        OnPropertyChanged(nameof(AccuracyPercentage));
        GenerateNewQuestion();
    }
    
    private void GenerateNewQuestion()
    {
        if (_countries.Count < 4) return;
        
        // Select question type
        var questionTypes = Enum.GetValues<QuestionType>();
        if (SelectedQuestionType.HasValue)
        {
            _currentQuestionType = SelectedQuestionType.Value;
        }
        else
        {
            _currentQuestionType = questionTypes[_random.Next(questionTypes.Length)];
        }
        
        // Select 4 random countries
        var selectedCountries = _countries
            .OrderBy(_ => _random.Next())
            .Take(4)
            .ToList();
        
        // Pick one as the correct answer
        _currentCountry = selectedCountries[_random.Next(4)];
        
        // Generate question text
        QuestionText = $"What is the {GetLabel(_currentQuestionType)} of {_currentCountry.Name}?";
        
        // Generate options
        var options = selectedCountries
            .Select(c => FormatValue(_currentQuestionType, GetValue(_currentQuestionType, c)))
            .ToList();
        
        Option1 = options[0];
        Option2 = options[1];
        Option3 = options[2];
        Option4 = options[3];
    }
    
    private static string GetLabel(QuestionType type) => type switch
    {
        QuestionType.Population => "population",
        QuestionType.Area => "area (km²)",
        QuestionType.GdpTotal=> "GDP",
        QuestionType.GdpPerCapita => "GDP per capita",
        QuestionType.PopulationDensity => "population density",
        QuestionType.LiteracyRate => "literacy rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "life expectancy",
        _ => "value"
    };
    
    private static double GetValue(QuestionType type, Country country) => type switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.GdpTotal=> country.GdpTotal,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.PopulationDensity => country.PopulationDensity,
        QuestionType.LiteracyRate => country.LiteracyRate,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };
    
    private static string FormatValue(QuestionType type, double value) => type switch
    {
        QuestionType.Population => FormatPopulation(value),
        QuestionType.Area => $"{value:N0} km²",
        QuestionType.GdpTotal=> FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.LiteracyRate => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N0")
    };
    
    private static string FormatPopulation(double value)
    {
        return value switch
        {
            >= 1_000_000_000 => $"{value / 1_000_000_000:N2}B",
            >= 1_000_000 => $"{value / 1_000_000:N2}M",
            >= 1_000 => $"{value / 1_000:N1}K",
            _ => value.ToString("N0")
        };
    }
    
    private static string FormatCurrency(double value)
    {
        return value switch
        {
            >= 1_000_000_000_000 => $"${value / 1_000_000_000_000:N2}T",
            >= 1_000_000_000 => $"${value / 1_000_000_000:N2}B",
            >= 1_000_000 => $"${value / 1_000_000:N2}M",
            _ => $"${value:N0}"
        };
    }
    
    private static string GetCorrectMessage(int streak, int bestStreak)
    {
        if (streak >= 10)
            return $"🔥 UNSTOPPABLE! {streak} in a row!";
        if (streak >= 5)
            return $"🎯 Amazing! {streak} streak!";
        if (streak == bestStreak && streak > 1)
            return $"⭐ New personal best: {streak}!";
        if (streak > 1)
            return $"✓ Correct! {streak} in a row!";
        return "✓ Correct!";
    }
}

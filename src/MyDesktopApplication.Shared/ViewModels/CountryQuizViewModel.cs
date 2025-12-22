using System.Collections.ObjectModel;
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
    private Country? _countryA;
    private Country? _countryB;
    
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _feedbackMessage = "";
    [ObservableProperty] private bool _showFeedback;
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;
    
    public string Country1Name => _countryA?.Name ?? "";
    public string Country2Name => _countryB?.Name ?? "";
    public string Country1Flag => _countryA?.Flag ?? "🏳️";
    public string Country2Flag => _countryB?.Flag ?? "🏳️";
    
    public ObservableCollection<QuestionType> QuestionTypes { get; } = 
        new(Enum.GetValues<QuestionType>());
    
    public CountryQuizViewModel()
    {
        GenerateNewQuestion();
    }
    
    [RelayCommand]
    private void GenerateNewQuestion()
    {
        var countries = CountryData.GetAllCountries();
        if (countries.Count < 2) return;
        
        // Pick two different random countries
        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();
        
        _countryA = countries[indices[0]];
        _countryB = countries[indices[1]];
        _currentCountry = _countryA; // Track the "correct" country for this round
        
        QuestionText = $"Which country has higher {SelectedQuestionType.GetLabel()}?";
        ShowFeedback = false;
        
        OnPropertyChanged(nameof(Country1Name));
        OnPropertyChanged(nameof(Country2Name));
        OnPropertyChanged(nameof(Country1Flag));
        OnPropertyChanged(nameof(Country2Flag));
    }
    
    [RelayCommand]
    private async Task SelectCountry(string countryParam)
    {
        if (_countryA == null || _countryB == null) return;
        
        bool selectedCountry1 = countryParam == "1";
        
        var valueA = GetValue(_countryA);
        var valueB = GetValue(_countryB);
        
        bool isCorrect = selectedCountry1 ? (valueA >= valueB) : (valueB >= valueA);
        
        if (isCorrect)
        {
            CurrentScore++;
            CurrentStreak++;
            if (CurrentScore > HighScore) HighScore = CurrentScore;
            if (CurrentStreak > BestStreak) BestStreak = CurrentStreak;
            FeedbackMessage = GetCorrectMessage(CurrentStreak, BestStreak);
        }
        else
        {
            CurrentStreak = 0;
            var winner = valueA >= valueB ? _countryA : _countryB;
            var winnerValue = FormatValue(Math.Max(valueA, valueB));
            var loserValue = FormatValue(Math.Min(valueA, valueB));
            FeedbackMessage = $"Wrong! {winner.Name} has {winnerValue} vs {loserValue}";
        }
        
        ShowFeedback = true;
        await Task.Delay(1500);
        GenerateNewQuestion();
    }
    
    [RelayCommand]
    private void ResetGame()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        ShowFeedback = false;
        GenerateNewQuestion();
    }
    
    private double GetValue(Country country) => SelectedQuestionType switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.GdpTotal => country.GdpTotal,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.PopulationDensity => country.PopulationDensity,
        QuestionType.LiteracyRate => country.LiteracyRate,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };
    
    private string FormatValue(double value) => SelectedQuestionType switch
    {
        QuestionType.Population => FormatPopulation(value),
        QuestionType.Area => $"{value:N0} km²",
        QuestionType.GdpTotal => FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.LiteracyRate => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N0")
    };
    
    private static string FormatPopulation(double value)
    {
        if (value >= 1_000_000_000) return $"{value / 1_000_000_000:N2}B";
        if (value >= 1_000_000) return $"{value / 1_000_000:N1}M";
        if (value >= 1_000) return $"{value / 1_000:N0}K";
        return value.ToString("N0");
    }
    
    private static string FormatCurrency(double value)
    {
        if (value >= 1_000_000_000_000) return $"${value / 1_000_000_000_000:N2}T";
        if (value >= 1_000_000_000) return $"${value / 1_000_000_000:N2}B";
        if (value >= 1_000_000) return $"${value / 1_000_000:N1}M";
        return $"${value:N0}";
    }
    
    private static string GetCorrectMessage(int streak, int bestStreak)
    {
        if (streak >= 10) return $"🔥 INCREDIBLE! {streak} in a row!";
        if (streak >= 5) return $"🎯 Amazing! {streak} streak!";
        if (streak >= 3) return $"✨ Nice! {streak} in a row!";
        if (streak == bestStreak && streak > 1) return $"🏆 New best streak: {streak}!";
        return "✓ Correct!";
    }
}

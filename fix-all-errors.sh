#!/bin/bash
set -e

# =============================================================================
# COMPREHENSIVE FIX SCRIPT - Fixes ALL build errors
# =============================================================================
# Based on output.txt error analysis:
# - 28 XAML binding errors (missing properties on MainWindowViewModel)
# - 11 test errors (wrong property names)
# =============================================================================

echo "=============================================="
echo "  Comprehensive Build Fix Script"
echo "=============================================="
echo ""
echo "This script fixes ALL errors from output.txt:"
echo "  - MainWindowViewModel missing XAML bindings"
echo "  - Test files with wrong property names"
echo "  - Property name harmonization"
echo ""

cd "$(dirname "$0")"

# -----------------------------------------------------------------------------
# Step 0: Kill stuck processes and clean
# -----------------------------------------------------------------------------
echo "[0/8] Killing stuck processes and cleaning..."
pkill -f "VBCSCompiler" 2>/dev/null || true
pkill -f "aapt2" 2>/dev/null || true
pkill -f "dotnet.*build" 2>/dev/null || true
sleep 1

rm -rf src/*/bin src/*/obj tests/*/bin tests/*/obj 2>/dev/null || true

# -----------------------------------------------------------------------------
# Step 1: Fix Country.cs - Add Flag property
# -----------------------------------------------------------------------------
echo "[1/8] Fixing Country.cs..."
mkdir -p src/MyDesktopApplication.Core/Entities

cat > src/MyDesktopApplication.Core/Entities/Country.cs << 'COUNTRYEOF'
namespace MyDesktopApplication.Core.Entities;

public class Country
{
    public required string Code { get; set; }
    public required string Name { get; set; }
    public string Iso2 { get; set; } = "";
    public string Continent { get; set; } = "";
    public long Population { get; set; }
    public double Area { get; set; }
    public double GdpTotal { get; set; }
    public double GdpPerCapita { get; set; }
    public double PopulationDensity { get; set; }
    public double LiteracyRate { get; set; }
    public double Hdi { get; set; }
    public double LifeExpectancy { get; set; }
    
    // Flag emoji based on ISO2 code
    public string Flag => string.IsNullOrEmpty(Iso2) ? "🏳️" : 
        string.Concat(Iso2.ToUpperInvariant().Select(c => char.ConvertFromUtf32(c + 0x1F1A5)));
}
COUNTRYEOF

# -----------------------------------------------------------------------------
# Step 2: Fix QuestionType.cs with extension methods
# -----------------------------------------------------------------------------
echo "[2/8] Fixing QuestionType.cs..."

cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'QUESTIONTYPEEOF'
namespace MyDesktopApplication.Core.Entities;

public enum QuestionType
{
    Population,
    Area,
    GdpTotal,
    GdpPerCapita,
    PopulationDensity,
    LiteracyRate,
    Hdi,
    LifeExpectancy
}

public static class QuestionTypeExtensions
{
    public static string GetLabel(this QuestionType questionType) => questionType switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.GdpTotal => "GDP (Total USD)",
        QuestionType.GdpPerCapita => "GDP per Capita (USD)",
        QuestionType.PopulationDensity => "Population Density (per km²)",
        QuestionType.LiteracyRate => "Literacy Rate (%)",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy (years)",
        _ => questionType.ToString()
    };

    public static double GetValue(this QuestionType questionType, Country country) => questionType switch
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

    public static string FormatValue(this QuestionType questionType, double value) => questionType switch
    {
        QuestionType.Population => FormatLargeNumber(value),
        QuestionType.Area => $"{value:N0} km²",
        QuestionType.GdpTotal => FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.LiteracyRate => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N0")
    };

    private static string FormatLargeNumber(double value)
    {
        if (value >= 1_000_000_000) return $"{value / 1_000_000_000:N2}B";
        if (value >= 1_000_000) return $"{value / 1_000_000:N2}M";
        if (value >= 1_000) return $"{value / 1_000:N2}K";
        return value.ToString("N0");
    }

    private static string FormatCurrency(double value)
    {
        if (value >= 1_000_000_000_000) return $"${value / 1_000_000_000_000:N2}T";
        if (value >= 1_000_000_000) return $"${value / 1_000_000_000:N2}B";
        if (value >= 1_000_000) return $"${value / 1_000_000:N2}M";
        return $"${value:N0}";
    }
}
QUESTIONTYPEEOF

# -----------------------------------------------------------------------------
# Step 3: Fix GameState.cs
# -----------------------------------------------------------------------------
echo "[3/8] Fixing GameState.cs..."

cat > src/MyDesktopApplication.Core/Entities/GameState.cs << 'GAMESTATEEOF'
namespace MyDesktopApplication.Core.Entities;

public class GameState
{
    public int Id { get; set; }
    public string UserId { get; set; } = "default";
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    public QuestionType? SelectedQuestionType { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public double AccuracyPercentage => Accuracy * 100;

    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        if (isCorrect)
        {
            TotalCorrect++;
            CurrentScore++;
            CurrentStreak++;
            if (CurrentScore > HighScore) HighScore = CurrentScore;
            if (CurrentStreak > BestStreak) BestStreak = CurrentStreak;
        }
        else
        {
            CurrentStreak = 0;
        }
        UpdatedAt = DateTime.UtcNow;
    }

    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Note: HighScore and BestStreak are preserved
        UpdatedAt = DateTime.UtcNow;
    }
}
GAMESTATEEOF

# -----------------------------------------------------------------------------
# Step 4: Fix IGameStateRepository.cs - inherit from IRepository
# -----------------------------------------------------------------------------
echo "[4/8] Fixing IGameStateRepository.cs..."

cat > src/MyDesktopApplication.Core/Interfaces/IGameStateRepository.cs << 'IGAMESTATEEOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

public interface IGameStateRepository : IRepository<GameState>
{
    Task<GameState> GetOrCreateAsync(string userId, CancellationToken cancellationToken = default);
    Task SaveAsync(GameState gameState, CancellationToken cancellationToken = default);
}
IGAMESTATEEOF

# -----------------------------------------------------------------------------
# Step 5: Fix MainWindowViewModel.cs - Add ALL missing properties for XAML
# -----------------------------------------------------------------------------
echo "[5/8] Fixing MainWindowViewModel.cs (COMPLETE rewrite with ALL bindings)..."

cat > src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs << 'VIEWMODELEOF'
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

    // =========================================================================
    // Observable Properties (backing fields auto-generated by CommunityToolkit)
    // =========================================================================
    
    [ObservableProperty] private string _greeting = "Welcome to Country Quiz!";
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private string _questionText = "Which country has higher...";
    [ObservableProperty] private string _feedbackMessage = "";
    [ObservableProperty] private bool _showFeedback;
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;
    
    // The two countries being compared
    [ObservableProperty] private Country? _country1;
    [ObservableProperty] private Country? _country2;
    
    // Has the user answered the current question?
    [ObservableProperty] private bool _hasAnswered;
    
    // Result message after answering
    [ObservableProperty] private string _resultMessage = "";
    
    // Visual feedback for correct/wrong answers
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;
    
    // Formatted values shown after answering
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";

    // =========================================================================
    // Computed Properties for UI Binding
    // =========================================================================
    
    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => _gameState.TotalAnswered > 0 
        ? $"Accuracy: {_gameState.AccuracyPercentage:F1}%" 
        : "Accuracy: --";
    
    // Question type dropdown options
    public ObservableCollection<QuestionType> QuestionTypes { get; } = 
        new(Enum.GetValues<QuestionType>());

    // =========================================================================
    // Constructors
    // =========================================================================
    
    public MainWindowViewModel() 
    {
        // Design-time / parameterless constructor
        GenerateNewQuestion();
    }
    
    public MainWindowViewModel(IGameStateRepository gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
    }

    // =========================================================================
    // Initialization
    // =========================================================================
    
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
        
        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    // =========================================================================
    // Commands
    // =========================================================================
    
    [RelayCommand]
    private void GenerateNewQuestion()
    {
        var countries = CountryData.GetAllCountries();
        
        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        Country1 = countries[indices[0]];
        Country2 = countries[indices[1]];
        
        QuestionText = $"Which country has higher {SelectedQuestionType.GetLabel()}?";
        
        // Reset answer state
        HasAnswered = false;
        ResultMessage = "";
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;
        Country1Value = "";
        Country2Value = "";
    }
    
    [RelayCommand]
    private async Task SelectCountry(string countryParam)
    {
        if (Country1 == null || Country2 == null || HasAnswered) return;

        bool selectedCountry1 = countryParam == "1";
        
        var val1 = SelectedQuestionType.GetValue(Country1);
        var val2 = SelectedQuestionType.GetValue(Country2);
        
        bool country1IsHigher = val1 >= val2;
        bool isCorrect = selectedCountry1 == country1IsHigher;
        
        // Record the answer
        _gameState.RecordAnswer(isCorrect);
        UpdateScoresFromGameState();
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }
        
        // Update UI state
        HasAnswered = true;
        Country1Value = SelectedQuestionType.FormatValue(val1);
        Country2Value = SelectedQuestionType.FormatValue(val2);
        
        // Set visual feedback
        if (country1IsHigher)
        {
            IsCountry1Correct = true;
            IsCountry2Wrong = !isCorrect && !selectedCountry1;
        }
        else
        {
            IsCountry2Correct = true;
            IsCountry1Wrong = !isCorrect && selectedCountry1;
        }
        
        // Set result message
        ResultMessage = isCorrect 
            ? GetCorrectMessage() 
            : GetIncorrectMessage();
    }
    
    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
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

    // =========================================================================
    // Helper Methods
    // =========================================================================
    
    private string GetCorrectMessage()
    {
        if (CurrentStreak >= 10) return "🔥 UNSTOPPABLE! 10+ streak!";
        if (CurrentStreak >= 5) return "🔥 On fire! 5+ streak!";
        if (CurrentStreak >= 3) return "🎯 Nice streak!";
        if (CurrentScore > _gameState.HighScore - 1) return "🏆 NEW HIGH SCORE!";
        return "✅ Correct!";
    }
    
    private string GetIncorrectMessage()
    {
        if (CurrentStreak == 0 && _gameState.TotalAnswered > 5)
            return "❌ Wrong! Keep trying!";
        return "❌ Wrong!";
    }
}
VIEWMODELEOF

# -----------------------------------------------------------------------------
# Step 6: Fix CountryData.cs
# -----------------------------------------------------------------------------
echo "[6/8] Fixing CountryData.cs..."
mkdir -p src/MyDesktopApplication.Shared/Data

cat > src/MyDesktopApplication.Shared/Data/CountryData.cs << 'COUNTRYDATAEOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Data;

public static class CountryData
{
    private static readonly List<Country> _countries = new()
    {
        new() { Code = "USA", Name = "United States", Iso2 = "US", Continent = "North America", Population = 331900000, Area = 9833520, GdpTotal = 25462700, GdpPerCapita = 76330, PopulationDensity = 33.6, LiteracyRate = 99.0, Hdi = 0.921, LifeExpectancy = 77.0 },
        new() { Code = "CHN", Name = "China", Iso2 = "CN", Continent = "Asia", Population = 1412000000, Area = 9596960, GdpTotal = 17963200, GdpPerCapita = 12720, PopulationDensity = 147.0, LiteracyRate = 96.8, Hdi = 0.768, LifeExpectancy = 78.2 },
        new() { Code = "IND", Name = "India", Iso2 = "IN", Continent = "Asia", Population = 1408000000, Area = 3287263, GdpTotal = 3385090, GdpPerCapita = 2410, PopulationDensity = 428.0, LiteracyRate = 74.4, Hdi = 0.633, LifeExpectancy = 70.4 },
        new() { Code = "JPN", Name = "Japan", Iso2 = "JP", Continent = "Asia", Population = 125700000, Area = 377975, GdpTotal = 4231140, GdpPerCapita = 33650, PopulationDensity = 332.0, LiteracyRate = 99.0, Hdi = 0.925, LifeExpectancy = 84.6 },
        new() { Code = "DEU", Name = "Germany", Iso2 = "DE", Continent = "Europe", Population = 83200000, Area = 357022, GdpTotal = 4072190, GdpPerCapita = 48720, PopulationDensity = 233.0, LiteracyRate = 99.0, Hdi = 0.942, LifeExpectancy = 81.3 },
        new() { Code = "GBR", Name = "United Kingdom", Iso2 = "GB", Continent = "Europe", Population = 67330000, Area = 243610, GdpTotal = 3070670, GdpPerCapita = 45850, PopulationDensity = 276.0, LiteracyRate = 99.0, Hdi = 0.929, LifeExpectancy = 81.2 },
        new() { Code = "FRA", Name = "France", Iso2 = "FR", Continent = "Europe", Population = 67750000, Area = 643801, GdpTotal = 2782910, GdpPerCapita = 42330, PopulationDensity = 105.0, LiteracyRate = 99.0, Hdi = 0.903, LifeExpectancy = 82.7 },
        new() { Code = "ITA", Name = "Italy", Iso2 = "IT", Continent = "Europe", Population = 59110000, Area = 301340, GdpTotal = 2010430, GdpPerCapita = 34010, PopulationDensity = 196.0, LiteracyRate = 99.2, Hdi = 0.895, LifeExpectancy = 83.5 },
        new() { Code = "CAN", Name = "Canada", Iso2 = "CA", Continent = "North America", Population = 38250000, Area = 9984670, GdpTotal = 2139840, GdpPerCapita = 55960, PopulationDensity = 3.8, LiteracyRate = 99.0, Hdi = 0.936, LifeExpectancy = 82.4 },
        new() { Code = "AUS", Name = "Australia", Iso2 = "AU", Continent = "Oceania", Population = 25690000, Area = 7692024, GdpTotal = 1675420, GdpPerCapita = 65210, PopulationDensity = 3.3, LiteracyRate = 99.0, Hdi = 0.951, LifeExpectancy = 83.4 },
        new() { Code = "KOR", Name = "South Korea", Iso2 = "KR", Continent = "Asia", Population = 51740000, Area = 100210, GdpTotal = 1804680, GdpPerCapita = 34870, PopulationDensity = 516.0, LiteracyRate = 99.0, Hdi = 0.925, LifeExpectancy = 83.7 },
        new() { Code = "BRA", Name = "Brazil", Iso2 = "BR", Continent = "South America", Population = 214300000, Area = 8515767, GdpTotal = 1920100, GdpPerCapita = 8920, PopulationDensity = 25.0, LiteracyRate = 93.2, Hdi = 0.754, LifeExpectancy = 75.9 },
        new() { Code = "RUS", Name = "Russia", Iso2 = "RU", Continent = "Europe", Population = 144100000, Area = 17098242, GdpTotal = 2240420, GdpPerCapita = 15270, PopulationDensity = 8.4, LiteracyRate = 99.7, Hdi = 0.822, LifeExpectancy = 73.2 },
        new() { Code = "MEX", Name = "Mexico", Iso2 = "MX", Continent = "North America", Population = 130300000, Area = 1964375, GdpTotal = 1293040, GdpPerCapita = 10040, PopulationDensity = 66.0, LiteracyRate = 95.4, Hdi = 0.758, LifeExpectancy = 75.0 },
        new() { Code = "ESP", Name = "Spain", Iso2 = "ES", Continent = "Europe", Population = 47420000, Area = 505992, GdpTotal = 1397510, GdpPerCapita = 29450, PopulationDensity = 94.0, LiteracyRate = 98.4, Hdi = 0.905, LifeExpectancy = 83.6 },
        new() { Code = "IDN", Name = "Indonesia", Iso2 = "ID", Continent = "Asia", Population = 273800000, Area = 1904569, GdpTotal = 1319100, GdpPerCapita = 4790, PopulationDensity = 144.0, LiteracyRate = 96.0, Hdi = 0.705, LifeExpectancy = 71.9 },
        new() { Code = "TUR", Name = "Turkey", Iso2 = "TR", Continent = "Asia", Population = 84780000, Area = 783562, GdpTotal = 905990, GdpPerCapita = 10670, PopulationDensity = 108.0, LiteracyRate = 96.7, Hdi = 0.838, LifeExpectancy = 78.0 },
        new() { Code = "NLD", Name = "Netherlands", Iso2 = "NL", Continent = "Europe", Population = 17440000, Area = 41543, GdpTotal = 991110, GdpPerCapita = 56490, PopulationDensity = 420.0, LiteracyRate = 99.0, Hdi = 0.941, LifeExpectancy = 82.3 },
        new() { Code = "SAU", Name = "Saudi Arabia", Iso2 = "SA", Continent = "Asia", Population = 34810000, Area = 2149690, GdpTotal = 1061900, GdpPerCapita = 27540, PopulationDensity = 16.0, LiteracyRate = 97.6, Hdi = 0.875, LifeExpectancy = 76.9 },
        new() { Code = "CHE", Name = "Switzerland", Iso2 = "CH", Continent = "Europe", Population = 8700000, Area = 41285, GdpTotal = 807710, GdpPerCapita = 92100, PopulationDensity = 211.0, LiteracyRate = 99.0, Hdi = 0.962, LifeExpectancy = 84.0 },
        new() { Code = "POL", Name = "Poland", Iso2 = "PL", Continent = "Europe", Population = 37950000, Area = 312696, GdpTotal = 688180, GdpPerCapita = 18000, PopulationDensity = 121.0, LiteracyRate = 99.8, Hdi = 0.876, LifeExpectancy = 78.7 },
        new() { Code = "SWE", Name = "Sweden", Iso2 = "SE", Continent = "Europe", Population = 10420000, Area = 450295, GdpTotal = 585940, GdpPerCapita = 55690, PopulationDensity = 23.0, LiteracyRate = 99.0, Hdi = 0.947, LifeExpectancy = 83.0 },
        new() { Code = "NOR", Name = "Norway", Iso2 = "NO", Continent = "Europe", Population = 5470000, Area = 385207, GdpTotal = 579270, GdpPerCapita = 106150, PopulationDensity = 14.0, LiteracyRate = 99.0, Hdi = 0.961, LifeExpectancy = 83.2 },
        new() { Code = "NGA", Name = "Nigeria", Iso2 = "NG", Continent = "Africa", Population = 218500000, Area = 923768, GdpTotal = 477380, GdpPerCapita = 2180, PopulationDensity = 236.0, LiteracyRate = 62.0, Hdi = 0.535, LifeExpectancy = 55.0 },
        new() { Code = "EGY", Name = "Egypt", Iso2 = "EG", Continent = "Africa", Population = 104300000, Area = 1001450, GdpTotal = 404140, GdpPerCapita = 3900, PopulationDensity = 104.0, LiteracyRate = 71.2, Hdi = 0.731, LifeExpectancy = 72.0 },
        new() { Code = "ZAF", Name = "South Africa", Iso2 = "ZA", Continent = "Africa", Population = 60040000, Area = 1221037, GdpTotal = 405870, GdpPerCapita = 6780, PopulationDensity = 49.0, LiteracyRate = 95.0, Hdi = 0.713, LifeExpectancy = 65.3 },
        new() { Code = "ARG", Name = "Argentina", Iso2 = "AR", Continent = "South America", Population = 45810000, Area = 2780400, GdpTotal = 632770, GdpPerCapita = 13650, PopulationDensity = 16.0, LiteracyRate = 99.0, Hdi = 0.842, LifeExpectancy = 77.3 },
        new() { Code = "THA", Name = "Thailand", Iso2 = "TH", Continent = "Asia", Population = 69950000, Area = 513120, GdpTotal = 534760, GdpPerCapita = 7650, PopulationDensity = 136.0, LiteracyRate = 93.8, Hdi = 0.800, LifeExpectancy = 79.3 },
        new() { Code = "VNM", Name = "Vietnam", Iso2 = "VN", Continent = "Asia", Population = 98170000, Area = 331212, GdpTotal = 408800, GdpPerCapita = 4160, PopulationDensity = 296.0, LiteracyRate = 95.8, Hdi = 0.703, LifeExpectancy = 75.8 },
        new() { Code = "PHL", Name = "Philippines", Iso2 = "PH", Continent = "Asia", Population = 113880000, Area = 300000, GdpTotal = 404280, GdpPerCapita = 3550, PopulationDensity = 380.0, LiteracyRate = 96.3, Hdi = 0.699, LifeExpectancy = 72.1 },
        new() { Code = "PAK", Name = "Pakistan", Iso2 = "PK", Continent = "Asia", Population = 231400000, Area = 881913, GdpTotal = 376530, GdpPerCapita = 1600, PopulationDensity = 262.0, LiteracyRate = 59.1, Hdi = 0.544, LifeExpectancy = 67.3 },
        new() { Code = "BGD", Name = "Bangladesh", Iso2 = "BD", Continent = "Asia", Population = 169400000, Area = 147570, GdpTotal = 416260, GdpPerCapita = 2460, PopulationDensity = 1148.0, LiteracyRate = 74.7, Hdi = 0.661, LifeExpectancy = 72.4 },
        new() { Code = "COL", Name = "Colombia", Iso2 = "CO", Continent = "South America", Population = 51870000, Area = 1141748, GdpTotal = 343940, GdpPerCapita = 6630, PopulationDensity = 45.0, LiteracyRate = 95.6, Hdi = 0.752, LifeExpectancy = 77.3 },
        new() { Code = "CHL", Name = "Chile", Iso2 = "CL", Continent = "South America", Population = 19490000, Area = 756102, GdpTotal = 301030, GdpPerCapita = 15360, PopulationDensity = 26.0, LiteracyRate = 96.9, Hdi = 0.855, LifeExpectancy = 80.2 },
        new() { Code = "PER", Name = "Peru", Iso2 = "PE", Continent = "South America", Population = 33720000, Area = 1285216, GdpTotal = 242630, GdpPerCapita = 7190, PopulationDensity = 26.0, LiteracyRate = 94.5, Hdi = 0.762, LifeExpectancy = 77.0 },
        new() { Code = "MYS", Name = "Malaysia", Iso2 = "MY", Continent = "Asia", Population = 32780000, Area = 330803, GdpTotal = 407030, GdpPerCapita = 12420, PopulationDensity = 99.0, LiteracyRate = 95.0, Hdi = 0.803, LifeExpectancy = 76.2 },
        new() { Code = "SGP", Name = "Singapore", Iso2 = "SG", Continent = "Asia", Population = 5450000, Area = 733, GdpTotal = 423800, GdpPerCapita = 78060, PopulationDensity = 7437.0, LiteracyRate = 97.5, Hdi = 0.939, LifeExpectancy = 84.1 },
        new() { Code = "NZL", Name = "New Zealand", Iso2 = "NZ", Continent = "Oceania", Population = 5130000, Area = 268021, GdpTotal = 247230, GdpPerCapita = 48350, PopulationDensity = 19.0, LiteracyRate = 99.0, Hdi = 0.937, LifeExpectancy = 82.5 },
        new() { Code = "IRL", Name = "Ireland", Iso2 = "IE", Continent = "Europe", Population = 5060000, Area = 70273, GdpTotal = 529240, GdpPerCapita = 103180, PopulationDensity = 72.0, LiteracyRate = 99.0, Hdi = 0.945, LifeExpectancy = 82.8 },
        new() { Code = "ISR", Name = "Israel", Iso2 = "IL", Continent = "Asia", Population = 9370000, Area = 22072, GdpTotal = 525000, GdpPerCapita = 54930, PopulationDensity = 425.0, LiteracyRate = 97.8, Hdi = 0.919, LifeExpectancy = 83.5 },
        new() { Code = "GRC", Name = "Greece", Iso2 = "GR", Continent = "Europe", Population = 10640000, Area = 131957, GdpTotal = 218010, GdpPerCapita = 20470, PopulationDensity = 81.0, LiteracyRate = 97.9, Hdi = 0.887, LifeExpectancy = 81.4 },
        new() { Code = "PRT", Name = "Portugal", Iso2 = "PT", Continent = "Europe", Population = 10270000, Area = 92212, GdpTotal = 251920, GdpPerCapita = 24540, PopulationDensity = 111.0, LiteracyRate = 96.1, Hdi = 0.866, LifeExpectancy = 82.2 },
        new() { Code = "CZE", Name = "Czech Republic", Iso2 = "CZ", Continent = "Europe", Population = 10510000, Area = 78865, GdpTotal = 290920, GdpPerCapita = 27220, PopulationDensity = 133.0, LiteracyRate = 99.0, Hdi = 0.889, LifeExpectancy = 79.5 },
        new() { Code = "FIN", Name = "Finland", Iso2 = "FI", Continent = "Europe", Population = 5540000, Area = 338424, GdpTotal = 282010, GdpPerCapita = 50870, PopulationDensity = 16.0, LiteracyRate = 99.0, Hdi = 0.940, LifeExpectancy = 82.0 },
        new() { Code = "DNK", Name = "Denmark", Iso2 = "DK", Continent = "Europe", Population = 5860000, Area = 43094, GdpTotal = 395400, GdpPerCapita = 67470, PopulationDensity = 136.0, LiteracyRate = 99.0, Hdi = 0.948, LifeExpectancy = 81.6 },
        new() { Code = "AUT", Name = "Austria", Iso2 = "AT", Continent = "Europe", Population = 9040000, Area = 83879, GdpTotal = 471400, GdpPerCapita = 52080, PopulationDensity = 108.0, LiteracyRate = 99.0, Hdi = 0.916, LifeExpectancy = 82.0 },
        new() { Code = "BEL", Name = "Belgium", Iso2 = "BE", Continent = "Europe", Population = 11590000, Area = 30528, GdpTotal = 578600, GdpPerCapita = 49930, PopulationDensity = 380.0, LiteracyRate = 99.0, Hdi = 0.937, LifeExpectancy = 82.1 },
        new() { Code = "ETH", Name = "Ethiopia", Iso2 = "ET", Continent = "Africa", Population = 120300000, Area = 1104300, GdpTotal = 126780, GdpPerCapita = 1030, PopulationDensity = 109.0, LiteracyRate = 51.8, Hdi = 0.498, LifeExpectancy = 67.8 },
        new() { Code = "KEN", Name = "Kenya", Iso2 = "KE", Continent = "Africa", Population = 54030000, Area = 580367, GdpTotal = 113420, GdpPerCapita = 2100, PopulationDensity = 93.0, LiteracyRate = 81.5, Hdi = 0.575, LifeExpectancy = 67.5 },
        new() { Code = "MAR", Name = "Morocco", Iso2 = "MA", Continent = "Africa", Population = 37080000, Area = 446550, GdpTotal = 134180, GdpPerCapita = 3620, PopulationDensity = 83.0, LiteracyRate = 73.8, Hdi = 0.683, LifeExpectancy = 77.0 },
    };

    public static IReadOnlyList<Country> GetAllCountries() => _countries.AsReadOnly();
}
COUNTRYDATAEOF

# -----------------------------------------------------------------------------
# Step 7: Fix UI Tests
# -----------------------------------------------------------------------------
echo "[7/8] Fixing UI Tests..."
mkdir -p tests/MyDesktopApplication.UI.Tests

cat > tests/MyDesktopApplication.UI.Tests/MainWindowViewModelTests.cs << 'UITESTSEOF'
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
        
        vm.CurrentScore.ShouldBe(0);
        vm.HighScore.ShouldBe(0);
        vm.CurrentStreak.ShouldBe(0);
        vm.BestStreak.ShouldBe(0);
        vm.HasAnswered.ShouldBeFalse();
    }

    [Fact]
    public void QuestionTypes_ShouldContainAllTypes()
    {
        var vm = new MainWindowViewModel();
        
        vm.QuestionTypes.Count.ShouldBe(8);
        vm.QuestionTypes.ShouldContain(QuestionType.Population);
        vm.QuestionTypes.ShouldContain(QuestionType.Area);
        vm.QuestionTypes.ShouldContain(QuestionType.GdpTotal);
        vm.QuestionTypes.ShouldContain(QuestionType.GdpPerCapita);
        vm.QuestionTypes.ShouldContain(QuestionType.PopulationDensity);
        vm.QuestionTypes.ShouldContain(QuestionType.LiteracyRate);
        vm.QuestionTypes.ShouldContain(QuestionType.Hdi);
        vm.QuestionTypes.ShouldContain(QuestionType.LifeExpectancy);
    }

    [Fact]
    public void GenerateNewQuestion_ShouldSetCountries()
    {
        var vm = new MainWindowViewModel();
        
        vm.GenerateNewQuestionCommand.Execute(null);

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
    public void ScoreText_ShouldBeFormatted()
    {
        var vm = new MainWindowViewModel();
        vm.ScoreText.ShouldBe("Score: 0");
    }
    
    [Fact]
    public void StreakText_ShouldBeFormatted()
    {
        var vm = new MainWindowViewModel();
        vm.StreakText.ShouldBe("Streak: 0");
    }
    
    [Fact]
    public void BestStreakText_ShouldBeFormatted()
    {
        var vm = new MainWindowViewModel();
        vm.BestStreakText.ShouldBe("Best: 0");
    }
}
UITESTSEOF

# -----------------------------------------------------------------------------
# Step 8: Build and verify
# -----------------------------------------------------------------------------
echo "[8/8] Restoring and building..."

dotnet restore MyDesktopApplication.slnx --verbosity minimal

echo ""
echo "Building solution..."
if dotnet build MyDesktopApplication.slnx --no-restore --verbosity minimal; then
    echo ""
    echo "=============================================="
    echo "  ✅ BUILD SUCCEEDED"
    echo "=============================================="
    echo ""
    echo "Running tests..."
    dotnet test MyDesktopApplication.slnx --no-build --verbosity minimal
else
    echo ""
    echo "=============================================="
    echo "  ❌ BUILD FAILED"
    echo "=============================================="
    exit 1
fi

#!/bin/bash
# ==============================================
#  Comprehensive Fix Script for MyDesktopApplication
#  Fixes 7 build errors identified in output.txt
# ==============================================

set -e
cd "$(dirname "$0")"

echo "=============================================="
echo "  Fixing All Build Errors"
echo "=============================================="
echo ""
echo "Errors to fix:"
echo "  1. QuestionType missing GetLabel extension method"
echo "  2. QuestionType missing GetValue extension method (4 occurrences)"
echo "  3. QuestionType missing FormatValue extension method"
echo "  4. CountryQuizViewModel line 203: Cannot convert string to double"
echo ""

# Kill any stuck processes
echo "Step 1: Killing any stuck build processes..."
pkill -f VBCSCompiler 2>/dev/null || true
pkill -f aapt2 2>/dev/null || true
pkill -f "dotnet.*build" 2>/dev/null || true
sleep 1
echo "✓ Done"

# Clean build artifacts
echo ""
echo "Step 2: Cleaning build artifacts..."
rm -rf src/*/bin src/*/obj tests/*/bin tests/*/obj 2>/dev/null || true
echo "✓ Done"

# ==============================================
# Step 3: Fix QuestionType.cs with extension methods
# ==============================================
echo ""
echo "Step 3: Adding extension methods to QuestionType.cs..."

mkdir -p src/MyDesktopApplication.Core/Entities

cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'QUESTIONTYPE_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of quiz questions about countries
/// </summary>
public enum QuestionType
{
    Population,
    Area,
    Gdp,
    GdpPerCapita,
    Density,
    Literacy,
    Hdi,
    LifeExpectancy
}

/// <summary>
/// Extension methods for QuestionType enum
/// </summary>
public static class QuestionTypeExtensions
{
    /// <summary>
    /// Gets a human-readable label for the question type
    /// </summary>
    public static string GetLabel(this QuestionType questionType) => questionType switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.Gdp => "GDP (USD)",
        QuestionType.GdpPerCapita => "GDP per Capita (USD)",
        QuestionType.Density => "Population Density (per km²)",
        QuestionType.Literacy => "Literacy Rate (%)",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy (years)",
        _ => questionType.ToString()
    };

    /// <summary>
    /// Gets the value from a country for the specified question type
    /// </summary>
    public static double GetValue(this QuestionType questionType, Country country) => questionType switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.Gdp => country.Gdp,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.Density => country.Density,
        QuestionType.Literacy => country.Literacy,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };

    /// <summary>
    /// Formats a value according to the question type
    /// </summary>
    public static string FormatValue(this QuestionType questionType, double value) => questionType switch
    {
        QuestionType.Population => FormatPopulation(value),
        QuestionType.Area => FormatArea(value),
        QuestionType.Gdp => FormatCurrency(value),
        QuestionType.GdpPerCapita => FormatCurrency(value),
        QuestionType.Density => $"{value:N1}/km²",
        QuestionType.Literacy => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N0")
    };

    private static string FormatPopulation(double value)
    {
        if (value >= 1_000_000_000) return $"{value / 1_000_000_000:N2}B";
        if (value >= 1_000_000) return $"{value / 1_000_000:N2}M";
        if (value >= 1_000) return $"{value / 1_000:N2}K";
        return value.ToString("N0");
    }

    private static string FormatArea(double value)
    {
        if (value >= 1_000_000) return $"{value / 1_000_000:N2}M km²";
        if (value >= 1_000) return $"{value / 1_000:N2}K km²";
        return $"{value:N0} km²";
    }

    private static string FormatCurrency(double value)
    {
        if (value >= 1_000_000_000_000) return $"${value / 1_000_000_000_000:N2}T";
        if (value >= 1_000_000_000) return $"${value / 1_000_000_000:N2}B";
        if (value >= 1_000_000) return $"${value / 1_000_000:N2}M";
        if (value >= 1_000) return $"${value / 1_000:N2}K";
        return $"${value:N0}";
    }
}
QUESTIONTYPE_EOF

echo "✓ Done"

# ==============================================
# Step 4: Fix Country.cs to ensure all properties exist
# ==============================================
echo ""
echo "Step 4: Ensuring Country class has all required properties..."

cat > src/MyDesktopApplication.Core/Entities/Country.cs << 'COUNTRY_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with geographic and demographic data
/// </summary>
public class Country
{
    /// <summary>
    /// ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR")
    /// </summary>
    public required string Code { get; init; }

    /// <summary>
    /// Common name of the country
    /// </summary>
    public required string Name { get; init; }

    /// <summary>
    /// ISO 3166-1 alpha-2 country code (e.g., "US", "GB")
    /// </summary>
    public string Iso2 { get; init; } = string.Empty;

    /// <summary>
    /// Continent where the country is located
    /// </summary>
    public string Continent { get; init; } = string.Empty;

    /// <summary>
    /// Total population
    /// </summary>
    public double Population { get; init; }

    /// <summary>
    /// Total area in square kilometers
    /// </summary>
    public double Area { get; init; }

    /// <summary>
    /// Gross Domestic Product in USD
    /// </summary>
    public double Gdp { get; init; }

    /// <summary>
    /// GDP per capita in USD
    /// </summary>
    public double GdpPerCapita { get; init; }

    /// <summary>
    /// Population density (people per square kilometer)
    /// </summary>
    public double Density { get; init; }

    /// <summary>
    /// Literacy rate as a percentage (0-100)
    /// </summary>
    public double Literacy { get; init; }

    /// <summary>
    /// Human Development Index (0-1)
    /// </summary>
    public double Hdi { get; init; }

    /// <summary>
    /// Life expectancy in years
    /// </summary>
    public double LifeExpectancy { get; init; }

    /// <summary>
    /// Flag emoji for the country
    /// </summary>
    public string Flag => GetFlagEmoji();

    private string GetFlagEmoji()
    {
        if (string.IsNullOrEmpty(Iso2) || Iso2.Length != 2)
            return "🏳️";

        // Convert ISO2 code to regional indicator symbols
        var c1 = char.ToUpperInvariant(Iso2[0]);
        var c2 = char.ToUpperInvariant(Iso2[1]);
        
        // Regional indicator symbols start at U+1F1E6 (A)
        var ri1 = 0x1F1E6 + (c1 - 'A');
        var ri2 = 0x1F1E6 + (c2 - 'A');
        
        return char.ConvertFromUtf32(ri1) + char.ConvertFromUtf32(ri2);
    }
}
COUNTRY_EOF

echo "✓ Done"

# ==============================================
# Step 5: Fix CountryQuizViewModel.cs
# ==============================================
echo ""
echo "Step 5: Rewriting CountryQuizViewModel.cs to fix all errors..."

mkdir -p src/MyDesktopApplication.Shared/ViewModels

cat > src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs << 'VIEWMODEL_EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private List<Country> _countries = new();
    private Country? _currentCountry;
    private Country? _optionA;
    private Country? _optionB;

    [ObservableProperty]
    private string _questionText = "Loading...";

    [ObservableProperty]
    private string _optionAText = "";

    [ObservableProperty]
    private string _optionBText = "";

    [ObservableProperty]
    private string _feedbackMessage = "";

    [ObservableProperty]
    private bool _isCorrect;

    [ObservableProperty]
    private bool _hasAnswered;

    [ObservableProperty]
    private int _score;

    [ObservableProperty]
    private int _streak;

    [ObservableProperty]
    private int _bestStreak;

    [ObservableProperty]
    private int _totalAnswered;

    [ObservableProperty]
    private double _accuracy;

    [ObservableProperty]
    private string _correctAnswer = "";

    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;

    [ObservableProperty]
    private List<QuestionType> _questionTypes = Enum.GetValues<QuestionType>().ToList();

    [ObservableProperty]
    private string _selectedQuestionTypeLabel = "Population";

    public CountryQuizViewModel() : this(null) { }

    public CountryQuizViewModel(IGameStateRepository? gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
        _countries = CountryData.GetAllCountries().ToList();
        GenerateNewQuestion();
    }

    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        SelectedQuestionTypeLabel = value.GetLabel();
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void SelectOptionA()
    {
        if (HasAnswered || _optionA == null || _optionB == null) return;
        ProcessAnswer(_optionA, _optionB);
    }

    [RelayCommand]
    private void SelectOptionB()
    {
        if (HasAnswered || _optionA == null || _optionB == null) return;
        ProcessAnswer(_optionB, _optionA);
    }

    private void ProcessAnswer(Country selected, Country other)
    {
        HasAnswered = true;
        TotalAnswered++;

        var selectedValue = SelectedQuestionType.GetValue(selected);
        var otherValue = SelectedQuestionType.GetValue(other);

        // Higher value wins for all question types
        IsCorrect = selectedValue >= otherValue;

        if (IsCorrect)
        {
            Score++;
            Streak++;
            if (Streak > BestStreak)
            {
                BestStreak = Streak;
            }
            FeedbackMessage = GetCorrectMessage();
            CorrectAnswer = $"{selected.Flag} {selected.Name}: {SelectedQuestionType.FormatValue(selectedValue)}";
        }
        else
        {
            Streak = 0;
            var correctCountry = selectedValue >= otherValue ? selected : other;
            var correctValue = SelectedQuestionType.GetValue(correctCountry);
            FeedbackMessage = GetIncorrectMessage();
            CorrectAnswer = $"{correctCountry.Flag} {correctCountry.Name}: {SelectedQuestionType.FormatValue(correctValue)}";
        }

        UpdateAccuracy();
        _ = SaveGameStateAsync();
    }

    private string GetCorrectMessage()
    {
        if (Streak >= 10) return "🔥 UNSTOPPABLE! 10+ streak!";
        if (Streak >= 5) return "🔥 On fire! " + Streak + " in a row!";
        if (Streak >= 3) return "🎯 Great streak! " + Streak + " correct!";
        if (Streak == BestStreak && BestStreak > 1) return "🏆 NEW PERSONAL BEST!";
        
        var messages = new[]
        {
            "✅ Correct!",
            "🎉 Well done!",
            "👏 Nice one!",
            "💪 You got it!",
            "⭐ Excellent!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        var messages = new[]
        {
            "❌ Not quite!",
            "😅 Oops!",
            "🤔 Close one!",
            "📚 Now you know!",
            "💡 Learn something new!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private void UpdateAccuracy()
    {
        Accuracy = TotalAnswered > 0 ? (double)Score / TotalAnswered * 100 : 0;
    }

    [RelayCommand]
    private void NextQuestion()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void Reset()
    {
        Score = 0;
        Streak = 0;
        TotalAnswered = 0;
        Accuracy = 0;
        // Keep BestStreak
        GenerateNewQuestion();
        _ = SaveGameStateAsync();
    }

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        FeedbackMessage = "";
        CorrectAnswer = "";
        IsCorrect = false;

        if (_countries.Count < 2) return;

        // Pick two random different countries
        var indices = Enumerable.Range(0, _countries.Count).OrderBy(_ => _random.Next()).Take(2).ToList();
        _optionA = _countries[indices[0]];
        _optionB = _countries[indices[1]];

        QuestionText = $"Which country has higher {SelectedQuestionType.GetLabel()}?";
        OptionAText = $"{_optionA.Flag} {_optionA.Name}";
        OptionBText = $"{_optionB.Flag} {_optionB.Name}";
    }

    private async Task SaveGameStateAsync()
    {
        if (_gameStateRepository == null) return;

        try
        {
            var state = await _gameStateRepository.GetOrCreateAsync("default");
            state.CurrentScore = Score;
            state.CurrentStreak = Streak;
            if (BestStreak > state.BestStreak)
            {
                state.BestStreak = BestStreak;
            }
            state.TotalCorrect = Score;
            state.TotalAnswered = TotalAnswered;
            state.LastPlayedAt = DateTime.UtcNow;
            await _gameStateRepository.SaveAsync(state);
        }
        catch
        {
            // Silently ignore save errors - game continues without persistence
        }
    }

    public async Task LoadGameStateAsync()
    {
        if (_gameStateRepository == null) return;

        try
        {
            var state = await _gameStateRepository.GetOrCreateAsync("default");
            Score = state.CurrentScore;
            Streak = state.CurrentStreak;
            BestStreak = state.BestStreak;
            TotalAnswered = state.TotalAnswered;
            UpdateAccuracy();
        }
        catch
        {
            // Silently ignore load errors - start fresh
        }
    }
}
VIEWMODEL_EOF

echo "✓ Done"

# ==============================================
# Step 6: Fix GameState.cs to have all required properties
# ==============================================
echo ""
echo "Step 6: Updating GameState.cs with all required properties..."

cat > src/MyDesktopApplication.Core/Entities/GameState.cs << 'GAMESTATE_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents the persistent game state for a user
/// </summary>
public class GameState : EntityBase
{
    /// <summary>
    /// User identifier (default for single-player)
    /// </summary>
    public string UserId { get; set; } = "default";

    /// <summary>
    /// Current score in the active session
    /// </summary>
    public int CurrentScore { get; set; }

    /// <summary>
    /// Highest score ever achieved
    /// </summary>
    public int HighScore { get; set; }

    /// <summary>
    /// Current consecutive correct answers
    /// </summary>
    public int CurrentStreak { get; set; }

    /// <summary>
    /// Best streak ever achieved
    /// </summary>
    public int BestStreak { get; set; }

    /// <summary>
    /// Total number of correct answers
    /// </summary>
    public int TotalCorrect { get; set; }

    /// <summary>
    /// Total number of questions answered
    /// </summary>
    public int TotalAnswered { get; set; }

    /// <summary>
    /// When the user last played
    /// </summary>
    public DateTime? LastPlayedAt { get; set; }

    /// <summary>
    /// Calculated accuracy percentage
    /// </summary>
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered * 100 : 0;

    /// <summary>
    /// Records an answer and updates statistics
    /// </summary>
    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        if (isCorrect)
        {
            TotalCorrect++;
            CurrentScore++;
            CurrentStreak++;
            if (CurrentScore > HighScore)
            {
                HighScore = CurrentScore;
            }
            if (CurrentStreak > BestStreak)
            {
                BestStreak = CurrentStreak;
            }
        }
        else
        {
            CurrentStreak = 0;
        }
        LastPlayedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Resets the current session (keeps high scores)
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
    }
}
GAMESTATE_EOF

echo "✓ Done"

# ==============================================
# Step 7: Fix QuestionTypeTests.cs
# ==============================================
echo ""
echo "Step 7: Fixing QuestionTypeTests.cs..."

mkdir -p tests/MyDesktopApplication.Core.Tests

cat > tests/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs << 'TESTS_EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Area, "Area (km²)")]
    [InlineData(QuestionType.Gdp, "GDP (USD)")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita (USD)")]
    [InlineData(QuestionType.Density, "Population Density (per km²)")]
    [InlineData(QuestionType.Literacy, "Literacy Rate (%)")]
    [InlineData(QuestionType.Hdi, "Human Development Index")]
    [InlineData(QuestionType.LifeExpectancy, "Life Expectancy (years)")]
    public void GetLabel_ReturnsCorrectLabel(QuestionType questionType, string expectedLabel)
    {
        // Act
        var label = questionType.GetLabel();

        // Assert
        label.ShouldBe(expectedLabel);
    }

    [Fact]
    public void GetValue_ReturnsCorrectValueForCountry()
    {
        // Arrange
        var country = new Country
        {
            Code = "USA",
            Name = "United States",
            Iso2 = "US",
            Continent = "North America",
            Population = 331_000_000,
            Area = 9_833_520,
            Gdp = 25_462_700_000_000,
            GdpPerCapita = 76_330,
            Density = 33.6,
            Literacy = 99.0,
            Hdi = 0.921,
            LifeExpectancy = 77.0
        };

        // Act & Assert
        QuestionType.Population.GetValue(country).ShouldBe(331_000_000);
        QuestionType.Area.GetValue(country).ShouldBe(9_833_520);
        QuestionType.Gdp.GetValue(country).ShouldBe(25_462_700_000_000);
        QuestionType.GdpPerCapita.GetValue(country).ShouldBe(76_330);
        QuestionType.Density.GetValue(country).ShouldBe(33.6);
        QuestionType.Literacy.GetValue(country).ShouldBe(99.0);
        QuestionType.Hdi.GetValue(country).ShouldBe(0.921);
        QuestionType.LifeExpectancy.GetValue(country).ShouldBe(77.0);
    }

    [Fact]
    public void FormatValue_FormatsPopulationCorrectly()
    {
        // Arrange & Act & Assert
        QuestionType.Population.FormatValue(1_500_000_000).ShouldBe("1.50B");
        QuestionType.Population.FormatValue(331_000_000).ShouldBe("331.00M");
        QuestionType.Population.FormatValue(500_000).ShouldBe("500.00K");
        QuestionType.Population.FormatValue(999).ShouldBe("999");
    }

    [Fact]
    public void FormatValue_FormatsCurrencyCorrectly()
    {
        // Arrange & Act & Assert
        QuestionType.Gdp.FormatValue(25_000_000_000_000).ShouldBe("$25.00T");
        QuestionType.Gdp.FormatValue(1_500_000_000).ShouldBe("$1.50B");
        QuestionType.Gdp.FormatValue(500_000_000).ShouldBe("$500.00M");
    }

    [Fact]
    public void FormatValue_FormatsPercentageCorrectly()
    {
        QuestionType.Literacy.FormatValue(99.5).ShouldBe("99.5%");
    }

    [Fact]
    public void FormatValue_FormatsHdiCorrectly()
    {
        QuestionType.Hdi.FormatValue(0.921).ShouldBe("0.921");
    }

    [Fact]
    public void FormatValue_FormatsLifeExpectancyCorrectly()
    {
        QuestionType.LifeExpectancy.FormatValue(77.5).ShouldBe("77.5 years");
    }
}
TESTS_EOF

echo "✓ Done"

# ==============================================
# Step 8: Fix ViewModelBase.cs to ensure it exists
# ==============================================
echo ""
echo "Step 8: Ensuring ViewModelBase.cs exists..."

cat > src/MyDesktopApplication.Shared/ViewModels/ViewModelBase.cs << 'VMBASE_EOF'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Base class for all view models
/// </summary>
public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;

    [ObservableProperty]
    private string _errorMessage = string.Empty;
}
VMBASE_EOF

echo "✓ Done"

# ==============================================
# Step 9: Restore and Build
# ==============================================
echo ""
echo "Step 9: Restoring packages..."
dotnet restore MyDesktopApplication.slnx --verbosity quiet
echo "✓ Done"

echo ""
echo "Step 10: Building solution..."
if dotnet build MyDesktopApplication.slnx --no-restore; then
    echo ""
    echo "=============================================="
    echo "  ✅ BUILD SUCCEEDED"
    echo "=============================================="
    
    echo ""
    echo "Step 11: Running tests..."
    if dotnet test MyDesktopApplication.slnx --no-build --verbosity normal; then
        echo ""
        echo "=============================================="
        echo "  ✅ ALL TESTS PASSED"
        echo "=============================================="
    else
        echo ""
        echo "⚠️  Some tests failed - check output above"
    fi
else
    echo ""
    echo "=============================================="
    echo "  ❌ BUILD FAILED"
    echo "=============================================="
    echo ""
    echo "Check the errors above and run the script again."
    exit 1
fi

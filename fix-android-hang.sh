#!/bin/bash
set -e

# =============================================================================
# COMPREHENSIVE BUILD FIX SCRIPT
# =============================================================================
# Fixes all 7 build errors:
#   1. QuestionType missing GetLabel extension (QuestionTypeTests.cs:20)
#   2. QuestionType missing GetValue extension (QuestionTypeTests.cs:41-44)
#   3. QuestionType missing FormatValue extension (QuestionTypeTests.cs:53)
#   4. CountryQuizViewModel.cs:203 - Cannot convert string to double
#
# Also fixes Android build hang by configuring aapt2 properly.
# Does NOT split the solution - maintains single MyDesktopApplication.slnx
# =============================================================================

echo "=============================================="
echo "  Comprehensive Build Fix Script"
echo "=============================================="
echo ""

cd "$(dirname "$0")"

# -----------------------------------------------------------------------------
# Step 1: Kill stuck processes
# -----------------------------------------------------------------------------
echo "[1/7] Cleaning up stuck processes..."
pkill -9 -f "aapt2" 2>/dev/null || true
pkill -9 -f "VBCSCompiler" 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
sleep 1

# -----------------------------------------------------------------------------
# Step 2: Clean build artifacts
# -----------------------------------------------------------------------------
echo "[2/7] Cleaning build artifacts..."
rm -rf src/*/bin src/*/obj tests/*/bin tests/*/obj 2>/dev/null || true

# -----------------------------------------------------------------------------
# Step 3: Update Directory.Build.props with Android fixes
# -----------------------------------------------------------------------------
echo "[3/7] Updating Directory.Build.props..."

cat > Directory.Build.props << 'EOF'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>

  <!-- Android aapt2 daemon fix to prevent hangs -->
  <PropertyGroup Condition="$(TargetFramework.Contains('-android'))">
    <AndroidUseAapt2Daemon>false</AndroidUseAapt2Daemon>
    <_Aapt2DaemonMaxInstanceCount>1</_Aapt2DaemonMaxInstanceCount>
    <Aapt2DaemonStartupTimeout>60000</Aapt2DaemonStartupTimeout>
    <AndroidAapt2CompileExtraArgs>--no-crunch</AndroidAapt2CompileExtraArgs>
    <UseInterpreter Condition="'$(Configuration)' == 'Debug'">true</UseInterpreter>
  </PropertyGroup>

  <PropertyGroup>
    <PublishRepositoryUrl>true</PublishRepositoryUrl>
    <EmbedUntrackedSources>true</EmbedUntrackedSources>
    <IncludeSymbols>true</IncludeSymbols>
    <SymbolPackageFormat>snupkg</SymbolPackageFormat>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest</AnalysisLevel>
  </PropertyGroup>
</Project>
EOF

# -----------------------------------------------------------------------------
# Step 4: Fix QuestionType.cs - Add extension methods
# -----------------------------------------------------------------------------
echo "[4/7] Fixing QuestionType.cs with extension methods..."

cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of quiz questions comparing countries
/// </summary>
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
        QuestionType.GdpTotal => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.LiteracyRate => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => questionType.ToString()
    };

    /// <summary>
    /// Gets the corresponding value from a Country for this question type
    /// </summary>
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

    /// <summary>
    /// Formats a value according to the question type's expected format
    /// </summary>
    public static string FormatValue(this QuestionType questionType, double value) => questionType switch
    {
        QuestionType.Population => FormatPopulation(value),
        QuestionType.Area => FormatArea(value),
        QuestionType.GdpTotal => FormatCurrency(value),
        QuestionType.GdpPerCapita => FormatCurrency(value),
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

    private static string FormatArea(double value)
    {
        return value switch
        {
            >= 1_000_000 => $"{value / 1_000_000:N2}M km²",
            >= 1_000 => $"{value / 1_000:N1}K km²",
            _ => $"{value:N0} km²"
        };
    }

    private static string FormatCurrency(double value)
    {
        return value switch
        {
            >= 1_000_000_000_000 => $"${value / 1_000_000_000_000:N2}T",
            >= 1_000_000_000 => $"${value / 1_000_000_000:N2}B",
            >= 1_000_000 => $"${value / 1_000_000:N2}M",
            >= 1_000 => $"${value / 1_000:N1}K",
            _ => $"${value:N0}"
        };
    }
}
EOF

# -----------------------------------------------------------------------------
# Step 5: Fix Country.cs - Ensure all properties exist
# -----------------------------------------------------------------------------
echo "[5/7] Ensuring Country.cs has all required properties..."

cat > src/MyDesktopApplication.Core/Entities/Country.cs << 'EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with statistical data for the quiz
/// </summary>
public class Country
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public string Iso2 { get; init; } = string.Empty;
    public string Continent { get; init; } = string.Empty;

    // Statistical properties (harmonized naming)
    public double Population { get; init; }
    public double Area { get; init; }
    public double GdpTotal { get; init; }
    public double GdpPerCapita { get; init; }
    public double PopulationDensity { get; init; }
    public double LiteracyRate { get; init; }
    public double Hdi { get; init; }
    public double LifeExpectancy { get; init; }

    /// <summary>
    /// Gets the country flag emoji based on ISO2 code
    /// </summary>
    public string Flag => GetFlagEmoji();

    private string GetFlagEmoji()
    {
        if (string.IsNullOrEmpty(Iso2) || Iso2.Length != 2)
            return "🏳️";
        
        var c1 = char.ToUpperInvariant(Iso2[0]);
        var c2 = char.ToUpperInvariant(Iso2[1]);
        var ri1 = 0x1F1E6 + (c1 - 'A');
        var ri2 = 0x1F1E6 + (c2 - 'A');
        return char.ConvertFromUtf32(ri1) + char.ConvertFromUtf32(ri2);
    }
}
EOF

# -----------------------------------------------------------------------------
# Step 6: Fix CountryQuizViewModel.cs - Fix string to double conversion
# -----------------------------------------------------------------------------
echo "[6/7] Fixing CountryQuizViewModel.cs..."

cat > src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs << 'EOF'
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
    private readonly List<Country> _countries;
    private Country? _country1;
    private Country? _country2;

    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Flag = "";
    [ObservableProperty] private string _country2Flag = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
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

    public CountryQuizViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        
        foreach (QuestionType qt in Enum.GetValues<QuestionType>())
        {
            QuestionTypes.Add(qt);
        }
        
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void SelectCountry(int countryNumber)
    {
        if (HasAnswered || _country1 == null || _country2 == null)
            return;

        HasAnswered = true;
        TotalQuestions++;

        var value1 = SelectedQuestionType.GetValue(_country1);
        var value2 = SelectedQuestionType.GetValue(_country2);
        
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

        // Pick two different random countries
        var indices = Enumerable.Range(0, _countries.Count).OrderBy(_ => _random.Next()).Take(2).ToList();
        _country1 = _countries[indices[0]];
        _country2 = _countries[indices[1]];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        Country1Flag = _country1.Flag;
        Country2Flag = _country2.Flag;

        QuestionText = $"Which country has a higher {SelectedQuestionType.GetLabel()}?";
    }

    private string GetCorrectMessage()
    {
        var messages = new[]
        {
            "🎉 Correct!",
            "✅ Well done!",
            "👏 Great job!",
            "🌟 Excellent!",
            CurrentStreak >= 5 ? $"🔥 {CurrentStreak} in a row!" : "💪 Keep it up!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        return "❌ Not quite! The correct answer is shown above.";
    }
}
EOF

# -----------------------------------------------------------------------------
# Step 7: Restore and Build
# -----------------------------------------------------------------------------
echo "[7/7] Restoring packages and building..."

dotnet restore MyDesktopApplication.slnx

echo ""
echo "Building desktop projects (net10.0)..."
time dotnet build MyDesktopApplication.slnx -p:TargetFramework=net10.0 --no-restore

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "=============================================="
    echo "  ✅ Build succeeded!"
    echo "=============================================="
    echo ""
    echo "Running tests..."
    dotnet test MyDesktopApplication.slnx --no-build || true
    echo ""
    echo "Next steps:"
    echo "  dotnet run --project src/MyDesktopApplication.Desktop"
else
    echo ""
    echo "=============================================="
    echo "  ❌ Build failed - check errors above"
    echo "=============================================="
    exit 1
fi

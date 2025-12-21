using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of quiz questions available
/// </summary>
public enum QuestionType
{
    Population = 0,
    Area = 1,
    GdpTotal = 2,
    GdpPerCapita = 3,
    PopulationDensity = 4,
    LiteracyRate = 5,
    Hdi = 6,
    LifeExpectancy = 7
}

/// <summary>
/// Extension methods for QuestionType used by CountryQuizViewModel
/// </summary>
public static class QuestionTypeExtensions
{
    public static string GetDisplayName(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.GdpTotal => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.LiteracyRate => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };

    public static string GetQuestion(this QuestionType type) => type switch
    {
        QuestionType.Population => "Which country has a higher population?",
        QuestionType.Area => "Which country has a larger area?",
        QuestionType.GdpTotal => "Which country has a higher GDP?",
        QuestionType.GdpPerCapita => "Which country has a higher GDP per capita?",
        QuestionType.PopulationDensity => "Which country has higher population density?",
        QuestionType.LiteracyRate => "Which country has a higher literacy rate?",
        QuestionType.Hdi => "Which country has a higher HDI?",
        QuestionType.LifeExpectancy => "Which country has higher life expectancy?",
        _ => "Which country is greater?"
    };

    /// <summary>
    /// Get the value for a specific question type from a Country object.
    /// Used by CountryQuizViewModel for comparisons.
    /// </summary>
    public static double GetValue(this QuestionType type, Country country) => type switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.GdpTotal => country.Gdp,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.PopulationDensity => country.Density,
        QuestionType.LiteracyRate => country.Literacy,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };

    /// <summary>
    /// Format a value for display based on question type.
    /// Used by CountryQuizViewModel for showing results.
    /// </summary>
    public static string FormatValue(this QuestionType type, double value) => type switch
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
        if (value >= 1_000_000_000)
            return $"{value / 1_000_000_000:N2}B";
        if (value >= 1_000_000)
            return $"{value / 1_000_000:N2}M";
        if (value >= 1_000)
            return $"{value / 1_000:N1}K";
        return value.ToString("N0");
    }

    private static string FormatCurrency(double value)
    {
        if (value >= 1_000_000_000_000)
            return $"${value / 1_000_000_000_000:N2}T";
        if (value >= 1_000_000_000)
            return $"${value / 1_000_000_000:N2}B";
        if (value >= 1_000_000)
            return $"${value / 1_000_000:N2}M";
        return $"${value:N0}";
    }
}

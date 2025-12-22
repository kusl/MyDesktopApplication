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

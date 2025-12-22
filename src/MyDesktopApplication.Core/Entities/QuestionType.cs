namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of quiz questions about countries.
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
/// Extension methods for QuestionType enum.
/// </summary>
public static class QuestionTypeExtensions
{
    /// <summary>
    /// Gets the human-readable label for a question type, including units where applicable.
    /// </summary>
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

    /// <summary>
    /// Gets the numeric value for a question type from a country.
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
    /// Formats a numeric value according to the question type's display conventions.
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

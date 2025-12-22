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

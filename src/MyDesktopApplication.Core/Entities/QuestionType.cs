namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of comparison questions in the country quiz.
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
/// Extension methods for QuestionType enum.
/// </summary>
public static class QuestionTypeExtensions
{
    /// <summary>
    /// Gets a human-readable label for the question type.
    /// </summary>
    public static string GetLabel(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.Gdp => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.Density => "Population Density",
        QuestionType.Literacy => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };

    /// <summary>
    /// Gets a grammatically correct question for the given question type.
    /// </summary>
    public static string GetQuestion(this QuestionType type) => type switch
    {
        QuestionType.Population => "Which country has a larger population?",
        QuestionType.Area => "Which country is larger in area?",
        QuestionType.Gdp => "Which country has a higher total GDP?",
        QuestionType.GdpPerCapita => "Which country has a higher GDP per capita?",
        QuestionType.Density => "Which country has a higher population density?",
        QuestionType.Literacy => "Which country has a higher literacy rate?",
        QuestionType.Hdi => "Which country has a higher Human Development Index?",
        QuestionType.LifeExpectancy => "Which country has a longer life expectancy?",
        _ => "Which country ranks higher?"
    };

    /// <summary>
    /// Gets the numeric value for a country based on the question type.
    /// Returns null if data is not available.
    /// </summary>
    public static double? GetValue(this QuestionType type, Country country) => type switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.Gdp => country.Gdp,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.Density => country.Density,
        QuestionType.Literacy => country.Literacy,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => null
    };

    /// <summary>
    /// Formats a numeric value with appropriate units for display.
    /// Uses enough precision to distinguish close values.
    /// </summary>
    public static string FormatValue(this QuestionType type, double? value)
    {
        if (!value.HasValue) return "N/A";
        var v = value.Value;

        return type switch
        {
            QuestionType.Population => FormatLargeNumber(v),
            QuestionType.Area => $"{v:N0} km²",
            QuestionType.Gdp => "$" + FormatLargeNumber(v),
            QuestionType.GdpPerCapita => $"${v:N0}",
            QuestionType.Density => $"{v:N1}/km²",
            QuestionType.Literacy => $"{v:N1}%",
            QuestionType.Hdi => $"{v:N3}",
            QuestionType.LifeExpectancy => $"{v:N1} years",
            _ => $"{v:N2}"
        };
    }

    private static string FormatLargeNumber(double value)
    {
        return value switch
        {
            >= 1_000_000_000_000 => $"{value / 1_000_000_000_000:N3}T",
            >= 1_000_000_000 => $"{value / 1_000_000_000:N3}B",
            >= 1_000_000 => $"{value / 1_000_000:N2}M",
            >= 1_000 => $"{value / 1_000:N1}K",
            _ => $"{value:N0}"
        };
    }
}

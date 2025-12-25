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
        QuestionType.GdpTotal => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.LiteracyRate => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
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

    /// <summary>
    /// Format a value for display with appropriate precision.
    /// Uses exact values to avoid confusion when numbers are close.
    /// </summary>
    public static string FormatValue(this QuestionType questionType, double value) => questionType switch
    {
        QuestionType.Population => FormatLargeNumber(value),
        QuestionType.Area => FormatArea(value),
        QuestionType.GdpTotal => FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.LiteracyRate => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N0")
    };

    /// <summary>
    /// Format large numbers with enough precision to distinguish close values.
    /// For example, 1,411,750,000 vs 1,417,173,173 should NOT both show as "1.4B"
    /// </summary>
    private static string FormatLargeNumber(double value)
    {
        // Use exact format for smaller numbers
        if (value < 1_000) return value.ToString("N0");
        if (value < 1_000_000) return $"{value / 1_000:N2}K";  // 2 decimal places
        if (value < 1_000_000_000) return $"{value / 1_000_000:N2}M";  // 2 decimal places
        
        // For billions, use 3 decimal places to distinguish close values
        // e.g., 1.412B vs 1.417B for China/India
        if (value < 1_000_000_000_000) return $"{value / 1_000_000_000:N3}B";
        
        return $"{value / 1_000_000_000_000:N3}T";
    }

    private static string FormatArea(double value)
    {
        if (value < 1_000) return $"{value:N0} km²";
        if (value < 1_000_000) return $"{value / 1_000:N2}K km²";
        return $"{value / 1_000_000:N2}M km²";
    }

    private static string FormatCurrency(double value)
    {
        if (value < 1_000) return $"${value:N0}";
        if (value < 1_000_000) return $"${value / 1_000:N2}K";
        if (value < 1_000_000_000) return $"${value / 1_000_000:N2}M";
        if (value < 1_000_000_000_000) return $"${value / 1_000_000_000:N2}B";
        return $"${value / 1_000_000_000_000:N2}T";
    }
}

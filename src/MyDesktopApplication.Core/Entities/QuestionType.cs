namespace MyDesktopApplication.Core.Entities;

public enum QuestionType
{
    Population,
    Area,
    Gdp,
    GdpPerCapita,
    PopulationDensity,
    Literacy,
    Hdi,
    LifeExpectancy
}

public static class QuestionTypeExtensions
{
    public static string GetLabel(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.Gdp => "GDP (USD)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.Literacy => "Literacy Rate (%)",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };
    
    public static double GetValue(this QuestionType type, Country country) => type switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.Gdp => country.Gdp,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.PopulationDensity => country.PopulationDensity,
        QuestionType.Literacy => country.LiteracyRate,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };
    
    public static string FormatValue(this QuestionType type, double value) => type switch
    {
        QuestionType.Population => FormatPopulation(value),
        QuestionType.Area => $"{value:N0} km²",
        QuestionType.Gdp => FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.Literacy => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N2")
    };
    
    private static string FormatPopulation(double pop)
    {
        return pop switch
        {
            >= 1_000_000_000 => $"{pop / 1_000_000_000:N2}B",
            >= 1_000_000 => $"{pop / 1_000_000:N2}M",
            >= 1_000 => $"{pop / 1_000:N1}K",
            _ => $"{pop:N0}"
        };
    }
    
    private static string FormatCurrency(double amount)
    {
        return amount switch
        {
            >= 1_000_000_000_000 => $"${amount / 1_000_000_000_000:N2}T",
            >= 1_000_000_000 => $"${amount / 1_000_000_000:N2}B",
            >= 1_000_000 => $"${amount / 1_000_000:N2}M",
            _ => $"${amount:N0}"
        };
    }
}

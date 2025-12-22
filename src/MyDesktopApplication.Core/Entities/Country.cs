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

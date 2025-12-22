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

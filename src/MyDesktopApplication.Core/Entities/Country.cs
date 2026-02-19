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
            return "\U0001F3F3\uFE0F";

        var c1 = char.ToUpperInvariant(Iso2[0]);
        var c2 = char.ToUpperInvariant(Iso2[1]);
        var ri1 = 0x1F1E6 + (c1 - 'A');
        var ri2 = 0x1F1E6 + (c2 - 'A');
        return char.ConvertFromUtf32(ri1) + char.ConvertFromUtf32(ri2);
    }

    /// <summary>
    /// Generates a human-readable summary paragraph with all stats.
    /// Short sentences, easy to read after a quiz answer.
    /// </summary>
    public string GetSummary()
    {
        var pop = FormatPopulation(Population);
        var area = $"{Area:N0} km\u00B2";
        var gdp = FormatGdp(GdpTotal);
        var gdpPc = $"${GdpPerCapita:N0}";
        var density = $"{PopulationDensity:N1} people/km\u00B2";
        var literacy = $"{LiteracyRate:N1}%";
        var hdi = $"{Hdi:N3}";
        var life = $"{LifeExpectancy:N1} years";

        return $"{Flag} {Name} is in {Continent}. " +
               $"Population: {pop}. " +
               $"Area: {area}. " +
               $"GDP: {gdp} (${gdpPc} per capita). " +
               $"Density: {density}. " +
               $"Literacy: {literacy}. " +
               $"HDI: {hdi}. " +
               $"Life expectancy: {life}.";
    }

    private static string FormatPopulation(double value) => value switch
    {
        >= 1_000_000_000 => $"{value / 1_000_000_000:N2} billion",
        >= 1_000_000 => $"{value / 1_000_000:N1} million",
        >= 1_000 => $"{value / 1_000:N1} thousand",
        _ => $"{value:N0}"
    };

    private static string FormatGdp(double millions) => millions switch
    {
        >= 1_000_000 => $"${millions / 1_000_000:N2} trillion",
        >= 1_000 => $"${millions / 1_000:N1} billion",
        _ => $"${millions:N0} million"
    };
}

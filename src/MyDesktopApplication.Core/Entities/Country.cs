namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with various statistical metrics.
/// Data sourced from World Bank, UN, IMF, and UNDP (2023/2024 estimates).
/// </summary>
public sealed class Country
{
    public required string Name { get; init; }
    public required string Iso2 { get; init; }
    public required string Flag { get; init; }
    public required string Continent { get; init; }
    public long? Area { get; init; }
    public long? Population { get; init; }
    public long? Gdp { get; init; }
    public int? GdpPerCapita { get; init; }
    public double? Density { get; init; }
    public double? Literacy { get; init; }
    public double? Hdi { get; init; }
    public double? LifeExpectancy { get; init; }
}

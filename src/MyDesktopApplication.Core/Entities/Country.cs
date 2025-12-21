namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with statistical data for the quiz game.
/// </summary>
public class Country
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public string? Iso2 { get; init; }
    public string? Continent { get; init; }
    public long Population { get; init; }
    public double Area { get; init; }
    public double Gdp { get; init; }
    public double GdpPerCapita { get; init; }
    public double Density { get; init; }
    public double Literacy { get; init; }
    public double Hdi { get; init; }
    public double LifeExpectancy { get; init; }
}

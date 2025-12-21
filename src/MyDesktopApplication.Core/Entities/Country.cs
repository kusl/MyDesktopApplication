namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Country data model with statistics for the quiz game.
/// </summary>
public class Country
{
    public required string Name { get; init; }
    public required string Code { get; init; }
    public required string Continent { get; init; }
    public required string Flag { get; init; }
    
    // Statistics
    public double Population { get; init; }
    public double Area { get; init; }
    public double GdpTotal { get; init; }
    public double GdpPerCapita { get; init; }
    public double PopulationDensity { get; init; }
    public double LiteracyRate { get; init; }
    public double Hdi { get; init; }
    public double LifeExpectancy { get; init; }
}

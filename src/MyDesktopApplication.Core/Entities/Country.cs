namespace MyDesktopApplication.Core.Entities;

public class Country
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public string Iso2 { get; init; } = "";
    public string Flag { get; init; } = "";
    public string Continent { get; init; } = "";
    
    // Core statistics
    public long Population { get; init; }
    public double Area { get; init; }
    public double Gdp { get; init; }
    public double GdpPerCapita { get; init; }
    
    // Derived/alternative names for compatibility
    public double Density { get; init; }
    public double PopulationDensity => Density > 0 ? Density : (Area > 0 ? Population / Area : 0);
    
    public double Literacy { get; init; }
    public double LiteracyRate => Literacy;
    
    public double Hdi { get; init; }
    public double LifeExpectancy { get; init; }
}

namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with various statistics for the quiz game
/// </summary>
public class Country
{
    public required string Code { get; set; }
    public required string Name { get; set; }
    public string Iso2 { get; set; } = "";
    public string Continent { get; set; } = "";
    
    // Statistics
    public double Population { get; set; }
    public double Area { get; set; }
    public double Gdp { get; set; }
    public double GdpPerCapita { get; set; }
    public double Density { get; set; }
    public double Literacy { get; set; }
    public double Hdi { get; set; }
    public double LifeExpectancy { get; set; }
    
    // Optional display properties
    public string? Flag { get; set; }
}

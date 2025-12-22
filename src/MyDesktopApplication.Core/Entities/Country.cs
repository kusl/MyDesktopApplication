namespace MyDesktopApplication.Core.Entities;

public class Country
{
    public required string Code { get; set; }
    public required string Name { get; set; }
    public string Iso2 { get; set; } = "";
    public string Continent { get; set; } = "";
    public long Population { get; set; }
    public double Area { get; set; }
    public double GdpTotal { get; set; }
    public double GdpPerCapita { get; set; }
    public double PopulationDensity { get; set; }
    public double LiteracyRate { get; set; }
    public double Hdi { get; set; }
    public double LifeExpectancy { get; set; }
    
    // Flag emoji based on ISO2 code
    public string Flag => string.IsNullOrEmpty(Iso2) ? "🏳️" : 
        string.Concat(Iso2.ToUpperInvariant().Select(c => char.ConvertFromUtf32(c + 0x1F1A5)));
}

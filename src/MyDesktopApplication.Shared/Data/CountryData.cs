using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Data;

public static class CountryData
{
    private static readonly List<Country> _countries = new()
    {
        new() { Code = "USA", Name = "United States", Iso2 = "US", Continent = "North America", Population = 331900000, Area = 9833517, GdpTotal = 25462700, GdpPerCapita = 76330, PopulationDensity = 33.8, LiteracyRate = 99.0, Hdi = 0.921, LifeExpectancy = 76.4 },
        new() { Code = "CHN", Name = "China", Iso2 = "CN", Continent = "Asia", Population = 1412000000, Area = 9596961, GdpTotal = 17963200, GdpPerCapita = 12720, PopulationDensity = 147.0, LiteracyRate = 96.8, Hdi = 0.768, LifeExpectancy = 78.2 },
        new() { Code = "IND", Name = "India", Iso2 = "IN", Continent = "Asia", Population = 1408000000, Area = 3287263, GdpTotal = 3385090, GdpPerCapita = 2410, PopulationDensity = 428.0, LiteracyRate = 74.4, Hdi = 0.633, LifeExpectancy = 70.8 },
        new() { Code = "BRA", Name = "Brazil", Iso2 = "BR", Continent = "South America", Population = 214300000, Area = 8515767, GdpTotal = 1920100, GdpPerCapita = 8960, PopulationDensity = 25.2, LiteracyRate = 93.2, Hdi = 0.754, LifeExpectancy = 76.0 },
        new() { Code = "RUS", Name = "Russia", Iso2 = "RU", Continent = "Europe", Population = 144100000, Area = 17098242, GdpTotal = 2240400, GdpPerCapita = 15350, PopulationDensity = 8.4, LiteracyRate = 99.7, Hdi = 0.822, LifeExpectancy = 72.6 },
        new() { Code = "JPN", Name = "Japan", Iso2 = "JP", Continent = "Asia", Population = 125700000, Area = 377975, GdpTotal = 4231140, GdpPerCapita = 33650, PopulationDensity = 333.0, LiteracyRate = 99.0, Hdi = 0.925, LifeExpectancy = 84.6 },
        new() { Code = "DEU", Name = "Germany", Iso2 = "DE", Continent = "Europe", Population = 83200000, Area = 357114, GdpTotal = 4072190, GdpPerCapita = 48940, PopulationDensity = 233.0, LiteracyRate = 99.0, Hdi = 0.942, LifeExpectancy = 81.3 },
        new() { Code = "GBR", Name = "United Kingdom", Iso2 = "GB", Continent = "Europe", Population = 67330000, Area = 242495, GdpTotal = 3070670, GdpPerCapita = 45600, PopulationDensity = 278.0, LiteracyRate = 99.0, Hdi = 0.929, LifeExpectancy = 81.2 },
        new() { Code = "FRA", Name = "France", Iso2 = "FR", Continent = "Europe", Population = 67750000, Area = 643801, GdpTotal = 2782910, GdpPerCapita = 41090, PopulationDensity = 105.0, LiteracyRate = 99.0, Hdi = 0.903, LifeExpectancy = 82.7 },
        new() { Code = "ITA", Name = "Italy", Iso2 = "IT", Continent = "Europe", Population = 59110000, Area = 301340, GdpTotal = 2010430, GdpPerCapita = 34010, PopulationDensity = 196.0, LiteracyRate = 99.2, Hdi = 0.895, LifeExpectancy = 83.5 },
        new() { Code = "CAN", Name = "Canada", Iso2 = "CA", Continent = "North America", Population = 38250000, Area = 9984670, GdpTotal = 2139840, GdpPerCapita = 55960, PopulationDensity = 3.8, LiteracyRate = 99.0, Hdi = 0.936, LifeExpectancy = 82.4 },
        new() { Code = "AUS", Name = "Australia", Iso2 = "AU", Continent = "Oceania", Population = 25690000, Area = 7692024, GdpTotal = 1675420, GdpPerCapita = 65210, PopulationDensity = 3.3, LiteracyRate = 99.0, Hdi = 0.951, LifeExpectancy = 83.4 },
        new() { Code = "KOR", Name = "South Korea", Iso2 = "KR", Continent = "Asia", Population = 51740000, Area = 100210, GdpTotal = 1804680, GdpPerCapita = 34870, PopulationDensity = 516.0, LiteracyRate = 99.0, Hdi = 0.925, LifeExpectancy = 83.7 },
        new() { Code = "ESP", Name = "Spain", Iso2 = "ES", Continent = "Europe", Population = 47420000, Area = 505990, GdpTotal = 1397510, GdpPerCapita = 29470, PopulationDensity = 93.7, LiteracyRate = 98.4, Hdi = 0.905, LifeExpectancy = 83.6 },
        new() { Code = "MEX", Name = "Mexico", Iso2 = "MX", Continent = "North America", Population = 130300000, Area = 1964375, GdpTotal = 1293040, GdpPerCapita = 9930, PopulationDensity = 66.3, LiteracyRate = 95.4, Hdi = 0.758, LifeExpectancy = 75.0 },
        new() { Code = "IDN", Name = "Indonesia", Iso2 = "ID", Continent = "Asia", Population = 273800000, Area = 1904569, GdpTotal = 1319100, GdpPerCapita = 4820, PopulationDensity = 144.0, LiteracyRate = 96.0, Hdi = 0.705, LifeExpectancy = 71.9 },
        new() { Code = "NLD", Name = "Netherlands", Iso2 = "NL", Continent = "Europe", Population = 17530000, Area = 41543, GdpTotal = 991110, GdpPerCapita = 56550, PopulationDensity = 422.0, LiteracyRate = 99.0, Hdi = 0.941, LifeExpectancy = 82.3 },
        new() { Code = "SAU", Name = "Saudi Arabia", Iso2 = "SA", Continent = "Asia", Population = 35340000, Area = 2149690, GdpTotal = 1108150, GdpPerCapita = 31360, PopulationDensity = 16.4, LiteracyRate = 97.6, Hdi = 0.875, LifeExpectancy = 76.9 },
        new() { Code = "TUR", Name = "Turkey", Iso2 = "TR", Continent = "Asia", Population = 84780000, Area = 783562, GdpTotal = 905990, GdpPerCapita = 10680, PopulationDensity = 108.0, LiteracyRate = 96.7, Hdi = 0.838, LifeExpectancy = 78.0 },
        new() { Code = "CHE", Name = "Switzerland", Iso2 = "CH", Continent = "Europe", Population = 8700000, Area = 41285, GdpTotal = 807710, GdpPerCapita = 92840, PopulationDensity = 211.0, LiteracyRate = 99.0, Hdi = 0.962, LifeExpectancy = 84.0 },
        new() { Code = "POL", Name = "Poland", Iso2 = "PL", Continent = "Europe", Population = 38180000, Area = 312679, GdpTotal = 688180, GdpPerCapita = 18030, PopulationDensity = 122.0, LiteracyRate = 99.8, Hdi = 0.876, LifeExpectancy = 78.7 },
        new() { Code = "SWE", Name = "Sweden", Iso2 = "SE", Continent = "Europe", Population = 10420000, Area = 450295, GdpTotal = 585940, GdpPerCapita = 56230, PopulationDensity = 23.1, LiteracyRate = 99.0, Hdi = 0.947, LifeExpectancy = 83.0 },
        new() { Code = "BEL", Name = "Belgium", Iso2 = "BE", Continent = "Europe", Population = 11590000, Area = 30528, GdpTotal = 578600, GdpPerCapita = 49930, PopulationDensity = 380.0, LiteracyRate = 99.0, Hdi = 0.937, LifeExpectancy = 82.0 },
        new() { Code = "NOR", Name = "Norway", Iso2 = "NO", Continent = "Europe", Population = 5470000, Area = 385207, GdpTotal = 579270, GdpPerCapita = 105890, PopulationDensity = 14.2, LiteracyRate = 99.0, Hdi = 0.961, LifeExpectancy = 83.2 },
        new() { Code = "ARG", Name = "Argentina", Iso2 = "AR", Continent = "South America", Population = 45810000, Area = 2780400, GdpTotal = 632770, GdpPerCapita = 13810, PopulationDensity = 16.5, LiteracyRate = 99.0, Hdi = 0.842, LifeExpectancy = 77.3 },
        new() { Code = "AUT", Name = "Austria", Iso2 = "AT", Continent = "Europe", Population = 9000000, Area = 83879, GdpTotal = 471400, GdpPerCapita = 52380, PopulationDensity = 107.0, LiteracyRate = 99.0, Hdi = 0.916, LifeExpectancy = 82.0 },
        new() { Code = "IRN", Name = "Iran", Iso2 = "IR", Continent = "Asia", Population = 87590000, Area = 1648195, GdpTotal = 366440, GdpPerCapita = 4180, PopulationDensity = 53.1, LiteracyRate = 85.5, Hdi = 0.774, LifeExpectancy = 76.7 },
        new() { Code = "THA", Name = "Thailand", Iso2 = "TH", Continent = "Asia", Population = 69950000, Area = 513120, GdpTotal = 505950, GdpPerCapita = 7230, PopulationDensity = 136.0, LiteracyRate = 93.8, Hdi = 0.800, LifeExpectancy = 78.7 },
        new() { Code = "ARE", Name = "United Arab Emirates", Iso2 = "AE", Continent = "Asia", Population = 9890000, Area = 83600, GdpTotal = 421140, GdpPerCapita = 42600, PopulationDensity = 118.0, LiteracyRate = 93.8, Hdi = 0.911, LifeExpectancy = 78.0 },
        new() { Code = "NGA", Name = "Nigeria", Iso2 = "NG", Continent = "Africa", Population = 218500000, Area = 923768, GdpTotal = 440830, GdpPerCapita = 2020, PopulationDensity = 236.0, LiteracyRate = 62.0, Hdi = 0.535, LifeExpectancy = 55.4 },
        new() { Code = "ISR", Name = "Israel", Iso2 = "IL", Continent = "Asia", Population = 9450000, Area = 22072, GdpTotal = 520700, GdpPerCapita = 55110, PopulationDensity = 428.0, LiteracyRate = 97.8, Hdi = 0.919, LifeExpectancy = 83.0 },
        new() { Code = "EGY", Name = "Egypt", Iso2 = "EG", Continent = "Africa", Population = 104300000, Area = 1002450, GdpTotal = 476750, GdpPerCapita = 4570, PopulationDensity = 104.0, LiteracyRate = 71.2, Hdi = 0.731, LifeExpectancy = 72.0 },
        new() { Code = "SGP", Name = "Singapore", Iso2 = "SG", Continent = "Asia", Population = 5450000, Area = 733, GdpTotal = 396990, GdpPerCapita = 72790, PopulationDensity = 7440.0, LiteracyRate = 97.5, Hdi = 0.939, LifeExpectancy = 84.1 },
        new() { Code = "VNM", Name = "Vietnam", Iso2 = "VN", Continent = "Asia", Population = 98170000, Area = 331212, GdpTotal = 408800, GdpPerCapita = 4160, PopulationDensity = 296.0, LiteracyRate = 95.8, Hdi = 0.703, LifeExpectancy = 75.8 },
        new() { Code = "PHL", Name = "Philippines", Iso2 = "PH", Continent = "Asia", Population = 113900000, Area = 300000, GdpTotal = 404260, GdpPerCapita = 3550, PopulationDensity = 380.0, LiteracyRate = 96.3, Hdi = 0.699, LifeExpectancy = 72.1 },
        new() { Code = "ZAF", Name = "South Africa", Iso2 = "ZA", Continent = "Africa", Population = 60040000, Area = 1221037, GdpTotal = 405270, GdpPerCapita = 6750, PopulationDensity = 49.2, LiteracyRate = 95.0, Hdi = 0.713, LifeExpectancy = 65.3 },
        new() { Code = "PAK", Name = "Pakistan", Iso2 = "PK", Continent = "Asia", Population = 231400000, Area = 881913, GdpTotal = 376530, GdpPerCapita = 1630, PopulationDensity = 262.0, LiteracyRate = 59.1, Hdi = 0.544, LifeExpectancy = 67.3 },
        new() { Code = "BGD", Name = "Bangladesh", Iso2 = "BD", Continent = "Asia", Population = 169400000, Area = 148460, GdpTotal = 460200, GdpPerCapita = 2720, PopulationDensity = 1140.0, LiteracyRate = 74.7, Hdi = 0.661, LifeExpectancy = 73.4 },
        new() { Code = "DNK", Name = "Denmark", Iso2 = "DK", Continent = "Europe", Population = 5860000, Area = 43094, GdpTotal = 395400, GdpPerCapita = 67500, PopulationDensity = 136.0, LiteracyRate = 99.0, Hdi = 0.948, LifeExpectancy = 81.4 },
        new() { Code = "FIN", Name = "Finland", Iso2 = "FI", Continent = "Europe", Population = 5540000, Area = 338424, GdpTotal = 299150, GdpPerCapita = 54010, PopulationDensity = 16.4, LiteracyRate = 99.0, Hdi = 0.940, LifeExpectancy = 82.1 },
        new() { Code = "NZL", Name = "New Zealand", Iso2 = "NZ", Continent = "Oceania", Population = 5124000, Area = 268021, GdpTotal = 249890, GdpPerCapita = 48780, PopulationDensity = 19.1, LiteracyRate = 99.0, Hdi = 0.937, LifeExpectancy = 82.5 },
        new() { Code = "CHL", Name = "Chile", Iso2 = "CL", Continent = "South America", Population = 19490000, Area = 756102, GdpTotal = 317060, GdpPerCapita = 16270, PopulationDensity = 25.8, LiteracyRate = 96.9, Hdi = 0.855, LifeExpectancy = 80.7 },
        new() { Code = "COL", Name = "Colombia", Iso2 = "CO", Continent = "South America", Population = 51870000, Area = 1141748, GdpTotal = 343940, GdpPerCapita = 6630, PopulationDensity = 45.4, LiteracyRate = 95.6, Hdi = 0.752, LifeExpectancy = 77.3 },
        new() { Code = "PER", Name = "Peru", Iso2 = "PE", Continent = "South America", Population = 33360000, Area = 1285216, GdpTotal = 242630, GdpPerCapita = 7270, PopulationDensity = 26.0, LiteracyRate = 94.5, Hdi = 0.762, LifeExpectancy = 77.0 },
        new() { Code = "KEN", Name = "Kenya", Iso2 = "KE", Continent = "Africa", Population = 54030000, Area = 580367, GdpTotal = 113420, GdpPerCapita = 2100, PopulationDensity = 93.1, LiteracyRate = 81.5, Hdi = 0.575, LifeExpectancy = 67.0 },
        new() { Code = "ETH", Name = "Ethiopia", Iso2 = "ET", Continent = "Africa", Population = 120300000, Area = 1104300, GdpTotal = 126780, GdpPerCapita = 1050, PopulationDensity = 109.0, LiteracyRate = 51.8, Hdi = 0.498, LifeExpectancy = 67.8 },
        new() { Code = "GHA", Name = "Ghana", Iso2 = "GH", Continent = "Africa", Population = 32830000, Area = 238533, GdpTotal = 77590, GdpPerCapita = 2360, PopulationDensity = 138.0, LiteracyRate = 79.0, Hdi = 0.632, LifeExpectancy = 64.9 },
        new() { Code = "TZA", Name = "Tanzania", Iso2 = "TZ", Continent = "Africa", Population = 63590000, Area = 947303, GdpTotal = 75710, GdpPerCapita = 1190, PopulationDensity = 67.1, LiteracyRate = 77.9, Hdi = 0.549, LifeExpectancy = 66.2 },
        new() { Code = "UGA", Name = "Uganda", Iso2 = "UG", Continent = "Africa", Population = 47250000, Area = 241550, GdpTotal = 45570, GdpPerCapita = 960, PopulationDensity = 196.0, LiteracyRate = 76.5, Hdi = 0.525, LifeExpectancy = 63.7 },
        new() { Code = "ISL", Name = "Iceland", Iso2 = "IS", Continent = "Europe", Population = 372000, Area = 103000, GdpTotal = 27840, GdpPerCapita = 74840, PopulationDensity = 3.6, LiteracyRate = 99.0, Hdi = 0.959, LifeExpectancy = 83.1 }
    };

    public static IReadOnlyList<Country> GetAllCountries() => _countries.AsReadOnly();
    
    public static Country? GetByCode(string code) => _countries.FirstOrDefault(c => c.Code == code);
    
    public static IReadOnlyList<Country> GetByContinent(string continent) => 
        _countries.Where(c => c.Continent == continent).ToList().AsReadOnly();
}

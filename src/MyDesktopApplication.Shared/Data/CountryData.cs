using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Data;

/// <summary>
/// Static country data for the quiz game.
/// Data sources: World Bank, UN, IMF, UNDP (2023/2024 estimates).
/// </summary>
public static class CountryData
{
    public static IReadOnlyList<Country> Countries { get; } = new List<Country>
    {
        // Africa
        new() { Code = "NGA", Name = "Nigeria", Iso2 = "NG", Continent = "Africa", Population = 223800000, Area = 923769, Gdp = 477000000000, GdpPerCapita = 2131, Density = 242, Literacy = 62, Hdi = 0.539, LifeExpectancy = 53.9 },
        new() { Code = "ETH", Name = "Ethiopia", Iso2 = "ET", Continent = "Africa", Population = 126500000, Area = 1104300, Gdp = 156000000000, GdpPerCapita = 1233, Density = 115, Literacy = 52, Hdi = 0.498, LifeExpectancy = 67.8 },
        new() { Code = "EGY", Name = "Egypt", Iso2 = "EG", Continent = "Africa", Population = 105000000, Area = 1002450, Gdp = 476700000000, GdpPerCapita = 4538, Density = 105, Literacy = 71, Hdi = 0.731, LifeExpectancy = 72.1 },
        new() { Code = "ZAF", Name = "South Africa", Iso2 = "ZA", Continent = "Africa", Population = 60000000, Area = 1219090, Gdp = 405000000000, GdpPerCapita = 6750, Density = 49, Literacy = 95, Hdi = 0.713, LifeExpectancy = 65.3 },
        new() { Code = "KEN", Name = "Kenya", Iso2 = "KE", Continent = "Africa", Population = 54000000, Area = 580367, Gdp = 113400000000, GdpPerCapita = 2100, Density = 93, Literacy = 82, Hdi = 0.575, LifeExpectancy = 67.5 },
        new() { Code = "MAR", Name = "Morocco", Iso2 = "MA", Continent = "Africa", Population = 37500000, Area = 446550, Gdp = 142900000000, GdpPerCapita = 3810, Density = 84, Literacy = 74, Hdi = 0.683, LifeExpectancy = 77.4 },
        new() { Code = "GHA", Name = "Ghana", Iso2 = "GH", Continent = "Africa", Population = 33500000, Area = 238535, Gdp = 77590000000, GdpPerCapita = 2316, Density = 140, Literacy = 79, Hdi = 0.632, LifeExpectancy = 64.9 },
        
        // Asia
        new() { Code = "CHN", Name = "China", Iso2 = "CN", Continent = "Asia", Population = 1411750000, Area = 9596961, Gdp = 17963000000000, GdpPerCapita = 12720, Density = 147, Literacy = 97, Hdi = 0.768, LifeExpectancy = 78.2 },
        new() { Code = "IND", Name = "India", Iso2 = "IN", Continent = "Asia", Population = 1428630000, Area = 3287263, Gdp = 3730000000000, GdpPerCapita = 2612, Density = 435, Literacy = 77, Hdi = 0.644, LifeExpectancy = 70.4 },
        new() { Code = "IDN", Name = "Indonesia", Iso2 = "ID", Continent = "Asia", Population = 277500000, Area = 1904569, Gdp = 1319000000000, GdpPerCapita = 4752, Density = 146, Literacy = 96, Hdi = 0.713, LifeExpectancy = 72.3 },
        new() { Code = "PAK", Name = "Pakistan", Iso2 = "PK", Continent = "Asia", Population = 235800000, Area = 881913, Gdp = 376500000000, GdpPerCapita = 1597, Density = 267, Literacy = 59, Hdi = 0.544, LifeExpectancy = 67.3 },
        new() { Code = "BGD", Name = "Bangladesh", Iso2 = "BD", Continent = "Asia", Population = 172000000, Area = 147570, Gdp = 460200000000, GdpPerCapita = 2676, Density = 1166, Literacy = 75, Hdi = 0.661, LifeExpectancy = 73.4 },
        new() { Code = "JPN", Name = "Japan", Iso2 = "JP", Continent = "Asia", Population = 124500000, Area = 377975, Gdp = 4231000000000, GdpPerCapita = 33973, Density = 329, Literacy = 99, Hdi = 0.920, LifeExpectancy = 84.6 },
        new() { Code = "PHL", Name = "Philippines", Iso2 = "PH", Continent = "Asia", Population = 115600000, Area = 300000, Gdp = 404300000000, GdpPerCapita = 3498, Density = 385, Literacy = 98, Hdi = 0.699, LifeExpectancy = 72.1 },
        new() { Code = "VNM", Name = "Vietnam", Iso2 = "VN", Continent = "Asia", Population = 100000000, Area = 331212, Gdp = 449000000000, GdpPerCapita = 4490, Density = 302, Literacy = 96, Hdi = 0.726, LifeExpectancy = 75.8 },
        new() { Code = "TUR", Name = "Turkey", Iso2 = "TR", Continent = "Asia", Population = 85300000, Area = 783356, Gdp = 905500000000, GdpPerCapita = 10618, Density = 109, Literacy = 97, Hdi = 0.838, LifeExpectancy = 78.6 },
        new() { Code = "IRN", Name = "Iran", Iso2 = "IR", Continent = "Asia", Population = 87900000, Area = 1648195, Gdp = 388500000000, GdpPerCapita = 4420, Density = 53, Literacy = 88, Hdi = 0.774, LifeExpectancy = 77.3 },
        new() { Code = "THA", Name = "Thailand", Iso2 = "TH", Continent = "Asia", Population = 71800000, Area = 513120, Gdp = 495300000000, GdpPerCapita = 6900, Density = 140, Literacy = 94, Hdi = 0.800, LifeExpectancy = 79.3 },
        new() { Code = "MMR", Name = "Myanmar", Iso2 = "MM", Continent = "Asia", Population = 54200000, Area = 676578, Gdp = 59400000000, GdpPerCapita = 1096, Density = 80, Literacy = 90, Hdi = 0.585, LifeExpectancy = 69.1 },
        new() { Code = "KOR", Name = "South Korea", Iso2 = "KR", Continent = "Asia", Population = 51700000, Area = 100210, Gdp = 1665000000000, GdpPerCapita = 32220, Density = 516, Literacy = 99, Hdi = 0.925, LifeExpectancy = 83.7 },
        new() { Code = "MYS", Name = "Malaysia", Iso2 = "MY", Continent = "Asia", Population = 33940000, Area = 330803, Gdp = 407000000000, GdpPerCapita = 11993, Density = 103, Literacy = 95, Hdi = 0.803, LifeExpectancy = 76.9 },
        new() { Code = "SAU", Name = "Saudi Arabia", Iso2 = "SA", Continent = "Asia", Population = 36400000, Area = 2149690, Gdp = 1069000000000, GdpPerCapita = 29369, Density = 17, Literacy = 98, Hdi = 0.875, LifeExpectancy = 76.9 },
        new() { Code = "NPL", Name = "Nepal", Iso2 = "NP", Continent = "Asia", Population = 30900000, Area = 147181, Gdp = 40830000000, GdpPerCapita = 1321, Density = 210, Literacy = 68, Hdi = 0.602, LifeExpectancy = 71.7 },
        new() { Code = "ARE", Name = "United Arab Emirates", Iso2 = "AE", Continent = "Asia", Population = 9440000, Area = 83600, Gdp = 498000000000, GdpPerCapita = 52757, Density = 113, Literacy = 98, Hdi = 0.911, LifeExpectancy = 78.7 },
        new() { Code = "ISR", Name = "Israel", Iso2 = "IL", Continent = "Asia", Population = 9730000, Area = 20770, Gdp = 525000000000, GdpPerCapita = 53969, Density = 468, Literacy = 98, Hdi = 0.915, LifeExpectancy = 83.5 },
        new() { Code = "SGP", Name = "Singapore", Iso2 = "SG", Continent = "Asia", Population = 5450000, Area = 733, Gdp = 501400000000, GdpPerCapita = 91990, Density = 7438, Literacy = 97, Hdi = 0.939, LifeExpectancy = 84.1 },
        
        // Europe
        new() { Code = "RUS", Name = "Russia", Iso2 = "RU", Continent = "Europe", Population = 144400000, Area = 17098242, Gdp = 2240000000000, GdpPerCapita = 15512, Density = 8, Literacy = 100, Hdi = 0.822, LifeExpectancy = 73.2 },
        new() { Code = "DEU", Name = "Germany", Iso2 = "DE", Continent = "Europe", Population = 83200000, Area = 357022, Gdp = 4259000000000, GdpPerCapita = 51203, Density = 233, Literacy = 99, Hdi = 0.942, LifeExpectancy = 81.9 },
        new() { Code = "GBR", Name = "United Kingdom", Iso2 = "GB", Continent = "Europe", Population = 67000000, Area = 242495, Gdp = 3070000000000, GdpPerCapita = 45820, Density = 276, Literacy = 99, Hdi = 0.929, LifeExpectancy = 82.0 },
        new() { Code = "FRA", Name = "France", Iso2 = "FR", Continent = "Europe", Population = 67750000, Area = 643801, Gdp = 2937000000000, GdpPerCapita = 43343, Density = 105, Literacy = 99, Hdi = 0.903, LifeExpectancy = 83.0 },
        new() { Code = "ITA", Name = "Italy", Iso2 = "IT", Continent = "Europe", Population = 58900000, Area = 301340, Gdp = 2107000000000, GdpPerCapita = 35776, Density = 196, Literacy = 99, Hdi = 0.895, LifeExpectancy = 84.0 },
        new() { Code = "ESP", Name = "Spain", Iso2 = "ES", Continent = "Europe", Population = 47420000, Area = 505990, Gdp = 1492000000000, GdpPerCapita = 31468, Density = 94, Literacy = 98, Hdi = 0.905, LifeExpectancy = 84.4 },
        new() { Code = "UKR", Name = "Ukraine", Iso2 = "UA", Continent = "Europe", Population = 37000000, Area = 603550, Gdp = 160500000000, GdpPerCapita = 4338, Density = 61, Literacy = 100, Hdi = 0.773, LifeExpectancy = 73.6 },
        new() { Code = "POL", Name = "Poland", Iso2 = "PL", Continent = "Europe", Population = 37700000, Area = 312696, Gdp = 688200000000, GdpPerCapita = 18258, Density = 121, Literacy = 99, Hdi = 0.876, LifeExpectancy = 78.8 },
        new() { Code = "ROU", Name = "Romania", Iso2 = "RO", Continent = "Europe", Population = 19050000, Area = 238397, Gdp = 312800000000, GdpPerCapita = 16422, Density = 80, Literacy = 99, Hdi = 0.821, LifeExpectancy = 76.6 },
        new() { Code = "NLD", Name = "Netherlands", Iso2 = "NL", Continent = "Europe", Population = 17590000, Area = 41543, Gdp = 1009000000000, GdpPerCapita = 57371, Density = 423, Literacy = 99, Hdi = 0.946, LifeExpectancy = 82.8 },
        new() { Code = "BEL", Name = "Belgium", Iso2 = "BE", Continent = "Europe", Population = 11590000, Area = 30528, Gdp = 578200000000, GdpPerCapita = 49887, Density = 380, Literacy = 99, Hdi = 0.937, LifeExpectancy = 82.2 },
        new() { Code = "GRC", Name = "Greece", Iso2 = "GR", Continent = "Europe", Population = 10360000, Area = 131957, Gdp = 218000000000, GdpPerCapita = 21044, Density = 79, Literacy = 98, Hdi = 0.887, LifeExpectancy = 82.2 },
        new() { Code = "CZE", Name = "Czechia", Iso2 = "CZ", Continent = "Europe", Population = 10510000, Area = 78867, Gdp = 290900000000, GdpPerCapita = 27683, Density = 133, Literacy = 99, Hdi = 0.889, LifeExpectancy = 79.9 },
        new() { Code = "PRT", Name = "Portugal", Iso2 = "PT", Continent = "Europe", Population = 10330000, Area = 92212, Gdp = 255850000000, GdpPerCapita = 24775, Density = 112, Literacy = 96, Hdi = 0.866, LifeExpectancy = 82.7 },
        new() { Code = "SWE", Name = "Sweden", Iso2 = "SE", Continent = "Europe", Population = 10540000, Area = 450295, Gdp = 585940000000, GdpPerCapita = 55603, Density = 23, Literacy = 99, Hdi = 0.947, LifeExpectancy = 83.3 },
        new() { Code = "HUN", Name = "Hungary", Iso2 = "HU", Continent = "Europe", Population = 9600000, Area = 93028, Gdp = 188500000000, GdpPerCapita = 19635, Density = 103, Literacy = 99, Hdi = 0.846, LifeExpectancy = 77.0 },
        new() { Code = "AUT", Name = "Austria", Iso2 = "AT", Continent = "Europe", Population = 9040000, Area = 83871, Gdp = 471400000000, GdpPerCapita = 52152, Density = 108, Literacy = 99, Hdi = 0.916, LifeExpectancy = 82.0 },
        new() { Code = "CHE", Name = "Switzerland", Iso2 = "CH", Continent = "Europe", Population = 8770000, Area = 41285, Gdp = 884940000000, GdpPerCapita = 100916, Density = 212, Literacy = 99, Hdi = 0.962, LifeExpectancy = 84.4 },
        new() { Code = "BGR", Name = "Bulgaria", Iso2 = "BG", Continent = "Europe", Population = 6870000, Area = 110879, Gdp = 89040000000, GdpPerCapita = 12960, Density = 62, Literacy = 98, Hdi = 0.795, LifeExpectancy = 75.1 },
        new() { Code = "DNK", Name = "Denmark", Iso2 = "DK", Continent = "Europe", Population = 5910000, Area = 43094, Gdp = 395400000000, GdpPerCapita = 66914, Density = 137, Literacy = 99, Hdi = 0.948, LifeExpectancy = 81.6 },
        new() { Code = "FIN", Name = "Finland", Iso2 = "FI", Continent = "Europe", Population = 5540000, Area = 338145, Gdp = 300190000000, GdpPerCapita = 54188, Density = 16, Literacy = 99, Hdi = 0.940, LifeExpectancy = 82.2 },
        new() { Code = "NOR", Name = "Norway", Iso2 = "NO", Continent = "Europe", Population = 5470000, Area = 323802, Gdp = 485510000000, GdpPerCapita = 88783, Density = 17, Literacy = 99, Hdi = 0.961, LifeExpectancy = 83.2 },
        new() { Code = "IRL", Name = "Ireland", Iso2 = "IE", Continent = "Europe", Population = 5130000, Area = 70273, Gdp = 504180000000, GdpPerCapita = 98268, Density = 73, Literacy = 99, Hdi = 0.945, LifeExpectancy = 82.8 },
        
        // North America
        new() { Code = "USA", Name = "United States", Iso2 = "US", Continent = "North America", Population = 331900000, Area = 9833517, Gdp = 27360000000000, GdpPerCapita = 82422, Density = 34, Literacy = 99, Hdi = 0.921, LifeExpectancy = 79.1 },
        new() { Code = "MEX", Name = "Mexico", Iso2 = "MX", Continent = "North America", Population = 128900000, Area = 1964375, Gdp = 1811000000000, GdpPerCapita = 14050, Density = 66, Literacy = 95, Hdi = 0.758, LifeExpectancy = 75.0 },
        new() { Code = "CAN", Name = "Canada", Iso2 = "CA", Continent = "North America", Population = 40100000, Area = 9984670, Gdp = 2139000000000, GdpPerCapita = 53340, Density = 4, Literacy = 99, Hdi = 0.936, LifeExpectancy = 82.7 },
        new() { Code = "GTM", Name = "Guatemala", Iso2 = "GT", Continent = "North America", Population = 18090000, Area = 108889, Gdp = 95000000000, GdpPerCapita = 5251, Density = 166, Literacy = 83, Hdi = 0.627, LifeExpectancy = 74.3 },
        new() { Code = "CUB", Name = "Cuba", Iso2 = "CU", Continent = "North America", Population = 11100000, Area = 109884, Gdp = 107400000000, GdpPerCapita = 9676, Density = 101, Literacy = 100, Hdi = 0.764, LifeExpectancy = 79.2 },
        new() { Code = "DOM", Name = "Dominican Republic", Iso2 = "DO", Continent = "North America", Population = 11230000, Area = 48671, Gdp = 113640000000, GdpPerCapita = 10119, Density = 231, Literacy = 95, Hdi = 0.767, LifeExpectancy = 74.1 },
        new() { Code = "HND", Name = "Honduras", Iso2 = "HN", Continent = "North America", Population = 10280000, Area = 112492, Gdp = 31720000000, GdpPerCapita = 3086, Density = 91, Literacy = 89, Hdi = 0.621, LifeExpectancy = 75.3 },
        new() { Code = "HTI", Name = "Haiti", Iso2 = "HT", Continent = "North America", Population = 11720000, Area = 27750, Gdp = 19710000000, GdpPerCapita = 1682, Density = 422, Literacy = 62, Hdi = 0.535, LifeExpectancy = 64.9 },
        
        // South America
        new() { Code = "BRA", Name = "Brazil", Iso2 = "BR", Continent = "South America", Population = 214300000, Area = 8515767, Gdp = 2126000000000, GdpPerCapita = 9921, Density = 25, Literacy = 93, Hdi = 0.760, LifeExpectancy = 76.4 },
        new() { Code = "COL", Name = "Colombia", Iso2 = "CO", Continent = "South America", Population = 51870000, Area = 1141748, Gdp = 363500000000, GdpPerCapita = 7007, Density = 45, Literacy = 95, Hdi = 0.752, LifeExpectancy = 77.3 },
        new() { Code = "ARG", Name = "Argentina", Iso2 = "AR", Continent = "South America", Population = 45810000, Area = 2780400, Gdp = 641100000000, GdpPerCapita = 13996, Density = 16, Literacy = 99, Hdi = 0.842, LifeExpectancy = 77.1 },
        new() { Code = "PER", Name = "Peru", Iso2 = "PE", Continent = "South America", Population = 34050000, Area = 1285216, Gdp = 267600000000, GdpPerCapita = 7859, Density = 26, Literacy = 95, Hdi = 0.762, LifeExpectancy = 77.4 },
        new() { Code = "VEN", Name = "Venezuela", Iso2 = "VE", Continent = "South America", Population = 28400000, Area = 916445, Gdp = 92100000000, GdpPerCapita = 3243, Density = 31, Literacy = 97, Hdi = 0.691, LifeExpectancy = 72.1 },
        new() { Code = "CHL", Name = "Chile", Iso2 = "CL", Continent = "South America", Population = 19490000, Area = 756102, Gdp = 335500000000, GdpPerCapita = 17218, Density = 26, Literacy = 97, Hdi = 0.855, LifeExpectancy = 80.7 },
        new() { Code = "ECU", Name = "Ecuador", Iso2 = "EC", Continent = "South America", Population = 18190000, Area = 256369, Gdp = 118850000000, GdpPerCapita = 6534, Density = 71, Literacy = 94, Hdi = 0.765, LifeExpectancy = 77.9 },
        new() { Code = "BOL", Name = "Bolivia", Iso2 = "BO", Continent = "South America", Population = 12080000, Area = 1098581, Gdp = 44010000000, GdpPerCapita = 3644, Density = 11, Literacy = 94, Hdi = 0.692, LifeExpectancy = 72.1 },
        new() { Code = "PRY", Name = "Paraguay", Iso2 = "PY", Continent = "South America", Population = 6780000, Area = 406752, Gdp = 42000000000, GdpPerCapita = 6195, Density = 17, Literacy = 95, Hdi = 0.717, LifeExpectancy = 74.5 },
        new() { Code = "URY", Name = "Uruguay", Iso2 = "UY", Continent = "South America", Population = 3420000, Area = 176215, Gdp = 71180000000, GdpPerCapita = 20813, Density = 19, Literacy = 99, Hdi = 0.830, LifeExpectancy = 78.4 },
        
        // Oceania
        new() { Code = "AUS", Name = "Australia", Iso2 = "AU", Continent = "Oceania", Population = 26440000, Area = 7692024, Gdp = 1675000000000, GdpPerCapita = 63360, Density = 3, Literacy = 99, Hdi = 0.951, LifeExpectancy = 84.5 },
        new() { Code = "PNG", Name = "Papua New Guinea", Iso2 = "PG", Continent = "Oceania", Population = 10140000, Area = 462840, Gdp = 30600000000, GdpPerCapita = 3018, Density = 22, Literacy = 65, Hdi = 0.558, LifeExpectancy = 65.4 },
        new() { Code = "NZL", Name = "New Zealand", Iso2 = "NZ", Continent = "Oceania", Population = 5120000, Area = 268021, Gdp = 247700000000, GdpPerCapita = 48379, Density = 19, Literacy = 99, Hdi = 0.937, LifeExpectancy = 82.5 },
        new() { Code = "FJI", Name = "Fiji", Iso2 = "FJ", Continent = "Oceania", Population = 930000, Area = 18274, Gdp = 5310000000, GdpPerCapita = 5710, Density = 51, Literacy = 99, Hdi = 0.730, LifeExpectancy = 67.4 },
    };
}

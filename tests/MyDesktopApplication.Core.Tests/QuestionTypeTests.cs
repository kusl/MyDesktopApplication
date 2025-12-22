using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Area, "Area (km²)")]
    [InlineData(QuestionType.GdpTotal, "GDP (Total USD)")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita (USD)")]
    [InlineData(QuestionType.PopulationDensity, "Population Density (per km²)")]
    [InlineData(QuestionType.LiteracyRate, "Literacy Rate (%)")]
    [InlineData(QuestionType.Hdi, "Human Development Index")]
    [InlineData(QuestionType.LifeExpectancy, "Life Expectancy (years)")]
    public void GetLabel_ReturnsCorrectLabel(QuestionType questionType, string expectedLabel)
    {
        var label = questionType.GetLabel();
        label.ShouldBe(expectedLabel);
    }

    [Fact]
    public void GetValue_ReturnsCorrectValueForCountry()
    {
        var country = new Country
        {
            Code = "USA",
            Name = "United States",
            Iso2 = "US",
            Continent = "North America",
            Population = 331_000_000,
            Area = 9_833_520,
            GdpTotal = 25_462_700_000_000,
            GdpPerCapita = 76_330,
            PopulationDensity = 33.6,
            LiteracyRate = 99.0,
            Hdi = 0.921,
            LifeExpectancy = 77.0
        };

        QuestionType.Population.GetValue(country).ShouldBe(331_000_000);
        QuestionType.Area.GetValue(country).ShouldBe(9_833_520);
        QuestionType.GdpTotal.GetValue(country).ShouldBe(25_462_700_000_000);
        QuestionType.GdpPerCapita.GetValue(country).ShouldBe(76_330);
        QuestionType.PopulationDensity.GetValue(country).ShouldBe(33.6);
        QuestionType.LiteracyRate.GetValue(country).ShouldBe(99.0);
        QuestionType.Hdi.GetValue(country).ShouldBe(0.921);
        QuestionType.LifeExpectancy.GetValue(country).ShouldBe(77.0);
    }

    [Fact]
    public void FormatValue_FormatsValuesCorrectly()
    {
        QuestionType.Population.FormatValue(1_500_000_000).ShouldBe("1.50B");
        QuestionType.GdpTotal.FormatValue(25_000_000_000_000).ShouldBe("$25.00T");
        QuestionType.LiteracyRate.FormatValue(99.5).ShouldBe("99.5%");
        QuestionType.Hdi.FormatValue(0.921).ShouldBe("0.921");
        QuestionType.LifeExpectancy.FormatValue(77.5).ShouldBe("77.5 years");
    }
}

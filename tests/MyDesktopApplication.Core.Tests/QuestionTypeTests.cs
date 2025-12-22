using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Area, "Area (km²)")]
    [InlineData(QuestionType.Gdp, "GDP (USD)")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita (USD)")]
    [InlineData(QuestionType.Density, "Population Density (per km²)")]
    [InlineData(QuestionType.Literacy, "Literacy Rate (%)")]
    [InlineData(QuestionType.Hdi, "Human Development Index")]
    [InlineData(QuestionType.LifeExpectancy, "Life Expectancy (years)")]
    public void GetLabel_ReturnsCorrectLabel(QuestionType questionType, string expectedLabel)
    {
        // Act
        var label = questionType.GetLabel();

        // Assert
        label.ShouldBe(expectedLabel);
    }

    [Fact]
    public void GetValue_ReturnsCorrectValueForCountry()
    {
        // Arrange
        var country = new Country
        {
            Code = "USA",
            Name = "United States",
            Iso2 = "US",
            Continent = "North America",
            Population = 331_000_000,
            Area = 9_833_520,
            Gdp = 25_462_700_000_000,
            GdpPerCapita = 76_330,
            Density = 33.6,
            Literacy = 99.0,
            Hdi = 0.921,
            LifeExpectancy = 77.0
        };

        // Act & Assert
        QuestionType.Population.GetValue(country).ShouldBe(331_000_000);
        QuestionType.Area.GetValue(country).ShouldBe(9_833_520);
        QuestionType.Gdp.GetValue(country).ShouldBe(25_462_700_000_000);
        QuestionType.GdpPerCapita.GetValue(country).ShouldBe(76_330);
        QuestionType.Density.GetValue(country).ShouldBe(33.6);
        QuestionType.Literacy.GetValue(country).ShouldBe(99.0);
        QuestionType.Hdi.GetValue(country).ShouldBe(0.921);
        QuestionType.LifeExpectancy.GetValue(country).ShouldBe(77.0);
    }

    [Fact]
    public void FormatValue_FormatsPopulationCorrectly()
    {
        // Arrange & Act & Assert
        QuestionType.Population.FormatValue(1_500_000_000).ShouldBe("1.50B");
        QuestionType.Population.FormatValue(331_000_000).ShouldBe("331.00M");
        QuestionType.Population.FormatValue(500_000).ShouldBe("500.00K");
        QuestionType.Population.FormatValue(999).ShouldBe("999");
    }

    [Fact]
    public void FormatValue_FormatsCurrencyCorrectly()
    {
        // Arrange & Act & Assert
        QuestionType.Gdp.FormatValue(25_000_000_000_000).ShouldBe("$25.00T");
        QuestionType.Gdp.FormatValue(1_500_000_000).ShouldBe("$1.50B");
        QuestionType.Gdp.FormatValue(500_000_000).ShouldBe("$500.00M");
    }

    [Fact]
    public void FormatValue_FormatsPercentageCorrectly()
    {
        QuestionType.Literacy.FormatValue(99.5).ShouldBe("99.5%");
    }

    [Fact]
    public void FormatValue_FormatsHdiCorrectly()
    {
        QuestionType.Hdi.FormatValue(0.921).ShouldBe("0.921");
    }

    [Fact]
    public void FormatValue_FormatsLifeExpectancyCorrectly()
    {
        QuestionType.LifeExpectancy.FormatValue(77.5).ShouldBe("77.5 years");
    }
}

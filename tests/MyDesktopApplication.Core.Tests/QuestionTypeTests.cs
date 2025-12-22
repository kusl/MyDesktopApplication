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
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita")]
    [InlineData(QuestionType.Density, "Population Density")]
    [InlineData(QuestionType.Literacy, "Literacy Rate (%)")]
    [InlineData(QuestionType.Hdi, "Human Development Index")]
    [InlineData(QuestionType.LifeExpectancy, "Life Expectancy")]
    public void GetLabel_ShouldReturnCorrectLabel(QuestionType type, string expectedLabel)
    {
        type.GetLabel().ShouldBe(expectedLabel);
    }

    [Fact]
    public void GetValue_ShouldReturnCorrectProperty()
    {
        var country = new Country
        {
            Code = "USA",
            Name = "United States",
            Flag = "🇺🇸",
            Population = 331_000_000,
            Area = 9_833_520,
            Gdp = 25_462_700_000_000,
            GdpPerCapita = 76_329,
            Density = 36,
            Literacy = 99.0,
            Hdi = 0.921,
            LifeExpectancy = 76.4
        };

        QuestionType.Population.GetValue(country).ShouldBe(331_000_000);
        QuestionType.Area.GetValue(country).ShouldBe(9_833_520);
        QuestionType.Density.GetValue(country).ShouldBe(36);
        QuestionType.Literacy.GetValue(country).ShouldBe(99.0);
    }

    [Theory]
    [InlineData(1_500_000_000, "1.50B")]
    [InlineData(350_000_000, "350.00M")]
    [InlineData(50_000, "50.0K")]
    public void FormatValue_Population_ShouldFormatCorrectly(double value, string expected)
    {
        QuestionType.Population.FormatValue(value).ShouldBe(expected);
    }
}

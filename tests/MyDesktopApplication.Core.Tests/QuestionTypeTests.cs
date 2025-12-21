using Xunit;
using Shouldly;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Area, "Area (km²)")]
    [InlineData(QuestionType.GdpTotal, "GDP (Total)")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita")]
    public void GetDisplayName_ShouldReturnCorrectName(QuestionType type, string expected)
    {
        type.GetDisplayName().ShouldBe(expected);
    }

    [Theory]
    [InlineData(QuestionType.Population, "Which country has a higher population?")]
    [InlineData(QuestionType.Area, "Which country has a larger area?")]
    public void GetQuestion_ShouldReturnCorrectQuestion(QuestionType type, string expected)
    {
        type.GetQuestion().ShouldBe(expected);
    }

    [Fact]
    public void GetValue_ShouldReturnCorrectPropertyValue()
    {
        var country = new Country
        {
            Name = "Test",
            Code = "TS",
            Continent = "Test",
            Flag = "🏳",
            Population = 1000000,
            Area = 50000,
            Gdp = 100000000000,
            GdpPerCapita = 50000,
            PopulationDensity = 20,
            LiteracyRate = 99.5,
            Hdi = 0.95,
            LifeExpectancy = 80.5
        };

        QuestionType.Population.GetValue(country).ShouldBe(1000000);
        QuestionType.Area.GetValue(country).ShouldBe(50000);
        QuestionType.GdpPerCapita.GetValue(country).ShouldBe(50000);
    }

    [Fact]
    public void FormatValue_ShouldFormatCorrectly()
    {
        QuestionType.Population.FormatValue(1500000000).ShouldBe("1.50B");
        QuestionType.Population.FormatValue(50000000).ShouldBe("50.00M");
        QuestionType.LiteracyRate.FormatValue(99.5).ShouldBe("99.5%");
        QuestionType.LifeExpectancy.FormatValue(80.5).ShouldBe("80.5 years");
    }
}

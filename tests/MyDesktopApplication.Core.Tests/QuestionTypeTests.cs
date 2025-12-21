using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Gdp, "GDP")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita")]
    [InlineData(QuestionType.Hdi, "HDI")]
    public void GetLabel_ReturnsCorrectLabel(QuestionType type, string expected)
    {
        type.GetLabel().ShouldBe(expected);
    }
    
    [Theory]
    [InlineData(QuestionType.Population, "Which country has a larger population?")]
    [InlineData(QuestionType.Area, "Which country is larger by area?")]
    public void GetQuestion_ReturnsCorrectQuestion(QuestionType type, string expected)
    {
        type.GetQuestion().ShouldBe(expected);
    }
    
    [Fact]
    public void GetValue_ReturnsCorrectValue()
    {
        var country = new Country
        {
            Name = "Test",
            Iso2 = "TE",
            Flag = "🏳️",
            Continent = "Test",
            Population = 1000000,
            Area = 500000,
            Gdp = 100000
        };
        
        QuestionType.Population.GetValue(country).ShouldBe(1000000);
        QuestionType.Area.GetValue(country).ShouldBe(500000);
        QuestionType.Gdp.GetValue(country).ShouldBe(100000);
    }
}

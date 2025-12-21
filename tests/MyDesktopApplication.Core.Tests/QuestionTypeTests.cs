using FluentAssertions;
using MyDesktopApplication.Core.Entities;
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
        type.GetLabel().Should().Be(expected);
    }
    
    [Theory]
    [InlineData(QuestionType.Population, "Which country has a larger population?")]
    [InlineData(QuestionType.Area, "Which country is larger by area?")]
    public void GetQuestion_ReturnsCorrectQuestion(QuestionType type, string expected)
    {
        type.GetQuestion().Should().Be(expected);
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
        
        QuestionType.Population.GetValue(country).Should().Be(1000000);
        QuestionType.Area.GetValue(country).Should().Be(500000);
        QuestionType.Gdp.GetValue(country).Should().Be(100000);
    }
    
    [Theory]
    [InlineData(QuestionType.Population, 1234567, "1,234,567")]
    [InlineData(QuestionType.Literacy, 95.5, "95.5%")]
    [InlineData(QuestionType.Hdi, 0.925, "0.925")]
    public void FormatValue_FormatsCorrectly(QuestionType type, double value, string expected)
    {
        type.FormatValue(value).Should().Be(expected);
    }
}

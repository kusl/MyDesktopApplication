using MyDesktopApplication.Core.Entities;
using Shouldly;

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
}

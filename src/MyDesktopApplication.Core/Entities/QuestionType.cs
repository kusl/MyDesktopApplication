namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of quiz questions available
/// </summary>
public enum QuestionType
{
    Population = 0,
    Area = 1,
    GdpTotal = 2,
    GdpPerCapita = 3,
    PopulationDensity = 4,
    LiteracyRate = 5,
    Hdi = 6,
    LifeExpectancy = 7
}

public static class QuestionTypeExtensions
{
    public static string GetDisplayName(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.GdpTotal => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.LiteracyRate => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };

    public static string GetQuestion(this QuestionType type) => type switch
    {
        QuestionType.Population => "Which country has a higher population?",
        QuestionType.Area => "Which country has a larger area?",
        QuestionType.GdpTotal => "Which country has a higher GDP?",
        QuestionType.GdpPerCapita => "Which country has a higher GDP per capita?",
        QuestionType.PopulationDensity => "Which country has higher population density?",
        QuestionType.LiteracyRate => "Which country has a higher literacy rate?",
        QuestionType.Hdi => "Which country has a higher HDI?",
        QuestionType.LifeExpectancy => "Which country has higher life expectancy?",
        _ => "Which country is greater?"
    };
}

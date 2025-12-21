namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of comparison questions available in the quiz.
/// </summary>
public enum QuestionType
{
    Population,
    Area,
    Gdp,
    GdpPerCapita,
    Density,
    Literacy,
    Hdi,
    LifeExpectancy
}

public static class QuestionTypeExtensions
{
    public static string GetLabel(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area",
        QuestionType.Gdp => "GDP",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.Density => "Pop. Density",
        QuestionType.Literacy => "Literacy Rate",
        QuestionType.Hdi => "HDI",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };
    
    public static string GetQuestion(this QuestionType type) => type switch
    {
        QuestionType.Population => "Which country has a larger population?",
        QuestionType.Area => "Which country is larger by area?",
        QuestionType.Gdp => "Which country has a higher GDP?",
        QuestionType.GdpPerCapita => "Which country has higher GDP per capita?",
        QuestionType.Density => "Which country has higher population density?",
        QuestionType.Literacy => "Which country has a higher literacy rate?",
        QuestionType.Hdi => "Which country has a higher Human Development Index?",
        QuestionType.LifeExpectancy => "Which country has higher life expectancy?",
        _ => "Which country has a higher value?"
    };
    
    public static double? GetValue(this QuestionType type, Country country) => type switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.Gdp => country.Gdp,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.Density => country.Density,
        QuestionType.Literacy => country.Literacy,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => null
    };
    
    public static string FormatValue(this QuestionType type, double value) => type switch
    {
        QuestionType.Population => value.ToString("N0"),
        QuestionType.Area => $"{value:N0} km²",
        QuestionType.Gdp => $"${value:N0}M",
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.Density => $"{value:F1}/km²",
        QuestionType.Literacy => $"{value:F1}%",
        QuestionType.Hdi => value.ToString("F3"),
        QuestionType.LifeExpectancy => $"{value:F1} years",
        _ => value.ToString("N0")
    };
}

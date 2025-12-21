using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game.
/// </summary>
public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private Country? _country1;
    private Country? _country2;
    private Country? _correctCountry;
    
    [ObservableProperty]
    private GameState _gameState = new();

    [ObservableProperty]
    private QuestionType _currentQuestionType = QuestionType.Population;

    [ObservableProperty]
    private string _questionText = "";

    [ObservableProperty]
    private string _country1Name = "";

    [ObservableProperty]
    private string _country2Name = "";

    [ObservableProperty]
    private string _country1Flag = "";

    [ObservableProperty]
    private string _country2Flag = "";

    [ObservableProperty]
    private string _feedbackMessage = "";

    [ObservableProperty]
    private string _country1Value = "";

    [ObservableProperty]
    private string _country2Value = "";

    [ObservableProperty]
    private bool _showValues;

    [ObservableProperty]
    private bool _isCorrect;

    [ObservableProperty]
    private string _motivationalMessage = "";

    [ObservableProperty]
    private string _statsText = "";

    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(
        Enum.GetValues<QuestionType>()
    );

    public CountryQuizViewModel()
    {
        GenerateNewQuestion();
        UpdateStats();
    }

    partial void OnCurrentQuestionTypeChanged(QuestionType value)
    {
        GameState.SelectedQuestionType = (int)value;
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void SelectCountry1()
    {
        CheckAnswer(_country1);
    }

    [RelayCommand]
    private void SelectCountry2()
    {
        CheckAnswer(_country2);
    }

    [RelayCommand]
    private void NextQuestion()
    {
        ShowValues = false;
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void ResetGame()
    {
        GameState.Reset();
        ShowValues = false;
        FeedbackMessage = "";
        MotivationalMessage = MotivationalMessages.GetResetMessage();
        UpdateStats();
        GenerateNewQuestion();
    }

    private void GenerateNewQuestion()
    {
        var countries = CountryData.Countries;
        
        // Pick two different random countries
        var index1 = _random.Next(countries.Count);
        var index2 = _random.Next(countries.Count);
        while (index2 == index1)
        {
            index2 = _random.Next(countries.Count);
        }

        _country1 = countries[index1];
        _country2 = countries[index2];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        Country1Flag = _country1.Flag;
        Country2Flag = _country2.Flag;

        // Determine correct answer
        var value1 = CurrentQuestionType.GetValue(_country1);
        var value2 = CurrentQuestionType.GetValue(_country2);
        _correctCountry = value1 > value2 ? _country1 : _country2;

        QuestionText = CurrentQuestionType.GetQuestion();
        
        // Prepare values for reveal
        Country1Value = CurrentQuestionType.FormatValue(value1);
        Country2Value = CurrentQuestionType.FormatValue(value2);
    }

    private void CheckAnswer(Country? selectedCountry)
    {
        if (selectedCountry == null || _correctCountry == null)
            return;

        IsCorrect = selectedCountry == _correctCountry;
        GameState.RecordAnswer(IsCorrect);
        ShowValues = true;

        if (IsCorrect)
        {
            FeedbackMessage = "✓ Correct!";
            MotivationalMessage = MotivationalMessages.GetCorrectMessage(GameState.CurrentStreak);
        }
        else
        {
            FeedbackMessage = $"✗ Wrong! It was {_correctCountry.Name}";
            MotivationalMessage = MotivationalMessages.GetIncorrectMessage();
        }

        UpdateStats();
    }

    private void UpdateStats()
    {
        var accuracy = GameState.TotalQuestions > 0 
            ? (double)GameState.CorrectAnswers / GameState.TotalQuestions * 100 
            : 0;
            
        StatsText = $"Score: {GameState.CurrentScore} | " +
                   $"High: {GameState.HighScore} | " +
                   $"Streak: {GameState.CurrentStreak} (Best: {GameState.BestStreak}) | " +
                   $"Accuracy: {accuracy:F1}%";
    }
}

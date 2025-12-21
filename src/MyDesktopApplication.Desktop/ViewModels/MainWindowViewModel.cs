using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Desktop.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private Country? _country1;
    private Country? _country2;

    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _feedbackMessage = "";
    [ObservableProperty] private bool _showValues;
    [ObservableProperty] private bool _isCorrect;
    [ObservableProperty] private int _score;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _streak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private double _accuracy;
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());

    public MainWindowViewModel() : this(null) { }

    public MainWindowViewModel(IGameStateRepository? gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
        _ = InitializeAsync();
    }

    private async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            var state = await _gameStateRepository.GetOrCreateAsync("default");
            Score = state.CurrentScore;
            HighScore = state.HighScore;
            Streak = state.CurrentStreak;
            BestStreak = state.BestStreak;
            Accuracy = state.Accuracy;
        }
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void GenerateNewQuestion()
    {
        var countries = CountryData.Countries;
        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        _country1 = countries[indices[0]];
        _country2 = countries[indices[1]];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        QuestionText = $"Which country has higher {SelectedQuestionType.GetLabel()}?";
        
        ShowValues = false;
        Country1Value = "";
        Country2Value = "";
        FeedbackMessage = "";
    }

    [RelayCommand]
    private async Task SelectCountry(int countryNumber)
    {
        if (_country1 == null || _country2 == null || ShowValues) return;

        var value1 = SelectedQuestionType.GetValue(_country1);
        var value2 = SelectedQuestionType.GetValue(_country2);

        var correctAnswer = value1 > value2 ? 1 : 2;
        IsCorrect = countryNumber == correctAnswer;

        Country1Value = SelectedQuestionType.FormatValue(value1);
        Country2Value = SelectedQuestionType.FormatValue(value2);
        ShowValues = true;

        if (IsCorrect)
        {
            Score++;
            Streak++;
            if (Streak > BestStreak) BestStreak = Streak;
            if (Score > HighScore) HighScore = Score;
            FeedbackMessage = GetCorrectMessage(Streak, BestStreak);
        }
        else
        {
            Streak = 0;
            FeedbackMessage = GetIncorrectMessage();
        }

        // Update accuracy (simple calculation)
        var totalAnswered = Score + (IsCorrect ? 0 : 1);
        if (totalAnswered > 0)
        {
            Accuracy = (double)Score / totalAnswered * 100;
        }

        // Save state
        if (_gameStateRepository != null)
        {
            var state = await _gameStateRepository.GetOrCreateAsync("default");
            state.RecordAnswer(IsCorrect);
            await _gameStateRepository.SaveAsync(state);
        }
    }

    [RelayCommand]
    private async Task Reset()
    {
        Score = 0;
        Streak = 0;
        Accuracy = 0;
        // Note: HighScore and BestStreak are preserved

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.ResetAsync("default");
        }

        GenerateNewQuestion();
    }

    private string GetCorrectMessage(int streak, int bestStreak)
    {
        if (streak == bestStreak && streak > 1)
            return $"🏆 NEW RECORD! {streak} in a row!";
        if (streak >= 10)
            return $"🔥 UNSTOPPABLE! {streak} streak!";
        if (streak >= 5)
            return $"🔥 On fire! {streak} in a row!";
        if (streak >= 3)
            return $"✨ Nice streak! {streak} in a row!";
        
        var messages = new[] { "Correct! ✓", "Well done! 👍", "Right! 🎯", "Excellent! ⭐" };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        var messages = new[]
        {
            "Not quite, but keep going! 💪",
            "Oops! Try the next one! 🔄",
            "Close! You'll get the next one! 🌟",
            "Learning opportunity! 📚"
        };
        return messages[_random.Next(messages.Length)];
    }
}

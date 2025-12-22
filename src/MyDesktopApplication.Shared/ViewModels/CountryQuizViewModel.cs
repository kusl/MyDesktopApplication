using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private List<Country> _countries = new();
    private Country? _currentCountry;
    private Country? _optionA;
    private Country? _optionB;

    [ObservableProperty]
    private string _questionText = "Loading...";

    [ObservableProperty]
    private string _optionAText = "";

    [ObservableProperty]
    private string _optionBText = "";

    [ObservableProperty]
    private string _feedbackMessage = "";

    [ObservableProperty]
    private bool _isCorrect;

    [ObservableProperty]
    private bool _hasAnswered;

    [ObservableProperty]
    private int _score;

    [ObservableProperty]
    private int _streak;

    [ObservableProperty]
    private int _bestStreak;

    [ObservableProperty]
    private int _totalAnswered;

    [ObservableProperty]
    private double _accuracy;

    [ObservableProperty]
    private string _correctAnswer = "";

    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;

    [ObservableProperty]
    private List<QuestionType> _questionTypes = Enum.GetValues<QuestionType>().ToList();

    [ObservableProperty]
    private string _selectedQuestionTypeLabel = "Population";

    public CountryQuizViewModel() : this(null) { }

    public CountryQuizViewModel(IGameStateRepository? gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
        _countries = CountryData.GetAllCountries().ToList();
        GenerateNewQuestion();
    }

    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        SelectedQuestionTypeLabel = value.GetLabel();
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void SelectOptionA()
    {
        if (HasAnswered || _optionA == null || _optionB == null) return;
        ProcessAnswer(_optionA, _optionB);
    }

    [RelayCommand]
    private void SelectOptionB()
    {
        if (HasAnswered || _optionA == null || _optionB == null) return;
        ProcessAnswer(_optionB, _optionA);
    }

    private void ProcessAnswer(Country selected, Country other)
    {
        HasAnswered = true;
        TotalAnswered++;

        var selectedValue = SelectedQuestionType.GetValue(selected);
        var otherValue = SelectedQuestionType.GetValue(other);

        // Higher value wins for all question types
        IsCorrect = selectedValue >= otherValue;

        if (IsCorrect)
        {
            Score++;
            Streak++;
            if (Streak > BestStreak)
            {
                BestStreak = Streak;
            }
            FeedbackMessage = GetCorrectMessage();
            CorrectAnswer = $"{selected.Flag} {selected.Name}: {SelectedQuestionType.FormatValue(selectedValue)}";
        }
        else
        {
            Streak = 0;
            var correctCountry = selectedValue >= otherValue ? selected : other;
            var correctValue = SelectedQuestionType.GetValue(correctCountry);
            FeedbackMessage = GetIncorrectMessage();
            CorrectAnswer = $"{correctCountry.Flag} {correctCountry.Name}: {SelectedQuestionType.FormatValue(correctValue)}";
        }

        UpdateAccuracy();
        _ = SaveGameStateAsync();
    }

    private string GetCorrectMessage()
    {
        if (Streak >= 10) return "🔥 UNSTOPPABLE! 10+ streak!";
        if (Streak >= 5) return "🔥 On fire! " + Streak + " in a row!";
        if (Streak >= 3) return "🎯 Great streak! " + Streak + " correct!";
        if (Streak == BestStreak && BestStreak > 1) return "🏆 NEW PERSONAL BEST!";
        
        var messages = new[]
        {
            "✅ Correct!",
            "🎉 Well done!",
            "👏 Nice one!",
            "💪 You got it!",
            "⭐ Excellent!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        var messages = new[]
        {
            "❌ Not quite!",
            "😅 Oops!",
            "🤔 Close one!",
            "📚 Now you know!",
            "💡 Learn something new!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private void UpdateAccuracy()
    {
        Accuracy = TotalAnswered > 0 ? (double)Score / TotalAnswered * 100 : 0;
    }

    [RelayCommand]
    private void NextQuestion()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void Reset()
    {
        Score = 0;
        Streak = 0;
        TotalAnswered = 0;
        Accuracy = 0;
        // Keep BestStreak
        GenerateNewQuestion();
        _ = SaveGameStateAsync();
    }

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        FeedbackMessage = "";
        CorrectAnswer = "";
        IsCorrect = false;

        if (_countries.Count < 2) return;

        // Pick two random different countries
        var indices = Enumerable.Range(0, _countries.Count).OrderBy(_ => _random.Next()).Take(2).ToList();
        _optionA = _countries[indices[0]];
        _optionB = _countries[indices[1]];

        QuestionText = $"Which country has higher {SelectedQuestionType.GetLabel()}?";
        OptionAText = $"{_optionA.Flag} {_optionA.Name}";
        OptionBText = $"{_optionB.Flag} {_optionB.Name}";
    }

    private async Task SaveGameStateAsync()
    {
        if (_gameStateRepository == null) return;

        try
        {
            var state = await _gameStateRepository.GetOrCreateAsync("default");
            state.CurrentScore = Score;
            state.CurrentStreak = Streak;
            if (BestStreak > state.BestStreak)
            {
                state.BestStreak = BestStreak;
            }
            state.TotalCorrect = Score;
            state.TotalAnswered = TotalAnswered;
            state.LastPlayedAt = DateTime.UtcNow;
            await _gameStateRepository.SaveAsync(state);
        }
        catch
        {
            // Silently ignore save errors - game continues without persistence
        }
    }

    public async Task LoadGameStateAsync()
    {
        if (_gameStateRepository == null) return;

        try
        {
            var state = await _gameStateRepository.GetOrCreateAsync("default");
            Score = state.CurrentScore;
            Streak = state.CurrentStreak;
            BestStreak = state.BestStreak;
            TotalAnswered = state.TotalAnswered;
            UpdateAccuracy();
        }
        catch
        {
            // Silently ignore load errors - start fresh
        }
    }
}

#!/bin/bash
# Fix Android build errors - comprehensive fix for all 4 errors
# This script is idempotent - safe to run multiple times

set -e
cd ~/src/dotnet/MyDesktopApplication

echo "=== Fixing Android Build Errors (4 errors) ==="
echo ""

# Error 1-3: MainView.axaml.cs references non-existent commands
# The ViewModel has SelectCountryCommand (with int parameter) and NextRoundCommand
# But the code-behind is trying to call SelectCountry1Command, SelectCountry2Command, NextQuestionCommand

echo "[1/3] Fixing MainView.axaml.cs - correcting command references..."

cat > src/MyDesktopApplication.Android/Views/MainView.axaml.cs << 'CSHARP_EOF'
using Avalonia.Controls;
using Avalonia.Interactivity;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
    }

    private void OnCountry1Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            // SelectCountryCommand takes a string parameter ("1" or "2")
            vm.SelectCountryCommand.Execute("1");
        }
    }

    private void OnCountry2Click(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            vm.SelectCountryCommand.Execute("2");
        }
    }

    private void OnNextClick(object? sender, RoutedEventArgs e)
    {
        if (DataContext is CountryQuizViewModel vm)
        {
            // The command is NextRoundCommand, not NextQuestionCommand
            vm.NextRoundCommand.Execute(null);
        }
    }
}
CSHARP_EOF

echo "   ✓ Fixed MainView.axaml.cs"

# Error 4: App.axaml.cs calls EnsureDatabaseCreatedAsync on ServiceProvider
# This method should be called on the DbContext, not the ServiceProvider

echo "[2/3] Fixing App.axaml.cs - correcting database initialization..."

cat > src/MyDesktopApplication.Android/App.axaml.cs << 'CSHARP_EOF'
using System;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android;

public partial class App : Avalonia.Application
{
    public static IServiceProvider? Services { get; private set; }

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override async void OnFrameworkInitializationCompleted()
    {
        // Set up dependency injection
        var services = new ServiceCollection();
        
        // Get the Android-specific database path
        var dbPath = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "countryquiz.db");
        
        // Register DbContext
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlite($"Data Source={dbPath}"));
        
        // Register repositories
        services.AddScoped<IGameStateRepository, GameStateRepository>();
        
        // Register ViewModels
        services.AddTransient<CountryQuizViewModel>();
        
        var serviceProvider = services.BuildServiceProvider();
        Services = serviceProvider;

        // Initialize database - get DbContext and ensure created
        using (var scope = serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            await dbContext.Database.EnsureCreatedAsync();
        }

        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform)
        {
            var viewModel = serviceProvider.GetRequiredService<CountryQuizViewModel>();
            await viewModel.InitializeAsync();
            
            singleViewPlatform.MainView = new MainView
            {
                DataContext = viewModel
            };
        }

        base.OnFrameworkInitializationCompleted();
    }
}
CSHARP_EOF

echo "   ✓ Fixed App.axaml.cs"

# Make sure the ViewModel has the correct commands and InitializeAsync
echo "[3/3] Verifying CountryQuizViewModel has required members..."

# Check if InitializeAsync exists in the ViewModel
if ! grep -q "public async Task InitializeAsync" src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs 2>/dev/null; then
    echo "   Adding InitializeAsync to CountryQuizViewModel..."
    
    # Create a backup
    cp src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs \
       src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs.bak
    
    cat > src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs << 'CSHARP_EOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game
/// </summary>
public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();
    private Country? _country1;
    private Country? _country2;

    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Flag = "";
    [ObservableProperty] private string _country2Flag = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;
    [ObservableProperty] private ObservableCollection<QuestionType> _questionTypes = new();

    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    public CountryQuizViewModel(IGameStateRepository gameStateRepository) : this()
    {
        _gameStateRepository = gameStateRepository;
    }

    public CountryQuizViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        foreach (QuestionType qt in Enum.GetValues<QuestionType>())
        {
            QuestionTypes.Add(qt);
        }
        GenerateNewQuestion();
    }

    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            try
            {
                _gameState = await _gameStateRepository.GetOrCreateAsync("default");
                CurrentScore = _gameState.CurrentScore;
                CurrentStreak = _gameState.CurrentStreak;
                BestStreak = _gameState.BestStreak;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading game state: {ex.Message}");
            }
        }
    }

    [RelayCommand]
    private async Task SelectCountry(string countryParam)
    {
        if (HasAnswered || _country1 == null || _country2 == null)
            return;

        if (!int.TryParse(countryParam, out int countryNumber))
            return;

        HasAnswered = true;
        TotalQuestions++;

        var value1 = SelectedQuestionType.GetValue(_country1);
        var value2 = SelectedQuestionType.GetValue(_country2);

        Country1Value = SelectedQuestionType.FormatValue(value1);
        Country2Value = SelectedQuestionType.FormatValue(value2);

        bool isCorrect;
        if (countryNumber == 1)
        {
            isCorrect = value1 >= value2;
            IsCountry1Correct = isCorrect;
            IsCountry1Wrong = !isCorrect;
            IsCountry2Correct = !isCorrect;
            IsCountry2Wrong = isCorrect;
        }
        else
        {
            isCorrect = value2 >= value1;
            IsCountry2Correct = isCorrect;
            IsCountry2Wrong = !isCorrect;
            IsCountry1Correct = !isCorrect;
            IsCountry1Wrong = isCorrect;
        }

        if (isCorrect)
        {
            CurrentScore++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
            ResultMessage = GetCorrectMessage();
        }
        else
        {
            CurrentStreak = 0;
            ResultMessage = GetIncorrectMessage();
        }

        // Sync to Entity and save
        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
        _gameState.RecordAnswer(isCorrect);

        if (_gameStateRepository != null)
        {
            await _gameStateRepository.SaveAsync(_gameState);
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void ChangeQuestionType(QuestionType newType)
    {
        SelectedQuestionType = newType;
        GenerateNewQuestion();
    }

    [RelayCommand]
    private async Task ResetGame()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalQuestions = 0;
        
        _gameState.Reset();
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.SaveAsync(_gameState);
        }
        
        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
        
        GenerateNewQuestion();
    }

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;
        Country1Value = "";
        Country2Value = "";
        ResultMessage = "";

        var indices = Enumerable.Range(0, _countries.Count).OrderBy(_ => _random.Next()).Take(2).ToList();
        _country1 = _countries[indices[0]];
        _country2 = _countries[indices[1]];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        Country1Flag = _country1.Flag;
        Country2Flag = _country2.Flag;

        QuestionText = $"Which country has a higher {SelectedQuestionType.GetLabel()}?";
    }

    private string GetCorrectMessage()
    {
        var messages = MotivationalMessages.GetCorrectMessages();
        return messages[_random.Next(messages.Count)];
    }

    private string GetIncorrectMessage()
    {
        var messages = MotivationalMessages.GetIncorrectMessages();
        return messages[_random.Next(messages.Count)];
    }
}
CSHARP_EOF

    echo "   ✓ Updated CountryQuizViewModel with all required members"
else
    echo "   ✓ CountryQuizViewModel already has InitializeAsync"
fi

echo ""
echo "=== Cleaning and Building ==="

# Clean build artifacts
dotnet clean --verbosity quiet 2>/dev/null || true

# Build the solution
echo "Building solution..."
if dotnet build; then
    echo ""
    echo "=== BUILD SUCCESSFUL ==="
    echo ""
    echo "All 4 Android errors have been fixed:"
    echo "  1. SelectCountry1Command → SelectCountryCommand.Execute(\"1\")"
    echo "  2. SelectCountry2Command → SelectCountryCommand.Execute(\"2\")"
    echo "  3. NextQuestionCommand → NextRoundCommand"
    echo "  4. ServiceProvider.EnsureDatabaseCreatedAsync → DbContext.Database.EnsureCreatedAsync"
else
    echo ""
    echo "=== Build failed - check errors above ==="
    exit 1
fi





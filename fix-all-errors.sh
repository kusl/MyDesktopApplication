#!/bin/bash
set -e

# =============================================================================
# Comprehensive Fix Script for MyDesktopApplication
# Fixes all 12 build errors identified in output.txt
# =============================================================================

cd ~/src/dotnet/MyDesktopApplication

echo "=========================================="
echo "  MyDesktopApplication - Build Fix Script"
echo "=========================================="

# -----------------------------------------------------------------------------
# Step 0: Kill stuck processes and clean
# -----------------------------------------------------------------------------
echo ""
echo "[Step 0] Cleaning environment..."
pkill -f VBCSCompiler 2>/dev/null || true
pkill -f aapt2 2>/dev/null || true
pkill -f dotnet 2>/dev/null || true
sleep 1

rm -rf bin obj
find . -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "obj" -exec rm -rf {} + 2>/dev/null || true

# -----------------------------------------------------------------------------
# Step 1: Fix GameState.cs - Add CurrentScore and HighScore properties
# The tests and ViewModel expect CurrentScore/HighScore, not Score/BestScore
# -----------------------------------------------------------------------------
echo ""
echo "[Step 1] Fixing GameState.cs..."

cat > src/MyDesktopApplication.Core/Entities/GameState.cs << 'GAMESTATEEOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents the persistent game state for a user
/// </summary>
public class GameState : EntityBase
{
    public string UserId { get; set; } = "default";
    
    // Current session scores
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    
    // Streak tracking
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    
    // Statistics
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    
    // Selected question type
    public int SelectedQuestionType { get; set; }
    
    // Calculated properties
    public double Accuracy => TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered : 0;
    public string AccuracyPercentage => $"{Accuracy:P0}";
    
    /// <summary>
    /// Records an answer and updates all relevant statistics
    /// </summary>
    public void RecordAnswer(bool isCorrect)
    {
        TotalAnswered++;
        
        if (isCorrect)
        {
            CurrentScore++;
            TotalCorrect++;
            CurrentStreak++;
            
            if (CurrentScore > HighScore)
                HighScore = CurrentScore;
            
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
        }
        else
        {
            CurrentStreak = 0;
        }
    }
    
    /// <summary>
    /// Resets the current session (keeps high score and best streak)
    /// </summary>
    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
    }
    
    /// <summary>
    /// Completely resets all statistics
    /// </summary>
    public void ResetAll()
    {
        CurrentScore = 0;
        HighScore = 0;
        CurrentStreak = 0;
        BestStreak = 0;
        TotalCorrect = 0;
        TotalAnswered = 0;
    }
}
GAMESTATEEOF

echo "  ✓ GameState.cs fixed with CurrentScore and HighScore properties"

# -----------------------------------------------------------------------------
# Step 2: Fix TodoRepository.cs - Add GetIncompleteAsync method
# The test expects GetIncompleteAsync but the repository has GetPendingAsync
# -----------------------------------------------------------------------------
echo ""
echo "[Step 2] Fixing TodoRepository.cs..."

cat > src/MyDesktopApplication.Infrastructure/Repositories/TodoRepository.cs << 'TODOREPOEOF'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

/// <summary>
/// TodoItem-specific repository implementation
/// </summary>
public class TodoRepository : Repository<TodoItem>, ITodoRepository
{
    public TodoRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<TodoItem>> GetCompletedAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => t.IsCompleted)
            .OrderByDescending(t => t.UpdatedAt)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<TodoItem>> GetPendingAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => !t.IsCompleted)
            .OrderBy(t => t.DueDate)
            .ThenByDescending(t => t.Priority)
            .ToListAsync(ct);

    /// <summary>
    /// Gets all incomplete (not completed) todo items - alias for GetPendingAsync
    /// </summary>
    public async Task<IReadOnlyList<TodoItem>> GetIncompleteAsync(CancellationToken ct = default)
        => await GetPendingAsync(ct);

    public async Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => !t.IsCompleted && t.DueDate != null && t.DueDate < DateTime.UtcNow)
            .OrderBy(t => t.DueDate)
            .ToListAsync(ct);
}
TODOREPOEOF

echo "  ✓ TodoRepository.cs fixed with GetIncompleteAsync method"

# -----------------------------------------------------------------------------
# Step 3: Fix ITodoRepository.cs - Add GetIncompleteAsync to interface
# -----------------------------------------------------------------------------
echo ""
echo "[Step 3] Fixing ITodoRepository.cs..."

cat > src/MyDesktopApplication.Core/Interfaces/ITodoRepository.cs << 'ITODOREPOEOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// TodoItem-specific repository interface
/// </summary>
public interface ITodoRepository : IRepository<TodoItem>
{
    Task<IReadOnlyList<TodoItem>> GetCompletedAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetPendingAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetIncompleteAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default);
}
ITODOREPOEOF

echo "  ✓ ITodoRepository.cs fixed with GetIncompleteAsync method"

# -----------------------------------------------------------------------------
# Step 4: Fix MainWindowViewModel.cs - Make InitializeAsync public and fix GameState access
# -----------------------------------------------------------------------------
echo ""
echo "[Step 4] Fixing MainWindowViewModel.cs..."

cat > src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs << 'MAINVMEOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Desktop.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();
    
    [ObservableProperty]
    private string _greeting = "Welcome to Country Quiz!";
    
    [ObservableProperty]
    private int _currentScore;
    
    [ObservableProperty]
    private int _highScore;
    
    [ObservableProperty]
    private int _currentStreak;
    
    [ObservableProperty]
    private int _bestStreak;
    
    [ObservableProperty]
    private string _questionText = "Loading...";
    
    [ObservableProperty]
    private string _feedbackMessage = "";
    
    [ObservableProperty]
    private bool _showFeedback;
    
    [ObservableProperty]
    private ObservableCollection<string> _answerOptions = new();
    
    [ObservableProperty]
    private Country? _currentCountryA;
    
    [ObservableProperty]
    private Country? _currentCountryB;
    
    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;
    
    public MainWindowViewModel()
    {
        // Design-time constructor
    }
    
    public MainWindowViewModel(IGameStateRepository gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
    }
    
    /// <summary>
    /// Initializes the ViewModel by loading game state
    /// </summary>
    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            _gameState = await _gameStateRepository.GetOrCreateAsync("default");
            UpdateScoresFromGameState();
        }
        
        GenerateNewQuestion();
    }
    
    private void UpdateScoresFromGameState()
    {
        CurrentScore = _gameState.CurrentScore;
        HighScore = _gameState.HighScore;
        CurrentStreak = _gameState.CurrentStreak;
        BestStreak = _gameState.BestStreak;
    }
    
    private void GenerateNewQuestion()
    {
        var countries = CountryData.GetAllCountries();
        var random = new Random();
        
        // Pick two different random countries
        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => random.Next())
            .Take(2)
            .ToList();
        
        CurrentCountryA = countries[indices[0]];
        CurrentCountryB = countries[indices[1]];
        
        QuestionText = GetQuestionText();
        
        AnswerOptions.Clear();
        AnswerOptions.Add(CurrentCountryA.Name);
        AnswerOptions.Add(CurrentCountryB.Name);
        
        ShowFeedback = false;
    }
    
    private string GetQuestionText()
    {
        return SelectedQuestionType switch
        {
            QuestionType.Population => "Which country has a larger population?",
            QuestionType.Area => "Which country has a larger area?",
            QuestionType.Gdp => "Which country has a higher GDP?",
            QuestionType.GdpPerCapita => "Which country has a higher GDP per capita?",
            QuestionType.Density => "Which country has a higher population density?",
            QuestionType.Literacy => "Which country has a higher literacy rate?",
            QuestionType.Hdi => "Which country has a higher Human Development Index?",
            QuestionType.LifeExpectancy => "Which country has a higher life expectancy?",
            _ => "Which country has a larger population?"
        };
    }
    
    private double GetValue(Country country)
    {
        return SelectedQuestionType switch
        {
            QuestionType.Population => country.Population,
            QuestionType.Area => country.Area,
            QuestionType.Gdp => country.Gdp,
            QuestionType.GdpPerCapita => country.GdpPerCapita,
            QuestionType.Density => country.Density,
            QuestionType.Literacy => country.Literacy,
            QuestionType.Hdi => country.Hdi,
            QuestionType.LifeExpectancy => country.LifeExpectancy,
            _ => country.Population
        };
    }
    
    [RelayCommand]
    private async Task SelectAnswer(string answer)
    {
        if (CurrentCountryA == null || CurrentCountryB == null)
            return;
        
        var valueA = GetValue(CurrentCountryA);
        var valueB = GetValue(CurrentCountryB);
        
        var correctCountry = valueA >= valueB ? CurrentCountryA : CurrentCountryB;
        var isCorrect = answer == correctCountry.Name;
        
        _gameState.RecordAnswer(isCorrect);
        UpdateScoresFromGameState();
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }
        
        FeedbackMessage = isCorrect 
            ? GetCorrectMessage() 
            : GetIncorrectMessage(correctCountry.Name);
        ShowFeedback = true;
        
        // Wait a moment then show next question
        await Task.Delay(1500);
        GenerateNewQuestion();
    }
    
    private string GetCorrectMessage()
    {
        var messages = new[]
        {
            "Correct! 🎉",
            "Well done! 👏",
            "You got it! ✨",
            "Excellent! 🌟",
            "Right on! 💪"
        };
        
        if (CurrentStreak >= 5)
            return $"🔥 {CurrentStreak} in a row! Amazing!";
        
        return messages[new Random().Next(messages.Length)];
    }
    
    private string GetIncorrectMessage(string correctAnswer)
    {
        return $"Not quite. The answer was {correctAnswer}. Keep going! 💪";
    }
    
    [RelayCommand]
    private async Task ResetGame()
    {
        _gameState.Reset();
        UpdateScoresFromGameState();
        
        if (_gameStateRepository != null)
        {
            await _gameStateRepository.UpdateAsync(_gameState);
        }
        
        GenerateNewQuestion();
    }
}
MAINVMEOF

echo "  ✓ MainWindowViewModel.cs fixed with public InitializeAsync"

# -----------------------------------------------------------------------------
# Step 5: Fix GameStateTests.cs - Use correct property names
# -----------------------------------------------------------------------------
echo ""
echo "[Step 5] Fixing GameStateTests.cs..."

cat > tests/MyDesktopApplication.Core.Tests/GameStateTests.cs << 'GAMETESTEOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void NewGameState_HasDefaultValues()
    {
        var state = new GameState();
        
        state.CurrentScore.ShouldBe(0);
        state.HighScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(0);
        state.TotalCorrect.ShouldBe(0);
        state.TotalAnswered.ShouldBe(0);
    }
    
    [Fact]
    public void RecordAnswer_CorrectAnswer_IncrementsScore()
    {
        var state = new GameState();
        
        state.RecordAnswer(true);
        
        state.CurrentScore.ShouldBe(1);
        state.HighScore.ShouldBe(1);
        state.CurrentStreak.ShouldBe(1);
        state.TotalCorrect.ShouldBe(1);
        state.TotalAnswered.ShouldBe(1);
    }
    
    [Fact]
    public void RecordAnswer_WrongAnswer_ResetsStreak()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        
        state.RecordAnswer(false);
        
        state.CurrentScore.ShouldBe(2);
        state.HighScore.ShouldBe(2);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(2);
    }
    
    [Fact]
    public void Reset_KeepsHighScoreAndBestStreak()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        
        state.Reset();
        
        state.CurrentScore.ShouldBe(0);
        state.HighScore.ShouldBe(3);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(3);
    }
    
    [Fact]
    public void Accuracy_CalculatedCorrectly()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(false);
        state.RecordAnswer(true);
        
        state.Accuracy.ShouldBe(0.75, tolerance: 0.01);
        state.AccuracyPercentage.ShouldBe("75%");
    }
}
GAMETESTEOF

echo "  ✓ GameStateTests.cs fixed with correct property names"

# -----------------------------------------------------------------------------
# Step 6: Fix TodoRepositoryTests.cs - Use GetIncompleteAsync
# -----------------------------------------------------------------------------
echo ""
echo "[Step 6] Fixing TodoRepositoryTests.cs..."

cat > tests/MyDesktopApplication.Integration.Tests/TodoRepositoryTests.cs << 'TODOTESTEOF'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Integration.Tests;

public class TodoRepositoryTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly TodoRepository _repository;
    
    public TodoRepositoryTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        
        _context = new AppDbContext(options);
        _repository = new TodoRepository(_context);
    }
    
    public void Dispose()
    {
        _context.Dispose();
    }
    
    [Fact]
    public async Task AddAsync_AddsTodoItem()
    {
        var todo = new TodoItem { Title = "Test Todo" };
        
        var result = await _repository.AddAsync(todo);
        
        result.ShouldNotBeNull();
        result.Id.ShouldNotBe(Guid.Empty);
        result.Title.ShouldBe("Test Todo");
    }
    
    [Fact]
    public async Task GetCompletedAsync_ReturnsOnlyCompletedItems()
    {
        await _repository.AddAsync(new TodoItem { Title = "Todo 1", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2", IsCompleted = false });
        await _repository.AddAsync(new TodoItem { Title = "Todo 3", IsCompleted = true });
        
        var completed = await _repository.GetCompletedAsync();
        
        completed.Count.ShouldBe(2);
        completed.All(t => t.IsCompleted).ShouldBeTrue();
    }
    
    [Fact]
    public async Task GetIncompleteAsync_ReturnsOnlyIncompleteItems()
    {
        await _repository.AddAsync(new TodoItem { Title = "Todo 1", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2", IsCompleted = false });
        await _repository.AddAsync(new TodoItem { Title = "Todo 3", IsCompleted = false });
        
        var incomplete = await _repository.GetIncompleteAsync();
        
        incomplete.Count.ShouldBe(2);
        incomplete.All(t => !t.IsCompleted).ShouldBeTrue();
    }
}
TODOTESTEOF

echo "  ✓ TodoRepositoryTests.cs fixed with GetIncompleteAsync"

# -----------------------------------------------------------------------------
# Step 7: Ensure MainWindow.axaml.cs calls InitializeAsync correctly
# -----------------------------------------------------------------------------
echo ""
echo "[Step 7] Fixing MainWindow.axaml.cs..."

cat > src/MyDesktopApplication.Desktop/Views/MainWindow.axaml.cs << 'MAINWINDOWEOF'
using Avalonia.Controls;

namespace MyDesktopApplication.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        
        // Initialize the ViewModel when the window loads
        Loaded += async (_, _) =>
        {
            if (DataContext is ViewModels.MainWindowViewModel vm)
            {
                await vm.InitializeAsync();
            }
        };
    }
}
MAINWINDOWEOF

echo "  ✓ MainWindow.axaml.cs fixed to call InitializeAsync properly"

# -----------------------------------------------------------------------------
# Step 8: Ensure CountryData exists with required properties
# -----------------------------------------------------------------------------
echo ""
echo "[Step 8] Ensuring CountryData.cs exists..."

mkdir -p src/MyDesktopApplication.Shared/Data

cat > src/MyDesktopApplication.Shared/Data/CountryData.cs << 'COUNTRYDATAEOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Data;

public static class CountryData
{
    private static readonly List<Country> _countries = new()
    {
        new() { Code = "USA", Name = "United States", Iso2 = "US", Continent = "North America", Population = 331900000, Area = 9833517, Gdp = 25462700, GdpPerCapita = 76330, Density = 33.8, Literacy = 99.0, Hdi = 0.921, LifeExpectancy = 76.4 },
        new() { Code = "CHN", Name = "China", Iso2 = "CN", Continent = "Asia", Population = 1412000000, Area = 9596961, Gdp = 17963200, GdpPerCapita = 12720, Density = 147.0, Literacy = 96.8, Hdi = 0.768, LifeExpectancy = 78.2 },
        new() { Code = "IND", Name = "India", Iso2 = "IN", Continent = "Asia", Population = 1408000000, Area = 3287263, Gdp = 3385090, GdpPerCapita = 2410, Density = 428.0, Literacy = 74.4, Hdi = 0.633, LifeExpectancy = 70.8 },
        new() { Code = "BRA", Name = "Brazil", Iso2 = "BR", Continent = "South America", Population = 214300000, Area = 8515767, Gdp = 1920100, GdpPerCapita = 8960, Density = 25.2, Literacy = 93.2, Hdi = 0.754, LifeExpectancy = 76.0 },
        new() { Code = "RUS", Name = "Russia", Iso2 = "RU", Continent = "Europe", Population = 144100000, Area = 17098242, Gdp = 2240400, GdpPerCapita = 15350, Density = 8.4, Literacy = 99.7, Hdi = 0.822, LifeExpectancy = 72.6 },
        new() { Code = "JPN", Name = "Japan", Iso2 = "JP", Continent = "Asia", Population = 125700000, Area = 377975, Gdp = 4231140, GdpPerCapita = 33650, Density = 333.0, Literacy = 99.0, Hdi = 0.925, LifeExpectancy = 84.6 },
        new() { Code = "DEU", Name = "Germany", Iso2 = "DE", Continent = "Europe", Population = 83200000, Area = 357114, Gdp = 4072190, GdpPerCapita = 48940, Density = 233.0, Literacy = 99.0, Hdi = 0.942, LifeExpectancy = 81.3 },
        new() { Code = "GBR", Name = "United Kingdom", Iso2 = "GB", Continent = "Europe", Population = 67330000, Area = 242495, Gdp = 3070670, GdpPerCapita = 45600, Density = 278.0, Literacy = 99.0, Hdi = 0.929, LifeExpectancy = 81.2 },
        new() { Code = "FRA", Name = "France", Iso2 = "FR", Continent = "Europe", Population = 67750000, Area = 643801, Gdp = 2782910, GdpPerCapita = 41090, Density = 105.0, Literacy = 99.0, Hdi = 0.903, LifeExpectancy = 82.7 },
        new() { Code = "ITA", Name = "Italy", Iso2 = "IT", Continent = "Europe", Population = 59110000, Area = 301340, Gdp = 2010430, GdpPerCapita = 34010, Density = 196.0, Literacy = 99.2, Hdi = 0.895, LifeExpectancy = 83.5 },
        new() { Code = "CAN", Name = "Canada", Iso2 = "CA", Continent = "North America", Population = 38250000, Area = 9984670, Gdp = 2139840, GdpPerCapita = 55960, Density = 3.8, Literacy = 99.0, Hdi = 0.936, LifeExpectancy = 82.4 },
        new() { Code = "AUS", Name = "Australia", Iso2 = "AU", Continent = "Oceania", Population = 25690000, Area = 7692024, Gdp = 1675420, GdpPerCapita = 65210, Density = 3.3, Literacy = 99.0, Hdi = 0.951, LifeExpectancy = 83.4 },
        new() { Code = "KOR", Name = "South Korea", Iso2 = "KR", Continent = "Asia", Population = 51740000, Area = 100210, Gdp = 1804680, GdpPerCapita = 34870, Density = 516.0, Literacy = 99.0, Hdi = 0.925, LifeExpectancy = 83.7 },
        new() { Code = "ESP", Name = "Spain", Iso2 = "ES", Continent = "Europe", Population = 47420000, Area = 505990, Gdp = 1397510, GdpPerCapita = 29470, Density = 93.7, Literacy = 98.4, Hdi = 0.905, LifeExpectancy = 83.6 },
        new() { Code = "MEX", Name = "Mexico", Iso2 = "MX", Continent = "North America", Population = 130300000, Area = 1964375, Gdp = 1293040, GdpPerCapita = 9930, Density = 66.3, Literacy = 95.4, Hdi = 0.758, LifeExpectancy = 75.0 },
        new() { Code = "IDN", Name = "Indonesia", Iso2 = "ID", Continent = "Asia", Population = 273800000, Area = 1904569, Gdp = 1319100, GdpPerCapita = 4820, Density = 144.0, Literacy = 96.0, Hdi = 0.705, LifeExpectancy = 71.9 },
        new() { Code = "NLD", Name = "Netherlands", Iso2 = "NL", Continent = "Europe", Population = 17530000, Area = 41543, Gdp = 991110, GdpPerCapita = 56550, Density = 422.0, Literacy = 99.0, Hdi = 0.941, LifeExpectancy = 82.3 },
        new() { Code = "SAU", Name = "Saudi Arabia", Iso2 = "SA", Continent = "Asia", Population = 35340000, Area = 2149690, Gdp = 1108150, GdpPerCapita = 31360, Density = 16.4, Literacy = 97.6, Hdi = 0.875, LifeExpectancy = 76.9 },
        new() { Code = "TUR", Name = "Turkey", Iso2 = "TR", Continent = "Asia", Population = 84780000, Area = 783562, Gdp = 905990, GdpPerCapita = 10680, Density = 108.0, Literacy = 96.7, Hdi = 0.838, LifeExpectancy = 78.0 },
        new() { Code = "CHE", Name = "Switzerland", Iso2 = "CH", Continent = "Europe", Population = 8700000, Area = 41285, Gdp = 807710, GdpPerCapita = 92840, Density = 211.0, Literacy = 99.0, Hdi = 0.962, LifeExpectancy = 84.0 },
        new() { Code = "POL", Name = "Poland", Iso2 = "PL", Continent = "Europe", Population = 38180000, Area = 312679, Gdp = 688180, GdpPerCapita = 18030, Density = 122.0, Literacy = 99.8, Hdi = 0.876, LifeExpectancy = 78.7 },
        new() { Code = "SWE", Name = "Sweden", Iso2 = "SE", Continent = "Europe", Population = 10420000, Area = 450295, Gdp = 585940, GdpPerCapita = 56230, Density = 23.1, Literacy = 99.0, Hdi = 0.947, LifeExpectancy = 83.0 },
        new() { Code = "BEL", Name = "Belgium", Iso2 = "BE", Continent = "Europe", Population = 11590000, Area = 30528, Gdp = 578600, GdpPerCapita = 49930, Density = 380.0, Literacy = 99.0, Hdi = 0.937, LifeExpectancy = 82.0 },
        new() { Code = "NOR", Name = "Norway", Iso2 = "NO", Continent = "Europe", Population = 5470000, Area = 385207, Gdp = 579270, GdpPerCapita = 105890, Density = 14.2, Literacy = 99.0, Hdi = 0.961, LifeExpectancy = 83.2 },
        new() { Code = "ARG", Name = "Argentina", Iso2 = "AR", Continent = "South America", Population = 45810000, Area = 2780400, Gdp = 632770, GdpPerCapita = 13810, Density = 16.5, Literacy = 99.0, Hdi = 0.842, LifeExpectancy = 77.3 },
        new() { Code = "AUT", Name = "Austria", Iso2 = "AT", Continent = "Europe", Population = 9000000, Area = 83879, Gdp = 471400, GdpPerCapita = 52380, Density = 107.0, Literacy = 99.0, Hdi = 0.916, LifeExpectancy = 82.0 },
        new() { Code = "IRN", Name = "Iran", Iso2 = "IR", Continent = "Asia", Population = 87590000, Area = 1648195, Gdp = 366440, GdpPerCapita = 4180, Density = 53.1, Literacy = 85.5, Hdi = 0.774, LifeExpectancy = 76.7 },
        new() { Code = "THA", Name = "Thailand", Iso2 = "TH", Continent = "Asia", Population = 69950000, Area = 513120, Gdp = 505950, GdpPerCapita = 7230, Density = 136.0, Literacy = 93.8, Hdi = 0.800, LifeExpectancy = 78.7 },
        new() { Code = "ARE", Name = "United Arab Emirates", Iso2 = "AE", Continent = "Asia", Population = 9890000, Area = 83600, Gdp = 421140, GdpPerCapita = 42600, Density = 118.0, Literacy = 93.8, Hdi = 0.911, LifeExpectancy = 78.0 },
        new() { Code = "NGA", Name = "Nigeria", Iso2 = "NG", Continent = "Africa", Population = 218500000, Area = 923768, Gdp = 440830, GdpPerCapita = 2020, Density = 236.0, Literacy = 62.0, Hdi = 0.535, LifeExpectancy = 55.4 },
        new() { Code = "ISR", Name = "Israel", Iso2 = "IL", Continent = "Asia", Population = 9450000, Area = 22072, Gdp = 520700, GdpPerCapita = 55110, Density = 428.0, Literacy = 97.8, Hdi = 0.919, LifeExpectancy = 83.0 },
        new() { Code = "EGY", Name = "Egypt", Iso2 = "EG", Continent = "Africa", Population = 104300000, Area = 1002450, Gdp = 476750, GdpPerCapita = 4570, Density = 104.0, Literacy = 71.2, Hdi = 0.731, LifeExpectancy = 72.0 },
        new() { Code = "SGP", Name = "Singapore", Iso2 = "SG", Continent = "Asia", Population = 5450000, Area = 733, Gdp = 396990, GdpPerCapita = 72790, Density = 7440.0, Literacy = 97.5, Hdi = 0.939, LifeExpectancy = 84.1 },
        new() { Code = "VNM", Name = "Vietnam", Iso2 = "VN", Continent = "Asia", Population = 98170000, Area = 331212, Gdp = 408800, GdpPerCapita = 4160, Density = 296.0, Literacy = 95.8, Hdi = 0.703, LifeExpectancy = 75.8 },
        new() { Code = "PHL", Name = "Philippines", Iso2 = "PH", Continent = "Asia", Population = 113900000, Area = 300000, Gdp = 404260, GdpPerCapita = 3550, Density = 380.0, Literacy = 96.3, Hdi = 0.699, LifeExpectancy = 72.1 },
        new() { Code = "ZAF", Name = "South Africa", Iso2 = "ZA", Continent = "Africa", Population = 60040000, Area = 1221037, Gdp = 405270, GdpPerCapita = 6750, Density = 49.2, Literacy = 95.0, Hdi = 0.713, LifeExpectancy = 65.3 },
        new() { Code = "PAK", Name = "Pakistan", Iso2 = "PK", Continent = "Asia", Population = 231400000, Area = 881913, Gdp = 376530, GdpPerCapita = 1630, Density = 262.0, Literacy = 59.1, Hdi = 0.544, LifeExpectancy = 67.3 },
        new() { Code = "BGD", Name = "Bangladesh", Iso2 = "BD", Continent = "Asia", Population = 169400000, Area = 148460, Gdp = 460200, GdpPerCapita = 2720, Density = 1140.0, Literacy = 74.7, Hdi = 0.661, LifeExpectancy = 73.4 },
        new() { Code = "DNK", Name = "Denmark", Iso2 = "DK", Continent = "Europe", Population = 5860000, Area = 43094, Gdp = 395400, GdpPerCapita = 67500, Density = 136.0, Literacy = 99.0, Hdi = 0.948, LifeExpectancy = 81.4 },
        new() { Code = "FIN", Name = "Finland", Iso2 = "FI", Continent = "Europe", Population = 5540000, Area = 338424, Gdp = 299150, GdpPerCapita = 54010, Density = 16.4, Literacy = 99.0, Hdi = 0.940, LifeExpectancy = 82.1 },
        new() { Code = "NZL", Name = "New Zealand", Iso2 = "NZ", Continent = "Oceania", Population = 5124000, Area = 268021, Gdp = 249890, GdpPerCapita = 48780, Density = 19.1, Literacy = 99.0, Hdi = 0.937, LifeExpectancy = 82.5 },
        new() { Code = "CHL", Name = "Chile", Iso2 = "CL", Continent = "South America", Population = 19490000, Area = 756102, Gdp = 317060, GdpPerCapita = 16270, Density = 25.8, Literacy = 96.9, Hdi = 0.855, LifeExpectancy = 80.7 },
        new() { Code = "COL", Name = "Colombia", Iso2 = "CO", Continent = "South America", Population = 51870000, Area = 1141748, Gdp = 343940, GdpPerCapita = 6630, Density = 45.4, Literacy = 95.6, Hdi = 0.752, LifeExpectancy = 77.3 },
        new() { Code = "PER", Name = "Peru", Iso2 = "PE", Continent = "South America", Population = 33360000, Area = 1285216, Gdp = 242630, GdpPerCapita = 7270, Density = 26.0, Literacy = 94.5, Hdi = 0.762, LifeExpectancy = 77.0 },
        new() { Code = "KEN", Name = "Kenya", Iso2 = "KE", Continent = "Africa", Population = 54030000, Area = 580367, Gdp = 113420, GdpPerCapita = 2100, Density = 93.1, Literacy = 81.5, Hdi = 0.575, LifeExpectancy = 67.0 },
        new() { Code = "ETH", Name = "Ethiopia", Iso2 = "ET", Continent = "Africa", Population = 120300000, Area = 1104300, Gdp = 126780, GdpPerCapita = 1050, Density = 109.0, Literacy = 51.8, Hdi = 0.498, LifeExpectancy = 67.8 },
        new() { Code = "GHA", Name = "Ghana", Iso2 = "GH", Continent = "Africa", Population = 32830000, Area = 238533, Gdp = 77590, GdpPerCapita = 2360, Density = 138.0, Literacy = 79.0, Hdi = 0.632, LifeExpectancy = 64.9 },
        new() { Code = "TZA", Name = "Tanzania", Iso2 = "TZ", Continent = "Africa", Population = 63590000, Area = 947303, Gdp = 75710, GdpPerCapita = 1190, Density = 67.1, Literacy = 77.9, Hdi = 0.549, LifeExpectancy = 66.2 },
        new() { Code = "UGA", Name = "Uganda", Iso2 = "UG", Continent = "Africa", Population = 47250000, Area = 241550, Gdp = 45570, GdpPerCapita = 960, Density = 196.0, Literacy = 76.5, Hdi = 0.525, LifeExpectancy = 63.7 },
        new() { Code = "ISL", Name = "Iceland", Iso2 = "IS", Continent = "Europe", Population = 372000, Area = 103000, Gdp = 27840, GdpPerCapita = 74840, Density = 3.6, Literacy = 99.0, Hdi = 0.959, LifeExpectancy = 83.1 }
    };

    public static IReadOnlyList<Country> GetAllCountries() => _countries.AsReadOnly();
    
    public static Country? GetByCode(string code) => _countries.FirstOrDefault(c => c.Code == code);
    
    public static IReadOnlyList<Country> GetByContinent(string continent) => 
        _countries.Where(c => c.Continent == continent).ToList().AsReadOnly();
}
COUNTRYDATAEOF

echo "  ✓ CountryData.cs created with 50 countries"

# -----------------------------------------------------------------------------
# Step 9: Ensure Country.cs has all required properties
# -----------------------------------------------------------------------------
echo ""
echo "[Step 9] Ensuring Country.cs has all properties..."

cat > src/MyDesktopApplication.Core/Entities/Country.cs << 'COUNTRYEOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with various statistics for the quiz game
/// </summary>
public class Country
{
    public required string Code { get; set; }
    public required string Name { get; set; }
    public string Iso2 { get; set; } = "";
    public string Continent { get; set; } = "";
    
    // Statistics
    public double Population { get; set; }
    public double Area { get; set; }
    public double Gdp { get; set; }
    public double GdpPerCapita { get; set; }
    public double Density { get; set; }
    public double Literacy { get; set; }
    public double Hdi { get; set; }
    public double LifeExpectancy { get; set; }
    
    // Optional display properties
    public string? Flag { get; set; }
}
COUNTRYEOF

echo "  ✓ Country.cs ensured with all properties"

# -----------------------------------------------------------------------------
# Step 10: Ensure QuestionType.cs exists
# -----------------------------------------------------------------------------
echo ""
echo "[Step 10] Ensuring QuestionType.cs exists..."

cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'QUESTIONTYPEEOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of questions available in the country quiz
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
QUESTIONTYPEEOF

echo "  ✓ QuestionType.cs ensured"

# -----------------------------------------------------------------------------
# Step 11: Build and verify
# -----------------------------------------------------------------------------
echo ""
echo "[Step 11] Building solution..."
echo ""

dotnet restore MyDesktopApplication.slnx --verbosity quiet

if dotnet build MyDesktopApplication.slnx --no-restore; then
    echo ""
    echo "=========================================="
    echo "  ✓ BUILD SUCCEEDED"
    echo "=========================================="
    
    echo ""
    echo "[Step 12] Running tests..."
    if dotnet test MyDesktopApplication.slnx --no-build --verbosity normal; then
        echo ""
        echo "=========================================="
        echo "  ✓ ALL TESTS PASSED"
        echo "=========================================="
    else
        echo ""
        echo "=========================================="
        echo "  ⚠ Some tests failed (build succeeded)"
        echo "=========================================="
    fi
else
    echo ""
    echo "=========================================="
    echo "  ✗ BUILD FAILED"
    echo "=========================================="
    exit 1
fi

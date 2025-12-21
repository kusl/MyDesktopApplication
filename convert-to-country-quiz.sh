#!/bin/bash
# =============================================================================
# Country Quiz Conversion Script
# Converts MyDesktopApplication from a counter demo to a full Country Quiz game
# with persistent SQLite storage and responsive UI
# =============================================================================

set -e

PROJECT_ROOT="$(pwd)"
SHARED_DIR="$PROJECT_ROOT/src/MyDesktopApplication.Shared"
CORE_DIR="$PROJECT_ROOT/src/MyDesktopApplication.Core"
INFRA_DIR="$PROJECT_ROOT/src/MyDesktopApplication.Infrastructure"
DESKTOP_DIR="$PROJECT_ROOT/src/MyDesktopApplication.Desktop"
ANDROID_DIR="$PROJECT_ROOT/src/MyDesktopApplication.Android"
TESTS_DIR="$PROJECT_ROOT/tests"

echo "=============================================="
echo "  Country Quiz Conversion Script"
echo "=============================================="
echo ""
echo "This script will:"
echo "  1. Create Country data models and quiz logic"
echo "  2. Add persistent SQLite storage for game state"
echo "  3. Create responsive UI for phones to tablets"
echo "  4. Add motivational messages"
echo "  5. Update tests"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Create Core Domain Models
# -----------------------------------------------------------------------------
echo "[1/8] Creating Core domain models..."

mkdir -p "$CORE_DIR/Entities"
mkdir -p "$CORE_DIR/Interfaces"

# Country Entity
cat > "$CORE_DIR/Entities/Country.cs" << 'EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a country with various statistical metrics.
/// Data sourced from World Bank, UN, IMF, and UNDP (2023/2024 estimates).
/// </summary>
public sealed class Country
{
    public required string Name { get; init; }
    public required string Iso2 { get; init; }
    public required string Flag { get; init; }
    public required string Continent { get; init; }
    public long? Area { get; init; }
    public long? Population { get; init; }
    public long? Gdp { get; init; }
    public int? GdpPerCapita { get; init; }
    public double? Density { get; init; }
    public double? Literacy { get; init; }
    public double? Hdi { get; init; }
    public double? LifeExpectancy { get; init; }
}
EOF

# GameState Entity for persistence
cat > "$CORE_DIR/Entities/GameState.cs" << 'EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Persisted game state for the Country Quiz.
/// </summary>
public class GameState : EntityBase
{
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public string SelectedQuestionType { get; set; } = "Population";
    
    public double Accuracy => TotalQuestions > 0 
        ? Math.Round((double)CorrectAnswers / TotalQuestions * 100, 1) 
        : 0;
    
    public void Reset()
    {
        CorrectAnswers = 0;
        TotalQuestions = 0;
        CurrentStreak = 0;
        // Note: BestStreak is preserved across resets
    }
    
    public void RecordAnswer(bool isCorrect)
    {
        TotalQuestions++;
        if (isCorrect)
        {
            CorrectAnswers++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
            {
                BestStreak = CurrentStreak;
            }
        }
        else
        {
            CurrentStreak = 0;
        }
    }
}
EOF

# QuestionType enum
cat > "$CORE_DIR/Entities/QuestionType.cs" << 'EOF'
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
EOF

# IGameStateRepository interface
cat > "$CORE_DIR/Interfaces/IGameStateRepository.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

public interface IGameStateRepository
{
    Task<GameState> GetOrCreateAsync(CancellationToken ct = default);
    Task SaveAsync(GameState state, CancellationToken ct = default);
}
EOF

echo "  ✓ Core domain models created"

# -----------------------------------------------------------------------------
# Step 2: Create Country Data
# -----------------------------------------------------------------------------
echo "[2/8] Creating country data..."

mkdir -p "$SHARED_DIR/Data"

cat > "$SHARED_DIR/Data/CountryData.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Data;

/// <summary>
/// Static country data from World Bank, UN, IMF, and UNDP (2023/2024 estimates).
/// </summary>
public static class CountryData
{
    private static Country C(string name, string iso2, string flag, string cont,
        long? area, long? pop, long? gdp, int? gdpPc, double? density,
        double? literacy, double? hdi, double? lifeExp) => new()
    {
        Name = name, Iso2 = iso2, Flag = flag, Continent = cont,
        Area = area, Population = pop, Gdp = gdp, GdpPerCapita = gdpPc,
        Density = density, Literacy = literacy, Hdi = hdi, LifeExpectancy = lifeExp
    };

    public static IReadOnlyList<Country> Countries { get; } = new[]
    {
        // AFRICA
        C("Algeria","DZ","🇩🇿","Africa",2381741,45400000,239900,5284,19.1,81.4,0.745,76.4),
        C("Angola","AO","🇦🇴","Africa",1246700,36000000,92124,2560,28.9,72.0,0.595,62.0),
        C("Botswana","BW","🇧🇼","Africa",581730,2600000,19396,7460,4.5,88.9,0.708,61.1),
        C("Cameroon","CM","🇨🇲","Africa",475442,28600000,48455,1694,60.2,77.1,0.587,61.0),
        C("DR Congo","CD","🇨🇩","Africa",2344858,102300000,66380,649,43.6,80.0,0.479,60.7),
        C("Egypt","EG","🇪🇬","Africa",1001450,105000000,387086,3686,104.9,73.1,0.728,70.2),
        C("Ethiopia","ET","🇪🇹","Africa",1104300,126500000,163698,1294,114.6,51.8,0.492,65.0),
        C("Ghana","GH","🇬🇭","Africa",238533,34100000,76370,2240,143.0,79.0,0.602,63.8),
        C("Kenya","KE","🇰🇪","Africa",580367,55100000,113420,2058,95.0,82.6,0.575,61.4),
        C("Morocco","MA","🇲🇦","Africa",446550,37500000,141109,3764,84.0,75.9,0.698,74.0),
        C("Nigeria","NG","🇳🇬","Africa",923768,223800000,472620,2112,242.3,62.0,0.548,52.7),
        C("South Africa","ZA","🇿🇦","Africa",1221037,60400000,399015,6607,49.5,95.0,0.713,62.3),
        C("Tanzania","TZ","🇹🇿","Africa",947300,65500000,79162,1209,69.2,78.1,0.532,66.2),
        C("Tunisia","TN","🇹🇳","Africa",163610,12400000,46840,3778,75.8,79.7,0.732,73.8),
        C("Uganda","UG","🇺🇬","Africa",241038,48600000,45561,937,201.6,79.0,0.525,62.7),
        
        // ASIA
        C("Bangladesh","BD","🇧🇩","Asia",147570,172000000,460201,2676,1166.0,74.9,0.670,72.4),
        C("China","CN","🇨🇳","Asia",9596960,1412000000,17963171,12720,147.0,97.5,0.788,78.2),
        C("India","IN","🇮🇳","Asia",3287263,1428000000,3737000,2617,434.0,74.4,0.644,67.2),
        C("Indonesia","ID","🇮🇩","Asia",1904569,277500000,1417387,5108,145.7,96.0,0.713,67.6),
        C("Iran","IR","🇮🇷","Asia",1648195,89200000,388000,4351,54.1,88.7,0.774,73.9),
        C("Iraq","IQ","🇮🇶","Asia",438317,44500000,267900,6021,101.5,85.6,0.686,70.4),
        C("Israel","IL","🇮🇱","Asia",20770,9750000,525000,53853,470.0,97.8,0.915,82.6),
        C("Japan","JP","🇯🇵","Asia",377975,124500000,4230862,33960,329.6,99.0,0.920,84.8),
        C("Malaysia","MY","🇲🇾","Asia",330803,34300000,430895,12563,103.7,95.9,0.807,74.9),
        C("Pakistan","PK","🇵🇰","Asia",881912,240500000,376493,1565,272.8,58.0,0.544,66.1),
        C("Philippines","PH","🇵🇭","Asia",300000,117300000,435667,3715,391.0,96.3,0.710,69.3),
        C("Saudi Arabia","SA","🇸🇦","Asia",2149690,36400000,1069437,29386,16.9,97.6,0.875,76.9),
        C("Singapore","SG","🇸🇬","Asia",733,5920000,515548,87088,8075.0,97.5,0.949,84.1),
        C("South Korea","KR","🇰🇷","Asia",100210,51780000,1721909,33268,517.0,99.0,0.929,83.7),
        C("Thailand","TH","🇹🇭","Asia",513120,71800000,514945,7172,140.0,94.1,0.803,79.3),
        C("Turkey","TR","🇹🇷","Asia",783562,85800000,1029303,12001,109.4,96.7,0.838,76.0),
        C("UAE","AE","🇦🇪","Asia",83600,9440000,507532,53757,112.9,98.0,0.937,78.7),
        C("Vietnam","VN","🇻🇳","Asia",331212,99500000,449900,4522,300.5,95.8,0.726,73.6),
        
        // EUROPE
        C("Austria","AT","🇦🇹","Europe",83879,9100000,515795,56681,108.5,99.0,0.926,81.6),
        C("Belgium","BE","🇧🇪","Europe",30528,11700000,624248,53378,383.4,99.0,0.942,81.9),
        C("Czech Republic","CZ","🇨🇿","Europe",78867,10500000,330483,31474,133.1,99.0,0.895,79.4),
        C("Denmark","DK","🇩🇰","Europe",43094,5900000,404198,68508,137.0,99.0,0.952,81.4),
        C("Finland","FI","🇫🇮","Europe",338424,5500000,305689,55580,16.3,99.0,0.942,82.0),
        C("France","FR","🇫🇷","Europe",643801,68000000,2923489,43000,105.7,99.0,0.910,82.5),
        C("Germany","DE","🇩🇪","Europe",357022,84400000,4456081,52824,236.4,99.0,0.950,81.7),
        C("Greece","GR","🇬🇷","Europe",131957,10400000,218015,20963,78.8,97.9,0.893,80.1),
        C("Hungary","HU","🇭🇺","Europe",93028,9600000,188505,19636,103.2,99.4,0.851,74.5),
        C("Ireland","IE","🇮🇪","Europe",70273,5200000,533680,102618,74.0,99.0,0.950,82.0),
        C("Italy","IT","🇮🇹","Europe",301340,59000000,2186082,37046,195.8,99.2,0.906,83.5),
        C("Netherlands","NL","🇳🇱","Europe",41543,17700000,1092748,61725,426.1,99.0,0.946,82.0),
        C("Norway","NO","🇳🇴","Europe",323802,5500000,579267,105321,17.0,99.0,0.966,83.2),
        C("Poland","PL","🇵🇱","Europe",312685,37600000,811229,21578,120.3,99.8,0.881,76.5),
        C("Portugal","PT","🇵🇹","Europe",92212,10400000,287080,27608,112.8,96.1,0.874,81.1),
        C("Romania","RO","🇷🇴","Europe",238391,19000000,348902,18370,79.7,99.1,0.827,74.2),
        C("Russia","RU","🇷🇺","Europe",17098242,144000000,2062649,14323,8.4,99.7,0.821,69.4),
        C("Spain","ES","🇪🇸","Europe",505990,47800000,1580690,33072,94.5,98.6,0.911,83.3),
        C("Sweden","SE","🇸🇪","Europe",450295,10500000,593267,56497,23.3,99.0,0.952,83.0),
        C("Switzerland","CH","🇨🇭","Europe",41284,8800000,884940,100578,213.1,99.0,0.967,84.0),
        C("Ukraine","UA","🇺🇦","Europe",603550,37000000,160500,4339,61.3,99.8,0.773,69.0),
        C("United Kingdom","GB","🇬🇧","Europe",242495,67500000,3332059,49384,278.4,99.0,0.940,80.7),
        
        // NORTH AMERICA
        C("Canada","CA","🇨🇦","N. America",9984670,40100000,2139840,53385,4.0,99.0,0.935,82.7),
        C("Costa Rica","CR","🇨🇷","N. America",51100,5200000,68379,13150,101.8,97.9,0.806,77.0),
        C("Cuba","CU","🇨🇺","N. America",109884,11100000,107352,9671,101.0,99.8,0.783,73.7),
        C("Dominican Rep.","DO","🇩🇴","N. America",48671,11300000,113642,10057,232.2,95.0,0.768,72.6),
        C("Guatemala","GT","🇬🇹","N. America",108889,17600000,95003,5398,161.7,83.3,0.627,69.2),
        C("Haiti","HT","🇭🇹","N. America",27750,11700000,21178,1810,421.6,61.7,0.552,64.0),
        C("Honduras","HN","🇭🇳","N. America",112492,10400000,31717,3050,92.5,87.2,0.624,70.1),
        C("Jamaica","JM","🇯🇲","N. America",10991,2800000,17099,6107,254.8,88.7,0.709,70.5),
        C("Mexico","MX","🇲🇽","N. America",1964375,128900000,1811468,14056,65.6,95.4,0.781,75.0),
        C("Panama","PA","🇵🇦","N. America",75420,4400000,76523,17391,58.3,95.7,0.820,76.2),
        C("USA","US","🇺🇸","N. America",9833517,335000000,27360935,81695,34.1,99.0,0.927,77.5),
        
        // SOUTH AMERICA
        C("Argentina","AR","🇦🇷","S. America",2780400,46300000,641131,13846,16.7,99.0,0.849,76.6),
        C("Bolivia","BO","🇧🇴","S. America",1098581,12400000,44315,3574,11.3,94.5,0.692,63.6),
        C("Brazil","BR","🇧🇷","S. America",8515767,216400000,2173668,10047,25.4,93.5,0.760,72.8),
        C("Chile","CL","🇨🇱","S. America",756102,19500000,335533,17206,25.8,97.0,0.860,78.9),
        C("Colombia","CO","🇨🇴","S. America",1138910,52000000,363835,6997,45.7,95.6,0.758,72.8),
        C("Ecuador","EC","🇪🇨","S. America",283561,18000000,118845,6603,63.5,94.5,0.765,74.3),
        C("Paraguay","PY","🇵🇾","S. America",406752,6800000,42956,6317,16.7,94.7,0.717,70.3),
        C("Peru","PE","🇵🇪","S. America",1285216,34000000,267603,7869,26.4,94.5,0.762,73.7),
        C("Uruguay","UY","🇺🇾","S. America",176215,3400000,77241,22718,19.3,98.8,0.830,77.7),
        C("Venezuela","VE","🇻🇪","S. America",916445,28400000,92200,3246,31.0,97.1,0.691,72.1),
        
        // OCEANIA
        C("Australia","AU","🇦🇺","Oceania",7692024,26500000,1687713,63688,3.4,99.0,0.946,84.5),
        C("Fiji","FJ","🇫🇯","Oceania",18274,930000,5314,5714,50.9,99.1,0.729,67.4),
        C("New Zealand","NZ","🇳🇿","Oceania",270467,5200000,251969,48455,19.2,99.0,0.939,82.5),
        C("Papua New Guinea","PG","🇵🇬","Oceania",462840,10300000,30624,2973,22.3,64.2,0.558,64.5),
    };
}
EOF

echo "  ✓ Country data created (80+ countries)"

# -----------------------------------------------------------------------------
# Step 3: Create Motivational Messages
# -----------------------------------------------------------------------------
echo "[3/8] Creating motivational messages..."

cat > "$SHARED_DIR/Data/MotivationalMessages.cs" << 'EOF'
namespace MyDesktopApplication.Shared.Data;

/// <summary>
/// Provides encouraging messages based on player performance.
/// </summary>
public static class MotivationalMessages
{
    private static readonly Random _random = new();
    
    private static readonly string[] CorrectMessages =
    [
        "🎉 Correct! You're on fire!",
        "✨ Brilliant! Keep it up!",
        "🌟 Amazing knowledge!",
        "💪 You really know your geography!",
        "🎯 Spot on! Nice work!",
        "🏆 Champion answer!",
        "📚 Well studied!",
        "🌍 World expert in the making!"
    ];
    
    private static readonly string[] IncorrectMessages =
    [
        "Not quite, but you're learning!",
        "Good try! Now you know!",
        "Interesting fact to remember!",
        "Keep going, you've got this!",
        "Every answer is a learning opportunity!",
        "Don't give up, you're improving!",
        "That's a tricky one!",
        "You'll get the next one!"
    ];
    
    private static readonly string[] StreakMessages =
    [
        "🔥 {0} in a row!",
        "🔥 {0} streak! Incredible!",
        "🔥 {0} consecutive! You're unstoppable!",
        "🔥 {0} correct answers! Amazing run!"
    ];
    
    private static readonly string[] NewBestMessages =
    [
        "🏆 NEW PERSONAL BEST! {0} streak!",
        "⭐ NEW RECORD! {0} in a row!",
        "🎊 PERSONAL BEST! {0} streak!"
    ];
    
    private static readonly string[] ResetMessages =
    [
        "Fresh start! Good luck! 🍀",
        "Ready for a new challenge! 💪",
        "Let's see what you've got! 🌟",
        "New game, new opportunities! 🎯"
    ];
    
    public static string GetCorrectMessage() => 
        CorrectMessages[_random.Next(CorrectMessages.Length)];
    
    public static string GetIncorrectMessage() => 
        IncorrectMessages[_random.Next(IncorrectMessages.Length)];
    
    public static string GetStreakMessage(int streak)
    {
        if (streak < 3) return string.Empty;
        var template = StreakMessages[_random.Next(StreakMessages.Length)];
        return string.Format(template, streak);
    }
    
    public static string GetNewBestMessage(int streak)
    {
        var template = NewBestMessages[_random.Next(NewBestMessages.Length)];
        return string.Format(template, streak);
    }
    
    public static string GetResetMessage() => 
        ResetMessages[_random.Next(ResetMessages.Length)];
    
    public static string GetAccuracyComment(double accuracy) => accuracy switch
    {
        >= 90 => "🏅 Geography genius!",
        >= 75 => "📊 Great accuracy!",
        >= 60 => "👍 Solid knowledge!",
        >= 40 => "📈 Room to grow!",
        _ => "🌱 Keep learning!"
    };
}
EOF

echo "  ✓ Motivational messages created"

# -----------------------------------------------------------------------------
# Step 4: Update Infrastructure for Persistence
# -----------------------------------------------------------------------------
echo "[4/8] Updating infrastructure for SQLite persistence..."

mkdir -p "$INFRA_DIR/Repositories"

# Update AppDbContext
cat > "$INFRA_DIR/Data/AppDbContext.cs" << 'EOF'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    
    public DbSet<GameState> GameStates => Set<GameState>();
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        modelBuilder.Entity<GameState>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SelectedQuestionType)
                  .HasMaxLength(50)
                  .HasDefaultValue("Population");
        });
    }
}
EOF

# GameStateRepository
cat > "$INFRA_DIR/Repositories/GameStateRepository.cs" << 'EOF'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

public class GameStateRepository : IGameStateRepository
{
    private readonly AppDbContext _context;
    
    public GameStateRepository(AppDbContext context)
    {
        _context = context;
    }
    
    public async Task<GameState> GetOrCreateAsync(CancellationToken ct = default)
    {
        var state = await _context.GameStates.FirstOrDefaultAsync(ct);
        if (state == null)
        {
            state = new GameState();
            _context.GameStates.Add(state);
            await _context.SaveChangesAsync(ct);
        }
        return state;
    }
    
    public async Task SaveAsync(GameState state, CancellationToken ct = default)
    {
        state.UpdatedAt = DateTime.UtcNow;
        _context.GameStates.Update(state);
        await _context.SaveChangesAsync(ct);
    }
}
EOF

# Update DependencyInjection
cat > "$INFRA_DIR/DependencyInjection.cs" << 'EOF'
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

namespace MyDesktopApplication.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, string? dbPath = null)
    {
        var path = dbPath ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "CountryQuiz",
            "countryquiz.db");
        
        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
        {
            Directory.CreateDirectory(directory);
        }
        
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlite($"Data Source={path}"));
        
        services.AddScoped<IGameStateRepository, GameStateRepository>();
        
        return services;
    }
    
    public static async Task InitializeDatabaseAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await context.Database.EnsureCreatedAsync();
    }
}
EOF

echo "  ✓ Infrastructure updated"

# -----------------------------------------------------------------------------
# Step 5: Create Shared ViewModel
# -----------------------------------------------------------------------------
echo "[5/8] Creating shared Country Quiz ViewModel..."

cat > "$SHARED_DIR/ViewModels/CountryQuizViewModel.cs" << 'EOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly IGameStateRepository _repository;
    private readonly Random _random = new();
    private GameState? _gameState;
    private Country? _correctCountry;
    
    [ObservableProperty]
    private string _questionText = "Loading...";
    
    [ObservableProperty]
    private Country? _country1;
    
    [ObservableProperty]
    private Country? _country2;
    
    [ObservableProperty]
    private string _scoreText = "0/0";
    
    [ObservableProperty]
    private string _streakText = "";
    
    [ObservableProperty]
    private string _bestStreakText = "";
    
    [ObservableProperty]
    private string _accuracyText = "";
    
    [ObservableProperty]
    private string _resultMessage = "";
    
    [ObservableProperty]
    private bool _hasAnswered;
    
    [ObservableProperty]
    private bool _isCorrectAnswer;
    
    [ObservableProperty]
    private int _selectedCountry; // 0 = none, 1 = country1, 2 = country2
    
    [ObservableProperty]
    private string _country1Value = "";
    
    [ObservableProperty]
    private string _country2Value = "";
    
    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;
    
    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());
    
    public CountryQuizViewModel(IGameStateRepository repository)
    {
        _repository = repository;
    }
    
    public async Task InitializeAsync()
    {
        IsBusy = true;
        try
        {
            _gameState = await _repository.GetOrCreateAsync();
            
            if (Enum.TryParse<QuestionType>(_gameState.SelectedQuestionType, out var qt))
            {
                SelectedQuestionType = qt;
            }
            
            UpdateScoreDisplay();
            await NextRoundAsync();
        }
        finally
        {
            IsBusy = false;
        }
    }
    
    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        if (_gameState != null)
        {
            _gameState.SelectedQuestionType = value.ToString();
            _ = SaveAndNextRoundAsync();
        }
    }
    
    private async Task SaveAndNextRoundAsync()
    {
        if (_gameState != null)
        {
            await _repository.SaveAsync(_gameState);
        }
        await NextRoundAsync();
    }
    
    private (Country, Country)? GetRandomPair()
    {
        var valid = CountryData.Countries
            .Where(c => SelectedQuestionType.GetValue(c) != null)
            .ToList();
        
        if (valid.Count < 2) return null;
        
        for (int i = 0; i < 100; i++)
        {
            var c1 = valid[_random.Next(valid.Count)];
            var c2 = valid[_random.Next(valid.Count)];
            var v1 = SelectedQuestionType.GetValue(c1);
            var v2 = SelectedQuestionType.GetValue(c2);
            
            // Ensure different countries AND different values (no ties)
            if (c1.Name != c2.Name && v1 != null && v2 != null && Math.Abs(v1.Value - v2.Value) > 0.001)
            {
                return (c1, c2);
            }
        }
        return null;
    }
    
    [RelayCommand]
    private async Task NextRoundAsync()
    {
        HasAnswered = false;
        SelectedCountry = 0;
        ResultMessage = "";
        Country1Value = "";
        Country2Value = "";
        
        var pair = GetRandomPair();
        if (pair == null)
        {
            QuestionText = "Not enough data for this question type.";
            return;
        }
        
        (Country1, Country2) = pair.Value;
        QuestionText = SelectedQuestionType.GetQuestion();
        
        var v1 = SelectedQuestionType.GetValue(Country1!);
        var v2 = SelectedQuestionType.GetValue(Country2!);
        _correctCountry = v1 > v2 ? Country1 : Country2;
    }
    
    [RelayCommand]
    private async Task SelectCountryAsync(int countryNumber)
    {
        if (HasAnswered || _gameState == null || _correctCountry == null) return;
        
        HasAnswered = true;
        SelectedCountry = countryNumber;
        
        var selectedCountry = countryNumber == 1 ? Country1 : Country2;
        var isCorrect = selectedCountry?.Name == _correctCountry.Name;
        IsCorrectAnswer = isCorrect;
        
        // Record answer
        var wasNewBest = _gameState.CurrentStreak == _gameState.BestStreak && isCorrect;
        _gameState.RecordAnswer(isCorrect);
        var isNewBest = _gameState.CurrentStreak == _gameState.BestStreak && _gameState.CurrentStreak > 1;
        
        // Show values
        if (Country1 != null)
        {
            var v1 = SelectedQuestionType.GetValue(Country1);
            Country1Value = v1.HasValue ? SelectedQuestionType.FormatValue(v1.Value) : "N/A";
        }
        if (Country2 != null)
        {
            var v2 = SelectedQuestionType.GetValue(Country2);
            Country2Value = v2.HasValue ? SelectedQuestionType.FormatValue(v2.Value) : "N/A";
        }
        
        // Build result message
        var message = isCorrect 
            ? MotivationalMessages.GetCorrectMessage()
            : MotivationalMessages.GetIncorrectMessage();
        
        if (isCorrect && isNewBest && !wasNewBest && _gameState.CurrentStreak >= 3)
        {
            message += "\n" + MotivationalMessages.GetNewBestMessage(_gameState.BestStreak);
        }
        else if (isCorrect && _gameState.CurrentStreak >= 3)
        {
            var streakMsg = MotivationalMessages.GetStreakMessage(_gameState.CurrentStreak);
            if (!string.IsNullOrEmpty(streakMsg))
            {
                message += "\n" + streakMsg;
            }
        }
        
        ResultMessage = message;
        UpdateScoreDisplay();
        
        await _repository.SaveAsync(_gameState);
    }
    
    [RelayCommand]
    private async Task ResetGameAsync()
    {
        if (_gameState == null) return;
        
        _gameState.Reset();
        await _repository.SaveAsync(_gameState);
        
        ResultMessage = MotivationalMessages.GetResetMessage();
        UpdateScoreDisplay();
        await NextRoundAsync();
    }
    
    private void UpdateScoreDisplay()
    {
        if (_gameState == null) return;
        
        ScoreText = $"{_gameState.CorrectAnswers}/{_gameState.TotalQuestions}";
        StreakText = _gameState.CurrentStreak > 0 ? $"🔥 {_gameState.CurrentStreak}" : "";
        BestStreakText = _gameState.BestStreak > 0 ? $"⭐ Best: {_gameState.BestStreak}" : "";
        AccuracyText = _gameState.TotalQuestions > 0 
            ? $"{_gameState.Accuracy}% {MotivationalMessages.GetAccuracyComment(_gameState.Accuracy)}"
            : "";
    }
}
EOF

# Update ViewModelBase
cat > "$SHARED_DIR/ViewModels/ViewModelBase.cs" << 'EOF'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
}
EOF

echo "  ✓ Shared ViewModel created"

# -----------------------------------------------------------------------------
# Step 6: Create Responsive Desktop UI
# -----------------------------------------------------------------------------
echo "[6/8] Creating responsive Desktop UI..."

mkdir -p "$DESKTOP_DIR/Views"
mkdir -p "$DESKTOP_DIR/ViewModels"
mkdir -p "$DESKTOP_DIR/Converters"

# Converters for UI
cat > "$DESKTOP_DIR/Converters/Converters.cs" << 'EOF'
using System;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Desktop.Converters;

public class QuestionTypeLabelConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value is QuestionType qt ? qt.GetLabel() : value?.ToString();
    }
    
    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class BoolToColorConverter : IValueConverter
{
    public IBrush? TrueBrush { get; set; }
    public IBrush? FalseBrush { get; set; }
    public IBrush? DefaultBrush { get; set; }
    
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool b)
        {
            return b ? TrueBrush : FalseBrush;
        }
        return DefaultBrush;
    }
    
    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class SelectedToBorderConverter : IMultiValueConverter
{
    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 4 && 
            values[0] is bool hasAnswered &&
            values[1] is int selected &&
            values[2] is bool isCorrect &&
            parameter is string cardNum &&
            int.TryParse(cardNum, out var cardNumber))
        {
            if (!hasAnswered) return new SolidColorBrush(Color.FromRgb(55, 65, 81)); // Gray border
            if (selected != cardNumber) return new SolidColorBrush(Color.FromRgb(55, 65, 81));
            return isCorrect 
                ? new SolidColorBrush(Color.FromRgb(34, 197, 94))   // Green
                : new SolidColorBrush(Color.FromRgb(239, 68, 68)); // Red
        }
        return new SolidColorBrush(Color.FromRgb(55, 65, 81));
    }
}
EOF

# Main Window XAML - Responsive Design
cat > "$DESKTOP_DIR/Views/MainWindow.axaml" << 'EOF'
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyDesktopApplication.Desktop.ViewModels"
        xmlns:conv="using:MyDesktopApplication.Desktop.Converters"
        xmlns:core="using:MyDesktopApplication.Core.Entities"
        x:Class="MyDesktopApplication.Desktop.Views.MainWindow"
        x:DataType="vm:MainWindowViewModel"
        Title="🌍 Country Quiz"
        MinWidth="320" MinHeight="480"
        Width="500" Height="700"
        Background="#0f172a">
    
    <Window.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
    </Window.Resources>
    
    <Window.Styles>
        <!-- Base button style -->
        <Style Selector="Button.country-card">
            <Setter Property="Background" Value="#1e293b"/>
            <Setter Property="BorderBrush" Value="#374151"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style Selector="Button.country-card:pointerover">
            <Setter Property="Background" Value="#334155"/>
            <Setter Property="BorderBrush" Value="#3b82f6"/>
        </Style>
        <Style Selector="Button.country-card:disabled">
            <Setter Property="Opacity" Value="1"/>
        </Style>
        
        <!-- Correct answer style -->
        <Style Selector="Button.correct">
            <Setter Property="Background" Value="#14532d"/>
            <Setter Property="BorderBrush" Value="#22c55e"/>
        </Style>
        
        <!-- Wrong answer style -->
        <Style Selector="Button.wrong">
            <Setter Property="Background" Value="#7f1d1d"/>
            <Setter Property="BorderBrush" Value="#ef4444"/>
        </Style>
        
        <!-- ComboBox styling -->
        <Style Selector="ComboBox">
            <Setter Property="Background" Value="#1e293b"/>
            <Setter Property="BorderBrush" Value="#374151"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
    </Window.Styles>
    
    <ScrollViewer HorizontalScrollBarVisibility="Disabled" VerticalScrollBarVisibility="Auto">
        <Grid RowDefinitions="Auto,Auto,Auto,Auto,*,Auto,Auto" 
              Margin="16" MaxWidth="600">
            
            <!-- Title -->
            <TextBlock Grid.Row="0" 
                       Text="🌍 Country Quiz" 
                       FontSize="28" FontWeight="Bold"
                       Foreground="White"
                       HorizontalAlignment="Center"
                       Margin="0,8,0,16"/>
            
            <!-- Controls Row -->
            <Grid Grid.Row="1" ColumnDefinitions="*,Auto" Margin="0,0,0,12">
                <ComboBox ItemsSource="{Binding QuestionTypes}"
                          SelectedItem="{Binding SelectedQuestionType}"
                          HorizontalAlignment="Stretch">
                    <ComboBox.ItemTemplate>
                        <DataTemplate x:DataType="core:QuestionType">
                            <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"/>
                        </DataTemplate>
                    </ComboBox.ItemTemplate>
                </ComboBox>
                <Button Grid.Column="1" 
                        Content="Reset" 
                        Command="{Binding ResetGameCommand}"
                        Background="#dc2626"
                        Foreground="White"
                        Padding="12,8"
                        Margin="8,0,0,0"/>
            </Grid>
            
            <!-- Score Display -->
            <StackPanel Grid.Row="2" Orientation="Horizontal" 
                        HorizontalAlignment="Center" 
                        Spacing="16" Margin="0,0,0,12">
                <TextBlock Foreground="White" FontSize="16">
                    <Run Text="Score: "/>
                    <Run Text="{Binding ScoreText}" FontWeight="Bold"/>
                </TextBlock>
                <TextBlock Text="{Binding StreakText}" 
                           Foreground="#f97316" FontWeight="Bold" FontSize="16"
                           IsVisible="{Binding StreakText, Converter={x:Static StringConverters.IsNotNullOrEmpty}}"/>
                <TextBlock Text="{Binding BestStreakText}" 
                           Foreground="#fbbf24" FontSize="14"
                           IsVisible="{Binding BestStreakText, Converter={x:Static StringConverters.IsNotNullOrEmpty}}"/>
            </StackPanel>
            
            <!-- Accuracy -->
            <TextBlock Grid.Row="3" 
                       Text="{Binding AccuracyText}"
                       Foreground="#94a3b8"
                       FontSize="14"
                       HorizontalAlignment="Center"
                       Margin="0,0,0,16"
                       IsVisible="{Binding AccuracyText, Converter={x:Static StringConverters.IsNotNullOrEmpty}}"/>
            
            <!-- Question and Countries -->
            <StackPanel Grid.Row="4" Spacing="16">
                <!-- Question Text -->
                <TextBlock Text="{Binding QuestionText}"
                           Foreground="White"
                           FontSize="18" FontWeight="SemiBold"
                           TextWrapping="Wrap"
                           HorizontalAlignment="Center"
                           TextAlignment="Center"
                           Margin="0,0,0,8"/>
                
                <!-- Country Cards Container -->
                <Grid ColumnDefinitions="*,Auto,*" RowDefinitions="Auto">
                    <!-- Country 1 -->
                    <Button Grid.Column="0"
                            Classes="country-card"
                            Classes.correct="{Binding IsCountry1Correct}"
                            Classes.wrong="{Binding IsCountry1Wrong}"
                            Command="{Binding SelectCountryCommand}"
                            CommandParameter="1"
                            IsEnabled="{Binding !HasAnswered}"
                            HorizontalAlignment="Stretch">
                        <StackPanel HorizontalAlignment="Center" Spacing="8">
                            <TextBlock Text="{Binding Country1.Flag}" 
                                       FontSize="48" 
                                       HorizontalAlignment="Center"/>
                            <TextBlock Text="{Binding Country1.Name}" 
                                       Foreground="White"
                                       FontSize="14" FontWeight="SemiBold"
                                       TextWrapping="Wrap"
                                       TextAlignment="Center"
                                       MaxWidth="120"/>
                            <TextBlock Text="{Binding Country1Value}"
                                       Foreground="#22c55e"
                                       FontSize="12" FontWeight="Bold"
                                       HorizontalAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                    </Button>
                    
                    <!-- VS Badge -->
                    <Border Grid.Column="1" 
                            Background="#3b82f6" 
                            CornerRadius="20"
                            Padding="12,8"
                            VerticalAlignment="Center"
                            Margin="8,0">
                        <TextBlock Text="VS" 
                                   Foreground="White" 
                                   FontWeight="Bold"
                                   FontSize="14"/>
                    </Border>
                    
                    <!-- Country 2 -->
                    <Button Grid.Column="2"
                            Classes="country-card"
                            Classes.correct="{Binding IsCountry2Correct}"
                            Classes.wrong="{Binding IsCountry2Wrong}"
                            Command="{Binding SelectCountryCommand}"
                            CommandParameter="2"
                            IsEnabled="{Binding !HasAnswered}"
                            HorizontalAlignment="Stretch">
                        <StackPanel HorizontalAlignment="Center" Spacing="8">
                            <TextBlock Text="{Binding Country2.Flag}" 
                                       FontSize="48" 
                                       HorizontalAlignment="Center"/>
                            <TextBlock Text="{Binding Country2.Name}" 
                                       Foreground="White"
                                       FontSize="14" FontWeight="SemiBold"
                                       TextWrapping="Wrap"
                                       TextAlignment="Center"
                                       MaxWidth="120"/>
                            <TextBlock Text="{Binding Country2Value}"
                                       Foreground="#22c55e"
                                       FontSize="12" FontWeight="Bold"
                                       HorizontalAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                    </Button>
                </Grid>
            </StackPanel>
            
            <!-- Result Message -->
            <Border Grid.Row="5" 
                    Background="#1e293b"
                    CornerRadius="8"
                    Padding="16"
                    Margin="0,16,0,0"
                    IsVisible="{Binding HasAnswered}">
                <TextBlock Text="{Binding ResultMessage}"
                           Foreground="White"
                           FontSize="16"
                           TextWrapping="Wrap"
                           TextAlignment="Center"/>
            </Border>
            
            <!-- Next Button -->
            <Button Grid.Row="6"
                    Content="Next →"
                    Command="{Binding NextRoundCommand}"
                    Background="#3b82f6"
                    Foreground="White"
                    FontSize="16" FontWeight="SemiBold"
                    Padding="24,12"
                    HorizontalAlignment="Center"
                    Margin="0,16,0,8"
                    IsVisible="{Binding HasAnswered}"/>
            
            <!-- Loading Indicator -->
            <StackPanel Grid.Row="4" 
                        HorizontalAlignment="Center" 
                        VerticalAlignment="Center"
                        IsVisible="{Binding IsBusy}">
                <TextBlock Text="Loading..." 
                           Foreground="White" 
                           FontSize="18"/>
            </StackPanel>
        </Grid>
    </ScrollViewer>
</Window>
EOF

# MainWindow code-behind
cat > "$DESKTOP_DIR/Views/MainWindow.axaml.cs" << 'EOF'
using Avalonia.Controls;
using MyDesktopApplication.Desktop.ViewModels;

namespace MyDesktopApplication.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }
    
    protected override async void OnOpened(EventArgs e)
    {
        base.OnOpened(e);
        
        if (DataContext is MainWindowViewModel vm)
        {
            await vm.InitializeAsync();
        }
    }
}
EOF

# Desktop ViewModel (wraps shared)
cat > "$DESKTOP_DIR/ViewModels/MainWindowViewModel.cs" << 'EOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Desktop.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private readonly IGameStateRepository _repository;
    private readonly Random _random = new();
    private GameState? _gameState;
    private Country? _correctCountry;
    
    [ObservableProperty]
    private string _questionText = "Loading...";
    
    [ObservableProperty]
    private Country? _country1;
    
    [ObservableProperty]
    private Country? _country2;
    
    [ObservableProperty]
    private string _scoreText = "0/0";
    
    [ObservableProperty]
    private string _streakText = "";
    
    [ObservableProperty]
    private string _bestStreakText = "";
    
    [ObservableProperty]
    private string _accuracyText = "";
    
    [ObservableProperty]
    private string _resultMessage = "";
    
    [ObservableProperty]
    private bool _hasAnswered;
    
    [ObservableProperty]
    private bool _isCorrectAnswer;
    
    [ObservableProperty]
    private int _selectedCountry;
    
    [ObservableProperty]
    private string _country1Value = "";
    
    [ObservableProperty]
    private string _country2Value = "";
    
    [ObservableProperty]
    private QuestionType _selectedQuestionType = QuestionType.Population;
    
    // Computed properties for UI styling
    public bool IsCountry1Correct => HasAnswered && SelectedCountry == 1 && IsCorrectAnswer;
    public bool IsCountry1Wrong => HasAnswered && SelectedCountry == 1 && !IsCorrectAnswer;
    public bool IsCountry2Correct => HasAnswered && SelectedCountry == 2 && IsCorrectAnswer;
    public bool IsCountry2Wrong => HasAnswered && SelectedCountry == 2 && !IsCorrectAnswer;
    
    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());
    
    public MainWindowViewModel(IGameStateRepository repository)
    {
        _repository = repository;
    }
    
    partial void OnHasAnsweredChanged(bool value)
    {
        OnPropertyChanged(nameof(IsCountry1Correct));
        OnPropertyChanged(nameof(IsCountry1Wrong));
        OnPropertyChanged(nameof(IsCountry2Correct));
        OnPropertyChanged(nameof(IsCountry2Wrong));
    }
    
    partial void OnSelectedCountryChanged(int value)
    {
        OnPropertyChanged(nameof(IsCountry1Correct));
        OnPropertyChanged(nameof(IsCountry1Wrong));
        OnPropertyChanged(nameof(IsCountry2Correct));
        OnPropertyChanged(nameof(IsCountry2Wrong));
    }
    
    partial void OnIsCorrectAnswerChanged(bool value)
    {
        OnPropertyChanged(nameof(IsCountry1Correct));
        OnPropertyChanged(nameof(IsCountry1Wrong));
        OnPropertyChanged(nameof(IsCountry2Correct));
        OnPropertyChanged(nameof(IsCountry2Wrong));
    }
    
    public async Task InitializeAsync()
    {
        IsBusy = true;
        try
        {
            _gameState = await _repository.GetOrCreateAsync();
            
            if (Enum.TryParse<QuestionType>(_gameState.SelectedQuestionType, out var qt))
            {
                SelectedQuestionType = qt;
            }
            
            UpdateScoreDisplay();
            await NextRoundAsync();
        }
        finally
        {
            IsBusy = false;
        }
    }
    
    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        if (_gameState != null && !IsBusy)
        {
            _gameState.SelectedQuestionType = value.ToString();
            _ = SaveAndNextRoundAsync();
        }
    }
    
    private async Task SaveAndNextRoundAsync()
    {
        if (_gameState != null)
        {
            await _repository.SaveAsync(_gameState);
        }
        await NextRoundAsync();
    }
    
    private (Country, Country)? GetRandomPair()
    {
        var valid = CountryData.Countries
            .Where(c => SelectedQuestionType.GetValue(c) != null)
            .ToList();
        
        if (valid.Count < 2) return null;
        
        for (int i = 0; i < 100; i++)
        {
            var c1 = valid[_random.Next(valid.Count)];
            var c2 = valid[_random.Next(valid.Count)];
            var v1 = SelectedQuestionType.GetValue(c1);
            var v2 = SelectedQuestionType.GetValue(c2);
            
            if (c1.Name != c2.Name && v1 != null && v2 != null && Math.Abs(v1.Value - v2.Value) > 0.001)
            {
                return (c1, c2);
            }
        }
        return null;
    }
    
    [RelayCommand]
    private async Task NextRoundAsync()
    {
        HasAnswered = false;
        SelectedCountry = 0;
        ResultMessage = "";
        Country1Value = "";
        Country2Value = "";
        
        var pair = GetRandomPair();
        if (pair == null)
        {
            QuestionText = "Not enough data for this question type.";
            return;
        }
        
        (Country1, Country2) = pair.Value;
        QuestionText = SelectedQuestionType.GetQuestion();
        
        var v1 = SelectedQuestionType.GetValue(Country1!);
        var v2 = SelectedQuestionType.GetValue(Country2!);
        _correctCountry = v1 > v2 ? Country1 : Country2;
    }
    
    [RelayCommand]
    private async Task SelectCountryAsync(string countryNumberStr)
    {
        if (!int.TryParse(countryNumberStr, out var countryNumber)) return;
        if (HasAnswered || _gameState == null || _correctCountry == null) return;
        
        HasAnswered = true;
        SelectedCountry = countryNumber;
        
        var selectedCountry = countryNumber == 1 ? Country1 : Country2;
        var isCorrect = selectedCountry?.Name == _correctCountry.Name;
        IsCorrectAnswer = isCorrect;
        
        var wasNewBest = _gameState.CurrentStreak == _gameState.BestStreak && isCorrect;
        _gameState.RecordAnswer(isCorrect);
        var isNewBest = _gameState.CurrentStreak == _gameState.BestStreak && _gameState.CurrentStreak > 1;
        
        if (Country1 != null)
        {
            var v1 = SelectedQuestionType.GetValue(Country1);
            Country1Value = v1.HasValue ? SelectedQuestionType.FormatValue(v1.Value) : "N/A";
        }
        if (Country2 != null)
        {
            var v2 = SelectedQuestionType.GetValue(Country2);
            Country2Value = v2.HasValue ? SelectedQuestionType.FormatValue(v2.Value) : "N/A";
        }
        
        var message = isCorrect 
            ? MotivationalMessages.GetCorrectMessage()
            : MotivationalMessages.GetIncorrectMessage();
        
        if (isCorrect && isNewBest && !wasNewBest && _gameState.CurrentStreak >= 3)
        {
            message += "\n" + MotivationalMessages.GetNewBestMessage(_gameState.BestStreak);
        }
        else if (isCorrect && _gameState.CurrentStreak >= 3)
        {
            var streakMsg = MotivationalMessages.GetStreakMessage(_gameState.CurrentStreak);
            if (!string.IsNullOrEmpty(streakMsg)) message += "\n" + streakMsg;
        }
        
        ResultMessage = message;
        UpdateScoreDisplay();
        await _repository.SaveAsync(_gameState);
    }
    
    [RelayCommand]
    private async Task ResetGameAsync()
    {
        if (_gameState == null) return;
        
        _gameState.Reset();
        await _repository.SaveAsync(_gameState);
        
        ResultMessage = MotivationalMessages.GetResetMessage();
        UpdateScoreDisplay();
        await NextRoundAsync();
    }
    
    private void UpdateScoreDisplay()
    {
        if (_gameState == null) return;
        
        ScoreText = $"{_gameState.CorrectAnswers}/{_gameState.TotalQuestions}";
        StreakText = _gameState.CurrentStreak > 0 ? $"🔥 {_gameState.CurrentStreak}" : "";
        BestStreakText = _gameState.BestStreak > 0 ? $"⭐ Best: {_gameState.BestStreak}" : "";
        AccuracyText = _gameState.TotalQuestions > 0 
            ? $"{_gameState.Accuracy}% {MotivationalMessages.GetAccuracyComment(_gameState.Accuracy)}"
            : "";
    }
}
EOF

echo "  ✓ Desktop UI created"

# -----------------------------------------------------------------------------
# Step 7: Update Android Project
# -----------------------------------------------------------------------------
echo "[7/8] Updating Android project..."

cat > "$ANDROID_DIR/Views/MainView.axaml" << 'EOF'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="using:MyDesktopApplication.Shared.ViewModels"
             xmlns:conv="using:MyDesktopApplication.Desktop.Converters"
             xmlns:core="using:MyDesktopApplication.Core.Entities"
             x:Class="MyDesktopApplication.Android.Views.MainView"
             x:DataType="vm:CountryQuizViewModel"
             Background="#0f172a">
    
    <UserControl.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
    </UserControl.Resources>
    
    <UserControl.Styles>
        <Style Selector="Button.country-card">
            <Setter Property="Background" Value="#1e293b"/>
            <Setter Property="BorderBrush" Value="#374151"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="12"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
        </Style>
        <Style Selector="Button.country-card:pointerover">
            <Setter Property="Background" Value="#334155"/>
        </Style>
        <Style Selector="Button.correct">
            <Setter Property="Background" Value="#14532d"/>
            <Setter Property="BorderBrush" Value="#22c55e"/>
        </Style>
        <Style Selector="Button.wrong">
            <Setter Property="Background" Value="#7f1d1d"/>
            <Setter Property="BorderBrush" Value="#ef4444"/>
        </Style>
    </UserControl.Styles>
    
    <ScrollViewer HorizontalScrollBarVisibility="Disabled" VerticalScrollBarVisibility="Auto">
        <Grid RowDefinitions="Auto,Auto,Auto,Auto,*,Auto,Auto" Margin="12">
            
            <!-- Title -->
            <TextBlock Grid.Row="0" Text="🌍 Country Quiz" 
                       FontSize="24" FontWeight="Bold" Foreground="White"
                       HorizontalAlignment="Center" Margin="0,8,0,12"/>
            
            <!-- Controls -->
            <Grid Grid.Row="1" ColumnDefinitions="*,Auto" Margin="0,0,0,8">
                <ComboBox ItemsSource="{Binding QuestionTypes}"
                          SelectedItem="{Binding SelectedQuestionType}"
                          Background="#1e293b" Foreground="White">
                    <ComboBox.ItemTemplate>
                        <DataTemplate x:DataType="core:QuestionType">
                            <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"/>
                        </DataTemplate>
                    </ComboBox.ItemTemplate>
                </ComboBox>
                <Button Grid.Column="1" Content="Reset" 
                        Command="{Binding ResetGameCommand}"
                        Background="#dc2626" Foreground="White"
                        Padding="10,6" Margin="8,0,0,0"/>
            </Grid>
            
            <!-- Score -->
            <WrapPanel Grid.Row="2" HorizontalAlignment="Center" Margin="0,0,0,8">
                <TextBlock Foreground="White" FontSize="14" Margin="0,0,12,0">
                    <Run Text="Score: "/><Run Text="{Binding ScoreText}" FontWeight="Bold"/>
                </TextBlock>
                <TextBlock Text="{Binding StreakText}" Foreground="#f97316" FontWeight="Bold"/>
                <TextBlock Text="{Binding BestStreakText}" Foreground="#fbbf24" Margin="12,0,0,0"/>
            </WrapPanel>
            
            <!-- Accuracy -->
            <TextBlock Grid.Row="3" Text="{Binding AccuracyText}"
                       Foreground="#94a3b8" FontSize="12"
                       HorizontalAlignment="Center" Margin="0,0,0,12"
                       IsVisible="{Binding AccuracyText, Converter={x:Static StringConverters.IsNotNullOrEmpty}}"/>
            
            <!-- Question and Cards -->
            <StackPanel Grid.Row="4" Spacing="12">
                <TextBlock Text="{Binding QuestionText}" Foreground="White"
                           FontSize="16" FontWeight="SemiBold"
                           TextWrapping="Wrap" TextAlignment="Center"/>
                
                <Grid ColumnDefinitions="*,Auto,*">
                    <Button Grid.Column="0" Classes="country-card"
                            Command="{Binding SelectCountryCommand}" CommandParameter="1"
                            IsEnabled="{Binding !HasAnswered}">
                        <StackPanel Spacing="6">
                            <TextBlock Text="{Binding Country1.Flag}" FontSize="40" HorizontalAlignment="Center"/>
                            <TextBlock Text="{Binding Country1.Name}" Foreground="White"
                                       FontSize="12" TextWrapping="Wrap" TextAlignment="Center"/>
                            <TextBlock Text="{Binding Country1Value}" Foreground="#22c55e"
                                       FontSize="11" HorizontalAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                    </Button>
                    
                    <Border Grid.Column="1" Background="#3b82f6" CornerRadius="16"
                            Padding="8,4" VerticalAlignment="Center" Margin="6,0">
                        <TextBlock Text="VS" Foreground="White" FontWeight="Bold" FontSize="12"/>
                    </Border>
                    
                    <Button Grid.Column="2" Classes="country-card"
                            Command="{Binding SelectCountryCommand}" CommandParameter="2"
                            IsEnabled="{Binding !HasAnswered}">
                        <StackPanel Spacing="6">
                            <TextBlock Text="{Binding Country2.Flag}" FontSize="40" HorizontalAlignment="Center"/>
                            <TextBlock Text="{Binding Country2.Name}" Foreground="White"
                                       FontSize="12" TextWrapping="Wrap" TextAlignment="Center"/>
                            <TextBlock Text="{Binding Country2Value}" Foreground="#22c55e"
                                       FontSize="11" HorizontalAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                    </Button>
                </Grid>
            </StackPanel>
            
            <!-- Result -->
            <Border Grid.Row="5" Background="#1e293b" CornerRadius="8"
                    Padding="12" Margin="0,12,0,0"
                    IsVisible="{Binding HasAnswered}">
                <TextBlock Text="{Binding ResultMessage}" Foreground="White"
                           FontSize="14" TextWrapping="Wrap" TextAlignment="Center"/>
            </Border>
            
            <!-- Next -->
            <Button Grid.Row="6" Content="Next →"
                    Command="{Binding NextRoundCommand}"
                    Background="#3b82f6" Foreground="White"
                    FontSize="14" FontWeight="SemiBold"
                    Padding="20,10" HorizontalAlignment="Center"
                    Margin="0,12,0,8" IsVisible="{Binding HasAnswered}"/>
        </Grid>
    </ScrollViewer>
</UserControl>
EOF

cat > "$ANDROID_DIR/Views/MainView.axaml.cs" << 'EOF'
using Avalonia.Controls;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
    }
}
EOF

# Update Android App
cat > "$ANDROID_DIR/App.cs" << 'EOF'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Android;

public class App : Avalonia.Application
{
    private IServiceProvider? _services;
    
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }
    
    public override async void OnFrameworkInitializationCompleted()
    {
        var services = new ServiceCollection();
        
        var dbPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "countryquiz.db");
        
        services.AddInfrastructure(dbPath);
        services.AddTransient<CountryQuizViewModel>();
        
        _services = services.BuildServiceProvider();
        
        await DependencyInjection.InitializeDatabaseAsync(_services);
        
        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewLifetime)
        {
            var vm = _services.GetRequiredService<CountryQuizViewModel>();
            var mainView = new MainView { DataContext = vm };
            singleViewLifetime.MainView = mainView;
            
            _ = vm.InitializeAsync();
        }
        
        base.OnFrameworkInitializationCompleted();
    }
}
EOF

echo "  ✓ Android project updated"

# -----------------------------------------------------------------------------
# Step 8: Update App.axaml.cs and Tests
# -----------------------------------------------------------------------------
echo "[8/8] Updating Desktop App and tests..."

cat > "$DESKTOP_DIR/App.axaml.cs" << 'EOF'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Desktop.ViewModels;
using MyDesktopApplication.Desktop.Views;
using MyDesktopApplication.Infrastructure;

namespace MyDesktopApplication.Desktop;

public partial class App : Avalonia.Application
{
    private IServiceProvider? _services;
    
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }
    
    public override async void OnFrameworkInitializationCompleted()
    {
        var services = new ServiceCollection();
        services.AddInfrastructure();
        services.AddTransient<MainWindowViewModel>();
        
        _services = services.BuildServiceProvider();
        
        await DependencyInjection.InitializeDatabaseAsync(_services);
        
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            var vm = _services.GetRequiredService<MainWindowViewModel>();
            desktop.MainWindow = new MainWindow { DataContext = vm };
        }
        
        base.OnFrameworkInitializationCompleted();
    }
}
EOF

# Update tests
mkdir -p "$TESTS_DIR/MyDesktopApplication.Core.Tests"

cat > "$TESTS_DIR/MyDesktopApplication.Core.Tests/GameStateTests.cs" << 'EOF'
using FluentAssertions;
using MyDesktopApplication.Core.Entities;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void RecordAnswer_CorrectAnswer_IncrementsScoreAndStreak()
    {
        var state = new GameState();
        
        state.RecordAnswer(true);
        
        state.CorrectAnswers.Should().Be(1);
        state.TotalQuestions.Should().Be(1);
        state.CurrentStreak.Should().Be(1);
    }
    
    [Fact]
    public void RecordAnswer_IncorrectAnswer_ResetsStreak()
    {
        var state = new GameState { CurrentStreak = 5 };
        
        state.RecordAnswer(false);
        
        state.CurrentStreak.Should().Be(0);
        state.TotalQuestions.Should().Be(1);
    }
    
    [Fact]
    public void RecordAnswer_NewBestStreak_UpdatesBestStreak()
    {
        var state = new GameState { BestStreak = 3, CurrentStreak = 3 };
        
        state.RecordAnswer(true);
        
        state.BestStreak.Should().Be(4);
        state.CurrentStreak.Should().Be(4);
    }
    
    [Fact]
    public void Reset_PreservesBestStreak()
    {
        var state = new GameState 
        { 
            CorrectAnswers = 10, 
            TotalQuestions = 15, 
            CurrentStreak = 5, 
            BestStreak = 8 
        };
        
        state.Reset();
        
        state.CorrectAnswers.Should().Be(0);
        state.TotalQuestions.Should().Be(0);
        state.CurrentStreak.Should().Be(0);
        state.BestStreak.Should().Be(8);
    }
    
    [Fact]
    public void Accuracy_CalculatesCorrectly()
    {
        var state = new GameState { CorrectAnswers = 7, TotalQuestions = 10 };
        
        state.Accuracy.Should().Be(70.0);
    }
    
    [Fact]
    public void Accuracy_NoQuestions_ReturnsZero()
    {
        var state = new GameState();
        
        state.Accuracy.Should().Be(0);
    }
}
EOF

cat > "$TESTS_DIR/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs" << 'EOF'
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
EOF

# Update csproj files
cat > "$SHARED_DIR/MyDesktopApplication.Shared.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <PackageReference Include="FluentValidation" />
  </ItemGroup>
</Project>
EOF

cat > "$DESKTOP_DIR/MyDesktopApplication.Desktop.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <BuiltInComInteropSupport>true</BuiltInComInteropSupport>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
    <ApplicationIcon>Assets\avalonia-logo.ico</ApplicationIcon>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Desktop" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="Avalonia.ReactiveUI" />
    <PackageReference Include="Avalonia.Diagnostics" Condition="'$(Configuration)' == 'Debug'" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
EOF

cat > "$ANDROID_DIR/MyDesktopApplication.Android.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <Nullable>enable</Nullable>
    <ApplicationId>com.mycompany.countryquiz</ApplicationId>
    <ApplicationVersion>1</ApplicationVersion>
    <ApplicationDisplayVersion>1.0.0</ApplicationDisplayVersion>
    <AndroidPackageFormat>apk</AndroidPackageFormat>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.ReactiveUI" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
EOF

# Update Desktop ViewModelBase
cat > "$DESKTOP_DIR/ViewModels/ViewModelBase.cs" << 'EOF'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Desktop.ViewModels;

public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
}
EOF

echo "  ✓ Tests and configuration updated"

# -----------------------------------------------------------------------------
# Build and Verify
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Building project..."
echo "=============================================="

cd "$PROJECT_ROOT"
dotnet restore
dotnet build

if [ $? -eq 0 ]; then
    echo ""
    echo "=============================================="
    echo "  ✅ Country Quiz Conversion Complete!"
    echo "=============================================="
    echo ""
    echo "Features implemented:"
    echo "  • 80+ countries with real statistics"
    echo "  • 8 question categories"
    echo "  • Persistent SQLite storage"
    echo "  • Score tracking with streaks"
    echo "  • Motivational messages"
    echo "  • Responsive UI (phones to tablets)"
    echo "  • Reset button (preserves best streak)"
    echo ""
    echo "To run Desktop:"
    echo "  dotnet run --project src/MyDesktopApplication.Desktop"
    echo ""
    echo "To build Android:"
    echo "  dotnet build src/MyDesktopApplication.Android"
    echo ""
    echo "To run tests:"
    echo "  dotnet test"
else
    echo ""
    echo "=============================================="
    echo "  ❌ Build failed - check errors above"
    echo "=============================================="
    exit 1
fi

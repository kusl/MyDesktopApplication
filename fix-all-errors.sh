# Fix UI.Tests csproj and tests
cat > "tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../../src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="../../src/MyDesktopApplication.Desktop#!/bin/bash
set -e

# =============================================================================
# Comprehensive Fix Script for MyDesktopApplication
# =============================================================================
# Fixes ALL 18 build errors identified in output.txt:
#
# Core.Tests (9 errors):
#   - GameState missing: CurrentScore, HighScore
#   - Country missing: Flag, PopulationDensity, LiteracyRate
#
# Integration.Tests (1 error):
#   - UseInMemoryDatabase missing (need package reference)
#
# Desktop (8 errors + 3 warnings):
#   - QuestionType missing: GetLabel extension
#   - IGameStateRepository.GetOrCreateAsync missing userId argument
#   - double.Value doesn't exist (nullable type confusion)
#   - Converters.cs issues
# =============================================================================

PROJECT_ROOT="${1:-$(pwd)}"
cd "$PROJECT_ROOT"

echo "=============================================="
echo "  Comprehensive Fix Script"
echo "=============================================="
echo ""
echo "Project root: $PROJECT_ROOT"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Kill stuck processes
# -----------------------------------------------------------------------------
echo "[1/9] Killing stuck build processes..."
pkill -f "aapt2" 2>/dev/null || true
pkill -f "VBCSCompiler" 2>/dev/null || true
pkill -f "dotnet.*build" 2>/dev/null || true
sleep 1

# -----------------------------------------------------------------------------
# Step 2: Clean build artifacts
# -----------------------------------------------------------------------------
echo "[2/9] Cleaning build artifacts..."
find . -type d \( -name "bin" -o -name "obj" \) -exec rm -rf {} + 2>/dev/null || true

# -----------------------------------------------------------------------------
# Step 3: Update Directory.Packages.props (add EF InMemory for tests)
# -----------------------------------------------------------------------------
echo "[3/9] Updating Directory.Packages.props..."
cat > "Directory.Packages.props" << 'PROPS_EOF'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup Label="Avalonia">
    <PackageVersion Include="Avalonia" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Android" Version="11.3.0" />
  </ItemGroup>

  <ItemGroup Label="MVVM">
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
  </ItemGroup>

  <ItemGroup Label="Entity Framework Core">
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.InMemory" Version="10.0.0" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
  </ItemGroup>

  <ItemGroup Label="Logging and Telemetry">
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Console" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.0" />
    <PackageVersion Include="OpenTelemetry" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Instrumentation.Runtime" Version="1.11.0" />
  </ItemGroup>

  <ItemGroup Label="Testing">
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.5" />
    <PackageVersion Include="Shouldly" Version="4.3.0" />
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
  </ItemGroup>
</Project>
PROPS_EOF

# -----------------------------------------------------------------------------
# Step 4: Fix GameState entity (add CurrentScore, HighScore, etc.)
# -----------------------------------------------------------------------------
echo "[4/9] Fixing GameState entity..."
mkdir -p "src/MyDesktopApplication.Core/Entities"
cat > "src/MyDesktopApplication.Core/Entities/GameState.cs" << 'EOF'
namespace MyDesktopApplication.Core.Entities;

public class GameState : EntityBase
{
    public string UserId { get; set; } = "default";
    
    // Score tracking
    public int Score { get; set; }
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int BestStreak { get; set; }
    public int CurrentStreak { get; set; }
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    
    // Selected question type (stored as int for EF)
    public int SelectedQuestionTypeValue { get; set; }
    
    // Calculated properties
    public double Accuracy => TotalQuestions > 0 
        ? (double)CorrectAnswers / TotalQuestions * 100 
        : 0;
    
    public double AccuracyPercentage => Accuracy;
    
    public void RecordAnswer(bool isCorrect)
    {
        TotalQuestions++;
        TotalAnswered++;
        
        if (isCorrect)
        {
            CorrectAnswers++;
            TotalCorrect++;
            CurrentScore++;
            Score++;
            CurrentStreak++;
            
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
            
            if (CurrentScore > HighScore)
                HighScore = CurrentScore;
        }
        else
        {
            CurrentStreak = 0;
        }
    }
    
    public void Reset()
    {
        Score = 0;
        CurrentScore = 0;
        CurrentStreak = 0;
        CorrectAnswers = 0;
        TotalQuestions = 0;
        TotalCorrect = 0;
        TotalAnswered = 0;
        // Note: HighScore and BestStreak are preserved
    }
}
EOF

# -----------------------------------------------------------------------------
# Step 5: Fix Country entity (add Flag, PopulationDensity, LiteracyRate, etc.)
# -----------------------------------------------------------------------------
echo "[5/9] Fixing Country entity..."
cat > "src/MyDesktopApplication.Core/Entities/Country.cs" << 'EOF'
namespace MyDesktopApplication.Core.Entities;

public class Country
{
    public required string Code { get; init; }
    public required string Name { get; init; }
    public string Iso2 { get; init; } = "";
    public string Flag { get; init; } = "";
    public string Continent { get; init; } = "";
    
    // Core statistics
    public long Population { get; init; }
    public double Area { get; init; }
    public double Gdp { get; init; }
    public double GdpPerCapita { get; init; }
    
    // Derived/alternative names for compatibility
    public double Density { get; init; }
    public double PopulationDensity => Density > 0 ? Density : (Area > 0 ? Population / Area : 0);
    
    public double Literacy { get; init; }
    public double LiteracyRate => Literacy;
    
    public double Hdi { get; init; }
    public double LifeExpectancy { get; init; }
}
EOF

# -----------------------------------------------------------------------------
# Step 6: Fix QuestionType with GetLabel extension
# -----------------------------------------------------------------------------
echo "[6/9] Fixing QuestionType and extensions..."
cat > "src/MyDesktopApplication.Core/Entities/QuestionType.cs" << 'EOF'
namespace MyDesktopApplication.Core.Entities;

public enum QuestionType
{
    Population,
    Area,
    Gdp,
    GdpPerCapita,
    PopulationDensity,
    Literacy,
    Hdi,
    LifeExpectancy
}

public static class QuestionTypeExtensions
{
    public static string GetLabel(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.Gdp => "GDP (USD)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.Literacy => "Literacy Rate (%)",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };
    
    public static double GetValue(this QuestionType type, Country country) => type switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.Gdp => country.Gdp,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.PopulationDensity => country.PopulationDensity,
        QuestionType.Literacy => country.LiteracyRate,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };
    
    public static string FormatValue(this QuestionType type, double value) => type switch
    {
        QuestionType.Population => FormatPopulation(value),
        QuestionType.Area => $"{value:N0} km²",
        QuestionType.Gdp => FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.Literacy => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N2")
    };
    
    private static string FormatPopulation(double pop)
    {
        return pop switch
        {
            >= 1_000_000_000 => $"{pop / 1_000_000_000:N2}B",
            >= 1_000_000 => $"{pop / 1_000_000:N2}M",
            >= 1_000 => $"{pop / 1_000:N1}K",
            _ => $"{pop:N0}"
        };
    }
    
    private static string FormatCurrency(double amount)
    {
        return amount switch
        {
            >= 1_000_000_000_000 => $"${amount / 1_000_000_000_000:N2}T",
            >= 1_000_000_000 => $"${amount / 1_000_000_000:N2}B",
            >= 1_000_000 => $"${amount / 1_000_000:N2}M",
            _ => $"${amount:N0}"
        };
    }
}
EOF

# -----------------------------------------------------------------------------
# Step 7: Fix IGameStateRepository interface
# -----------------------------------------------------------------------------
echo "[7/9] Fixing repositories and tests..."

# Fix the interface
cat > "src/MyDesktopApplication.Core/Interfaces/IGameStateRepository.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

public interface IGameStateRepository
{
    Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default);
    Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default);
    Task SaveAsync(GameState gameState, CancellationToken ct = default);
    Task ResetAsync(string userId, CancellationToken ct = default);
}
EOF

# Fix the repository implementation
cat > "src/MyDesktopApplication.Infrastructure/Repositories/GameStateRepository.cs" << 'EOF'
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
    
    public async Task<GameState> GetOrCreateAsync(string userId, CancellationToken ct = default)
    {
        var state = await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
        
        if (state == null)
        {
            state = new GameState { UserId = userId };
            _context.GameStates.Add(state);
            await _context.SaveChangesAsync(ct);
        }
        
        return state;
    }
    
    public async Task<GameState?> GetByUserIdAsync(string userId, CancellationToken ct = default)
    {
        return await _context.GameStates
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);
    }
    
    public async Task SaveAsync(GameState gameState, CancellationToken ct = default)
    {
        if (gameState.Id == Guid.Empty)
        {
            _context.GameStates.Add(gameState);
        }
        else
        {
            _context.GameStates.Update(gameState);
        }
        
        await _context.SaveChangesAsync(ct);
    }
    
    public async Task ResetAsync(string userId, CancellationToken ct = default)
    {
        var state = await GetOrCreateAsync(userId, ct);
        state.Reset();
        await _context.SaveChangesAsync(ct);
    }
}
EOF

# Fix Core.Tests csproj
cat > "tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../../src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
  </ItemGroup>
</Project>
EOF

# Fix Integration.Tests csproj to include InMemory package
cat > "tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../../src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="../../src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
</Project>
EOF

# Fix TodoRepositoryTests to have proper using
cat > "tests/MyDesktopApplication.Integration.Tests/TodoRepositoryTests.cs" << 'EOF'
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

    [Fact]
    public async Task AddAsync_ShouldAddTodoItem()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        await _repository.AddAsync(todo);
        var items = await _repository.GetAllAsync();

        // Assert
        items.ShouldContain(t => t.Title == "Test Todo");
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnAllItems()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Todo 1" });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2" });

        // Act
        var items = await _repository.GetAllAsync();

        // Assert
        items.Count().ShouldBe(2);
    }

    [Fact]
    public async Task GetIncompleteAsync_ShouldReturnOnlyIncomplete()
    {
        // Arrange
        var complete = new TodoItem { Title = "Complete" };
        complete.MarkComplete();
        await _repository.AddAsync(complete);
        await _repository.AddAsync(new TodoItem { Title = "Incomplete" });

        // Act
        var items = await _repository.GetIncompleteAsync();

        // Assert
        items.Count().ShouldBe(1);
        items.First().Title.ShouldBe("Incomplete");
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}
EOF

# Fix GameStateTests
cat > "tests/MyDesktopApplication.Core.Tests/GameStateTests.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void NewGameState_ShouldHaveZeroScores()
    {
        var state = new GameState();

        state.CurrentScore.ShouldBe(0);
        state.HighScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.BestStreak.ShouldBe(0);
    }

    [Fact]
    public void RecordAnswer_Correct_ShouldIncrementScoreAndStreak()
    {
        var state = new GameState();

        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(true);

        state.CurrentScore.ShouldBe(3);
        state.HighScore.ShouldBe(3);
        state.CurrentStreak.ShouldBe(3);
        state.BestStreak.ShouldBe(3);
    }

    [Fact]
    public void RecordAnswer_Incorrect_ShouldResetStreak()
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
    public void Reset_ShouldPreserveHighScoreAndBestStreak()
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
    public void Accuracy_ShouldCalculateCorrectly()
    {
        var state = new GameState();
        state.RecordAnswer(true);
        state.RecordAnswer(true);
        state.RecordAnswer(false);
        state.RecordAnswer(true);

        state.Accuracy.ShouldBe(75.0);
    }
}
EOF

# Fix TodoItemTests
cat > "tests/MyDesktopApplication.Core.Tests/TodoItemTests.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_ShouldBeIncomplete()
    {
        var todo = new TodoItem { Title = "Test" };
        
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }

    [Fact]
    public void MarkComplete_ShouldSetCompletedAtAndIsCompleted()
    {
        var todo = new TodoItem { Title = "Test" };
        
        todo.MarkComplete();
        
        todo.IsCompleted.ShouldBeTrue();
        todo.CompletedAt.ShouldNotBeNull();
    }

    [Fact]
    public void MarkIncomplete_ShouldClearCompletedAt()
    {
        var todo = new TodoItem { Title = "Test" };
        todo.MarkComplete();
        
        todo.MarkIncomplete();
        
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }
}
EOF

# Fix QuestionTypeTests
cat > "tests/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Area, "Area (km²)")]
    [InlineData(QuestionType.Gdp, "GDP (USD)")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita")]
    [InlineData(QuestionType.PopulationDensity, "Population Density")]
    [InlineData(QuestionType.Literacy, "Literacy Rate (%)")]
    [InlineData(QuestionType.Hdi, "Human Development Index")]
    [InlineData(QuestionType.LifeExpectancy, "Life Expectancy")]
    public void GetLabel_ShouldReturnCorrectLabel(QuestionType type, string expectedLabel)
    {
        type.GetLabel().ShouldBe(expectedLabel);
    }

    [Fact]
    public void GetValue_ShouldReturnCorrectProperty()
    {
        var country = new Country
        {
            Code = "USA",
            Name = "United States",
            Flag = "🇺🇸",
            Population = 331_000_000,
            Area = 9_833_520,
            Gdp = 25_462_700_000_000,
            GdpPerCapita = 76_329,
            Density = 36,
            Literacy = 99.0,
            Hdi = 0.921,
            LifeExpectancy = 76.4
        };

        QuestionType.Population.GetValue(country).ShouldBe(331_000_000);
        QuestionType.Area.GetValue(country).ShouldBe(9_833_520);
        QuestionType.PopulationDensity.GetValue(country).ShouldBe(36);
        QuestionType.Literacy.GetValue(country).ShouldBe(99.0);
    }

    [Theory]
    [InlineData(1_500_000_000, "1.50B")]
    [InlineData(350_000_000, "350.00M")]
    [InlineData(50_000, "50.0K")]
    public void FormatValue_Population_ShouldFormatCorrectly(double value, string expected)
    {
        QuestionType.Population.FormatValue(value).ShouldBe(expected);
    }
}
EOF

# Ensure CountryData exists in Shared
mkdir -p "src/MyDesktopApplication.Shared/Data"
cat > "src/MyDesktopApplication.Shared/Data/CountryData.cs" << 'EOF'
using System.Collections.Generic;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Data;

public static class CountryData
{
    public static IReadOnlyList<Country> Countries { get; } = new List<Country>
    {
        new() { Code = "CHN", Name = "China", Iso2 = "CN", Flag = "🇨🇳", Continent = "Asia", Population = 1_412_000_000, Area = 9_596_960, Gdp = 17_963_000_000_000, GdpPerCapita = 12_720, Density = 147, Literacy = 96.8, Hdi = 0.768, LifeExpectancy = 78.2 },
        new() { Code = "IND", Name = "India", Iso2 = "IN", Flag = "🇮🇳", Continent = "Asia", Population = 1_408_000_000, Area = 3_287_263, Gdp = 3_385_000_000_000, GdpPerCapita = 2_410, Density = 428, Literacy = 74.4, Hdi = 0.633, LifeExpectancy = 70.4 },
        new() { Code = "USA", Name = "United States", Iso2 = "US", Flag = "🇺🇸", Continent = "North America", Population = 331_000_000, Area = 9_833_520, Gdp = 25_462_700_000_000, GdpPerCapita = 76_329, Density = 36, Literacy = 99.0, Hdi = 0.921, LifeExpectancy = 76.4 },
        new() { Code = "IDN", Name = "Indonesia", Iso2 = "ID", Flag = "🇮🇩", Continent = "Asia", Population = 275_000_000, Area = 1_904_569, Gdp = 1_319_000_000_000, GdpPerCapita = 4_788, Density = 144, Literacy = 96.0, Hdi = 0.705, LifeExpectancy = 71.7 },
        new() { Code = "PAK", Name = "Pakistan", Iso2 = "PK", Flag = "🇵🇰", Continent = "Asia", Population = 231_000_000, Area = 881_913, Gdp = 376_500_000_000, GdpPerCapita = 1_505, Density = 262, Literacy = 58.0, Hdi = 0.544, LifeExpectancy = 66.1 },
        new() { Code = "NGA", Name = "Nigeria", Iso2 = "NG", Flag = "🇳🇬", Continent = "Africa", Population = 218_000_000, Area = 923_768, Gdp = 477_400_000_000, GdpPerCapita = 2_184, Density = 236, Literacy = 62.0, Hdi = 0.535, LifeExpectancy = 53.9 },
        new() { Code = "BRA", Name = "Brazil", Iso2 = "BR", Flag = "🇧🇷", Continent = "South America", Population = 215_000_000, Area = 8_515_767, Gdp = 1_920_000_000_000, GdpPerCapita = 8_917, Density = 25, Literacy = 93.2, Hdi = 0.754, LifeExpectancy = 75.9 },
        new() { Code = "BGD", Name = "Bangladesh", Iso2 = "BD", Flag = "🇧🇩", Continent = "Asia", Population = 171_000_000, Area = 147_570, Gdp = 460_200_000_000, GdpPerCapita = 2_688, Density = 1159, Literacy = 74.9, Hdi = 0.661, LifeExpectancy = 72.4 },
        new() { Code = "RUS", Name = "Russia", Iso2 = "RU", Flag = "🇷🇺", Continent = "Europe", Population = 144_000_000, Area = 17_098_242, Gdp = 2_240_000_000_000, GdpPerCapita = 15_345, Density = 8, Literacy = 99.7, Hdi = 0.822, LifeExpectancy = 70.1 },
        new() { Code = "MEX", Name = "Mexico", Iso2 = "MX", Flag = "🇲🇽", Continent = "North America", Population = 128_000_000, Area = 1_964_375, Gdp = 1_322_000_000_000, GdpPerCapita = 10_046, Density = 65, Literacy = 95.4, Hdi = 0.758, LifeExpectancy = 75.1 },
        new() { Code = "JPN", Name = "Japan", Iso2 = "JP", Flag = "🇯🇵", Continent = "Asia", Population = 125_000_000, Area = 377_975, Gdp = 4_231_000_000_000, GdpPerCapita = 33_815, Density = 331, Literacy = 99.0, Hdi = 0.925, LifeExpectancy = 84.6 },
        new() { Code = "ETH", Name = "Ethiopia", Iso2 = "ET", Flag = "🇪🇹", Continent = "Africa", Population = 120_000_000, Area = 1_104_300, Gdp = 126_800_000_000, GdpPerCapita = 1_027, Density = 109, Literacy = 51.8, Hdi = 0.498, LifeExpectancy = 65.0 },
        new() { Code = "PHL", Name = "Philippines", Iso2 = "PH", Flag = "🇵🇭", Continent = "Asia", Population = 115_000_000, Area = 300_000, Gdp = 404_300_000_000, GdpPerCapita = 3_499, Density = 383, Literacy = 96.3, Hdi = 0.699, LifeExpectancy = 71.2 },
        new() { Code = "EGY", Name = "Egypt", Iso2 = "EG", Flag = "🇪🇬", Continent = "Africa", Population = 104_000_000, Area = 1_001_450, Gdp = 476_700_000_000, GdpPerCapita = 4_295, Density = 104, Literacy = 73.1, Hdi = 0.731, LifeExpectancy = 72.0 },
        new() { Code = "VNM", Name = "Vietnam", Iso2 = "VN", Flag = "🇻🇳", Continent = "Asia", Population = 99_000_000, Area = 331_212, Gdp = 408_800_000_000, GdpPerCapita = 4_122, Density = 299, Literacy = 95.8, Hdi = 0.703, LifeExpectancy = 75.4 },
        new() { Code = "DEU", Name = "Germany", Iso2 = "DE", Flag = "🇩🇪", Continent = "Europe", Population = 84_000_000, Area = 357_022, Gdp = 4_072_000_000_000, GdpPerCapita = 48_718, Density = 235, Literacy = 99.0, Hdi = 0.942, LifeExpectancy = 81.2 },
        new() { Code = "TUR", Name = "Turkey", Iso2 = "TR", Flag = "🇹🇷", Continent = "Asia", Population = 85_000_000, Area = 783_562, Gdp = 905_500_000_000, GdpPerCapita = 10_674, Density = 109, Literacy = 96.7, Hdi = 0.838, LifeExpectancy = 78.0 },
        new() { Code = "IRN", Name = "Iran", Iso2 = "IR", Flag = "🇮🇷", Continent = "Asia", Population = 87_000_000, Area = 1_648_195, Gdp = 388_500_000_000, GdpPerCapita = 4_686, Density = 53, Literacy = 85.5, Hdi = 0.774, LifeExpectancy = 76.7 },
        new() { Code = "THA", Name = "Thailand", Iso2 = "TH", Flag = "🇹🇭", Continent = "Asia", Population = 70_000_000, Area = 513_120, Gdp = 495_300_000_000, GdpPerCapita = 7_066, Density = 136, Literacy = 94.1, Hdi = 0.800, LifeExpectancy = 78.7 },
        new() { Code = "GBR", Name = "United Kingdom", Iso2 = "GB", Flag = "🇬🇧", Continent = "Europe", Population = 67_000_000, Area = 242_495, Gdp = 3_070_000_000_000, GdpPerCapita = 45_850, Density = 276, Literacy = 99.0, Hdi = 0.929, LifeExpectancy = 81.0 },
        new() { Code = "FRA", Name = "France", Iso2 = "FR", Flag = "🇫🇷", Continent = "Europe", Population = 68_000_000, Area = 643_801, Gdp = 2_780_000_000_000, GdpPerCapita = 40_886, Density = 106, Literacy = 99.0, Hdi = 0.903, LifeExpectancy = 82.5 },
        new() { Code = "ITA", Name = "Italy", Iso2 = "IT", Flag = "🇮🇹", Continent = "Europe", Population = 59_000_000, Area = 301_340, Gdp = 2_010_000_000_000, GdpPerCapita = 34_158, Density = 196, Literacy = 99.2, Hdi = 0.895, LifeExpectancy = 83.5 },
        new() { Code = "ZAF", Name = "South Africa", Iso2 = "ZA", Flag = "🇿🇦", Continent = "Africa", Population = 60_000_000, Area = 1_221_037, Gdp = 405_900_000_000, GdpPerCapita = 6_776, Density = 49, Literacy = 95.0, Hdi = 0.713, LifeExpectancy = 64.1 },
        new() { Code = "KOR", Name = "South Korea", Iso2 = "KR", Flag = "🇰🇷", Continent = "Asia", Population = 52_000_000, Area = 100_210, Gdp = 1_665_000_000_000, GdpPerCapita = 32_255, Density = 519, Literacy = 97.9, Hdi = 0.925, LifeExpectancy = 83.5 },
        new() { Code = "ESP", Name = "Spain", Iso2 = "ES", Flag = "🇪🇸", Continent = "Europe", Population = 47_000_000, Area = 505_990, Gdp = 1_418_000_000_000, GdpPerCapita = 30_104, Density = 93, Literacy = 98.6, Hdi = 0.905, LifeExpectancy = 83.6 },
        new() { Code = "ARG", Name = "Argentina", Iso2 = "AR", Flag = "🇦🇷", Continent = "South America", Population = 46_000_000, Area = 2_780_400, Gdp = 632_800_000_000, GdpPerCapita = 13_709, Density = 17, Literacy = 99.0, Hdi = 0.842, LifeExpectancy = 77.0 },
        new() { Code = "UKR", Name = "Ukraine", Iso2 = "UA", Flag = "🇺🇦", Continent = "Europe", Population = 41_000_000, Area = 603_550, Gdp = 160_500_000_000, GdpPerCapita = 3_727, Density = 68, Literacy = 99.8, Hdi = 0.773, LifeExpectancy = 71.6 },
        new() { Code = "POL", Name = "Poland", Iso2 = "PL", Flag = "🇵🇱", Continent = "Europe", Population = 38_000_000, Area = 312_696, Gdp = 688_200_000_000, GdpPerCapita = 18_000, Density = 122, Literacy = 99.8, Hdi = 0.876, LifeExpectancy = 78.7 },
        new() { Code = "CAN", Name = "Canada", Iso2 = "CA", Flag = "🇨🇦", Continent = "North America", Population = 39_000_000, Area = 9_984_670, Gdp = 2_140_000_000_000, GdpPerCapita = 52_051, Density = 4, Literacy = 99.0, Hdi = 0.936, LifeExpectancy = 82.4 },
        new() { Code = "AUS", Name = "Australia", Iso2 = "AU", Flag = "🇦🇺", Continent = "Oceania", Population = 26_000_000, Area = 7_692_024, Gdp = 1_675_000_000_000, GdpPerCapita = 65_366, Density = 3, Literacy = 99.0, Hdi = 0.951, LifeExpectancy = 83.4 },
        new() { Code = "NLD", Name = "Netherlands", Iso2 = "NL", Flag = "🇳🇱", Continent = "Europe", Population = 18_000_000, Area = 41_850, Gdp = 991_100_000_000, GdpPerCapita = 57_025, Density = 430, Literacy = 99.0, Hdi = 0.941, LifeExpectancy = 82.0 },
        new() { Code = "SAU", Name = "Saudi Arabia", Iso2 = "SA", Flag = "🇸🇦", Continent = "Asia", Population = 35_000_000, Area = 2_149_690, Gdp = 1_108_000_000_000, GdpPerCapita = 30_436, Density = 16, Literacy = 97.6, Hdi = 0.875, LifeExpectancy = 76.9 },
        new() { Code = "CHE", Name = "Switzerland", Iso2 = "CH", Flag = "🇨🇭", Continent = "Europe", Population = 9_000_000, Area = 41_284, Gdp = 807_700_000_000, GdpPerCapita = 93_260, Density = 218, Literacy = 99.0, Hdi = 0.962, LifeExpectancy = 83.8 },
        new() { Code = "NOR", Name = "Norway", Iso2 = "NO", Flag = "🇳🇴", Continent = "Europe", Population = 5_500_000, Area = 385_207, Gdp = 579_300_000_000, GdpPerCapita = 106_328, Density = 14, Literacy = 99.0, Hdi = 0.961, LifeExpectancy = 83.2 },
        new() { Code = "SWE", Name = "Sweden", Iso2 = "SE", Flag = "🇸🇪", Continent = "Europe", Population = 10_500_000, Area = 450_295, Gdp = 585_900_000_000, GdpPerCapita = 55_566, Density = 23, Literacy = 99.0, Hdi = 0.947, LifeExpectancy = 83.0 },
        new() { Code = "ISR", Name = "Israel", Iso2 = "IL", Flag = "🇮🇱", Continent = "Asia", Population = 9_500_000, Area = 22_145, Gdp = 525_000_000_000, GdpPerCapita = 54_930, Density = 429, Literacy = 97.8, Hdi = 0.919, LifeExpectancy = 82.9 },
        new() { Code = "SGP", Name = "Singapore", Iso2 = "SG", Flag = "🇸🇬", Continent = "Asia", Population = 6_000_000, Area = 733, Gdp = 397_000_000_000, GdpPerCapita = 72_795, Density = 8186, Literacy = 97.5, Hdi = 0.939, LifeExpectancy = 83.9 },
        new() { Code = "NZL", Name = "New Zealand", Iso2 = "NZ", Flag = "🇳🇿", Continent = "Oceania", Population = 5_000_000, Area = 268_838, Gdp = 247_200_000_000, GdpPerCapita = 48_802, Density = 19, Literacy = 99.0, Hdi = 0.937, LifeExpectancy = 82.5 },
        new() { Code = "KEN", Name = "Kenya", Iso2 = "KE", Flag = "🇰🇪", Continent = "Africa", Population = 54_000_000, Area = 580_367, Gdp = 113_400_000_000, GdpPerCapita = 2_082, Density = 93, Literacy = 81.5, Hdi = 0.575, LifeExpectancy = 67.0 },
        new() { Code = "GHA", Name = "Ghana", Iso2 = "GH", Flag = "🇬🇭", Continent = "Africa", Population = 33_000_000, Area = 238_533, Gdp = 77_590_000_000, GdpPerCapita = 2_363, Density = 138, Literacy = 79.0, Hdi = 0.632, LifeExpectancy = 64.1 },
    };
}
EOF

# Fix Desktop Converters
mkdir -p "src/MyDesktopApplication.Desktop/Converters"
cat > "src/MyDesktopApplication.Desktop/Converters/Converters.cs" << 'EOF'
using System;
using System.Globalization;
using Avalonia.Data.Converters;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Desktop.Converters;

public class QuestionTypeLabelConverter : IValueConverter
{
    public static readonly QuestionTypeLabelConverter Instance = new();

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is QuestionType qt)
        {
            return qt.GetLabel();
        }
        return value?.ToString() ?? "";
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}

public class BoolToStringConverter : IValueConverter
{
    public static readonly BoolToStringConverter Instance = new();

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool b && parameter is string s)
        {
            var parts = s.Split('|');
            return b ? parts[0] : (parts.Length > 1 ? parts[1] : "");
        }
        return "";
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
EOF

# Fix MainWindowViewModel - remove nullable .Value calls
cat > "src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs" << 'EOF'
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
EOF

# -----------------------------------------------------------------------------
# Step 8: Fix UI Tests
# -----------------------------------------------------------------------------
echo "[8/9] Fixing UI tests..."
cat > "tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../../src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="../../src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
    <ProjectReference Include="../../src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
</Project>
EOF

cat > "tests/MyDesktopApplication.UI.Tests/MainWindowViewModelTests.cs" << 'EOF'
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Desktop.ViewModels;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.UI.Tests;

public class MainWindowViewModelTests
{
    [Fact]
    public void NewViewModel_ShouldHaveInitialState()
    {
        var vm = new MainWindowViewModel();

        vm.Score.ShouldBe(0);
        vm.HighScore.ShouldBe(0);
        vm.Streak.ShouldBe(0);
        vm.BestStreak.ShouldBe(0);
    }

    [Fact]
    public void QuestionTypes_ShouldContainAllTypes()
    {
        var vm = new MainWindowViewModel();

        vm.QuestionTypes.Count.ShouldBe(8);
        vm.QuestionTypes.ShouldContain(QuestionType.Population);
        vm.QuestionTypes.ShouldContain(QuestionType.Area);
        vm.QuestionTypes.ShouldContain(QuestionType.Gdp);
    }

    [Fact]
    public void GenerateNewQuestion_ShouldSetCountryNames()
    {
        var vm = new MainWindowViewModel();
        
        // Wait briefly for initialization
        Thread.Sleep(100);
        vm.GenerateNewQuestionCommand.Execute(null);

        vm.Country1Name.ShouldNotBeNullOrEmpty();
        vm.Country2Name.ShouldNotBeNullOrEmpty();
        vm.Country1Name.ShouldNotBe(vm.Country2Name);
    }

    [Fact]
    public void SelectedQuestionType_DefaultsToPopulation()
    {
        var vm = new MainWindowViewModel();

        vm.SelectedQuestionType.ShouldBe(QuestionType.Population);
    }
}
EOF

# -----------------------------------------------------------------------------
# Step 9: Restore and build
# -----------------------------------------------------------------------------
echo "[9/9] Restoring and building..."
dotnet restore MyDesktopApplication.slnx
dotnet build MyDesktopApplication.slnx --no-restore

echo ""
echo "=============================================="
echo "  Fix Complete!"
echo "=============================================="
echo ""
echo "The following issues were fixed:"
echo "  • GameState: Added CurrentScore, HighScore, RecordAnswer(), Reset()"
echo "  • Country: Added Flag, PopulationDensity, LiteracyRate aliases"
echo "  • QuestionType: Added GetLabel(), GetValue(), FormatValue() extensions"
echo "  • IGameStateRepository: Fixed interface with userId parameter"
echo "  • GameStateRepository: Fixed implementation"
echo "  • Integration.Tests: Added Microsoft.EntityFrameworkCore.InMemory package"
echo "  • TodoRepositoryTests: Added proper using statements"
echo "  • GameStateTests: Rewrote to use correct properties"
echo "  • QuestionTypeTests: Fixed to use correct property names"
echo "  • Desktop Converters: Fixed QuestionType converter"
echo "  • MainWindowViewModel: Fixed nullable .Value calls"
echo ""
echo "Run tests with: dotnet test MyDesktopApplication.slnx"

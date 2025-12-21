#!/bin/bash
set -e

# =============================================================================
# fix-project-properly.sh - Comprehensive Project Fix Script
# =============================================================================
# This script:
# 1. Fixes the AppDbContext missing GameStates DbSet
# 2. Removes FluentAssertions and replaces with Shouldly
# 3. Consolidates to a single SLNX solution
# 4. Removes all silo scripts
# 5. Creates a proper migration script
# 6. Kills stuck build processes
# 7. Updates all package versions properly
# =============================================================================

echo "=============================================="
echo "  Comprehensive Project Fix Script"
echo "=============================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# -----------------------------------------------------------------------------
# Step 1: Kill stuck build processes
# -----------------------------------------------------------------------------
echo "[Step 1/9] Killing stuck build processes..."
pkill -f aapt2 2>/dev/null || true
pkill -f VBCSCompiler 2>/dev/null || true
pkill -f dotnet 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
sleep 2
echo "  ✓ Processes cleaned"

# -----------------------------------------------------------------------------
# Step 2: Clean build artifacts
# -----------------------------------------------------------------------------
echo "[Step 2/9] Cleaning build artifacts..."
rm -rf src/*/bin src/*/obj tests/*/bin tests/*/obj 2>/dev/null || true
rm -rf ~/.nuget/packages/mydesktopapplication* 2>/dev/null || true
echo "  ✓ Build artifacts cleaned"

# -----------------------------------------------------------------------------
# Step 3: Remove redundant solution files and scripts
# -----------------------------------------------------------------------------
echo "[Step 3/9] Removing redundant files and scripts..."

# Remove extra solution files
rm -f MyDesktopApplication.Desktop.slnx 2>/dev/null && echo "  Removed: MyDesktopApplication.Desktop.slnx"

# Remove all silo/fix scripts (keep only export.sh and this script)
scripts_to_remove=(
    "build-android.sh"
    "build-desktop.sh"
    "cleanup-and-rebuild.sh"
    "cleanup-and-standardize.sh"
    "cleanup-project.sh"
    "continue-setup.sh"
    "convert-to-country-quiz.sh"
    "fix-all.sh"
    "fix-android-build.sh"
    "fix-android-code.sh"
    "fix-android-font.sh"
    "fix-android-namespace.sh"
    "fix-android-theme.sh"
    "fix-android-theme-crash.sh"
    "fix-avalonia-version.sh"
    "fix-build-errors.sh"
    "fix-ci-and-add-android.sh"
    "fix-cpm.sh"
    "fix-tests.sh"
    "init-project.sh"
    "run-tests.sh"
    "setup.sh"
    "setup-all.sh"
    "setup-android-fedora.sh"
    "setup-github-actions.sh"
    "setup-project.sh"
    "update-github-actions.sh"
    "update-packages.sh"
)

for script in "${scripts_to_remove[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "  Removed: $script"
    fi
done

# Remove duplicate root appsettings.json (keep one in Desktop project)
rm -f appsettings.json 2>/dev/null && echo "  Removed: root appsettings.json (duplicate)"

echo "  ✓ Cleanup complete (export.sh preserved)"

# -----------------------------------------------------------------------------
# Step 4: Create unified solution file
# -----------------------------------------------------------------------------
echo "[Step 4/9] Creating unified solution file..."

cat > MyDesktopApplication.slnx << 'SLNX_EOF'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj" />
    <Project Path="src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <Project Path="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
    <Project Path="src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
    <Project Path="src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" />
  </Folder>
</Solution>
SLNX_EOF

echo "  ✓ Created unified MyDesktopApplication.slnx with all 8 projects"

# -----------------------------------------------------------------------------
# Step 5: Update Directory.Packages.props (remove FluentAssertions, add Shouldly)
# -----------------------------------------------------------------------------
echo "[Step 5/9] Updating Directory.Packages.props..."

cat > Directory.Packages.props << 'PACKAGES_EOF'
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
    <PackageVersion Include="Avalonia.Headless" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.0" />
  </ItemGroup>
  
  <ItemGroup Label="MVVM">
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
  </ItemGroup>
  
  <ItemGroup Label="EntityFramework">
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.0" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
    <PackageVersion Include="Dapper" Version="2.1.35" />
  </ItemGroup>
  
  <ItemGroup Label="Configuration">
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Json" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Binder" Version="10.0.0" />
  </ItemGroup>
  
  <ItemGroup Label="DependencyInjection">
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection.Abstractions" Version="10.0.0" />
  </ItemGroup>
  
  <ItemGroup Label="Logging">
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Abstractions" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Console" Version="10.0.0" />
    <PackageVersion Include="Serilog" Version="4.2.0" />
    <PackageVersion Include="Serilog.Extensions.Logging" Version="9.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="6.0.0" />
    <PackageVersion Include="Serilog.Sinks.File" Version="6.0.0" />
  </ItemGroup>
  
  <ItemGroup Label="OpenTelemetry">
    <PackageVersion Include="OpenTelemetry" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Instrumentation.Http" Version="1.11.0" />
  </ItemGroup>
  
  <ItemGroup Label="Validation">
    <PackageVersion Include="FluentValidation" Version="11.11.0" />
    <PackageVersion Include="FluentValidation.DependencyInjectionExtensions" Version="11.11.0" />
  </ItemGroup>
  
  <ItemGroup Label="Testing - All BSD/MIT Licensed (Free of Cost)">
    <!-- xUnit - Apache 2.0 License -->
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.5" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    
    <!-- Shouldly - BSD-3-Clause License (replaces FluentAssertions) -->
    <PackageVersion Include="Shouldly" Version="4.3.0" />
    
    <!-- NSubstitute - BSD-3-Clause License -->
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    
    <!-- Bogus - MIT License -->
    <PackageVersion Include="Bogus" Version="35.6.1" />
    
    <!-- Testcontainers - MIT License -->
    <PackageVersion Include="Testcontainers" Version="4.3.0" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.3.0" />
    
    <!-- Coverage -->
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
  </ItemGroup>
</Project>
PACKAGES_EOF

echo "  ✓ Updated Directory.Packages.props"
echo "    - Removed: FluentAssertions (commercial license v8+)"
echo "    - Added: Shouldly 4.3.0 (BSD-3-Clause, 100% free)"
echo "    - Pinned all Microsoft.Extensions.* to 10.0.0 (avoids downgrade errors)"

# -----------------------------------------------------------------------------
# Step 6: Fix AppDbContext - Add missing GameStates DbSet
# -----------------------------------------------------------------------------
echo "[Step 6/9] Fixing AppDbContext..."

mkdir -p src/MyDesktopApplication.Infrastructure/Data

cat > src/MyDesktopApplication.Infrastructure/Data/AppDbContext.cs << 'DBCONTEXT_EOF'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Infrastructure.Data;

/// <summary>
/// Application database context for Entity Framework Core
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    /// <summary>
    /// Design-time factory constructor for EF migrations
    /// </summary>
    public AppDbContext() : base(new DbContextOptionsBuilder<AppDbContext>()
        .UseSqlite("Data Source=app.db")
        .Options)
    {
    }

    public DbSet<TodoItem> TodoItems => Set<TodoItem>();
    public DbSet<GameState> GameStates => Set<GameState>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // TodoItem configuration
        modelBuilder.Entity<TodoItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Priority).HasDefaultValue(0);
            entity.HasIndex(e => e.IsCompleted);
            entity.HasIndex(e => e.DueDate);
        });

        // GameState configuration
        modelBuilder.Entity<GameState>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.UserId).IsRequired().HasMaxLength(100);
            entity.Property(e => e.CurrentScore).HasDefaultValue(0);
            entity.Property(e => e.HighScore).HasDefaultValue(0);
            entity.Property(e => e.CurrentStreak).HasDefaultValue(0);
            entity.Property(e => e.BestStreak).HasDefaultValue(0);
            entity.Property(e => e.TotalCorrect).HasDefaultValue(0);
            entity.Property(e => e.TotalAnswered).HasDefaultValue(0);
            entity.Property(e => e.SelectedQuestionType).HasDefaultValue(0);
            entity.HasIndex(e => e.UserId).IsUnique();
        });
    }
}
DBCONTEXT_EOF

echo "  ✓ Fixed AppDbContext with GameStates DbSet"

# -----------------------------------------------------------------------------
# Step 7: Ensure GameState entity exists in Core
# -----------------------------------------------------------------------------
echo "[Step 7/9] Ensuring all entities exist..."

mkdir -p src/MyDesktopApplication.Core/Entities

# Ensure EntityBase exists
cat > src/MyDesktopApplication.Core/Entities/EntityBase.cs << 'ENTITYBASE_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Base class for all entities with common properties
/// </summary>
public abstract class EntityBase
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
ENTITYBASE_EOF

# Ensure TodoItem exists with Priority
cat > src/MyDesktopApplication.Core/Entities/TodoItem.cs << 'TODOITEM_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Todo item domain entity
/// </summary>
public class TodoItem : EntityBase
{
    public required string Title { get; set; }
    public string? Description { get; set; }
    public int Priority { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? DueDate { get; set; }
    
    public void MarkComplete()
    {
        IsCompleted = true;
        CompletedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }
    
    public void MarkIncomplete()
    {
        IsCompleted = false;
        CompletedAt = null;
        UpdatedAt = DateTime.UtcNow;
    }
}
TODOITEM_EOF

# Ensure GameState exists
cat > src/MyDesktopApplication.Core/Entities/GameState.cs << 'GAMESTATE_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Game state for tracking quiz progress and scores
/// </summary>
public class GameState : EntityBase
{
    public required string UserId { get; set; }
    public int CurrentScore { get; set; }
    public int HighScore { get; set; }
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalAnswered { get; set; }
    public int SelectedQuestionType { get; set; }
    public DateTime? LastPlayedAt { get; set; }

    public void RecordCorrectAnswer()
    {
        CurrentScore++;
        CurrentStreak++;
        TotalCorrect++;
        TotalAnswered++;
        
        if (CurrentScore > HighScore)
            HighScore = CurrentScore;
        
        if (CurrentStreak > BestStreak)
            BestStreak = CurrentStreak;
        
        LastPlayedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void RecordWrongAnswer()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalAnswered++;
        LastPlayedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Reset()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        // Keep HighScore and BestStreak
        UpdatedAt = DateTime.UtcNow;
    }

    public double AccuracyPercentage => 
        TotalAnswered > 0 ? (double)TotalCorrect / TotalAnswered * 100 : 0;
}
GAMESTATE_EOF

# Ensure QuestionType exists
cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'QUESTIONTYPE_EOF'
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
QUESTIONTYPE_EOF

echo "  ✓ All entities created/verified"

# -----------------------------------------------------------------------------
# Step 8: Update test files to use Shouldly instead of FluentAssertions
# -----------------------------------------------------------------------------
echo "[Step 8/9] Updating test files to use Shouldly..."

# Update Core.Tests project file
cat > tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj << 'CORETESTS_CSPROJ_EOF'
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
    <PackageReference Include="xunit.runner.visualstudio" />
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Bogus" />
    <PackageReference Include="coverlet.collector" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
</Project>
CORETESTS_CSPROJ_EOF

# Update Integration.Tests project file
cat > tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj << 'INTTESTS_CSPROJ_EOF'
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
    <PackageReference Include="xunit.runner.visualstudio" />
    <PackageReference Include="Shouldly" />
    <PackageReference Include="Bogus" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
    <PackageReference Include="Testcontainers" />
    <PackageReference Include="Testcontainers.PostgreSql" />
    <PackageReference Include="coverlet.collector" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
</Project>
INTTESTS_CSPROJ_EOF

# Update UI.Tests project file
cat > tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj << 'UITESTS_CSPROJ_EOF'
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
    <PackageReference Include="xunit.runner.visualstudio" />
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Avalonia.Headless" />
    <PackageReference Include="Avalonia.Headless.XUnit" />
    <PackageReference Include="coverlet.collector" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Desktop\MyDesktopApplication.Desktop.csproj" />
    <ProjectReference Include="..\..\src\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
</Project>
UITESTS_CSPROJ_EOF

# Update TodoItemTests to use Shouldly
cat > tests/MyDesktopApplication.Core.Tests/TodoItemTests.cs << 'TODOITEM_TESTS_EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void TodoItem_ShouldInitialize_WithDefaults()
    {
        var item = new TodoItem { Title = "Test" };
        
        item.Id.ShouldNotBe(Guid.Empty);
        item.Title.ShouldBe("Test");
        item.IsCompleted.ShouldBeFalse();
        item.CompletedAt.ShouldBeNull();
        item.Priority.ShouldBe(0);
    }

    [Fact]
    public void MarkComplete_ShouldSetIsCompletedAndCompletedAt()
    {
        var item = new TodoItem { Title = "Test" };
        
        item.MarkComplete();
        
        item.IsCompleted.ShouldBeTrue();
        item.CompletedAt.ShouldNotBeNull();
        item.CompletedAt!.Value.ShouldBeGreaterThan(DateTime.UtcNow.AddSeconds(-5));
    }

    [Fact]
    public void MarkIncomplete_ShouldClearIsCompletedAndCompletedAt()
    {
        var item = new TodoItem { Title = "Test" };
        item.MarkComplete();
        
        item.MarkIncomplete();
        
        item.IsCompleted.ShouldBeFalse();
        item.CompletedAt.ShouldBeNull();
    }

    [Fact]
    public void Priority_ShouldBeSettable()
    {
        var item = new TodoItem { Title = "Test", Priority = 5 };
        
        item.Priority.ShouldBe(5);
    }
}
TODOITEM_TESTS_EOF

# Update GameStateTests to use Shouldly
cat > tests/MyDesktopApplication.Core.Tests/GameStateTests.cs << 'GAMESTATE_TESTS_EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;

namespace MyDesktopApplication.Core.Tests;

public class GameStateTests
{
    [Fact]
    public void RecordCorrectAnswer_ShouldIncrementScoresAndStreak()
    {
        var state = new GameState { UserId = "test" };
        
        state.RecordCorrectAnswer();
        
        state.CurrentScore.ShouldBe(1);
        state.HighScore.ShouldBe(1);
        state.CurrentStreak.ShouldBe(1);
        state.BestStreak.ShouldBe(1);
        state.TotalCorrect.ShouldBe(1);
        state.TotalAnswered.ShouldBe(1);
    }

    [Fact]
    public void RecordWrongAnswer_ShouldResetCurrentScoreAndStreak()
    {
        var state = new GameState { UserId = "test" };
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        
        state.RecordWrongAnswer();
        
        state.CurrentScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.HighScore.ShouldBe(2); // Should preserve high score
        state.BestStreak.ShouldBe(2); // Should preserve best streak
    }

    [Fact]
    public void Reset_ShouldKeepHighScoreAndBestStreak()
    {
        var state = new GameState { UserId = "test" };
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        
        state.Reset();
        
        state.CurrentScore.ShouldBe(0);
        state.CurrentStreak.ShouldBe(0);
        state.HighScore.ShouldBe(3);
        state.BestStreak.ShouldBe(3);
    }

    [Fact]
    public void AccuracyPercentage_ShouldCalculateCorrectly()
    {
        var state = new GameState { UserId = "test" };
        state.RecordCorrectAnswer();
        state.RecordCorrectAnswer();
        state.RecordWrongAnswer();
        state.RecordCorrectAnswer();
        
        state.AccuracyPercentage.ShouldBe(75.0);
    }
}
GAMESTATE_TESTS_EOF

# Update QuestionTypeTests to use Shouldly
cat > tests/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs << 'QUESTIONTYPE_TESTS_EOF'
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
QUESTIONTYPE_TESTS_EOF

echo "  ✓ Updated all test files to use Shouldly"

# -----------------------------------------------------------------------------
# Step 9: Create migration script
# -----------------------------------------------------------------------------
echo "[Step 9/9] Creating migration script..."

cat > migrate.sh << 'MIGRATE_EOF'
#!/bin/bash
set -e

# =============================================================================
# migrate.sh - Entity Framework Core Migration Helper
# =============================================================================
# Usage:
#   ./migrate.sh add <MigrationName>  - Add a new migration
#   ./migrate.sh update               - Apply pending migrations
#   ./migrate.sh remove               - Remove last migration
#   ./migrate.sh list                 - List all migrations
#   ./migrate.sh script               - Generate SQL script
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

INFRASTRUCTURE_PROJECT="src/MyDesktopApplication.Infrastructure"
STARTUP_PROJECT="src/MyDesktopApplication.Desktop"
MIGRATIONS_DIR="Data/Migrations"

# Ensure dotnet-ef is installed
if ! command -v dotnet-ef &> /dev/null; then
    echo "Installing dotnet-ef tool..."
    dotnet tool install --global dotnet-ef
fi

case "$1" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: ./migrate.sh add <MigrationName>"
            exit 1
        fi
        echo "Adding migration: $2"
        dotnet ef migrations add "$2" \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --output-dir "$MIGRATIONS_DIR"
        echo "✓ Migration '$2' created"
        ;;
    update)
        echo "Applying pending migrations..."
        dotnet ef database update \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        echo "✓ Database updated"
        ;;
    remove)
        echo "Removing last migration..."
        dotnet ef migrations remove \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        echo "✓ Last migration removed"
        ;;
    list)
        echo "Listing migrations..."
        dotnet ef migrations list \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        ;;
    script)
        echo "Generating SQL script..."
        dotnet ef migrations script \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --output "migrations.sql"
        echo "✓ SQL script saved to migrations.sql"
        ;;
    *)
        echo "Usage: ./migrate.sh <command>"
        echo ""
        echo "Commands:"
        echo "  add <name>  - Add a new migration"
        echo "  update      - Apply pending migrations"
        echo "  remove      - Remove last migration"
        echo "  list        - List all migrations"
        echo "  script      - Generate SQL script"
        ;;
esac
MIGRATE_EOF

chmod +x migrate.sh
echo "  ✓ Created migrate.sh"

# =============================================================================
# Final verification build
# =============================================================================
echo ""
echo "=============================================="
echo "  Building and Testing"
echo "=============================================="

echo "Restoring packages..."
dotnet restore MyDesktopApplication.slnx

echo ""
echo "Building solution..."
if dotnet build MyDesktopApplication.slnx --configuration Release --no-restore; then
    echo ""
    echo "✓ Build succeeded!"
    
    echo ""
    echo "Running tests..."
    if dotnet test MyDesktopApplication.slnx --configuration Release --no-build --verbosity minimal; then
        echo ""
        echo "✓ All tests passed!"
    else
        echo ""
        echo "⚠ Some tests failed - check output above"
    fi
else
    echo ""
    echo "✗ Build failed - check errors above"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Fix Complete!"
echo "=============================================="
echo ""
echo "Summary of changes:"
echo "  • Unified solution: MyDesktopApplication.slnx (8 projects)"
echo "  • Fixed AppDbContext with GameStates DbSet"
echo "  • Replaced FluentAssertions with Shouldly (BSD-3-Clause)"
echo "  • Removed all silo scripts (preserved in git history)"
echo "  • Created migrate.sh for EF Core migrations"
echo ""
echo "Next steps:"
echo "  1. Run: ./migrate.sh add InitialCreate"
echo "  2. Run: ./migrate.sh update"
echo "  3. Commit changes: git add -A && git commit -m 'Unify project structure'"
echo ""

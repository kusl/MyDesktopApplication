#!/bin/bash
# =============================================================================
# Fix Tests & Remove Non-Free Packages
# =============================================================================
# This script:
# 1. Removes FluentAssertions (no longer free - Xceed license)
# 2. Removes Moq (SponsorLink controversy)
# 3. Removes NSubstitute (not needed currently)
# 4. Fixes InMemoryDatabase issue - uses SQLite in-memory instead
# 5. Rewrites tests to use plain xUnit assertions
# =============================================================================

set -e

PROJECT_NAME="MyDesktopApplication"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "=============================================="
echo "  Removing Non-Free Packages & Fixing Tests"
echo "=============================================="
echo ""

# =============================================================================
# STEP 1: Update Directory.Packages.props - Remove problematic packages
# =============================================================================
log "Updating Directory.Packages.props..."

cat > Directory.Packages.props << 'ENDOFFILE'
<Project>
  <!-- Central Package Management - All package versions in one place -->
  <!-- ================================================================ -->
  <!-- LICENSE POLICY: Only packages with truly free licenses allowed   -->
  <!-- Allowed: MIT, Apache-2.0, BSD, Public Domain, PostgreSQL License -->
  <!-- NOT Allowed: Packages requiring payment for any use              -->
  <!-- ================================================================ -->
  <!-- Removed: FluentAssertions (Xceed license - requires payment)     -->
  <!-- Removed: Moq (SponsorLink controversy)                           -->
  <!-- ================================================================ -->
  
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup>
    <!-- Avalonia UI (MIT License) -->
    <PackageVersion Include="Avalonia" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.10" />
    <PackageVersion Include="Avalonia.ReactiveUI" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Headless" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.10" />

    <!-- MVVM (MIT License) -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
    <PackageVersion Include="ReactiveUI" Version="20.2.62" />

    <!-- Microsoft Extensions (MIT License) -->
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Hosting" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Json" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Console" Version="10.0.1" />

    <!-- Logging - Serilog (Apache-2.0 License) -->
    <PackageVersion Include="Serilog" Version="4.2.0" />
    <PackageVersion Include="Serilog.Extensions.Hosting" Version="9.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="6.0.0" />
    <PackageVersion Include="Serilog.Sinks.File" Version="6.0.0" />

    <!-- OpenTelemetry (Apache-2.0 License) -->
    <PackageVersion Include="OpenTelemetry" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.11.2" />

    <!-- Database (MIT / Public Domain / PostgreSQL License) -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.1" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
    <PackageVersion Include="Dapper" Version="2.1.66" />

    <!-- Validation (Apache-2.0 License) -->
    <PackageVersion Include="FluentValidation" Version="12.1.1" />
    <PackageVersion Include="FluentValidation.DependencyInjectionExtensions" Version="12.1.1" />

    <!-- Testing (MIT / Apache-2.0 License) -->
    <!-- Using plain xUnit assertions - no FluentAssertions (Xceed license) -->
    <!-- No Moq (SponsorLink controversy) - use NSubstitute if mocking needed -->
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="18.0.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.5" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
    <PackageVersion Include="Bogus" Version="35.6.5" />
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    <PackageVersion Include="Testcontainers" Version="4.9.0" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.9.0" />

    <!-- HTTP & Serialization (MIT License) -->
    <PackageVersion Include="System.Text.Json" Version="10.0.1" />
    <PackageVersion Include="Refit" Version="8.0.0" />
    <PackageVersion Include="Polly" Version="8.5.2" />
  </ItemGroup>
</Project>
ENDOFFILE

# =============================================================================
# STEP 2: Update test project files - Remove FluentAssertions
# =============================================================================
log "Updating test project files..."

# Core.Tests
cat > tests/$PROJECT_NAME.Core.Tests/$PROJECT_NAME.Core.Tests.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Test framework - xUnit with built-in assertions (MIT License) -->
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <!-- Test data generation (MIT License) -->
    <PackageReference Include="Bogus" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
</Project>
ENDOFFILE

# Integration.Tests
cat > tests/$PROJECT_NAME.Integration.Tests/$PROJECT_NAME.Integration.Tests.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Test framework (MIT License) -->
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <!-- Test data generation (MIT License) -->
    <PackageReference Include="Bogus" />
    <!-- Database - using SQLite for in-memory testing -->
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
    <!-- Testcontainers for realistic integration tests (MIT License) -->
    <PackageReference Include="Testcontainers" />
    <PackageReference Include="Testcontainers.PostgreSql" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\..\src\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
</Project>
ENDOFFILE

# UI.Tests
cat > tests/$PROJECT_NAME.UI.Tests/$PROJECT_NAME.UI.Tests.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <!-- Test framework (MIT License) -->
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <!-- Avalonia Headless for UI testing (MIT License) -->
    <PackageReference Include="Avalonia.Headless" />
    <PackageReference Include="Avalonia.Headless.XUnit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Desktop\MyDesktopApplication.Desktop.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
</Project>
ENDOFFILE

# =============================================================================
# STEP 3: Rewrite Core.Tests using plain xUnit assertions
# =============================================================================
log "Rewriting Core.Tests with xUnit assertions..."

cat > tests/$PROJECT_NAME.Core.Tests/TodoItemTests.cs << 'ENDOFFILE'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

/// <summary>
/// Unit tests for TodoItem entity using plain xUnit assertions.
/// No FluentAssertions - it requires payment for commercial use.
/// </summary>
public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_ShouldHaveDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem();

        // Assert using plain xUnit
        Assert.NotEqual(Guid.Empty, todo.Id);
        Assert.Equal(string.Empty, todo.Title);
        Assert.False(todo.IsCompleted);
        Assert.Equal(Priority.Normal, todo.Priority);
        Assert.Null(todo.Description);
        Assert.Null(todo.DueDate);
        
        // Check timestamp is recent (within 1 second)
        var timeDiff = DateTime.UtcNow - todo.CreatedAt;
        Assert.True(timeDiff.TotalSeconds < 1, "CreatedAt should be recent");
    }

    [Fact]
    public void MarkComplete_ShouldSetIsCompletedToTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };
        Assert.False(todo.IsCompleted);

        // Act
        todo.MarkComplete();

        // Assert
        Assert.True(todo.IsCompleted);
    }

    [Fact]
    public void MarkComplete_ShouldUpdateTimestamp()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test" };
        var originalUpdatedAt = todo.UpdatedAt;
        
        // Small delay to ensure timestamp changes
        System.Threading.Thread.Sleep(10);

        // Act
        todo.MarkComplete();

        // Assert
        Assert.True(todo.UpdatedAt >= originalUpdatedAt);
    }

    [Fact]
    public void MarkIncomplete_ShouldSetIsCompletedToFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test", IsCompleted = true };
        Assert.True(todo.IsCompleted);

        // Act
        todo.MarkIncomplete();

        // Assert
        Assert.False(todo.IsCompleted);
    }

    [Fact]
    public void IsOverdue_WhenPastDueDateAndNotCompleted_ShouldReturnTrue()
    {
        // Arrange
        var todo = new TodoItem
        {
            Title = "Overdue",
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = false
        };

        // Assert
        Assert.True(todo.IsOverdue);
    }

    [Fact]
    public void IsOverdue_WhenFutureDueDate_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem
        {
            Title = "Future",
            DueDate = DateTime.UtcNow.AddDays(1),
            IsCompleted = false
        };

        // Assert
        Assert.False(todo.IsOverdue);
    }

    [Fact]
    public void IsOverdue_WhenCompleted_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem
        {
            Title = "Done",
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = true
        };

        // Assert
        Assert.False(todo.IsOverdue);
    }

    [Fact]
    public void IsOverdue_WhenNoDueDate_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "No deadline", DueDate = null };

        // Assert
        Assert.False(todo.IsOverdue);
    }

    [Theory]
    [InlineData(Priority.Low)]
    [InlineData(Priority.Normal)]
    [InlineData(Priority.High)]
    [InlineData(Priority.Critical)]
    public void Priority_ShouldAcceptAllValues(Priority priority)
    {
        // Arrange & Act
        var todo = new TodoItem { Title = "Test", Priority = priority };

        // Assert
        Assert.Equal(priority, todo.Priority);
    }

    [Fact]
    public void Title_ShouldBeSettable()
    {
        // Arrange
        var todo = new TodoItem();

        // Act
        todo.Title = "My Task";

        // Assert
        Assert.Equal("My Task", todo.Title);
    }

    [Fact]
    public void Description_ShouldBeSettable()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test" };

        // Act
        todo.Description = "This is a description";

        // Assert
        Assert.Equal("This is a description", todo.Description);
    }
}
ENDOFFILE

# Remove old test file if exists
rm -f tests/$PROJECT_NAME.Core.Tests/UnitTest1.cs

# =============================================================================
# STEP 4: Rewrite Integration.Tests using SQLite in-memory
# =============================================================================
log "Rewriting Integration.Tests with SQLite in-memory..."

cat > tests/$PROJECT_NAME.Integration.Tests/TodoRepositoryTests.cs << 'ENDOFFILE'
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

namespace MyDesktopApplication.Integration.Tests;

/// <summary>
/// Integration tests for TodoRepository using SQLite in-memory database.
/// SQLite in-memory is more realistic than EF InMemory provider.
/// </summary>
public class TodoRepositoryTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AppDbContext _context;
    private readonly TodoRepository _repository;

    public TodoRepositoryTests()
    {
        // SQLite in-memory requires the connection to stay open
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new AppDbContext(options);
        _context.Database.EnsureCreated();
        
        _repository = new TodoRepository(_context);
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task AddAsync_ShouldPersistTodo()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        var result = await _repository.AddAsync(todo);

        // Assert
        Assert.NotEqual(Guid.Empty, result.Id);
        
        var saved = await _repository.GetByIdAsync(result.Id);
        Assert.NotNull(saved);
        Assert.Equal("Test Todo", saved.Title);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        // Act
        var result = await _repository.GetByIdAsync(Guid.NewGuid());

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnAllTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Todo 1" });
        await _repository.AddAsync(new TodoItem { Title = "Todo 2" });
        await _repository.AddAsync(new TodoItem { Title = "Todo 3" });

        // Act
        var result = await _repository.GetAllAsync();

        // Assert
        Assert.Equal(3, result.Count);
    }

    [Fact]
    public async Task GetCompletedAsync_ShouldReturnOnlyCompletedTodos()
    {
        // Arrange
        var completed = new TodoItem { Title = "Done", IsCompleted = true };
        var pending = new TodoItem { Title = "Pending", IsCompleted = false };
        await _repository.AddAsync(completed);
        await _repository.AddAsync(pending);

        // Act
        var result = await _repository.GetCompletedAsync();

        // Assert
        Assert.Single(result);
        Assert.Equal("Done", result[0].Title);
    }

    [Fact]
    public async Task GetPendingAsync_ShouldReturnOnlyPendingTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Done", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Pending 1", IsCompleted = false });
        await _repository.AddAsync(new TodoItem { Title = "Pending 2", IsCompleted = false });

        // Act
        var result = await _repository.GetPendingAsync();

        // Assert
        Assert.Equal(2, result.Count);
        Assert.All(result, todo => Assert.False(todo.IsCompleted));
    }

    [Fact]
    public async Task GetOverdueAsync_ShouldReturnOverdueTodos()
    {
        // Arrange
        var overdue = new TodoItem 
        { 
            Title = "Overdue", 
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = false 
        };
        var future = new TodoItem 
        { 
            Title = "Future", 
            DueDate = DateTime.UtcNow.AddDays(1),
            IsCompleted = false 
        };
        var completedOverdue = new TodoItem 
        { 
            Title = "Done", 
            DueDate = DateTime.UtcNow.AddDays(-1),
            IsCompleted = true 
        };
        
        await _repository.AddAsync(overdue);
        await _repository.AddAsync(future);
        await _repository.AddAsync(completedOverdue);

        // Act
        var result = await _repository.GetOverdueAsync();

        // Assert
        Assert.Single(result);
        Assert.Equal("Overdue", result[0].Title);
    }

    [Fact]
    public async Task UpdateAsync_ShouldModifyExistingTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "Original" });
        todo.Title = "Updated";

        // Act
        await _repository.UpdateAsync(todo);

        // Assert - get fresh from database
        var updated = await _repository.GetByIdAsync(todo.Id);
        Assert.NotNull(updated);
        Assert.Equal("Updated", updated.Title);
    }

    [Fact]
    public async Task DeleteAsync_ShouldRemoveTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "To Delete" });
        var id = todo.Id;

        // Act
        await _repository.DeleteAsync(todo);

        // Assert
        var deleted = await _repository.GetByIdAsync(id);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task ExistsAsync_WhenExists_ShouldReturnTrue()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "Exists" });

        // Act
        var exists = await _repository.ExistsAsync(todo.Id);

        // Assert
        Assert.True(exists);
    }

    [Fact]
    public async Task ExistsAsync_WhenNotExists_ShouldReturnFalse()
    {
        // Act
        var exists = await _repository.ExistsAsync(Guid.NewGuid());

        // Assert
        Assert.False(exists);
    }
}
ENDOFFILE

# Remove old test file if exists
rm -f tests/$PROJECT_NAME.Integration.Tests/UnitTest1.cs

# =============================================================================
# STEP 5: Rewrite UI.Tests using plain xUnit assertions
# =============================================================================
log "Rewriting UI.Tests with xUnit assertions..."

cat > tests/$PROJECT_NAME.UI.Tests/MainWindowViewModelTests.cs << 'ENDOFFILE'
using MyDesktopApplication.Desktop.ViewModels;

namespace MyDesktopApplication.UI.Tests;

/// <summary>
/// Unit tests for MainWindowViewModel using plain xUnit assertions.
/// </summary>
public class MainWindowViewModelTests
{
    [Fact]
    public void Constructor_ShouldSetDefaultValues()
    {
        // Act
        var viewModel = new MainWindowViewModel();

        // Assert
        Assert.Equal(0, viewModel.Counter);
        Assert.Contains("Welcome", viewModel.Greeting);
        Assert.False(viewModel.IsBusy);
        Assert.Null(viewModel.CurrentPage);
        Assert.Empty(viewModel.TodoItems);
    }

    [Fact]
    public void IncrementCounter_ShouldIncreaseCounterByOne()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();
        var initialCount = viewModel.Counter;

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        Assert.Equal(initialCount + 1, viewModel.Counter);
    }

    [Fact]
    public void IncrementCounter_FirstClick_ShouldUpdateGreeting()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        Assert.Equal("You clicked once!", viewModel.Greeting);
    }

    [Fact]
    public void IncrementCounter_MultipleClicks_ShouldUpdateGreetingCorrectly()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act - click 3 times
        viewModel.IncrementCounterCommand.Execute(null);
        viewModel.IncrementCounterCommand.Execute(null);
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        Assert.Equal(3, viewModel.Counter);
        Assert.Contains("3", viewModel.Greeting);
    }

    [Fact]
    public void IncrementCounter_TenClicks_ShouldShowAmazingMessage()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act - click 10 times
        for (int i = 0; i < 10; i++)
        {
            viewModel.IncrementCounterCommand.Execute(null);
        }

        // Assert
        Assert.Equal(10, viewModel.Counter);
        Assert.Contains("Amazing", viewModel.Greeting);
    }

    [Fact]
    public void NavigateToHome_ShouldSetCurrentPageToHomeViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();
        Assert.Null(viewModel.CurrentPage);

        // Act
        viewModel.NavigateToHomeCommand.Execute(null);

        // Assert
        Assert.NotNull(viewModel.CurrentPage);
        Assert.IsType<HomeViewModel>(viewModel.CurrentPage);
    }

    [Fact]
    public void NavigateToSettings_ShouldSetCurrentPageToSettingsViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToSettingsCommand.Execute(null);

        // Assert
        Assert.NotNull(viewModel.CurrentPage);
        Assert.IsType<SettingsViewModel>(viewModel.CurrentPage);
    }

    [Fact]
    public void NavigateToHome_ThenSettings_ShouldReplaceCurrentPage()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToHomeCommand.Execute(null);
        var homePage = viewModel.CurrentPage;
        
        viewModel.NavigateToSettingsCommand.Execute(null);

        // Assert
        Assert.NotNull(viewModel.CurrentPage);
        Assert.IsType<SettingsViewModel>(viewModel.CurrentPage);
        Assert.NotSame(homePage, viewModel.CurrentPage);
    }
}

public class HomeViewModelTests
{
    [Fact]
    public void Constructor_ShouldSetDefaultTitle()
    {
        // Act
        var viewModel = new HomeViewModel();

        // Assert
        Assert.Equal("Home", viewModel.Title);
    }
}

public class SettingsViewModelTests
{
    [Fact]
    public void Constructor_ShouldSetDefaultValues()
    {
        // Act
        var viewModel = new SettingsViewModel();

        // Assert
        Assert.Equal("Settings", viewModel.Title);
        Assert.False(viewModel.DarkMode);
    }

    [Fact]
    public void DarkMode_ShouldBeSettable()
    {
        // Arrange
        var viewModel = new SettingsViewModel();

        // Act
        viewModel.DarkMode = true;

        // Assert
        Assert.True(viewModel.DarkMode);
    }
}
ENDOFFILE

# Remove old test file if exists
rm -f tests/$PROJECT_NAME.UI.Tests/UnitTest1.cs

# =============================================================================
# STEP 6: Clean up NuGet caches to remove old packages
# =============================================================================
log "Cleaning build artifacts..."

# Clean solution
dotnet clean --verbosity quiet 2>/dev/null || true

# Remove bin/obj folders
find . -type d \( -name "bin" -o -name "obj" \) -exec rm -rf {} + 2>/dev/null || true

# =============================================================================
# STEP 7: Restore and build
# =============================================================================
echo ""
log "Running dotnet restore..."
dotnet restore

echo ""
log "Running dotnet build..."
if dotnet build; then
    echo ""
    log "Running dotnet test..."
    dotnet test
    
    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}All Fixes Applied Successfully!${NC}"
    echo "=============================================="
    echo ""
    echo "Changes made:"
    echo "  ✓ Removed FluentAssertions (Xceed license - requires payment)"
    echo "  ✓ Removed NSubstitute from test projects (kept in props if needed)"
    echo "  ✓ Fixed InMemoryDatabase error - now using SQLite in-memory"
    echo "  ✓ Rewrote all tests with plain xUnit assertions"
    echo ""
    echo "License policy:"
    echo "  ✓ All packages are now MIT, Apache-2.0, BSD, or Public Domain"
    echo "  ✓ No packages that require payment for any use"
    echo ""
else
    echo ""
    warn "Build failed - check errors above"
    exit 1
fi

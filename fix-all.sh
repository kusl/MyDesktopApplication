#!/bin/bash
# =============================================================================
# MyDesktopApplication - Complete Code Review Fixes
# =============================================================================
# Generated: Sat Dec 20 2025
# This script addresses all issues found in code review:
# 1. Adds proper project references to Desktop
# 2. Creates meaningful domain entities in Core
# 3. Adds repository pattern to Infrastructure  
# 4. Adds shared DTOs/services to Shared
# 5. Updates tests to actually test the code
# 6. Ensures all config files are in place
# 7. Removes unused ViewLocator
# =============================================================================

set -e

PROJECT_NAME="MyDesktopApplication"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "=============================================="
echo "  Code Review Fixes"
echo "=============================================="
echo ""

# =============================================================================
# FIX 1: Update Desktop .csproj to reference other projects
# =============================================================================
log "Updating Desktop project references..."

cat > src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
  </PropertyGroup>

  <ItemGroup>
    <AvaloniaResource Include="Assets\**" />
  </ItemGroup>

  <!-- Project References - Connect all layers -->
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
    <PackageReference Include="Avalonia.Diagnostics" Condition="'$(Configuration)' == 'Debug'" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
  </ItemGroup>

  <!-- Copy appsettings to output -->
  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
ENDOFFILE

# =============================================================================
# FIX 2: Create proper Core domain entities and interfaces
# =============================================================================
log "Creating Core domain entities..."

mkdir -p src/$PROJECT_NAME.Core/Entities
mkdir -p src/$PROJECT_NAME.Core/Interfaces

# Entity base class
cat > src/$PROJECT_NAME.Core/Entities/EntityBase.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Base class for all domain entities
/// </summary>
public abstract class EntityBase
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
ENDOFFILE

# TodoItem entity
cat > src/$PROJECT_NAME.Core/Entities/TodoItem.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a todo item in the application
/// </summary>
public class TodoItem : EntityBase
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? DueDate { get; set; }
    public Priority Priority { get; set; } = Priority.Normal;

    /// <summary>
    /// Marks the todo item as completed
    /// </summary>
    public void MarkComplete()
    {
        IsCompleted = true;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Marks the todo item as incomplete
    /// </summary>
    public void MarkIncomplete()
    {
        IsCompleted = false;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Returns true if the item is past its due date and not completed
    /// </summary>
    public bool IsOverdue => DueDate.HasValue && DueDate.Value < DateTime.UtcNow && !IsCompleted;
}

public enum Priority
{
    Low = 0,
    Normal = 1,
    High = 2,
    Critical = 3
}
ENDOFFILE

# Repository interface
cat > src/$PROJECT_NAME.Core/Interfaces/IRepository.cs << 'ENDOFFILE'
using System.Linq.Expressions;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// Generic repository interface for data access
/// </summary>
public interface IRepository<T> where T : EntityBase
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<T>> GetAllAsync(CancellationToken ct = default);
    Task<IReadOnlyList<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken ct = default);
    Task<T> AddAsync(T entity, CancellationToken ct = default);
    Task UpdateAsync(T entity, CancellationToken ct = default);
    Task DeleteAsync(T entity, CancellationToken ct = default);
    Task<bool> ExistsAsync(Guid id, CancellationToken ct = default);
}
ENDOFFILE

# TodoItem repository interface
cat > src/$PROJECT_NAME.Core/Interfaces/ITodoRepository.cs << 'ENDOFFILE'
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

/// <summary>
/// Repository interface specific to TodoItems
/// </summary>
public interface ITodoRepository : IRepository<TodoItem>
{
    Task<IReadOnlyList<TodoItem>> GetCompletedAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetPendingAsync(CancellationToken ct = default);
    Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default);
}
ENDOFFILE

# Remove old placeholder
rm -f src/$PROJECT_NAME.Core/Class1.cs

# =============================================================================
# FIX 3: Create Infrastructure with EF Core DbContext and Repository
# =============================================================================
log "Creating Infrastructure data access layer..."

mkdir -p src/$PROJECT_NAME.Infrastructure/Data
mkdir -p src/$PROJECT_NAME.Infrastructure/Repositories

# DbContext
cat > src/$PROJECT_NAME.Infrastructure/Data/AppDbContext.cs << 'ENDOFFILE'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Infrastructure.Data;

/// <summary>
/// Application database context
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<TodoItem> TodoItems => Set<TodoItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<TodoItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.HasIndex(e => e.IsCompleted);
            entity.HasIndex(e => e.DueDate);
        });
    }

    public override Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        foreach (var entry in ChangeTracker.Entries<EntityBase>())
        {
            if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = DateTime.UtcNow;
            }
        }
        return base.SaveChangesAsync(ct);
    }
}
ENDOFFILE

# Generic Repository implementation
cat > src/$PROJECT_NAME.Infrastructure/Repositories/Repository.cs << 'ENDOFFILE'
using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;

namespace MyDesktopApplication.Infrastructure.Repositories;

/// <summary>
/// Generic repository implementation using Entity Framework Core
/// </summary>
public class Repository<T> : IRepository<T> where T : EntityBase
{
    protected readonly AppDbContext Context;
    protected readonly DbSet<T> DbSet;

    public Repository(AppDbContext context)
    {
        Context = context;
        DbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await DbSet.FindAsync([id], ct);

    public virtual async Task<IReadOnlyList<T>> GetAllAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking().ToListAsync(ct);

    public virtual async Task<IReadOnlyList<T>> FindAsync(
        Expression<Func<T, bool>> predicate, CancellationToken ct = default)
        => await DbSet.AsNoTracking().Where(predicate).ToListAsync(ct);

    public virtual async Task<T> AddAsync(T entity, CancellationToken ct = default)
    {
        await DbSet.AddAsync(entity, ct);
        await Context.SaveChangesAsync(ct);
        return entity;
    }

    public virtual async Task UpdateAsync(T entity, CancellationToken ct = default)
    {
        DbSet.Update(entity);
        await Context.SaveChangesAsync(ct);
    }

    public virtual async Task DeleteAsync(T entity, CancellationToken ct = default)
    {
        DbSet.Remove(entity);
        await Context.SaveChangesAsync(ct);
    }

    public virtual async Task<bool> ExistsAsync(Guid id, CancellationToken ct = default)
        => await DbSet.AnyAsync(e => e.Id == id, ct);
}
ENDOFFILE

# TodoRepository implementation
cat > src/$PROJECT_NAME.Infrastructure/Repositories/TodoRepository.cs << 'ENDOFFILE'
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

    public async Task<IReadOnlyList<TodoItem>> GetOverdueAsync(CancellationToken ct = default)
        => await DbSet.AsNoTracking()
            .Where(t => !t.IsCompleted && t.DueDate != null && t.DueDate < DateTime.UtcNow)
            .OrderBy(t => t.DueDate)
            .ToListAsync(ct);
}
ENDOFFILE

# DI Extension
cat > src/$PROJECT_NAME.Infrastructure/DependencyInjection.cs << 'ENDOFFILE'
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

namespace MyDesktopApplication.Infrastructure;

/// <summary>
/// Dependency injection extensions for Infrastructure layer
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services, 
        string? connectionString = null)
    {
        // Use SQLite by default with a local file
        var dbPath = connectionString ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "MyDesktopApplication", "app.db");
        
        Directory.CreateDirectory(Path.GetDirectoryName(dbPath)!);

        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlite($"Data Source={dbPath}"));

        services.AddScoped<ITodoRepository, TodoRepository>();
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

        return services;
    }
}
ENDOFFILE

# Remove old placeholder
rm -f src/$PROJECT_NAME.Infrastructure/Class1.cs

# =============================================================================
# FIX 4: Update Shared with DTOs
# =============================================================================
log "Creating Shared DTOs..."

mkdir -p src/$PROJECT_NAME.Shared/DTOs

cat > src/$PROJECT_NAME.Shared/DTOs/TodoItemDto.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.DTOs;

/// <summary>
/// Data transfer object for TodoItem, used in ViewModels
/// </summary>
public partial class TodoItemDto : ObservableObject
{
    public Guid Id { get; set; }

    [ObservableProperty]
    private string _title = string.Empty;

    [ObservableProperty]
    private string? _description;

    [ObservableProperty]
    private bool _isCompleted;

    [ObservableProperty]
    private DateTime? _dueDate;

    [ObservableProperty]
    private int _priority;

    public bool IsOverdue => DueDate.HasValue && DueDate.Value < DateTime.UtcNow && !IsCompleted;
}
ENDOFFILE

# Remove old placeholder
rm -f src/$PROJECT_NAME.Shared/Class1.cs

# =============================================================================
# FIX 5: Update Desktop ViewModels with proper logic
# =============================================================================
log "Updating Desktop ViewModels..."

cat > src/$PROJECT_NAME.Desktop/ViewModels/ViewModelBase.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// Base class for all ViewModels
/// </summary>
public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;

    [ObservableProperty]
    private string? _errorMessage;

    protected void ClearError() => ErrorMessage = null;
    protected void SetError(string message) => ErrorMessage = message;
}
ENDOFFILE

cat > src/$PROJECT_NAME.Desktop/ViewModels/MainWindowViewModel.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using System.Collections.ObjectModel;

namespace MyDesktopApplication.Desktop.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    private readonly ITodoRepository? _todoRepository;

    [ObservableProperty]
    private string _greeting = "Welcome to Avalonia with .NET 10!";

    [ObservableProperty]
    private int _counter;

    [ObservableProperty]
    private ViewModelBase? _currentPage;

    [ObservableProperty]
    private ObservableCollection<TodoItem> _todoItems = [];

    [ObservableProperty]
    private string _newTodoTitle = string.Empty;

    // Constructor with DI (for runtime)
    public MainWindowViewModel(ITodoRepository todoRepository)
    {
        _todoRepository = todoRepository;
        _ = LoadTodosAsync();
    }

    // Parameterless constructor (for design-time and simple usage)
    public MainWindowViewModel()
    {
        _todoRepository = null;
    }

    [RelayCommand]
    private void IncrementCounter()
    {
        Counter++;
        Greeting = Counter switch
        {
            1 => "You clicked once!",
            < 5 => $"You clicked {Counter} times",
            < 10 => $"Wow, {Counter} clicks! Keep going!",
            _ => $"Amazing! {Counter} clicks!"
        };
    }

    [RelayCommand]
    private async Task LoadDataAsync()
    {
        IsBusy = true;
        ClearError();
        try
        {
            await LoadTodosAsync();
        }
        catch (Exception ex)
        {
            SetError($"Failed to load data: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private async Task AddTodoAsync()
    {
        if (string.IsNullOrWhiteSpace(NewTodoTitle) || _todoRepository is null)
            return;

        var todo = new TodoItem { Title = NewTodoTitle.Trim() };
        await _todoRepository.AddAsync(todo);
        TodoItems.Add(todo);
        NewTodoTitle = string.Empty;
    }

    [RelayCommand]
    private async Task ToggleTodoAsync(TodoItem? todo)
    {
        if (todo is null || _todoRepository is null)
            return;

        if (todo.IsCompleted)
            todo.MarkIncomplete();
        else
            todo.MarkComplete();

        await _todoRepository.UpdateAsync(todo);
    }

    [RelayCommand]
    private void NavigateToHome()
    {
        CurrentPage = new HomeViewModel();
    }

    [RelayCommand]
    private void NavigateToSettings()
    {
        CurrentPage = new SettingsViewModel();
    }

    private async Task LoadTodosAsync()
    {
        if (_todoRepository is null) return;
        
        var todos = await _todoRepository.GetAllAsync();
        TodoItems = new ObservableCollection<TodoItem>(todos);
    }
}

public partial class HomeViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _title = "Home";

    [ObservableProperty]
    private string _message = "Welcome to the home page!";
}

public partial class SettingsViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _title = "Settings";

    [ObservableProperty]
    private bool _darkMode;

    [ObservableProperty]
    private string _version = "1.0.0";
}
ENDOFFILE

# =============================================================================
# FIX 6: Update App.axaml.cs with proper DI setup
# =============================================================================
log "Updating App.axaml.cs with DI..."

cat > src/$PROJECT_NAME.Desktop/App.axaml.cs << 'ENDOFFILE'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Data.Core.Plugins;
using Avalonia.Markup.Xaml;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Desktop.ViewModels;
using MyDesktopApplication.Desktop.Views;
using MyDesktopApplication.Infrastructure;
using MyDesktopApplication.Infrastructure.Data;
using System;
using System.Linq;

namespace MyDesktopApplication.Desktop;

public partial class App : Application
{
    public static IServiceProvider? Services { get; private set; }

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            // Avoid duplicate validations from both Avalonia and CommunityToolkit
            DisableAvaloniaDataAnnotationValidation();

            // Setup dependency injection
            var services = new ServiceCollection();
            ConfigureServices(services);
            Services = services.BuildServiceProvider();

            // Initialize database
            InitializeDatabase();

            // Create main window
            var mainViewModel = Services.GetRequiredService<MainWindowViewModel>();
            desktop.MainWindow = new MainWindow
            {
                DataContext = mainViewModel
            };
        }

        base.OnFrameworkInitializationCompleted();
    }

    private static void ConfigureServices(IServiceCollection services)
    {
        // Add infrastructure (database, repositories)
        services.AddInfrastructure();

        // Add ViewModels
        services.AddTransient<MainWindowViewModel>();
        services.AddTransient<HomeViewModel>();
        services.AddTransient<SettingsViewModel>();
    }

    private static void InitializeDatabase()
    {
        using var scope = Services!.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        context.Database.EnsureCreated();
    }

    private static void DisableAvaloniaDataAnnotationValidation()
    {
        var toRemove = BindingPlugins.DataValidators
            .OfType<DataAnnotationsValidationPlugin>()
            .ToArray();

        foreach (var plugin in toRemove)
        {
            BindingPlugins.DataValidators.Remove(plugin);
        }
    }
}
ENDOFFILE

# =============================================================================
# FIX 7: Create App.axaml (in case it's missing)
# =============================================================================
log "Ensuring App.axaml exists..."

cat > src/$PROJECT_NAME.Desktop/App.axaml << 'ENDOFFILE'
<Application xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Desktop.App"
             RequestedThemeVariant="Default">
    <Application.Styles>
        <FluentTheme />
    </Application.Styles>
</Application>
ENDOFFILE

# =============================================================================
# FIX 8: Update MainWindow.axaml with todo list
# =============================================================================
log "Updating MainWindow.axaml..."

cat > src/$PROJECT_NAME.Desktop/Views/MainWindow.axaml << 'ENDOFFILE'
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyDesktopApplication.Desktop.ViewModels"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d" d:DesignWidth="800" d:DesignHeight="600"
        x:Class="MyDesktopApplication.Desktop.Views.MainWindow"
        x:DataType="vm:MainWindowViewModel"
        Title="MyDesktopApplication"
        Width="900" Height="650"
        MinWidth="600" MinHeight="400"
        WindowStartupLocation="CenterScreen">

    <Design.DataContext>
        <vm:MainWindowViewModel/>
    </Design.DataContext>

    <Grid RowDefinitions="Auto,*,Auto">
        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D4" Padding="20,15">
            <Grid ColumnDefinitions="*,Auto">
                <TextBlock Text="MyDesktopApplication" 
                           FontSize="24" FontWeight="Bold" Foreground="White"/>
                <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="10">
                    <Button Content="Home" Command="{Binding NavigateToHomeCommand}"/>
                    <Button Content="Settings" Command="{Binding NavigateToSettingsCommand}"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Main Content -->
        <ScrollViewer Grid.Row="1" Padding="30">
            <StackPanel Spacing="20" MaxWidth="600" HorizontalAlignment="Center">
                
                <!-- Greeting & Counter -->
                <TextBlock Text="{Binding Greeting}" FontSize="24" FontWeight="SemiBold"
                           HorizontalAlignment="Center"/>
                <TextBlock Text="{Binding Counter, StringFormat='Counter: {0}'}" 
                           FontSize="16" HorizontalAlignment="Center" Foreground="#0078D4"/>
                
                <StackPanel Orientation="Horizontal" Spacing="10" HorizontalAlignment="Center">
                    <Button Content="Click Me!" Command="{Binding IncrementCounterCommand}"
                            Classes="accent" Padding="15,8"/>
                    <Button Content="Refresh" Command="{Binding LoadDataCommand}"
                            IsEnabled="{Binding !IsBusy}" Padding="15,8"/>
                </StackPanel>

                <ProgressBar IsIndeterminate="True" IsVisible="{Binding IsBusy}" Width="200"/>

                <!-- Error Message -->
                <TextBlock Text="{Binding ErrorMessage}" Foreground="Red" 
                           IsVisible="{Binding ErrorMessage, Converter={x:Static StringConverters.IsNotNullOrEmpty}}"
                           HorizontalAlignment="Center"/>

                <Separator Margin="0,10"/>

                <!-- Todo Section -->
                <TextBlock Text="Todo List" FontSize="18" FontWeight="SemiBold"/>
                
                <!-- Add Todo -->
                <Grid ColumnDefinitions="*,Auto">
                    <TextBox Grid.Column="0" Text="{Binding NewTodoTitle}" 
                             Watermark="Enter a new todo..." Margin="0,0,10,0"/>
                    <Button Grid.Column="1" Content="Add" Command="{Binding AddTodoCommand}"
                            IsEnabled="{Binding NewTodoTitle, Converter={x:Static StringConverters.IsNotNullOrEmpty}}"/>
                </Grid>

                <!-- Todo List -->
                <ItemsControl ItemsSource="{Binding TodoItems}">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Margin="0,5" Padding="10" CornerRadius="4"
                                    Background="{DynamicResource SystemControlBackgroundAltHighBrush}">
                                <Grid ColumnDefinitions="Auto,*">
                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsCompleted}"
                                              Command="{Binding $parent[Window].((vm:MainWindowViewModel)DataContext).ToggleTodoCommand}"
                                              CommandParameter="{Binding}"/>
                                    <TextBlock Grid.Column="1" Text="{Binding Title}" 
                                               VerticalAlignment="Center" Margin="10,0,0,0"
                                               TextDecorations="{Binding IsCompleted, Converter={StaticResource BoolToStrikethrough}}"/>
                                </Grid>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>

                <!-- Current Page -->
                <ContentControl Content="{Binding CurrentPage}" Margin="0,20,0,0"/>
            </StackPanel>
        </ScrollViewer>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#F0F0F0" Padding="15,10">
            <Grid ColumnDefinitions="*,Auto">
                <TextBlock Text="Built with Avalonia UI + .NET 10" Opacity="0.6" FontSize="12"/>
                <TextBlock Grid.Column="1" Text="{Binding Counter, StringFormat='Clicks: {0}'}" 
                           Opacity="0.6" FontSize="12"/>
            </Grid>
        </Border>
    </Grid>

    <Window.Resources>
        <ResourceDictionary>
            <!-- Converter for strikethrough text on completed todos -->
            <Binding x:Key="BoolToStrikethrough" Path="." 
                     Converter="{x:Static BoolConverters.Or}"
                     ConverterParameter="Strikethrough"/>
        </ResourceDictionary>
    </Window.Resources>
</Window>
ENDOFFILE

# Simplified MainWindow without strikethrough converter (simpler)
cat > src/$PROJECT_NAME.Desktop/Views/MainWindow.axaml << 'ENDOFFILE'
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyDesktopApplication.Desktop.ViewModels"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d" d:DesignWidth="800" d:DesignHeight="600"
        x:Class="MyDesktopApplication.Desktop.Views.MainWindow"
        x:DataType="vm:MainWindowViewModel"
        Title="MyDesktopApplication"
        Width="900" Height="650"
        MinWidth="600" MinHeight="400"
        WindowStartupLocation="CenterScreen">

    <Design.DataContext>
        <vm:MainWindowViewModel/>
    </Design.DataContext>

    <Grid RowDefinitions="Auto,*,Auto">
        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D4" Padding="20,15">
            <Grid ColumnDefinitions="*,Auto">
                <TextBlock Text="MyDesktopApplication" 
                           FontSize="24" FontWeight="Bold" Foreground="White"/>
                <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="10">
                    <Button Content="Home" Command="{Binding NavigateToHomeCommand}"/>
                    <Button Content="Settings" Command="{Binding NavigateToSettingsCommand}"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Main Content -->
        <ScrollViewer Grid.Row="1" Padding="30">
            <StackPanel Spacing="20" MaxWidth="600" HorizontalAlignment="Center">
                
                <!-- Greeting & Counter -->
                <TextBlock Text="{Binding Greeting}" FontSize="24" FontWeight="SemiBold"
                           HorizontalAlignment="Center"/>
                <TextBlock Text="{Binding Counter, StringFormat='Counter: {0}'}" 
                           FontSize="16" HorizontalAlignment="Center" Foreground="#0078D4"/>
                
                <StackPanel Orientation="Horizontal" Spacing="10" HorizontalAlignment="Center">
                    <Button Content="Click Me!" Command="{Binding IncrementCounterCommand}"
                            Classes="accent" Padding="15,8"/>
                    <Button Content="Refresh" Command="{Binding LoadDataCommand}"
                            IsEnabled="{Binding !IsBusy}" Padding="15,8"/>
                </StackPanel>

                <ProgressBar IsIndeterminate="True" IsVisible="{Binding IsBusy}" Width="200"/>

                <Separator Margin="0,10"/>

                <!-- Todo Section -->
                <TextBlock Text="Todo List" FontSize="18" FontWeight="SemiBold"/>
                
                <!-- Add Todo -->
                <Grid ColumnDefinitions="*,Auto">
                    <TextBox Grid.Column="0" Text="{Binding NewTodoTitle}" 
                             Watermark="Enter a new todo..." Margin="0,0,10,0"/>
                    <Button Grid.Column="1" Content="Add" Command="{Binding AddTodoCommand}"/>
                </Grid>

                <!-- Todo List -->
                <ItemsControl ItemsSource="{Binding TodoItems}">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Margin="0,5" Padding="10" CornerRadius="4" Background="#F5F5F5">
                                <Grid ColumnDefinitions="Auto,*">
                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsCompleted}"/>
                                    <TextBlock Grid.Column="1" Text="{Binding Title}" 
                                               VerticalAlignment="Center" Margin="10,0,0,0"/>
                                </Grid>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>

                <!-- Current Page -->
                <ContentControl Content="{Binding CurrentPage}" Margin="0,20,0,0"/>
            </StackPanel>
        </ScrollViewer>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#F0F0F0" Padding="15,10">
            <Grid ColumnDefinitions="*,Auto">
                <TextBlock Text="Built with Avalonia UI + .NET 10" Opacity="0.6" FontSize="12"/>
                <TextBlock Grid.Column="1" Text="{Binding Counter, StringFormat='Clicks: {0}'}" 
                           Opacity="0.6" FontSize="12"/>
            </Grid>
        </Border>
    </Grid>
</Window>
ENDOFFILE

# =============================================================================
# FIX 9: Remove unused ViewLocator
# =============================================================================
log "Removing unused ViewLocator..."
rm -f src/$PROJECT_NAME.Desktop/ViewLocator.cs

# =============================================================================
# FIX 10: Update tests to actually test the code
# =============================================================================
log "Updating unit tests..."

cat > tests/$PROJECT_NAME.Core.Tests/UnitTest1.cs << 'ENDOFFILE'
using FluentAssertions;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void NewTodoItem_ShouldHaveDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem();

        // Assert
        todo.Id.Should().NotBeEmpty();
        todo.Title.Should().BeEmpty();
        todo.IsCompleted.Should().BeFalse();
        todo.Priority.Should().Be(Priority.Normal);
        todo.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void MarkComplete_ShouldSetIsCompletedToTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        todo.MarkComplete();

        // Assert
        todo.IsCompleted.Should().BeTrue();
        todo.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void MarkIncomplete_ShouldSetIsCompletedToFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test", IsCompleted = true };

        // Act
        todo.MarkIncomplete();

        // Assert
        todo.IsCompleted.Should().BeFalse();
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
        todo.IsOverdue.Should().BeTrue();
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
        todo.IsOverdue.Should().BeFalse();
    }

    [Fact]
    public void IsOverdue_WhenNoDueDate_ShouldReturnFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "No deadline" };

        // Assert
        todo.IsOverdue.Should().BeFalse();
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
        todo.Priority.Should().Be(priority);
    }
}
ENDOFFILE

log "Updating integration tests..."

cat > tests/$PROJECT_NAME.Integration.Tests/UnitTest1.cs << 'ENDOFFILE'
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

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
    public async Task AddAsync_ShouldPersistTodo()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };

        // Act
        var result = await _repository.AddAsync(todo);

        // Assert
        result.Id.Should().NotBeEmpty();
        var saved = await _repository.GetByIdAsync(result.Id);
        saved.Should().NotBeNull();
        saved!.Title.Should().Be("Test Todo");
    }

    [Fact]
    public async Task GetCompletedAsync_ShouldReturnOnlyCompletedTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Done", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Pending", IsCompleted = false });

        // Act
        var completed = await _repository.GetCompletedAsync();

        // Assert
        completed.Should().HaveCount(1);
        completed[0].Title.Should().Be("Done");
    }

    [Fact]
    public async Task GetPendingAsync_ShouldReturnOnlyPendingTodos()
    {
        // Arrange
        await _repository.AddAsync(new TodoItem { Title = "Done", IsCompleted = true });
        await _repository.AddAsync(new TodoItem { Title = "Pending", IsCompleted = false });

        // Act
        var pending = await _repository.GetPendingAsync();

        // Assert
        pending.Should().HaveCount(1);
        pending[0].Title.Should().Be("Pending");
    }

    [Fact]
    public async Task UpdateAsync_ShouldModifyExistingTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "Original" });
        todo.Title = "Updated";

        // Act
        await _repository.UpdateAsync(todo);

        // Assert
        var updated = await _repository.GetByIdAsync(todo.Id);
        updated!.Title.Should().Be("Updated");
    }

    [Fact]
    public async Task DeleteAsync_ShouldRemoveTodo()
    {
        // Arrange
        var todo = await _repository.AddAsync(new TodoItem { Title = "To Delete" });

        // Act
        await _repository.DeleteAsync(todo);

        // Assert
        var deleted = await _repository.GetByIdAsync(todo.Id);
        deleted.Should().BeNull();
    }
}
ENDOFFILE

log "Updating UI tests..."

cat > tests/$PROJECT_NAME.UI.Tests/UnitTest1.cs << 'ENDOFFILE'
using FluentAssertions;
using MyDesktopApplication.Desktop.ViewModels;

namespace MyDesktopApplication.UI.Tests;

public class MainWindowViewModelTests
{
    [Fact]
    public void IncrementCounter_ShouldIncreaseCounterByOne()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();
        var initialCount = viewModel.Counter;

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        viewModel.Counter.Should().Be(initialCount + 1);
    }

    [Fact]
    public void IncrementCounter_ShouldUpdateGreeting()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        viewModel.Greeting.Should().Be("You clicked once!");
    }

    [Fact]
    public void IncrementCounter_MultipleTimes_ShouldUpdateGreetingCorrectly()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        for (int i = 0; i < 5; i++)
            viewModel.IncrementCounterCommand.Execute(null);

        // Assert
        viewModel.Counter.Should().Be(5);
        viewModel.Greeting.Should().Contain("5");
    }

    [Fact]
    public void NavigateToHome_ShouldSetCurrentPageToHomeViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToHomeCommand.Execute(null);

        // Assert
        viewModel.CurrentPage.Should().BeOfType<HomeViewModel>();
    }

    [Fact]
    public void NavigateToSettings_ShouldSetCurrentPageToSettingsViewModel()
    {
        // Arrange
        var viewModel = new MainWindowViewModel();

        // Act
        viewModel.NavigateToSettingsCommand.Execute(null);

        // Assert
        viewModel.CurrentPage.Should().BeOfType<SettingsViewModel>();
    }

    [Fact]
    public void NewViewModel_ShouldHaveDefaultValues()
    {
        // Act
        var viewModel = new MainWindowViewModel();

        // Assert
        viewModel.Counter.Should().Be(0);
        viewModel.Greeting.Should().Contain("Welcome");
        viewModel.IsBusy.Should().BeFalse();
        viewModel.CurrentPage.Should().BeNull();
    }
}
ENDOFFILE

# =============================================================================
# FIX 11: Update appsettings.json location
# =============================================================================
log "Creating appsettings.json in Desktop project..."

cat > src/$PROJECT_NAME.Desktop/appsettings.json << 'ENDOFFILE'
{
  "Application": {
    "Name": "MyDesktopApplication",
    "Version": "1.0.0"
  },
  "Database": {
    "Provider": "SQLite"
  },
  "Logging": {
    "Level": "Information"
  }
}
ENDOFFILE

# =============================================================================
# FIX 12: Update export script to include .axaml files
# =============================================================================
log "Updating export script..."

cat > export.sh << 'ENDOFFILE'
#!/bin/bash
# Export project files for LLM analysis
# Includes: .cs, .csproj, .axaml, .json, .props, .slnx

OUTPUT_DIR="docs/llm"
OUTPUT_FILE="$OUTPUT_DIR/dump.txt"
PROJECT_PATH="$(pwd)"

echo "Starting project export..."
echo "Project Path: $PROJECT_PATH"
echo "Output File: $OUTPUT_FILE"

mkdir -p "$OUTPUT_DIR"

{
    echo "==============================================================================="
    echo "PROJECT EXPORT"
    echo "Generated: $(date)"
    echo "Project Path: $PROJECT_PATH"
    echo "==============================================================================="
    echo ""
    echo "DIRECTORY STRUCTURE:"
    echo "==================="
    echo ""
    tree -I 'bin|obj|.git|.vs|.idea|TestResults' --noreport 2>/dev/null || find . -type f \( -name "*.cs" -o -name "*.csproj" -o -name "*.axaml" -o -name "*.json" -o -name "*.props" -o -name "*.slnx" \) | grep -v -E "(bin|obj|\.git)" | sort
    echo ""
    echo ""
    echo "FILE CONTENTS:"
    echo "=============="
    echo ""
} > "$OUTPUT_FILE"

# Find all relevant files (including .axaml!)
FILES=$(find . -type f \( \
    -name "*.cs" -o \
    -name "*.csproj" -o \
    -name "*.axaml" -o \
    -name "*.json" -o \
    -name "*.props" -o \
    -name "*.slnx" -o \
    -name "*.md" \
    \) ! -path "*/bin/*" ! -path "*/obj/*" ! -path "*/.git/*" ! -path "*/.vs/*" | sort)

FILE_COUNT=$(echo "$FILES" | wc -l)
echo "Generating directory structure..."
echo "Collecting files..."
echo "Found $FILE_COUNT files to export"

COUNTER=0
for file in $FILES; do
    COUNTER=$((COUNTER + 1))
    FILENAME="${file#./}"
    FILESIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
    MODIFIED=$(stat -c%y "$file" 2>/dev/null | cut -d'.' -f1 || stat -f"%Sm" "$file" 2>/dev/null)
    
    echo "Processing ($COUNTER/$FILE_COUNT): $FILENAME"
    
    {
        echo "================================================================================"
        echo "FILE: $FILENAME"
        echo "SIZE: $(echo "scale=2; $FILESIZE/1024" | bc) KB"
        echo "MODIFIED: $MODIFIED"
        echo "================================================================================"
        echo ""
        cat "$file"
        echo ""
        echo ""
    } >> "$OUTPUT_FILE"
done

{
    echo "==============================================================================="
    echo "EXPORT COMPLETED: $(date)"
    echo "Total Files Exported: $FILE_COUNT"
    echo "Output File: $PROJECT_PATH/$OUTPUT_FILE"
    echo "==============================================================================="
} >> "$OUTPUT_FILE"

echo ""
echo "Export completed successfully!"
echo "Output file: $PROJECT_PATH/$OUTPUT_FILE"
echo "Total files exported: $FILE_COUNT"
FILESIZE=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null)
echo "Output file size: $(echo "scale=2; $FILESIZE/1048576" | bc) MB"
ENDOFFILE

chmod +x export.sh

# =============================================================================
# FINAL: Build and test
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
    echo "  ✓ Added project references to Desktop"
    echo "  ✓ Created Core entities (TodoItem, EntityBase)"
    echo "  ✓ Created Core interfaces (IRepository, ITodoRepository)"
    echo "  ✓ Created Infrastructure (DbContext, Repositories)"
    echo "  ✓ Created Shared DTOs"
    echo "  ✓ Updated ViewModels with todo functionality"
    echo "  ✓ Updated MainWindow.axaml with todo list UI"
    echo "  ✓ Added dependency injection setup"
    echo "  ✓ Updated tests with real assertions"
    echo "  ✓ Removed unused ViewLocator"
    echo "  ✓ Fixed export script to include .axaml files"
    echo ""
    echo "Run the app: dotnet run --project src/$PROJECT_NAME.Desktop"
else
    echo ""
    warn "Build failed - check errors above"
fi

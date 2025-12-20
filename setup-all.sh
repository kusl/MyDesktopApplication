#!/bin/bash
# =============================================================================
# MyDesktopApplication - COMPLETE Setup Script (All Files)
# =============================================================================
# This script creates/updates ALL configuration AND source files.
# Run from: ~/src/dotnet/MyDesktopApplication/
# =============================================================================

set -e

PROJECT_NAME="MyDesktopApplication"

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}✓${NC} $1"; }

echo "=============================================="
echo "  $PROJECT_NAME - Full Setup"
echo "=============================================="

# =============================================================================
# PART 1: Build Configuration Files
# =============================================================================

log "Creating Directory.Build.props..."
cat > Directory.Build.props << 'ENDOFFILE'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsAsErrors />
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <AnalysisLevel>latest</AnalysisLevel>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <PropertyGroup>
    <Company>YourCompanyName</Company>
    <Authors>Your Name</Authors>
    <Copyright>Copyright © $([System.DateTime]::Now.Year)</Copyright>
    <VersionPrefix>1.0.0</VersionPrefix>
    <VersionSuffix Condition="'$(Configuration)' == 'Debug'">dev</VersionSuffix>
    <RepositoryType>git</RepositoryType>
  </PropertyGroup>
  <PropertyGroup>
    <Deterministic>true</Deterministic>
    <ContinuousIntegrationBuild Condition="'$(CI)' == 'true'">true</ContinuousIntegrationBuild>
  </PropertyGroup>
  <PropertyGroup Condition="$(MSBuildProjectName.EndsWith('.Tests'))">
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
</Project>
ENDOFFILE

log "Creating Directory.Packages.props..."
cat > Directory.Packages.props << 'ENDOFFILE'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>
  <ItemGroup>
    <!-- Avalonia UI (MIT License) -->
    <PackageVersion Include="Avalonia" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.0" />
    <PackageVersion Include="Avalonia.ReactiveUI" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.0" />
    <!-- MVVM (MIT License) -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
    <PackageVersion Include="ReactiveUI" Version="20.2.62" />
    <!-- Microsoft Extensions (MIT License) -->
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Hosting" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Json" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Console" Version="10.0.0" />
    <!-- Logging - Serilog (Apache-2.0) -->
    <PackageVersion Include="Serilog" Version="4.2.0" />
    <PackageVersion Include="Serilog.Extensions.Hosting" Version="9.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="6.0.0" />
    <PackageVersion Include="Serilog.Sinks.File" Version="6.0.0" />
    <!-- OpenTelemetry (Apache-2.0) -->
    <PackageVersion Include="OpenTelemetry" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.11.2" />
    <!-- Database -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.0" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
    <PackageVersion Include="Dapper" Version="2.1.66" />
    <!-- Validation -->
    <PackageVersion Include="FluentValidation" Version="11.11.0" />
    <PackageVersion Include="FluentValidation.DependencyInjectionExtensions" Version="11.11.0" />
    <!-- Testing -->
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.4" />
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    <PackageVersion Include="FluentAssertions" Version="8.0.1" />
    <PackageVersion Include="Bogus" Version="35.6.1" />
    <PackageVersion Include="Testcontainers" Version="4.3.0" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.3.0" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
    <!-- HTTP & Serialization -->
    <PackageVersion Include="System.Text.Json" Version="10.0.0" />
    <PackageVersion Include="Refit" Version="8.0.0" />
    <PackageVersion Include="Polly" Version="8.5.2" />
  </ItemGroup>
</Project>
ENDOFFILE

# =============================================================================
# PART 2: Project Files (.csproj)
# =============================================================================

log "Updating src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj..."
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
    <Folder Include="Models\" />
    <AvaloniaResource Include="Assets\**" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Desktop" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="Avalonia.Diagnostics" Condition="'$(Configuration)' == 'Debug'" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
  </ItemGroup>
</Project>
ENDOFFILE

log "Updating src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj..."
cat > src/$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="FluentValidation" />
  </ItemGroup>
</Project>
ENDOFFILE

log "Updating src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj..."
cat > src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" />
    <PackageReference Include="Dapper" />
    <PackageReference Include="Microsoft.Extensions.Configuration" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
ENDOFFILE

log "Updating src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj..."
cat > src/$PROJECT_NAME.Shared/$PROJECT_NAME.Shared.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="CommunityToolkit.Mvvm" />
  </ItemGroup>
</Project>
ENDOFFILE

log "Updating tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj..."
cat > tests/$PROJECT_NAME.Core.Tests/$PROJECT_NAME.Core.Tests.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
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
    <PackageReference Include="FluentAssertions" />
    <PackageReference Include="NSubstitute" />
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

log "Updating tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj..."
cat > tests/$PROJECT_NAME.Integration.Tests/$PROJECT_NAME.Integration.Tests.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
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
    <PackageReference Include="FluentAssertions" />
    <PackageReference Include="Bogus" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
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

log "Updating tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj..."
cat > tests/$PROJECT_NAME.UI.Tests/$PROJECT_NAME.UI.Tests.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
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
    <PackageReference Include="FluentAssertions" />
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
# PART 3: Desktop Source Files
# =============================================================================

log "Updating src/MyDesktopApplication.Desktop/ViewModels/ViewModelBase.cs..."
cat > src/$PROJECT_NAME.Desktop/ViewModels/ViewModelBase.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Desktop.ViewModels;

public abstract class ViewModelBase : ObservableObject
{
}
ENDOFFILE

log "Updating src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs..."
cat > src/$PROJECT_NAME.Desktop/ViewModels/MainWindowViewModel.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Threading.Tasks;

namespace MyDesktopApplication.Desktop.ViewModels;

public partial class MainWindowViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _greeting = "Welcome to Avalonia with .NET 10!";

    [ObservableProperty]
    private int _counter;

    [ObservableProperty]
    private bool _isBusy;

    [ObservableProperty]
    private ViewModelBase? _currentPage;

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
        // Simulate loading data
        await Task.Delay(1000);
        IsBusy = false;
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
}

public partial class HomeViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _title = "Home";
}

public partial class SettingsViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _title = "Settings";

    [ObservableProperty]
    private bool _darkMode;
}
ENDOFFILE

log "Updating src/MyDesktopApplication.Desktop/Views/MainWindow.axaml..."
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
        <Border Grid.Row="0" 
                Background="{DynamicResource SystemAccentColorLight2}" 
                Padding="20,15">
            <Grid ColumnDefinitions="*,Auto">
                <TextBlock Text="MyDesktopApplication" 
                           FontSize="24" 
                           FontWeight="Bold"
                           Foreground="White"/>
                <StackPanel Grid.Column="1" 
                            Orientation="Horizontal" 
                            Spacing="10">
                    <Button Content="Home" 
                            Command="{Binding NavigateToHomeCommand}"/>
                    <Button Content="Settings" 
                            Command="{Binding NavigateToSettingsCommand}"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Main Content -->
        <Border Grid.Row="1" Padding="30">
            <StackPanel Spacing="20" 
                        HorizontalAlignment="Center" 
                        VerticalAlignment="Center">
                
                <TextBlock Text="{Binding Greeting}" 
                           FontSize="28" 
                           FontWeight="SemiBold"
                           HorizontalAlignment="Center"/>

                <TextBlock Text="{Binding Counter, StringFormat='Counter: {0}'}" 
                           FontSize="18"
                           HorizontalAlignment="Center"
                           Foreground="{DynamicResource SystemAccentColor}"/>

                <StackPanel Orientation="Horizontal" 
                            Spacing="15" 
                            HorizontalAlignment="Center">
                    <Button Content="Click Me!" 
                            Command="{Binding IncrementCounterCommand}"
                            Classes="accent"
                            Padding="20,10"
                            FontSize="16"/>
                    
                    <Button Content="Load Data" 
                            Command="{Binding LoadDataCommand}"
                            IsEnabled="{Binding !IsBusy}"
                            Padding="20,10"
                            FontSize="16"/>
                </StackPanel>

                <!-- Loading indicator -->
                <ProgressBar IsIndeterminate="True" 
                             IsVisible="{Binding IsBusy}"
                             Width="200"/>

                <!-- Current Page Content -->
                <ContentControl Content="{Binding CurrentPage}" 
                                Margin="0,20,0,0"/>
            </StackPanel>
        </Border>

        <!-- Footer -->
        <Border Grid.Row="2" 
                Background="{DynamicResource SystemChromeHighColor}" 
                Padding="15,10">
            <Grid ColumnDefinitions="*,Auto">
                <TextBlock Text="Built with Avalonia UI + .NET 10" 
                           Opacity="0.7" 
                           FontSize="12"/>
                <TextBlock Grid.Column="1" 
                           Text="{Binding Counter, StringFormat='Clicks: {0}'}" 
                           Opacity="0.7" 
                           FontSize="12"/>
            </Grid>
        </Border>
    </Grid>
</Window>
ENDOFFILE

log "Updating src/MyDesktopApplication.Desktop/Views/MainWindow.axaml.cs..."
cat > src/$PROJECT_NAME.Desktop/Views/MainWindow.axaml.cs << 'ENDOFFILE'
using Avalonia.Controls;

namespace MyDesktopApplication.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }
}
ENDOFFILE

log "Updating src/MyDesktopApplication.Desktop/App.axaml..."
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

log "Updating src/MyDesktopApplication.Desktop/App.axaml.cs..."
cat > src/$PROJECT_NAME.Desktop/App.axaml.cs << 'ENDOFFILE'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Data.Core.Plugins;
using System.Linq;
using Avalonia.Markup.Xaml;
using MyDesktopApplication.Desktop.ViewModels;
using MyDesktopApplication.Desktop.Views;

namespace MyDesktopApplication.Desktop;

public partial class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            // Avoid duplicate validations from both Avalonia and the CommunityToolkit
            DisableAvaloniaDataAnnotationValidation();
            desktop.MainWindow = new MainWindow
            {
                DataContext = new MainWindowViewModel(),
            };
        }

        base.OnFrameworkInitializationCompleted();
    }

    private void DisableAvaloniaDataAnnotationValidation()
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

log "Updating src/MyDesktopApplication.Desktop/Program.cs..."
cat > src/$PROJECT_NAME.Desktop/Program.cs << 'ENDOFFILE'
using Avalonia;
using System;

namespace MyDesktopApplication.Desktop;

sealed class Program
{
    [STAThread]
    public static void Main(string[] args) => BuildAvaloniaApp()
        .StartWithClassicDesktopLifetime(args);

    public static AppBuilder BuildAvaloniaApp()
        => AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .WithInterFont()
            .LogToTrace();
}
ENDOFFILE

# =============================================================================
# PART 4: Core Source Files
# =============================================================================

log "Updating src/MyDesktopApplication.Core/Class1.cs..."
cat > src/$PROJECT_NAME.Core/Class1.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Core;

/// <summary>
/// Sample entity - replace with your domain entities
/// </summary>
public class TodoItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public void MarkComplete() => IsCompleted = true;
    public void MarkIncomplete() => IsCompleted = false;
}
ENDOFFILE

# =============================================================================
# PART 5: Infrastructure Source Files
# =============================================================================

log "Updating src/MyDesktopApplication.Infrastructure/Class1.cs..."
cat > src/$PROJECT_NAME.Infrastructure/Class1.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Infrastructure;

/// <summary>
/// Placeholder for infrastructure services (repositories, data access, etc.)
/// </summary>
public class PlaceholderService
{
    public string GetMessage() => "Infrastructure layer ready!";
}
ENDOFFILE

# =============================================================================
# PART 6: Shared Source Files
# =============================================================================

log "Updating src/MyDesktopApplication.Shared/Class1.cs..."
cat > src/$PROJECT_NAME.Shared/Class1.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Shared;

/// <summary>
/// Placeholder for shared DTOs, services, etc.
/// </summary>
public class PlaceholderDto
{
    public string Name { get; set; } = string.Empty;
}
ENDOFFILE

# =============================================================================
# PART 7: Test Files
# =============================================================================

log "Updating tests/MyDesktopApplication.Core.Tests/UnitTest1.cs..."
cat > tests/$PROJECT_NAME.Core.Tests/UnitTest1.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void MarkComplete_SetsIsCompletedToTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test" };
        
        // Act
        todo.MarkComplete();
        
        // Assert
        Assert.True(todo.IsCompleted);
    }

    [Fact]
    public void NewTodoItem_HasDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem();
        
        // Assert
        Assert.NotEqual(Guid.Empty, todo.Id);
        Assert.False(todo.IsCompleted);
        Assert.Equal(string.Empty, todo.Title);
    }
}
ENDOFFILE

log "Updating tests/MyDesktopApplication.Integration.Tests/UnitTest1.cs..."
cat > tests/$PROJECT_NAME.Integration.Tests/UnitTest1.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Integration.Tests;

public class IntegrationTest1
{
    [Fact]
    public void PlaceholderTest()
    {
        // Placeholder for integration tests
        Assert.True(true);
    }
}
ENDOFFILE

log "Updating tests/MyDesktopApplication.UI.Tests/UnitTest1.cs..."
cat > tests/$PROJECT_NAME.UI.Tests/UnitTest1.cs << 'ENDOFFILE'
namespace MyDesktopApplication.UI.Tests;

public class UITest1
{
    [Fact]
    public void PlaceholderTest()
    {
        // Placeholder for UI tests with Avalonia.Headless
        Assert.True(true);
    }
}
ENDOFFILE

# =============================================================================
# PART 8: Config Files
# =============================================================================

log "Creating appsettings.json..."
cat > appsettings.json << 'ENDOFFILE'
{
  "Application": {
    "Name": "MyDesktopApplication",
    "Theme": "Fluent"
  },
  "Database": {
    "UsePostgreSql": false,
    "PostgreSqlConnection": "Host=localhost;Database=myapp;Username=postgres;Password=postgres",
    "SqliteFileName": "app.db"
  },
  "OpenTelemetry": {
    "EnableConsoleExporter": true,
    "OtlpEndpoint": null
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" }
    ],
    "Enrich": ["FromLogContext", "WithMachineName"]
  }
}
ENDOFFILE

log "Creating .gitignore..."
cat > .gitignore << 'ENDOFFILE'
[Bb]in/
[Oo]bj/
.vs/
.vscode/
.idea/
*.user
*.suo
TestResults/
*.db
*.log
.DS_Store
appsettings.*.local.json
ENDOFFILE

log "Creating README.md..."
cat > README.md << 'ENDOFFILE'
# MyDesktopApplication

Cross-platform desktop app built with **Avalonia UI** and **.NET 10**.

## Quick Start

```bash
dotnet restore
dotnet build
dotnet run --project src/MyDesktopApplication.Desktop
```

## Run Tests

```bash
dotnet test
```

## Features

- .NET 10 with SLNX solution format
- Central Package Management
- Avalonia UI 11.3 (cross-platform)
- CommunityToolkit.Mvvm for MVVM pattern
- SQLite & PostgreSQL support ready
- OpenTelemetry observability ready
- 100% free/open source packages
ENDOFFILE

# =============================================================================
# PART 9: Build & Verify
# =============================================================================

echo ""
log "Running dotnet restore..."
dotnet restore

echo ""
log "Running dotnet build..."
dotnet build

echo ""
echo "=============================================="
echo -e "  ${GREEN}Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Run the application:"
echo "  dotnet run --project src/$PROJECT_NAME.Desktop"
echo ""
echo "Run tests:"
echo "  dotnet test"
echo ""

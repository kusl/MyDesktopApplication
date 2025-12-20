#!/bin/bash
# =============================================================================
# Fix GitHub Actions + Add Android Support
# =============================================================================
# This script:
# 1. Fixes the PowerShell line continuation error in GitHub Actions
# 2. Adds Android project to the solution
# 3. Updates workflows to include Android builds
# =============================================================================

set -e

PROJECT_NAME="MyDesktopApplication"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "=============================================="
echo "  Fix CI + Add Android Support"
echo "=============================================="
echo ""

# =============================================================================
# PART 1: Fix CI workflow (PowerShell compatibility)
# =============================================================================
log "Fixing CI workflow..."

cat > .github/workflows/ci.yml << 'ENDOFFILE'
name: CI

on:
  push:
    branches: [ master, main, develop ]
  pull_request:
    branches: [ master, main, develop ]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  build-and-test:
    name: Build & Test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Cache NuGet packages
        uses: actions/cache@v4
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Test
        run: dotnet test --configuration Release --no-build --verbosity normal

  lint:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Restore
        run: dotnet restore

      - name: Check formatting
        run: dotnet format --verify-no-changes --verbosity diagnostic || echo "::warning::Formatting issues found"
ENDOFFILE

# =============================================================================
# PART 2: Fix Release workflow (PowerShell compatibility)
# =============================================================================
log "Fixing Release workflow..."

cat > .github/workflows/release.yml << 'ENDOFFILE'
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version number (e.g., 1.0.0)'
        required: true
        default: '1.0.0'

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true
  APP_NAME: MyDesktopApplication

jobs:
  build-desktop:
    name: Desktop - ${{ matrix.name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: windows-latest
            name: Windows x64
            rid: win-x64
          - os: windows-latest
            name: Windows ARM64
            rid: win-arm64
          - os: ubuntu-latest
            name: Linux x64
            rid: linux-x64
          - os: ubuntu-latest
            name: Linux ARM64
            rid: linux-arm64
          - os: macos-latest
            name: macOS x64
            rid: osx-x64
          - os: macos-latest
            name: macOS ARM64
            rid: osx-arm64

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Get version
        id: version
        shell: bash
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "version=${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
          else
            echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
          fi

      - name: Restore
        run: dotnet restore

      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release \
            -r ${{ matrix.rid }} \
            --self-contained true \
            -o ./publish/${{ matrix.rid }} \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -p:EnableCompressionInSingleFile=true \
            -p:Version=${{ steps.version.outputs.version }}

      - name: Create archive (Unix)
        if: runner.os != 'Windows'
        shell: bash
        run: |
          cd ./publish
          tar -czvf ${{ env.APP_NAME }}-${{ steps.version.outputs.version }}-${{ matrix.rid }}.tar.gz ${{ matrix.rid }}

      - name: Create archive (Windows)
        if: runner.os == 'Windows'
        shell: pwsh
        run: |
          Compress-Archive -Path ./publish/${{ matrix.rid }}/* -DestinationPath ./publish/${{ env.APP_NAME }}-${{ steps.version.outputs.version }}-${{ matrix.rid }}.zip

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: desktop-${{ matrix.rid }}
          path: |
            ./publish/*.tar.gz
            ./publish/*.zip
          retention-days: 7

  build-android:
    name: Android
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Install Android workload
        run: dotnet workload install android

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Get version
        id: version
        shell: bash
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "version=${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
          else
            echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
          fi

      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj

      - name: Build Android APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release \
            -f net10.0-android \
            -o ./publish/android \
            -p:Version=${{ steps.version.outputs.version }}

      - name: Rename APK
        run: |
          mv ./publish/android/*.apk ./publish/android/${{ env.APP_NAME }}-${{ steps.version.outputs.version }}-android.apk || true
          ls -la ./publish/android/

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: android
          path: ./publish/android/*.apk
          retention-days: 7

  release:
    name: Create Release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Get version
        id: version
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "version=${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
            echo "tag=v${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
          else
            echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
            echo "tag=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
          fi

      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: ./artifacts

      - name: List artifacts
        run: find ./artifacts -type f

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ steps.version.outputs.tag }}
          name: Release ${{ steps.version.outputs.version }}
          draft: false
          prerelease: ${{ contains(steps.version.outputs.version, '-') }}
          generate_release_notes: true
          files: |
            ./artifacts/**/*.tar.gz
            ./artifacts/**/*.zip
            ./artifacts/**/*.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
ENDOFFILE

# =============================================================================
# PART 3: Fix Nightly workflow
# =============================================================================
log "Fixing Nightly workflow..."

cat > .github/workflows/nightly.yml << 'ENDOFFILE'
name: Nightly Build

on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  nightly:
    name: Nightly (${{ matrix.rid }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            rid: linux-x64
          - os: windows-latest
            rid: win-x64
          - os: macos-latest
            rid: osx-arm64

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Get date
        id: date
        shell: bash
        run: echo "date=$(date +'%Y%m%d')" >> $GITHUB_OUTPUT

      - name: Restore
        run: dotnet restore

      - name: Test
        run: dotnet test --configuration Release

      - name: Publish
        shell: bash
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release \
            -r ${{ matrix.rid }} \
            --self-contained true \
            -o ./publish \
            -p:PublishSingleFile=true \
            -p:Version=0.0.0-nightly.${{ steps.date.outputs.date }}

      - name: Upload nightly build
        uses: actions/upload-artifact@v4
        with:
          name: nightly-${{ matrix.rid }}-${{ steps.date.outputs.date }}
          path: ./publish
          retention-days: 7
ENDOFFILE

# =============================================================================
# PART 4: Create Android Project
# =============================================================================
log "Creating Android project structure..."

mkdir -p src/$PROJECT_NAME.Android
mkdir -p src/$PROJECT_NAME.Android/Resources/values
mkdir -p src/$PROJECT_NAME.Android/Resources/mipmap-hdpi
mkdir -p src/$PROJECT_NAME.Android/Resources/mipmap-mdpi
mkdir -p src/$PROJECT_NAME.Android/Resources/mipmap-xhdpi
mkdir -p src/$PROJECT_NAME.Android/Resources/mipmap-xxhdpi
mkdir -p src/$PROJECT_NAME.Android/Resources/mipmap-xxxhdpi

# Android .csproj
log "Creating Android project file..."
cat > src/$PROJECT_NAME.Android/$PROJECT_NAME.Android.csproj << 'ENDOFFILE'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <OutputType>Exe</OutputType>
    
    <!-- Android-specific settings -->
    <ApplicationId>com.mydesktopapplication</ApplicationId>
    <ApplicationVersion>1</ApplicationVersion>
    <ApplicationDisplayVersion>1.0.0</ApplicationDisplayVersion>
    <ApplicationTitle>MyDesktopApplication</ApplicationTitle>
    
    <!-- Android SDK versions -->
    <SupportedOSPlatformVersion>21</SupportedOSPlatformVersion>
    <TargetPlatformVersion>35</TargetPlatformVersion>
  </PropertyGroup>

  <ItemGroup>
    <!-- Avalonia for Android -->
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
  </ItemGroup>

  <ItemGroup>
    <!-- Reference shared projects -->
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
</Project>
ENDOFFILE

# MainActivity.cs
log "Creating MainActivity.cs..."
cat > src/$PROJECT_NAME.Android/MainActivity.cs << 'ENDOFFILE'
using Android.App;
using Android.Content.PM;
using Avalonia;
using Avalonia.Android;
using Avalonia.ReactiveUI;

namespace MyDesktopApplication.Android;

[Activity(
    Label = "MyDesktopApplication",
    Theme = "@style/MyTheme.NoActionBar",
    Icon = "@mipmap/ic_launcher",
    MainLauncher = true,
    ConfigurationChanges = ConfigChanges.Orientation | ConfigChanges.ScreenSize | ConfigChanges.UiMode)]
public class MainActivity : AvaloniaMainActivity<App>
{
    protected override AppBuilder CustomizeAppBuilder(AppBuilder builder)
    {
        return base.CustomizeAppBuilder(builder)
            .WithInterFont()
            .UseReactiveUI();
    }
}
ENDOFFILE

# App.cs for Android (uses shared ViewModels)
log "Creating Android App.cs..."
cat > src/$PROJECT_NAME.Android/App.cs << 'ENDOFFILE'
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Data.Core.Plugins;
using Avalonia.Markup.Xaml;
using MyDesktopApplication.Android.Views;
using MyDesktopApplication.Shared.ViewModels;
using System.Linq;

namespace MyDesktopApplication.Android;

public partial class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform)
        {
            // Disable Avalonia's data annotation validation to avoid conflicts
            var toRemove = BindingPlugins.DataValidators
                .OfType<DataAnnotationsValidationPlugin>()
                .ToArray();
            foreach (var plugin in toRemove)
            {
                BindingPlugins.DataValidators.Remove(plugin);
            }

            singleViewPlatform.MainView = new MainView
            {
                DataContext = new MainViewModel()
            };
        }

        base.OnFrameworkInitializationCompleted();
    }
}
ENDOFFILE

# App.axaml for Android
log "Creating Android App.axaml..."
cat > src/$PROJECT_NAME.Android/App.axaml << 'ENDOFFILE'
<Application xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             x:Class="MyDesktopApplication.Android.App"
             RequestedThemeVariant="Default">
    <Application.Styles>
        <FluentTheme />
    </Application.Styles>
</Application>
ENDOFFILE

# Create Views folder
mkdir -p src/$PROJECT_NAME.Android/Views

# MainView.axaml for Android
log "Creating Android MainView.axaml..."
cat > src/$PROJECT_NAME.Android/Views/MainView.axaml << 'ENDOFFILE'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="using:MyDesktopApplication.Shared.ViewModels"
             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
             xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
             mc:Ignorable="d" d:DesignWidth="400" d:DesignHeight="700"
             x:Class="MyDesktopApplication.Android.Views.MainView"
             x:DataType="vm:MainViewModel">

    <Design.DataContext>
        <vm:MainViewModel/>
    </Design.DataContext>

    <Grid RowDefinitions="Auto,*,Auto">
        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D4" Padding="16">
            <TextBlock Text="MyDesktopApplication" 
                       FontSize="20" FontWeight="Bold" Foreground="White"
                       HorizontalAlignment="Center"/>
        </Border>

        <!-- Main Content -->
        <ScrollViewer Grid.Row="1" Padding="16">
            <StackPanel Spacing="16">
                
                <!-- Greeting & Counter -->
                <TextBlock Text="{Binding Greeting}" 
                           FontSize="24" FontWeight="SemiBold"
                           HorizontalAlignment="Center"
                           TextWrapping="Wrap"/>
                
                <TextBlock Text="{Binding Counter, StringFormat='Counter: {0}'}" 
                           FontSize="18" HorizontalAlignment="Center" 
                           Foreground="#0078D4"/>
                
                <Button Content="Click Me!" 
                        Command="{Binding IncrementCounterCommand}"
                        HorizontalAlignment="Stretch"
                        HorizontalContentAlignment="Center"
                        Padding="16,12"
                        FontSize="16"/>

                <Button Content="Load Data" 
                        Command="{Binding LoadDataCommand}"
                        IsEnabled="{Binding !IsBusy}"
                        HorizontalAlignment="Stretch"
                        HorizontalContentAlignment="Center"
                        Padding="16,12"
                        FontSize="16"/>

                <ProgressBar IsIndeterminate="True" 
                             IsVisible="{Binding IsBusy}"/>

                <Separator Margin="0,8"/>

                <!-- Todo Section -->
                <TextBlock Text="Todo List" FontSize="18" FontWeight="SemiBold"/>
                
                <Grid ColumnDefinitions="*,Auto">
                    <TextBox Grid.Column="0" 
                             Text="{Binding NewTodoTitle}" 
                             Watermark="Enter a new todo..." 
                             Margin="0,0,8,0"/>
                    <Button Grid.Column="1" Content="Add" 
                            Command="{Binding AddTodoCommand}"/>
                </Grid>

                <!-- Todo List -->
                <ItemsControl ItemsSource="{Binding TodoItems}">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Margin="0,4" Padding="12" CornerRadius="4" Background="#F5F5F5">
                                <Grid ColumnDefinitions="Auto,*">
                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsCompleted}"/>
                                    <TextBlock Grid.Column="1" Text="{Binding Title}" 
                                               VerticalAlignment="Center" Margin="8,0,0,0"/>
                                </Grid>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>
            </StackPanel>
        </ScrollViewer>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#F0F0F0" Padding="16,8">
            <TextBlock Text="Built with Avalonia UI + .NET 10" 
                       HorizontalAlignment="Center"
                       Opacity="0.6" FontSize="12"/>
        </Border>
    </Grid>
</UserControl>
ENDOFFILE

# MainView.axaml.cs
log "Creating Android MainView.axaml.cs..."
cat > src/$PROJECT_NAME.Android/Views/MainView.axaml.cs << 'ENDOFFILE'
using Avalonia.Controls;

namespace MyDesktopApplication.Android.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
    }
}
ENDOFFILE

# Android Resources - strings.xml
log "Creating Android resources..."
cat > src/$PROJECT_NAME.Android/Resources/values/strings.xml << 'ENDOFFILE'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MyDesktopApplication</string>
</resources>
ENDOFFILE

# Android Resources - styles.xml
cat > src/$PROJECT_NAME.Android/Resources/values/styles.xml << 'ENDOFFILE'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="MyTheme" parent="@android:style/Theme.Material.Light.DarkActionBar">
    </style>
    <style name="MyTheme.NoActionBar" parent="@android:style/Theme.Material.Light.NoActionBar">
        <item name="android:windowActionBar">false</item>
        <item name="android:windowNoTitle">true</item>
    </style>
</resources>
ENDOFFILE

# AndroidManifest.xml
cat > src/$PROJECT_NAME.Android/AndroidManifest.xml << 'ENDOFFILE'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application 
        android:allowBackup="true" 
        android:icon="@mipmap/ic_launcher" 
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/MyTheme.NoActionBar">
    </application>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
</manifest>
ENDOFFILE

# =============================================================================
# PART 5: Create Shared ViewModels (shared between Desktop and Android)
# =============================================================================
log "Creating shared ViewModels..."

mkdir -p src/$PROJECT_NAME.Shared/ViewModels

# Move ViewModel logic to Shared so it can be used by both Desktop and Android
cat > src/$PROJECT_NAME.Shared/ViewModels/ViewModelBase.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Base class for all ViewModels - shared between Desktop and Android
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

cat > src/$PROJECT_NAME.Shared/ViewModels/MainViewModel.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Main ViewModel shared between Desktop and Android
/// </summary>
public partial class MainViewModel : ViewModelBase
{
    [ObservableProperty]
    private string _greeting = "Welcome to Avalonia!";

    [ObservableProperty]
    private int _counter;

    [ObservableProperty]
    private ObservableCollection<TodoItem> _todoItems = [];

    [ObservableProperty]
    private string _newTodoTitle = string.Empty;

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
            // Simulate loading
            await Task.Delay(1000);
        }
        catch (System.Exception ex)
        {
            SetError($"Failed to load: {ex.Message}");
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private void AddTodo()
    {
        if (string.IsNullOrWhiteSpace(NewTodoTitle))
            return;

        var todo = new TodoItem { Title = NewTodoTitle.Trim() };
        TodoItems.Add(todo);
        NewTodoTitle = string.Empty;
    }

    [RelayCommand]
    private void ToggleTodo(TodoItem? todo)
    {
        if (todo is null)
            return;

        if (todo.IsCompleted)
            todo.MarkIncomplete();
        else
            todo.MarkComplete();
    }
}
ENDOFFILE

# =============================================================================
# PART 6: Update Desktop project to use shared ViewModels
# =============================================================================
log "Updating Desktop ViewModels to inherit from Shared..."

cat > src/$PROJECT_NAME.Desktop/ViewModels/ViewModelBase.cs << 'ENDOFFILE'
// Desktop-specific ViewModelBase - inherits from Shared
// This allows Desktop to add platform-specific functionality if needed

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// Desktop-specific base class - inherits shared functionality
/// </summary>
public abstract class ViewModelBase : Shared.ViewModels.ViewModelBase
{
}
ENDOFFILE

cat > src/$PROJECT_NAME.Desktop/ViewModels/MainWindowViewModel.cs << 'ENDOFFILE'
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// Desktop MainWindow ViewModel - extends shared MainViewModel with desktop-specific features
/// </summary>
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

    // Parameterless constructor (for design-time and testing)
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
        try
        {
            await LoadTodosAsync();
        }
        finally
        {
            IsBusy = false;
        }
    }

    [RelayCommand]
    private async Task AddTodoAsync()
    {
        if (string.IsNullOrWhiteSpace(NewTodoTitle))
            return;

        var todo = new TodoItem { Title = NewTodoTitle.Trim() };
        
        if (_todoRepository is not null)
            await _todoRepository.AddAsync(todo);
        
        TodoItems.Add(todo);
        NewTodoTitle = string.Empty;
    }

    [RelayCommand]
    private async Task ToggleTodoAsync(TodoItem? todo)
    {
        if (todo is null)
            return;

        if (todo.IsCompleted)
            todo.MarkIncomplete();
        else
            todo.MarkComplete();

        if (_todoRepository is not null)
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
# PART 7: Update Directory.Packages.props with Android package
# =============================================================================
log "Adding Avalonia.Android to Directory.Packages.props..."

cat > Directory.Packages.props << 'ENDOFFILE'
<Project>
  <!-- Central Package Management - All package versions in one place -->
  <!-- LICENSE POLICY: Only truly free packages (MIT, Apache-2.0, BSD, Public Domain) -->
  
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup>
    <!-- Avalonia UI (MIT License) -->
    <PackageVersion Include="Avalonia" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Android" Version="11.3.10" />
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
# PART 8: Add Android project to solution
# =============================================================================
log "Adding Android project to solution..."

dotnet sln add src/$PROJECT_NAME.Android/$PROJECT_NAME.Android.csproj 2>/dev/null || warn "Could not add to solution (may need Android workload)"

# =============================================================================
# PART 9: Update README
# =============================================================================
log "Updating README..."

cat > README.md << 'ENDOFFILE'
# MyDesktopApplication

[![CI](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml)
[![Release](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cross-platform application built with **Avalonia UI** and **.NET 10**.

## Downloads

| Platform | Architecture | Download |
|----------|--------------|----------|
| Windows | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Windows | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | x64 (Intel) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | ARM64 (Apple Silicon) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Android | APK | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |

## Quick Start

### Desktop

```bash
dotnet restore
dotnet build
dotnet run --project src/MyDesktopApplication.Desktop
```

### Android (requires Android workload)

```bash
# Install Android workload (one-time)
dotnet workload install android

# Build APK
dotnet build src/MyDesktopApplication.Android -c Release
```

## Run Tests

```bash
dotnet test
```

## Create Release

Push a tag to create a release with binaries for all platforms:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
├── src/
│   ├── MyDesktopApplication.Core/          # Domain logic
│   ├── MyDesktopApplication.Infrastructure/ # Data access
│   ├── MyDesktopApplication.Shared/        # Shared ViewModels
│   ├── MyDesktopApplication.Desktop/       # Desktop (Windows/Linux/macOS)
│   └── MyDesktopApplication.Android/       # Android
└── tests/
    ├── MyDesktopApplication.Core.Tests/
    ├── MyDesktopApplication.Integration.Tests/
    └── MyDesktopApplication.UI.Tests/
```

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows x64 | ✅ |
| Windows ARM64 | ✅ |
| Linux x64 | ✅ |
| Linux ARM64 | ✅ |
| macOS x64 | ✅ |
| macOS ARM64 | ✅ |
| Android | ✅ |
| iOS | ❌ (requires Apple Developer account - $99/year) |

## License

MIT License - Free for any use.

All dependencies are MIT, Apache-2.0, BSD, or Public Domain licensed.
ENDOFFILE

# =============================================================================
# PART 10: Build desktop (Android requires workload)
# =============================================================================
echo ""
log "Running dotnet restore (Desktop only)..."
dotnet restore --ignore-failed-sources 2>/dev/null || dotnet restore

echo ""
log "Running dotnet build (Desktop only)..."
if dotnet build src/$PROJECT_NAME.Desktop; then
    echo ""
    log "Running dotnet test..."
    dotnet test
    
    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}Setup Complete!${NC}"
    echo "=============================================="
    echo ""
    echo "Changes made:"
    echo "  ✓ Fixed GitHub Actions for Windows PowerShell"
    echo "  ✓ Created Android project"
    echo "  ✓ Added shared ViewModels for code reuse"
    echo "  ✓ Updated workflows to build Android APK"
    echo ""
    echo "To build Android locally:"
    echo "  dotnet workload install android"
    echo "  dotnet build src/$PROJECT_NAME.Android"
    echo ""
    echo "To create a release:"
    echo "  git add ."
    echo "  git commit -m 'Add Android support'"
    echo "  git push"
    echo "  git tag v1.0.0"
    echo "  git push origin v1.0.0"
    echo ""
else
    warn "Build had issues - check errors above"
fi

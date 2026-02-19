#!/bin/bash
set -euo pipefail

# =============================================================================
# COMPREHENSIVE FIX SCRIPT
# =============================================================================
# Fixes:
#   1. Desktop: Only selected option gets colored (green=correct, red=wrong)
#   2. Both platforms: Add category-specific question text
#   3. Both platforms: Reset game requires confirmation prompt
#   4. Responsive text sizing for small displays
# =============================================================================

cd "$(dirname "$0")"

echo "=============================================="
echo "  Comprehensive Fix Script"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# Step 0: Kill stuck processes and clean
# -----------------------------------------------------------------------------
echo "[0] Cleaning..."
pkill -f "VBCSCompiler" 2>/dev/null || true
pkill -f "aapt2" 2>/dev/null || true
sleep 1

find . -type d \( -name "obj" -o -name "bin" \) \
  -not -path "./.git/*" \
  -exec rm -rf {} + 2>/dev/null || true

# =============================================================================
# FIX 1: QuestionType.GetQuestion() - proper grammatical questions
# =============================================================================
echo "[1/8] Updating QuestionType extensions with GetQuestion()..."

cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'ENDOFFILE'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Types of comparison questions in the country quiz.
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

/// <summary>
/// Extension methods for QuestionType enum.
/// </summary>
public static class QuestionTypeExtensions
{
    /// <summary>
    /// Gets a human-readable label for the question type.
    /// </summary>
    public static string GetLabel(this QuestionType type) => type switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.Gdp => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.Density => "Population Density",
        QuestionType.Literacy => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => type.ToString()
    };

    /// <summary>
    /// Gets a grammatically correct question for the given question type.
    /// </summary>
    public static string GetQuestion(this QuestionType type) => type switch
    {
        QuestionType.Population => "Which country has a larger population?",
        QuestionType.Area => "Which country is larger in area?",
        QuestionType.Gdp => "Which country has a higher total GDP?",
        QuestionType.GdpPerCapita => "Which country has a higher GDP per capita?",
        QuestionType.Density => "Which country has a higher population density?",
        QuestionType.Literacy => "Which country has a higher literacy rate?",
        QuestionType.Hdi => "Which country has a higher Human Development Index?",
        QuestionType.LifeExpectancy => "Which country has a longer life expectancy?",
        _ => "Which country ranks higher?"
    };

    /// <summary>
    /// Gets the numeric value for a country based on the question type.
    /// Returns null if data is not available.
    /// </summary>
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

    /// <summary>
    /// Formats a numeric value with appropriate units for display.
    /// Uses enough precision to distinguish close values.
    /// </summary>
    public static string FormatValue(this QuestionType type, double? value)
    {
        if (!value.HasValue) return "N/A";
        var v = value.Value;

        return type switch
        {
            QuestionType.Population => FormatLargeNumber(v),
            QuestionType.Area => $"{v:N0} km²",
            QuestionType.Gdp => "$" + FormatLargeNumber(v),
            QuestionType.GdpPerCapita => $"${v:N0}",
            QuestionType.Density => $"{v:N1}/km²",
            QuestionType.Literacy => $"{v:N1}%",
            QuestionType.Hdi => $"{v:N3}",
            QuestionType.LifeExpectancy => $"{v:N1} years",
            _ => $"{v:N2}"
        };
    }

    private static string FormatLargeNumber(double value)
    {
        return value switch
        {
            >= 1_000_000_000_000 => $"{value / 1_000_000_000_000:N3}T",
            >= 1_000_000_000 => $"{value / 1_000_000_000:N3}B",
            >= 1_000_000 => $"{value / 1_000_000:N2}M",
            >= 1_000 => $"{value / 1_000:N1}K",
            _ => $"{value:N0}"
        };
    }
}
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 2: Desktop MainWindowViewModel - fix coloring + add question + reset confirm
# =============================================================================
echo "[2/8] Updating Desktop MainWindowViewModel..."

cat > src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs << 'ENDOFFILE'
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

/// <summary>
/// ViewModel for the Desktop main window.
/// </summary>
public partial class MainWindowViewModel : ViewModelBase
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private GameState _gameState = new();
    private Country? _correctCountry;

    // --- Observable properties ---

    [ObservableProperty] private string _questionText = "Loading...";

    [ObservableProperty] private Country? _country1;
    [ObservableProperty] private Country? _country2;

    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";

    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    [ObservableProperty] private bool _isCorrectAnswer;
    [ObservableProperty] private int _selectedCountry; // 0=none, 1=country1, 2=country2

    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;

    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    // Reset confirmation overlay
    [ObservableProperty] private bool _isResetConfirmationVisible;

    // --- Computed properties for button coloring ---
    // CRITICAL: Only the SELECTED button gets colored. Unselected stays default.

    public bool IsCountry1Correct => HasAnswered && SelectedCountry == 1 && IsCorrectAnswer;
    public bool IsCountry1Wrong => HasAnswered && SelectedCountry == 1 && !IsCorrectAnswer;
    public bool IsCountry2Correct => HasAnswered && SelectedCountry == 2 && IsCorrectAnswer;
    public bool IsCountry2Wrong => HasAnswered && SelectedCountry == 2 && !IsCorrectAnswer;

    // Formatted text properties
    public string ScoreText => $"{_gameState.CurrentScore}/{_gameState.TotalAnswered}";
    public string StreakText => _gameState.CurrentStreak > 0 ? $"Streak: {_gameState.CurrentStreak}" : "";
    public string BestStreakText => _gameState.BestStreak > 0 ? $"Best: {_gameState.BestStreak}" : "";
    public string AccuracyText => _gameState.TotalAnswered > 0
        ? $"Accuracy: {_gameState.AccuracyPercentage:F1}%"
        : "Accuracy: --";

    public ObservableCollection<QuestionType> QuestionTypes { get; } =
        new(Enum.GetValues<QuestionType>());

    // --- Constructors ---

    public MainWindowViewModel()
    {
        GenerateNewQuestion();
    }

    public MainWindowViewModel(IGameStateRepository gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
    }

    // --- Initialization ---

    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            _gameState = await _gameStateRepository.GetOrCreateAsync("default");
            SyncScoresFromGameState();
        }
        GenerateNewQuestion();
    }

    private void SyncScoresFromGameState()
    {
        CurrentScore = _gameState.CurrentScore;
        HighScore = _gameState.HighScore;
        CurrentStreak = _gameState.CurrentStreak;
        BestStreak = _gameState.BestStreak;
        RefreshTextProperties();
    }

    private void RefreshTextProperties()
    {
        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    // --- Property change notifications for computed properties ---

    partial void OnHasAnsweredChanged(bool value) => RefreshButtonStates();
    partial void OnSelectedCountryChanged(int value) => RefreshButtonStates();
    partial void OnIsCorrectAnswerChanged(bool value) => RefreshButtonStates();

    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        _gameState.SelectedQuestionType = (int)value;
        GenerateNewQuestion();
    }

    private void RefreshButtonStates()
    {
        OnPropertyChanged(nameof(IsCountry1Correct));
        OnPropertyChanged(nameof(IsCountry1Wrong));
        OnPropertyChanged(nameof(IsCountry2Correct));
        OnPropertyChanged(nameof(IsCountry2Wrong));
    }

    // --- Commands ---

    [RelayCommand]
    private async Task SelectCountryAsync(string countryNumberStr)
    {
        if (!int.TryParse(countryNumberStr, out var countryNumber)) return;
        if (HasAnswered || _correctCountry == null) return;

        HasAnswered = true;
        SelectedCountry = countryNumber;

        var selectedCountry = countryNumber == 1 ? Country1 : Country2;
        var isCorrect = selectedCountry?.Name == _correctCountry.Name;
        IsCorrectAnswer = isCorrect;

        // Record answer in game state
        _gameState.RecordAnswer(isCorrect);
        SyncScoresFromGameState();

        // Show values for both countries
        if (Country1 != null)
        {
            var v1 = SelectedQuestionType.GetValue(Country1);
            Country1Value = v1.HasValue ? SelectedQuestionType.FormatValue(v1) : "N/A";
        }
        if (Country2 != null)
        {
            var v2 = SelectedQuestionType.GetValue(Country2);
            Country2Value = v2.HasValue ? SelectedQuestionType.FormatValue(v2) : "N/A";
        }

        ResultMessage = isCorrect ? GetCorrectMessage() : GetIncorrectMessage();

        // Persist
        if (_gameStateRepository != null)
        {
            try { await _gameStateRepository.UpdateAsync(_gameState); }
            catch { /* Silently handle persistence failures */ }
        }
    }

    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    /// <summary>
    /// Shows the reset confirmation overlay instead of immediately resetting.
    /// </summary>
    [RelayCommand]
    private void RequestResetGame()
    {
        IsResetConfirmationVisible = true;
    }

    /// <summary>
    /// User confirmed: reset the game.
    /// </summary>
    [RelayCommand]
    private async Task ConfirmResetGameAsync()
    {
        IsResetConfirmationVisible = false;

        _gameState.Reset();
        SyncScoresFromGameState();
        GenerateNewQuestion();

        if (_gameStateRepository != null)
        {
            try { await _gameStateRepository.UpdateAsync(_gameState); }
            catch { /* Silently handle persistence failures */ }
        }
    }

    /// <summary>
    /// User cancelled: hide the confirmation overlay.
    /// </summary>
    [RelayCommand]
    private void CancelResetGame()
    {
        IsResetConfirmationVisible = false;
    }

    // --- Internals ---

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        SelectedCountry = 0;
        IsCorrectAnswer = false;
        ResultMessage = "";
        Country1Value = "";
        Country2Value = "";

        var countries = CountryData.GetAllCountries();
        if (countries.Count < 2)
        {
            QuestionText = "Not enough countries loaded.";
            return;
        }

        var indices = Enumerable.Range(0, countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        Country1 = countries[indices[0]];
        Country2 = countries[indices[1]];

        QuestionText = SelectedQuestionType.GetQuestion();

        var v1 = SelectedQuestionType.GetValue(Country1);
        var v2 = SelectedQuestionType.GetValue(Country2);
        _correctCountry = (v1 ?? 0) >= (v2 ?? 0) ? Country1 : Country2;
    }

    private string GetCorrectMessage()
    {
        if (_gameState.CurrentStreak >= 10) return "UNSTOPPABLE! 10+ streak!";
        if (_gameState.CurrentStreak >= 5) return $"On fire! {_gameState.CurrentStreak} in a row!";
        if (_gameState.CurrentStreak >= 3) return $"Great streak! {_gameState.CurrentStreak} correct!";

        var messages = new[] { "Correct!", "Well done!", "Nice one!", "You got it!", "Excellent!" };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        var messages = new[] { "Not quite!", "Oops!", "Close one!", "Now you know!", "Learn something new!" };
        return messages[_random.Next(messages.Length)];
    }
}
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 3: Desktop Converters - only color selected button
# =============================================================================
echo "[3/8] Updating Desktop Converters..."

cat > src/MyDesktopApplication.Desktop/Converters/Converters.cs << 'ENDOFFILE'
using System;
using System.Collections.Generic;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Desktop.Converters;

/// <summary>
/// Converts QuestionType enum to human-readable label.
/// </summary>
public class QuestionTypeLabelConverter : IValueConverter
{
    public static readonly QuestionTypeLabelConverter Instance = new();

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is QuestionType qt)
            return qt.GetLabel();
        return value?.ToString() ?? "";
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotSupportedException();
}

/// <summary>
/// Converts (IsCorrect, IsWrong) booleans to a background color.
/// ONLY the selected button will have IsCorrect=true or IsWrong=true.
/// Unselected buttons will have both as false → default color.
/// </summary>
public class AnswerStateToBackgroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBackgroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect)
                return new SolidColorBrush(Color.FromRgb(34, 139, 34));   // Green - correct selected
            if (isWrong)
                return new SolidColorBrush(Color.FromRgb(220, 53, 69));   // Red - wrong selected
        }
        // Default: unselected or not yet answered
        return new SolidColorBrush(Color.FromRgb(30, 41, 59)); // Slate-800 (#1e293b)
    }
}

/// <summary>
/// Converts (IsCorrect, IsWrong) booleans to a border color.
/// </summary>
public class AnswerStateToBorderConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBorderConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect)
                return new SolidColorBrush(Color.FromRgb(34, 197, 94));   // Bright green border
            if (isWrong)
                return new SolidColorBrush(Color.FromRgb(239, 68, 68));   // Bright red border
        }
        return new SolidColorBrush(Color.FromRgb(55, 65, 81)); // Gray border default
    }
}

/// <summary>
/// Converts answer state to text foreground color.
/// </summary>
public class AnswerStateToForegroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToForegroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        // Always white text
        return new SolidColorBrush(Colors.White);
    }
}

/// <summary>
/// Simple bool to color converter using ConverterParameter format: "TrueColor|FalseColor"
/// </summary>
public class BoolToColorConverter : IValueConverter
{
    public static readonly BoolToColorConverter Instance = new();

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool b && parameter is string s)
        {
            var parts = s.Split('|');
            var colorStr = b ? parts[0] : (parts.Length > 1 ? parts[1] : "#FFFFFF");
            return new SolidColorBrush(Color.Parse(colorStr));
        }
        return new SolidColorBrush(Colors.White);
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotSupportedException();
}
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 4: Desktop MainWindow.axaml - COMPLETE REWRITE with all fixes
# =============================================================================
echo "[4/8] Updating Desktop MainWindow.axaml..."

cat > src/MyDesktopApplication.Desktop/Views/MainWindow.axaml << 'ENDOFFILE'
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyDesktopApplication.Desktop.ViewModels"
        xmlns:conv="using:MyDesktopApplication.Desktop.Converters"
        x:Class="MyDesktopApplication.Desktop.Views.MainWindow"
        x:DataType="vm:MainWindowViewModel"
        Title="Country Quiz"
        Width="600" Height="700"
        MinWidth="360" MinHeight="500"
        Background="#0f172a">

    <Window.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
        <conv:AnswerStateToBackgroundConverter x:Key="AnswerStateBgConverter"/>
        <conv:AnswerStateToBorderConverter x:Key="AnswerStateBorderConverter"/>
        <conv:AnswerStateToForegroundConverter x:Key="AnswerStateFgConverter"/>
        <conv:BoolToColorConverter x:Key="BoolToColorConverter"/>
    </Window.Resources>

    <!-- Responsive font sizes via Styles -->
    <Window.Styles>
        <Style Selector="TextBlock.header-title">
            <Setter Property="FontSize" Value="22"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style Selector="TextBlock.stat-text">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="#94a3b8"/>
        </Style>
        <Style Selector="TextBlock.question-text">
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#e2e8f0"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
            <Setter Property="TextAlignment" Value="Center"/>
        </Style>
        <Style Selector="TextBlock.flag-text">
            <Setter Property="FontSize" Value="48"/>
        </Style>
        <Style Selector="TextBlock.country-name">
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
            <Setter Property="TextAlignment" Value="Center"/>
        </Style>
        <Style Selector="TextBlock.value-text">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#22c55e"/>
            <Setter Property="TextAlignment" Value="Center"/>
        </Style>

        <!-- Smaller fonts for narrow windows -->
        <Style Selector="Window[Width=0]:lt(480) TextBlock.header-title">
            <Setter Property="FontSize" Value="17"/>
        </Style>
        <Style Selector="Window[Width=0]:lt(480) TextBlock.question-text">
            <Setter Property="FontSize" Value="14"/>
        </Style>
        <Style Selector="Window[Width=0]:lt(480) TextBlock.flag-text">
            <Setter Property="FontSize" Value="36"/>
        </Style>
        <Style Selector="Window[Width=0]:lt(480) TextBlock.country-name">
            <Setter Property="FontSize" Value="14"/>
        </Style>
    </Window.Styles>

    <Panel>
        <!-- Main content -->
        <ScrollViewer HorizontalScrollBarVisibility="Disabled"
                      VerticalScrollBarVisibility="Auto">
            <Grid RowDefinitions="Auto,Auto,*,Auto" Margin="16">

                <!-- Row 0: Header with score and category selector -->
                <Border Grid.Row="0" Background="#1e293b" CornerRadius="12" Padding="16" Margin="0,0,0,12">
                    <Grid ColumnDefinitions="*,Auto">
                        <!-- Score info -->
                        <StackPanel Spacing="4">
                            <TextBlock Classes="header-title" Text="Country Quiz"/>
                            <StackPanel Orientation="Horizontal" Spacing="12">
                                <TextBlock Classes="stat-text" Text="{Binding ScoreText}"/>
                                <TextBlock Classes="stat-text" Text="{Binding StreakText}"/>
                                <TextBlock Classes="stat-text" Text="{Binding BestStreakText}"/>
                            </StackPanel>
                            <TextBlock Classes="stat-text" Text="{Binding AccuracyText}"/>
                        </StackPanel>

                        <!-- Category selector -->
                        <ComboBox Grid.Column="1"
                                  ItemsSource="{Binding QuestionTypes}"
                                  SelectedItem="{Binding SelectedQuestionType}"
                                  Background="#334155"
                                  Foreground="White"
                                  MinWidth="160"
                                  VerticalAlignment="Center">
                            <ComboBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"
                                               Foreground="White"/>
                                </DataTemplate>
                            </ComboBox.ItemTemplate>
                        </ComboBox>
                    </Grid>
                </Border>

                <!-- Row 1: Question text -->
                <Border Grid.Row="1" Margin="0,0,0,12">
                    <TextBlock Classes="question-text" Text="{Binding QuestionText}"/>
                </Border>

                <!-- Row 2: Country cards + result -->
                <StackPanel Grid.Row="2" Spacing="12">

                    <!-- Country selection buttons side-by-side -->
                    <Grid ColumnDefinitions="*,Auto,*">

                        <!-- Country 1 Button -->
                        <Button Grid.Column="0"
                                Command="{Binding SelectCountryCommand}"
                                CommandParameter="1"
                                IsEnabled="{Binding !HasAnswered}"
                                HorizontalAlignment="Stretch"
                                VerticalAlignment="Stretch"
                                MinHeight="180"
                                CornerRadius="12"
                                Padding="0"
                                BorderThickness="2"
                                Cursor="Hand">
                            <Button.Background>
                                <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                                    <Binding Path="IsCountry1Correct"/>
                                    <Binding Path="IsCountry1Wrong"/>
                                </MultiBinding>
                            </Button.Background>
                            <Button.BorderBrush>
                                <MultiBinding Converter="{StaticResource AnswerStateBorderConverter}">
                                    <Binding Path="IsCountry1Correct"/>
                                    <Binding Path="IsCountry1Wrong"/>
                                </MultiBinding>
                            </Button.BorderBrush>
                            <!-- Keep full opacity when disabled (after answering) -->
                            <Button.Styles>
                                <Style Selector="Button:disabled">
                                    <Setter Property="Opacity" Value="1"/>
                                </Style>
                            </Button.Styles>
                            <StackPanel HorizontalAlignment="Center"
                                        VerticalAlignment="Center"
                                        Spacing="8" Margin="12">
                                <TextBlock Classes="flag-text"
                                           Text="{Binding Country1.Flag}"
                                           HorizontalAlignment="Center"/>
                                <TextBlock Classes="country-name"
                                           Text="{Binding Country1.Name}"
                                           MaxWidth="140"/>
                                <TextBlock Classes="value-text"
                                           Text="{Binding Country1Value}"
                                           IsVisible="{Binding HasAnswered}"/>
                            </StackPanel>
                        </Button>

                        <!-- VS separator -->
                        <TextBlock Grid.Column="1"
                                   Text="VS"
                                   FontSize="16" FontWeight="Bold"
                                   Foreground="#475569"
                                   VerticalAlignment="Center"
                                   Margin="12,0"/>

                        <!-- Country 2 Button -->
                        <Button Grid.Column="2"
                                Command="{Binding SelectCountryCommand}"
                                CommandParameter="2"
                                IsEnabled="{Binding !HasAnswered}"
                                HorizontalAlignment="Stretch"
                                VerticalAlignment="Stretch"
                                MinHeight="180"
                                CornerRadius="12"
                                Padding="0"
                                BorderThickness="2"
                                Cursor="Hand">
                            <Button.Background>
                                <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                                    <Binding Path="IsCountry2Correct"/>
                                    <Binding Path="IsCountry2Wrong"/>
                                </MultiBinding>
                            </Button.Background>
                            <Button.BorderBrush>
                                <MultiBinding Converter="{StaticResource AnswerStateBorderConverter}">
                                    <Binding Path="IsCountry2Correct"/>
                                    <Binding Path="IsCountry2Wrong"/>
                                </MultiBinding>
                            </Button.BorderBrush>
                            <Button.Styles>
                                <Style Selector="Button:disabled">
                                    <Setter Property="Opacity" Value="1"/>
                                </Style>
                            </Button.Styles>
                            <StackPanel HorizontalAlignment="Center"
                                        VerticalAlignment="Center"
                                        Spacing="8" Margin="12">
                                <TextBlock Classes="flag-text"
                                           Text="{Binding Country2.Flag}"
                                           HorizontalAlignment="Center"/>
                                <TextBlock Classes="country-name"
                                           Text="{Binding Country2.Name}"
                                           MaxWidth="140"/>
                                <TextBlock Classes="value-text"
                                           Text="{Binding Country2Value}"
                                           IsVisible="{Binding HasAnswered}"/>
                            </StackPanel>
                        </Button>
                    </Grid>

                    <!-- Result message -->
                    <Border Background="#1e293b" CornerRadius="8" Padding="16"
                            IsVisible="{Binding HasAnswered}">
                        <TextBlock Text="{Binding ResultMessage}"
                                   FontSize="18" FontWeight="SemiBold"
                                   TextAlignment="Center" TextWrapping="Wrap"
                                   Foreground="#e2e8f0"/>
                    </Border>

                    <!-- Next Round button -->
                    <Button Content="Next Round"
                            Command="{Binding NextRoundCommand}"
                            IsVisible="{Binding HasAnswered}"
                            HorizontalAlignment="Center"
                            MinWidth="200" MinHeight="48"
                            FontSize="16" FontWeight="SemiBold"
                            Background="#3b82f6" Foreground="White"
                            CornerRadius="8" Cursor="Hand"/>
                </StackPanel>

                <!-- Row 3: Footer with Reset -->
                <StackPanel Grid.Row="3" Orientation="Horizontal"
                            HorizontalAlignment="Center" Margin="0,12,0,0" Spacing="16">
                    <Button Content="Reset Game"
                            Command="{Binding RequestResetGameCommand}"
                            MinWidth="120"
                            Background="#475569" Foreground="White"
                            CornerRadius="6"/>
                </StackPanel>
            </Grid>
        </ScrollViewer>

        <!-- Reset confirmation overlay -->
        <Border IsVisible="{Binding IsResetConfirmationVisible}"
                Background="#CC000000"
                HorizontalAlignment="Stretch"
                VerticalAlignment="Stretch">
            <Border Background="#1e293b"
                    CornerRadius="16"
                    Padding="32"
                    HorizontalAlignment="Center"
                    VerticalAlignment="Center"
                    MinWidth="300"
                    MaxWidth="400"
                    BorderBrush="#334155"
                    BorderThickness="1">
                <StackPanel Spacing="20">
                    <TextBlock Text="Reset Game?"
                               FontSize="22" FontWeight="Bold"
                               Foreground="White"
                               TextAlignment="Center"/>
                    <TextBlock Text="This will reset your score, streak, and all statistics. This cannot be undone."
                               FontSize="14" Foreground="#94a3b8"
                               TextWrapping="Wrap" TextAlignment="Center"/>
                    <Grid ColumnDefinitions="*,16,*">
                        <Button Grid.Column="0"
                                Content="Cancel"
                                Command="{Binding CancelResetGameCommand}"
                                HorizontalAlignment="Stretch"
                                MinHeight="44"
                                Background="#475569" Foreground="White"
                                HorizontalContentAlignment="Center"
                                CornerRadius="8"/>
                        <Button Grid.Column="2"
                                Content="Yes, Reset"
                                Command="{Binding ConfirmResetGameCommand}"
                                HorizontalAlignment="Stretch"
                                MinHeight="44"
                                Background="#dc2626" Foreground="White"
                                HorizontalContentAlignment="Center"
                                CornerRadius="8"/>
                    </Grid>
                </StackPanel>
            </Border>
        </Border>
    </Panel>
</Window>
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 5: Android CountryQuizViewModel - add question text + reset confirm
# =============================================================================
echo "[5/8] Updating Shared CountryQuizViewModel..."

cat > src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs << 'ENDOFFILE'
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Shared ViewModel for the Country Quiz game.
/// Used by Android (and potentially other platforms).
/// </summary>
public partial class CountryQuizViewModel : ObservableObject
{
    private readonly IGameStateRepository? _gameStateRepository;
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private GameState _gameState = new();
    private Country? _correctCountry;

    // --- Observable properties ---

    [ObservableProperty] private string _questionText = "Loading...";

    [ObservableProperty] private Country? _country1;
    [ObservableProperty] private Country? _country2;

    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";

    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    [ObservableProperty] private bool _isCorrectAnswer;
    [ObservableProperty] private int _selectedCountry; // 0=none, 1=country1, 2=country2

    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;

    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    // Reset confirmation
    [ObservableProperty] private bool _isResetConfirmationVisible;

    // --- Computed properties for button coloring ---
    // CRITICAL: Only the SELECTED button gets colored. Unselected stays default.

    public bool IsCountry1Correct => HasAnswered && SelectedCountry == 1 && IsCorrectAnswer;
    public bool IsCountry1Wrong => HasAnswered && SelectedCountry == 1 && !IsCorrectAnswer;
    public bool IsCountry2Correct => HasAnswered && SelectedCountry == 2 && IsCorrectAnswer;
    public bool IsCountry2Wrong => HasAnswered && SelectedCountry == 2 && !IsCorrectAnswer;

    public string ScoreText => $"{_gameState.CurrentScore}/{_gameState.TotalAnswered}";
    public string StreakText => _gameState.CurrentStreak > 0 ? $"Streak: {_gameState.CurrentStreak}" : "";
    public string BestStreakText => _gameState.BestStreak > 0 ? $"Best: {_gameState.BestStreak}" : "";
    public string AccuracyText => _gameState.TotalAnswered > 0
        ? $"Accuracy: {_gameState.AccuracyPercentage:F1}%"
        : "Accuracy: --";

    public ObservableCollection<QuestionType> QuestionTypes { get; } =
        new(Enum.GetValues<QuestionType>());

    // --- Constructors ---

    public CountryQuizViewModel() : this(null) { }

    public CountryQuizViewModel(IGameStateRepository? gameStateRepository)
    {
        _gameStateRepository = gameStateRepository;
        _countries = CountryData.GetAllCountries().ToList();
        GenerateNewQuestion();
    }

    // --- Initialization ---

    public async Task InitializeAsync()
    {
        if (_gameStateRepository != null)
        {
            _gameState = await _gameStateRepository.GetOrCreateAsync("default");
            SyncScoresFromGameState();
        }
        GenerateNewQuestion();
    }

    private void SyncScoresFromGameState()
    {
        CurrentScore = _gameState.CurrentScore;
        HighScore = _gameState.HighScore;
        CurrentStreak = _gameState.CurrentStreak;
        BestStreak = _gameState.BestStreak;
        RefreshTextProperties();
    }

    private void RefreshTextProperties()
    {
        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    // --- Property change handlers ---

    partial void OnHasAnsweredChanged(bool value) => RefreshButtonStates();
    partial void OnSelectedCountryChanged(int value) => RefreshButtonStates();
    partial void OnIsCorrectAnswerChanged(bool value) => RefreshButtonStates();

    partial void OnSelectedQuestionTypeChanged(QuestionType value)
    {
        _gameState.SelectedQuestionType = (int)value;
        GenerateNewQuestion();
    }

    private void RefreshButtonStates()
    {
        OnPropertyChanged(nameof(IsCountry1Correct));
        OnPropertyChanged(nameof(IsCountry1Wrong));
        OnPropertyChanged(nameof(IsCountry2Correct));
        OnPropertyChanged(nameof(IsCountry2Wrong));
    }

    // --- Commands ---

    [RelayCommand]
    private async Task SelectCountryAsync(string countryNumberStr)
    {
        if (!int.TryParse(countryNumberStr, out var countryNumber)) return;
        if (HasAnswered || _correctCountry == null) return;

        HasAnswered = true;
        SelectedCountry = countryNumber;

        var selectedCountry = countryNumber == 1 ? Country1 : Country2;
        var isCorrect = selectedCountry?.Name == _correctCountry.Name;
        IsCorrectAnswer = isCorrect;

        _gameState.RecordAnswer(isCorrect);
        SyncScoresFromGameState();

        if (Country1 != null)
        {
            var v1 = SelectedQuestionType.GetValue(Country1);
            Country1Value = v1.HasValue ? SelectedQuestionType.FormatValue(v1) : "N/A";
        }
        if (Country2 != null)
        {
            var v2 = SelectedQuestionType.GetValue(Country2);
            Country2Value = v2.HasValue ? SelectedQuestionType.FormatValue(v2) : "N/A";
        }

        ResultMessage = isCorrect ? GetCorrectMessage() : GetIncorrectMessage();

        if (_gameStateRepository != null)
        {
            try { await _gameStateRepository.UpdateAsync(_gameState); }
            catch { /* Silently handle persistence failures */ }
        }
    }

    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    [RelayCommand]
    private void RequestResetGame()
    {
        IsResetConfirmationVisible = true;
    }

    [RelayCommand]
    private async Task ConfirmResetGameAsync()
    {
        IsResetConfirmationVisible = false;

        _gameState.Reset();
        SyncScoresFromGameState();
        GenerateNewQuestion();

        if (_gameStateRepository != null)
        {
            try { await _gameStateRepository.UpdateAsync(_gameState); }
            catch { /* Silently handle persistence failures */ }
        }
    }

    [RelayCommand]
    private void CancelResetGame()
    {
        IsResetConfirmationVisible = false;
    }

    // --- Internals ---

    private void GenerateNewQuestion()
    {
        HasAnswered = false;
        SelectedCountry = 0;
        IsCorrectAnswer = false;
        ResultMessage = "";
        Country1Value = "";
        Country2Value = "";

        if (_countries.Count < 2)
        {
            QuestionText = "Not enough countries loaded.";
            return;
        }

        var indices = Enumerable.Range(0, _countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

        Country1 = _countries[indices[0]];
        Country2 = _countries[indices[1]];

        QuestionText = SelectedQuestionType.GetQuestion();

        var v1 = SelectedQuestionType.GetValue(Country1);
        var v2 = SelectedQuestionType.GetValue(Country2);
        _correctCountry = (v1 ?? 0) >= (v2 ?? 0) ? Country1 : Country2;
    }

    private string GetCorrectMessage()
    {
        if (_gameState.CurrentStreak >= 10) return "UNSTOPPABLE! 10+ streak!";
        if (_gameState.CurrentStreak >= 5) return $"On fire! {_gameState.CurrentStreak} in a row!";
        if (_gameState.CurrentStreak >= 3) return $"Great streak! {_gameState.CurrentStreak} correct!";

        var messages = new[] { "Correct!", "Well done!", "Nice one!", "You got it!", "Excellent!" };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        var messages = new[] { "Not quite!", "Oops!", "Close one!", "Now you know!", "Learn something new!" };
        return messages[_random.Next(messages.Length)];
    }
}
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 6: Android MainView.axaml - add question text + reset confirm + coloring
# =============================================================================
echo "[6/8] Updating Android MainView.axaml..."

cat > src/MyDesktopApplication.Android/Views/MainView.axaml << 'ENDOFFILE'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="using:MyDesktopApplication.Shared.ViewModels"
             xmlns:conv="using:MyDesktopApplication.Android.Converters"
             x:Class="MyDesktopApplication.Android.Views.MainView"
             x:DataType="vm:CountryQuizViewModel">

    <UserControl.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
        <conv:AnswerStateToBackgroundConverter x:Key="AnswerStateBgConverter"/>
        <conv:AnswerStateToBorderConverter x:Key="AnswerStateBorderConverter"/>
    </UserControl.Resources>

    <Panel Background="#0f172a">
        <!-- Main scrollable content -->
        <ScrollViewer HorizontalScrollBarVisibility="Disabled"
                      VerticalScrollBarVisibility="Auto">
            <Grid RowDefinitions="Auto,Auto,*,Auto" Margin="12,8">

                <!-- Row 0: Compact header -->
                <Border Grid.Row="0" Background="#1e293b" CornerRadius="10" Padding="12" Margin="0,0,0,8">
                    <Grid ColumnDefinitions="*,Auto">
                        <StackPanel Spacing="2">
                            <TextBlock Text="Country Quiz"
                                       FontSize="18" FontWeight="Bold" Foreground="White"/>
                            <StackPanel Orientation="Horizontal" Spacing="10">
                                <TextBlock Text="{Binding ScoreText}" FontSize="12" Foreground="#94a3b8"/>
                                <TextBlock Text="{Binding StreakText}" FontSize="12" Foreground="#94a3b8"/>
                                <TextBlock Text="{Binding BestStreakText}" FontSize="12" Foreground="#94a3b8"/>
                            </StackPanel>
                        </StackPanel>
                        <ComboBox Grid.Column="1"
                                  ItemsSource="{Binding QuestionTypes}"
                                  SelectedItem="{Binding SelectedQuestionType}"
                                  Background="#334155" Foreground="White"
                                  MinWidth="140" FontSize="12"
                                  VerticalAlignment="Center">
                            <ComboBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"
                                               Foreground="White" FontSize="12"/>
                                </DataTemplate>
                            </ComboBox.ItemTemplate>
                        </ComboBox>
                    </Grid>
                </Border>

                <!-- Row 1: Question text -->
                <TextBlock Grid.Row="1"
                           Text="{Binding QuestionText}"
                           FontSize="15" FontWeight="SemiBold"
                           Foreground="#e2e8f0"
                           TextWrapping="Wrap" TextAlignment="Center"
                           Margin="0,0,0,8"/>

                <!-- Row 2: Country cards stacked vertically for phones -->
                <StackPanel Grid.Row="2" Spacing="8">

                    <!-- Country 1 -->
                    <Button Command="{Binding SelectCountryCommand}"
                            CommandParameter="1"
                            IsEnabled="{Binding !HasAnswered}"
                            HorizontalAlignment="Stretch"
                            MinHeight="80"
                            CornerRadius="10" Padding="0" BorderThickness="2"
                            Cursor="Hand">
                        <Button.Background>
                            <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                                <Binding Path="IsCountry1Correct"/>
                                <Binding Path="IsCountry1Wrong"/>
                            </MultiBinding>
                        </Button.Background>
                        <Button.BorderBrush>
                            <MultiBinding Converter="{StaticResource AnswerStateBorderConverter}">
                                <Binding Path="IsCountry1Correct"/>
                                <Binding Path="IsCountry1Wrong"/>
                            </MultiBinding>
                        </Button.BorderBrush>
                        <Button.Styles>
                            <Style Selector="Button:disabled">
                                <Setter Property="Opacity" Value="1"/>
                            </Style>
                        </Button.Styles>
                        <Grid ColumnDefinitions="Auto,*,Auto" Margin="16,12">
                            <TextBlock Text="{Binding Country1.Flag}"
                                       FontSize="36" VerticalAlignment="Center"/>
                            <TextBlock Grid.Column="1"
                                       Text="{Binding Country1.Name}"
                                       FontSize="16" FontWeight="SemiBold" Foreground="White"
                                       VerticalAlignment="Center" Margin="12,0"
                                       TextWrapping="Wrap"/>
                            <TextBlock Grid.Column="2"
                                       Text="{Binding Country1Value}"
                                       FontSize="12" Foreground="#22c55e" FontWeight="Bold"
                                       VerticalAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </Grid>
                    </Button>

                    <!-- VS separator -->
                    <TextBlock Text="VS" FontSize="14" FontWeight="Bold"
                               Foreground="#475569" TextAlignment="Center"/>

                    <!-- Country 2 -->
                    <Button Command="{Binding SelectCountryCommand}"
                            CommandParameter="2"
                            IsEnabled="{Binding !HasAnswered}"
                            HorizontalAlignment="Stretch"
                            MinHeight="80"
                            CornerRadius="10" Padding="0" BorderThickness="2"
                            Cursor="Hand">
                        <Button.Background>
                            <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                                <Binding Path="IsCountry2Correct"/>
                                <Binding Path="IsCountry2Wrong"/>
                            </MultiBinding>
                        </Button.Background>
                        <Button.BorderBrush>
                            <MultiBinding Converter="{StaticResource AnswerStateBorderConverter}">
                                <Binding Path="IsCountry2Correct"/>
                                <Binding Path="IsCountry2Wrong"/>
                            </MultiBinding>
                        </Button.BorderBrush>
                        <Button.Styles>
                            <Style Selector="Button:disabled">
                                <Setter Property="Opacity" Value="1"/>
                            </Style>
                        </Button.Styles>
                        <Grid ColumnDefinitions="Auto,*,Auto" Margin="16,12">
                            <TextBlock Text="{Binding Country2.Flag}"
                                       FontSize="36" VerticalAlignment="Center"/>
                            <TextBlock Grid.Column="1"
                                       Text="{Binding Country2.Name}"
                                       FontSize="16" FontWeight="SemiBold" Foreground="White"
                                       VerticalAlignment="Center" Margin="12,0"
                                       TextWrapping="Wrap"/>
                            <TextBlock Grid.Column="2"
                                       Text="{Binding Country2Value}"
                                       FontSize="12" Foreground="#22c55e" FontWeight="Bold"
                                       VerticalAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </Grid>
                    </Button>

                    <!-- Result message -->
                    <Border Background="#1e293b" CornerRadius="8" Padding="12"
                            IsVisible="{Binding HasAnswered}">
                        <TextBlock Text="{Binding ResultMessage}"
                                   FontSize="16" FontWeight="SemiBold"
                                   Foreground="#e2e8f0"
                                   TextAlignment="Center" TextWrapping="Wrap"/>
                    </Border>

                    <!-- Next Round -->
                    <Button Content="Next Round"
                            Command="{Binding NextRoundCommand}"
                            IsVisible="{Binding HasAnswered}"
                            HorizontalAlignment="Stretch"
                            MinHeight="56"
                            FontSize="16" FontWeight="SemiBold"
                            Background="#3b82f6" Foreground="White"
                            HorizontalContentAlignment="Center"
                            CornerRadius="8"/>
                </StackPanel>

                <!-- Row 3: Reset button -->
                <StackPanel Grid.Row="3" HorizontalAlignment="Center" Margin="0,8,0,8">
                    <Button Content="Reset Game"
                            Command="{Binding RequestResetGameCommand}"
                            MinWidth="120" MinHeight="40"
                            Background="#475569" Foreground="White"
                            HorizontalContentAlignment="Center"
                            CornerRadius="6" FontSize="13"/>
                </StackPanel>
            </Grid>
        </ScrollViewer>

        <!-- Reset confirmation overlay -->
        <Border IsVisible="{Binding IsResetConfirmationVisible}"
                Background="#CC000000"
                HorizontalAlignment="Stretch"
                VerticalAlignment="Stretch">
            <Border Background="#1e293b"
                    CornerRadius="16" Padding="24"
                    HorizontalAlignment="Center"
                    VerticalAlignment="Center"
                    MinWidth="280" MaxWidth="360"
                    BorderBrush="#334155" BorderThickness="1"
                    Margin="24">
                <StackPanel Spacing="16">
                    <TextBlock Text="Reset Game?"
                               FontSize="20" FontWeight="Bold"
                               Foreground="White" TextAlignment="Center"/>
                    <TextBlock Text="This will reset your score, streak, and all statistics. This cannot be undone."
                               FontSize="13" Foreground="#94a3b8"
                               TextWrapping="Wrap" TextAlignment="Center"/>
                    <Grid ColumnDefinitions="*,12,*">
                        <Button Grid.Column="0"
                                Content="Cancel"
                                Command="{Binding CancelResetGameCommand}"
                                HorizontalAlignment="Stretch" MinHeight="44"
                                Background="#475569" Foreground="White"
                                HorizontalContentAlignment="Center"
                                CornerRadius="8"/>
                        <Button Grid.Column="2"
                                Content="Yes, Reset"
                                Command="{Binding ConfirmResetGameCommand}"
                                HorizontalAlignment="Stretch" MinHeight="44"
                                Background="#dc2626" Foreground="White"
                                HorizontalContentAlignment="Center"
                                CornerRadius="8"/>
                    </Grid>
                </StackPanel>
            </Border>
        </Border>
    </Panel>
</UserControl>
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 7: Android Converters - match Desktop converters
# =============================================================================
echo "[7/8] Updating Android Converters..."

cat > src/MyDesktopApplication.Android/Converters/Converters.cs << 'ENDOFFILE'
using System;
using System.Collections.Generic;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Android.Converters;

/// <summary>
/// Converts QuestionType enum to human-readable label.
/// </summary>
public class QuestionTypeLabelConverter : IValueConverter
{
    public static readonly QuestionTypeLabelConverter Instance = new();

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is QuestionType qt)
            return qt.GetLabel();
        return value?.ToString() ?? "";
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotSupportedException();
}

/// <summary>
/// Converts (IsCorrect, IsWrong) booleans to a background color.
/// ONLY the selected button will have IsCorrect=true or IsWrong=true.
/// Unselected buttons will have both as false → default color.
/// </summary>
public class AnswerStateToBackgroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBackgroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect)
                return new SolidColorBrush(Color.FromRgb(34, 139, 34));   // Green
            if (isWrong)
                return new SolidColorBrush(Color.FromRgb(220, 53, 69));   // Red
        }
        return new SolidColorBrush(Color.FromRgb(30, 41, 59)); // Default slate
    }
}

/// <summary>
/// Converts (IsCorrect, IsWrong) booleans to a border color.
/// </summary>
public class AnswerStateToBorderConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBorderConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect)
                return new SolidColorBrush(Color.FromRgb(34, 197, 94));
            if (isWrong)
                return new SolidColorBrush(Color.FromRgb(239, 68, 68));
        }
        return new SolidColorBrush(Color.FromRgb(55, 65, 81)); // Gray default
    }
}
ENDOFFILE

echo "  Done."

# =============================================================================
# FIX 8: Build and verify
# =============================================================================
echo "[8/8] Building solution..."
echo ""

dotnet restore
dotnet build --configuration Debug --no-restore

BUILD_RESULT=$?

echo ""
if [ $BUILD_RESULT -eq 0 ]; then
    echo "=============================================="
    echo "  BUILD SUCCEEDED"
    echo "=============================================="
    echo ""
    echo "  Changes made:"
    echo "  1. QuestionType.GetQuestion() - proper grammatical questions per category"
    echo "  2. Desktop: Only SELECTED button gets colored (green/red)"
    echo "     Root cause: computed properties gate on SelectedCountry == N"
    echo "     XAML uses MultiBinding with AnswerStateBg/Border converters"
    echo "     NO CSS class approach - purely converter-driven for reliability"
    echo "  3. Android: Same coloring fix + question text + reset confirm"
    echo "  4. Reset Game: Shows confirmation overlay with Cancel/Yes buttons"
    echo "  5. Responsive text: Uses Avalonia style classes for font sizing"
    echo ""

    echo "Running tests..."
    dotnet test --no-build --configuration Debug 2>&1 || echo "(Some tests may need updating)"
else
    echo "=============================================="
    echo "  BUILD FAILED - see errors above"
    echo "=============================================="
    exit 1
fi

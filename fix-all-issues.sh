#!/bin/bash
# =============================================================================
# fix-all-issues.sh - Comprehensive fixes for MyDesktopApplication
# =============================================================================
# Fixes:
# 1. Answer highlighting - only highlight the selected answer (not both)
# 2. Remove emojis from UI buttons (Next Round, etc.) - use plain text
# 3. Fix Android versioning for proper updates via Obtanium
# =============================================================================

set -e
cd "$(dirname "$0")"

echo "=============================================="
echo "  MyDesktopApplication - Comprehensive Fix"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# Cleanup: Kill stuck processes and clean build artifacts
# -----------------------------------------------------------------------------
echo "[1/8] Cleaning up stuck processes and build artifacts..."
pkill -9 aapt2 2>/dev/null || true
pkill -9 VBCSCompiler 2>/dev/null || true
dotnet clean --verbosity quiet 2>/dev/null || true
find . -type d -name "obj" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true
echo "✓ Cleanup complete"

# -----------------------------------------------------------------------------
# Fix 1: Update CountryQuizViewModel - Only highlight selected answer
# -----------------------------------------------------------------------------
echo "[2/8] Updating CountryQuizViewModel (answer highlighting fix)..."

cat > src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs << 'EOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// ViewModel for the Country Quiz game.
/// Shared between Desktop and Android platforms.
/// </summary>
public partial class CountryQuizViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();

    // Backing fields for country references (not observable - we expose flat properties)
    private Country? _country1;
    private Country? _country2;

    // Observable properties for UI binding
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Flag = "";
    [ObservableProperty] private string _country2Flag = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;
    
    // Answer state - FIX: Only highlight the selected answer
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;
    
    // Score tracking
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;
    
    // Question type selection
    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;
    [ObservableProperty] private ObservableCollection<QuestionType> _questionTypes = new();

    // Computed properties for UI display
    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    /// <summary>
    /// Constructor with dependency injection for game state persistence.
    /// </summary>
    public CountryQuizViewModel(IGameStateRepository gameStateRepository) : this()
    {
        _gameStateRepository = gameStateRepository;
    }

    /// <summary>
    /// Parameterless constructor for design-time and default initialization.
    /// </summary>
    public CountryQuizViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        foreach (QuestionType qt in Enum.GetValues<QuestionType>())
        {
            QuestionTypes.Add(qt);
        }
        GenerateNewQuestion();
    }

    /// <summary>
    /// Initialize async - loads persisted game state from database.
    /// </summary>
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

    /// <summary>
    /// Handle country selection.
    /// FIX: Only highlight the answer the user selected, not both answers.
    /// </summary>
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
        
        // FIX: Only highlight the selected answer
        // Reset all states first
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;

        if (countryNumber == 1)
        {
            // User selected Country 1
            isCorrect = value1 >= value2;
            // Only set state for Country 1 (the selected one)
            IsCountry1Correct = isCorrect;
            IsCountry1Wrong = !isCorrect;
            // Do NOT set Country 2 state - leave it unhighlighted
        }
        else
        {
            // User selected Country 2
            isCorrect = value2 >= value1;
            // Only set state for Country 2 (the selected one)
            IsCountry2Correct = isCorrect;
            IsCountry2Wrong = !isCorrect;
            // Do NOT set Country 1 state - leave it unhighlighted
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

        // Persist game state
        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
        _gameState.RecordAnswer(isCorrect);

        if (_gameStateRepository != null)
        {
            try
            {
                await _gameStateRepository.UpdateAsync(_gameState);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error saving game state: {ex.Message}");
            }
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
        OnPropertyChanged(nameof(BestStreakText));
        OnPropertyChanged(nameof(AccuracyText));
    }

    /// <summary>
    /// Start a new round with new countries.
    /// </summary>
    [RelayCommand]
    private void NextRound()
    {
        GenerateNewQuestion();
    }

    /// <summary>
    /// Change the question type and generate a new question.
    /// </summary>
    [RelayCommand]
    private void ChangeQuestionType(QuestionType newType)
    {
        SelectedQuestionType = newType;
        GenerateNewQuestion();
    }

    /// <summary>
    /// Reset the game to initial state.
    /// </summary>
    [RelayCommand]
    private async Task ResetGame()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalQuestions = 0;
        
        _gameState.CurrentScore = 0;
        _gameState.CurrentStreak = 0;
        
        if (_gameStateRepository != null)
        {
            try
            {
                await _gameStateRepository.UpdateAsync(_gameState);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error resetting game state: {ex.Message}");
            }
        }
        
        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
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

        // Pick two different random countries
        var indices = Enumerable.Range(0, _countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();
        
        _country1 = _countries[indices[0]];
        _country2 = _countries[indices[1]];

        Country1Name = _country1.Name;
        Country2Name = _country2.Name;
        Country1Flag = _country1.Flag;
        Country2Flag = _country2.Flag;

        QuestionText = $"Which country has a higher {SelectedQuestionType.GetLabel()}?";
    }

    // FIX: Remove emojis - use plain text messages instead
    private string GetCorrectMessage()
    {
        var messages = new[]
        {
            "Correct!",
            "Well done!",
            "Great job!",
            "Excellent!",
            CurrentStreak >= 5 ? $"{CurrentStreak} in a row!" : "Keep it up!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        return "Not quite! The correct answer is shown above.";
    }
}
EOF

echo "✓ CountryQuizViewModel updated"

# -----------------------------------------------------------------------------
# Fix 2: Update Android MainView.axaml - Remove emojis, fix button text
# -----------------------------------------------------------------------------
echo "[3/8] Updating Android MainView.axaml (remove emojis)..."

cat > src/MyDesktopApplication.Android/Views/MainView.axaml << 'EOF'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="using:MyDesktopApplication.Shared.ViewModels"
             xmlns:conv="using:MyDesktopApplication.Android.Converters"
             x:Class="MyDesktopApplication.Android.Views.MainView"
             x:DataType="vm:CountryQuizViewModel">

    <UserControl.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
        <conv:AnswerStateToBackgroundConverter x:Key="AnswerStateBgConverter"/>
        <conv:AnswerStateToForegroundConverter x:Key="AnswerStateFgConverter"/>
    </UserControl.Resources>

    <ScrollViewer>
        <StackPanel Margin="16" Spacing="12">
            
            <!-- Header with Score -->
            <Border Background="#1E3A5F" CornerRadius="12" Padding="16">
                <Grid ColumnDefinitions="*,Auto">
                    <StackPanel>
                        <TextBlock Text="Country Quiz" 
                                   FontSize="24" FontWeight="Bold" Foreground="White"/>
                        <TextBlock Text="{Binding AccuracyText}" 
                                   FontSize="14" Foreground="#B0C4DE"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" HorizontalAlignment="Right">
                        <TextBlock Text="{Binding ScoreText}" 
                                   FontSize="18" FontWeight="SemiBold" Foreground="White"/>
                        <TextBlock Text="{Binding StreakText}" 
                                   FontSize="14" Foreground="#90EE90"/>
                        <TextBlock Text="{Binding BestStreakText}" 
                                   FontSize="12" Foreground="#FFD700"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Question Type Selector -->
            <Border Background="#2D4A6A" CornerRadius="8" Padding="12">
                <StackPanel>
                    <TextBlock Text="Category:" FontSize="14" Foreground="#B0C4DE" Margin="0,0,0,8"/>
                    <ComboBox ItemsSource="{Binding QuestionTypes}"
                              SelectedItem="{Binding SelectedQuestionType}"
                              HorizontalAlignment="Stretch"
                              MinHeight="48">
                        <ComboBox.ItemTemplate>
                            <DataTemplate>
                                <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"
                                           FontSize="16"/>
                            </DataTemplate>
                        </ComboBox.ItemTemplate>
                    </ComboBox>
                </StackPanel>
            </Border>

            <!-- Question Text -->
            <TextBlock Text="{Binding QuestionText}"
                       FontSize="20" FontWeight="SemiBold"
                       TextAlignment="Center" TextWrapping="Wrap"
                       Foreground="White" Margin="0,8"/>

            <!-- Country Cards - Full Width for Easy Tapping -->
            <Button Command="{Binding SelectCountryCommand}"
                    CommandParameter="1"
                    HorizontalAlignment="Stretch"
                    HorizontalContentAlignment="Stretch"
                    MinHeight="80"
                    Padding="0"
                    CornerRadius="12">
                <Button.Background>
                    <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                        <Binding Path="IsCountry1Correct"/>
                        <Binding Path="IsCountry1Wrong"/>
                    </MultiBinding>
                </Button.Background>
                <Border Padding="16" HorizontalAlignment="Stretch">
                    <Grid ColumnDefinitions="Auto,*,Auto">
                        <TextBlock Text="{Binding Country1Flag}" 
                                   FontSize="40" VerticalAlignment="Center"/>
                        <StackPanel Grid.Column="1" Margin="16,0" VerticalAlignment="Center">
                            <TextBlock Text="{Binding Country1Name}" 
                                       FontSize="20" FontWeight="SemiBold">
                                <TextBlock.Foreground>
                                    <MultiBinding Converter="{StaticResource AnswerStateFgConverter}">
                                        <Binding Path="IsCountry1Correct"/>
                                        <Binding Path="IsCountry1Wrong"/>
                                    </MultiBinding>
                                </TextBlock.Foreground>
                            </TextBlock>
                            <TextBlock Text="{Binding Country1Value}"
                                       FontSize="14" Foreground="#B0C4DE"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                        <TextBlock Grid.Column="2" Text="[1]" 
                                   FontSize="14" Foreground="#666"
                                   VerticalAlignment="Center"/>
                    </Grid>
                </Border>
            </Button>

            <!-- VS Separator -->
            <TextBlock Text="VS" FontSize="16" FontWeight="Bold"
                       TextAlignment="Center" Foreground="#666"/>

            <Button Command="{Binding SelectCountryCommand}"
                    CommandParameter="2"
                    HorizontalAlignment="Stretch"
                    HorizontalContentAlignment="Stretch"
                    MinHeight="80"
                    Padding="0"
                    CornerRadius="12">
                <Button.Background>
                    <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                        <Binding Path="IsCountry2Correct"/>
                        <Binding Path="IsCountry2Wrong"/>
                    </MultiBinding>
                </Button.Background>
                <Border Padding="16" HorizontalAlignment="Stretch">
                    <Grid ColumnDefinitions="Auto,*,Auto">
                        <TextBlock Text="{Binding Country2Flag}" 
                                   FontSize="40" VerticalAlignment="Center"/>
                        <StackPanel Grid.Column="1" Margin="16,0" VerticalAlignment="Center">
                            <TextBlock Text="{Binding Country2Name}" 
                                       FontSize="20" FontWeight="SemiBold">
                                <TextBlock.Foreground>
                                    <MultiBinding Converter="{StaticResource AnswerStateFgConverter}">
                                        <Binding Path="IsCountry2Correct"/>
                                        <Binding Path="IsCountry2Wrong"/>
                                    </MultiBinding>
                                </TextBlock.Foreground>
                            </TextBlock>
                            <TextBlock Text="{Binding Country2Value}"
                                       FontSize="14" Foreground="#B0C4DE"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                        <TextBlock Grid.Column="2" Text="[2]" 
                                   FontSize="14" Foreground="#666"
                                   VerticalAlignment="Center"/>
                    </Grid>
                </Border>
            </Button>

            <!-- Result Message -->
            <TextBlock Text="{Binding ResultMessage}"
                       FontSize="18" FontWeight="SemiBold"
                       TextAlignment="Center"
                       Foreground="#90EE90"
                       IsVisible="{Binding HasAnswered}"
                       Margin="0,8"/>

            <!-- Next Round Button - NO EMOJIS -->
            <Button Content="Next Round"
                    Command="{Binding NextRoundCommand}"
                    IsVisible="{Binding HasAnswered}"
                    HorizontalAlignment="Stretch"
                    MinHeight="56"
                    FontSize="18"
                    FontWeight="SemiBold"
                    Background="#4CAF50"
                    Foreground="White"
                    CornerRadius="12"/>

            <!-- Reset Button -->
            <Button Content="Reset Game"
                    Command="{Binding ResetGameCommand}"
                    HorizontalAlignment="Stretch"
                    MinHeight="48"
                    FontSize="14"
                    Background="#666"
                    Foreground="White"
                    CornerRadius="8"
                    Margin="0,16,0,0"/>
                    
        </StackPanel>
    </ScrollViewer>
</UserControl>
EOF

echo "✓ Android MainView.axaml updated"

# -----------------------------------------------------------------------------
# Fix 3: Update Android Converters with proper answer state handling
# -----------------------------------------------------------------------------
echo "[4/8] Updating Android Converters..."

cat > src/MyDesktopApplication.Android/Converters/Converters.cs << 'EOF'
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

/// <summary>
/// Converts answer state (IsCorrect, IsWrong) to background color.
/// Only colors the selected answer - unselected answers stay default.
/// </summary>
public class AnswerStateToBackgroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBackgroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect)
                return new SolidColorBrush(Color.FromRgb(76, 175, 80)); // Green #4CAF50
            if (isWrong)
                return new SolidColorBrush(Color.FromRgb(244, 67, 54)); // Red #F44336
        }
        // Default - not selected or not answered yet
        return new SolidColorBrush(Color.FromRgb(45, 74, 106)); // Dark blue #2D4A6A
    }
}

/// <summary>
/// Converts answer state to foreground (text) color.
/// </summary>
public class AnswerStateToForegroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToForegroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect || isWrong)
                return new SolidColorBrush(Colors.White);
        }
        // Default text color
        return new SolidColorBrush(Colors.White);
    }
}
EOF

echo "✓ Android Converters updated"

# -----------------------------------------------------------------------------
# Fix 4: Update Desktop MainWindow.axaml - Remove emojis
# -----------------------------------------------------------------------------
echo "[5/8] Updating Desktop MainWindow.axaml (remove emojis)..."

cat > src/MyDesktopApplication.Desktop/Views/MainWindow.axaml << 'EOF'
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyDesktopApplication.Desktop.ViewModels"
        xmlns:conv="using:MyDesktopApplication.Desktop.Converters"
        x:Class="MyDesktopApplication.Desktop.Views.MainWindow"
        x:DataType="vm:MainWindowViewModel"
        Title="Country Quiz"
        Width="800" Height="600"
        MinWidth="600" MinHeight="500"
        Background="#1a1a2e">

    <Window.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
        <conv:AnswerStateToBackgroundConverter x:Key="AnswerStateBgConverter"/>
        <conv:AnswerStateToForegroundConverter x:Key="AnswerStateFgConverter"/>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#16213e" CornerRadius="12" Padding="20" Margin="0,0,0,16">
            <Grid ColumnDefinitions="*,Auto">
                <StackPanel>
                    <TextBlock Text="Country Quiz" FontSize="28" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Text="{Binding AccuracyText}" FontSize="14" Foreground="#a0a0a0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" HorizontalAlignment="Right">
                    <TextBlock Text="{Binding ScoreText}" FontSize="20" FontWeight="SemiBold" Foreground="White"/>
                    <TextBlock Text="{Binding StreakText}" FontSize="14" Foreground="#90EE90"/>
                    <TextBlock Text="{Binding BestStreakText}" FontSize="12" Foreground="#FFD700"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Question Type Selector -->
        <Border Grid.Row="1" Background="#16213e" CornerRadius="8" Padding="16" Margin="0,0,0,16">
            <StackPanel Orientation="Horizontal" Spacing="12">
                <TextBlock Text="Category:" FontSize="14" Foreground="#a0a0a0" VerticalAlignment="Center"/>
                <ComboBox ItemsSource="{Binding QuestionTypes}"
                          SelectedItem="{Binding SelectedQuestionType}"
                          MinWidth="200">
                    <ComboBox.ItemTemplate>
                        <DataTemplate>
                            <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"/>
                        </DataTemplate>
                    </ComboBox.ItemTemplate>
                </ComboBox>
            </StackPanel>
        </Border>

        <!-- Main Game Area -->
        <Border Grid.Row="2" Background="#16213e" CornerRadius="12" Padding="24">
            <StackPanel VerticalAlignment="Center" Spacing="20">
                
                <!-- Question -->
                <TextBlock Text="{Binding QuestionText}"
                           FontSize="24" FontWeight="SemiBold"
                           TextAlignment="Center" TextWrapping="Wrap"
                           Foreground="White"/>

                <!-- Country Cards -->
                <Grid ColumnDefinitions="*,Auto,*">
                    <!-- Country 1 -->
                    <Button Grid.Column="0"
                            Command="{Binding SelectCountryCommand}"
                            CommandParameter="1"
                            HorizontalAlignment="Stretch"
                            VerticalAlignment="Stretch"
                            MinHeight="150"
                            Padding="0"
                            CornerRadius="12">
                        <Button.Background>
                            <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                                <Binding Path="IsCountry1Correct"/>
                                <Binding Path="IsCountry1Wrong"/>
                            </MultiBinding>
                        </Button.Background>
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center" Margin="16">
                            <TextBlock Text="{Binding Country1Flag}" FontSize="48" TextAlignment="Center"/>
                            <TextBlock Text="{Binding Country1Name}" FontSize="20" FontWeight="SemiBold" TextAlignment="Center">
                                <TextBlock.Foreground>
                                    <MultiBinding Converter="{StaticResource AnswerStateFgConverter}">
                                        <Binding Path="IsCountry1Correct"/>
                                        <Binding Path="IsCountry1Wrong"/>
                                    </MultiBinding>
                                </TextBlock.Foreground>
                            </TextBlock>
                            <TextBlock Text="{Binding Country1Value}"
                                       FontSize="14" Foreground="#a0a0a0" TextAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                    </Button>

                    <!-- VS -->
                    <TextBlock Grid.Column="1" Text="VS" FontSize="20" FontWeight="Bold"
                               VerticalAlignment="Center" Foreground="#666" Margin="20,0"/>

                    <!-- Country 2 -->
                    <Button Grid.Column="2"
                            Command="{Binding SelectCountryCommand}"
                            CommandParameter="2"
                            HorizontalAlignment="Stretch"
                            VerticalAlignment="Stretch"
                            MinHeight="150"
                            Padding="0"
                            CornerRadius="12">
                        <Button.Background>
                            <MultiBinding Converter="{StaticResource AnswerStateBgConverter}">
                                <Binding Path="IsCountry2Correct"/>
                                <Binding Path="IsCountry2Wrong"/>
                            </MultiBinding>
                        </Button.Background>
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center" Margin="16">
                            <TextBlock Text="{Binding Country2Flag}" FontSize="48" TextAlignment="Center"/>
                            <TextBlock Text="{Binding Country2Name}" FontSize="20" FontWeight="SemiBold" TextAlignment="Center">
                                <TextBlock.Foreground>
                                    <MultiBinding Converter="{StaticResource AnswerStateFgConverter}">
                                        <Binding Path="IsCountry2Correct"/>
                                        <Binding Path="IsCountry2Wrong"/>
                                    </MultiBinding>
                                </TextBlock.Foreground>
                            </TextBlock>
                            <TextBlock Text="{Binding Country2Value}"
                                       FontSize="14" Foreground="#a0a0a0" TextAlignment="Center"
                                       IsVisible="{Binding HasAnswered}"/>
                        </StackPanel>
                    </Button>
                </Grid>

                <!-- Result -->
                <TextBlock Text="{Binding ResultMessage}"
                           FontSize="20" FontWeight="SemiBold"
                           TextAlignment="Center"
                           Foreground="#90EE90"
                           IsVisible="{Binding HasAnswered}"/>

                <!-- Next Round Button - NO EMOJIS -->
                <Button Content="Next Round"
                        Command="{Binding NextRoundCommand}"
                        IsVisible="{Binding HasAnswered}"
                        HorizontalAlignment="Center"
                        MinWidth="200" MinHeight="48"
                        FontSize="16" FontWeight="SemiBold"
                        Background="#4CAF50"
                        Foreground="White"
                        CornerRadius="8"/>
            </StackPanel>
        </Border>

        <!-- Footer -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,16,0,0" Spacing="16">
            <Button Content="Reset Game"
                    Command="{Binding ResetGameCommand}"
                    MinWidth="120"
                    Background="#666"
                    Foreground="White"/>
        </StackPanel>
    </Grid>
</Window>
EOF

echo "✓ Desktop MainWindow.axaml updated"

# -----------------------------------------------------------------------------
# Fix 5: Update Desktop Converters
# -----------------------------------------------------------------------------
echo "[6/8] Updating Desktop Converters..."

cat > src/MyDesktopApplication.Desktop/Converters/Converters.cs << 'EOF'
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

/// <summary>
/// Converts answer state (IsCorrect, IsWrong) to background color.
/// Only colors the selected answer - unselected answers stay default.
/// </summary>
public class AnswerStateToBackgroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBackgroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect)
                return new SolidColorBrush(Color.FromRgb(76, 175, 80)); // Green #4CAF50
            if (isWrong)
                return new SolidColorBrush(Color.FromRgb(244, 67, 54)); // Red #F44336
        }
        // Default - not selected or not answered yet
        return new SolidColorBrush(Color.FromRgb(30, 58, 95)); // Dark blue #1E3A5F
    }
}

/// <summary>
/// Converts answer state to foreground (text) color.
/// </summary>
public class AnswerStateToForegroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToForegroundConverter Instance = new();

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect || isWrong)
                return new SolidColorBrush(Colors.White);
        }
        // Default text color
        return new SolidColorBrush(Colors.White);
    }
}
EOF

echo "✓ Desktop Converters updated"

# -----------------------------------------------------------------------------
# Fix 6: Update Desktop MainWindowViewModel to match shared patterns
# -----------------------------------------------------------------------------
echo "[7/8] Updating Desktop MainWindowViewModel..."

cat > src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs << 'EOF'
using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Data;

namespace MyDesktopApplication.Desktop.ViewModels;

/// <summary>
/// ViewModel for the Desktop main window.
/// Implements the same quiz logic as CountryQuizViewModel for consistency.
/// </summary>
public partial class MainWindowViewModel : ViewModelBase
{
    private readonly Random _random = new();
    private readonly List<Country> _countries;
    private readonly IGameStateRepository? _gameStateRepository;
    private GameState _gameState = new();

    private Country? _country1;
    private Country? _country2;

    [ObservableProperty] private string _greeting = "Welcome to Country Quiz!";
    [ObservableProperty] private string _questionText = "Loading...";
    [ObservableProperty] private string _country1Name = "";
    [ObservableProperty] private string _country2Name = "";
    [ObservableProperty] private string _country1Flag = "";
    [ObservableProperty] private string _country2Flag = "";
    [ObservableProperty] private string _country1Value = "";
    [ObservableProperty] private string _country2Value = "";
    [ObservableProperty] private string _resultMessage = "";
    [ObservableProperty] private bool _hasAnswered;

    // Answer states - only highlight selected answer
    [ObservableProperty] private bool _isCountry1Correct;
    [ObservableProperty] private bool _isCountry1Wrong;
    [ObservableProperty] private bool _isCountry2Correct;
    [ObservableProperty] private bool _isCountry2Wrong;

    // Scores
    [ObservableProperty] private int _currentScore;
    [ObservableProperty] private int _highScore;
    [ObservableProperty] private int _currentStreak;
    [ObservableProperty] private int _bestStreak;
    [ObservableProperty] private int _totalQuestions;

    [ObservableProperty] private QuestionType _selectedQuestionType = QuestionType.Population;

    public ObservableCollection<QuestionType> QuestionTypes { get; } = new(Enum.GetValues<QuestionType>());

    public string ScoreText => $"Score: {CurrentScore}";
    public string StreakText => $"Streak: {CurrentStreak}";
    public string BestStreakText => $"Best: {BestStreak}";
    public string AccuracyText => TotalQuestions > 0
        ? $"Accuracy: {(double)CurrentScore / TotalQuestions * 100:N1}%"
        : "Accuracy: --";

    public MainWindowViewModel()
    {
        _countries = CountryData.GetAllCountries().ToList();
        GenerateNewQuestion();
    }

    public MainWindowViewModel(IGameStateRepository gameStateRepository) : this()
    {
        _gameStateRepository = gameStateRepository;
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
                HighScore = _gameState.HighScore;
                OnPropertyChanged(nameof(ScoreText));
                OnPropertyChanged(nameof(StreakText));
                OnPropertyChanged(nameof(BestStreakText));
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

        // FIX: Only highlight the selected answer
        IsCountry1Correct = false;
        IsCountry1Wrong = false;
        IsCountry2Correct = false;
        IsCountry2Wrong = false;

        bool isCorrect;
        if (countryNumber == 1)
        {
            isCorrect = value1 >= value2;
            IsCountry1Correct = isCorrect;
            IsCountry1Wrong = !isCorrect;
        }
        else
        {
            isCorrect = value2 >= value1;
            IsCountry2Correct = isCorrect;
            IsCountry2Wrong = !isCorrect;
        }

        if (isCorrect)
        {
            CurrentScore++;
            CurrentStreak++;
            if (CurrentStreak > BestStreak)
                BestStreak = CurrentStreak;
            if (CurrentScore > HighScore)
                HighScore = CurrentScore;
            ResultMessage = GetCorrectMessage();
        }
        else
        {
            CurrentStreak = 0;
            ResultMessage = GetIncorrectMessage();
        }

        _gameState.CurrentScore = CurrentScore;
        _gameState.CurrentStreak = CurrentStreak;
        _gameState.BestStreak = BestStreak;
        _gameState.HighScore = HighScore;
        _gameState.RecordAnswer(isCorrect);

        if (_gameStateRepository != null)
        {
            try
            {
                await _gameStateRepository.UpdateAsync(_gameState);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error saving game state: {ex.Message}");
            }
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
    private async Task ResetGame()
    {
        CurrentScore = 0;
        CurrentStreak = 0;
        TotalQuestions = 0;

        _gameState.CurrentScore = 0;
        _gameState.CurrentStreak = 0;

        if (_gameStateRepository != null)
        {
            try
            {
                await _gameStateRepository.UpdateAsync(_gameState);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error resetting game state: {ex.Message}");
            }
        }

        OnPropertyChanged(nameof(ScoreText));
        OnPropertyChanged(nameof(StreakText));
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

        var indices = Enumerable.Range(0, _countries.Count)
            .OrderBy(_ => _random.Next())
            .Take(2)
            .ToList();

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
        var messages = new[]
        {
            "Correct!",
            "Well done!",
            "Great job!",
            "Excellent!",
            CurrentStreak >= 5 ? $"{CurrentStreak} in a row!" : "Keep it up!"
        };
        return messages[_random.Next(messages.Length)];
    }

    private string GetIncorrectMessage()
    {
        return "Not quite! The correct answer is shown above.";
    }
}
EOF

echo "✓ Desktop MainWindowViewModel updated"

# -----------------------------------------------------------------------------
# Fix 7: Update GitHub Actions workflow for proper Android versioning
# -----------------------------------------------------------------------------
echo "[8/8] Updating GitHub Actions workflow for Android versioning..."

mkdir -p .github/workflows

cat > .github/workflows/build-and-release.yml << 'EOF'
name: Build and Release

on:
  push:
    branches: [master, main]
  pull_request:
    branches: [master, main]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: ${{ runner.os }}-nuget-

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Test
        run: dotnet test --configuration Release --no-build --verbosity normal

  build-desktop:
    needs: build-and-test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main')
    strategy:
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: MyDesktopApplication-win-x64
          - os: windows-latest
            rid: win-arm64
            artifact: MyDesktopApplication-win-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: MyDesktopApplication-linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: MyDesktopApplication-linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: MyDesktopApplication-osx-x64
          - os: macos-latest
            rid: osx-arm64
            artifact: MyDesktopApplication-osx-arm64
    runs-on: ${{ matrix.os }}
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            --configuration Release \
            --runtime ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:Version=1.0.${{ github.run_number }} \
            -p:AssemblyVersion=1.0.${{ github.run_number }}.0 \
            -p:FileVersion=1.0.${{ github.run_number }}.0 \
            --output ./publish/${{ matrix.artifact }}

      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: ${{ matrix.artifact }}
          path: ./publish/${{ matrix.artifact }}

  build-android:
    needs: build-and-test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Install Android workload
        run: dotnet workload install android

      - name: Build Android APK
        run: |
          dotnet publish src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            --configuration Release \
            -p:ApplicationVersion=${{ github.run_number }} \
            -p:ApplicationDisplayVersion="1.0.${{ github.run_number }}" \
            --output ./publish/android

      - name: Find and rename APK
        run: |
          mkdir -p ./publish/final
          APK=$(find ./publish/android -name "*.apk" | head -1)
          if [ -n "$APK" ]; then
            cp "$APK" "./publish/final/MyDesktopApplication-1.0.${{ github.run_number }}.apk"
          fi

      - name: Upload Android artifact
        uses: actions/upload-artifact@v6
        with:
          name: MyDesktopApplication-android
          path: ./publish/final/*.apk

  release:
    needs: [build-desktop, build-android]
    if: github.event_name == 'push' && (github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main')
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v7
        with:
          path: ./artifacts

      - name: Prepare release assets
        run: |
          mkdir -p ./release
          
          # Package desktop builds
          for dir in ./artifacts/MyDesktopApplication-*; do
            if [ -d "$dir" ] && [[ "$dir" != *"android"* ]]; then
              name=$(basename "$dir")
              if [[ "$name" == *"win"* ]]; then
                cd "$dir" && zip -r "../../release/${name}-1.0.${{ github.run_number }}.zip" . && cd ../..
              else
                cd "$dir" && tar -czvf "../../release/${name}-1.0.${{ github.run_number }}.tar.gz" . && cd ../..
              fi
            fi
          done
          
          # Copy Android APK
          if [ -d "./artifacts/MyDesktopApplication-android" ]; then
            cp ./artifacts/MyDesktopApplication-android/*.apk ./release/ 2>/dev/null || true
          fi
          
          ls -la ./release/

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Release 1.0.${{ github.run_number }}
          body: |
            ## Release 1.0.${{ github.run_number }}
            
            ### Downloads
            - **Windows x64**: MyDesktopApplication-win-x64-1.0.${{ github.run_number }}.zip
            - **Windows ARM64**: MyDesktopApplication-win-arm64-1.0.${{ github.run_number }}.zip
            - **Linux x64**: MyDesktopApplication-linux-x64-1.0.${{ github.run_number }}.tar.gz
            - **Linux ARM64**: MyDesktopApplication-linux-arm64-1.0.${{ github.run_number }}.tar.gz
            - **macOS x64**: MyDesktopApplication-osx-x64-1.0.${{ github.run_number }}.tar.gz
            - **macOS ARM64**: MyDesktopApplication-osx-arm64-1.0.${{ github.run_number }}.tar.gz
            - **Android**: MyDesktopApplication-1.0.${{ github.run_number }}.apk
            
            ### Changes
            - Auto-release from commit ${{ github.sha }}
          files: ./release/*
          draft: false
          prerelease: false
          generate_release_notes: true
EOF

echo "✓ GitHub Actions workflow updated"

# -----------------------------------------------------------------------------
# Build and verify
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Building and Verifying..."
echo "=============================================="

dotnet restore
if ! dotnet build --configuration Release; then
    echo ""
    echo "=============================================="
    echo "  BUILD FAILED - Check errors above"
    echo "=============================================="
    exit 1
fi

if ! dotnet test --configuration Release --no-build; then
    echo ""
    echo "=============================================="
    echo "  TESTS FAILED - Check errors above"
    echo "=============================================="
    exit 1
fi

echo ""
echo "=============================================="
echo "  All Fixes Applied Successfully!"
echo "=============================================="
echo ""
echo "Changes made:"
echo "  1. Answer highlighting - only the selected answer is highlighted"
echo "     - Green for correct selection"
echo "     - Red for wrong selection"
echo "     - Other answer stays neutral (not highlighted)"
echo ""
echo "  2. Removed all emojis from UI"
echo "     - Next Round button now shows plain text"
echo "     - Result messages use plain text"
echo "     - No more [x] placeholders on Android"
echo ""
echo "  3. Fixed Android versioning for Obtanium updates"
echo "     - ApplicationVersion (VersionCode) = github.run_number"
echo "     - ApplicationDisplayVersion = 1.0.{run_number}"
echo "     - Each build has incrementing version"
echo "     - Updates will work without uninstall"
echo ""
echo "To deploy:"
echo "  git add -A"
echo "  git commit -m 'Fix answer highlighting, remove emojis, fix Android versioning'"
echo "  git push"
echo ""
EOF

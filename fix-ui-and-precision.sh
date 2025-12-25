#!/bin/bash
#
# fix-ui-and-precision.sh
# Fixes UI layout issues and value display precision
# Idempotent - safe to run multiple times
#

set -e
cd "$(dirname "$0")"

echo "=============================================="
echo "  UI & Precision Fix Script"
echo "=============================================="

# -----------------------------------------------------------------------------
# 1. Kill stuck processes
# -----------------------------------------------------------------------------
echo "[1/7] Cleaning up stuck processes..."
pkill -f "VBCSCompiler" 2>/dev/null || true
pkill -f "aapt2" 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true

# -----------------------------------------------------------------------------
# 2. Clean build artifacts
# -----------------------------------------------------------------------------
echo "[2/7] Cleaning build artifacts..."
rm -rf bin obj src/*/bin src/*/obj tests/*/bin tests/*/obj 2>/dev/null || true

# -----------------------------------------------------------------------------
# 3. Delete old unnecessary shell scripts
# -----------------------------------------------------------------------------
echo "[3/7] Removing old shell scripts..."
rm -f fix-all-errors.sh 2>/dev/null || true
rm -f fix-android-code.sh 2>/dev/null || true
rm -f fix-avalonia-version.sh 2>/dev/null || true
rm -f fix-updateasync-error.sh 2>/dev/null || true
rm -f convert-to-country-quiz.sh 2>/dev/null || true
rm -f repair-project.sh 2>/dev/null || true
rm -f setup-all.sh 2>/dev/null || true
rm -f setup-project.sh 2>/dev/null || true
rm -f setup-android-sdk.sh 2>/dev/null || true
rm -f harmonize-properties.sh 2>/dev/null || true

# -----------------------------------------------------------------------------
# 4. Update QuestionType.cs with smart precision formatting
# -----------------------------------------------------------------------------
echo "[4/7] Updating QuestionType.cs with smart precision formatting..."
cat > src/MyDesktopApplication.Core/Entities/QuestionType.cs << 'EOF'
namespace MyDesktopApplication.Core.Entities;

public enum QuestionType
{
    Population,
    Area,
    GdpTotal,
    GdpPerCapita,
    PopulationDensity,
    LiteracyRate,
    Hdi,
    LifeExpectancy
}

public static class QuestionTypeExtensions
{
    public static string GetLabel(this QuestionType questionType) => questionType switch
    {
        QuestionType.Population => "Population",
        QuestionType.Area => "Area (km²)",
        QuestionType.GdpTotal => "GDP (Total)",
        QuestionType.GdpPerCapita => "GDP per Capita",
        QuestionType.PopulationDensity => "Population Density",
        QuestionType.LiteracyRate => "Literacy Rate",
        QuestionType.Hdi => "Human Development Index",
        QuestionType.LifeExpectancy => "Life Expectancy",
        _ => questionType.ToString()
    };

    public static double GetValue(this QuestionType questionType, Country country) => questionType switch
    {
        QuestionType.Population => country.Population,
        QuestionType.Area => country.Area,
        QuestionType.GdpTotal => country.GdpTotal,
        QuestionType.GdpPerCapita => country.GdpPerCapita,
        QuestionType.PopulationDensity => country.PopulationDensity,
        QuestionType.LiteracyRate => country.LiteracyRate,
        QuestionType.Hdi => country.Hdi,
        QuestionType.LifeExpectancy => country.LifeExpectancy,
        _ => 0
    };

    /// <summary>
    /// Format a value for display with appropriate precision.
    /// Uses exact values to avoid confusion when numbers are close.
    /// </summary>
    public static string FormatValue(this QuestionType questionType, double value) => questionType switch
    {
        QuestionType.Population => FormatLargeNumber(value),
        QuestionType.Area => FormatArea(value),
        QuestionType.GdpTotal => FormatCurrency(value),
        QuestionType.GdpPerCapita => $"${value:N0}",
        QuestionType.PopulationDensity => $"{value:N1}/km²",
        QuestionType.LiteracyRate => $"{value:N1}%",
        QuestionType.Hdi => $"{value:N3}",
        QuestionType.LifeExpectancy => $"{value:N1} years",
        _ => value.ToString("N0")
    };

    /// <summary>
    /// Format large numbers with enough precision to distinguish close values.
    /// For example, 1,411,750,000 vs 1,417,173,173 should NOT both show as "1.4B"
    /// </summary>
    private static string FormatLargeNumber(double value)
    {
        // Use exact format for smaller numbers
        if (value < 1_000) return value.ToString("N0");
        if (value < 1_000_000) return $"{value / 1_000:N2}K";  // 2 decimal places
        if (value < 1_000_000_000) return $"{value / 1_000_000:N2}M";  // 2 decimal places
        
        // For billions, use 3 decimal places to distinguish close values
        // e.g., 1.412B vs 1.417B for China/India
        if (value < 1_000_000_000_000) return $"{value / 1_000_000_000:N3}B";
        
        return $"{value / 1_000_000_000_000:N3}T";
    }

    private static string FormatArea(double value)
    {
        if (value < 1_000) return $"{value:N0} km²";
        if (value < 1_000_000) return $"{value / 1_000:N2}K km²";
        return $"{value / 1_000_000:N2}M km²";
    }

    private static string FormatCurrency(double value)
    {
        if (value < 1_000) return $"${value:N0}";
        if (value < 1_000_000) return $"${value / 1_000:N2}K";
        if (value < 1_000_000_000) return $"${value / 1_000_000:N2}M";
        if (value < 1_000_000_000_000) return $"${value / 1_000_000_000:N2}B";
        return $"${value / 1_000_000_000_000:N2}T";
    }
}
EOF

# -----------------------------------------------------------------------------
# 5. Update Desktop MainWindow.axaml with improved layout
# -----------------------------------------------------------------------------
echo "[5/7] Updating Desktop MainWindow.axaml..."
cat > src/MyDesktopApplication.Desktop/Views/MainWindow.axaml << 'EOF'
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyDesktopApplication.Desktop.ViewModels"
        xmlns:conv="using:MyDesktopApplication.Desktop.Converters"
        x:Class="MyDesktopApplication.Desktop.Views.MainWindow"
        x:DataType="vm:MainWindowViewModel"
        Title="Country Quiz"
        Width="800" Height="700"
        MinWidth="400" MinHeight="500"
        Background="#1a1a2e">

    <Window.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
        <conv:BoolToColorConverter x:Key="BoolToColorConverter"/>
    </Window.Resources>

    <ScrollViewer HorizontalScrollBarVisibility="Disabled" 
                  VerticalScrollBarVisibility="Auto">
        <Grid RowDefinitions="Auto,Auto,*,Auto" Margin="20">
            
            <!-- Header: Score & Stats -->
            <Border Grid.Row="0" Background="#16213e" CornerRadius="12" Padding="16" Margin="0,0,0,16">
                <Grid ColumnDefinitions="*,Auto,Auto,Auto">
                    <!-- Question Type Selector -->
                    <ComboBox Grid.Column="0"
                              ItemsSource="{Binding QuestionTypes}"
                              SelectedItem="{Binding SelectedQuestionType}"
                              Background="#0f3460"
                              Foreground="White"
                              MinWidth="180"
                              HorizontalAlignment="Left">
                        <ComboBox.ItemTemplate>
                            <DataTemplate>
                                <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"
                                           Foreground="White"/>
                            </DataTemplate>
                        </ComboBox.ItemTemplate>
                    </ComboBox>
                    
                    <!-- Stats Display -->
                    <StackPanel Grid.Column="1" Orientation="Horizontal" Spacing="16" Margin="16,0">
                        <TextBlock Text="{Binding ScoreText}" Foreground="#4ade80" FontSize="16" FontWeight="Bold"/>
                        <TextBlock Text="{Binding StreakText}" Foreground="#fbbf24" FontSize="16"/>
                        <TextBlock Text="{Binding BestStreakText}" Foreground="#f472b6" FontSize="16"/>
                    </StackPanel>
                    
                    <TextBlock Grid.Column="2" Text="{Binding AccuracyText}" Foreground="#94a3b8" 
                               FontSize="14" VerticalAlignment="Center" Margin="0,0,16,0"/>
                    
                    <!-- Reset Button -->
                    <Button Grid.Column="3" Content="Reset" Command="{Binding ResetGameCommand}"
                            Background="#ef4444" Foreground="White" Padding="16,8"/>
                </Grid>
            </Border>
            
            <!-- Question Text -->
            <Border Grid.Row="1" Background="#16213e" CornerRadius="12" Padding="20" Margin="0,0,0,16">
                <TextBlock Text="{Binding QuestionText}" 
                           Foreground="White" FontSize="22" FontWeight="SemiBold"
                           TextAlignment="Center" TextWrapping="Wrap"/>
            </Border>
            
            <!-- Country Cards - Two columns side by side -->
            <Grid Grid.Row="2" ColumnDefinitions="*,16,*" Margin="0,0,0,16">
                
                <!-- Country 1 Card -->
                <Button Grid.Column="0" 
                        Command="{Binding SelectCountryCommand}" 
                        CommandParameter="1"
                        IsEnabled="{Binding !HasAnswered}"
                        HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                        HorizontalContentAlignment="Stretch" VerticalContentAlignment="Stretch"
                        Padding="0" Background="Transparent" BorderThickness="0"
                        MinHeight="200">
                    <Border CornerRadius="16" Padding="24"
                            Background="{Binding IsCountry1Correct, Converter={StaticResource BoolToColorConverter}, ConverterParameter=correct}"
                            Classes.wrong="{Binding IsCountry1Wrong}">
                        <Border.Styles>
                            <Style Selector="Border">
                                <Setter Property="Background" Value="#16213e"/>
                            </Style>
                            <Style Selector="Border.wrong">
                                <Setter Property="Background" Value="#7f1d1d"/>
                            </Style>
                        </Border.Styles>
                        <Grid RowDefinitions="Auto,*,Auto">
                            <!-- Flag -->
                            <TextBlock Grid.Row="0" Text="{Binding Country1.Flag}" 
                                       FontSize="64" HorizontalAlignment="Center" Margin="0,0,0,12"/>
                            
                            <!-- Country Name -->
                            <TextBlock Grid.Row="1" Text="{Binding Country1.Name}" 
                                       Foreground="White" FontSize="24" FontWeight="Bold"
                                       TextAlignment="Center" TextWrapping="Wrap"
                                       VerticalAlignment="Center"/>
                            
                            <!-- Value (shown after answer) -->
                            <TextBlock Grid.Row="2" Text="{Binding Country1Value}"
                                       IsVisible="{Binding HasAnswered}"
                                       Foreground="#60a5fa" FontSize="20" FontWeight="Bold"
                                       TextAlignment="Center" Margin="0,12,0,0"/>
                        </Grid>
                    </Border>
                </Button>
                
                <!-- VS Text -->
                <TextBlock Grid.Column="1" Text="VS" 
                           Foreground="#64748b" FontSize="24" FontWeight="Bold"
                           VerticalAlignment="Center" HorizontalAlignment="Center"/>
                
                <!-- Country 2 Card -->
                <Button Grid.Column="2" 
                        Command="{Binding SelectCountryCommand}" 
                        CommandParameter="2"
                        IsEnabled="{Binding !HasAnswered}"
                        HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                        HorizontalContentAlignment="Stretch" VerticalContentAlignment="Stretch"
                        Padding="0" Background="Transparent" BorderThickness="0"
                        MinHeight="200">
                    <Border CornerRadius="16" Padding="24"
                            Background="{Binding IsCountry2Correct, Converter={StaticResource BoolToColorConverter}, ConverterParameter=correct}"
                            Classes.wrong="{Binding IsCountry2Wrong}">
                        <Border.Styles>
                            <Style Selector="Border">
                                <Setter Property="Background" Value="#16213e"/>
                            </Style>
                            <Style Selector="Border.wrong">
                                <Setter Property="Background" Value="#7f1d1d"/>
                            </Style>
                        </Border.Styles>
                        <Grid RowDefinitions="Auto,*,Auto">
                            <!-- Flag -->
                            <TextBlock Grid.Row="0" Text="{Binding Country2.Flag}" 
                                       FontSize="64" HorizontalAlignment="Center" Margin="0,0,0,12"/>
                            
                            <!-- Country Name -->
                            <TextBlock Grid.Row="1" Text="{Binding Country2.Name}" 
                                       Foreground="White" FontSize="24" FontWeight="Bold"
                                       TextAlignment="Center" TextWrapping="Wrap"
                                       VerticalAlignment="Center"/>
                            
                            <!-- Value (shown after answer) -->
                            <TextBlock Grid.Row="2" Text="{Binding Country2Value}"
                                       IsVisible="{Binding HasAnswered}"
                                       Foreground="#60a5fa" FontSize="20" FontWeight="Bold"
                                       TextAlignment="Center" Margin="0,12,0,0"/>
                        </Grid>
                    </Border>
                </Button>
            </Grid>
            
            <!-- Result & Next Button -->
            <StackPanel Grid.Row="3" Spacing="12">
                <!-- Result Message -->
                <Border IsVisible="{Binding HasAnswered}" 
                        Background="#16213e" CornerRadius="12" Padding="16">
                    <TextBlock Text="{Binding ResultMessage}" 
                               Foreground="White" FontSize="18"
                               TextAlignment="Center" TextWrapping="Wrap"/>
                </Border>
                
                <!-- Next Round Button -->
                <Button Command="{Binding NextRoundCommand}"
                        IsVisible="{Binding HasAnswered}"
                        Content="Next Round →"
                        Background="#3b82f6" Foreground="White"
                        FontSize="18" FontWeight="Bold"
                        Padding="24,16"
                        HorizontalAlignment="Center"
                        HorizontalContentAlignment="Center"/>
            </StackPanel>
        </Grid>
    </ScrollViewer>
</Window>
EOF

# -----------------------------------------------------------------------------
# 6. Update Android MainView.axaml with touch-optimized layout
# -----------------------------------------------------------------------------
echo "[6/7] Updating Android MainView.axaml with touch-optimized layout..."
cat > src/MyDesktopApplication.Android/Views/MainView.axaml << 'EOF'
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="using:MyDesktopApplication.Shared.ViewModels"
             xmlns:conv="using:MyDesktopApplication.Android.Converters"
             x:Class="MyDesktopApplication.Android.Views.MainView"
             x:DataType="vm:CountryQuizViewModel"
             Background="#1a1a2e">

    <UserControl.Resources>
        <conv:QuestionTypeLabelConverter x:Key="QuestionTypeLabelConverter"/>
    </UserControl.Resources>

    <!-- Main ScrollViewer to handle all screen sizes -->
    <ScrollViewer HorizontalScrollBarVisibility="Disabled" 
                  VerticalScrollBarVisibility="Auto">
        
        <Grid RowDefinitions="Auto,Auto,*,Auto" Margin="12">
            
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <!-- ROW 0: Header with Stats and Controls                           -->
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <Border Grid.Row="0" Background="#16213e" CornerRadius="12" Padding="12" Margin="0,0,0,8">
                <Grid RowDefinitions="Auto,Auto">
                    <!-- Stats Row -->
                    <Grid Grid.Row="0" ColumnDefinitions="*,*,*,*" Margin="0,0,0,8">
                        <TextBlock Grid.Column="0" Text="{Binding ScoreText}" 
                                   Foreground="#4ade80" FontSize="14" FontWeight="Bold"
                                   HorizontalAlignment="Center"/>
                        <TextBlock Grid.Column="1" Text="{Binding StreakText}" 
                                   Foreground="#fbbf24" FontSize="14"
                                   HorizontalAlignment="Center"/>
                        <TextBlock Grid.Column="2" Text="{Binding BestStreakText}" 
                                   Foreground="#f472b6" FontSize="14"
                                   HorizontalAlignment="Center"/>
                        <TextBlock Grid.Column="3" Text="{Binding AccuracyText}" 
                                   Foreground="#94a3b8" FontSize="14"
                                   HorizontalAlignment="Center"/>
                    </Grid>
                    
                    <!-- Controls Row -->
                    <Grid Grid.Row="1" ColumnDefinitions="*,Auto">
                        <ComboBox Grid.Column="0"
                                  ItemsSource="{Binding QuestionTypes}"
                                  SelectedItem="{Binding SelectedQuestionType}"
                                  Background="#0f3460"
                                  Foreground="White"
                                  MinHeight="44"
                                  HorizontalAlignment="Stretch"
                                  Margin="0,0,8,0">
                            <ComboBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Converter={StaticResource QuestionTypeLabelConverter}}"
                                               Foreground="White" FontSize="14"/>
                                </DataTemplate>
                            </ComboBox.ItemTemplate>
                        </ComboBox>
                        
                        <Button Grid.Column="1" Content="Reset" 
                                Command="{Binding ResetGameCommand}"
                                Background="#ef4444" Foreground="White"
                                MinHeight="44" MinWidth="70"
                                Padding="12,8"
                                FontSize="14"/>
                    </Grid>
                </Grid>
            </Border>
            
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <!-- ROW 1: Question Text                                            -->
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <Border Grid.Row="1" Background="#16213e" CornerRadius="12" Padding="16" Margin="0,0,0,8">
                <TextBlock Text="{Binding QuestionText}" 
                           Foreground="White" FontSize="18" FontWeight="SemiBold"
                           TextAlignment="Center" TextWrapping="Wrap"/>
            </Border>
            
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <!-- ROW 2: Country Cards (MAXIMIZED TOUCH AREA)                     -->
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <Grid Grid.Row="2" RowDefinitions="*,Auto,*" Margin="0,0,0,8" MinHeight="350">
                
                <!-- Country 1 - TOP (Full Width, Large Touch Target) -->
                <Button Grid.Row="0" 
                        Command="{Binding SelectCountryCommand}" 
                        CommandParameter="1"
                        IsEnabled="{Binding !HasAnswered}"
                        HorizontalAlignment="Stretch" 
                        VerticalAlignment="Stretch"
                        HorizontalContentAlignment="Stretch" 
                        VerticalContentAlignment="Stretch"
                        Padding="0" 
                        Background="Transparent" 
                        BorderThickness="0"
                        Margin="0,0,0,4">
                    <Border CornerRadius="16" Padding="16"
                            HorizontalAlignment="Stretch"
                            VerticalAlignment="Stretch">
                        <Border.Styles>
                            <Style Selector="Border">
                                <Setter Property="Background" Value="#16213e"/>
                            </Style>
                        </Border.Styles>
                        <Border.Background>
                            <MultiBinding Converter="{x:Static conv:AnswerBackgroundConverter.Instance}">
                                <Binding Path="IsCountry1Correct"/>
                                <Binding Path="IsCountry1Wrong"/>
                            </MultiBinding>
                        </Border.Background>
                        
                        <Grid ColumnDefinitions="Auto,*,Auto">
                            <!-- Flag (Left) -->
                            <TextBlock Grid.Column="0" Text="{Binding Country1.Flag}" 
                                       FontSize="48" VerticalAlignment="Center" Margin="0,0,12,0"/>
                            
                            <!-- Country Name (Center) -->
                            <TextBlock Grid.Column="1" Text="{Binding Country1.Name}" 
                                       Foreground="White" FontSize="22" FontWeight="Bold"
                                       TextWrapping="Wrap" VerticalAlignment="Center"
                                       HorizontalAlignment="Center"/>
                            
                            <!-- Value (Right, shown after answer) -->
                            <StackPanel Grid.Column="2" VerticalAlignment="Center" 
                                        IsVisible="{Binding HasAnswered}">
                                <TextBlock Text="{Binding Country1Value}"
                                           Foreground="#60a5fa" FontSize="16" FontWeight="Bold"
                                           HorizontalAlignment="Right"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                </Button>
                
                <!-- VS Divider -->
                <Border Grid.Row="1" Background="#0f3460" CornerRadius="20" 
                        Padding="16,4" HorizontalAlignment="Center" Margin="0,4">
                    <TextBlock Text="VS" Foreground="#64748b" FontSize="16" FontWeight="Bold"/>
                </Border>
                
                <!-- Country 2 - BOTTOM (Full Width, Large Touch Target) -->
                <Button Grid.Row="2" 
                        Command="{Binding SelectCountryCommand}" 
                        CommandParameter="2"
                        IsEnabled="{Binding !HasAnswered}"
                        HorizontalAlignment="Stretch" 
                        VerticalAlignment="Stretch"
                        HorizontalContentAlignment="Stretch" 
                        VerticalContentAlignment="Stretch"
                        Padding="0" 
                        Background="Transparent" 
                        BorderThickness="0"
                        Margin="0,4,0,0">
                    <Border CornerRadius="16" Padding="16"
                            HorizontalAlignment="Stretch"
                            VerticalAlignment="Stretch">
                        <Border.Styles>
                            <Style Selector="Border">
                                <Setter Property="Background" Value="#16213e"/>
                            </Style>
                        </Border.Styles>
                        <Border.Background>
                            <MultiBinding Converter="{x:Static conv:AnswerBackgroundConverter.Instance}">
                                <Binding Path="IsCountry2Correct"/>
                                <Binding Path="IsCountry2Wrong"/>
                            </MultiBinding>
                        </Border.Background>
                        
                        <Grid ColumnDefinitions="Auto,*,Auto">
                            <!-- Flag (Left) -->
                            <TextBlock Grid.Column="0" Text="{Binding Country2.Flag}" 
                                       FontSize="48" VerticalAlignment="Center" Margin="0,0,12,0"/>
                            
                            <!-- Country Name (Center) -->
                            <TextBlock Grid.Column="1" Text="{Binding Country2.Name}" 
                                       Foreground="White" FontSize="22" FontWeight="Bold"
                                       TextWrapping="Wrap" VerticalAlignment="Center"
                                       HorizontalAlignment="Center"/>
                            
                            <!-- Value (Right, shown after answer) -->
                            <StackPanel Grid.Column="2" VerticalAlignment="Center" 
                                        IsVisible="{Binding HasAnswered}">
                                <TextBlock Text="{Binding Country2Value}"
                                           Foreground="#60a5fa" FontSize="16" FontWeight="Bold"
                                           HorizontalAlignment="Right"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                </Button>
            </Grid>
            
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <!-- ROW 3: Result Message & Next Button                             -->
            <!-- ═══════════════════════════════════════════════════════════════ -->
            <StackPanel Grid.Row="3" Spacing="8">
                <!-- Result Message -->
                <Border IsVisible="{Binding HasAnswered}" 
                        Background="#16213e" CornerRadius="12" Padding="12">
                    <TextBlock Text="{Binding ResultMessage}" 
                               Foreground="White" FontSize="16"
                               TextAlignment="Center" TextWrapping="Wrap"/>
                </Border>
                
                <!-- Next Round Button - LARGE TOUCH TARGET -->
                <Button Command="{Binding NextRoundCommand}"
                        IsVisible="{Binding HasAnswered}"
                        Content="Next Round →"
                        Background="#3b82f6" Foreground="White"
                        FontSize="18" FontWeight="Bold"
                        MinHeight="56"
                        Padding="24,12"
                        HorizontalAlignment="Stretch"
                        HorizontalContentAlignment="Center"/>
            </StackPanel>
        </Grid>
    </ScrollViewer>
</UserControl>
EOF

# -----------------------------------------------------------------------------
# 7. Update Android Converters with the new AnswerBackgroundConverter
# -----------------------------------------------------------------------------
echo "[7/7] Updating Android Converters..."
cat > src/MyDesktopApplication.Android/Converters/Converters.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Android.Converters;

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
/// Multi-value converter that determines background color based on correct/wrong state
/// </summary>
public class AnswerBackgroundConverter : IMultiValueConverter
{
    public static readonly AnswerBackgroundConverter Instance = new();
    
    private static readonly SolidColorBrush DefaultBrush = new(Color.Parse("#16213e"));
    private static readonly SolidColorBrush CorrectBrush = new(Color.Parse("#166534"));  // Green
    private static readonly SolidColorBrush WrongBrush = new(Color.Parse("#7f1d1d"));    // Red

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2)
        {
            var isCorrect = values[0] is true;
            var isWrong = values[1] is true;
            
            if (isCorrect) return CorrectBrush;
            if (isWrong) return WrongBrush;
        }
        return DefaultBrush;
    }
}
EOF

# -----------------------------------------------------------------------------
# Update Desktop Converters to match
# -----------------------------------------------------------------------------
cat > src/MyDesktopApplication.Desktop/Converters/Converters.cs << 'EOF'
using System;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
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

public class BoolToColorConverter : IValueConverter
{
    private static readonly SolidColorBrush CorrectBrush = new(Color.Parse("#166534"));
    private static readonly SolidColorBrush DefaultBrush = new(Color.Parse("#16213e"));
    
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is true && parameter?.ToString() == "correct")
        {
            return CorrectBrush;
        }
        return DefaultBrush;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
EOF

# -----------------------------------------------------------------------------
# Update QuestionTypeTests to match new precision
# -----------------------------------------------------------------------------
cat > tests/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs << 'EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class QuestionTypeTests
{
    [Theory]
    [InlineData(QuestionType.Population, "Population")]
    [InlineData(QuestionType.Area, "Area (km²)")]
    [InlineData(QuestionType.GdpTotal, "GDP (Total)")]
    [InlineData(QuestionType.GdpPerCapita, "GDP per Capita")]
    [InlineData(QuestionType.PopulationDensity, "Population Density")]
    [InlineData(QuestionType.LiteracyRate, "Literacy Rate")]
    [InlineData(QuestionType.Hdi, "Human Development Index")]
    [InlineData(QuestionType.LifeExpectancy, "Life Expectancy")]
    public void GetLabel_ReturnsCorrectLabel(QuestionType questionType, string expectedLabel)
    {
        var label = questionType.GetLabel();
        label.ShouldBe(expectedLabel);
    }

    [Fact]
    public void GetValue_ReturnsCorrectValueForCountry()
    {
        var country = new Country
        {
            Code = "USA",
            Name = "United States",
            Iso2 = "US",
            Continent = "North America",
            Population = 331_000_000,
            Area = 9_833_520,
            GdpTotal = 25_462_700_000_000,
            GdpPerCapita = 76_330,
            PopulationDensity = 33.6,
            LiteracyRate = 99.0,
            Hdi = 0.921,
            LifeExpectancy = 77.0
        };

        QuestionType.Population.GetValue(country).ShouldBe(331_000_000);
        QuestionType.Area.GetValue(country).ShouldBe(9_833_520);
        QuestionType.GdpTotal.GetValue(country).ShouldBe(25_462_700_000_000);
        QuestionType.GdpPerCapita.GetValue(country).ShouldBe(76_330);
        QuestionType.PopulationDensity.GetValue(country).ShouldBe(33.6);
        QuestionType.LiteracyRate.GetValue(country).ShouldBe(99.0);
        QuestionType.Hdi.GetValue(country).ShouldBe(0.921);
        QuestionType.LifeExpectancy.GetValue(country).ShouldBe(77.0);
    }

    [Fact]
    public void FormatValue_UsesEnoughPrecisionToDistinguishCloseValues()
    {
        // This is the key test - China (1,411,750,000) vs India (1,417,173,173)
        // should NOT both show as "1.4B" - that's confusing!
        var chinaPopulation = 1_411_750_000.0;
        var indiaPopulation = 1_417_173_173.0;
        
        var chinaFormatted = QuestionType.Population.FormatValue(chinaPopulation);
        var indiaFormatted = QuestionType.Population.FormatValue(indiaPopulation);
        
        // They should be different! Users need to see the difference
        chinaFormatted.ShouldNotBe(indiaFormatted);
        
        // Check the actual values - should show 3 decimal places for billions
        chinaFormatted.ShouldBe("1.412B");
        indiaFormatted.ShouldBe("1.417B");
    }

    [Fact]
    public void FormatValue_FormatsValuesCorrectly()
    {
        // Population formatting
        QuestionType.Population.FormatValue(1_500_000_000).ShouldBe("1.500B");
        QuestionType.Population.FormatValue(50_000_000).ShouldBe("50.00M");
        QuestionType.Population.FormatValue(500_000).ShouldBe("500.00K");
        
        // GDP formatting
        QuestionType.GdpTotal.FormatValue(25_000_000_000_000).ShouldBe("$25.00T");
        QuestionType.GdpTotal.FormatValue(1_500_000_000_000).ShouldBe("$1.50T");
        
        // Other types
        QuestionType.LiteracyRate.FormatValue(99.5).ShouldBe("99.5%");
        QuestionType.Hdi.FormatValue(0.921).ShouldBe("0.921");
        QuestionType.LifeExpectancy.FormatValue(77.5).ShouldBe("77.5 years");
    }
}
EOF

# -----------------------------------------------------------------------------
# Build and Test
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Building..."
echo "=============================================="
dotnet restore MyDesktopApplication.slnx
if dotnet build MyDesktopApplication.slnx; then
    echo ""
    echo "=============================================="
    echo "  Running Tests..."
    echo "=============================================="
    dotnet test MyDesktopApplication.slnx --no-build
    
    echo ""
    echo "=============================================="
    echo "  ✓ All fixes applied successfully!"
    echo "=============================================="
    echo ""
    echo "Changes made:"
    echo "  1. Deleted old shell scripts (cleanup)"
    echo "  2. Updated QuestionType.FormatValue() to use 3 decimal places for billions"
    echo "     - China 1,411,750,000 now shows as '1.412B'"
    echo "     - India 1,417,173,173 now shows as '1.417B'"
    echo "     - No more confusion when values are close!"
    echo "  3. Updated Desktop MainWindow.axaml with improved layout"
    echo "  4. Updated Android MainView.axaml with maximized touch targets"
    echo "     - Full-width country cards for easy tapping"
    echo "     - Larger Next button (56px minimum height)"
    echo "     - Better spacing and layout"
    echo "  5. Updated converters with proper answer state handling"
    echo "  6. Added new test to verify close values are distinguishable"
    echo ""
else
    echo ""
    echo "=============================================="
    echo "  ✗ Build failed - see errors above"
    echo "=============================================="
    exit 1
fi

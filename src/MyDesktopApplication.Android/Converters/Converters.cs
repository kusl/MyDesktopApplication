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

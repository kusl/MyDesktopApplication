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

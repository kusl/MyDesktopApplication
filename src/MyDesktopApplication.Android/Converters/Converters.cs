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

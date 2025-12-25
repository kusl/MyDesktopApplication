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

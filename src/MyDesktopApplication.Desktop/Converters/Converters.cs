using System;
using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Desktop.Converters;

public class QuestionTypeLabelConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value is QuestionType qt ? qt.GetLabel() : value?.ToString();
    }
    
    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class BoolToColorConverter : IValueConverter
{
    public IBrush? TrueBrush { get; set; }
    public IBrush? FalseBrush { get; set; }
    public IBrush? DefaultBrush { get; set; }
    
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool b)
        {
            return b ? TrueBrush : FalseBrush;
        }
        return DefaultBrush;
    }
    
    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class SelectedToBorderConverter : IMultiValueConverter
{
    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 4 && 
            values[0] is bool hasAnswered &&
            values[1] is int selected &&
            values[2] is bool isCorrect &&
            parameter is string cardNum &&
            int.TryParse(cardNum, out var cardNumber))
        {
            if (!hasAnswered) return new SolidColorBrush(Color.FromRgb(55, 65, 81)); // Gray border
            if (selected != cardNumber) return new SolidColorBrush(Color.FromRgb(55, 65, 81));
            return isCorrect 
                ? new SolidColorBrush(Color.FromRgb(34, 197, 94))   // Green
                : new SolidColorBrush(Color.FromRgb(239, 68, 68)); // Red
        }
        return new SolidColorBrush(Color.FromRgb(55, 65, 81));
    }
}

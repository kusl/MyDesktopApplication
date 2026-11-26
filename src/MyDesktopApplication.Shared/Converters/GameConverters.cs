using System.Globalization;
using Avalonia.Data.Converters;
using Avalonia.Media;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Shared.Converters;

public sealed class QuestionTypeLabelConverter : IValueConverter
{
    public static readonly QuestionTypeLabelConverter Instance = new();

    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is QuestionType qt ? qt.GetLabel() : value?.ToString() ?? "";

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotSupportedException();
}

public sealed class AnswerStateToBackgroundConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBackgroundConverter Instance = new();

    private static readonly SolidColorBrush Correct = new(Color.FromRgb(34, 139, 34));
    private static readonly SolidColorBrush Wrong = new(Color.FromRgb(220, 53, 69));
    private static readonly SolidColorBrush Default = new(Color.FromRgb(30, 41, 59));

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect) return Correct;
            if (isWrong) return Wrong;
        }
        return Default;
    }
}

public sealed class AnswerStateToBorderConverter : IMultiValueConverter
{
    public static readonly AnswerStateToBorderConverter Instance = new();

    private static readonly SolidColorBrush Correct = new(Color.FromRgb(34, 197, 94));
    private static readonly SolidColorBrush Wrong = new(Color.FromRgb(239, 68, 68));
    private static readonly SolidColorBrush Default = new(Color.FromRgb(55, 65, 81));

    public object? Convert(IList<object?> values, Type targetType, object? parameter, CultureInfo culture)
    {
        if (values.Count >= 2 && values[0] is bool isCorrect && values[1] is bool isWrong)
        {
            if (isCorrect) return Correct;
            if (isWrong) return Wrong;
        }
        return Default;
    }
}

namespace MyDesktopApplication.Shared.Data;

/// <summary>
/// Provides encouraging messages based on player performance.
/// </summary>
public static class MotivationalMessages
{
    private static readonly Random _random = new();

    private static readonly string[] CorrectMessages =
    [
        "🎉 Correct! You're on fire!",
        "✨ Brilliant! Keep it up!",
        "🌟 Amazing knowledge!",
        "💪 You really know your geography!",
        "🎯 Spot on! Nice work!",
        "🏆 Champion answer!",
        "📚 Well studied!",
        "🌍 World expert in the making!"
    ];

    private static readonly string[] IncorrectMessages =
    [
        "Not quite, but you're learning!",
        "Good try! Now you know!",
        "Interesting fact to remember!",
        "Keep going, you've got this!",
        "Every answer is a learning opportunity!",
        "Don't give up, you're improving!",
        "That's a tricky one!",
        "You'll get the next one!"
    ];

    private static readonly string[] StreakMessages =
    [
        "🔥 {0} in a row!",
        "🔥 {0} streak! Incredible!",
        "🔥 {0} consecutive! You're unstoppable!",
        "🔥 {0} correct answers! Amazing run!"
    ];

    private static readonly string[] NewBestMessages =
    [
        "🏆 NEW PERSONAL BEST! {0} streak!",
        "⭐ NEW RECORD! {0} in a row!",
        "🎊 PERSONAL BEST! {0} streak!"
    ];

    private static readonly string[] ResetMessages =
    [
        "Fresh start! Good luck! 🍀",
        "Ready for a new challenge! 💪",
        "Let's see what you've got! 🌟",
        "New game, new opportunities! 🎯"
    ];

    public static string GetCorrectMessage() =>
        CorrectMessages[_random.Next(CorrectMessages.Length)];

    public static string GetIncorrectMessage() =>
        IncorrectMessages[_random.Next(IncorrectMessages.Length)];

    public static string GetStreakMessage(int streak)
    {
        if (streak < 3) return string.Empty;
        var template = StreakMessages[_random.Next(StreakMessages.Length)];
        return string.Format(template, streak);
    }

    public static string GetNewBestMessage(int streak)
    {
        var template = NewBestMessages[_random.Next(NewBestMessages.Length)];
        return string.Format(template, streak);
    }

    public static string GetResetMessage() =>
        ResetMessages[_random.Next(ResetMessages.Length)];

    public static string GetAccuracyComment(double accuracy) => accuracy switch
    {
        >= 90 => "🏅 Geography genius!",
        >= 75 => "📊 Great accuracy!",
        >= 60 => "👍 Solid knowledge!",
        >= 40 => "📈 Room to grow!",
        _ => "🌱 Keep learning!"
    };
}

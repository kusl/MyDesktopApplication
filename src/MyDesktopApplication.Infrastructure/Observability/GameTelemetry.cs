using System.Diagnostics.Metrics;
using MyDesktopApplication.Core.Entities;
using MyDesktopApplication.Core.Interfaces;

namespace MyDesktopApplication.Infrastructure.Observability;

public sealed class GameTelemetry : IGameTelemetry
{
    private readonly Counter<long> _questions;
    private readonly Counter<long> _answers;
    private readonly Counter<long> _resets;

    public GameTelemetry()
    {
        _questions = AppTelemetry.Meter.CreateCounter<long>(
            "countryquiz.questions_generated",
            unit: "{question}",
            description: "Number of quiz questions generated.");

        _answers = AppTelemetry.Meter.CreateCounter<long>(
            "countryquiz.answers_submitted",
            unit: "{answer}",
            description: "Number of answers submitted.");

        _resets = AppTelemetry.Meter.CreateCounter<long>(
            "countryquiz.games_reset",
            unit: "{reset}",
            description: "Number of times the game was reset.");
    }

    public void RecordQuestionGenerated(QuestionType questionType)
    {
        _questions.Add(1, new KeyValuePair<string, object?>("question_type", questionType.ToString()));
    }

    public void RecordAnswer(bool isCorrect, QuestionType questionType)
    {
        _answers.Add(
            1,
            new KeyValuePair<string, object?>("correct", isCorrect),
            new KeyValuePair<string, object?>("question_type", questionType.ToString()));
    }

    public void RecordGameReset()
    {
        _resets.Add(1);
    }
}

using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Core.Interfaces;

public interface IGameTelemetry
{
    void RecordQuestionGenerated(QuestionType questionType);
    void RecordAnswer(bool isCorrect, QuestionType questionType);
    void RecordGameReset();
}

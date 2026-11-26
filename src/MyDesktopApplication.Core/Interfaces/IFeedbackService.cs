namespace MyDesktopApplication.Core.Interfaces;

public enum FeedbackCue
{
    Tap,
    Correct,
    Incorrect
}

public interface IFeedbackService
{
    void Play(FeedbackCue cue);
}

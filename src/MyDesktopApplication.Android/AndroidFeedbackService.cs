using Android.Content;
using Android.Media;
using Android.OS;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Audio;
using Application = Android.App.Application;

namespace MyDesktopApplication.Android;

public sealed class AndroidFeedbackService : IFeedbackService
{
    private readonly SoundPool _pool;
    private readonly Dictionary<FeedbackCue, int> _soundIds = [];
    private readonly Vibrator? _vibrator;

    public AndroidFeedbackService()
    {
        var attributes = new AudioAttributes.Builder()!
            .SetUsage(AudioUsageKind.Game)!
            .SetContentType(AudioContentType.Sonification)!
            .Build();

        _pool = new SoundPool.Builder()
            .SetMaxStreams(4)!
            .SetAudioAttributes(attributes)!
            .Build()!;

        foreach (var cue in Enum.GetValues<FeedbackCue>())
        {
            _soundIds[cue] = _pool.Load(WriteWav(cue), 1);
        }

        _vibrator = ResolveVibrator();
    }

    public void Play(FeedbackCue cue)
    {
        if (_soundIds.TryGetValue(cue, out var id))
        {
            _pool.Play(id, 1f, 1f, 1, 0, 1f);
        }

        Vibrate(cue switch
        {
            FeedbackCue.Incorrect => 40,
            FeedbackCue.Correct => 25,
            _ => 15
        });
    }

    private static string WriteWav(FeedbackCue cue)
    {
        var directory = Application.Context.CacheDir!.AbsolutePath;
        var path = System.IO.Path.Combine(directory, $"cue-{cue}.wav");
        System.IO.File.WriteAllBytes(path, ToneSynthesizer.ForCue(cue));
        return path;
    }

    private static Vibrator? ResolveVibrator()
    {
        var context = Application.Context;
#pragma warning disable CA1416, CA1422, CS0618
        if (Build.VERSION.SdkInt >= BuildVersionCodes.S)
        {
            var manager = (VibratorManager?)context.GetSystemService(Context.VibratorManagerService);
            return manager?.DefaultVibrator;
        }
        return (Vibrator?)context.GetSystemService(Context.VibratorService);
#pragma warning restore CA1416, CA1422, CS0618
    }

    private void Vibrate(long milliseconds)
    {
        if (_vibrator is not { HasVibrator: true }) return;
#pragma warning disable CA1416, CA1422, CS0618
        if (Build.VERSION.SdkInt >= BuildVersionCodes.O)
        {
            _vibrator.Vibrate(VibrationEffect.CreateOneShot(milliseconds, VibrationEffect.DefaultAmplitude));
        }
        else
        {
            _vibrator.Vibrate(milliseconds);
        }
#pragma warning restore CA1416, CA1422, CS0618
    }
}

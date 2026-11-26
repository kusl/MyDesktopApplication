using MyDesktopApplication.Core.Interfaces;

namespace MyDesktopApplication.Shared.Audio;

public static class ToneSynthesizer
{
    private const int SampleRate = 44100;

    public static byte[] ForCue(FeedbackCue cue) => cue switch
    {
        FeedbackCue.Correct => CreateWav([(660, 70), (990, 110)], 0.45),
        FeedbackCue.Incorrect => CreateWav([(220, 200)], 0.45),
        _ => CreateWav([(880, 45)], 0.35)
    };

    public static byte[] CreateWav((double FrequencyHz, int DurationMs)[] segments, double volume)
    {
        var samples = new List<short>();
        foreach (var (frequency, durationMs) in segments)
        {
            var count = SampleRate * durationMs / 1000;
            var fade = Math.Min(count / 2, SampleRate / 400);
            for (var i = 0; i < count; i++)
            {
                var envelope = 1.0;
                if (i < fade) envelope = (double)i / fade;
                else if (i > count - fade) envelope = (double)(count - i) / fade;

                var value = Math.Sin(2.0 * Math.PI * frequency * i / SampleRate) * volume * envelope;
                samples.Add((short)(value * short.MaxValue));
            }
        }

        var dataBytes = samples.Count * 2;
        using var stream = new MemoryStream(44 + dataBytes);
        using var writer = new BinaryWriter(stream);

        writer.Write("RIFF"u8.ToArray());
        writer.Write(36 + dataBytes);
        writer.Write("WAVE"u8.ToArray());
        writer.Write("fmt "u8.ToArray());
        writer.Write(16);
        writer.Write((short)1);
        writer.Write((short)1);
        writer.Write(SampleRate);
        writer.Write(SampleRate * 2);
        writer.Write((short)2);
        writer.Write((short)16);
        writer.Write("data"u8.ToArray());
        writer.Write(dataBytes);
        foreach (var sample in samples) writer.Write(sample);

        writer.Flush();
        return stream.ToArray();
    }
}

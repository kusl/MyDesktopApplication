using System.Collections.Concurrent;
using System.Diagnostics;
using System.Runtime.InteropServices;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Shared.Audio;

namespace MyDesktopApplication.Desktop;

public sealed partial class DesktopFeedbackService : IFeedbackService
{
    private const uint SndFilename = 0x00020000;
    private const uint SndAsync = 0x0001;
    private const uint SndNodefault = 0x0002;

    private static readonly string[] LinuxPlayers = ["pw-play", "paplay", "aplay"];
    private readonly ConcurrentDictionary<FeedbackCue, string> _files = new();

    [LibraryImport("winmm.dll", EntryPoint = "PlaySoundW", StringMarshalling = StringMarshalling.Utf16)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static partial bool PlaySound(string? pszSound, IntPtr hmod, uint fdwSound);

    public void Play(FeedbackCue cue)
    {
        try
        {
            var path = _files.GetOrAdd(cue, WriteWav);
            if (OperatingSystem.IsWindows())
            {
                PlaySound(path, IntPtr.Zero, SndFilename | SndAsync | SndNodefault);
            }
            else if (OperatingSystem.IsMacOS())
            {
                Launch("afplay", path);
            }
            else
            {
                foreach (var player in LinuxPlayers)
                {
                    if (Launch(player, path)) break;
                }
            }
        }
        catch
        {
        }
    }

    private static string WriteWav(FeedbackCue cue)
    {
        var path = Path.Combine(Path.GetTempPath(), $"countryquiz-{cue}.wav");
        File.WriteAllBytes(path, ToneSynthesizer.ForCue(cue));
        return path;
    }

    private static bool Launch(string fileName, string argument)
    {
        try
        {
            using var process = Process.Start(new ProcessStartInfo
            {
                FileName = fileName,
                ArgumentList = { argument },
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            });
            return process != null;
        }
        catch
        {
            return false;
        }
    }
}

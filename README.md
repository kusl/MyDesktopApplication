# MyDesktopApplication

[![Build and Release](https://github.com/kusl/MyDesktopApplication/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/build-and-release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Country statistics quiz built with **Avalonia UI 12.2**, **.NET 11**, and **C# 15**. Desktop (Windows, Linux, macOS) and Android from one solution, one shared ViewModel. No ads, no payments, no tracking. Free forever.

## Downloads

| Platform | Architecture | Download |
|----------|--------------|----------|
| Windows | x64, ARM64 | [latest release](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | x64, ARM64 | [latest release](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | x64 (Intel), ARM64 (Apple Silicon) | [latest release](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Android 7.0+ (API 24) | APK | [latest release](https://github.com/kusl/MyDesktopApplication/releases/latest) |

Android: point [Obtainium](https://github.com/ImranR98/Obtainium) at the releases. `versionCode` is the CI run number.

If a platform build fails or GitHub cancels its runner, the other platforms still ship as a **pre-release** that lists what is missing; `latest` and Obtainium stay on the last complete release.

## Quick Start

```bash
dotnet restore
dotnet build
dotnet run --project src/MyDesktopApplication.Desktop
```

Android (requires the workload):

```bash
dotnet workload install android
dotnet build src/MyDesktopApplication.Android -c Release
```

## Run Tests

```bash
dotnet test
```

## Feedback

Every button gives feedback:

- **Sound:** short tones synthesised in code (`ToneSynthesizer`) — no audio assets, no audio packages. Desktop plays them with `winmm` (`PlaySound`) on Windows, `afplay` on macOS, and the first available of `pw-play`, `paplay`, or `aplay` on Linux. Android uses `SoundPool`.
- **Haptics:** Android only (`Vibrator` / `VibratorManager`, requires the `VIBRATE` permission). Desktop has none.
- **Visual:** buttons scale down briefly while pressed, on every platform.

Cues: tap (any button), correct, incorrect. A 🔊/🔇 toggle in the footer mutes sound and haptics for the session (not persisted — no database change, so existing saves are untouched).

## Project Structure

```
src/
  MyDesktopApplication.Core            entities, interfaces (no UI, no IO)
  MyDesktopApplication.Infrastructure  EF Core SQLite, repositories, OpenTelemetry
  MyDesktopApplication.Shared          CountryQuizViewModel, converters, tone synthesis
  MyDesktopApplication.Desktop         Windows/Linux/macOS head
  MyDesktopApplication.Android         Android head
tests/
  MyDesktopApplication.Core.Tests
  MyDesktopApplication.Integration.Tests
  MyDesktopApplication.UI.Tests
```

One `.slnx`, one workflow, one build. Converters and app bootstrap live in `Shared` (no per-platform duplication). Each platform head only registers its own services (database path, feedback implementation).

## Build System

- `global.json` pins the .NET 11 SDK with `rollForward: latestFeature` and `allowPrerelease: true`, so a local `11.0.100-rc` or any newer `11.0.1xx` both work. CI installs `11.0.x`.
- Central Package Management via `Directory.Packages.props`; common settings in `Directory.Build.props`.
- `TreatWarningsAsErrors` in Release.
- Android runs on **CoreCLR** (Mono was removed in .NET 11); the old `RunAOTCompilation` / `UseInterpreter` properties are gone.

## Dependencies

All MIT, Apache-2.0, or BSD. No package whose use depends on payment of any kind.

| | |
|---|---|
| UI | Avalonia 12.2.0 (Fluent2 theme) |
| MVVM | CommunityToolkit.Mvvm 8.4.2 |
| Data | EF Core SQLite 11.0.0 |
| Telemetry | OpenTelemetry 1.21.0 |
| Tests | xunit.v3 4.0.3, Shouldly 4.3.0, NSubstitute 6.2.0, coverlet 10.1.1 |

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows x64 / ARM64 | ✅ |
| Linux x64 / ARM64 | ✅ |
| macOS x64 / ARM64 | ✅ |
| Android 7.0+ | ✅ |
| iOS | ❌ (requires Apple Developer account — $99/year) |

## License

MIT License — free for any use. All dependencies are MIT, Apache-2.0, BSD, or Public Domain licensed.

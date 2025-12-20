# MyDesktopApplication

[![CI](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml)
[![Release](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cross-platform application built with **Avalonia UI** and **.NET 10**.

## Downloads

| Platform | Architecture | Download |
|----------|--------------|----------|
| Windows | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Windows | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | x64 (Intel) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | ARM64 (Apple Silicon) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Android | APK | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |

## Quick Start

### Desktop

```bash
dotnet restore
dotnet build
dotnet run --project src/MyDesktopApplication.Desktop
```

### Android (requires Android workload)

```bash
# Install Android workload (one-time)
dotnet workload install android

# Build APK
dotnet build src/MyDesktopApplication.Android -c Release
```

## Run Tests

```bash
dotnet test
```

## Create Release

Push a tag to create a release with binaries for all platforms:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
├── src/
│   ├── MyDesktopApplication.Core/          # Domain logic
│   ├── MyDesktopApplication.Infrastructure/ # Data access
│   ├── MyDesktopApplication.Shared/        # Shared ViewModels
│   ├── MyDesktopApplication.Desktop/       # Desktop (Windows/Linux/macOS)
│   └── MyDesktopApplication.Android/       # Android
└── tests/
    ├── MyDesktopApplication.Core.Tests/
    ├── MyDesktopApplication.Integration.Tests/
    └── MyDesktopApplication.UI.Tests/
```

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows x64 | ✅ |
| Windows ARM64 | ✅ |
| Linux x64 | ✅ |
| Linux ARM64 | ✅ |
| macOS x64 | ✅ |
| macOS ARM64 | ✅ |
| Android | ✅ |
| iOS | ❌ (requires Apple Developer account - $99/year) |

## License

MIT License - Free for any use.

All dependencies are MIT, Apache-2.0, BSD, or Public Domain licensed.

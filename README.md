# MyDesktopApplication

[![CI](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/ci.yml)
[![Release](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml/badge.svg)](https://github.com/kusl/MyDesktopApplication/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cross-platform desktop app built with **Avalonia UI** and **.NET 10**.

## Downloads

Download the latest release for your platform:

| Platform | Architecture | Download |
|----------|--------------|----------|
| Windows | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Windows | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | x64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| Linux | ARM64 | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | x64 (Intel) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |
| macOS | ARM64 (Apple Silicon) | [Download](https://github.com/kusl/MyDesktopApplication/releases/latest) |

## Quick Start

```bash
dotnet restore
dotnet build
dotnet run --project src/MyDesktopApplication.Desktop
```

## Run Tests

```bash
dotnet test
```

## Create Release

To create a release, push a tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This will automatically build binaries for all platforms and create a GitHub release.

## Project Structure

```
├── src/
│   ├── MyDesktopApplication.Core/          # Domain logic
│   ├── MyDesktopApplication.Infrastructure/ # Data access
│   ├── MyDesktopApplication.Shared/        # Shared code
│   └── MyDesktopApplication.Desktop/       # Avalonia UI
└── tests/
    ├── MyDesktopApplication.Core.Tests/
    ├── MyDesktopApplication.Integration.Tests/
    └── MyDesktopApplication.UI.Tests/
```

## Supported Platforms

### Desktop (Current)
- ✅ Windows x64
- ✅ Windows ARM64
- ✅ Linux x64
- ✅ Linux ARM64
- ✅ macOS x64 (Intel)
- ✅ macOS ARM64 (Apple Silicon)

### Mobile (Future)
- 🔜 Android (requires project setup)
- 🔜 iOS (requires Apple Developer account)

## License

MIT License - Free for any use.

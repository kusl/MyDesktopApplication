# MyDesktopApplication

Cross-platform desktop app built with **Avalonia UI** and **.NET 10**.

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

## Features

- ✅ .NET 10 with SLNX solution format
- ✅ Central Package Management
- ✅ Avalonia UI 11.3 (cross-platform)
- ✅ SQLite & PostgreSQL support
- ✅ OpenTelemetry observability
- ✅ 100% free/open source packages

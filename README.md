# MyDesktopApplication

A modern, cross-platform desktop application built with **Avalonia UI** and **.NET 10**.

## Features

- ✅ **Cross-platform**: Windows, Linux, macOS
- ✅ **Modern .NET 10**: Latest language features and performance
- ✅ **SLNX solution format**: New XML-based solution file
- ✅ **Central Package Management**: All versions in one place
- ✅ **OpenTelemetry**: Full observability (logs, metrics, traces)
- ✅ **SQLite & PostgreSQL**: Sustainable database options
- ✅ **100% Free packages**: MIT/Apache-2.0 licensed only
- ✅ **Testable architecture**: Unit, integration, and UI tests
- ✅ **MVVM pattern**: Clean separation with CommunityToolkit.Mvvm

## Quick Start

```bash
# 1. Install Avalonia templates
dotnet new install Avalonia.Templates

# 2. Clone or create project directory
cd ~/src/dotnet/MyDesktopApplication

# 3. Run setup script (creates all projects)
chmod +x setup.sh && ./setup.sh

# 4. Restore and build
dotnet restore
dotnet build

# 5. Run the application
dotnet run --project src/MyDesktopApplication.Desktop

# 6. Run tests
dotnet test
```

## Project Structure

```
MyDesktopApplication/
├── MyDesktopApplication.slnx          # New SLNX solution format
├── Directory.Build.props              # Shared build settings
├── Directory.Packages.props           # Central package versions
├── .gitignore
├── README.md
├── src/
│   ├── MyDesktopApplication.Core/     # Domain entities, interfaces
│   ├── MyDesktopApplication.Infrastructure/  # Data access, repositories
│   ├── MyDesktopApplication.Shared/   # Shared ViewModels/DTOs
│   └── MyDesktopApplication.Desktop/  # Avalonia UI application
│       ├── Assets/
│       ├── Views/
│       ├── ViewModels/
│       ├── Extensions/
│       ├── App.axaml
│       ├── Program.cs
│       └── appsettings.json
└── tests/
    ├── MyDesktopApplication.Core.Tests/        # Unit tests
    ├── MyDesktopApplication.Integration.Tests/ # DB integration tests
    └── MyDesktopApplication.UI.Tests/          # Avalonia headless tests
```

## Technology Stack

| Category | Technology | License |
|----------|------------|---------|
| UI Framework | Avalonia 11.3 | MIT |
| MVVM | CommunityToolkit.Mvvm | MIT |
| DI | Microsoft.Extensions.DI | MIT |
| Logging | Serilog | Apache-2.0 |
| Telemetry | OpenTelemetry | Apache-2.0 |
| Database | SQLite / PostgreSQL | Public Domain / PostgreSQL |
| ORM | Entity Framework Core | MIT |
| Testing | xUnit, FluentAssertions | Apache-2.0/MIT |
| Containers | Testcontainers | MIT |

## Configuration

### Database (appsettings.json)

```json
{
  "Database": {
    "UsePostgreSql": false,  // Set true for PostgreSQL
    "PostgreSqlConnection": "Host=localhost;Database=myapp;..."
  }
}
```

### OpenTelemetry

Export telemetry to OTLP-compatible backends:

```json
{
  "OpenTelemetry": {
    "EnableConsoleExporter": true,
    "OtlpEndpoint": "http://localhost:4317"  // Jaeger, Grafana, etc.
  }
}
```

## Commands

```bash
# Build
dotnet build

# Run application
dotnet run --project src/MyDesktopApplication.Desktop

# Run all tests
dotnet test

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"

# Create release build
dotnet publish src/MyDesktopApplication.Desktop -c Release -r linux-x64

# Add new project to solution
dotnet sln add path/to/project.csproj
```

## IDE Recommendations

For Linux/Fedora, **JetBrains Rider** is recommended for the best Avalonia development experience with XAML preview support. Install the AvaloniaRider plugin for live preview.

VS Code works with the C# Dev Kit and Avalonia extensions, though with more limited XAML support.

## License

AGPLv3 

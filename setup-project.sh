#!/bin/bash
# =============================================================================
# MyDesktopApplication - Complete Setup & Fix Script
# =============================================================================
# This script creates/updates all configuration files for the project.
# Run from: ~/src/dotnet/MyDesktopApplication/
#
# Usage: ./setup-project.sh [--clean]
#   --clean    Remove and recreate all generated files
# =============================================================================

set -e

PROJECT_NAME="MyDesktopApplication"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

echo "=============================================="
echo "  $PROJECT_NAME Setup Script"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# 1. Create Directory.Build.props
# -----------------------------------------------------------------------------
log_info "Creating Directory.Build.props..."

cat > Directory.Build.props << 'EOF'
<Project>
  <!-- Shared build properties for all projects -->
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsAsErrors />
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <AnalysisLevel>latest</AnalysisLevel>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>

  <!-- Assembly and versioning -->
  <PropertyGroup>
    <Company>YourCompanyName</Company>
    <Authors>Your Name</Authors>
    <Copyright>Copyright © $([System.DateTime]::Now.Year)</Copyright>
    <VersionPrefix>1.0.0</VersionPrefix>
    <VersionSuffix Condition="'$(Configuration)' == 'Debug'">dev</VersionSuffix>
    <RepositoryType>git</RepositoryType>
  </PropertyGroup>

  <!-- Deterministic builds for reproducibility -->
  <PropertyGroup>
    <Deterministic>true</Deterministic>
    <ContinuousIntegrationBuild Condition="'$(CI)' == 'true'">true</ContinuousIntegrationBuild>
  </PropertyGroup>

  <!-- Test project conventions -->
  <PropertyGroup Condition="$(MSBuildProjectName.EndsWith('.Tests'))">
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
</Project>
EOF

# -----------------------------------------------------------------------------
# 2. Create Directory.Packages.props (Central Package Management)
# -----------------------------------------------------------------------------
log_info "Creating Directory.Packages.props..."

cat > Directory.Packages.props << 'EOF'
<Project>
  <!-- Central Package Management - All package versions in one place -->
  <!-- All packages are MIT/Apache-2.0 licensed and free for any use -->
  
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup>
    <!-- Avalonia UI (MIT License) -->
    <PackageVersion Include="Avalonia" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.0" />
    <PackageVersion Include="Avalonia.ReactiveUI" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.0" />

    <!-- MVVM (MIT License) -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
    <PackageVersion Include="ReactiveUI" Version="20.2.62" />

    <!-- Microsoft Extensions (MIT License) -->
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Hosting" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Json" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Console" Version="10.0.0" />

    <!-- Logging - Serilog (Apache-2.0 License) -->
    <PackageVersion Include="Serilog" Version="4.2.0" />
    <PackageVersion Include="Serilog.Extensions.Hosting" Version="9.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="6.0.0" />
    <PackageVersion Include="Serilog.Sinks.File" Version="6.0.0" />

    <!-- OpenTelemetry (Apache-2.0 License) -->
    <PackageVersion Include="OpenTelemetry" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.11.2" />

    <!-- Database (Public Domain / PostgreSQL License) -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.0" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
    <PackageVersion Include="Dapper" Version="2.1.66" />

    <!-- Validation (Apache-2.0 License) -->
    <PackageVersion Include="FluentValidation" Version="11.11.0" />
    <PackageVersion Include="FluentValidation.DependencyInjectionExtensions" Version="11.11.0" />

    <!-- Testing (MIT/Apache-2.0 License) -->
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.4" />
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    <PackageVersion Include="FluentAssertions" Version="8.0.1" />
    <PackageVersion Include="Bogus" Version="35.6.1" />
    <PackageVersion Include="Testcontainers" Version="4.3.0" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.3.0" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />

    <!-- HTTP & Serialization (MIT License) -->
    <PackageVersion Include="System.Text.Json" Version="10.0.0" />
    <PackageVersion Include="Refit" Version="8.0.0" />
    <PackageVersion Include="Polly" Version="8.5.2" />
  </ItemGroup>
</Project>
EOF

# -----------------------------------------------------------------------------
# 3. Create/Update .csproj files (remove Version attributes for CPM)
# -----------------------------------------------------------------------------
log_info "Updating project files for Central Package Management..."

# Desktop project
cat > src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
  </PropertyGroup>

  <ItemGroup>
    <Folder Include="Models\" />
    <AvaloniaResource Include="Assets\**" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Desktop" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="Avalonia.Diagnostics" Condition="'$(Configuration)' == 'Debug'" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
  </ItemGroup>
</Project>
EOF

# Core project
cat > src/$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="FluentValidation" />
  </ItemGroup>
</Project>
EOF

# Infrastructure project
cat > src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" />
    <PackageReference Include="Dapper" />
    <PackageReference Include="Microsoft.Extensions.Configuration" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
EOF

# Shared project
cat > src/$PROJECT_NAME.Shared/$PROJECT_NAME.Shared.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="CommunityToolkit.Mvvm" />
  </ItemGroup>
</Project>
EOF

# Core.Tests project
cat > tests/$PROJECT_NAME.Core.Tests/$PROJECT_NAME.Core.Tests.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Bogus" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
</Project>
EOF

# Integration.Tests project
cat > tests/$PROJECT_NAME.Integration.Tests/$PROJECT_NAME.Integration.Tests.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" />
    <PackageReference Include="Bogus" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
    <PackageReference Include="Testcontainers" />
    <PackageReference Include="Testcontainers.PostgreSql" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\..\src\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
</Project>
EOF

# UI.Tests project
cat > tests/$PROJECT_NAME.UI.Tests/$PROJECT_NAME.UI.Tests.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" />
    <PackageReference Include="Avalonia.Headless" />
    <PackageReference Include="Avalonia.Headless.XUnit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Desktop\MyDesktopApplication.Desktop.csproj" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
</Project>
EOF

# -----------------------------------------------------------------------------
# 4. Create appsettings.json
# -----------------------------------------------------------------------------
log_info "Creating appsettings.json..."

cat > appsettings.json << 'EOF'
{
  "Application": {
    "Name": "MyDesktopApplication",
    "Theme": "Fluent"
  },
  "Database": {
    "UsePostgreSql": false,
    "PostgreSqlConnection": "Host=localhost;Database=myapp;Username=postgres;Password=postgres",
    "SqliteFileName": "app.db"
  },
  "OpenTelemetry": {
    "EnableConsoleExporter": true,
    "OtlpEndpoint": null
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console" }
    ],
    "Enrich": ["FromLogContext", "WithMachineName"]
  }
}
EOF

# -----------------------------------------------------------------------------
# 5. Create .gitignore
# -----------------------------------------------------------------------------
log_info "Creating .gitignore..."

cat > .gitignore << 'EOF'
# Build outputs
[Bb]in/
[Oo]bj/
[Oo]ut/
[Ll]og/
[Ll]ogs/

# IDE
.vs/
.vscode/
.idea/
*.suo
*.user
*.sln.iml

# Test results
TestResults/
coverage*/
*.coverage

# NuGet
*.nupkg
**/[Pp]ackages/*

# Local settings
appsettings.*.local.json
.env
.env.local

# Databases
*.db
*.db-shm
*.db-wal

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/
EOF

# -----------------------------------------------------------------------------
# 6. Create README.md
# -----------------------------------------------------------------------------
log_info "Creating README.md..."

cat > README.md << 'EOF'
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
EOF

# -----------------------------------------------------------------------------
# 7. Restore and Build
# -----------------------------------------------------------------------------
echo ""
log_info "Running dotnet restore..."
if dotnet restore; then
    log_info "Restore successful!"
else
    log_error "Restore failed. Check errors above."
    exit 1
fi

echo ""
log_info "Running dotnet build..."
if dotnet build --no-restore; then
    log_info "Build successful!"
else
    log_error "Build failed. Check errors above."
    exit 1
fi

# -----------------------------------------------------------------------------
# Done!
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo -e "  ${GREEN}Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  1. Run the app:    dotnet run --project src/$PROJECT_NAME.Desktop"
echo "  2. Run tests:      dotnet test"
echo "  3. Edit code in:   src/$PROJECT_NAME.Desktop/"
echo ""

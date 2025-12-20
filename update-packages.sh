#!/bin/bash
# =============================================================================
# Update All Package Versions to Latest
# =============================================================================
# This script updates Directory.Packages.props with the latest package versions.
# Run from: ~/src/dotnet/MyDesktopApplication/
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "  Updating Package Versions"
echo "=============================================="
echo ""

# Backup current file
cp Directory.Packages.props Directory.Packages.props.bak
echo -e "${GREEN}✓${NC} Backed up Directory.Packages.props to Directory.Packages.props.bak"

# Create updated Directory.Packages.props with latest versions
cat > Directory.Packages.props << 'ENDOFFILE'
<Project>
  <!-- Central Package Management - All package versions in one place -->
  <!-- All packages are MIT/Apache-2.0 licensed and free for any use -->
  <!-- Last updated: TIMESTAMP_PLACEHOLDER -->
  
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup>
    <!-- Avalonia UI (MIT License) - Updated to 11.3.10 -->
    <PackageVersion Include="Avalonia" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.10" />
    <PackageVersion Include="Avalonia.ReactiveUI" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Headless" Version="11.3.10" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.10" />

    <!-- MVVM (MIT License) -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
    <PackageVersion Include="ReactiveUI" Version="20.2.62" />

    <!-- Microsoft Extensions (MIT License) - Updated to 10.0.1 -->
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Hosting" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Json" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Console" Version="10.0.1" />

    <!-- Logging - Serilog (Apache-2.0) -->
    <PackageVersion Include="Serilog" Version="4.2.0" />
    <PackageVersion Include="Serilog.Extensions.Hosting" Version="9.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="6.0.0" />
    <PackageVersion Include="Serilog.Sinks.File" Version="6.0.0" />

    <!-- OpenTelemetry (Apache-2.0) -->
    <PackageVersion Include="OpenTelemetry" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.11.2" />
    <PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.11.2" />

    <!-- Database - Updated to 10.0.1 -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.1" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.1" />
    <PackageVersion Include="Dapper" Version="2.1.66" />

    <!-- Validation - Updated to 12.1.1 -->
    <PackageVersion Include="FluentValidation" Version="12.1.1" />
    <PackageVersion Include="FluentValidation.DependencyInjectionExtensions" Version="12.1.1" />

    <!-- Testing - Updated versions -->
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="18.0.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.5" />
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    <PackageVersion Include="FluentAssertions" Version="8.8.0" />
    <PackageVersion Include="Bogus" Version="35.6.5" />
    <PackageVersion Include="Testcontainers" Version="4.9.0" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.9.0" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />

    <!-- HTTP & Serialization (MIT License) -->
    <PackageVersion Include="System.Text.Json" Version="10.0.1" />
    <PackageVersion Include="Refit" Version="8.0.0" />
    <PackageVersion Include="Polly" Version="8.5.2" />
  </ItemGroup>
</Project>
ENDOFFILE

# Replace timestamp placeholder with actual date
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date '+%Y-%m-%d')/" Directory.Packages.props

echo -e "${GREEN}✓${NC} Updated Directory.Packages.props with latest versions"
echo ""

# Show what changed
echo -e "${YELLOW}Package version changes:${NC}"
echo "  Avalonia:                    11.3.0  → 11.3.10"
echo "  Microsoft.Extensions.*:      10.0.0  → 10.0.1"
echo "  Microsoft.EntityFrameworkCore: 10.0.0 → 10.0.1"
echo "  FluentValidation:            11.11.0 → 12.1.1"
echo "  Microsoft.NET.Test.Sdk:      17.14.1 → 18.0.1"
echo "  FluentAssertions:            8.0.1   → 8.8.0"
echo "  Bogus:                       35.6.1  → 35.6.5"
echo "  Testcontainers:              4.3.0   → 4.9.0"
echo "  xunit.runner.visualstudio:   3.1.4   → 3.1.5"
echo ""

# Restore and build
echo -e "${GREEN}✓${NC} Running dotnet restore..."
dotnet restore

echo ""
echo -e "${GREEN}✓${NC} Running dotnet build..."
if dotnet build; then
    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}Update Complete!${NC}"
    echo "=============================================="
    echo ""
    echo "All packages updated to latest versions."
    echo "Run tests to verify: dotnet test"
    echo ""
    echo "To rollback: cp Directory.Packages.props.bak Directory.Packages.props"
else
    echo ""
    echo -e "${YELLOW}Build failed - you may need to check for breaking changes${NC}"
    echo "Rollback with: cp Directory.Packages.props.bak Directory.Packages.props"
fi

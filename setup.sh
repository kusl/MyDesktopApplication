#!/bin/bash
# Avalonia UI Desktop Application Setup Script
# .NET 10 with modern practices: SLNX, Central Package Management, OpenTelemetry

set -e

PROJECT_NAME="MyDesktopApplication"
BASE_DIR="$HOME/src/dotnet/$PROJECT_NAME"

echo "🚀 Setting up $PROJECT_NAME with .NET 10 and Avalonia UI..."

# Install Avalonia templates if not already installed
echo "📦 Installing Avalonia templates..."
dotnet new install Avalonia.Templates

# Create directory structure
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Initialize git repository
git init

# Create the SLNX solution file (default in .NET 10)
echo "📄 Creating SLNX solution file..."
dotnet new sln -n "$PROJECT_NAME"

# Create source directories
mkdir -p src tests docs

# Create the main application project structure
echo "🏗️ Creating project structure..."

# 1. Core/Domain project (business logic, no dependencies)
dotnet new classlib -n "$PROJECT_NAME.Core" -o "src/$PROJECT_NAME.Core" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj"

# 2. Infrastructure project (data access, external services)
dotnet new classlib -n "$PROJECT_NAME.Infrastructure" -o "src/$PROJECT_NAME.Infrastructure" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj"

# 3. Main Avalonia Desktop App
dotnet new avalonia.mvvm -n "$PROJECT_NAME.Desktop" -o "src/$PROJECT_NAME.Desktop" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj"

# 4. Shared ViewModels/Services (for potential future mobile/web)
dotnet new classlib -n "$PROJECT_NAME.Shared" -o "src/$PROJECT_NAME.Shared" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Shared/$PROJECT_NAME.Shared.csproj"

# 5. Unit Tests
dotnet new xunit -n "$PROJECT_NAME.Core.Tests" -o "tests/$PROJECT_NAME.Core.Tests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.Core.Tests/$PROJECT_NAME.Core.Tests.csproj"

# 6. Integration Tests
dotnet new xunit -n "$PROJECT_NAME.Integration.Tests" -o "tests/$PROJECT_NAME.Integration.Tests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.Integration.Tests/$PROJECT_NAME.Integration.Tests.csproj"

# 7. UI Tests (Avalonia Headless)
dotnet new xunit -n "$PROJECT_NAME.UI.Tests" -o "tests/$PROJECT_NAME.UI.Tests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.UI.Tests/$PROJECT_NAME.UI.Tests.csproj"

echo "✅ Project structure created successfully!"
echo ""
echo "📁 Project layout:"
find . -name "*.csproj" -o -name "*.slnx" | sort
echo ""
echo "Next steps:"
echo "1. Copy the Directory.Build.props file to the root"
echo "2. Copy the Directory.Packages.props file to the root"
echo "3. Update individual .csproj files with the provided templates"
echo "4. Run: dotnet restore"
echo "5. Run: dotnet build"
echo "6. Run: dotnet run --project src/$PROJECT_NAME.Desktop"

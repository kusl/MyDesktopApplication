#!/bin/bash
# Avalonia UI Desktop Application Setup Script
# .NET 10 with modern practices: SLNX, Central Package Management, OpenTelemetry
# 
# WORKAROUND: Avalonia templates don't support -f net10.0 yet,
# so we create with net9.0 then Directory.Build.props overrides to net10.0

set -e

PROJECT_NAME="MyDesktopApplication"

echo "🚀 Setting up $PROJECT_NAME with .NET 10 and Avalonia UI..."

# Install Avalonia templates if not already installed
echo "📦 Installing Avalonia templates..."
dotnet new install Avalonia.Templates

# Initialize git repository if not already
if [ ! -d ".git" ]; then
    git init
fi

# Create the SLNX solution file (default in .NET 10)
# Remove existing solution if present
rm -f "$PROJECT_NAME.slnx" "$PROJECT_NAME.sln"

echo "📄 Creating SLNX solution file..."
dotnet new sln -n "$PROJECT_NAME"

# Create source directories
mkdir -p src tests docs/llm

# Create the main application project structure
echo "🏗️ Creating project structure..."

# 1. Core/Domain project (business logic, no dependencies)
# Using classlib which works fine with net10.0
rm -rf "src/$PROJECT_NAME.Core"
dotnet new classlib -n "$PROJECT_NAME.Core" -o "src/$PROJECT_NAME.Core" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Core/$PROJECT_NAME.Core.csproj"

# 2. Infrastructure project (data access, external services)
rm -rf "src/$PROJECT_NAME.Infrastructure"
dotnet new classlib -n "$PROJECT_NAME.Infrastructure" -o "src/$PROJECT_NAME.Infrastructure" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Infrastructure/$PROJECT_NAME.Infrastructure.csproj"

# 3. Shared ViewModels/Services (for potential future mobile/web)
rm -rf "src/$PROJECT_NAME.Shared"
dotnet new classlib -n "$PROJECT_NAME.Shared" -o "src/$PROJECT_NAME.Shared" -f net10.0
dotnet sln add "src/$PROJECT_NAME.Shared/$PROJECT_NAME.Shared.csproj"

# 4. Main Avalonia Desktop App
# WORKAROUND: Create with net9.0 (template limitation), then manually update to net10.0
echo "🎨 Creating Avalonia Desktop project (will upgrade to net10.0)..."
rm -rf "src/$PROJECT_NAME.Desktop"
dotnet new avalonia.mvvm -n "$PROJECT_NAME.Desktop" -o "src/$PROJECT_NAME.Desktop" -f net9.0
dotnet sln add "src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj"

# Update the Desktop project to net10.0
echo "⬆️ Upgrading Desktop project to net10.0..."
sed -i 's/<TargetFramework>net9.0<\/TargetFramework>/<TargetFramework>net10.0<\/TargetFramework>/g' \
    "src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj"

# 5. Unit Tests
rm -rf "tests/$PROJECT_NAME.Core.Tests"
dotnet new xunit -n "$PROJECT_NAME.Core.Tests" -o "tests/$PROJECT_NAME.Core.Tests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.Core.Tests/$PROJECT_NAME.Core.Tests.csproj"

# 6. Integration Tests
rm -rf "tests/$PROJECT_NAME.Integration.Tests"
dotnet new xunit -n "$PROJECT_NAME.Integration.Tests" -o "tests/$PROJECT_NAME.Integration.Tests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.Integration.Tests/$PROJECT_NAME.Integration.Tests.csproj"

# 7. UI Tests (Avalonia Headless)
rm -rf "tests/$PROJECT_NAME.UI.Tests"
dotnet new xunit -n "$PROJECT_NAME.UI.Tests" -o "tests/$PROJECT_NAME.UI.Tests" -f net10.0
dotnet sln add "tests/$PROJECT_NAME.UI.Tests/$PROJECT_NAME.UI.Tests.csproj"

echo ""
echo "✅ Project structure created successfully!"
echo ""
echo "📁 Project layout:"
find . -name "*.csproj" -o -name "*.slnx" 2>/dev/null | grep -v obj | sort
echo ""
echo "🔧 Next steps:"
echo "1. Ensure Directory.Build.props is in the root (sets net10.0 for all)"
echo "2. Ensure Directory.Packages.props is in the root"
echo "3. Update individual .csproj files with proper package references"
echo "4. Run: dotnet restore"
echo "5. Run: dotnet build"
echo "6. Run: dotnet run --project src/$PROJECT_NAME.Desktop"

#!/bin/bash
# Continue setup from current state
# Run this from ~/src/dotnet/MyDesktopApplication/

set -e

PROJECT_NAME="MyDesktopApplication"

echo "🔧 Continuing setup from current state..."

# Create Shared project
if [ ! -d "src/$PROJECT_NAME.Shared" ]; then
    echo "Creating Shared project..."
    dotnet new classlib -n "$PROJECT_NAME.Shared" -o "src/$PROJECT_NAME.Shared" -f net10.0
    dotnet sln "$PROJECT_NAME.slnx" add "src/$PROJECT_NAME.Shared/$PROJECT_NAME.Shared.csproj"
fi

# Create Desktop project with Avalonia (use net9.0 then upgrade)
if [ ! -d "src/$PROJECT_NAME.Desktop" ]; then
    echo "🎨 Creating Avalonia Desktop project..."
    dotnet new avalonia.mvvm -n "$PROJECT_NAME.Desktop" -o "src/$PROJECT_NAME.Desktop" -f net9.0
    dotnet sln "$PROJECT_NAME.slnx" add "src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj"
    
    # Upgrade to net10.0
    echo "⬆️ Upgrading to net10.0..."
    sed -i 's/<TargetFramework>net9.0<\/TargetFramework>/<TargetFramework>net10.0<\/TargetFramework>/g' \
        "src/$PROJECT_NAME.Desktop/$PROJECT_NAME.Desktop.csproj"
fi

# Create test projects
mkdir -p tests

if [ ! -d "tests/$PROJECT_NAME.Core.Tests" ]; then
    echo "Creating Core.Tests..."
    dotnet new xunit -n "$PROJECT_NAME.Core.Tests" -o "tests/$PROJECT_NAME.Core.Tests" -f net10.0
    dotnet sln "$PROJECT_NAME.slnx" add "tests/$PROJECT_NAME.Core.Tests/$PROJECT_NAME.Core.Tests.csproj"
fi

if [ ! -d "tests/$PROJECT_NAME.Integration.Tests" ]; then
    echo "Creating Integration.Tests..."
    dotnet new xunit -n "$PROJECT_NAME.Integration.Tests" -o "tests/$PROJECT_NAME.Integration.Tests" -f net10.0
    dotnet sln "$PROJECT_NAME.slnx" add "tests/$PROJECT_NAME.Integration.Tests/$PROJECT_NAME.Integration.Tests.csproj"
fi

if [ ! -d "tests/$PROJECT_NAME.UI.Tests" ]; then
    echo "Creating UI.Tests..."
    dotnet new xunit -n "$PROJECT_NAME.UI.Tests" -o "tests/$PROJECT_NAME.UI.Tests" -f net10.0
    dotnet sln "$PROJECT_NAME.slnx" add "tests/$PROJECT_NAME.UI.Tests/$PROJECT_NAME.UI.Tests.csproj"
fi

echo ""
echo "✅ All projects created!"
echo ""
echo "📁 Current solution structure:"
cat "$PROJECT_NAME.slnx"
echo ""
echo "🔧 Next: Run 'dotnet restore' then 'dotnet build'"

#!/bin/bash
set -e

cd ~/src/dotnet/MyDesktopApplication

echo "=============================================="
echo "  Cleaning Up Project Structure"
echo "=============================================="

# Step 1: Create unified solution with all projects
echo ""
echo "Step 1: Creating unified solution file..."

cat > MyDesktopApplication.slnx << 'SLNX'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <Project Path="src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
    <Project Path="src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
    <Project Path="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
    <Project Path="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" />
  </Folder>
</Solution>
SLNX

echo "✓ Created unified MyDesktopApplication.slnx"

# Step 2: Remove the desktop-only solution
echo ""
echo "Step 2: Removing duplicate solution files..."

rm -f MyDesktopApplication.Desktop.slnx
echo "✓ Removed MyDesktopApplication.Desktop.slnx"

# Step 3: Remove all the temporary shell scripts (keep only export.sh)
echo ""
echo "Step 3: Removing temporary shell scripts..."

SCRIPTS_TO_REMOVE=(
    "build-android.sh"
    "build-desktop.sh"
    "continue-setup.sh"
    "fix-all.sh"
    "fix-android-build.sh"
    "fix-android-code.sh"
    "fix-android-font.sh"
    "fix-android-namespace.sh"
    "fix-android-theme.sh"
    "fix-ci-and-add-android.sh"
    "fix-cpm.sh"
    "fix-tests.sh"
    "run-tests.sh"
    "setup-all.sh"
    "setup-android-fedora.sh"
    "setup-github-actions.sh"
    "setup-project.sh"
    "setup.sh"
    "update-packages.sh"
)

for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "  Removed: $script"
    fi
done

echo "✓ Temporary scripts removed (export.sh kept)"

# Step 4: Remove root appsettings.json if Desktop has one
echo ""
echo "Step 4: Cleaning up duplicate config files..."

if [ -f "src/MyDesktopApplication.Desktop/appsettings.json" ] && [ -f "appsettings.json" ]; then
    rm -f appsettings.json
    echo "✓ Removed duplicate root appsettings.json"
fi

# Step 5: Update .gitignore to be cleaner
echo ""
echo "Step 5: Updating .gitignore..."

cat > .gitignore << 'GITIGNORE'
# Build outputs
bin/
obj/
out/

# IDE
.vs/
.vscode/
.idea/
*.user
*.suo
*.userosscache
*.sln.docstates

# NuGet
*.nupkg
packages/
project.lock.json
project.fragment.lock.json

# Test results
TestResults/
coverage/
*.coverage
*.coveragexml

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Local settings
appsettings.local.json
appsettings.*.local.json

# LLM export (optional - uncomment to ignore)
# docs/llm/
GITIGNORE

echo "✓ Updated .gitignore"

# Step 6: Clean build artifacts
echo ""
echo "Step 6: Cleaning build artifacts..."

rm -rf bin obj
rm -rf src/*/bin src/*/obj
rm -rf tests/*/bin tests/*/obj
dotnet build-server shutdown 2>/dev/null || true

echo "✓ Build artifacts cleaned"

# Step 7: Test the unified build
echo ""
echo "Step 7: Testing unified build..."

if dotnet build MyDesktopApplication.slnx -v quiet; then
    echo "✓ Build succeeded!"
else
    echo "✗ Build failed - check errors above"
    exit 1
fi

# Step 8: Run tests
echo ""
echo "Step 8: Running tests..."

if dotnet test MyDesktopApplication.slnx --no-build -v quiet; then
    echo "✓ All tests passed!"
else
    echo "⚠ Some tests failed"
fi

# Step 9: Summary
echo ""
echo "=============================================="
echo "  Cleanup Complete!"
echo "=============================================="
echo ""
echo "Project structure is now simplified:"
echo ""
echo "  MyDesktopApplication.slnx     <- Single unified solution"
echo "  export.sh                     <- Export script for LLM analysis"
echo "  Directory.Build.props         <- Shared build settings"
echo "  Directory.Packages.props      <- Central package versions"
echo ""
echo "Standard commands:"
echo "  dotnet build                  <- Build everything"
echo "  dotnet test                   <- Run all tests"
echo "  dotnet run --project src/MyDesktopApplication.Desktop"
echo ""
echo "Files removed:"
echo "  - MyDesktopApplication.Desktop.slnx (redundant)"
echo "  - All fix-*.sh, setup-*.sh, build-*.sh scripts"
echo "  - Root appsettings.json (duplicate)"
echo ""
echo "These scripts are preserved in git history if needed."

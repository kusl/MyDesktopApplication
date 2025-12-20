#!/bin/bash
# Fix Central Package Management issues by removing Version attributes from PackageReference
# Run from: ~/src/dotnet/MyDesktopApplication/

set -e

echo "🔧 Fixing Central Package Management compatibility..."

# Function to remove Version attributes from PackageReference elements
fix_csproj() {
    local file="$1"
    echo "  Fixing: $file"
    
    # Remove Version="X.Y.Z" from PackageReference lines
    # This sed pattern handles various formats
    sed -i -E 's/(<PackageReference Include="[^"]+") Version="[^"]+"/\1/g' "$file"
    
    # Also handle multiline format where Version is on same line
    sed -i -E 's/(<PackageReference Include="[^"]+") Version="[^"]+"/\1/g' "$file"
}

# Fix Desktop project
if [ -f "src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" ]; then
    fix_csproj "src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj"
fi

# Fix test projects
for proj in tests/*/; do
    csproj=$(find "$proj" -name "*.csproj" 2>/dev/null | head -1)
    if [ -n "$csproj" ]; then
        fix_csproj "$csproj"
    fi
done

echo ""
echo "✅ Fixed! Now run:"
echo "   dotnet restore"
echo "   dotnet build"

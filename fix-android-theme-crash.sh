#!/bin/bash
set -e

cd ~/src/dotnet/MyDesktopApplication

echo "Fixing Android AppCompat theme crash..."

# Fix styles.xml - use AppCompat theme instead of Material
cat > src/MyDesktopApplication.Android/Resources/values/styles.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="MyTheme" parent="Theme.AppCompat.Light.DarkActionBar">
    </style>
    <style name="MyTheme.NoActionBar" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="android:windowBackground">@android:color/white</item>
        <item name="windowActionBar">false</item>
        <item name="windowNoTitle">true</item>
    </style>
</resources>
XML

echo "✓ Fixed styles.xml (now using Theme.AppCompat)"

# Verify the csproj has the AppCompat package reference
if ! grep -q "Xamarin.AndroidX.AppCompat" src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj; then
    echo "Adding Xamarin.AndroidX.AppCompat package reference..."
    # Insert before closing </Project> tag
    sed -i 's|</Project>|  <ItemGroup>\n    <PackageReference Include="Xamarin.AndroidX.AppCompat" />\n  </ItemGroup>\n</Project>|' src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj
    
    # Add to Directory.Packages.props if not present
    if ! grep -q "Xamarin.AndroidX.AppCompat" Directory.Packages.props; then
        sed -i 's|</ItemGroup>|  <PackageVersion Include="Xamarin.AndroidX.AppCompat" Version="1.7.0.3" />\n  </ItemGroup>|' Directory.Packages.props
    fi
    echo "✓ Added AppCompat package reference"
fi

echo ""
echo "Done! Now rebuild and redeploy:"
echo "  dotnet build src/MyDesktopApplication.Android"
echo "  # Then install the new APK on your tablet"

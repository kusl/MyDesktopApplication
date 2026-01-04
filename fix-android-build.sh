#!/bin/sh

# This script fixes the invalid android:versionCode error in local builds
# without affecting GitHub Actions CI. It edits Directory.Build.props and
# MyDesktopApplication.Android.csproj to set valid defaults and dynamic versions.
# Run this in the project root (/home/kushal/src/dotnet/MyDesktopApplication).
# After running, test with: dotnet clean; dotnet build

set -e  # Exit on error

# Step 1: Update default BuildNumber to 1 in Directory.Build.props
# Why: Local default was 0 (invalid for versionCode); change to 1 (valid minimum).
# CI overrides this, so no regression.
sed -i 's/<BuildNumber Condition="'\''$(BuildNumber)'\'' == '\'''\''">0<\/BuildNumber>/<BuildNumber Condition="'\''$(BuildNumber)'\'' == '\'''\''">1<\/BuildNumber>/' Directory.Build.props
echo "Updated default BuildNumber to 1 in Directory.Build.props"

# Step 2: Add ApplicationVersion and ApplicationDisplayVersion to Android.csproj
# Why: These map to android:versionCode and versionName in the manifest.
# Inserts after the first <PropertyGroup> line to place in the main group.
# Uses $(BuildNumber) for dynamic CI incrementing; falls back to local default (now 1).
# ApplicationDisplayVersion uses existing InformationalVersion for consistency.
csproj="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"
sed -i '/<PropertyGroup>/a\    <ApplicationVersion>$(BuildNumber)<\/ApplicationVersion>\n    <ApplicationDisplayVersion>$(InformationalVersion)<\/ApplicationDisplayVersion>' "$csproj"
echo "Added ApplicationVersion and ApplicationDisplayVersion to $csproj"

echo "Fix complete. Run 'dotnet clean; dotnet build' to verify. No changes to CI workflow."

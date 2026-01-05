#!/bin/sh

# This script fixes the empty AndroidSigningKeyPass error in local Debug builds
# by adding a conditional hardcoded password for Debug config in Android.csproj.
# Run this in the project root (/home/kushal/src/dotnet/MyDesktopApplication).
# After running, test with: dotnet clean; dotnet build

set -e  # Exit on error

csproj="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"

# Check if Debug conditional group already exists
if grep -q "<PropertyGroup Condition=\"'\\\$(Configuration)'=='Debug'\">" "$csproj"; then
  echo "Debug conditional PropertyGroup already exists in $csproj - skipping to avoid duplicates."
else
  # Insert after the first <PropertyGroup> (main one)
  sed -i '/<PropertyGroup>/a\  <PropertyGroup Condition="'\''$(Configuration)'\''=='\''Debug'\''">\n    <AndroidSigningPassword>android<\/AndroidSigningPassword>\n  <\/PropertyGroup>' "$csproj"
  echo "Added Debug conditional AndroidSigningPassword in $csproj"
fi

echo "Fix complete. Run 'dotnet clean; dotnet build' to verify. No changes to CI (Release overrides via secret)."

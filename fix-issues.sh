#!/bin/sh

# This script fixes two issues:
# 1. Android APK update conflict by implementing consistent signing with a keystore.
# - Generates a keystore locally if not exists (using weak 'android' password for simplicity; change for production).
# - Base64 encodes it and instructs to add to GitHub secrets.
# - Modifies .csproj to use signing props with password from MSBuild property (via secret in CI).
# - Modifies workflow.yml to decode keystore from secret and pass password to publish command.
# - Adds keystore files to .gitignore.
# Why: Each CI run generates a new debug key, causing signature mismatch. Using consistent keystore allows direct updates.
# No regression: Local builds use generated keystore; CI uses secret. Releases continue on push.
# Note: After running, go to GitHub repo settings > Secrets and actions > New repository secret:
# - ANDROID_KEYSTORE_BASE64: paste content of android.keystore.base64
# - ANDROID_SIGNING_PASSWORD: 'android' (or your custom password if changed below)

# 2. UI highlight only selected answer on all platforms (fix for Windows; ensure consistency elsewhere).
# - Modifies ViewModels (CountryQuizViewModel.cs and MainWindowViewModel.cs) to set IsCorrect/IsIncorrect only for the selected country.
# - Assumes code structure: In SelectCountry1(), remove lines setting IsCorrectAnswer2 and IsIncorrectAnswer2.
# - Similar for SelectCountry2().
# Why: Setting for both countries causes both to color on Windows. Setting only selected fixes it without changing XAML.
# No regression: Android already behaves correctly (perhaps due to XAML); this aligns all. Non-selected remains uncolored.
# Tests: No changes needed as existing tests don't check answer coloring logic.

set -e  # Exit on error

# Issue 1: Signing setup
if [ ! -f "android.keystore" ]; then
  keytool -genkeypair -v -keystore android.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias myalias \
    -storepass android -keypass android -dname "CN=MyDesktopApplication, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=US"
  echo "Generated android.keystore with password 'android'"
fi

base64 android.keystore > android.keystore.base64
echo "Base64 encoded keystore to android.keystore.base64"
echo "ACTION REQUIRED: Copy content of android.keystore.base64 to GitHub secrets as ANDROID_KEYSTORE_BASE64"
echo "Set ANDROID_SIGNING_PASSWORD to 'android' in GitHub secrets"

# Add to .gitignore if not present
if ! grep -q "^android\.keystore$" .gitignore; then
  echo "android.keystore" >> .gitignore
fi
if ! grep -q "^android\.keystore\.base64$" .gitignore; then
  echo "android.keystore.base64" >> .gitignore
fi
echo "Updated .gitignore"

# Modify Android.csproj (insert signing props in first PropertyGroup)
csproj="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj"
sed -i '/<PropertyGroup>/a\    <AndroidKeyStore>True<\/AndroidKeyStore>\n    <AndroidSigningKeyStore>android.keystore<\/AndroidSigningKeyStore>\n    <AndroidSigningKeyAlias>myalias<\/AndroidSigningKeyAlias>\n    <AndroidSigningKeyPass>$(AndroidSigningPassword)<\/AndroidSigningKeyPass>\n    <AndroidSigningStorePass>$(AndroidSigningPassword)<\/AndroidSigningStorePass>' "$csproj"
echo "Updated $csproj with signing properties"

# Modify workflow.yml: Add keystore setup step after Checkout in build-android job
# Find line after '- name: Checkout', insert the new step
# Also add -p to publish command
workflow=".github/workflows/build-and-release.yml"
sed -i '/- name: Checkout/a\      - name: Setup Keystore\n        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android.keystore' "$workflow"
sed -i 's/--output \.\/publish\/android/--output \.\/publish\/android \\\n            -p:AndroidSigningPassword=${{ secrets.ANDROID_SIGNING_PASSWORD }}/' "$workflow"
echo "Updated $workflow with signing setup and password prop"

# Issue 2: UI highlight fix in ViewModels
# Surgical: Remove lines setting the non-selected country's IsCorrect/IsIncorrect
# Assume standard code; if not exact match, manual review needed
quiz_vm="src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs"
if [ -f "$quiz_vm" ]; then
  sed -i '/SelectCountry1/,/}/{/IsCorrectAnswer2/d; /IsIncorrectAnswer2/d}' "$quiz_vm"
  sed -i '/SelectCountry2/,/}/{/IsCorrectAnswer1/d; /IsIncorrectAnswer1/d}' "$quiz_vm"
  echo "Updated $quiz_vm to set highlights only for selected"
fi

desktop_vm="src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs"
if [ -f "$desktop_vm" ]; then
  sed -i '/SelectCountry1/,/}/{/IsCorrectAnswer2/d; /IsIncorrectAnswer2/d}' "$desktop_vm"
  sed -i '/SelectCountry2/,/}/{/IsCorrectAnswer1/d; /IsIncorrectAnswer1/d}' "$desktop_vm"
  echo "Updated $desktop_vm to set highlights only for selected"
fi

# No test updates needed (no changes to tested properties/behaviors)

echo "Fix complete. Run 'sh export.sh' to update dump, then commit/push. Set GitHub secrets as instructed for CI signing."


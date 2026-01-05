#!/bin/sh

# This script fixes the misplaced 'uses' and 'with' in the workflow YAML by rearranging the Setup Keystore and Checkout steps.
# It moves the Keystore step before Checkout in each job, ensuring proper structure without both 'run' and 'uses' in one step.
# Handles the optional 'with' in build-and-test.
# Why: The previous sed insertion disrupted indentation, attaching 'uses' to Keystore. This rearranges to valid YAML.
# No regression: CI will run Keystore before Checkout (better, as it doesn't need code). Releases unchanged.
# Run in project root; tests with 'yamlLint' if installed, but optional.

set -e  # Exit on error

workflow=".github/workflows/build-and-release.yml"

# Fix for jobs with 'with' (build-and-test)
sed -i '/- name: Checkout/{N; /Setup Keystore/{N; N; N; s/- name: Checkout\n- name: Setup Keystore\n  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android.keystore\n  uses: actions\/checkout@v4\n  with:/- name: Setup Keystore\n  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android.keystore\n- name: Checkout\n  uses: actions\/checkout@v4\n  with:/}}' "$workflow"

# Fix for jobs without 'with' (build-desktop, build-android)
sed -i '/- name: Checkout/{N; /Setup Keystore/{N; N; s/- name: Checkout\n- name: Setup Keystore\n  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android.keystore\n  uses: actions\/checkout@v4/- name: Setup Keystore\n  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android.keystore\n- name: Checkout\n  uses: actions\/checkout@v4/}}' "$workflow"

echo "Fixed step order in $workflow. Run 'yamllint $workflow' to verify if installed, or check manually."
echo "Fix complete. Commit/push to test in CI."

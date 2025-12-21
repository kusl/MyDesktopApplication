#!/bin/bash
# Build desktop projects only (excludes Android to avoid aapt2 hanging)
set -e
echo "Building desktop projects..."
dotnet build MyDesktopApplication.Desktop.slnx
echo "✓ Desktop build complete"

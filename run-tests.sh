#!/bin/bash
# Run all tests (uses desktop solution)
set -e
echo "Running tests..."
dotnet test MyDesktopApplication.Desktop.slnx

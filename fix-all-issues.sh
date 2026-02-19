#!/usr/bin/env bash
set -euo pipefail

cd ~/src/dotnet/MyDesktopApplication

VM_FILE="src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs"
QT_FILE="src/MyDesktopApplication.Core/Entities/QuestionType.cs"

# =============================================================================
# FIX 1: CS0266 on line 116
#
# GameState.SelectedQuestionType is QuestionType? (not int).
# The code does: _gameState.SelectedQuestionType = (int)value;
# That casts QuestionType to int, then tries to assign int to QuestionType?
# → CS0266: Cannot implicitly convert int to QuestionType?
#
# Fix: just assign directly: _gameState.SelectedQuestionType = value;
# =============================================================================
echo "[1/2] Fixing CS0266: removing incorrect (int) cast..."
echo "  Before:"
grep -n '(int)value' "$VM_FILE" || echo "  (pattern not found - checking alternate forms)"
grep -n 'SelectedQuestionType' "$VM_FILE"

sed -i 's/_gameState\.SelectedQuestionType = (int)value;/_gameState.SelectedQuestionType = value;/' "$VM_FILE"

echo "  After:"
grep -n 'SelectedQuestionType' "$VM_FILE"
echo ""

# =============================================================================
# FIX 2: FormatLargeNumber thousands: N1 → N2
#
# Test expects "500.00K" but code produces "500.0K" (uses N1 for thousands).
# Previous sed failed to match - using simpler pattern this time.
# =============================================================================
echo "[2/2] Fixing FormatLargeNumber thousands precision..."
echo "  Before:"
grep -n ':N1' "$QT_FILE"

# Target: the line with 1_000 and N1 and K
sed -i '/1_000/s/:N1}K/:N2}K/' "$QT_FILE"

echo "  After:"
grep -n ':N[0-9]}K' "$QT_FILE"
echo ""

# =============================================================================
# Build + Test
# =============================================================================
echo "=== Building ==="
time dotnet build

echo ""
echo "=== Running tests ==="
time dotnet test

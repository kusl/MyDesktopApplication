#!/usr/bin/env bash
set -euo pipefail

cd ~/src/dotnet/MyDesktopApplication

VM_FILE="src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs"
QT_FILE="src/MyDesktopApplication.Core/Entities/QuestionType.cs"
TEST_FILE="tests/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs"

echo "=== DIAGNOSTIC: What's actually on/around line 116? ==="
echo "--- Line 114-118 of $VM_FILE ---"
sed -n '114,118p' "$VM_FILE"
echo ""
echo "--- All reads of _gameState.SelectedQuestionType (right-hand side) ---"
grep -n '_gameState\.SelectedQuestionType' "$VM_FILE" | grep -v '_gameState\.SelectedQuestionType ='
echo ""
echo "--- All occurrences of _gameState.SelectedQuestionType ---"
grep -n '_gameState\.SelectedQuestionType' "$VM_FILE"
echo ""

# =============================================================================
# FIX 1: CS0266 - int to QuestionType? cast
# The issue is any place where _gameState.SelectedQuestionType (int) is used
# where QuestionType or QuestionType? is expected.
# We cast every READ of _gameState.SelectedQuestionType to (QuestionType).
# We must NOT touch the WRITE side: _gameState.SelectedQuestionType = (int)value;
# Strategy: replace pattern where _gameState.SelectedQuestionType is NOT 
# immediately followed by ' =' (assignment target).
# =============================================================================
echo "[1/2] Fixing int→QuestionType cast on line 116..."

# Use perl for negative lookahead - only cast when NOT followed by ' ='
perl -i -pe 's/(?<!\(int\))_gameState\.SelectedQuestionType(?!\s*=)/(QuestionType)_gameState.SelectedQuestionType/g' "$VM_FILE"

echo "  Verifying fix..."
echo "--- Line 114-118 after fix ---"
sed -n '114,118p' "$VM_FILE"
echo ""

# =============================================================================
# FIX 2: FormatLargeNumber uses N1 for thousands but test expects N2 ("500.00K")
# The implementation has: >= 1_000 => $"{value / 1_000:N1}K"
# The test expects: "500.00K" (2 decimal places)
# Fix: Change N1 to N2 for thousands to match the test expectation and be
# consistent with millions (N2), billions (N3), trillions (N3).
# =============================================================================
echo "[2/2] Fixing FormatLargeNumber thousands precision (N1 → N2)..."

sed -i 's|>= 1_000 => \$"{value / 1_000:N1}K"|>= 1_000 => $"{value / 1_000:N2}K"|' "$QT_FILE"

echo "  Verifying fix..."
grep -n 'N[0-9]}K' "$QT_FILE"
echo ""

# =============================================================================
# Build + Test
# =============================================================================
echo "=== Building ==="
time dotnet build

echo ""
echo "=== Running tests ==="
time dotnet test

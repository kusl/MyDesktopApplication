#!/usr/bin/env bash
set -euo pipefail

cd ~/src/dotnet/MyDesktopApplication

# =============================================================================
# FIX 1: QuestionTypeTests.cs - enum member names don't match Country properties
#   QuestionType enum:  Gdp, Density, Literacy
#   Country entity:     GdpTotal, PopulationDensity, LiteracyRate
#   Tests wrongly use:  QuestionType.GdpTotal, QuestionType.PopulationDensity, QuestionType.LiteracyRate
# =============================================================================
echo "[1/2] Fixing QuestionTypeTests.cs enum references..."

sed -i \
  -e 's/QuestionType\.GdpTotal/QuestionType.Gdp/g' \
  -e 's/QuestionType\.PopulationDensity/QuestionType.Density/g' \
  -e 's/QuestionType\.LiteracyRate/QuestionType.Literacy/g' \
  tests/MyDesktopApplication.Core.Tests/QuestionTypeTests.cs

echo "  Fixed 3 enum references: GdpTotal→Gdp, PopulationDensity→Density, LiteracyRate→Literacy"

# =============================================================================
# FIX 2: CountryQuizViewModel.cs:116 - int to QuestionType? needs explicit cast
#   _gameState.SelectedQuestionType is int
#   Target is QuestionType? — requires (QuestionType) cast
# =============================================================================
echo "[2/2] Fixing CountryQuizViewModel.cs int→QuestionType cast..."

sed -i 's/= _gameState\.SelectedQuestionType;/= (QuestionType)_gameState.SelectedQuestionType;/' \
  src/MyDesktopApplication.Shared/ViewModels/CountryQuizViewModel.cs

echo "  Added explicit (QuestionType) cast"

# =============================================================================
# Verify
# =============================================================================
echo ""
echo "Building and testing..."
time dotnet build
echo ""
time dotnet test

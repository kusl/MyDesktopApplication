#!/bin/bash
set -e

# =============================================================================
# fix-updateasync-error.sh
# =============================================================================
# This script:
# 1. RESTORES MainWindowViewModel.cs from git (since it was accidentally overwritten)
# 2. Applies a SURGICAL fix to IGameStateRepository.cs to add inheritance
#
# The previous script accidentally overwrote MainWindowViewModel.cs, causing
# 28 AXAML binding errors. This script fixes that.
# =============================================================================

echo "=============================================="
echo "  Fixing UpdateAsync Error (Properly)"
echo "=============================================="

cd ~/src/dotnet/MyDesktopApplication

# -----------------------------------------------------------------------------
# STEP 1: Restore MainWindowViewModel.cs from git
# -----------------------------------------------------------------------------
echo "[1/4] Restoring MainWindowViewModel.cs from git..."

if git checkout HEAD -- src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs 2>/dev/null; then
    echo "  ✓ MainWindowViewModel.cs restored from git"
else
    echo "  ⚠ Could not restore from git - file may not have been in git yet"
    echo "  Checking if backup exists..."
    
    # If git restore failed, the file might be new or there might be a backup
    if [ -f src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs.bak ]; then
        cp src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs.bak \
           src/MyDesktopApplication.Desktop/ViewModels/MainWindowViewModel.cs
        echo "  ✓ Restored from backup"
    fi
fi

# -----------------------------------------------------------------------------
# STEP 2: Apply SURGICAL fix to IGameStateRepository.cs
# Only add inheritance, don't rewrite the whole file
# -----------------------------------------------------------------------------
echo "[2/4] Fixing IGameStateRepository.cs..."

INTERFACE_FILE="src/MyDesktopApplication.Core/Interfaces/IGameStateRepository.cs"

# Check if the interface already inherits from IRepository<GameState>
if grep -q ": IRepository<GameState>" "$INTERFACE_FILE" 2>/dev/null; then
    echo "  ✓ Interface already inherits from IRepository<GameState>"
else
    echo "  Adding inheritance from IRepository<GameState>..."
    
    # Use sed to add the inheritance
    # Match: "public interface IGameStateRepository" (with no inheritance)
    # Replace with: "public interface IGameStateRepository : IRepository<GameState>"
    sed -i 's/public interface IGameStateRepository[[:space:]]*$/public interface IGameStateRepository : IRepository<GameState>/g' "$INTERFACE_FILE"
    
    # Also handle case where there's a brace on the same line
    sed -i 's/public interface IGameStateRepository[[:space:]]*{/public interface IGameStateRepository : IRepository<GameState>\n{/g' "$INTERFACE_FILE"
    
    echo "  ✓ Added inheritance"
fi

# Verify the change
echo ""
echo "  Current interface declaration:"
grep "public interface IGameStateRepository" "$INTERFACE_FILE" | head -1

# -----------------------------------------------------------------------------
# STEP 3: Ensure GameStateRepository extends Repository<GameState>
# -----------------------------------------------------------------------------
echo ""
echo "[3/4] Verifying GameStateRepository implementation..."

REPO_FILE="src/MyDesktopApplication.Infrastructure/Repositories/GameStateRepository.cs"

if grep -q "Repository<GameState>" "$REPO_FILE" 2>/dev/null; then
    echo "  ✓ GameStateRepository already extends Repository<GameState>"
else
    echo "  ⚠ GameStateRepository may need to extend Repository<GameState>"
    echo "  Checking current class declaration..."
    grep "class GameStateRepository" "$REPO_FILE" | head -1
fi

# -----------------------------------------------------------------------------
# STEP 4: Clean and rebuild
# -----------------------------------------------------------------------------
echo ""
echo "[4/4] Rebuilding..."

# Clean obj directories
rm -rf src/MyDesktopApplication.Core/obj
rm -rf src/MyDesktopApplication.Infrastructure/obj  
rm -rf src/MyDesktopApplication.Desktop/obj

echo "Restoring packages..."
dotnet restore --verbosity minimal

echo ""
echo "Building solution..."
if dotnet build --no-restore --verbosity minimal; then
    echo ""
    echo "=============================================="
    echo "  ✓ Build Successful!"
    echo "=============================================="
else
    echo ""
    echo "=============================================="
    echo "  ✗ Build Failed - see errors above"
    echo "=============================================="
    echo ""
    echo "If you still see AXAML binding errors, you may need to"
    echo "restore MainWindowViewModel.cs manually from a backup or"
    echo "revert your last git commit."
    exit 1
fi

#!/bin/bash
set -e

# Robust EF Core migration script
# Usage: ./add-migration.sh <MigrationName>

MIGRATION_NAME="$1"
INFRASTRUCTURE_PROJECT="src/MyDesktopApplication.Infrastructure"
STARTUP_PROJECT="src/MyDesktopApplication.Desktop"
CONTEXT_FILE="$INFRASTRUCTURE_PROJECT/Data/AppDbContext.cs"
MIGRATIONS_DIR="Data/Migrations"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  EF Core Migration Tool"
echo "=============================================="

# Validate migration name
if [ -z "$MIGRATION_NAME" ]; then
    echo -e "${RED}Error: Migration name required${NC}"
    echo ""
    echo "Usage: ./add-migration.sh <MigrationName>"
    echo "Example: ./add-migration.sh AddPriorityToTodoItem"
    exit 1
fi

# Validate migration name format (PascalCase, no spaces)
if [[ ! "$MIGRATION_NAME" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
    echo -e "${YELLOW}Warning: Migration name should be PascalCase (e.g., InitialCreate)${NC}"
fi

# Step 1: Validate AppDbContext exists
echo ""
echo "Step 1: Validating AppDbContext..."
if [ ! -f "$CONTEXT_FILE" ]; then
    echo -e "${RED}Error: AppDbContext not found at $CONTEXT_FILE${NC}"
    echo ""
    echo "Expected location: $CONTEXT_FILE"
    echo "Please ensure the Infrastructure project has a Data/AppDbContext.cs file"
    exit 1
fi

# Check if AppDbContext class is defined
if ! grep -q "class AppDbContext" "$CONTEXT_FILE"; then
    echo -e "${RED}Error: AppDbContext class not found in $CONTEXT_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AppDbContext found${NC}"

# Step 2: Validate startup project
echo ""
echo "Step 2: Validating startup project..."
if [ ! -f "$STARTUP_PROJECT/MyDesktopApplication.Desktop.csproj" ]; then
    echo -e "${RED}Error: Startup project not found at $STARTUP_PROJECT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Startup project found${NC}"

# Step 3: Check for EF tools
echo ""
echo "Step 3: Checking EF Core tools..."
if ! command -v dotnet-ef &> /dev/null && ! dotnet tool list -g | grep -q "dotnet-ef"; then
    echo -e "${YELLOW}Installing dotnet-ef tool...${NC}"
    dotnet tool install --global dotnet-ef
fi
echo -e "${GREEN}✓ EF Core tools available${NC}"

# Step 4: Kill any stuck processes
echo ""
echo "Step 4: Cleaning up stuck processes..."
pkill -f aapt2 2>/dev/null || true
pkill -f VBCSCompiler 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
echo -e "${GREEN}✓ Processes cleaned${NC}"

# Step 5: Build the projects first (excluding Android to avoid hangs)
echo ""
echo "Step 5: Building projects..."
dotnet build "$INFRASTRUCTURE_PROJECT" --no-restore -v q 2>/dev/null || \
    dotnet build "$INFRASTRUCTURE_PROJECT" -v q
dotnet build "$STARTUP_PROJECT" --no-restore -v q 2>/dev/null || \
    dotnet build "$STARTUP_PROJECT" -v q
echo -e "${GREEN}✓ Projects built${NC}"

# Step 6: Create the migration
echo ""
echo "Step 6: Creating migration '$MIGRATION_NAME'..."
dotnet ef migrations add "$MIGRATION_NAME" \
    --project "$INFRASTRUCTURE_PROJECT" \
    --startup-project "$STARTUP_PROJECT" \
    --output-dir "$MIGRATIONS_DIR" \
    --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Migration '$MIGRATION_NAME' created successfully!${NC}"
    
    # Step 7: Apply the migration
    echo ""
    echo "Step 7: Applying migration to database..."
    dotnet ef database update \
        --project "$INFRASTRUCTURE_PROJECT" \
        --startup-project "$STARTUP_PROJECT"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Database updated successfully!${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Migration created but database update failed${NC}"
        echo "You can manually apply with:"
        echo "  dotnet ef database update --project $INFRASTRUCTURE_PROJECT --startup-project $STARTUP_PROJECT"
    fi
else
    echo ""
    echo -e "${RED}✗ Migration creation failed${NC}"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Migration Complete!"
echo "=============================================="
echo ""
echo "Migration files created in: $INFRASTRUCTURE_PROJECT/$MIGRATIONS_DIR/"
echo ""

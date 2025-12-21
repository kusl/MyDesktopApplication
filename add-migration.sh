#!/bin/bash
# Add a new EF Core migration
# Usage: ./add-migration.sh MigrationName

if [ -z "$1" ]; then
    echo "Usage: ./add-migration.sh <MigrationName>"
    echo "Example: ./add-migration.sh AddPriorityToTodoItem"
    exit 1
fi

MIGRATION_NAME="$1"

echo "Adding migration: $MIGRATION_NAME"
dotnet ef migrations add "$MIGRATION_NAME" \
    --project src/MyDesktopApplication.Infrastructure \
    --startup-project src/MyDesktopApplication.Desktop \
    --output-dir Data/Migrations

echo "✓ Migration created"
echo ""
echo "To apply the migration, run:"
echo "  dotnet ef database update --project src/MyDesktopApplication.Infrastructure --startup-project src/MyDesktopApplication.Desktop"

#!/bin/bash
set -e

# =============================================================================
# migrate.sh - Entity Framework Core Migration Helper
# =============================================================================
# Usage:
#   ./migrate.sh add <MigrationName>  - Add a new migration
#   ./migrate.sh update               - Apply pending migrations
#   ./migrate.sh remove               - Remove last migration
#   ./migrate.sh list                 - List all migrations
#   ./migrate.sh script               - Generate SQL script
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

INFRASTRUCTURE_PROJECT="src/MyDesktopApplication.Infrastructure"
STARTUP_PROJECT="src/MyDesktopApplication.Desktop"
MIGRATIONS_DIR="Data/Migrations"

# Ensure dotnet-ef is installed
if ! command -v dotnet-ef &> /dev/null; then
    echo "Installing dotnet-ef tool..."
    dotnet tool install --global dotnet-ef
fi

case "$1" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: ./migrate.sh add <MigrationName>"
            exit 1
        fi
        echo "Adding migration: $2"
        dotnet ef migrations add "$2" \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --output-dir "$MIGRATIONS_DIR"
        echo "✓ Migration '$2' created"
        ;;
    update)
        echo "Applying pending migrations..."
        dotnet ef database update \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        echo "✓ Database updated"
        ;;
    remove)
        echo "Removing last migration..."
        dotnet ef migrations remove \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        echo "✓ Last migration removed"
        ;;
    list)
        echo "Listing migrations..."
        dotnet ef migrations list \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        ;;
    script)
        echo "Generating SQL script..."
        dotnet ef migrations script \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --output "migrations.sql"
        echo "✓ SQL script saved to migrations.sql"
        ;;
    *)
        echo "Usage: ./migrate.sh <command>"
        echo ""
        echo "Commands:"
        echo "  add <name>  - Add a new migration"
        echo "  update      - Apply pending migrations"
        echo "  remove      - Remove last migration"
        echo "  list        - List all migrations"
        echo "  script      - Generate SQL script"
        ;;
esac

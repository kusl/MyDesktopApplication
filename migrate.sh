#!/bin/bash
set -e

# =============================================================================
#  Database Migration Script
# =============================================================================
#
#  Usage:
#    ./migrate.sh <MigrationName>           # Add migration and apply
#    ./migrate.sh <MigrationName> --add     # Add migration only
#    ./migrate.sh --apply                   # Apply pending migrations
#    ./migrate.sh --status                  # Show migration status
#    ./migrate.sh --rollback                # Rollback last migration
#
# =============================================================================

INFRASTRUCTURE_PROJECT="src/MyDesktopApplication.Infrastructure"
STARTUP_PROJECT="src/MyDesktopApplication.Desktop"
MIGRATIONS_DIR="Data/Migrations"

show_usage() {
    echo "Usage: $0 <MigrationName> [options]"
    echo ""
    echo "Options:"
    echo "  --add        Add migration only (don't apply)"
    echo "  --apply      Apply pending migrations"
    echo "  --status     Show migration status"
    echo "  --rollback   Rollback last migration"
    echo ""
    echo "Examples:"
    echo "  $0 InitialCreate           # Add and apply 'InitialCreate' migration"
    echo "  $0 AddUserTable --add      # Add 'AddUserTable' migration only"
    echo "  $0 --apply                 # Apply all pending migrations"
}

# Check if EF tools are installed
if ! dotnet ef --version &>/dev/null; then
    echo "Installing Entity Framework Core tools..."
    dotnet tool install --global dotnet-ef
fi

case "${1:-}" in
    --apply)
        echo "Applying pending migrations..."
        dotnet ef database update \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        echo "✓ Migrations applied"
        ;;
    --status)
        echo "Migration status:"
        dotnet ef migrations list \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        ;;
    --rollback)
        echo "Rolling back last migration..."
        # Get the previous migration
        PREV=$(dotnet ef migrations list \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --no-connect 2>/dev/null | tail -2 | head -1 | xargs)
        if [ -n "$PREV" ] && [ "$PREV" != "(No migrations)" ]; then
            dotnet ef database update "$PREV" \
                --project "$INFRASTRUCTURE_PROJECT" \
                --startup-project "$STARTUP_PROJECT"
            echo "✓ Rolled back to: $PREV"
        else
            echo "No migrations to rollback"
        fi
        ;;
    --help|-h)
        show_usage
        ;;
    "")
        show_usage
        exit 1
        ;;
    *)
        MIGRATION_NAME="$1"
        ADD_ONLY=false
        
        if [ "${2:-}" == "--add" ]; then
            ADD_ONLY=true
        fi
        
        echo "Adding migration: $MIGRATION_NAME"
        dotnet ef migrations add "$MIGRATION_NAME" \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --output-dir "$MIGRATIONS_DIR"
        echo "✓ Migration added: $MIGRATION_NAME"
        
        if [ "$ADD_ONLY" = false ]; then
            echo "Applying migration to SQLite database..."
            dotnet ef database update \
                --project "$INFRASTRUCTURE_PROJECT" \
                --startup-project "$STARTUP_PROJECT"
            echo "✓ Migration applied"
        fi
        ;;
esac

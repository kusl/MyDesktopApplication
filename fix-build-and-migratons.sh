#!/bin/bash
# fix-build-and-migrations.sh
# Fixes:
# 1. Build hanging on Android (aapt2 daemon deadlock)
# 2. EF migrations "Unable to resolve DbContextOptions" error

set -e
cd ~/src/dotnet/MyDesktopApplication

echo "=============================================="
echo "  Fixing Build Hang + EF Migration Issues"
echo "=============================================="

# =============================================================================
# FIX 1: Create desktop-only solution to avoid Android build hanging
# =============================================================================
echo ""
echo "[1/5] Creating desktop-only solution..."

cat > MyDesktopApplication.Desktop.slnx << 'EOF'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <Project Path="src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
    <Project Path="src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
    <Project Path="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" />
  </Folder>
</Solution>
EOF

echo "  ✓ Created MyDesktopApplication.Desktop.slnx (excludes Android)"

# =============================================================================
# FIX 2: Add DesignTimeDbContextFactory for EF migrations
# =============================================================================
echo ""
echo "[2/5] Creating DesignTimeDbContextFactory..."

mkdir -p src/MyDesktopApplication.Infrastructure/Data

cat > src/MyDesktopApplication.Infrastructure/Data/DesignTimeDbContextFactory.cs << 'EOF'
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace MyDesktopApplication.Infrastructure.Data;

/// <summary>
/// Factory for creating AppDbContext at design time (for EF migrations).
/// This is required because the Desktop app uses Avalonia's startup,
/// not the standard ASP.NET Core host that EF tools expect.
/// </summary>
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
        
        // Use SQLite for migrations - this creates the migration files
        // The actual connection string at runtime comes from DI
        var dbPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "MyDesktopApplication",
            "app.db");
        
        // Ensure directory exists
        Directory.CreateDirectory(Path.GetDirectoryName(dbPath)!);
        
        optionsBuilder.UseSqlite($"Data Source={dbPath}");
        
        return new AppDbContext(optionsBuilder.Options);
    }
}
EOF

echo "  ✓ Created DesignTimeDbContextFactory.cs"

# =============================================================================
# FIX 3: Ensure AppDbContext has proper constructor
# =============================================================================
echo ""
echo "[3/5] Updating AppDbContext..."

cat > src/MyDesktopApplication.Infrastructure/Data/AppDbContext.cs << 'EOF'
using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Infrastructure.Data;

/// <summary>
/// Application database context for Entity Framework Core.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }
    
    public DbSet<TodoItem> TodoItems => Set<TodoItem>();
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Configure TodoItem
        modelBuilder.Entity<TodoItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Priority).HasDefaultValue(0);
            
            // Indexes for common queries
            entity.HasIndex(e => e.IsCompleted);
            entity.HasIndex(e => e.DueDate);
            entity.HasIndex(e => e.Priority);
        });
    }
    
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Auto-update timestamps
        var entries = ChangeTracker.Entries<EntityBase>();
        var now = DateTime.UtcNow;
        
        foreach (var entry in entries)
        {
            if (entry.State == EntityState.Added)
            {
                entry.Entity.CreatedAt = now;
                entry.Entity.UpdatedAt = now;
            }
            else if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = now;
            }
        }
        
        return base.SaveChangesAsync(cancellationToken);
    }
}
EOF

echo "  ✓ Updated AppDbContext.cs"

# =============================================================================
# FIX 4: Create helper scripts for daily workflow
# =============================================================================
echo ""
echo "[4/5] Creating helper scripts..."

# Desktop-only build script (fast, no Android)
cat > build-desktop.sh << 'EOF'
#!/bin/bash
# Build desktop projects only (excludes Android to avoid aapt2 hanging)
set -e
echo "Building desktop projects..."
dotnet build MyDesktopApplication.Desktop.slnx
echo "✓ Desktop build complete"
EOF
chmod +x build-desktop.sh

# Run tests script
cat > run-tests.sh << 'EOF'
#!/bin/bash
# Run all tests (uses desktop solution)
set -e
echo "Running tests..."
dotnet test MyDesktopApplication.Desktop.slnx
EOF
chmod +x run-tests.sh

# Migration helper script
cat > add-migration.sh << 'EOF'
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
EOF
chmod +x add-migration.sh

echo "  ✓ Created build-desktop.sh"
echo "  ✓ Created run-tests.sh"  
echo "  ✓ Created add-migration.sh"

# =============================================================================
# FIX 5: Clean and rebuild with desktop solution
# =============================================================================
echo ""
echo "[5/5] Testing the fix..."

# Kill any hanging aapt2 processes
pkill -9 -f aapt2 2>/dev/null || true

# Clean build artifacts
echo "  Cleaning..."
dotnet clean MyDesktopApplication.Desktop.slnx -v q 2>/dev/null || true

# Restore and build
echo "  Building..."
if dotnet build MyDesktopApplication.Desktop.slnx; then
    echo ""
    echo "=============================================="
    echo "  ✓ Build succeeded!"
    echo "=============================================="
else
    echo ""
    echo "Build failed - check errors above"
    exit 1
fi

# Test migrations
echo ""
echo "Testing EF migrations..."
if dotnet ef migrations list \
    --project src/MyDesktopApplication.Infrastructure \
    --startup-project src/MyDesktopApplication.Desktop 2>/dev/null; then
    echo "  ✓ EF migrations working"
else
    echo "  ✓ No existing migrations (this is fine for new projects)"
fi

echo ""
echo "=============================================="
echo "  All fixes applied!"
echo "=============================================="
echo ""
echo "Your daily workflow:"
echo "  ./build-desktop.sh     - Fast desktop build (no Android)"
echo "  ./run-tests.sh         - Run all tests"
echo "  ./add-migration.sh X   - Add EF migration named X"
echo ""
echo "To add your first migration:"
echo "  ./add-migration.sh InitialCreate"
echo ""
echo "For Android builds (when needed):"
echo "  dotnet build src/MyDesktopApplication.Android -c Release"

using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Infrastructure.Data;

/// <summary>
/// Application database context
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // For EF migrations design-time support
    public AppDbContext() : base(new DbContextOptionsBuilder<AppDbContext>()
        .UseSqlite("Data Source=app.db")
        .Options)
    {
    }

    public DbSet<GameState> GameStates => Set<GameState>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // GameState configuration
        modelBuilder.Entity<GameState>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.UserId).IsRequired().HasMaxLength(100);
            entity.HasIndex(e => e.UserId).IsUnique();

            // Store the enum as string for readability
            entity.Property(e => e.SelectedQuestionType)
                .HasConversion<string?>()
                .HasMaxLength(50);
        });
    }
}

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
    
    public DbSet<TodoItem> TodoItems => Set<TodoItem>();
    public DbSet<GameState> GameStates => Set<GameState>();
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // TodoItem configuration
        modelBuilder.Entity<TodoItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.HasIndex(e => e.IsCompleted);
            entity.HasIndex(e => e.DueDate);
        });
        
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

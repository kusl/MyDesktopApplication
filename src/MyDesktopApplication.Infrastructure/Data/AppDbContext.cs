using Microsoft.EntityFrameworkCore;
using MyDesktopApplication.Core.Entities;

namespace MyDesktopApplication.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    
    public DbSet<GameState> GameStates => Set<GameState>();
    public DbSet<TodoItem> TodoItems => Set<TodoItem>();
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        modelBuilder.Entity<GameState>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SelectedQuestionType)
                  .HasMaxLength(50)
                  .HasDefaultValue("Population");
        });
        
        modelBuilder.Entity<TodoItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(1000);
        });
    }
}

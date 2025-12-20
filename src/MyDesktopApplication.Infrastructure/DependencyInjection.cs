using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Core.Interfaces;
using MyDesktopApplication.Infrastructure.Data;
using MyDesktopApplication.Infrastructure.Repositories;

namespace MyDesktopApplication.Infrastructure;

/// <summary>
/// Dependency injection extensions for Infrastructure layer
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services, 
        string? connectionString = null)
    {
        // Use SQLite by default with a local file
        var dbPath = connectionString ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "MyDesktopApplication", "app.db");
        
        Directory.CreateDirectory(Path.GetDirectoryName(dbPath)!);

        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlite($"Data Source={dbPath}"));

        services.AddScoped<ITodoRepository, TodoRepository>();
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

        return services;
    }
}

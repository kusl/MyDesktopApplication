using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MyDesktopApplication.Core.Interfaces;
using OpenTelemetry;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace MyDesktopApplication.Infrastructure.Observability;

public static class ObservabilityExtensions
{
    public static IServiceCollection AddObservability(this IServiceCollection services)
    {
        services.AddSingleton<IGameTelemetry, GameTelemetry>();

        services.AddLogging(logging =>
        {
            logging.AddOpenTelemetry(options =>
            {
                options.SetResourceBuilder(BuildResource());
                options.IncludeScopes = true;
                options.IncludeFormattedMessage = true;
                options.AddConsoleExporter();
            });
        });

        services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService(AppTelemetry.ServiceName, serviceVersion: AppTelemetry.ServiceVersion))
            .WithTracing(tracing => tracing
                .AddSource(AppTelemetry.ServiceName)
                .AddConsoleExporter())
            .WithMetrics(metrics => metrics
                .AddMeter(AppTelemetry.ServiceName)
                .AddConsoleExporter());

        return services;
    }

    public static void StartObservability(this IServiceProvider services)
    {
        _ = services.GetService<TracerProvider>();
        _ = services.GetService<MeterProvider>();
        _ = services.GetService<ILoggerFactory>();
    }

    private static ResourceBuilder BuildResource() => ResourceBuilder.CreateDefault()
        .AddService(AppTelemetry.ServiceName, serviceVersion: AppTelemetry.ServiceVersion);
}

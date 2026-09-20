using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Reflection;

namespace MyDesktopApplication.Infrastructure.Observability;

public static class AppTelemetry
{
    public const string ServiceName = "MyDesktopApplication";

    public static string ServiceVersion { get; } =
        typeof(AppTelemetry).Assembly.GetName().Version?.ToString() ?? "0.0.0";

    public static readonly ActivitySource ActivitySource = new(ServiceName, ServiceVersion);

    public static readonly Meter Meter = new(ServiceName, ServiceVersion);
}

using Microsoft.Extensions.DependencyInjection;
using MyDesktopApplication.Shared.ViewModels;

namespace MyDesktopApplication.Shared;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCountryQuizApp(this IServiceCollection services)
    {
        services.AddTransient<CountryQuizViewModel>();
        return services;
    }
}

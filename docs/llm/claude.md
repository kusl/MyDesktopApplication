I am using an Acer Swift Go 14 with AMD Ryzen 8845HS processor running Fedora Linux. How do I get started writing an Avalonia UI application? 
here are my thoughts: 
I want to learn Avalonia UI to write high performance cross platform free of cost. 
I want to use the latest and greatest technology. 
I want this to serve as a sample as well as a starting point for native applications. 
It should be easy to use the latest dotnet technology 
such as slnx files, props files, and so on. 
Where possible, we should use long term sustainable technology such as sqlite and postgresql. 
We should avoid any nuget package that requires payment of money, free of cost for non-commercial software is not enough. 
We ourselves should not charge any money, ever. 
We should have extensive logging, metrics, etc using open telemetry. 
Application should be built from the ground up to be testable.
All tests including Unit tests, integration tests should be automated and be performant so we can run them after every change. 
The whole thing should fit in a single git repository. 

```bash
kushal@fedora:~$ cd ~/src/dotnet/MyDesktopApplication/
kushal@fedora:~/src/dotnet/MyDesktopApplication$ dotnet --info
.NET SDK:
 Version:           10.0.100
 Commit:            b0f34d51fc
 Workload version:  10.0.100-manifests.4eab3e0f
 MSBuild version:   18.0.2+b0f34d51f

Runtime Environment:
 OS Name:     fedora
 OS Version:  43
 OS Platform: Linux
 RID:         fedora.43-x64
 Base Path:   /usr/lib64/dotnet/sdk/10.0.100/

.NET workloads installed:
There are no installed workloads to display.
Configured to use workload sets when installing new manifests.
No workload sets are installed. Run "dotnet workload restore" to install a workload set.

Host:
  Version:      10.0.0
  Architecture: x64
  Commit:       b0f34d51fc

.NET SDKs installed:
  10.0.100 [/usr/lib64/dotnet/sdk]

.NET runtimes installed:
  Microsoft.AspNetCore.App 10.0.0 [/usr/lib64/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 10.0.0 [/usr/lib64/dotnet/shared/Microsoft.NETCore.App]

Other architectures found:
  None

Environment variables:
  DOTNET_BUNDLE_EXTRACT_BASE_DIR           [/home/kushal/.cache/dotnet_bundle_extract]
  DOTNET_ROOT                              [/usr/lib64/dotnet]

global.json file:
  Not found

Learn more:
  https://aka.ms/dotnet/info

Download .NET:
  https://aka.ms/dotnet/download
kushal@fedora:~/src/dotnet/MyDesktopApplication$ 
```





This is a great project! Let me help you set up a well-structured Avalonia UI application with modern .NET 10 practices. I'll create a complete solution structure that incorporates all your requirements.Now I have enough information. Let me create a comprehensive, well-structured Avalonia UI project for you that incorporates all your requirements.

<function_results>OK</function_results>Now let me create a comprehensive guide document that ties everything together:Here's a summary of everything I've created for your Avalonia UI project:

## Getting Started

**Step 1: Install Avalonia templates**
```bash
dotnet new install Avalonia.Templates
```

**Step 2: Run the setup script** (I've created it as the first artifact) to scaffold the entire project structure.

**Step 3: Copy the configuration files** I've provided to your project root:
- `Directory.Build.props` - shared build settings for all projects
- `Directory.Packages.props` - central package management (all versions in one file)
- `.gitignore`
- `appsettings.json`

**Step 4: Update individual `.csproj` files** with the templates I provided.

## What's Included

**Modern .NET 10 practices:**
- Starting in .NET 10, `dotnet new sln` creates a SLNX-format solution file by default - the new XML-based format that's cleaner and easier to merge
- Central Package Management via `Directory.Packages.props`
- Shared build properties via `Directory.Build.props`

**Observability with OpenTelemetry:**
- Logs, metrics, and distributed tracing are the three pillars of observability
- Console exporter for development, OTLP exporter for production backends (Jaeger, Grafana, etc.)
- Custom metrics and traces built into ViewModels

**Architecture:**
- Clean separation: Core (domain) → Infrastructure (data) → Desktop (UI)
- Repository pattern with Unit of Work
- MVVM with CommunityToolkit.Mvvm source generators
- Dependency injection throughout

**Database options:**
- SQLite by default (zero configuration, embedded)
- PostgreSQL when you need more power
- Entity Framework Core with migrations support

**Testing:**
- Unit tests with xUnit + FluentAssertions + Bogus (fake data)
- Integration tests with in-memory SQLite (fast) or Testcontainers PostgreSQL (realistic)
- UI tests possible with Avalonia.Headless

**All packages are completely free** - MIT, Apache-2.0, or public domain licenses only.

For your Fedora setup with Rider, I'd recommend installing the **AvaloniaRider** plugin from the JetBrains plugin marketplace for XAML preview support.








Thank you. I ran into a problem when running the setup script. 
We might have to start over? 
I have added an export script and added the dump.txt of all the code we have so far in the project files in claude. 
Project `src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj` added to the solution.
Error: Invalid option(s):
-f net10.0
   'net10.0' is not a valid value for -f. The possible values are:
      net8.0   - Target net8.0
      net9.0   - Target net9.0

For more information, run:
   dotnet new avalonia.mvvm -h

For details on the exit code, refer to https://aka.ms/templating-exit-codes#127

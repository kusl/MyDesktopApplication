Manage project memory
Claude regenerates project memory every evening from your past chats in this project. Only you can see this memory, and it is not shared with other project users.

Purpose & context

Kushal is building a cross-platform application called Country Quiz (previously called MyDesktopApplication) — a country comparison quiz game built with Avalonia UI and .NET 10, targeting Desktop and Android from a single unified solution. The project doubles as a sample/reference application for modern, native cross-platform .NET development.

Core architectural values:

One Team One Build: Single .slnx solution file, no platform silos, no separate desktop/android builds — everyone builds everything; if it's slow, fix the root cause
FOSS-only: All NuGet packages must be MIT, Apache-2.0, BSD, or Public Domain licensed; no commercial licenses, no "free for non-commercial" — the app itself is always free
Clean Architecture: Core / Infrastructure / Shared / Platform projects
Testable from the ground up: Comprehensive unit and integration tests, automated CI
Stack: .NET 10, Avalonia UI, EF Core with SQLite/PostgreSQL (Npgsql), CommunityToolkit.Mvvm, Serilog, OpenTelemetry, xUnit, Shouldly (replaced FluentAssertions due to licensing), NSubstitute (replaced Moq), Bogus, Testcontainers, Central Package Management via Directory.Packages.props

Approved packages (notable replacements made):

Shouldly over FluentAssertions (BSD-3-Clause vs. commercial tier)
NSubstitute over Moq (SponsorLink concerns)
Avalonia.Themes.Fluent; Avalonia.Diagnostics dropped entirely (became commercial in Avalonia 12)
Distribution: Android APKs distributed via Obtainium from GitHub Releases; desktop binaries released for Windows/Linux/macOS (x64 + ARM64)

Current state

Avalonia 12.0.4 adopted; breaking changes addressed:
AvaloniaMainActivity is no longer generic
CustomizeAppBuilder moved out of MainActivity into a new AndroidApp.cs (inheriting AvaloniaAndroidApplication<App>)
App.axaml.cs updated to use IActivityApplicationLifetime / MainViewFactory pattern; database initialization moved out of the factory to avoid re-running on activity recreation
Directory.Packages.props fully updated with MSBuild version variables ($(AvaloniaVersion), $(EFCoreVersion), $(MicrosoftExtensionsVersion), $(OpenTelemetryVersion), $(SerilogVersion), $(TestcontainersVersion)) grouping related packages for easier future upgrades
Key current package versions: EF Core 10.0.8, Microsoft.Extensions 10.0.8, CommunityToolkit.Mvvm 8.4.2, Serilog 4.3.1, OpenTelemetry 1.15.0, Testcontainers 4.11.0, Npgsql 10.0.1, coverlet 10.0.1, test SDK 18.6.0
CI/CD: Unified build-and-release.yml GitHub Actions workflow; automatic versioning using github.run_number; Android signing conditional on AndroidSigningPassword being supplied (not hardcoded); keystore referenced via $GITHUB_WORKSPACE absolute path; Android workload installed before dotnet restore
Android build: AndroidUseAapt2Daemon=false / _Aapt2DaemonMaxInstanceCount=1 set to prevent aapt2 daemon hangs; AOT disabled, Mono interpreter enabled for runtime compatibility
On the horizon

Potential API integration for automatic country data updates (currently static CountryData.cs)
Continued refinement of Android UX (touch targets, layout for small phones through large tablets like Samsung Tab A9+)
Key learnings & principles

Never use sed or partial patches — Kushal copies files directly; always provide complete file replacements with full file paths
Search project knowledge before writing any fix — understand all types involved (properties, method signatures, interface constraints) across the entire codebase before returning corrected files
Fix ALL instances of a bug across every project — check Desktop, Shared, Android, Core, Infrastructure, and all test projects; don't fix only the first occurrence
Surgical over sweeping when fixing specific errors — rewriting unrelated files causes regressions (learned from MainWindowViewModel.cs overwrite that dropped XAML-bound properties)
Verify NuGet versions before writing them — query [PackageName] latest stable release NuGet rather than trusting dotnet list package --outdated alone; avoid version hallucination
Android signing must be conditional — unconditional AndroidKeyStore=True breaks the unified dotnet build for team members without credentials, violating One Team One Build
AppCompat theme required — Avalonia's AvaloniaActivity inherits from AppCompatActivity; Android styles.xml must use Theme.AppCompat.* not @android:style/Theme.Material.*
Cross-framework transitive dependencies don't flow — when Infrastructure targets net10.0 and Android targets net10.0-android, explicit PackageReference entries are needed in the Android project for packages that would otherwise be transitive
IDesignTimeDbContextFactory<AppDbContext> required for dotnet ef migrations add to work without a running host
Approach & patterns

File delivery: Always return complete files with full paths — no sed, no bash scripts, no partial patches
Build error workflow: (1) search project knowledge for actual file contents, (2) understand all involved types, (3) return the complete corrected file(s) across all affected projects
Package upgrades: Web-search each package for latest stable before writing versions; use MSBuild version variables to group related packages
Codebase exploration: When working from a dump.txt export, use grep -n to locate line ranges then view with explicit view_range as a reliable two-step extraction approach
Android build reliability: Kill stuck aapt2/VBCSCompiler processes and clean artifacts before builds when troubleshooting hangs
Versioning: github.run_number drives ApplicationVersion (versionCode) and ApplicationDisplayVersion (1.0.{run_number}) for incrementing Android updates via Obtainium
XAML coloring: Prefer pure converter-driven approach with MultiBinding for answer highlight states over CSS class-based coloring (avoids conflicts on desktop)
Tools & resources

Dev environment: Fedora Linux; Android SDK (official command-line tools, not Fedora's android-tools package); JDK 21 (Temurin)
Solution format: .slnx (modern single solution file), Directory.Packages.props with CentralPackageTransitivePinningEnabled
CI: GitHub Actions — actions/checkout@v6, actions/setup-dotnet@v5, actions/setup-java@v5 (Temurin distribution), actions/upload-artifact@v6, actions/download-artifact@v7
Export tooling: export.sh script generating a dump.txt monolithic codebase export (excludes docs/llm/ directory to keep output size manageable)
Android distribution: Obtainium pulling APKs from GitHub Releases

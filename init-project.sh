#!/bin/bash
set -e

# =============================================================================
#  MyDesktopApplication: Unified Project Initialization
# =============================================================================
#
#  This script consolidates the project into a unified, sustainable state:
#    - Single SLNX solution for all platforms
#    - Free/open-source packages only (MIT/Apache/BSD)
#    - Robust migration workflow
#    - Latest GitHub Actions versions
#    - Clean repository without redundant scripts
#
#  Philosophy: One Team, One Build
#    - No silos between Desktop and Android teams
#    - Everyone experiences the same build (even if slow)
#    - Issues get fixed collectively, not worked around
#
# =============================================================================

echo "=============================================="
echo "  MyDesktopApplication: Project Initialization"
echo "=============================================="
echo ""
echo "This script will:"
echo "  1. Kill stuck build processes (aapt2, VBCSCompiler)"
echo "  2. Remove redundant solution files and scripts"
echo "  3. Create unified MyDesktopApplication.slnx"
echo "  4. Update packages to free/open-source alternatives"
echo "  5. Fix all source code issues"
echo "  6. Update GitHub Actions to latest versions"
echo "  7. Create robust migration script"
echo "  8. Build and test everything"
echo ""

# -----------------------------------------------------------------------------
#  Step 1: Housekeeping - Kill Stuck Processes
# -----------------------------------------------------------------------------
echo "[Step 1/8] Killing stuck build processes..."

pkill -f aapt2 2>/dev/null || true
pkill -f VBCSCompiler 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true

echo "  ✓ Processes cleaned"

# -----------------------------------------------------------------------------
#  Step 2: Remove Silo Scripts and Redundant Files
# -----------------------------------------------------------------------------
echo "[Step 2/8] Removing redundant scripts and files..."

# Remove siloed solution
rm -f MyDesktopApplication.Desktop.slnx 2>/dev/null && echo "  Removed: MyDesktopApplication.Desktop.slnx"

# Remove all silo/fix/setup scripts (keeping only export.sh and this script)
SCRIPTS_TO_REMOVE=(
    "build-android.sh"
    "build-desktop.sh"
    "continue-setup.sh"
    "fix-all.sh"
    "fix-android-build.sh"
    "fix-android-code.sh"
    "fix-android-font.sh"
    "fix-android-namespace.sh"
    "fix-android-theme.sh"
    "fix-android-theme-crash.sh"
    "fix-avalonia-version.sh"
    "fix-build-errors.sh"
    "fix-ci-and-add-android.sh"
    "fix-cpm.sh"
    "fix-github-actions.sh"
    "fix-properly.sh"
    "fix-tests.sh"
    "run-tests.sh"
    "setup-all.sh"
    "setup-android-fedora.sh"
    "setup-github-actions.sh"
    "setup-project.sh"
    "setup.sh"
    "update-packages.sh"
    "update-github-actions.sh"
    "cleanup-project.sh"
    "cleanup-and-rebuild.sh"
    "cleanup-and-standardize.sh"
    "convert-to-country-quiz.sh"
)

for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "  Removed: $script"
    fi
done

# Remove duplicate root appsettings.json (Desktop has its own)
rm -f appsettings.json 2>/dev/null && echo "  Removed: root appsettings.json (duplicate)"

echo "  ✓ Cleanup complete (export.sh preserved)"

# -----------------------------------------------------------------------------
#  Step 3: Create Unified SLNX Solution
# -----------------------------------------------------------------------------
echo "[Step 3/8] Creating unified solution file..."

cat > MyDesktopApplication.slnx << 'SLNX_EOF'
<Solution>
  <!-- Source Projects -->
  <Folder Name="/src/">
    <Project Path="src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <Project Path="src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
    <Project Path="src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
    <Project Path="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
    <Project Path="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj" />
  </Folder>
  <!-- Test Projects -->
  <Folder Name="/tests/">
    <Project Path="tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" />
  </Folder>
</Solution>
SLNX_EOF

echo "  ✓ Created unified MyDesktopApplication.slnx with all 8 projects"

# -----------------------------------------------------------------------------
#  Step 4: Update Directory.Packages.props (Free/Open-Source Only)
# -----------------------------------------------------------------------------
echo "[Step 4/8] Updating packages to free/open-source alternatives..."

cat > Directory.Packages.props << 'PACKAGES_EOF'
<Project>
  <!--
    Central Package Management
    All packages are 100% free under permissive licenses (MIT/Apache/BSD)
    
    REMOVED (not free for commercial use):
      - FluentAssertions 8+ (commercial license for companies >$1M revenue)
      - Moq (SponsorLink controversy, telemetry concerns)
      
    REMOVED (deprecated):
      - Avalonia.ReactiveUI (deprecated, use CommunityToolkit.Mvvm instead)
  -->
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  
  <ItemGroup>
    <!-- Avalonia UI Framework (MIT License) -->
    <PackageVersion Include="Avalonia" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Controls.DataGrid" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Android" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless" Version="11.3.0" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.0" />
    
    <!-- MVVM Toolkit (MIT License) -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
    
    <!-- Entity Framework Core (MIT License) -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.1" />
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
    <PackageVersion Include="Dapper" Version="2.1.35" />
    
    <!-- Configuration (MIT License) -->
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.Json" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.1" />
    <PackageVersion Include="Microsoft.Extensions.Logging.Abstractions" Version="10.0.1" />
    
    <!-- Validation (Apache-2.0 License) -->
    <PackageVersion Include="FluentValidation" Version="12.1.1" />
    
    <!-- OpenTelemetry (Apache-2.0 License) -->
    <PackageVersion Include="OpenTelemetry" Version="1.12.0" />
    <PackageVersion Include="OpenTelemetry.Api" Version="1.12.0" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.12.0" />
    <PackageVersion Include="OpenTelemetry.Exporter.Console" Version="1.12.0" />
    <PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.12.0" />
    <PackageVersion Include="OpenTelemetry.Instrumentation.Http" Version="1.12.0" />
    
    <!-- Logging (Apache-2.0 License) -->
    <PackageVersion Include="Serilog" Version="4.2.0" />
    <PackageVersion Include="Serilog.Extensions.Logging" Version="9.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="6.0.0" />
    <PackageVersion Include="Serilog.Sinks.File" Version="6.0.0" />
    
    <!-- Testing - All Free/Open-Source -->
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="18.0.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.5" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
    
    <!-- Shouldly - BSD-3-Clause License (FREE replacement for FluentAssertions) -->
    <PackageVersion Include="Shouldly" Version="4.3.0" />
    
    <!-- NSubstitute - BSD-3-Clause License (FREE replacement for Moq) -->
    <PackageVersion Include="NSubstitute" Version="5.3.0" />
    
    <!-- Bogus - MIT License (Fake data generation) -->
    <PackageVersion Include="Bogus" Version="35.6.5" />
    
    <!-- Testcontainers - MIT License (Integration testing) -->
    <PackageVersion Include="Testcontainers" Version="4.4.0" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.4.0" />
  </ItemGroup>
</Project>
PACKAGES_EOF

echo "  ✓ Updated Directory.Packages.props"
echo "    - Removed: FluentAssertions (commercial license)"
echo "    - Removed: Moq (compromised package)"
echo "    - Removed: Avalonia.ReactiveUI (deprecated)"
echo "    - Added: Shouldly (BSD-3-Clause, 100% free)"
echo "    - Added: NSubstitute (BSD-3-Clause, 100% free)"

# -----------------------------------------------------------------------------
#  Step 5: Update Directory.Build.props (Build Optimizations)
# -----------------------------------------------------------------------------
echo "[Step 5/8] Updating build configuration..."

cat > Directory.Build.props << 'BUILD_PROPS_EOF'
<Project>
  <!--
    Shared Build Properties for All Projects
    Includes optimizations for Android aapt2 issues
  -->
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <NoWarn>$(NoWarn);CS1591;CS8618</NoWarn>
    <GenerateDocumentationFile>false</GenerateDocumentationFile>
  </PropertyGroup>
  
  <!-- Android-specific optimizations to prevent aapt2 hangs -->
  <PropertyGroup Condition="$(TargetFramework.Contains('android'))">
    <!-- Disable aapt2 daemon (prevents deadlocks on Linux/macOS) -->
    <AndroidAapt2DaemonEnabled>false</AndroidAapt2DaemonEnabled>
    <!-- Use single-threaded aapt2 -->
    <AndroidAapt2ParallelThread>1</AndroidAapt2ParallelThread>
    <!-- Faster resource compilation -->
    <AndroidEnableAapt2NoCrunch>true</AndroidEnableAapt2NoCrunch>
    <!-- Use interpreted mode for faster debug builds -->
    <UseInterpreter Condition="'$(Configuration)' == 'Debug'">true</UseInterpreter>
    <!-- Reduce logging verbosity -->
    <AndroidUseSharedRuntime>false</AndroidUseSharedRuntime>
  </PropertyGroup>
  
  <!-- Source generators for MVVM -->
  <PropertyGroup>
    <EnableMSBuildToolsGeneration>true</EnableMSBuildToolsGeneration>
  </PropertyGroup>
</Project>
BUILD_PROPS_EOF

echo "  ✓ Updated Directory.Build.props with aapt2 optimizations"

# -----------------------------------------------------------------------------
#  Step 6: Fix Source Code Files
# -----------------------------------------------------------------------------
echo "[Step 6/8] Fixing source code files..."

# 6.1: Fix TodoItem.cs (add CompletedAt and Priority properties)
cat > src/MyDesktopApplication.Core/Entities/TodoItem.cs << 'TODOITEM_EOF'
namespace MyDesktopApplication.Core.Entities;

/// <summary>
/// Represents a todo item in the application
/// </summary>
public class TodoItem : EntityBase
{
    public required string Title { get; set; }
    public string? Description { get; set; }
    public int Priority { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? DueDate { get; set; }
    
    /// <summary>
    /// Marks the todo item as complete
    /// </summary>
    public void MarkComplete()
    {
        IsCompleted = true;
        CompletedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// Marks the todo item as incomplete
    /// </summary>
    public void MarkIncomplete()
    {
        IsCompleted = false;
        CompletedAt = null;
    }
}
TODOITEM_EOF
echo "  ✓ Fixed TodoItem.cs (added CompletedAt, Priority)"

# 6.2: Fix ViewModelBase.cs (add ClearError/SetError methods)
cat > src/MyDesktopApplication.Shared/ViewModels/ViewModelBase.cs << 'VIEWMODELBASE_EOF'
using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

/// <summary>
/// Base class for all ViewModels with common functionality
/// </summary>
public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
    
    [ObservableProperty]
    private bool _hasError;
    
    /// <summary>
    /// Clears any error state
    /// </summary>
    protected void ClearError()
    {
        ErrorMessage = null;
        HasError = false;
    }
    
    /// <summary>
    /// Sets an error message
    /// </summary>
    protected void SetError(string message)
    {
        ErrorMessage = message;
        HasError = true;
    }
    
    /// <summary>
    /// Executes an async operation with busy state management
    /// </summary>
    protected async Task ExecuteBusyAsync(Func<Task> operation)
    {
        if (IsBusy) return;
        
        try
        {
            IsBusy = true;
            ClearError();
            await operation();
        }
        catch (Exception ex)
        {
            SetError(ex.Message);
        }
        finally
        {
            IsBusy = false;
        }
    }
}
VIEWMODELBASE_EOF
echo "  ✓ Fixed ViewModelBase.cs (added ClearError/SetError)"

# 6.3: Update test files to use Shouldly instead of FluentAssertions
if [ -f "tests/MyDesktopApplication.Core.Tests/TodoItemTests.cs" ]; then
    cat > tests/MyDesktopApplication.Core.Tests/TodoItemTests.cs << 'TODOITEMTESTS_EOF'
using MyDesktopApplication.Core.Entities;
using Shouldly;
using Xunit;

namespace MyDesktopApplication.Core.Tests;

public class TodoItemTests
{
    [Fact]
    public void MarkComplete_SetsIsCompletedTrue()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };
        
        // Act
        todo.MarkComplete();
        
        // Assert
        todo.IsCompleted.ShouldBeTrue();
        todo.CompletedAt.ShouldNotBeNull();
    }
    
    [Fact]
    public void MarkIncomplete_SetsIsCompletedFalse()
    {
        // Arrange
        var todo = new TodoItem { Title = "Test Todo" };
        todo.MarkComplete();
        
        // Act
        todo.MarkIncomplete();
        
        // Assert
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
    }
    
    [Fact]
    public void NewTodoItem_HasDefaultValues()
    {
        // Arrange & Act
        var todo = new TodoItem { Title = "Test" };
        
        // Assert
        todo.IsCompleted.ShouldBeFalse();
        todo.CompletedAt.ShouldBeNull();
        todo.Priority.ShouldBe(0);
        todo.DueDate.ShouldBeNull();
    }
}
TODOITEMTESTS_EOF
    echo "  ✓ Updated TodoItemTests.cs (using Shouldly)"
fi

# 6.4: Update Core.Tests csproj to use Shouldly
cat > tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj << 'CORETESTS_CSPROJ_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Bogus" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
  </ItemGroup>
</Project>
CORETESTS_CSPROJ_EOF
echo "  ✓ Updated Core.Tests.csproj (using Shouldly)"

# 6.5: Update Integration.Tests csproj
cat > tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj << 'INTTESTS_CSPROJ_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Bogus" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" />
    <PackageReference Include="Testcontainers" />
    <PackageReference Include="Testcontainers.PostgreSql" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\..\src\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
  </ItemGroup>
</Project>
INTTESTS_CSPROJ_EOF
echo "  ✓ Updated Integration.Tests.csproj (using Shouldly)"

# 6.6: Update UI.Tests csproj
cat > tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj << 'UITESTS_CSPROJ_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Shouldly" />
    <PackageReference Include="NSubstitute" />
    <PackageReference Include="Avalonia.Headless" />
    <PackageReference Include="Avalonia.Headless.XUnit" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
</Project>
UITESTS_CSPROJ_EOF
echo "  ✓ Updated UI.Tests.csproj (using Shouldly)"

# -----------------------------------------------------------------------------
#  Step 7: Update GitHub Actions
# -----------------------------------------------------------------------------
echo "[Step 7/8] Updating GitHub Actions to latest versions..."

mkdir -p .github/workflows

# 7.1: CI Workflow (every push/PR)
cat > .github/workflows/ci.yml << 'CI_WORKFLOW_EOF'
name: CI

on:
  push:
    branches: [master, main, develop]
  pull_request:
    branches: [master, main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    name: Build & Test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
          
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
            
      - name: Restore (Desktop only)
        run: |
          dotnet restore src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj
          dotnet restore src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj
          dotnet restore src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj
          dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
          dotnet restore tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj
          dotnet restore tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj
          dotnet restore tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj
          
      - name: Build
        run: |
          dotnet build src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj --no-restore -c Release
          
      - name: Test
        run: |
          dotnet test tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj --no-restore -c Release --verbosity normal
          dotnet test tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj --no-restore -c Release --verbosity normal
CI_WORKFLOW_EOF
echo "  ✓ Created ci.yml (build & test on every push/PR)"

# 7.2: Build Workflow (pre-releases on push to main branches)
cat > .github/workflows/build.yml << 'BUILD_WORKFLOW_EOF'
name: Build

on:
  push:
    branches: [master, main, develop]
    
concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-desktop:
    name: Build Desktop (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            rid: linux-x64
            artifact: linux-x64
          - os: ubuntu-24.04-arm
            rid: linux-arm64
            artifact: linux-arm64
          - os: windows-latest
            rid: win-x64
            artifact: win-x64
          - os: windows-11-arm
            rid: win-arm64
            artifact: win-arm64
          - os: macos-latest
            rid: osx-arm64
            artifact: osx-arm64
          - os: macos-13
            rid: osx-x64
            artifact: osx-x64
            
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
          
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
            
      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
        
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release \
            -r ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -o ./publish/${{ matrix.artifact }}
            
      - name: Upload Artifact
        uses: actions/upload-artifact@v6
        with:
          name: desktop-${{ matrix.artifact }}
          path: ./publish/${{ matrix.artifact }}
          retention-days: 5

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
          
      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '21'
          
      - name: Install Android Workload
        run: dotnet workload install android
        
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-
            
      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj
        
      - name: Build APK
        run: |
          dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release \
            -p:AndroidAapt2DaemonEnabled=false
            
      - name: Upload APK
        uses: actions/upload-artifact@v6
        with:
          name: android-apk
          path: src/MyDesktopApplication.Android/bin/Release/**/**.apk
          retention-days: 5

  create-prerelease:
    name: Create Pre-release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
    
    steps:
      - name: Download All Artifacts
        uses: actions/download-artifact@v7
        with:
          path: ./artifacts
          pattern: '*'
          merge-multiple: false
          
      - name: Create Archives
        run: |
          cd artifacts
          for dir in */; do
            name="${dir%/}"
            if [[ "$name" == *"win"* ]]; then
              zip -r "../${name}.zip" "$dir"
            else
              tar -czvf "../${name}.tar.gz" "$dir"
            fi
          done
          
      - name: Delete Previous Dev Release
        uses: dev-drprasad/delete-tag-and-release@v1.1
        with:
          tag_name: dev
          github_token: ${{ secrets.GITHUB_TOKEN }}
          delete_release: true
        continue-on-error: true
        
      - name: Create Dev Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: dev
          name: Development Build
          prerelease: true
          body: |
            🚧 **Development Build**
            
            This is an automatically generated pre-release from the latest commit on `${{ github.ref_name }}`.
            
            **Commit:** ${{ github.sha }}
            **Date:** ${{ github.event.head_commit.timestamp }}
            
            ⚠️ This build may be unstable. Use at your own risk.
          files: |
            *.zip
            *.tar.gz
BUILD_WORKFLOW_EOF
echo "  ✓ Created build.yml (pre-releases on push to main)"

# 7.3: Release Workflow (stable releases on tags)
cat > .github/workflows/release.yml << 'RELEASE_WORKFLOW_EOF'
name: Release

on:
  push:
    tags: ['v*']

jobs:
  build-desktop:
    name: Build Desktop (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            rid: linux-x64
            artifact: linux-x64
          - os: ubuntu-24.04-arm
            rid: linux-arm64
            artifact: linux-arm64
          - os: windows-latest
            rid: win-x64
            artifact: win-x64
          - os: windows-11-arm
            rid: win-arm64
            artifact: win-arm64
          - os: macos-latest
            rid: osx-arm64
            artifact: osx-arm64
          - os: macos-13
            rid: osx-x64
            artifact: osx-x64
            
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
          
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
            
      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj
        
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj \
            -c Release \
            -r ${{ matrix.rid }} \
            --self-contained true \
            -p:PublishSingleFile=true \
            -p:IncludeNativeLibrariesForSelfExtract=true \
            -o ./publish/${{ matrix.artifact }}
            
      - name: Upload Artifact
        uses: actions/upload-artifact@v6
        with:
          name: desktop-${{ matrix.artifact }}
          path: ./publish/${{ matrix.artifact }}

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: '10.0.x'
          
      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '21'
          
      - name: Install Android Workload
        run: dotnet workload install android
        
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-
            
      - name: Restore
        run: dotnet restore src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj
        
      - name: Build APK
        run: |
          dotnet build src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj \
            -c Release \
            -p:AndroidAapt2DaemonEnabled=false
            
      - name: Upload APK
        uses: actions/upload-artifact@v6
        with:
          name: android-apk
          path: src/MyDesktopApplication.Android/bin/Release/**/**.apk

  create-release:
    name: Create Release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    
    steps:
      - name: Download All Artifacts
        uses: actions/download-artifact@v7
        with:
          path: ./artifacts
          pattern: '*'
          merge-multiple: false
          
      - name: Create Archives
        run: |
          cd artifacts
          for dir in */; do
            name="${dir%/}"
            if [[ "$name" == *"win"* ]]; then
              zip -r "../${name}.zip" "$dir"
            else
              tar -czvf "../${name}.tar.gz" "$dir"
            fi
          done
          
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          name: Release ${{ github.ref_name }}
          generate_release_notes: true
          files: |
            *.zip
            *.tar.gz
RELEASE_WORKFLOW_EOF
echo "  ✓ Created release.yml (stable releases on git tags)"

# 7.4: Update dependabot.yml
cat > .github/dependabot.yml << 'DEPENDABOT_EOF'
version: 2
updates:
  - package-ecosystem: "nuget"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    groups:
      avalonia:
        patterns:
          - "Avalonia*"
      microsoft:
        patterns:
          - "Microsoft.*"
      opentelemetry:
        patterns:
          - "OpenTelemetry*"
      testing:
        patterns:
          - "xunit*"
          - "Shouldly*"
          - "NSubstitute*"
          - "Bogus"
          - "coverlet*"
          - "Testcontainers*"
    ignore:
      # Ignore FluentAssertions (commercial license)
      - dependency-name: "FluentAssertions"
      # Ignore Moq (compromised)
      - dependency-name: "Moq"
      
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
DEPENDABOT_EOF
echo "  ✓ Updated dependabot.yml"

# -----------------------------------------------------------------------------
#  Step 8: Create Migration Script
# -----------------------------------------------------------------------------
echo "[Step 8/8] Creating migration script..."

cat > migrate.sh << 'MIGRATE_EOF'
#!/bin/bash
set -e

# =============================================================================
#  Database Migration Script
# =============================================================================
#
#  Usage:
#    ./migrate.sh <MigrationName>           # Add migration and apply
#    ./migrate.sh <MigrationName> --add     # Add migration only
#    ./migrate.sh --apply                   # Apply pending migrations
#    ./migrate.sh --status                  # Show migration status
#    ./migrate.sh --rollback                # Rollback last migration
#
# =============================================================================

INFRASTRUCTURE_PROJECT="src/MyDesktopApplication.Infrastructure"
STARTUP_PROJECT="src/MyDesktopApplication.Desktop"
MIGRATIONS_DIR="Data/Migrations"

show_usage() {
    echo "Usage: $0 <MigrationName> [options]"
    echo ""
    echo "Options:"
    echo "  --add        Add migration only (don't apply)"
    echo "  --apply      Apply pending migrations"
    echo "  --status     Show migration status"
    echo "  --rollback   Rollback last migration"
    echo ""
    echo "Examples:"
    echo "  $0 InitialCreate           # Add and apply 'InitialCreate' migration"
    echo "  $0 AddUserTable --add      # Add 'AddUserTable' migration only"
    echo "  $0 --apply                 # Apply all pending migrations"
}

# Check if EF tools are installed
if ! dotnet ef --version &>/dev/null; then
    echo "Installing Entity Framework Core tools..."
    dotnet tool install --global dotnet-ef
fi

case "${1:-}" in
    --apply)
        echo "Applying pending migrations..."
        dotnet ef database update \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        echo "✓ Migrations applied"
        ;;
    --status)
        echo "Migration status:"
        dotnet ef migrations list \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT"
        ;;
    --rollback)
        echo "Rolling back last migration..."
        # Get the previous migration
        PREV=$(dotnet ef migrations list \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --no-connect 2>/dev/null | tail -2 | head -1 | xargs)
        if [ -n "$PREV" ] && [ "$PREV" != "(No migrations)" ]; then
            dotnet ef database update "$PREV" \
                --project "$INFRASTRUCTURE_PROJECT" \
                --startup-project "$STARTUP_PROJECT"
            echo "✓ Rolled back to: $PREV"
        else
            echo "No migrations to rollback"
        fi
        ;;
    --help|-h)
        show_usage
        ;;
    "")
        show_usage
        exit 1
        ;;
    *)
        MIGRATION_NAME="$1"
        ADD_ONLY=false
        
        if [ "${2:-}" == "--add" ]; then
            ADD_ONLY=true
        fi
        
        echo "Adding migration: $MIGRATION_NAME"
        dotnet ef migrations add "$MIGRATION_NAME" \
            --project "$INFRASTRUCTURE_PROJECT" \
            --startup-project "$STARTUP_PROJECT" \
            --output-dir "$MIGRATIONS_DIR"
        echo "✓ Migration added: $MIGRATION_NAME"
        
        if [ "$ADD_ONLY" = false ]; then
            echo "Applying migration to SQLite database..."
            dotnet ef database update \
                --project "$INFRASTRUCTURE_PROJECT" \
                --startup-project "$STARTUP_PROJECT"
            echo "✓ Migration applied"
        fi
        ;;
esac
MIGRATE_EOF

chmod +x migrate.sh
echo "  ✓ Created migrate.sh"

# -----------------------------------------------------------------------------
#  Final Build and Test
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Building and Testing"
echo "=============================================="

# Clean build artifacts
echo "Cleaning build artifacts..."
find . -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "obj" -exec rm -rf {} + 2>/dev/null || true

# Restore
echo "Restoring packages..."
dotnet restore MyDesktopApplication.slnx

# Build
echo "Building solution..."
if dotnet build MyDesktopApplication.slnx -c Release --no-restore; then
    echo "✓ Build succeeded!"
else
    echo "✗ Build failed - check errors above"
    exit 1
fi

# Test
echo "Running tests..."
if dotnet test MyDesktopApplication.slnx -c Release --no-build --verbosity normal; then
    echo "✓ All tests passed!"
else
    echo "✗ Some tests failed - check output above"
    exit 1
fi

# -----------------------------------------------------------------------------
#  Summary
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Initialization Complete!"
echo "=============================================="
echo ""
echo "Project Structure:"
echo "  MyDesktopApplication.slnx    <- Single unified solution"
echo "  Directory.Build.props        <- Shared build settings"
echo "  Directory.Packages.props     <- Central package management"
echo "  migrate.sh                   <- Database migration script"
echo "  export.sh                    <- LLM export script"
echo ""
echo "GitHub Actions:"
echo "  ci.yml      <- Build & test on every push/PR"
echo "  build.yml   <- Pre-release on push to main"
echo "  release.yml <- Stable release on git tags (v*)"
echo ""
echo "Standard Commands:"
echo "  dotnet build                 <- Build everything"
echo "  dotnet test                  <- Run all tests"
echo "  dotnet run --project src/MyDesktopApplication.Desktop"
echo ""
echo "Package Changes:"
echo "  ✗ FluentAssertions (commercial) -> ✓ Shouldly (BSD-3-Clause)"
echo "  ✗ Moq (compromised)            -> ✓ NSubstitute (BSD-3-Clause)"
echo "  ✗ Avalonia.ReactiveUI (deprecated)"
echo ""
echo "Next Steps:"
echo "  1. Review the changes: git diff"
echo "  2. Commit: git add -A && git commit -m 'Unify project structure'"
echo "  3. Push: git push"
echo "  4. Create release: git tag v1.0.3 && git push --tags"
echo ""

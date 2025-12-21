#!/bin/bash
# Fix Avalonia.ReactiveUI version issue
# We don't need ReactiveUI since we're using CommunityToolkit.Mvvm

set -e

echo "Fixing Avalonia package versions..."

# Update Directory.Packages.props to remove ReactiveUI and fix versions
cat > Directory.Packages.props << 'EOF'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>
  <ItemGroup>
    <!-- Avalonia UI -->
    <PackageVersion Include="Avalonia" Version="11.3.9" />
    <PackageVersion Include="Avalonia.Desktop" Version="11.3.9" />
    <PackageVersion Include="Avalonia.Android" Version="11.3.9" />
    <PackageVersion Include="Avalonia.Themes.Fluent" Version="11.3.9" />
    <PackageVersion Include="Avalonia.Fonts.Inter" Version="11.3.9" />
    <PackageVersion Include="Avalonia.Diagnostics" Version="11.3.9" />
    
    <!-- MVVM -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.4.0" />
    
    <!-- Entity Framework Core -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.1" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.InMemory" Version="10.0.1" />
    
    <!-- DI -->
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.0" />
    
    <!-- Validation -->
    <PackageVersion Include="FluentValidation" Version="12.1.1" />
    
    <!-- Testing -->
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.1.1" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
    <PackageVersion Include="FluentAssertions" Version="8.4.0" />
    <PackageVersion Include="Moq" Version="4.20.72" />
    <PackageVersion Include="Avalonia.Headless.XUnit" Version="11.3.9" />
  </ItemGroup>
</Project>
EOF

# Update Desktop csproj - remove ReactiveUI
cat > src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <BuiltInComInteropSupport>true</BuiltInComInteropSupport>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
    <ApplicationIcon>Assets\avalonia-logo.ico</ApplicationIcon>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Desktop" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="Avalonia.Fonts.Inter" />
    <PackageReference Include="Avalonia.Diagnostics" Condition="'$(Configuration)' == 'Debug'" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
EOF

# Update Android csproj - remove ReactiveUI
cat > src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <Nullable>enable</Nullable>
    <ApplicationId>com.mycompany.countryquiz</ApplicationId>
    <ApplicationVersion>1</ApplicationVersion>
    <ApplicationDisplayVersion>1.0.0</ApplicationDisplayVersion>
    <AndroidPackageFormat>apk</AndroidPackageFormat>
    <AvaloniaUseCompiledBindingsByDefault>true</AvaloniaUseCompiledBindingsByDefault>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyDesktopApplication.Core\MyDesktopApplication.Core.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Infrastructure\MyDesktopApplication.Infrastructure.csproj" />
    <ProjectReference Include="..\MyDesktopApplication.Shared\MyDesktopApplication.Shared.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" />
    <PackageReference Include="Avalonia.Android" />
    <PackageReference Include="Avalonia.Themes.Fluent" />
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" />
  </ItemGroup>
</Project>
EOF

# Update UI Tests csproj - remove ReactiveUI
cat > tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\MyDesktopApplication.Desktop\MyDesktopApplication.Desktop.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" />
    <PackageReference Include="Moq" />
    <PackageReference Include="Avalonia.Headless.XUnit" />
  </ItemGroup>
</Project>
EOF

echo "✓ Package versions fixed (removed ReactiveUI, using 11.3.9)"
echo ""
echo "Running restore and build..."

dotnet restore
dotnet build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "To run: dotnet run --project src/MyDesktopApplication.Desktop"
else
    echo ""
    echo "❌ Build failed - check errors above"
fi

#!/bin/bash
set -e

echo "=============================================="
echo "  Cleanup and Standardize Project"
echo "=============================================="
echo ""
echo "This script will:"
echo "  1. Consolidate to single MyDesktopApplication.slnx"
echo "  2. Kill stuck aapt2/VBCSCompiler processes"
echo "  3. Update GitHub Actions to latest versions"
echo "  4. Create robust add-migration.sh"
echo "  5. Remove redundant fix-* scripts"
echo ""

# Step 1: Kill stuck processes
echo "Step 1: Killing stuck processes..."
pkill -f aapt2 2>/dev/null || true
pkill -f VBCSCompiler 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
echo "✓ Processes cleaned"

# Step 2: Remove duplicate solution file
echo ""
echo "Step 2: Consolidating solution files..."
if [ -f "MyDesktopApplication.Desktop.slnx" ]; then
    rm -f MyDesktopApplication.Desktop.slnx
    echo "✓ Removed MyDesktopApplication.Desktop.slnx"
fi

# Step 3: Create the unified solution file
echo ""
echo "Step 3: Creating unified MyDesktopApplication.slnx..."
cat > MyDesktopApplication.slnx << 'SLNX_EOF'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/MyDesktopApplication.Android/MyDesktopApplication.Android.csproj" />
    <Project Path="src/MyDesktopApplication.Core/MyDesktopApplication.Core.csproj" />
    <Project Path="src/MyDesktopApplication.Desktop/MyDesktopApplication.Desktop.csproj" />
    <Project Path="src/MyDesktopApplication.Infrastructure/MyDesktopApplication.Infrastructure.csproj" />
    <Project Path="src/MyDesktopApplication.Shared/MyDesktopApplication.Shared.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/MyDesktopApplication.Core.Tests/MyDesktopApplication.Core.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.Integration.Tests/MyDesktopApplication.Integration.Tests.csproj" />
    <Project Path="tests/MyDesktopApplication.UI.Tests/MyDesktopApplication.UI.Tests.csproj" />
  </Folder>
</Solution>
SLNX_EOF
echo "✓ Created unified solution with all 8 projects"

# Step 4: Optimize Directory.Build.props
echo ""
echo "Step 4: Updating Directory.Build.props..."
cat > Directory.Build.props << 'PROPS_EOF'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    
    <!-- Disable telemetry -->
    <SuppressNETCoreSdkPreviewMessage>true</SuppressNETCoreSdkPreviewMessage>
    
    <!-- Build optimization -->
    <GenerateDocumentationFile>false</GenerateDocumentationFile>
    <NoWarn>$(NoWarn);CS1591;CS8618</NoWarn>
    
    <!-- Android build fixes: prevent aapt2 daemon deadlocks -->
    <AndroidUseAapt2Daemon>false</AndroidUseAapt2Daemon>
    <AndroidAapt2CompileExtraArgs>--no-crunch</AndroidAapt2CompileExtraArgs>
    
    <!-- Force single-threaded resource processing -->
    <BuildInParallel>false</BuildInParallel>
  </PropertyGroup>

  <!-- Common metadata -->
  <PropertyGroup>
    <Authors>MyDesktopApplication Contributors</Authors>
    <Company>MyDesktopApplication</Company>
    <Product>MyDesktopApplication</Product>
    <Copyright>Copyright © 2025 MyDesktopApplication Contributors</Copyright>
    <RepositoryType>git</RepositoryType>
  </PropertyGroup>
</Project>
PROPS_EOF
echo "✓ Directory.Build.props updated with aapt2 fixes"

# Step 5: Create robust add-migration.sh
echo ""
echo "Step 5: Creating robust add-migration.sh..."
cat > add-migration.sh << 'MIGRATION_EOF'
#!/bin/bash
set -e

# Robust EF Core migration script
# Usage: ./add-migration.sh <MigrationName>

MIGRATION_NAME="$1"
INFRASTRUCTURE_PROJECT="src/MyDesktopApplication.Infrastructure"
STARTUP_PROJECT="src/MyDesktopApplication.Desktop"
CONTEXT_FILE="$INFRASTRUCTURE_PROJECT/Data/AppDbContext.cs"
MIGRATIONS_DIR="Data/Migrations"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  EF Core Migration Tool"
echo "=============================================="

# Validate migration name
if [ -z "$MIGRATION_NAME" ]; then
    echo -e "${RED}Error: Migration name required${NC}"
    echo ""
    echo "Usage: ./add-migration.sh <MigrationName>"
    echo "Example: ./add-migration.sh AddPriorityToTodoItem"
    exit 1
fi

# Validate migration name format (PascalCase, no spaces)
if [[ ! "$MIGRATION_NAME" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
    echo -e "${YELLOW}Warning: Migration name should be PascalCase (e.g., InitialCreate)${NC}"
fi

# Step 1: Validate AppDbContext exists
echo ""
echo "Step 1: Validating AppDbContext..."
if [ ! -f "$CONTEXT_FILE" ]; then
    echo -e "${RED}Error: AppDbContext not found at $CONTEXT_FILE${NC}"
    echo ""
    echo "Expected location: $CONTEXT_FILE"
    echo "Please ensure the Infrastructure project has a Data/AppDbContext.cs file"
    exit 1
fi

# Check if AppDbContext class is defined
if ! grep -q "class AppDbContext" "$CONTEXT_FILE"; then
    echo -e "${RED}Error: AppDbContext class not found in $CONTEXT_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AppDbContext found${NC}"

# Step 2: Validate startup project
echo ""
echo "Step 2: Validating startup project..."
if [ ! -f "$STARTUP_PROJECT/MyDesktopApplication.Desktop.csproj" ]; then
    echo -e "${RED}Error: Startup project not found at $STARTUP_PROJECT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Startup project found${NC}"

# Step 3: Check for EF tools
echo ""
echo "Step 3: Checking EF Core tools..."
if ! command -v dotnet-ef &> /dev/null && ! dotnet tool list -g | grep -q "dotnet-ef"; then
    echo -e "${YELLOW}Installing dotnet-ef tool...${NC}"
    dotnet tool install --global dotnet-ef
fi
echo -e "${GREEN}✓ EF Core tools available${NC}"

# Step 4: Kill any stuck processes
echo ""
echo "Step 4: Cleaning up stuck processes..."
pkill -f aapt2 2>/dev/null || true
pkill -f VBCSCompiler 2>/dev/null || true
dotnet build-server shutdown 2>/dev/null || true
echo -e "${GREEN}✓ Processes cleaned${NC}"

# Step 5: Build the projects first (excluding Android to avoid hangs)
echo ""
echo "Step 5: Building projects..."
dotnet build "$INFRASTRUCTURE_PROJECT" --no-restore -v q 2>/dev/null || \
    dotnet build "$INFRASTRUCTURE_PROJECT" -v q
dotnet build "$STARTUP_PROJECT" --no-restore -v q 2>/dev/null || \
    dotnet build "$STARTUP_PROJECT" -v q
echo -e "${GREEN}✓ Projects built${NC}"

# Step 6: Create the migration
echo ""
echo "Step 6: Creating migration '$MIGRATION_NAME'..."
dotnet ef migrations add "$MIGRATION_NAME" \
    --project "$INFRASTRUCTURE_PROJECT" \
    --startup-project "$STARTUP_PROJECT" \
    --output-dir "$MIGRATIONS_DIR" \
    --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Migration '$MIGRATION_NAME' created successfully!${NC}"
    
    # Step 7: Apply the migration
    echo ""
    echo "Step 7: Applying migration to database..."
    dotnet ef database update \
        --project "$INFRASTRUCTURE_PROJECT" \
        --startup-project "$STARTUP_PROJECT"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Database updated successfully!${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Migration created but database update failed${NC}"
        echo "You can manually apply with:"
        echo "  dotnet ef database update --project $INFRASTRUCTURE_PROJECT --startup-project $STARTUP_PROJECT"
    fi
else
    echo ""
    echo -e "${RED}✗ Migration creation failed${NC}"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Migration Complete!"
echo "=============================================="
echo ""
echo "Migration files created in: $INFRASTRUCTURE_PROJECT/$MIGRATIONS_DIR/"
echo ""
MIGRATION_EOF
chmod +x add-migration.sh
echo "✓ Created robust add-migration.sh"

# Step 6: Update GitHub Actions workflows
echo ""
echo "Step 6: Updating GitHub Actions to latest versions..."
mkdir -p .github/workflows

# Create ci.yml (runs on every push/PR - desktop only, no artifacts)
cat > .github/workflows/ci.yml << 'CI_EOF'
name: CI

on:
  push:
    branches: [master, main, develop]
  pull_request:
    branches: [master, main, develop]

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  build-and-test:
    name: Build & Test
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
      
      - name: Kill stuck processes
        if: runner.os != 'Windows'
        run: |
          pkill -f aapt2 || true
          pkill -f VBCSCompiler || true
        shell: bash
      
      - name: Restore (Desktop projects only)
        run: |
          dotnet restore src/MyDesktopApplication.Core
          dotnet restore src/MyDesktopApplication.Infrastructure
          dotnet restore src/MyDesktopApplication.Shared
          dotnet restore src/MyDesktopApplication.Desktop
          dotnet restore tests/MyDesktopApplication.Core.Tests
          dotnet restore tests/MyDesktopApplication.Integration.Tests
          dotnet restore tests/MyDesktopApplication.UI.Tests
      
      - name: Build (Desktop projects only)
        run: |
          dotnet build src/MyDesktopApplication.Desktop --no-restore -c Release
          dotnet build tests/MyDesktopApplication.Core.Tests --no-restore -c Release
          dotnet build tests/MyDesktopApplication.Integration.Tests --no-restore -c Release
          dotnet build tests/MyDesktopApplication.UI.Tests --no-restore -c Release
      
      - name: Test
        run: dotnet test tests/ --no-build -c Release --verbosity normal
CI_EOF
echo "✓ Created ci.yml"

# Create build.yml (pre-releases on push to main branches)
cat > .github/workflows/build.yml << 'BUILD_EOF'
name: Build

on:
  push:
    branches: [master, main, develop]
    paths-ignore:
      - '**.md'
      - 'docs/**'

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  # Desktop builds
  build-desktop:
    name: Build Desktop (${{ matrix.rid }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: MyDesktopApplication-win-x64
          - os: windows-latest
            rid: win-arm64
            artifact: MyDesktopApplication-win-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: MyDesktopApplication-linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: MyDesktopApplication-linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: MyDesktopApplication-osx-x64
          - os: macos-latest
            rid: osx-arm64
            artifact: MyDesktopApplication-osx-arm64
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
      
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop -c Release -r ${{ matrix.rid }} --self-contained -o publish/${{ matrix.artifact }}
      
      - name: Create archive (Windows)
        if: startsWith(matrix.rid, 'win')
        run: Compress-Archive -Path publish/${{ matrix.artifact }}/* -DestinationPath ${{ matrix.artifact }}.zip
        shell: pwsh
      
      - name: Create archive (Linux/macOS)
        if: "!startsWith(matrix.rid, 'win')"
        run: tar -czvf ${{ matrix.artifact }}.tar.gz -C publish ${{ matrix.artifact }}
        shell: bash
      
      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: ${{ matrix.artifact }}
          path: |
            ${{ matrix.artifact }}.zip
            ${{ matrix.artifact }}.tar.gz
          if-no-files-found: ignore
          retention-days: 7

  # Android build
  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '21'
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      
      - name: Install Android workload
        run: dotnet workload install android
      
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-
      
      - name: Kill stuck processes
        run: |
          pkill -f aapt2 || true
          pkill -f VBCSCompiler || true
      
      - name: Build APK
        run: |
          dotnet publish src/MyDesktopApplication.Android -c Release -o publish/android \
            -p:AndroidUseAapt2Daemon=false \
            -p:BuildInParallel=false
      
      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: MyDesktopApplication-android
          path: publish/android/*.apk
          if-no-files-found: warn
          retention-days: 7

  # Create dev pre-release
  create-prerelease:
    name: Create Pre-release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v7
        with:
          path: artifacts
          merge-multiple: false
      
      - name: List artifacts
        run: find artifacts -type f
      
      - name: Delete existing dev release
        uses: actions/github-script@v7
        with:
          script: |
            try {
              const release = await github.rest.repos.getReleaseByTag({
                owner: context.repo.owner,
                repo: context.repo.repo,
                tag: 'dev'
              });
              await github.rest.repos.deleteRelease({
                owner: context.repo.owner,
                repo: context.repo.repo,
                release_id: release.data.id
              });
              await github.rest.git.deleteRef({
                owner: context.repo.owner,
                repo: context.repo.repo,
                ref: 'tags/dev'
              });
            } catch (e) {
              console.log('No existing dev release to delete');
            }
      
      - name: Create dev release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: dev
          name: Development Build
          body: |
            🚧 **Development Build**
            
            This is an automated pre-release build from the latest commit.
            
            **Commit:** ${{ github.sha }}
            **Branch:** ${{ github.ref_name }}
            **Date:** ${{ github.event.head_commit.timestamp }}
          prerelease: true
          files: |
            artifacts/**/*.zip
            artifacts/**/*.tar.gz
            artifacts/**/*.apk
BUILD_EOF
echo "✓ Created build.yml"

# Create release.yml (stable releases on git tags)
cat > .github/workflows/release.yml << 'RELEASE_EOF'
name: Release

on:
  push:
    tags:
      - 'v*'

env:
  DOTNET_VERSION: '10.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  # Desktop builds
  build-desktop:
    name: Build Desktop (${{ matrix.rid }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: windows-latest
            rid: win-x64
            artifact: MyDesktopApplication-win-x64
          - os: windows-latest
            rid: win-arm64
            artifact: MyDesktopApplication-win-arm64
          - os: ubuntu-latest
            rid: linux-x64
            artifact: MyDesktopApplication-linux-x64
          - os: ubuntu-latest
            rid: linux-arm64
            artifact: MyDesktopApplication-linux-arm64
          - os: macos-latest
            rid: osx-x64
            artifact: MyDesktopApplication-osx-x64
          - os: macos-latest
            rid: osx-arm64
            artifact: MyDesktopApplication-osx-arm64
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-nuget-
      
      - name: Publish
        run: |
          dotnet publish src/MyDesktopApplication.Desktop -c Release -r ${{ matrix.rid }} --self-contained -o publish/${{ matrix.artifact }}
      
      - name: Create archive (Windows)
        if: startsWith(matrix.rid, 'win')
        run: Compress-Archive -Path publish/${{ matrix.artifact }}/* -DestinationPath ${{ matrix.artifact }}.zip
        shell: pwsh
      
      - name: Create archive (Linux/macOS)
        if: "!startsWith(matrix.rid, 'win')"
        run: tar -czvf ${{ matrix.artifact }}.tar.gz -C publish ${{ matrix.artifact }}
        shell: bash
      
      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: ${{ matrix.artifact }}
          path: |
            ${{ matrix.artifact }}.zip
            ${{ matrix.artifact }}.tar.gz
          if-no-files-found: ignore
          retention-days: 30

  # Android build
  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Setup Java
        uses: actions/setup-java@v5
        with:
          distribution: 'temurin'
          java-version: '21'
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      
      - name: Install Android workload
        run: dotnet workload install android
      
      - name: Cache NuGet packages
        uses: actions/cache@v5
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-android-nuget-${{ hashFiles('**/*.csproj', '**/Directory.Packages.props') }}
          restore-keys: |
            ${{ runner.os }}-android-nuget-
      
      - name: Kill stuck processes
        run: |
          pkill -f aapt2 || true
          pkill -f VBCSCompiler || true
      
      - name: Build signed APK
        run: |
          dotnet publish src/MyDesktopApplication.Android -c Release -o publish/android \
            -p:AndroidUseAapt2Daemon=false \
            -p:BuildInParallel=false
      
      - name: Upload artifact
        uses: actions/upload-artifact@v6
        with:
          name: MyDesktopApplication-android
          path: publish/android/*.apk
          if-no-files-found: warn
          retention-days: 30

  # Create GitHub Release
  create-release:
    name: Create Release
    needs: [build-desktop, build-android]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Download all artifacts
        uses: actions/download-artifact@v7
        with:
          path: artifacts
          merge-multiple: false
      
      - name: List artifacts
        run: find artifacts -type f
      
      - name: Generate changelog
        id: changelog
        run: |
          echo "## What's Changed" > CHANGELOG.md
          echo "" >> CHANGELOG.md
          git log --pretty=format:"* %s (%h)" $(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")..HEAD >> CHANGELOG.md 2>/dev/null || echo "* Initial release" >> CHANGELOG.md
      
      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          name: Release ${{ github.ref_name }}
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
          files: |
            artifacts/**/*.zip
            artifacts/**/*.tar.gz
            artifacts/**/*.apk
          generate_release_notes: true
RELEASE_EOF
echo "✓ Created release.yml"

# Update dependabot.yml
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
      testing:
        patterns:
          - "xunit*"
          - "FluentAssertions*"
          - "NSubstitute*"
          - "Bogus"
          - "coverlet*"
    ignore:
      - dependency-name: "*"
        update-types: ["version-update:semver-patch"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
DEPENDABOT_EOF
echo "✓ Updated dependabot.yml"

# Step 7: Remove redundant scripts
echo ""
echo "Step 7: Removing redundant scripts..."
SCRIPTS_TO_REMOVE=(
    "fix-android-build.sh"
    "fix-tests.sh"
    "fix-all.sh"
    "fix-cpm.sh"
    "fix-ci-and-add-android.sh"
    "fix-android-code.sh"
    "fix-android-font.sh"
    "fix-android-namespace.sh"
    "fix-android-theme.sh"
    "fix-build-errors.sh"
    "fix-build-and-migratons.sh"
    "fix-github-actions.sh"
    "setup-project.sh"
    "setup.sh"
    "setup-all.sh"
    "setup-android-fedora.sh"
    "setup-github-actions.sh"
    "continue-setup.sh"
    "update-packages.sh"
    "update-github-actions.sh"
    "build-android.sh"
    "build-desktop.sh"
    "run-tests.sh"
    "cleanup-project.sh"
    "cleanup-and-rebuild.sh"
)

for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "  Removed: $script"
    fi
done
echo "✓ Redundant scripts removed"

# Keep these essential scripts
echo ""
echo "Essential scripts preserved:"
echo "  - export.sh (LLM analysis)"
echo "  - add-migration.sh (EF Core migrations)"

# Step 8: Clean build artifacts
echo ""
echo "Step 8: Cleaning build artifacts..."
dotnet clean -v q 2>/dev/null || true
find . -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "obj" -exec rm -rf {} + 2>/dev/null || true
echo "✓ Build artifacts cleaned"

# Step 9: Test build
echo ""
echo "Step 9: Testing build (Desktop only)..."
dotnet restore src/MyDesktopApplication.Desktop
dotnet restore tests/MyDesktopApplication.Core.Tests
dotnet build src/MyDesktopApplication.Desktop -c Release --no-restore -v q
dotnet build tests/MyDesktopApplication.Core.Tests -c Release --no-restore -v q
echo "✓ Desktop build succeeded!"

# Step 10: Run tests
echo ""
echo "Step 10: Running tests..."
dotnet test tests/MyDesktopApplication.Core.Tests --no-build -c Release -v q
echo "✓ Tests passed!"

echo ""
echo "=============================================="
echo "  Cleanup Complete!"
echo "=============================================="
echo ""
echo "Summary of changes:"
echo ""
echo "  Solution Files:"
echo "    ✓ MyDesktopApplication.slnx (unified, all 8 projects)"
echo "    ✗ MyDesktopApplication.Desktop.slnx (removed)"
echo ""
echo "  GitHub Actions (updated to latest versions):"
echo "    ┌────────────────────────────┬──────┬──────┐"
echo "    │ Action                     │ Old  │ New  │"
echo "    ├────────────────────────────┼──────┼──────┤"
echo "    │ actions/checkout           │ v4   │ v6   │"
echo "    │ actions/setup-dotnet       │ v4   │ v5   │"
echo "    │ actions/setup-java         │ v4   │ v5   │"
echo "    │ actions/cache              │ v4   │ v5   │"
echo "    │ actions/upload-artifact    │ v4   │ v6   │"
echo "    │ actions/download-artifact  │ v4   │ v7   │"
echo "    │ softprops/action-gh-release│ v1   │ v2   │"
echo "    └────────────────────────────┴──────┴──────┘"
echo ""
echo "  Workflow Behavior:"
echo "    • ci.yml: Build & test on every push/PR (desktop only)"
echo "    • build.yml: Creates 'dev' pre-release on push to main branches"
echo "    • release.yml: Creates stable release on git tags (v*)"
echo ""
echo "  Scripts:"
echo "    ✓ add-migration.sh (robust EF Core migrations)"
echo "    ✓ export.sh (preserved)"
echo "    ✗ All fix-*.sh, setup-*.sh, build-*.sh (removed)"
echo ""
echo "Next steps:"
echo "  1. git add -A"
echo "  2. git commit -m 'Cleanup: consolidate solution, update GitHub Actions'"
echo "  3. git push"
echo ""
echo "To create a release:"
echo "  git tag v1.0.3"
echo "  git push origin v1.0.3"
echo ""

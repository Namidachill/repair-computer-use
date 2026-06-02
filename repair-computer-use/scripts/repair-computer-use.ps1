[CmdletBinding()]
param(
    [ValidateSet('Inspect', 'Repair')]
    [string]$Mode = 'Inspect'
)

$ErrorActionPreference = 'Stop'

function Get-CodexDesktopPackage {
    $package = Get-AppxPackage -Name 'OpenAI.Codex'
    if (-not $package) {
        throw 'OpenAI.Codex Desktop package was not found.'
    }

    return $package
}

function Get-PluginNames {
    param([string]$MarketplaceRoot)

    $pluginsRoot = Join-Path $MarketplaceRoot 'plugins'
    if (-not (Test-Path -LiteralPath $pluginsRoot)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $pluginsRoot -Directory -Force |
        Select-Object -ExpandProperty Name)
}

function Invoke-CodexText {
    param([string[]]$Arguments)

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = (& codex @Arguments 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 0) {
            throw "codex $($Arguments -join ' ') failed with exit code $LASTEXITCODE`n$output"
        }
        return $output
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Get-OpenAiBundledStatus {
    $package = Get-CodexDesktopPackage
    $packageMarketplace = Join-Path $package.InstallLocation 'app\resources\plugins\openai-bundled'
    $packageManifest = Join-Path $packageMarketplace '.agents\plugins\marketplace.json'
    $temporaryMarketplace = Join-Path $env:USERPROFILE '.codex\.tmp\bundled-marketplaces\openai-bundled'
    $configPath = Join-Path $env:USERPROFILE '.codex\config.toml'

    $marketplaceList = Invoke-CodexText -Arguments @('plugin', 'marketplace', 'list')
    $pluginList = Invoke-CodexText -Arguments @('plugin', 'list')
    $configText = if (Test-Path -LiteralPath $configPath) {
        Get-Content -LiteralPath $configPath -Raw -Encoding utf8
    } else {
        ''
    }

    [PSCustomObject]@{
        DesktopVersion = $package.Version.ToString()
        PackageMarketplaceRoot = $packageMarketplace
        PackageManifestExists = Test-Path -LiteralPath $packageManifest
        PackagePlugins = (Get-PluginNames -MarketplaceRoot $packageMarketplace) -join ', '
        PackageContainsComputerUse = 'computer-use' -in (Get-PluginNames -MarketplaceRoot $packageMarketplace)
        TemporaryMarketplaceRoot = $temporaryMarketplace
        TemporaryManifestExists = Test-Path -LiteralPath (Join-Path $temporaryMarketplace '.agents\plugins\marketplace.json')
        TemporaryPlugins = (Get-PluginNames -MarketplaceRoot $temporaryMarketplace) -join ', '
        MarketplaceRegistered = $marketplaceList -match '(?m)^openai-bundled\s+'
        ComputerUseListed = $pluginList -match '(?m)^computer-use@openai-bundled\s+'
        ComputerUseEnabledInConfig = $configText -match '(?ms)^\[plugins\."computer-use@openai-bundled"\]\s*\r?\nenabled\s*=\s*true\s*$'
    }
}

$statusBefore = Get-OpenAiBundledStatus

if ($Mode -eq 'Inspect') {
    $statusBefore
    exit 0
}

if (-not $statusBefore.PackageManifestExists) {
    throw "Bundled marketplace manifest was not found: $($statusBefore.PackageMarketplaceRoot)"
}

if (-not $statusBefore.PackageContainsComputerUse) {
    throw "The installed Codex Desktop bundled marketplace does not contain computer-use: $($statusBefore.PackageMarketplaceRoot)"
}

$configPath = Join-Path $env:USERPROFILE '.codex\config.toml'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Codex config was not found: $configPath"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = "$configPath.bak-before-openai-bundled-reregister-$timestamp"
Copy-Item -LiteralPath $configPath -Destination $backupPath

$null = Invoke-CodexText -Arguments @('plugin', 'marketplace', 'add', $statusBefore.PackageMarketplaceRoot)

$statusAfter = Get-OpenAiBundledStatus
[PSCustomObject]@{
    BackupPath = $backupPath
    MarketplaceRoot = $statusBefore.PackageMarketplaceRoot
    MarketplaceRegistered = $statusAfter.MarketplaceRegistered
    ComputerUseListed = $statusAfter.ComputerUseListed
    ComputerUseEnabledInConfig = $statusAfter.ComputerUseEnabledInConfig
    NextStep = 'Restart Codex Desktop, then verify Settings > Computer Use and validate from a fresh chat.'
}

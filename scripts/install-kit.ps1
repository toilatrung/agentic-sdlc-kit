[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetProjectPath
)

$ErrorActionPreference = 'Stop'
$kitRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if (-not (Test-Path -LiteralPath $TargetProjectPath -PathType Container)) {
    throw "Target project directory does not exist: $TargetProjectPath"
}

$targetRoot = (Resolve-Path -LiteralPath $TargetProjectPath).Path
if ($targetRoot -eq $kitRoot) {
    throw 'Target project must be different from the Agentic SDLC Kit source directory.'
}

$copied = [System.Collections.Generic.List[string]]::new()
$backedUp = [System.Collections.Generic.List[string]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()

@(
    'README.md (target project identity preserved)',
    'LICENSE (target project license preserved)',
    'CHANGELOG.md (not part of overlay)',
    'CONTRIBUTING.md (not part of overlay)',
    'src/ (not part of overlay)',
    'tests/ (not part of overlay)',
    'infrastructure/ (not part of overlay)',
    'package and build files (not part of overlay)'
) | ForEach-Object { $skipped.Add($_) }

function Get-BackupPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $base = "$Path.backup-agentic-sdlc-kit"
    $candidate = $base
    $number = 1
    while (Test-Path -LiteralPath $candidate) {
        $candidate = "$base.$number"
        $number++
    }
    return $candidate
}

function Get-RelativeChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$ChildPath
    )

    $baseFull = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/')
    $childFull = [System.IO.Path]::GetFullPath($ChildPath)
    $prefix = "$baseFull$([System.IO.Path]::DirectorySeparatorChar)"
    if (-not $childFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is not inside the expected base path: $ChildPath"
    }
    return $childFull.Substring($prefix.Length)
}

function Backup-Existing {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    $backup = Get-BackupPath -Path $Path
    Copy-Item -LiteralPath $Path -Destination $backup -Recurse
    $relative = Get-RelativeChildPath -BasePath $targetRoot -ChildPath $backup
    $backedUp.Add($relative)
}

function Copy-FileAsset {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRelative,
        [Parameter(Mandatory = $true)][string]$DestinationRelative
    )

    $source = Join-Path $kitRoot $SourceRelative
    $destination = Join-Path $targetRoot $DestinationRelative
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        $skipped.Add("$SourceRelative (source asset missing)")
        return
    }
    Backup-Existing -Path $destination
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $destination -Force
    $copied.Add($DestinationRelative)
}

function Copy-DirectoryAsset {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRelative,
        [Parameter(Mandatory = $true)][string]$DestinationRelative
    )

    $source = Join-Path $kitRoot $SourceRelative
    $destination = Join-Path $targetRoot $DestinationRelative
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        $skipped.Add("$SourceRelative/ (source asset missing)")
        return
    }
    Backup-Existing -Path $destination
    if (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force
    }
    Get-ChildItem -LiteralPath $source -Recurse -Force -File | ForEach-Object {
        $relative = Get-RelativeChildPath -BasePath $source -ChildPath $_.FullName
        $copied.Add((Join-Path $DestinationRelative $relative))
    }
}

Copy-FileAsset -SourceRelative 'AGENT.md' -DestinationRelative 'AGENT.md'
Copy-DirectoryAsset -SourceRelative '.agent' -DestinationRelative '.agent'
Copy-DirectoryAsset -SourceRelative 'docs' -DestinationRelative 'docs'
Copy-FileAsset -SourceRelative 'scripts/validate-framework.py' -DestinationRelative 'scripts/validate-framework.py'
Copy-FileAsset -SourceRelative 'LICENSE' -DestinationRelative 'LICENSE.agentic-sdlc-kit'
Copy-FileAsset -SourceRelative 'README.md' -DestinationRelative 'AGENTIC-SDLC-KIT.md'

$validationResult = 'VALIDATION_SKIPPED_PYTHON_NOT_AVAILABLE'
$validationExit = 0
$pythonAttempted = $false
$candidates = @(
    @{ Name = 'python'; Prefix = @() },
    @{ Name = 'python3'; Prefix = @() },
    @{ Name = 'py'; Prefix = @('-3') }
)

foreach ($candidate in $candidates) {
    $command = Get-Command $candidate.Name -ErrorAction SilentlyContinue
    if (-not $command) {
        continue
    }
    $pythonAttempted = $true
    try {
        Push-Location $targetRoot
        $arguments = @($candidate.Prefix) + @('scripts/validate-framework.py')
        $output = @(& $command.Source @arguments 2>&1)
        $exitCode = $LASTEXITCODE
        Pop-Location
        Write-Output "Validation output ($($candidate.Name)):"
        $output | ForEach-Object { Write-Output $_ }
        if ($exitCode -eq 0 -and $output -contains 'FRAMEWORK_VALIDATION_PASS') {
            $validationResult = 'FRAMEWORK_VALIDATION_PASS'
            $validationExit = 0
            break
        }
        elseif ($output -contains 'FRAMEWORK_VALIDATION_FAIL') {
            $validationResult = 'FRAMEWORK_VALIDATION_FAIL'
            $validationExit = 1
            break
        }
    }
    catch {
        if ((Get-Location).Path -eq $targetRoot) {
            Pop-Location
        }
        continue
    }
}

if ($pythonAttempted -and $validationResult -eq 'VALIDATION_SKIPPED_PYTHON_NOT_AVAILABLE') {
    $validationResult = 'FRAMEWORK_VALIDATION_FAIL'
    $validationExit = 1
}

function Write-List {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][System.Collections.IEnumerable]$Items
    )

    Write-Output $Title
    $values = @($Items)
    if ($values.Count -eq 0) {
        Write-Output '  - none'
        return
    }
    $values | ForEach-Object { Write-Output "  - $_" }
}

Write-Output ''
Write-List -Title 'Files copied:' -Items $copied
Write-List -Title 'Files backed up:' -Items $backedUp
Write-List -Title 'Files skipped:' -Items $skipped
Write-Output "Validation result: $validationResult"

exit $validationExit

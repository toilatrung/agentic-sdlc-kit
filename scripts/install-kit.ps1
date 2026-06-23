[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetProjectPath,

    [switch]$Force,
    [switch]$ResetRuntime
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
$overwriteRuntime = $Force -or $ResetRuntime

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

function Write-CleanRuntimeFile {
    param(
        [Parameter(Mandatory = $true)][string]$DestinationRelative,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $destination = Join-Path $targetRoot $DestinationRelative
    if ((Test-Path -LiteralPath $destination) -and -not $overwriteRuntime) {
        $skipped.Add("$DestinationRelative (existing runtime state preserved; use -ResetRuntime or -Force to overwrite)")
        return
    }
    Backup-Existing -Path $destination
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $destination -Value $Content -Encoding UTF8
    $copied.Add($DestinationRelative)
}

function Ensure-KeepFile {
    param([Parameter(Mandatory = $true)][string]$DestinationRelative)

    $destination = Join-Path $targetRoot $DestinationRelative
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path -LiteralPath $destination) {
        $skipped.Add("$DestinationRelative (already exists)")
        return
    }
    New-Item -ItemType File -Path $destination -Force | Out-Null
    $copied.Add($DestinationRelative)
}

function Initialize-CleanRuntime {
    Write-CleanRuntimeFile -DestinationRelative '.agent/execution/current-context.md' -Content @'
---
id: current-context
title: Current Context
type: execution
domain: governance
module: execution
tags: [context, execution, state]
priority: 1
---
# Current Context

## Purpose

Expose the minimal synchronized state for currently authorized execution without becoming a fixed or mandatory reading list.

## Status Model

- **Valid Context Statuses**: `current | stale | archived`
- **Valid Roadmap Statuses**: `ROADMAP_DRAFT | ROADMAP_APPROVED | ROADMAP_ACTIVE | ROADMAP_BLOCKED | ROADMAP_DONE | ROADMAP_CANCELLED`
- **Valid Epic Statuses**: `EPIC_PROPOSED | EPIC_READY | EPIC_IN_PROGRESS | EPIC_BLOCKED | EPIC_DONE | EPIC_CANCELLED`
- **Valid Task Statuses**: `pending | in-progress | blocked | review | done | cancelled`

## Current State

- **Context Revision**: `1`
- **Context Status**: `current`
- **Last Updated**: `not-started`
- **Updated By**: `installer`
- **Update Trigger**: `clean-overlay-install`
- **Planning Roadmap ID**: `none`
- **Planning Roadmap Status**: `ROADMAP_DRAFT`
- **Onboarding State**: `not-started`
- **Active Epic IDs**: `none`
- **Active Task IDs**: `none`
- **Active Blocker IDs**: `none`
- **Active Decision IDs**: `none`
- **Active Risk IDs**: `none`
- **Active Change Request IDs**: `none`
- **Current Session ID**: `none`
'@

    Write-CleanRuntimeFile -DestinationRelative '.agent/execution/sessions-history.md' -Content @'
---
id: sessions-history
title: Sessions History
type: execution
domain: governance
module: execution
tags: [sessions, history, audit]
priority: 3
---
# Sessions History

## Purpose

Maintain an append-only audit of agent execution sessions, their ownership, scope, outcome, and produced evidence.

## Status Model

- **Valid Outcomes**: `in-progress | completed | partial | blocked | failed | cancelled | corrected`

## Session Records

| Session ID | Start Date | End Date | Owner | Task or Scope IDs | Outcome | Summary | Output and Evidence Links | Supersedes |
|---|---|---|---|---|---|---|---|---|

No session records are registered.
'@

    Write-CleanRuntimeFile -DestinationRelative '.agent/execution/task-board.md' -Content @'
---
id: task-board
title: Task Board
type: execution
domain: governance
module: execution
tags: [tasks, execution, board]
priority: 1
---
# Task Board

## Purpose

Maintain the authoritative registry of executable tasks and their lifecycle state.

## Status Model

- **Valid Statuses**: `pending | in-progress | blocked | review | done | cancelled`
- `pending -> in-progress` requires an owner, sufficient context, satisfied dependencies, and parent epic `EPIC_IN_PROGRESS`.
- `in-progress -> blocked` requires a linked blocker.
- `in-progress -> review` requires implementation evidence and acceptance-criteria results.
- `review -> done` requires required review and QA evidence.
- `blocked -> in-progress` requires verified blocker resolution.
- `cancelled` requires an authorized rationale; `done` and `cancelled` are terminal.

## Task Records

| Task ID | Epic ID | Title | Owner | Status | Dependencies | Blocker IDs | Evidence Links | Updated Date |
|---|---|---|---|---|---|---|---|---|

No task records are registered.
'@

    Write-CleanRuntimeFile -DestinationRelative '.agent/planning/roadmap.md' -Content @'
---
id: roadmap-v1
title: Project Roadmap
type: planning
domain: governance
module: planning
tags: [roadmap, milestones, planning]
priority: 1
---
# Project Roadmap

## Purpose

Maintain the approved sequence of outcome-level roadmap items and their target windows without defining task-level implementation.

## Status Model

- **Valid Statuses**: `ROADMAP_DRAFT | ROADMAP_APPROVED | ROADMAP_ACTIVE | ROADMAP_BLOCKED | ROADMAP_DONE | ROADMAP_CANCELLED`

## Roadmap Records

| Roadmap ID | Outcome | Owner | Target Window | Status | Milestone IDs | Change Request |
|---|---|---|---|---|---|---|

No roadmap records are registered.
'@

    Write-CleanRuntimeFile -DestinationRelative '.agent/planning/milestones.md' -Content @'
---
id: milestones-v1
title: Milestones
type: planning
domain: governance
module: planning
tags: [milestones, planning]
priority: 2
---
# Milestones

## Purpose

Maintain measurable delivery checkpoints that group epics under approved roadmap outcomes.

## Status Model

- **Valid Statuses**: `proposed | ready | in-progress | blocked | completed | cancelled`

## Milestone Records

| Milestone ID | Roadmap ID | Outcome | Owner | Target Window | Status | Epic IDs | Acceptance Evidence |
|---|---|---|---|---|---|---|---|

No milestone records are registered.
'@

    Write-CleanRuntimeFile -DestinationRelative '.agent/planning/epics.md' -Content @'
---
id: epics-v1
title: Epics
type: planning
domain: governance
module: planning
tags: [epics, planning]
priority: 2
---
# Epics

## Purpose

Maintain the authoritative registry of bounded delivery outcomes that may be expanded into executable tasks.

## Status Model

- **Valid Statuses**: `EPIC_PROPOSED | EPIC_READY | EPIC_IN_PROGRESS | EPIC_BLOCKED | EPIC_DONE | EPIC_CANCELLED`

## Epic Records

| Epic ID | Milestone ID | Outcome | Owner | Status | Task IDs | Acceptance Evidence | Governance Links |
|---|---|---|---|---|---|---|---|

No epic records are registered.
'@

    Write-CleanRuntimeFile -DestinationRelative '.agent/planning/dependency-graph.md' -Content @'
---
id: dep-graph-v1
title: Dependency Graph
type: planning
domain: architecture
module: planning
tags: [dependencies, epics, milestones]
priority: 2
---
# Dependency Graph

## Purpose

Maintain the authoritative directed relationships that constrain roadmap items, milestones, epics, and tasks.

## Status Model

- **Valid Edge Statuses**: `active | satisfied | blocked | removed`

## Dependency Records

| Edge ID | Dependent ID | Prerequisite ID | Type | Owner | Status | Evidence | Governance Link |
|---|---|---|---|---|---|---|---|

No dependency records are registered.
'@

    $intelligenceFiles = @{
        '.agent/intelligence/code-graph/modules.md' = @('code-graph-modules', 'Code Graph Modules', 'architecture', 'code-graph', '[code-graph, modules]', 'Modules', 'Catalog repository modules, their responsibilities, boundaries, owners, and source locations. No application modules are registered yet.')
        '.agent/intelligence/code-graph/dependencies.md' = @('code-graph-dependencies', 'Code Graph Dependencies', 'architecture', 'code-graph', '[code-graph, dependencies]', 'Dependencies', 'Map internal and external module dependencies, direction, purpose, and constraints. No application dependencies are registered yet.')
        '.agent/intelligence/code-graph/api-routes.md' = @('code-graph-api-routes', 'Code Graph API Routes', 'api', 'code-graph', '[code-graph, api]', 'API Routes', 'Catalog API routes, methods, handlers, contracts, and ownership. No API routes are registered yet.')
        '.agent/intelligence/code-graph/database-usage.md' = @('code-graph-database-usage', 'Code Graph Database Usage', 'database', 'code-graph', '[code-graph, database]', 'Database Usage', 'Catalog database entities, access paths, migrations, and ownership. No database usage is registered yet.')
        '.agent/intelligence/code-graph/function-map.md' = @('code-graph-function-map', 'Code Graph Function Map', 'development', 'code-graph', '[code-graph, functions]', 'Function Map', 'Catalog important functions, entry points, call relationships, and ownership. No functions are registered yet.')
        '.agent/intelligence/git-nexus/commit-map.md' = @('git-nexus-commit-map', 'Git Nexus Commit Map', 'governance', 'git-nexus', '[git-nexus, commits, traceability]', 'Commit Map', 'Index commits by hash, date, author, summary, affected modules, related tasks, decisions, and releases. No commit mappings are registered yet.')
        '.agent/intelligence/git-nexus/task-commit-map.md' = @('git-nexus-task-commit-map', 'Git Nexus Task Commit Map', 'governance', 'git-nexus', '[git-nexus, tasks, commits]', 'Task Commit Map', 'Map task IDs to implementation commits and report evidence. No task commit mappings are registered yet.')
        '.agent/intelligence/git-nexus/decision-commit-map.md' = @('git-nexus-decision-commit-map', 'Git Nexus Decision Commit Map', 'governance', 'git-nexus', '[git-nexus, decisions, commits]', 'Decision Commit Map', 'Map decisions and change requests to commits that implement or depend on them. No decision commit mappings are registered yet.')
        '.agent/intelligence/git-nexus/regression-log.md' = @('git-nexus-regression-log', 'Git Nexus Regression Log', 'quality', 'git-nexus', '[git-nexus, regressions]', 'Regression Log', 'Record regressions, suspected commits, fixes, and verification evidence. No regressions are registered yet.')
    }
    foreach ($entry in $intelligenceFiles.GetEnumerator()) {
        $values = $entry.Value
        Write-CleanRuntimeFile -DestinationRelative $entry.Key -Content @"
---
id: $($values[0])
title: $($values[1])
type: intelligence
domain: $($values[2])
module: $($values[3])
tags: $($values[4])
priority: 3
---
# $($values[5])

$($values[6])
"@
    }

    @(
        '.agent/reports/implementation/.keep',
        '.agent/reports/review/.keep',
        '.agent/reports/qa/.keep',
        '.agent/reports/releases/.keep',
        '.agent/governance/issues/.keep',
        '.agent/governance/blockers/.keep',
        '.agent/governance/change-requests/.keep',
        '.agent/governance/decisions/.keep',
        '.agent/governance/risks/.keep'
    ) | ForEach-Object { Ensure-KeepFile -DestinationRelative $_ }
}

Copy-FileAsset -SourceRelative 'AGENT.md' -DestinationRelative 'AGENT.md'
Copy-DirectoryAsset -SourceRelative '.agent/templates' -DestinationRelative '.agent/templates'
Initialize-CleanRuntime
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

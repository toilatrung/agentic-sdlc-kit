#!/usr/bin/env bash

set -u

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target-project-path> [--force|--reset-runtime]" >&2
  exit 2
fi

TARGET_INPUT=""
RESET_RUNTIME=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force|--reset-runtime)
      RESET_RUNTIME=1
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [[ -n "$TARGET_INPUT" ]]; then
        echo "Usage: $0 <target-project-path> [--force|--reset-runtime]" >&2
        exit 2
      fi
      TARGET_INPUT="$1"
      shift
      ;;
  esac
done

if [[ -z "$TARGET_INPUT" ]]; then
  echo "Usage: $0 <target-project-path> [--force|--reset-runtime]" >&2
  exit 2
fi

if [[ ! -d "$TARGET_INPUT" ]]; then
  echo "Target project directory does not exist: $TARGET_INPUT" >&2
  exit 2
fi

TARGET_ROOT="$(cd "$TARGET_INPUT" && pwd)"
if [[ "$TARGET_ROOT" == "$KIT_ROOT" ]]; then
  echo "Target project must be different from the Agentic SDLC Kit source directory." >&2
  exit 2
fi

COPIED=()
BACKED_UP=()
SKIPPED=(
  "README.md (target project identity preserved)"
  "LICENSE (target project license preserved)"
  "CHANGELOG.md (not part of overlay)"
  "CONTRIBUTING.md (not part of overlay)"
  "src/ (not part of overlay)"
  "tests/ (not part of overlay)"
  "infrastructure/ (not part of overlay)"
  "package and build files (not part of overlay)"
)

next_backup_path() {
  local original="$1"
  local base="${original}.backup-agentic-sdlc-kit"
  local candidate="$base"
  local number=1
  while [[ -e "$candidate" ]]; do
    candidate="${base}.${number}"
    number=$((number + 1))
  done
  printf '%s' "$candidate"
}

backup_existing() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return
  fi
  local backup
  backup="$(next_backup_path "$path")"
  cp -a "$path" "$backup"
  BACKED_UP+=("${backup#"$TARGET_ROOT"/}")
}

record_tree_files() {
  local source="$1"
  local destination_relative="$2"
  while IFS= read -r -d '' file; do
    local relative="${file#"$source"/}"
    COPIED+=("${destination_relative}/${relative}")
  done < <(find "$source" -type f -print0)
}

copy_file_asset() {
  local source_relative="$1"
  local destination_relative="$2"
  local source="$KIT_ROOT/$source_relative"
  local destination="$TARGET_ROOT/$destination_relative"
  if [[ ! -f "$source" ]]; then
    SKIPPED+=("$source_relative (source asset missing)")
    return 1
  fi
  backup_existing "$destination"
  mkdir -p "$(dirname "$destination")"
  cp -a "$source" "$destination"
  COPIED+=("$destination_relative")
}

copy_directory_asset() {
  local source_relative="$1"
  local destination_relative="$2"
  local source="$KIT_ROOT/$source_relative"
  local destination="$TARGET_ROOT/$destination_relative"
  if [[ ! -d "$source" ]]; then
    SKIPPED+=("$source_relative/ (source asset missing)")
    return 1
  fi
  backup_existing "$destination"
  mkdir -p "$destination"
  cp -a "$source/." "$destination/"
  record_tree_files "$source" "$destination_relative"
}

write_clean_runtime_file() {
  local destination_relative="$1"
  local destination="$TARGET_ROOT/$destination_relative"
  if [[ -e "$destination" && "$RESET_RUNTIME" -eq 0 ]]; then
    SKIPPED+=("$destination_relative (existing runtime state preserved; use --reset-runtime or --force to overwrite)")
    cat >/dev/null
    return
  fi
  backup_existing "$destination"
  mkdir -p "$(dirname "$destination")"
  cat >"$destination"
  COPIED+=("$destination_relative")
}

ensure_keep_file() {
  local destination_relative="$1"
  local destination="$TARGET_ROOT/$destination_relative"
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" ]]; then
    SKIPPED+=("$destination_relative (already exists)")
    return
  fi
  : >"$destination"
  COPIED+=("$destination_relative")
}

initialize_clean_runtime() {
  write_clean_runtime_file ".agent/execution/current-context.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/execution/sessions-history.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/execution/task-board.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/planning/roadmap.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/planning/milestones.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/planning/epics.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/planning/dependency-graph.md" <<'EOF'
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
EOF

  write_clean_runtime_file ".agent/intelligence/code-graph/modules.md" <<'EOF'
---
id: code-graph-modules
title: Code Graph Modules
type: intelligence
domain: architecture
module: code-graph
tags: [code-graph, modules]
priority: 3
---
# Modules

Catalog repository modules, their responsibilities, boundaries, owners, and source locations. No application modules are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/code-graph/dependencies.md" <<'EOF'
---
id: code-graph-dependencies
title: Code Graph Dependencies
type: intelligence
domain: architecture
module: code-graph
tags: [code-graph, dependencies]
priority: 3
---
# Dependencies

Map internal and external module dependencies, direction, purpose, and constraints. No application dependencies are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/code-graph/api-routes.md" <<'EOF'
---
id: code-graph-api-routes
title: Code Graph API Routes
type: intelligence
domain: api
module: code-graph
tags: [code-graph, api]
priority: 3
---
# API Routes

Catalog API routes, methods, handlers, contracts, and ownership. No API routes are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/code-graph/database-usage.md" <<'EOF'
---
id: code-graph-database-usage
title: Code Graph Database Usage
type: intelligence
domain: database
module: code-graph
tags: [code-graph, database]
priority: 3
---
# Database Usage

Catalog database entities, access paths, migrations, and ownership. No database usage is registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/code-graph/function-map.md" <<'EOF'
---
id: code-graph-function-map
title: Code Graph Function Map
type: intelligence
domain: development
module: code-graph
tags: [code-graph, functions]
priority: 3
---
# Function Map

Catalog important functions, entry points, call relationships, and ownership. No functions are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/git-nexus/commit-map.md" <<'EOF'
---
id: git-nexus-commit-map
title: Git Nexus Commit Map
type: intelligence
domain: governance
module: git-nexus
tags: [git-nexus, commits, traceability]
priority: 3
---
# Commit Map

Index commits by hash, date, author, summary, affected modules, related tasks, decisions, and releases. No commit mappings are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/git-nexus/task-commit-map.md" <<'EOF'
---
id: git-nexus-task-commit-map
title: Git Nexus Task Commit Map
type: intelligence
domain: governance
module: git-nexus
tags: [git-nexus, tasks, commits]
priority: 3
---
# Task Commit Map

Map task IDs to implementation commits and report evidence. No task commit mappings are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/git-nexus/decision-commit-map.md" <<'EOF'
---
id: git-nexus-decision-commit-map
title: Git Nexus Decision Commit Map
type: intelligence
domain: governance
module: git-nexus
tags: [git-nexus, decisions, commits]
priority: 3
---
# Decision Commit Map

Map decisions and change requests to commits that implement or depend on them. No decision commit mappings are registered yet.
EOF

  write_clean_runtime_file ".agent/intelligence/git-nexus/regression-log.md" <<'EOF'
---
id: git-nexus-regression-log
title: Git Nexus Regression Log
type: intelligence
domain: quality
module: git-nexus
tags: [git-nexus, regressions]
priority: 3
---
# Regression Log

Record regressions, suspected commits, fixes, and verification evidence. No regressions are registered yet.
EOF

  local keep
  for keep in \
    ".agent/reports/implementation/.keep" \
    ".agent/reports/review/.keep" \
    ".agent/reports/qa/.keep" \
    ".agent/reports/releases/.keep" \
    ".agent/governance/issues/.keep" \
    ".agent/governance/blockers/.keep" \
    ".agent/governance/change-requests/.keep" \
    ".agent/governance/decisions/.keep" \
    ".agent/governance/risks/.keep"; do
    ensure_keep_file "$keep"
  done
}

copy_file_asset "AGENT.md" "AGENT.md"
copy_directory_asset ".agent/templates" ".agent/templates"
initialize_clean_runtime
copy_directory_asset "docs" "docs"
copy_file_asset "scripts/validate-framework.py" "scripts/validate-framework.py"
copy_file_asset "LICENSE" "LICENSE.agentic-sdlc-kit"
copy_file_asset "README.md" "AGENTIC-SDLC-KIT.md"

VALIDATION_RESULT="VALIDATION_SKIPPED_PYTHON_NOT_AVAILABLE"
VALIDATION_EXIT=0
PYTHON_FOUND=0
for PYTHON_NAME in python python3; do
  if ! command -v "$PYTHON_NAME" >/dev/null 2>&1; then
    continue
  fi
  PYTHON_FOUND=1
  echo "Validation output ($PYTHON_NAME):"
  pushd "$TARGET_ROOT" >/dev/null
  set +e
  VALIDATION_OUTPUT="$("$PYTHON_NAME" scripts/validate-framework.py 2>&1)"
  CANDIDATE_EXIT=$?
  set -e
  popd >/dev/null
  printf '%s\n' "$VALIDATION_OUTPUT"
  if grep -q '^FRAMEWORK_VALIDATION_PASS$' <<<"$VALIDATION_OUTPUT" && [[ $CANDIDATE_EXIT -eq 0 ]]; then
    VALIDATION_RESULT="FRAMEWORK_VALIDATION_PASS"
    VALIDATION_EXIT=0
    break
  fi
  if grep -q '^FRAMEWORK_VALIDATION_FAIL$' <<<"$VALIDATION_OUTPUT"; then
    VALIDATION_RESULT="FRAMEWORK_VALIDATION_FAIL"
    VALIDATION_EXIT=1
    break
  fi
done

if [[ $PYTHON_FOUND -eq 1 && "$VALIDATION_RESULT" == "VALIDATION_SKIPPED_PYTHON_NOT_AVAILABLE" ]]; then
  VALIDATION_RESULT="FRAMEWORK_VALIDATION_FAIL"
  VALIDATION_EXIT=1
fi

print_list() {
  local title="$1"
  shift
  echo "$title"
  if [[ $# -eq 0 ]]; then
    echo "  - none"
    return
  fi
  local item
  for item in "$@"; do
    echo "  - $item"
  done
}

echo
print_list "Files copied:" "${COPIED[@]}"
print_list "Files backed up:" "${BACKED_UP[@]}"
print_list "Files skipped:" "${SKIPPED[@]}"
echo "Validation result: $VALIDATION_RESULT"

exit "$VALIDATION_EXIT"

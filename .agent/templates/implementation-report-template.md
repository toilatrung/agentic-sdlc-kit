---
id: implementation-report-template
title: Implementation Report Template
type: report
domain: development
module: templates
tags: [implementation, report, template]
priority: 3
---
# Implementation Report Template

## Usage Purpose

Use this template to provide auditable evidence of work performed for one authorized task or epic.

## Record Metadata

- **Report ID**: `IMPL-<number>`
- **Title**: `<required>`
- **Owner**: `<required-person-or-agent-id>`
- **Author**: `<required-person-or-agent-id>`
- **Status**: `draft | complete | blocked | superseded`
- **Task IDs**: `<T-number-list>`
- **Epic ID**: `E-<number>`
- **Report Date**: `YYYY-MM-DD`

## Scope

- **Implemented**: `<specific-deliverables>`
- **Not Implemented**: `<excluded-or-deferred-items-or-none>`

## Changes Made

| File or Artifact | Change Summary | Task ID |
|---|---|---|
| `<repository-relative-path>` | `<specific-change>` | `T-<number>` |

## Related Files

- **Task Records**: `<paths-and-anchors>`
- **Context Packages**: `<paths>`
- **Decisions**: `<paths-or-none>`
- **Change Requests**: `<paths-or-none>`
- **Risks or Blockers**: `<paths-or-none>`
- **Commits**: `<hashes-or-none-with-reason>`

## Verification Evidence

| Check | Result | Evidence |
|---|---|---|
| `<command-or-review>` | `passed | failed | not-run` | `<output-or-path>` |

## Deviations

- **Plan Deviations**: `<deviations-or-none>`
- **Approved By**: `<approval-path-or-not-applicable>`
- **Known Limitations**: `<limitations-or-none>`

## Completion Criteria

- [ ] Every reported change maps to an authorized task.
- [ ] Acceptance criteria results and evidence are linked.
- [ ] Deviations and limitations are explicit.
- [ ] Git Nexus mappings are updated when commits exist.

## Forbidden Actions

- Do not report unperformed work as implemented.
- Do not omit failed or unexecuted required checks.
- Do not claim completion with unmet task acceptance criteria.
- Do not include secrets or sensitive command output.

## Output Requirements

- Save as `.agent/reports/implementation/IMPL-<number>.md`.
- Preserve every heading and table column in this template.
- Set status `complete` only after completion criteria pass.

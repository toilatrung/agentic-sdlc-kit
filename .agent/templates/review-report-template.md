---
id: review-report-template
title: Review Report Template
type: report
domain: quality
module: templates
tags: [review, report, template]
priority: 3
---
# Review Report Template

## Usage Purpose

Use this template to record an independent review of implementation, documentation, design, or governance artifacts.

## Record Metadata

- **Report ID**: `REVIEW-<number>`
- **Title**: `<required>`
- **Owner**: `<required-person-or-agent-id>`
- **Reviewer**: `<required-person-or-agent-id>`
- **Status**: `draft | changes-required | approved | rejected | superseded`
- **Review Type**: `code | architecture | documentation | security | governance | release`
- **Task or Epic IDs**: `<ids>`
- **Report Date**: `YYYY-MM-DD`

## Review Scope

- **Included Artifacts**: `<paths-or-commit-range>`
- **Excluded Artifacts**: `<paths-or-none>`
- **Review Standard**: `<criteria-checklist-or-policy-path>`

## Related Files

- **Implementation Reports**: `<paths-or-none>`
- **Task or Epic Records**: `<paths-and-anchors>`
- **Decisions**: `<paths-or-none>`
- **Risks or Issues**: `<paths-or-none>`
- **Verification Evidence**: `<paths-or-none>`

## Findings

| Finding ID | Severity | Artifact | Finding | Required Action | Owner |
|---|---|---|---|---|---|
| `F-<number>` | `critical | major | minor | observation` | `<path>` | `<specific-finding>` | `<action-or-none>` | `<person-or-agent-id>` |

## Acceptance Criteria

- [ ] Review scope and standard are explicit.
- [ ] Each finding identifies evidence, severity, action, and owner.
- [ ] Critical and major findings are resolved or formally accepted.
- [ ] Approval outcome matches unresolved findings.

## Approval Outcome

- **Decision**: `changes-required | approved | rejected`
- **Rationale**: `<required>`
- **Approved By**: `<reviewer-or-authorized-role>`
- **Decision Date**: `YYYY-MM-DD`
- **Follow-up Tasks**: `<task-ids-or-none>`

## Completion Criteria

- [ ] All required actions are linked to tasks or verified as resolved.
- [ ] Approval outcome and rationale are recorded.
- [ ] Related issue, risk, and report records are updated.

## Forbidden Actions

- Do not approve artifacts with unresolved critical findings.
- Do not remove findings after remediation; record their resolution.
- Do not assign ambiguous severity or ownership.
- Do not claim review coverage outside the declared scope.

## Output Requirements

- Save as `.agent/reports/review/REVIEW-<number>.md`.
- Preserve every heading and table column in this template.
- Use repository-relative links and exact enum values.

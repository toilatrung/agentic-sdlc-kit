---
id: qa-report-template
title: QA Report Template
type: report
domain: testing
module: templates
tags: [qa, testing, report, template]
priority: 3
---
# QA Report Template

## Usage Purpose

Use this template to record executed quality checks, results, defects, and a release-readiness recommendation.

## Record Metadata

- **Report ID**: `QA-<number>`
- **Title**: `<required>`
- **Owner**: `<required-person-or-agent-id>`
- **Tester**: `<required-person-or-agent-id>`
- **Status**: `draft | passed | failed | blocked | superseded`
- **Task or Epic IDs**: `<ids>`
- **Test Date**: `YYYY-MM-DD`
- **Environment ID**: `<environment-name-or-id>`

## Test Scope

- **Features or Requirements**: `<ids-or-descriptions>`
- **Included Test Levels**: `unit | integration | contract | end-to-end | security | performance | manual`
- **Excluded Checks**: `<checks-and-reasons-or-none>`

## Related Files

- **Test Plan or Strategy**: `<paths>`
- **Implementation Reports**: `<paths>`
- **Review Reports**: `<paths-or-none>`
- **Issues or Risks**: `<paths-or-none>`
- **Build or Commit**: `<identifier>`

## Test Results

| Check ID | Test Level | Result | Evidence | Defect ID |
|---|---|---|---|---|
| `CHECK-<number>` | `<enum-value>` | `passed | failed | blocked | skipped` | `<path-or-output>` | `<issue-id-or-none>` |

## Result Summary

- **Total**: `<integer>`
- **Passed**: `<integer>`
- **Failed**: `<integer>`
- **Blocked**: `<integer>`
- **Skipped**: `<integer>`

## Defects and Risks

- **Open Defects**: `<issue-ids-or-none>`
- **Residual Risks**: `<risk-ids-or-none>`
- **Blocking Conditions**: `<blocker-ids-or-none>`

## Acceptance Criteria

- [ ] Every required check has a result and evidence.
- [ ] Result totals reconcile with the results table.
- [ ] Failed checks map to issue records.
- [ ] Skipped checks include an explicit approved reason.

## Release Recommendation

- **Recommendation**: `go | conditional-go | no-go`
- **Conditions**: `<required-for-conditional-go-or-none>`
- **Rationale**: `<required>`
- **Authorized By**: `<person-or-role-id>`

## Completion Criteria

- [ ] Required tests are executed or formally waived.
- [ ] Defects, blockers, and residual risks are linked.
- [ ] Release recommendation matches recorded results.

## Forbidden Actions

- Do not mark status `passed` with unresolved required failures.
- Do not omit, relabel, or discard failed results.
- Do not count unexecuted checks as passed.
- Do not expose secrets or production personal data in evidence.

## Output Requirements

- Save as `.agent/reports/qa/QA-<number>.md`.
- Preserve every heading and table column in this template.
- Use exact enum values and non-negative integer totals.

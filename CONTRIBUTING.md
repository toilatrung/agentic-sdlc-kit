---
id: agentic-sdlc-kit-contributing
title: Contributing to Agentic SDLC Kit
type: reference
domain: project
module: repository
tags: [contributing, governance, validation]
priority: 2
---
# Contributing to Agentic SDLC Kit

## Purpose

Define the minimum requirements for safe, reviewable contributions to the framework distribution.

## Operating Policy

`AGENT.md` is authoritative. Contributions must preserve its roles, lifecycle definitions, task-driven retrieval model, governance controls, report controls, and forbidden actions.

## Contribution Scope

Acceptable contributions include:

- documentation corrections and clarifications;
- validator improvements that preserve operating semantics;
- new reusable tooling or templates approved through governance;
- compatibility, packaging, accessibility, and security improvements.

Application business logic, project-specific requirements, fabricated runtime records, and silent policy changes do not belong in the framework distribution.

## Change Control

- Changes to operating policy, baselined architecture, lifecycle definitions, templates, or roadmap commitments require an approved change request.
- Material design choices require a decision record.
- Known uncertainty or delivery impact requires a risk, issue, or blocker record as applicable.
- Final reports and accepted governance history must not be rewritten; supersede them with linked records.

## Metadata Requirements

Every Markdown file must include non-empty `id`, `title`, `type`, `domain`, `module`, `tags`, and `priority` frontmatter fields. IDs must remain unique and stable.

## Development Workflow

1. Define the authorized scope and governing task or change request.
2. Retrieve context based on that scope; do not adopt a fixed reading order.
3. Make the smallest coherent change.
4. Preserve stable headings, exact lifecycle enums, and folder ownership.
5. Run `python scripts/validate-framework.py`.
6. Record review and QA evidence appropriate to the change risk.
7. Update `CHANGELOG.md` when the change affects a published release.

## Validation Requirements

A contribution is not release-ready unless the validator prints `FRAMEWORK_VALIDATION_PASS`. Contributors must also verify that:

- internal Markdown links resolve;
- required templates and prompts exist;
- runtime governance and report folders contain no reusable templates;
- epic and task enums match `AGENT.md` and their templates;
- no secrets or fabricated evidence were introduced.

## Review Requirements

- Review must be independent when required by `AGENT.md`.
- Critical and major findings must be resolved or formally accepted before approval.
- Reviewer, QA, and release-manager outputs must use the corresponding templates and runtime report directories.

## Forbidden Actions

- Do not weaken governance or lifecycle checks to make validation pass.
- Do not commit credentials, personal data, generated secrets, or sensitive raw output.
- Do not claim verification that was not executed.
- Do not move reusable templates into runtime record directories.
- Do not erase history to resolve a conflict.

---
id: agentic-sdlc-kit-installation
title: Installing Agentic SDLC Kit
type: reference
domain: project
module: installation
tags: [installation, overlay, upgrade]
priority: 1
---
# Installing Agentic SDLC Kit

## Purpose

Install the kit as a framework overlay without replacing the target project's identity, application code, tests, package configuration, or infrastructure.

## Prerequisites

- A cloned Agentic SDLC Kit repository
- An existing target project directory
- Bash for `install-kit.sh` or PowerShell 7/Windows PowerShell for `install-kit.ps1`
- Python 3.10 or later for post-install validation

## Install from a Cloned Kit

Clone or download the kit, then run an installer from the kit root.

### Bash

```bash
chmod +x scripts/install-kit.sh
./scripts/install-kit.sh /absolute/path/to/target-project
```

### PowerShell

```powershell
.\scripts\install-kit.ps1 -TargetProjectPath C:\absolute\path\to\target-project
```

The target must already exist and must not be the cloned kit directory.

## Install into an Existing Project

The installer performs an overlay operation:

1. Validate the source and target paths.
2. Back up every existing overlay destination before copying.
3. Merge kit-owned `.agent/` and `docs/` content into the target.
4. Copy the validator and renamed distribution guide and license.
5. Leave project-owned files and directories outside the overlay untouched.
6. Run `python scripts/validate-framework.py` when a Python command is available.
7. Print copied, backed-up, skipped, and validation results.

The validator automatically detects overlay mode through `AGENTIC-SDLC-KIT.md`. In overlay mode, it validates kit-owned Markdown only; unrelated project Markdown is not required to adopt kit frontmatter.

## Backup Behavior

Before replacing an existing destination, the installer creates a sibling backup using:

```text
<original-path>.backup-agentic-sdlc-kit
```

If that backup already exists, the installer appends `.1`, `.2`, and so on. Backups are copied snapshots; the target remains available while the overlay is applied.

Directory backups cover the complete pre-install `.agent/` or `docs/` tree. File backups cover `AGENT.md`, `scripts/validate-framework.py`, `AGENTIC-SDLC-KIT.md`, and `LICENSE.agentic-sdlc-kit` when present.

## Files Copied

| Kit source | Target destination |
|---|---|
| `AGENT.md` | `AGENT.md` |
| `.agent/` | `.agent/` |
| `docs/` | `docs/` |
| `scripts/validate-framework.py` | `scripts/validate-framework.py` |
| `LICENSE` | `LICENSE.agentic-sdlc-kit` |
| `README.md` | `AGENTIC-SDLC-KIT.md` |

## Files Never Copied

- `src/`
- `tests/`
- `infrastructure/`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- Root `README.md` as `README.md`
- Root `LICENSE` as `LICENSE`
- Package manifests, lock files, build configuration, and application-specific scripts

## Validation

When Python is available, the installer runs:

```bash
python scripts/validate-framework.py
```

Expected success output:

```text
FRAMEWORK_VALIDATION_PASS
```

If no Python command is available, installation completes with `VALIDATION_SKIPPED_PYTHON_NOT_AVAILABLE`. Run the validator manually after installing Python 3.10 or later.

## Uninstall Notes

There is intentionally no destructive automatic uninstaller.

1. Preserve any runtime records created after installation.
2. Compare active overlay files with the installer's copied-file output.
3. For destinations that had backups, move the active destination aside and restore the corresponding `.backup-agentic-sdlc-kit` snapshot.
4. For destinations without backups, remove only files listed as copied by the installer.
5. Remove `AGENTIC-SDLC-KIT.md` and `LICENSE.agentic-sdlc-kit` only if the target project did not adopt them.
6. Re-run project-native checks after restoration.

Do not recursively delete `.agent/`, `docs/`, or `scripts/` without reviewing project-owned and post-install content.

## Upgrade Notes

Run the newer kit's installer against the same target project. The installer creates a new backup before applying the upgraded overlay; existing backup names are never overwritten.

Before accepting an upgrade:

- review changes to `AGENT.md`, templates, prompts, and validator behavior;
- preserve runtime governance and report records created by the target project;
- use a governed change request for operating-policy or lifecycle changes;
- run framework validation after installation;
- run the target project's native build, test, and security checks.

An upgrade must not silently resolve governance records, rewrite final reports, or change project source and identity files.

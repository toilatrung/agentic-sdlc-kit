#!/usr/bin/env bash

set -u

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <target-project-path>" >&2
  exit 2
fi

TARGET_INPUT="$1"
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

copy_file_asset "AGENT.md" "AGENT.md"
copy_directory_asset ".agent" ".agent"
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

#!/usr/bin/env bash
# validate-phase-metadata.sh - Validate optional phase-level metadata fields
#
# PURPOSE:
#   Validates optional phase-level metadata fields when present in plan files.
#   Checks implementer, dependencies, and lean_file field formats.
#
# USAGE:
#   bash validate-phase-metadata.sh <plan-file>
#
# EXIT CODES:
#   0 - Validation passed (all present fields valid)
#   1 - Validation failed (format errors in present fields)
#
# OUTPUT:
#   ERROR messages for invalid field values (blocks commits)
#   INFO messages for valid optional fields found
#
# VALIDATION RULES (all fields optional, validated only when present):
#   - implementer: Must be "lean" or "software"
#   - dependencies: Must be space-separated numbers or "[]"
#   - lean_file: Must be absolute path (starting with /)
#
# INTEGRATION:
#   - Called by validate-all-standards.sh --plans
#   - Phase-level metadata is optional - only validates format when present

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# ARGUMENT PARSING
# ═══════════════════════════════════════════════════════════════════════════

if [ $# -ne 1 ]; then
  echo "ERROR: Missing plan file argument" >&2
  echo "Usage: $0 <plan-file>" >&2
  exit 1
fi

PLAN_FILE="$1"

if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION STATE
# ═══════════════════════════════════════════════════════════════════════════

VALIDATION_ERRORS=0
PHASES_WITH_METADATA=0

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

validate_implementer() {
  local value="$1"
  local phase_num="$2"

  # Valid values: "lean" or "software"
  if [[ "$value" =~ ^(lean|software)$ ]]; then
    echo "  INFO: Phase $phase_num has valid implementer: $value"
    return 0
  else
    echo "  ERROR: Phase $phase_num has invalid implementer value: $value (must be 'lean' or 'software')" >&2
    return 1
  fi
}

validate_dependencies() {
  local value="$1"
  local phase_num="$2"

  # Valid formats: "[]" or space-separated numbers "[1, 2, 3]" or "[1]"
  # Strip brackets and commas for validation
  local deps_cleaned=$(echo "$value" | tr -d '[],' | xargs)

  # Empty is valid (no dependencies)
  if [ -z "$deps_cleaned" ]; then
    echo "  INFO: Phase $phase_num has no dependencies (independent)"
    return 0
  fi

  # Check all elements are numbers
  for dep in $deps_cleaned; do
    if ! [[ "$dep" =~ ^[0-9]+$ ]]; then
      echo "  ERROR: Phase $phase_num has invalid dependency: $dep (must be numeric)" >&2
      return 1
    fi
  done

  echo "  INFO: Phase $phase_num has valid dependencies: [$deps_cleaned]"
  return 0
}

validate_lean_file() {
  local value="$1"
  local phase_num="$2"

  # Must be absolute path (starting with /)
  if [[ "$value" =~ ^/ ]]; then
    echo "  INFO: Phase $phase_num has valid lean_file path: $value"
    return 0
  else
    echo "  ERROR: Phase $phase_num has invalid lean_file path: $value (must be absolute path)" >&2
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# PHASE EXTRACTION AND VALIDATION
# ═══════════════════════════════════════════════════════════════════════════

echo "Validating phase-level metadata in: $(basename "$PLAN_FILE")"
echo ""

# Extract phases and their metadata
# Look for phase headings (### Phase N:) and following metadata lines
phase_num=0
while IFS= read -r line; do
  # Detect phase heading
  if [[ "$line" =~ ^###[[:space:]]+Phase[[:space:]]+([0-9]+): ]]; then
    phase_num="${BASH_REMATCH[1]}"
    continue
  fi

  # Skip if not in a phase
  [ "$phase_num" -eq 0 ] && continue

  # Extract implementer field
  if [[ "$line" =~ ^implementer:[[:space:]]*(.*) ]]; then
    PHASES_WITH_METADATA=$((PHASES_WITH_METADATA + 1))
    implementer_value="${BASH_REMATCH[1]}"
    if ! validate_implementer "$implementer_value" "$phase_num"; then
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
  fi

  # Extract dependencies field
  if [[ "$line" =~ ^dependencies:[[:space:]]*(.*) ]]; then
    deps_value="${BASH_REMATCH[1]}"
    if ! validate_dependencies "$deps_value" "$phase_num"; then
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
  fi

  # Extract lean_file field
  if [[ "$line" =~ ^lean_file:[[:space:]]*(.*) ]]; then
    lean_file_value="${BASH_REMATCH[1]}"
    if ! validate_lean_file "$lean_file_value" "$phase_num"; then
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
  fi

  # Reset phase context when reaching next phase or end of metadata section
  if [[ "$line" =~ ^(###|##[^#]|Tasks:|Objective:) ]]; then
    phase_num=0
  fi
done < "$PLAN_FILE"

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo ""
if [ $VALIDATION_ERRORS -eq 0 ]; then
  if [ $PHASES_WITH_METADATA -gt 0 ]; then
    echo "✓ Phase metadata validation passed ($PHASES_WITH_METADATA phases with metadata)"
  else
    echo "INFO: No phase-level metadata found (optional fields)"
  fi
  exit 0
else
  echo "✗ Phase metadata validation failed: $VALIDATION_ERRORS errors" >&2
  exit 1
fi

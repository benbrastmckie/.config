#!/usr/bin/env bash
# validate-plan-metadata.sh - Validate plan metadata compliance with canonical standard
#
# PURPOSE:
#   Validates plan files conform to plan-metadata-standard.md requirements.
#   Checks required fields, field formats, and optional recommended fields.
#
# USAGE:
#   bash validate-plan-metadata.sh <plan-file>
#
# EXIT CODES:
#   0 - Validation passed (all required fields present and valid)
#   1 - Validation failed (missing required fields or format errors)
#
# OUTPUT:
#   ERROR messages for missing required fields (blocks commits)
#   WARNING messages for format issues (informational)
#   INFO messages for missing optional recommended fields
#
# VALIDATION RULES:
#   Required Fields (ERROR if missing):
#     - Date: YYYY-MM-DD or YYYY-MM-DD (Revised)
#     - Feature: One-line description
#     - Status: [NOT STARTED], [IN PROGRESS], [COMPLETE], or [BLOCKED]
#     - Estimated Hours: {low}-{high} hours
#     - Standards File: /absolute/path/to/CLAUDE.md
#     - Research Reports: Markdown links with relative paths or 'none'
#
#   Optional Fields (INFO if missing):
#     - Scope: Multi-line scope description
#     - Complexity Score: Numeric complexity value
#     - Structure Level: 0, 1, or 2
#     - Estimated Phases: Phase count estimate
#
# INTEGRATION:
#   - Called by pre-commit hook for staged plan files
#   - Called by validate-all-standards.sh --plans
#   - Called by plan-architect agent (STEP 3 self-validation)

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
# METADATA EXTRACTION
# ═══════════════════════════════════════════════════════════════════════════

# Extract metadata section from plan file
# Returns content between "## Metadata" and next "##" heading
extract_metadata_section() {
  awk '
    /^## Metadata/ {
      in_metadata = 1
      next
    }
    /^##/ && in_metadata {
      exit
    }
    in_metadata {
      print
    }
  ' "$PLAN_FILE"
}

# Extract value for specific metadata field
# Usage: extract_field "Date"
extract_field() {
  local field="$1"
  local metadata="$2"

  echo "$metadata" | grep "^- \*\*${field}\*\*:" | sed "s/^- \*\*${field}\*\*: *//" || true
}

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

validate_date_format() {
  local date="$1"

  # Match YYYY-MM-DD or YYYY-MM-DD (Revised)
  if [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}( \(Revised\))?$ ]]; then
    return 0
  else
    return 1
  fi
}

validate_status_format() {
  local status="$1"

  # Match bracket notation with approved statuses
  if [[ "$status" =~ ^\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]$ ]]; then
    return 0
  else
    return 1
  fi
}

validate_estimated_hours_format() {
  local hours="$1"

  # Match {low}-{high} hours with optional revision note
  if [[ "$hours" =~ ^[0-9]+-[0-9]+\ hours ]]; then
    return 0
  else
    return 1
  fi
}

validate_standards_file_format() {
  local path="$1"

  # Must be absolute path (starts with /)
  if [[ "$path" =~ ^/ ]]; then
    return 0
  else
    return 1
  fi
}

validate_research_reports_format() {
  local reports="$1"

  # Accept literal "none" or markdown links with relative paths
  if [ "$reports" = "none" ]; then
    return 0
  fi

  # Check if contains markdown link pattern with relative path
  if [[ "$reports" =~ \[.*\]\(\.\./.*\.md\) ]] || [[ "$reports" =~ \[.*\]\(\.\./.*\.md\) ]]; then
    return 0
  fi

  # If not "none" and no links found, it's invalid
  return 1
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN VALIDATION LOGIC
# ═══════════════════════════════════════════════════════════════════════════

METADATA=$(extract_metadata_section)

if [ -z "$METADATA" ]; then
  echo "ERROR: No ## Metadata section found in plan file" >&2
  exit 1
fi

# Track validation status
ERRORS=0
WARNINGS=0
INFOS=0

# ═══ REQUIRED FIELDS VALIDATION ═══

# 1. Date
DATE=$(extract_field "Date" "$METADATA")
if [ -z "$DATE" ]; then
  echo "ERROR: Required field 'Date' is missing" >&2
  ((ERRORS++))
elif ! validate_date_format "$DATE"; then
  echo "WARNING: Date format should be YYYY-MM-DD or YYYY-MM-DD (Revised): $DATE" >&2
  ((WARNINGS++))
fi

# 2. Feature
FEATURE=$(extract_field "Feature" "$METADATA")
if [ -z "$FEATURE" ]; then
  echo "ERROR: Required field 'Feature' is missing" >&2
  ((ERRORS++))
fi

# 3. Status
STATUS=$(extract_field "Status" "$METADATA")
if [ -z "$STATUS" ]; then
  echo "ERROR: Required field 'Status' is missing" >&2
  ((ERRORS++))
elif ! validate_status_format "$STATUS"; then
  echo "WARNING: Status format should be [NOT STARTED], [IN PROGRESS], [COMPLETE], or [BLOCKED]: $STATUS" >&2
  ((WARNINGS++))
fi

# 4. Estimated Hours
ESTIMATED_HOURS=$(extract_field "Estimated Hours" "$METADATA")
if [ -z "$ESTIMATED_HOURS" ]; then
  echo "ERROR: Required field 'Estimated Hours' is missing" >&2
  ((ERRORS++))
elif ! validate_estimated_hours_format "$ESTIMATED_HOURS"; then
  echo "WARNING: Estimated Hours format should be '{low}-{high} hours': $ESTIMATED_HOURS" >&2
  ((WARNINGS++))
fi

# 5. Standards File
STANDARDS_FILE=$(extract_field "Standards File" "$METADATA")
if [ -z "$STANDARDS_FILE" ]; then
  echo "ERROR: Required field 'Standards File' is missing" >&2
  ((ERRORS++))
elif ! validate_standards_file_format "$STANDARDS_FILE"; then
  echo "ERROR: Standards File must be absolute path (starts with /): $STANDARDS_FILE" >&2
  ((ERRORS++))
fi

# 6. Research Reports
# Check if Research Reports field exists (inline or multi-line)
RESEARCH_REPORTS_LINE=$(echo "$METADATA" | grep "^\- \*\*Research Reports\*\*:")
if [ -z "$RESEARCH_REPORTS_LINE" ]; then
  echo "ERROR: Required field 'Research Reports' is missing" >&2
  ((ERRORS++))
else
  # Extract inline value or first multi-line entry
  RESEARCH_REPORTS=$(extract_field "Research Reports" "$METADATA")

  # If no inline value, check for multi-line entries
  if [ -z "$RESEARCH_REPORTS" ]; then
    RESEARCH_REPORTS=$(awk '
      /^\- \*\*Research Reports\*\*:/ {
        in_reports = 1
        next
      }
      /^\- \*\*[^*]+\*\*:/ && in_reports {
        exit
      }
      in_reports && /^  \-/ {
        print
        found = 1
        exit
      }
    ' "$PLAN_FILE")
  fi

  # Validate format if value exists
  if [ -n "$RESEARCH_REPORTS" ]; then
    if ! validate_research_reports_format "$RESEARCH_REPORTS"; then
      echo "WARNING: Research Reports should use relative paths with markdown links or literal 'none'" >&2
      ((WARNINGS++))
    fi
  else
    # Field exists but no value (could be empty list)
    echo "WARNING: Research Reports field exists but has no value" >&2
    ((WARNINGS++))
  fi
fi

# ═══ OPTIONAL FIELDS VALIDATION ═══

# Check for recommended optional fields (INFO level)
SCOPE=$(extract_field "Scope" "$METADATA")
COMPLEXITY=$(extract_field "Complexity Score" "$METADATA")
STRUCTURE_LEVEL=$(extract_field "Structure Level" "$METADATA")

if [ -z "$COMPLEXITY" ]; then
  echo "INFO: Optional field 'Complexity Score' is missing (recommended for tracking)" >&2
  ((INFOS++))
fi

if [ -z "$STRUCTURE_LEVEL" ]; then
  echo "INFO: Optional field 'Structure Level' is missing (recommended for plan organization tracking)" >&2
  ((INFOS++))
fi

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION RESULT
# ═══════════════════════════════════════════════════════════════════════════

if [ $ERRORS -gt 0 ]; then
  echo "" >&2
  echo "VALIDATION FAILED: $ERRORS error(s), $WARNINGS warning(s), $INFOS info message(s)" >&2
  exit 1
else
  if [ $WARNINGS -gt 0 ] || [ $INFOS -gt 0 ]; then
    echo "" >&2
    echo "VALIDATION PASSED with $WARNINGS warning(s), $INFOS info message(s)" >&2
  fi
  exit 0
fi

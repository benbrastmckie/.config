#!/usr/bin/env bash
# validate-plan.sh - Plan validation library for /plan command
#
# This library provides comprehensive plan validation against project standards,
# checking metadata completeness, standards compliance, test phases, documentation
# tasks, and phase dependencies.
#
# Source guard: Prevent multiple sourcing
if [ -n "${VALIDATE_PLAN_SOURCED:-}" ]; then
  return 0
fi
export VALIDATE_PLAN_SOURCED=1
#
# Functions:
#   validate_metadata() - Check 8 required metadata fields
#   validate_standards_compliance() - Verify CLAUDE.md references
#   validate_test_phases() - Check test phase presence
#   validate_documentation_tasks() - Check documentation tasks
#   validate_phase_dependencies() - Check for circular dependencies
#   generate_validation_report() - Generate JSON validation report
#   validate_plan() - Main validation entry point
#
# Usage:
#   source .claude/lib/validate-plan.sh
#   REPORT=$(validate_plan "$PLAN_PATH" "$STANDARDS_FILE")
#   echo "$REPORT" | jq -r '.errors | length'
#
# Return Codes:
#   0 - Success (validation complete, check report for errors/warnings)
#   1 - Failure (validation could not be performed)

set -eo pipefail

# ==============================================================================
# Metadata Validation
# ==============================================================================

# validate_metadata - Check 8 required metadata fields
#
# Required fields:
#   1. Date
#   2. Feature
#   3. Scope
#   4. Estimated Phases (or Phases)
#   5. Estimated Hours (or Hours)
#   6. Structure Level
#   7. Complexity Score (or Complexity)
#   8. Standards File
#
# Parameters:
#   $1 - plan_path: Path to plan file
#
# Returns:
#   0 - All required fields present
#   1 - Missing required fields (outputs JSON with missing fields)
validate_metadata() {
  local plan_path="$1"

  if [ ! -f "$plan_path" ]; then
    echo '{"valid": false, "missing": ["file_not_found"]}'
    return 1
  fi

  local missing_fields=()

  # Check for Date
  if ! grep -q "^- \*\*Date\*\*:" "$plan_path"; then
    missing_fields+=("Date")
  fi

  # Check for Feature
  if ! grep -q "^- \*\*Feature\*\*:" "$plan_path"; then
    missing_fields+=("Feature")
  fi

  # Check for Scope
  if ! grep -q "^- \*\*Scope\*\*:" "$plan_path"; then
    missing_fields+=("Scope")
  fi

  # Check for Phases (allow variants)
  if ! grep -qE "^- \*\*(Estimated )?Phases\*\*:" "$plan_path"; then
    missing_fields+=("Phases")
  fi

  # Check for Hours (allow variants)
  if ! grep -qE "^- \*\*(Estimated )?Hours\*\*:" "$plan_path"; then
    missing_fields+=("Hours")
  fi

  # Check for Structure Level
  if ! grep -q "^- \*\*Structure Level\*\*:" "$plan_path"; then
    missing_fields+=("Structure Level")
  fi

  # Check for Complexity (allow variants)
  if ! grep -qE "^- \*\*Complexity( Score)?\*\*:" "$plan_path"; then
    missing_fields+=("Complexity")
  fi

  # Check for Standards File
  if ! grep -q "^- \*\*Standards File\*\*:" "$plan_path"; then
    missing_fields+=("Standards File")
  fi

  # Generate result JSON
  if [ ${#missing_fields[@]} -eq 0 ]; then
    echo '{"valid": true, "missing": []}'
    return 0
  else
    local missing_json=$(printf '%s\n' "${missing_fields[@]}" | jq -R . | jq -s .)
    echo "{\"valid\": false, \"missing\": $missing_json}"
    return 1
  fi
}

# ==============================================================================
# Standards Compliance Validation
# ==============================================================================

# validate_standards_compliance - Verify CLAUDE.md path and Standard N references
#
# Checks:
#   1. CLAUDE.md path referenced in metadata
#   2. At least one Standard N reference in plan body
#   3. Standards File path exists
#
# Parameters:
#   $1 - plan_path: Path to plan file
#
# Returns:
#   0 - Standards compliance verified
#   1 - Compliance issues found
validate_standards_compliance() {
  local plan_path="$1"

  if [ ! -f "$plan_path" ]; then
    echo '{"valid": false, "issues": ["file_not_found"]}'
    return 1
  fi

  local issues=()

  # Check for CLAUDE.md reference
  if ! grep -q "CLAUDE.md" "$plan_path"; then
    issues+=("No CLAUDE.md reference found")
  fi

  # Check for Standards File field
  local standards_file=$(grep "^- \*\*Standards File\*\*:" "$plan_path" | head -1 | sed 's/^- \*\*Standards File\*\*: *//')

  if [ -n "$standards_file" ]; then
    # Verify file exists
    if [ ! -f "$standards_file" ]; then
      issues+=("Standards file does not exist: $standards_file")
    fi
  fi

  # Check for Standard N references (optional but recommended)
  if ! grep -qE "Standard [0-9]+" "$plan_path"; then
    issues+=("No Standard N references found (recommended for design rationale)")
  fi

  # Generate result JSON
  if [ ${#issues[@]} -eq 0 ]; then
    echo '{"valid": true, "issues": []}'
    return 0
  else
    local issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
    echo "{\"valid\": false, \"issues\": $issues_json}"
    return 1
  fi
}

# ==============================================================================
# Test Phase Validation
# ==============================================================================

# validate_test_phases - Check test phases exist if Testing Protocols defined
#
# Parameters:
#   $1 - plan_path: Path to plan file
#   $2 - standards_file: Path to CLAUDE.md (optional)
#
# Returns:
#   0 - Test phases present or not required
#   1 - Test phases missing when required
validate_test_phases() {
  local plan_path="$1"
  local standards_file="${2:-}"

  if [ ! -f "$plan_path" ]; then
    echo '{"valid": false, "issues": ["file_not_found"]}'
    return 1
  fi

  # If no standards file, skip test validation
  if [ -z "$standards_file" ] || [ ! -f "$standards_file" ]; then
    echo '{"valid": true, "issues": [], "skipped": "No standards file"}'
    return 0
  fi

  # Check if Testing Protocols defined in standards
  if ! grep -q "## Testing Protocols" "$standards_file"; then
    echo '{"valid": true, "issues": [], "skipped": "No testing protocols in standards"}'
    return 0
  fi

  local issues=()

  # Check for test-related content in plan
  if ! grep -qiE "test|testing|coverage" "$plan_path"; then
    issues+=("No test phases found but Testing Protocols defined in CLAUDE.md")
  fi

  # Check for test tasks
  if ! grep -qiE "- \[ \].*test" "$plan_path"; then
    issues+=("No test tasks found (≥80% coverage requirement recommended)")
  fi

  # Generate result JSON
  if [ ${#issues[@]} -eq 0 ]; then
    echo '{"valid": true, "issues": []}'
    return 0
  else
    local issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
    echo "{\"valid\": false, \"issues\": $issues_json}"
    return 1
  fi
}

# ==============================================================================
# Documentation Tasks Validation
# ==============================================================================

# validate_documentation_tasks - Check documentation tasks if policy defined
#
# Parameters:
#   $1 - plan_path: Path to plan file
#   $2 - standards_file: Path to CLAUDE.md (optional)
#
# Returns:
#   0 - Documentation tasks present or not required
#   1 - Documentation tasks missing when required
validate_documentation_tasks() {
  local plan_path="$1"
  local standards_file="${2:-}"

  if [ ! -f "$plan_path" ]; then
    echo '{"valid": false, "issues": ["file_not_found"]}'
    return 1
  fi

  # If no standards file, skip documentation validation
  if [ -z "$standards_file" ] || [ ! -f "$standards_file" ]; then
    echo '{"valid": true, "issues": [], "skipped": "No standards file"}'
    return 0
  fi

  # Check if Documentation Policy defined in standards
  if ! grep -q "## Documentation Policy" "$standards_file"; then
    echo '{"valid": true, "issues": [], "skipped": "No documentation policy in standards"}'
    return 0
  fi

  local issues=()

  # Check for documentation-related content
  if ! grep -qiE "document|documentation|readme|docs" "$plan_path"; then
    issues+=("No documentation tasks found but Documentation Policy defined in CLAUDE.md")
  fi

  # Generate result JSON
  if [ ${#issues[@]} -eq 0 ]; then
    echo '{"valid": true, "issues": []}'
    return 0
  else
    local issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
    echo "{\"valid\": false, \"issues\": $issues_json}"
    return 1
  fi
}

# ==============================================================================
# Phase Dependency Validation (Kahn's Algorithm for Cycle Detection)
# ==============================================================================

# validate_phase_dependencies - Check for circular dependencies, forward refs, self-deps
#
# Uses simplified topological sort to detect cycles
#
# Parameters:
#   $1 - plan_path: Path to plan file
#
# Returns:
#   0 - No dependency issues
#   1 - Circular dependencies or invalid references found
validate_phase_dependencies() {
  local plan_path="$1"

  if [ ! -f "$plan_path" ]; then
    echo '{"valid": false, "issues": ["file_not_found"]}'
    return 1
  fi

  local issues=()

  # Extract phase dependencies (format: "dependencies: [0, 1, 2]")
  local phase_num=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^###\ Phase\ ([0-9]+): ]]; then
      phase_num="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^dependencies:\ \[(.*)\] ]]; then
      local deps="${BASH_REMATCH[1]}"

      # Check for self-dependency
      if [[ ",$deps," == *",$phase_num,"* ]]; then
        issues+=("Phase $phase_num has self-dependency")
      fi

      # Check for forward references
      IFS=',' read -ra dep_array <<< "$deps"
      for dep in "${dep_array[@]}"; do
        dep=$(echo "$dep" | tr -d ' ')
        if [ -n "$dep" ] && [ "$dep" -ge "$phase_num" ]; then
          issues+=("Phase $phase_num references forward/equal phase: $dep")
        fi
      done
    fi
  done < "$plan_path"

  # Note: Full cycle detection would require building dependency graph
  # This simplified version catches self-deps and forward refs which are most common

  # Generate result JSON
  if [ ${#issues[@]} -eq 0 ]; then
    echo '{"valid": true, "issues": []}'
    return 0
  else
    local issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
    echo "{\"valid\": false, \"issues\": $issues_json}"
    return 1
  fi
}

# ==============================================================================
# Main Validation Entry Point
# ==============================================================================

# generate_validation_report - Generate comprehensive JSON validation report
#
# Parameters:
#   $1 - plan_path: Path to plan file
#   $2 - standards_file: Path to CLAUDE.md (optional)
#
# Returns:
#   JSON report with categorized warnings/errors, severity levels, fix suggestions
generate_validation_report() {
  local plan_path="$1"
  local standards_file="${2:-}"

  if [ ! -f "$plan_path" ]; then
    echo '{"error": "Plan file not found", "path": "'"$plan_path"'"}'
    return 1
  fi

  # Run all validations
  local metadata_result=$(validate_metadata "$plan_path")
  local standards_result=$(validate_standards_compliance "$plan_path")
  local test_result=$(validate_test_phases "$plan_path" "$standards_file")
  local docs_result=$(validate_documentation_tasks "$plan_path" "$standards_file")
  local deps_result=$(validate_phase_dependencies "$plan_path")

  # Combine results
  local report=$(jq -n \
    --argjson metadata "$metadata_result" \
    --argjson standards "$standards_result" \
    --argjson tests "$test_result" \
    --argjson docs "$docs_result" \
    --argjson deps "$deps_result" \
    '{
      metadata: $metadata,
      standards: $standards,
      tests: $tests,
      documentation: $docs,
      dependencies: $deps,
      summary: {
        errors: (
          (if $metadata.valid == false then ($metadata.missing | length) else 0 end) +
          (if $deps.valid == false then ($deps.issues | length) else 0 end)
        ),
        warnings: (
          (if $standards.valid == false then ($standards.issues | length) else 0 end) +
          (if $tests.valid == false then ($tests.issues | length) else 0 end) +
          (if $docs.valid == false then ($docs.issues | length) else 0 end)
        )
      }
    }')

  echo "$report"
  return 0
}

# validate_plan - Main validation entry point
#
# Runs all validations and returns comprehensive report
#
# Parameters:
#   $1 - plan_path: Path to plan file
#   $2 - standards_file: Path to CLAUDE.md (optional)
#
# Returns:
#   0 - Validation complete (check report for errors/warnings)
#   1 - Validation failed to run
validate_plan() {
  local plan_path="$1"
  local standards_file="${2:-}"

  generate_validation_report "$plan_path" "$standards_file"
  return $?
}

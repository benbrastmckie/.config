#!/usr/bin/env bash
# validate_executable_doc_separation.sh - Validate Standard 14 compliance
#
# Purpose:
#   Verify separation of executable code and documentation per Standard 14.
#   Checks for guide file existence, cross-references, line count trends,
#   and content duplication.
#
# Usage:
#   validate_executable_doc_separation.sh <command-file-path>
#
# Arguments:
#   command-file-path: Absolute path to command file (e.g., .claude/commands/plan.md)
#
# Exit Codes:
#   0: All validation checks passed
#   1: One or more validation checks failed
#   2: Usage error (missing arguments, file not found)
#
# Output:
#   JSON compliance report with detailed validation results
#
# Examples:
#   # Validate plan command
#   validate_executable_doc_separation.sh .claude/commands/plan.md
#
#   # CI/CD integration
#   if ! validate_executable_doc_separation.sh .claude/commands/plan.md; then
#     echo "Standard 14 compliance failed"
#     exit 1
#   fi
#
# Integration with CI/CD:
#   Add to pre-commit hooks or GitHub Actions workflow:
#   - name: Validate Standard 14 Compliance
#     run: bash .claude/lib/validate_executable_doc_separation.sh .claude/commands/plan.md

set -euo pipefail

# Configuration
BASELINE_LINE_COUNT=985  # Original plan.md line count before Phase 1
MIN_CROSS_REFS=3         # Minimum cross-references each direction
MIN_GUIDE_SIZE=1000      # Minimum guide file size in bytes

# Colors for output (if terminal supports)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# Validation results
VALIDATION_RESULTS=()
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Usage
usage() {
  cat <<EOF
Usage: $(basename "$0") <command-file-path>

Validate Standard 14 compliance (executable/documentation separation).

Arguments:
  command-file-path  Absolute path to command file

Exit Codes:
  0  All validation checks passed
  1  One or more validation checks failed
  2  Usage error

Example:
  $(basename "$0") .claude/commands/plan.md
EOF
  exit 2
}

# Logging helpers
log_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
}

log_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
}

log_info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Record validation result
record_result() {
  local check_name="$1"
  local status="$2"  # "pass" or "fail"
  local message="$3"
  local details="${4:-}"

  ((TOTAL_CHECKS++))

  if [[ "$status" == "pass" ]]; then
    ((PASSED_CHECKS++))
    log_pass "$check_name: $message"
  else
    ((FAILED_CHECKS++))
    log_fail "$check_name: $message"
  fi

  # Store for JSON report
  VALIDATION_RESULTS+=("$(cat <<EOF
{
  "check": "$check_name",
  "status": "$status",
  "message": "$message",
  "details": "$details"
}
EOF
  )")
}

# Validation Function 1: validate_line_count
validate_line_count() {
  local command_file="$1"

  if [[ ! -f "$command_file" ]]; then
    record_result "validate_line_count" "fail" "Command file not found" "$command_file"
    return 1
  fi

  # Count total lines
  local total_lines=$(wc -l < "$command_file")

  # Count non-blank lines
  local non_blank_lines=$(grep -cvE '^\s*$' "$command_file" || echo "0")

  # Calculate reduction from baseline
  local reduction=$((BASELINE_LINE_COUNT - total_lines))
  local reduction_pct=0
  if [[ $BASELINE_LINE_COUNT -gt 0 ]]; then
    reduction_pct=$(( (reduction * 100) / BASELINE_LINE_COUNT ))
  fi

  # Trend analysis
  local trend="unchanged"
  if [[ $total_lines -lt $BASELINE_LINE_COUNT ]]; then
    trend="reduced"
  elif [[ $total_lines -gt $BASELINE_LINE_COUNT ]]; then
    trend="increased"
  fi

  # Report (informational, not pass/fail)
  local details="Lines: $total_lines (non-blank: $non_blank_lines), Baseline: $BASELINE_LINE_COUNT, Reduction: $reduction_pct%, Trend: $trend"

  record_result "validate_line_count" "pass" "$details" ""

  log_info "Line Count Analysis:"
  log_info "  Total lines: $total_lines"
  log_info "  Non-blank lines: $non_blank_lines"
  log_info "  Baseline (before Phase 1): $BASELINE_LINE_COUNT"
  log_info "  Reduction: $reduction lines ($reduction_pct%)"
  log_info "  Trend: $trend"

  return 0
}

# Validation Function 2: validate_guide_exists
validate_guide_exists() {
  local command_file="$1"

  # Auto-detect guide file path
  local command_dir=$(dirname "$command_file")
  local command_name=$(basename "$command_file" .md)
  local guide_file="$(dirname "$command_dir")/docs/guides/${command_name}-command-guide.md"

  if [[ ! -f "$guide_file" ]]; then
    record_result "validate_guide_exists" "fail" "Guide file not found" "$guide_file"
    return 1
  fi

  # Check file size
  local file_size=$(wc -c < "$guide_file")

  if [[ $file_size -lt $MIN_GUIDE_SIZE ]]; then
    record_result "validate_guide_exists" "fail" "Guide file too small ($file_size < $MIN_GUIDE_SIZE bytes)" "$guide_file"
    return 1
  fi

  record_result "validate_guide_exists" "pass" "Guide file exists and sufficient ($file_size bytes)" "$guide_file"
  return 0
}

# Validation Function 3: validate_cross_references
validate_cross_references() {
  local command_file="$1"

  # Auto-detect guide file path
  local command_dir=$(dirname "$command_file")
  local command_name=$(basename "$command_file" .md)
  local guide_file="$(dirname "$command_dir")/docs/guides/${command_name}-command-guide.md"

  if [[ ! -f "$guide_file" ]]; then
    record_result "validate_cross_references" "fail" "Guide file not found for cross-reference check" "$guide_file"
    return 1
  fi

  # Count command → guide references
  local cmd_to_guide=$(grep -c "${command_name}-command-guide" "$command_file" 2>/dev/null || echo "0")

  # Count guide → command references
  local guide_to_cmd=$(grep -c "${command_name}\.md" "$guide_file" 2>/dev/null || echo "0")

  # Check threshold
  if [[ $cmd_to_guide -lt $MIN_CROSS_REFS ]] || [[ $guide_to_cmd -lt $MIN_CROSS_REFS ]]; then
    local details="Command → Guide: $cmd_to_guide, Guide → Command: $guide_to_cmd (threshold: ≥$MIN_CROSS_REFS each)"
    record_result "validate_cross_references" "fail" "Insufficient cross-references" "$details"
    return 1
  fi

  local details="Command → Guide: $cmd_to_guide, Guide → Command: $guide_to_cmd"
  record_result "validate_cross_references" "pass" "Cross-references sufficient" "$details"

  log_info "Cross-Reference Analysis:"
  log_info "  Command → Guide: $cmd_to_guide references"
  log_info "  Guide → Command: $guide_to_cmd references"
  log_info "  Threshold: ≥$MIN_CROSS_REFS each direction"

  return 0
}

# Validation Function 4: validate_no_duplication
validate_no_duplication() {
  local command_file="$1"

  # Auto-detect guide file path
  local command_dir=$(dirname "$command_file")
  local command_name=$(basename "$command_file" .md)
  local guide_file="$(dirname "$command_dir")/docs/guides/${command_name}-command-guide.md"

  if [[ ! -f "$guide_file" ]]; then
    record_result "validate_no_duplication" "fail" "Guide file not found for duplication check" "$guide_file"
    return 1
  fi

  # Note: This check is informational. Educational code examples in the guide
  # may legitimately duplicate small portions of command logic for illustration.
  # Only flag complete execution blocks (>50 lines) as problematic duplication.

  # Extract bash code blocks from guide (>50 lines for significant duplication)
  local temp_dir="/tmp/validate_dup_$$"
  mkdir -p "$temp_dir"

  local in_bash=false
  local block_num=0
  local line_count=0
  local current_block="$temp_dir/block_$block_num.sh"

  while IFS= read -r line; do
    if [[ "$line" =~ ^\`\`\`bash ]]; then
      in_bash=true
      line_count=0
      current_block="$temp_dir/block_$block_num.sh"
      > "$current_block"
    elif [[ "$line" =~ ^\`\`\` ]] && [[ "$in_bash" == true ]]; then
      in_bash=false
      # Only keep blocks >50 lines (large execution blocks)
      if [[ $line_count -le 50 ]]; then
        rm -f "$current_block"
      else
        ((block_num++))
      fi
    elif [[ "$in_bash" == true ]]; then
      echo "$line" >> "$current_block"
      ((line_count++))
    fi
  done < "$guide_file"

  # Check each large block for duplication in command file
  local duplicated_blocks=0
  for block in "$temp_dir"/block_*.sh; do
    if [[ -f "$block" ]]; then
      local block_content=$(cat "$block")
      if grep -Fq "$block_content" "$command_file"; then
        ((duplicated_blocks++))
      fi
    fi
  done

  # Cleanup
  rm -rf "$temp_dir"

  # Report but don't fail (informational)
  if [[ $duplicated_blocks -gt 0 ]]; then
    local details="Found $duplicated_blocks large blocks (>50 lines). Note: Small educational examples are acceptable."
    record_result "validate_no_duplication" "pass" "$details" ""
    log_info "Duplication Analysis:"
    log_info "  Large duplicated blocks (>50 lines): $duplicated_blocks"
    log_info "  Note: Educational examples <50 lines are acceptable"
  else
    record_result "validate_no_duplication" "pass" "No significant code duplication found" ""
  fi

  return 0
}

# Validation Function 5: generate_compliance_report
generate_compliance_report() {
  local command_file="$1"

  echo ""
  echo "========================================="
  echo " Standard 14 Compliance Report"
  echo "========================================="
  echo ""
  echo "Command File: $command_file"
  echo ""
  echo "Validation Results:"
  echo "  Total Checks: $TOTAL_CHECKS"
  echo "  Passed: $PASSED_CHECKS"
  echo "  Failed: $FAILED_CHECKS"
  echo ""

  # Generate JSON report
  local json_results="["
  local first=true
  for result in "${VALIDATION_RESULTS[@]}"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      json_results+=","
    fi
    json_results+="$result"
  done
  json_results+="]"

  local overall_status="pass"
  if [[ $FAILED_CHECKS -gt 0 ]]; then
    overall_status="fail"
  fi

  local json_report=$(cat <<EOF
{
  "command_file": "$command_file",
  "timestamp": "$(date -Iseconds)",
  "overall_status": "$overall_status",
  "total_checks": $TOTAL_CHECKS,
  "passed_checks": $PASSED_CHECKS,
  "failed_checks": $FAILED_CHECKS,
  "validation_results": $json_results
}
EOF
  )

  echo "$json_report" | jq '.' 2>/dev/null || echo "$json_report"

  echo ""
  echo "========================================="
  if [[ "$overall_status" == "pass" ]]; then
    echo -e "${GREEN}Overall Status: PASS${NC}"
  else
    echo -e "${RED}Overall Status: FAIL${NC}"
  fi
  echo "========================================="
  echo ""

  if [[ "$overall_status" == "pass" ]]; then
    return 0
  else
    return 1
  fi
}

# Main validation entry point
main() {
  # Argument validation
  if [[ $# -eq 0 ]]; then
    echo "Error: Missing required argument <command-file-path>"
    echo ""
    usage
  fi

  local command_file="$1"

  # Validate file exists
  if [[ ! -f "$command_file" ]]; then
    echo "Error: Command file not found: $command_file"
    exit 2
  fi

  # Validate absolute path
  if [[ "$command_file" != /* ]]; then
    echo "Error: Command file path must be absolute: $command_file"
    exit 2
  fi

  echo ""
  echo "Validating Standard 14 Compliance..."
  echo "Command file: $command_file"
  echo ""

  # Run all validation functions
  validate_line_count "$command_file" || true
  validate_guide_exists "$command_file" || true
  validate_cross_references "$command_file" || true
  validate_no_duplication "$command_file" || true

  # Generate compliance report
  if generate_compliance_report "$command_file"; then
    exit 0
  else
    exit 1
  fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

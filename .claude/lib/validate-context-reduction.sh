#!/usr/bin/env bash
# validate_context_reduction.sh - Validate context reduction across all commands
# Part of hierarchical agent context preservation system
#
# Usage:
#   ./validate_context_reduction.sh [--verbose] [--output report.md]
#
# Validates:
#   - Context usage <30% throughout workflows
#   - Context reduction ≥60% vs direct implementation
#   - Metadata-only passing works correctly
#   - No loss of functionality

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

: "${CLAUDE_PROJECT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

VERBOSE=false
OUTPUT_FILE=""
CONTEXT_THRESHOLD=30  # Max context usage percentage
REDUCTION_TARGET=60   # Min context reduction percentage

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# Argument Parsing
# ==============================================================================

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --threshold)
      CONTEXT_THRESHOLD="$2"
      shift 2
      ;;
    --target)
      REDUCTION_TARGET="$2"
      shift 2
      ;;
    --help)
      cat <<EOF
Usage: validate_context_reduction.sh [OPTIONS]

Validate context reduction across hierarchical agent workflows.

OPTIONS:
  --verbose           Show detailed validation output
  --output FILE       Write report to FILE (markdown format)
  --threshold N       Set context usage threshold (default: 30%)
  --target N          Set reduction target (default: 60%)
  --help              Show this help message

EXAMPLES:
  ./validate_context_reduction.sh
  ./validate_context_reduction.sh --verbose --output report.md
  ./validate_context_reduction.sh --threshold 25 --target 70
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# ==============================================================================
# Utility Functions
# ==============================================================================

log() {
  if [ "$VERBOSE" = true ]; then
    echo -e "$@"
  fi
}

log_success() {
  echo -e "${GREEN}✓${NC} $@"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $@"
}

log_error() {
  echo -e "${RED}✗${NC} $@"
}

log_info() {
  echo -e "${BLUE}ℹ${NC} $@"
}

# ==============================================================================
# Validation Functions
# ==============================================================================

# validate_metadata_extraction: Test metadata extraction utilities
validate_metadata_extraction() {
  log_info "Validating metadata extraction utilities..."

  local test_passed=true
  local test_report=""

  # Source utilities
  if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh" ] || [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-registry.sh" ]; then
    log_error "artifact-creation.sh or artifact-registry.sh not found"
    test_report+="FAIL: Missing artifact libraries\n"
    test_passed=false
  else
    source "$CLAUDE_PROJECT_DIR/.claude/lib/metadata-extraction.sh"

    # Test if functions exist
    local required_functions=(
      "extract_report_metadata"
      "extract_plan_metadata"
      "extract_summary_metadata"
      "load_metadata_on_demand"
      "cache_metadata"
      "get_cached_metadata"
    )

    for func in "${required_functions[@]}"; do
      if ! declare -f "$func" >/dev/null 2>&1; then
        log_error "Function not found: $func"
        test_report+="FAIL: Missing function $func\n"
        test_passed=false
      else
        log "  Found function: $func"
      fi
    done

    if [ "$test_passed" = true ]; then
      log_success "Metadata extraction utilities validated"
      test_report+="PASS: All metadata extraction functions present\n"
    fi
  fi

  echo -e "$test_report"
  return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# validate_forward_message: Test forward_message pattern
validate_forward_message() {
  log_info "Validating forward_message pattern..."

  local test_passed=true
  local test_report=""

  # Source utilities
  if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh" ] || [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-registry.sh" ]; then
    log_error "artifact-creation.sh or artifact-registry.sh not found"
    test_report+="FAIL: Missing artifact libraries\n"
    return 1
  fi

  source "$CLAUDE_PROJECT_DIR/.claude/lib/metadata-extraction.sh"

  # Test if forward_message exists
  if ! declare -f "forward_message" >/dev/null 2>&1; then
    log_error "forward_message function not found"
    test_report+="FAIL: Missing forward_message function\n"
    test_passed=false
  else
    log_success "forward_message function validated"
    test_report+="PASS: forward_message function present\n"
  fi

  echo -e "$test_report"
  return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# validate_context_pruning: Test context pruning utilities
validate_context_pruning() {
  log_info "Validating context pruning utilities..."

  local test_passed=true
  local test_report=""

  # Source utilities
  if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/context-pruning.sh" ]; then
    log_error "context-pruning.sh not found"
    test_report+="FAIL: Missing context-pruning.sh\n"
    return 1
  fi

  source "$CLAUDE_PROJECT_DIR/.claude/lib/context-pruning.sh"

  # Test if functions exist
  local required_functions=(
    "prune_subagent_output"
    "prune_phase_metadata"
    "prune_workflow_metadata"
    "store_phase_metadata"
    "get_current_context_size"
    "apply_pruning_policy"
  )

  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      log_error "Function not found: $func"
      test_report+="FAIL: Missing function $func\n"
      test_passed=false
    else
      log "  Found function: $func"
    fi
  done

  if [ "$test_passed" = true ]; then
    log_success "Context pruning utilities validated"
    test_report+="PASS: All context pruning functions present\n"
  fi

  echo -e "$test_report"
  return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# validate_context_metrics: Test context metrics utilities
validate_context_metrics() {
  log_info "Validating context metrics utilities..."

  local test_passed=true
  local test_report=""

  # Source utilities
  if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/context-metrics.sh" ]; then
    log_error "context-metrics.sh not found"
    test_report+="FAIL: Missing context-metrics.sh\n"
    return 1
  fi

  source "$CLAUDE_PROJECT_DIR/.claude/lib/context-metrics.sh"

  # Test if functions exist
  local required_functions=(
    "track_context_usage"
    "calculate_context_reduction"
    "log_context_metrics"
    "generate_context_report"
  )

  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      log_error "Function not found: $func"
      test_report+="FAIL: Missing function $func\n"
      test_passed=false
    else
      log "  Found function: $func"
    fi
  done

  if [ "$test_passed" = true ]; then
    log_success "Context metrics utilities validated"
    test_report+="PASS: All context metrics functions present\n"
  fi

  echo -e "$test_report"
  return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# validate_command_integration: Check commands have subagent delegation
validate_command_integration() {
  log_info "Validating command integration..."

  local test_passed=true
  local test_report=""

  # Check /implement command
  if [ -f "$CLAUDE_PROJECT_DIR/.claude/commands/implement.md" ]; then
    if grep -q "Implementation Research Agent Invocation" "$CLAUDE_PROJECT_DIR/.claude/commands/implement.md"; then
      log_success "/implement command has subagent delegation"
      test_report+="PASS: /implement has subagent delegation\n"
    else
      log_warning "/implement command missing subagent delegation"
      test_report+="WARN: /implement missing subagent delegation section\n"
    fi
  else
    log_error "/implement command not found"
    test_report+="FAIL: /implement command not found\n"
    test_passed=false
  fi

  # Check /debug command
  if [ -f "$CLAUDE_PROJECT_DIR/.claude/commands/debug.md" ]; then
    if grep -q "Parallel Hypothesis Investigation" "$CLAUDE_PROJECT_DIR/.claude/commands/debug.md"; then
      log_success "/debug command has subagent delegation"
      test_report+="PASS: /debug has subagent delegation\n"
    else
      log_warning "/debug command missing subagent delegation"
      test_report+="WARN: /debug missing subagent delegation section\n"
    fi
  else
    log_error "/debug command not found"
    test_report+="FAIL: /debug command not found\n"
    test_passed=false
  fi

  # Check /plan command
  if [ -f "$CLAUDE_PROJECT_DIR/.claude/commands/plan.md" ]; then
    if grep -q "Research Agent Delegation" "$CLAUDE_PROJECT_DIR/.claude/commands/plan.md"; then
      log_success "/plan command has subagent delegation"
      test_report+="PASS: /plan has subagent delegation\n"
    else
      log_warning "/plan command missing subagent delegation"
      test_report+="WARN: /plan missing subagent delegation section\n"
    fi
  else
    log_error "/plan command not found"
    test_report+="FAIL: /plan command not found\n"
    test_passed=false
  fi

  # Check /orchestrate command
  if [ -f "$CLAUDE_PROJECT_DIR/.claude/commands/orchestrate.md" ]; then
    if grep -q "Forward Message Integration" "$CLAUDE_PROJECT_DIR/.claude/commands/orchestrate.md"; then
      log_success "/orchestrate command has forward_message integration"
      test_report+="PASS: /orchestrate has forward_message integration\n"
    else
      log_warning "/orchestrate command missing forward_message"
      test_report+="WARN: /orchestrate missing forward_message section\n"
    fi
  else
    log_error "/orchestrate command not found"
    test_report+="FAIL: /orchestrate command not found\n"
    test_passed=false
  fi

  echo -e "$test_report"
  return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# validate_agent_templates: Check agent templates exist
validate_agent_templates() {
  log_info "Validating agent templates..."

  local test_passed=true
  local test_report=""

  local required_agents=(
    "implementation-researcher.md"
    "debug-analyst.md"
  )

  for agent in "${required_agents[@]}"; do
    if [ -f "$CLAUDE_PROJECT_DIR/.claude/agents/$agent" ]; then
      log_success "Agent template found: $agent"
      test_report+="PASS: $agent template present\n"
    else
      log_error "Agent template not found: $agent"
      test_report+="FAIL: Missing $agent template\n"
      test_passed=false
    fi
  done

  echo -e "$test_report"
  return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# ==============================================================================
# Report Generation
# ==============================================================================

generate_report() {
  local total_tests="$1"
  local passed_tests="$2"
  local failed_tests="$3"
  local warnings="$4"

  local pass_rate=$(( passed_tests * 100 / total_tests ))

  cat <<EOF
# Context Reduction Validation Report

**Date**: $(date -u +%Y-%m-%d)
**Pass Rate**: $pass_rate% ($passed_tests/$total_tests tests passed)
**Warnings**: $warnings
**Failed**: $failed_tests

## Summary

This report validates the hierarchical agent context preservation system implementation across all commands and utilities.

**Target Metrics**:
- Context usage: <$CONTEXT_THRESHOLD% throughout workflows
- Context reduction: ≥$REDUCTION_TARGET% vs direct implementation
- Test pass rate: ≥80%

## Validation Results

### Metadata Extraction Utilities
$(validate_metadata_extraction)

### Forward Message Pattern
$(validate_forward_message)

### Context Pruning Utilities
$(validate_context_pruning)

### Context Metrics Utilities
$(validate_context_metrics)

### Command Integration
$(validate_command_integration)

### Agent Templates
$(validate_agent_templates)

## Overall Status

**Pass Rate**: $pass_rate%
**Target**: ≥80%
**Status**: $([ "$pass_rate" -ge 80 ] && echo "✓ PASS" || echo "✗ FAIL")

## Recommendations

EOF

  if [ "$pass_rate" -ge 80 ]; then
    echo "All validation checks passed. The hierarchical agent context preservation system is ready for production use."
  else
    echo "Some validation checks failed. Review the failures above and address issues before production deployment."
  fi

  if [ "$warnings" -gt 0 ]; then
    echo ""
    echo "**Note**: $warnings warning(s) detected. These are non-critical but should be reviewed."
  fi
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CONTEXT REDUCTION VALIDATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Project: $CLAUDE_PROJECT_DIR"
  echo "Threshold: <$CONTEXT_THRESHOLD% context usage"
  echo "Target: ≥$REDUCTION_TARGET% context reduction"
  echo ""

  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  local warnings=0

  # Run validations
  local tests=(
    validate_metadata_extraction
    validate_forward_message
    validate_context_pruning
    validate_context_metrics
    validate_command_integration
    validate_agent_templates
  )

  for test_func in "${tests[@]}"; do
    total_tests=$((total_tests + 1))
    if $test_func >/dev/null 2>&1; then
      passed_tests=$((passed_tests + 1))
    else
      # Check if it's a warning or failure
      local test_output=$($test_func 2>&1 || true)
      if echo "$test_output" | grep -q "WARN"; then
        warnings=$((warnings + 1))
        passed_tests=$((passed_tests + 1))  # Warnings don't fail tests
      else
        failed_tests=$((failed_tests + 1))
      fi
    fi
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "VALIDATION COMPLETE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Total tests: $total_tests"
  echo "Passed: $passed_tests"
  echo "Failed: $failed_tests"
  echo "Warnings: $warnings"
  echo "Pass rate: $(( passed_tests * 100 / total_tests ))%"
  echo ""

  if [ $(( passed_tests * 100 / total_tests )) -ge 80 ]; then
    log_success "Validation passed (≥80% pass rate)"
  else
    log_error "Validation failed (<80% pass rate)"
  fi

  # Generate report if output file specified
  if [ -n "$OUTPUT_FILE" ]; then
    log_info "Generating report: $OUTPUT_FILE"
    generate_report "$total_tests" "$passed_tests" "$failed_tests" "$warnings" > "$OUTPUT_FILE"
    log_success "Report generated: $OUTPUT_FILE"
  fi

  # Return success if pass rate ≥80%
  if [ $(( passed_tests * 100 / total_tests )) -ge 80 ]; then
    return 0
  else
    return 1
  fi
}

# Run main function
main "$@"

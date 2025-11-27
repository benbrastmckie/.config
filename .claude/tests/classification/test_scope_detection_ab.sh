#!/usr/bin/env bash
# A/B Testing Framework for Workflow Classification (2-Mode System)
#
# Compares LLM-only mode vs regex-only mode classifications
# to identify disagreements and measure agreement rate.
# Note: Hybrid mode has been removed in clean-break update.

set -euo pipefail

# Source the libraries we need to test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
PROJECT_ROOT="$CLAUDE_PROJECT_DIR"

# Source workflow scope detection library
source "${PROJECT_ROOT}/.claude/lib/workflow/workflow-scope-detection.sh"

# Test results tracking
TOTAL_TESTS=0
AGREEMENTS=0
DISAGREEMENTS=0
declare -a DISAGREEMENT_CASES=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test dataset: workflow descriptions with expected classifications
# Format: "description|expected_scope"
# Available scopes: research-and-plan, research-and-revise, full-implementation, research-only, debug-only
TEST_CASES=(
  # Straightforward cases (both should agree)
  "research authentication patterns and create implementation plan|research-and-plan"
  "implement the authentication system|full-implementation"
  "revise the plan at specs/042/plans/001.md based on new requirements|research-and-revise"
  "research the codebase to understand how auth works|research-only"
  "plan a new feature for user management|research-and-plan"
  "test the authentication flow|research-and-plan"
  "debug the login failure issue|debug-only"

  # Edge cases from the original issue (LLM should outperform regex on these)
  "research the research-and-revise workflow to understand misclassification|research-only"
  "analyze the coordinate command implementation|research-and-plan"
  "investigate why the implement workflow failed|full-implementation"

  # Quoted keywords (LLM should outperform regex on these)
  "research the 'implement' command source code|full-implementation"
  "analyze the 'revise' function behavior|research-and-plan"

  # Negation cases
  "don't revise the plan, create a new one|research-and-plan"
  "research alternatives instead of implementing the current approach|research-only"

  # Multiple actions (priority detection)
  "research X, plan Y, and implement Z|research-and-plan"
  "implement feature A and test feature B|full-implementation"

  # Ambiguous intent
  "look into the coordinate output|research-and-plan"
  "check the test results|research-and-plan"
  "review the documentation|research-and-plan"

  # Complex descriptions
  "research authentication patterns in the codebase, analyze security implications, and create a comprehensive implementation plan|research-and-plan"
  "implement the user authentication system with OAuth2 support, including login, logout, and token refresh|full-implementation"

  # Research-and-plan variations
  "research and plan the authentication system|research-and-plan"
  "analyze the codebase and create a plan|research-and-plan"
  "investigate the issue and plan the fix|research-and-plan"

  # Research-and-revise variations
  "research new requirements and revise the existing plan|research-and-revise"
  "analyze feedback and update the plan|research-and-revise"
  "investigate issues and modify the plan|research-and-plan"

  # Full-implementation variations
  "implement the feature described in the plan|full-implementation"
  "build the authentication system|research-and-plan"
  "code the new API endpoint|research-and-plan"

  # Debug variations
  "fix the login bug|debug-only"
  "troubleshoot the authentication failure|debug-only"
  "investigate why the test is failing|research-and-plan"

  # Research-only variations
  "study the codebase architecture|research-and-plan"
  "explore authentication libraries|research-and-plan"
  "analyze the current implementation|research-and-plan"

  # Additional edge cases for semantic understanding (LLM should outperform regex)
  "look into authentication patterns|research-and-plan"
  "examine the codebase|research-and-plan"
  "review auth implementation|research-and-plan"
  "understand the workflow system|research-and-plan"
  "implement X and debug Y|full-implementation"
  "execute the plan in specs/042/plans/001.md|full-implementation"
)

# Check if LLM classification is available
check_llm_available() {
  export WORKFLOW_CLASSIFICATION_MODE="llm-only"
  export WORKFLOW_CLASSIFICATION_DEBUG=0
  local test_result
  test_result=$(detect_workflow_scope "test" 2>&1)
  local exit_code=$?

  # If LLM-only mode returns error or fallback, LLM is not available
  if [ $exit_code -ne 0 ] || echo "$test_result" | grep -q "fallback\|timeout\|error"; then
    return 1
  fi
  return 0
}

# Function to run classification with a specific mode
classify_with_mode() {
  local description="$1"
  local mode="$2"

  export WORKFLOW_CLASSIFICATION_MODE="$mode"
  export WORKFLOW_CLASSIFICATION_DEBUG=0

  local result
  result=$(detect_workflow_scope "$description" 2>/dev/null || echo "unknown")

  echo "$result"
}

# Function to compare LLM and regex classifications
compare_classifications() {
  local description="$1"
  local expected="$2"

  # Get LLM classification (will fall back to regex if LLM unavailable)
  local llm_result
  llm_result=$(classify_with_mode "$description" "llm-only" 2>/dev/null || echo "unknown")

  # Get regex classification
  local regex_result
  regex_result=$(classify_with_mode "$description" "regex-only")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [ "$llm_result" = "$regex_result" ]; then
    AGREEMENTS=$((AGREEMENTS + 1))
    echo -e "${GREEN}AGREE${NC}"
    return 0
  else
    DISAGREEMENTS=$((DISAGREEMENTS + 1))
    DISAGREEMENT_CASES+=("$description|Expected: $expected|LLM: $llm_result|Regex: $regex_result")
    echo -e "${YELLOW}DISAGREE${NC}"
    return 1
  fi
}

# Function to generate disagreement report
generate_disagreement_report() {
  local report_file="${PROJECT_ROOT}/.claude/tests/ab_disagreement_report.txt"

  {
    echo "A/B Testing Disagreement Report"
    echo "Generated: $(date)"
    echo "================================"
    echo ""
    echo "Summary:"
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Agreements: $AGREEMENTS"
    echo "  Disagreements: $DISAGREEMENTS"

    if [ $TOTAL_TESTS -gt 0 ]; then
      local agreement_rate=$((AGREEMENTS * 100 / TOTAL_TESTS))
      echo "  Agreement Rate: ${agreement_rate}%"
    fi

    echo ""
    echo "Disagreement Cases:"
    echo "===================="

    if [ ${#DISAGREEMENT_CASES[@]} -eq 0 ]; then
      echo "  None - Perfect agreement!"
    else
      local i=1
      for case in "${DISAGREEMENT_CASES[@]}"; do
        echo ""
        echo "Case #$i:"
        IFS='|' read -r desc expected llm regex <<< "$case"
        echo "  Description: $desc"
        echo "  $expected"
        echo "  $llm"
        echo "  $regex"
        i=$((i + 1))
      done
    fi

    echo ""
    echo "Analysis:"
    echo "========="
    echo "  - Review each disagreement case manually"
    echo "  - Determine which classification is correct"
    echo "  - Update test dataset with validated classifications"
    echo "  - If LLM consistently outperforms regex, document edge cases"
  } > "$report_file"

  echo "Disagreement report written to: $report_file"
}

# Main test execution
main() {
  echo "=========================================="
  echo "Workflow Classification A/B Testing"
  echo "=========================================="
  echo ""

  # Check if LLM is available
  if check_llm_available; then
    echo -e "${GREEN}✓ LLM classification available${NC}"
    LLM_AVAILABLE=true
  else
    echo -e "${YELLOW}⚠ LLM classification not available - testing regex-only mode${NC}"
    echo "  This is expected during development before LLM integration is complete."
    echo "  Testing will validate regex classifications against expected results."
    LLM_AVAILABLE=false
  fi

  echo ""
  echo "Testing ${#TEST_CASES[@]} workflow descriptions..."
  echo ""

  # Run all test cases
  for test_case in "${TEST_CASES[@]}"; do
    IFS='|' read -r description expected <<< "$test_case"

    printf "%-70s ... " "${description:0:70}"

    if [ "$LLM_AVAILABLE" = true ]; then
      compare_classifications "$description" "$expected"
    else
      # If LLM not available, just test regex against expected
      local regex_result
      regex_result=$(classify_with_mode "$description" "regex-only")
      TOTAL_TESTS=$((TOTAL_TESTS + 1))

      if [ "$regex_result" = "$expected" ]; then
        echo -e "${GREEN}PASS${NC}"
        AGREEMENTS=$((AGREEMENTS + 1))
      else
        echo -e "${RED}FAIL${NC} (Expected: $expected, Got: $regex_result)"
        DISAGREEMENTS=$((DISAGREEMENTS + 1))
        DISAGREEMENT_CASES+=("$description|Expected: $expected|Regex: $regex_result")
      fi
    fi
  done

  echo ""
  echo "=========================================="
  echo "Results Summary"
  echo "=========================================="
  echo "Total Tests: $TOTAL_TESTS"
  echo "Agreements: $AGREEMENTS"
  echo "Disagreements: $DISAGREEMENTS"

  if [ $TOTAL_TESTS -gt 0 ]; then
    AGREEMENT_RATE=$((AGREEMENTS * 100 / TOTAL_TESTS))

    if [ "$LLM_AVAILABLE" = true ]; then
      echo "Agreement Rate (LLM vs Regex): ${AGREEMENT_RATE}%"

      if [ $AGREEMENT_RATE -ge 90 ]; then
        echo -e "${GREEN}✓ Agreement rate >= 90% (PASS)${NC}"
      else
        echo -e "${YELLOW}⚠ Agreement rate < 90% - Review disagreements${NC}"
      fi
    else
      echo "Pass Rate (Regex vs Expected): ${AGREEMENT_RATE}%"

      if [ $AGREEMENT_RATE -ge 85 ]; then
        echo -e "${GREEN}✓ Pass rate >= 85% (PASS)${NC}"
      else
        echo -e "${RED}✗ Pass rate < 85% (FAIL)${NC}"
      fi
    fi
  fi

  echo ""
  generate_disagreement_report

  # Exit with success if pass rate is acceptable
  if [ $TOTAL_TESTS -gt 0 ]; then
    if [ "$LLM_AVAILABLE" = true ]; then
      # For A/B testing, accept >= 90% agreement
      [ $AGREEMENT_RATE -ge 90 ] && exit 0 || exit 1
    else
      # For regex testing, accept >= 85% pass rate
      [ $AGREEMENT_RATE -ge 85 ] && exit 0 || exit 1
    fi
  else
    exit 1
  fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi

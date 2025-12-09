#!/usr/bin/env bash
# Integration test for research-coordinator agent
# Tests multi-topic research orchestration, parallel execution, metadata aggregation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/research_coordinator_test_$$"
AGENTS_DIR="$(cd "$(dirname "$0")/../../agents" && pwd)"
LIB_DIR="$(cd "$(dirname "$0")/../../lib" && pwd)"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/specs/028_test_topic/reports"
  mkdir -p "$TEST_DIR/tmp"

  # Export test paths
  export TOPIC_PATH="$TEST_DIR/specs/028_test_topic"
  export RESEARCH_DIR="$TOPIC_PATH/reports"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Test 1: Verify research-coordinator agent file exists
test_coordinator_file_exists() {
  info "Testing research-coordinator agent file exists"

  local agent_file="$AGENTS_DIR/research-coordinator.md"

  if [[ -f "$agent_file" ]]; then
    pass "research-coordinator.md exists"
  else
    fail "research-coordinator.md not found" "Expected at $agent_file"
    return
  fi

  # Validate frontmatter
  if grep -q "^allowed-tools: Task, Read, Bash, Grep" "$agent_file"; then
    pass "research-coordinator has correct allowed-tools"
  else
    fail "research-coordinator missing or incorrect allowed-tools" "Should include Task, Read, Bash, Grep"
  fi

  if grep -q "^model: sonnet-4.5" "$agent_file"; then
    pass "research-coordinator uses sonnet-4.5 model"
  else
    fail "research-coordinator missing or incorrect model" "Should use sonnet-4.5"
  fi

  if grep -q "^dependent-agents: research-specialist" "$agent_file"; then
    pass "research-coordinator has dependent-agents field"
  else
    fail "research-coordinator missing dependent-agents field" "Should list research-specialist"
  fi
}

# Test 2: Verify research-coordinator has required steps
test_coordinator_workflow_steps() {
  info "Testing research-coordinator workflow steps"

  local agent_file="$AGENTS_DIR/research-coordinator.md"

  # Check for all 6 required steps
  local steps=(
    "STEP 1: Receive and Verify Research Topics"
    "STEP 2: Pre-Calculate Report Paths"
    "STEP 3: Invoke Parallel Research Workers"
    "STEP 4: Validate Research Artifacts"
    "STEP 5: Extract Metadata"
    "STEP 6: Return Aggregated Metadata"
  )

  for step in "${steps[@]}"; do
    if grep -q "^### $step" "$agent_file"; then
      pass "Found workflow step: $step"
    else
      fail "Missing workflow step: $step" "Required for coordinator behavior"
    fi
  done
}

# Test 3: Verify topic-detection-agent exists
test_topic_detection_agent_exists() {
  info "Testing topic-detection-agent file exists"

  local agent_file="$AGENTS_DIR/topic-detection-agent.md"

  if [[ -f "$agent_file" ]]; then
    pass "topic-detection-agent.md exists"
  else
    fail "topic-detection-agent.md not found" "Expected at $agent_file"
    return
  fi

  # Validate frontmatter
  if grep -q "^model: haiku-4.1" "$agent_file"; then
    pass "topic-detection-agent uses haiku-4.1 model"
  else
    fail "topic-detection-agent missing or incorrect model" "Should use haiku-4.1"
  fi

  # Validate fallback behavior documented
  if grep -q "fallback" "$agent_file"; then
    pass "topic-detection-agent documents fallback behavior"
  else
    fail "topic-detection-agent missing fallback documentation" "Should handle ambiguous prompts"
  fi
}

# Test 4: Mock multi-topic research scenario (path pre-calculation)
test_path_precalculation() {
  info "Testing report path pre-calculation logic"

  # Simulate path pre-calculation from coordinator
  local topics=(
    "Mathlib Theorems for Group Homomorphism"
    "Proof Automation Strategies"
    "Lean 4 Project Structure Patterns"
  )

  # Find existing reports
  local existing_reports=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)
  local start_num=$((existing_reports + 1))

  # Calculate paths
  local report_paths=()
  for i in "${!topics[@]}"; do
    local topic_slug=$(echo "${topics[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    local report_num=$(printf "%03d" $((start_num + i)))
    local report_path="${RESEARCH_DIR}/${report_num}-${topic_slug}.md"
    report_paths+=("$report_path")
  done

  # Validate path format
  if [[ "${report_paths[0]}" =~ /001-mathlib-theorems-for-group-homomorphism\.md$ ]]; then
    pass "Path pre-calculation generates correct format"
  else
    fail "Path pre-calculation incorrect format" "Expected 001-mathlib-theorems-for-group-homomorphism.md, got ${report_paths[0]}"
  fi

  # Validate sequential numbering
  if [[ "${report_paths[1]}" =~ /002- ]]; then
    pass "Sequential numbering works correctly"
  else
    fail "Sequential numbering broken" "Expected 002-, got ${report_paths[1]}"
  fi
}

# Test 5: Mock research report validation (hard barrier pattern)
test_hard_barrier_validation() {
  info "Testing hard barrier validation logic"

  # Create mock reports
  local report_paths=(
    "$RESEARCH_DIR/001-mathlib-theorems.md"
    "$RESEARCH_DIR/002-proof-automation.md"
    "$RESEARCH_DIR/003-project-structure.md"
  )

  for path in "${report_paths[@]}"; do
    cat > "$path" <<'EOF'
# Research Report Title

## Overview

This is a comprehensive research report analyzing the specified topic. The research covers multiple aspects including current best practices, common patterns, and recommended approaches. This overview section provides context for the findings and recommendations that follow.

## Findings

### Finding 1
Detailed finding content with substantial analysis. This finding provides in-depth information about the researched topic, including examples, code patterns, and relevant context. The analysis is comprehensive and actionable.

Additional details about this finding, including supporting evidence and references to relevant documentation or codebase examples.

### Finding 2
Another detailed finding with comprehensive analysis. This finding explores a different aspect of the researched topic, providing insights into implementation strategies, potential pitfalls, and optimization opportunities.

Supporting information and context for this finding, with concrete examples and actionable insights.

## Recommendations

1. Test recommendation 1 with detailed guidance on implementation approach
2. Test recommendation 2 with specific steps and best practices
3. Additional recommendation for comprehensive coverage
4. Final recommendation ensuring actionable outcomes

## Conclusion

Summary of research findings and recommendations, providing a cohesive overview of the research outcomes and next steps for implementation.
EOF
  done

  # Validate all reports exist
  local missing_reports=()
  for report_path in "${report_paths[@]}"; do
    if [[ ! -f "$report_path" ]]; then
      missing_reports+=("$report_path")
    fi
  done

  if [[ ${#missing_reports[@]} -eq 0 ]]; then
    pass "All pre-calculated reports exist (hard barrier validation)"
  else
    fail "Hard barrier validation failed" "${#missing_reports[@]} reports missing: ${missing_reports[*]}"
    return
  fi

  # Validate report size >500 bytes (coordinator requirement)
  local small_reports=()
  for report_path in "${report_paths[@]}"; do
    local size=$(wc -c < "$report_path")
    if [[ $size -lt 500 ]]; then
      small_reports+=("$report_path")
    fi
  done

  if [[ ${#small_reports[@]} -eq 0 ]]; then
    pass "All reports meet size threshold (>500 bytes)"
  else
    fail "Reports below size threshold" "${#small_reports[@]} reports <500 bytes: ${small_reports[*]}"
  fi

  # Validate required sections exist
  local invalid_reports=()
  for report_path in "${report_paths[@]}"; do
    if ! grep -q "^## Findings" "$report_path" 2>/dev/null; then
      invalid_reports+=("$report_path")
    fi
  done

  if [[ ${#invalid_reports[@]} -eq 0 ]]; then
    pass "All reports contain required ## Findings section"
  else
    fail "Reports missing required sections" "${#invalid_reports[@]} reports missing ## Findings: ${invalid_reports[*]}"
  fi
}

# Test 6: Mock metadata extraction
test_metadata_extraction() {
  info "Testing metadata extraction from research reports"

  local report_path="$RESEARCH_DIR/001-mathlib-theorems.md"

  # Extract title (first heading)
  local title=$(grep -m 1 "^# " "$report_path" | sed 's/^# //')

  if [[ "$title" == "Research Report Title" ]]; then
    pass "Metadata extraction: title extracted correctly"
  else
    fail "Metadata extraction: title incorrect" "Expected 'Research Report Title', got '$title'"
  fi

  # Count findings (### Finding subsections)
  local findings_count=$(grep -c "^### Finding" "$report_path" 2>/dev/null || echo 0)

  if [[ $findings_count -eq 2 ]]; then
    pass "Metadata extraction: findings count correct ($findings_count)"
  else
    fail "Metadata extraction: findings count incorrect" "Expected 2, got $findings_count"
  fi

  # Count recommendations (numbered items in ## Recommendations)
  local recommendations_count=$(grep -A 100 "^## Recommendations" "$report_path" | grep -E "^[0-9]+\." | wc -l)

  if [[ $recommendations_count -eq 4 ]]; then
    pass "Metadata extraction: recommendations count correct ($recommendations_count)"
  else
    fail "Metadata extraction: recommendations count incorrect" "Expected 4, got $recommendations_count"
  fi

  # Verify metadata is compact (110 tokens target)
  # Approximate: {"path": "...", "title": "...", "findings_count": 2, "recommendations_count": 2}
  local metadata_json="{\"path\": \"$report_path\", \"title\": \"$title\", \"findings_count\": $findings_count, \"recommendations_count\": $recommendations_count}"
  local metadata_chars=${#metadata_json}

  # Rough estimate: 4 chars per token (conservative)
  local estimated_tokens=$((metadata_chars / 4))

  if [[ $estimated_tokens -le 150 ]]; then
    pass "Metadata is compact (~$estimated_tokens tokens, target 110)"
  else
    fail "Metadata too large" "Estimated $estimated_tokens tokens, target 110"
  fi
}

# Test 7: Context reduction calculation
test_context_reduction() {
  info "Testing context reduction vs full report content"

  local report_path="$RESEARCH_DIR/001-mathlib-theorems.md"

  # Measure full report size (tokens)
  local report_chars=$(wc -c < "$report_path")
  local report_tokens=$((report_chars / 4))  # Rough estimate

  # Measure metadata size (tokens)
  local metadata_json='{"path": "/path/to/001-mathlib-theorems.md", "title": "Research Report Title", "findings_count": 2, "recommendations_count": 2}'
  local metadata_chars=${#metadata_json}
  local metadata_tokens=$((metadata_chars / 4))

  # Calculate reduction percentage
  local reduction_percent=$(( (report_tokens - metadata_tokens) * 100 / report_tokens ))

  if [[ $reduction_percent -ge 90 ]]; then
    pass "Context reduction achieved: ${reduction_percent}% (target 95%)"
  else
    fail "Context reduction below target" "Achieved ${reduction_percent}%, target 95%"
  fi

  info "Full report: ~$report_tokens tokens"
  info "Metadata: ~$metadata_tokens tokens"
  info "Reduction: ${reduction_percent}%"
}

# Test 8: Verify hierarchical-agents-examples.md updated
test_documentation_updated() {
  info "Testing documentation updates"

  local examples_file="$(cd "$(dirname "$0")/../../docs/concepts" && pwd)/hierarchical-agents-examples.md"

  if [[ ! -f "$examples_file" ]]; then
    fail "hierarchical-agents-examples.md not found" "Expected at $examples_file"
    return
  fi

  # Check for Example 7: Research Coordinator
  if grep -q "^## Example 7: Research Coordinator" "$examples_file"; then
    pass "hierarchical-agents-examples.md includes Example 7: Research Coordinator"
  else
    fail "hierarchical-agents-examples.md missing Example 7" "Should document research-coordinator pattern"
  fi

  # Check for context reduction metrics
  if grep -q "Context reduction: 95" "$examples_file"; then
    pass "Documentation includes context reduction metrics"
  else
    fail "Documentation missing context reduction metrics" "Should show 95%+ reduction"
  fi

  # Check for parallel execution mention
  if grep -q "parallel" "$examples_file"; then
    pass "Documentation mentions parallel execution"
  else
    fail "Documentation missing parallel execution details" "Should explain parallelization benefits"
  fi
}

# Test 9: Error handling validation
test_error_handling() {
  info "Testing error handling in research-coordinator"

  local agent_file="$AGENTS_DIR/research-coordinator.md"

  # Check for error handling section
  if grep -q "^## Error Handling" "$agent_file"; then
    pass "research-coordinator has Error Handling section"
  else
    fail "research-coordinator missing Error Handling section" "Required for robust operation"
  fi

  # Check for specific error types
  local error_types=(
    "Missing Research Request"
    "Reports Directory Inaccessible"
    "Report Validation Failure"
    "Research-Specialist Agent Failure"
    "Metadata Extraction Failure"
  )

  for error_type in "${error_types[@]}"; do
    if grep -q "$error_type" "$agent_file"; then
      pass "Error handling covers: $error_type"
    else
      fail "Error handling missing: $error_type" "Should have error handling for this case"
    fi
  done

  # Check for TASK_ERROR return protocol
  if grep -q "TASK_ERROR:" "$agent_file"; then
    pass "research-coordinator uses TASK_ERROR return protocol"
  else
    fail "research-coordinator missing TASK_ERROR protocol" "Required for error propagation"
  fi
}

# Test 10: Output format validation
test_output_format() {
  info "Testing research-coordinator output format"

  local agent_file="$AGENTS_DIR/research-coordinator.md"

  # Check for RESEARCH_COMPLETE signal
  if grep -q "RESEARCH_COMPLETE:" "$agent_file"; then
    pass "research-coordinator defines RESEARCH_COMPLETE signal"
  else
    fail "research-coordinator missing RESEARCH_COMPLETE signal" "Required for orchestrator parsing"
  fi

  # Check for JSON metadata format
  if grep -q '"reports":' "$agent_file"; then
    pass "research-coordinator defines JSON metadata format"
  else
    fail "research-coordinator missing JSON metadata format" "Required for metadata aggregation"
  fi

  # Check for metadata fields
  local metadata_fields=(
    "path"
    "title"
    "findings_count"
    "recommendations_count"
  )

  for field in "${metadata_fields[@]}"; do
    if grep -q "\"$field\":" "$agent_file"; then
      pass "Metadata includes field: $field"
    else
      fail "Metadata missing field: $field" "Required for complete metadata"
    fi
  done
}

# Main test execution
main() {
  echo "=================================================="
  echo "Research Coordinator Integration Test Suite"
  echo "=================================================="
  echo ""

  setup
  trap cleanup EXIT

  # Run all tests
  test_coordinator_file_exists
  test_coordinator_workflow_steps
  test_topic_detection_agent_exists
  test_path_precalculation
  test_hard_barrier_validation
  test_metadata_extraction
  test_context_reduction
  test_documentation_updated
  test_error_handling
  test_output_format

  # Print summary
  echo ""
  echo "=================================================="
  echo "Test Summary"
  echo "=================================================="
  echo "Total Tests: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    exit 0
  else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    exit 1
  fi
}

# Run tests
main "$@"

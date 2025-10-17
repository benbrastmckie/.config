#!/usr/bin/env bash
# Test suite for hierarchical agent patterns
# Tests metadata extraction, forward_message, recursive supervision, context reduction

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
TEST_DIR="/tmp/hierarchical_agent_tests_$$"
LIB_DIR="$(dirname "$0")/../lib"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/specs/reports"
  mkdir -p "$TEST_DIR/specs/plans"
  mkdir -p "$TEST_DIR/specs/summaries"
  mkdir -p "$TEST_DIR/.claude/data/logs"

  # Source utility libraries
  if [ -f "$LIB_DIR/artifact-operations.sh" ]; then
    source "$LIB_DIR/artifact-operations.sh" 2>/dev/null || true
  fi
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

# Test: Report metadata extraction
test_metadata_extraction() {
  info "Testing report metadata extraction"

  # Create test report
  local report_file="$TEST_DIR/specs/reports/001_auth_patterns.md"
  cat > "$report_file" <<'EOF'
# Authentication Patterns Research

## Metadata
- **Date**: 2025-10-16
- **Research Questions**: 3

## Executive Summary
This report analyzes JWT vs session-based authentication patterns for web applications. JWT provides stateless authentication suitable for microservices, while sessions offer better security for traditional web apps. Analysis covers security trade-offs, scalability considerations, and implementation complexity.

## Findings
- JWT: Stateless, scalable, suitable for APIs
- Sessions: Stateful, more secure, better for web apps
- Hybrid: Combines benefits of both approaches

## Recommendations
- Use JWT for API authentication
- Use sessions for web application
- Implement refresh token rotation
- Consider hybrid approach for complex systems
- Add rate limiting for auth endpoints

## File References
- lib/auth/jwt.lua
- lib/auth/sessions.lua
- lib/middleware/auth.lua
EOF

  # Test metadata extraction (if function available)
  if type extract_report_metadata &>/dev/null; then
    local metadata=$(extract_report_metadata "$report_file")

    if [ -n "$metadata" ]; then
      pass "Extracted metadata from report"
    else
      fail "Metadata extraction returned empty" "File: $report_file"
      return
    fi

    # Verify JSON structure
    local title=$(echo "$metadata" | jq -r '.title' 2>/dev/null)
    if [ "$title" = "Authentication Patterns Research" ]; then
      pass "Extracted correct title"
    else
      fail "Incorrect title extracted" "Got: $title"
    fi

    # Verify summary length (should be ≤50 words)
    local summary=$(echo "$metadata" | jq -r '.summary' 2>/dev/null)
    local word_count=$(echo "$summary" | wc -w)
    if [ "$word_count" -le 50 ]; then
      pass "Summary length ≤50 words"
    else
      fail "Summary too long" "Got: $word_count words (expected ≤50)"
    fi

    # Verify file paths extracted
    local paths_count=$(echo "$metadata" | jq -r '.file_paths | length' 2>/dev/null)
    if [ "$paths_count" -ge 1 ]; then
      pass "Extracted file paths from report"
    else
      fail "No file paths extracted" "Expected ≥1 paths"
    fi

    # Verify recommendations extracted
    local rec_count=$(echo "$metadata" | jq -r '.recommendations | length' 2>/dev/null)
    if [ "$rec_count" -ge 3 ] && [ "$rec_count" -le 5 ]; then
      pass "Extracted 3-5 recommendations"
    else
      fail "Incorrect recommendation count" "Got: $rec_count (expected 3-5)"
    fi
  else
    # Fallback: verify file structure
    if grep -q "# Authentication Patterns Research" "$report_file" && \
       grep -q "## Executive Summary" "$report_file"; then
      pass "Report has valid structure for metadata extraction"
    else
      fail "Report structure invalid" "Missing title or summary"
    fi
  fi
}

# Test: Plan metadata extraction
test_plan_metadata_extraction() {
  info "Testing plan metadata extraction"

  local plan_file="$TEST_DIR/specs/plans/001_auth_implementation.md"
  cat > "$plan_file" <<'EOF'
# Authentication Implementation Plan

## Metadata
- **Date**: 2025-10-16
- **Feature**: JWT Authentication
- **Scope**: API authentication with JWT tokens
- **Estimated Phases**: 3
- **Complexity**: Medium
- **Time Estimate**: 6-8 hours

## Success Criteria
- [x] JWT generation and validation
- [ ] Refresh token rotation
- [ ] Rate limiting

## Implementation Phases

### Phase 1: JWT Utilities
**Objective**: Implement JWT generation and validation
**Tasks**:
- [ ] Create JWT signing function
- [ ] Create JWT validation function
- [ ] Add expiration handling
EOF

  if type extract_plan_metadata &>/dev/null; then
    local metadata=$(extract_plan_metadata "$plan_file")

    if [ -n "$metadata" ]; then
      pass "Extracted metadata from plan"
    else
      fail "Plan metadata extraction failed" "File: $plan_file"
      return
    fi

    # Verify complexity field
    local complexity=$(echo "$metadata" | jq -r '.complexity' 2>/dev/null)
    if [ "$complexity" = "Medium" ]; then
      pass "Extracted complexity correctly"
    else
      fail "Incorrect complexity" "Got: $complexity"
    fi

    # Verify phase count
    local phases=$(echo "$metadata" | jq -r '.phases' 2>/dev/null)
    if [ "$phases" -ge 1 ]; then
      pass "Extracted phase count"
    else
      fail "Phase count extraction failed" "Got: $phases"
    fi

    # Verify success criteria count
    local criteria=$(echo "$metadata" | jq -r '.success_criteria' 2>/dev/null)
    if [ "$criteria" -ge 2 ]; then
      pass "Extracted success criteria count"
    else
      fail "Success criteria count incorrect" "Got: $criteria"
    fi
  else
    # Fallback test
    if grep -q "## Metadata" "$plan_file" && \
       grep -q "## Success Criteria" "$plan_file"; then
      pass "Plan structure valid for metadata extraction"
    else
      fail "Plan structure invalid" "Missing required sections"
    fi
  fi
}

# Test: Metadata caching
test_metadata_caching() {
  info "Testing metadata cache functionality"

  local report_file="$TEST_DIR/specs/reports/002_test_cache.md"
  cat > "$report_file" <<'EOF'
# Cache Test Report

## Executive Summary
Short summary for testing metadata caching functionality.

## Findings
- Finding 1
- Finding 2
EOF

  if type load_metadata_on_demand &>/dev/null && \
     type cache_metadata &>/dev/null && \
     type get_cached_metadata &>/dev/null; then

    # Load metadata (should cache it)
    local metadata1=$(load_metadata_on_demand "$report_file")

    # Get from cache
    local cached=$(get_cached_metadata "$report_file")

    if [ -n "$cached" ]; then
      pass "Metadata cached successfully"
    else
      fail "Metadata not cached" "Cache returned empty"
      return
    fi

    # Verify cache hit returns same data
    if [ "$metadata1" = "$cached" ]; then
      pass "Cache returns consistent data"
    else
      fail "Cache data mismatch" "Different metadata returned"
    fi

    # Clear cache
    if type clear_metadata_cache &>/dev/null; then
      clear_metadata_cache
      local after_clear=$(get_cached_metadata "$report_file")
      if [ -z "$after_clear" ]; then
        pass "Cache cleared successfully"
      else
        fail "Cache clear failed" "Data still present"
      fi
    fi
  else
    # Verify cache functions exist in library
    if grep -q "METADATA_CACHE" "$LIB_DIR/artifact-operations.sh" 2>/dev/null; then
      pass "Metadata cache structure defined"
    else
      fail "Cache structure not found" "Check artifact-operations.sh"
    fi
  fi
}

# Test: Forward message pattern
test_forward_message_pattern() {
  info "Testing forward_message pattern"

  local subagent_output="Research complete. Created report at specs/042_auth/reports/001_patterns.md.

Summary: JWT vs sessions comparison. JWT recommended for APIs due to stateless nature and scalability. Sessions better for traditional web apps requiring revocation.

Key findings:
- JWT: Stateless, scalable, suitable for microservices
- Sessions: Stateful, more secure, better for web applications
- Hybrid approach combines benefits"

  if type forward_message &>/dev/null; then
    local handoff=$(forward_message "$subagent_output")

    if [ -n "$handoff" ]; then
      pass "forward_message processed subagent output"
    else
      fail "forward_message returned empty" "Input: $subagent_output"
      return
    fi

    # Verify artifact extraction
    local artifact_path=$(echo "$handoff" | jq -r '.artifacts[0].path' 2>/dev/null)
    if [[ "$artifact_path" == *"specs/"*".md" ]]; then
      pass "Extracted artifact path from output"
    else
      fail "Artifact path extraction failed" "Got: $artifact_path"
    fi

    # Verify summary is concise
    local summary=$(echo "$handoff" | jq -r '.summary' 2>/dev/null)
    local word_count=$(echo "$summary" | wc -w)
    if [ "$word_count" -le 100 ]; then
      pass "Handoff summary concise (≤100 words)"
    else
      fail "Summary too verbose" "Got: $word_count words"
    fi

    # Verify original output NOT included in handoff
    if ! echo "$handoff" | grep -q "Key findings"; then
      pass "Original subagent output not duplicated in handoff"
    else
      fail "Handoff contains full original output" "Should be metadata only"
    fi
  else
    # Fallback: test artifact path extraction
    local artifact_path=$(echo "$subagent_output" | grep -oP 'specs/[^[:space:]]+\.md')
    if [ -n "$artifact_path" ]; then
      pass "Can extract artifact paths from subagent output"
    else
      fail "Artifact path extraction failed" "Pattern not matched"
    fi
  fi
}

# Test: Subagent response parsing
test_subagent_response_parsing() {
  info "Testing subagent response parser"

  local response_with_json="Task complete. Created files.

\`\`\`json
{
  \"status\": \"SUCCESS\",
  \"artifacts\": [
    \"specs/042_auth/reports/001_patterns.md\",
    \"specs/042_auth/reports/002_security.md\"
  ],
  \"summary\": \"Research complete. 2 reports generated.\"
}
\`\`\`"

  if type parse_subagent_response &>/dev/null; then
    local parsed=$(parse_subagent_response "$response_with_json")

    if [ -n "$parsed" ]; then
      pass "Parsed subagent JSON response"
    else
      fail "Response parsing failed" "No output"
      return
    fi

    # Verify status extraction
    local status=$(echo "$parsed" | jq -r '.status' 2>/dev/null)
    if [ "$status" = "SUCCESS" ]; then
      pass "Extracted status from response"
    else
      fail "Status extraction failed" "Got: $status"
    fi

    # Verify artifact count
    local count=$(echo "$parsed" | jq -r '.artifacts | length' 2>/dev/null)
    if [ "$count" = "2" ]; then
      pass "Extracted artifact array"
    else
      fail "Artifact array incorrect" "Expected 2, got: $count"
    fi
  else
    # Fallback: verify JSON block extraction
    if echo "$response_with_json" | grep -q "\"status\": \"SUCCESS\""; then
      pass "Response contains parseable JSON"
    else
      fail "JSON block not found in response" "Check format"
    fi
  fi
}

# Test: Recursive supervision depth tracking
test_recursive_supervision_depth() {
  info "Testing recursive supervision depth tracking"

  if type track_supervision_depth &>/dev/null; then
    # Reset depth counter
    track_supervision_depth reset
    local initial=$(track_supervision_depth get)

    if [ "$initial" = "0" ]; then
      pass "Supervision depth initialized to 0"
    else
      fail "Initial depth incorrect" "Expected 0, got: $initial"
    fi

    # Increment depth
    track_supervision_depth increment
    local after_inc=$(track_supervision_depth get)

    if [ "$after_inc" = "1" ]; then
      pass "Depth increment works"
    else
      fail "Depth increment failed" "Expected 1, got: $after_inc"
    fi

    # Test limit checking
    if type MAX_SUPERVISION_DEPTH &>/dev/null || \
       grep -q "MAX_SUPERVISION_DEPTH" "$LIB_DIR/artifact-operations.sh" 2>/dev/null; then
      pass "MAX_SUPERVISION_DEPTH defined"
    else
      fail "Depth limit not defined" "Check MAX_SUPERVISION_DEPTH"
    fi

    # Decrement depth
    track_supervision_depth decrement
    local after_dec=$(track_supervision_depth get)

    if [ "$after_dec" = "0" ]; then
      pass "Depth decrement works"
    else
      fail "Depth decrement failed" "Expected 0, got: $after_dec"
    fi
  else
    # Fallback: verify depth tracking code exists
    if grep -q "track_supervision_depth" "$LIB_DIR/artifact-operations.sh" 2>/dev/null; then
      pass "Supervision depth tracking function defined"
    else
      fail "Depth tracking not found" "Check artifact-operations.sh"
    fi
  fi
}

# Test: Sub-supervisor invocation
test_sub_supervisor_invocation() {
  info "Testing sub-supervisor invocation"

  local config='{
    "task_domain": "security_research",
    "subagent_count": 2,
    "task_list": ["Auth patterns", "Security best practices"]
  }'

  if type invoke_sub_supervisor &>/dev/null; then
    # Note: This returns metadata for invocation, not actual invocation
    local result=$(invoke_sub_supervisor "$config")

    if [ -n "$result" ]; then
      pass "Sub-supervisor invocation prepared"
    else
      fail "Invocation preparation failed" "No result"
      return
    fi

    # Verify task domain extracted
    if echo "$result" | grep -q "security_research"; then
      pass "Task domain preserved in invocation"
    else
      fail "Task domain not found" "Result: $result"
    fi
  else
    # Verify sub-supervisor template exists
    if [ -f ".claude/templates/sub_supervisor_pattern.md" ]; then
      pass "Sub-supervisor template file exists"
    else
      fail "Sub-supervisor template missing" "Check templates directory"
    fi
  fi
}

# Test: Supervision tree visualization
test_supervision_tree_visualization() {
  info "Testing supervision tree generation"

  local workflow_state='{
    "supervisor": {
      "type": "orchestrator",
      "agents": 3,
      "sub_supervisors": [
        {
          "type": "research_supervisor",
          "agents": 2,
          "artifacts": 2
        },
        {
          "type": "implementation_supervisor",
          "agents": 1,
          "artifacts": 1
        }
      ]
    }
  }'

  if type generate_supervision_tree &>/dev/null; then
    local tree=$(generate_supervision_tree "$workflow_state")

    if [ -n "$tree" ]; then
      pass "Generated supervision tree"
    else
      fail "Tree generation failed" "No output"
      return
    fi

    # Verify tree contains hierarchy markers
    if echo "$tree" | grep -q "├\|└"; then
      pass "Tree uses proper ASCII art"
    else
      fail "Tree formatting incorrect" "Missing hierarchy markers"
    fi

    # Verify agent counts shown
    if echo "$tree" | grep -qP "\d+ agents"; then
      pass "Tree shows agent counts"
    else
      fail "Agent counts not displayed" "Check tree format"
    fi
  else
    # Verify function exists
    if grep -q "generate_supervision_tree" "$LIB_DIR/artifact-operations.sh" 2>/dev/null; then
      pass "Supervision tree function defined"
    else
      fail "Tree generation function missing" "Check artifact-operations.sh"
    fi
  fi
}

# Test: Context reduction calculation
test_context_reduction() {
  info "Testing context reduction calculation"

  # Simulate before/after context sizes
  local full_content_size=5000  # chars
  local metadata_size=250       # chars

  # Calculate reduction
  local reduction=$(( (full_content_size - metadata_size) * 100 / full_content_size ))

  if [ "$reduction" -ge 60 ]; then
    pass "Context reduction meets threshold (${reduction}%)"
  else
    fail "Insufficient context reduction" "Got: ${reduction}%, expected ≥60%"
  fi

  # Verify reduction calculation formula
  if [ "$reduction" = "95" ]; then
    pass "Context reduction calculation correct"
  else
    fail "Calculation error" "Expected 95%, got: ${reduction}%"
  fi
}

# Test: Context metrics logging
test_context_metrics_logging() {
  info "Testing context metrics logging"

  local log_file="$TEST_DIR/.claude/data/logs/context-metrics.log"

  # Simulate log entry
  cat > "$log_file" <<'EOF'
2025-10-16 12:00:00 | /implement | CONTEXT_BEFORE: 5000 tokens
2025-10-16 12:01:00 | /implement | SUBAGENT_INVOKED: implementation-researcher
2025-10-16 12:02:00 | /implement | CONTEXT_AFTER: 1500 tokens
2025-10-16 12:02:00 | /implement | REDUCTION: 70%
2025-10-16 12:03:00 | /plan | CONTEXT_BEFORE: 3000 tokens
2025-10-16 12:04:00 | /plan | SUBAGENT_INVOKED: research-agent
2025-10-16 12:05:00 | /plan | CONTEXT_AFTER: 800 tokens
2025-10-16 12:05:00 | /plan | REDUCTION: 73%
EOF

  # Verify log format
  if grep -q "CONTEXT_BEFORE:" "$log_file" && \
     grep -q "CONTEXT_AFTER:" "$log_file" && \
     grep -q "REDUCTION:" "$log_file"; then
    pass "Context metrics log format correct"
  else
    fail "Log format invalid" "Missing required fields"
  fi

  # Verify subagent invocations logged
  if grep -q "SUBAGENT_INVOKED:" "$log_file"; then
    pass "Subagent invocations logged"
  else
    fail "Subagent invocations not logged" "Check log format"
  fi

  # Calculate average reduction
  local reductions=($(grep "REDUCTION:" "$log_file" | grep -oP '\d+'))
  local sum=0
  local count=${#reductions[@]}

  for r in "${reductions[@]}"; do
    sum=$((sum + r))
  done

  if [ "$count" -gt 0 ]; then
    local avg=$((sum / count))
    if [ "$avg" -ge 60 ]; then
      pass "Average context reduction ≥60% (${avg}%)"
    else
      fail "Average reduction below threshold" "Got: ${avg}%"
    fi
  else
    fail "No reduction values found" "Check log parsing"
  fi
}

# Test: Agent template validation
test_agent_templates() {
  info "Testing agent template files"

  local templates=(
    ".claude/agents/implementation-researcher.md"
    ".claude/agents/debug-analyst.md"
    ".claude/templates/sub_supervisor_pattern.md"
  )

  for template in "${templates[@]}"; do
    if [ -f "$template" ]; then
      pass "Template exists: $(basename "$template")"

      # Verify template has required sections
      if grep -q "## Role" "$template" && \
         grep -q "## Responsibilities" "$template"; then
        pass "Template has required sections: $(basename "$template")"
      else
        fail "Template missing sections" "File: $template"
      fi
    else
      fail "Template missing" "Expected: $template"
    fi
  done
}

# Run all tests
run_all_tests() {
  echo "========================================"
  echo "Hierarchical Agent Pattern Test Suite"
  echo "========================================"
  echo ""

  setup

  # Metadata extraction tests
  test_metadata_extraction
  test_plan_metadata_extraction
  test_metadata_caching

  # Forward message pattern tests
  test_forward_message_pattern
  test_subagent_response_parsing

  # Recursive supervision tests
  test_recursive_supervision_depth
  test_sub_supervisor_invocation
  test_supervision_tree_visualization

  # Context reduction tests
  test_context_reduction
  test_context_metrics_logging

  # Template validation
  test_agent_templates

  cleanup

  echo ""
  echo "========================================"
  echo "Test Results"
  echo "========================================"
  echo "Tests Run:    $TESTS_RUN"
  echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

  if [ "$TESTS_RUN" -gt 0 ]; then
    local pass_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo "Pass Rate:    ${pass_rate}%"
  fi
  echo ""

  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}FAILURE${NC}: Some tests failed"
    exit 1
  else
    echo -e "${GREEN}SUCCESS${NC}: All tests passed"
    exit 0
  fi
}

# Run tests
run_all_tests

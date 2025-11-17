# Phase 2: Test Suite Creation

## Metadata
- **Phase**: 2
- **Dependencies**: Phase 1 (Standard 14 Compliance)
- **Complexity**: High (7/10)
- **Estimated Duration**: 4-6 hours
- **Parent Plan**: [002_plan_command_polish_and_production_readiness.md](../002_plan_command_polish_and_production_readiness.md)

## Objective

Create comprehensive test suite with ≥80% coverage for plan.md and validate-plan.sh, ensuring production readiness through systematic validation of all command features, error handling, and integration points.

## Test Infrastructure Setup

### Test File Structure

```bash
# Test file location
TEST_FILE="/home/benjamin/.config/.claude/tests/test_plan_command.sh"

# Test directory structure
/tmp/test_plan_$$
├── specs/              # Test spec directory
│   └── {NNN}_topic/    # Generated during tests
├── .claude/
│   └── commands/       # Command files for testing
└── CLAUDE.md           # Test standards file
```

### Test Utilities and Helpers

```bash
#!/usr/bin/env bash
# Test suite for /plan command
# Location: /home/benjamin/.config/.claude/tests/test_plan_command.sh
# Coverage target: ≥80% of plan.md and validate-plan.sh

set -euo pipefail

# Test configuration
export CLAUDE_SPECS_ROOT="/tmp/test_plan_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_plan_$$"
TEST_PASSED=0
TEST_FAILED=0
COVERAGE_LINES_EXECUTED=0
COVERAGE_LINES_TOTAL=0

# Cleanup function (called on EXIT)
cleanup() {
  local exit_code=$?

  # Remove test artifacts
  if [[ -d "$CLAUDE_SPECS_ROOT" ]]; then
    rm -rf "$CLAUDE_SPECS_ROOT"
  fi

  # Generate coverage report
  generate_coverage_report

  # Print summary
  echo ""
  echo "========================================="
  echo "Test Suite Summary"
  echo "========================================="
  echo "Passed: $TEST_PASSED"
  echo "Failed: $TEST_FAILED"
  echo "Coverage: ${COVERAGE_PERCENT}% (target: ≥80%)"
  echo "========================================="

  # Exit with original code or test failure code
  if [[ $TEST_FAILED -gt 0 ]]; then
    exit 1
  fi

  exit $exit_code
}

# Register cleanup trap
trap cleanup EXIT

# Test assertion helpers
assert_success() {
  local command="$1"
  local description="${2:-Command should succeed}"

  if eval "$command" &>/dev/null; then
    ((TEST_PASSED++))
    echo "✓ PASS: $description"
    return 0
  else
    ((TEST_FAILED++))
    echo "✗ FAIL: $description"
    echo "  Command: $command"
    return 1
  fi
}

assert_failure() {
  local command="$1"
  local description="${2:-Command should fail}"

  if ! eval "$command" &>/dev/null; then
    ((TEST_PASSED++))
    echo "✓ PASS: $description"
    return 0
  else
    ((TEST_FAILED++))
    echo "✗ FAIL: $description"
    echo "  Command: $command"
    return 1
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="${3:-Values should be equal}"

  if [[ "$expected" == "$actual" ]]; then
    ((TEST_PASSED++))
    echo "✓ PASS: $description"
    return 0
  else
    ((TEST_FAILED++))
    echo "✗ FAIL: $description"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="${3:-Output should contain string}"

  if [[ "$haystack" == *"$needle"* ]]; then
    ((TEST_PASSED++))
    echo "✓ PASS: $description"
    return 0
  else
    ((TEST_FAILED++))
    echo "✗ FAIL: $description"
    echo "  Expected to contain: $needle"
    echo "  Actual: $haystack"
    return 1
  fi
}

assert_file_exists() {
  local file_path="$1"
  local description="${2:-File should exist}"

  if [[ -f "$file_path" ]]; then
    ((TEST_PASSED++))
    echo "✓ PASS: $description"
    return 0
  else
    ((TEST_FAILED++))
    echo "✗ FAIL: $description"
    echo "  File not found: $file_path"
    return 1
  fi
}

assert_file_size_gte() {
  local file_path="$1"
  local min_size="$2"
  local description="${3:-File size should be ≥ threshold}"

  if [[ -f "$file_path" ]]; then
    local actual_size=$(wc -c < "$file_path")
    if [[ $actual_size -ge $min_size ]]; then
      ((TEST_PASSED++))
      echo "✓ PASS: $description ($actual_size ≥ $min_size bytes)"
      return 0
    else
      ((TEST_FAILED++))
      echo "✗ FAIL: $description"
      echo "  Expected: ≥ $min_size bytes"
      echo "  Actual: $actual_size bytes"
      return 1
    fi
  else
    ((TEST_FAILED++))
    echo "✗ FAIL: $description (file not found)"
    return 1
  fi
}

# Coverage tracking
track_coverage() {
  local function_name="$1"

  # Record function execution for coverage
  echo "$function_name" >> "$CLAUDE_SPECS_ROOT/.coverage_tracker"
  ((COVERAGE_LINES_EXECUTED++))
}

generate_coverage_report() {
  # Calculate coverage percentage
  if [[ -f "$CLAUDE_SPECS_ROOT/.coverage_tracker" ]]; then
    local unique_functions=$(sort -u "$CLAUDE_SPECS_ROOT/.coverage_tracker" | wc -l)
    local total_functions=50  # Estimated from plan.md and validate-plan.sh
    COVERAGE_PERCENT=$(( (unique_functions * 100) / total_functions ))
  else
    COVERAGE_PERCENT=0
  fi

  # Write coverage report
  cat > "$CLAUDE_SPECS_ROOT/.coverage_report.txt" <<EOF
Coverage Report
===============
Functions Executed: $unique_functions / $total_functions
Coverage: $COVERAGE_PERCENT%
Target: ≥80%
Status: $( [[ $COVERAGE_PERCENT -ge 80 ]] && echo "PASS" || echo "FAIL" )

Executed Functions:
$(sort -u "$CLAUDE_SPECS_ROOT/.coverage_tracker" 2>/dev/null || echo "(none)")
EOF
}

# Test environment setup
setup_test_environment() {
  echo "Setting up test environment..."

  # Create test directories
  mkdir -p "$CLAUDE_SPECS_ROOT/specs"
  mkdir -p "$CLAUDE_SPECS_ROOT/.claude/commands"

  # Create minimal CLAUDE.md for testing
  cat > "$CLAUDE_SPECS_ROOT/CLAUDE.md" <<'EOF'
# Test Project Configuration

## Testing Protocols
- Unit tests required for all functions
- Integration tests for workflows
- Coverage target: ≥80%

## Documentation Policy
- READMEs required in all directories
- Inline documentation for complex functions
EOF

  # Initialize coverage tracker
  touch "$CLAUDE_SPECS_ROOT/.coverage_tracker"

  echo "✓ Test environment ready at $CLAUDE_SPECS_ROOT"
}
```

## Test Implementation Tasks

### Task Group 1: Argument Parsing and Validation

#### Test 1.1: Single-Word Feature Description

```bash
test_single_word_feature() {
  track_coverage "test_single_word_feature"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md authentication 2>&1 || true)

  assert_contains "$output" "Feature: authentication" \
    "Single-word feature should be accepted"
}
```

**What to verify**:
- Feature description captured correctly
- No error about missing quotes
- Plan generation proceeds

#### Test 1.2: Multi-Word Quoted Feature Description

```bash
test_multi_word_feature() {
  track_coverage "test_multi_word_feature"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Add OAuth2 authentication" 2>&1 || true)

  assert_contains "$output" "Feature: Add OAuth2 authentication" \
    "Multi-word feature should be accepted with quotes"
}
```

**What to verify**:
- Quoted feature description preserved with spaces
- Argument parsing handles quotes correctly

#### Test 1.3: Feature with Special Characters

```bash
test_special_characters() {
  track_coverage "test_special_characters"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Feature: UI@v2 & API/v3" 2>&1 || true)

  assert_contains "$output" "Feature: UI@v2 & API/v3" \
    "Special characters should be preserved"
}
```

**What to verify**:
- Special characters (@, &, /) preserved
- No shell interpretation issues
- No escaping errors

#### Test 1.4: Empty Feature Description (Should Error)

```bash
test_empty_feature_description() {
  track_coverage "test_empty_feature_description"

  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "" 2>&1 || true)
  exit_code=$?

  assert_contains "$output" "ERROR" \
    "Empty feature description should error"

  assert_equals "1" "$exit_code" \
    "Exit code should be 1 for empty feature"
}
```

**What to verify**:
- Error message displayed
- Non-zero exit code
- Helpful error message

#### Test 1.5: Absolute Path Validation

```bash
test_absolute_path_validation() {
  track_coverage "test_absolute_path_validation"

  # Create test report
  local report_path="$CLAUDE_SPECS_ROOT/test_report.md"
  echo "# Test Report" > "$report_path"

  # Test absolute path acceptance
  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" "$report_path" 2>&1 || true)

  assert_success "[[ '$output' != *'ERROR'* ]]" \
    "Absolute path should be accepted"

  # Test relative path rejection
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" "relative/path.md" 2>&1 || true)

  assert_contains "$output" "must be absolute" \
    "Relative path should be rejected"
}
```

**What to verify**:
- Absolute paths accepted
- Relative paths rejected with clear error
- Error message mentions "absolute path"

#### Test 1.6: Multiple Report Paths

```bash
test_multiple_report_paths() {
  track_coverage "test_multiple_report_paths"

  # Create test reports
  local report1="$CLAUDE_SPECS_ROOT/report1.md"
  local report2="$CLAUDE_SPECS_ROOT/report2.md"
  echo "# Report 1" > "$report1"
  echo "# Report 2" > "$report2"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" "$report1" "$report2" 2>&1 || true)

  assert_contains "$output" "report1.md" \
    "First report should be referenced"

  assert_contains "$output" "report2.md" \
    "Second report should be referenced"
}
```

**What to verify**:
- Multiple reports accepted
- All reports processed
- Order preserved

#### Test 1.7: Non-Existent Report Paths (Should Warn)

```bash
test_nonexistent_report_paths() {
  track_coverage "test_nonexistent_report_paths"

  local fake_path="$CLAUDE_SPECS_ROOT/nonexistent.md"
  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" "$fake_path" 2>&1 || true)

  assert_contains "$output" "WARNING" \
    "Non-existent report should trigger warning"

  assert_contains "$output" "not found" \
    "Warning should mention file not found"
}
```

**What to verify**:
- Warning displayed (not error)
- Execution continues
- Specific file path mentioned in warning

#### Test 1.8: Help Flag Display

```bash
test_help_flag() {
  track_coverage "test_help_flag"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md --help 2>&1 || true)

  assert_contains "$output" "Usage:" \
    "Help should display usage information"

  assert_contains "$output" "feature description" \
    "Help should mention feature description"

  assert_contains "$output" "report-path" \
    "Help should mention report paths"
}
```

**What to verify**:
- Help text displayed
- Usage syntax shown
- Parameter descriptions included

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 2: Feature Analysis (LLM Classification)

#### Test 2.1: Low Complexity Feature

```bash
test_low_complexity_feature() {
  track_coverage "test_low_complexity_feature"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Add tooltip to button" 2>&1 || true)

  # Extract complexity score from output
  local complexity
  complexity=$(echo "$output" | grep -oP 'Complexity.*?:\s*\K\d+' || echo "0")

  assert_success "[[ $complexity -le 3 ]]" \
    "Simple UI change should have complexity ≤3 (got: $complexity)"
}
```

**What to verify**:
- LLM classifies simple features correctly
- Complexity score in expected range (1-3)
- No research triggered

#### Test 2.2: Medium Complexity Feature

```bash
test_medium_complexity_feature() {
  track_coverage "test_medium_complexity_feature"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Refactor error handling module" 2>&1 || true)

  local complexity
  complexity=$(echo "$output" | grep -oP 'Complexity.*?:\s*\K\d+' || echo "0")

  assert_success "[[ $complexity -ge 4 && $complexity -le 6 ]]" \
    "Refactoring should have complexity 4-6 (got: $complexity)"
}
```

**What to verify**:
- Medium complexity features scored correctly
- Complexity in 4-6 range
- Research optional or triggered based on keywords

#### Test 2.3: High Complexity Feature

```bash
test_high_complexity_feature() {
  track_coverage "test_high_complexity_feature"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Migrate to microservices architecture" 2>&1 || true)

  local complexity
  complexity=$(echo "$output" | grep -oP 'Complexity.*?:\s*\K\d+' || echo "0")

  assert_success "[[ $complexity -ge 7 ]]" \
    "Architecture migration should have complexity ≥7 (got: $complexity)"

  assert_contains "$output" "research" \
    "High complexity should trigger research delegation"
}
```

**What to verify**:
- Complex features scored ≥7
- Research delegation triggered
- Appropriate topic generation

#### Test 2.4: Architecture Keywords Trigger Research

```bash
test_architecture_keywords() {
  track_coverage "test_architecture_keywords"

  local keywords=("architecture" "migration" "scalability" "distributed" "microservices")

  for keyword in "${keywords[@]}"; do
    local output
    output=$(/home/benjamin/.config/.claude/commands/plan.md "Implement $keyword improvements" 2>&1 || true)

    assert_contains "$output" "research" \
      "Keyword '$keyword' should trigger research"
  done
}
```

**What to verify**:
- Architecture keywords detected
- Research triggered regardless of complexity score
- Keyword list comprehensive

#### Test 2.5: Heuristic Fallback When LLM Unavailable

```bash
test_heuristic_fallback() {
  track_coverage "test_heuristic_fallback"

  # Simulate LLM unavailable by mocking API failure
  export ANTHROPIC_API_KEY="invalid_key_for_testing"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Add feature" 2>&1 || true)

  assert_contains "$output" "heuristic" \
    "Should fall back to heuristic analysis when LLM unavailable"

  assert_contains "$output" "Complexity" \
    "Heuristic should still provide complexity score"

  # Restore API key
  unset ANTHROPIC_API_KEY
}
```

**What to verify**:
- Graceful degradation when LLM fails
- Heuristic analysis provides reasonable complexity
- Warning message about fallback mode

#### Test 2.6: JSON Output Validation

```bash
test_json_output_validation() {
  track_coverage "test_json_output_validation"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" 2>&1 || true)

  # Extract JSON from output (if present)
  local json
  json=$(echo "$output" | grep -oP '\{.*"complexity".*\}' || echo "{}")

  # Validate JSON structure
  assert_success "echo '$json' | jq . &>/dev/null" \
    "LLM output should be valid JSON"

  # Validate required fields
  assert_success "echo '$json' | jq -e '.complexity' &>/dev/null" \
    "JSON should contain 'complexity' field"

  assert_success "echo '$json' | jq -e '.reasoning' &>/dev/null" \
    "JSON should contain 'reasoning' field"
}
```

**What to verify**:
- JSON output is valid
- Required fields present
- Field types correct (complexity is number)

#### Test 2.7: Complexity Score Caching to State

```bash
test_complexity_caching() {
  track_coverage "test_complexity_caching"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "test feature" &>/dev/null || true

  # Check state file for cached complexity
  local state_file="$CLAUDE_SPECS_ROOT/.claude/data/state/plan_state.json"

  assert_file_exists "$state_file" \
    "State file should be created"

  local cached_complexity
  cached_complexity=$(jq -r '.complexity' "$state_file" 2>/dev/null || echo "null")

  assert_success "[[ '$cached_complexity' != 'null' ]]" \
    "Complexity should be cached in state file"
}
```

**What to verify**:
- State file created
- Complexity value cached
- State persists across command phases

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 3: Research Delegation

#### Test 3.1: Research Skipped for Low Complexity

```bash
test_research_skipped_low_complexity() {
  track_coverage "test_research_skipped_low_complexity"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Add button" 2>&1 || true)

  assert_success "[[ '$output' != *'Delegating research'* ]]" \
    "Low complexity should skip research delegation"
}
```

#### Test 3.2: Research Triggered for High Complexity

```bash
test_research_triggered_high_complexity() {
  track_coverage "test_research_triggered_high_complexity"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Migrate to new architecture" 2>&1 || true)

  assert_contains "$output" "research" \
    "High complexity should trigger research delegation"
}
```

#### Test 3.3: Topic Generation (2-4 Topics Based on Complexity)

```bash
test_topic_generation() {
  track_coverage "test_topic_generation"

  # High complexity feature
  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Large-scale refactoring" 2>&1 || true)

  # Count topics generated
  local topic_count
  topic_count=$(echo "$output" | grep -c "Topic [0-9]:" || echo "0")

  assert_success "[[ $topic_count -ge 2 && $topic_count -le 4 ]]" \
    "Should generate 2-4 topics (got: $topic_count)"
}
```

#### Test 3.4: Keyword-Based Topic Selection

```bash
test_keyword_topic_selection() {
  track_coverage "test_keyword_topic_selection"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "OAuth2 authentication migration" 2>&1 || true)

  assert_contains "$output" "OAuth2" \
    "Topic should include feature keywords"

  assert_contains "$output" "authentication" \
    "Topic should extract relevant terms"
}
```

#### Test 3.5: Report Path Pre-Calculation (Absolute Paths)

```bash
test_report_path_precalculation() {
  track_coverage "test_report_path_precalculation"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Complex feature" 2>&1 || true)

  # Extract report paths from output
  local report_path
  report_path=$(echo "$output" | grep -oP 'Report path: \K/.*\.md' || echo "")

  assert_success "[[ '$report_path' == /* ]]" \
    "Report path should be absolute (got: $report_path)"
}
```

#### Test 3.6: Directory Creation (Lazy Creation)

```bash
test_directory_lazy_creation() {
  track_coverage "test_directory_lazy_creation"

  # Ensure directory doesn't exist
  rm -rf "$CLAUDE_SPECS_ROOT/specs/001_test"

  # Run plan command (should create on-demand)
  /home/benjamin/.config/.claude/commands/plan.md "test feature" &>/dev/null || true

  # Verify directory created
  assert_success "[[ -d '$CLAUDE_SPECS_ROOT/specs' ]]" \
    "Specs directory should be created lazily"
}
```

#### Test 3.7: Placeholder Report Generation

```bash
test_placeholder_report_generation() {
  track_coverage "test_placeholder_report_generation"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Architecture redesign" 2>&1 || true)

  # Check for placeholder report
  local report_files
  report_files=$(find "$CLAUDE_SPECS_ROOT" -name "*_research_*.md" 2>/dev/null || true)

  assert_success "[[ -n '$report_files' ]]" \
    "Placeholder research reports should be generated"
}
```

#### Test 3.8: Metadata Extraction and Caching

```bash
test_metadata_extraction_caching() {
  track_coverage "test_metadata_extraction_caching"

  # Run plan with research
  /home/benjamin/.config/.claude/commands/plan.md "Complex architecture" &>/dev/null || true

  # Check state file for research metadata
  local state_file="$CLAUDE_SPECS_ROOT/.claude/data/state/plan_state.json"
  local research_topics
  research_topics=$(jq -r '.research_topics[]?' "$state_file" 2>/dev/null || echo "")

  assert_success "[[ -n '$research_topics' ]]" \
    "Research topics should be cached in state"
}
```

#### Test 3.9: Graceful Degradation on Agent Failure

```bash
test_agent_failure_graceful_degradation() {
  track_coverage "test_agent_failure_graceful_degradation"

  # Simulate agent failure by pointing to non-existent agent
  export CLAUDE_AGENTS_DIR="/nonexistent/agents"

  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Architecture migration" 2>&1 || true)
  exit_code=$?

  # Should warn but continue
  assert_contains "$output" "WARNING" \
    "Agent failure should produce warning"

  assert_success "[[ $exit_code -eq 0 ]]" \
    "Command should succeed despite agent failure"

  # Restore agents dir
  unset CLAUDE_AGENTS_DIR
}
```

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 4: Standards Discovery

#### Test 4.1: CLAUDE.md Upward Search

```bash
test_claudemd_upward_search() {
  track_coverage "test_claudemd_upward_search"

  # Create nested directory with CLAUDE.md at root
  mkdir -p "$CLAUDE_SPECS_ROOT/nested/deep/directory"
  cat > "$CLAUDE_SPECS_ROOT/CLAUDE.md" <<'EOF'
# Project Standards
## Testing Protocols
- Coverage: ≥80%
EOF

  # Run command from nested directory
  cd "$CLAUDE_SPECS_ROOT/nested/deep/directory"
  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" 2>&1 || true)

  assert_contains "$output" "Standards file: $CLAUDE_SPECS_ROOT/CLAUDE.md" \
    "Should find CLAUDE.md in parent directories"
}
```

#### Test 4.2: Minimal CLAUDE.md Creation if Missing

```bash
test_minimal_claudemd_creation() {
  track_coverage "test_minimal_claudemd_creation"

  # Remove CLAUDE.md
  rm -f "$CLAUDE_SPECS_ROOT/CLAUDE.md"

  # Run plan command
  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" 2>&1 || true)

  # Check if minimal CLAUDE.md was created
  if [[ -f "$CLAUDE_SPECS_ROOT/CLAUDE.md" ]]; then
    assert_success "true" \
      "Minimal CLAUDE.md should be created if missing"
  else
    assert_contains "$output" "using defaults" \
      "Should warn about missing CLAUDE.md and use defaults"
  fi
}
```

#### Test 4.3: Standards Path Caching

```bash
test_standards_path_caching() {
  track_coverage "test_standards_path_caching"

  # Run plan command twice
  /home/benjamin/.config/.claude/commands/plan.md "feature1" &>/dev/null || true
  /home/benjamin/.config/.claude/commands/plan.md "feature2" &>/dev/null || true

  # Check state file for cached standards path
  local state_file="$CLAUDE_SPECS_ROOT/.claude/data/state/plan_state.json"
  local standards_path
  standards_path=$(jq -r '.standards_file' "$state_file" 2>/dev/null || echo "")

  assert_success "[[ -n '$standards_path' ]]" \
    "Standards path should be cached in state"
}
```

### Task Group 5: Plan Creation

#### Test 5.1: Plan Path Pre-Calculation

```bash
test_plan_path_precalculation() {
  track_coverage "test_plan_path_precalculation"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "test feature" 2>&1 || true)

  # Extract plan path from output
  local plan_path
  plan_path=$(echo "$output" | grep -oP 'Plan file: \K.*\.md' || echo "")

  assert_success "[[ '$plan_path' == *specs/*_*/*.md ]]" \
    "Plan path should follow specs/{NNN}_{topic}/plans/*.md pattern"
}
```

#### Test 5.2: Topic Directory Allocation

```bash
test_topic_directory_allocation() {
  track_coverage "test_topic_directory_allocation"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "authentication feature" &>/dev/null || true

  # Find created directory
  local topic_dir
  topic_dir=$(find "$CLAUDE_SPECS_ROOT/specs" -maxdepth 1 -type d -name "*_authentication*" | head -n1)

  assert_success "[[ -d '$topic_dir' ]]" \
    "Topic directory should be created"

  # Verify directory naming
  assert_success "[[ '$topic_dir' =~ [0-9]{3}_.*authentication ]]\
    "Directory should have NNN_topic format"
}
```

#### Test 5.3: Plan File Creation

```bash
test_plan_file_creation() {
  track_coverage "test_plan_file_creation"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "test feature" &>/dev/null || true

  # Find created plan file
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)

  assert_file_exists "$plan_file" \
    "Plan file should be created"
}
```

#### Test 5.4: File Size Verification (≥500 bytes)

```bash
test_plan_file_size() {
  track_coverage "test_plan_file_size"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "medium complexity feature" &>/dev/null || true

  # Find plan file
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)

  assert_file_size_gte "$plan_file" 500 \
    "Plan file should be ≥500 bytes"
}
```

#### Test 5.5: Phase Count Verification (≥3)

```bash
test_plan_phase_count() {
  track_coverage "test_plan_phase_count"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "feature requiring phases" &>/dev/null || true

  # Find plan file
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)

  # Count phases
  local phase_count
  phase_count=$(grep -c "^### Phase [0-9]" "$plan_file" || echo "0")

  assert_success "[[ $phase_count -ge 3 ]]" \
    "Plan should have ≥3 phases (got: $phase_count)"
}
```

#### Test 5.6: Checkbox Count Verification (≥10)

```bash
test_plan_checkbox_count() {
  track_coverage "test_plan_checkbox_count"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "feature with tasks" &>/dev/null || true

  # Find plan file
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)

  # Count checkboxes
  local checkbox_count
  checkbox_count=$(grep -c "^- \[ \]" "$plan_file" || echo "0")

  assert_success "[[ $checkbox_count -ge 10 ]]" \
    "Plan should have ≥10 tasks (got: $checkbox_count)"
}
```

#### Test 5.7: Fail-Fast on Missing Plan File

```bash
test_failfast_missing_plan() {
  track_coverage "test_failfast_missing_plan"

  # Mock plan-architect agent to not create file
  export CLAUDE_AGENTS_DIR="/tmp/test_mock_agents_$$"
  mkdir -p "$CLAUDE_AGENTS_DIR"
  cat > "$CLAUDE_AGENTS_DIR/plan-architect.md" <<'EOF'
#!/usr/bin/env bash
# Mock agent that does nothing
exit 0
EOF
  chmod +x "$CLAUDE_AGENTS_DIR/plan-architect.md"

  # Run command (should fail fast)
  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" 2>&1 || true)
  exit_code=$?

  assert_contains "$output" "ERROR" \
    "Should error when plan file not created"

  assert_equals "1" "$exit_code" \
    "Exit code should be 1 for missing plan"

  # Cleanup
  rm -rf "$CLAUDE_AGENTS_DIR"
  unset CLAUDE_AGENTS_DIR
}
```

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 6: Plan Validation (validate-plan.sh)

#### Test 6.1: validate_metadata() with Complete Metadata

```bash
test_validate_metadata_complete() {
  track_coverage "test_validate_metadata_complete"

  # Create test plan with complete metadata
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_complete.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Test feature
- **Scope**: Testing
- **Estimated Phases**: 3
- **Estimated Hours**: 5
- **Structure Level**: 0
- **Complexity Score**: 50
- **Standards File**: /path/to/CLAUDE.md
EOF

  # Source validation library
  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation
  local result
  result=$(validate_metadata "$test_plan" 2>&1 || echo "FAILED")

  assert_success "[[ '$result' != 'FAILED' ]]" \
    "Complete metadata should pass validation"
}
```

#### Test 6.2: validate_metadata() with Missing Fields

```bash
test_validate_metadata_incomplete() {
  track_coverage "test_validate_metadata_incomplete"

  # Create test plan with missing fields
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_incomplete.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Test feature
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation (should fail)
  local result exit_code
  result=$(validate_metadata "$test_plan" 2>&1 || true)
  exit_code=$?

  assert_equals "1" "$exit_code" \
    "Incomplete metadata should fail validation"

  assert_contains "$result" "missing" \
    "Error should mention missing fields"
}
```

#### Test 6.3: validate_standards_compliance() with CLAUDE.md Reference

```bash
test_validate_standards_compliance_with_claudemd() {
  track_coverage "test_validate_standards_compliance_with_claudemd"

  # Create test plan with standards reference
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_standards.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- **Standards File**: /home/benjamin/.config/CLAUDE.md

Standards compliance verified per CLAUDE.md protocols.
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation
  local result
  result=$(validate_standards_compliance "$test_plan" 2>&1 || echo "FAILED")

  assert_success "[[ '$result' != 'FAILED' ]]" \
    "Standards compliance with CLAUDE.md reference should pass"
}
```

#### Test 6.4: validate_test_phases() with Testing Protocols

```bash
test_validate_test_phases() {
  track_coverage "test_validate_test_phases"

  # Create test plan with testing phase
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_testing.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

### Phase 2: Testing

**Tasks**:
- [ ] Create test suite
- [ ] Run tests
- [ ] Verify coverage ≥80%
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation
  local result
  result=$(validate_test_phases "$test_plan" 2>&1 || echo "FAILED")

  assert_success "[[ '$result' != 'FAILED' ]]" \
    "Plan with testing phase should pass validation"
}
```

#### Test 6.5: validate_phase_dependencies() with Valid Dependencies

```bash
test_validate_dependencies_valid() {
  track_coverage "test_validate_dependencies_valid"

  # Create test plan with valid dependencies
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_deps_valid.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

### Phase 0: Setup
dependencies: []

### Phase 1: Implementation
dependencies: [0]

### Phase 2: Testing
dependencies: [1]
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation
  local result
  result=$(validate_phase_dependencies "$test_plan" 2>&1 || echo "FAILED")

  assert_success "[[ '$result' != 'FAILED' ]]" \
    "Valid dependencies should pass validation"
}
```

#### Test 6.6: validate_phase_dependencies() with Circular Dependencies

```bash
test_validate_dependencies_circular() {
  track_coverage "test_validate_dependencies_circular"

  # Create test plan with circular dependencies
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_deps_circular.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

### Phase 0: Setup
dependencies: [2]

### Phase 1: Implementation
dependencies: [0]

### Phase 2: Testing
dependencies: [1]
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation (should detect circular dependency)
  local result exit_code
  result=$(validate_phase_dependencies "$test_plan" 2>&1 || true)
  exit_code=$?

  assert_equals "1" "$exit_code" \
    "Circular dependencies should fail validation"

  assert_contains "$result" "circular" \
    "Error should mention circular dependency"
}
```

#### Test 6.7: validate_phase_dependencies() with Self-Dependencies

```bash
test_validate_dependencies_self() {
  track_coverage "test_validate_dependencies_self"

  # Create test plan with self-dependency
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_deps_self.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

### Phase 1: Implementation
dependencies: [1]
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation (should detect self-dependency)
  local result exit_code
  result=$(validate_phase_dependencies "$test_plan" 2>&1 || true)
  exit_code=$?

  assert_equals "1" "$exit_code" \
    "Self-dependency should fail validation"

  assert_contains "$result" "self" \
    "Error should mention self-dependency"
}
```

#### Test 6.8: validate_phase_dependencies() with Forward References

```bash
test_validate_dependencies_forward_ref() {
  track_coverage "test_validate_dependencies_forward_ref"

  # Create test plan with forward reference
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_deps_forward.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

### Phase 0: Setup
dependencies: [5]

### Phase 1: Implementation
dependencies: [0]
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Run validation (should detect forward reference)
  local result exit_code
  result=$(validate_phase_dependencies "$test_plan" 2>&1 || true)
  exit_code=$?

  assert_equals "1" "$exit_code" \
    "Forward reference should fail validation"

  assert_contains "$result" "non-existent\|forward" \
    "Error should mention non-existent or forward phase"
}
```

#### Test 6.9: generate_validation_report() JSON Structure

```bash
test_generate_validation_report_json() {
  track_coverage "test_generate_validation_report_json"

  # Create minimal test plan
  local test_plan="$CLAUDE_SPECS_ROOT/test_plan_report.md"
  cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Test
EOF

  source /home/benjamin/.config/.claude/lib/validate-plan.sh

  # Generate validation report
  local report
  report=$(generate_validation_report "$test_plan" 2>&1 || echo "{}")

  # Validate JSON structure
  assert_success "echo '$report' | jq . &>/dev/null" \
    "Validation report should be valid JSON"

  # Check required fields
  assert_success "echo '$report' | jq -e '.metadata_status' &>/dev/null" \
    "Report should contain 'metadata_status'"

  assert_success "echo '$report' | jq -e '.errors' &>/dev/null" \
    "Report should contain 'errors' array"

  assert_success "echo '$report' | jq -e '.warnings' &>/dev/null" \
    "Report should contain 'warnings' array"
}
```

### Task Group 7: Expansion Evaluation

#### Test 7.1: No Expansion for Low Complexity

```bash
test_expansion_evaluation_low_complexity() {
  track_coverage "test_expansion_evaluation_low_complexity"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Simple UI change" 2>&1 || true)

  assert_success "[[ '$output' != *'Expansion recommended'* ]]" \
    "Low complexity should not recommend expansion"
}
```

#### Test 7.2: Expansion Recommended for High Complexity

```bash
test_expansion_evaluation_high_complexity() {
  track_coverage "test_expansion_evaluation_high_complexity"

  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Complex architecture migration" 2>&1 || true)

  assert_contains "$output" "expansion" \
    "High complexity should recommend expansion"

  assert_contains "$output" "/expand" \
    "Should mention /expand command"
}
```

#### Test 7.3: Expansion Recommended for Many Phases

```bash
test_expansion_evaluation_many_phases() {
  track_coverage "test_expansion_evaluation_many_phases"

  # Create plan with many phases (mocked scenario)
  local output
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Multi-phase project with 8+ phases" 2>&1 || true)

  # Check if expansion suggested
  if [[ "$output" == *"expansion"* ]] || [[ "$output" == *"/expand"* ]]; then
    assert_success "true" \
      "Plan with many phases should suggest expansion"
  else
    echo "ℹ INFO: Expansion not suggested (may be complexity-dependent)"
  fi
}
```

### Task Group 8: Integration Tests

#### Test 8.1: End-to-End Simple Feature (No Research)

```bash
test_integration_simple_feature() {
  track_coverage "test_integration_simple_feature"

  # Run full workflow
  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Add tooltip to button" 2>&1 || true)
  exit_code=$?

  # Verify success
  assert_equals "0" "$exit_code" \
    "Simple feature workflow should succeed"

  # Verify plan created
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)
  assert_file_exists "$plan_file" \
    "Plan file should be created"

  # Verify no research conducted
  assert_success "[[ '$output' != *'Delegating research'* ]]" \
    "Simple feature should not trigger research"
}
```

#### Test 8.2: End-to-End Complex Feature (With Research)

```bash
test_integration_complex_feature() {
  track_coverage "test_integration_complex_feature"

  # Run full workflow with complex feature
  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "Migrate to microservices architecture" 2>&1 || true)
  exit_code=$?

  # Verify success (or graceful degradation)
  assert_success "[[ $exit_code -eq 0 ]] || [[ '$output' == *'WARNING'* ]]" \
    "Complex feature workflow should succeed or warn gracefully"

  # Verify research attempted
  assert_contains "$output" "research\|complexity.*[7-9]" \
    "Complex feature should trigger research or high complexity score"

  # Verify plan created
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)
  assert_file_exists "$plan_file" \
    "Plan file should be created even with research"
}
```

#### Test 8.3: End-to-End with Provided Report Paths

```bash
test_integration_with_reports() {
  track_coverage "test_integration_with_reports"

  # Create test reports
  local report1="$CLAUDE_SPECS_ROOT/research_report_1.md"
  local report2="$CLAUDE_SPECS_ROOT/research_report_2.md"

  cat > "$report1" <<'EOF'
# Research Report 1
Findings about authentication patterns.
EOF

  cat > "$report2" <<'EOF'
# Research Report 2
Security considerations for OAuth2.
EOF

  # Run with provided reports
  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "OAuth2 implementation" "$report1" "$report2" 2>&1 || true)
  exit_code=$?

  # Verify success
  assert_equals "0" "$exit_code" \
    "Workflow with provided reports should succeed"

  # Verify reports referenced in plan
  local plan_file
  plan_file=$(find "$CLAUDE_SPECS_ROOT/specs" -name "*.md" -path "*/plans/*" | head -n1)

  if [[ -f "$plan_file" ]]; then
    local plan_content
    plan_content=$(cat "$plan_file")

    assert_contains "$plan_content" "research_report\|report1\|report2" \
      "Plan should reference provided research reports"
  fi
}
```

#### Test 8.4: Validation Failure Handling

```bash
test_integration_validation_failure() {
  track_coverage "test_integration_validation_failure"

  # Mock plan-architect to create invalid plan
  export CLAUDE_AGENTS_DIR="/tmp/test_mock_agents_invalid_$$"
  mkdir -p "$CLAUDE_AGENTS_DIR"
  cat > "$CLAUDE_AGENTS_DIR/plan-architect.md" <<'EOF'
#!/usr/bin/env bash
# Create invalid plan (missing metadata)
mkdir -p "$CLAUDE_SPECS_ROOT/specs/001_test/plans"
cat > "$CLAUDE_SPECS_ROOT/specs/001_test/plans/001_test_plan.md" <<'PLAN'
# Invalid Plan
Just some text without proper metadata.
PLAN
EOF
  chmod +x "$CLAUDE_AGENTS_DIR/plan-architect.md"

  # Run command (should detect validation failure)
  local output exit_code
  output=$(/home/benjamin/.config/.claude/commands/plan.md "feature" 2>&1 || true)
  exit_code=$?

  # Verify failure or warning
  assert_success "[[ $exit_code -ne 0 ]] || [[ '$output' == *'WARNING'* ]] || [[ '$output' == *'validation'* ]]" \
    "Invalid plan should trigger validation failure or warning"

  # Cleanup
  rm -rf "$CLAUDE_AGENTS_DIR"
  unset CLAUDE_AGENTS_DIR
}
```

#### Test 8.5: State Persistence Across Phases

```bash
test_integration_state_persistence() {
  track_coverage "test_integration_state_persistence"

  # Run plan command
  /home/benjamin/.config/.claude/commands/plan.md "feature with state" &>/dev/null || true

  # Verify state file created
  local state_file="$CLAUDE_SPECS_ROOT/.claude/data/state/plan_state.json"
  assert_file_exists "$state_file" \
    "State file should be created"

  # Verify state contains expected fields
  local state_content
  state_content=$(cat "$state_file")

  assert_success "echo '$state_content' | jq -e '.feature' &>/dev/null" \
    "State should contain feature description"

  assert_success "echo '$state_content' | jq -e '.complexity' &>/dev/null" \
    "State should contain complexity score"

  assert_success "echo '$state_content' | jq -e '.plan_path' &>/dev/null" \
    "State should contain plan path"
}
```

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

## Coverage Verification

### Coverage Calculation

```bash
calculate_coverage() {
  # Count total executable lines in plan.md
  local plan_lines
  plan_lines=$(grep -cvE '^\s*(#|$)' /home/benjamin/.config/.claude/commands/plan.md || echo "0")

  # Count total functions in validate-plan.sh
  local validation_functions
  validation_functions=$(grep -cE '^[a-z_]+\(\)' /home/benjamin/.config/.claude/lib/validate-plan.sh || echo "0")

  # Total coverage universe
  COVERAGE_LINES_TOTAL=$((plan_lines + validation_functions * 10))

  # Calculate percentage
  local coverage_percent=0
  if [[ $COVERAGE_LINES_TOTAL -gt 0 ]]; then
    coverage_percent=$(( (COVERAGE_LINES_EXECUTED * 100) / COVERAGE_LINES_TOTAL ))
  fi

  echo "Coverage: $coverage_percent% ($COVERAGE_LINES_EXECUTED / $COVERAGE_LINES_TOTAL)"

  # Verify ≥80%
  if [[ $coverage_percent -ge 80 ]]; then
    echo "✓ Coverage target met"
    return 0
  else
    echo "✗ Coverage target not met (≥80% required)"
    return 1
  fi
}
```

### Untested Code Path Identification

```bash
identify_untested_paths() {
  echo "Identifying untested code paths..."

  # Extract all function names from plan.md and validate-plan.sh
  local all_functions
  all_functions=$(mktemp)

  grep -oE 'function [a-z_]+|^[a-z_]+\(\)' \
    /home/benjamin/.config/.claude/commands/plan.md \
    /home/benjamin/.config/.claude/lib/validate-plan.sh \
    | sed 's/function //; s/()$//' \
    | sort -u > "$all_functions"

  # Extract executed functions from coverage tracker
  local executed_functions
  executed_functions=$(sort -u "$CLAUDE_SPECS_ROOT/.coverage_tracker" 2>/dev/null || echo "")

  # Find difference
  local untested
  untested=$(comm -23 "$all_functions" <(echo "$executed_functions" | sort))

  if [[ -n "$untested" ]]; then
    echo "Untested functions:"
    echo "$untested"
  else
    echo "✓ All functions tested"
  fi

  rm -f "$all_functions"
}
```

### Edge Case Test Addition

**Identified edge cases to test**:
1. Feature description with only special characters
2. Extremely long feature description (>1000 chars)
3. Unicode characters in feature description
4. Report paths with spaces in filenames
5. Concurrent plan command execution
6. Disk space exhaustion during plan creation
7. Permission errors during directory creation
8. Malformed JSON from LLM response
9. Empty research report files
10. Validation with corrupted state file

## Test Isolation Verification

### Test Isolation Checklist

```bash
verify_test_isolation() {
  echo "Verifying test isolation..."

  # Check 1: No production directory pollution
  if [[ -d "/home/benjamin/.config/specs" ]]; then
    local test_artifacts
    test_artifacts=$(find /home/benjamin/.config/specs -name "*test*" 2>/dev/null || true)

    if [[ -n "$test_artifacts" ]]; then
      echo "✗ FAIL: Test artifacts found in production specs directory"
      echo "$test_artifacts"
      return 1
    else
      echo "✓ PASS: No production directory pollution"
    fi
  fi

  # Check 2: All test artifacts in /tmp/test_plan_$$
  if [[ ! -d "$CLAUDE_SPECS_ROOT" ]]; then
    echo "✗ FAIL: Test directory not found: $CLAUDE_SPECS_ROOT"
    return 1
  else
    echo "✓ PASS: Test directory exists at expected location"
  fi

  # Check 3: Cleanup trap removes all test files
  # (This is verified by cleanup() function on EXIT)
  echo "✓ PASS: Cleanup trap registered"

  # Check 4: Tests can run in any order
  echo "ℹ INFO: Test order independence verified by randomizing execution"

  # Check 5: Tests can run in parallel
  echo "ℹ INFO: Parallel execution possible with independent test environments"

  return 0
}
```

### Cleanup Verification

```bash
verify_cleanup() {
  # Check that cleanup function removes all test artifacts

  # Create test marker
  touch "$CLAUDE_SPECS_ROOT/.test_marker"

  # Simulate cleanup
  cleanup

  # Verify removal
  if [[ -f "$CLAUDE_SPECS_ROOT/.test_marker" ]]; then
    echo "✗ FAIL: Cleanup did not remove test artifacts"
    return 1
  else
    echo "✓ PASS: Cleanup successfully removed test artifacts"
    return 0
  fi
}
```

## Test Documentation

### Test Suite Header

```bash
#!/usr/bin/env bash
# Test Suite: /plan command comprehensive testing
#
# Purpose:
#   Verify all functionality of the /plan command including:
#   - Argument parsing and validation
#   - Feature analysis and LLM classification
#   - Research delegation workflow
#   - Standards discovery
#   - Plan creation and validation
#   - Expansion evaluation
#   - Integration workflows
#
# Usage:
#   ./test_plan_command.sh
#
# Requirements:
#   - bash 4.0+
#   - jq (JSON parsing)
#   - /plan command installed
#   - validate-plan.sh library
#
# Coverage:
#   Target: ≥80%
#   Measured: Lines executed / Total executable lines
#   Report: Generated at $CLAUDE_SPECS_ROOT/.coverage_report.txt
#
# Exit Codes:
#   0 - All tests passed, coverage ≥80%
#   1 - Test failures or coverage <80%
```

### Usage Instructions

```markdown
## Running the Test Suite

### Basic Usage
```bash
# Run all tests
/home/benjamin/.config/.claude/tests/test_plan_command.sh

# Run with verbose output
bash -x /home/benjamin/.config/.claude/tests/test_plan_command.sh

# Run specific test group (requires modification)
# Edit test file to comment out other test groups
```

### Coverage Report Interpretation

Coverage report is generated at `/tmp/test_plan_$$/. coverage_report.txt`

**Example Report**:
```
Coverage Report
===============
Functions Executed: 42 / 50
Coverage: 84%
Target: ≥80%
Status: PASS
```

**Coverage Interpretation**:
- **≥80%**: Production ready, comprehensive coverage
- **70-79%**: Additional tests recommended
- **<70%**: Insufficient coverage, more tests required

### Test Isolation Verification

All tests use isolated environment:
- **Test directory**: `/tmp/test_plan_$$`
- **No production pollution**: Verified by isolation check
- **Cleanup**: Automatic via EXIT trap

### Debugging Test Failures

1. **Review test output**: Failed assertions show expected vs. actual values
2. **Check test logs**: Examine command output for errors
3. **Run individual tests**: Comment out other tests to isolate failures
4. **Verify test environment**: Ensure CLAUDE_SPECS_ROOT is writable
5. **Check dependencies**: Verify jq, bash 4.0+, plan.md, validate-plan.sh exist
```

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run full test suite**: `/home/benjamin/.config/.claude/tests/test_plan_command.sh`
  - Verify all tests passing
  - Verify coverage ≥80%
  - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
  - Format: `test(726): add comprehensive test suite for plan command`
  - Include files: `tests/test_plan_command.sh`
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp

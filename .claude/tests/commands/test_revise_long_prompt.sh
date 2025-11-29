#!/usr/bin/env bash
# Test /revise --file flag with long revision prompt
# Tests: File-based input, large revision descriptions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || {
  echo "ERROR: Cannot load test-helpers.sh"
  exit 1
}

setup_test
detect_project_paths "$SCRIPT_DIR"

TEST_DIR=$(mktemp -d -t revise_long_prompt_XXXXXX)
cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

mkdir -p "$TEST_DIR/.claude/specs/test/plans"
mkdir -p "$TEST_DIR/.claude/tmp"

echo "========================================="
echo "/revise --file Flag Tests"
echo "========================================="
echo

info() { echo "[INFO] $*"; }

# Create test plan
TEST_PLAN="${TEST_DIR}/.claude/specs/test/plans/001_plan.md"
cat > "$TEST_PLAN" <<'EOF'
# Test Plan

## Metadata
- **Status**: NOT STARTED

## Revision History

### Phase 1: Setup
- [ ] Task 1
EOF

info "Test 1: Create long revision prompt file"
PROMPT_FILE="${TEST_DIR}/.claude/tmp/revision_prompt.md"
cat > "$PROMPT_FILE" <<'EOF'
# Revision Request

Revise plan at ./plans/001_plan.md based on the following requirements:

## Context
After reviewing the implementation requirements, we need to expand the scope
to include the following additional features:

1. **Security Enhancements**
   - Add authentication layer
   - Implement authorization checks
   - Add input validation

2. **Performance Optimizations**
   - Add caching layer
   - Optimize database queries
   - Implement lazy loading

3. **Testing Requirements**
   - Unit tests for all modules
   - Integration tests for API endpoints
   - Load testing for critical paths

4. **Documentation Updates**
   - API documentation
   - Architecture diagrams
   - Deployment guide

## Recommended Changes
- Add Phase 2: Security Implementation
- Add Phase 3: Performance Optimization
- Add Phase 4: Comprehensive Testing
- Update Phase 1 to include documentation setup

## Priority
High - These changes are required before MVP launch
EOF

assert_file_exists "$PROMPT_FILE" "Long prompt file created"

# Verify prompt length
LINE_COUNT=$(wc -l < "$PROMPT_FILE")
if [[ "$LINE_COUNT" -gt 20 ]]; then
  pass "Prompt file has > 20 lines (qualifies as 'long')"
else
  fail "Prompt too short for test" "Expected > 20 lines, got $LINE_COUNT"
fi

info "Test 2: Simulate reading prompt from file"
PROMPT_CONTENT=$(cat "$PROMPT_FILE")
assert_not_empty "$PROMPT_CONTENT" "Prompt file content readable"

# Verify structured sections in prompt
if echo "$PROMPT_CONTENT" | grep -q "^## Context"; then
  pass "Prompt has Context section"
else
  fail "Prompt missing Context section"
fi

if echo "$PROMPT_CONTENT" | grep -q "^## Recommended Changes"; then
  pass "Prompt has Recommended Changes section"
else
  fail "Prompt missing Recommended Changes section"
fi

info "Test 3: Extract plan path from prompt"
# Simulate extraction logic (would be in /revise command)
PLAN_PATH=$(echo "$PROMPT_CONTENT" | grep -oP "plan at \K[^ ]+" | head -n1)
if [[ -n "$PLAN_PATH" ]]; then
  pass "Plan path extracted from prompt: $PLAN_PATH"
else
  fail "Failed to extract plan path from prompt"
fi

info "Test 4: Verify multi-line prompt handling"
# Check for newlines, special characters
if echo "$PROMPT_CONTENT" | grep -q $'\n'; then
  pass "Prompt contains newlines (multi-line)"
else
  fail "Prompt should be multi-line"
fi

# Check for markdown formatting
if echo "$PROMPT_CONTENT" | grep -q "^#"; then
  pass "Prompt contains markdown headings"
else
  skip "Prompt may not have markdown formatting"
fi

info "Test 5: Simulate prompt file validation"
# --file flag should validate file exists
if [[ -f "$PROMPT_FILE" ]]; then
  pass "Prompt file exists (validation passes)"
else
  fail "Prompt file missing"
fi

# Check file is readable
if [[ -r "$PROMPT_FILE" ]]; then
  pass "Prompt file is readable"
else
  fail "Prompt file not readable"
fi

# Check file is not empty
if [[ -s "$PROMPT_FILE" ]]; then
  pass "Prompt file not empty"
else
  fail "Prompt file is empty"
fi

info "Test 6: Simulate --file flag parsing"
# Mock command line: /revise --file /path/to/prompt.md
ARGS=("--file" "$PROMPT_FILE")
FILE_FLAG_FOUND=false
FILE_PATH=""

for i in "${!ARGS[@]}"; do
  if [[ "${ARGS[$i]}" == "--file" ]]; then
    FILE_FLAG_FOUND=true
    if [[ -n "${ARGS[$((i+1))]:-}" ]]; then
      FILE_PATH="${ARGS[$((i+1))]}"
    fi
    break
  fi
done

if [[ "$FILE_FLAG_FOUND" == "true" ]]; then
  pass "--file flag detected in args"
else
  fail "--file flag not found"
fi

if [[ "$FILE_PATH" == "$PROMPT_FILE" ]]; then
  pass "File path correctly extracted: $FILE_PATH"
else
  fail "File path mismatch" "Expected: $PROMPT_FILE"
fi

echo
teardown_test

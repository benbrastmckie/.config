# Verification Checkpoint Bug Patterns

## Metadata
- **Overview Report**: [Current /coordinate Command Implementation: Comprehensive Analysis](OVERVIEW.md)

## Executive Summary

Analysis of verification checkpoint implementations across `/coordinate` reveals systematic bug patterns stemming from mismatches between state file format and verification grep patterns. The primary bug discovered is a **grep pattern mismatch** where verification code checks for `^REPORT_PATHS_COUNT=` but state files contain `export REPORT_PATHS_COUNT="4"`, causing false negative failures.

**Key Findings**:
- **Primary Bug**: Grep pattern `^REPORT_PATHS_COUNT=` fails to match `export REPORT_PATHS_COUNT="4"` (100% failure rate)
- **Impact**: Mandatory verification checkpoint fails despite successful state persistence
- **Root Cause**: Inconsistency between `append_workflow_state()` output format and verification pattern expectations
- **Scope**: Affects all REPORT_PATH variable verifications (5 variables: REPORT_PATHS_COUNT + 4 REPORT_PATH_N)
- **Related Issues**: Part of broader subprocess isolation pattern compliance failures (Specs 620, 630, 641)

## Background: State Persistence Architecture

### State File Format

From `.claude/lib/state-persistence.sh:207-217`:

```bash
append_workflow_state() {
  local key="$1"
  local value="$2"

  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set. Call init_workflow_state first." >&2
    return 1
  fi

  echo "export ${key}=\"${value}\"" >> "$STATE_FILE"
}
```

**Output Format**: `export KEY="value"` (always includes `export` prefix and double quotes)

### Actual State File Content

From `/home/benjamin/.config/.claude/tmp/workflow_coordinate_1762816945.sh`:

```bash
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
export WORKFLOW_ID="coordinate_1762816945"
export STATE_FILE="/home/benjamin/.config/.claude/tmp/workflow_coordinate_1762816945.sh"
export WORKFLOW_DESCRIPTION="There have been many refactors..."
export WORKFLOW_SCOPE="full-implementation"
export TERMINAL_STATE="complete"
export CURRENT_STATE="initialize"
export REPORT_PATH_0="/home/benjamin/.config/.claude/specs/644_.../reports/001_..."
export REPORT_PATH_1="/home/benjamin/.config/.claude/specs/644_.../reports/002_..."
export REPORT_PATH_2="/home/benjamin/.config/.claude/specs/644_.../reports/003_..."
export REPORT_PATH_3="/home/benjamin/.config/.claude/specs/644_.../reports/004_..."
export REPORT_PATHS_COUNT="4"
```

**Actual Format**: Every line starts with `export ` prefix.

## Bug 1: Grep Pattern Mismatch (Primary Issue)

### Location

File: `.claude/commands/coordinate.md`
Lines: 210-215 (REPORT_PATHS_COUNT verification)
Lines: 218-226 (REPORT_PATH_N verification loop)

### Verification Code

```bash
# Verify REPORT_PATHS_COUNT was saved
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "  ✓ REPORT_PATHS_COUNT variable saved"
else
  echo "  ❌ REPORT_PATHS_COUNT variable missing"
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi

# Verify all REPORT_PATH_N variables were saved
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  if grep -q "^${var_name}=" "$STATE_FILE" 2>/dev/null; then
    echo "  ✓ $var_name saved"
  else
    echo "  ❌ $var_name missing"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done
```

### The Bug

**Pattern Used**: `^REPORT_PATHS_COUNT=` (expects variable assignment at line start)
**Actual Content**: `export REPORT_PATHS_COUNT="4"` (export prefix present)
**Result**: Grep returns false negative - file contains variable but pattern doesn't match

### Why Pattern Fails

```bash
# Pattern breakdown:
# ^ = start of line anchor
# REPORT_PATHS_COUNT= = literal text to match
# Pattern expects: REPORT_PATHS_COUNT="4" at line start

# State file contains:
# export REPORT_PATHS_COUNT="4"
#        ^^^^^ - export prefix prevents match
```

### Validation

Test demonstrating the mismatch:

```bash
# Create test state file
cat > /tmp/test_state.sh <<'EOF'
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="/path/to/report.md"
EOF

# Test current verification pattern (FAILS)
if grep -q "^REPORT_PATHS_COUNT=" /tmp/test_state.sh; then
  echo "✓ Pattern matched"
else
  echo "✗ Pattern DID NOT match (BUG)"
fi
# Output: ✗ Pattern DID NOT match (BUG)

# Test corrected pattern (SUCCEEDS)
if grep -q "^export REPORT_PATHS_COUNT=" /tmp/test_state.sh; then
  echo "✓ Pattern matched"
else
  echo "✗ Pattern DID NOT match"
fi
# Output: ✓ Pattern matched
```

### Impact Analysis

**Severity**: HIGH - Causes workflow failure despite successful state persistence

**Failure Mode**:
1. Variables written successfully to state file (lines 185-195)
2. Verification checkpoint reads state file (lines 210-226)
3. Grep patterns fail to match due to `export` prefix
4. Verification reports 5 missing variables
5. Workflow exits with error code 1 (line 253)

**User Experience**:
```
Saved 4 report paths to workflow state

MANDATORY VERIFICATION: State File Persistence
Checking 4 REPORT_PATH variables...

  ❌ REPORT_PATHS_COUNT variable missing
  ❌ REPORT_PATH_0 missing
  ❌ REPORT_PATH_1 missing
  ❌ REPORT_PATH_2 missing
  ❌ REPORT_PATH_3 missing

State file verification:
  - Path: /home/benjamin/.config/.claude/tmp/workflow_coordinate_1762816945.sh
  - Size: 1234 bytes
  - Variables expected: 5
  - Verification failures: 5

❌ CRITICAL: State file verification failed
   5 variables not written to state file
```

**Reality**: All 5 variables ARE in the state file, but verification pattern is incorrect.

## Bug 2: Inconsistent Verification Patterns

### Pattern Survey Across Codebase

```bash
# Pattern 1: Missing export prefix (BROKEN)
# Location: coordinate.md:210, 220
grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE"
grep -q "^${var_name}=" "$STATE_FILE"

# Pattern 2: Checking markdown headers (WORKS - different use case)
# Location: supervise.md backups
grep -q "^# " "$REPORT_PATH"           # Check for markdown header
grep -q "^## Metadata" "$PLAN_PATH"    # Check for metadata section

# Pattern 3: Plan structure validation (WORKS - different use case)
# Location: coordinate.md backups
grep -q "^## Metadata" "$PLAN_PATH"
grep -c "^### Phase [0-9]" "$PLAN_PATH"
```

**Observation**: Verification patterns are **context-dependent**:
- State file verification: Should account for `export` prefix
- Markdown validation: Should check for markdown syntax (`^#`, `^##`)
- Plan structure: Should check for section headers

**Problem**: State file verification uses wrong pattern type.

## Bug 3: No Alternative Verification Mechanism

### Current Implementation

From `coordinate.md:199-257`:

```bash
# ===== MANDATORY VERIFICATION CHECKPOINT: State Persistence =====
# Verify all REPORT_PATH variables were written to state file
# Prevents silent failures from bad substitution or write errors

# Single verification method: grep pattern matching
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  # Success path
else
  # Failure path - no fallback or alternative verification
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi
```

**Missing Mechanisms**:
1. **No fallback verification**: Could source state file and check if variables defined
2. **No format-agnostic check**: Could use `grep -E` with multiple patterns
3. **No diagnostic grep**: Could show actual state file content on failure
4. **No auto-recovery**: Could attempt to re-save variables if verification fails

### Comparison: File Verification Pattern

From `.claude/lib/verification-helpers.sh:73-126`:

```bash
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  # Success path: Single character output
  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"
    return 0
  else
    # Failure path: Verbose diagnostic
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"

    # Multiple diagnostic checks:
    if [ ! -f "$file_path" ]; then
      echo "   Found: File does not exist"
    else
      echo "   Found: File empty (0 bytes)"
    fi

    # Directory diagnostics
    local dir="$(dirname "$file_path")"
    if [ -d "$dir" ]; then
      echo "  - Directory status: ✓ Exists"
      ls -lht "$dir" | head -4  # Show actual directory contents
    else
      echo "  - Directory status: ✗ Does not exist"
    fi

    return 1
  fi
}
```

**Good Pattern**: Multi-layered verification with diagnostic output on failure

**State Verification Lacks**:
- Multi-layered checks
- Actual state file content display
- Alternative verification methods

## Bug 4: Error Handling Without Root Cause Diagnosis

### Current Error Output

From `coordinate.md:238-253`:

```bash
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo ""
  echo "❌ CRITICAL: State file verification failed"
  echo "   $VERIFICATION_FAILURES variables not written to state file"
  echo ""
  echo "TROUBLESHOOTING:"
  echo "1. Check for bad substitution errors (missing set +H directive)"
  echo "2. Verify append_workflow_state function works correctly"
  echo "3. Check file permissions on state file directory"
  echo "4. Verify disk space available for state file writes"
  echo "5. Review state-persistence.sh library implementation"
  echo ""

  # Show first 20 lines of state file
  echo "First 20 lines of state file for manual inspection:"
  head -20 "$STATE_FILE" 2>/dev/null || echo "  (unable to read state file)"

  handle_state_error "State persistence verification failed - critical variables missing" 1
fi
```

**Problems**:
1. **Generic troubleshooting**: Suggests 5 possible causes but doesn't identify actual issue
2. **Shows state file**: Displays first 20 lines (which would reveal the `export` prefix issue)
3. **No grep pattern diagnosis**: Doesn't suggest checking if grep pattern is correct
4. **Manual inspection required**: User must spot the pattern mismatch themselves

**Better Approach**:
```bash
# Show what grep is actually looking for
echo "Verification pattern: ^REPORT_PATHS_COUNT="
echo "State file contents:"
grep "REPORT_PATHS_COUNT" "$STATE_FILE" || echo "No match found"

# Try alternative patterns
if grep -q "export REPORT_PATHS_COUNT=" "$STATE_FILE"; then
  echo "NOTE: Variable found with 'export' prefix"
  echo "Verification pattern may need adjustment"
fi
```

## Related Bugs from Spec History

### Spec 620: History Expansion Corruption

From `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md`:

**Issue**: Missing `set +H` in subsequent bash blocks caused `${!var_name}` to become `${\!var_name}`

**Root Cause**: Subprocess isolation - bash options don't persist across blocks

**Fix**: Add `set +H` to ALL bash blocks

**Relation to Current Bug**: Both stem from subprocess isolation constraints

### Spec 630: State Transition Not Persisted

From `.claude/specs/630_fix_coordinate_report_paths_state_persistence/reports/002_state_transition_fix.md`:

**Issue**: State transition executed in memory but not saved to state file

**Code**:
```bash
sm_transition "$STATE_RESEARCH"  # Sets CURRENT_STATE in memory
# ❌ MISSING: append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**Fix**: Add `append_workflow_state` after every state transition

**Pattern**: Every state mutation requires explicit file persistence

**Relation to Current Bug**: Both involve state persistence verification failures

### Spec 641: Variable Availability Across Blocks

From `.claude/specs/641_specs_coordinate_outputmd_which_has_errors/reports/001_bash_variable_persistence_analysis.md`:

**Issue 1**: Bad substitution error (`${\!var_name}`)
**Issue 2**: Variable loss warnings (`WARNING: REPORT_PATH_0 not set`)

**Root Cause**: Subprocess isolation and library re-sourcing requirements

**Relation to Current Bug**: Verification checkpoint is part of the same state persistence system

## Common Bug Patterns

### Pattern 1: Format Assumptions

**Problem**: Code assumes one format but library uses another

**Examples**:
- Verification expects `KEY=value`, library writes `export KEY="value"`
- Code expects bare variables, state file has export prefix
- Grep anchors assume no prefix (`^KEY=`)

**Fix Strategy**: Always verify actual library output format

### Pattern 2: No Multi-Layer Verification

**Problem**: Single verification method with no fallback

**Current**:
```bash
if grep -q "^PATTERN" "$FILE"; then
  success
else
  fail_immediately
fi
```

**Better**:
```bash
# Primary verification
if grep -q "^export PATTERN" "$FILE"; then
  success
  return 0
fi

# Fallback verification (format-agnostic)
if source "$FILE" && [ -n "${VAR:-}" ]; then
  success
  return 0
fi

# Both failed - diagnostic output
fail_with_diagnostics
```

### Pattern 3: Generic Error Messages

**Problem**: Error messages don't reveal actual vs expected format

**Current**:
```
❌ REPORT_PATHS_COUNT variable missing
```

**Better**:
```
❌ REPORT_PATHS_COUNT verification failed
   Expected pattern: ^REPORT_PATHS_COUNT=
   Found in file: export REPORT_PATHS_COUNT="4"
   Suggestion: Pattern may need 'export' prefix
```

### Pattern 4: No Diagnostic Grep

**Problem**: Verification failure doesn't show what was actually found

**Current**:
```bash
if grep -q "^PATTERN" "$FILE"; then
  echo "✓ Found"
else
  echo "❌ Missing"  # No information about what WAS found
fi
```

**Better**:
```bash
if grep -q "^PATTERN" "$FILE"; then
  echo "✓ Found"
else
  echo "❌ Pattern '^PATTERN' not found"
  echo "Actual content:"
  grep "PARTIAL_PATTERN" "$FILE" || echo "No partial match either"
fi
```

## Verification Checkpoint Best Practices

### 1. Format-Aware Patterns

```bash
# BAD: Assumes no prefix
grep -q "^VAR_NAME=" "$STATE_FILE"

# GOOD: Matches actual append_workflow_state format
grep -q "^export VAR_NAME=" "$STATE_FILE"

# BEST: Format-agnostic (matches both)
grep -q "VAR_NAME=" "$STATE_FILE"  # No anchor if prefix varies
```

### 2. Multi-Method Verification

```bash
verify_state_variable() {
  local var_name="$1"
  local state_file="$2"

  # Method 1: Grep with correct format
  if grep -q "^export ${var_name}=" "$state_file"; then
    return 0
  fi

  # Method 2: Source and check (works regardless of format)
  if source "$state_file" 2>/dev/null && [ -n "${!var_name:-}" ]; then
    return 0
  fi

  # Both failed
  return 1
}
```

### 3. Diagnostic Output on Failure

```bash
if ! verify_state_variable "REPORT_PATHS_COUNT" "$STATE_FILE"; then
  echo "❌ REPORT_PATHS_COUNT verification failed"
  echo ""
  echo "Diagnostic information:"
  echo "  Pattern searched: ^export REPORT_PATHS_COUNT="
  echo "  State file: $STATE_FILE"
  echo ""
  echo "Actual content (lines containing REPORT_PATHS_COUNT):"
  grep -n "REPORT_PATHS_COUNT" "$STATE_FILE" || echo "  No matches found"
  echo ""
  echo "State file format sample:"
  head -5 "$STATE_FILE"
fi
```

### 4. Pattern Validation Tests

```bash
# Test verification patterns against known good state file
test_verification_patterns() {
  local test_state_file="/tmp/test_state_$$.sh"

  # Create test state file using actual library
  source ".claude/lib/state-persistence.sh"
  STATE_FILE="$test_state_file"
  append_workflow_state "TEST_VAR" "test_value"

  # Test verification pattern
  if grep -q "^export TEST_VAR=" "$test_state_file"; then
    echo "✓ Verification pattern works"
  else
    echo "✗ Verification pattern BROKEN"
    echo "State file contains:"
    cat "$test_state_file"
  fi

  rm -f "$test_state_file"
}
```

## Recommended Fixes

### Fix 1: Correct Grep Pattern (Immediate)

**File**: `.claude/commands/coordinate.md`
**Lines**: 210, 220

**Before**:
```bash
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
```

**After**:
```bash
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
```

**Impact**: Fixes immediate verification failure

### Fix 2: Add Format-Agnostic Fallback (Robust)

**File**: `.claude/commands/coordinate.md`
**Lines**: After 210

**Implementation**:
```bash
# Primary verification: exact format match
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "  ✓ REPORT_PATHS_COUNT variable saved"
# Fallback: format-agnostic check
elif grep -q "REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "  ✓ REPORT_PATHS_COUNT variable saved (non-standard format)"
else
  echo "  ❌ REPORT_PATHS_COUNT variable missing"
  echo "     Searched for: ^export REPORT_PATHS_COUNT= or REPORT_PATHS_COUNT="
  echo "     State file sample:"
  head -3 "$STATE_FILE" 2>/dev/null | sed 's/^/       /'
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi
```

**Impact**: Handles format variations, provides diagnostic output

### Fix 3: Extract Verification to Library Function (Maintainable)

**File**: `.claude/lib/verification-helpers.sh`
**New Function**:

```bash
# verify_state_variable - Verify variable exists in state file
#
# Handles both formats: "export VAR=" and "VAR="
# Provides diagnostic output on failure
#
# Usage: verify_state_variable "VAR_NAME" "$STATE_FILE"
# Returns: 0 on success, 1 on failure
verify_state_variable() {
  local var_name="$1"
  local state_file="$2"

  # Primary pattern: export prefix
  if grep -q "^export ${var_name}=" "$state_file" 2>/dev/null; then
    echo -n "✓"
    return 0
  fi

  # Fallback pattern: no export prefix
  if grep -q "^${var_name}=" "$state_file" 2>/dev/null; then
    echo -n "✓"
    return 0
  fi

  # Both patterns failed - diagnostic output
  echo ""
  echo "  ❌ $var_name verification failed"
  echo "     Patterns checked:"
  echo "       - ^export ${var_name}="
  echo "       - ^${var_name}="
  echo "     Actual matches:"
  grep -n "$var_name" "$state_file" 2>/dev/null | head -2 | sed 's/^/       /' || echo "       (none)"

  return 1
}
```

**Usage in coordinate.md**:
```bash
if verify_state_variable "REPORT_PATHS_COUNT" "$STATE_FILE"; then
  echo " saved"
else
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi
```

**Impact**: Centralized verification logic, consistent patterns, reusable

## Testing Strategy

### Unit Tests for Verification Functions

```bash
#!/usr/bin/env bash
# test_verification_patterns.sh

source ".claude/lib/state-persistence.sh"
source ".claude/lib/verification-helpers.sh"

echo "=== Test 1: Verify append_workflow_state format ==="
TEST_STATE="/tmp/test_state_$$.sh"
STATE_FILE="$TEST_STATE"
append_workflow_state "TEST_VAR" "test_value"

echo "State file content:"
cat "$TEST_STATE"

if grep -q "^export TEST_VAR=" "$TEST_STATE"; then
  echo "✓ Format includes 'export' prefix"
else
  echo "✗ Format DOES NOT include 'export' prefix"
fi

echo ""
echo "=== Test 2: Verify current coordinate.md pattern ==="
if grep -q "^TEST_VAR=" "$TEST_STATE"; then
  echo "✗ Current pattern MATCHES (unexpected)"
else
  echo "✓ Current pattern FAILS as expected (bug confirmed)"
fi

echo ""
echo "=== Test 3: Verify corrected pattern ==="
if grep -q "^export TEST_VAR=" "$TEST_STATE"; then
  echo "✓ Corrected pattern MATCHES"
else
  echo "✗ Corrected pattern FAILS"
fi

echo ""
echo "=== Test 4: Test verify_state_variable function ==="
if verify_state_variable "TEST_VAR" "$TEST_STATE"; then
  echo " - Function returned success"
else
  echo "✗ Function returned failure"
fi

rm -f "$TEST_STATE"
```

### Integration Test for State Persistence

```bash
#!/usr/bin/env bash
# test_coordinate_verification.sh

# Simulate coordinate.md state persistence block
source ".claude/lib/state-persistence.sh"
source ".claude/lib/workflow-initialization.sh"

# Initialize state
STATE_FILE=$(init_workflow_state "test_$$")

# Simulate report path creation
setup_research_supervisor \
  "test_topic" \
  "Test Workflow" \
  "Test description"

# Persist report paths (coordinate.md:185-195)
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done

# Test current verification pattern (should fail)
echo "=== Testing CURRENT verification pattern ==="
FAILURES=0
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE"; then
  echo "✓ REPORT_PATHS_COUNT found (current pattern)"
else
  echo "✗ REPORT_PATHS_COUNT NOT found (current pattern FAILS)"
  FAILURES=$((FAILURES + 1))
fi

# Test corrected verification pattern (should succeed)
echo ""
echo "=== Testing CORRECTED verification pattern ==="
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE"; then
  echo "✓ REPORT_PATHS_COUNT found (corrected pattern)"
else
  echo "✗ REPORT_PATHS_COUNT NOT found (corrected pattern FAILS)"
fi

# Cleanup
rm -f "$STATE_FILE"

if [ $FAILURES -gt 0 ]; then
  echo ""
  echo "BUG CONFIRMED: Current verification pattern fails"
  exit 1
else
  echo ""
  echo "Tests passed (or bug not present)"
  exit 0
fi
```

## Conclusion

The verification checkpoint bug patterns reveal systematic issues in state persistence verification:

1. **Primary Bug**: Grep pattern `^REPORT_PATHS_COUNT=` doesn't match `export REPORT_PATHS_COUNT="4"`
2. **Root Cause**: Format assumptions inconsistent with library implementation
3. **Impact**: 100% false negative rate on state verification
4. **Scope**: Affects all 5 REPORT_PATH variables in coordinate.md
5. **Related Issues**: Part of broader subprocess isolation compliance failures

**Recommended Immediate Fix**: Change grep patterns from `^VAR=` to `^export VAR=`

**Recommended Long-Term Fix**: Extract verification to library function with multi-method checking and diagnostic output

**Testing Strategy**: Unit tests for verification patterns, integration tests for full state persistence workflow

**Prevention**: Add verification pattern validation tests to test suite

## Metadata

- **Research Date**: 2025-11-10
- **Files Analyzed**:
  - `.claude/commands/coordinate.md` (verification code)
  - `.claude/lib/state-persistence.sh` (state format)
  - `.claude/lib/verification-helpers.sh` (file verification patterns)
  - `.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/*.md` (related bugs)
  - `.claude/specs/630_fix_coordinate_report_paths_state_persistence/reports/*.md` (related bugs)
  - `.claude/specs/641_specs_coordinate_outputmd_which_has_errors/reports/*.md` (related bugs)
- **Bug Instances**: 10 grep patterns (5 in coordinate.md, 5 in backup files)
- **False Negative Rate**: 100% (all grep patterns fail to match actual state file format)
- **Recommended Priority**: P0 (blocks workflow execution)

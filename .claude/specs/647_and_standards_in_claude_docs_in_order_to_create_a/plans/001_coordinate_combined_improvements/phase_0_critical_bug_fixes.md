# Phase 0: Critical Bug Fixes (Spec 648) - Detailed Specification

## Metadata
- **Phase Number**: 0
- **Phase Name**: Critical Bug Fixes
- **Estimated Duration**: 4-5 hours
- **Complexity Level**: 9 (Medium)
- **Dependencies**: None (prerequisite for all optimization phases)
- **Risk Level**: Medium (state persistence changes could break checkpoints)
- **Created**: 2025-11-10

## Overview

Phase 0 addresses three critical P0 bugs preventing the coordinate command from executing successfully:

1. **Unbound Variable Errors**: Variables used across bash blocks are not persisted to workflow state
2. **Verification Grep Pattern Mismatches**: Verification expects wrong state file format
3. **Library Re-sourcing Gaps**: Missing libraries cause "command not found" errors

These bugs must be fixed before any optimization work begins. The coordinate command currently has a 0% workflow success rate due to these issues.

## Background and Context

### Discovery Through Spec 648

Spec 648 analyzed coordinate command output and identified systematic failures in the research phase verification. While research agents executed successfully (3/3 completed), the workflow failed immediately after with:

```
/run/current-system/sw/bin/bash: line 243: USE_HIERARCHICAL_RESEARCH: unbound variable
```

This error revealed gaps in state persistence implementation from previous fixes (Specs 620 and 630).

### Subprocess Isolation Constraint

The coordinate command uses the bash block execution model where each bash block runs as a separate subprocess:

- Process ID changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Only files persist across blocks

**Critical Implication**: Variables used across bash blocks MUST be saved to state files using `append_workflow_state()`.

### Previous Related Fixes

**Spec 620** (Bash Variable Scoping):
- Fixed: WORKFLOW_DESCRIPTION overwritten by library pre-initialization
- Solution: SAVED_WORKFLOW_DESC pattern to preserve parent value

**Spec 630** (Report Paths State Persistence):
- Fixed: REPORT_PATHS_COUNT and REPORT_PATH_N not persisting
- Solution: Serialize array to individual state variables
- Result: 100% test pass rate

**Spec 648 Discovery**: Additional variables (USE_HIERARCHICAL_RESEARCH, WORKFLOW_SCOPE, RESEARCH_COMPLEXITY) still missing from state persistence.

## Technical Design

### Architecture Principles

1. **Comprehensive State Coverage**: Audit ALL variables used across bash blocks, not just known failures
2. **Consistent State File Format**: All variables written as `export VAR="value"` per state-persistence.sh
3. **Standardized Library Re-sourcing**: Every bash block sources all 6 critical libraries
4. **Verification Pattern Alignment**: Grep patterns match actual state file format

### State Persistence Strategy

#### State File Format

State files follow GitHub Actions $GITHUB_OUTPUT pattern:

```bash
#!/usr/bin/env bash
export WORKFLOW_DESCRIPTION="research auth patterns"
export WORKFLOW_SCOPE="research-only"
export USE_HIERARCHICAL_RESEARCH="false"
export REPORT_PATHS_COUNT="3"
export REPORT_PATH_0="/path/to/report1.md"
export REPORT_PATH_1="/path/to/report2.md"
export REPORT_PATH_2="/path/to/report3.md"
```

**Critical Format Detail**: All lines start with `export ` prefix.

#### Variables Requiring Persistence

**Tier 1: Cross-Block State** (used in 2+ blocks, critical):
- WORKFLOW_DESCRIPTION
- WORKFLOW_SCOPE
- CURRENT_STATE
- WORKFLOW_ID
- STATE_FILE
- TOPIC_PATH
- PLAN_PATH

**Tier 2: Conditional Execution Variables** (control flow across blocks):
- USE_HIERARCHICAL_RESEARCH
- RESEARCH_COMPLEXITY
- TEST_EXIT_CODE

**Tier 3: Data Arrays** (serialized per Spec 630 pattern):
- REPORT_PATHS_COUNT
- REPORT_PATH_0, REPORT_PATH_1, ... REPORT_PATH_N

**Total Variables**: 10 core + N report paths (typically 13-14 variables for 3-report workflow)

### Verification Grep Pattern Standards

**Problem**: Verification checkpoints use grep to detect state variables:

```bash
# WRONG (current coordinate.md code)
grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE"

# RIGHT (must match state-persistence.sh format)
grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE"
```

**Impact**: Current grep patterns always fail, making verification checkpoints non-functional.

**Solution**: Add `^export ` prefix to ALL verification grep patterns.

### Library Re-sourcing Standards

Each bash block MUST re-source these libraries in this order:

1. **workflow-state-machine.sh**: State transition functions (sm_init, sm_transition)
2. **state-persistence.sh**: State file operations (load_workflow_state, append_workflow_state)
3. **workflow-initialization.sh**: Path detection (initialize_workflow_paths, reconstruct_report_paths_array)
4. **error-handling.sh**: Error recovery (handle_state_error)
5. **unified-logger.sh**: Progress markers (emit_progress, display_brief_summary)
6. **verification-helpers.sh**: File verification (verify_file_created)

**Critical**: Missing unified-logger.sh causes "emit_progress: command not found" errors.

**Template Pattern**:
```bash
set +H  # Disable history expansion (workaround for Bash tool preprocessing)
set -euo pipefail

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state from fixed location
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi
```

## Implementation Tasks

### Task Group 1: State Persistence Audit and Fixes

#### Task 1.1: Extract All Variable References

**Objective**: Create comprehensive list of all variables used in coordinate.md.

**Method**:
```bash
# Extract all variable references from coordinate.md
grep -oE '\$\{?[A-Z_]+\}?' .claude/commands/coordinate.md | \
  sed 's/[${}]//g' | \
  sort -u > /tmp/coordinate_vars.txt

# Count: Expected ~25-30 unique variables
wc -l /tmp/coordinate_vars.txt
```

**Expected Variables**:
- WORKFLOW_DESCRIPTION
- WORKFLOW_SCOPE
- CURRENT_STATE
- STATE_FILE
- WORKFLOW_ID
- TOPIC_PATH
- PLAN_PATH
- REPORT_PATHS_COUNT
- REPORT_PATH_0, REPORT_PATH_1, ...
- USE_HIERARCHICAL_RESEARCH
- RESEARCH_COMPLEXITY
- TEST_EXIT_CODE
- DEBUG_REPORT_PATH
- CLAUDE_PROJECT_DIR
- LIB_DIR
- STATE_RESEARCH, STATE_PLAN, STATE_IMPLEMENT, etc. (constants)

**Output**: `/tmp/coordinate_vars.txt` with complete variable list

**Time**: 15 minutes

#### Task 1.2: Create Variable Usage Matrix

**Objective**: Identify which bash blocks use which variables.

**Method**:
```bash
# For each variable, find which bash blocks reference it
# Bash blocks in coordinate.md are separated by ```bash markers

# Extract bash blocks with line numbers
awk '/```bash/,/```/ {print NR": "$0}' .claude/commands/coordinate.md > /tmp/bash_blocks.txt

# For each variable, grep which blocks contain it
while read var; do
  echo "=== $var ==="
  grep -n "\$$var" /tmp/bash_blocks.txt | cut -d: -f1 | sort -u
done < /tmp/coordinate_vars.txt > /tmp/variable_usage_matrix.txt
```

**Output Format**:
```
=== WORKFLOW_DESCRIPTION ===
Block 1 (lines 46-120)
Block 2 (lines 292-369)
Block 3 (lines 426-480)

=== USE_HIERARCHICAL_RESEARCH ===
Block 2 (lines 292-369)
Block 3 (lines 426-480)
```

**Time**: 30 minutes

#### Task 1.3: Identify Cross-Block Variables

**Objective**: Flag variables used in 2+ bash blocks (require state persistence).

**Method**:
```bash
# Variables appearing in multiple blocks must be persisted
# Parse variable_usage_matrix.txt and count block occurrences

awk '/^=== / {var=$2; count=0}
     /^Block / {count++}
     count > 1 {print var}' /tmp/variable_usage_matrix.txt | \
  sort -u > /tmp/cross_block_vars.txt
```

**Expected Cross-Block Variables** (10-15 total):
1. WORKFLOW_DESCRIPTION ✓ (already persisted)
2. WORKFLOW_SCOPE ✓ (already persisted)
3. CURRENT_STATE ✓ (already persisted)
4. WORKFLOW_ID ✓ (already persisted)
5. STATE_FILE ✓ (already persisted)
6. TOPIC_PATH ✓ (already persisted)
7. PLAN_PATH ✓ (already persisted)
8. REPORT_PATHS_COUNT ✓ (already persisted)
9. REPORT_PATH_0...N ✓ (already persisted)
10. USE_HIERARCHICAL_RESEARCH ❌ **MISSING**
11. RESEARCH_COMPLEXITY ❌ **MISSING**
12. WORKFLOW_SCOPE (verify persisted in init block)

**Output**: `/tmp/cross_block_vars.txt` with flagged variables

**Time**: 20 minutes

#### Task 1.4: Add Missing Variables to State Persistence

**Objective**: Update coordinate.md initialization block to persist all cross-block variables.

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Location**: Bash block 2 (lines ~100-280), after `append_workflow_state "PLAN_PATH" "$PLAN_PATH"`

**Current Code** (lines 173-196):
```bash
# Save paths to workflow state
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Save report paths array metadata to state
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"

# Save individual report path variables
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done
```

**New Code to ADD** (after line 196):
```bash
# Save research configuration to state (Spec 648 fix)
# These variables control conditional execution in subsequent bash blocks
append_workflow_state "USE_HIERARCHICAL_RESEARCH" "${USE_HIERARCHICAL_RESEARCH:-false}"
append_workflow_state "RESEARCH_COMPLEXITY" "${RESEARCH_COMPLEXITY:-2}"

# Save workflow scope (used in verification checkpoints)
# Already saved earlier but verify it's present
if ! grep -q "^export WORKFLOW_SCOPE=" "$STATE_FILE" 2>/dev/null; then
  append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
fi
```

**Verification**:
```bash
# After adding code, verify state file contains new variables
grep -E "^export (USE_HIERARCHICAL_RESEARCH|RESEARCH_COMPLEXITY)=" "$STATE_FILE"
```

**Time**: 30 minutes

#### Task 1.5: Verify State File Format

**Objective**: Confirm all state variables use correct export format.

**Method**:
```bash
# Check state file after initialization block
STATE_FILE="${HOME}/.claude/tmp/workflow_coordinate_test.sh"

# All lines should start with "export "
if grep -vE '^(export |#!/usr/bin/bash|#|$)' "$STATE_FILE" 2>/dev/null; then
  echo "ERROR: Invalid state file format detected"
  exit 1
fi

# Verify specific variables
required_vars=(
  "WORKFLOW_DESCRIPTION"
  "WORKFLOW_SCOPE"
  "USE_HIERARCHICAL_RESEARCH"
  "RESEARCH_COMPLEXITY"
  "REPORT_PATHS_COUNT"
)

for var in "${required_vars[@]}"; do
  if grep -q "^export ${var}=" "$STATE_FILE"; then
    echo "✓ $var persisted correctly"
  else
    echo "✗ $var missing from state file"
  fi
done
```

**Expected Output**:
```
✓ WORKFLOW_DESCRIPTION persisted correctly
✓ WORKFLOW_SCOPE persisted correctly
✓ USE_HIERARCHICAL_RESEARCH persisted correctly
✓ RESEARCH_COMPLEXITY persisted correctly
✓ REPORT_PATHS_COUNT persisted correctly
```

**Time**: 15 minutes

### Task Group 2: Verification Grep Pattern Fixes

#### Task 2.1: Locate All Verification Grep Patterns

**Objective**: Find all grep commands checking for state variables.

**Method**:
```bash
# Search coordinate.md for grep patterns checking state variables
grep -n 'grep.*REPORT_PATH\|grep.*USE_HIERARCHICAL\|grep.*WORKFLOW_SCOPE' \
  .claude/commands/coordinate.md > /tmp/verification_greps.txt
```

**Expected Locations** (from error patterns analysis):
- Line ~211: REPORT_PATHS_COUNT verification
- Line ~222: REPORT_PATH_N verification loop
- Line ~462: USE_HIERARCHICAL_RESEARCH verification (probable location)

**Output**: `/tmp/verification_greps.txt` with line numbers

**Time**: 15 minutes

#### Task 2.2: Update Grep Patterns with Export Prefix

**Objective**: Fix all grep patterns to match state file format.

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Pattern Replacements**:

**Location 1** (line ~211):
```bash
# BEFORE
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then

# AFTER
# State file format: export VAR="value" (per state-persistence.sh)
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
```

**Location 2** (line ~222):
```bash
# BEFORE
if grep -q "^${var_name}=" "$STATE_FILE" 2>/dev/null; then

# AFTER
# State file format: export VAR="value" (per state-persistence.sh)
if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
```

**Location 3** (Research verification block - add if missing):
```bash
# Add this check in research verification bash block
# State file format: export VAR="value" (per state-persistence.sh)
if grep -q "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ USE_HIERARCHICAL_RESEARCH variable verified in state"
else
  echo "❌ USE_HIERARCHICAL_RESEARCH missing from state file"
  handle_state_error "USE_HIERARCHICAL_RESEARCH not persisted to state" 1
fi
```

**Time**: 45 minutes (including testing each pattern)

#### Task 2.3: Add Clarifying Comments

**Objective**: Document why grep patterns use `^export ` prefix.

**Pattern**:
```bash
# State file format: export VAR="value" (per state-persistence.sh)
# All variables must be checked with ^export prefix
if grep -q "^export VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  ...
fi
```

**Apply to**: All verification grep patterns in coordinate.md (estimated 5-7 locations)

**Time**: 20 minutes

#### Task 2.4: Create Verification Test Script

**Objective**: Automated test to validate grep patterns work correctly.

**File**: `/home/benjamin/.config/.claude/tests/test_coordinate_verification.sh`

**Content**:
```bash
#!/usr/bin/env bash
# Test coordinate verification grep patterns

set -euo pipefail

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

STATE_FILE="$TEST_DIR/test_state.sh"

# Create test state file with correct format
cat > "$STATE_FILE" <<'EOF'
#!/usr/bin/env bash
export WORKFLOW_DESCRIPTION="test workflow"
export WORKFLOW_SCOPE="research-only"
export USE_HIERARCHICAL_RESEARCH="false"
export RESEARCH_COMPLEXITY="2"
export REPORT_PATHS_COUNT="3"
export REPORT_PATH_0="/path/to/report1.md"
export REPORT_PATH_1="/path/to/report2.md"
export REPORT_PATH_2="/path/to/report3.md"
EOF

# Test 1: Verify REPORT_PATHS_COUNT pattern
echo "Test 1: REPORT_PATHS_COUNT verification"
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ PASS: REPORT_PATHS_COUNT pattern works"
else
  echo "✗ FAIL: REPORT_PATHS_COUNT pattern doesn't match"
  exit 1
fi

# Test 2: Verify USE_HIERARCHICAL_RESEARCH pattern
echo "Test 2: USE_HIERARCHICAL_RESEARCH verification"
if grep -q "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ PASS: USE_HIERARCHICAL_RESEARCH pattern works"
else
  echo "✗ FAIL: USE_HIERARCHICAL_RESEARCH pattern doesn't match"
  exit 1
fi

# Test 3: Verify REPORT_PATH_N patterns
echo "Test 3: REPORT_PATH_N verification"
for i in 0 1 2; do
  var_name="REPORT_PATH_$i"
  if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
    echo "✓ PASS: $var_name pattern works"
  else
    echo "✗ FAIL: $var_name pattern doesn't match"
    exit 1
  fi
done

# Test 4: Verify wrong patterns fail (negative test)
echo "Test 4: Negative test (patterns without export prefix)"
if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "✗ FAIL: Pattern without export prefix incorrectly matched"
  exit 1
else
  echo "✓ PASS: Pattern without export prefix correctly failed"
fi

echo ""
echo "All verification grep pattern tests passed"
```

**Execution**:
```bash
chmod +x .claude/tests/test_coordinate_verification.sh
bash .claude/tests/test_coordinate_verification.sh
```

**Time**: 30 minutes

### Task Group 3: Library Re-sourcing Standardization

#### Task 3.1: Count Bash Blocks in Coordinate.md

**Objective**: Identify all bash blocks requiring library re-sourcing.

**Method**:
```bash
# Count bash blocks (start markers)
grep -c '^```bash' .claude/commands/coordinate.md

# Expected: 11-13 blocks
# Block 1: Workflow description capture
# Block 2: State machine initialization
# Block 3: Research phase handler
# Block 4: Research verification
# Block 5: Planning phase handler
# Block 6: Planning verification
# Block 7: Implementation phase handler
# Block 8: Implementation verification
# Block 9: Testing phase handler
# Block 10: Debug phase handler (conditional)
# Block 11: Documentation phase handler (conditional)
```

**Output**: List of bash block line ranges

**Time**: 10 minutes

#### Task 3.2: Create Standardized Re-sourcing Template

**Objective**: Extract canonical pattern from bash-block-execution-model.md.

**Source**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (lines 256-286)

**Template**:
```bash
set +H  # Disable history expansion (workaround for Bash tool preprocessing)
set -euo pipefail

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state from fixed location
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi
```

**Save to**: `/tmp/library_resourcing_template.sh`

**Time**: 15 minutes

#### Task 3.3: Audit Each Bash Block for Library Sourcing

**Objective**: Check which blocks have complete library re-sourcing.

**Method**:
```bash
# For each bash block, check if it sources all 6 libraries
required_libs=(
  "workflow-state-machine.sh"
  "state-persistence.sh"
  "workflow-initialization.sh"
  "error-handling.sh"
  "unified-logger.sh"
  "verification-helpers.sh"
)

# Extract each bash block and check
awk '/```bash/,/```/ {if (!/```/) print}' .claude/commands/coordinate.md | \
  awk 'BEGIN {block=1} /^set \+H/ {print "=== Block " block " ==="; block++} 1' | \
  grep -E 'source.*\.sh|=== Block'
```

**Expected Issues**:
- Some blocks may be missing unified-logger.sh
- Some blocks may be missing verification-helpers.sh
- Block 1 (workflow capture) intentionally minimal (skip)

**Output**: Matrix showing which blocks source which libraries

**Time**: 30 minutes

#### Task 3.4: Add Missing Library Sourcing

**Objective**: Ensure all bash blocks (except block 1) source all 6 libraries.

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Pattern**: For each bash block missing libraries:

1. Verify `set +H` is first line
2. Verify Standard 13 CLAUDE_PROJECT_DIR detection present
3. Add missing source statements in correct order
4. Verify load_workflow_state call present

**Example Fix** (typical block missing unified-logger.sh):

**BEFORE**:
```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
# Missing unified-logger.sh and verification-helpers.sh
```

**AFTER**:
```bash
set +H  # Disable history expansion (workaround for Bash tool preprocessing)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"  # FIX: Added missing logger
source "${LIB_DIR}/verification-helpers.sh"  # FIX: Added missing verification
```

**Apply to**: 8-10 bash blocks (all except workflow capture block)

**Time**: 60 minutes (including careful verification)

#### Task 3.5: Verify Consistent LIB_DIR Construction

**Objective**: Ensure all blocks use identical path construction.

**Standard Pattern**:
```bash
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Anti-patterns to fix**:
```bash
# WRONG: Hardcoded path
LIB_DIR="/home/benjamin/.config/.claude/lib"

# WRONG: Relative path
LIB_DIR="../.claude/lib"

# WRONG: Inconsistent variable
CLAUDE_LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Method**:
```bash
# Search for LIB_DIR assignments
grep -n 'LIB_DIR=' .claude/commands/coordinate.md

# All should match: LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Time**: 15 minutes

## Testing Specifications

### Test 1: State Persistence Unit Test

**File**: Create new test or add to existing

**Test Code**:
```bash
#!/usr/bin/env bash
# Test state persistence for all cross-block variables

set -euo pipefail

CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Test initialization
STATE_FILE=$(init_workflow_state "test_$$")
trap "rm -f '$STATE_FILE'" EXIT

echo "Test 1: Basic state persistence"
append_workflow_state "TEST_VAR" "test_value"
if grep -q "^export TEST_VAR=\"test_value\"" "$STATE_FILE"; then
  echo "✓ PASS: Basic persistence works"
else
  echo "✗ FAIL: Basic persistence failed"
  exit 1
fi

echo "Test 2: USE_HIERARCHICAL_RESEARCH persistence"
append_workflow_state "USE_HIERARCHICAL_RESEARCH" "false"
if grep -q "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE"; then
  echo "✓ PASS: USE_HIERARCHICAL_RESEARCH persisted"
else
  echo "✗ FAIL: USE_HIERARCHICAL_RESEARCH not persisted"
  exit 1
fi

echo "Test 3: WORKFLOW_SCOPE persistence"
append_workflow_state "WORKFLOW_SCOPE" "research-only"
if grep -q "^export WORKFLOW_SCOPE=" "$STATE_FILE"; then
  echo "✓ PASS: WORKFLOW_SCOPE persisted"
else
  echo "✗ FAIL: WORKFLOW_SCOPE not persisted"
  exit 1
fi

echo "Test 4: State file format validation"
if grep -vE '^(export |#!/usr/bin/bash|#|$)' "$STATE_FILE"; then
  echo "✗ FAIL: State file has invalid format"
  exit 1
else
  echo "✓ PASS: State file format is valid"
fi

echo ""
echo "All state persistence tests passed"
```

**Expected Output**:
```
✓ PASS: Basic persistence works
✓ PASS: USE_HIERARCHICAL_RESEARCH persisted
✓ PASS: WORKFLOW_SCOPE persisted
✓ PASS: State file format is valid

All state persistence tests passed
```

**Time**: 20 minutes to create, 5 minutes to run

### Test 2: Verification Grep Pattern Test

**Covered by**: Task 2.4 (test_coordinate_verification.sh)

**Additional Coverage**:
```bash
# Test grep pattern false positive detection
echo "Test 5: False positive prevention"

# Create state file with malformed entry
cat > "$STATE_FILE" <<'EOF'
#!/usr/bin/env bash
export VALID_VAR="value"
INVALID_VAR="no_export_prefix"
EOF

# Should match valid variable
if grep -q "^export VALID_VAR=" "$STATE_FILE"; then
  echo "✓ PASS: Valid variable detected"
else
  echo "✗ FAIL: Valid variable not detected"
  exit 1
fi

# Should NOT match invalid variable
if grep -q "^export INVALID_VAR=" "$STATE_FILE"; then
  echo "✗ FAIL: Invalid variable incorrectly matched"
  exit 1
else
  echo "✓ PASS: Invalid variable correctly ignored"
fi
```

**Time**: 10 minutes to add

### Test 3: Library Re-sourcing Presence Test

**Objective**: Verify all bash blocks source required libraries.

**Test Code**:
```bash
#!/usr/bin/env bash
# Test library re-sourcing presence in coordinate.md

set -euo pipefail

COORDINATE_FILE=".claude/commands/coordinate.md"

required_libs=(
  "workflow-state-machine.sh"
  "state-persistence.sh"
  "workflow-initialization.sh"
  "error-handling.sh"
  "unified-logger.sh"
  "verification-helpers.sh"
)

echo "Counting bash blocks in $COORDINATE_FILE"
BASH_BLOCK_COUNT=$(grep -c '^```bash' "$COORDINATE_FILE")
echo "Found $BASH_BLOCK_COUNT bash blocks"

# Expect 11-13 blocks, skip first block (workflow capture)
EXPECTED_MIN=10

echo ""
echo "Checking library sourcing in each block..."

for lib in "${required_libs[@]}"; do
  COUNT=$(grep -c "source.*${lib}" "$COORDINATE_FILE" || true)
  echo "  $lib: sourced $COUNT times"

  if [ "$COUNT" -lt "$EXPECTED_MIN" ]; then
    echo "    ⚠ WARNING: Expected at least $EXPECTED_MIN, found $COUNT"
    echo "    Some bash blocks may be missing this library"
  fi
done

echo ""
echo "Checking set +H directive..."
SET_H_COUNT=$(grep -c '^set +H' "$COORDINATE_FILE" || true)
echo "  set +H directives: $SET_H_COUNT"

if [ "$SET_H_COUNT" -ge "$EXPECTED_MIN" ]; then
  echo "  ✓ PASS: Sufficient set +H directives"
else
  echo "  ⚠ WARNING: Expected $EXPECTED_MIN, found $SET_H_COUNT"
fi

echo ""
echo "Library sourcing audit complete"
```

**Expected Output**:
```
Found 12 bash blocks

Checking library sourcing in each block...
  workflow-state-machine.sh: sourced 11 times
  state-persistence.sh: sourced 11 times
  workflow-initialization.sh: sourced 11 times
  error-handling.sh: sourced 11 times
  unified-logger.sh: sourced 11 times
  verification-helpers.sh: sourced 11 times

Checking set +H directive...
  set +H directives: 12
  ✓ PASS: Sufficient set +H directives

Library sourcing audit complete
```

**Time**: 20 minutes to create, 5 minutes to run

### Test 4: End-to-End Integration Test

**Objective**: Run full coordinate workflow to verify all fixes work together.

**Test Command**:
```bash
/coordinate "research existing authentication patterns, security best practices, and OAuth implementation options in order to create comprehensive authentication plan"
```

**Expected Behavior**:
1. Workflow description captured successfully
2. State machine initializes (see "=== State Machine Workflow Orchestration ===")
3. Research agents execute (3 agents complete)
4. NO "unbound variable" errors
5. Verification checkpoints pass (see "✓ All 3 research reports verified")
6. Workflow proceeds to planning phase OR completes (if research-only scope)

**Success Criteria**:
- Exit code 0
- Zero unbound variable errors
- 100% verification checkpoint success rate
- No "command not found" errors

**Failure Diagnosis**:
```bash
# If test fails, check:

# 1. State file contents
cat ~/.claude/tmp/workflow_coordinate_*.sh

# 2. Missing variables
grep "unbound variable" output.log

# 3. Verification failures
grep "verification failed" output.log

# 4. Library loading errors
grep "command not found" output.log
```

**Time**: 30 minutes (including test execution and result analysis)

## Error Handling

### Error Scenario 1: State Variable Missing

**Symptom**:
```
/run/current-system/sw/bin/bash: line 243: VARIABLE_NAME: unbound variable
```

**Diagnosis**:
1. Check which bash block failed (line number from error)
2. Check if variable is saved to state in initialization block
3. Check if variable is loaded from state before use

**Fix**:
```bash
# Add to initialization block
append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"

# Verify in state file
grep "^export VARIABLE_NAME=" "$STATE_FILE"
```

**Prevention**: Use variable usage matrix (Task 1.2) to identify all cross-block variables

### Error Scenario 2: Verification Grep Pattern Mismatch

**Symptom**:
```
❌ CRITICAL: State file verification failed
   N variables not written to state file
```

**Diagnosis**:
```bash
# Check actual state file format
head -20 "$STATE_FILE"

# Should show:
# export VAR1="value1"
# export VAR2="value2"

# Check grep pattern
grep -n 'grep.*VARIABLE_NAME' .claude/commands/coordinate.md
```

**Fix**: Ensure grep pattern includes `^export ` prefix

**Prevention**: Use test_coordinate_verification.sh (Task 2.4)

### Error Scenario 3: Library Function Not Found

**Symptom**:
```
emit_progress: command not found
display_brief_summary: command not found
```

**Diagnosis**:
1. Check which bash block failed
2. Verify library re-sourcing present in that block
3. Check if unified-logger.sh is sourced

**Fix**:
```bash
# Add to bash block (if missing)
source "${LIB_DIR}/unified-logger.sh"
```

**Prevention**: Use library sourcing audit (Task 3.3)

### Error Scenario 4: State File Not Found

**Symptom**:
```
ERROR: Workflow state ID file not found: /home/user/.claude/tmp/coordinate_state_id.txt
```

**Diagnosis**:
1. Check if initialization block ran successfully
2. Check if state ID was saved to fixed location
3. Check file permissions on .claude/tmp/

**Fix**:
```bash
# Verify state ID file creation in initialization block
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Verify file was created
ls -la "$COORDINATE_STATE_ID_FILE"
```

**Prevention**: Add verification checkpoint after state ID file creation

## Rollback Strategy

### Rollback Approach

**If Phase 0 fixes cause regressions**:

1. Identify failing component (state persistence, verification, or library sourcing)
2. Git revert specific changes
3. Apply fixes individually and test after each

**Rollback Sequence**:
```bash
# Rollback all Phase 0 changes
git log --oneline --grep="fix(648)" | head -1  # Get commit hash
git revert <commit-hash>

# Or rollback specific files
git checkout HEAD~1 -- .claude/commands/coordinate.md
git checkout HEAD~1 -- .claude/tests/test_coordinate_verification.sh
```

### Checkpoint Compatibility

**State File Schema**: Phase 0 does not change state file schema, only adds new variables

**Backward Compatibility**: Old state files (without new variables) will gracefully degrade:
- load_workflow_state() succeeds
- Missing variables will be unset (bash default behavior)
- Unbound variable errors will occur (expected, pre-fix behavior)

**Forward Compatibility**: New state files (with new variables) are compatible with old code:
- Extra variables ignored
- Core variables still present

**Mitigation**: If rollback required, delete state files to force clean initialization:
```bash
rm -f ~/.claude/tmp/workflow_coordinate_*.sh
rm -f ~/.claude/tmp/coordinate_state_id.txt
```

## Completion Criteria

### Functional Requirements

- [ ] All cross-block variables (10 core + N report paths) persisted to state
- [ ] USE_HIERARCHICAL_RESEARCH specifically added to state persistence
- [ ] WORKFLOW_SCOPE specifically added to state persistence
- [ ] RESEARCH_COMPLEXITY specifically added to state persistence
- [ ] All verification grep patterns use `^export ` prefix
- [ ] All bash blocks (except block 1) source all 6 libraries
- [ ] All bash blocks start with `set +H` directive
- [ ] LIB_DIR construction consistent across all blocks

### Testing Requirements

- [ ] State persistence unit test passes (100% coverage)
- [ ] Verification grep pattern test passes (5 tests)
- [ ] Library sourcing audit shows complete coverage
- [ ] End-to-end integration test completes without errors

### Quality Requirements

- [ ] Zero unbound variable errors in test execution
- [ ] 100% verification checkpoint success rate
- [ ] Zero "command not found" errors
- [ ] State file format validation passes

### Documentation Requirements

- [ ] Variable usage matrix documented in /tmp/variable_usage_matrix.txt
- [ ] Cross-block variables list documented in /tmp/cross_block_vars.txt
- [ ] Verification grep test script committed to .claude/tests/
- [ ] Library sourcing audit script committed to .claude/tests/

### Deliverables

1. **Modified Files**:
   - .claude/commands/coordinate.md (state persistence + verification fixes)

2. **New Test Files**:
   - .claude/tests/test_coordinate_verification.sh
   - .claude/tests/test_state_persistence.sh (if new)
   - .claude/tests/test_library_sourcing.sh (if new)

3. **Diagnostic Artifacts**:
   - /tmp/coordinate_vars.txt (all variables)
   - /tmp/variable_usage_matrix.txt (cross-block analysis)
   - /tmp/cross_block_vars.txt (variables requiring persistence)

4. **Git Commit**:
   - Message: `fix(648): eliminate P0 bugs in coordinate command (unbound vars, verification, library sourcing)`
   - Files changed: 1-2
   - Lines changed: +50-80 (state persistence), +20-30 (verification patterns), ~100 (library sourcing)

### Success Validation

**Final Validation Command**:
```bash
# Run complete test suite
bash .claude/tests/test_coordinate_verification.sh && \
bash .claude/tests/test_state_persistence.sh && \
bash .claude/tests/test_library_sourcing.sh && \
/coordinate "research existing authentication patterns, security best practices, and OAuth implementation options in order to create comprehensive authentication plan"

# Expected: All tests pass, coordinate command completes successfully
```

**Success Metrics**:
- Test suite pass rate: 100% (all 4 test scripts)
- Coordinate command exit code: 0
- Unbound variable error count: 0
- Verification checkpoint failure count: 0
- "Command not found" error count: 0

## Related Documentation

### Primary References

- **Spec 648 Error Patterns Analysis**: /home/benjamin/.config/.claude/specs/648_and_standards_in_claude_docs_to_avoid_redundancy/reports/001_error_patterns_analysis.md
- **Bash Block Execution Model**: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md
- **State Persistence Library**: /home/benjamin/.config/.claude/lib/state-persistence.sh

### Historical Context

- **Spec 620**: Bash variable scoping diagnostic (WORKFLOW_DESCRIPTION fix)
- **Spec 630**: Report paths state persistence (REPORT_PATHS_COUNT fix)
- **Spec 644**: Coordinate verification grep pattern fix (original identification)

### Architecture Documentation

- **State-Based Orchestration Overview**: /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
- **Command Architecture Standards**: /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md

## Appendix A: Complete Variable List

### Variables Requiring State Persistence (Tier 1)

| Variable | Usage | Blocks | Status |
|----------|-------|--------|--------|
| WORKFLOW_DESCRIPTION | Feature description | 1, 2, 3, 4, 5, 6 | ✓ Persisted |
| WORKFLOW_SCOPE | Execution scope | 1, 2, 3, 4, 5 | ⚠ Verify |
| CURRENT_STATE | State machine state | 1, 2, 3, 4, 5, 6 | ✓ Persisted |
| WORKFLOW_ID | Unique workflow ID | 1, 2, 3, 4, 5, 6 | ✓ Persisted |
| STATE_FILE | State file path | 1, 2, 3, 4, 5, 6 | ✓ Persisted |
| TOPIC_PATH | Topic directory | 1, 2, 3, 4, 5 | ✓ Persisted |
| PLAN_PATH | Plan file path | 1, 2, 4, 5, 6 | ✓ Persisted |

### Variables Requiring State Persistence (Tier 2)

| Variable | Usage | Blocks | Status |
|----------|-------|--------|--------|
| USE_HIERARCHICAL_RESEARCH | Research mode | 2, 3 | ❌ MISSING |
| RESEARCH_COMPLEXITY | Topic count | 2, 3 | ❌ MISSING |
| TEST_EXIT_CODE | Test result | 5, 6 | ⚠ Check |

### Variables Requiring State Persistence (Tier 3)

| Variable | Usage | Blocks | Status |
|----------|-------|--------|--------|
| REPORT_PATHS_COUNT | Array size | 1, 2, 3, 4 | ✓ Persisted |
| REPORT_PATH_0 | Report path | 1, 2, 3, 4 | ✓ Persisted |
| REPORT_PATH_1 | Report path | 1, 2, 3, 4 | ✓ Persisted |
| REPORT_PATH_N | Report path | 1, 2, 3, 4 | ✓ Persisted |

### Variables NOT Requiring Persistence

| Variable | Reason | Usage |
|----------|--------|-------|
| CLAUDE_PROJECT_DIR | Recalculated | Standard 13 pattern |
| LIB_DIR | Derived | Constructed from CLAUDE_PROJECT_DIR |
| STATE_* constants | Constants | Defined in workflow-state-machine.sh |

**Total Variables Requiring Action**: 3 (USE_HIERARCHICAL_RESEARCH, RESEARCH_COMPLEXITY, WORKFLOW_SCOPE verification)

## Appendix B: Verification Checkpoint Locations

### Checkpoint 1: State File Persistence (Block 2)

**Location**: Lines ~199-259 in coordinate.md

**Purpose**: Verify all variables written to state file

**Current Status**: Working (Spec 630 fix)

**Enhancement**: Add USE_HIERARCHICAL_RESEARCH and RESEARCH_COMPLEXITY verification

### Checkpoint 2: Research Phase Completion (Block 4)

**Location**: Lines ~529-641 in coordinate.md

**Purpose**: Verify all research reports created

**Current Status**: Failing (grep pattern mismatch)

**Fix Required**: Update grep patterns with `^export ` prefix

### Checkpoint 3: Planning Phase Completion (Block 6)

**Location**: Lines ~792-905 in coordinate.md

**Purpose**: Verify plan file created

**Current Status**: Unknown (workflow doesn't reach this point)

**Action**: Test after research phase fixes

### Checkpoint 4: Implementation Phase Completion (Block 8)

**Location**: Lines ~1017-1048 in coordinate.md

**Purpose**: Verify implementation complete

**Current Status**: Unknown (workflow doesn't reach this point)

**Action**: Test after earlier phase fixes

### Checkpoint 5: Testing Phase Completion (Block 9)

**Location**: Lines ~1120-1169 in coordinate.md

**Purpose**: Verify test execution

**Current Status**: Unknown (workflow doesn't reach this point)

**Action**: Test after earlier phase fixes

**Total Checkpoints**: 5 major + 1 state persistence = 6 verification points

## Summary

Phase 0 fixes three critical P0 bugs preventing coordinate command execution:

1. **State Persistence Gaps**: Add USE_HIERARCHICAL_RESEARCH, RESEARCH_COMPLEXITY, and WORKFLOW_SCOPE to state persistence
2. **Verification Pattern Mismatches**: Update all grep patterns to use `^export ` prefix matching state file format
3. **Library Re-sourcing Gaps**: Ensure all bash blocks source all 6 critical libraries

**Implementation Effort**: 4-5 hours
**Testing Effort**: 1 hour
**Total Effort**: 5-6 hours

**Success Criteria**: Zero unbound variable errors, 100% verification success, zero "command not found" errors, full coordinate workflow completes without manual intervention.

**Next Phase**: Phase 1 (Baseline Metrics) can proceed after Phase 0 completes successfully.

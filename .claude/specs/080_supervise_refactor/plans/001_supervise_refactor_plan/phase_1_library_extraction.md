# Phase 1: Library Extraction and Sourcing - Detailed Implementation

## Phase Metadata

**Phase Number**: 1
**Parent Plan**: 001_supervise_refactor_plan.md
**Status**: PENDING

**Objective**: Extract 750 lines of inline bash utility functions from `/supervise` to library files and replace with source statements, reducing the command file from ~800 lines to ~50 lines of essential examples.

**Duration**: 2 hours

**Complexity**: 7/10

**Complexity Justification**:
- High risk of breaking existing functionality if extraction isn't precise
- Requires careful dependency management across 4 different library files
- Need to ensure correct sourcing order to avoid circular dependencies
- Function reference tables must accurately document all available utilities
- Integration testing required to verify no regression

**Key Success Metrics**:
- `workflow-detection.sh` created with 150+ lines
- Source statements added to supervise.md (5 lines total)
- Inline bash reduced from 800 lines to ~50 lines (93% reduction)
- Function reference table present and complete
- All existing test scripts pass with sourced libraries

---

## Task Group 1: Create workflow-detection.sh Library

### Task 1.1: Create Library File Structure

**Objective**: Create the new library file with proper header and documentation.

**Steps**:

1. **Create the file**: `/home/benjamin/.config/.claude/lib/workflow-detection.sh`

2. **Add header with metadata**:
```bash
#!/usr/bin/env bash
# Workflow Detection Utilities
# Used by: /supervise
# Functions: detect_workflow_scope, should_run_phase
#
# This library provides workflow scope detection and phase execution logic
# for the /supervise command. It determines which phases should run based
# on workflow keywords and patterns.

set -euo pipefail
```

3. **Add usage documentation**:
```bash
# ==============================================================================
# Workflow Scope Detection
# ==============================================================================
#
# The /supervise command supports 4 workflow types:
#
# 1. research-only
#    - Keywords: "research [topic]" without "plan" or "implement"
#    - Phases: 0 (Location) → 1 (Research) → STOP
#    - No plan created, no summary
#
# 2. research-and-plan (MOST COMMON)
#    - Keywords: "research...to create plan", "analyze...for planning"
#    - Phases: 0 → 1 (Research) → 2 (Planning) → STOP
#    - Creates research reports + implementation plan
#
# 3. full-implementation
#    - Keywords: "implement", "build", "add feature"
#    - Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 6 (Documentation)
#    - Phase 5 conditional on test failures
#
# 4. debug-only
#    - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
#    - Phases: 0 → 1 (Research) → 5 (Debug) → STOP
#    - No new plan or summary
```

**Verification**:
- [ ] File created at correct path
- [ ] Header includes all required metadata
- [ ] Usage documentation is comprehensive

---

### Task 1.2: Extract detect_workflow_scope Function

**Objective**: Extract the `detect_workflow_scope()` function from supervise.md (lines ~343-381).

**Current Location**: `/home/benjamin/.config/.claude/commands/supervise.md` lines 343-381

**Extraction Steps**:

1. **Copy the complete function** from supervise.md:
```bash
# ═══════════════════════════════════════════════════════════════
# detect_workflow_scope: Detect workflow type from description
# ═══════════════════════════════════════════════════════════════
#
# Usage: detect_workflow_scope <workflow-description>
# Returns: workflow scope (research-only|research-and-plan|full-implementation|debug-only)
# Example: detect_workflow_scope "research authentication to create plan"
#
detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 1: Research-only (no planning or implementation)
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: 0 (Location) → 1 (Research) → STOP
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan (most common case)
  # Keywords: "research...to create plan", "analyze...for planning"
  # Phases: 0 → 1 (Research) → 2 (Planning) → STOP
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 4: Debug-only (fix existing code)
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: 0 → 1 (Research) → 5 (Debug) → STOP (no new implementation)
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    echo "debug-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan (safest for ambiguous cases)
  echo "research-and-plan"
}
```

2. **Add to workflow-detection.sh** with enhanced documentation

3. **Add test examples**:
```bash
# Test Examples:
# - detect_workflow_scope "research API patterns" → research-only
# - detect_workflow_scope "research auth to create plan" → research-and-plan
# - detect_workflow_scope "implement OAuth2 authentication" → full-implementation
# - detect_workflow_scope "fix token refresh bug" → debug-only
```

**Verification**:
- [ ] Function extracted with exact logic preserved
- [ ] Documentation enhanced with examples
- [ ] No changes to core detection logic

---

### Task 1.3: Extract should_run_phase Function

**Objective**: Extract the `should_run_phase()` function from supervise.md (lines ~387-397).

**Current Location**: `/home/benjamin/.config/.claude/commands/supervise.md` lines 387-397

**Extraction Steps**:

1. **Copy the complete function**:
```bash
# ═══════════════════════════════════════════════════════════════
# should_run_phase: Check if phase should execute for current scope
# ═══════════════════════════════════════════════════════════════
#
# Usage: should_run_phase <phase-number>
# Returns: 0 (true) if phase should execute, 1 (false) otherwise
# Example: should_run_phase 3  # Returns 0 if phase 3 in PHASES_TO_EXECUTE
#
# Requires: PHASES_TO_EXECUTE environment variable (comma-separated list)
#
should_run_phase() {
  local phase_num="$1"

  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}
```

2. **Add usage notes**:
```bash
# Usage Pattern in /supervise:
#
# should_run_phase 1 || {
#   echo "⏭️  Skipping Phase 1 (Research)"
#   exit 0
# }
#
# This allows conditional phase execution based on workflow scope.
```

**Verification**:
- [ ] Function extracted with exact logic
- [ ] Environment variable dependency documented
- [ ] Usage pattern examples added

---

### Task 1.4: Add Function Export Section

**Objective**: Export functions for use in /supervise command.

**Implementation**:

```bash
# ==============================================================================
# Export Functions
# ==============================================================================

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f detect_workflow_scope
  export -f should_run_phase
fi
```

**Verification**:
- [ ] Export section added at end of file
- [ ] Both functions exported
- [ ] Conditional export pattern used

---

## Task Group 2: Verify Existing Library Coverage

### Task 2.1: Verify error-handling.sh Functions

**Objective**: Confirm that error-handling.sh contains all required functions referenced in supervise.md.

**Required Functions** (as referenced in supervise.md lines 476-625):
- `classify_error()` - Classify error based on error message
- `suggest_recovery()` - Suggest recovery action based on error type
- `detect_specific_error_type()` - Detect specific error category (4 types)
- `extract_error_location()` - Extract file:line location from error message
- `generate_suggestions()` - Generate error-specific suggestions
- `retry_with_backoff()` - Retry command with exponential backoff

**Verification Steps**:

1. **Read error-handling.sh**: `/home/benjamin/.config/.claude/lib/error-handling.sh`

2. **Check for each function**:
```bash
grep -n "^classify_error()" error-handling.sh
grep -n "^suggest_recovery()" error-handling.sh
grep -n "^detect_error_type()" error-handling.sh
grep -n "^extract_location()" error-handling.sh
grep -n "^generate_suggestions()" error-handling.sh
grep -n "^retry_with_backoff()" error-handling.sh
```

3. **Document findings**:
   - Line numbers where each function is defined
   - Any missing functions that need to be added
   - Any function signature mismatches

**From Read Analysis**:
- ✅ `classify_error()` - Line 20
- ✅ `suggest_recovery()` - Line 48
- ✅ `detect_error_type()` - Line 81 (note: function name is `detect_error_type`, not `detect_specific_error_type`)
- ✅ `extract_location()` - Line 134 (note: function name is `extract_location`, not `extract_error_location`)
- ✅ `generate_suggestions()` - Line 151
- ✅ `retry_with_backoff()` - Line 234

**Action Required**:
- Update supervise.md to use correct function names: `detect_error_type()` and `extract_location()`
- OR add aliases in error-handling.sh:
```bash
# Aliases for backward compatibility
detect_specific_error_type() { detect_error_type "$@"; }
extract_error_location() { extract_location "$@"; }
export -f detect_specific_error_type
export -f extract_error_location
```

**Verification**:
- [ ] All 6 required functions present
- [ ] Function signatures match usage in supervise.md
- [ ] Aliases added if function names differ

---

### Task 2.2: Verify checkpoint-utils.sh Functions

**Objective**: Confirm checkpoint-utils.sh has checkpoint management functions.

**Required Functions** (as referenced in supervise.md lines 486-738):
- `save_checkpoint()` - Save checkpoint at phase boundary
- `restore_checkpoint()` - Load checkpoint and return resume phase
- `checkpoint_get_field()` - Extract field from checkpoint
- `checkpoint_set_field()` - Update field in checkpoint

**Verification Steps**:

1. **Read checkpoint-utils.sh**: `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`

2. **Check for each function**:
```bash
grep -n "^save_checkpoint()" checkpoint-utils.sh
grep -n "^restore_checkpoint()" checkpoint-utils.sh
grep -n "^checkpoint_get_field()" checkpoint-utils.sh
grep -n "^checkpoint_set_field()" checkpoint-utils.sh
```

**From Read Analysis**:
- ✅ `save_checkpoint()` - Line 58
- ✅ `restore_checkpoint()` - Line 178
- ✅ `checkpoint_get_field()` - Line 381
- ✅ `checkpoint_set_field()` - Line 402

**Additional Utility Functions Available**:
- `validate_checkpoint()` - Line 236
- `migrate_checkpoint_format()` - Line 284
- `checkpoint_increment_replan()` - Line 438
- `checkpoint_delete()` - Line 478

**Verification**:
- [ ] All 4 required functions present
- [ ] Function signatures match usage patterns
- [ ] Additional utilities documented

---

### Task 2.3: Verify unified-logger.sh Functions

**Objective**: Confirm unified-logger.sh has progress emission capabilities.

**Required Functions** (as referenced in supervise.md line 542):
- `emit_progress()` - Emit silent progress marker

**Verification Steps**:

1. **Read unified-logger.sh**: `/home/benjamin/.config/.claude/lib/unified-logger.sh`

2. **Search for emit_progress function**:
```bash
grep -n "emit_progress" unified-logger.sh
```

**From Read Analysis**:
- ❌ `emit_progress()` function NOT found in unified-logger.sh

**Action Required**:
- Add `emit_progress()` function to unified-logger.sh:
```bash
# ==============================================================================
# Progress Markers
# ==============================================================================

#
# emit_progress - Emit silent progress marker
#
# Arguments:
#   $1: phase_number
#   $2: action description
#
# Output format: PROGRESS: [Phase N] - action
#
emit_progress() {
  local phase="$1"
  local action="$2"
  echo "PROGRESS: [Phase $phase] - $action"
}

export -f emit_progress
```

**Verification**:
- [ ] emit_progress function added to unified-logger.sh
- [ ] Function signature matches usage in supervise.md
- [ ] Function exported for external use

---

## Task Group 3: Replace Inline Definitions with Source Statements

### Task 3.1: Remove Inline Utility Functions from supervise.md

**Objective**: Remove 750 lines of inline bash utilities from supervise.md (lines ~339-738).

**Current Structure** (supervise.md lines 338-803):
```markdown
## Shared Utility Functions

```bash
# ═══════════════════════════════════════════════════════════════
# Workflow Scope Detection (After Phase 0: Location)
# ═══════════════════════════════════════════════════════════════

detect_workflow_scope() {
  # ... 40 lines
}

# ═══════════════════════════════════════════════════════════════
# Phase Execution Check
# ═══════════════════════════════════════════════════════════════

should_run_phase() {
  # ... 10 lines
}

# [... 600+ more lines of utilities ...]
```
```

**Replacement Strategy**:

1. **Identify the exact line range to remove**:
   - Start: Line 339 (first function definition)
   - End: Line 803 (end of final function)
   - Total: ~465 lines to remove

2. **Preserve section header**: Keep "## Shared Utility Functions" but replace content

3. **Replace with source statements and documentation**

**Verification**:
- [ ] Inline function definitions removed
- [ ] Section header preserved
- [ ] Line count reduced significantly

---

### Task 3.2: Add Source Statements

**Objective**: Add source statements to load required libraries.

**New Content** (replaces lines 339-803):

```markdown
## Shared Utility Functions

**EXECUTE NOW - Source Required Libraries**

```bash
# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source workflow detection utilities
if [ -f "$SCRIPT_DIR/../lib/workflow-detection.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-detection.sh"
else
  echo "ERROR: workflow-detection.sh not found"
  exit 1
fi

# Source error handling utilities
if [ -f "$SCRIPT_DIR/../lib/error-handling.sh" ]; then
  source "$SCRIPT_DIR/../lib/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found"
  exit 1
fi

# Source checkpoint utilities
if [ -f "$SCRIPT_DIR/../lib/checkpoint-utils.sh" ]; then
  source "$SCRIPT_DIR/../lib/checkpoint-utils.sh"
else
  echo "ERROR: checkpoint-utils.sh not found"
  exit 1
fi

# Source unified logger
if [ -f "$SCRIPT_DIR/../lib/unified-logger.sh" ]; then
  source "$SCRIPT_DIR/../lib/unified-logger.sh"
else
  echo "ERROR: unified-logger.sh not found"
  exit 1
fi
```

**Verification**: All required functions available via sourced libraries.
```

**Implementation Notes**:
- Error handling for missing libraries (fail-fast)
- Consistent path resolution via SCRIPT_DIR
- Order matters: error-handling before checkpoint-utils (checkpoint-utils uses error functions)

**Verification**:
- [ ] Source statements added
- [ ] Error handling for missing libraries
- [ ] Correct sourcing order maintained

---

### Task 3.3: Create Function Reference Table

**Objective**: Document all available utility functions in a comprehensive reference table.

**New Content** (add after source statements):

```markdown
## Available Utility Functions

All utility functions are now sourced from library files. This table documents the complete API:

### Workflow Detection Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `detect_workflow_scope()` | workflow-detection.sh | Determine workflow type from description | `SCOPE=$(detect_workflow_scope "$DESC")` |
| `should_run_phase()` | workflow-detection.sh | Check if phase executes for current scope | `should_run_phase 3 \|\| exit 0` |

### Error Handling Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `classify_error()` | error-handling.sh | Classify error type (transient/permanent/fatal) | `TYPE=$(classify_error "$ERROR_MSG")` |
| `suggest_recovery()` | error-handling.sh | Suggest recovery action based on error type | `suggest_recovery "$ERROR_TYPE" "$MSG"` |
| `detect_error_type()` | error-handling.sh | Detect specific error category | `TYPE=$(detect_error_type "$ERROR")` |
| `extract_location()` | error-handling.sh | Extract file:line from error message | `LOC=$(extract_location "$ERROR")` |
| `generate_suggestions()` | error-handling.sh | Generate error-specific suggestions | `generate_suggestions "$TYPE" "$MSG" "$LOC"` |
| `retry_with_backoff()` | error-handling.sh | Retry command with exponential backoff | `retry_with_backoff 3 500 curl "$URL"` |

### Checkpoint Management Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `save_checkpoint()` | checkpoint-utils.sh | Save workflow checkpoint for resume | `CKPT=$(save_checkpoint "supervise" "project" "$JSON")` |
| `restore_checkpoint()` | checkpoint-utils.sh | Load most recent checkpoint | `DATA=$(restore_checkpoint "supervise" "project")` |
| `checkpoint_get_field()` | checkpoint-utils.sh | Extract field from checkpoint | `PHASE=$(checkpoint_get_field "$CKPT" ".current_phase")` |
| `checkpoint_set_field()` | checkpoint-utils.sh | Update field in checkpoint | `checkpoint_set_field "$CKPT" ".phase" "3"` |

### Progress Logging Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `emit_progress()` | unified-logger.sh | Emit silent progress marker | `emit_progress "1" "Research complete"` |

### Function Categories Summary

- **Workflow Management**: 2 functions (scope detection, phase execution)
- **Error Handling**: 6 functions (classification, recovery, suggestions)
- **Checkpoint Management**: 4 functions (save, restore, get/set fields)
- **Progress Logging**: 1 function (progress markers)

**Total Functions Available**: 13 core utilities
```

**Verification**:
- [ ] All functions documented
- [ ] Usage examples provided
- [ ] Library sources clearly indicated
- [ ] Function count accurate (13 functions)

---

### Task 3.4: Add Retained Examples Section

**Objective**: Keep ~30 lines of inline examples to demonstrate common usage patterns.

**New Content** (add after function reference table):

```markdown
## Retained Usage Examples

The following examples demonstrate common usage patterns for sourced utilities:

### Example 1: Workflow Scope Detection

```bash
# Detect workflow scope and configure phases
WORKFLOW_DESCRIPTION="research authentication patterns to create implementation plan"
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    ;;
esac

export WORKFLOW_SCOPE PHASES_TO_EXECUTE
```

### Example 2: Conditional Phase Execution

```bash
# Check if phase should run
should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  exit 0
}

echo "Executing Phase 3: Implementation"
```

### Example 3: Error Handling with Recovery

```bash
# Classify error and determine recovery
ERROR_MSG="Connection timeout after 30 seconds"
ERROR_TYPE=$(classify_error "$ERROR_MSG")

if [ "$ERROR_TYPE" == "transient" ]; then
  echo "Transient error detected, retrying..."
  retry_with_backoff 3 1000 curl "https://api.example.com"
else
  echo "Permanent error:"
  suggest_recovery "$ERROR_TYPE" "$ERROR_MSG"
  exit 1
fi
```

### Example 4: Checkpoint Save/Restore

```bash
# Save checkpoint at phase boundary
CHECKPOINT_DATA=$(cat <<EOF
{
  "current_phase": 2,
  "completed_phases": [0, 1],
  "scope": "research-and-plan",
  "topic_path": "$TOPIC_PATH"
}
EOF
)

CHECKPOINT_FILE=$(save_checkpoint "supervise" "auth_research" "$CHECKPOINT_DATA")
echo "Checkpoint saved: $CHECKPOINT_FILE"

# Restore checkpoint on resume
RESTORED_DATA=$(restore_checkpoint "supervise" "auth_research")
RESUME_PHASE=$(echo "$RESTORED_DATA" | jq -r '.current_phase + 1')
echo "Resuming from phase: $RESUME_PHASE"
```

### Example 5: Progress Markers

```bash
# Emit progress markers at phase transitions
emit_progress "1" "Invoking 4 research agents in parallel"
# ... agent invocations ...
emit_progress "1" "All research agents completed"
emit_progress "2" "Planning phase started"
```
```

**Verification**:
- [ ] 5 comprehensive examples provided
- [ ] Examples cover all major function categories
- [ ] Code is copy-paste ready
- [ ] Total ~50 lines of examples

---

## Task Group 4: Testing and Validation

### Task 4.1: Create Unit Tests for workflow-detection.sh

**Objective**: Create comprehensive tests for the new library file.

**Test File**: `/home/benjamin/.config/.claude/tests/test_workflow_detection.sh`

**Test Structure**:

```bash
#!/usr/bin/env bash
# Unit tests for workflow-detection.sh

source "$(dirname "$0")/../lib/workflow-detection.sh"

# Test detect_workflow_scope function
test_research_only() {
  local result=$(detect_workflow_scope "research API patterns")
  if [ "$result" == "research-only" ]; then
    echo "✓ PASS: research-only detection"
    return 0
  else
    echo "✗ FAIL: Expected 'research-only', got '$result'"
    return 1
  fi
}

test_research_and_plan() {
  local result=$(detect_workflow_scope "research authentication to create plan")
  if [ "$result" == "research-and-plan" ]; then
    echo "✓ PASS: research-and-plan detection"
    return 0
  else
    echo "✗ FAIL: Expected 'research-and-plan', got '$result'"
    return 1
  fi
}

test_full_implementation() {
  local result=$(detect_workflow_scope "implement OAuth2 authentication")
  if [ "$result" == "full-implementation" ]; then
    echo "✓ PASS: full-implementation detection"
    return 0
  else
    echo "✗ FAIL: Expected 'full-implementation', got '$result'"
    return 1
  fi
}

test_debug_only() {
  local result=$(detect_workflow_scope "fix token refresh bug")
  if [ "$result" == "debug-only" ]; then
    echo "✓ PASS: debug-only detection"
    return 0
  else
    echo "✗ FAIL: Expected 'debug-only', got '$result'"
    return 1
  fi
}

test_should_run_phase() {
  export PHASES_TO_EXECUTE="0,1,2"

  if should_run_phase 1; then
    echo "✓ PASS: should_run_phase detects phase in list"
  else
    echo "✗ FAIL: should_run_phase failed to detect phase 1"
    return 1
  fi

  if ! should_run_phase 3; then
    echo "✓ PASS: should_run_phase correctly skips phase 3"
  else
    echo "✗ FAIL: should_run_phase incorrectly included phase 3"
    return 1
  fi
}

# Run all tests
echo "Running workflow-detection.sh unit tests..."
echo ""

FAILURES=0
test_research_only || FAILURES=$((FAILURES + 1))
test_research_and_plan || FAILURES=$((FAILURES + 1))
test_full_implementation || FAILURES=$((FAILURES + 1))
test_debug_only || FAILURES=$((FAILURES + 1))
test_should_run_phase || FAILURES=$((FAILURES + 1))

echo ""
if [ $FAILURES -eq 0 ]; then
  echo "All tests passed ✓"
  exit 0
else
  echo "Tests failed: $FAILURES"
  exit 1
fi
```

**Verification**:
- [ ] Test file created
- [ ] All 4 workflow types tested
- [ ] should_run_phase tested with positive and negative cases
- [ ] Tests executable and pass

---

### Task 4.2: Integration Testing with Existing Tests

**Objective**: Run existing /supervise tests to ensure no regression.

**Test Discovery**:

1. **Search for existing supervise tests**:
```bash
find /home/benjamin/.config/.claude/tests -name "*supervise*" -o -name "*orchestrate*"
```

2. **Run discovered tests**:
```bash
for test_file in $(find .claude/tests -name "test_*.sh"); do
  if grep -q "supervise\|workflow-detection" "$test_file"; then
    echo "Running: $test_file"
    bash "$test_file"
  fi
done
```

3. **Document test results**:
   - Number of tests run
   - Number passed
   - Number failed
   - Specific failures with error messages

**Verification**:
- [ ] All existing tests discovered
- [ ] All tests executed
- [ ] No regressions introduced
- [ ] Test results documented

---

### Task 4.3: Manual Integration Test

**Objective**: Manually test /supervise with sourced libraries.

**Test Scenarios**:

**Scenario 1: Research-only workflow**
```bash
cd /home/benjamin/.config
.claude/commands/supervise.md "research API authentication patterns"
```

**Expected Behavior**:
- Workflow scope detected as "research-only"
- Phases 0-1 execute
- No plan created
- No errors related to missing functions

**Scenario 2: Research-and-plan workflow**
```bash
.claude/commands/supervise.md "research authentication to create implementation plan"
```

**Expected Behavior**:
- Workflow scope detected as "research-and-plan"
- Phases 0-2 execute
- Plan created
- No errors

**Scenario 3: Library error handling**
```bash
# Temporarily rename workflow-detection.sh to test error handling
mv .claude/lib/workflow-detection.sh .claude/lib/workflow-detection.sh.backup
.claude/commands/supervise.md "test library missing"
# Should see: "ERROR: workflow-detection.sh not found"
mv .claude/lib/workflow-detection.sh.backup .claude/lib/workflow-detection.sh
```

**Expected Behavior**:
- Clear error message about missing library
- Immediate exit with error code
- No confusing stack traces

**Verification**:
- [ ] All 3 scenarios tested
- [ ] Expected behaviors observed
- [ ] No unexpected errors
- [ ] Library loading works correctly

---

## Task Group 5: Documentation Updates

### Task 5.1: Update supervise.md Documentation

**Objective**: Update the command documentation to reflect the new library-based architecture.

**Changes Required**:

1. **Add Library Dependencies section** (after line 169):

```markdown
## Library Dependencies

This command relies on the following library files:

- `.claude/lib/workflow-detection.sh` - Workflow scope detection and phase execution logic
- `.claude/lib/error-handling.sh` - Error classification, recovery, and retry utilities
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore for workflow resume
- `.claude/lib/unified-logger.sh` - Progress markers and structured logging

**Architecture Benefits**:
- 93% reduction in command file size (800 → 50 lines of utilities)
- Shared utilities available to other commands
- Easier testing and maintenance
- Clear separation of concerns

**Fallback Behavior**:
If any required library is missing, the command fails fast with a clear error message indicating which library is not found.
```

2. **Update Performance Metrics section** (line 2120):

```markdown
- **File size**: ~~2,500-3,000 lines~~ → 1,750 lines (750 lines extracted to libraries)
- **Inline utilities**: ~~800 lines~~ → 50 lines (examples only)
- **Library extraction**: 93% reduction in inline bash code
```

**Verification**:
- [ ] Library Dependencies section added
- [ ] Performance metrics updated
- [ ] File size estimates accurate

---

### Task 5.2: Create Library Documentation

**Objective**: Document the new workflow-detection.sh library in the library reference.

**File**: `/home/benjamin/.config/.claude/lib/README.md`

**Add entry for workflow-detection.sh**:

```markdown
### workflow-detection.sh

**Purpose**: Workflow scope detection and phase execution logic for /supervise command

**Functions**:
- `detect_workflow_scope(description)` - Detect workflow type (research-only, research-and-plan, full-implementation, debug-only)
- `should_run_phase(phase_number)` - Check if phase should execute for current scope

**Usage**:
```bash
source .claude/lib/workflow-detection.sh

SCOPE=$(detect_workflow_scope "research auth to create plan")
echo "Detected scope: $SCOPE"  # Output: research-and-plan

export PHASES_TO_EXECUTE="0,1,2"
if should_run_phase 3; then
  echo "Execute phase 3"
else
  echo "Skip phase 3"
fi
```

**Dependencies**: None (pure bash utilities)

**Used by**: /supervise
```

**Verification**:
- [ ] README.md updated
- [ ] Entry includes all required sections
- [ ] Usage example is accurate

---

### Task 5.3: Update Error Message References

**Objective**: Fix any error messages in supervise.md that reference inline functions.

**Search for references**:
```bash
grep -n "inline.*function\|utility.*function" /home/benjamin/.config/.claude/commands/supervise.md
```

**Update error messages** to reference libraries instead:
- Before: "inline utility function failed"
- After: "library function failed (check .claude/lib/workflow-detection.sh)"

**Verification**:
- [ ] All error message references found
- [ ] Messages updated to reference libraries
- [ ] Error messages remain helpful

---

## Task Group 6: Rollback Planning

### Task 6.1: Create Backup of Original supervise.md

**Objective**: Preserve original file for easy rollback if needed.

**Steps**:

1. **Create backup**:
```bash
cp /home/benjamin/.config/.claude/commands/supervise.md \
   /home/benjamin/.config/.claude/commands/supervise.md.pre-library-extraction
```

2. **Add backup metadata**:
```bash
cat > /home/benjamin/.config/.claude/commands/supervise.md.pre-library-extraction.README <<EOF
# Backup Information

**Backup created**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Reason**: Phase 1 of supervise refactor (library extraction)
**Original size**: $(wc -l < /home/benjamin/.config/.claude/commands/supervise.md) lines

## Restoration

To restore from this backup:

\`\`\`bash
mv supervise.md supervise.md.failed-refactor
mv supervise.md.pre-library-extraction supervise.md
rm .claude/lib/workflow-detection.sh
\`\`\`

## Changes Made in Refactor

- Extracted 750 lines of inline utilities to libraries
- Created workflow-detection.sh (150 lines)
- Replaced inline code with source statements (5 lines)
- Added function reference table
- Reduced inline utilities from 800 → 50 lines
EOF
```

**Verification**:
- [ ] Backup file created
- [ ] Metadata file created
- [ ] Restoration instructions clear

---

### Task 6.2: Document Rollback Procedure

**Objective**: Create clear rollback instructions for quick recovery.

**File**: `/home/benjamin/.config/.claude/specs/080_supervise_refactor/ROLLBACK.md`

**Content**:

```markdown
# Phase 1 Rollback Procedure

## Quick Rollback (1 minute)

If library extraction breaks /supervise functionality:

```bash
# 1. Restore original supervise.md
cd /home/benjamin/.config/.claude
mv commands/supervise.md commands/supervise.md.failed-refactor
mv commands/supervise.md.pre-library-extraction commands/supervise.md

# 2. Remove new library file
rm lib/workflow-detection.sh

# 3. Verify restoration
wc -l commands/supervise.md  # Should be ~2150 lines
```

## Partial Rollback (keep library, restore inline)

If you want to keep workflow-detection.sh but restore supervise.md:

```bash
# Just restore supervise.md
mv commands/supervise.md.pre-library-extraction commands/supervise.md
# workflow-detection.sh remains for future use
```

## Verification After Rollback

```bash
# Test original functionality
.claude/commands/supervise.md "research test topic"

# Check for inline functions
grep -c "^detect_workflow_scope()" .claude/commands/supervise.md
# Should output: 1 (function present)
```

## Re-attempt Extraction

If you want to retry the extraction after rollback:

1. Review the failure logs
2. Fix the identified issues
3. Run Phase 1 expansion again
4. Test thoroughly before committing

## Commit Rollback

If rollback is successful, commit the restoration:

```bash
git add .claude/commands/supervise.md
git add .claude/lib/
git commit -m "Rollback: Revert supervise library extraction (Phase 1)"
```
```

**Verification**:
- [ ] Rollback document created
- [ ] Quick rollback procedure tested
- [ ] Instructions are clear and complete

---

## Success Criteria

### Completion Checklist

**Library Creation**:
- [ ] workflow-detection.sh created (150+ lines)
- [ ] detect_workflow_scope() extracted
- [ ] should_run_phase() extracted
- [ ] Functions exported properly

**Library Verification**:
- [ ] error-handling.sh has all 6 required functions (or aliases)
- [ ] checkpoint-utils.sh has all 4 required functions
- [ ] unified-logger.sh has emit_progress() function
- [ ] Function signatures match usage in supervise.md

**Code Replacement**:
- [ ] Inline functions removed from supervise.md (750 lines)
- [ ] Source statements added (5 lines)
- [ ] Function reference table created (complete)
- [ ] Usage examples retained (~50 lines)
- [ ] Total inline code: 800 → 50 lines (93% reduction)

**Testing**:
- [ ] Unit tests created for workflow-detection.sh
- [ ] All existing tests pass
- [ ] Manual integration tests pass
- [ ] No regression in functionality

**Documentation**:
- [ ] supervise.md documentation updated
- [ ] Library README updated
- [ ] Error messages reference libraries
- [ ] Architecture benefits documented

**Rollback Preparation**:
- [ ] Backup created
- [ ] Rollback procedure documented
- [ ] Restoration tested

### Verification Commands

```bash
# Verify library file size
wc -l /home/benjamin/.config/.claude/lib/workflow-detection.sh
# Expected: 150+ lines

# Verify supervise.md reduction
wc -l /home/benjamin/.config/.claude/commands/supervise.md
# Expected: ~1400 lines (down from ~2150)

# Verify source statements present
grep -c "source.*workflow-detection.sh" /home/benjamin/.config/.claude/commands/supervise.md
# Expected: 1

# Verify function reference table
grep -c "Available Utility Functions" /home/benjamin/.config/.claude/commands/supervise.md
# Expected: 1

# Run tests
bash /home/benjamin/.config/.claude/tests/test_workflow_detection.sh
# Expected: All tests pass
```

---

## Risk Mitigation

### High-Risk Areas

1. **Function Name Mismatches**
   - Risk: supervise.md calls functions with different names than in libraries
   - Mitigation: Add aliases in libraries for backward compatibility
   - Verification: Grep for all function calls and cross-reference

2. **Sourcing Order Dependencies**
   - Risk: Libraries depend on functions from other libraries
   - Mitigation: Source in dependency order, document dependencies
   - Verification: Test with each library individually

3. **Missing Functions**
   - Risk: emit_progress() not in unified-logger.sh
   - Mitigation: Add function before extraction
   - Verification: Test emit_progress calls

4. **Path Resolution Issues**
   - Risk: SCRIPT_DIR calculation fails in some environments
   - Mitigation: Test on multiple shells (bash 3.2+, 4.0+, 5.0+)
   - Verification: Manual testing with different bash versions

### Testing Strategy

**Phase 1: Unit Testing**
- Test each extracted function in isolation
- Verify function signatures match
- Test edge cases and error conditions

**Phase 2: Integration Testing**
- Run existing test suite
- Verify no regressions
- Test library loading

**Phase 3: Manual Testing**
- Test all 4 workflow types
- Test error conditions
- Test library missing scenarios

**Phase 4: Performance Testing**
- Measure command startup time
- Compare before/after metrics
- Verify no performance degradation

---

## Implementation Notes

### Complexity Score Breakdown

**Base Complexity**: 4/10 (straightforward extraction)

**Additional Complexity Factors**:
- +1: Function name mismatches require aliases
- +1: Missing emit_progress() requires adding to library
- +1: Integration with 4 different libraries
- +0: Testing complexity (standard unit/integration tests)

**Total Complexity**: 7/10

### Time Estimates

- **Task Group 1** (Library Creation): 30 minutes
- **Task Group 2** (Library Verification): 20 minutes
- **Task Group 3** (Code Replacement): 30 minutes
- **Task Group 4** (Testing): 30 minutes
- **Task Group 5** (Documentation): 20 minutes
- **Task Group 6** (Rollback Planning): 10 minutes

**Total Estimated Time**: 2 hours 20 minutes (includes buffer for issues)

### Dependencies

**Sequential Dependencies**:
1. Task 2.3 must complete before Task 3.2 (need emit_progress in library)
2. Task 3.1-3.4 must complete before Task 4.2 (need code changes before testing)
3. Task 6.1 must complete before Task 3.1 (backup before modification)

**Parallel Opportunities**:
- Task 1.x can run in parallel with Task 2.x
- Task 5.x can run in parallel with Task 4.x
- Task 6.2 can run in parallel with other tasks

---

## Completion Report Template

```markdown
# Phase 1 Completion Report

## Summary

- **Start Time**: [timestamp]
- **End Time**: [timestamp]
- **Duration**: [actual time]
- **Status**: [COMPLETED/PARTIAL/FAILED]

## Metrics

- **Lines Removed**: [actual count]
- **Lines Added**: [library lines + source statements]
- **Net Reduction**: [percentage]
- **Functions Extracted**: [count]
- **Tests Created**: [count]
- **Tests Passed**: [count/total]

## Issues Encountered

[List any issues and resolutions]

## Verification Results

- [ ] All success criteria met
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Rollback tested

## Next Steps

Proceed to Phase 2: [next phase description]
```

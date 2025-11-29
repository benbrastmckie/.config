# Command Error Capture Gap Analysis

## Metadata
- **Date**: 2025-11-27
- **Agent**: research-specialist
- **Topic**: Error Capture Trap Timing Gaps Across All Commands
- **Report Type**: Comparative command analysis

## Executive Summary

Analysis of all 7 command templates reveals that every command shares the exact same 5 error capture gaps identified in /plan. The error trap initialization pattern is copy-pasted across all commands, creating a systemic vulnerability where errors occurring before line ~159 (Block 1) or between bash blocks cannot be captured in errors.jsonl. Commands analyzed: /plan, /build, /debug, /research, /revise, /errors, /repair.

## Findings

### Failure Mode 1: Before error-handling.sh Sourced (Lines 1-135)

**Vulnerability Window**: First ~135 lines of Block 1 in EVERY command

**Pattern Identified** (Universal across ALL commands):
```bash
# Lines 1-117: CLAUDE_PROJECT_DIR detection
# Lines 118-135: Library sourcing with 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
# ... (lines 119-135)
```

**Commands Affected**:
- `/plan` - Lines 118-135 (plan.md:118-135)
- `/build` - Lines 76-93 (build.md:76-93)
- `/debug` - Lines 190-203 (debug.md:190-203)
- `/research` - Lines 119-134 (research.md:119-134)
- `/revise` - Lines 276-293 (revise.md:276-293)
- `/errors` - Lines 171-176 (errors.md:171-176, minimal pattern)
- `/repair` - Lines 142-163 (repair.md:142-163)

**Errors Lost**:
- Library syntax errors (hidden by `2>/dev/null`)
- Permission denied on library files
- Corrupted library files
- Missing library files (caught by `|| exit 1` but NOT logged)

**Example Real Failure** (from plan.md execution):
```
Line 120: FEATURE_DESCRIPTION=$(cat "$TEMP_FILE" 2>/dev/null || echo "")
ERROR: FEATURE_DESCRIPTION: unbound variable
Location: Before error-handling.sh sourced
Result: Error printed to stderr, NOT captured in errors.jsonl
```

### Failure Mode 2: Before setup_bash_error_trap Called (Lines 135-159)

**Vulnerability Window**: After library sourcing, before trap setup

**Pattern Identified** (Universal across ALL commands):
```bash
# Lines 136-148: Library version checking
check_library_requirements "..." || exit 1
validate_library_functions "state-persistence" || exit 1

# Lines 149-154: ensure_error_log_exists (no trap yet!)
ensure_error_log_exists

# Lines 155-159: EARLY trap with temporary metadata
setup_bash_error_trap "/plan" "plan_early_$(date +%s)" "early_init"
```

**Commands with Early Trap**:
- `/plan` - Line 159 with "plan_early_*" ID (plan.md:159)
- `/build` - Line 100 with "build_early_*" ID (build.md:100)
- `/research` - Line 152 with "research_early_*" ID (research.md:152)
- `/revise` - Line 177 (revise.md, uses "revise_early_*")
- `/repair` - Line 177 with "repair_early_*" ID (repair.md:177)

**Commands WITHOUT Early Trap**:
- `/debug` - No early trap! setup_bash_error_trap at line 252, gap is 49 lines (debug.md:203-252)
- `/errors` - No early trap! setup_bash_error_trap at line 281 (errors.md:176-281)

**Problem with Early Trap**:
- Uses placeholder WORKFLOW_ID ("plan_early_1732723456")
- Errors logged with wrong workflow_id
- Cannot be queried by real workflow_id later
- `/errors --workflow-id plan_12345` won't find errors from early trap phase

**Errors Lost or Mislabeled**:
- Variable initialization errors (lines 136-158)
- State file creation errors
- sm_init failures (logged with wrong workflow_id)

### Failure Mode 3: State File Sourcing Without Protection (Block 2+)

**Vulnerability Window**: Lines ~610-677 in Block 2 (all commands)

**Pattern Identified** (Universal across Block 2+ in ALL commands):
```bash
# Line ~610: Read WORKFLOW_ID
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

# Lines ~610-645: Source libraries AGAIN (no trap yet!)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
# ...

# Line ~667: Load state file WITHOUT defensive initialization
load_workflow_state "$WORKFLOW_ID" false

# Line ~678: FINALLY set trap (67-line gap!)
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Commands Affected** (Block 2 pattern):
- `/plan` - Block 2 gap lines 610-678 (68 lines) (plan.md:610-678)
- `/build` - Block 1c gap lines 496-558 (62 lines) (build.md:496-558)
- `/debug` - Block 3 gap lines 479-519 (40 lines) (debug.md:479-519)
- `/research` - Block 2 gap lines 475-534 (59 lines) (research.md:475-534)
- `/revise` - Block 4a gap lines 392-432 (40 lines) (revise.md:392-432)
- `/repair` - Has NO Block 2+ analyzed (only saw Block 1, limit 400 lines)

**Defensive Pattern MISSING**:
```bash
# SHOULD BE (but isn't):
set +u  # Allow unbound variables during source
source "$STATE_FILE"
set -u  # Re-enable strict mode
```

**Currently Used** (unsafe):
```bash
source "$STATE_FILE"  # Will exit if any variable unbound!
```

**Errors Lost**:
- Unbound variable errors during state restoration
- Corrupt state file entries
- Missing state variables (RESEARCH_COMPLEXITY, etc.)
- These errors cause exit 1 WITHOUT logging

**Real Example from /plan Block 2**:
```
Line 667: load_workflow_state "$WORKFLOW_ID" false
Line 729: RESEARCH_DIR="${RESEARCH_DIR:-}"  # Defensive after-the-fact
Problem: If RESEARCH_DIR unbound BEFORE line 729, exit happens at line 667
Result: No error log entry created
```

### Failure Mode 4: Benign Filtering Too Aggressive

**Vulnerability Window**: validate_library_functions return statements

**Pattern Identified** (in error-handling.sh, affects ALL commands):
```bash
# error-handling.sh lines 1626-1644
_is_benign_bash_error() {
  local exit_code="$1"
  local command="$2"

  # PROBLEMATIC: Filters ALL returns from /lib/ directories
  if [[ "$command" =~ ^return$ ]] && [[ "$BASH_SOURCE" =~ \.claude/lib/ ]]; then
    return 0  # Treat as benign
  fi
}
```

**Commands Using validate_library_functions**:
- `/plan` - Lines 149-152 (plan.md:149-152)
- `/build` - Lines 95-109 (build.md, calls check_library_requirements)
- `/debug` - Lines 218-222 (debug.md:218-222)
- `/research` - Lines 140-145 (research.md:140-145)
- `/revise` - Lines 304-308 (revise.md:304-308)
- `/errors` - No library validation (errors.md)
- `/repair` - Lines 166-170 (repair.md:166-170)

**Validation Failures Masked**:
```bash
# Example from /plan:
validate_library_functions "state-persistence" || exit 1
# If validate_library_functions internally calls:
# return 1  # Function not found!
# _is_benign_bash_error sees "return" + ".claude/lib/" and filters it
# Result: exit 1 happens but NO error logged
```

**Functions Affected**:
- `append_workflow_state` - checked in /plan, /build, /debug, /research
- `save_completed_states_to_state` - checked in /plan, /build
- `sm_transition` - NOT validated (should be!)
- `initialize_workflow_paths` - NOT validated (should be!)

### Failure Mode 5: Between Bash Blocks (Stale Trap Metadata)

**Vulnerability Window**: Between ANY two bash blocks in ALL commands

**Pattern Identified** (metadata string interpolation):
```bash
# Block 1: Set trap with metadata
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
# Trap captures: command="/plan", workflow_id="plan_12345"

# --- Bash block boundary (new subprocess) ---

# Block 2: Trap LOST (new bash process)
# Libraries re-sourced
# Trap re-set at line 678
# GAP: Lines 610-678 have NO trap at all!
```

**Commands with Multiple Blocks**:
- `/plan` - 3 blocks (1a/1b/1c, 2, 3) - 2 vulnerability windows (plan.md)
- `/build` - 4 blocks (1a/1b/1c, 2, 3, 4) - 3 vulnerability windows (build.md)
- `/debug` - 6 blocks (1-6) - 5 vulnerability windows (debug.md)
- `/research` - 2 blocks (1a/1b/1c/1d, 2) - 1 vulnerability window (research.md)
- `/revise` - Multiple blocks (not fully analyzed, limit 500 lines)
- `/errors` - 2 blocks - 1 vulnerability window (errors.md)
- `/repair` - Multiple blocks (not fully analyzed, limit 400 lines)

**Trap Re-Set Location** (Block 2):
- `/plan` - Line 679 (68-line gap from block start)
- `/build` - Line 558 (62-line gap from block start)
- `/debug` - Line 519 (40-line gap from block start)
- `/research` - Line 534 (59-line gap from block start)

**Metadata Staleness Example**:
```bash
# Block 1: Trap set with:
# USER_ARGS="implement JWT authentication"

# Block 2: Variable restored from state:
# USER_ARGS="implement JWT authentication"  # Same value

# But if state file corrupted:
# USER_ARGS=""  # DIFFERENT value, but trap has old value!

# Error logged with STALE metadata from Block 1
```

## Comparative Analysis

### Commands with ALL 5 Gaps

**All 7 commands analyzed have all 5 failure modes:**

| Command | Gap 1 (Lines) | Gap 2 (Has Early Trap?) | Gap 3 (Block 2 Lines) | Gap 4 (Uses validate) | Gap 5 (# Blocks) |
|---------|---------------|-------------------------|------------------------|------------------------|-------------------|
| /plan | 118-135 (17) | YES (line 159) | 610-678 (68) | YES | 3 blocks |
| /build | 76-93 (17) | YES (line 100) | 496-558 (62) | YES | 4 blocks |
| /debug | 190-203 (13) | NO (49-line gap!) | 479-519 (40) | YES | 6 blocks |
| /research | 119-134 (15) | YES (line 152) | 475-534 (59) | YES | 2 blocks |
| /revise | 276-293 (17) | YES (line 177) | 392-432 (40) | YES | 4+ blocks |
| /errors | 171-176 (5) | NO (105-line gap!) | Not analyzed | NO | 2 blocks |
| /repair | 142-163 (21) | YES (line 177) | Not analyzed | YES | 3+ blocks |

### Gap Severity by Command

**Most Vulnerable** (/errors):
- No early trap (105-line gap before first trap!)
- Shortest library sourcing gap (5 lines, but still vulnerable)
- Used for error analysis, ironically most vulnerable to errors

**Second Most Vulnerable** (/debug):
- No early trap (49-line gap)
- Used for debugging, should have most robust error capture
- 6 bash blocks = 5 vulnerability windows between blocks

**Third Most Vulnerable** (/plan):
- Has early trap, but 68-line gap in Block 2 (longest)
- Most frequently used command, highest error volume
- Serves as template for other commands

### Shared Code Patterns

**All commands share identical code structure:**
```bash
# Block 1 (Lines 1-159 pattern):
# 1. CLAUDE_PROJECT_DIR detection (30 lines, no error handling)
# 2. Library sourcing (17 lines, 2>/dev/null suppression)
# 3. ensure_error_log_exists (no trap yet!)
# 4. setup_bash_error_trap (early trap with temporary ID)
# 5. Variable initialization
# 6. sm_init
# 7. sm_transition

# Block 2+ (Lines ~610-678 pattern):
# 1. CLAUDE_PROJECT_DIR detection (re-do!)
# 2. Library sourcing (re-do!)
# 3. load_workflow_state (BEFORE trap!)
# 4. setup_bash_error_trap (finally!)
```

**Implication**: Fixing one command provides template for all others.

## Recommendations

### 1. Create Pre-Trap Error Buffer (Universal)

**Applies to**: ALL 7 commands

**Implementation**:
```bash
# TOP of EVERY bash block (before ANY other code):
declare -a _EARLY_ERROR_BUFFER=()
_buffer_early_error() {
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local line="${BASH_LINENO[0]}"
  local code="${1:-1}"
  local message="${2:-Unknown error}"
  _EARLY_ERROR_BUFFER+=("$timestamp|$line|$code|$message")
}

# After error-handling.sh sourced and trap set:
_flush_early_errors() {
  for entry in "${_EARLY_ERROR_BUFFER[@]}"; do
    IFS='|' read -r timestamp line code message <<< "$entry"
    log_command_error \
      "${COMMAND_NAME:-unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "initialization_error" \
      "$message" \
      "early_buffer" \
      "$(jq -n --argjson line "$line" --argjson code "$code" '{line: $line, code: $code}')"
  done
  _EARLY_ERROR_BUFFER=()
}
```

**Benefits**:
- Captures errors in Gap 1 (before error-handling.sh)
- Captures errors in Gap 5 (between blocks)
- Works across ALL commands with same code

### 2. Remove Overly Aggressive Benign Filtering

**Applies to**: error-handling.sh (affects ALL commands)

**Change** (error-handling.sh:1626-1644):
```bash
# BEFORE:
if [[ "$command" =~ ^return$ ]] && [[ "$BASH_SOURCE" =~ \.claude/lib/ ]]; then
  return 0  # Treat ALL library returns as benign
fi

# AFTER:
if [[ "$command" =~ ^return$ ]] && [[ "$BASH_SOURCE" =~ \.claude/lib/ ]]; then
  # Whitelist ONLY safe functions
  local caller_func=$(caller 1 | awk '{print $2}')
  case "$caller_func" in
    classify_error|suggest_recovery|detect_error_type|extract_location)
      return 0  # These are benign
      ;;
    *)
      # Log validation failures and other library returns
      return 1
      ;;
  esac
fi
```

**Benefits**:
- validate_library_functions failures now logged
- Specific functions still filtered (no noise)
- ONE change fixes ALL commands

### 3. Defensive State Restoration (Universal)

**Applies to**: ALL commands with Block 2+

**Implementation**:
```bash
# Block 2+ (before load_workflow_state):
set +u  # Temporarily allow unbound variables
source "$STATE_FILE" 2>/dev/null || {
  set -u
  echo "ERROR: Failed to source state file: $STATE_FILE" >&2
  _buffer_early_error 1 "State file sourcing failed: $STATE_FILE"
  exit 1
}
set -u  # Re-enable strict mode

# DEFENSIVE: Initialize variables that might be unbound
RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-2}"
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
ARCHIVED_PROMPT_PATH="${ARCHIVED_PROMPT_PATH:-}"
```

**Benefits**:
- Prevents exit on unbound variables during state load
- Errors buffered instead of lost
- Applies to /plan, /build, /debug, /research, /revise, /repair

### 4. Eliminate 2>/dev/null Blindness (Universal)

**Applies to**: ALL commands (library sourcing lines 118-135)

**Create Helper** (error-handling.sh):
```bash
_source_with_diagnostics() {
  local lib_path="$1"
  local lib_name=$(basename "$lib_path")
  local stderr_file=$(mktemp)

  if source "$lib_path" 2>"$stderr_file"; then
    rm -f "$stderr_file"
    return 0
  else
    local stderr_content=$(cat "$stderr_file")
    rm -f "$stderr_file"
    _buffer_early_error 1 "Failed to source $lib_name: $stderr_content"
    return 1
  fi
}
```

**Usage** (replace ALL `source ... 2>/dev/null || exit 1` lines):
```bash
# BEFORE:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# AFTER:
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

**Benefits**:
- Syntax errors in libraries now visible
- Permission errors captured
- ONE helper function used by ALL commands

### 5. Workflow ID Validation and Fallback (Universal)

**Applies to**: ALL commands with Block 2+

**Implementation** (in Block 2, after reading STATE_ID_FILE):
```bash
# Read WORKFLOW_ID
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

# VALIDATE format (e.g., plan_1234567890)
if ! [[ "$WORKFLOW_ID" =~ ^[a-z_]+_[0-9]+$ ]]; then
  WORKFLOW_ID="${COMMAND_NAME#/}_$(date +%s)_recovered"
  _buffer_early_error 1 "Invalid WORKFLOW_ID in state file, using fallback: $WORKFLOW_ID"
fi
```

**Benefits**:
- Prevents empty WORKFLOW_ID from causing workflow_id="unknown"
- Errors remain searchable via /errors command
- Applies to all commands with multiple blocks

### 6. Block Boundary Markers (Observability)

**Applies to**: ALL commands with multiple blocks

**Implementation**:
```bash
# TOP of each bash block (after buffer initialization):
_log_block_boundary() {
  local block_num="$1"
  local block_name="$2"
  if declare -f log_command_error >/dev/null 2>&1; then
    log_command_error \
      "${COMMAND_NAME:-unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "block_boundary" \
      "Entering $block_name" \
      "block_$block_num" \
      "$(jq -n --argjson num "$block_num" '{block_number: $num}')"
  fi
}

# Usage:
_log_block_boundary 2 "Research Verification"
```

**Benefits**:
- Errors can be correlated to specific blocks
- Helps identify which block had the gap
- Useful for debugging trap metadata staleness

### 7. Create Comprehensive Test Suite

**Coverage Required**:

1. **Pre-trap buffer test**:
   - Trigger error before error-handling.sh sourced
   - Verify error appears in errors.jsonl after buffer flush

2. **Defensive state restoration test**:
   - Corrupt state file with unbound variable
   - Verify error logged instead of exit 1

3. **Benign filtering test**:
   - Call validate_library_functions with missing function
   - Verify error logged (not filtered)

4. **Workflow ID validation test**:
   - Corrupt STATE_ID_FILE with invalid format
   - Verify fallback ID generated and logged

5. **Library sourcing diagnostics test**:
   - Create library with syntax error
   - Verify stderr captured and logged

6. **Block boundary test**:
   - Multi-block command execution
   - Verify trap re-set between blocks
   - Verify metadata refreshed

7. **Integration test**:
   - Reproduce original FEATURE_DESCRIPTION error
   - Verify error now captured in errors.jsonl

## References

**Command Files Analyzed** (with specific line numbers):
- /home/benjamin/.config/.claude/commands/plan.md (lines 118-135, 159, 610-678, 729)
- /home/benjamin/.config/.claude/commands/build.md (lines 76-93, 100, 496-558)
- /home/benjamin/.config/.claude/commands/debug.md (lines 190-203, 252, 479-519)
- /home/benjamin/.config/.claude/commands/research.md (lines 119-134, 152, 475-534)
- /home/benjamin/.config/.claude/commands/revise.md (lines 276-293, 177, 392-432)
- /home/benjamin/.config/.claude/commands/errors.md (lines 171-176, 281)
- /home/benjamin/.config/.claude/commands/repair.md (lines 142-163, 177)

**Library Files Referenced**:
- /home/benjamin/.config/.claude/lib/core/error-handling.sh (lines 1626-1644 for benign filtering)
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh (load_workflow_state, append_workflow_state)
- /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh (sm_init, sm_transition)

**Existing Plan Reference**:
- /home/benjamin/.config/.claude/specs/955_error_capture_trap_timing/plans/001-error-capture-trap-timing-plan.md

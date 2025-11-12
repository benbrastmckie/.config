# Bash Command Failures in /coordinate Command Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: Bash command failures in /coordinate command execution
- **Report Type**: debugging analysis
- **Complexity Level**: 2

## Executive Summary

The /coordinate command experiences two distinct bash-related errors during execution: (1) bash history expansion errors (`bash: line N: !: command not found`) occurring at lines 145, and 74 in Phase 0, and (2) missing function errors (`emit_progress: command not found`). Both errors are non-blocking but degrade output quality and user experience. The root cause is an architectural mismatch between Claude Code's markdown-to-bash execution model and bash's parsing behavior, combined with Bash tool's export non-persistence limitation.

**Key Findings**:
- **Error 1**: History expansion triggered by `${!varname}` indirect variable references in sourced library files (9 occurrences across 2 files)
- **Error 2**: `emit_progress` function not found due to library sourcing happening in separate bash invocation contexts
- **Impact**: Functional (workflow completes) but produces confusing error messages
- **Root Cause**: Bash parses scripts for history expansion BEFORE executing commands like `set +H`

## Findings

### Finding 1: Bash History Expansion Errors

#### Symptoms

From `/home/benjamin/.config/.claude/specs/coordinate_output.md`:

```
Line 21: bash: line 145: !: command not found
Line 32: bash: line 74: emit_progress: command not found
```

These errors appear during Phase 0 initialization blocks but do not prevent workflow completion.

#### Root Cause Analysis

**Primary Issue**: Indirect variable reference syntax in library files triggers bash history expansion

**Evidence from codebase analysis**:

1. **`.claude/lib/context-pruning.sh`** - 7 occurrences:
   - Line 55: `local full_output="${!output_var_name}"`
   - Line 150: `for key in "${!PRUNED_METADATA_CACHE[@]}"`
   - Line 245: `for phase_id in "${!PHASE_METADATA_CACHE[@]}"`
   - Line 252: `for key in "${!PRUNED_METADATA_CACHE[@]}"`
   - Line 314: `for key in "${!PRUNED_METADATA_CACHE[@]}"`
   - Line 320: `for key in "${!PHASE_METADATA_CACHE[@]}"`
   - Line 326: `for key in "${!WORKFLOW_METADATA_CACHE[@]}"`

2. **`.claude/lib/workflow-initialization.sh`** - 2 occurrences:
   - Line 291: `for i in "${!report_paths[@]}"`
   - Line 319: `REPORT_PATHS+=("${!var_name}")`

**Bash Syntax Explanation**:
- `${!varname}` = indirect variable expansion (reads value of variable whose name is stored in `varname`)
- `${!array[@]}` = array key iteration (gets all keys/indices of an array)
- Both are valid bash 4.x+ syntax for legitimate shell programming needs

**Why History Expansion Triggers**:

From previous diagnostic report at `/home/benjamin/.config/.claude/specs/coordinate_diagnostic_report.md` (lines 64-83):

```
Bash parses script text for history expansion BEFORE executing any commands,
including `set +H`.

Why `set +H` Doesn't Work:
  bash -c 'set +H; echo ${!var}'  # Still fails!

The script text is parsed for history expansion BEFORE the `set +H` command
executes. By the time `set +H` runs, bash has already tried to expand the
`!` characters and failed.
```

**Execution Flow**:

```
Claude Code → bash -c '<script>' → Bash Process
                                    ├─ PARSE PHASE (first)
                                    │  ├─ Check shell options
                                    │  ├─ Tokenize script
                                    │  └─ Expand history (! patterns) ❌ FAILS HERE
                                    └─ EXECUTE PHASE (never reached)
                                       └─ Run: set +H (too late)
```

#### Location in /coordinate Command

From `/home/benjamin/.config/.claude/commands/coordinate.md`:

**Line 844**: Phase 0 Block 2 (Function Definitions)
```bash
local checkpoint_pid=$!
```

This line captures the PID of a background process, using bash's special variable `$!` (last background PID). When sourcing library files that contain `${!varname}`, bash's parser interprets the `!` as a history expansion trigger before the script executes.

**Line 702**: Phase 0 Block 1 (Library Sourcing)
```bash
if ! source_required_libraries "${REQUIRED_LIBS[@]}"; then
```

The negation `!` before `source_required_libraries` is valid bash syntax, but when combined with the sourced library files containing `${!varname}`, the accumulated `!` characters trigger history expansion parsing errors.

#### Pattern Comparison with Other Commands

Checking `/orchestrate` and `/supervise` for similar issues:

**Search Results**:
- Neither `/orchestrate.md` nor `/supervise.md` use `$!` for background PIDs
- Both commands avoid indirect variable references in inline bash blocks
- Other commands delegate complex state management to library functions without inlining them

**Key Difference**: `/coordinate` attempts to inline checkpoint management with background processes, while other commands use simpler sequential patterns.

### Finding 2: Function Not Found Errors

#### Symptoms

```
Line 32: bash: line 74: emit_progress: command not found
```

The `emit_progress` function is defined in `unified-logger.sh` but is not available when called in Phase 0 Block 3.

#### Root Cause Analysis

**Primary Issue**: Bash tool creates separate shell processes for each invocation, and function exports don't persist

**Evidence from /coordinate execution flow**:

1. **Phase 0 Block 1** (lines 526-712): Sources libraries and defines REQUIRED_FUNCTIONS
   ```bash
   source_required_libraries "${REQUIRED_LIBS[@]}"
   ```

2. **Phase 0 Block 3** (lines 905-991): Attempts to call `emit_progress`
   ```bash
   emit_progress "0" "Phase 0 complete (topic: $TOPIC_PATH)"
   ```

**Problem**: Block 1 and Block 3 run in **different bash processes**. Functions sourced in Block 1 are not available in Block 3.

**From coordinate_output.md observations** (lines 16-33):
```
Phase 0: Initialization started
  ✓ Libraries loaded (5 for research-and-plan)
bash: line 145: !: command not found
...
bash: line 74: emit_progress: command not found
```

Libraries are successfully loaded in Block 1, but functions are unavailable in subsequent blocks.

#### Documentation References

From `/home/benjamin/.config/.claude/specs/coordinate_diagnostic_report.md` (lines 300-323):

> **Fundamental Limitation**: The Bash tool creates a **new shell process** for each invocation.
> Environment variables exported in one invocation are NOT available in subsequent invocations.
> This is documented in Claude Code GitHub issues #334 and #2508.

From `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 719-723):

> Bash tool limitation (GitHub #334, #2508): exports from Block 1 don't persist to Block 2.
> Recalculate using same git-based detection pattern.

**Current Workaround Pattern** (coordinate.md lines 1002-1005):

```bash
# Source verification helpers library
# Note: Export -f doesn't persist between Bash invocations (GitHub #334, #2508)
# Solution: Source library in blocks that need it (this block and Phase 1)
```

**Why the workaround fails for emit_progress**:

Phase 0 Block 3 does NOT re-source the unified-logger.sh library before calling `emit_progress`, despite the documented limitation. Block 3 only sources workflow-initialization.sh (line 910).

### Finding 3: Error Impact on Workflow Execution

#### Functional Impact: Minimal

From coordinate_output.md analysis:
- Phase 0 completed successfully (line 20: "✓ Libraries loaded")
- Workflow scope detected correctly (line 26: "research-and-plan")
- All 3 research agents completed (lines 68-74)
- Plan creation succeeded (lines 102-109)
- Overall workflow status: "Complete" (line 118)

**Conclusion**: Errors are **non-blocking warnings** that don't prevent successful execution.

#### User Experience Impact: High

**Confusion Factors**:
1. Error messages appear immediately after "Phase 0: Initialization started" (line 19-21)
2. Errors mixed with success messages creates ambiguity about workflow health
3. "command not found" typically indicates serious failure, but workflow continues
4. Users may attempt unnecessary debugging or abort workflows prematurely

**Evidence from output pattern**:
```
Phase 0: Initialization started
  ✓ Libraries loaded (5 for research-and-plan)
bash: line 145: !: command not found    ← Confusing error

✓ Workflow scope detected: research-and-plan  ← But workflow continues?
```

#### Debugging Impact: Medium

**Problems for maintainers**:
1. Real errors may be hidden among expected warnings
2. Log analysis tools may flag false positives
3. Automated testing must distinguish expected vs unexpected errors
4. New contributors may assume command is broken

### Finding 4: Historical Context and Related Work

#### Previous Research

**Spec 582**: `/home/benjamin/.config/.claude/specs/582_coordinate_bash_history_expansion_fixes/`

From `QUICK_SUMMARY.md`:
- ✓ Bash invocation already optimal (non-interactive, histexpand disabled)
- ❌ Adding `set +H` ineffective (timing issue)
- ✓ Root cause identified: indirect variable references in libraries

**Spec 593**: `/home/benjamin/.config/.claude/specs/593_coordinate_command_fixes/`

From `reports/001_coordinate_issues_analysis.md` (lines 28-85):
- Issue classified as "High priority" but "causes errors but workflow continues"
- Three fix options evaluated:
  1. Escape exclamation marks (simplest)
  2. Disable history expansion in bash invocations (robust)
  3. Use different punctuation (cleanest)
- Recommendation: Option 3 (reword) + Option 2 (set +H) for defense in depth

#### Git History

From coordinate_output.md git status (lines 1-4):
```
M .claude/specs/coordinate_output.md
?? .claude/specs/593_coordinate_command_fixes/
```

Recent commit: "fd975080 fix(coordinate): resolve 3 critical regressions from export persistence refactor"

**Implication**: Export persistence issues were recently addressed, but history expansion errors remain.

## Recommendations

### Recommendation 1: Fix $! Background PID Reference (High Priority)

**Problem**: Line 844 in coordinate.md uses `$!` to capture background checkpoint PID, triggering history expansion.

**Solution**: Replace with alternative patterns that avoid `!` in bash blocks.

**Option A**: Use explicit PID capture before background operation
```bash
# Before (line 843-844):
save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json" &
local checkpoint_pid=$!

# After:
save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json" &
checkpoint_pid=$BASHPID  # Or capture differently
```

**Option B**: Remove background checkpointing entirely
```bash
# Synchronous checkpoint (simpler, slight performance cost):
save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json"
```

**Option C**: Move checkpoint logic to separate block without `$!`
```bash
# Block 1: Trigger checkpoint
save_checkpoint_in_background "coordinate" "phase_${from_phase}" "$artifacts_json"

# Library handles PID internally, never exposed to coordinate.md
```

**Recommended**: Option C (encapsulate in library) for cleanest separation of concerns.

**Effort**: 1-2 hours (modify checkpoint-utils.sh, test)

**Impact**: Eliminates line 145 history expansion error

### Recommendation 2: Fix emit_progress Function Availability (High Priority)

**Problem**: Phase 0 Block 3 calls `emit_progress` without sourcing unified-logger.sh first.

**Solution**: Add library sourcing to Block 3.

**Implementation** (coordinate.md line 905, before line 989):

```bash
# ────────────────────────────────────────────────────────────────────
# STEP 0.6: Initialize Workflow Paths
# ────────────────────────────────────────────────────────────────────

# Recalculate CLAUDE_PROJECT_DIR (exports don't persist)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source required libraries for this block
source "$LIB_DIR/library-sourcing.sh"
source_required_libraries "unified-logger.sh" || {
  echo "WARNING: Could not load unified-logger.sh, progress markers disabled"
}

# Source workflow initialization library
source "$LIB_DIR/workflow-initialization.sh" || exit 1
```

**Effort**: 15 minutes (add sourcing lines, test)

**Impact**: Eliminates line 74 "emit_progress: command not found" error

### Recommendation 3: Refactor Library Files to Eliminate Indirect References (Long-term)

**Problem**: 9 instances of `${!varname}` and `${!array[@]}` in library files trigger history expansion during sourcing.

**Solution**: Replace with bash 4.3+ nameref pattern or alternative approaches.

**Implementation Example** (context-pruning.sh line 55):

```bash
# Before:
prune_subagent_output() {
  local output_var_name="$1"
  local full_output="${!output_var_name}"  # ← Triggers history expansion
  # ...
}

# After (using nameref):
prune_subagent_output() {
  local output_var_name="$1"
  declare -n output_ref="$output_var_name"
  local full_output="$output_ref"  # ← No ! character
  # ...
}
```

**For array key iteration** (context-pruning.sh line 150):

```bash
# Before:
for key in "${!PRUNED_METADATA_CACHE[@]}"; do  # ← Triggers history expansion

# After (cache keys during initialization):
# In cache initialization:
PRUNED_METADATA_CACHE_KEYS=("${!PRUNED_METADATA_CACHE[@]}")

# In iteration:
for key in "${PRUNED_METADATA_CACHE_KEYS[@]}"; do  # ← No ! character
```

**Files to modify**:
1. `.claude/lib/context-pruning.sh` - 7 locations
2. `.claude/lib/workflow-initialization.sh` - 2 locations

**Effort**: 4-6 hours (modify, test all affected functions, update tests)

**Impact**: Eliminates all history expansion errors at root cause

**Trade-offs**:
- **Pros**: Cleaner solution, more portable, eliminates all `!` characters
- **Cons**: Requires bash 4.3+, moderate refactoring effort, testing overhead

### Recommendation 4: Consolidate Phase 0 Bash Blocks (Medium Priority)

**Problem**: State (functions, variables) doesn't persist between bash blocks, requiring re-sourcing and recalculation.

**Solution**: Merge Phase 0 Blocks 1-3 into single block to eliminate inter-block state transfer.

**Current Structure**:
- Block 1 (lines 526-712): Project detection, library sourcing
- Block 2 (lines 718-897): Function verification, definitions
- Block 3 (lines 905-991): Path initialization, completion

**Proposed Structure**:
- Single Block (lines 526-991): All Phase 0 initialization in one bash invocation

**Benefits**:
1. Functions sourced once, available throughout Phase 0
2. No export persistence issues within Phase 0
3. Reduces token usage by ~50-100 lines (eliminate recalculation boilerplate)
4. Simplifies debugging (single execution context)

**Effort**: 2-3 hours (merge blocks, test, verify no regressions)

**Impact**: Prevents both error types by ensuring libraries sourced only once in single context

### Recommendation 5: Add Defensive Checks for Missing Functions (Low Priority)

**Problem**: When functions are missing, bash produces generic "command not found" errors without context.

**Solution**: Add function existence checks before critical calls.

**Implementation Pattern** (coordinate.md):

```bash
# Before:
emit_progress "0" "Phase 0 complete (topic: $TOPIC_PATH)"

# After:
if command -v emit_progress >/dev/null 2>&1; then
  emit_progress "0" "Phase 0 complete (topic: $TOPIC_PATH)"
else
  echo "PROGRESS: [Phase 0] - Phase 0 complete (topic: $TOPIC_PATH)"
fi
```

**Benefits**:
- Graceful degradation when functions unavailable
- Clearer error messages
- Maintains progress reporting even if library sourcing fails

**Effort**: 1-2 hours (add checks to all critical function calls)

**Impact**: Reduces confusion from "command not found" errors, doesn't eliminate root cause

### Priority Matrix

| Recommendation | Priority | Effort | Impact | When to Implement |
|----------------|----------|--------|--------|-------------------|
| Fix $! PID reference | High | 1-2h | Eliminates line 145 error | Immediately |
| Fix emit_progress sourcing | High | 15m | Eliminates line 74 error | Immediately |
| Consolidate Phase 0 blocks | Medium | 2-3h | Prevents both errors | After high priority |
| Refactor library files | Long-term | 4-6h | Eliminates root cause | Future iteration |
| Add defensive checks | Low | 1-2h | Improves UX | Optional enhancement |

### Implementation Sequence

**Phase 1 (Quick Wins - 2-3 hours)**:
1. Fix emit_progress sourcing (15 minutes)
2. Fix $! PID reference (1-2 hours)
3. Test basic workflow (30 minutes)

**Phase 2 (Consolidation - 2-3 hours)**:
4. Consolidate Phase 0 blocks (2-3 hours)
5. Test all workflow types (1 hour)

**Phase 3 (Root Cause - 4-6 hours)**:
6. Refactor library files with nameref pattern (4-6 hours)
7. Comprehensive testing (2 hours)

**Total Effort**: 8-14 hours for complete resolution

## References

### Primary Source Files

1. **`/home/benjamin/.config/.claude/commands/coordinate.md`**
   - Line 702: `!` in conditional (source_required_libraries)
   - Line 844: `local checkpoint_pid=$!` (background PID capture)
   - Line 989: `emit_progress` call without prior library sourcing
   - Lines 526-991: Phase 0 split into 3 separate bash blocks

2. **`/home/benjamin/.config/.claude/lib/context-pruning.sh`**
   - Line 55: `local full_output="${!output_var_name}"`
   - Lines 150, 245, 252, 314, 320, 326: Array key iteration with `${!array[@]}`

3. **`/home/benjamin/.config/.claude/lib/workflow-initialization.sh`**
   - Line 291: `for i in "${!report_paths[@]}"`
   - Line 319: `REPORT_PATHS+=("${!var_name}")`

4. **`/home/benjamin/.config/.claude/lib/unified-logger.sh`**
   - Defines `emit_progress()` function (required by Phase 0 Block 3)

### Related Documentation

5. **`/home/benjamin/.config/.claude/specs/coordinate_diagnostic_report.md`**
   - Lines 64-83: Explanation of why `set +H` fails
   - Lines 159-181: Execution flow diagram
   - Lines 200-290: Analysis of 4 solution approaches

6. **`/home/benjamin/.config/.claude/specs/593_coordinate_command_fixes/reports/001_coordinate_issues_analysis.md`**
   - Lines 28-85: History expansion error analysis
   - Lines 458-493: Prioritized fix recommendations
   - Lines 496-520: Proposed fix plan with effort estimates

7. **`/home/benjamin/.config/.claude/specs/582_coordinate_bash_history_expansion_fixes/`**
   - QUICK_SUMMARY.md: Summary of previous research
   - reports/001_coordinate_bash_history_expansion_fixes/002_history_expansion_disable_methods.md: Detailed analysis of disable methods

### Execution Context

8. **`/home/benjamin/.config/.claude/specs/coordinate_output.md`**
   - Lines 19-21: Error manifestation in actual execution
   - Line 32: emit_progress error context
   - Lines 118-167: Overall workflow completion status

### Architectural References

9. **Claude Code GitHub Issues**
   - Issue #334: Bash tool export non-persistence
   - Issue #2508: Related discussion on state management

### Testing Resources

10. **`/home/benjamin/.config/.claude/tests/`**
    - test_coordinate_workflow.sh (recommended for creation)
    - Existing test patterns for other commands

# Systematic Command Pattern Analysis - State Persistence & Error Logging

**Report ID**: 002
**Created**: 2025-11-20
**Workflow**: revise
**Analysis Scope**: All workflow commands in .claude/commands/
**Research Complexity**: 2

---

## Executive Summary

After analyzing all workflow commands in `.claude/commands/`, I've identified that **the /plan command issues are NOT unique** - they represent a **systematic gap** affecting 6 out of 6 multi-block workflow commands. However, the severity varies:

**Critical Finding**: While all commands have state file validation in Block 1, **only /build has comprehensive state validation checkpoints between blocks**. The remaining 5 commands (/plan, /debug, /research, /revise, /repair) lack:
1. State validation checkpoints after `load_workflow_state()` in subsequent blocks
2. Error logging integration (`log_command_error()`) at error points
3. Diagnostic output when state loading fails

**Recommendation**: **Systematic fix required** - Apply defensive patterns to all 6 commands, but with /build as the reference implementation that already demonstrates best practices.

---

## Commands Analyzed

### Multi-Block Workflow Commands (All Use State Persistence)

1. **/plan** - Research-and-Plan (3 blocks)
2. **/build** - Build-from-Plan (4 blocks)
3. **/debug** - Debug-Focused (6 blocks)
4. **/research** - Research-Only (2 blocks)
5. **/revise** - Research-and-Revise (5 blocks)
6. **/repair** - Error Analysis and Repair Planning (3 blocks)

### Commands Excluded from Analysis

- **/setup** - Does NOT use state persistence (single block, no workflow state machine)
- **/optimize-claude** - Uses `log_command_error()` but has different architecture
- **/errors** - Utility command, not a workflow
- **/expand**, **/collapse**, **/convert-docs** - Utility commands

---

## Pattern Analysis Matrix

| Command | Blocks | STATE_FILE Init | Block 1 Validation | Block 2+ Validation | Error Logging | Diagnostic Output |
|---------|--------|-----------------|-------------------|---------------------|---------------|-------------------|
| /build  | 4      | ✅ Yes          | ✅ Yes            | ✅ **YES**         | ❌ No         | ✅ **YES**       |
| /plan   | 3      | ✅ Yes          | ✅ Yes            | ❌ **NO**          | ❌ No         | ❌ **NO**        |
| /debug  | 6      | ✅ Yes          | ✅ Yes            | ❌ **NO**          | ❌ No         | ❌ **NO**        |
| /research | 2    | ✅ Yes          | ✅ Yes            | ❌ **NO**          | ❌ No         | ❌ **NO**        |
| /revise | 5      | ✅ Yes          | ✅ Yes            | ❌ **NO**          | ❌ No         | ❌ **NO**        |
| /repair | 3      | ✅ Yes          | ✅ Yes            | ❌ **NO**          | ❌ No         | ❌ **NO**        |

**Key Observations**:
- ✅ **Consistent Pattern**: All 6 commands properly initialize `STATE_FILE` in Block 1
- ✅ **Consistent Pattern**: All 6 commands validate state creation in Block 1
- ❌ **Critical Gap**: Only /build validates state after `load_workflow_state()` in subsequent blocks
- ❌ **Critical Gap**: NONE of the commands integrate error logging with `log_command_error()`
- ✅ **Best Practice**: /build provides diagnostic output when state loading fails (DEBUG_LOG)

---

## Detailed Command Analysis

### 1. /build Command (REFERENCE IMPLEMENTATION)

**File**: `/home/benjamin/.config/.claude/commands/build.md`
**Blocks**: 4 (Setup, Phase Update, Testing, Completion)
**State Persistence**: YES (all blocks load state)

#### Strengths (Best Practices to Replicate)

✅ **Block 1 - Proper Initialization**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

✅ **Blocks 2-4 - Comprehensive State Validation** (EXAMPLE TO FOLLOW):
```bash
load_workflow_state "$WORKFLOW_ID" false

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 2, testing phase initialization"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 2, testing phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi
```

✅ **Additional State Validation** (checks CURRENT_STATE):
```bash
if [ -z "${CURRENT_STATE:-}" ] || [ "$CURRENT_STATE" = "initialize" ]; then
  {
    echo "[$(date)] ERROR: State restoration failed"
    echo "WHICH: load_workflow_state"
    echo "WHAT: CURRENT_STATE not properly restored"
    echo "WHERE: Block 2, testing phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State restoration failed (see $DEBUG_LOG)" >&2
  exit 1
fi
```

#### Gaps

❌ **No Error Logging Integration**:
- Does NOT source `error-handling.sh` in Block 1
- Does NOT call `ensure_error_log_exists()`
- Does NOT use `log_command_error()` at error points
- Cannot query errors via `/errors --command /build`

---

### 2. /plan Command (SUBJECT OF CURRENT FIX)

**File**: `/home/benjamin/.config/.claude/commands/plan.md`
**Blocks**: 3 (Setup, Research Agent, Planning Agent)
**State Persistence**: YES (Blocks 2-3 load state)

#### Current State

✅ **Block 1 - Has Basic Validation**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

❌ **Blocks 2-3 - NO State Validation After Load**:
```bash
# Block 2 (around line 263)
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - proceeds directly to agent invocation

# Block 3 (around line 376)
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - PLAN_PATH used immediately, causing "unbound variable" error
```

❌ **No Error Logging Integration**:
- Does NOT source `error-handling.sh`
- Does NOT use `log_command_error()` at any error point

#### Vulnerability Analysis

**High Risk Scenario**: If `load_workflow_state()` fails or `STATE_FILE` is deleted between blocks:
1. Block 2 proceeds without validating `RESEARCH_DIR` was loaded
2. Block 3 proceeds without validating `PLAN_PATH` was loaded
3. Results in cryptic "PLAN_PATH: unbound variable" error
4. No diagnostic information about which variable failed to load
5. No centralized error log entry for debugging

---

### 3. /debug Command (6 BLOCKS)

**File**: `/home/benjamin/.config/.claude/commands/debug.md`
**Blocks**: 6 (Capture, Init, Classification, Research, Plan, Debug)
**State Persistence**: YES (Blocks 3-6 load state)

#### Gaps Identified

✅ **Block 2 - Has Basic Validation**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

❌ **Blocks 3-6 - NO State Validation After Load**:
- All 4 blocks call `load_workflow_state "$WORKFLOW_ID" false`
- NONE validate that `STATE_FILE` or other critical variables were restored
- Blocks 3-6 immediately use variables like `RESEARCH_DIR`, `PLAN_PATH`, `DEBUG_DIR`

❌ **No Error Logging Integration**

#### Risk Assessment

**Medium-High Risk**: 6 blocks mean more opportunities for state persistence failure. If state file is deleted or corrupted mid-workflow:
- Block 3 classification could fail silently
- Block 4 research could use undefined `RESEARCH_DIR`
- Block 5 planning could use undefined `PLAN_PATH`
- Block 6 debug could use undefined `DEBUG_DIR`

---

### 4. /research Command (2 BLOCKS)

**File**: `/home/benjamin/.config/.claude/commands/research.md`
**Blocks**: 2 (Setup, Verification)
**State Persistence**: YES (Block 2 loads state)

#### Gaps Identified

✅ **Block 1 - Has Basic Validation**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

❌ **Block 2 - NO State Validation After Load**:
```bash
load_workflow_state "$WORKFLOW_ID" false

# Immediately uses $RESEARCH_DIR without validation
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  exit 1
fi
```

❌ **No Error Logging Integration**

#### Risk Assessment

**Low-Medium Risk**: Only 2 blocks, simpler workflow. However, if state file deleted between blocks:
- Block 2 validation of `$RESEARCH_DIR` would fail with confusing error
- No way to know if `RESEARCH_DIR` was never loaded vs. directory not created

---

### 5. /revise Command (5 BLOCKS)

**File**: `/home/benjamin/.config/.claude/commands/revise.md`
**Blocks**: 5 (Capture, Validate, Init, Research, Plan)
**State Persistence**: YES (Blocks 3-5 load state)

#### Gaps Identified

✅ **Block 3 - Has Basic Validation**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

❌ **Blocks 4-5 - NO State Validation After Load**:
```bash
# Block 4 (Part 3, around line 290)
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - proceeds to transition

# Block 5 (Part 4, around line 428)
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - uses $EXISTING_PLAN_PATH, $RESEARCH_DIR
```

❌ **No Error Logging Integration**

#### Risk Assessment

**Medium Risk**: 5 blocks with complex revision logic. If state persistence fails:
- Block 4 could fail to load `RESEARCH_DIR`
- Block 5 could fail to load `EXISTING_PLAN_PATH` or `BACKUP_PATH`
- Backup safety checks depend on loaded state

---

### 6. /repair Command (3 BLOCKS)

**File**: `/home/benjamin/.config/.claude/commands/repair.md`
**Blocks**: 3 (Setup, Research Verification, Plan Verification)
**State Persistence**: YES (Blocks 2-3 load state)

#### Gaps Identified

✅ **Block 1 - Has Basic Validation**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

❌ **Blocks 2-3 - NO State Validation After Load**:
```bash
# Block 2 (around line 255)
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - uses $RESEARCH_DIR, $REPORT_COUNT

# Block 3 (around line 364)
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - uses $PLAN_PATH
```

❌ **No Error Logging Integration**

#### Risk Assessment

**Medium Risk**: Error repair workflow critically depends on state persistence. If state fails:
- Cannot track which error patterns were analyzed
- Cannot ensure plan addresses correct errors
- Ironic: error repair command cannot report its own errors

---

## Standards Compliance Analysis

### Error Handling Pattern (`.claude/docs/concepts/patterns/error-handling.md`)

**Current Standards Requirements**:

1. ✅ **Requirement**: Use JSONL-based centralized error logging
   **Status**: Standard defined, implementation exists
   **Compliance**: ❌ **0/6 commands** integrate error logging

2. ✅ **Requirement**: Environment-based error routing (production vs. test logs)
   **Status**: Standard defined, library supports it
   **Compliance**: ❌ **0/6 commands** use environment detection

3. ✅ **Requirement**: All commands must integrate `log_command_error()`
   **Status**: Standard explicitly requires "100% error capture rate"
   **Compliance**: ❌ **0/6 workflow commands** comply

4. ✅ **Requirement**: Parse subagent errors with `parse_subagent_error()`
   **Status**: Standard defined for hierarchical agents
   **Compliance**: ❌ **0/6 commands** parse agent errors

**Standard Quote**:
> "All errors are classified into standardized types for consistent handling... Every command must integrate error logging in three places: (1) Initialization, (2) Error Points, (3) Subagent Errors."

**Compliance Score**: **0% - Critical gap across all workflow commands**

---

### Output Formatting Standards (`.claude/docs/reference/standards/output-formatting.md`)

**Current Standards Requirements**:

1. ✅ **Requirement**: Comments describe WHAT, not WHY
   **Status**: Standard defined
   **Compliance**: ✅ All commands follow this

2. ✅ **Requirement**: Suppress library sourcing with `2>/dev/null`
   **Status**: Standard defined
   **Compliance**: ✅ All commands comply

3. ✅ **Requirement**: Single summary line per block
   **Status**: Standard defined
   **Compliance**: ⚠️ Mixed - /build has good patterns, others verbose

4. ✅ **Requirement**: Error messages to stderr with diagnostic context
   **Status**: Standard defined
   **Compliance**: ✅ Most commands comply (basic error messages)

**Compliance Score**: **75% - Generally good, minor improvements possible**

---

## Root Cause Analysis

### Why /plan Failed But /build Works

**The /plan Failure**:
```bash
# Block 3 in /plan
load_workflow_state "$WORKFLOW_ID" false
# NO VALIDATION - immediately uses $PLAN_PATH
if [ ! -f "$PLAN_PATH" ]; then  # ← PLAN_PATH unbound if load failed
  echo "ERROR: Planning phase failed to create plan file" >&2
  exit 1
fi
```

**The /build Success** (BECAUSE IT VALIDATES):
```bash
# Block 2 in /build
load_workflow_state "$WORKFLOW_ID" false

# COMPREHENSIVE VALIDATION
if [ -z "$STATE_FILE" ]; then
  # Diagnostic output to DEBUG_LOG
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  # Diagnostic output with PATH
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Only proceeds if state is valid
```

**Key Difference**: /build **validates the load operation succeeded** before using state variables. /plan **assumes load succeeded** and proceeds directly.

---

### Why Error Logging Is Missing Everywhere

**Analysis**: Error logging integration was added to `.claude/docs/concepts/patterns/error-handling.md` as a standard, but:

1. ❌ Commands were written **before** error logging standard was finalized
2. ❌ No systematic refactor pass after standard was established
3. ❌ No enforcement mechanism (tests/linting) for error logging compliance
4. ❌ `/setup` and `/optimize-claude` have it, workflow commands don't (inconsistent)

**Evidence**: Only 2 commands have `log_command_error()`:
- `/setup` - Utility command for project initialization
- `/optimize-claude` - Specialized meta-command

**Conclusion**: Error logging is a **new standard** that workflow commands haven't been updated to follow.

---

## Standards Assessment: Need Update?

### Question: Do Standards Need Changing?

**Answer**: ❌ **NO** - Standards are correct and comprehensive

**Rationale**:

1. **Error Handling Standard is Excellent**:
   - Comprehensive error taxonomy (state_error, validation_error, agent_error, etc.)
   - Environment-based routing (production/test isolation)
   - Query interface via `/errors` command
   - Full JSONL schema with workflow context

2. **Output Formatting Standard is Clear**:
   - WHAT vs WHY separation well-defined
   - Suppression patterns documented
   - Block consolidation guidelines provided

3. **State Persistence Pattern is Sound**:
   - Current pattern (`.claude/tmp/workflow_*.sh`) is correct
   - Documentation shows correct paths

### Question: Should Standards Add State Validation?

**Answer**: ⚠️ **MAYBE** - Consider adding explicit checkpoint requirements

**Recommendation**: Add to Output Formatting Standards or create new State Validation Standard:

```markdown
## State Validation Checkpoints

**Requirement**: All multi-block commands MUST validate state after `load_workflow_state()`.

**Pattern**:
```bash
load_workflow_state "$WORKFLOW_ID" false

# Validate state file path was restored
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: State file not found after load" >&2
  exit 1
fi

# Validate critical variables were restored
if [ -z "$CRITICAL_VAR" ]; then
  echo "ERROR: Critical variable not restored from state" >&2
  exit 1
fi
```

**Rationale**: Fail-fast validation prevents cryptic "unbound variable" errors.
```

**Location Options**:
1. Add to `.claude/docs/reference/standards/output-formatting.md` (Validation section)
2. Add to `.claude/docs/concepts/patterns/` as `state-validation.md`
3. Add to `.claude/docs/reference/library-api/` as state-persistence API requirements

---

## Fix Scope Recommendation

### Option 1: Targeted Fix (PLAN ONLY)

**Scope**: Fix only `/plan` command (current plan 001)
**Rationale**: Immediate fix for reported issue

**Pros**:
- ✅ Quick resolution of user-reported bug
- ✅ Low risk (single command)
- ✅ Can ship immediately

**Cons**:
- ❌ Leaves 5 other commands vulnerable
- ❌ Technical debt remains
- ❌ Users may hit same issue in /debug, /revise, etc.
- ❌ Inconsistent patterns across codebase

**Verdict**: ⚠️ **Not Recommended** - Band-aid solution

---

### Option 2: Systematic Fix (ALL 6 COMMANDS)

**Scope**: Apply fixes to all 6 workflow commands
**Rationale**: Systematic prevention of state persistence failures

**Implementation Plan**:

#### Phase 1: State Validation (CRITICAL)

Add checkpoint validation to all 6 commands after `load_workflow_state()`:

**Commands to Fix**:
1. `/plan` - Add validation in Blocks 2-3 (2 locations)
2. `/debug` - Add validation in Blocks 3-6 (4 locations)
3. `/research` - Add validation in Block 2 (1 location)
4. `/revise` - Add validation in Blocks 4-5 (2 locations)
5. `/repair` - Add validation in Blocks 2-3 (2 locations)
6. `/build` - ✅ **Already has validation** (use as template)

**Total Checkpoints**: 11 validation blocks to add

**Effort Estimate**: 2-3 hours (copy /build pattern to 5 commands)

**Pattern to Apply** (from /build):
```bash
load_workflow_state "$WORKFLOW_ID" false

# Validate STATE_FILE was restored
if [ -z "$STATE_FILE" ]; then
  echo "ERROR: State file path not set after load" >&2
  echo "WORKFLOW_ID: $WORKFLOW_ID" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: State file not found at expected path" >&2
  echo "Expected: ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh" >&2
  exit 1
fi

# Validate critical variables (command-specific)
if [ -z "$CRITICAL_VAR" ]; then
  echo "ERROR: Critical variable not restored from state" >&2
  exit 1
fi
```

---

#### Phase 2: Error Logging Integration (HIGH PRIORITY)

Add `log_command_error()` integration to all 6 commands:

**Per Command Additions**:

1. **Block 1 - Initialize Error Logging**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
ensure_error_log_exists

COMMAND_NAME="/command_name"
USER_ARGS="$FEATURE_DESCRIPTION"  # or equivalent
export COMMAND_NAME USER_ARGS
```

2. **All Blocks - Source error-handling.sh**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
```

3. **Error Points - Add log_command_error()**:
```bash
if [ validation_fails ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Validation failed: details" \
    "bash_block" \
    '{"context_key": "context_value"}'

  echo "ERROR: Validation failed" >&2
  exit 1
fi
```

**Error Types by Scenario**:
- State file failures: `state_error`
- Missing variables: `validation_error`
- Agent failures: `agent_error`
- File operations: `file_error`
- State transitions: `state_error`

**Effort Estimate**: 4-6 hours (6 commands × 5-10 error points each)

---

#### Phase 3: Diagnostic Output Enhancement (OPTIONAL)

Add DEBUG_LOG pattern from /build to other commands:

```bash
# Initialize DEBUG_LOG
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# Use in error messages
if [ validation_fails ]; then
  {
    echo "[$(date)] ERROR: Validation failed"
    echo "WHICH: function_name"
    echo "WHAT: Description of what failed"
    echo "WHERE: Block N, phase name"
    echo "CONTEXT: Additional details"
  } >> "$DEBUG_LOG"

  echo "ERROR: Validation failed (see $DEBUG_LOG)" >&2
  exit 1
fi
```

**Effort Estimate**: 3-4 hours (optional enhancement)

---

### Option 3: Phased Rollout

**Approach**: Fix in waves based on risk/usage

**Wave 1 (Week 1)**: High-usage commands
- `/plan` (current issue)
- `/build` (✅ already done - verify only)
- `/debug` (complex, 6 blocks)

**Wave 2 (Week 2)**: Supporting commands
- `/revise` (5 blocks, revision safety critical)
- `/research` (2 blocks, simpler)
- `/repair` (3 blocks, error analysis)

**Wave 3 (Week 3)**: Standards documentation
- Update `.claude/docs/reference/standards/` with validation requirements
- Add state validation pattern to documentation
- Create test suite for state persistence patterns

**Pros**:
- ✅ Gradual rollout reduces risk
- ✅ Learn from Wave 1 before applying to Wave 2
- ✅ Users get immediate fix for highest-risk command

**Cons**:
- ❌ Takes longer (3 weeks vs 1 week)
- ❌ Temporary inconsistency across commands
- ❌ More coordination overhead

---

## Recommended Fix Strategy

### 🎯 **RECOMMENDATION: Option 2 (Systematic Fix)**

**Rationale**:

1. **Root Cause is Systematic**: All 6 commands share the same vulnerability
2. **Pattern is Proven**: /build demonstrates working solution
3. **Effort is Reasonable**: 6-10 hours for comprehensive fix
4. **Standards Compliance**: Aligns with error handling pattern requirements
5. **Future-Proof**: Prevents users from hitting same issue in other commands

### Implementation Order

**Priority 1 (Must Have)**:
- ✅ Phase 1: State validation checkpoints in all 6 commands
- ✅ This fixes the "unbound variable" issue systematically

**Priority 2 (Should Have)**:
- ✅ Phase 2: Error logging integration in all 6 commands
- ✅ This enables `/errors` command usage for workflow debugging
- ✅ Aligns with error handling pattern standard

**Priority 3 (Nice to Have)**:
- ⚠️ Phase 3: Diagnostic output enhancement
- ⚠️ Optional - /build pattern is good, but not all commands need it

---

## Standards Update Recommendations

### 1. Add State Validation Pattern to Documentation

**Location**: `.claude/docs/reference/standards/output-formatting.md`

**New Section** (append to "Block Consolidation Patterns"):

```markdown
## State Validation Checkpoints

### Requirement

All multi-block commands using `load_workflow_state()` MUST validate state restoration before using state variables.

### Pattern

```bash
# After load_workflow_state
load_workflow_state "$WORKFLOW_ID" false

# Validate STATE_FILE was restored
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: State file not found after load" >&2
  exit 1
fi

# Validate critical variables
if [ -z "$CRITICAL_VAR1" ] || [ -z "$CRITICAL_VAR2" ]; then
  echo "ERROR: Critical variables not restored" >&2
  echo "  CRITICAL_VAR1: ${CRITICAL_VAR1:-MISSING}" >&2
  echo "  CRITICAL_VAR2: ${CRITICAL_VAR2:-MISSING}" >&2
  exit 1
fi
```

### Rationale

Fail-fast validation prevents cryptic "unbound variable" errors and provides diagnostic context.

### Reference Implementation

See `/build` command for comprehensive state validation pattern.
```

---

### 2. Update Error Handling Pattern Documentation

**Location**: `.claude/docs/concepts/patterns/error-handling.md`

**Update Section**: "Implementation" → "Logging Integration in Commands"

**Add Checklist**:

```markdown
### Integration Checklist

Every workflow command MUST include:

- [ ] Source error-handling.sh in Block 1
- [ ] Call ensure_error_log_exists() in Block 1
- [ ] Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS
- [ ] Source error-handling.sh in each subsequent block
- [ ] Add log_command_error() at every error exit point
- [ ] Parse agent errors with parse_subagent_error()
- [ ] Test error logging with /errors --command <cmd>

### Commands Compliant

✅ /setup
✅ /optimize-claude
⚠️ /plan (partial - no error logging)
⚠️ /build (partial - no error logging)
⚠️ /debug (partial - no error logging)
⚠️ /research (partial - no error logging)
⚠️ /revise (partial - no error logging)
⚠️ /repair (partial - no error logging)
```

---

### 3. Create State Persistence Test Suite

**Location**: `.claude/tests/test_state_persistence_compliance.sh`

**Purpose**: Automated verification that commands follow state validation pattern

**Test Cases**:
1. Verify all multi-block commands source state-persistence.sh
2. Verify all blocks call load_workflow_state
3. Verify validation exists after load_workflow_state
4. Verify STATE_FILE is checked after load
5. Verify critical variables are validated

**Effort**: 2-3 hours to implement

---

## Affected Files Summary

### Commands Requiring Changes (6 files)

1. `/home/benjamin/.config/.claude/commands/plan.md` (3 blocks → 2 checkpoints)
2. `/home/benjamin/.config/.claude/commands/debug.md` (6 blocks → 4 checkpoints)
3. `/home/benjamin/.config/.claude/commands/research.md` (2 blocks → 1 checkpoint)
4. `/home/benjamin/.config/.claude/commands/revise.md` (5 blocks → 2 checkpoints)
5. `/home/benjamin/.config/.claude/commands/repair.md` (3 blocks → 2 checkpoints)
6. `/home/benjamin/.config/.claude/commands/build.md` (✅ reference - verify only)

### Documentation Requiring Updates (3 files)

1. `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` (add state validation section)
2. `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (add compliance checklist)
3. `/home/benjamin/.config/.claude/docs/guides/patterns/` (new file: `state-validation-pattern.md` - OPTIONAL)

### Tests to Create (1 file - OPTIONAL)

1. `/home/benjamin/.config/.claude/tests/test_state_persistence_compliance.sh` (new test suite)

---

## Effort Breakdown

| Phase | Tasks | Estimated Hours | Priority |
|-------|-------|----------------|----------|
| **Phase 1: State Validation** | Add 11 checkpoints across 5 commands | 2-3 hours | CRITICAL |
| **Phase 2: Error Logging** | Add 6×10=60 error log calls | 4-6 hours | HIGH |
| **Phase 3: Diagnostic Output** | Add DEBUG_LOG to 5 commands | 3-4 hours | OPTIONAL |
| **Standards Updates** | Update 2-3 documentation files | 1-2 hours | MEDIUM |
| **Testing** | Create compliance test suite | 2-3 hours | OPTIONAL |
| **TOTAL (Critical Path)** | Phases 1+2 only | **6-9 hours** | - |
| **TOTAL (Complete)** | All phases | **12-18 hours** | - |

---

## Risk Assessment

### Risk: Regression in Other Commands

**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
1. Use /build as reference (proven pattern)
2. Test each command after modification
3. Keep changes minimal (defensive additions only)

### Risk: Standards Documentation Lag

**Likelihood**: Medium (already lagging)
**Impact**: Medium
**Mitigation**:
1. Update standards as part of fix (not after)
2. Include standards updates in same commit/PR

### Risk: User Confusion During Rollout

**Likelihood**: Low
**Impact**: Low
**Mitigation**:
1. Systematic fix (all at once) prevents inconsistency
2. Changes are defensive (more robust error messages)
3. No breaking changes to command interfaces

---

## Success Criteria

### Phase 1 Success (State Validation)

✅ All 6 commands validate STATE_FILE after load_workflow_state
✅ All 6 commands validate critical variables before use
✅ Error messages include diagnostic context (WORKFLOW_ID, expected path)
✅ Zero "unbound variable" errors in testing

### Phase 2 Success (Error Logging)

✅ All 6 commands source error-handling.sh
✅ All 6 commands call ensure_error_log_exists()
✅ All 6 commands use log_command_error() at error points
✅ `/errors --command <cmd>` returns structured error entries
✅ Error log contains workflow context (command, workflow_id, user_args)

### Phase 3 Success (Diagnostic Output)

✅ All 6 commands initialize DEBUG_LOG
✅ Error messages reference DEBUG_LOG for details
✅ DEBUG_LOG contains WHICH/WHAT/WHERE structured output

### Standards Update Success

✅ State validation pattern documented
✅ Error logging compliance checklist added
✅ Command compliance status tracked

---

## Conclusion

**Primary Finding**: The /plan command failure is **not an isolated bug** - it's a **systematic pattern** affecting all 6 multi-block workflow commands.

**Root Cause**: Commands were implemented before defensive state validation patterns were established. /build demonstrates the correct pattern (likely added later), but other 5 commands lack this.

**Recommended Action**: **Systematic fix** - Apply /build's state validation pattern to all 5 remaining commands, plus error logging integration for standards compliance.

**Standards Assessment**: ✅ **Standards are correct** - Implementation has fallen behind standards. No standards changes needed, only code updates.

**Estimated Effort**: 6-9 hours (critical path), 12-18 hours (complete with optional enhancements)

**Impact**: High - Prevents state persistence failures across entire workflow system, enables error log querying, aligns code with documented standards.

---

## Next Steps for Plan Revision

When revising the current plan (`001_claude_planoutputmd_which_i_want_you_to__plan.md`), consider:

1. **Expand Scope**: Change from "/plan only" to "systematic fix for 6 commands"
2. **Use /build as Template**: Copy validation blocks from /build to other commands
3. **Add Phase 2**: Include error logging integration (standards compliance)
4. **Update Standards Docs**: Include documentation updates in plan
5. **Keep Priority Structure**: Phase 1 (validation) remains critical, Phase 2 (logging) is high priority

**Plan Structure Suggestion**:
- Phase 1: State Validation (5 commands, using /build pattern)
- Phase 2: Error Logging Integration (6 commands)
- Phase 3: Standards Documentation Updates
- Phase 4: Testing (optional - compliance test suite)

---

**Report Complete**: REPORT_CREATED: /home/benjamin/.config/.claude/specs/849_claude_planoutputmd_which_i_want_you_to_research/reports/002_systematic_command_pattern_analysis_20251120.md

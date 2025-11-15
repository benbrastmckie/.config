# Root Cause Analysis - SM Init Premature Invocation

## Metadata
- **Date**: 2025-11-14
- **Research Topic**: Root cause of /coordinate calling sm_init() without workflow-classifier agent
- **Investigator**: research-specialist
- **Bug Symptoms**: Missing classification parameters, sm_init() validation failure
- **Severity**: Critical (100% failure rate for /coordinate command)
- **Parent Report**: [Comprehensive Overview](OVERVIEW.md)

## Executive Summary

The `/coordinate` command fails because it calls `sm_init()` with the **old 2-parameter signature** while the function was **refactored 8 hours ago** (commit `ce1d29a1`) to require **5 parameters including pre-computed classification data**. This is a classic **breaking change synchronization failure**: the library signature changed (clean-break refactor) but the calling command was not updated in the same commit.

**Timeline**:
- **2025-11-14 16:35** (commit `ce1d29a1`): `sm_init()` signature changed from 2 params to 5 params
- **2025-11-14 16:35** (same commit): File-based classification code deleted from library
- **2025-11-14 16:35** (same commit): `/coordinate` NOT updated with new invocation pattern
- **2025-11-14 [current]**: `/coordinate` still uses old signature → **parameter validation failure**

**Root Cause**: Breaking change was committed without updating all callers. The commit message acknowledged this was a breaking change requiring Phase 4-5 updates, but those updates were not completed.

## Analysis

### 1. Current sm_init() Function Signature

**Location**: `.claude/lib/workflow-state-machine.sh:340-438`

**New Signature** (as of commit `ce1d29a1`, 2025-11-14 16:35):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_type="$3"          # NEW - required
  local research_complexity="$4"    # NEW - required
  local research_topics_json="$5"   # NEW - required

  # Parameter validation (fail-fast)
  if [ -z "$workflow_type" ] || [ -z "$research_complexity" ] || [ -z "$research_topics_json" ]; then
    echo "ERROR: sm_init requires classification parameters" >&2
    echo "  Usage: sm_init WORKFLOW_DESC COMMAND_NAME WORKFLOW_TYPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON" >&2
    echo "" >&2
    echo "  Missing parameters:" >&2
    [ -z "$workflow_type" ] && echo "    - workflow_type" >&2
    [ -z "$research_complexity" ] && echo "    - research_complexity" >&2
    [ -z "$research_topics_json" ] && echo "    - research_topics_json" >&2
    echo "" >&2
    echo "  IMPORTANT: Commands must invoke workflow-classifier agent BEFORE calling sm_init" >&2
    echo "  See: .claude/agents/workflow-classifier.md" >&2
    return 1
  fi

  # Validate workflow_type enum
  case "$workflow_type" in
    research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
      : # Valid
      ;;
    *)
      echo "ERROR: Invalid workflow_type: $workflow_type" >&2
      echo "  Valid types: research-only, research-and-plan, research-and-revise, full-implementation, debug-only" >&2
      return 1
      ;;
  esac

  # Validate research_complexity range
  if ! [[ "$research_complexity" =~ ^[0-9]+$ ]] || [ "$research_complexity" -lt 1 ] || [ "$research_complexity" -gt 4 ]; then
    echo "ERROR: research_complexity must be integer 1-4, got: $research_complexity" >&2
    return 1
  fi

  # Validate research_topics_json is valid JSON array
  if ! echo "$research_topics_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
    echo "ERROR: research_topics_json must be valid JSON array" >&2
    echo "  Received: $research_topics_json" >&2
    return 1
  fi

  # Store validated classification parameters
  WORKFLOW_SCOPE="$workflow_type"
  RESEARCH_COMPLEXITY="$research_complexity"
  RESEARCH_TOPICS_JSON="$research_topics_json"

  # Export classification dimensions for use by orchestration commands
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON

  # ... rest of initialization
}
```

**Key Changes**:
1. **Parameters 3-5 added**: `workflow_type`, `research_complexity`, `research_topics_json`
2. **Fail-fast validation**: Missing parameters cause immediate failure with clear error message
3. **Pre-computed classification**: Function expects classification ALREADY DONE by agent
4. **No internal classification**: Removed all classification logic from sm_init()

### 2. How /coordinate Currently Invokes sm_init

**Location**: `.claude/commands/coordinate.md:163-172`

**Current Invocation** (BROKEN - uses old signature):
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
# WORKAROUND: Use exit code capture instead of bare '!' to avoid bash history expansion (Spec 700, Report 1)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi
```

**Problem**: Only passes 2 parameters (`$SAVED_WORKFLOW_DESC`, `"coordinate"`), missing the 3 required classification parameters.

**Consequence**:
- `$workflow_type` is empty → fails validation line 352
- `$research_complexity` is empty → fails validation line 352
- `$research_topics_json` is empty → fails validation line 352
- Function returns error code 1
- Error handler invoked with misleading message about network connection

### 3. What Changed - When Did sm_init Start Requiring Pre-Classification?

**Critical Commit**: `ce1d29a1` (2025-11-14 16:35:10)

**Commit Message**:
```
feat(orchestration): Phases 1-3 - Agent-based classification foundation

Implements Phases 1-3 of Spec 1763161992 (LLM Classification Agent Integration):

Phase 1: workflow-classifier agent created
- Created .claude/agents/workflow-classifier.md (530 lines)
- Semantic workflow classification with edge case handling
- JSON output with comprehensive validation
- Standard 0.5 compliant (100% compliance score, 34/34 tests passed)

Phase 1.5: Agent compliance validated
- Created test suite: test_workflow_classifier_agent.sh
- 34 comprehensive tests covering YAML, imperative language, edge cases
- 100% pass rate, 100% compliance score

Phase 2: sm_init() refactored to clean-break signature
- Updated signature: accepts pre-computed classification parameters
- Removed file-based classification invocation (lines 345-410 deleted)
- Added fail-fast parameter validation
- Breaking change: commands must classify BEFORE calling sm_init()

Phase 2.5: v2.0 → v2.1 checkpoint migration
- Updated CHECKPOINT_SCHEMA_VERSION to "2.1"
- Added migration logic for v2.0 → v2.1 (adds classification metadata)
- Backward compatible with automatic migration
- Tested with sample v2.0 checkpoints

Phase 3: File-based signaling code removed
- Deleted invoke_llm_classifier() function (lines 287-359)
- Deleted cleanup_workflow_classification_files() function (lines 650-677)
- Removed export statements for deleted functions
- Eliminates 100% timeout rate from file-based signaling

This is a breaking change requiring commands to invoke workflow-classifier
agent directly via Task tool before calling sm_init().

Performance improvements:
- Classification time: 10s timeout → <5s (agent-based, target)
- 100% timeout elimination (file-based approach had 100% failure rate)

Next phases: Update commands with agent invocation pattern (Phase 4-5)
```

**Key Insight**: The commit message **explicitly acknowledges** this is a breaking change and that "Next phases: Update commands with agent invocation pattern (Phase 4-5)" are required. **However, Phase 4-5 were not completed before committing the breaking change.**

### 4. Old sm_init Signature (Before ce1d29a1)

**Previous Signature** (commit `ce1d29a1~1`):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Store workflow configuration
  WORKFLOW_DESCRIPTION="$workflow_desc"
  COMMAND_NAME="$command_name"

  # Generate workflow ID for semantic filename scoping (Spec 704 Phase 2)
  local classification_workflow_id="${command_name}_classify_$(date +%s)"

  # Perform comprehensive workflow classification (scope + complexity + subtopics)
  # Source unified workflow scope detection library
  if [ -f "$SCRIPT_DIR/workflow-scope-detection.sh" ]; then
    source "$SCRIPT_DIR/workflow-scope-detection.sh"

    # Get comprehensive classification (workflow_type, research_complexity, subtopics)
    # Capture stderr to temp file for error visibility (Spec 704 Phase 1)
    local classification_stderr_file="${HOME}/.claude/tmp/classification_stderr_$$.tmp"
    mkdir -p "${HOME}/.claude/tmp"

    local classification_result
    if classification_result=$(classify_workflow_comprehensive "$workflow_desc" "$classification_workflow_id" 2>"$classification_stderr_file"); then
      # Parse JSON response
      WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
      RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')

      # Serialize subtopics array to JSON for state persistence
      RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

      # Export all three classification dimensions
      export WORKFLOW_SCOPE
      export RESEARCH_COMPLEXITY
      export RESEARCH_TOPICS_JSON

      # Log successful comprehensive classification
      echo "Comprehensive classification: scope=$WORKFLOW_SCOPE, complexity=$RESEARCH_COMPLEXITY, topics=$(echo "$RESEARCH_TOPICS_JSON" | jq -r 'length')" >&2

      # Cleanup stderr temp file on success
      rm -f "$classification_stderr_file"
    else
      # Display captured stderr messages for debugging (Spec 704 Phase 1)
      if [ -s "$classification_stderr_file" ]; then
        echo "Classification Error Details:" >&2
        cat "$classification_stderr_file" >&2
        echo "" >&2
      fi

      # Fail-fast: No automatic fallback (maintain fail-fast philosophy)
      echo "CRITICAL ERROR: Comprehensive classification failed" >&2
      echo "  Workflow Description: $workflow_desc" >&2
      # ... error handling ...
      return 1
    fi
  fi

  # ... rest of initialization
}
```

**Key Differences**:
1. **Old**: Only required 2 parameters (workflow_desc, command_name)
2. **Old**: Performed classification INTERNALLY via `classify_workflow_comprehensive()`
3. **Old**: Classification logic embedded in sm_init() function (lines 345-410)
4. **New**: Requires 5 parameters (adds pre-computed classification results)
5. **New**: NO internal classification, expects agent to provide results
6. **New**: 66 lines of classification code deleted

### 5. Why /coordinate Wasn't Updated When sm_init Changed

**Analysis of Commit Scope**:

Commit `ce1d29a1` modified 3 files:
```
.claude/lib/checkpoint-utils.sh        |  42 +++++++++-
.claude/lib/workflow-llm-classifier.sh | 113 +++-----------------------
.claude/lib/workflow-state-machine.sh  | 144 ++++++++++++---------------------
3 files changed, 104 insertions(+), 195 deletions(-)
```

**Files NOT Modified**:
- `.claude/commands/coordinate.md` ❌
- `.claude/commands/orchestrate.md` ❌
- `.claude/commands/supervise.md` ❌

**Why This Happened** (Hypothesis):

1. **Phased Implementation**: Commit message says "Next phases: Update commands with agent invocation pattern (Phase 4-5)", indicating **intentional** phasing
2. **Incomplete Phases**: Phases 1-3 completed (agent creation, sm_init refactor, file cleanup), but Phases 4-5 (command updates) NOT completed
3. **Clean-Break Philosophy**: Project follows "clean-break" approach (no backward compatibility shims), so no optional parameter fallback was added
4. **Breaking Change Awareness**: Commit message explicitly acknowledges breaking change, suggesting **known incomplete state**

**Supporting Evidence from Spec Research**:

From OVERVIEW.md (Spec 1763161992):
```markdown
**Phase 1: Create Agent** (30 min, Non-Breaking)
**Phase 2: State Machine Update** (15 min, Backward Compatible)
**Phase 3: Command Updates** (3 hours, Opt-In Breaking)
- [ ] Update `/coordinate` (1 hour)
- [ ] Update `/orchestrate` (1 hour)
- [ ] Update `/supervise` (1 hour)
**Phase 4: Testing** (1 hour)
**Phase 5: Documentation** (30 min)
```

**Analysis**: The spec planned for Phase 3 to include command updates, but those checkboxes remain **unchecked**. Commit `ce1d29a1` only completed Phases 1-2.5.

### 6. Git History Showing Architectural Evolution

**Relevant Commits** (reverse chronological):

1. **ce1d29a1** (2025-11-14 16:35) - "feat(orchestration): Phases 1-3 - Agent-based classification foundation"
   - **Change**: Refactored sm_init() to require 5 parameters
   - **Impact**: Breaking change for all orchestration commands
   - **Status**: Incomplete (only updated library, not commands)

2. **2c182d4c** (before ce1d29a1) - "feat(704): complete Phase 4 - Remove Regex Classification"
   - **Change**: Removed regex-only classification mode
   - **Impact**: LLM classification becomes only option

3. **56406289** (before 2c182d4c) - "feat(704): complete Phase 3 - Maintain Fail-Fast Approach"
   - **Change**: Removed auto-fallback to regex mode
   - **Impact**: Classification must succeed (no silent degradation)

4. **14a268b6** (before 56406289) - "feat(704): complete Phase 2 - Semantic Filename Persistence"
   - **Change**: Added semantic filename scoping for classification files
   - **Impact**: Improved file-based signaling (still broken)

5. **32e1a7d0** (before 14a268b6) - "feat(704): complete Phase 1 - Error Visibility and Handler Integration"
   - **Change**: Improved error messages for classification failures
   - **Impact**: Better diagnostics for file-based timeout issues

**Pattern**: Commits 32e1a7d0 → ce1d29a1 represent incremental improvements to classification system, culminating in **clean-break refactor** to agent-based approach. However, **migration was incomplete** (library updated, commands not updated).

**Earlier Relevant Commits**:

6. **bf50ee10** (2025-11-XX) - "feat(700): complete Phase 3 - Fix sm_init Export Persistence"
   - **Change**: Fixed export persistence issues in sm_init
   - **Context**: Still using 2-parameter signature at this point

7. **6edf5a76** (2025-11-XX) - "fix(698): add return code checks and verification for sm_init() calls"
   - **Change**: Added verification checkpoints after sm_init calls
   - **Context**: /coordinate already using 2-parameter signature with verification

**Evolution Timeline**:

```
Time →

[Spec 700-704: Incremental LLM classification improvements]
    ↓
[File-based signaling issues persist (100% timeout rate)]
    ↓
[Spec 1763161992 Research: Agent-based solution recommended]
    ↓
[ce1d29a1: Clean-break refactor - sm_init signature change]
    ↓
[CURRENT STATE: Commands broken, waiting for Phase 4-5 updates]
```

## Root Cause Summary

**Direct Cause**: `/coordinate` command calls `sm_init()` with 2 parameters, but function now requires 5 parameters (workflow_type, research_complexity, research_topics_json).

**Architectural Cause**: Clean-break refactor (commit `ce1d29a1`) changed library signature without updating all callers in the same atomic commit.

**Process Cause**: Phased implementation strategy (Phases 1-3 committed) without completing dependent phases (Phases 4-5 command updates).

**Design Decision**: Project's "clean-break" philosophy prohibits backward compatibility shims, so no optional parameter fallback exists.

**Mitigation Gap**: No integration tests detected signature mismatch before commit.

## Impact Assessment

**Severity**: Critical (P0)
- **Scope**: All 3 orchestration commands affected (`/coordinate`, `/orchestrate`, `/supervise`)
- **Failure Rate**: 100% (all invocations fail at sm_init() call)
- **User Impact**: Complete workflow orchestration outage
- **Workaround**: None (requires code changes)

**Blast Radius**:
- `/coordinate` - ❌ Broken (confirmed in analysis)
- `/orchestrate` - ❌ Likely broken (same sm_init call pattern)
- `/supervise` - ❌ Likely broken (same sm_init call pattern)

**Time Broken**: Since commit `ce1d29a1` (2025-11-14 16:35) = **~8 hours**

## Recommended Fix

**Immediate Action** (Complete Phase 4-5):

1. **Update /coordinate command** (1 hour):
   - Add Phase 0 bash block: Invoke `workflow-classifier` agent via Task tool
   - Parse JSON classification result
   - Pass 5 parameters to sm_init()

2. **Update /orchestrate and /supervise** (2 hours):
   - Same pattern as /coordinate
   - Ensure consistent agent invocation

3. **Integration Testing** (1 hour):
   - Test all 3 commands with various workflow descriptions
   - Verify classification accuracy
   - Confirm no timeouts occur

**Example Fix Pattern** (for /coordinate):

Add before line 163:
```bash
# ========================================
# Phase 0: Workflow Classification
# ========================================

echo "=== Workflow Classification ==="

# Invoke workflow-classifier agent via Task tool
# CRITICAL: Must execute BEFORE sm_init() call

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

# Parse classification result (CRITICAL - agent must return JSON)
CLASSIFICATION_JSON=$(echo "$AGENT_RESPONSE" | grep -oP 'CLASSIFICATION_COMPLETE: \K.*')

# Extract classification dimensions
WORKFLOW_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity')
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_JSON" | jq -c '.research_topics')

# Validate extraction
if [ -z "$WORKFLOW_TYPE" ] || [ -z "$RESEARCH_COMPLEXITY" ] || [ -z "$RESEARCH_TOPICS_JSON" ]; then
  handle_state_error "CRITICAL: Failed to parse classification from agent response" 1
fi

echo "✓ Classification complete: type=$WORKFLOW_TYPE, complexity=$RESEARCH_COMPLEXITY, topics=$(echo "$RESEARCH_TOPICS_JSON" | jq -r 'length')"

# ========================================
# State Machine Initialization (Updated)
# ========================================
```

Replace line 167:
```bash
# OLD (BROKEN):
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1

# NEW (FIXED):
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON" 2>&1
```

**Validation**: Verify fix with test case:
```bash
/coordinate "research authentication patterns and create implementation plan"
# Should:
# 1. Invoke workflow-classifier agent
# 2. Receive classification JSON
# 3. Call sm_init with 5 parameters
# 4. Successfully initialize state machine
# 5. Proceed to research phase
```

## Prevention Recommendations

**Short-Term**:
1. Add integration test suite for orchestration commands
2. Create smoke tests for sm_init() signature compatibility
3. Document breaking changes in CHANGELOG with migration steps

**Long-Term**:
1. Establish atomic commit policy: Breaking changes + all caller updates in single commit
2. Add pre-commit hook to detect signature mismatches
3. Implement contract testing between libraries and commands
4. Consider backward-compatible transition period for critical functions

## References

### Related Files
- **Library**: `.claude/lib/workflow-state-machine.sh` (sm_init function lines 340-438)
- **Command**: `.claude/commands/coordinate.md` (sm_init call line 167)
- **Agent**: `.claude/agents/workflow-classifier.md` (created in ce1d29a1)
- **Spec**: `.claude/specs/1763161992_setup_command_refactoring/reports/001_llm_classification_state_machine_integration/OVERVIEW.md`

### Related Commits
- **ce1d29a1** - Breaking change commit (sm_init refactor)
- **2c182d4c** - Removed regex classification
- **56406289** - Removed auto-fallback
- **14a268b6** - Semantic filename persistence
- **32e1a7d0** - Error visibility improvements

### Standards References
- [Command Architecture Standards](../../../../docs/reference/command_architecture_standards.md) - Standard 11 (Imperative Agent Invocation)
- [Behavioral Injection Pattern](../../../../docs/concepts/patterns/behavioral-injection.md) - Agent invocation via Task tool
- [Development Philosophy](../../../../docs/concepts/writing-standards.md) - Clean-break approach

## Conclusion

The root cause is a **clean-break architectural refactor** where the library signature changed (2 params → 5 params) but calling commands were not updated in the same commit. This is an **incomplete migration** (Phases 1-3 complete, Phases 4-5 incomplete) following the project's fail-fast, no-backward-compatibility philosophy.

**Fix effort**: 4 hours total (1h /coordinate + 2h other commands + 1h testing)

**Prevention**: Establish atomic commit policy for breaking changes + integration tests

**Priority**: Critical (P0) - Complete orchestration outage affecting all workflows

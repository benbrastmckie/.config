# Plan Naming Implementation Analysis

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Plan naming implementation in /coordinate workflow
- **Report Type**: codebase analysis
- **Complexity Level**: 2

## Executive Summary

The regression to generic "001_implementation.md" plan filenames was introduced in commit 4534cef0 (Nov 7, 2025) during the state machine migration of /coordinate. The hardcoded path replaced the descriptive naming pattern `001_${TOPIC_NAME}_plan.md` that was calculated in workflow-initialization.sh. The fix requires restoring the PLAN_PATH variable assignment in coordinate.md line 731 to use the value exported by workflow-initialization.sh.

## Findings

### 1. Current Implementation (Regression Source)

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Line**: 731
**Current Code**:
```bash
PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"
```

This hardcoded assignment was introduced in commit 4534cef0 during the Phase 5 state machine migration. The commit replaced 726 lines of phase-based code with 363 lines of state machine architecture.

### 2. Original Implementation (Pre-Regression)

**File**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`
**Line**: 259
**Correct Code**:
```bash
local plan_path="${topic_path}/plans/001_${topic_name}_plan.md"
```

This pattern was present in coordinate.md backups dated 2024-10-27 (line 969) and is still correctly implemented in workflow-initialization.sh. The library function exports PLAN_PATH (line 297) for use by coordinate.md.

### 3. Topic Name Generation

**File**: `/home/benjamin/.config/.claude/lib/topic-utils.sh`
**Function**: `sanitize_topic_name()` (lines 78-141)

**Algorithm**:
1. Extract path components from description (last 2-3 segments)
2. Remove full paths and trailing words like "directory"
3. Convert to lowercase
4. Remove filler prefixes ("research", "analyze", "investigate")
5. Filter stopwords (40+ common words) while preserving action verbs
6. Combine path components with cleaned description
7. Clean formatting (collapse multiple underscores)
8. Truncate to 50 chars preserving whole words

**Examples**:
- "Research the /home/user/nvim/docs directory" → "nvim_docs_directory"
- "fix the token refresh bug" → "fix_token_refresh_bug"
- "research authentication patterns to create implementation plan" → "authentication_patterns_create_implementation"

### 4. Git History Analysis

**Regression Commit**: 4534cef0 (Nov 7, 2025)
**Commit Message**: "feat(602): complete Phase 5 - /coordinate migration to state machine"

**Before Regression** (coordinate.md.backup-20251027_144901, line 969):
```bash
PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"
```

**After Regression** (commit 4534cef0):
```bash
PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"
```

**Scope of Change**: The commit reduced coordinate.md from 1,084 lines to 721 lines (33.5% reduction) by replacing phase-based architecture with state machine. During this refactor, the PLAN_PATH calculation was inadvertently hardcoded instead of using the exported value from workflow-initialization.sh.

### 5. Impact Analysis

**Files Affected** (8 examples found):
- `.claude/specs/482_*/plans/001_implementation.md`
- `.claude/specs/577_*/plans/001_implementation.md`
- `.claude/specs/586_*/plans/001_implementation.md`
- `.claude/specs/594_*/plans/001_implementation.md`
- `.claude/specs/595_*/plans/001_implementation.md`
- `.claude/specs/636_*/plans/001_implementation.md`
- `.claude/specs/637_*/plans/001_implementation.md`
- `.claude/specs/639_*/plans/001_implementation.md`

All created after Nov 7, 2025 (regression date).

**Workflow-initialization.sh Status**: Still correctly implements descriptive naming at line 259 and exports PLAN_PATH at line 297. The library code is correct; coordinate.md simply ignores the exported value.

### 6. Agent Invocation Pattern

**Current** (coordinate.md, lines 672-696):
- Uses Task tool to invoke plan-architect agent behavioral file
- Agent creates plan using workflow context
- coordinate.md then hardcodes verification path (line 731)

**Root Cause**: Mismatch between agent's actual output path and coordinate.md's hardcoded expectation. The plan-architect agent may be creating plans with descriptive names (following workflow-initialization.sh), but coordinate.md looks for generic "001_implementation.md".

## Recommendations

### 1. Restore Variable Assignment (CRITICAL - Immediate Fix)

**File**: `.claude/commands/coordinate.md`
**Line**: 731
**Change**:
```bash
# FROM (hardcoded):
PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"

# TO (use exported variable):
# PLAN_PATH is already exported by workflow-initialization.sh at line 297
# No reassignment needed - use the existing value
```

Or if reassignment is required for clarity:
```bash
# Use the PLAN_PATH calculated by workflow-initialization.sh
if [ -z "$PLAN_PATH" ]; then
  # Fallback calculation if not exported (should never happen)
  PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"
fi
```

**Rationale**: workflow-initialization.sh already calculates and exports PLAN_PATH with descriptive naming. coordinate.md should trust this value instead of overriding it.

### 2. Verify State Persistence Pattern

**File**: `.claude/commands/coordinate.md`
**Lines**: 108-116

The coordinate.md saves WORKFLOW_ID and WORKFLOW_DESCRIPTION to state file but does not save PLAN_PATH from workflow-initialization.sh. Verify that PLAN_PATH is available in the bash block at line 731 (after library sourcing).

**Diagnostic Check**:
```bash
# After line 164 (workflow initialization complete)
echo "DEBUG: PLAN_PATH from library: $PLAN_PATH"
```

If PLAN_PATH is empty, the state persistence may need to include it.

### 3. Add Verification Test

**File**: `.claude/tests/test_orchestration_commands.sh`

Add test case to verify plan naming pattern:
```bash
test_coordinate_plan_naming() {
  # Create coordinate workflow
  WORKFLOW_DESC="fix authentication bug"

  # Run coordinate through planning phase
  # ... (mock execution)

  # Verify plan path uses descriptive name
  EXPECTED_PATTERN="*/plans/001_fix_authentication_bug_plan.md"
  ACTUAL_PATH=$(find .claude/specs -name "001_*.md" -path "*/plans/*" | head -1)

  assert_not_equal "$ACTUAL_PATH" "*/plans/001_implementation.md" "Plan should not use generic name"
  assert_match "$ACTUAL_PATH" "*fix_authentication_bug*" "Plan should include workflow description"
}
```

### 4. Documentation Update

**File**: `.claude/docs/guides/coordinate-command-guide.md`

Add section documenting the plan naming pattern:
```markdown
## Plan Naming Convention

Plans created by /coordinate follow the pattern:
- `{NNN}_{topic_name}_plan.md` where {topic_name} is derived from workflow description
- Topic names are sanitized: lowercase, snake_case, stopwords removed, max 50 chars
- Examples:
  - "fix auth bug" → "001_fix_auth_bug_plan.md"
  - "implement user dashboard" → "002_implement_user_dashboard_plan.md"

**NEVER** use generic names like "001_implementation.md" - these provide no context.
```

### 5. Prevent Future Regressions

**Strategy**: Add assertion to workflow-initialization.sh that PLAN_PATH contains TOPIC_NAME:
```bash
# After line 259 in workflow-initialization.sh
if [[ ! "$plan_path" =~ $topic_name ]]; then
  echo "CRITICAL ERROR: PLAN_PATH does not contain topic name" >&2
  echo "  Expected substring: $topic_name" >&2
  echo "  Actual path: $plan_path" >&2
  return 1
fi
```

This prevents accidental hardcoding in future refactors.

## References

### Primary Files
- `/home/benjamin/.config/.claude/commands/coordinate.md:731` - Regression location (hardcoded path)
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:259` - Correct implementation
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:297` - PLAN_PATH export
- `/home/benjamin/.config/.claude/lib/topic-utils.sh:78-141` - sanitize_topic_name() function

### Backup Files (Pre-Regression Evidence)
- `/home/benjamin/.config/.claude/commands/coordinate.md.backup-20251027_144901:969` - Original pattern
- `/home/benjamin/.config/.claude/commands/coordinate.md.backup-phase1:969` - Phase 1 pattern
- `/home/benjamin/.config/.claude/commands/supervise.md.backup-20251027_150123:875` - Similar pattern

### Git History
- Commit 4534cef0 (Nov 7, 2025) - "feat(602): complete Phase 5 - /coordinate migration to state machine"
- Commit diff: Changed from `001_${TOPIC_NAME}_plan.md` to `001_implementation.md`

### Affected Specs (Created After Regression)
- 8 specs with generic "001_implementation.md" filenames (all dated after Nov 7, 2025)
- Pattern: `.claude/specs/{NNN}_*/plans/001_implementation.md`

### Related Documentation
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation pattern
- `.claude/specs/coordinate_output.md` - Example of regression impact

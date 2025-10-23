# Fix Missing Task Invocations in /orchestrate - Implementation Plan

## Metadata
- **Date**: 2025-10-22
- **Feature**: Add missing Task invocation code to /orchestrate planning and research phases
- **Scope**: Fix incomplete implementation from plan 071-001
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Root Cause**: Plan 071 added retry loops and templates but never added the actual Task invocation code
- **Plan Number**: 072-001

## Overview

Plan 071-001 successfully added retry logic and template definitions for research and planning phases, but failed to add the actual Task tool invocation code. This leaves the orchestrate command with comments saying "invoke the agent" but no code to do so.

**Current State**:
- Templates defined at lines 1030-1127 ✓
- Retry loop structure at lines 1723-1776 ✓
- **Missing**: Actual Task invocation code inside retry loop ✗

**Result**: When orchestrate runs, Claude sees instruction to invoke agent but has no explicit code, so it falls back to calling `SlashCommand("/plan")` instead of `Task(plan-architect)`.

**Root Issue**:
```bash
# Line 1746 in orchestrate.md (CURRENT - INCOMPLETE)
# Invoke plan-architect agent with selected template
# YOU MUST use Task tool with appropriate PLAN-ARCHITECT template
#
# ← NO CODE HERE - this is where Task invocation should be!
```

**Target State**: Add complete Task invocation code that:
1. Uses case statement to select template based on attempt number
2. Constructs agent prompt with workflow context and research reports
3. Invokes Task tool with plan-architect behavioral injection
4. Returns to retry loop for verification

## Success Criteria

- [ ] Planning phase retry loop has complete Task invocation code (case statement with 3 templates)
- [ ] Research phase retry loop has complete Task invocation code (case statement with 3 templates)
- [ ] Context preparation added before retry loops (extract workflow description, research reports)
- [ ] Template definitions (lines 1030-1127) removed (now inline in case statements)
- [ ] Validation script created to detect missing invocations
- [ ] Test: /orchestrate no longer calls SlashCommand("/plan")
- [ ] Test: /orchestrate uses Task(plan-architect) with behavioral injection
- [ ] Test: Validation script passes all checks

## Technical Design

### Architecture Pattern: Inline Template Invocation

Instead of defining templates as documentation and expecting Claude to interpret them, we inline the actual Task invocation code directly in the retry loop using a case statement.

**Before (incomplete)**:
```bash
for attempt in 1 2 3; do
  select_template  # Chooses which template
  # TODO: invoke agent  ← No actual invocation!
  check_if_file_created
done
```

**After (complete)**:
```bash
for attempt in 1 2 3; do
  case "$template" in
    standard)
      Task { ... }  # Actual invocation with standard template
      ;;
    ultra_explicit)
      Task { ... }  # Actual invocation with ultra-explicit template
      ;;
    step_by_step)
      Task { ... }  # Actual invocation with step-by-step template
      ;;
  esac
  check_if_file_created
done
```

### Context Injection Variables

The Task invocations need these variables prepared before the retry loop:

```bash
# Before retry loop starts
WORKFLOW_DESCRIPTION="${USER_REQUEST}"
PLAN_PATH="${calculated_path}"
RESEARCH_REPORTS_LIST="$(build_report_list)"
CLAUDE_PROJECT_DIR="$(pwd)"
```

## Implementation Phases

### Phase 1: Add Context Preparation for Planning Phase [COMPLETED]
**Objective**: Extract and prepare all context variables needed for Task invocation prompts

**Complexity**: Low

**Tasks**:
- [x] Read orchestrate.md lines 1700-1723 (before retry loop)
- [x] Add context extraction section:
  - [x] Extract workflow description from USER_REQUEST variable
  - [x] Build research reports list from SUCCESSFUL_REPORTS array
  - [x] Get standards file path (CLAUDE.md)
  - [x] Display preparation checkpoint (echo context prepared)
- [x] Verify variables are set before retry loop starts

**Testing**:
```bash
# Verify context preparation section exists
grep -A 15 "Prepare planning context" .claude/commands/orchestrate.md | grep -q "WORKFLOW_DESCRIPTION="
grep -A 15 "Prepare planning context" .claude/commands/orchestrate.md | grep -q "RESEARCH_REPORTS_LIST="
```

**Git Commit**: `feat(072): Phase 1 - add context preparation for planning phase Task invocations`

---

### Phase 2: Add Task Invocation Code in Planning Retry Loop [COMPLETED]
**Objective**: Replace comment placeholder with actual case statement invoking Task tool

**Complexity**: Medium

**Tasks**:
- [x] Read orchestrate.md lines 1723-1776 (planning retry loop)
- [x] Replace lines 1746-1747 (comment placeholder) with case statement:
  - [x] Case 'standard': Task invocation with STANDARD template
  - [x] Case 'ultra_explicit': Task invocation with ULTRA-EXPLICIT template
  - [x] Case 'step_by_step': Task invocation with STEP-BY-STEP template
- [x] Each Task invocation includes:
  - [x] subagent_type: "general-purpose"
  - [x] description: appropriate for attempt number
  - [x] timeout: 600000 (10 minutes)
  - [x] prompt: behavioral injection referencing plan-architect.md
  - [x] Context injection: PLAN_PATH, WORKFLOW_DESCRIPTION, RESEARCH_REPORTS_LIST
- [x] Verify case statement syntax is correct (esac at end)

**Task Prompt Structure** (all 3 templates):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create plan - [standard/ultra-explicit/step-by-step] enforcement"
  timeout: 600000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **PLAN PATH (MANDATORY)**: ${PLAN_PATH}

    [Template-specific enforcement instructions]

    Create plan for: ${WORKFLOW_DESCRIPTION}

    ${RESEARCH_REPORTS_LIST}

    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Testing**:
```bash
# Verify case statement exists
grep -A 50 "case \"\$template\" in" .claude/commands/orchestrate.md | grep -q "standard)"
grep -A 50 "case \"\$template\" in" .claude/commands/orchestrate.md | grep -q "ultra_explicit)"
grep -A 50 "case \"\$template\" in" .claude/commands/orchestrate.md | grep -q "step_by_step)"

# Verify all 3 templates invoke Task tool
[ $(grep -A 100 "case \"\$template\" in" .claude/commands/orchestrate.md | grep -c "Task {") -eq 3 ]
```

**Git Commit**: `feat(072): Phase 2 - add Task invocation code in planning retry loop`

---

### Phase 3: Fix Research Phase (Same Pattern) [COMPLETED]
**Objective**: Apply same fix to research phase retry loop

**Complexity**: Medium

**Tasks**:
- [x] Search orchestrate.md for research agent retry loop
- [x] Identify line with comment placeholder (similar to planning phase)
- [x] Add context preparation before research retry loop:
  - [x] Extract research topics from TOPICS array
  - [x] Build report paths from REPORT_PATHS map
  - [x] Get standards file path
- [x] Replace comment placeholder with case statement:
  - [x] Case 'standard': Task invocation with research standard template
  - [x] Case 'ultra_explicit': Task invocation with research ultra-explicit template
  - [x] Case 'step_by_step': Task invocation with research step-by-step template
- [x] Each invocation includes REPORT_PATH, TOPIC, and behavioral injection

**Testing**:
```bash
# Verify research retry loop has invocations
grep -B 10 -A 50 "invoke_research_agent_with_retry" .claude/commands/orchestrate.md | grep -q "Task {"

# Verify 3 templates for research
RESEARCH_TASK_COUNT=$(grep -A 200 "Research.*retry" .claude/commands/orchestrate.md | grep -c "Task {")
[ "$RESEARCH_TASK_COUNT" -ge 3 ]
```

**Git Commit**: `feat(072): Phase 3 - fix research phase with same Task invocation pattern`

---

### Phase 4: Cleanup and Validation
**Objective**: Remove duplicate templates and add validation script

**Complexity**: Low

**Tasks**:
- [ ] Remove template definition sections (lines 1030-1127):
  - [ ] PLAN-ARCHITECT INVOCATION - STANDARD TEMPLATE
  - [ ] PLAN-ARCHITECT INVOCATION - ULTRA-EXPLICIT TEMPLATE
  - [ ] PLAN-ARCHITECT INVOCATION - STEP-BY-STEP TEMPLATE
  - [ ] Reason: Now inline in case statements, duplicates are confusing
- [ ] Remove research template definitions (similar section for research agents)
- [ ] Create validation script: `.claude/lib/validate-orchestrate-implementation.sh`
  - [ ] Test 1: No SlashCommand invocations (grep fails on "SlashCommand(")
  - [ ] Test 2: At least 2 Task invocations present (research + planning)
  - [ ] Test 3: All "YOU MUST" comments followed by actual Task code
  - [ ] Test 4: Case statements have all 3 branches (standard, ultra-explicit, step-by-step)
- [ ] Make validation script executable (chmod +x)
- [ ] Run validation script to verify all fixes

**Testing**:
```bash
# Run validation script
.claude/lib/validate-orchestrate-implementation.sh

# Expected output:
# ✓ No SlashCommand invocations found
# ✓ Found 6 Task invocations (3 research + 3 planning)
# ✓ Task invocation code follows instruction comments
# ✓ All case statements complete (3 branches each)
# === All Validation Tests Passed ===
```

**Git Commit**: `refactor(072): Phase 4 - remove duplicate templates, add validation script`

---

## Testing Strategy

### Unit Tests

**Test 1: Context Preparation**
```bash
# Verify all context variables are set before retry loop
grep -B 5 "for attempt in" .claude/commands/orchestrate.md | grep -q "WORKFLOW_DESCRIPTION="
grep -B 5 "for attempt in" .claude/commands/orchestrate.md | grep -q "RESEARCH_REPORTS_LIST="
```

**Test 2: Task Invocation Syntax**
```bash
# Extract one Task invocation and verify YAML structure
TASK_BLOCK=$(grep -A 30 "Task {" .claude/commands/orchestrate.md | head -35)
echo "$TASK_BLOCK" | grep -q "subagent_type:"
echo "$TASK_BLOCK" | grep -q "description:"
echo "$TASK_BLOCK" | grep -q "timeout:"
echo "$TASK_BLOCK" | grep -q "prompt:"
```

**Test 3: No SlashCommand Usage**
```bash
# Ensure no actual SlashCommand calls (only documentation)
! grep -q 'SlashCommand("/plan")' .claude/commands/orchestrate.md
! grep -q 'SlashCommand("/report")' .claude/commands/orchestrate.md
```

### Integration Tests

**Test 1: End-to-End /orchestrate Execution**
```bash
# Run /orchestrate with simple workflow
/orchestrate "Research testing best practices and create implementation plan"

# Expected behavior:
# 1. Research phase uses Task(research-specialist) not SlashCommand("/report")
# 2. Planning phase uses Task(plan-architect) not SlashCommand("/plan")
# 3. Agents create files using Write tool
# 4. No "permission requested" popups for /plan or /report
# 5. Workflow completes successfully
```

**Test 2: Retry Mechanism**
```bash
# Simulate agent failure (agent doesn't create file)
# This tests retry with escalating templates

# Expected behavior:
# 1. Attempt 1 fails (file not created)
# 2. Retry message: "Retrying with ultra-explicit enforcement"
# 3. Attempt 2 with ultra-explicit template
# 4. If succeeds: workflow continues
# 5. If fails: Attempt 3 with step-by-step template
# 6. After 3 failures: Clear error message, no fallback file creation
```

### Validation

Run validation script after implementation:
```bash
.claude/lib/validate-orchestrate-implementation.sh
```

All tests must pass:
- ✓ No SlashCommand invocations
- ✓ Task invocations present
- ✓ Case statements complete
- ✓ Context preparation exists

## Documentation Requirements

### Update Files

1. **orchestrate.md**:
   - Lines 1700-1723: Add context preparation section
   - Lines 1723-1776: Replace comment with case statement + Task invocations
   - Lines 1030-1127: Remove duplicate template definitions
   - Research phase: Add similar fixes

2. **CHANGELOG** (if exists):
   - Document fix for incomplete plan 071-001 implementation
   - Note: /orchestrate now correctly uses Task tool, not SlashCommand

3. **specs/071_orchestrate_enforcement_fix/**:
   - Add note to plan 071-001: "Completed but missing invocation code - see plan 072-001"
   - Link to this plan for follow-up fix

## Dependencies

### Internal Dependencies
- `.claude/commands/orchestrate.md` - File being fixed
- `.claude/agents/plan-architect.md` - Referenced in Task prompts
- `.claude/agents/research-specialist.md` - Referenced in Task prompts (if exists)
- Plan 071-001 - Incomplete implementation being fixed

### External Dependencies
None

### Breaking Changes
None - this is a bug fix that completes the intended behavior from plan 071-001.

## Migration Guide

No migration required. This fix makes /orchestrate work as intended:
- Before: Claude interprets comments and calls SlashCommand("/plan")
- After: Explicit Task invocation code executes with behavioral injection

Users will see:
- No more permission popups for /plan or /report during /orchestrate
- Faster execution (no command prompt expansion overhead)
- Correct behavioral injection (agents receive artifact paths)

## Notes

### Design Rationale

**Why Inline Invocations Instead of Template References?**

The original approach (plan 071) defined templates as documentation and expected Claude to interpret them. This failed because:

1. **AI Ambiguity**: Comments like "YOU MUST invoke" are interpreted, not executed
2. **No Executable Code**: Without explicit `Task { ... }` calls, Claude defaults to SlashCommand
3. **Behavioral Injection Broken**: SlashCommand prevents context injection (paths, topics)

**The Fix**: Inline the actual Task invocation code in case statements
- Each branch explicitly calls Task tool
- Prompts are constructed with variables
- No interpretation needed - direct execution

**Why Remove Template Definitions?**

Having templates both as documentation (lines 1030-1127) AND inline in case statements creates confusion:
1. **Which is Source of Truth?** Two versions can drift apart
2. **Maintenance Burden**: Updates needed in two places
3. **Size**: Adds ~100 lines with no functional benefit

**Solution**: Keep only inline versions (in case statements), remove documentation duplicates.

### Breaking Changes

**None** - This is a bug fix completing the intended behavior from plan 071-001.

**User-Visible Changes**:
1. **No Permission Popups**: /orchestrate will stop requesting permission for /plan and /report
2. **Correct Artifact Paths**: Agents receive pre-calculated paths (behavioral injection works)
3. **Faster Execution**: No command prompt expansion (saves ~3000 tokens per phase)

### Performance Impact

**Before (Broken)**:
- /orchestrate → SlashCommand("/plan") → /plan expands (3000 tokens) → plan-architect agent
- Total: ~3500 tokens for planning phase

**After (Fixed)**:
- /orchestrate → Task(plan-architect) with inline prompt → plan-architect agent
- Total: ~500 tokens for planning phase

**Savings**: ~3000 tokens per workflow (85% reduction in planning phase context usage)

### Validation Strategy

The validation script (Phase 4) ensures this issue never happens again:
1. **Detects SlashCommand** usage (fails build if found)
2. **Requires Task invocations** after instruction comments
3. **Verifies case completeness** (all 3 templates present)
4. **Can be added to test suite** for CI/CD integration

---

**Plan Status**: Ready for implementation
**Estimated Total Time**: 2-3 hours
**Risk Level**: Low (straightforward code completion, no architectural changes)
**Success Probability**: Very High (clear problem, clear solution)

## Revision History

### 2025-10-22 - Initial Version
**Created**: Root cause analysis completed
**Scope**: Fix incomplete implementation from plan 071-001 by adding missing Task invocation code
**Phases**: 4 phases covering context preparation, invocation code, research fix, and validation

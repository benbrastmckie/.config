# Debug Artifacts: Coordinate Workflow Classifier State Persistence

## Overview

This directory contains comprehensive debug artifacts for fixing the coordinate command's workflow classifier state persistence failures (Spec 752).

**Root Cause**: The workflow-classifier agent has contradictory configuration (`allowed-tools: None` but instructed to execute bash commands), preventing it from saving `CLASSIFICATION_JSON` to workflow state.

**Solution**: Three-phase fix approach:
- **P0 (Critical)**: Remove impossible state persistence from agent, move to coordinate command
- **P1 (High)**: Add enhanced validation to detect missing state variables early
- **P2 (Medium)**: Comprehensive testing and verification

---

## Debug Artifacts

### 001_fix_workflow_classifier.md (P0 - Critical)

**Purpose**: Remove impossible state persistence instructions from workflow-classifier agent

**Summary**:
- Delete lines 530-587 from workflow-classifier.md (bash block instructions)
- Agent will focus solely on classification (single responsibility)
- State persistence moved to coordinate.md (Fix 002)

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

**Estimated Time**: 15 minutes

**Dependencies**: None

**Blocks**: Fix 002 (coordinate.md requires this fix first)

**Key Changes**:
```bash
# Remove this section (lines 530-587):
## CRITICAL - MANDATORY STATE PERSISTENCE
USE the Bash tool:
```bash
# ... state persistence code ...
```
```

**Verification**:
```bash
grep -q "USE the Bash tool" .claude/agents/workflow-classifier.md && \
  echo "✗ Fix NOT applied" || echo "✓ Fix applied"
```

---

### 002_fix_coordinate_command.md (P0 - Critical)

**Purpose**: Add state extraction bash block to coordinate command after Task tool invocation

**Summary**:
- Insert new bash block after workflow-classifier Task invocation (line ~213)
- Extract classification JSON from Task output
- Validate JSON with jq
- Save to state using append_workflow_state()
- Verify save successful

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/coordinate.md`

**Estimated Time**: 30 minutes

**Dependencies**: Fix 001 must be applied first

**Key Changes**:
```markdown
## Phase 0.1: Workflow Classification

Task {
  # Invoke workflow-classifier agent
}

**NEW SECTION**: Extract and save classification

USE the Bash tool:

```bash
# Extract JSON from Task output
CLASSIFICATION_JSON='<EXTRACT_FROM_TASK_OUTPUT>'

# Validate and save to state
echo "$CLASSIFICATION_JSON" | jq empty
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"

# Verify save
load_workflow_state "$WORKFLOW_ID"
echo "✓ Classification saved successfully"
```
```

**Verification**:
```bash
grep -q "EXTRACT_FROM_TASK_OUTPUT" .claude/commands/coordinate.md && \
  echo "✓ Fix applied" || echo "✗ Fix NOT applied"
```

---

### 003_fix_state_persistence.md (P1 - High)

**Purpose**: Add optional variable validation to load_workflow_state() for fail-fast diagnostics

**Summary**:
- Enhance load_workflow_state() to accept optional required variable names
- After sourcing state file, verify specified variables exist
- Generate detailed error showing missing variables and state file contents
- Return exit code 3 for validation failures (distinct from other errors)

**Files Modified**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`
- `/home/benjamin/.config/.claude/commands/coordinate.md` (caller updates)

**Estimated Time**: 20 minutes

**Dependencies**: None (independent enhancement, most useful after Fix 001/002)

**Key Changes**:
```bash
# Enhanced signature
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"
  shift 2 2>/dev/null || true
  local required_vars=("$@")  # NEW: Variable validation

  # ... existing logic ...

  # NEW: Validate required variables
  if [ ${#required_vars[@]} -gt 0 ]; then
    for var_name in "${required_vars[@]}"; do
      if [ -z "${!var_name:-}" ]; then
        missing_vars+=("$var_name")
      fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
      echo "❌ CRITICAL ERROR: Required variables missing"
      echo "Missing: ${missing_vars[*]}"
      cat "$state_file" >&2  # Show actual contents
      return 3  # Validation error
    fi
  fi
}
```

**Usage in coordinate.md**:
```bash
# Old usage (no validation)
load_workflow_state "$WORKFLOW_ID"

# New usage (with validation)
load_workflow_state "$WORKFLOW_ID" false "CLASSIFICATION_JSON"
```

**Verification**:
```bash
grep -q "shift 2 2>/dev/null || true" .claude/lib/state-persistence.sh && \
  echo "✓ Fix applied" || echo "✗ Fix NOT applied"
```

---

### 004_test_plan.md

**Purpose**: Comprehensive test suite for all fixes

**Summary**:
- Unit tests (load_workflow_state validation, JSON escaping)
- Integration tests (research, implementation, debug workflows)
- Edge case tests (quoted keywords, negations, multi-phase)
- Regression tests (performance, file locations)

**Test Levels**:
1. **Unit Tests** (5 min):
   - State validation: success, failure, multiple vars, backward compat
   - JSON escaping: simple, quoted, nested, complex
   - Performance: append, load, validation overhead

2. **Integration Tests** (30 min - manual):
   - Research workflow: `/coordinate "research authentication patterns"`
   - Implementation: `/coordinate "implement user registration..."`
   - Debug: `/coordinate "debug login validation error"`

3. **Edge Cases** (15 min - manual):
   - Quoted keywords: `"research the 'implement' command"`
   - Negations: `"don't revise, create new plan"`
   - Multi-phase: `"research patterns, design plan, build system"`
   - Intentional failure: Verify Fix 003 validation works

4. **Regression Tests** (10 min):
   - State file locations (correct: .claude/tmp/, not .claude/data/workflows/)
   - Performance benchmarks (append <5ms, load <50ms)

**Total Time**: 60 minutes (full suite)

**Quick Test Suite**: 5 minutes (unit tests only)

---

## Implementation Order

### Phase 1: Critical Fixes (45 minutes)

**Step 1**: Apply Fix 001 (15 min)
```bash
cd /home/benjamin/.config
cp .claude/agents/workflow-classifier.md .claude/agents/workflow-classifier.md.backup
sed -i '530,587d' .claude/agents/workflow-classifier.md
# Verify: grep -q "USE the Bash tool" .claude/agents/workflow-classifier.md
```

**Step 2**: Apply Fix 002 (30 min)
```bash
cp .claude/commands/coordinate.md .claude/commands/coordinate.md.backup
# Manually edit coordinate.md to insert extraction bash block after line 213
# See 002_fix_coordinate_command.md for exact code to insert
```

**Step 3**: Test basic workflow (5 min)
```bash
/coordinate "research authentication patterns"
# Expected: ✓ Classification saved to state successfully
```

---

### Phase 2: Enhanced Diagnostics (35 minutes)

**Step 4**: Apply Fix 003 (20 min)
```bash
cp .claude/lib/state-persistence.sh .claude/lib/state-persistence.sh.backup
# Manually edit state-persistence.sh to enhance load_workflow_state()
# See 003_fix_state_persistence.md for exact implementation
```

**Step 5**: Update coordinate.md callers (10 min)
```bash
# Update load_workflow_state calls to include validation
# Example: load_workflow_state "$WORKFLOW_ID" false "CLASSIFICATION_JSON"
```

**Step 6**: Test validation (5 min)
```bash
# Run unit tests from 004_test_plan.md
bash test_state_validation.sh
bash test_json_escaping.sh
```

---

### Phase 3: Comprehensive Testing (60 minutes)

**Step 7**: Execute full test suite
```bash
# See 004_test_plan.md for complete test execution instructions
cd /home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/test_data
bash test_state_validation.sh
bash test_json_escaping.sh
bash test_performance.sh

# Manual integration tests
/coordinate "research authentication patterns"
/coordinate "implement user registration feature"
/coordinate "debug login validation error"

# Edge case tests
/coordinate "research the 'implement' command"
/coordinate "don't revise, create new plan"
```

---

## Exit Codes Reference

After applying fixes, `load_workflow_state()` returns:

- **0**: Success - State file loaded (validation passed if specified)
- **1**: Expected - State file doesn't exist (first block, initialized)
- **2**: Error - State file missing (unexpected, critical configuration error)
- **3**: Error - Validation failed (state file exists but required variables missing) **[NEW]**

---

## Success Criteria

### Fix 001 (workflow-classifier.md)
- [ ] Lines 530-587 deleted
- [ ] No "USE the Bash tool" references remain
- [ ] Agent frontmatter unchanged (allowed-tools: None)
- [ ] Backup created

### Fix 002 (coordinate.md)
- [ ] New bash block inserted after Task invocation (line ~213)
- [ ] Block extracts CLASSIFICATION_JSON from Task output
- [ ] Block validates JSON with jq
- [ ] Block saves to state with append_workflow_state()
- [ ] Block verifies save successful
- [ ] Error message updated in existing validation
- [ ] Backup created

### Fix 003 (state-persistence.sh)
- [ ] load_workflow_state() signature updated with varargs
- [ ] Variable validation logic implemented
- [ ] Missing variables trigger exit code 3
- [ ] Error message lists missing variables
- [ ] Error message dumps state file contents
- [ ] Troubleshooting steps included
- [ ] Backward compatible (validation optional)
- [ ] Backup created

### Testing
- [ ] All unit tests pass (validation, JSON escaping, performance)
- [ ] Integration tests pass (research, implementation, debug workflows)
- [ ] Edge cases handled correctly (quoted keywords, negations, multi-phase)
- [ ] Regression tests pass (file locations, performance)

---

## Rollback Plan

If any fix causes issues:

```bash
cd /home/benjamin/.config

# Rollback Fix 001
cp .claude/agents/workflow-classifier.md.backup .claude/agents/workflow-classifier.md

# Rollback Fix 002
cp .claude/commands/coordinate.md.backup .claude/commands/coordinate.md

# Rollback Fix 003
cp .claude/lib/state-persistence.sh.backup .claude/lib/state-persistence.sh

# Verify rollback
diff .claude/agents/workflow-classifier.md.backup .claude/agents/workflow-classifier.md
diff .claude/commands/coordinate.md.backup .claude/commands/coordinate.md
diff .claude/lib/state-persistence.sh.backup .claude/lib/state-persistence.sh
```

---

## Architecture Comparison

### Before Fixes (Broken)

```
┌─────────────────────────────┐
│ coordinate.md               │
│ - Invoke Task tool          │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ workflow-classifier agent   │
│ - allowed-tools: None       │ ← Cannot use Bash!
│ - Instructions: USE Bash    │ ← Contradictory!
│ - Returns classification    │
│ - SKIPS bash block          │ ← STATE NOT SAVED
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ coordinate.md (next block)  │
│ - load_workflow_state()     │
│ - Expects CLASSIFICATION_JSON│ ← ERROR: Missing!
│ - FAILS: unbound variable   │
└─────────────────────────────┘
```

### After Fixes (Correct)

```
┌─────────────────────────────┐
│ coordinate.md               │
│ - Invoke Task tool          │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ workflow-classifier agent   │
│ - allowed-tools: None       │ ← Simplified scope
│ - Returns classification    │ ← Single responsibility
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ coordinate.md (NEW block)   │ ← Fix 002
│ - Extract JSON from Task    │
│ - Validate with jq          │
│ - append_workflow_state()   │ ← STATE SAVED
│ - Verify save successful    │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ coordinate.md (next block)  │
│ - load_workflow_state()     │ ← Fix 003
│   with validation           │
│ - CLASSIFICATION_JSON OK    │ ← SUCCESS!
│ - Continue workflow         │
└─────────────────────────────┘
```

---

## File Locations Reference

### Debug Artifacts (This Directory)
```
/home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/debug/
├── README.md (this file)
├── 001_fix_workflow_classifier.md
├── 002_fix_coordinate_command.md
├── 003_fix_state_persistence.md
└── 004_test_plan.md
```

### Files to Modify
```
/home/benjamin/.config/.claude/agents/workflow-classifier.md (Fix 001)
/home/benjamin/.config/.claude/commands/coordinate.md (Fix 002)
/home/benjamin/.config/.claude/lib/state-persistence.sh (Fix 003)
```

### Test Directory
```
/home/benjamin/.config/.claude/specs/752_debug_coordinate_workflow_classifier/test_data/
├── test_state_validation.sh
├── test_json_escaping.sh
├── test_performance.sh
└── test_research_workflow.sh
```

### State Files (Runtime)
```
/home/benjamin/.config/.claude/tmp/workflow_coordinate_*.sh (Correct location)
/home/benjamin/.config/.claude/tmp/coordinate_state_id.txt (State ID)
/home/benjamin/.config/.claude/tmp/coordinate_workflow_desc_*.txt (Workflow description)
```

---

## Additional Resources

- **Debug Strategy Plan**: `../plans/001_debug_strategy.md`
- **Root Cause Analysis**: `../reports/001_root_cause_analysis.md`
- **Error Logs**: `/home/benjamin/.config/.claude/coordinate_output.md`
- **State Persistence Library**: `/home/benjamin/.config/.claude/lib/state-persistence.sh`
- **Workflow State Machine**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

---

## Questions and Troubleshooting

### Q: Why can't the agent save state directly?

**A**: The Task tool creates execution isolation (subprocess boundaries). When Claude invokes an agent via Task tool, the agent runs in a separate process that cannot modify the parent process's environment or access parent variables like `STATE_FILE`. File-based persistence must occur in the parent (coordinate.md) context.

### Q: What if JSON extraction from Task output fails?

**A**: See Fix 002 alternative implementation (inline classification using keyword matching). This is a fallback if Claude cannot parse Task output and substitute JSON values.

### Q: Can I apply Fix 003 without Fix 001/002?

**A**: Yes, Fix 003 is independent and provides better diagnostics regardless. However, it's most useful AFTER Fix 001/002 are applied, as it will catch any state persistence failures with clear error messages.

### Q: What if performance degrades after Fix 003?

**A**: Validation adds ~2-5ms overhead per load_workflow_state call. If this is problematic, validation is optional (backward compatible). You can selectively validate only critical variables.

### Q: How do I know if fixes are working?

**A**: Run `/coordinate "research test"` and look for:
```
✓ Classification saved to state successfully
  Workflow type: research-only
  Research complexity: 1
  Topics: 1
```

If you see this, all fixes are working correctly.

---

**Debug Artifacts Status**: COMPLETE
**Created**: 2025-11-17
**Spec**: 752_debug_coordinate_workflow_classifier
**Total Artifacts**: 4 fixes + 1 test plan + this README
**Estimated Implementation Time**: 2 hours (all fixes + testing)
**Priority**: P0 (Critical - Blocking all coordinate workflows)

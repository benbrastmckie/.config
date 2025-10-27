# Standardize OVERVIEW.md Synthesis Across Commands Implementation Plan

## Metadata
- **Date**: 2025-10-27
- **Feature**: Standardize OVERVIEW.md synthesis behavior across /research, /supervise, and /coordinate
- **Scope**: Modify three orchestration commands to use uniform overview synthesis logic
- **Estimated Phases**: 5
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Overview

Currently, the `/research`, `/supervise`, and `/coordinate` commands use inconsistent patterns for creating OVERVIEW.md reports after research agents complete. This inconsistency creates confusion about when overview synthesis should occur.

**Problem Statement**:
- `/research` always creates OVERVIEW.md (correct for research-only workflow)
- `/supervise` and `/coordinate` create OVERVIEW.md even when planning follows (incorrect - plan synthesizes reports)
- No unified decision logic for "should we synthesize an overview?"

**Solution**:
Implement uniform behavior where OVERVIEW.md synthesis only occurs when the workflow concludes with research reports (no subsequent planning phase). When a plan is to be created, the individual reports are synthesized by the plan-architect agent, making OVERVIEW.md redundant.

## Success Criteria
- [ ] All three commands use identical decision logic for overview synthesis
- [ ] OVERVIEW.md created only for research-only workflows
- [ ] OVERVIEW.md NOT created for research-and-plan workflows
- [ ] research-synthesizer agent invocation follows uniform pattern
- [ ] All verification checkpoints consistent across commands
- [ ] Documentation updated to reflect uniform behavior
- [ ] No regression in existing functionality

## Research Findings

### Current Implementation Analysis

**Command**: `/research`
- **Pattern**: Always invokes research-synthesizer after subtopic reports verified
- **Path**: `${RESEARCH_SUBDIR}/OVERVIEW.md` (ALL CAPS, not numbered)
- **Condition**: `if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then`
- **Agent**: research-synthesizer with OVERVIEW.md path
- **Correct Behavior**: ✓ Yes (research-only workflow)

**Command**: `/supervise`
- **Pattern**: Creates overview in Phase 1 (Research), before Phase 2 (Planning)
- **Path**: `${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md` (numbered, not ALL CAPS)
- **Condition**: `if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then`
- **Issue**: Creates OVERVIEW.md even for research-and-plan workflows
- **Correct Behavior**: ✗ No (should check WORKFLOW_SCOPE)

**Command**: `/coordinate`
- **Pattern**: Same as /supervise (creates overview before planning)
- **Path**: `${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md` (numbered, not ALL CAPS)
- **Condition**: `if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then`
- **Issue**: Same as /supervise - creates OVERVIEW.md even for research-and-plan workflows
- **Correct Behavior**: ✗ No (should check WORKFLOW_SCOPE)

### Key Differences Identified

1. **Path Format**:
   - `/research`: `OVERVIEW.md` (ALL CAPS, standard)
   - `/supervise` + `/coordinate`: `${TOPIC_NUM}_overview.md` (numbered, non-standard)

2. **Decision Logic**:
   - `/research`: Correct (research-only workflow)
   - `/supervise` + `/coordinate`: Incorrect (creates overview even when planning follows)

3. **Workflow Scope Awareness**:
   - `/research`: Implicit (command is research-only)
   - `/supervise` + `/coordinate`: Explicit (WORKFLOW_SCOPE variable exists but not used for overview decision)

4. **Agent Invocation**:
   - All three use research-synthesizer agent (consistent ✓)
   - All three provide similar context (consistent ✓)
   - Path format differs (inconsistent ✗)

## Technical Design

### Unified Decision Logic

Create a reusable function that determines if overview synthesis should occur:

```bash
# Function: should_synthesize_overview
# Returns: 0 (true) if overview should be created, 1 (false) otherwise
should_synthesize_overview() {
  local workflow_scope="$1"
  local report_count="$2"

  # Require at least 2 reports for synthesis
  if [ "$report_count" -lt 2 ]; then
    return 1  # false
  fi

  # Only synthesize if workflow concludes with research (no planning follows)
  case "$workflow_scope" in
    research-only)
      return 0  # true - workflow ends with research
      ;;
    research-and-plan|full-implementation|debug-only)
      return 1  # false - plan will synthesize reports
      ;;
    *)
      # Unknown workflow scope - default to no synthesis (conservative)
      return 1  # false
      ;;
  esac
}
```

### Path Format Standardization

All commands should use the `/research` path format:
- **Standard**: `OVERVIEW.md` (ALL CAPS, not numbered)
- **Location**: Same directory as subtopic reports
- **Rationale**: Distinguishes synthesis report from numbered subtopic reports

**Path Calculation**:
- `/research`: `${RESEARCH_SUBDIR}/OVERVIEW.md` ✓ Already correct
- `/supervise`: Change from `${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md` to `${RESEARCH_SUBDIR}/OVERVIEW.md`
- `/coordinate`: Change from `${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md` to `${RESEARCH_SUBDIR}/OVERVIEW.md`

**Note**: `/supervise` and `/coordinate` need to define `RESEARCH_SUBDIR` variable (currently only `/research` has this).

### Integration Points

1. **Phase 1 (Research) in /supervise and /coordinate**:
   - After research report verification
   - Before Phase 2 (Planning) check
   - Add conditional overview synthesis based on WORKFLOW_SCOPE

2. **research-synthesizer Agent**:
   - No changes needed to agent behavioral file
   - All three commands use same agent invocation pattern
   - Only path format needs standardization

3. **Verification Checkpoints**:
   - OVERVIEW.md verification should be conditional (only if synthesized)
   - Update checkpoint JSON to include overview_path only when created

## Implementation Phases

### Phase 1: Create Reusable Overview Decision Library [COMPLETED]
**Objective**: Extract overview synthesis decision logic into shared library function
**Complexity**: Low

Tasks:
- [x] Create `.claude/lib/overview-synthesis.sh` library file
- [x] Implement `should_synthesize_overview()` function with workflow scope logic
- [x] Implement `calculate_overview_path()` function for standardized path format
- [x] Add function documentation and usage examples
- [x] Add unit tests for decision logic (test all workflow scopes)

Testing:
```bash
# Test decision logic for all workflow scopes
source .claude/lib/overview-synthesis.sh

# Test research-only (should return 0 = true)
should_synthesize_overview "research-only" 3
echo "Expected: 0, Got: $?"

# Test research-and-plan (should return 1 = false)
should_synthesize_overview "research-and-plan" 3
echo "Expected: 1, Got: $?"

# Test with insufficient reports (should return 1 = false)
should_synthesize_overview "research-only" 1
echo "Expected: 1, Got: $?"
```

**Deliverable**: `.claude/lib/overview-synthesis.sh` with tested decision logic

---

### Phase 2: Update /research Command [COMPLETED]
**Objective**: Refactor /research to use shared library (reference implementation)
**Complexity**: Low

Tasks:
- [x] Source `.claude/lib/overview-synthesis.sh` in /research command
- [x] Replace inline overview decision with `should_synthesize_overview()` call
- [x] Update overview path calculation to use `calculate_overview_path()`
- [x] Verify OVERVIEW.md path format unchanged (already correct)
- [x] Update comments to reference shared library

Code Changes:
```bash
# Before (inline logic):
if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then
  echo "Creating research overview to synthesize findings..."
  OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"
  # ... invoke agent
fi

# After (using library):
source "$SCRIPT_DIR/../lib/overview-synthesis.sh"

# /research is implicitly research-only workflow
WORKFLOW_SCOPE="research-only"

if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
  echo "Creating research overview to synthesize findings..."
  OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")
  # ... invoke agent
fi
```

Testing:
```bash
# Test /research with 2+ reports (should create OVERVIEW.md)
/research "authentication patterns and security best practices"

# Verify OVERVIEW.md created at correct path
ls -la ~/.config/.claude/specs/*/reports/*/OVERVIEW.md

# Verify OVERVIEW.md has correct structure (Research Structure section, cross-references)
```

**Deliverable**: Updated /research command using shared library

---

### Phase 3: Update /supervise Command [COMPLETED]
**Objective**: Fix /supervise to skip overview synthesis for research-and-plan workflows
**Complexity**: Medium

Tasks:
- [x] Source `.claude/lib/overview-synthesis.sh` in /supervise command
- [x] Define `RESEARCH_SUBDIR` variable (currently missing)
- [x] Replace inline overview decision with `should_synthesize_overview()` call
- [x] Update overview path from `${TOPIC_NUM}_overview.md` to `OVERVIEW.md` (ALL CAPS)
- [x] Update conditional verification logic (only verify if overview created)
- [x] Update checkpoint JSON to conditionally include overview_path
- [x] Update Phase 2 planning context to conditionally include overview

Code Changes:
```bash
# Step 1: Define RESEARCH_SUBDIR (add after Phase 0 path calculation)
# Calculate research subdirectory path
RESEARCH_NUM=1
if [ -d "${TOPIC_PATH}/reports" ]; then
  EXISTING_COUNT=$(find "${TOPIC_PATH}/reports" -mindepth 1 -maxdepth 1 -type d | wc -l)
  RESEARCH_NUM=$((EXISTING_COUNT + 1))
fi
RESEARCH_SUBDIR="${TOPIC_PATH}/reports/$(printf "%03d" "$RESEARCH_NUM")_${TOPIC_NAME}_research"

# Step 2: Update overview synthesis decision (Phase 1)
# Before:
if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then
  echo "Creating research overview to synthesize findings..."
  OVERVIEW_PATH="${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md"
  # ... invoke agent
fi

# After:
source "$SCRIPT_DIR/../lib/overview-synthesis.sh"

if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
  echo "Creating research overview to synthesize findings..."
  OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")
  # ... invoke agent
else
  echo "⏭️  Skipping overview synthesis"
  echo "  Reason: Reports will be synthesized by plan-architect in Phase 2"
  OVERVIEW_PATH=""  # Explicitly set to empty
fi

# Step 3: Update Phase 2 planning context
# Only include overview if created
if [ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ]; then
  RESEARCH_REPORTS_LIST+="- $OVERVIEW_PATH (synthesis)\n"
fi
```

Testing:
```bash
# Test research-only workflow (should create OVERVIEW.md)
/supervise "research authentication patterns"

# Verify OVERVIEW.md created
ls -la ~/.config/.claude/specs/*/reports/*/OVERVIEW.md

# Test research-and-plan workflow (should NOT create OVERVIEW.md)
/supervise "research authentication patterns to create a refactor plan"

# Verify NO OVERVIEW.md created
ls -la ~/.config/.claude/specs/*/reports/*/OVERVIEW.md | grep -v "No such file"

# Verify plan was created successfully without overview
ls -la ~/.config/.claude/specs/*/plans/*.md
```

**Deliverable**: Updated /supervise command with correct overview synthesis behavior

---

### Phase 4: Update /coordinate Command
**Objective**: Apply same fixes as /supervise to /coordinate command
**Complexity**: Medium

Tasks:
- [ ] Source `.claude/lib/overview-synthesis.sh` in /coordinate command
- [ ] Define `RESEARCH_SUBDIR` variable (currently missing)
- [ ] Replace inline overview decision with `should_synthesize_overview()` call
- [ ] Update overview path from `${TOPIC_NUM}_overview.md` to `OVERVIEW.md` (ALL CAPS)
- [ ] Update conditional verification logic (only verify if overview created)
- [ ] Update checkpoint JSON to conditionally include overview_path
- [ ] Update Phase 2 planning context to conditionally include overview
- [ ] Update context pruning logic (only prune overview if it exists)

Code Changes:
```bash
# Same changes as Phase 3, but applied to /coordinate command
# (Copy the pattern from /supervise with identical logic)

# Additional: Update context pruning (Phase 1 -> Phase 2 transition)
# Before:
# (No conditional check - assumes overview exists)

# After:
if [ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ]; then
  store_phase_metadata "phase_1_overview" "$OVERVIEW_PATH"
fi
```

Testing:
```bash
# Test all workflow scopes
/coordinate "research authentication patterns"  # research-only
/coordinate "research auth to create plan"      # research-and-plan
/coordinate "implement OAuth2 authentication"   # full-implementation

# Verify overview created only for research-only
find ~/.config/.claude/specs -name "OVERVIEW.md" -mmin -5

# Verify all workflows complete successfully
echo "All workflows should complete without errors"
```

**Deliverable**: Updated /coordinate command with correct overview synthesis behavior

---

### Phase 5: Documentation and Validation
**Objective**: Update documentation and validate uniform behavior across all commands
**Complexity**: Low

Tasks:
- [ ] Update `.claude/commands/research.md` - document overview synthesis behavior
- [ ] Update `.claude/commands/supervise.md` - document conditional overview synthesis
- [ ] Update `.claude/commands/coordinate.md` - document conditional overview synthesis
- [ ] Update `.claude/commands/README.md` - update orchestration command comparison table
- [ ] Add library documentation to `.claude/docs/reference/library-api.md`
- [ ] Update CLAUDE.md section on orchestration commands (if needed)
- [ ] Create integration test script to validate uniform behavior
- [ ] Run full test suite on all three commands

Integration Test Script:
```bash
#!/bin/bash
# File: .claude/tests/test_overview_synthesis_uniformity.sh

echo "Testing overview synthesis uniformity across commands"

# Test 1: /research always creates OVERVIEW.md
/research "test authentication patterns"
OVERVIEW_CREATED=$(find ~/.config/.claude/specs -name "OVERVIEW.md" -mmin -2 | wc -l)
[ "$OVERVIEW_CREATED" -eq 1 ] && echo "✓ /research creates OVERVIEW.md" || echo "✗ FAILED"

# Test 2: /supervise research-and-plan does NOT create OVERVIEW.md
/supervise "research auth to create plan"
OVERVIEW_CREATED=$(find ~/.config/.claude/specs -name "OVERVIEW.md" -mmin -2 | wc -l)
[ "$OVERVIEW_CREATED" -eq 0 ] && echo "✓ /supervise skips OVERVIEW.md for research-and-plan" || echo "✗ FAILED"

# Test 3: /coordinate research-and-plan does NOT create OVERVIEW.md
/coordinate "research auth to create plan"
OVERVIEW_CREATED=$(find ~/.config/.claude/specs -name "OVERVIEW.md" -mmin -2 | wc -l)
[ "$OVERVIEW_CREATED" -eq 0 ] && echo "✓ /coordinate skips OVERVIEW.md for research-and-plan" || echo "✗ FAILED"

# Test 4: All commands use same path format (OVERVIEW.md ALL CAPS)
LOWERCASE_OVERVIEW=$(find ~/.config/.claude/specs -name "*overview.md" | wc -l)
[ "$LOWERCASE_OVERVIEW" -eq 0 ] && echo "✓ All commands use OVERVIEW.md format" || echo "✗ FAILED: Found lowercase overview.md"

echo "Integration tests complete"
```

Testing:
```bash
# Run integration test
bash .claude/tests/test_overview_synthesis_uniformity.sh

# Run full test suite
.claude/tests/run_all_tests.sh

# Verify all tests pass
echo "Expected: All tests passing"
```

**Deliverable**: Updated documentation and passing integration tests

---

## Testing Strategy

### Unit Tests
- Decision logic function (`should_synthesize_overview`) for all workflow scopes
- Path calculation function (`calculate_overview_path`) for correct format
- Edge cases: 0 reports, 1 report, 2+ reports

### Integration Tests
- Each command tested with all applicable workflow scopes
- Verify OVERVIEW.md presence/absence matches expectations
- Verify path format consistency (ALL CAPS)
- Verify checkpoint JSON correctness
- Verify planning context includes/excludes overview appropriately

### Regression Tests
- Existing functionality unchanged (research agents, planning, implementation)
- No impact on other phases (implementation, testing, debug, documentation)
- Context pruning still works correctly

## Dependencies

- `.claude/lib/workflow-detection.sh` - WORKFLOW_SCOPE variable
- `.claude/agents/research-synthesizer.md` - Agent behavioral file (no changes)
- Checkpoint utilities - Conditional overview_path in JSON

## Risk Assessment

**Low Risk**:
- New library function is pure decision logic (no side effects)
- Changes are additive (new conditional, not replacing existing logic)
- Path format change only affects new runs (no migration needed)

**Mitigation**:
- Thorough testing of all workflow scopes
- Phase-by-phase implementation with validation
- Reference implementation (/research) unchanged in behavior

## Documentation Requirements

### Update Files
- `.claude/commands/research.md` - Document library usage
- `.claude/commands/supervise.md` - Document conditional synthesis
- `.claude/commands/coordinate.md` - Document conditional synthesis
- `.claude/commands/README.md` - Update command comparison
- `.claude/docs/reference/library-api.md` - Add new library functions

### New Files
- `.claude/lib/overview-synthesis.sh` - Library file with documentation
- `.claude/tests/test_overview_synthesis_uniformity.sh` - Integration test

## Success Metrics

- [ ] Zero test failures after all phases complete
- [ ] All three commands use identical decision logic
- [ ] OVERVIEW.md path format consistent (ALL CAPS)
- [ ] Documentation clearly explains when overview is created
- [ ] No regressions in existing workflows

## Notes

### Design Decisions

1. **Why conditional synthesis?**
   - Avoids redundant work (plan-architect synthesizes reports)
   - Clearer artifact boundaries (overview OR plan, not both)
   - Reduces cognitive load (one synthesis point per workflow)

2. **Why standardize path format to OVERVIEW.md?**
   - Consistency with `/research` command (established pattern)
   - Visual distinction from numbered subtopic reports
   - Industry convention (ALL CAPS for special files like README, LICENSE)

3. **Why create library instead of duplicating logic?**
   - Single source of truth for decision logic
   - Easier to test in isolation
   - Easier to update behavior in future
   - Reduces maintenance burden

### Implementation Order Rationale

Phase order chosen to minimize risk:
1. Create library (no impact on commands)
2. Update /research first (reference implementation, already correct)
3. Update /supervise (most similar to /coordinate)
4. Update /coordinate (learn from /supervise updates)
5. Documentation last (after behavior validated)

### Future Enhancements

Potential improvements beyond this plan:
- Unified orchestration base class/library (abstract common patterns)
- Standardized checkpoint schema validator
- Automated workflow scope detection improvements

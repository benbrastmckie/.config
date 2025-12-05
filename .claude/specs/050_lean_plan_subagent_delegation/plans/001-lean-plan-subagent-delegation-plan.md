# /lean-plan Command Subagent Delegation Refactoring Implementation Plan

## Metadata
- **Date**: 2025-12-04
- **Feature**: Refactor /lean-plan to use Hard Barrier Pattern with proper subagent delegation
- **Scope**: Refactor /lean-plan command Blocks 1d-2 to pre-calculate report paths before subagent invocation, add hard barrier validation blocks, and update Task prompts to pass absolute file paths instead of directories. This aligns /lean-plan with /create-plan reference pattern and enables proper error isolation, context reduction (93% token reduction from 74.2k to ~5k), and potential parallel execution.
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Complexity Score**: 42.0
- **Structure Level**: 0
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Subagent Delegation Pattern Research](../reports/001-lean-plan-subagent-research.md)

## Overview

The /lean-plan command currently performs most research work inline in the main conversation (74.2k token Explore operations, many direct Read calls) instead of delegating to the lean-research-specialist subagent with proper hard barriers. This violates the Hard Barrier Pattern and prevents error isolation, context reduction, and parallel execution opportunities.

This plan refactors /lean-plan to match the /create-plan reference implementation by:
1. Adding Block 1d-calc to pre-calculate REPORT_PATH before research agent invocation
2. Updating Block 1e to Block 1e-exec with explicit REPORT_PATH contract in Task prompt
3. Adding Block 1f for hard barrier validation of research report artifacts
4. Updating Block 2 to pre-calculate PLAN_PATH before planning agent invocation
5. Testing end-to-end workflow with error isolation verification

**Key Benefits**:
- **Context reduction**: 93% reduction (74.2k → ~5k tokens in main conversation)
- **Error isolation**: Subagent failures don't pollute main context
- **Artifact validation**: Pre-calculated paths enable reliable validation
- **Infrastructure alignment**: Agents already expect REPORT_PATH contract

## Research Summary

Research findings from comprehensive analysis of /lean-plan vs /create-plan patterns:

**Current State Issues**:
- Block 1e passes `Output Directory` (directory) instead of `REPORT_PATH` (absolute file path)
- lean-research-specialist.md expects REPORT_PATH in STEP 1 but receives directory
- Main conversation performs 74.2k token operations directly instead of delegating
- No hard barrier validation block after research agent invocation
- Block 2 inlines plan path calculation (acceptable but not ideal Hard Barrier Pattern)

**Reference Pattern** (/create-plan):
- Block 1b: Pre-calculate topic name file path before agent invocation
- Block 1b-exec: Task invocation with explicit TOPIC_NAME_FILE contract
- Block 1c: Hard barrier validation using validate_agent_artifact
- Pattern ensures agent knows exact output path and orchestrator validates after

**Agent Behavioral Files**:
- lean-research-specialist.md STEP 1 already expects REPORT_PATH (lines 24-62)
- lean-plan-architect.md STEP 2 already expects PLAN_PATH (lines 108-205)
- No agent behavioral file changes needed - only command file updates

**Impact Analysis**:
- Breaking changes: None (agents already expect correct contract)
- Migration path: Direct replacement of Blocks 1d-2
- Performance: 93% main context reduction, error isolation, parallel potential

## Success Criteria

- [ ] Block 1d-calc exists and pre-calculates REPORT_PATH before Block 1e-exec
- [ ] REPORT_PATH is absolute path, persisted to state file, validated
- [ ] Block 1e-exec Task prompt passes REPORT_PATH contract to lean-research-specialist
- [ ] Block 1f exists and performs hard barrier validation using validate_agent_artifact
- [ ] Block 2 pre-calculates PLAN_PATH before Task invocation
- [ ] Block 2 Task prompt passes PLAN_PATH contract to lean-plan-architect
- [ ] End-to-end test: /lean-plan creates research report at pre-calculated path
- [ ] End-to-end test: /lean-plan creates plan at pre-calculated path
- [ ] Error isolation test: Subagent failure doesn't pollute main context with 74k tokens
- [ ] All bash blocks follow three-tier sourcing pattern (code standards compliance)
- [ ] Hard barrier pattern validated via linter and pre-commit hooks

## Technical Design

### Architecture Overview

**Current Architecture** (problematic):
```
Block 1d: Setup research directories
Block 1e: Task invocation with directory path → lean-research-specialist
  → Agent calculates own report path (violates Hard Barrier)
  → Main conversation continues without validation
Block 2: Inline research verification + plan path calc + Task invocation
```

**New Architecture** (Hard Barrier Pattern):
```
Block 1d: Setup research directories
Block 1d-calc: Pre-calculate REPORT_PATH, persist to state
Block 1e-exec: Task invocation with REPORT_PATH contract → lean-research-specialist
  → Agent writes to exact path provided
Block 1f: Hard barrier validation (validate_agent_artifact)
Block 2: Pre-calculate PLAN_PATH, persist to state
Block 2-exec: Task invocation with PLAN_PATH contract → lean-plan-architect
Block 3: Lean-specific validation (existing, no changes needed)
```

### Component Integration

**State Persistence**:
- Block 1d-calc: `append_workflow_state "REPORT_PATH" "$REPORT_PATH"`
- Block 1f: Restore REPORT_PATH from state file for validation
- Block 2: `append_workflow_state "PLAN_PATH" "$PLAN_PATH"`

**Hard Barrier Validation**:
- Use `validate_agent_artifact` from validation-utils.sh
- Minimum size: 500 bytes for research reports (comprehensive content)
- Fail workflow immediately if validation fails (exit 1)

**Task Prompt Contracts**:
- Block 1e-exec: Add **Input Contract (Hard Barrier Pattern)** section
- Block 2-exec: Add **Input Contract (Hard Barrier Pattern)** section
- Both contracts explicitly state: "You MUST write to EXACT path specified"

### Divergence from Standards

**No divergence** - this plan aligns existing /lean-plan implementation with established Hard Barrier Pattern already used in /create-plan. Agent behavioral files already expect this contract.

## Implementation Phases

### Phase 1: Add Block 1d-calc (Research Report Path Pre-Calculation) [COMPLETE]
dependencies: []

**Objective**: Insert new bash block between current Block 1d and Block 1e to pre-calculate REPORT_PATH variable, validate it's absolute, and persist to state file.

**Complexity**: Low

**Tasks**:
- [x] Insert Block 1d-calc heading after line 817 in /lean-plan.md (file: /home/benjamin/.config/.claude/commands/lean-plan.md)
- [x] Add bash block with project directory detection (lines 718-730 from research report example)
- [x] Add state restoration logic using STATE_ID_FILE pattern (lines 735-750)
- [x] Add library sourcing: error-handling.sh, state-persistence.sh (lines 756-764)
- [x] Add error trap setup: `setup_bash_error_trap` (line 768)
- [x] Calculate REPORT_PATH: `REPORT_PATH="${RESEARCH_DIR}/001-lean-mathlib-research.md"` (lines 772-774)
- [x] Validate REPORT_PATH is absolute using regex test (lines 776-790)
- [x] Create parent directory: `mkdir -p "$(dirname "$REPORT_PATH")"` (line 792)
- [x] Persist REPORT_PATH to state: `append_workflow_state "REPORT_PATH" "$REPORT_PATH"` (lines 795-797)
- [x] Add console output: echo report path and workflow ID (lines 800-805)
- [x] Verify bash block uses three-tier sourcing pattern (code standards compliance)

**Testing**:
```bash
# Run /lean-plan with a test feature description
cd /home/benjamin/.config
/lean-plan "prove group homomorphism properties"

# Verify REPORT_PATH persisted to state
STATE_FILE=$(cat .claude/tmp/lean_plan_state_id.txt)
grep "REPORT_PATH=" .claude/tmp/workflow_${STATE_FILE}.sh

# Verify path is absolute
[[ $(grep "REPORT_PATH=" .claude/tmp/workflow_${STATE_FILE}.sh | cut -d'=' -f2) =~ ^/ ]]
```

**Expected Duration**: 1 hour

### Phase 2: Update Block 1e to Block 1e-exec (Hard Barrier Invocation) [COMPLETE]
dependencies: [1]

**Objective**: Rename current Block 1e to Block 1e-exec, update Task prompt to pass REPORT_PATH contract instead of Output Directory, and add Input Contract section documenting Hard Barrier Pattern.

**Complexity**: Low

**Tasks**:
- [x] Rename "Block 1e: Research Initiation" to "Block 1e-exec: Research Execution (Hard Barrier Invocation)" (line 819 in /lean-plan.md)
- [x] Update Task description to include "with mandatory file creation" (line 825)
- [x] Add **Input Contract (Hard Barrier Pattern)** section after workflow context heading (lines 836-841 from research report)
- [x] Replace `- Output Directory: ${RESEARCH_DIR}` with `- REPORT_PATH: ${REPORT_PATH}` in Task prompt
- [x] Add LEAN_PROJECT_PATH to Input Contract (line 829 from research report)
- [x] Add FEATURE_DESCRIPTION to Input Contract (line 830)
- [x] Add RESEARCH_COMPLEXITY to Input Contract (line 831)
- [x] Add **CRITICAL** instruction: "You MUST write the research report to the EXACT path specified in REPORT_PATH" (lines 842-844)
- [x] Update completion signal: `REPORT_CREATED: ${REPORT_PATH}` (line 854)
- [x] Remove outdated "Output Directory" reference from Workflow-Specific Context section
- [x] Verify Task prompt follows command authoring standards (imperative directive pattern)

**Testing**:
```bash
# Verify Task prompt contains REPORT_PATH contract
grep -A 20 "Input Contract" /home/benjamin/.config/.claude/commands/lean-plan.md | grep "REPORT_PATH"

# Verify completion signal uses REPORT_PATH
grep "REPORT_CREATED: \${REPORT_PATH}" /home/benjamin/.config/.claude/commands/lean-plan.md
```

**Expected Duration**: 0.5 hours

### Phase 3: Add Block 1f (Research Report Hard Barrier Validation) [COMPLETE]
dependencies: [2]

**Objective**: Add new validation block after Block 1e-exec to restore REPORT_PATH from state, validate report file exists with minimum size using validate_agent_artifact, and fail workflow if validation fails.

**Complexity**: Medium

**Tasks**:
- [x] Insert Block 1f heading after Block 1e-exec in /lean-plan.md (after line 853)
- [x] Add bash block with project directory detection (lines 474-486 from research report)
- [x] Add state restoration logic using STATE_ID_FILE pattern (lines 491-506)
- [x] Add library sourcing: error-handling.sh, validation-utils.sh (lines 512-522)
- [x] Add error trap setup: `setup_bash_error_trap` (line 525)
- [x] Add console output heading: "=== Research Report Hard Barrier Validation ===" (lines 527-529)
- [x] Validate REPORT_PATH is set from Block 1d-calc state (lines 533-544)
- [x] Echo expected report file path (line 546)
- [x] Call `validate_agent_artifact "$REPORT_PATH" 500 "research report"` (line 550)
- [x] Add error handling: exit 1 if validation fails (lines 551-560)
- [x] Add success message: "✓ Hard barrier passed - research report file validated" (lines 562-563)
- [x] Add error logging using log_command_error for state_error type (lines 534-542)
- [x] Verify bash block uses three-tier sourcing pattern (code standards compliance)

**Testing**:
```bash
# Run /lean-plan and verify hard barrier validation
cd /home/benjamin/.config
/lean-plan "prove ring homomorphism theorems"

# Check validation output
# Expected: "✓ Hard barrier passed - research report file validated"

# Test failure case: Delete report file before Block 1f
# Expected: "ERROR: HARD BARRIER FAILED - Lean research specialist validation failed"
```

**Expected Duration**: 1 hour

### Phase 4: Update Block 2 Plan Path Calculation [COMPLETE]
dependencies: [3]

**Objective**: Move PLAN_PATH calculation before Task invocation, add absolute path validation, update Task prompt with Input Contract section, and ensure pre-calculated path is passed to lean-plan-architect.

**Complexity**: Medium

**Tasks**:
- [x] Locate PLAN_PATH calculation in current Block 2 (around lines 1116-1118 based on research)
- [x] Extract PLAN_PATH calculation logic to separate section before Task invocation
- [x] Add absolute path validation for PLAN_PATH using regex test (file: /home/benjamin/.config/.claude/commands/lean-plan.md)
- [x] Add error logging if PLAN_PATH is not absolute using log_command_error
- [x] Persist PLAN_PATH to state: `append_workflow_state "PLAN_PATH" "$PLAN_PATH"`
- [x] Update lean-plan-architect Task prompt (locate around line 1201-1265)
- [x] Add **Input Contract (Hard Barrier Pattern)** section to Task prompt (lines 638-641 from research report)
- [x] Replace or verify PLAN_PATH is passed in Input Contract section
- [x] Add **CRITICAL** instruction: "You MUST write the implementation plan to the EXACT path specified in PLAN_PATH" (lines 644-646)
- [x] Update completion signal expectation: `PLAN_CREATED: ${PLAN_PATH}` (line 665)
- [x] Collect research report paths and pass to Task prompt as REPORT_PATHS_LIST
- [x] Verify Task prompt follows command authoring standards (imperative directive pattern)

**Testing**:
```bash
# Verify PLAN_PATH is calculated before Task invocation
grep -n "PLAN_PATH=" /home/benjamin/.config/.claude/commands/lean-plan.md
grep -n "Task {" /home/benjamin/.config/.claude/commands/lean-plan.md | grep "lean-plan-architect"

# Verify PLAN_PATH line number < Task invocation line number

# Verify Input Contract in Task prompt
grep -A 10 "Input Contract" /home/benjamin/.config/.claude/commands/lean-plan.md | tail -20
```

**Expected Duration**: 1.5 hours

### Phase 5: End-to-End Testing and Validation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Run /lean-plan with a real Lean project to verify research report created at pre-calculated path, plan created at pre-calculated path, and error isolation works correctly without polluting main context.

**Complexity**: Medium

**Tasks**:
- [x] Create test Lean project with sample theorem file (file: /tmp/test_lean_project/Main.lean)
- [x] Run /lean-plan with test feature: "formalize group homomorphism preservation properties"
- [x] Verify Block 1d-calc output shows pre-calculated REPORT_PATH
- [x] Verify Block 1e-exec Task invocation passes REPORT_PATH contract
- [x] Verify Block 1f validation output shows "✓ Hard barrier passed"
- [x] Verify research report file exists at expected path in specs/{NNN_topic}/reports/
- [x] Verify research report file size >= 500 bytes (comprehensive content)
- [x] Verify Block 2 output shows pre-calculated PLAN_PATH
- [x] Verify plan file exists at expected path in specs/{NNN_topic}/plans/
- [x] Verify plan file size >= 2000 bytes (comprehensive plan)
- [x] Test error isolation: Induce agent failure and verify main context not polluted
- [x] Test state restoration: Verify REPORT_PATH restored correctly in Block 1f
- [x] Test state restoration: Verify PLAN_PATH used correctly in Block 2
- [x] Run validation script: `bash .claude/scripts/validate-all-standards.sh --sourcing` (verify three-tier pattern)
- [x] Run pre-commit hooks to validate standards compliance

**Testing**:
```bash
# Create test Lean project
mkdir -p /tmp/test_lean_project
cat > /tmp/test_lean_project/Main.lean <<'EOF'
import Mathlib.Algebra.Group.Hom.Defs

theorem group_hom_preserves_identity {G H : Type*} [Group G] [Group H]
  (f : G →* H) : f 1 = 1 := by
  sorry
EOF

# Run /lean-plan with test Lean project
cd /home/benjamin/.config
/lean-plan "formalize group homomorphism preservation properties" --lean-project /tmp/test_lean_project

# Verify research report created
TOPIC_DIR=$(ls -td .claude/specs/*_group_hom* | head -1)
test -f "$TOPIC_DIR/reports/001-lean-mathlib-research.md"
REPORT_SIZE=$(wc -c < "$TOPIC_DIR/reports/001-lean-mathlib-research.md")
[ "$REPORT_SIZE" -ge 500 ]

# Verify plan created
test -f "$TOPIC_DIR/plans/001-"*"-plan.md"
PLAN_SIZE=$(wc -c < "$TOPIC_DIR/plans/001-"*"-plan.md")
[ "$PLAN_SIZE" -ge 2000 ]

# Verify no 74k token Explore operations in main context
# (check output manually - should see Task delegations instead of inline research)

# Test error isolation (simulate agent failure)
# Manually edit lean-research-specialist.md to force early exit
# Run /lean-plan again
# Expected: Block 1f fails with clear error, no 74k token pollution
# Restore lean-research-specialist.md after test

# Validate standards compliance
bash .claude/scripts/validate-all-standards.sh --sourcing
# Expected: All checks pass for updated /lean-plan.md
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing

**Block 1d-calc Validation**:
- Test REPORT_PATH calculation produces absolute path
- Test state persistence includes REPORT_PATH variable
- Test error handling for non-absolute paths

**Block 1f Validation**:
- Test validate_agent_artifact detects missing report file
- Test validate_agent_artifact detects undersized report file (<500 bytes)
- Test state restoration retrieves correct REPORT_PATH

**Block 2 Plan Path Validation**:
- Test PLAN_PATH calculation produces absolute path
- Test state persistence includes PLAN_PATH variable
- Test Task prompt includes Input Contract section

### Integration Testing

**End-to-End Workflow**:
- Test /lean-plan creates research report at pre-calculated path
- Test /lean-plan creates plan at pre-calculated path
- Test hard barrier validation catches missing artifacts
- Test error isolation prevents main context pollution

**Error Handling**:
- Test Block 1f fails workflow when report missing
- Test Block 1f fails workflow when report undersized
- Test error logging creates centralized error log entries

### Standards Compliance Testing

**Code Standards**:
- Verify all new bash blocks use three-tier sourcing pattern
- Verify error trap setup follows defensive programming pattern
- Verify state persistence uses append_workflow_state correctly

**Output Formatting**:
- Verify bash blocks suppress library sourcing output with 2>/dev/null
- Verify console summaries use 4-section format (if applicable)
- Verify checkpoint format follows standards

## Documentation Requirements

### Command File Documentation

**Update /lean-plan.md**:
- Add inline comments documenting Hard Barrier Pattern in Block 1d-calc
- Add inline comments documenting validation logic in Block 1f
- Update Block 2 comments to explain plan path pre-calculation
- Add references to research report showing pattern rationale

**Update lean-plan-output.md** (if exists):
- Document expected output format changes (hard barrier validation messages)
- Document context reduction metrics (74.2k → ~5k tokens)
- Add examples of Block 1f validation success/failure messages

### Guide Documentation

**Update lean-plan-command-guide.md** (file: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md):
- Document Hard Barrier Pattern implementation
- Add section explaining REPORT_PATH contract between command and agent
- Add section explaining PLAN_PATH contract between command and agent
- Add troubleshooting section for hard barrier validation failures
- Add performance comparison: before/after context usage

**Create or update Hard Barrier Pattern documentation**:
- Document pre-calculation → invocation → validation pattern
- Add /lean-plan as reference implementation example
- Document benefits: error isolation, context reduction, artifact validation

### Agent Behavioral File Documentation

**No changes needed**:
- lean-research-specialist.md already expects REPORT_PATH (lines 24-62)
- lean-plan-architect.md already expects PLAN_PATH (lines 108-205)
- Agent behavioral files correctly document Input Contract expectations

**Verification task**:
- Verify lean-research-specialist.md STEP 1 documentation matches new Block 1e-exec contract
- Verify lean-plan-architect.md STEP 2 documentation matches new Block 2 contract

## Dependencies

### External Dependencies

**None** - All required infrastructure exists:
- lean-research-specialist.md agent (already expects REPORT_PATH)
- lean-plan-architect.md agent (already expects PLAN_PATH)
- validation-utils.sh library (provides validate_agent_artifact)
- state-persistence.sh library (provides append_workflow_state)
- error-handling.sh library (provides log_command_error, setup_bash_error_trap)

### Internal Prerequisites

**Completed Phases**:
- Phase 1 must complete before Phase 2 (REPORT_PATH persistence required)
- Phase 2 must complete before Phase 3 (Block 1e-exec must pass contract)
- Phase 3 must complete before Phase 4 (research validation must work)
- Phase 4 must complete before Phase 5 (all blocks needed for end-to-end test)

**State File Dependencies**:
- Block 1d-calc depends on STATE_FILE created by Block 1d
- Block 1f depends on REPORT_PATH persisted by Block 1d-calc
- Block 2 depends on state variables from previous blocks

## Rollback Plan

**If implementation fails**:
1. Revert /lean-plan.md to git HEAD: `git checkout HEAD -- .claude/commands/lean-plan.md`
2. No agent behavioral files modified (rollback not needed)
3. No library files modified (rollback not needed)
4. Clean up test artifacts: `rm -rf .claude/specs/*_group_hom*`

**Safe rollback guaranteed** because:
- Only /lean-plan.md is modified (single file)
- Agent behavioral files already correct (no changes)
- State file format unchanged (backward compatible)

## Risk Analysis

### Implementation Risks

**Risk**: Block 1f hard barrier validation too strict (500 bytes minimum)
- **Mitigation**: Research report analysis shows reports are comprehensive (>2000 bytes typical)
- **Severity**: Low - agents already create large reports

**Risk**: State restoration fails between blocks
- **Mitigation**: Use proven STATE_ID_FILE pattern from existing blocks
- **Severity**: Low - pattern already used successfully in /lean-plan

**Risk**: Task prompt changes break lean-research-specialist behavior
- **Mitigation**: Agent already expects REPORT_PATH contract (no behavioral changes needed)
- **Severity**: Very Low - aligning command with existing agent expectations

### Performance Risks

**Risk**: Additional bash blocks slow down /lean-plan execution
- **Mitigation**: Blocks are lightweight (path calculation + validation only)
- **Expected overhead**: <100ms per block
- **Severity**: Very Low - offset by 93% context reduction benefit

**Risk**: Hard barrier validation adds latency
- **Mitigation**: validate_agent_artifact is fast (file existence + size check)
- **Expected overhead**: <50ms
- **Severity**: Very Low - critical for artifact reliability

### Compatibility Risks

**Risk**: Existing /lean-plan workflows break
- **Mitigation**: State file format unchanged, output paths unchanged
- **User impact**: None - command invocation identical
- **Severity**: None - backward compatible

## Success Metrics

**Context Reduction**:
- **Target**: 93% reduction in main conversation token usage
- **Measurement**: Compare lean-plan-output.md before/after (74.2k → ~5k tokens)
- **Validation**: Verify main conversation shows Task delegations, not inline Explore

**Artifact Reliability**:
- **Target**: 100% research report creation at pre-calculated paths
- **Measurement**: Run 10 test cases, verify all reports at expected paths
- **Validation**: No agent-calculated path mismatches

**Error Isolation**:
- **Target**: Subagent failures don't pollute main context
- **Measurement**: Induce agent failure, verify main conversation <5k tokens
- **Validation**: Error logged to centralized error log, not dumped to main context

**Standards Compliance**:
- **Target**: 100% validation script pass rate
- **Measurement**: `bash .claude/scripts/validate-all-standards.sh --sourcing`
- **Validation**: Zero ERROR-level violations in updated /lean-plan.md

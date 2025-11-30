# Research Command Subagent Delegation Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Fix /research command to properly delegate to research-specialist subagent
- **Scope**: Modify /research command architecture to enforce hard barrier pattern for mandatory subagent delegation
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Research Command Root Cause Analysis](../reports/001-research-command-root-cause-analysis.md)

## Overview

The `/research` command currently exhibits poor performance because the primary agent performs research work directly instead of delegating to the research-specialist subagent. While the command includes proper Task invocations at Block 1d (lines 450-472), the primary agent bypasses this delegation and executes research tasks itself.

This implementation plan addresses the root cause by implementing the **hard barrier pattern** - a three-part architectural pattern that enforces mandatory subagent delegation through:
1. Pre-calculation of expected output paths (before Task invocation)
2. Explicit path contract in Task prompt (subagent receives absolute report path)
3. Hard validation barrier (verify subagent output exists before proceeding)

The fix brings `/research` into alignment with `/build` and `/plan` commands, which successfully enforce hierarchical agent architecture through this pattern.

## Research Summary

Key findings from root cause analysis:

1. **Missing Report Path Pre-Calculation**: The `/research` command provides only `RESEARCH_DIR` to the research-specialist, not the specific `REPORT_PATH` that the agent expects (research-specialist.md lines 24-44 require absolute report path input)

2. **No Hard Barrier Validation**: After Task invocation (Block 1d), the command proceeds directly to Block 2 verification without an intermediate validation block that enforces subagent completion

3. **Weak Delegation Language**: Block 1d uses descriptive language ("CRITICAL BARRIER", "MANDATORY") but lacks procedural enforcement - the primary agent interprets this as guidance rather than execution requirement

4. **Successful Pattern in /build**: The `/build` command demonstrates the correct pattern with pre-calculated paths, explicit "After it returns" temporal dependency, and inline verification that checks for agent-specific outputs

5. **Agent Contract Violation**: research-specialist behavioral file (lines 24-44) EXPECTS a pre-calculated report path as input, but `/research` command does NOT provide it, violating the required input protocol

## Success Criteria
- [ ] `/research` command pre-calculates REPORT_PATH before Task invocation
- [ ] Task prompt passes absolute REPORT_PATH to research-specialist (not just RESEARCH_DIR)
- [ ] New Block 1e validation enforces hard barrier (exits if report missing)
- [ ] Primary agent CANNOT bypass subagent delegation (architectural enforcement)
- [ ] Test case: `/research "test topic"` → research-specialist creates report at pre-calculated path
- [ ] Test case: Simulated agent failure → Block 1e exits with error, workflow halts
- [ ] Verification: grep for "research-specialist" in output (confirms subagent invocation)
- [ ] Verification: Output shows Task invocation → Agent execution → Validation → Completion sequence

## Technical Design

### Architecture Pattern: Hard Barrier Subagent Delegation

The implementation follows the **hard barrier pattern** used successfully in `/build` and `/plan` commands:

```
Block 1c: Topic Path Initialization
  ↓
Block 1d-NEW: Report Path Pre-Calculation (bash block)
  • Calculate REPORT_PATH = ${RESEARCH_DIR}/001-${REPORT_SLUG}.md
  • Persist REPORT_PATH to state
  ↓
Block 1d-UPDATED: Research Specialist Invocation (Task block)
  • Pass REPORT_PATH to agent (not just RESEARCH_DIR)
  • Agent receives absolute path contract
  ↓
Block 1e-NEW: Agent Output Validation (bash block)
  • HARD BARRIER: Verify REPORT_PATH file exists
  • Exit 1 if missing (prevents proceeding)
  • Validate report contains required sections
  ↓
Block 2: Verification and Completion (existing)
  • Verify artifacts (already checks directory/files)
  • Complete workflow state transition
```

### Key Architectural Changes

1. **Block 1d Split**: Current Block 1d (lines 444-472) becomes:
   - Block 1d-NEW: Report path pre-calculation (bash)
   - Block 1d-UPDATED: Task invocation with absolute path (Task)

2. **New Block 1e**: Hard barrier validation
   - Positioned AFTER Task invocation, BEFORE Block 2
   - Creates execution dependency (cannot reach Block 2 without agent completion)
   - Logs agent_error if report missing

3. **Task Prompt Update**: Change from `Output Directory: ${RESEARCH_DIR}` to:
   ```
   - Report Path: ${REPORT_PATH}
   - Output Directory: ${RESEARCH_DIR}
   ```

### Report Path Calculation Logic

```bash
# Calculate report number (001, 002, 003...)
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# Generate report slug from workflow description (max 40 chars)
REPORT_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

# Construct absolute report path
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Persist for Block 1e validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
```

### Error Logging Integration

All validation failures log to centralized error log:

```bash
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "agent_error" \
  "research-specialist failed to create report file" \
  "bash_block_1e" \
  "$(jq -n --arg path "$REPORT_PATH" '{expected_path: $path}')"
```

## Implementation Phases

### Phase 1: Add Report Path Pre-Calculation Block [COMPLETE]
dependencies: []

**Objective**: Insert new bash block between Block 1c and current Block 1d to pre-calculate the absolute report path

**Complexity**: Low

Tasks:
- [ ] Insert new Block 1d heading at line 444 (shift current Block 1d to 1d-updated)
- [ ] Add bash block with REPORT_PATH calculation logic (file: .claude/commands/research.md:444-510)
  - Calculate REPORT_NUMBER from existing reports in RESEARCH_DIR
  - Generate REPORT_SLUG from WORKFLOW_DESCRIPTION (40 char max, kebab-case)
  - Construct REPORT_PATH = ${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md
  - Call append_workflow_state "REPORT_PATH" "$REPORT_PATH"
- [ ] Add echo statement showing pre-calculated path for visibility
- [ ] Verify bash block includes library sourcing (state-persistence.sh)
- [ ] Verify bash block restores state from Block 1c (WORKFLOW_ID, RESEARCH_DIR)

Testing:
```bash
# Unit test: Path calculation logic
bash .claude/tests/unit/test-report-path-calculation.sh

# Integration test: Run /research and verify REPORT_PATH in state file
/research "test topic"
grep "REPORT_PATH=" ~/.claude/tmp/workflow_research_*.sh
```

**Expected Duration**: 1.5 hours

### Phase 2: Update Task Prompt with Absolute Path [COMPLETE]
dependencies: [1]

**Objective**: Modify Block 1d Task invocation to pass REPORT_PATH to research-specialist

**Complexity**: Low

Tasks:
- [ ] Update Task prompt template in research.md (file: .claude/commands/research.md:450-472)
- [ ] Change "Output Directory: ${RESEARCH_DIR}" to include REPORT_PATH (lines ~462-463)
  - Add line: "- Report Path: ${REPORT_PATH}"
  - Keep existing: "- Output Directory: ${RESEARCH_DIR}"
- [ ] Update block heading language for clarity (file: .claude/commands/research.md:446-448)
  - Replace "CRITICAL BARRIER - Research Delegation" with "HARD BARRIER - Research Specialist Invocation"
  - Update text to mention "After the agent returns, Block 1e will verify..."
- [ ] Add explicit agent contract language (what file will be created, where)
- [ ] Verify REPORT_PATH variable interpolation works in Task prompt

Testing:
```bash
# Integration test: Verify Task prompt contains REPORT_PATH
/research "authentication patterns" --dry-run
# Check output for "Report Path: /path/to/report"

# Verify research-specialist receives absolute path
grep "REPORT_PATH" ~/.claude/output/research-output.md
```

**Expected Duration**: 1 hour

### Phase 3: Add Agent Output Validation Block (Block 1e) [COMPLETE]
dependencies: [2]

**Objective**: Insert new Block 1e between Task invocation and Block 2 to enforce hard barrier

**Complexity**: Medium

Tasks:
- [ ] Insert Block 1e heading after Task invocation block (file: .claude/commands/research.md:~473)
- [ ] Add bash block with agent output validation logic (lines ~474-530)
  - Source required libraries (error-handling.sh, state-persistence.sh)
  - Restore WORKFLOW_ID and state file from Block 1d
  - Load REPORT_PATH from state
  - Validate REPORT_PATH file exists (exit 1 if missing)
  - Validate report contains required sections (grep for "## Findings")
  - Log agent_error if validation fails
- [ ] Add echo statement confirming validation success
- [ ] Ensure error messages reference Block 1e for debugging
- [ ] Update line numbers in existing Block 2 references (shift by ~60 lines)

Testing:
```bash
# Test case 1: Normal operation (agent creates report)
/research "async patterns"
# Expected: Block 1e validates successfully, workflow completes

# Test case 2: Simulated agent failure (mock research-specialist to skip file creation)
# Create mock agent that returns without creating file
# Expected: Block 1e exits with error, workflow halts

# Test case 3: Malformed report (missing required sections)
# Create report file but omit "## Findings" section
# Expected: Block 1e validation fails on section check
```

**Expected Duration**: 2 hours

### Phase 4: Update Block 2 Verification Logic [COMPLETE]
dependencies: [3]

**Objective**: Simplify Block 2 verification since hard barrier is now in Block 1e

**Complexity**: Low

Tasks:
- [ ] Review Block 2 verification logic (file: .claude/commands/research.md:592-636)
- [ ] Keep directory existence check (line 595) - still useful for defensive validation
- [ ] Keep file existence check (line 609) - defensive validation
- [ ] Keep undersized file check (line 623) - catches edge cases
- [ ] Update Block 2 comments to reference Block 1e as primary validation
- [ ] Ensure Block 2 line numbers updated after Block 1e insertion
- [ ] Verify Block 2 restoration of state still works (RESEARCH_DIR, WORKFLOW_ID)

Testing:
```bash
# Integration test: Full workflow with all validation layers
/research "database migrations" --complexity 3

# Verify both Block 1e and Block 2 validation execute
grep "Agent output validated" ~/.claude/output/research-output.md
grep "Verifying research artifacts" ~/.claude/output/research-output.md
```

**Expected Duration**: 1 hour

### Phase 5: Documentation and Pattern Standardization [COMPLETE]
dependencies: [4]

**Objective**: Document the hard barrier pattern for reuse in other orchestrator commands

**Complexity**: Medium

Tasks:
- [ ] Create pattern documentation (file: .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
  - Document the three-part pattern (pre-calc, pass path, validate)
  - Include examples from /build, /plan, /research
  - Show before/after code snippets
  - Explain why descriptive language alone fails
  - Provide template for applying pattern to new commands
- [ ] Update command guide (file: .claude/docs/guides/commands/research-command-guide.md)
  - Add section on subagent delegation architecture
  - Explain REPORT_PATH pre-calculation
  - Document Block 1e validation barrier
  - Add troubleshooting for "agent did not create report" errors
- [ ] Update hierarchical agents overview (file: .claude/docs/concepts/hierarchical-agents-overview.md)
  - Add hard barrier pattern to best practices section
  - Reference /research as example of enforcement
  - Cross-reference pattern documentation
- [ ] Update research-specialist agent docs (file: .claude/agents/research-specialist.md)
  - Verify STEP 1 requirements match /research implementation
  - Add note that calling commands MUST provide REPORT_PATH
  - Reference /research as canonical example

Testing:
```bash
# Documentation validation
bash .claude/scripts/validate-readmes.sh
bash .claude/scripts/validate-links-quick.sh

# Verify pattern doc is discoverable
grep "hard-barrier" .claude/docs/concepts/patterns/README.md
grep "hard-barrier" .claude/docs/concepts/hierarchical-agents-overview.md
```

**Expected Duration**: 2.5 hours

## Testing Strategy

### Unit Tests
- Report path calculation logic (Phase 1)
  - Test slug generation from various workflow descriptions
  - Test report number sequencing (001, 002, 003...)
  - Test path construction format

### Integration Tests
- Full /research workflow (all phases)
  - Run `/research "test topic"` and verify:
    - REPORT_PATH calculated in Block 1d
    - Task prompt includes REPORT_PATH
    - research-specialist creates file at expected path
    - Block 1e validates successfully
    - Block 2 completes workflow
- Agent failure simulation (Phase 3)
  - Mock research-specialist to skip file creation
  - Verify Block 1e exits with agent_error
  - Verify workflow halts (does not reach Block 2)
- Malformed report detection (Phase 3)
  - Create report missing required sections
  - Verify Block 1e validation catches this

### Regression Tests
- Existing /research functionality preserved
  - --complexity flag still works
  - --file flag still works
  - Topic naming integration unaffected
  - State persistence intact across blocks
  - Error logging functional

### Success Criteria Validation
Run comprehensive test suite after Phase 5:
```bash
# Test Case 1: Normal operation
/research "authentication patterns" --complexity 2
# Verify: research-specialist invoked, report created, validation passed

# Test Case 2: High complexity (potential future supervisor pattern)
/research "microservices architecture" --complexity 4
# Verify: Workflow completes (supervisor pattern not yet implemented)

# Test Case 3: File input mode
echo "Detailed research prompt..." > /tmp/research-prompt.md
/research --file /tmp/research-prompt.md
# Verify: Prompt archived, research-specialist receives full context

# Verification Commands
grep "research-specialist" ~/.claude/output/research-output.md  # Confirms delegation
grep "REPORT_PATH" ~/.claude/tmp/workflow_research_*.sh        # Confirms path calc
grep "Agent output validated" ~/.claude/output/research-output.md  # Confirms Block 1e
```

## Documentation Requirements

### Command Documentation
- Update `.claude/docs/guides/commands/research-command-guide.md`
  - Add architecture diagram showing block flow with hard barrier
  - Document REPORT_PATH pre-calculation
  - Explain Block 1e validation purpose
  - Add troubleshooting section for delegation failures

### Pattern Documentation (New)
- Create `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`
  - Problem statement (why agents bypass delegation)
  - Solution pattern (three-part barrier)
  - Implementation guide with code examples
  - Examples from /build, /plan, /research
  - Template for applying to new commands

### Agent Documentation
- Update `.claude/agents/research-specialist.md`
  - Verify STEP 1 requirements documented
  - Add note that REPORT_PATH is mandatory input
  - Cross-reference /research command as canonical caller

### Standards Documentation
- Update `.claude/docs/concepts/hierarchical-agents-overview.md`
  - Add "Hard Barrier Pattern" to best practices
  - Reference new pattern documentation
  - Update /research example to show corrected architecture

## Dependencies

### External Dependencies
None - all changes are internal to .claude/ system

### Internal Prerequisites
- workflow-state-machine.sh >= 2.0.0 (already required)
- state-persistence.sh >= 1.5.0 (already required)
- error-handling.sh (already sourced)
- Research-specialist agent behavioral file (.claude/agents/research-specialist.md)

### File Dependencies
- `.claude/commands/research.md` (primary modification target)
- `.claude/agents/research-specialist.md` (input protocol contract)
- `.claude/lib/core/state-persistence.sh` (append_workflow_state function)
- `.claude/lib/core/error-handling.sh` (log_command_error function)

## Risk Mitigation

### Risk 1: Breaking Existing /research Workflows
**Mitigation**:
- Maintain backward compatibility for --complexity and --file flags
- Preserve all existing state variables (RESEARCH_DIR, TOPIC_PATH, etc.)
- Add new REPORT_PATH without removing old paths
- Test with various workflow descriptions to ensure path calculation robust

### Risk 2: Agent Still Bypasses Delegation
**Mitigation**:
- Hard barrier validation (exit 1) makes bypass impossible
- Block 1e creates hard dependency (cannot reach Block 2 without report)
- Error logging captures delegation failures for debugging
- Integration tests verify agent invocation actually occurs

### Risk 3: Path Calculation Edge Cases
**Mitigation**:
- Sanitize workflow description for slug (remove special chars)
- Limit slug to 40 characters (prevent overly long filenames)
- Use sequential numbering (001, 002, 003...) to avoid collisions
- Unit tests cover various workflow description formats

### Risk 4: Documentation Drift
**Mitigation**:
- Update all relevant docs in Phase 5 (atomic documentation update)
- Link validation checks catch broken cross-references
- Pattern documentation provides single source of truth
- Pre-commit hooks validate README structure

## Rollback Plan

If hard barrier pattern causes unforeseen issues:

1. **Immediate Rollback**: Revert `.claude/commands/research.md` to commit before Phase 1
   ```bash
   git checkout HEAD~5 .claude/commands/research.md
   ```

2. **Partial Rollback**: Keep Blocks 1d/1e but disable validation
   - Comment out `exit 1` in Block 1e validation
   - Change to warning-only mode (echo errors but continue)
   - Provides time to investigate root cause

3. **Graceful Degradation**: Add `--skip-validation` flag
   - Allow bypassing Block 1e for emergency workflows
   - Log usage of skip flag for tracking
   - Document as temporary escape hatch

## Estimated Impact

Based on research findings and comparison with `/build` command:

- **Context Reduction**: 85-95% (specialist summarizes findings vs full research in primary context)
- **Specialization**: research-specialist uses domain-specific tools and patterns
- **Maintainability**: Single source of truth in `.claude/agents/research-specialist.md`
- **Consistency**: Aligns `/research` with `/plan` and `/build` delegation patterns
- **Performance**: Enables future hierarchical supervision for complex research workflows (Complexity >= 3)
- **Reliability**: Hard barrier prevents silent delegation failures (fail-fast instead of degraded execution)

## Completion Verification

After implementation, verify all success criteria met:
- [ ] Run `/research "test topic"` → verify research-specialist creates report at REPORT_PATH
- [ ] Check output contains Task invocation evidence (grep "research-specialist")
- [ ] Verify Block 1e validation executes (grep "Agent output validated")
- [ ] Simulate agent failure → verify Block 1e exits with error
- [ ] Verify error logged to centralized error log (`/errors --command /research`)
- [ ] Run existing /research tests → verify no regressions
- [ ] Documentation links valid (bash .claude/scripts/validate-links-quick.sh)
- [ ] Pattern doc discoverable in hierarchical agents overview

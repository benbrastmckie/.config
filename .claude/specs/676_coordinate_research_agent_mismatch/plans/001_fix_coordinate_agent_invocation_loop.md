# Fix /coordinate Agent Invocation Loop Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Fix agent invocation to use RESEARCH_COMPLEXITY instead of hardcoded count
- **Scope**: /coordinate command research phase agent invocation (coordinate.md:470-491)
- **Estimated Phases**: 3
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/reports/001_agent_mismatch_investigation/OVERVIEW.md
  - /home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/reports/001_agent_mismatch_investigation/001_hardcoded_report_paths_count_analysis.md
  - /home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/reports/001_agent_mismatch_investigation/002_agent_invocation_template_interpretation.md
  - /home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/reports/001_agent_mismatch_investigation/003_loop_count_determination_logic.md

## Overview

The /coordinate command currently invokes 4 research agents regardless of the calculated RESEARCH_COMPLEXITY value (which correctly evaluates to 2 for typical workflows). This occurs because the agent invocation section uses natural language template instructions that Claude interprets as documentation rather than executable loop control. Claude resolves the invocation count by examining the 4 pre-calculated REPORT_PATHS array entries (from Phase 0 optimization) instead of the RESEARCH_COMPLEXITY variable.

### Root Cause
**Architectural Issue**: Natural language template at coordinate.md:470-491 lacks explicit bash loop control:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent for EACH research topic (1 to $RESEARCH_COMPLEXITY):
```

Claude interprets "for EACH research topic" as a suggestion and examines available context to determine iteration count, finding 4 REPORT_PATH variables (REPORT_PATH_0 through REPORT_PATH_3) and invoking 4 agents.

### Solution
Replace natural language template with **explicit bash loop** that programmatically controls Task invocations:
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  # Task tool invocation here
done
```

This aligns with existing patterns already used in verification loops (coordinate.md:681-686) and discovery loops (coordinate.md:576-596).

### Impact
- **Performance**: Eliminates 100% time/token overhead (reduces 4 agents to 2, saving 10-20 minutes and ~25,000 tokens per workflow)
- **Correctness**: Ensures agent count matches calculated complexity
- **Consistency**: Aligns agent invocation with existing loop patterns
- **User Experience**: Eliminates confusion when complexity score doesn't match observed agent count

## Success Criteria
- [ ] Agent invocation loop uses RESEARCH_COMPLEXITY as explicit controlling variable
- [ ] Number of Task invocations matches RESEARCH_COMPLEXITY value (verified via test workflow)
- [ ] All existing functionality preserved (behavioral injection, path passing, verification)
- [ ] Test workflow with RESEARCH_COMPLEXITY=2 invokes exactly 2 agents (not 4)
- [ ] Verification checkpoints continue to pass with correct file counts
- [ ] Documentation updated to explain explicit loop requirement

## Technical Design

### Architecture Analysis

**Current Flow** (Problematic):
```
Phase 0 (Initialization)
  ↓
  Pre-allocate 4 REPORT_PATH variables (REPORT_PATHS_COUNT=4)
  ↓
Phase 1 (Research)
  ↓
  Calculate RESEARCH_COMPLEXITY=2 ✓
  ↓
  Natural language template: "for EACH research topic (1 to $RESEARCH_COMPLEXITY)"
  ↓
  Claude examines context → finds 4 REPORT_PATH variables
  ↓
  Invokes 4 Task agents ✗ (should be 2)
  ↓
  Verification loop uses explicit bash: for i in $(seq 1 $RESEARCH_COMPLEXITY)
  ↓
  Verifies 2 files ✓ (ignores extra 2 files created by excess agents)
```

**Fixed Flow**:
```
Phase 0 (Initialization)
  ↓
  Pre-allocate 4 REPORT_PATH variables (REPORT_PATHS_COUNT=4) [unchanged]
  ↓
Phase 1 (Research)
  ↓
  Calculate RESEARCH_COMPLEXITY=2 ✓ [unchanged]
  ↓
  Bash block: Prepare iteration variables and diagnostic output
  ↓
  Markdown section: Explicit conditional enumeration
  ↓
  IF RESEARCH_COMPLEXITY >= 1: Invoke Task agent 1
  IF RESEARCH_COMPLEXITY >= 2: Invoke Task agent 2
  IF RESEARCH_COMPLEXITY >= 3: Invoke Task agent 3
  IF RESEARCH_COMPLEXITY >= 4: Invoke Task agent 4
  ↓
  Invokes 2 Task agents ✓ (conditionals evaluate to true for 1-2 only)
  ↓
  Verification loop uses explicit bash: for i in $(seq 1 $RESEARCH_COMPLEXITY) [unchanged]
  ↓
  Verifies 2 files ✓
```

### Critical Architectural Constraint (Research Finding)

**Task Invocation Limitation**: Task tool invocations **cannot** be placed inside bash blocks due to behavioral injection pattern (Standard 11). Task invocations must occur in markdown sections between bash blocks.

**Evidence** (Report 001, 003):
- coordinate.md structure: Bash blocks calculate variables → Markdown sections invoke Task tool
- Task tool is Claude Code feature invoked through behavioral injection, not bash command
- All existing agent invocations in coordinate.md occur in markdown sections (lines 444-464, 470-491)

**Implementation Implications**:
1. Bash blocks: Calculate iteration variables, prepare context, diagnostic output
2. Markdown sections: Explicit Task invocations with conditional guards
3. Cannot programmatically loop Task invocations from bash (architectural constraint)

**Comparison with Verification Loop**:
- Verification loop (coordinate.md:681) uses bash function `verify_file_created()`
- Bash functions CAN be called from bash loops
- Task tool is NOT a bash command → requires different approach

### Design Decisions

1. **Preserve Phase 0 Pre-Allocation**
   - Rationale: Phase 0 optimization achieves 85% token reduction and 25x speedup
   - Decision: Keep REPORT_PATHS_COUNT=4 hardcoded (max capacity design)
   - Trade-off: Minor memory overhead for unused paths acceptable for massive performance gain

2. **Explicit Loop Pattern**
   - Rationale: Matches existing verification/discovery loop patterns (lines 576, 681)
   - Decision: Use `for i in $(seq 1 $RESEARCH_COMPLEXITY)` syntax
   - Consistency: All loops in coordinate.md now use same iteration control pattern

3. **Diagnostic Output Enhancement**
   - Rationale: Improve observability and debugging
   - Decision: Add echo statements showing expected vs. actual agent counts
   - Benefit: Makes any future mismatch immediately visible

4. **Explicit Conditional Enumeration** (REVISED - Research Finding)
   - Rationale: Task tool invocations must be in markdown sections, not bash blocks
   - Decision: Use explicit conditional guards for each Task invocation (4 separate blocks)
   - Pattern: `**IF RESEARCH_COMPLEXITY >= N**: Invoke agent N` (Standard 11 compliant)
   - Alternative Considered: Single coordinator subagent (adds indirection, deferred)
   - Trade-off: Verbosity (4 Task blocks) for explicit control and architectural compliance

### Modified Section Structure (REVISED - Research Finding)

**Replace coordinate.md:466-491** (26 lines) with two-part implementation (~100 lines):

**Part 1: Bash Block** (Variable preparation and diagnostic output):
```bash
**EXECUTE NOW**: USE the Bash tool to prepare iteration variables:

# Calculate variables for each possible agent invocation
for i in $(seq 1 4); do
  export "RESEARCH_TOPIC_${i}=Topic ${i}"
  export "AGENT_REPORT_PATH_${i}=${REPORT_PATH_$((i-1))}"
done

echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo "Will invoke $RESEARCH_COMPLEXITY agents (conditionally guarded)"
```

**Part 2: Markdown Section** (Explicit conditional Task invocations):
```markdown
**EXECUTE CONDITIONALLY**: Based on RESEARCH_COMPLEXITY value:

**IF RESEARCH_COMPLEXITY >= 1** (always true):
Task { [agent 1 invocation with REPORT_PATH_0] }

**IF RESEARCH_COMPLEXITY >= 2** (true for complexity 2-4):
Task { [agent 2 invocation with REPORT_PATH_1] }

**IF RESEARCH_COMPLEXITY >= 3** (true for complexity 3-4):
Task { [agent 3 invocation with REPORT_PATH_2] }

**IF RESEARCH_COMPLEXITY >= 4** (true for complexity 4 only):
Task { [agent 4 invocation with REPORT_PATH_3] }
```

**Rationale**: Bash block cannot contain Task invocations (architectural constraint from Report 003). Solution splits preparation (bash) from invocation (markdown with conditionals).

## Implementation Phases

### Phase 1: Replace Agent Invocation Template with Explicit Conditional Enumeration [COMPLETED]
**Objective**: Convert natural language template to explicit conditional Task invocations (architectural constraint compliance)
**Complexity**: Medium
**Estimated Time**: 45-60 minutes (increased due to conditional enumeration pattern)

Tasks:
- [x] Read current coordinate.md:466-491 to capture exact Task invocation template structure (.claude/commands/coordinate.md:466-491)
- [x] Create backup of coordinate.md before modifications (coordinate.md.backup-YYYYMMDD-HHMMSS)
- [x] Design bash block for variable preparation (RESEARCH_TOPIC_N, AGENT_REPORT_PATH_N exports)
- [x] Design markdown section with 4 conditional Task invocations (IF RESEARCH_COMPLEXITY >= N guards)
- [x] Replace natural language section (lines 466-491) with two-part implementation (bash + markdown)
- [x] Verify syntax: Check bash variable exports, conditional guard format, Task invocation structure
- [x] Ensure Standard 11 compliance: Imperative instructions, no code fences, behavioral file references
- [x] Update line number references in comments if sections shift

**Key Implementation Details** (REVISED - Research Finding):

**Part 1: Bash Block** (Variable Preparation):
```bash
# Prepare variables for conditional invocations
for i in $(seq 1 4); do
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  export "RESEARCH_TOPIC_${i}=Topic ${i}"
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"
done

echo "━━━ Research Phase: Flat Coordination ━━━"
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo "Agent Invocations: Conditionally guarded (1-4 based on complexity)"
echo ""
```

**Part 2: Markdown Section** (Conditional Task Invocations):

**CRITICAL**: Task invocations must be in markdown, not bash blocks (architectural constraint from Report 003).

```markdown
**EXECUTE CONDITIONALLY**: Invoke research agents based on RESEARCH_COMPLEXITY:

**IF RESEARCH_COMPLEXITY >= 1** (always true):

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_1
    - Report Path: $AGENT_REPORT_PATH_1
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

**IF RESEARCH_COMPLEXITY >= 2** (true for complexity 2-4):

Task { [similar structure for agent 2 with RESEARCH_TOPIC_2, AGENT_REPORT_PATH_2] }

**IF RESEARCH_COMPLEXITY >= 3** (true for complexity 3-4):

Task { [similar structure for agent 3 with RESEARCH_TOPIC_3, AGENT_REPORT_PATH_3] }

**IF RESEARCH_COMPLEXITY >= 4** (hierarchical research triggers, not this code path):

Task { [similar structure for agent 4 with RESEARCH_TOPIC_4, AGENT_REPORT_PATH_4] }
```

**Rationale for Conditional Enumeration**:
- Task tool invocations CANNOT be inside bash loops (Report 003: architectural constraint)
- Explicit conditionals provide iteration control while respecting markdown requirement
- Standard 11 compliance: Imperative instructions, no code fences, behavioral file references
- Trade-off: Verbosity (4 Task blocks) for architectural compliance and explicit control

Testing:
```bash
# Test variable preparation bash block
RESEARCH_COMPLEXITY=2
REPORT_PATH_0="/path/to/001.md"
REPORT_PATH_1="/path/to/002.md"
REPORT_PATH_2="/path/to/003.md"
REPORT_PATH_3="/path/to/004.md"

for i in $(seq 1 4); do
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  export "RESEARCH_TOPIC_${i}=Topic ${i}"
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"
done

echo "RESEARCH_TOPIC_1: $RESEARCH_TOPIC_1"
echo "AGENT_REPORT_PATH_1: $AGENT_REPORT_PATH_1"
echo "RESEARCH_TOPIC_2: $RESEARCH_TOPIC_2"
echo "AGENT_REPORT_PATH_2: $AGENT_REPORT_PATH_2"
# Expected: All variables populated correctly

# Test conditional evaluation logic (manual)
# IF RESEARCH_COMPLEXITY >= 1: TRUE (invokes agent 1)
# IF RESEARCH_COMPLEXITY >= 2: TRUE (invokes agent 2)
# IF RESEARCH_COMPLEXITY >= 3: FALSE (skips agent 3)
# IF RESEARCH_COMPLEXITY >= 4: FALSE (skips agent 4)
# Expected: 2 agents invoked for RESEARCH_COMPLEXITY=2
```

**Validation**:
- Bash syntax valid (variable exports work correctly)
- Indirect variable expansion resolves REPORT_PATH correctly
- All 4 variables prepared (conditional guards control invocation, not preparation)
- Diagnostic output shows expected complexity value

**Files Modified**:
- .claude/commands/coordinate.md (lines 466-491 replaced with ~100 lines: bash block + 4 conditional Task invocations)

### Phase 2: Test Conditional Enumeration with RESEARCH_COMPLEXITY=2
**Objective**: Verify modified command invokes exactly 2 agents (not 4) for typical workflows via conditional guards
**Complexity**: Low
**Estimated Time**: 20-30 minutes (increased to test conditional evaluation)

Tasks:
- [ ] Create test workflow description with RESEARCH_COMPLEXITY=2 (e.g., "Investigate authentication patterns")
- [ ] Run modified /coordinate command with test workflow
- [ ] Monitor agent invocations: Count Task tool calls during research phase
- [ ] Verify exactly 2 research-specialist agents invoked (conditional guards IF >= 1, IF >= 2 evaluate true)
- [ ] Verify agents 3-4 NOT invoked (conditional guards IF >= 3, IF >= 4 evaluate false)
- [ ] Verify exactly 2 report files created (001, 002 only - no 003, 004)
- [ ] Verify verification loop passes (checks 2 files as expected)
- [ ] Verify workflow completes successfully (no errors in subsequent phases)
- [ ] Test edge cases: RESEARCH_COMPLEXITY=1, 3 (conditional evaluation at boundaries)

**Test Cases**:

**Test Case 1: Default Complexity (2 topics)**
```bash
/coordinate "Investigate authentication patterns and security implementation"
# Expected: RESEARCH_COMPLEXITY=2 (default)
# Expected: 2 Task invocations
# Expected: 2 reports created (001, 002)
```

**Test Case 2: Simple Fix (1 topic)**
```bash
/coordinate "Fix a single small bug in the login handler"
# Expected: RESEARCH_COMPLEXITY=1 (matches pattern "^(fix|update|modify).*(one|single|small)")
# Expected: 1 Task invocation
# Expected: 1 report created (001)
```

**Test Case 3: Architecture Change (3 topics)**
```bash
/coordinate "Refactor authentication architecture for microservices"
# Expected: RESEARCH_COMPLEXITY=3 (matches pattern "refactor|architecture")
# Expected: 3 Task invocations
# Expected: 3 reports created (001, 002, 003)
```

**Test Case 4: Max Complexity (4 topics)**
```bash
/coordinate "Design multi-tenant distributed authentication system"
# Expected: RESEARCH_COMPLEXITY=4 (matches pattern "multi-.*system|distributed")
# Expected: Hierarchical supervision triggers (USE_HIERARCHICAL_RESEARCH=true)
# Expected: Single research-sub-supervisor invocation (different code path, lines 440-464)
# Note: This test case validates hierarchical path unchanged, not flat coordination fix
```

Testing:
```bash
# Manual test execution
cd /home/benjamin/.config
/coordinate "Investigate authentication patterns and security implementation"

# Monitor output for:
# - "Research Complexity Score: 2 topics" ✓
# - Exactly 2 "Research Agent N/2" messages (not 4)
# - Verification: "Checking 2 research reports..." (not 4)
# - Success: "✓ All 2 reports verified successfully"
```

**Expected Behavior**:
- Diagnostic output shows "Research Agent 1/2", "Research Agent 2/2" (not 1/4, 2/4, 3/4, 4/4)
- Only 2 report files exist in reports directory after research phase
- Verification section shows "Checking 2 research reports..." (not "Checking 2 research reports..." while 4 exist)
- Workflow completes in ~10-20 minutes (not 20-40 minutes)

**Validation**:
- Agent count matches RESEARCH_COMPLEXITY for all test cases
- No extra report files created (003, 004) when RESEARCH_COMPLEXITY=2
- Performance improvement: Research phase duration reduced by ~50%
- Token usage reduced by ~25,000 tokens per workflow

**Success Criteria**:
- ✓ Test Case 1 (default=2): Exactly 2 agents invoked
- ✓ Test Case 2 (simple=1): Exactly 1 agent invoked
- ✓ Test Case 3 (complex=3): Exactly 3 agents invoked
- ✓ Test Case 4 (max=4): Hierarchical supervision used (different code path, already correct)

### Phase 3: Update Documentation and Inline Comments [COMPLETED]
**Objective**: Document explicit loop requirement and clarify Phase 0 pre-allocation strategy
**Complexity**: Low
**Estimated Time**: 20-30 minutes

Tasks:
- [x] Update coordinate-command-guide.md with "Agent Invocation Architecture" section (.claude/docs/guides/coordinate-command-guide.md)
- [x] Add explanation: Why explicit bash loops required (vs. natural language templates)
- [x] Document REPORT_PATHS_COUNT vs. RESEARCH_COMPLEXITY relationship
- [x] Add inline comment in coordinate.md explaining loop control rationale
- [x] Update workflow-initialization.sh comments clarifying pre-allocation strategy (.claude/lib/workflow-initialization.sh:318-331)
- [x] Add note: "Actual usage determined by RESEARCH_COMPLEXITY in Phase 1"
- [x] Verify cross-references: Link coordinate-command-guide.md to phase-0-optimization.md

**Documentation Updates**:

**1. Coordinate Command Guide** (.claude/docs/guides/coordinate-command-guide.md):

Add new section after "State Handler: Research Phase":

```markdown
### Agent Invocation Architecture

#### Explicit Loop Requirement

The research phase uses **explicit bash loops** to control agent invocations:

\```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  # Task tool invocation here
done
\```

**Why Explicit Loops Required**:

Natural language instructions like "for EACH research topic (1 to $RESEARCH_COMPLEXITY)"
are documentation templates, not executable code. Claude interprets these as suggestions
rather than iteration constraints. Only explicit bash `for` loops guarantee the correct
number of Task invocations.

**Historical Context**: Prior to this fix (Spec 676), the /coordinate command used natural
language templates and invoked 4 agents regardless of RESEARCH_COMPLEXITY value, causing
100% time/token overhead for typical workflows (RESEARCH_COMPLEXITY=2).

#### Pre-Calculated Array Size vs. Actual Usage

- **REPORT_PATHS_COUNT=4**: Pre-allocated path capacity (Phase 0 optimization)
- **RESEARCH_COMPLEXITY=1-4**: Actual agent invocations (pattern-based heuristic)
- **Design Intent**: Pre-allocate max paths (4) for performance, use subset (1-4) dynamically

Verification and discovery loops use RESEARCH_COMPLEXITY (not REPORT_PATHS_COUNT) to
determine iteration bounds, ensuring correctness even when pre-allocated capacity exceeds
actual usage.

**Performance Impact**:
- Phase 0 pre-allocation: 85% token reduction, 25x speedup vs. agent-based detection
- Explicit loop control: Eliminates unnecessary agent invocations (50% time savings for typical workflows)
```

**2. Inline Comment** (.claude/commands/coordinate.md, before loop):

```bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CRITICAL: Explicit bash loop required for agent invocation control
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Natural language templates ("for EACH topic") are interpreted as documentation,
# not iteration constraints. Claude resolves invocation count by examining available
# REPORT_PATH variables (4 pre-allocated) rather than RESEARCH_COMPLEXITY value.
#
# Solution: Explicit loop enforces RESEARCH_COMPLEXITY as controlling variable.
# See: Spec 676 (root cause analysis), coordinate-command-guide.md (architecture)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
```

**3. Workflow Initialization Comments** (.claude/lib/workflow-initialization.sh:318-331):

```bash
# Research phase paths (pre-allocate maximum 4 paths for Phase 0 optimization)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Design Trade-off: Fixed capacity (4) vs. dynamic complexity (1-4)
#   - Pre-allocate max paths upfront → 85% token reduction, 25x speedup
#   - Actual usage determined by RESEARCH_COMPLEXITY in Phase 1 (see coordinate.md)
#   - Unused paths remain exported but empty (minor memory overhead acceptable)
#
# Rationale: Phase 0 optimization pattern prioritizes performance over memory efficiency.
# Separation of concerns: Path calculation (infrastructure) vs. complexity detection (orchestration).
# See: phase-0-optimization.md (pattern guide), Spec 676 (architecture analysis)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local -a report_paths
for i in 1 2 3 4; do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# Export fixed count (4) for subprocess persistence
# Phase 1 orchestration uses RESEARCH_COMPLEXITY (1-4) for actual agent invocation control
export REPORT_PATHS_COUNT=4
```

Testing:
```bash
# Verify documentation links
cd /home/benjamin/.config/.claude/docs/guides
grep -n "Agent Invocation Architecture" coordinate-command-guide.md

# Verify inline comments added
grep -A 5 "CRITICAL: Explicit bash loop required" /home/benjamin/.config/.claude/commands/coordinate.md

# Verify cross-references
grep -n "Spec 676" coordinate-command-guide.md
grep -n "phase-0-optimization.md" /home/benjamin/.config/.claude/lib/workflow-initialization.sh
```

**Validation**:
- Documentation clearly explains explicit loop requirement
- Inline comments reference relevant specs and guides
- Cross-references link to phase-0-optimization.md and coordinate-command-guide.md
- Comments explain REPORT_PATHS_COUNT vs. RESEARCH_COMPLEXITY relationship

**Files Modified**:
- .claude/docs/guides/coordinate-command-guide.md (new section added)
- .claude/commands/coordinate.md (inline comments added before loop)
- .claude/lib/workflow-initialization.sh (enhanced comments at lines 318-331)

## Testing Strategy

### Unit Testing
Not applicable - this is a command orchestration fix, not a library function.

### Integration Testing

**Test Framework**: Manual execution of /coordinate command with various workflow descriptions

**Test Coverage**:
1. **Default Complexity (2 topics)**: Most common workflow type
2. **Simple Fix (1 topic)**: Edge case testing minimum complexity
3. **Architecture Change (3 topics)**: Testing pattern matching for complex workflows
4. **Max Complexity (4 topics)**: Edge case testing maximum complexity (hierarchical supervision)

**Validation Methods**:
- Count Task invocations during research phase (should match RESEARCH_COMPLEXITY)
- Check number of report files created (should match RESEARCH_COMPLEXITY)
- Verify verification checkpoint messages (should reference RESEARCH_COMPLEXITY count)
- Measure research phase duration (should be ~50% faster for RESEARCH_COMPLEXITY=2)

### Regression Testing

**Critical Paths to Verify**:
1. Verification loop still uses RESEARCH_COMPLEXITY (unchanged, should continue working)
2. Dynamic path discovery still uses RESEARCH_COMPLEXITY (unchanged)
3. Hierarchical research (≥4 topics) still triggers correctly (different code path)
4. Report path passing to agents still works (REPORT_PATH variable substitution)
5. Behavioral injection pattern preserved (agent reads behavioral file)

**Test Command**:
```bash
# Run existing .claude/tests for state machine and workflow coordination
cd /home/benjamin/.config
./run_all_tests.sh | grep -E "(coordinate|workflow|state_machine)"

# Expected: All existing tests pass (no regressions)
```

### Performance Testing

**Metrics to Capture**:
- Research phase duration (before vs. after fix)
- Token consumption during research phase (before vs. after)
- Number of Task invocations (before vs. after)

**Expected Improvements**:
- **Time**: 20-40 min → 10-20 min (50% reduction for RESEARCH_COMPLEXITY=2)
- **Tokens**: 50,000 → 25,000 (50% reduction for RESEARCH_COMPLEXITY=2)
- **Agent count**: 4 → 2 (100% accuracy for RESEARCH_COMPLEXITY=2)

## Risk Assessment

### Low Risks
- **Bash syntax errors**: Mitigated by syntax validation in Phase 1, manual testing in Phase 2
- **Variable substitution errors**: Mitigated by testing indirect expansion (${!REPORT_PATH_VAR})
- **Documentation drift**: Mitigated by updating all relevant docs and comments in Phase 3

### Medium Risks
- **Task invocation inside bash block limitation**: Claude Code may not support Task tool invocation inside bash blocks
  - **Mitigation**: Use hybrid approach - bash block calculates variables, Task invocations follow in markdown
  - **Fallback**: If hybrid doesn't work, restructure as bash block → markdown instructions → multiple Task blocks
- **Edge case: RESEARCH_COMPLEXITY=0**: Not handled by current heuristic (defaults to 2)
  - **Mitigation**: Add validation check `if [ $RESEARCH_COMPLEXITY -lt 1 ]; then RESEARCH_COMPLEXITY=1; fi`
  - **Note**: Current patterns don't produce RESEARCH_COMPLEXITY=0, but defensive coding recommended

### Negligible Risks
- **Phase 0 pre-allocation change**: Not modifying REPORT_PATHS_COUNT=4 (preserves optimization benefits)
- **Hierarchical research (≥4 topics)**: Separate code path, unaffected by flat coordination changes
- **Verification loop changes**: Not modifying verification logic (already correct)

## Dependencies

### Internal Dependencies
- **Phase 0 Optimization Pattern**: Pre-allocated paths (REPORT_PATHS_COUNT=4) remain unchanged
- **Bash Block Execution Model**: Subprocess isolation requires variable persistence patterns
- **Behavioral Injection Pattern**: Task invocation template structure preserved
- **Verification Fallback Pattern**: File verification checkpoints remain unchanged

### External Dependencies
None - this is an internal command orchestration fix.

## Rollback Plan

### Backup Strategy
- Create timestamped backup of coordinate.md before modifications (Phase 1, Task 2)
- Backup filename: `coordinate.md.backup-YYYYMMDD-HHMMSS`
- Location: Same directory as original (.claude/commands/)

### Rollback Procedure
If issues detected during Phase 2 testing:

```bash
# Restore from backup
cd /home/benjamin/.config/.claude/commands
cp coordinate.md.backup-YYYYMMDD-HHMMSS coordinate.md

# Verify restoration
git diff coordinate.md  # Should show no changes vs. pre-fix version

# Re-test original behavior
/coordinate "Test workflow"  # Should revert to invoking 4 agents
```

### Rollback Triggers
- Agent count doesn't match RESEARCH_COMPLEXITY after fix (indicates loop logic error)
- Verification checkpoints fail (indicates path passing broken)
- Bash syntax errors prevent command execution (indicates syntax validation missed errors)
- Task invocation fails due to variable substitution errors

## Notes

### Alternative Approaches Considered

**Option A: Dynamic Pre-Allocation** (Rejected)
- Move complexity detection into workflow-initialization.sh
- Allocate only RESEARCH_COMPLEXITY paths (not fixed 4)
- **Rejected Reason**: Violates separation of concerns (infrastructure vs. orchestration)

**Option C: MAX_REPORT_PATHS Constant** (Deferred)
- Introduce named constant for pre-allocation limit
- **Deferred Reason**: Complementary enhancement, not required for core fix
- **Future Work**: Consider for Spec 677 (code clarity improvements)

### Design Decisions

1. **Preserve Phase 0 Optimization**: REPORT_PATHS_COUNT=4 remains hardcoded
   - Rationale: 85% token reduction and 25x speedup benefits outweigh minor memory overhead
   - Trade-off: Accept architectural tension between fixed capacity (4) and dynamic usage (1-4)

2. **Explicit Loop Pattern**: Use `for i in $(seq 1 $RESEARCH_COMPLEXITY)`
   - Rationale: Matches existing verification/discovery loop patterns (consistency)
   - Alternative: `for i in {1..$RESEARCH_COMPLEXITY}` (bash brace expansion)
   - Decision: Use `seq` for clarity and compatibility with variable expansion

3. **Diagnostic Output**: Add echo statements for observability
   - Rationale: Makes any future mismatch immediately visible
   - Cost: ~5 lines of additional output per workflow (negligible)

4. **Inline Comments**: Explain why explicit loops required
   - Rationale: Prevent future regressions (developers might revert to natural language templates)
   - Reference: Link to Spec 676 and coordinate-command-guide.md

### Future Enhancements

**Phase 4 (Optional)**: Topic Name Extraction
- Current: Generic "Topic 1", "Topic 2" naming
- Enhancement: Parse workflow description to derive meaningful topic names
- Example: "authentication patterns" → "Topic 1: Authentication Patterns", "Topic 2: Security Best Practices"
- Benefit: More descriptive agent invocation output

**Phase 5 (Optional)**: MAX_REPORT_PATHS Constant
- Introduce named constant in workflow-initialization.sh
- Improve code clarity and maintainability
- See: Spec 676 OVERVIEW.md, Option C analysis

## Cross-References

### Related Specifications
- **Spec 676**: Root cause analysis and investigation reports (this spec)
- **Spec 602**: State-based orchestration architecture (Phase 0 optimization pattern)
- **Spec 057**: Verification fallback vs. bootstrap fallback patterns

### Documentation
- [Coordinate Command Guide](.claude/docs/guides/coordinate-command-guide.md) - Architecture overview
- [Phase 0 Optimization Guide](.claude/docs/guides/phase-0-optimization.md) - Pre-calculation strategy
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md) - Agent invocation via Task tool

### Source Files
- `.claude/commands/coordinate.md:466-491` - Agent invocation template (target for modification)
- `.claude/commands/coordinate.md:402-414` - RESEARCH_COMPLEXITY calculation (unchanged)
- `.claude/commands/coordinate.md:576-596` - Dynamic path discovery loop (reference pattern)
- `.claude/commands/coordinate.md:681-686` - Verification loop (reference pattern)
- `.claude/lib/workflow-initialization.sh:318-331` - REPORT_PATHS pre-calculation (comments updated)

## Revision History

### Revision 2 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: compatibility-verification (no changes)
- **Research Reports Used**:
  - [001_plan_676_analysis.md](../reports/001_plan_676_analysis.md) - Plan 676 implementation readiness analysis
  - [002_plan_670_compatibility.md](../reports/002_plan_670_compatibility.md) - Compatibility analysis with Plan 670 (Hybrid Classification)
- **Assessment**:
  - **Implementation Readiness**: HIGH (95% confidence) - Plan is comprehensive and architecturally sound
  - **Plan 670 Compatibility**: FULLY COMPATIBLE - Zero file conflicts, zero functional overlap, zero integration challenges
  - **Orthogonal Layers**: Plan 670 modifies libraries (`.claude/lib/*.sh`), Plan 676 modifies commands (`.claude/commands/coordinate.md`)
  - **Different Variables**: Plan 670 affects WORKFLOW_SCOPE, Plan 676 affects RESEARCH_COMPLEXITY (no interaction)
  - **Sequential Execution**: Plan 670 scope detection occurs in Phase 0 (initialization), Plan 676 agent invocation occurs in Phase 1 (research)
- **Key Findings**:
  - All three phases well-specified with clear validation steps
  - Explicit conditional enumeration approach is architecturally compliant (Standard 11)
  - Comprehensive testing strategy covers entire complexity range (1-4)
  - Rollback plan is simple and testable
  - Performance improvements quantified (50% time/token savings for RESEARCH_COMPLEXITY=2)
- **Changes Made**: NONE (minimal changes principle - plan is implementation-ready as-is)
- **Rationale**: Research confirms plan is implementation-ready with zero compatibility issues. No revisions required. Plan 676 can proceed immediately without coordination with Plan 670.
- **Recommendation**: Proceed with implementation following existing plan phases
- **Backup**: /home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/plans/backups/001_fix_coordinate_agent_invocation_loop_20251112_revision2.md

### Revision 1 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: research-informed
- **Research Reports Used**:
  - [001_coordinate_infrastructure.md](../reports/001_coordinate_infrastructure.md) - Coordinate command infrastructure analysis
  - [002_agent_invocation_standards.md](../reports/002_agent_invocation_standards.md) - Agent invocation standards and best practices
  - [003_plan_root_cause_analysis.md](../reports/003_plan_root_cause_analysis.md) - Plan root cause analysis
- **Key Changes**:
  - **Technical Design**: Added "Critical Architectural Constraint" section documenting Task invocation limitation (cannot be inside bash blocks)
  - **Architecture Analysis**: Updated "Fixed Flow" to show two-part implementation (bash block for preparation + markdown section for conditional invocations)
  - **Design Decisions**: Revised Decision 4 from "Task Invocation Inside Loop" to "Explicit Conditional Enumeration" pattern
  - **Modified Section Structure**: Changed from single bash loop implementation to two-part pattern (bash variable preparation + markdown conditional guards)
  - **Phase 1 Objective**: Updated to reflect conditional enumeration approach (not bash loop with Task invocations inside)
  - **Phase 1 Key Implementation Details**: Completely revised to show bash block (Part 1) and markdown section (Part 2) with explicit conditional guards
  - **Phase 1 Testing**: Updated to test variable preparation and conditional evaluation logic
  - **Phase 2 Title/Objective**: Updated to emphasize conditional enumeration testing
  - **Phase 2 Tasks**: Added verification steps for conditional guard evaluation (agents 3-4 NOT invoked when RESEARCH_COMPLEXITY=2)
  - **Test Case 4**: Added note clarifying hierarchical supervision triggers at complexity 4 (different code path)
- **Rationale**: Research reports revealed critical architectural constraint that Task tool invocations must be in markdown sections between bash blocks, not within bash blocks themselves. This constraint stems from behavioral injection pattern (Standard 11) and bash block subprocess isolation. Original plan showed Task invocations inside bash loop, which violates coordinate.md architecture. Revised to explicit conditional enumeration pattern (IF RESEARCH_COMPLEXITY >= N guards) achieving same iteration control while respecting architectural constraints.
- **Backup**: /home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/plans/backups/001_fix_coordinate_agent_invocation_loop_20251112_101438.md

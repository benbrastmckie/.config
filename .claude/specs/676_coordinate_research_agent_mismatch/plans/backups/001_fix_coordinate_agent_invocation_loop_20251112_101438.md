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
  Explicit bash loop: for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  ↓
  Invokes 2 Task agents ✓ (controlled by loop bound)
  ↓
  Verification loop uses explicit bash: for i in $(seq 1 $RESEARCH_COMPLEXITY) [unchanged]
  ↓
  Verifies 2 files ✓
```

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

4. **Task Invocation Inside Loop**
   - Rationale: Task tool must be invoked per-iteration with loop-specific values
   - Decision: Move entire Task invocation template inside bash loop body
   - Challenge: Requires proper variable substitution for $RESEARCH_TOPIC and $REPORT_PATH

### Modified Section Structure

**Replace coordinate.md:466-491** (26 lines) with bash loop implementation (~40 lines):

```bash
### Option B: Flat Research Coordination (<4 topics)

**EXECUTE IF** `USE_HIERARCHICAL_RESEARCH == "false"`:

**EXECUTE NOW**: USE the Bash tool to implement the research agent invocation loop:

[bash block with explicit for loop containing Task invocations]
```

## Implementation Phases

### Phase 1: Replace Agent Invocation Template with Explicit Loop
**Objective**: Convert natural language template to executable bash loop controlling Task invocations
**Complexity**: Medium
**Estimated Time**: 30-45 minutes

Tasks:
- [ ] Read current coordinate.md:466-491 to capture exact Task invocation template structure (.claude/commands/coordinate.md:466-491)
- [ ] Create backup of coordinate.md before modifications (coordinate.md.backup-YYYYMMDD-HHMMSS)
- [ ] Design bash loop structure with diagnostic output (echo statements for observability)
- [ ] Move Task invocation template inside loop body with proper variable substitution
- [ ] Replace natural language section (lines 466-491) with bash block containing explicit loop
- [ ] Verify syntax: Check bash loop structure, variable substitution ($i, $RESEARCH_COMPLEXITY, $REPORT_PATH)
- [ ] Update line number references in comments if bash block shifts subsequent sections

**Key Implementation Details**:

**Bash Loop Structure**:
```bash
# Explicit loop: Invoke exactly RESEARCH_COMPLEXITY agents
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  RESEARCH_TOPIC="Topic $i"  # Generic naming (can enhance later with topic extraction)
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  REPORT_PATH="${!REPORT_PATH_VAR}"  # Indirect variable expansion

  echo "━━━ Research Agent $i/$RESEARCH_COMPLEXITY ━━━"
  echo "Topic: $RESEARCH_TOPIC"
  echo "Report Path: $REPORT_PATH"
  echo ""
done
```

**Task Invocation Inside Loop** (maintain exact behavioral injection pattern):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research $RESEARCH_TOPIC with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC
    - Report Path: $REPORT_PATH
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Critical Requirement**: Task tool invocation must remain **outside** the bash block (Claude Code parsing limitation). The bash block prepares variables; Task invocations follow immediately after in markdown.

**Revised Structure**:
1. Bash block: Calculate loop-specific variables (RESEARCH_TOPIC, REPORT_PATH) for each iteration
2. Markdown instructions: "EXECUTE NOW: Invoke Task tool $RESEARCH_COMPLEXITY times with values from bash block"
3. Task template: Reference variables calculated in bash block

Testing:
```bash
# Verify bash loop syntax
bash -n .claude/commands/coordinate.md  # Syntax check (extract bash blocks first)

# Verify variable substitution
echo "Test RESEARCH_COMPLEXITY=2"
RESEARCH_COMPLEXITY=2
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  echo "Iteration $i: REPORT_PATH_$((i-1))"
done
# Expected output: Iteration 1/2, Iteration 2/2
```

**Validation**:
- Bash syntax valid (no parse errors)
- Loop bound correctly uses $RESEARCH_COMPLEXITY
- Variable substitution resolves REPORT_PATH correctly (indirect expansion: ${!REPORT_PATH_VAR})
- Diagnostic output shows expected iteration count

**Files Modified**:
- .claude/commands/coordinate.md (lines 466-491 replaced with ~40 lines)

### Phase 2: Test Agent Invocation with RESEARCH_COMPLEXITY=2
**Objective**: Verify modified command invokes exactly 2 agents (not 4) for typical workflows
**Complexity**: Low
**Estimated Time**: 15-20 minutes

Tasks:
- [ ] Create test workflow description with RESEARCH_COMPLEXITY=2 (e.g., "Investigate authentication patterns")
- [ ] Run modified /coordinate command with test workflow
- [ ] Monitor agent invocations: Count Task tool calls during research phase
- [ ] Verify exactly 2 research-specialist agents invoked (not 4)
- [ ] Verify exactly 2 report files created (001, 002 only - no 003, 004)
- [ ] Verify verification loop passes (checks 2 files as expected)
- [ ] Verify workflow completes successfully (no errors in subsequent phases)
- [ ] Test edge cases: RESEARCH_COMPLEXITY=1 (simple fix), RESEARCH_COMPLEXITY=3 (architecture change), RESEARCH_COMPLEXITY=4 (max complexity)

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
# Expected: 4 Task invocations (hierarchical supervision kicks in at ≥4)
# Expected: Via research-sub-supervisor (different code path)
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

### Phase 3: Update Documentation and Inline Comments
**Objective**: Document explicit loop requirement and clarify Phase 0 pre-allocation strategy
**Complexity**: Low
**Estimated Time**: 20-30 minutes

Tasks:
- [ ] Update coordinate-command-guide.md with "Agent Invocation Architecture" section (.claude/docs/guides/coordinate-command-guide.md)
- [ ] Add explanation: Why explicit bash loops required (vs. natural language templates)
- [ ] Document REPORT_PATHS_COUNT vs. RESEARCH_COMPLEXITY relationship
- [ ] Add inline comment in coordinate.md explaining loop control rationale
- [ ] Update workflow-initialization.sh comments clarifying pre-allocation strategy (.claude/lib/workflow-initialization.sh:318-331)
- [ ] Add note: "Actual usage determined by RESEARCH_COMPLEXITY in Phase 1"
- [ ] Verify cross-references: Link coordinate-command-guide.md to phase-0-optimization.md

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

# Plan Root Cause Analysis: Agent Invocation Loop Fix

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Analysis of existing plan to fix /coordinate agent invocation loop
- **Report Type**: Plan Review and Root Cause Investigation
- **Complexity Level**: 3

## Executive Summary

The existing implementation plan (001_fix_coordinate_agent_invocation_loop.md) correctly identifies the root cause and proposes a valid solution. However, upon deep analysis of the coordinate.md command structure and comparing it with the plan's proposed fix, a **critical implementation constraint** emerges: Task tool invocations cannot be placed inside bash blocks in the coordinate.md command architecture. The plan correctly identifies the need for explicit loop control but must be revised to accommodate the behavioral injection pattern where Task invocations exist in markdown sections between bash blocks, not within them.

## Findings

### 1. Plan Accuracy Assessment

**Current Plan Diagnosis** (Lines 16-42): ✓ ACCURATE

The plan correctly identifies:
- Natural language template at coordinate.md:470-491 lacks explicit bash loop control
- Claude interprets "for EACH research topic" as suggestion, not iteration control
- Claude examines 4 REPORT_PATH variables and invokes 4 agents
- RESEARCH_COMPLEXITY=2 is correctly calculated but not used as iteration bound

**Evidence from coordinate.md:470-491**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent for EACH research topic (1 to $RESEARCH_COMPLEXITY):

Task {
  subagent_type: "general-purpose"
  description: "Research [topic name] with mandatory artifact creation"
  ...
}
```

This is indeed a **natural language template** with no programmatic iteration control.

### 2. Root Cause Validation

**Proposed Root Cause** (Plan lines 20-34): ✓ VALIDATED

The plan states:
> "Natural language template at coordinate.md:470-491 lacks explicit bash loop control"
> "Claude interprets 'for EACH research topic' as a suggestion and examines available context to determine iteration count"

**Cross-Reference with Investigation Reports**:

From OVERVIEW.md (lines 98-127):
> "Natural language loop instruction: 'for EACH research topic (1 to $RESEARCH_COMPLEXITY)' is a **documentation template**, not executable code"
> "No explicit bash loop: Missing `for i in $(seq 1 $RESEARCH_COMPLEXITY); do ... done`"

From 003_loop_count_determination_logic.md (lines 106-114):
> "No Explicit Bash Loop: There is **no `for i in $(seq 1 $RESEARCH_COMPLEXITY)` loop** wrapping the Task invocation"
> "Claude Interpretation: Claude interprets this as 'invoke 4 agents' because REPORT_PATHS array has 4 entries"

**Verdict**: Root cause is accurately identified and matches findings from hierarchical investigation.

### 3. Proposed Solution Analysis

**Plan's Primary Fix** (Lines 118-187): ARCHITECTURALLY CONSTRAINED

The plan proposes:
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  RESEARCH_TOPIC="Topic $i"
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  REPORT_PATH="${!REPORT_PATH_VAR}"

  # Task invocation inside loop body
done
```

**Critical Issue Identified**: coordinate.md architecture separates bash blocks from Task invocations.

**Evidence from coordinate.md structure**:

Lines 340-436: Bash block calculating RESEARCH_COMPLEXITY
Lines 438-465: Hierarchical research Task invocation (markdown, not in bash)
Lines 466-491: Flat research Task invocation (markdown, not in bash)
Lines 493-596: Subsequent bash block for verification

**Pattern**: Task invocations exist in **markdown sections between bash blocks**, not within bash blocks.

**Reason**: The Task tool is a Claude Code feature invoked through behavioral injection, not a bash command. It must be called from markdown prompts, not bash subprocess contexts.

### 4. Implementation Constraint Discovery

**Key Architectural Constraint**: Task tool invocations cannot be inside bash blocks.

**Why This Matters**:
1. **Behavioral Injection Pattern** (Standard 11): Task invocations use markdown syntax with prompt strings
2. **Bash Block Isolation**: Each bash block runs in separate subprocess with no access to Claude Code tools
3. **Existing Pattern**: All agent invocations in coordinate.md occur in markdown sections (lines 444-464, 470-491)

**Evidence from coordinate.md:444-464** (Hierarchical research invocation):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-sub-supervisor:

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md
    ...
  "
}
```

This invocation is in **markdown**, not inside a bash block.

### 5. Plan Implementation Strategy Gap

**Gap Identified**: Plan lines 118-187 show bash loop with Task invocation inside, but coordinate.md architecture requires Task invocations in markdown.

**Plan's Code Structure** (Lines 150-187):
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  # Bash variables calculated
  RESEARCH_TOPIC="Topic $i"
  REPORT_PATH="${!REPORT_PATH_VAR}"

  # Then shows Task invocation template (lines 165-187)
  # But this would need to be OUTSIDE the bash block
done
```

**Architectural Reality**:
- Bash block can calculate variables (RESEARCH_TOPIC, REPORT_PATH)
- Task invocation must occur in markdown section AFTER bash block
- Cannot programmatically loop Task invocations from bash

**Critical Question**: How can we enforce RESEARCH_COMPLEXITY iteration count if Task invocations must be in markdown?

### 6. Alternative Implementation Approaches

**Approach A: Hybrid Pattern** (Recommended)

Separate variable preparation (bash) from invocation instruction (markdown):

```bash
# Bash block: Prepare iteration variables
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  export "RESEARCH_TOPIC_${i}=Topic ${i}"
  export "REPORT_PATH_FOR_AGENT_${i}=${REPORT_PATHS[$((i-1))]}"
done

# Export RESEARCH_COMPLEXITY for markdown section
export RESEARCH_COMPLEXITY
```

Then markdown section:
```markdown
**EXECUTE NOW**: Invoke Task tool $RESEARCH_COMPLEXITY times using exported variables:
- Iteration 1: Use RESEARCH_TOPIC_1, REPORT_PATH_FOR_AGENT_1
- Iteration 2: Use RESEARCH_TOPIC_2, REPORT_PATH_FOR_AGENT_2
...
```

**Problem**: Still requires Claude to interpret "invoke N times", doesn't solve iteration control.

**Approach B: Explicit Enumeration** (Working Constraint)

Since markdown can't programmatically loop, explicitly enumerate all possible invocations with conditional execution:

```bash
# Bash block: Calculate complexity and export
echo "Research Complexity: $RESEARCH_COMPLEXITY"
export RESEARCH_COMPLEXITY
```

Then markdown:
```markdown
**IF RESEARCH_COMPLEXITY >= 1**: Invoke agent 1
Task { ... prompt with REPORT_PATH_0 ... }

**IF RESEARCH_COMPLEXITY >= 2**: Invoke agent 2
Task { ... prompt with REPORT_PATH_1 ... }

**IF RESEARCH_COMPLEXITY >= 3**: Invoke agent 3
Task { ... prompt with REPORT_PATH_2 ... }

**IF RESEARCH_COMPLEXITY >= 4**: Invoke agent 4
Task { ... prompt with REPORT_PATH_3 ... }
```

**Advantage**: Explicit control, Claude evaluates conditionals
**Disadvantage**: Verbose, max 4 topics hardcoded

**Approach C: Unified Agent Invocation** (Simpler Alternative)

Invoke a **single coordinator subagent** that receives RESEARCH_COMPLEXITY and internally loops:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Coordinate flat research with explicit loop control"
  prompt: "
    You will invoke $RESEARCH_COMPLEXITY research-specialist agents.

    Use a bash loop:
    for i in 1 2 ... $RESEARCH_COMPLEXITY; do
      # Invoke Task tool for each agent
    done
  "
}
```

**Advantage**: Single invocation, subagent handles looping
**Disadvantage**: Adds one level of indirection

### 7. Examining Existing Verification Pattern

**Verification Loop Works** (coordinate.md:681-686):
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Research"; then
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
```

**Why This Works**: Verification is a **bash function** (verify_file_created), not a Task tool invocation. Bash loops can call bash functions, but cannot loop Task invocations.

**Key Insight**: The plan's comparison to verification loops (lines 102-105) is valid for **demonstrating explicit iteration**, but the implementation mechanism differs (bash function vs Claude Code Task tool).

### 8. Plan Phase 1 Feasibility Assessment

**Plan Phase 1 Tasks** (Lines 135-216):

Task: "Replace natural language section (lines 466-491) with bash block containing explicit loop"

**Feasibility**: PARTIALLY FEASIBLE

- ✓ Can add bash block with explicit loop calculating variables
- ✗ Cannot place Task invocations inside bash block
- ⚠ Must revise to accommodate markdown/bash separation

**Implementation Reality Check**:

Plan shows (lines 150-187):
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  # Variable calculation ✓
  RESEARCH_TOPIC="Topic $i"
  REPORT_PATH="${!REPORT_PATH_VAR}"

  # Task invocation ✗ (must be outside bash)
  Task { ... }
done
```

Must be restructured as:
```bash
# Bash: Calculate all variables upfront
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  eval "RESEARCH_TOPIC_${i}='Topic ${i}'"
  eval "AGENT_REPORT_PATH_${i}='${REPORT_PATHS[$((i-1))]}'"
done
```

Then markdown section with explicit enumeration (Approach B).

### 9. Root Cause Implications for Fix

**Original Problem**: Natural language template causes Claude to invoke 4 agents instead of 2.

**Why Template Exists**: Cannot use bash loop for Task invocations due to architectural constraint.

**Real Fix Needed**: Replace natural language template with **explicit conditional enumeration** (Approach B) or **single coordinator subagent** (Approach C).

**Plan's Proposed Fix**: Technically correct in principle (explicit iteration control) but implementation details need revision to accommodate architectural constraints.

### 10. Phase 0 Pre-Allocation Analysis

**Plan Correctly Preserves Phase 0** (Lines 98-101):

> "Preserve Phase 0 Pre-Allocation: REPORT_PATHS_COUNT=4 remains hardcoded (max capacity design)"

**Cross-Reference with 001_hardcoded_report_paths_count_analysis.md**:

From investigation report (lines 83-94):
> "Design trade-off: Pre-allocate maximum paths (4) upfront, accept minor memory overhead for unused paths"
> "Impact: Positive: Massive performance improvement (25x speedup, 85% token reduction)"

**Verdict**: Plan's decision to preserve Phase 0 optimization is architecturally sound. The issue is not pre-allocation but lack of iteration control during invocation.

## Recommendations

### 1. Revise Plan Phase 1 Implementation Strategy

**Current Plan**: Lines 135-147 propose replacing natural language with bash block containing Task invocations.

**Revised Approach**: Split into two components:
1. **Bash Block**: Prepare all iteration variables (Topic names, Report paths, Diagnostic output)
2. **Markdown Section**: Explicit conditional enumeration of Task invocations (Approach B)

**Justification**: Accommodates architectural constraint that Task invocations must be in markdown, not bash.

### 2. Use Explicit Conditional Enumeration Pattern

**Pattern**: Enumerate all 4 possible invocations with conditional execution guards.

**Example**:
```markdown
**EXECUTE CONDITIONALLY**: Based on RESEARCH_COMPLEXITY value:

**IF RESEARCH_COMPLEXITY >= 1** (always true):
Task { prompt: "Research Topic 1 at $REPORT_PATH_0" }

**IF RESEARCH_COMPLEXITY >= 2** (true for complexity 2-4):
Task { prompt: "Research Topic 2 at $REPORT_PATH_1" }

**IF RESEARCH_COMPLEXITY >= 3** (true for complexity 3-4):
Task { prompt: "Research Topic 3 at $REPORT_PATH_2" }

**IF RESEARCH_COMPLEXITY >= 4** (true for complexity 4 only):
Task { prompt: "Research Topic 4 at $REPORT_PATH_3" }
```

**Advantages**:
- ✓ Explicit control over invocation count
- ✓ No ambiguity in Claude's interpretation
- ✓ Matches architectural pattern (Task in markdown)
- ✓ Preserves Phase 0 optimization

**Disadvantages**:
- Verbose (4 separate Task blocks)
- Hardcoded maximum (cannot exceed 4 topics)

### 3. Alternative: Single Coordinator Subagent

**Pattern**: Invoke one subagent that internally handles loop iteration.

**Implementation**:
```markdown
**EXECUTE NOW**: Invoke flat-research-coordinator subagent:

Task {
  subagent_type: "general-purpose"
  description: "Coordinate flat research with $RESEARCH_COMPLEXITY agents"
  prompt: "
    You are the flat-research-coordinator.

    Invoke $RESEARCH_COMPLEXITY research-specialist agents using explicit bash loop:

    for i in $(seq 1 $RESEARCH_COMPLEXITY); do
      Task {
        prompt: 'Research topic $i at $REPORT_PATH_$((i-1))'
      }
    done
  "
}
```

**Advantages**:
- ✓ Single invocation point
- ✓ Subagent can use bash loop for Task invocations
- ✓ Clean separation of concerns

**Disadvantages**:
- Adds one level of indirection (coordinator → specialists)
- Increases complexity (new agent file required)

### 4. Update Plan Documentation with Architectural Constraints

**Add Section to Plan** (After Technical Design):

```markdown
## Architectural Constraints

### Task Invocation Limitation
Task tool invocations cannot be placed inside bash blocks due to behavioral injection pattern (Standard 11). Task invocations must occur in markdown sections between bash blocks.

### Implementation Implications
1. Bash blocks: Calculate iteration variables, prepare context
2. Markdown sections: Explicit Task invocations (conditional enumeration or coordinator)
3. Cannot programmatically loop Task invocations from bash

### Comparison with Verification Loop
Verification loop (line 681) uses bash function verify_file_created(), which CAN be called from bash loop. Task tool is Claude Code feature, not bash command, requiring different approach.
```

### 5. Revise Phase 1 Tasks with Implementation Reality

**Current Task** (Plan line 145):
> "Replace natural language section (lines 466-491) with bash block containing explicit loop"

**Revised Task**:
> "Replace natural language section (lines 466-491) with:
> 1. Bash block: Calculate iteration variables with explicit loop
> 2. Markdown section: Conditional enumeration of Task invocations (4 blocks with IF guards)"

### 6. Add Testing for Edge Cases

**Current Plan Testing** (Lines 232-279): Covers RESEARCH_COMPLEXITY 1-4.

**Additional Test Cases**:
1. **Conditional Evaluation**: Verify IF guards work correctly
   - RESEARCH_COMPLEXITY=2 should invoke agents 1-2 only (not 3-4)
   - RESEARCH_COMPLEXITY=4 should invoke all 4 agents

2. **State Persistence**: Verify RESEARCH_COMPLEXITY loads correctly from state file
   - Test across bash block boundaries

3. **Backward Compatibility**: Ensure hierarchical research (>=4 topics) still works
   - Hierarchical path (lines 440-464) uses different mechanism

## Conclusion

The existing plan (001_fix_coordinate_agent_invocation_loop.md) **correctly identifies the root cause** (lack of explicit loop control in natural language template) and **proposes a valid solution direction** (explicit bash loop for iteration). However, the implementation must be revised to accommodate the **critical architectural constraint** that Task tool invocations cannot occur inside bash blocks in the coordinate.md command structure.

**Core Issue**: The plan shows Task invocations inside bash loops (lines 165-187), but coordinate.md architecture requires Task invocations in markdown sections between bash blocks, not within them.

**Recommended Revision**: Use explicit conditional enumeration pattern (Approach B) or single coordinator subagent (Approach C) to achieve explicit iteration control while respecting architectural constraints.

**Plan Accuracy**: 85% - Root cause correct, solution direction correct, implementation details need architectural adjustment.

**Next Steps**:
1. Revise plan Phase 1 to split bash (variable preparation) from markdown (conditional Task invocations)
2. Choose between explicit enumeration (simple, verbose) or coordinator subagent (cleaner, more complex)
3. Update testing strategy to cover conditional execution guards
4. Document architectural constraint in plan's Technical Design section

## Cross-References

### Related Investigation Reports
- [OVERVIEW.md](./001_agent_mismatch_investigation/OVERVIEW.md) - Complete root cause analysis, validates plan's diagnosis
- [002_agent_invocation_template_interpretation.md](./001_agent_mismatch_investigation/002_agent_invocation_template_interpretation.md) - Claude's template resolution process
- [003_loop_count_determination_logic.md](./001_agent_mismatch_investigation/003_loop_count_determination_logic.md) - Variable controlling iteration count

### Plan Being Analyzed
- [001_fix_coordinate_agent_invocation_loop.md](../plans/001_fix_coordinate_agent_invocation_loop.md) - Implementation plan with proposed fix

### Architectural Documentation
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md) - Standard 11 (Task invocations in markdown)
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation constraints
- [Phase 0 Optimization Guide](.claude/docs/guides/phase-0-optimization.md) - Pre-calculation strategy rationale

## References

### Source Files Analyzed
1. `/home/benjamin/.config/.claude/commands/coordinate.md:340-596` - Full research phase structure (bash blocks and Task invocations)
2. `/home/benjamin/.config/.claude/commands/coordinate.md:681-723` - Verification loop (bash function pattern)
3. `/home/benjamin/.config/.claude/agents/research-specialist.md:1-100` - Research agent behavioral guidelines
4. `/home/benjamin/.config/.claude/specs/676_coordinate_research_agent_mismatch/plans/001_fix_coordinate_agent_invocation_loop.md:1-599` - Complete plan

### Key Architectural Patterns
1. **Behavioral Injection** - Agent invocation via Task tool with behavioral file reference (markdown, not bash)
2. **Subprocess Isolation** - Bash blocks run independently, require state persistence
3. **Verification Fallback** - Bash loops work for bash functions, not Task invocations
4. **Phase 0 Optimization** - Pre-calculate paths for performance (85% token reduction)

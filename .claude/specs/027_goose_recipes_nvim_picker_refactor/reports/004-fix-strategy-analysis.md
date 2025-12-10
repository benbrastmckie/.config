---
report_type: pattern_recognition
topic: "Fix Strategy Analysis for Research Coordinator Pseudo-Code Issue"
findings_count: 4
recommendations_count: 4
---

# Fix Strategy Analysis for Research Coordinator Pseudo-Code Issue

## Metadata
- **Date**: 2025-12-10
- **Agent**: research-specialist
- **Topic**: Fix Strategy Analysis for Research Coordinator Pseudo-Code Issue
- **Report Type**: pattern recognition

## Research Objective

Synthesize findings and develop fix strategy for the research-coordinator.md pseudo-code issue where agent files cannot invoke Task tool (only primary orchestrating agent can).

## Executive Summary

The research-coordinator.md file contains an architectural violation where it attempts to use the Task tool to invoke research-specialist agents. Agents invoked via Task tool cannot themselves invoke Task tool - only the primary orchestrating agent (command) has that capability. Three fix strategies were evaluated: (A) move Task invocations to primary agent, (B) hybrid instruction-based coordination, or (C) eliminate coordinator entirely. **Option A is recommended** as it provides the simplest, standards-compliant solution that aligns with existing patterns in hierarchical-agents-examples.md Example 1.

## Problem Analysis

### Core Issue

**Agent files cannot invoke Task tool.** When a command uses the Task tool to invoke an agent, that agent CANNOT use the Task tool itself. Task tool invocation is reserved for the primary orchestrating agent only.

From research-coordinator.md STEP 3 (lines 333-423):
- Contains Bash script that generates Task invocation patterns
- Includes `**EXECUTE NOW**` directives followed by `Task { ... }` blocks
- This creates appearance that agent should invoke Task tool
- But agent CANNOT actually invoke Task tool

### Evidence from Existing Agents

**1. plan-architect.md** (Lines 1-1341):
- NO Task tool invocations present
- Uses only: Read, Write, Edit, Grep, Glob, WebSearch, Bash
- Allowed-tools frontmatter (line 2): `Read, Write, Edit, Grep, Glob, WebSearch, Bash`
- Does NOT include Task tool

**2. research-specialist.md** (Lines 1-908):
- NO Task tool invocations present
- Uses only: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
- Allowed-tools frontmatter (line 2): `Read, Write, Grep, Glob, WebSearch, WebFetch, Bash`
- Does NOT include Task tool

**3. research-coordinator.md** (Lines 1-1190):
- **VIOLATION**: Allowed-tools frontmatter (line 2): `Task, Read, Bash, Grep`
- Contains Task invocation pseudo-code in STEP 3
- But as an agent invoked via Task tool, it CANNOT use Task tool

### Hierarchical Agent Architecture Constraints

From hierarchical-agents-overview.md (lines 1-177):
- Hierarchy structure: Orchestrator -> Supervisor -> Workers
- Communication flow (lines 74-80):
  - Command -> Orchestrator (primary agent)
  - Orchestrator -> Supervisor (via Task tool)
  - Supervisor -> Workers (via Task tool) ← **THIS IS THE PROBLEM**

The architecture documentation shows "Supervisor -> Workers" using Task tool, but this is architecturally impossible if Supervisor is itself an agent invoked via Task tool.

## Fix Strategy Options

### Option A: Move Task Invocations to Primary Agent (RECOMMENDED)

**Description**: Remove Task invocations from research-coordinator.md and have the primary agent (command) perform all Task invocations directly.

**Implementation Pattern** (from hierarchical-agents-examples.md Example 1):
```markdown
## In /research command (primary agent):

# Pre-calculate paths
REPORT_PATHS["auth"]="${TOPIC_DIR}/reports/001_authentication.md"
REPORT_PATHS["errors"]="${TOPIC_DIR}/reports/002_error_handling.md"

# Command invokes research-specialist directly for each topic
Task {
  description: "Research authentication patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Authentication patterns
    Output: ${REPORT_PATHS["auth"]}
}

Task {
  description: "Research error handling"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Error handling best practices
    Output: ${REPORT_PATHS["errors"]}
}
```

**Advantages**:
- Standards-compliant (only primary agent uses Task tool)
- Matches Example 1 pattern in hierarchical-agents-examples.md
- Simple, direct invocation
- No intermediate coordination layer

**Disadvantages**:
- Loses 95% context reduction benefit of coordinator pattern
- Command blocks grow larger with multiple Task invocations
- No metadata aggregation layer

**Impact**:
- research-coordinator.md: Remove allowed-tools: Task, remove STEP 3 Task invocations
- /research command: Add direct Task invocations for each topic
- /lean-plan command: Add direct Task invocations for each topic
- /create-plan command: Add direct Task invocations for each topic

### Option B: Coordinator Returns Invocation Instructions (HYBRID)

**Description**: Coordinator agent does NOT invoke Task tool, but instead returns structured invocation instructions that the primary agent executes.

**Implementation Pattern**:
```markdown
## In research-coordinator.md:

### STEP 3: Generate Invocation Instructions (NOT Task invocations)

Return structured invocation plan:

INVOCATION_PLAN:
topics_count: 3
invocations: [
  {
    "topic": "Mathlib Theorems",
    "report_path": "/path/001-mathlib.md",
    "description": "Research Mathlib theorems"
  },
  {
    "topic": "Proof Automation",
    "report_path": "/path/002-automation.md",
    "description": "Research proof automation"
  }
]

## In /research command (after coordinator returns):

# Parse INVOCATION_PLAN from coordinator output
# Execute Task invocations based on plan
for invocation in $(parse_invocation_plan); do
  Task {
    description: $invocation.description
    prompt: |
      Read and follow: research-specialist.md
      Topic: $invocation.topic
      Output: $invocation.report_path
  }
done
```

**Advantages**:
- Maintains coordinator role for topic decomposition
- Preserves standards compliance (only primary agent uses Task)
- Coordinator can still perform path pre-calculation
- Flexible routing logic in coordinator

**Disadvantages**:
- Two-phase execution (coordinator generates plan, command executes)
- Adds complexity to command parsing
- Still requires command to handle Task invocations

**Impact**:
- research-coordinator.md: Change STEP 3 to return invocation plan (not execute Task)
- Commands: Add invocation plan parsing and Task execution loop

### Option C: Eliminate Coordinator Entirely (SIMPLIFICATION)

**Description**: Remove research-coordinator.md completely. Commands perform topic decomposition and invoke research-specialist directly.

**Implementation Pattern**:
```bash
## In /research command:

# Decompose topics inline
decompose_topics() {
  local workflow_desc="$1"
  # Logic to split topics (currently in coordinator)
  echo "topic1|topic2|topic3"
}

TOPICS=$(decompose_topics "$WORKFLOW_DESCRIPTION")

# Invoke research-specialist for each topic
for topic in $(echo "$TOPICS" | tr '|' ' '); do
  REPORT_PATH="${TOPIC_DIR}/reports/$(next_report_num)-${topic}.md"

  Task {
    description: "Research $topic"
    prompt: |
      Read and follow: research-specialist.md
      Topic: $topic
      Output: $REPORT_PATH
  }
done
```

**Advantages**:
- Simplest architecture (no intermediate layer)
- All Task invocations clearly in primary agent
- No behavioral file ambiguity
- Easier to understand and maintain

**Disadvantages**:
- Loses coordinator abstraction benefits
- Duplicates topic decomposition logic across commands
- No reusable coordination patterns
- Commands become longer and more complex

**Impact**:
- research-coordinator.md: Delete file
- Commands: Add topic decomposition logic inline
- Documentation: Update hierarchical agent examples

## Comparison Matrix

| Criterion | Option A (Direct) | Option B (Hybrid) | Option C (No Coordinator) |
|-----------|-------------------|-------------------|---------------------------|
| Standards Compliance | ✓ | ✓ | ✓ |
| Context Reduction | ✗ (loses 95%) | ✗ (loses 95%) | ✗ (loses 95%) |
| Coordinator Role | Eliminated | Topic planning only | Eliminated |
| Command Complexity | Moderate | High | Moderate |
| Maintainability | Good | Poor | Good |
| Reusability | Poor | Moderate | Poor |

## Recommended Solution

**Option A (Move Task Invocations to Primary Agent)** is recommended because:

1. **Standards Compliance**: Fully aligns with architectural constraint that only primary agents invoke Task tool
2. **Clear Precedent**: Matches Example 1 in hierarchical-agents-examples.md exactly
3. **Simple Implementation**: Straightforward refactoring with clear boundaries
4. **Maintainability**: No ambiguous agent responsibilities

**Trade-off Acceptance**: Accept loss of 95% context reduction in exchange for architectural correctness. For commands with 3-4 research topics, the context cost (3-4 x 2,500 tokens = 7,500-10,000 tokens) is acceptable within 200k context window.

**Implementation Steps**:
1. Remove allowed-tools: Task from research-coordinator.md frontmatter
2. Replace STEP 3 Task invocations with "return invocation metadata" pattern
3. Update /research, /lean-plan, /create-plan commands to invoke research-specialist directly
4. Update hierarchical-agents-examples.md to clarify supervisor limitations
5. Add warning to hierarchical-agents-patterns.md about Task tool constraint

## Alternative Consideration: Is There a Valid Supervisor Pattern?

**Question**: Can a supervisor agent coordinate workers WITHOUT using Task tool?

**Answer**: NO, not in the current architecture. The only way for agents to invoke other agents is via the Task tool, which is restricted to primary orchestrating agents.

**Architectural Constraint**: The hierarchical agent architecture has a hard limitation:
- **Primary Agent** (command): CAN invoke Task tool → agents
- **Supervisor Agent** (invoked via Task): CANNOT invoke Task tool → workers
- **Worker Agent** (invoked via Task): CANNOT invoke Task tool

This means the "Supervisor -> Workers" pattern shown in hierarchical-agents-overview.md (lines 22-33) is architecturally impossible unless the supervisor is the primary agent (not invoked via Task tool itself).

**Documentation Fix Required**: The hierarchical-agents-overview.md and hierarchical-agents-examples.md Example 2 show invalid supervisor patterns that imply agents can invoke Task tool. These examples must be corrected to show either:
1. Primary agent invoking workers directly (no supervisor layer), OR
2. Supervisor returning invocation instructions for primary agent to execute

## References

### Files Analyzed

1. `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-1341)
   - Evidence: No Task tool invocations, allowed-tools does not include Task
   - Relevance: Confirms agent pattern compliance

2. `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-908)
   - Evidence: No Task tool invocations, allowed-tools does not include Task
   - Relevance: Confirms agent pattern compliance

3. `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 1-1190)
   - Evidence: VIOLATION - allowed-tools includes Task, STEP 3 contains Task invocation pseudo-code
   - Relevance: Identifies architectural violation

4. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (lines 1-177)
   - Evidence: Shows "Supervisor -> Workers (via Task tool)" pattern (lines 74-80)
   - Relevance: Documentation shows architecturally impossible pattern

5. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 1-300)
   - Evidence: Example 1 shows primary agent invoking workers directly (correct), Example 2 shows supervisor invoking Task tool (incorrect)
   - Relevance: Mixed examples create confusion about valid patterns

6. `/home/benjamin/.config/.claude/commands/research.md` (lines 1-627)
   - Evidence: Primary agent (/research command) invokes research-coordinator or research-specialist via Task tool
   - Relevance: Shows correct primary agent pattern

### External Sources

None (internal architectural analysis only)

## Findings Summary

| Finding | Description | Impact |
|---------|-------------|--------|
| **F1**: Task tool constraint | Agents invoked via Task tool cannot invoke Task tool themselves | Architectural limitation |
| **F2**: research-coordinator violation | Contains Task invocations it cannot execute | Invalid agent pattern |
| **F3**: Documentation inconsistency | Examples show impossible supervisor patterns | Developer confusion |
| **F4**: Three valid fix options | Direct invocation, hybrid instructions, or no coordinator | Implementation choices |

## Next Actions

1. **Immediate**: Implement Option A (recommended) to fix research-coordinator.md
2. **Documentation**: Update hierarchical-agents-*.md files to clarify Task tool constraints
3. **Validation**: Add linter check to detect Task tool in agent allowed-tools when inappropriate
4. **Testing**: Verify refactored commands work correctly with direct research-specialist invocation

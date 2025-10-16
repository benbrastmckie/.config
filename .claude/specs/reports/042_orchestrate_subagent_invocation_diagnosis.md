# Orchestrate Command Subagent Invocation Diagnosis

## Metadata
- **Date**: 2025-10-12
- **Report Number**: 042
- **Topic**: orchestrate_diagnosis
- **Created By**: Manual Analysis
- **Issue**: /orchestrate not invoking subagents for research, planning, or implementation

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [042_orchestrate_command_execution_refactor.md](../../plans/042_orchestrate_command_execution_refactor.md)
- **Implementation**: Pending
- **Date**: 2025-10-12

## Problem Statement

When `/orchestrate` is invoked, it fails to call subagents for:
1. **Research Phase**: No research-specialist agents invoked to create report files
2. **Planning Phase**: No plan-architect agent invoked to create implementation plans  
3. **Implementation Phase**: No code-writer agent invoked to execute plans
4. **Debugging Phase**: No debug-specialist agent invoked for failures
5. **Documentation Phase**: No doc-writer agent invoked for updates

Instead, the orchestrator appears to be executing these tasks directly rather than delegating to specialized subagents.

## Root Cause Analysis

### Issue 1: Documentation-Only Command File

**Location**: `.claude/commands/orchestrate.md` (1953 lines)

**Problem**: The entire file is **documentation/specification** rather than **executable instructions**.

**Evidence**:
- Line 11: "I'll coordinate multiple specialized subagents..."
- Line 150: "#### Step 2: Launch Parallel Research Agents"
- Line 152: "For each identified research topic, I'll create a focused research task..."

**Analysis**:
- The file describes HOW the orchestrator SHOULD work
- It does NOT contain explicit instructions to USE the Task tool
- Claude Code reads this as a prompt but doesn't have clear action steps
- The phrase "I'll" is aspirational, not imperative

### Issue 2: Missing Explicit Task Tool Invocations

**Expected Pattern** (from documentation):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research existing patterns using research-specialist protocol"
  prompt: "[Generated research prompt]"
}
```

**Actual Pattern** (in command file):
```markdown
"For each identified research topic, I'll create a focused research task and invoke agents in parallel."

"See [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation) for detailed patterns."
```

**Analysis**:
- Command file REFERENCES how to invoke agents
- Command file does NOT explicitly INSTRUCT Claude to invoke agents
- Links to external documentation instead of inline execution steps

### Issue 3: Lack of Imperative Execution Steps

**Current Structure**:
```markdown
### Research Phase (Parallel Execution)
#### Step 1: Identify Research Topics
I'll analyze the workflow description...

#### Step 2: Launch Parallel Research Agents  
For each identified research topic, I'll create...
```

**Required Structure**:
```markdown
### Research Phase (Parallel Execution)
#### Step 1: Identify Research Topics
**EXECUTE**: Analyze the workflow description and extract 2-4 research topics.

#### Step 2: Launch Parallel Research Agents
**EXECUTE**: Use the Task tool to invoke research-specialist agents in parallel.

For each research topic identified:
1. Generate the research prompt from template (Step 3)
2. Use Task tool with subagent_type: general-purpose
3. Include behavioral injection to research-specialist.md agent
4. Collect report file paths from agent output
```

**Key Difference**:
- Current: Describes what should happen ("I'll create...")
- Required: Commands what must be done ("EXECUTE: Use the Task tool...")

### Issue 4: No Clear "Now Do This" Instructions

**Problem**: The command reads like a **design document** rather than **executable instructions**.

**Example from Planning Phase** (lines 507-520):
```
#### Step 3: Invoke Planning Agent

**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Create implementation plan for [feature] using plan-architect protocol"
prompt: "Read and follow the behavioral guidelines from:
         /home/benjamin/.config/.claude/agents/plan-architect.md
         ...
         [Generated planning prompt from Step 2]"
```

**Analysis**:
- Shows a YAML example of what the invocation should look like
- Does NOT say "Now use the Task tool with these parameters"
- Claude Code interprets this as reference material, not as an instruction to act

## Proposed Solutions

### Solution 1: Add Explicit Execution Blocks

**Pattern**: After each step description, add an explicit "EXECUTE NOW" block.

**Example**:
```markdown
#### Step 2: Launch Parallel Research Agents

[Documentation about what this step does...]

**EXECUTE NOW:**
Use the Task tool to invoke research-specialist agents in parallel. For each research topic you identified in Step 1, create a Task invocation using the template from Step 3.

Required actions:
1. Generate research prompt for each topic using template in Step 3
2. Invoke Task tool for each topic in a single message (parallel execution)
3. Wait for all agents to complete
4. Extract report file paths from agent outputs
5. Proceed to Step 4
```

### Solution 2: Replace "I'll" with Imperatives

**Pattern**: Change all passive descriptions to active commands.

**Examples**:
- ❌ "I'll analyze the workflow description to extract topics"
- ✅ "ANALYZE the workflow description to extract topics"

- ❌ "I'll invoke research-specialist agents in parallel"
- ✅ "INVOKE research-specialist agents in parallel using the Task tool"

- ❌ "For each identified research topic, I'll create a focused research task"
- ✅ "For each identified research topic, CREATE a focused research task and INVOKE it using Task tool"

### Solution 3: Inline Critical Tool Usage

**Pattern**: Instead of referencing external patterns, inline the actual tool invocation syntax.

**Current** (line 154):
```markdown
See [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation) for detailed patterns.
```

**Proposed**:
```markdown
INVOKE Task tool with the following structure for EACH research topic:

Task tool invocation:
- subagent_type: general-purpose
- description: "Research [topic] using research-specialist protocol"  
- prompt: "[Use template from Step 3, filled with this topic's details]"

Send all research task invocations in a SINGLE MESSAGE for parallel execution.
```

### Solution 4: Add Execution Checklist

**Pattern**: At the end of each major phase, add a checklist to verify execution.

**Example**:
```markdown
#### Research Phase Execution Checklist

Before proceeding to Planning Phase, verify:
- [ ] Research topics extracted from workflow description
- [ ] Task tool invoked for each research topic (in parallel)
- [ ] Report file paths extracted from each agent output
- [ ] All report files exist and are readable
- [ ] Research checkpoint saved

If any checkbox is unchecked, STOP and complete missing steps.
```

## Recommended Implementation Plan

### Phase 1: Add Execution Blocks to All Steps
1. Search for all "#### Step N:" headers
2. After each step description, add "**EXECUTE NOW:**" block
3. Provide explicit tool invocation instructions

### Phase 2: Convert Passive to Active Voice
1. Replace all "I'll [verb]" with "[VERB]"
2. Replace all "For each X, I'll Y" with "For each X, [VERB] Y"
3. Emphasize direct commands over descriptions

### Phase 3: Inline Critical Tool Usage
1. Identify all references to external patterns
2. Inline the essential syntax for Task tool invocations
3. Keep reference links but don't rely on them for execution

### Phase 4: Add Execution Checklists
1. At end of each major phase, add verification checklist
2. Require explicit confirmation before proceeding
3. Catch missing subagent invocations before they cascade

## Testing Strategy

### Test Case 1: Simple Workflow
```
/orchestrate Add a simple hello world function
```

**Expected Behavior**:
- Skip research (simple task)
- Invoke plan-architect agent → creates plan file
- Invoke code-writer agent → implements plan
- Invoke doc-writer agent → updates docs

**Success Criteria**:
- 3 Task tool invocations visible in output
- 3 agents complete their work
- Files created: plan, code, updated docs

### Test Case 2: Complex Workflow (from user's example)
```
/orchestrate use /document to revise the README.md files in agents/,
commands/, and lib/. Once this is complete, research the documentation  
in /home/benjamin/.config/.claude/docs/ in order to design and
implement a plan to systematically refactor this documentation to be
clear, concise, and well organized/consolidated
```

**Expected Behavior**:
- Invoke doc-writer agent → updates README files in 3 directories
- Invoke 2-3 research-specialist agents in parallel → research docs structure
- Invoke plan-architect agent → creates refactoring plan
- Invoke code-writer agent → executes refactoring
- Invoke doc-writer agent → final documentation

**Success Criteria**:
- 7+ Task tool invocations visible in output
- Research reports created in specs/reports/
- Implementation plan created in specs/plans/
- READMEs updated
- Docs refactored

## Impact Analysis

### Current State
- /orchestrate executes tasks directly instead of delegating
- No agent specialization leveraged
- No parallel research execution
- No separation of concerns
- Workflow appears to work but misses the entire multi-agent architecture

### After Fix
- /orchestrate delegates all major tasks to specialized agents
- Research agents run in parallel (time savings)
- Each agent focused on its specialty
- Clear separation of concerns
- Proper multi-agent orchestration workflow

## Notes

### Why This Matters

The current implementation defeats the purpose of the orchestrate command:
1. **No specialization**: Each agent has specific tools and behavioral guidelines
2. **No parallelization**: Research should run multiple agents concurrently
3. **No context isolation**: Subagents should receive focused prompts, not full orchestrator context
4. **No behavioral injection**: Agents should read their protocol files for guidance

### Alignment with Project Philosophy

The fix aligns with:
- **Clean, clear documentation**: Explicit instructions over aspirational descriptions
- **System coherence**: Orchestrator delegates, agents execute
- **Maintainability**: Clear execution path makes debugging easier

## Revision History

### 2025-10-12 - Initial Diagnosis
Created comprehensive analysis of why /orchestrate isn't invoking subagents.
Identified root causes and proposed solutions.

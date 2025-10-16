# Phase 1: Orchestrate Command Transformation Checklist

## Analysis Summary

**Date**: 2025-10-12
**Source File**: `.claude/commands/orchestrate.md`
**Lines**: 1953
**Backup**: `.claude/commands/orchestrate.md.backup`

### Passive Voice Analysis
- **Total "I'll" instances**: 8
- **Distribution**: Mostly in early sections (lines 11, 27, 35, 51, 89, 152, 1884, 1895)
- **Assessment**: Less pervasive than initially expected, but key transformation points exist

### External References Analysis
- **Total references**: 6
- **Target**: `../docs/command-patterns.md`
- **Locations**:
  1. Line 154: Parallel Agent Invocation pattern
  2. Line 286: Progress Marker Detection pattern
  3. Line 307: Save Checkpoint After Phase pattern
  4. Line 847: Test Failure Handling pattern (reference without See)
  5. Line 1651: Error Recovery Patterns
  6. Line 1663: Checkpoint Management Patterns
  7. Line 1684: User Escalation Format pattern

### Major Sections Map

**Metadata & Overview** (Lines 1-12)
- Line 1-7: YAML frontmatter
- Line 9: Title
- Line 11: Description (contains "I'll")

**Workflow Analysis** (Lines 13-82)
- Line 13-24: Workflow Analysis intro
- Line 17-22: Shared Utilities Integration
- Line 25-32: Step 1: Parse Workflow Description
- Line 33-47: Step 2: Identify Workflow Phases
- Line 49-81: Step 3: Initialize Workflow State

**Phase Coordination** (Lines 83-1600)
- **Research Phase** (Lines 85-368)
  - Line 87-148: Step 1: Identify Research Topics
  - Line 122-148: Step 1.5: Determine Thinking Mode
  - Line 150-162: Step 2: Launch Parallel Research Agents
  - Line 163-248: Step 3: Research Agent Prompt Template
  - Line 249-284: Step 3.5: Generate Project Name
  - Line 285-304: Step 4: Collect Report Paths (Progress Streaming)
  - Line 305-324: Step 5: Save Research Checkpoint
  - Line 325-335: Step 6: Report File Validation
  - Line 336-368: Research Phase Execution Example

- **Planning Phase** (Lines 370-593)
  - Line 372-401: Step 1: Prepare Planning Context
  - Line 402-505: Step 2: Generate Planning Agent Prompt
  - Line 507-527: Step 3: Invoke Planning Agent
  - Line 535-556: Step 4: Extract Plan Path and Validation
  - Line 558-579: Step 5: Save Planning Checkpoint
  - Line 581-593: Step 6: Planning Phase Completion

- **Implementation Phase** (Lines 594-844)
  - Line 596-620: Step 1: Prepare Implementation Context
  - Line 621-712: Step 2: Generate Implementation Agent Prompt
  - Line 713-736: Step 3: Invoke Implementation Agent
  - Line 737-764: Step 4: Extract Implementation Status
  - Line 765-779: Step 5: Conditional Branch
  - Line 781-816: Step 6: Save Implementation Checkpoint
  - Line 817-844: Step 7: Implementation Phase Completion

- **Debugging Loop** (Lines 845-1137)
  - Line 851-875: Step 1: Generate Debug Topic Slug
  - Line 877-929: Step 2: Invoke Debug Specialist Agent
  - Line 930-954: Step 3: Extract Debug Report Path
  - Line 955-992: Step 4: Apply Recommended Fix
  - Line 993-1012: Step 5: Run Tests Again
  - Line 1013-1039: Step 6: Decision Logic
  - Line 1040-1071: Step 7: Update Workflow State
  - Line 1072-1114: Step 8: Save Debug Checkpoint
  - Line 1115-1137: Debugging Loop Example

- **Documentation Phase** (Lines 1138-1600)
  - Line 1142-1175: Step 1: Prepare Documentation Context
  - Line 1176-1199: Step 2-4: Documentation Agent Invocation
  - Line 1200-1222: Step 3: Invoke Documentation Agent
  - Line 1223-1240: Step 4: Extract Documentation Results
  - Line 1241-1387: Step 5: Generate Workflow Summary
  - Line 1388-1417: Step 6: Create Summary File
  - Line 1418-1445: Step 7: Save Final Checkpoint
  - Line 1446-1538: Step 8: Create Pull Request
  - Line 1539-1600: Step 9: Workflow Completion Message

**Supporting Sections** (Lines 1601-1953)
- Line 1602-1661: Context Management Strategy
- Line 1662-1710: Error Recovery Mechanism
- Line 1711-1742: Performance Monitoring
- Line 1743-1836: Execution Flow & Usage Examples
- Line 1837-1880: Agent Usage (already well documented)
- Line 1881-1953: Checkpoint Detection and Resume

## Transformation Points by Category

### Category 1: Passive Voice Conversion (8 instances)

| Line | Current Text | Target Text | Priority |
|------|--------------|-------------|----------|
| 11 | "I'll coordinate..." | "**EXECUTE**: COORDINATE specialized subagents..." | HIGH |
| 27 | "I'll extract:" | "EXTRACT the following:" | MEDIUM |
| 35 | "I'll determine..." | "DETERMINE which phases are needed:" | MEDIUM |
| 51 | "I'll create minimal..." | "CREATE minimal orchestrator state:" | MEDIUM |
| 89 | "I'll analyze..." | "ANALYZE the workflow description to extract..." | HIGH |
| 152 | "I'll create a focused..." | "CREATE a focused research task and INVOKE..." | HIGH |
| 1884 | "I'll check for..." | "CHECK for existing checkpoints..." | LOW |
| 1895 | "I'll present..." | "PRESENT interactive options:" | LOW |

### Category 2: External Pattern References (6+ locations)

| Line | Reference | Inline Requirement | Priority |
|------|-----------|-------------------|----------|
| 154 | Parallel Agent Invocation | Full Task tool syntax with example | CRITICAL |
| 286 | Progress Marker Detection | Progress marker format and examples | MEDIUM |
| 307 | Save Checkpoint After Phase | Checkpoint utility usage | MEDIUM |
| 847 | Test Failure Handling | Brief reference, less critical | LOW |
| 1651 | Error Recovery Patterns | Error classification table | MEDIUM |
| 1663 | Checkpoint Management | Checkpoint patterns | MEDIUM |
| 1684 | User Escalation Format | Escalation message template | MEDIUM |

### Category 3: Missing EXECUTE NOW Blocks (Major Steps)

**Research Phase** (6 steps need EXECUTE NOW blocks):
- [ ] Step 1: Identify Research Topics (Line 87) - Add EXECUTE NOW block
- [ ] Step 1.5: Determine Thinking Mode (Line 122) - Add EXECUTE NOW block
- [ ] Step 2: Launch Parallel Research Agents (Line 150) - **CRITICAL** - Add EXECUTE NOW with Task tool
- [ ] Step 3.5: Generate Project Name (Line 249) - Add EXECUTE NOW block
- [ ] Step 4: Collect Report Paths (Line 290) - Add EXECUTE NOW block
- [ ] Step 5: Save Research Checkpoint (Line 305) - Add EXECUTE NOW block

**Planning Phase** (5 steps need EXECUTE NOW blocks):
- [ ] Step 1: Prepare Planning Context (Line 372) - Add EXECUTE NOW block
- [ ] Step 2: Generate Planning Agent Prompt (Line 402) - Add EXECUTE NOW block
- [ ] Step 3: Invoke Planning Agent (Line 507) - **CRITICAL** - Add EXECUTE NOW with Task tool
- [ ] Step 4: Extract Plan Path (Line 535) - Add EXECUTE NOW block
- [ ] Step 5: Save Planning Checkpoint (Line 558) - Add EXECUTE NOW block

**Implementation Phase** (6 steps need EXECUTE NOW blocks):
- [ ] Step 1: Prepare Implementation Context (Line 596) - Add EXECUTE NOW block
- [ ] Step 2: Generate Implementation Agent Prompt (Line 621) - Add EXECUTE NOW block
- [ ] Step 3: Invoke Implementation Agent (Line 713) - **CRITICAL** - Add EXECUTE NOW with Task tool
- [ ] Step 4: Extract Implementation Status (Line 737) - Add EXECUTE NOW block
- [ ] Step 5: Conditional Branch (Line 765) - Add EXECUTE NOW block
- [ ] Step 6: Save Implementation Checkpoint (Line 781) - Add EXECUTE NOW block

**Debugging Loop** (8 steps need EXECUTE NOW blocks):
- [ ] Step 1: Generate Debug Topic Slug (Line 851) - Add EXECUTE NOW block
- [ ] Step 2: Invoke Debug Specialist (Line 877) - **CRITICAL** - Add EXECUTE NOW with Task tool
- [ ] Step 3: Extract Debug Report Path (Line 930) - Add EXECUTE NOW block
- [ ] Step 4: Apply Recommended Fix (Line 955) - **CRITICAL** - Add EXECUTE NOW with Task tool
- [ ] Step 5: Run Tests Again (Line 993) - Add EXECUTE NOW block
- [ ] Step 6: Decision Logic (Line 1013) - Add EXECUTE NOW block
- [ ] Step 7: Update Workflow State (Line 1040) - Add EXECUTE NOW block
- [ ] Step 8: Save Debug Checkpoint (Line 1072) - Add EXECUTE NOW block

**Documentation Phase** (9 steps need EXECUTE NOW blocks):
- [ ] Step 1: Prepare Documentation Context (Line 1142) - Add EXECUTE NOW block
- [ ] Step 2-4: Documentation Agent Invocation (Line 1176) - Add EXECUTE NOW block
- [ ] Step 3: Invoke Documentation Agent (Line 1200) - **CRITICAL** - Add EXECUTE NOW with Task tool
- [ ] Step 4: Extract Documentation Results (Line 1223) - Add EXECUTE NOW block
- [ ] Step 5: Generate Workflow Summary (Line 1241) - Add EXECUTE NOW block
- [ ] Step 6: Create Summary File (Line 1388) - Add EXECUTE NOW block
- [ ] Step 7: Save Final Checkpoint (Line 1418) - Add EXECUTE NOW block
- [ ] Step 8: Create Pull Request (Line 1446) - Add EXECUTE NOW block (conditional)
- [ ] Step 9: Workflow Completion Message (Line 1539) - Add EXECUTE NOW block

**Total EXECUTE NOW blocks needed**: 34

### Category 4: Execution Verification Checklists

**After Each Major Phase** (5 checklists needed):
- [ ] After Research Phase (Line ~335) - Checklist already exists, enhance it
- [ ] After Planning Phase (Line ~593) - Add new checklist
- [ ] After Implementation Phase (Line ~844) - Add new checklist
- [ ] After Debugging Loop (Line ~1137) - Add new checklist
- [ ] After Documentation Phase (Line ~1600) - Add new checklist

### Category 5: Task Tool Invocation Examples

**Critical Inlining Points** (7 locations need inline Task tool syntax):
1. **Research Phase - Parallel Invocation** (Line ~154)
   - Replace: Reference to pattern docs
   - With: Complete Task tool invocation for 2-3 parallel research agents
   - Include: Full prompt template inlined

2. **Planning Phase - Single Invocation** (Line ~507)
   - Replace: YAML example
   - With: Explicit "EXECUTE NOW: USE the Task tool with these parameters"
   - Include: Full plan-architect prompt inlined

3. **Implementation Phase - Single Invocation** (Line ~713)
   - Replace: YAML example
   - With: Explicit Task tool invocation
   - Include: Full code-writer prompt inlined
   - Note: Extended timeout parameter (600000ms)

4. **Debugging Loop - Debug Specialist** (Line ~877)
   - Replace: YAML example
   - With: Explicit Task tool invocation
   - Include: Full debug-specialist prompt with file creation inlined

5. **Debugging Loop - Code Writer Fix** (Line ~955)
   - Replace: YAML example
   - With: Explicit Task tool invocation
   - Include: Full code-writer fix prompt inlined

6. **Documentation Phase - Doc Writer** (Line ~1200)
   - Replace: YAML example
   - With: Explicit Task tool invocation
   - Include: Full doc-writer prompt inlined

7. **PR Creation - GitHub Specialist** (Line ~1469)
   - Already has good structure
   - Enhance with EXECUTE NOW block

## Transformation Strategy

### Phase 2 Priority (Research Phase - Lines 85-368)
**Focus**: Lines 85-368
**Key Changes**:
- Convert 3 passive voice instances (lines 89, 152)
- Inline parallel agent invocation pattern (line 154) - **CRITICAL**
- Add 6 EXECUTE NOW blocks (one per step)
- Enhance execution checklist (line 325)

### Phase 3 Priority (Planning Phase - Lines 370-600)
**Focus**: Lines 370-593
**Key Changes**:
- Inline planning agent prompt template (line 402-505)
- Add EXECUTE NOW to Step 3 invocation (line 507) - **CRITICAL**
- Add 5 EXECUTE NOW blocks (one per step)
- Add execution verification checklist

### Phase 4 Priority (Implementation Phase - Lines 594-844)
**Focus**: Lines 594-844
**Key Changes**:
- Inline implementation agent prompt (line 621-712)
- Add EXECUTE NOW to Step 3 invocation (line 713) - **CRITICAL**
- Add 6 EXECUTE NOW blocks (one per step)
- Add execution verification checklist

### Phase 5 Priority (Debugging Loop - Lines 845-1136)
**Focus**: Lines 845-1137
**Key Changes**:
- Inline debug-specialist prompt (line 877-929) with EXECUTE NOW
- Inline code-writer fix prompt (line 955-992) with EXECUTE NOW
- Add 8 EXECUTE NOW blocks (one per step)
- Enhance iteration control logic (line 1013-1039)
- Add execution verification checklist

### Phase 6 Priority (Documentation Phase - Lines 1138-1600)
**Focus**: Lines 1138-1600
**Key Changes**:
- Inline doc-writer prompt (line 1176-1199)
- Add EXECUTE NOW to Step 3 invocation (line 1200) - **CRITICAL**
- Add 9 EXECUTE NOW blocks (one per step)
- Inline workflow summary template (currently Step 5)
- Add execution verification checklist

### Phase 7 Priority (Infrastructure - Lines 1-84, 1601-1953)
**Focus**: Workflow initialization and state management
**Key Changes**:
- Add workflow initialization with TodoWrite (line 49-51)
- Add state management updates throughout
- Enhance checkpoint sections (lines 1881-1953)
- Add progress streaming guidance
- Add execution verification infrastructure

## Current vs Target Structure Examples

### Example 1: Research Phase Step 2 (Lines 150-162)

**CURRENT**:
```markdown
#### Step 2: Launch Parallel Research Agents

For each identified research topic, I'll create a focused research task and invoke agents in parallel.

See [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation) for detailed parallel execution patterns.

**Orchestrate-specific invocation**:
- Launch 2-4 research agents simultaneously (single message, multiple Task blocks)
- Each agent receives ONLY its specific research focus
- NO orchestration routing logic in prompts
- Complete task description with success criteria per agent
```

**TARGET**:
```markdown
#### Step 2: Launch Parallel Research Agents

**EXECUTE NOW**: USE the Task tool to invoke research-specialist agents in parallel.

For each research topic identified in Step 1, create a Task tool invocation.

**Task Tool Syntax** (repeat for each topic):
```
Task tool invocation #1:
{
  subagent_type: "general-purpose",
  description: "Research [topic_1] using research-specialist protocol",
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    You are acting as a Research Specialist with the tools and constraints
    defined in that file.

    [Complete inlined prompt from Step 3]
}

Task tool invocation #2:
{
  subagent_type: "general-purpose",
  description: "Research [topic_2] using research-specialist protocol",
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    [Complete inlined prompt from Step 3]
}
```

**CRITICAL**: Send ALL research Task invocations in a SINGLE MESSAGE for parallel execution.

**Execution Steps**:
1. Generate research prompt for each topic using template from Step 3
2. Create Task tool invocation for each topic
3. Send all Task invocations in ONE message (parallel execution)
4. Wait for all agents to complete
5. Proceed to Step 4 to collect report paths
```

### Example 2: Planning Phase Step 3 (Lines 507-527)

**CURRENT**:
```markdown
#### Step 3: Invoke Planning Agent

**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Create implementation plan for [feature] using plan-architect protocol"
prompt: "Read and follow the behavioral guidelines from:
         /home/benjamin/.config/.claude/agents/plan-architect.md

         You are acting as a Plan Architect with the tools and constraints
         defined in that file.

         [Generated planning prompt from Step 2]"
```

**Execution Details**:
- Single agent (sequential execution)
- Full access to project files for analysis
- Can invoke /plan slash command
- Returns plan file path and summary
```

**TARGET**:
```markdown
#### Step 3: Invoke Planning Agent

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task tool invocation:
{
  subagent_type: "general-purpose",
  description: "Create implementation plan using plan-architect protocol",
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    You are acting as a Plan Architect with the tools and constraints
    defined in that file.

    [COMPLETE PROMPT FROM STEP 2 INLINED HERE - Full planning prompt template]
}

**Execution Steps**:
1. Verify research reports collected (if research phase completed)
2. USE the Task tool with parameters above
3. WAIT for agent completion
4. PROCEED to Step 4 to extract plan path

**Verification**:
- [ ] Task tool invoked (not just documented)
- [ ] Agent prompt includes all context from Step 2
- [ ] Agent has access to research report paths
- [ ] Agent output contains plan file path
```

## Testing Requirements

After completing transformation of each phase, verify:

1. **Backup Verification**:
   ```bash
   ls -la .claude/commands/orchestrate.md.backup
   diff .claude/commands/orchestrate.md .claude/commands/orchestrate.md.backup | wc -l
   ```

2. **Passive Voice Reduction**:
   ```bash
   # Should be significantly reduced after refactor
   grep -c "I'll\|I will" .claude/commands/orchestrate.md
   ```

3. **External Reference Elimination**:
   ```bash
   # Should be 0 for critical patterns (parallel invocation, Task tool usage)
   grep -c "See \[Parallel Agent\]" .claude/commands/orchestrate.md
   grep -c "See \[.*\](.*command-patterns" .claude/commands/orchestrate.md
   ```

4. **EXECUTE NOW Block Count**:
   ```bash
   # Should have 34+ instances
   grep -c "EXECUTE NOW" .claude/commands/orchestrate.md
   ```

5. **Task Tool Invocation Validation**:
   ```bash
   # Should have inline Task tool syntax (not YAML examples)
   grep -A 5 "Task tool invocation" .claude/commands/orchestrate.md | head -20
   ```

## Estimated Effort

- **Passive Voice Conversion**: 1 hour (8 instances, straightforward)
- **External Pattern Inlining**: 3-4 hours (6 locations, varying complexity)
- **EXECUTE NOW Blocks**: 6-8 hours (34 blocks, each with execution steps)
- **Verification Checklists**: 2 hours (5 checklists)
- **Documentation & Testing**: 1 hour

**Total Phase 1**: 13-16 hours (spread across Phases 2-7 implementation)

## Phase 1 Completion Criteria

- [x] Backup created
- [x] Line count verified (1953 lines)
- [x] Passive voice instances identified (8 total)
- [x] External references mapped (6 locations)
- [x] Major sections mapped (all phases documented)
- [x] EXECUTE NOW gaps identified (34 locations)
- [x] Transformation checklist created (this document)
- [ ] Phase 1 marked as complete in plan
- [ ] Git commit created for Phase 1

## Next Steps

Proceed to **Phase 2: Research Phase Refactor** with this checklist as the guide.
Focus on lines 85-368 with priority on:
1. Inlining parallel agent invocation pattern (line 154) - **CRITICAL**
2. Adding EXECUTE NOW blocks (6 locations)
3. Converting passive voice (2 instances)
4. Adding execution verification checklist

This checklist will be referenced throughout Phases 2-7 to ensure systematic transformation.

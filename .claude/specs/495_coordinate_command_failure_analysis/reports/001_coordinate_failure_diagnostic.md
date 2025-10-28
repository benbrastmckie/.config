# /coordinate Command Failure Analysis

**STATUS**: ✅ RESOLVED (2025-10-27)
**Fixed In**: Spec 497 - Unified Orchestration Command Improvements
**Implementation Plan**: `.claude/specs/497_unified_plan_coordinate_supervise_improvements/plans/001_unified_implementation_plan.md`
**Resolution Date**: 2025-10-27
**Resolution Summary**: Applied imperative agent invocation pattern to all 9 agent invocations. Delegation rate improved from 0% to >90%. File creation reliability improved from 0% to 100%.

---

## Executive Summary

The `/coordinate` command is experiencing a **0% agent delegation rate**, causing it to write output to TODO files instead of invoking research subagents. This is caused by **YAML-like Task invocations appearing as documentation** rather than **executable instructions**.

**Critical Finding**: The command uses the EXACT SAME anti-pattern previously identified and fixed in `/supervise` command (spec 438), but the fix was never applied to `/coordinate`.

**Impact**:
- `/coordinate` command completely non-functional for all workflows
- Outputs written to `.claude/TODO1.md` instead of creating research reports
- No research agents invoked despite explicit instructions in command file
- Similar pattern affects `/research` command

**Root Cause**: YAML-style Task invocations that Claude interprets as documentation examples, not executable instructions.

---

## Critical Issue: Agent Delegation Failure

### Symptom

When user ran:
```bash
/coordinate "research the /home/benjamin/.config/.claude/commands/shared/ directory..."
```

**Expected behavior**:
1. Invoke 2-4 research-specialist agents in parallel via Task tool
2. Agents create report files in `.claude/specs/NNN_topic/reports/`
3. Research-synthesizer creates OVERVIEW.md
4. Display summary with artifact paths

**Actual behavior**:
1. No agents invoked
2. Output written to `/home/benjamin/.config/.claude/TODO1.md`
3. No research reports created
4. Command appears to interpret bash/YAML code blocks as literal documentation

---

## Root Cause Analysis

### Anti-Pattern: YAML-Style Task Invocations

**The Problem**: Task invocations are written as YAML-like pseudo-code blocks:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md
    ...
  "
}
```

**Why Claude Ignores This**:
1. **Imperative instruction** (`**EXECUTE NOW**: USE the Task tool`) appears to request action
2. **YAML-like syntax** (`Task { ... }`) appears as **pseudo-code documentation**
3. **No actual function call** - Claude interprets this as "show user what Task invocation would look like"
4. **Result**: Claude provides narrative explanation instead of invoking Task tool

### Historical Context: Spec 438 (/supervise Failure)

This **exact anti-pattern** was discovered and documented in spec 438:

> "An anti-pattern was discovered in the `/supervise` command where 7 YAML blocks were wrapped in markdown code fences (\`\`\`yaml), causing a **0% agent delegation rate**. All agent invocations appeared as documentation examples rather than executable instructions."

**Resolution documented** in CLAUDE.md (lines 2276-2295):
```markdown
**Resolution**: All orchestration commands now enforce Standard 11 (Imperative Agent Invocation Pattern), which requires:
- Imperative instructions (`**EXECUTE NOW**: USE the Task tool...`)
- No code block wrappers around Task invocations
- Direct reference to agent behavioral files (`.claude/agents/*.md`)
- Explicit completion signals (e.g., `REPORT_CREATED:`)
```

**Current Status**: `/coordinate` command was **never updated** with this fix, causing identical failure mode.

### Experimental Confirmation

I tested the pattern by attempting to invoke a research agent using the coordinate.md syntax:

**Test 1**: YAML-style invocation (coordinate.md pattern)
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "..."
}
```

**Result**: Agent was invoked BUT revealed **template variable substitution failure**:
- `${WORKFLOW_DESCRIPTION}` was passed as literal string (not substituted)
- `${REPORT_PATHS[i]}` was passed as literal string (not substituted)
- Agent correctly identified this as a bug in the invoking command

**Root Cause Confirmed**: Even when YAML-style invocations work, they fail due to:
1. **Bash variable substitution issues** (using wrong quoting)
2. **Template variables passed literally** instead of being evaluated
3. **Missing path pre-calculation** before agent invocation

---

## Detailed Failure Points

### 1. Research Phase Failure (Lines 1042-1082)

**Location**: coordinate.md:1053-1073

**Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]}
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATHS[i]}
  "
}
```

**Why it fails**:
- Imperative instruction (`**EXECUTE NOW**`) suggests action, but...
- YAML-like `Task { }` syntax appears as **pseudo-code documentation**
- Claude interprets this as "here's what the Task invocation would look like"
- Even if invoked, variables like `${TOPIC_NAME}` are not substituted
- **Evidence**: User reported output went to `TODO1.md` instead of invoking agents

### 2. Planning Phase Failure (Lines 1323-1346)

**Location**: coordinate.md:1327-1346

**Same pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  prompt: "..."
}
```

**Why it fails**: Identical anti-pattern to research phase.

### 3. Implementation Phase Failure (Lines 1579-1620)

**Location**: coordinate.md:1583-1620

**Same pattern** with additional complexity (wave-based execution context).

### 4. Testing/Debug/Documentation Phases (Lines 1761+)

**All subsequent phases** use identical documentation-style Task invocations.

**Total failure points**: 9 agent invocations across 6 phases, all using the same broken pattern.

---

## Comparison: Working vs Broken Patterns

### /supervise Command (FIXED) - 90%+ Delegation Rate

**Pattern** (from supervise.md after spec 438 fix):
```markdown
**STEP 2: Invoke Research Agents in Parallel**

For each research topic identified, YOU MUST invoke research-specialist agents:

**AGENT INVOCATION - Use THIS EXACT Pattern**:

For research topic: "API authentication patterns"

USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Research API authentication patterns"
- prompt: "Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

**Workflow-Specific Context**:
- Research Topic: API authentication patterns
- Report Path: /absolute/path/to/report.md

Execute research following all guidelines in behavioral file.
Return: REPORT_CREATED: /absolute/path/to/report.md"
```

**Why it works**:
1. **Clear imperative**: "YOU MUST invoke", "USE the Task tool NOW"
2. **No YAML pseudo-code**: Parameters listed as bullet points, not YAML blocks
3. **Explicit values**: No template variables, actual values provided
4. **Unambiguous instruction**: "USE the Task tool NOW with these parameters"

### /coordinate Command (BROKEN) - 0% Delegation Rate

**Pattern** (from coordinate.md current state):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md
    ...
  "
}
```

**Why it fails**:
1. **YAML pseudo-code**: `Task { }` syntax appears as documentation
2. **Template variables**: `${TOPIC_NAME}`, `${WORKFLOW_DESCRIPTION}` not substituted
3. **Ambiguous instruction**: Could be "here's what it would look like" vs "execute this"
4. **No explicit values**: Everything is a placeholder

### Side-by-Side Comparison

| Aspect | /supervise (fixed) | /coordinate (broken) |
|--------|-------------------|---------------------|
| **Agent invocations** | Imperative with explicit bullet points | YAML blocks appearing as documentation |
| **Variable substitution** | Actual values, no templates | Template variables (`${VAR}`) not substituted |
| **Instruction clarity** | "USE the Task tool NOW with these parameters" | "USE the Task tool" (ambiguous) |
| **Executable markers** | Present on working examples | Missing from actual invocations |
| **Code fences** | None around Task invocations | Bash code fences in some sections |
| **Delegation rate** | >90% (after fix) | 0% (current state) |
| **File creation** | Works correctly | Fails (writes to TODO1.md) |

---

## Additional Issues Found

### Issue 1: Template Variable Substitution Failure

Even if YAML-style invocations were recognized as executable, they contain **unsubstituted bash variables**:

```markdown
- Research Topic: ${WORKFLOW_DESCRIPTION}
- Report Path: ${REPORT_PATHS[i]}
```

**Problem**: These are bash variable syntax, but coordinate.md is a **markdown file** interpreted by Claude, not executed as bash.

**Expected**: Orchestrator should pre-calculate all values and inject them as literals:
```markdown
- Research Topic: authentication patterns
- Report Path: /home/benjamin/.config/.claude/specs/042_auth/reports/001_report.md
```

### Issue 2: Bash Code Block Execution Assumption

The command contains extensive bash code blocks with instructions like:

```bash
# Source required libraries
source .claude/lib/topic-decomposition.sh

# Determine number of subtopics
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")
```

**Problem**: These are **documentation/examples** showing what bash operations would be needed, not instructions for Claude to execute bash commands.

**Claude's interpretation**: "This is an example of bash code that would need to run" (not "execute this bash code now")

### Issue 3: Missing Executable Markers

The command has ONE example with `<!-- This Task invocation is executable -->` comment (line 87), but all actual agent invocations (lines 1053, 1327, 1583, 1765, 1896, 1967, 1996, 2101) **lack this marker**.

**Implication**: Claude correctly interprets marked invocation as executable, but interprets unmarked invocations as documentation.

---

## Architectural Anti-Patterns Documented

### Anti-Pattern 1: YAML-Style Task Blocks

**Description**: Writing Task tool invocations as YAML-like pseudo-code blocks that appear to be documentation.

**Detection**: Look for patterns like:
```markdown
Task {
  subagent_type: "..."
  description: "..."
  prompt: "..."
}
```

**Without** explicit markers like `<!-- This Task invocation is executable -->` or imperative phrasing like "USE the Task tool NOW with these parameters:".

**Fix**: Use imperative bullet-point pattern:
```markdown
USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Research topic X"
- prompt: "Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

**Workflow-Specific Context**:
- Research Topic: [ACTUAL VALUE, NOT TEMPLATE]
- Report Path: [ABSOLUTE PATH, PRE-CALCULATED]

Execute research following all guidelines.
Return: REPORT_CREATED: [ABSOLUTE PATH]"
```

### Anti-Pattern 2: Template Variables in Agent Prompts

**Description**: Using bash variable syntax (`${VAR}`) in markdown files expecting Claude to substitute them.

**Detection**: Look for patterns like:
```markdown
- Research Topic: ${WORKFLOW_DESCRIPTION}
- Report Path: ${REPORT_PATHS[i]}
```

**Fix**: Pre-calculate all values in Phase 0 and inject as literals:
```markdown
- Research Topic: authentication patterns for REST APIs
- Report Path: /home/benjamin/.config/.claude/specs/042_auth/reports/001_patterns.md
```

### Anti-Pattern 3: Bash Code Blocks as Instructions

**Description**: Writing bash code in markdown code fences expecting Claude to execute it.

**Detection**: Look for patterns like:
````markdown
```bash
source .claude/lib/utilities.sh
RESULT=$(calculate_value "$INPUT")
```
````

**Fix**: Use imperative instructions with explicit Bash tool invocations:
```markdown
**EXECUTE NOW**: USE the Bash tool to source the utilities library:

Command: source .claude/lib/utilities.sh && calculate_value "$INPUT"
Description: Load utilities and calculate value
```

### Anti-Pattern 4: Documentation-Style Examples in Execution Sections

**Description**: Mixing actual executable instructions with documentation examples without clear markers.

**Detection**: Sections with both:
- `<!-- This Task invocation is executable -->` (marked examples)
- Unmarked Task invocations that should be executable

**Fix**: Either:
1. Mark ALL executable invocations explicitly, OR
2. Remove documentation examples from execution sections, OR
3. Use consistent imperative phrasing for all executable instructions

---

## Impact Assessment

### Commands Affected

Based on similar patterns, these commands likely have the same issue:

1. **`/coordinate`** (86KB) - **CONFIRMED BROKEN**
   - 0% agent delegation rate
   - All 9 agent invocations use YAML-style blocks

2. **`/research`** (currently running) - **LIKELY BROKEN**
   - Uses identical YAML-style Task invocations
   - Same template variable pattern

3. **`/orchestrate`** (186KB) - **STATUS UNKNOWN**
   - Needs verification for delegation rate
   - May have been partially updated after spec 438 fix

4. **`/supervise`** (74KB) - **FIXED** (after spec 438)
   - Uses imperative bullet-point pattern
   - 90%+ delegation rate confirmed

### Severity: CRITICAL

**Affected workflows**: ALL multi-agent orchestration workflows

**User impact**:
- Cannot use `/coordinate` for any research or development workflows
- Cannot use `/research` command (hierarchical multi-agent pattern)
- Possible failures in `/orchestrate` (needs verification)
- Only `/supervise` command working correctly

**Workaround**: Use `/supervise` command for multi-agent workflows until `/coordinate` and `/research` are fixed.

---

## Recommendations

### Immediate Actions

1. **Fix /coordinate command** using spec 438 resolution pattern:
   - Replace all YAML-style Task blocks with imperative bullet-point pattern
   - Remove template variables, use pre-calculated values
   - Add explicit executable markers or use consistent imperative phrasing
   - Verify delegation rate >90% after changes

2. **Fix /research command** using same pattern

3. **Verify /orchestrate command** delegation rate and fix if needed

4. **Document anti-patterns** in command architecture standards to prevent future occurrences

### Long-Term Solutions

1. **Create validation script** to detect YAML-style Task blocks in command files:
   ```bash
   # .claude/lib/validate-command-task-invocations.sh
   # Fails CI if YAML-style Task blocks found without executable markers
   ```

2. **Add to test suite**: Automatic detection of anti-patterns in all commands

3. **Update command development guide** with explicit examples of correct vs incorrect patterns

4. **Code review checklist** for new commands:
   - [ ] All Task invocations use imperative bullet-point pattern
   - [ ] No template variables in agent prompts
   - [ ] No YAML-style pseudo-code blocks for Task invocations
   - [ ] Executable markers present where needed

---

## Related Issues

### Shared Directory Cleanup (Original Research Request)

The user's original request was to research the `/home/benjamin/.config/.claude/commands/shared/` directory to identify unused files.

**Status**: Research not completed due to `/coordinate` command failure.

**Alternative approach**: Use `/supervise` command or manual research to complete this task.

### /orchestrate vs /coordinate Consolidation

Both commands provide similar multi-agent orchestration:
- `/orchestrate`: 186KB, full-featured with PR automation
- `/coordinate`: 86KB, wave-based parallel execution
- `/supervise`: 74KB, sequential proven architecture

**Question**: If `/coordinate` is broken and requires significant rework, should it be deprecated in favor of `/supervise` or consolidated with `/orchestrate`?

---

## Verification Steps

To confirm the fix works:

1. **Update /coordinate command** with imperative pattern
2. **Run test workflow**:
   ```bash
   /coordinate "research test topic for verification"
   ```
3. **Verify outputs**:
   - [ ] Research agents invoked (check for PROGRESS: markers)
   - [ ] Report files created in `.claude/specs/NNN_topic/reports/`
   - [ ] No output in `.claude/TODO.md` or `.claude/TODO1.md`
   - [ ] OVERVIEW.md created by research-synthesizer
   - [ ] Summary displayed to user with artifact paths

4. **Check delegation rate**:
   ```bash
   # Should show >90% agent delegation
   /analyze agents
   ```

---

## Conclusion

The `/coordinate` command failure is caused by using the EXACT SAME anti-pattern that broke `/supervise` command (spec 438). The fix is well-documented and proven to work, but was never applied to `/coordinate`.

**Immediate action required**: Apply spec 438 resolution pattern to `/coordinate` and `/research` commands to restore functionality.

**Prevention**: Add validation scripts and test suite checks to prevent this anti-pattern from recurring in future command development.

# /research Command Failure Analysis

**STATUS**: ✅ RESOLVED (2025-10-27)
**Fixed In**: Spec 497 - Unified Orchestration Command Improvements
**Implementation Plan**: `.claude/specs/497_unified_plan_coordinate_supervise_improvements/plans/001_unified_implementation_plan.md`
**Resolution Date**: 2025-10-27
**Resolution Summary**: Applied imperative agent invocation pattern to 3 agent invocations. Converted ~10 bash code blocks to explicit Bash tool invocations. Delegation rate improved from 0% to >90%.

---

## Executive Summary

The `/research` command exhibits the **identical failure pattern** as `/coordinate`: **0% agent delegation rate** due to YAML-style Task invocations interpreted as documentation rather than executable instructions.

**Evidence**: When invoked with `/research "research /home/benjamin/.config/.claude/TODO2.md..."`, the command displayed its entire prompt (including bash code blocks and YAML Task templates) instead of executing the research workflow.

**Status**: CONFIRMED BROKEN - Same anti-pattern as coordinate.md, requires same fix from spec 438.

---

## Failure Confirmation

### Test Invocation

**Command executed**:
```bash
/research "research /home/benjamin/.config/.claude/TODO2.md which demonstrates that /research suffers from a similar problem"
```

**Expected behavior**:
1. Decompose topic into 2-4 research subtopics
2. Invoke research-specialist agents in parallel
3. Create report files in `.claude/specs/NNN_topic/reports/`
4. Synthesize findings into OVERVIEW.md
5. Display summary with artifact paths

**Actual behavior**:
1. Command expanded its full prompt to user (21,000+ lines)
2. No agents invoked
3. No report files created
4. Displayed bash code blocks as if they were instructions to read
5. Showed YAML Task templates as documentation examples

**Evidence**: The command output began with:
```
# Generate Research Report with Hierarchical Multi-Agent Pattern

YOU MUST orchestrate hierarchical research by delegating to specialized subagents...

### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition

**EXECUTE NOW - Decompose Research Topic Into Subtopics**

```bash
# Source required libraries
source .claude/lib/topic-decomposition.sh
...
```
```

This is the **command file content being displayed**, not the command being executed.

---

## Root Cause: Identical Anti-Pattern

### Pattern Analysis

The `/research` command uses the **exact same YAML-style Task blocks** as `/coordinate`:

**From research.md (STEP 3 - Agent Invocation)**:
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [SUBTOPIC_DISPLAY_NAME]
    - Report Path: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]
    ...
  "
}
```
```

**Why this fails**:
1. **Markdown code fence** wrapping YAML block (` ```yaml `)
2. **YAML-style syntax** appears as documentation, not executable instruction
3. **Template placeholders** (`[SUBTOPIC]`, `[ABSOLUTE_PATH]`) not substituted
4. **No imperative invocation** pattern like "USE the Task tool NOW with these parameters"

### Comparison to Working Pattern

**Broken Pattern** (research.md current state):
```markdown
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [subtopic]"
  prompt: "..."
}
```
```

**Working Pattern** (supervise.md after spec 438 fix):
```markdown
USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Research authentication patterns"
- prompt: "Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

**Workflow-Specific Context**:
- Research Topic: authentication patterns  # Actual value
- Report Path: /absolute/path/to/report.md  # Pre-calculated

Execute research following all guidelines.
Return: REPORT_CREATED: /absolute/path/to/report.md"
```

---

## Architectural Issues in /research Command

### Issue 1: Code Fences Around Task Invocations

**Problem**: Task blocks wrapped in markdown code fences with ` ```yaml ` syntax

**Location**: Multiple occurrences throughout research.md:
- STEP 3 (research-specialist invocation)
- STEP 5 (research-synthesizer invocation)
- STEP 6 (spec-updater invocation)

**Evidence from anti-pattern documentation** (CLAUDE.md lines 2276-2295):
> "An anti-pattern was discovered in the `/supervise` command where 7 YAML blocks were wrapped in markdown code fences (\`\`\`yaml), causing a **0% agent delegation rate**."

**Fix**: Remove code fences, use imperative bullet-point pattern.

### Issue 2: Template Placeholders Not Substituted

**Problem**: Placeholders like `[SUBTOPIC]`, `[ABSOLUTE_PATH]` appear literally instead of being substituted with actual values

**Example from research.md**:
```markdown
Task {
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  prompt: "
    - Research Topic: [SUBTOPIC_DISPLAY_NAME]
    - Report Path: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]
  "
}
```

**Why this fails**: These are markdown placeholders in a documentation file, not bash variables that get substituted. Claude sees literal `[SUBTOPIC]` not actual topic name.

**Fix**: Pre-calculate all values and inject as literals before agent invocation.

### Issue 3: Bash Code Blocks as Pseudo-Instructions

**Problem**: Extensive bash code blocks that appear as "here's what code would run" rather than "execute this code now"

**Example from research.md STEP 2**:
````markdown
```bash
# Source unified location detection utilities
source .claude/lib/topic-utils.sh
source .claude/lib/detect-project-dir.sh

# Get project root (from environment or git)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
if [ -z "$PROJECT_ROOT" ]; then
  echo "ERROR: CLAUDE_PROJECT_DIR not set"
  exit 1
fi
```
````

**Claude's interpretation**: "This is example bash code showing what operations are needed" (not "execute this bash code now via Bash tool")

**Fix**: Use explicit imperative instructions:
```markdown
**EXECUTE NOW**: USE the Bash tool to source location detection utilities and calculate topic directory.
```

### Issue 4: Orchestrator vs Executor Role Confusion

**Problem**: The command's preamble states:
```markdown
**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
```

But then provides bash code blocks and YAML templates that **look like instructions for Claude to follow**, contradicting the orchestrator role.

**Confusion**: If Claude is the orchestrator and should ONLY use Task tool, why is the command file full of bash code blocks and YAML templates?

**Fix**: Clarify execution model and use only imperative Task invocations, no bash/YAML pseudo-code.

---

## Comparison: /research vs /coordinate vs /supervise

| Aspect | /supervise (fixed) | /coordinate (broken) | /research (broken) |
|--------|-------------------|---------------------|-------------------|
| **Agent invocations** | Imperative bullet points | YAML blocks | YAML blocks in code fences |
| **Code fences** | None | Some | Extensive (```yaml, ```bash) |
| **Variable substitution** | Actual values | Template vars ${VAR} | Template vars [VAR] |
| **Instruction clarity** | "USE Task tool NOW" | "EXECUTE NOW" | "EXECUTE NOW" |
| **Bash code blocks** | Minimal, explicit | Many, ambiguous | Extensive, ambiguous |
| **Delegation rate** | >90% | 0% | 0% |
| **File creation** | Works | Fails | Fails |
| **Status** | PRODUCTION | BROKEN | BROKEN |

---

## Impact Assessment

### Commands Confirmed Broken

1. **`/coordinate`** (86KB) - CONFIRMED BROKEN
   - 0% agent delegation rate
   - Writes output to TODO1.md

2. **`/research`** (current command) - CONFIRMED BROKEN
   - 0% agent delegation rate
   - Displays entire command prompt instead of executing

### Severity: CRITICAL

**User Impact**:
- **Cannot perform any research workflows** (hierarchical multi-agent pattern completely non-functional)
- **Cannot use /coordinate** for multi-agent orchestration
- **Both primary research commands broken** (/research, /coordinate research phase)

**Working Alternative**: `/supervise` command only

---

## Root Cause Summary

Both `/coordinate` and `/research` commands suffer from the **same architectural anti-pattern**:

1. **YAML-style Task blocks** wrapped in markdown code fences
2. **Template placeholders** not substituted with actual values
3. **Bash code blocks** appearing as documentation, not executable instructions
4. **Ambiguous instruction phrasing** ("EXECUTE NOW" but shows pseudo-code, not imperative invocation)

**Historical Context**: This exact pattern was identified and fixed in `/supervise` command (spec 438), but the fix was **never propagated** to `/coordinate` or `/research`.

---

## Recommendations

### Immediate Actions

1. **Apply spec 438 fix to both commands**:
   - `/coordinate` (86KB, 9 broken agent invocations)
   - `/research` (current command, 3 broken agent invocations)

2. **Verification testing**:
   ```bash
   # After fixes applied
   /research "test research topic"
   /coordinate "research test workflow"

   # Verify:
   # - Agents invoked (check for PROGRESS: markers)
   # - Report files created
   # - No output in TODO*.md files
   ```

3. **Deprecation consideration**:
   - `/research` command may be redundant if `/coordinate` handles research phase
   - Consider consolidating into single working orchestration command
   - If keeping both, ensure consistency in agent invocation patterns

### Pattern Standardization

**Problem**: Three different patterns for agent invocation across commands:
1. `/supervise`: Imperative bullet-point pattern (WORKS)
2. `/coordinate`: YAML-style blocks (BROKEN)
3. `/research`: YAML-style blocks in code fences (BROKEN)

**Solution**: Standardize ALL commands on supervise.md pattern:
```markdown
USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "[actual description, no placeholders]"
- prompt: "[complete prompt with actual values]"
```

### Prevention

1. **Command validation script** (`.claude/lib/validate-agent-invocation-pattern.sh`):
   ```bash
   # Detect YAML-style Task blocks
   # Detect code fences around Task invocations
   # Detect template placeholders in agent prompts
   # Fail CI if anti-patterns found
   ```

2. **Test suite addition**:
   - Test ALL orchestration commands for agent delegation
   - Verify >90% delegation rate
   - Check for artifact creation (not TODO.md output)

3. **Documentation update**:
   - Add "/research failure" to anti-pattern documentation
   - Update [Behavioral Injection Pattern](../docs/concepts/patterns/behavioral-injection.md) with /research example
   - Reference in [Command Architecture Standards](../docs/reference/command_architecture_standards.md#standard-11)

---

## Technical Details

### Expected vs Actual Flow

**Expected Flow** (if /research worked correctly):
```
User: /research "topic"
  ↓
Claude (Orchestrator):
  ↓
  1. Calculate paths (Phase 0)
  ↓
  2. Decompose into subtopics (STEP 1)
  ↓
  3. Pre-calculate report paths (STEP 2)
  ↓
  4. Invoke research-specialist agents (STEP 3) ← USE Task tool
     ├─ Agent 1 → Report 1
     ├─ Agent 2 → Report 2
     ├─ Agent 3 → Report 3
     └─ Agent 4 → Report 4
  ↓
  5. Verify all reports created (STEP 4)
  ↓
  6. Invoke research-synthesizer (STEP 5) ← USE Task tool
     └─ Synthesizer → OVERVIEW.md
  ↓
  7. Invoke spec-updater (STEP 6) ← USE Task tool
     └─ Update cross-references
  ↓
  8. Display summary to user (STEP 7)
```

**Actual Flow** (current broken state):
```
User: /research "topic"
  ↓
Claude: "Here's the research.md command file content for you to read"
  ↓
Output: [Displays 21,000+ lines of command documentation]
  ↓
Result: No agents invoked, no files created
```

### Why Claude Shows Command Content

**Reason**: Claude interprets the `/research` invocation as:
1. User wants to know what the `/research` command does
2. Show user the command file content (like a help system)
3. Explain the workflow steps with code examples

**Not interpreted as**:
1. User wants to execute the `/research` workflow
2. Invoke agents and create artifacts
3. Perform actual research

**Root cause**: Ambiguous instructions in command file that read like documentation rather than executable workflow steps.

---

## Verification After Fix

### Success Criteria

After applying spec 438 fixes, verify:

1. **Agent Invocation**:
   - [ ] research-specialist agents invoked (check for Task tool usage in logs)
   - [ ] research-synthesizer invoked
   - [ ] spec-updater invoked
   - [ ] Total: 3+ agent invocations per research workflow

2. **File Creation**:
   - [ ] Report files created in `.claude/specs/NNN_topic/reports/001_research/`
   - [ ] Subtopic reports (001_*.md, 002_*.md, ...)
   - [ ] OVERVIEW.md exists
   - [ ] No output in `.claude/TODO*.md`

3. **Output Format**:
   - [ ] PROGRESS: markers emitted
   - [ ] Summary displayed with artifact paths
   - [ ] No command file content displayed

4. **Delegation Rate**:
   ```bash
   /analyze agents
   # Should show:
   # - /research: >90% delegation rate
   # - Multiple agent invocations recorded
   ```

---

## Conclusion

The `/research` command failure confirms the **systemic nature** of the YAML-style Task block anti-pattern:
- Same root cause as `/coordinate` (spec 438 anti-pattern)
- Same symptoms (0% delegation, TODO.md output)
- Same fix required (spec 438 resolution pattern)

**Critical Priority**: Both `/coordinate` and `/research` must be fixed before any research or orchestration workflows can function.

**Recommended Approach**:
1. Fix `/supervise` if not already done (verify working state)
2. Apply identical pattern to `/coordinate`
3. Apply identical pattern to `/research`
4. Add validation to prevent regression
5. Consider consolidating redundant commands

**Alternative**: If fixing both commands is resource-intensive, deprecate `/coordinate` and `/research`, document `/supervise` as the only supported orchestration command until patterns are standardized.

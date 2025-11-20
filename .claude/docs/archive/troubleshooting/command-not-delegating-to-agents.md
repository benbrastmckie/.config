# Troubleshooting: Command Not Delegating to Agents

**Problem Type**: Execution Flow
**Symptoms**: Command executes tasks directly instead of invoking subagents
**Severity**: High
**Fix Time**: 10-25 minutes

---

## Quick Diagnosis

### Symptoms Checklist

Your command has this issue if you observe:

- [ ] Command uses Read/Write/Grep/Edit tools **directly** for agent tasks
- [ ] **No Task tool invocations** visible in command output
- [ ] **Single artifact** created instead of multiple subtopic artifacts
- [ ] No progress markers from subagents (e.g., "PROGRESS: Starting research...")
- [ ] No "REPORT_CREATED:" or similar agent return messages
- [ ] Execution completes faster than expected (no parallel processing)

### Example Output Comparison

**Broken Command** (not delegating):
```
● /report is running…
● Read(.claude/commands/report.md)
● Read(.claude/docs/concepts/hierarchical_agents.md)
● Glob(pattern: ".claude/agents/*.md")
● Read(.claude/agents/research-specialist.md)
● Write(reports/001_analysis.md)  ← Direct write, no agent
```

**Working Command** (delegating):
```
● /report is running…
● Bash(source .claude/lib/plan/topic-decomposition.sh && ...)
● Task(research-specialist) - Research auth_patterns
● Task(research-specialist) - Research oauth_flows
● Task(research-specialist) - Research session_mgmt
[Agents execute in parallel]
● Task(research-synthesizer) - Synthesize findings
● Read(reports/001_research/OVERVIEW.md)  ← Reading agent output
```

---

## Root Cause

**Issue**: Command opening statement uses ambiguous first-person language.

**Pattern**: "I'll [task verb]..." → Claude interprets as "I (Claude) should [task]"

**Examples**:
- ❌ "I'll research the specified topic..." → Claude researches directly
- ❌ "I'll implement the feature..." → Claude implements directly
- ❌ "I'll analyze the codebase..." → Claude analyzes directly
- ❌ "I'll create a plan..." → Claude creates plan directly (no agent delegation)

**Why This Happens**:
1. Claude sees "I'll research" and adopts first-person perspective
2. Sections describing agent pattern appear as documentation, not directives
3. Bash code blocks and Task templates appear as examples, not executable commands
4. No explicit "DO NOT execute this yourself" constraint

---

## Quick Fix (10 minutes)

### Step 1: Update Command Opening (5 minutes)

**Location**: First 10-20 lines of command file

**Find** (example pattern):
```markdown
# [Command Name]

I'll [task verb] the [object]...

## [Section]
$ARGUMENTS
```

**Replace With**:
```markdown
# [Command Name]

I'll orchestrate [task noun] by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the [executor/researcher/implementer].

**CRITICAL INSTRUCTIONS**:
- DO NOT execute [task] yourself using [Read/Write/Grep/Edit] tools
- ONLY use Task tool to delegate [task] to [agent-type] agents
- Your job: [orchestration steps: decompose → invoke → verify → synthesize]

You will NOT see [task results] directly. Agents will create [artifacts],
and you will [action: read/verify/extract metadata] after creation.

## [Section]
$ARGUMENTS
```

**Customization Guide**:
| Placeholder | /report Example | /plan Example | /implement Example |
|-------------|----------------|---------------|-------------------|
| `[task noun]` | hierarchical research | implementation planning | phased implementation |
| `[executor/...]` | researcher | planner | implementer |
| `[task]` | research | planning | implementation |
| `[Read/Write/...]` | Read/Grep/Write | Read/Write | Write/Edit/Bash |
| `[agent-type]` | research-specialist | plan-architect | code-writer |
| `[orchestration steps]` | decompose topic → invoke agents → verify outputs → synthesize | analyze feature → invoke planner → verify plan → estimate complexity | parse phases → invoke code-writer → run tests → verify |
| `[artifacts]` | report files | plan files | code changes |
| `[action]` | read | verify | test |

### Step 2: Add Execution Enforcement to Sections (5 minutes)

**Find** (example pattern):
```markdown
### 1. [Task Step]

[Description of what to do]:
```

**Replace With**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - [Task Step]

**EXECUTE NOW - [Imperative Action]**

YOU MUST run this code block NOW:
```

**Examples**:
- "### 1. Topic Analysis" → "### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition"
- "Decompose research topic" → "**EXECUTE NOW - Source Utilities and Decompose Topic**"
- "First, analyze..." → "YOU MUST run this code block NOW:"

---

## Complete Fix (25 minutes)

For comprehensive fix with all execution enforcement patterns:

**Follow**: [Execution Enforcement Migration Guide - Phase 0](../guides/execution-enforcement-migration-guide.md#phase-0-clarify-command-role-critical-foundation)

**Phases**:
1. **Phase 0**: Clarify orchestrator role (10 min) ← **THIS FIX**
2. **Phase 1**: Add path pre-calculation (5 min)
3. **Phase 2**: Add verification checkpoints (5 min)
4. **Phase 3**: Add checkpoint reporting (5 min)

---

## Verification

After applying fix, run command and check:

### Expected Output

✅ **Task tool invocations**:
```
● Task(subagent_type: "general-purpose")
  description: "Research [subtopic] with mandatory file creation"
```

✅ **Multiple agents** (if parallel pattern):
```
● Task(research-specialist) - Research subtopic_1
● Task(research-specialist) - Research subtopic_2
● Task(research-specialist) - Research subtopic_3
```

✅ **Agent return messages**:
```
Agent output: REPORT_CREATED: /path/to/report.md
```

✅ **Verification checkpoints**:
```
● Bash(if [ -f "$REPORT_PATH" ]; then echo "✓ Verified"; fi)
```

### Unexpected Output (Still Broken)

❌ **Direct tool usage for agent tasks**:
```
● Read(codebase/file.lua)  ← Should be agent reading this
● Write(reports/001.md)    ← Should be agent writing this
```

❌ **No Task invocations** in output

❌ **Fast completion** (seconds instead of minutes for multi-agent tasks)

---

## Related Issues

### Issue: "Agent created report but in wrong location"
**Solution**: [Phase 1 - Path Pre-Calculation](../guides/execution-enforcement-migration-guide.md#phase-1-add-path-pre-calculation-pattern-1)

### Issue: "Agent didn't create file at all"
**Solution**: [Agent Authoring Guide - Enforcement Patterns](../guides/agent-development-guide.md)

### Issue: "Command skips verification steps"
**Solution**: [Phase 2 - Verification Checkpoints](../guides/execution-enforcement-migration-guide.md#phase-2-add-verification-checkpoints-pattern-2)

### Issue: "Cannot tell what command is doing"
**Solution**: [Phase 3 - Checkpoint Reporting](../guides/execution-enforcement-migration-guide.md#phase-3-add-checkpoint-reporting-pattern-4)

---

## Real-World Example: /report Command

**Symptom**: User runs `/report "authentication patterns"` but gets single report instead of hierarchical multi-agent research.

**Root Cause**: Command opening says "I'll research the specified topic..."

**Investigation**:
```bash
# Check execution output
cat .claude/specs/002_report_creation/example_3.md

# Observed:
# - ● Read(.claude/commands/report.md)
# - ● Read(.claude/docs/concepts/hierarchical_agents.md)
# - ● Write(reports/002_report_command_compliance_analysis.md)
# - No Task tool invocations
# - Single report created

# Conclusion: Command executed research directly, no agents invoked
```

**Fix Applied**:
```markdown
# Before
I'll research the specified topic and create a comprehensive report...

# After
I'll orchestrate hierarchical research by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize
```

**Result**: Command now invokes 2-4 research-specialist agents in parallel, creates subtopic reports + overview, achieves 95% context reduction.

**Debug Report**: [.claude/specs/002_report_creation/debug/002_report_command_not_invoking_subagents.md](../../specs/002_report_creation/debug/002_report_command_not_invoking_subagents.md)

---

## Prevention

When authoring new commands that use agents:

### DO

✅ Open with "I'll orchestrate [task] by delegating..."
✅ Add "**YOUR ROLE**: You are the ORCHESTRATOR" section
✅ Add "DO NOT execute [task] yourself" constraint
✅ Use "EXECUTE NOW" markers for critical operations
✅ Use "STEP N (REQUIRED BEFORE STEP N+1)" format
✅ Test with actual execution, verify Task invocations appear

### DON'T

❌ Open with "I'll [task verb]..." where verb is the agent's task
❌ Describe agent pattern without execution enforcement
❌ Use passive language (should, may, can)
❌ Present bash code and Task templates as examples only
❌ Assume Claude will interpret documentation as executable directives

---

## Quick Reference Template

**Copy-paste template for command openings**:

```markdown
# [Command Name]

I'll orchestrate [task] by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the [executor].

**CRITICAL INSTRUCTIONS**:
- DO NOT execute [task] yourself using [tool-list] tools
- ONLY use Task tool to delegate [task] to [agent-type] agents
- Your job: [step1] → [step2] → [step3] → [step4]

You will NOT see [results] directly. Agents will create [artifacts],
and you will [action] after creation.

## [Description Section]
$ARGUMENTS

## Process

### STEP 1 (REQUIRED BEFORE STEP 2) - [First Step]

**EXECUTE NOW - [Imperative Action]**

YOU MUST run this code block NOW:

```bash
# Actual executable bash code here
```

**CHECKPOINT**:
```
CHECKPOINT: [Step] complete
- [Metric 1]: [value]
- [Metric 2]: [value]
- Proceeding to: [Next step]
```

### STEP 2 (REQUIRED AFTER STEP 1) - [Second Step]

**AGENT INVOCATION - Reference Behavioral File, Inject Context Only**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "[Brief description with mandatory file creation]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context Parameter 1]: [value]
    - [Context Parameter 2]: [value]
    - [Output Path]: [absolute path, pre-calculated]

    Execute per behavioral guidelines. Return: [SIGNAL]: [path]
  "
}
```

**Pattern Notes**:
- Agent behavioral file (e.g., research-specialist.md) contains complete step-by-step instructions
- Command prompt injects ONLY workflow-specific context (paths, parameters, requirements)
- No duplication: all behavioral guidelines in agent file, not inline
- Reduction: ~150 lines → ~15 lines per invocation (90% reduction)
```

---

## See Also

- [Execution Enforcement Migration Guide](../guides/execution-enforcement-migration-guide.md) - Complete migration process
- [Command Authoring Guide](../guides/command-development-guide.md) - Best practices
- [Agent Delegation Issues](agent-delegation-issues.md) - Other delegation problems
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Architecture overview

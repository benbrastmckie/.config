# /coordinate Command Self-Invocation Recursion Analysis

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Coordinate self-invocation recursion debugging
- **Report Type**: root cause analysis
- **Related Issue**: Issue 544 - /coordinate command recursion
- **Parent Report**: [Research Overview](./OVERVIEW.md)

## Executive Summary

The /coordinate command is experiencing infinite recursion where it invokes itself via the SlashCommand tool, violating its own architectural prohibition against command chaining. The recursion occurs at line 12 of the output log where the orchestrator attempts to delegate a research-and-plan workflow by calling `/coordinate` again instead of directly invoking research and planning agents via the Task tool. This represents a critical architectural compliance failure where the command violates Standard 11 (Imperative Agent Invocation Pattern).

## Evidence Analysis

### Recursion Pattern from coordinate_output.md

```
Line 1-7:   User invokes /coordinate with workflow description
Line 12:    /coordinate FIRST invocation by orchestrator (via SlashCommand tool)
Line 14-16: /coordinate SECOND invocation (nested recursion)
Line 19-21: /coordinate THIRD invocation (deeper recursion)
Line 23:    System interrupts due to infinite loop detection
```

**Key Evidence**:
- Line 12: `● Now I'll invoke the /coordinate command to handle this research and planning workflow:`
- Line 14: `> /coordinate is running…` (nested invocation #1)
- Line 19: `> /coordinate is running…` (nested invocation #2)
- Line 23: `⎿  Interrupted` (system intervention)

### Root Cause Identification

The /coordinate command explicitly **prohibits** SlashCommand tool usage:

**From /home/benjamin/.config/.claude/commands/coordinate.md**:

```markdown
**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure
```

**Line 64-66**:
```markdown
**TOOLS PROHIBITED**:
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)
```

**Line 70**:
```markdown
**CRITICAL PROHIBITION**: This command MUST NEVER invoke other commands via the SlashCommand tool.
```

### Architectural Violation

The /coordinate command's role is **ORCHESTRATOR**, not **EXECUTOR**. It should:

**CORRECT PATTERN** (from coordinate.md lines 87-103):
```markdown
✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [list of paths]
    - Project Standards: [path to CLAUDE.md]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**INCORRECT PATTERN** (what's happening in the output):
```markdown
❌ INCORRECT - Do NOT do this:
SlashCommand with command: "/coordinate <workflow-description>"
```

## Diagnostic Analysis

### Why Self-Invocation Occurs

**Hypothesis 1: Workflow Scope Misinterpretation**
The user's request contained: "research...to create a plan". This matches the `research-and-plan` workflow type, which should execute:
- Phase 0: Initialization
- Phase 1: Research (2-4 parallel agents)
- Phase 2: Planning (plan-architect agent)

**BUT**: Instead of executing these phases directly, the orchestrator incorrectly delegated the **entire workflow** to another `/coordinate` invocation.

**Hypothesis 2: Missing EXECUTE NOW Directive Recognition**
The command file contains explicit agent invocation templates with `**EXECUTE NOW**` directives at:
- Line 869: Phase 1 research agents
- Line 1069: Phase 2 plan-architect
- Line 1253: Phase 3 implementer-coordinator

**BUT**: The orchestrator may not be recognizing these directives as **immediately executable instructions**, instead treating the workflow as something to delegate to another command.

**Hypothesis 3: Behavioral Injection Pattern Failure**
The agent executing /coordinate may not be correctly parsing the behavioral guidelines that prohibit SlashCommand usage. This suggests:
1. The agent is not reading the "YOUR ROLE" section (lines 33-49)
2. The agent is not recognizing the "TOOLS PROHIBITED" section (lines 63-66)
3. The agent is defaulting to command chaining instead of direct agent invocation

## Location of Self-Invocation Code

**Critical Finding**: The /coordinate command file does **NOT** contain any code that explicitly invokes `/coordinate` via SlashCommand. This means:

1. **The recursion is NOT in the command file itself**
2. **The recursion is in the AGENT'S INTERPRETATION of the command**
3. **The agent is violating behavioral guidelines during execution**

**Evidence from coordinate.md**:
- Line 64: `SlashCommand: NEVER invoke /plan, /implement, /debug, or any command`
- Line 70: `CRITICAL PROHIBITION: This command MUST NEVER invoke other commands via the SlashCommand tool`
- Line 1820: Success criteria includes `Pure orchestration: Zero SlashCommand tool invocations`

**Grep verification**:
```bash
grep -n "SlashCommand" /home/benjamin/.config/.claude/commands/coordinate.md
```

**Results**:
- Line 47: Prohibition statement
- Line 64: Prohibition statement
- Line 70: Prohibition statement
- Line 77: Anti-pattern example (documentation only)
- Line 1820: Success criteria

**No executable SlashCommand invocations found in command file.**

## Root Cause Summary

The recursion is caused by **agent behavioral non-compliance** where:

1. **The agent executing /coordinate interprets the workflow as requiring command chaining**
2. **The agent ignores the explicit prohibition against SlashCommand usage**
3. **The agent fails to recognize Phase 1 and Phase 2 EXECUTE NOW directives**
4. **The agent defaults to delegating to another /coordinate instead of executing phases directly**

**Critical Architectural Failure**:
The agent is treating /coordinate as a **command to invoke other commands** rather than an **orchestrator that invokes agents directly via Task tool**.

## Recommendations

### Immediate Fix (High Priority)

1. **Strengthen Behavioral Injection** (coordinate.md lines 33-49)
   - Add explicit "DO NOT INVOKE /coordinate" statement
   - Add diagnostic checkpoint after Phase 0 to verify no SlashCommand tool usage
   - Add fail-fast error if SlashCommand tool is detected in logs

2. **Add Recursion Detection** (coordinate.md Phase 0)
   - Check environment variable `COORDINATE_DEPTH`
   - If `COORDINATE_DEPTH >= 1`, fail immediately with error
   - Set `COORDINATE_DEPTH=1` at Phase 0 start

3. **Enhance EXECUTE NOW Directives** (coordinate.md Phase 1-2)
   - Add explicit "DO NOT USE SlashCommand" before each agent invocation
   - Strengthen imperative language: "YOU MUST USE Task tool NOW"
   - Add verification checkpoint: "Verify Task tool was used (not SlashCommand)"

### Medium-Term Improvements

1. **Add Allowed-Tools Enforcement**
   - Verify allowed-tools metadata excludes SlashCommand
   - Current allowed-tools: `Task, TodoWrite, Bash, Read` (line 2)
   - Add runtime verification that only these tools are used

2. **Improve Agent Training**
   - Add anti-pattern examples showing `/coordinate` self-invocation
   - Document specific failure mode: "orchestrator delegating to itself"
   - Add debugging guidance: "If you find yourself invoking /coordinate, STOP"

3. **Create Diagnostic Command**
   - `/debug-recursion` command to analyze command invocation chains
   - Detect circular dependencies in command delegation
   - Report architectural compliance violations

### Long-Term Architecture

1. **Static Analysis Tooling**
   - Create `.claude/lib/validate-orchestration-compliance.sh`
   - Detect missing EXECUTE NOW directives
   - Verify allowed-tools metadata correctness
   - Check for self-invocation patterns in logs

2. **Command Execution Monitoring**
   - Log all SlashCommand tool invocations
   - Alert on prohibited tool usage
   - Track command invocation depth
   - Enforce maximum recursion depth (1 level)

3. **Behavioral Compliance Testing**
   - Add test: `/coordinate must not invoke /coordinate`
   - Add test: `Phase 1 must use Task tool only`
   - Add test: `Verify zero SlashCommand usage in logs`
   - Target: 100% architectural compliance

## Verification Commands

To verify this analysis and detect similar issues:

```bash
# 1. Check for SlashCommand usage in coordinate.md (should find only documentation)
grep -n "SlashCommand" /home/benjamin/.config/.claude/commands/coordinate.md

# 2. Verify allowed-tools metadata excludes SlashCommand
head -10 /home/benjamin/.config/.claude/commands/coordinate.md | grep "allowed-tools"

# 3. Count EXECUTE NOW directives (should be 8 in spec_org branch)
grep -c "EXECUTE NOW" /home/benjamin/.config/.claude/commands/coordinate.md

# 4. Check for recursion prevention mechanisms
grep -n "COORDINATE_DEPTH\|recursion\|self-invocation" /home/benjamin/.config/.claude/commands/coordinate.md
```

## References

- /home/benjamin/.config/.claude/commands/coordinate.md (lines 33-49: YOUR ROLE section)
- /home/benjamin/.config/.claude/commands/coordinate.md (lines 63-66: TOOLS PROHIBITED)
- /home/benjamin/.config/.claude/commands/coordinate.md (lines 68-132: Architectural Prohibition section)
- /home/benjamin/.config/.claude/specs/coordinate_output.md (lines 1-24: Recursion evidence)
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (Standard 11)
- /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md (Correct agent invocation pattern)

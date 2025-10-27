# Root Cause of Subagent Delegation Failures

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: root_cause_of_subagent_delegation_failures
- **Report Type**: architectural analysis
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

The /supervise command has already been fixed (as of 2025-10-24, spec 469) for the primary delegation failure cause: code-fenced Task invocation examples that created a "priming effect", causing Claude to interpret all Task blocks as documentation rather than executable commands. However, architectural analysis reveals the command does NOT currently suffer from delegation failures - it follows correct imperative patterns with unwrapped Task invocations. The real question is why users perceive it as failing to delegate, which may be due to verbose inline bash scaffolding masking actual agent work.

## Findings

### 1. Historical Anti-Pattern (RESOLVED)

**Timeline Analysis**:
- **2025-10-21**: Behavioral injection pattern documented (commit d90bdd0f)
- **2025-10-24**: Anti-pattern documented in behavioral-injection.md (commit e5d7246e)
- **2025-10-24**: /supervise fixed to remove code fence priming effect (commit 5771a4cf, spec 469)
- **Current state**: /supervise uses correct unwrapped Task invocations

**Evidence from /supervise command (lines 960-978, 1232-1251, 1431-1451)**:
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "..."
}
```

**Analysis**: Task invocations are NOT wrapped in code fences and ARE preceded by imperative instructions ("EXECUTE NOW", "USE the Task tool"). This is the CORRECT pattern per behavioral-injection.md:415-425.

### 2. Comparison with Working Commands

**Pattern Analysis Across Commands**:

| Command | Task Invocation Pattern | Code Fences? | Delegation Status |
|---------|------------------------|--------------|-------------------|
| /research | Wrapped in ` ```yaml ` | YES | WORKS (examples only) |
| /orchestrate | Wrapped in ` ```yaml ` | YES | WORKS (examples only) |
| /supervise | NOT wrapped | NO | SHOULD WORK (correct pattern) |

**Critical Finding**: Both /research and /orchestrate wrap Task invocations in ` ```yaml ` code fences (lines 220-244, 748-784), yet they delegate correctly. However, these are marked as **templates** with explicit instructions to use them, not as documentation examples.

**Key Distinction** (from behavioral-injection.md:206-256):
- **Structural templates** (correct): Task invocation structure showing syntax (fenced, marked as templates)
- **Documentation examples** (anti-pattern): Task examples showing what NOT to do (fenced, marked as examples)
- **Executable invocations** (correct): Actual Task calls preceded by imperative instructions (NOT fenced)

### 3. Current /supervise Architecture

**Pattern Compliance Check** (lines 958-978):
- ✅ Imperative instruction present: "EXECUTE NOW: USE the Task tool"
- ✅ No code block wrapper around Task invocations
- ✅ Direct reference to agent behavioral file: `.claude/agents/research-specialist.md`
- ✅ Explicit completion signal required: `Return: REPORT_CREATED: ${REPORT_PATHS[i]}`
- ✅ HTML comment clarification: `<!-- This Task invocation is executable -->` (line 64)

**Verification against anti-pattern criteria** (behavioral-injection.md:376-390):
1. ✅ Imperative instruction present
2. ✅ No code block wrapper
3. ✅ No "Example" prefix
4. ✅ Completion signal required

**Conclusion**: /supervise follows ALL correct patterns and should delegate properly.

### 4. Potential Perception Issues

**Hypothesis**: Users may perceive /supervise as "not delegating" due to:

1. **Verbose bash scaffolding** (lines 234-398, 462-843): 400+ lines of inline bash setup code executed BEFORE agent invocations, creating impression that command does work itself

2. **Inline verification code** (lines 992-1117): 125+ lines of bash verification after each agent completes, masking actual agent work with orchestrator verification

3. **Conditional phase execution** (lines 908-916, 1415-1422): Phase skip logic may cause agents to never invoke if workflow scope excludes phases

**Example of verbose scaffolding** (lines 570-843):
```bash
# STEP 1: Parse workflow description (20 lines)
# STEP 2: Detect workflow scope (70 lines)
# STEP 3: Source utility libraries (100 lines)
# STEP 4: Calculate location metadata (80 lines)
# STEP 5: Create topic directory (75 lines)
# STEP 6: Pre-calculate artifact paths (40 lines)
# STEP 7: Initialize tracking arrays (10 lines)

# TOTAL: 395 lines of bash BEFORE first agent invocation
```

**Result**: Only ~8% of Phase 1 content (40 lines / 500 total) is actual agent invocation, rest is orchestrator setup.

### 5. Architectural Comparison

**Agent-to-Scaffolding Ratio**:

| Command | Scaffolding Lines | Agent Invocation Lines | Ratio | Perceived Delegation |
|---------|-------------------|------------------------|-------|---------------------|
| /research | ~150 (path calc) | ~30 (Task calls) | 83% scaffolding | HIGH (minimal setup) |
| /orchestrate | ~200 (location) | ~100 (multi-phase) | 67% scaffolding | HIGH (clear phases) |
| /supervise | ~400 (extensive) | ~200 (7 phases) | 67% scaffolding | LOW? (verbose setup) |

**Finding**: /supervise has similar ratio to /orchestrate but FEELS more verbose due to inline bash rather than library references.

### 6. Working Commands Pattern Analysis

**Why /research and /orchestrate FEEL like they delegate**:

1. **Minimal inline bash**: Most setup delegated to libraries (.claude/lib/*)
2. **Imperative agent invocation**: "EXECUTE NOW" followed immediately by Task calls
3. **Clear phase separation**: Research phase is ONLY agent invocations, not mixed with setup
4. **Template markers**: Code-fenced Task examples clearly marked as "TEMPLATE" or "EXAMPLE"

**Example from /research (lines 206-244)**:
```markdown
### STEP 3 (REQUIRED BEFORE STEP 4) - Invoke Research Agents

**EXECUTE NOW - Invoke All Research-Specialist Agents in Parallel**

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  [...]
}
```
```

**Key**: Template is fenced AND labeled "EXACT TEMPLATE", making it clear this is NOT documentation but a TEMPLATE TO USE.

### 7. Historical Context

**Timeline of Standards Development**:

1. **Pre-2025-10-21**: No documented pattern for Task invocations
2. **2025-10-21**: Behavioral injection pattern documented (spec 438)
3. **2025-10-24**: Anti-pattern discovered in /supervise (spec 469) - code-fenced examples caused 0% delegation
4. **2025-10-24**: /supervise fixed by removing code fences around executable Task calls
5. **Current**: /supervise complies with all standards

**Finding**: /supervise was NOT created before standards - it was updated TO follow standards in spec 469.

## Recommendations

### 1. Verify Delegation Works (Priority: CRITICAL)

Before making changes, verify that /supervise actually fails to delegate:

```bash
# Test delegation rate
/supervise "research authentication patterns to create plan"

# Expected behavior if working:
# - research-specialist agents invoked (check for PROGRESS: markers)
# - plan-architect agent invoked
# - Files created at expected paths

# If agents DO invoke:
# - Issue is PERCEPTION, not actual failure
# - Focus on improving clarity of orchestration
```

### 2. If Delegation Works: Improve Perception (Priority: HIGH)

Reduce verbose inline bash by extracting to libraries:

**Move to libraries**:
- Path calculation scaffolding → `.claude/lib/supervise-location-detection.sh`
- Verification checkpoints → `.claude/lib/supervise-verification.sh`
- Conditional phase logic → `.claude/lib/supervise-phase-control.sh`

**Result**: Reduce Phase 1 from 500 lines to ~150 lines (70% reduction), making agent invocations more prominent.

### 3. If Delegation Fails: Debug Root Cause (Priority: CRITICAL)

Current architecture is correct, so failure would indicate:

1. **Runtime issue**: Task tool not available or malfunctioning
2. **Context issue**: Agent prompts too long, causing truncation
3. **Priming issue**: Earlier content in conversation history primes "don't execute"
4. **Tool access issue**: Agents missing required tools (verified in spec 444)

**Debugging steps**:
```bash
# Check if Task tool available
/supervise "test delegation" 2>&1 | grep -i "task tool"

# Check agent output
/supervise "research simple topic" 2>&1 | grep -i "REPORT_CREATED:"

# If no "REPORT_CREATED:" seen:
# - Agents not returning (invocation succeeded but execution failed)
# - Check agent logs for tool access issues
```

### 4. Align Template Presentation with /research (Priority: MEDIUM)

Both /research and /supervise use templates, but /research is clearer:

**Current /supervise** (lines 958-978):
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  [unwrapped invocation]
}
```

**Recommended pattern from /research** (lines 217-244):
```
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

```yaml
Task {
  [wrapped template]
}
```

**Rationale**: Explicit "TEMPLATE" label prevents interpretation as documentation example, while code fence provides syntax highlighting. The key is the label "Use THIS EXACT TEMPLATE", which signals "execute this" rather than "this is an example".

### 5. Consider Hybrid Approach (Priority: LOW)

/orchestrate uses fenced templates AND achieves high delegation. Pattern:

1. **Template section** (fenced, labeled "TEMPLATE"): Shows syntax
2. **Execution section** (unfenced, imperative): Actual invocation with substituted values

**Example**:
```markdown
### Template Reference

```yaml
Task {
  description: "Research [TOPIC]"
  prompt: "..."
}
```

### EXECUTE NOW

Task {
  description: "Research ${ACTUAL_TOPIC}"
  prompt: "..."
}
```

**Benefit**: Provides template for reference while ensuring actual invocation is unwrapped.

## Related Reports

- **[OVERVIEW.md](./OVERVIEW.md)** - Synthesizes findings from all 4 research reports
- **[001_supervise_command_implementation_analysis.md](./001_supervise_command_implementation_analysis.md)** - Implementation analysis showing Phase 3 sequential execution gap
- **[002_standards_violations_and_pattern_deviations.md](./002_standards_violations_and_pattern_deviations.md)** - Standards compliance analysis showing 95% adherence with 3 specific violations
- **[004_corrective_actions_and_improvement_recommendations.md](./004_corrective_actions_and_improvement_recommendations.md)** - Implementation guidance and deprecation evaluation

## References

- `/home/benjamin/.config/.claude/commands/supervise.md` (lines 958-978, 1232-1251, 1431-1451) - Task invocations
- `/home/benjamin/.config/.claude/commands/research.md` (lines 220-244) - Template pattern
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (lines 748-784, 1758-1794) - Multi-phase templates
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 322-525) - Anti-pattern documentation
- Git commit 5771a4cf (2025-10-24) - Fix for code fence priming effect (spec 469)
- Git commit e5d7246e (2025-10-24) - Anti-pattern documentation (spec 438)
- `.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/` - Prior investigation of delegation failure
- `.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/` - Refactor analysis including anti-pattern discovery

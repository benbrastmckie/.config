# Current Plan Tool Restriction Analysis

## Research Metadata
- **Topic**: Analysis of tool restriction approach in plan 001_fix_research_command_allowed_tools.md
- **Date**: 2025-10-24
- **Status**: Complete
- **Plan Path**: /home/benjamin/.config/.claude/specs/444_research_allowed_tools_fix/plans/001_fix_research_command_allowed_tools.md

## Related Reports
- [Overview Report](./OVERVIEW.md) - Comprehensive synthesis of all research findings
- [Alternative Delegation Enforcement Mechanisms](./002_alternative_delegation_enforcement_mechanisms.md) - Survey of enforcement patterns
- [Post-Research Primary Agent Flexibility Requirements](./003_post_research_primary_agent_flexibility_requirements.md) - Post-delegation tool requirements
- [Tool Permission Architecture Tradeoffs](./004_tool_permission_architecture_tradeoffs.md) - Enforcement approach tradeoffs

## Executive Summary

The plan proposes a **simple yet architecturally sound fix**: reduce `/research` command's `allowed-tools` from 8 tools (Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task) to just 2 tools (Task, Bash). This enforces the hierarchical multi-agent delegation pattern by making it **impossible** for the orchestrator to conduct research directly.

**Root Cause Identified**: Tool availability overrides behavioral instructions. Despite explicit "DO NOT execute research yourself" warnings, agents use available tools when it's more efficient than delegation.

**Solution Approach**: Permission-level enforcement. Remove research tools, keep only Task (for delegation) and Bash (for setup/verification scripts).

**Assessment**: This is a **well-designed minimal fix** that addresses the root cause correctly. The plan demonstrates thorough analysis with clear rationale, comprehensive workflow impact analysis, and appropriate testing strategy.

## Plan Overview

### Problem Statement

The `/research` command (lines 1-430 of research.md) is configured with excessive tool permissions that enable the orchestrator agent to bypass the intended hierarchical delegation pattern. Current configuration (line 2):

```yaml
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task
```

**Issue**: 7 of 8 tools enable direct research execution, contradicting the command's architectural role as an orchestrator.

### Proposed Solution

**Target Configuration** (plan lines 38-42):
```yaml
allowed-tools: Task, Bash
```

**Rationale**:
- **Task**: Required for delegating to research-specialist and research-synthesizer agents
- **Bash**: Required for executing decomposition scripts, path calculation, verification checkpoints
- **Removed**: Read, Write, Grep, Glob, WebSearch, WebFetch (research tools that bypass delegation)

### Implementation Strategy

**3-Phase Approach** (plan lines 96-221):

1. **Phase 1** (Complexity: Low) - Modify allowed-tools configuration
   - Single-line change in research.md:2
   - Update YAML frontmatter
   - Document rationale in commit message

2. **Phase 2** (Complexity: Medium) - Validate workflow compatibility
   - Review all bash script blocks (lines 40-50, 82-160, 238-300, 308-318)
   - Verify scripts don't require removed tools
   - Confirm Task tool invocations remain functional
   - Check verification checkpoints use bash-only commands

3. **Phase 3** (Complexity: Medium) - Integration testing
   - Create test script for delegation verification
   - Run /research with sample topic
   - Verify primary agent uses only Task and Bash tools
   - Confirm research activities occur in subagent context only
   - Validate report creation workflow

## Tool Restriction Analysis

### Current State (research.md:2)

**Orchestrator Tools** (8 total):
- `Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task`

**Problem**: 7 tools enable direct execution, only 1 (Task) enforces delegation.

**Agent Tools** (research-specialist.md:2):
- `Read, Write, Grep, Glob, WebSearch, WebFetch` (6 tools)
- No Task tool (agents are executors, not orchestrators)

**Pattern Violation**: Orchestrator and agent have overlapping tool permissions, enabling orchestrator to do agent work.

### Proposed State

**Orchestrator Tools** (2 total):
- `Task, Bash`

**Agent Tools** (unchanged):
- `Read, Write, Grep, Glob, WebSearch, WebFetch`

**Pattern Enforcement**: Zero overlap. Orchestrator can only delegate (Task) and execute scripts (Bash), not conduct research.

### Workflow Impact

**Preserved Capabilities** (plan lines 51-58):
1. Topic decomposition via bash scripts (research.md lines 40-50)
2. Path pre-calculation via bash scripts (lines 82-160)
3. Directory verification checkpoints (lines 99-106, 122-126)
4. Subtopic report path calculation (lines 131-144)
5. Agent invocation via Task tool (lines 172-225, 321-360, 376-430)
6. Report verification via bash (lines 238-300)

**Removed Capabilities** (plan lines 59-64, intentionally restricted):
1. Direct file reading (Read tool)
2. Direct file writing (Write tool)
3. Direct codebase searching (Grep/Glob tools)
4. Direct web research (WebSearch/WebFetch tools)

**Critical Insight**: All bash-based operations (path calculation, verification) use bash string manipulation and file system commands only. No reliance on removed tools.

### Enforcement Mechanism

**Before Fix** (plan lines 72-77):
```
Agent sees instruction: "DO NOT research yourself"
Agent has tools: WebSearch, Read, Grep, etc.
Agent decision: "I'll use available tools anyway" ❌
```

**After Fix** (plan lines 79-84):
```
Agent sees instruction: "DO NOT research yourself"
Agent has tools: Task, Bash only
Agent decision: "I must delegate (no research tools)" ✅
```

**Architecture Principle** (plan lines 300-303): "Tool constraints should enforce architectural patterns, not rely on behavioral instructions alone."

## Related Files and Context

### Behavioral Injection Pattern

**File**: /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md

**Key Concepts** (lines 1-35):
- Commands inject context into agents via Task tool, not SlashCommand
- Separates orchestrator role (path calculation, delegation, verification) from agent role (execution)
- Solves two problems:
  1. **Role Ambiguity**: "I'll research" interpreted as direct execution
  2. **Context Bloat**: Command-to-command invocations cause exponential context growth
- Results: 100% file creation rate, <30% context usage, hierarchical coordination

**Connection to Plan**: The tool restriction plan implements this pattern at the permission level. Behavioral injection requires clear role separation, which tool constraints enforce.

### Troubleshooting Guide

**File**: /home/benjamin/.config/.claude/docs/troubleshooting/command-not-delegating-to-agents.md

**Symptoms of Non-Delegation** (lines 14-21):
- Command uses Read/Write/Grep/Edit tools directly for agent tasks
- No Task tool invocations visible in output
- Single artifact created instead of multiple subtopic artifacts
- No progress markers from subagents
- No "REPORT_CREATED:" return messages
- Execution faster than expected (no parallel processing)

**Root Cause Analysis** (lines 49-66):
- Commands with "I'll [task verb]..." opening → Claude interprets as direct execution
- Sections describing agent pattern appear as documentation, not directives
- Bash code blocks and Task templates appear as examples, not commands
- No explicit "DO NOT execute this yourself" constraint

**Quick Fix** (lines 71-103):
- Update command opening to "I'll orchestrate [task] by delegating..."
- Add "YOUR ROLE: You are the ORCHESTRATOR" section
- Add "DO NOT execute [task] yourself using [tools]" constraint
- Use "EXECUTE NOW" markers for critical operations

**Real-World Example** (lines 215-252): /report command had identical issue - opened with "I'll research...", executed directly. Fixed by role clarification + tool restrictions.

**Connection to Plan**: The troubleshooting guide documents behavioral fixes (language/structure). This plan complements with technical fixes (permission constraints).

### Orchestrator Pattern Reference

**File**: /home/benjamin/.config/.claude/commands/orchestrate.md

**Critical Architectural Pattern** (lines 10-30):
- `/orchestrate` MUST NEVER invoke other slash commands
- FORBIDDEN TOOLS: SlashCommand
- REQUIRED PATTERN: Task tool → Specialized agents

**Why This Matters** (lines 17-26):
1. **Context Bloat**: SlashCommand expands entire command prompts (3000+ tokens each)
2. **Broken Behavioral Injection**: Commands invoked via SlashCommand cannot receive artifact path context
3. **Lost Control**: Orchestrator cannot customize agent behavior or inject topic numbers
4. **Anti-Pattern Propagation**: Sets bad example for future command development

**Current Configuration** (orchestrate.md:2):
```yaml
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
```

**Issue Identified**: `/orchestrate` suffers from the same problem as `/research`! It has Read/Write/Grep/Glob tools that enable direct execution. Plan mentions this (lines 311-313):
> Related Issues:
> - /orchestrate may have similar allowed-tools configuration issues
> - All commands following behavioral injection pattern should be reviewed

**Orchestrator Role** (lines 42-44):
- DO NOT execute research/planning/implementation/testing/debugging/documentation yourself
- ONLY use Task tool to invoke specialized agents for each phase

**Connection to Plan**: `/orchestrate` demonstrates the pattern `/research` should follow. However, `/orchestrate` itself needs the same fix.

### Tool Restriction Patterns

**File**: /home/benjamin/.config/.claude/docs/reference/agent-reference.md

**Tool Restrictions** (line 308):
> Tool Restrictions: Agents can ONLY use tools listed in their allowed-tools. Attempting to use unlisted tools will result in permission errors.

**Connection to Plan**: This confirms tool restrictions are technically enforceable, not just advisory.

### Allowed-Tools Survey

**Search Results**: Grep search across .claude/commands/ revealed 31 command files with allowed-tools configuration.

**Pattern Analysis**:
- **Orchestrator Commands** (should use Task + limited utilities):
  - `/orchestrate`: Task, TodoWrite, Read, Write, Bash, Grep, Glob ❌ (has research tools)
  - `/supervise`: Task, TodoWrite, Bash, Read ✅ (minimal tools)
  - `/research`: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task ❌ (excessive)
  - `/debug`: Read, Bash, Grep, Glob, WebSearch, WebFetch, TodoWrite, Task ❌ (excessive)

- **Implementation Commands** (need direct file manipulation):
  - `/implement`: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand ✅
  - `/revise`: Read, Write, Edit, Glob, Grep, Task, MultiEdit, TodoWrite, SlashCommand ✅
  - `/document`: Read, Write, Edit, MultiEdit, Grep, Glob, Task, TodoWrite ✅

- **Research Commands** (should delegate or execute directly):
  - `/report`: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task ❌ (same issue as /research)
  - `/plan`: Read, Write, Bash, Grep, Glob, WebSearch ✅ (no Task = direct execution intended)

**Finding**: At least 4 orchestrator commands have excessive tool permissions: /research, /orchestrate, /debug, /report.

## Key Findings

### Finding 1: Root Cause Analysis is Correct

**Evidence** (plan lines 14-18):
> Tool availability overrides behavioral instructions. Despite explicit instructions "DO NOT execute research yourself," the agent uses available research tools to complete tasks directly because it's more efficient than delegation.

**Validation**: This is confirmed by:
- Troubleshooting guide documentation (command-not-delegating-to-agents.md lines 49-66)
- Real-world /report command regression (mentioned in troubleshooting guide lines 215-252)
- Behavioral injection pattern rationale (behavioral-injection.md lines 16-28)

**Assessment**: The plan correctly identifies that **permission-level enforcement is necessary** because behavioral instructions alone are insufficient.

### Finding 2: Proposed Solution is Architecturally Sound

**Tool Selection Rationale** (plan lines 44-48):
- **Task**: Required for agent delegation (core orchestrator function)
- **Bash**: Required for path calculation, verification checkpoints, setup scripts
- **Removed Tools**: All research execution tools

**Validation**: Bash script analysis confirms no dependency on removed tools:
- Path calculation: Uses bash string manipulation, `dirname`, `basename` (research.md lines 82-160)
- Topic decomposition: Sources bash libraries, calls functions (lines 40-50)
- Verification: Uses bash `test` operators, `find`, `wc` commands (lines 238-300)
- Agent invocation: Uses Task tool only (lines 172-225)

**Assessment**: The tool selection is **minimal and sufficient**. No over-restriction, no under-restriction.

### Finding 3: Workflow Compatibility is Preserved

**Preserved Operations** (plan lines 51-58):
1. Topic decomposition ✅ (bash source + function calls)
2. Path pre-calculation ✅ (bash string manipulation)
3. Directory verification ✅ (bash test operators)
4. Subtopic path calculation ✅ (bash for-loops + string ops)
5. Agent invocation ✅ (Task tool retained)
6. Report verification ✅ (bash find + test commands)

**Removed Operations** (plan lines 59-64):
1. Direct file reading ❌ (intentionally restricted)
2. Direct file writing ❌ (intentionally restricted)
3. Direct codebase searching ❌ (intentionally restricted)
4. Direct web research ❌ (intentionally restricted)

**Assessment**: All orchestration functions are preserved. All execution functions are removed (as intended).

### Finding 4: Testing Strategy is Comprehensive

**Test Script Design** (plan lines 164-210):
1. Configuration validation (grep allowed-tools, verify "Task,Bash")
2. Manual delegation verification (requires actual /research invocation)
3. Automated checks (parse allowed-tools from file)
4. Clear pass/fail criteria

**Validation Criteria** (plan lines 212-218):
- Primary agent shows Task tool usage only
- Agent invocation prompts appear in execution log
- PROGRESS markers from subagents visible
- Research reports created at correct paths
- No WebSearch/Read/Grep in primary agent context
- Overview synthesis via research-synthesizer invocation

**Assessment**: Testing approach balances automation (configuration checks) with manual verification (delegation behavior). Criteria are specific and measurable.

### Finding 5: Plan Identifies Broader Systemic Issue

**Related Issues Section** (plan lines 311-314):
> - /orchestrate may have similar allowed-tools configuration issues
> - All commands following behavioral injection pattern should be reviewed
> - Agent development guide should document tool restriction patterns
> - Create linting rule to detect orchestrator commands with research tools

**Validation**: Grep search confirms multiple commands need similar fixes:
- `/orchestrate`: Has Read, Write, Grep, Glob (should be Task, TodoWrite, Bash only)
- `/debug`: Has Read, Grep, Glob, WebSearch, WebFetch (should delegate more aggressively)
- `/report`: Has same excessive tools as /research (should delegate like /research)

**Assessment**: This plan is **Phase 1 of a broader refactoring effort**. The principles apply to multiple orchestrator commands.

### Finding 6: Risk Assessment is Realistic

**Identified Risks** (plan lines 271-283):
1. Bash scripts might fail if inadvertently using removed tools
   - **Mitigation**: Phase 2 validates all bash blocks
   - **Fallback**: Add Read tool back if absolutely required
2. Agent invocation might fail if Task tool has issues
   - **Mitigation**: Test Task tool separately before deployment
   - **Fallback**: Add minimal tools back if delegation broken
3. Performance impact from more agent invocations
   - **Mitigation**: Architectural intent (parallel subagents expected)
   - **Benefit**: Enforced delegation validates hierarchical pattern

**Assessment**: Risks are **low and mitigable**. The single-line change is easily reversible (plan includes rollback procedure, lines 318-337).

## Evaluation and Recommendations

### Strengths of Current Plan

1. **Correct Root Cause**: Identifies that tool availability overrides behavioral instructions
2. **Minimal Change**: Single-line configuration change reduces risk
3. **Thorough Analysis**: Comprehensive workflow impact analysis validates tool selection
4. **Clear Testing**: Automated + manual verification with specific criteria
5. **Reversible**: Includes rollback plan for quick recovery if issues arise
6. **Future-Oriented**: Identifies broader systemic issue affecting multiple commands

### Potential Issues

1. **Phase 2 Manual Review**: Plan requires manual review of bash blocks (lines 122-145). Consider automated verification:
   ```bash
   # Check for direct tool usage patterns
   grep -n "Read(\\|Write(\\|Grep(\\|Glob(\\|WebSearch(\\|WebFetch(" research.md
   ```

2. **Test Coverage Gap**: Test script (lines 164-210) validates configuration but requires manual delegation testing. Consider automated delegation detection:
   ```bash
   # Parse execution log for Task invocations
   grep "Task(subagent_type:" execution_log.txt
   ```

3. **Related Command Updates**: Plan mentions /orchestrate, /debug, /report need similar fixes but doesn't provide timeline or priority. Recommend creating umbrella plan.

### Recommendations

#### Recommendation 1: Approve Plan as Written

**Rationale**: The plan is well-researched, minimal risk, high architectural value, and easily reversible. Proceed with 3-phase implementation.

**Suggested Additions**:
- Add automated bash block verification to Phase 2
- Add delegation detection automation to Phase 3
- Create follow-up issue for /orchestrate, /debug, /report

#### Recommendation 2: Create Umbrella Plan for Orchestrator Tool Restrictions

**Scope**: Apply same principles to all orchestrator commands

**Commands to Review**:
- `/orchestrate` (priority: high, most complex orchestrator)
- `/report` (priority: high, same issue as /research)
- `/debug` (priority: medium, less frequently used)
- `/supervise` (priority: low, already minimal tools)

**Approach**: Create comparative analysis plan showing before/after configurations for all orchestrator commands.

#### Recommendation 3: Document Tool Restriction Pattern

**Location**: .claude/docs/guides/command-development-guide.md

**Content**:
- **Principle**: "Tool constraints enforce architectural patterns"
- **Orchestrator Pattern**: Task + minimal utilities (Bash, TodoWrite)
- **Agent Pattern**: Execution tools (Read, Write, Grep, Glob, WebSearch, WebFetch)
- **Implementation Pattern**: Direct manipulation tools (Read, Edit, Write, Bash)
- **Verification**: Linting rules to detect violations

#### Recommendation 4: Create Linting Tool

**Purpose**: Detect orchestrator commands with excessive tool permissions

**Implementation**:
```bash
# Pseudo-code for linter
for cmd_file in .claude/commands/*.md; do
  if grep -q "orchestrate\\|coordinate\\|delegate" "$cmd_file"; then
    # This is an orchestrator command
    allowed_tools=$(grep "^allowed-tools:" "$cmd_file" | cut -d: -f2)
    if echo "$allowed_tools" | grep -qE "Read|Write|Grep|Glob|WebSearch|WebFetch"; then
      echo "WARNING: $cmd_file has excessive tools for orchestrator"
    fi
  fi
done
```

**Integration**: Add to CI/CD pipeline or pre-commit hooks

### Summary Assessment

**Overall Assessment**: The plan is **excellent**. It demonstrates:
- Correct root cause analysis
- Minimal, targeted solution
- Comprehensive validation
- Clear testing strategy
- Awareness of broader implications

**Confidence Level**: High (90%)

**Recommended Action**: Approve for implementation with suggested automation enhancements.

**Follow-Up Required**: Create umbrella plan for systemic orchestrator tool restriction refactoring across /orchestrate, /report, /debug commands.

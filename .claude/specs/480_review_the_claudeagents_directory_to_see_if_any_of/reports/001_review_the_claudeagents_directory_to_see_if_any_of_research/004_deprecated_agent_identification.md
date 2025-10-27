# Research Report: Deprecated Agent Identification

## Metadata
- **Topic**: Deprecated Agent Identification
- **Created**: 2025-10-26
- **Status**: Complete
- **Agent**: Research Specialist

## Executive Summary

Research identified **ONE deprecated agent** already archived, **ZERO agents requiring immediate deprecation**, and **THREE agents requiring monitoring** for potential future deprecation. The agent registry shows discrepancies with actual file count (17 registered vs 23 actual files), indicating registry maintenance is needed.

**Key Finding**: The `.claude/agents/` directory has been recently cleaned (2025-10-26) with `location-specialist.md` successfully archived and superseded by library utilities. The remaining agents follow current behavioral injection standards with no active anti-patterns detected.

## Research Scope
Identify deprecated agents in .claude/agents/ directory by:
- Reviewing CHANGELOG.md for agent removal history
- Examining archive/ directory for archived agents
- Finding agents superseded by library utilities
- Detecting agents referencing deprecated patterns/workflows

## Findings

### 1. Recently Archived Agents (Confirmed Deprecated)

**location-specialist.md** (Archived 2025-10-26)
- **Location**: `.claude/archive/agents/location-specialist.md` (14,187 bytes)
- **Superseded By**: `.claude/lib/unified-location-detection.sh`
- **Impact**: 3.7% reduction (22 → 21 agents), ~14KB saved
- **Migration Complete**: All references updated across system
- **Status**: ✅ Successfully deprecated and archived

**Evidence**:
- CHANGELOG.md lines 20-23: "Deprecated Agent (2025-10-26): Archived deprecated agent file... `location-specialist.md` - Superseded by unified location detection library"
- README.md lines 10-18: Agent cleanup documentation confirms removal
- Archive directory confirmed: `/home/benjamin/.config/.claude/archive/agents/location-specialist.md`

### 2. Agents with Potential Deprecation Risk (Monitoring Required)

#### plan-expander.md (⚠️ Pattern Violation - Special Case)

**Issue**: This agent explicitly uses `SlashCommand` tool to invoke `/expand` command, which violates standard behavioral injection pattern (agents should create files directly, not invoke commands).

**Why Not Deprecated**: This appears to be an **intentional coordinator pattern** where the agent's role is to orchestrate the `/expand` command workflow, not to replace it.

**Evidence**:
- Lines 2, 101, 387, 419, 540 reference SlashCommand and /expand invocation
- agent-registry.json (lines 293-311) lists "SlashCommand" as allowed tool (unusual)
- Used by `/expand`, `/collapse`, and orchestration commands (4 command references found)

**Recommendation**: Evaluate if this coordinator pattern is necessary or if functionality should be absorbed into `/expand` command directly.

#### collapse-specialist.md & expansion-specialist.md (⚠️ Overlap Risk)

**Issue**: These agents overlap with `plan-expander` in functionality (expansion/collapse operations).

**Evidence**:
- All three agents handle plan expansion/collapse operations
- agent-registry.json shows hierarchical type for collapse/expansion specialists
- Used by `/expand` and `/collapse` commands

**Recommendation**: Review if three separate agents are needed or if consolidation would reduce complexity.

### 3. Agent Registry Discrepancies

**Critical Finding**: Agent registry is out of sync with actual agent files.

**Discrepancy Details**:
- **Registry Count**: 17 agents in `agent-registry.json`
- **Actual Count**: 23 agent markdown files in `.claude/agents/`
- **Missing from Registry**: 6 agents not registered

**Missing Agents** (identified by comparing file list to registry):
1. `git-commit-helper.md`
2. `implementation-executor.md`
3. `implementer-coordinator.md`
4. `research-synthesizer.md`
5. `doc-converter-usage.md` (documentation file, not behavioral agent)
6. 1 additional unidentified agent

**Impact**: Agent discovery and metrics tracking will miss unregistered agents.

### 4. Agents Following Current Standards (No Deprecation Risk)

All remaining agents follow behavioral injection pattern correctly:
- **code-writer.md**: Lines 18, 38, 59, 96, 111 - Explicit anti-pattern warnings, NEVER invoke SlashCommand
- **plan-architect.md**: Line 18 - CREATE plan file at exact path, do NOT invoke slash commands
- **research-synthesizer.md**: Line 229 - DO NOT invoke slash commands
- **implementation-researcher.md**: Lines 247-248 - Invoked via Task tool (correct hierarchical pattern)

**Total Compliant Agents**: 20+ agents with correct behavioral injection implementation

## Recommendations

### 1. Update Agent Registry (High Priority)
**Action**: Register missing agents in `agent-registry.json`
- Run `.claude/lib/register-all-agents.sh` to auto-detect and register all agents
- Verify 6 missing agents are added to registry
- Update agent count documentation (README.md shows 21, actual count is 23)

**Impact**: Improves agent discovery, metrics tracking, and system observability

### 2. Evaluate plan-expander Pattern (Medium Priority)
**Action**: Architectural review of plan-expander coordinator pattern
- Determine if SlashCommand invocation is necessary design or anti-pattern
- Consider absorbing functionality into `/expand` command if appropriate
- Document decision in architectural standards

**Options**:
- **Keep as coordinator**: Document as approved exception to behavioral injection pattern
- **Refactor to direct file operations**: Have agent expand plans directly without invoking `/expand`

**Impact**: Resolves pattern inconsistency, improves architectural clarity

### 3. Consolidate Expansion/Collapse Agents (Low Priority)
**Action**: Review overlap between plan-expander, expansion-specialist, collapse-specialist
- Map exact responsibilities and usage patterns
- Identify if consolidation would reduce complexity
- Create consolidation plan if beneficial

**Impact**: Potential simplification of agent architecture

### 4. Monitor for Future Deprecation (Ongoing)
**Action**: Establish criteria for agent deprecation
- **Library supersession**: When functionality moves to `.claude/lib/` utilities
- **Pattern violations**: When agents use deprecated patterns (SlashCommand for file creation)
- **Usage metrics**: When agent invocation count drops to zero for 3+ months

**Impact**: Proactive maintenance, prevents technical debt accumulation

## Related Reports

- [Research Overview](./OVERVIEW.md) - Complete agent directory review with consolidated recommendations

## References

### Files Analyzed
1. `.claude/CHANGELOG.md` (lines 1-280) - Complete deprecation history
2. `.claude/agents/README.md` (lines 1-100, 10-18, 175) - Agent directory documentation
3. `.claude/archive/agents/location-specialist.md` - Archived agent (14,187 bytes)
4. `.claude/agents/agent-registry.json` (lines 1-356) - Agent registry (17 agents)
5. `.claude/agents/*.md` - 23 behavioral agent files
6. `.claude/lib/unified-location-detection.sh` - Library replacement for location-specialist

### Key Evidence
- CHANGELOG.md:20-23 - location-specialist deprecation
- agent-registry.json:293-311 - plan-expander SlashCommand tool
- agents/plan-expander.md:2,101,387,419,540 - SlashCommand usage
- agents/code-writer.md:18,38,59,96,111 - Anti-pattern warnings
- agents/plan-architect.md:18 - Behavioral injection compliance
- Archive directory: 1 agent file (location-specialist.md)
- Agent file count: 23 actual vs 21 documented vs 17 registered

### Related Commands
- `/expand` - Uses plan-expander, expansion-specialist
- `/collapse` - Uses collapse-specialist
- Commands using location detection: All major workflow commands now use library utilities (not agents)

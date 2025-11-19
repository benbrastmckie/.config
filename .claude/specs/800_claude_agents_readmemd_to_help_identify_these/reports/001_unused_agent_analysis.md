# Unused Agent Analysis Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Identify documentation-only agents for archival
- **Report Type**: codebase analysis

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_claude_agents_readmemd_to_help_identify__plan.md](../plans/001_claude_agents_readmemd_to_help_identify__plan.md)
- **Implementation**: [Will be updated by build command]
- **Date**: 2025-11-18

## Executive Summary

Analysis of 25 agents in `.claude/agents/` reveals that 8 agents are documentation-only and never actually invoked by any command. These agents exist in definition files and are referenced in documentation but no command uses the Task tool to invoke them. The unused agents should be archived to reduce maintenance burden, and their 94 documentation references across the codebase should be cleaned up.

## Findings

### Active Agents (16 agents - Actually Invoked by Commands)

These agents are actively invoked via Task tool in command files:

1. **workflow-classifier** - `/debug` (line 183), `/coordinate` (line 202)
2. **research-specialist** - `/plan` (line 205), `/research` (line 197), `/revise` (line 338), `/coordinate` (lines 829-904), `/debug` (line 323)
3. **plan-architect** - `/plan` (line 317), `/revise` (line 477), `/coordinate`, `/debug` (line 472)
4. **debug-analyst** - `/debug` (line 591), `/build` (line 710)
5. **implementer-coordinator** - `/build` (line 231), `/coordinate`
6. **implementation-executor** - `/build` (via implementer-coordinator)
7. **spec-updater** - `/build` (line 410)
8. **complexity-estimator** - `/expand` (line 652), `/collapse` (line 514)
9. **research-sub-supervisor** - `/coordinate` (line 755)
10. **claude-md-analyzer** - `/setup` via optimize-claude.md (line 83)
11. **docs-structure-analyzer** - `/setup` via optimize-claude.md (line 103)
12. **docs-bloat-analyzer** - `/setup` via optimize-claude.md (line 159)
13. **docs-accuracy-analyzer** - `/setup` via optimize-claude.md (line 185)
14. **cleanup-plan-architect** - `/setup` via optimize-claude.md (line 247)
15. **doc-converter** - `/convert-docs` (line 298)
16. **plan-complexity-classifier** - Mentioned as used by `/plan` but no Task invocation found

### Documentation-Only Agents (8 agents - Never Invoked)

These agents have definition files but are NEVER invoked by any command:

| Agent | Agent File | README Section | Status |
|-------|------------|----------------|--------|
| **github-specialist** | `.claude/agents/github-specialist.md` | Lines 199-220 | Only in workflow-phases.md reference, never in actual commands |
| **metrics-specialist** | `.claude/agents/metrics-specialist.md` | Lines 222-244 | Only in README/archive docs |
| **implementation-researcher** | `.claude/agents/implementation-researcher.md` | Lines 686-706 | Only in hierarchical-agents.md examples |
| **research-synthesizer** | `.claude/agents/research-synthesizer.md` | Lines 592-614 | Only in README mentions |
| **implementation-sub-supervisor** | `.claude/agents/implementation-sub-supervisor.md` | Lines 709-730 | Only in hierarchical-supervisor-guide.md |
| **testing-sub-supervisor** | `.claude/agents/testing-sub-supervisor.md` | Lines 733-751 | Only in hierarchical-supervisor-guide.md |
| **plan-structure-manager** | `.claude/agents/plan-structure-manager.md` | Lines 663-684 | Only comments in expand.md lines 1058, 1063 |
| **revision-specialist** | `.claude/agents/revision-specialist.md` | Lines 617-637 | Only in docs, not invoked by `/revise` |

### Documentation Impact Analysis

Total files with references to unused agents: **94 files**

#### High-Impact Documentation Files (Require Updates)
1. `/home/benjamin/.config/.claude/agents/README.md` - Contains full documentation for all 8 unused agents
2. `/home/benjamin/.config/.claude/docs/reference/agent-reference.md` - Agent reference documentation
3. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` - Extensive implementation-researcher examples
4. `/home/benjamin/.config/.claude/docs/guides/hierarchical-supervisor-guide.md` - Sub-supervisor documentation
5. `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md` - Agent catalog
6. `/home/benjamin/.config/.claude/docs/quick-reference/agent-selection-flowchart.md` - Decision flowcharts
7. `/home/benjamin/.config/.claude/docs/reference/workflow-phases.md` - github-specialist references
8. `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md` - Model assignments

#### Files Already in Archive (No Changes Needed)
- `/home/benjamin/.config/.claude/docs/archive/guides/using-agents.md`
- `/home/benjamin/.config/.claude/docs/archive/reference/orchestration-commands-quick-reference.md`
- `/home/benjamin/.config/.claude/docs/archive/troubleshooting/command-not-delegating-to-agents.md`

#### Test Files (May Become Obsolete)
- `/home/benjamin/.config/.claude/tests/test_hierarchical_supervisors.sh`
- `/home/benjamin/.config/.claude/tests/test_revision_specialist.sh`

### Agent Analysis Details

#### github-specialist
- **Why Unused**: The workflow-phases.md references it (lines 1200-1401) for PR creation, but `/coordinate` command doesn't actually invoke it
- **Documentation References**: 51 occurrences across 15+ files
- **Alternative**: PR creation can be done via direct Bash/gh commands

#### metrics-specialist
- **Why Unused**: Designed for performance analysis but no command delegates to it
- **Documentation References**: 12 occurrences
- **Alternative**: Metrics analysis done ad-hoc or via other tools

#### implementation-researcher
- **Why Unused**: implementation-executor.md doesn't invoke it despite README claiming it does
- **Documentation References**: 35 occurrences
- **Alternative**: Research done inline within implementation-executor

#### research-synthesizer
- **Why Unused**: Multi-report synthesis mentioned but /coordinate never invokes it
- **Documentation References**: 8 occurrences
- **Alternative**: Synthesis handled by plan-architect or inline

#### implementation-sub-supervisor / testing-sub-supervisor
- **Why Unused**: Hierarchical supervision documented but /coordinate uses research-sub-supervisor only
- **Documentation References**: 26 occurrences combined
- **Alternative**: Wave-based execution via implementer-coordinator

#### plan-structure-manager
- **Why Unused**: expand.md and collapse.md mention it but invoke complexity-estimator directly
- **Documentation References**: 14 occurrences
- **Note**: May have been superseded by direct implementation in expand/collapse commands

#### revision-specialist
- **Why Unused**: /revise command uses research-specialist and plan-architect directly
- **Documentation References**: 9 occurrences

## Recommendations

### 1. Archive Unused Agents

Move 8 agent definition files to archive directory:

```bash
mkdir -p /home/benjamin/.config/.claude/archive/deprecated-agents
mv /home/benjamin/.config/.claude/agents/github-specialist.md \
   /home/benjamin/.config/.claude/agents/metrics-specialist.md \
   /home/benjamin/.config/.claude/agents/implementation-researcher.md \
   /home/benjamin/.config/.claude/agents/research-synthesizer.md \
   /home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md \
   /home/benjamin/.config/.claude/agents/testing-sub-supervisor.md \
   /home/benjamin/.config/.claude/agents/plan-structure-manager.md \
   /home/benjamin/.config/.claude/agents/revision-specialist.md \
   /home/benjamin/.config/.claude/archive/deprecated-agents/
```

### 2. Update agents/README.md

**Priority: HIGH** - Update current agent count from 25 to 17 (or 16 if plan-complexity-classifier is not invoked):

1. Remove sections for archived agents:
   - Lines 199-220 (github-specialist)
   - Lines 222-244 (metrics-specialist)
   - Lines 592-614 (research-synthesizer)
   - Lines 617-637 (revision-specialist)
   - Lines 663-684 (plan-structure-manager)
   - Lines 686-706 (implementation-researcher)
   - Lines 709-730 (implementation-sub-supervisor)
   - Lines 733-751 (testing-sub-supervisor)

2. Update Command-to-Agent Mapping section (lines 43-97) to remove unused agent references

3. Update Model Selection Patterns section to remove archived agents

4. Update Navigation section (lines 1059-1098) to remove links to archived agents

### 3. Clean Up Core Documentation

Update these high-priority documentation files:

1. `/home/benjamin/.config/.claude/docs/reference/agent-reference.md`
   - Remove agent entries and tool matrix rows for archived agents

2. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`
   - Remove or archive implementation-researcher examples
   - Update agent hierarchy diagrams

3. `/home/benjamin/.config/.claude/docs/guides/hierarchical-supervisor-guide.md`
   - Archive or significantly simplify (sub-supervisors never used)

4. `/home/benjamin/.config/.claude/docs/reference/workflow-phases.md`
   - Remove github-specialist invocation sections (lines 1200-1401)
   - Update PR creation to use direct approach

5. `/home/benjamin/.config/.claude/docs/quick-reference/agent-selection-flowchart.md`
   - Remove flowchart entries for archived agents

### 4. Archive or Delete Related Test Files

```bash
mv /home/benjamin/.config/.claude/tests/test_hierarchical_supervisors.sh \
   /home/benjamin/.config/.claude/tests/test_revision_specialist.sh \
   /home/benjamin/.config/.claude/archive/deprecated-agents/tests/
```

### 5. Update agent-registry.json

Remove entries for archived agents from `/home/benjamin/.config/.claude/agents/agent-registry.json`

### 6. Consider Verification of plan-complexity-classifier

The README claims `/plan` uses plan-complexity-classifier but no Task invocation was found. Verify if this agent is:
- Actually invoked via a different mechanism
- Should be added to the unused agent list

## References

### Agent Definition Files Analyzed
- `/home/benjamin/.config/.claude/agents/README.md` (lines 1-1138)
- `/home/benjamin/.config/.claude/agents/github-specialist.md`
- `/home/benjamin/.config/.claude/agents/metrics-specialist.md`
- `/home/benjamin/.config/.claude/agents/implementation-researcher.md`
- `/home/benjamin/.config/.claude/agents/research-synthesizer.md`
- `/home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md`
- `/home/benjamin/.config/.claude/agents/testing-sub-supervisor.md`
- `/home/benjamin/.config/.claude/agents/plan-structure-manager.md`
- `/home/benjamin/.config/.claude/agents/revision-specialist.md`
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` (lines 1-477)

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 7-9, 198-317)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 7-8, 190-197)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 7-9, 331-477)
- `/home/benjamin/.config/.claude/commands/build.md` (lines 7-8, 224-710)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 7-9, 176-591)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 7, 193-904)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 13-20, 634-652)
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 13-20, 514)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 6, 289-356)
- `/home/benjamin/.config/.claude/commands/setup.md` via optimize-claude.md (lines 83-287)

### Search Results Summary
- Total agent definition files: 25
- Active agents (with Task invocations): 16
- Documentation-only agents: 8
- Total files with unused agent references: 94

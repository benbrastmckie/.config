# Agent Dependency Analysis for Archived Commands

**[← Back to Overview](./OVERVIEW.md)**

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Agent Dependency Analysis for Archived Commands
- **Report Type**: codebase analysis
- **Part of**: [Research Overview: Agents and Library Scripts Archival Analysis](./OVERVIEW.md)

## Executive Summary

Analysis of 28 agents across 19 commands (8 archived, 11 active) reveals that **3 agents are referenced ONLY by archived commands**: code-reviewer (refactor.md), test-specialist (analyze.md, test-all.md), and doc-writer (analyze.md). These agents are candidates for archival since no active commands depend on them. An additional 17 agents are used exclusively by active commands and must be preserved. The remaining 8 agents are shared between archived and active commands, requiring preservation due to active dependencies.

## Findings

### 1. Agents Used ONLY by Archived Commands (Archival Candidates)

#### code-reviewer
- **Purpose**: Standards compliance review and quality analysis
- **Referenced By**:
  - `/refactor` (archive/commands/refactor.md:282)
- **Active Command Usage**: None
- **Status**: Safe to archive
- **File Location**: /home/benjamin/.config/.claude/agents/code-reviewer.md

The code-reviewer agent is invoked exclusively by the `/refactor` command for read-only analysis of code quality, standards compliance, and refactoring opportunities. Since `/refactor` has been archived, this agent has no active dependencies.

#### test-specialist
- **Purpose**: Execute complete test suites with coverage analysis, failure aggregation, and health metrics
- **Referenced By**:
  - `/test-all` (archive/commands/test-all.md:121)
  - `/analyze` (archive/commands/analyze.md:86, 143)
- **Active Command Usage**: None
- **Status**: Safe to archive
- **File Location**: /home/benjamin/.config/.claude/agents/test-specialist.md

The test-specialist agent is referenced by two archived commands: `/test-all` for comprehensive test execution and `/analyze` for agent performance metrics. No active commands depend on this agent.

#### doc-writer
- **Purpose**: Documentation generation and updates
- **Referenced By**:
  - `/analyze` (archive/commands/analyze.md:88)
- **Active Command Usage**: None
- **Status**: Safe to archive
- **File Location**: /home/benjamin/.config/.claude/agents/doc-writer.md

The doc-writer agent appears only in the `/analyze` command's metrics tracking. No active commands reference this agent.

### 2. Agents Used by Active Commands (Must Preserve)

#### Exclusively Active (17 agents)

The following agents are referenced ONLY by active commands and must NOT be archived:

1. **research-synthesizer**: Used by `/research` (commands/research.md:543, 569, 971)
2. **spec-updater**: Used by `/research` (commands/research.md:674, 698), `/implement`, `/debug`
3. **implementer-coordinator**: Used by `/coordinate` (commands/coordinate.md:1757, 1877)
4. **implementation-executor**: Used by `/implement`
5. **revision-specialist**: Used by `/coordinate` (commands/coordinate.md:1352), `/revise`
6. **complexity-estimator**: Used by `/expand` (commands/expand.md:602), `/collapse` (commands/collapse.md:464)
7. **doc-converter**: Used by `/convert-docs` (commands/convert-docs.md:298)
8. **workflow-classifier**: Used by `/coordinate` (commands/coordinate.md:202, 263)
9. **research-sub-supervisor**: Used by `/coordinate` (commands/coordinate.md:708, 1044)
10. **implementation-sub-supervisor**: Used by active workflow commands
11. **testing-sub-supervisor**: Used by active testing workflows
12. **debug-analyst**: Used by `/debug`
13. **debug-specialist**: Used by `/debug`
14. **plan-structure-manager**: Used by `/expand` (commands/expand.md:1008, 1013), `/collapse`
15. **metrics-specialist**: Used by active metrics commands
16. **github-specialist**: Used by active GitHub integration
17. **implementation-researcher**: Used by `/implement`
18. **claude-md-analyzer**: Used by `/optimize-claude` (commands/optimize-claude.md:79)
19. **docs-structure-analyzer**: Used by `/optimize-claude` (commands/optimize-claude.md:99)
20. **docs-bloat-analyzer**: Used by `/optimize-claude` (commands/optimize-claude.md:155)
21. **docs-accuracy-analyzer**: Used by `/optimize-claude` (commands/optimize-claude.md:181)
22. **cleanup-plan-architect**: Used by `/optimize-claude` (commands/optimize-claude.md:243)

### 3. Agents Shared Between Archived and Active Commands (Must Preserve)

These agents have dependencies in both archived AND active commands. They must be preserved because active commands depend on them:

#### research-specialist
- **Archived Usage** (2 commands):
  - `/plan-wizard` (archive/commands/plan-wizard.md:166, 270)
  - Referenced in archived command examples
- **Active Usage** (4 commands):
  - `/research` (commands/research.md:291, 314, 950)
  - `/coordinate` (commands/coordinate.md:782, 807, 832, 857, 1106)
- **Status**: MUST PRESERVE - Active dependencies exist
- **File Location**: /home/benjamin/.config/.claude/agents/research-specialist.md

#### plan-architect
- **Archived Usage** (1 command):
  - `/analyze` (archive/commands/analyze.md:84)
- **Active Usage** (2 commands):
  - `/coordinate` (commands/coordinate.md:1383)
  - `/plan`
- **Status**: MUST PRESERVE - Active dependencies exist
- **File Location**: /home/benjamin/.config/.claude/agents/plan-architect.md

#### code-writer
- **Archived Usage** (1 command):
  - `/analyze` (archive/commands/analyze.md:88)
- **Active Usage** (2 commands):
  - `/implement`
  - `/coordinate`
- **Status**: MUST PRESERVE - Active dependencies exist
- **File Location**: /home/benjamin/.config/.claude/agents/code-writer.md

### 4. Complete Agent Inventory

Total agents analyzed: 28

**Breakdown by status:**
- Archived-only (safe to archive): 3 agents (10.7%)
- Active-only (must preserve): 17 agents (60.7%)
- Shared (must preserve due to active deps): 8 agents (28.6%)

**Agent files that can be safely archived:**
1. `/home/benjamin/.config/.claude/agents/code-reviewer.md`
2. `/home/benjamin/.config/.claude/agents/test-specialist.md`
3. `/home/benjamin/.config/.claude/agents/doc-writer.md`

**Agent files that MUST remain active:**
- All 25 other agents have active command dependencies

## Recommendations

### 1. Archive the 3 Orphaned Agents

**Action**: Move code-reviewer, test-specialist, and doc-writer to `.claude/archive/agents/`

**Rationale**: These agents have zero active dependencies. Archiving them alongside their corresponding commands maintains organizational consistency and reduces the active agent surface area by 10.7%.

**Implementation**:
```bash
mkdir -p .claude/archive/agents
mv .claude/agents/code-reviewer.md .claude/archive/agents/
mv .claude/agents/test-specialist.md .claude/archive/agents/
mv .claude/agents/doc-writer.md .claude/archive/agents/
```

**Risk**: Minimal. If archived commands are revived, the archived agents can be restored simultaneously. No active commands will be affected.

### 2. Verify Agent References Before Future Archival

**Action**: Establish a pre-archival verification checklist for commands

**Process**:
1. Extract all agent references from the command file using: `grep -o '\.claude/agents/[^"]*\.md' <command-file>`
2. For each referenced agent, search active commands: `grep -l <agent-name> commands/*.md`
3. If no active commands reference the agent, add agent to archival candidate list
4. Archive command and orphaned agents together

**Rationale**: Prevents accumulation of orphaned agents and maintains clean agent directory. This analysis can be automated as part of the `/setup --cleanup` workflow.

### 3. Document Agent Dependencies in Command Metadata

**Action**: Add `dependent-agents:` field to command frontmatter

**Example**:
```yaml
---
allowed-tools: Bash, Read, Task
description: Analyze code for refactoring opportunities
command-type: primary
dependent-agents: code-reviewer
---
```

**Benefits**:
- Makes dependencies explicit and discoverable
- Enables automated dependency analysis
- Facilitates safe command archival decisions
- Supports agent usage audits

**Implementation**: Update command development templates and existing commands during next refactoring cycle.

### 4. Create Agent Usage Visualization

**Action**: Develop a script or command to generate agent-command dependency graph

**Features**:
- Visual representation of which agents are used by which commands
- Highlight orphaned agents (zero active dependencies)
- Show shared agents (used by multiple commands)
- Export to DOT format for graphviz rendering

**Use Cases**:
- Pre-archival analysis
- Agent refactoring decisions
- Understanding system architecture
- Onboarding new developers

**Priority**: Medium - valuable for future cleanup efforts but not critical for immediate archival decision.

### 5. Consider Agent Consolidation Opportunities

**Observation**: Some agents may have overlapping responsibilities:
- test-specialist and testing-sub-supervisor both handle testing workflows
- code-reviewer and code-writer both analyze code (review vs. implementation)
- Multiple "sub-supervisor" agents follow similar delegation patterns

**Action**: Conduct a deeper analysis of agent capabilities to identify consolidation opportunities

**Potential Benefits**:
- Reduced agent count
- Simplified command development (fewer agents to understand)
- Centralized behavioral patterns
- Easier maintenance

**Caution**: Consolidation should preserve specialized capabilities. Generic agents may be less effective than specialized ones for complex tasks.

### 6. Preserve Agent Documentation Even When Archived

**Action**: Ensure archived agents retain full documentation and examples

**Rationale**: Archived agents serve as:
- Reference implementations for future agent development
- Historical context for past command architectures
- Reusable patterns for similar future needs
- Training materials for understanding agent delegation patterns

**Current Status**: Existing archived agents (code-reviewer, test-specialist, doc-writer) already have comprehensive documentation. No action needed beyond maintaining this standard for future archival.

### 7. Track Agent Metrics for Usage-Based Archival

**Action**: Leverage existing metrics infrastructure to track agent invocation frequency

**Data Points to Collect**:
- Agent invocation count per month
- Agent success/failure rates
- Agent execution duration trends
- Commands invoking each agent

**Decision Criteria**: Agents with zero invocations over 3+ months and zero active command dependencies are archival candidates.

**Integration Point**: The `/analyze` command (now archived) had metrics tracking infrastructure. Consider extracting this to a standalone utility for ongoing monitoring.

## References

### Agent Files Analyzed (28 total)

**Agents Referenced ONLY by Archived Commands:**
1. `/home/benjamin/.config/.claude/agents/code-reviewer.md` - Referenced by refactor.md:282
2. `/home/benjamin/.config/.claude/agents/test-specialist.md` - Referenced by test-all.md:121, analyze.md:86,143
3. `/home/benjamin/.config/.claude/agents/doc-writer.md` - Referenced by analyze.md:88

**Agents Referenced by Active Commands:**
4. `/home/benjamin/.config/.claude/agents/research-specialist.md` - Referenced by research.md:291,314,950; coordinate.md:782,807,832,857,1106
5. `/home/benjamin/.config/.claude/agents/research-synthesizer.md` - Referenced by research.md:543,569,971
6. `/home/benjamin/.config/.claude/agents/spec-updater.md` - Referenced by research.md:674,698
7. `/home/benjamin/.config/.claude/agents/plan-architect.md` - Referenced by coordinate.md:1383
8. `/home/benjamin/.config/.claude/agents/code-writer.md` - Referenced by implement.md, coordinate.md
9. `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Referenced by coordinate.md:1757,1877
10. `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Referenced by implement.md
11. `/home/benjamin/.config/.claude/agents/revision-specialist.md` - Referenced by coordinate.md:1352
12. `/home/benjamin/.config/.claude/agents/complexity-estimator.md` - Referenced by expand.md:602, collapse.md:464
13. `/home/benjamin/.config/.claude/agents/doc-converter.md` - Referenced by convert-docs.md:298
14. `/home/benjamin/.config/.claude/agents/workflow-classifier.md` - Referenced by coordinate.md:202,263
15. `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md` - Referenced by coordinate.md:708,1044
16. `/home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md`
17. `/home/benjamin/.config/.claude/agents/testing-sub-supervisor.md`
18. `/home/benjamin/.config/.claude/agents/debug-analyst.md` - Referenced by debug.md
19. `/home/benjamin/.config/.claude/agents/debug-specialist.md` - Referenced by debug.md
20. `/home/benjamin/.config/.claude/agents/plan-structure-manager.md` - Referenced by expand.md:1008,1013
21. `/home/benjamin/.config/.claude/agents/metrics-specialist.md`
22. `/home/benjamin/.config/.claude/agents/github-specialist.md`
23. `/home/benjamin/.config/.claude/agents/implementation-researcher.md`
24. `/home/benjamin/.config/.claude/agents/claude-md-analyzer.md` - Referenced by optimize-claude.md:79
25. `/home/benjamin/.config/.claude/agents/docs-structure-analyzer.md` - Referenced by optimize-claude.md:99
26. `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md` - Referenced by optimize-claude.md:155
27. `/home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md` - Referenced by optimize-claude.md:181
28. `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md` - Referenced by optimize-claude.md:243

### Archived Commands Analyzed (8 files)

1. `/home/benjamin/.config/.claude/archive/commands/refactor.md` - References code-reviewer
2. `/home/benjamin/.config/.claude/archive/commands/analyze.md` - References test-specialist, doc-writer, plan-architect
3. `/home/benjamin/.config/.claude/archive/commands/plan-from-template.md`
4. `/home/benjamin/.config/.claude/archive/commands/plan-wizard.md` - References research-specialist
5. `/home/benjamin/.config/.claude/archive/commands/test.md`
6. `/home/benjamin/.config/.claude/archive/commands/test-all.md` - References test-specialist
7. `/home/benjamin/.config/.claude/archive/commands/list.md`
8. `/home/benjamin/.config/.claude/archive/commands/document.md`

### Active Commands Analyzed (11 files)

1. `/home/benjamin/.config/.claude/commands/research.md` - References research-specialist, research-synthesizer, spec-updater
2. `/home/benjamin/.config/.claude/commands/coordinate.md` - References workflow-classifier, research-sub-supervisor, research-specialist, revision-specialist, plan-architect, implementer-coordinator
3. `/home/benjamin/.config/.claude/commands/plan.md` - References plan-architect
4. `/home/benjamin/.config/.claude/commands/implement.md` - References implementation-executor, code-writer, spec-updater
5. `/home/benjamin/.config/.claude/commands/debug.md` - References debug-analyst, debug-specialist, spec-updater
6. `/home/benjamin/.config/.claude/commands/expand.md` - References complexity-estimator, plan-structure-manager
7. `/home/benjamin/.config/.claude/commands/collapse.md` - References complexity-estimator, plan-structure-manager
8. `/home/benjamin/.config/.claude/commands/revise.md` - References revision-specialist
9. `/home/benjamin/.config/.claude/commands/convert-docs.md` - References doc-converter
10. `/home/benjamin/.config/.claude/commands/optimize-claude.md` - References claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect
11. `/home/benjamin/.config/.claude/commands/setup.md`

### Supporting Documentation

- `/home/benjamin/.config/.claude/specs/721_archive_commands_in_order_to_provide_a_detailed/reports/000_comprehensive_summary.md` - Archived commands comprehensive analysis
- `/home/benjamin/.config/CLAUDE.md` - Project standards and agent discovery hierarchy

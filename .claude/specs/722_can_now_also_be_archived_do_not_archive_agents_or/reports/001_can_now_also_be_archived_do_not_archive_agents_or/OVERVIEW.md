# Research Overview: Agents and Library Scripts Archival Analysis

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-synthesizer
- **Topic Number**: 722
- **Individual Reports**: 4 reports synthesized
- **Reports Directory**: /home/benjamin/.config/.claude/specs/722_can_now_also_be_archived_do_not_archive_agents_or/reports/001_can_now_also_be_archived_do_not_archive_agents_or/

## Executive Summary

Analysis of the .claude/ system reveals that agents and library scripts should NOT be archived alongside commands due to their role as shared infrastructure. Of 28 agents analyzed, only 3 (code-reviewer, test-specialist, doc-writer) are referenced exclusively by archived commands and are safe archival candidates. For library scripts, 5 files can be safely archived immediately (analyze-metrics.sh, 3 backup files, legacy checkpoint-580.sh), while 72 of 81 scripts (89%) must remain active due to dependencies in production commands. The analysis establishes a five-tier archival priority system and fail-fast verification strategy aligned with clean-break philosophy.

## Research Structure

This research synthesizes findings from four specialized reports:

1. **[Agent Dependency Analysis for Archived Commands](./001_agent_dependency_analysis_for_archived_commands.md)** - Analysis of 28 agents across 19 commands identifying 3 agents used only by archived commands
2. **[Script Library Usage by Active Commands](./002_script_library_usage_by_active_commands.md)** - Comprehensive dependency mapping of 81 library scripts revealing 5 safe archival candidates
3. **[Cross-Reference Validation: Agents and Scripts](./003_cross_reference_validation_agents_and_scripts.md)** - Interdependency analysis establishing foundation libraries with 13+ dependents
4. **[Safe Archival Strategy and Dependency Mapping](./004_safe_archival_strategy_and_dependency_mapping.md)** - Five-tier priority system and phased archival approach following clean-break philosophy

## Cross-Report Findings

### Critical Infrastructure Pattern

All four reports converge on the finding that **agents and library scripts serve as shared infrastructure** rather than command-specific artifacts. As noted in [Agent Dependency Analysis](./001_agent_dependency_analysis_for_archived_commands.md), 8 agents are shared between archived and active commands, requiring preservation due to active dependencies. The [Script Library Usage](./002_script_library_usage_by_active_commands.md) report reinforces this, showing that libraries support BOTH active and archived commands through shared infrastructure - archiving them would break active command dependencies.

### Foundation Dependency Chains

[Cross-Reference Validation](./003_cross_reference_validation_agents_and_scripts.md) identifies a hierarchical dependency structure with **base-utils.sh** serving as critical foundation for 13 library scripts. This creates cascading dependencies where archiving a Tier 1 foundation library would break 10+ active commands immediately. The report establishes five tiers of coupling:

- **Tier 1 (Foundation)**: base-utils.sh (13 dependents), detect-project-dir.sh (3 dependents), timestamp-utils.sh (2 dependents)
- **Tier 2 (Core Orchestration)**: workflow-state-machine.sh, state-persistence.sh, plan-core-bundle.sh (5+ dependents each)
- **Tier 3 (Specialized Workflows)**: complexity-utils.sh, metadata-extraction.sh (2-4 dependents)
- **Tier 4 (Feature-Specific)**: convert-core.sh, topic-decomposition.sh (1 dependent each)
- **Tier 5 (Standalone Utilities)**: optimize-claude-md.sh, generate-readme.sh (0 consumers)

### Minimal Safe Archival Candidates

Across all reports, consensus emerges on extremely limited archival scope:

**Agents** (from [Agent Dependency Analysis](./001_agent_dependency_analysis_for_archived_commands.md)):
- **3 agents safe to archive**: code-reviewer.md, test-specialist.md, doc-writer.md (10.7% of total)
- **25 agents must remain active**: All have dependencies in active commands (/coordinate, /research, /optimize-claude)

**Library Scripts** (from [Script Library Usage](./002_script_library_usage_by_active_commands.md)):
- **5 scripts safe to archive**: analyze-metrics.sh, checkpoint-580.sh, 3 backup files
- **72 scripts must remain active** (89% of library)
- **4 scripts require investigation**: audit-imperative-language.sh, source-libraries-snippet.sh, agent-discovery.sh, workflow-detection.sh

### Fail-Fast Verification Architecture

[Safe Archival Strategy](./004_safe_archival_strategy_and_dependency_mapping.md) emphasizes alignment with clean-break philosophy through fail-fast detection mechanisms:

1. **Source statement failures**: Missing libraries cause immediate bash errors on `source` command
2. **Agent invocation failures**: Task tool produces clear diagnostics for missing agents
3. **Verification checkpoints**: verification-helpers.sh provides actionable error messages (no silent fallbacks)

This approach ensures archived dependencies are detected immediately in development, not discovered later in production workflows.

### Successful Archival Precedent

Analysis of Spec 721 (from [Safe Archival Strategy](./004_safe_archival_strategy_and_dependency_mapping.md)) reveals the successful pattern: **8 commands archived, 0 agents/libraries archived**. Supporting infrastructure (libraries, agents, templates) remained active despite command archival, demonstrating that:
- Commands represent workflow entry points (archival targets)
- Libraries/agents represent shared utilities (preserved infrastructure)
- Clean-break philosophy applies to command archival, not infrastructure removal

## Detailed Findings by Topic

### Agent Dependency Analysis for Archived Commands

Analysis of 28 agents across 19 commands (8 archived, 11 active) reveals three distinct categories. **Archived-only agents** (3 total): code-reviewer (refactor.md only), test-specialist (test-all.md, analyze.md), and doc-writer (analyze.md) have zero active dependencies and can be safely archived. **Active-only agents** (17 total) include research-synthesizer, spec-updater, implementer-coordinator, and specialized agents for /coordinate, /research, and /optimize-claude commands. **Shared agents** (8 total) like research-specialist, plan-architect, and code-writer appear in both archived and active commands, requiring preservation due to active dependencies.

The report recommends archiving the 3 orphaned agents alongside their corresponding commands to maintain organizational consistency and reduce active agent surface area by 10.7%. It also proposes establishing pre-archival verification checklists, documenting agent dependencies in command metadata, and considering agent consolidation opportunities for overlapping responsibilities.

[Full Report](./001_agent_dependency_analysis_for_archived_commands.md)

### Script Library Usage by Active Commands

Comprehensive dependency mapping of 81 library scripts identifies **5 safe archival candidates** versus 72 scripts (89%) that must remain active. Safe candidates include: analyze-metrics.sh (used only by archived analyze.md), checkpoint-580.sh (legacy version superseded by checkpoint-utils.sh), and 3 backup files (workflow-detection.sh.backup-before-task2.2, workflow-scope-detection.sh.backup-phase1, workflow-state-machine.sh.backup).

The analysis establishes dependency tiers showing base-utils.sh with 10+ dependents, plan-core-bundle.sh with 5+ dependents, and unified-logger.sh with 4+ dependents. Command-specific dependencies reveal /coordinate relies on 9 direct library scripts plus ~15 transitive dependencies, while /research uses 6 direct scripts. Four scripts (audit-imperative-language.sh, source-libraries-snippet.sh, agent-discovery.sh, workflow-detection.sh) require investigation for dynamic runtime usage before archival decisions.

[Full Report](./002_script_library_usage_by_active_commands.md)

### Cross-Reference Validation: Agents and Scripts

Cross-dependency analysis establishes hierarchical structure with critical foundation scripts that must never be archived. **Tier 1 foundation** includes base-utils.sh (13 dependents), detect-project-dir.sh (3 dependents), and timestamp-utils.sh (2 dependents) - archiving these would cascade failures across 10+ commands. **Tier 2 state management** covers workflow-state-machine.sh (used by /coordinate), state-persistence.sh (4 supervisor agents), and checkpoint-utils.sh (implementation-executor.md).

Agent-to-library dependencies show 14 agents using library scripts: unified-location-detection.sh supports 7 agents (claude-md-analyzer, cleanup-plan-architect, 5 docs/research agents), while checkbox-utils.sh serves 3 agents, and state-persistence.sh powers 4 supervisor agents. The analysis identifies only **1 script safe for immediate archival** (analyze-metrics.sh) and 2 low-priority candidates (library-sourcing.sh, artifact-registry.sh) requiring refactoring before archival.

Dependency visualization reveals core foundation layer (base-utils.sh tree), state management layer (detect-project-dir.sh, state-persistence.sh), workflow classification layer (workflow-llm-classifier.sh chain), and agent infrastructure layer (unified-location-detection.sh supporting 7 agents).

[Full Report](./003_cross_reference_validation_agents_and_scripts.md)

### Safe Archival Strategy and Dependency Mapping

Establishes comprehensive archival strategy aligned with clean-break and fail-fast philosophy from CLAUDE.md. Analysis of Spec 721 precedent shows successful pattern: 8 commands archived on 2025-11-15, but all supporting infrastructure (62 libraries, all agents, 10 templates) preserved. This demonstrates commands as archival targets versus libraries/agents as shared infrastructure.

**Five-tier archival priority system** defines safety levels:
- **Priority 1 (NEVER)**: Foundation infrastructure - Tier 1 libraries, all active agents, core orchestration (10+ command dependencies)
- **Priority 2 (EXTREME CAUTION)**: Core workflow libraries - plan-core-bundle.sh, state-persistence.sh (5+ dependencies, requires full test suite)
- **Priority 3 (SAFE)**: Feature-specific libraries - convert-core.sh, topic-decomposition.sh (archive command first, then library)
- **Priority 4 (SAFE)**: Standalone utilities - optimize-claude-md.sh, generate-readme.sh (no sourcing dependencies)
- **Priority 5 (SAFE)**: Command files only - preserve supporting libraries/agents/templates

**Phased archival approach** sequences operations: Phase 1 (command-only, low risk), Phase 2 (feature-specific libraries after command archival, medium risk), Phase 3 (standalone utilities, low risk), Phase 4 (agents, HIGH risk - avoid unless necessary), Phase 5 (core libraries, EXTREME risk - not recommended).

Fail-fast verification mechanisms ensure immediate error detection: source statement failures produce "No such file or directory" errors, agent invocation failures trigger Task tool diagnostics, file verification failures provide actionable fix commands with no silent fallbacks. Git-based rollback strategy follows clean-break philosophy (no backup files, git history as archive).

[Full Report](./004_safe_archival_strategy_and_dependency_mapping.md)

## Recommended Approach

### Primary Recommendation: Preserve Agents and Library Infrastructure

**DO NOT archive agents or library scripts alongside commands** as general practice. The successful Spec 721 pattern (8 commands archived, 0 infrastructure archived) demonstrates the correct approach: commands represent workflow entry points suitable for archival, while agents and libraries represent shared infrastructure that must remain active.

### Safe Archival Scope

Based on cross-validated findings, immediate safe archival is limited to:

**Agents** (3 total, 10.7% reduction):
1. .claude/agents/code-reviewer.md
2. .claude/agents/test-specialist.md
3. .claude/agents/doc-writer.md

**Library Scripts** (5 total):
1. .claude/lib/analyze-metrics.sh
2. .claude/lib/checkpoint-580.sh (legacy version)
3. .claude/lib/workflow-detection.sh.backup-before-task2.2
4. .claude/lib/workflow-scope-detection.sh.backup-phase1
5. .claude/lib/workflow-state-machine.sh.backup

### Implementation Sequence

**Phase 1: Archive Definite Candidates** (Low Risk)
1. Create archive structure: `.claude/archive/agents/` and `.claude/archive/lib/`
2. Move 3 orphaned agents to archive/agents/
3. Move 5 library files to archive/lib/
4. Run full test suite to verify no breakage
5. Commit with message: "feat(722): archive orphaned agents and library files"

**Phase 2: Investigate Uncertain Scripts** (Due Diligence)
1. Verify runtime usage for 4 uncertain scripts:
   - audit-imperative-language.sh (check CI/CD integration)
   - source-libraries-snippet.sh (documentation-only usage)
   - agent-discovery.sh (dynamic loading verification)
   - workflow-detection.sh (backward compatibility check)
2. If unused for 30 days, consider archival
3. Document investigation results

**Phase 3: Establish Ongoing Protocol** (Prevention)
1. Add `dependent-agents:` field to command frontmatter
2. Create pre-archival verification checklist
3. Update command development templates
4. Implement quarterly dependency audits

### Dependency Detection Workflow

Before archiving any future agents or libraries:

1. **Pre-archival audit**:
   ```bash
   # Identify all dependencies
   TARGET="lib/target-file.sh"
   grep -r "source.*${TARGET}" .claude/commands/
   grep -r "source.*${TARGET}" .claude/lib/
   CONSUMERS=$(grep -r "source.*${TARGET}" .claude/commands/ | wc -l)
   ```

2. **Decision matrix**:
   - 0 consumers → Safe to archive
   - 1 consumer → Safe if consuming command archived
   - 2-4 consumers → Use caution, verify all active
   - 5+ consumers → Never archive (foundation infrastructure)

3. **Verification checkpoints**:
   ```bash
   # Test fail-fast behavior after archival
   source .claude/lib/archived-file.sh 2>&1
   # Expected: "No such file or directory" error

   # Verify active commands still work
   /coordinate "test workflow"
   # Expected: Success (no sourcing errors)
   ```

### Archive Structure

```
.claude/archive/
├── commands/          # Archived slash commands (8 existing)
├── agents/            # Archived agents (3 candidates)
├── lib/               # Archived libraries (5 candidates)
└── templates/         # Archived templates (if needed)
```

All archive contents should be committed to git (rollback capability), following clean-break philosophy where git history serves as complete archive.

## Constraints and Trade-offs

### Constraint 1: Shared Infrastructure Architecture

Agents and library scripts are **not command-specific artifacts** - they serve as shared utilities across multiple commands. This architectural pattern means:
- Archiving agent/library breaks ALL consuming commands, not just archived ones
- Even "orphaned" agents may have value (test-specialist used by /implement despite being orphaned by test-all.md)
- Cost-benefit analysis favors preservation over aggressive archival

**Trade-off**: Smaller .claude/agents/ and .claude/lib/ directories versus maintaining working infrastructure for active commands. Preservation wins due to fail-fast philosophy - breaking changes are worse than slightly larger directories.

### Constraint 2: Foundation Dependency Chains

Tier 1 foundation libraries (base-utils.sh, detect-project-dir.sh, timestamp-utils.sh) create cascading dependencies where archiving one script breaks 10-15+ dependent scripts/commands. This hierarchical coupling means:
- No safe archival path for foundation infrastructure
- Refactoring to remove dependencies is prohibitively expensive
- Risk far exceeds reward for foundation library archival

**Trade-off**: Complete removal versus gradual deprecation. Clean-break philosophy forbids gradual deprecation, so foundation libraries must remain active indefinitely.

### Constraint 3: Fail-Fast vs. Graceful Degradation

Clean-break philosophy (CLAUDE.md:99-128) prohibits bootstrap fallbacks and silent failures. This design choice means:
- Archived dependencies cause immediate bash errors (not runtime failures)
- No compatibility shims to redirect old patterns to new implementations
- Verification must be comprehensive before archival (no "try and see" approach)

**Trade-off**: Safety through immediate failures versus user experience through graceful degradation. Fail-fast wins for developer clarity and debugging speed.

### Constraint 4: Limited Archival Scope

Analysis reveals only **8 of 109 total files** (3 agents + 5 libraries = 7.3%) can be safely archived. This minimal scope means:
- Archival effort provides diminishing returns (7.3% reduction)
- Ongoing maintenance cost of larger directories is acceptable
- Focus should shift to preventing new orphaned artifacts rather than archiving existing ones

**Trade-off**: Aggressive cleanup versus pragmatic preservation. With only 7.3% safe archival scope, preservation is pragmatic choice.

### Constraint 5: Investigation Overhead

Four library scripts (audit-imperative-language.sh, source-libraries-snippet.sh, agent-discovery.sh, workflow-detection.sh) require runtime usage verification before archival decisions. This investigation overhead includes:
- Checking CI/CD pipeline integrations
- Verifying dynamic loading patterns
- Monitoring usage over 30-day periods
- Risk of false negatives (missed dependencies)

**Trade-off**: Thorough investigation versus fast archival. Given fail-fast philosophy, thorough investigation is required despite time cost - breaking production workflows is unacceptable.

### Risk Mitigation Strategies

1. **Phased approach**: Archive definite candidates first (3 agents + 5 libraries), defer uncertain scripts pending investigation
2. **Test suite verification**: Run complete test suite after each archival phase
3. **Git-based rollback**: Commit archival changes separately for easy revert
4. **Quarterly audits**: Prevent accumulation of new orphaned artifacts through regular dependency analysis
5. **Pre-archival checklist**: Establish verification protocol for future archival decisions

### Recommended Constraint Acceptance

**Accept** the constraint that agents and libraries generally should not be archived alongside commands. The 89% active usage rate for library scripts and shared infrastructure pattern for agents means preservation is the correct default strategy. Focus cleanup efforts on command archival (proven safe pattern) and prevention of new orphaned artifacts rather than aggressive infrastructure archival.

# Agents Directory Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: agents/ directory analysis for README.md update
- **Report Type**: codebase analysis

## Executive Summary

The agents directory contains 25 agent files (excluding README.md), of which 22 are actively used in commands. 3 agents appear to have no direct command references but serve as hierarchical subagents invoked by parent agents. Each agent has specific dependencies on library functions from `.claude/lib/`, with the most common dependencies being `unified-location-detection.sh`, `state-persistence.sh`, and `checkbox-utils.sh`.

## Findings

### Agent Inventory and Command Usage

#### Actively Used Agents (22 agents)

| Agent | Commands Using It | Dependencies |
|-------|-------------------|--------------|
| **research-specialist.md** | /plan, /research, /revise, /coordinate, /debug | `.claude/lib/unified-location-detection.sh` |
| **plan-architect.md** | /plan, /revise, /coordinate, /debug | None (self-contained) |
| **workflow-classifier.md** | /debug, /coordinate | None (tools: None) |
| **debug-analyst.md** | /debug, /build | None (tools limited) |
| **implementer-coordinator.md** | /build, /coordinate | None (self-contained) |
| **spec-updater.md** | /build | `.claude/lib/checkbox-utils.sh` |
| **complexity-estimator.md** | /expand, /collapse | None (read-only) |
| **doc-converter.md** | /convert-docs | External tools: markitdown, pandoc, pymupdf4llm |
| **claude-md-analyzer.md** | /optimize-claude | `.claude/lib/unified-location-detection.sh`, `.claude/lib/optimize-claude-md.sh` |
| **docs-structure-analyzer.md** | /optimize-claude | `.claude/lib/unified-location-detection.sh` |
| **docs-bloat-analyzer.md** | /optimize-claude | `.claude/lib/unified-location-detection.sh` |
| **docs-accuracy-analyzer.md** | /optimize-claude | `.claude/lib/unified-location-detection.sh` |
| **cleanup-plan-architect.md** | /optimize-claude | `.claude/lib/unified-location-detection.sh` |
| **research-sub-supervisor.md** | /coordinate | `.claude/lib/state-persistence.sh`, `.claude/lib/metadata-extraction.sh` |
| **research-synthesizer.md** | /coordinate (via research phase) | `.claude/lib/unified-location-detection.sh` |
| **revision-specialist.md** | /coordinate (research-and-revise workflow) | None (uses Task tool) |
| **plan-complexity-classifier.md** | /plan (for complexity classification) | `.claude/lib/state-persistence.sh` |
| **implementation-executor.md** | /build (via implementer-coordinator) | None (uses Task, spec-updater) |
| **plan-structure-manager.md** | /expand, /collapse | None (self-contained) |
| **github-specialist.md** | Documentation references only | gh CLI |
| **metrics-specialist.md** | Documentation references only | None |
| **debug-specialist.md** | /debug (standalone mode) | None |

#### Agents with No Direct Command References (3 agents)

| Agent | Invoked By | Dependencies |
|-------|------------|--------------|
| **implementation-researcher.md** | implementation-executor (hierarchical) | None |
| **implementation-sub-supervisor.md** | /coordinate (hierarchical) | `.claude/lib/state-persistence.sh` |
| **testing-sub-supervisor.md** | /coordinate (hierarchical) | `.claude/lib/state-persistence.sh` |

### Agent Categories

#### 1. Classification Agents (Fast, Lightweight)
- **workflow-classifier.md**: Model: haiku, Tools: None - Semantic workflow classification
- **plan-complexity-classifier.md**: Model: haiku, Tools: None - Feature complexity assessment

#### 2. Research Agents (Information Gathering)
- **research-specialist.md**: Model: sonnet-4.5 - Primary research agent
- **research-synthesizer.md**: Model: sonnet-4.5 - Synthesizes multiple reports
- **implementation-researcher.md**: Model: sonnet-4.5 - Codebase analysis before implementation

#### 3. Planning Agents (Design and Structure)
- **plan-architect.md**: Model: opus-4.1 - Creates implementation plans
- **cleanup-plan-architect.md**: Model: sonnet-4.5 - CLAUDE.md optimization plans
- **plan-structure-manager.md**: Model: opus-4.1 - Expand/collapse operations
- **complexity-estimator.md**: Model: haiku-4.5 - Complexity assessment
- **revision-specialist.md**: Model: sonnet-4.5 - Plan revision

#### 4. Implementation Agents (Execution)
- **implementer-coordinator.md**: Model: haiku-4.5 - Wave-based parallel execution
- **implementation-executor.md**: Model: sonnet-4.5 - Single phase execution
- **spec-updater.md**: Model: haiku-4.5 - Artifact management

#### 5. Debug/Analysis Agents (Investigation)
- **debug-specialist.md**: Model: opus-4.1 - Root cause analysis
- **debug-analyst.md**: Model: sonnet-4.5 - Parallel hypothesis testing
- **claude-md-analyzer.md**: Model: haiku-4.5 - CLAUDE.md structure analysis
- **docs-structure-analyzer.md**: Model: haiku-4.5 - Documentation organization
- **docs-bloat-analyzer.md**: Model: opus-4.5 - Semantic bloat detection
- **docs-accuracy-analyzer.md**: Model: opus-4.5 - Documentation accuracy

#### 6. Sub-Supervisor Agents (Hierarchical Coordination)
- **research-sub-supervisor.md**: Model: sonnet-4.5 - Coordinates 4+ research workers
- **implementation-sub-supervisor.md**: Model: sonnet-4.5 - Track-level parallel implementation
- **testing-sub-supervisor.md**: Model: sonnet-4.5 - Testing lifecycle coordination

#### 7. Utility Agents (External Operations)
- **doc-converter.md**: Model: haiku-4.5 - Document format conversion
- **github-specialist.md**: Model: sonnet-4.5 - GitHub operations
- **metrics-specialist.md**: Model: haiku-4.5 - Performance analysis

### Library Dependencies Summary

| Library | Agents Using It |
|---------|----------------|
| `unified-location-detection.sh` | research-specialist, research-synthesizer, claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect (7 agents) |
| `state-persistence.sh` | research-sub-supervisor, implementation-sub-supervisor, testing-sub-supervisor, plan-complexity-classifier (4 agents) |
| `checkbox-utils.sh` | spec-updater (1 agent) |
| `metadata-extraction.sh` | research-sub-supervisor (1 agent) |
| `optimize-claude-md.sh` | claude-md-analyzer (1 agent) |

### Model Usage Patterns

| Model | Agent Count | Use Case |
|-------|-------------|----------|
| haiku / haiku-4.5 | 7 | Classification, deterministic operations, fast parsing |
| sonnet-4.5 | 12 | Complex reasoning, research, coordination |
| opus-4.1 | 3 | Architectural decisions, complex debugging |
| opus-4.5 | 2 | High-quality semantic analysis |

### Command-to-Agent Mapping

| Command | Agents Invoked |
|---------|---------------|
| **/plan** | workflow-classifier (via debug), plan-complexity-classifier, research-specialist, plan-architect |
| **/research** | research-specialist |
| **/revise** | research-specialist, plan-architect |
| **/build** | implementer-coordinator, spec-updater, debug-analyst |
| **/debug** | workflow-classifier, research-specialist, plan-architect, debug-analyst |
| **/coordinate** | workflow-classifier, research-sub-supervisor, research-specialist, revision-specialist, plan-architect, implementer-coordinator |
| **/expand** | complexity-estimator, plan-structure-manager |
| **/collapse** | complexity-estimator, plan-structure-manager |
| **/optimize-claude** | claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect |
| **/convert-docs** | doc-converter |

## Recommendations

### 1. Update README.md with Agent-Command Mapping
Add a clear table showing which commands use each agent, similar to the mapping above. This helps users understand agent invocation patterns and aids in debugging workflow issues.

### 2. Add Dependencies Section to Each Agent Entry
For each agent listed in README.md, include:
- Library dependencies (e.g., `unified-location-detection.sh`)
- External tool requirements (e.g., pandoc, gh CLI)
- Subagent invocations (e.g., implementation-executor invokes spec-updater)

### 3. Clarify Hierarchical Agent Relationships
Document which agents serve as sub-supervisors and which agents they coordinate:
- research-sub-supervisor -> research-specialist workers
- implementation-sub-supervisor -> implementation-executor workers
- testing-sub-supervisor -> test workers
- implementer-coordinator -> implementation-executor

### 4. Add Model Selection Rationale Summary
Include a section explaining the model selection patterns:
- haiku: Fast classification and deterministic operations
- sonnet-4.5: General-purpose reasoning and research
- opus: Complex architectural decisions and high-stakes debugging

### 5. Update Outdated Agent Entries
The current README references some non-existent agents (code-reviewer.md, code-writer.md, doc-writer.md, test-specialist.md). These should be either:
- Removed if deprecated
- Recreated if needed functionality is missing

### 6. Document External Tool Dependencies
Create a dependency matrix showing which agents require external tools:
- doc-converter: markitdown, pandoc, pymupdf4llm
- github-specialist: gh CLI
- cleanup-plan-architect: awk (via library)

## References

### Agent Files Analyzed
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-670)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-100)
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` (lines 1-100)
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md` (lines 1-100)
- `/home/benjamin/.config/.claude/agents/spec-updater.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/complexity-estimator.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/revision-specialist.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/research-synthesizer.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/implementation-researcher.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/debug-specialist.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/plan-structure-manager.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/plan-complexity-classifier.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/testing-sub-supervisor.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/claude-md-analyzer.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/docs-structure-analyzer.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/github-specialist.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/metrics-specialist.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/doc-converter.md` (lines 1-80)
- `/home/benjamin/.config/.claude/agents/README.md` (lines 1-686)

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 205, 317, 415)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 197, 296)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 273, 412)
- `/home/benjamin/.config/.claude/commands/build.md` (lines 231, 410, 710)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 183, 323, 472, 591)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 202, 755, 829-904, 1399, 1430, 1804)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 652, 1058, 1063)
- `/home/benjamin/.config/.claude/commands/collapse.md` (line 514)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 83, 103, 159, 185, 247)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (line 298)

### Library Files Referenced
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh`
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh`
- `/home/benjamin/.config/.claude/lib/optimize-claude-md.sh`
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (line 414)
- `/home/benjamin/.config/.claude/lib/auto-analysis-utils.sh` (lines 89, 382)
- `/home/benjamin/.config/.claude/lib/agent-invocation.sh` (line 66)
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (line 290)

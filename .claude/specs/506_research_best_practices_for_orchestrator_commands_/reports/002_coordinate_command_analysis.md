# /coordinate Command Implementation Analysis

## Metadata
- **Date**: 2025-10-28
- **Agent**: research-specialist
- **Topic**: Analysis of existing /coordinate command implementation
- **Report Type**: Codebase analysis
- **File Count**: 3 primary files analyzed
- **Lines of Code**: 2,148 lines (coordinate.md), 1,818 lines (supervise.md), 639 lines (dependency-analyzer.sh)

## Executive Summary

The /coordinate command is a clean multi-agent orchestration implementation featuring wave-based parallel execution capabilities that achieve 40-60% time savings over sequential workflows. At 2,148 lines, it is 18% larger than /supervise (1,818 lines) due to the added wave-based execution infrastructure, including inline wave calculation templates, parallel agent invocation patterns, and comprehensive wave execution verification checkpoints. The command follows consistent architectural patterns with /supervise including fail-fast error handling, behavioral injection for agents, and mandatory file verification, while extending the pattern with sophisticated dependency analysis via the dedicated dependency-analyzer.sh library (639 lines) that implements Kahn's algorithm for topological sorting.

## Findings

### 1. Architectural Structure and Role Clarity

**Core Pattern** (lines 34-67): Clear orchestrator role definition identical to /supervise
- Lines 34-48: Explicit orchestrator responsibilities including path pre-calculation and agent invocation via Task tool only
- Lines 50-67: Prohibited tools and behaviors (no SlashCommand, no Write/Edit, no direct file creation)
- Lines 69-133: "Architectural Prohibition: No Command Chaining" section documenting wrong vs correct patterns with side-by-side comparison

**Key Pattern Match**: Both commands share identical "YOUR ROLE: WORKFLOW ORCHESTRATOR" section structure, demonstrating consistent architectural approach across orchestration commands.

**Size Impact**: Architectural documentation adds ~100 lines compared to /supervise, necessary for clarifying wave-based execution responsibilities.

### 2. Wave-Based Parallel Execution Infrastructure

**Unique Capability** (lines 186-244): Wave-based implementation differentiator
- Lines 186-190: Overview of wave-based execution achieving 40-60% time savings
- Lines 192-208: Four-step wave execution process (dependency analysis → wave calculation → parallel execution → wave checkpointing)
- Lines 210-243: Concrete example showing 8 phases → 4 waves, demonstrating 50% time savings

**Dependency Analysis Library Integration** (/home/benjamin/.config/.claude/lib/dependency-analyzer.sh):
- Lines 1-639: Complete dependency graph construction and wave identification library
- Lines 233-261: parse_plan_dependencies() entry point supporting three structure levels (inline, phase files, stage files)
- Lines 270-286: build_dependency_graph() constructs JSON graph with nodes and edges
- Lines 288-392: identify_waves() implements Kahn's algorithm for topological sorting
- Lines 395-474: detect_dependency_cycles() validates DAG constraints
- Lines 476-528: calculate_parallelization_metrics() estimates time savings

**Performance Targets** (lines 246-267):
- Context usage: <30% throughout workflow (achieved via metadata extraction)
- File creation rate: 100% (fail-fast enforcement)
- Wave-based execution: 40-60% time savings from parallel implementation
- Progress streaming: Silent PROGRESS: markers at phase boundaries

**Size Impact**: Wave-based infrastructure adds ~300-400 lines to /coordinate including:
- Wave calculation templates and examples (~150 lines)
- Parallel agent invocation patterns (~100 lines)
- Wave verification checkpoints (~100 lines)
- Wave-based checkpointing logic (~50 lines)

### 3. Phase 0 Implementation: Path Pre-Calculation

**Pattern Consistency** (lines 621-778): Nearly identical to /supervise with minor enhancements
- Lines 621-656: Argument parsing, checkpoint resume detection, error diagnostics
- Lines 658-743: Workflow scope detection (4 types: research-only, research-and-plan, full-implementation, debug-only)
- Lines 745-778: Unified workflow initialization via workflow-initialization.sh library

**Minor Differences**: /coordinate adds explicit wave-related context to progress markers but overall structure identical to /supervise.

### 4. Phase 1 Implementation: Research

**Parallel Agent Invocation Pattern** (lines 780-1063):
- Lines 780-827: Complexity-based research topic calculation (1-4 topics)
- Lines 831-865: Parallel research agent invocation template (identical to /supervise)
- Lines 867-985: Mandatory verification with auto-recovery (fail-fast with single retry)
- Lines 987-1063: Conditional overview synthesis based on workflow scope

**Metadata Extraction** (lines 811-842): Context reduction strategy
- Extract title + 50-word summary from each report
- Achieves 95% context reduction (5,000 tokens → 250 tokens)
- Metadata stored in associative array for Phase 2 planning

**Pattern Consistency**: Phase 1 implementation is nearly identical to /supervise, demonstrating reusable orchestration patterns.

**Size Impact**: Metadata extraction adds ~50 lines compared to basic research phase, but achieves critical context reduction goal.

### 5. Phase 2 Implementation: Planning

**Planning Context Preparation** (lines 1065-1268):
- Lines 1087-1118: Metadata-only research report passing (95% context reduction)
- Lines 1120-1143: Plan-architect agent invocation via Task tool with behavioral injection
- Lines 1145-1223: Mandatory verification with fail-fast error handling
- Lines 1225-1301: Workflow completion check for research-and-plan workflows

**Pattern Consistency**: Phase 2 structure matches /supervise exactly, with metadata extraction as the key enhancement.

### 6. Phase 3 Implementation: Wave-Based Execution

**Unique Infrastructure** (lines 1303-1515): Major differentiator from /supervise
- Lines 1303-1372: Dependency analysis and wave calculation using dependency-analyzer.sh
- Lines 1325-1371: Wave structure display showing parallelization plan
- Lines 1373-1400: Implementer-coordinator agent invocation with wave context
- Lines 1402-1515: Wave execution verification and metrics reporting

**Implementer-Coordinator Agent Pattern** (lines 1373-1400):
- Receives complete wave structure and dependency graph
- Orchestrates parallel execution within waves
- Delegates to implementation-executor agents (one per phase)
- Returns structured status including waves_completed, time_saved_percentage

**Wave Checkpointing** (lines 1481-1515):
- Saves checkpoint after each wave boundary
- Enables resume from wave completion point
- Tracks wave execution metrics (parallel phases, time saved)
- Provides context pruning after wave completion

**Size Impact**: Wave-based implementation adds ~350-400 lines compared to /supervise's sequential implementation phase.

**Comparison to /supervise Phase 3** (/home/benjamin/.config/.claude/commands/supervise.md:1150-1278):
- /supervise: Sequential phase-by-phase execution via code-writer agent (128 lines)
- /coordinate: Wave-based parallel execution via implementer-coordinator + implementation-executor agents (212 lines)
- Delta: +84 lines for wave orchestration infrastructure

### 7. Phases 4-6 Implementation: Testing, Debug, Documentation

**Pattern Consistency** (lines 1517-1996): Identical to /supervise
- Phase 4 (Testing): Lines 1517-1630, same test-specialist invocation pattern
- Phase 5 (Debug): Lines 1632-1848, same iterative debug cycle (max 3 iterations)
- Phase 6 (Documentation): Lines 1850-1980, same doc-writer invocation with conditional execution

**Size Parity**: Phases 4-6 contribute equally to both commands (~480 lines each), demonstrating mature pattern reuse.

### 8. Error Handling and Recovery

**Fail-Fast Philosophy** (lines 269-286):
- NO retries: Single execution attempt per operation (except transient failures)
- NO fallbacks: If operation fails, report why and exit with diagnostics
- Clear diagnostics: Every error shows exactly what failed and why
- Debugging guidance: Every error includes steps to diagnose the issue

**Library Requirements** (lines 318-330): All libraries required, no fallback mechanisms
- workflow-detection.sh
- error-handling.sh
- checkpoint-utils.sh
- unified-logger.sh
- unified-location-detection.sh
- metadata-extraction.sh
- context-pruning.sh
- dependency-analyzer.sh (unique to /coordinate)

**Rationale** (lines 332-338): "Fallback mechanisms hide configuration errors and make debugging harder. Explicit errors force proper setup and enable consistent behavior across environments."

**Pattern Consistency**: Fail-fast philosophy identical to /supervise, with dependency-analyzer.sh as the only additional library requirement.

### 9. Agent Behavioral File Integration

**Agent Registry** (lines 1999-2042): 6 specialized agents invoked via Task tool
1. research-specialist.md (Phase 1): Parallel research with mandatory file creation
2. plan-architect.md (Phase 2): Implementation planning with research synthesis
3. implementer-coordinator.md (Phase 3): Wave-based implementation orchestration
4. implementation-executor.md (Phase 3): Individual phase execution within waves
5. test-specialist.md (Phase 4): Comprehensive test execution
6. debug-analyst.md (Phase 5): Root cause analysis and fix proposals
7. doc-writer.md (Phase 6): Workflow summary creation

**Invocation Pattern** (lines 2025-2042): Consistent behavioral injection pattern
```
Task {
  subagent_type: "general-purpose"
  description: "Brief task description"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/[agent-name].md

    **Context**: [Workflow-specific context]

    Execute following all guidelines.
    Return: [SIGNAL]: [artifact_path]
  "
}
```

**Pattern Consistency**: Agent invocation pattern identical to /supervise, demonstrating consistency in behavioral injection approach.

**Unique Agent**: implementer-coordinator.md is specific to /coordinate for wave-based execution orchestration.

### 10. Checkpoint and Resume Capabilities

**Checkpoint API** (lines 334-339): Auto-resume from last completed phase
- Checkpoints saved after Phases 1-4
- Wave-level checkpointing in Phase 3 (unique to /coordinate)
- Validates checkpoint → Skips completed phases → Resumes seamlessly

**Wave Checkpointing** (lines 1481-1499): Enhanced checkpoint structure for /coordinate
- Tracks wave_execution metadata (waves_completed, parallel_phases, time_saved_percentage, duration_seconds)
- Enables resume from wave boundary on interruption
- Preserves wave execution metrics for reporting

**Pattern Enhancement**: /coordinate extends /supervise's checkpoint pattern with wave-specific metadata, enabling more granular resume capabilities.

### 11. Progress Markers and Logging

**Progress Marker Format** (lines 341-349):
```
PROGRESS: [Phase N] - [action]
```

**Examples** (lines 347-349):
- `PROGRESS: [Phase 1] - Research complete (4/4 succeeded)`
- `PROGRESS: [Phase 3] - Implementation complete (8 phases in parallel, 45% time saved)`

**Pattern Consistency**: Progress marker format identical to /supervise, with wave-specific metrics added to Phase 3 markers in /coordinate.

### 12. Context Management and Pruning

**Context Reduction Strategy** (lines 246-252):
- Target: <30% context usage throughout workflow
- Method: Metadata extraction (95% reduction for research reports)
- Application: Aggressive pruning of wave metadata after Phase 3
- Result: Achieved via context-pruning.sh library integration

**Phase-Specific Pruning** (lines 1501-1515):
- Phase 1: Metadata extraction, retain for planning (80-90% reduction)
- Phase 2: Prune research if plan-only workflow
- Phase 3: Aggressive wave metadata pruning, keep summary only
- Phase 4: Retain test output for potential debugging
- Phase 5: Prune test output after debugging complete
- Phase 6: Final pruning, <30% context usage achieved

**Pattern Consistency**: Context management strategy identical to /supervise, demonstrating mature approach to context window optimization.

### 13. Workflow Scope Detection

**Four Workflow Types** (lines 135-184):
1. **research-only**: Phases 0-1 only (keywords: "research [topic]" without "plan" or "implement")
2. **research-and-plan**: Phases 0-2 only (keywords: "research...to create plan", "analyze...for planning") - MOST COMMON
3. **full-implementation**: Phases 0-4, 6 (keywords: "implement", "build", "add feature")
4. **debug-only**: Phases 0, 1, 5 only (keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]")

**Detection Implementation**: Via workflow-detection.sh library, shared with /supervise

**Pattern Consistency**: Workflow scope detection identical to /supervise, demonstrating reusable pattern across orchestration commands.

### 14. Size Analysis and Code Distribution

**Overall Size**:
- /coordinate: 2,148 lines
- /supervise: 1,818 lines
- Delta: +330 lines (+18%)

**Size Breakdown by Category**:

| Category | /coordinate | /supervise | Delta | Reason |
|----------|-------------|-----------|-------|--------|
| Architectural documentation | ~200 lines | ~100 lines | +100 | Wave-based execution explanation |
| Phase 0 (Location) | ~150 lines | ~150 lines | 0 | Identical pattern |
| Phase 1 (Research) | ~280 lines | ~280 lines | 0 | Identical pattern |
| Phase 2 (Planning) | ~200 lines | ~200 lines | 0 | Identical pattern |
| Phase 3 (Implementation) | ~350 lines | ~130 lines | +220 | Wave-based vs sequential |
| Phase 4 (Testing) | ~110 lines | ~110 lines | 0 | Identical pattern |
| Phase 5 (Debug) | ~210 lines | ~210 lines | 0 | Identical pattern |
| Phase 6 (Documentation) | ~130 lines | ~130 lines | 0 | Identical pattern |
| Utility functions | ~300 lines | ~300 lines | 0 | Shared library loading |
| Agent reference | ~100 lines | ~100 lines | 0 | Identical pattern |
| Examples | ~120 lines | ~120 lines | 0 | Identical pattern |

**Key Insight**: 18% size increase is primarily due to wave-based execution infrastructure in Phase 3 and enhanced architectural documentation explaining wave-based execution. All other phases demonstrate pattern consistency with /supervise.

### 15. Library Dependencies

**Shared Libraries** (8 libraries):
1. library-sourcing.sh (consolidated loading)
2. workflow-detection.sh (scope detection)
3. error-handling.sh (fail-fast error handling)
4. checkpoint-utils.sh (resume capability)
5. unified-logger.sh (progress tracking)
6. unified-location-detection.sh (path calculation)
7. metadata-extraction.sh (context reduction)
8. context-pruning.sh (context optimization)
9. dependency-analyzer.sh (unique to /coordinate)

**Library Loading Pattern** (lines 352-388): Consolidated via library-sourcing.sh
- Lines 352-379: Source library-sourcing.sh with fail-fast error handling
- Lines 381-386: Call source_required_libraries() with dependency-analyzer.sh parameter
- Lines 388: Success confirmation

**Pattern Consistency**: Library loading pattern identical to /supervise, with dependency-analyzer.sh as the only additional dependency.

### 16. Verification and Validation Patterns

**Mandatory Verification Checkpoints** (throughout command):
- Phase 1: Research report verification (lines 867-985)
- Phase 2: Plan file verification (lines 1145-1223)
- Phase 3: Wave execution verification (lines 1402-1515)
- Phase 4: Test results verification (lines 1572-1630)
- Phase 5: Debug report verification (lines 1698-1742)
- Phase 6: Summary file verification (lines 1909-1980)

**Verification Pattern** (consistent across all phases):
1. Check file exists and has content (with retry for transient failures)
2. Extract error info if verification fails
3. Classify error type (transient vs permanent)
4. Apply single retry for transient errors
5. Fail-fast with diagnostics for permanent errors

**Pattern Consistency**: Verification pattern identical to /supervise, demonstrating mature approach to fail-fast error handling with minimal retry infrastructure.

### 17. Optimization History and Design Decisions

**Optimization Note** (lines 592-619): "Integration, not build" approach
- Original plan: 6 phases, 12-15 days estimated duration
- Optimized approach: 3 phases, 8-11 days actual duration (40-50% reduction)
- Key insight: 70-80% of planned infrastructure already existed in production-ready form

**Infrastructure Maturity Impact**:
- 100% coverage on location detection, metadata extraction, context pruning, error handling
- All 6 agent behavioral files already exist (no extraction needed)
- Library consolidation instead of rebuilding
- Git-based version control instead of manual backups

**Time Savings**: 4-5 days (40-50% reduction) by integrating existing infrastructure

**Pattern Insight**: Design decision to reuse /supervise patterns and extend with wave-based execution was correct approach, avoiding redundant work while adding targeted functionality.

### 18. Performance Metrics and Success Criteria

**Performance Targets** (lines 2097-2132):
- File creation rate: 100% (strong enforcement, first attempt)
- Context usage: <25% cumulative across all phases
- Zero fallbacks: Single working path, fail-fast on errors
- Wave-based execution: 40-60% time savings from parallel implementation
- Progress streaming: Silent PROGRESS: markers at each phase boundary
- Error reporting: Clear diagnostics, debugging guidance, file system state

**Success Criteria Categories**:
1. Architectural Excellence (6 criteria)
2. Enforcement Standards (5 criteria)
3. Performance Targets (6 criteria)
4. Auto-Recovery Features (8 criteria)
5. Deficiency Resolution (4 criteria)

**Total Success Criteria**: 29 criteria across 5 categories

**Pattern Consistency**: Success criteria structure identical to /supervise, with wave-based execution metrics as the only addition.

### 19. Usage Examples and Common Patterns

**Example Workflows** (lines 2043-2095):

1. **Research-only** (lines 2047-2057):
   - Command: `/coordinate "research API authentication patterns"`
   - Phases: 0-1 only
   - Artifacts: 2-3 research reports
   - No plan, implementation, or summary

2. **Research-and-plan** (lines 2059-2071) - MOST COMMON:
   - Command: `/coordinate "research the authentication module to create a refactor plan"`
   - Phases: 0-2 only
   - Artifacts: 4 research reports + 1 implementation plan
   - No implementation or summary (per standards)

3. **Full-implementation** (lines 2073-2083):
   - Command: `/coordinate "implement OAuth2 authentication for the API"`
   - Phases: 0-4, 6 (Phase 5 conditional on test failures)
   - Artifacts: reports + plan + implementation + summary
   - Wave-based parallel execution in Phase 3

4. **Debug-only** (lines 2085-2095):
   - Command: `/coordinate "fix the token refresh bug in auth.js"`
   - Phases: 0, 1, 5 only
   - Artifacts: research reports + debug report
   - No new plan or implementation (fixes existing code)

**Pattern Consistency**: Usage examples structure identical to /supervise, demonstrating consistent user experience across orchestration commands.

### 20. Documentation and Reference Structure

**External Documentation References** (throughout command):
- Lines 111-113: [Hierarchical Agent Architecture Guide](../docs/concepts/hierarchical_agents.md)
- Lines 2041: [Behavioral Injection Pattern](../docs/concepts/patterns/behavioral-injection.md)
- Lines 338: [Checkpoint Recovery Pattern](../docs/concepts/patterns/checkpoint-recovery.md)
- Lines 619: [Research Report Overview](../../specs/438_analysis_of_supervise_command_refactor_plan_for_re/reports/001_analysis_of_supervise_command_refactor_plan_for_re_research/OVERVIEW.md)

**Documentation Strategy**: Command files contain execution-critical inline content, external docs provide supplemental context and reference material.

**Pattern Consistency**: Documentation reference strategy identical to /supervise, following Command Architecture Standards.

## Recommendations

### 1. Maintain Wave-Based Execution as Differentiator

**Rationale**: Wave-based parallel execution provides 40-60% time savings for full-implementation workflows, justifying the 18% size increase over /supervise. This is a valuable capability for large-scale implementation projects.

**Action**: Preserve Phase 3 wave-based infrastructure including:
- dependency-analyzer.sh library integration
- Implementer-coordinator agent orchestration pattern
- Wave checkpointing and metrics reporting
- Parallel agent invocation within waves

### 2. Consider Consolidating Phase 4-6 with /supervise

**Rationale**: Phases 4-6 (Testing, Debug, Documentation) are identical between /coordinate and /supervise, demonstrating mature pattern reuse. Potential for further consolidation via shared phase library.

**Action**: Evaluate extraction of Phases 4-6 to `.claude/lib/orchestration-phases-4-6.sh` library:
- Would reduce duplication across orchestration commands
- Would enable consistent behavior updates across all orchestration commands
- Would reduce maintenance burden (single source of truth)

**Effort Estimate**: 1-2 hours to extract and test shared phase library

### 3. Document Wave-Based Execution Decision Criteria

**Rationale**: Users need guidance on when to use /coordinate (wave-based) vs /supervise (sequential) for their workflows.

**Action**: Add decision criteria section to command documentation:
- Use /coordinate when: >5 phases, parallel-safe operations, time-critical projects
- Use /supervise when: <5 phases, sequential dependencies, debugging-focused workflows
- Use /orchestrate when: Full dashboard tracking, PR automation needed

**Effort Estimate**: 30 minutes to document decision criteria

### 4. Enhance Wave Execution Visibility

**Rationale**: Wave-based execution is complex and users benefit from clear visibility into wave boundaries, parallel execution status, and time savings metrics.

**Action**: Add enhanced progress markers for wave execution:
- `PROGRESS: [Phase 3] - Wave 1/4 starting (3 phases in parallel)`
- `PROGRESS: [Phase 3] - Wave 1/4 complete (3 phases finished)`
- `PROGRESS: [Phase 3] - All waves complete (45% time saved vs sequential)`

**Effort Estimate**: 1 hour to enhance progress markers

### 5. Validate Dependency-Analyzer Library Performance

**Rationale**: Dependency analysis via dependency-analyzer.sh is critical path for wave execution. Performance bottlenecks in parsing or topological sorting would degrade user experience.

**Action**: Performance testing and optimization:
- Benchmark dependency parsing on plans with 10, 20, 50 phases
- Profile topological sort algorithm for large dependency graphs
- Add caching for repeated dependency analysis calls
- Document performance characteristics in library header

**Effort Estimate**: 2-3 hours for comprehensive performance testing

### 6. Add Wave Execution Validation Tests

**Rationale**: Wave-based execution is complex logic with multiple edge cases (circular dependencies, disconnected graphs, single-phase waves). Comprehensive testing ensures reliability.

**Action**: Create `.claude/tests/test_wave_execution.sh` with test cases:
- Parse inline plan dependencies (Level 0)
- Parse hierarchical plan dependencies (Level 1, Level 2)
- Detect circular dependencies
- Calculate waves for various dependency patterns
- Validate parallelization metrics calculation

**Effort Estimate**: 3-4 hours for comprehensive test suite

**Expected Coverage**: >80% code coverage for dependency-analyzer.sh

### 7. Preserve Fail-Fast Error Handling Philosophy

**Rationale**: Fail-fast error handling with comprehensive diagnostics is a key strength of /coordinate, enabling rapid debugging and clear error reporting. This should be preserved and extended.

**Action**: Maintain fail-fast philosophy across all phases:
- Single retry for transient errors only
- Clear diagnostics with file system state on failure
- Debugging guidance included in every error message
- No silent degradation or hidden fallback mechanisms

### 8. Monitor Context Usage Metrics

**Rationale**: Context usage target of <30% throughout workflow is ambitious. Actual context usage should be monitored to validate metadata extraction and pruning strategies.

**Action**: Add context usage instrumentation:
- Log context size at each phase boundary
- Report cumulative context usage at workflow completion
- Alert if context usage exceeds 30% target
- Identify phases with highest context consumption

**Effort Estimate**: 2 hours for instrumentation implementation

### 9. Consider Async Wave Execution

**Rationale**: Current wave execution is synchronous (wait for all phases in wave to complete before proceeding to next wave). Async execution could enable further time savings by starting next wave's independent phases earlier.

**Action**: Evaluate async wave execution pattern:
- Stream phase completion events to orchestrator
- Calculate wave boundary completion incrementally
- Start next wave's independent phases as soon as dependencies satisfied
- Requires enhanced checkpoint and error handling for mid-wave failures

**Effort Estimate**: 4-6 hours for design and prototype

**Expected Impact**: Additional 10-20% time savings for workflows with long-running phases

### 10. Document Agent Behavioral File Requirements

**Rationale**: /coordinate relies on 7 specialized agents with specific behavioral files. Missing or malformed agent files would cause runtime errors.

**Action**: Add agent validation to startup sequence:
- Check all required agent files exist (.claude/agents/*.md)
- Validate agent file format and required sections
- Report clear error message if agent file missing or invalid
- Reference agent-schema-validator.sh library for validation logic

**Effort Estimate**: 1-2 hours for validation implementation

## References

### Files Analyzed

1. `/home/benjamin/.config/.claude/commands/coordinate.md` (2,148 lines)
   - Lines 1-67: Orchestrator role and architectural prohibition
   - Lines 135-244: Workflow overview and wave-based execution
   - Lines 269-330: Error handling and library requirements
   - Lines 621-1996: Phase implementations (0-6)
   - Lines 1999-2042: Agent behavioral file integration
   - Lines 2043-2095: Usage examples

2. `/home/benjamin/.config/.claude/commands/supervise.md` (1,818 lines)
   - Comparative analysis for pattern consistency validation
   - Reference implementation for orchestration patterns

3. `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh` (639 lines)
   - Lines 1-58: Structure level detection
   - Lines 60-261: Dependency parsing (inline, hierarchical, deep)
   - Lines 263-286: Dependency graph construction
   - Lines 288-392: Wave identification via Kahn's algorithm
   - Lines 394-474: Cycle detection via DFS
   - Lines 476-528: Parallelization metrics calculation

### Related Documentation

- [Behavioral Injection Pattern](../docs/concepts/patterns/behavioral-injection.md) - Agent invocation pattern
- [Checkpoint Recovery Pattern](../docs/concepts/patterns/checkpoint-recovery.md) - Resume capability
- [Hierarchical Agent Architecture Guide](../docs/concepts/hierarchical_agents.md) - Multi-level coordination
- [Command Architecture Standards](../docs/reference/command_architecture_standards.md) - Design guidelines

### Library Dependencies

1. library-sourcing.sh - Consolidated library loading
2. workflow-detection.sh - Workflow scope detection
3. error-handling.sh - Fail-fast error handling
4. checkpoint-utils.sh - Resume capability
5. unified-logger.sh - Progress tracking
6. unified-location-detection.sh - Path calculation
7. metadata-extraction.sh - Context reduction
8. context-pruning.sh - Context optimization
9. dependency-analyzer.sh - Wave execution (unique to /coordinate)

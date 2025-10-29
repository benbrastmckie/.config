# Research Overview: Orchestration Command Comparison and Migration Feasibility

## Metadata
- **Date**: 2025-10-28
- **Agent**: research-synthesizer
- **Topic Number**: 513
- **Individual Reports**: 4 reports synthesized
- **Reports Directory**: /home/benjamin/.config/.claude/specs/513_compare_orchestrate_supervise_and_coordinate_in_or/reports/001_compare_orchestrate_supervise_and_coordinate_in_or

## Executive Summary

This comprehensive analysis compares three orchestration commands (/orchestrate, /supervise, /coordinate) to determine whether /orchestrate and /supervise can be deprecated in favor of /coordinate. **Key finding: All three commands should be retained** as they serve distinct use cases despite sharing 100% architectural compatibility. The commands implement identical core patterns (7-phase workflow, behavioral injection, fail-fast error handling, checkpoint recovery, >90% agent delegation rate) but differ significantly in advanced features and complexity. /orchestrate uniquely provides PR automation and interactive dashboard tracking for full-featured workflows. /supervise serves as the proven minimal reference implementation with comprehensive external documentation. /coordinate introduces wave-based parallel execution achieving 40-60% time savings while maintaining clean architecture at 2,500-3,000 lines (46-54% smaller than /orchestrate's 5,438 lines). The commands are fully interoperable and can be used interchangeably based on workflow requirements, making deprecation unnecessary and potentially limiting user choice.

## Related Subtopic Reports

This overview synthesizes findings from the following detailed subtopic reports:

1. **[/orchestrate Unique Features and Capabilities](./001_orchestrate_unique_features_and_capabilities.md)** - Analysis of PR automation, interactive dashboard, and comprehensive metrics tracking capabilities unique to /orchestrate
2. **[/supervise Unique Features and Capabilities](./002_supervise_unique_features_and_capabilities.md)** - Analysis of fail-fast error handling, external documentation ecosystem, and sequential execution validation
3. **[/coordinate Unique Features and Capabilities](./003_coordinate_unique_features_and_capabilities.md)** - Analysis of workflow scope auto-detection, wave-based parallel execution, and streamlined architecture
4. **[Comparative Analysis and Migration Feasibility](./004_comparative_analysis_and_migration_feasibility.md)** - Comprehensive comparison across architecture, complexity, features, and performance with migration recommendations

## Research Structure

1. **[/orchestrate Unique Features](./001_orchestrate_unique_features_and_capabilities.md)** - Analysis of PR automation, interactive dashboard, and comprehensive metrics tracking capabilities unique to /orchestrate
2. **[/supervise Unique Features](./002_supervise_unique_features_and_capabilities.md)** - Analysis of fail-fast error handling, external documentation ecosystem, and sequential execution validation
3. **[/coordinate Unique Features](./003_coordinate_unique_features_and_capabilities.md)** - Analysis of workflow scope auto-detection, wave-based parallel execution, and streamlined architecture
4. **[Comparative Analysis and Migration Feasibility](./004_comparative_analysis_and_migration_feasibility.md)** - Comprehensive comparison across architecture, complexity, features, and performance with migration recommendations

## Cross-Report Findings

### 1. Complete Architectural Compatibility (100% Overlap)

All three commands implement identical core architectural patterns, confirming they are fully interoperable:

**7-Phase Workflow Architecture**: Phase 0 (location pre-calculation) → Phase 1 (parallel research with 2-4 agents) → Phase 2 (planning) → Phase 3 (implementation) → Phase 4 (testing) → Phase 5 (conditional debug) → Phase 6 (conditional documentation). As noted in [Comparative Analysis](./004_comparative_analysis_and_migration_feasibility.md), this pattern is identical across all commands with conditional phase execution based on workflow scope.

**Behavioral Injection Pattern**: All commands use Task tool (NOT SlashCommand) for direct agent invocation with pre-calculated paths and behavioral guidelines from `.claude/agents/*.md` files. This pattern was unified across commands through Specs 438, 495, and 497, achieving >90% agent delegation rate for all commands ([/orchestrate Features](./001_orchestrate_unique_features_and_capabilities.md), [/supervise Features](./002_supervise_unique_features_and_capabilities.md), [/coordinate Features](./003_coordinate_unique_features_and_capabilities.md)).

**Fail-Fast Error Handling**: All commands implement single execution attempts with zero retries, comprehensive 5-section diagnostics (Expected/Found/Diagnostic/Commands/Causes), and immediate termination with actionable guidance. As documented in [/supervise Features](./002_supervise_unique_features_and_capabilities.md), this achieves 100% file creation reliability with zero retry overhead.

**Checkpoint Recovery**: All commands save checkpoints after Phases 1-4 using identical JSON schema (workflow_scope, current_phase, research_reports, plan_path, impl_artifacts, test_status), enabling auto-resume from last completed phase ([Comparative Analysis](./004_comparative_analysis_and_migration_feasibility.md)).

**Context Management**: All commands target <30% context usage through metadata extraction (80-90% reduction in Phases 1-2) and progressive context pruning after each phase ([/coordinate Features](./003_coordinate_unique_features_and_capabilities.md), [/supervise Features](./002_supervise_unique_features_and_capabilities.md)).

**Shared Infrastructure**: All commands use identical library dependencies (workflow-detection.sh, error-handling.sh, checkpoint-utils.sh, unified-logger.sh, unified-location-detection.sh, metadata-extraction.sh, context-pruning.sh) and agent behavioral files (research-specialist.md, plan-architect.md, implementation-executor.md, test-specialist.md, debug-analyst.md, doc-writer.md).

### 2. Unique Features Define Distinct Use Cases

While architecturally identical, each command provides unique capabilities that cannot be easily replaced:

**/orchestrate Unique Features** ([Full Report](./001_orchestrate_unique_features_and_capabilities.md)):
- **PR Automation**: Only command with github-specialist agent integration (574 lines) for automatic pull request creation with comprehensive metadata extraction, branch management, and CI/CD monitoring
- **Interactive Progress Dashboard**: Real-time ANSI terminal dashboard (351-line library) with Unicode box-drawing, status icons, phase progress visualization, and graceful fallback to PROGRESS markers
- **Comprehensive Metrics Tracking**: Workflow execution metrics including context usage analysis, agent delegation rates, wave-based parallelization time savings, file creation reliability, and token usage with performance reporting dashboard

**/supervise Unique Features** ([Full Report](./002_supervise_unique_features_and_capabilities.md)):
- **Comprehensive External Documentation**: Only command with dedicated usage guide (7.2 KB) and phase reference (14.3 KB) separating usage patterns from technical implementation, improving maintainability
- **Proven Architectural Compliance**: Extensively validated through Spec 507 refactoring achieving 40-60% faster implementation than estimated (12 hours vs 21-30 hours) through library consolidation
- **Partial Failure Handling**: Unique logic allowing continuation if ≥50% of parallel research agents succeed (Phase 1 only), with all other phases requiring 100% success
- **Sequential Execution Validation**: Aggressive library consolidation (90% code reduction from 126→25 lines) and explicit context pruning integration validated through extensive refactoring

**/coordinate Unique Features** ([Full Report](./003_coordinate_unique_features_and_capabilities.md)):
- **Workflow Scope Auto-Detection**: Automatic detection of 4 workflow types (research-only, research-and-plan, full-implementation, debug-only) based on natural language description keywords, dynamically skipping irrelevant phases
- **Wave-Based Parallel Implementation**: Dependency analysis using Kahn's algorithm for topological sorting, enabling parallel phase execution within waves for 40-60% time savings (typical case)
- **Concise Verification Formatting**: Silent success pattern with single-character "✓" indicators achieving 90% token reduction (3,500→350 tokens across 7 checkpoints), verbose failure diagnostics maintained
- **Pure Orchestration Architecture**: Explicit prohibition of command chaining via SlashCommand tool with detailed rationale and enforcement guidance, ensuring lean context through direct agent invocation
- **Streamlined Implementation**: 2,500-3,000 lines (46-54% smaller than /orchestrate) achieved through "integrate, not build" approach leveraging 70-80% existing infrastructure

### 3. Performance Characteristics Reveal Optimization Opportunities

All commands target identical performance metrics but achieve them through different approaches:

**Shared Performance Targets** ([Comparative Analysis](./004_comparative_analysis_and_migration_feasibility.md)):
- Context usage: <30% throughout workflow
- File creation rate: 100% reliability
- Metadata extraction reduction: 80-90%
- Agent delegation rate: >90%

**Wave-Based Execution Advantage** (/coordinate only, [/coordinate Features](./003_coordinate_unique_features_and_capabilities.md)):
- Best case: 60% time savings (many independent phases)
- Typical case: 40-50% time savings (moderate dependencies)
- Worst case: 0% savings (fully sequential dependencies)
- No overhead for plans with <3 phases (single wave)

**Example Wave Performance** (8-phase plan with moderate dependencies):
- Sequential execution (/orchestrate, /supervise): 8 phases × avg_time = 8T
- Wave-based execution (/coordinate): 4 waves × avg_time = 4T (50% time savings)

**Research-and-Plan Workflows**: All three commands perform identically (wave execution not applicable without Phase 3 implementation).

### 4. File Size and Complexity Analysis

**Measured File Sizes**:
- /orchestrate: 5,438 lines (high complexity, complete feature set)
- /supervise: 1,939 lines (medium complexity, proven compliance)
- /coordinate: 2,500-3,000 lines (medium complexity, wave-based + core orchestration)

**Size Reduction Analysis** ([/coordinate Features](./003_coordinate_unique_features_and_capabilities.md)):
- /coordinate vs /orchestrate: 46-54% reduction (2,500-3,000 vs 5,438)
- Primary removals: PR automation (~500 lines), dashboard tracking (~400 lines), enhanced documentation (~300 lines)
- /coordinate vs /supervise: 29% increase (wave infrastructure overhead: dependency-analyzer.sh integration, wave checkpointing, parallel execution coordination)

**Complexity Trade-offs**:
- /supervise: Smallest file, simplest implementation, most extensively documented
- /coordinate: Medium file, adds wave-based execution complexity, concise inline documentation
- /orchestrate: Largest file, complete feature set including PR automation and dashboards, comprehensive inline documentation

### 5. Migration Feasibility and Interoperability

All three commands are **fully interoperable** due to shared infrastructure:

**Compatibility Evidence** ([Comparative Analysis](./004_comparative_analysis_and_migration_feasibility.md)):
- Same behavioral agent files (`.claude/agents/*.md`)
- Same library dependencies (`.claude/lib/*.sh`)
- Same artifact directory structure (`specs/{NNN_topic}/reports|plans|summaries`)
- Same checkpoint format (JSON with identical schema)

**Key Insight**: Commands can be used interchangeably at the workflow level. Users can run Phase 0-2 with /coordinate, then switch to /orchestrate for Phase 3 if PR automation is needed, or start with /supervise for research-only workflows.

**Migration Risk Assessment**:
- Command switching: Zero risk (drop-in compatible)
- Checkpoint compatibility: Zero risk (identical JSON schema)
- Wave execution differences: No risk (both produce identical artifacts, just different execution order)
- Missing PR automation: Manageable (use appropriate command for workflow needs)

## Detailed Findings by Topic

### /orchestrate Unique Features and Capabilities

The /orchestrate command positions itself as the "batteries-included" solution with three unique capabilities not found in /supervise or /coordinate: (1) PR automation via github-specialist agent for automatic pull request creation with rich metadata, (2) interactive progress dashboard with ANSI terminal rendering and real-time visual feedback, and (3) comprehensive workflow metrics tracking including context usage, time savings, and agent delegation rates.

**Key Capabilities**:
- **PR Automation**: Automatic or flag-triggered (`--create-pr`) pull request creation with comprehensive descriptions from implementation plans, metadata extraction from artifacts, label/reviewer/milestone management, GitHub Actions CI/CD monitoring, and merge conflict validation
- **Interactive Dashboard**: Terminal capability detection (ANSI support, colors, interactive mode), real-time in-place updates using ANSI escape codes, Unicode box-drawing for professional layout, status icons (✓ complete, → in progress, ⬚ pending), graceful fallback to PROGRESS markers
- **Metrics Tracking**: Context usage analysis targeting <30%, agent delegation rates targeting >90%, wave-based parallelization time savings (40-60%), file creation reliability (100%), test coverage percentages, token usage tracking

**Command Selection Criteria**: Use /orchestrate for complex multi-phase projects requiring end-to-end automation, automatic PR creation, visual progress feedback, or comprehensive performance reporting.

[Full Report](./001_orchestrate_unique_features_and_capabilities.md)

### /supervise Unique Features and Capabilities

The /supervise command distinguishes itself as the proven reference implementation with three primary unique features: (1) comprehensive external documentation ecosystem (usage guide + phase reference) reducing command file size by 14% while improving maintainability, (2) proven fail-fast error handling with structured 5-section diagnostics achieving 100% file creation reliability, and (3) sequential execution pattern validated through Spec 507 refactoring demonstrating 40-60% faster implementation than estimated.

**Key Capabilities**:
- **External Documentation**: Dedicated usage guide (277 lines, 7.2 KB) with 4 workflow scope types, common patterns, troubleshooting; Phase reference (568 lines, 14.3 KB) with detailed technical documentation, agent invocation patterns, verification checkpoints
- **Fail-Fast Error Handling**: Structured 5-section diagnostic templates (ERROR/Expected/Found/Diagnostic/Commands/Causes) at all 7 verification checkpoints, immediate feedback (<1s vs 3-5s retry delay), zero retry overhead
- **Library Consolidation**: 90% code reduction (126→25 lines) using consolidated library-sourcing pattern, explicit context pruning integration after each phase with reduction reporting
- **Partial Failure Handling**: Unique logic allowing ≥50% research success threshold (Phase 1 only), all other phases require 100% success
- **Research Complexity Scaling**: Dynamic agent scaling (1-4 agents) based on workflow description keywords

**Command Selection Criteria**: Use /supervise for proven architectural compliance, minimal complexity reference implementation, learning the orchestration pattern, or when comprehensive external documentation is valuable.

[Full Report](./002_supervise_unique_features_and_capabilities.md)

### /coordinate Unique Features and Capabilities

The /coordinate command represents a streamlined orchestration approach focused on clean architecture and performance optimization. Its unique capabilities include: (1) workflow scope auto-detection analyzing natural language descriptions to determine execution phases, (2) wave-based parallel implementation achieving 40-60% time savings, (3) concise verification formatting reducing context consumption by 90%, and (4) pure orchestration architecture explicitly prohibiting command chaining.

**Key Capabilities**:
- **Workflow Scope Auto-Detection**: Automatic detection of 4 types (research-only, research-and-plan, full-implementation, debug-only) based on keywords, dynamic phase skipping, eliminates need for explicit workflow type specification
- **Wave-Based Parallel Execution**: Dependency analysis via dependency-analyzer.sh, Kahn's algorithm for topological sorting, parallel phase execution within waves, 40-60% typical time savings, wave-level checkpointing
- **Concise Verification**: Silent success pattern (single-character "✓"), 90% token reduction (3,500→350 tokens), verbose failure diagnostics maintained, inline verification helper function
- **Pure Orchestration**: Explicit prohibition of SlashCommand tool, direct agent invocation via Task tool, lean context through behavioral injection, structured output metadata
- **Streamlined Implementation**: 2,500-3,000 lines (46-54% smaller than /orchestrate), "integrate, not build" approach leveraging 70-80% existing infrastructure, realistic file size targets

**Command Selection Criteria**: Use /coordinate for performance-critical workflows requiring wave-based parallelization, clean minimal orchestration without PR automation overhead, or when auto-detection of workflow scope improves user experience.

[Full Report](./003_coordinate_unique_features_and_capabilities.md)

### Comparative Analysis and Migration Feasibility

Comprehensive comparison reveals all three commands share 100% architectural compatibility (7 phases, behavioral injection, fail-fast, checkpoint recovery) but differ significantly in advanced features. /coordinate achieves 50-54% size reduction (2,500-3,000 vs 5,438 lines) primarily by removing PR automation, dashboard tracking, and documentation while maintaining 100% core orchestration functionality.

**Key Findings**:
- **Architectural Patterns**: 100% overlap on core patterns (workflow, agents, libraries, error handling, checkpoints, context management)
- **Feature Completeness**: All commands implement 7-phase workflow, scope detection, behavioral injection, fail-fast, checkpoints, context management; Only /coordinate provides wave-based execution; Only /orchestrate provides PR automation and dashboards
- **Performance Targets**: Identical across all commands (context <30%, file creation 100%, metadata reduction 80-90%, agent delegation >90%)
- **Wave-Based Performance**: 40-60% time savings for /coordinate vs sequential execution in /orchestrate and /supervise
- **Library Dependencies**: All commands use identical core libraries; /coordinate adds dependency-analyzer.sh for wave calculation
- **Agent Behavioral Files**: All commands use identical agent invocation patterns with same behavioral files
- **Interoperability**: Commands are drop-in compatible and can be switched mid-workflow

**Migration Scenarios**:
1. /orchestrate → /coordinate: Feature loss (PR automation, dashboards), feature gain (wave-based 40-60% time savings), 100% compatibility
2. /supervise → /coordinate: No feature loss, feature gain (wave-based execution), 100% compatibility
3. /coordinate → /orchestrate: Feature loss (wave execution), feature gain (PR automation, dashboards), 100% compatibility
4. Keep all three: Optimal command selection per workflow type, no risk, interoperable

**Migration Risks**: Low across all scenarios due to shared infrastructure, identical checkpoint schemas, and drop-in compatibility.

[Full Report](./004_comparative_analysis_and_migration_feasibility.md)

## Recommended Approach

### Primary Recommendation: Retain All Three Commands

**Rationale**: Each command serves distinct use cases and provides unique value:

1. **/orchestrate**: Essential for workflows requiring PR automation (github-specialist integration) or interactive dashboard tracking (progress-dashboard.sh). The 5,438-line implementation includes features that cannot be easily replaced without significant development effort. **Use case**: Complex multi-phase projects with GitHub integration, end-to-end automation with PR creation, workflows requiring visual progress feedback or comprehensive metrics reporting.

2. **/supervise**: Serves as the proven minimal reference implementation (1,939 lines) with comprehensive external documentation (usage guide + phase reference). Extensively validated through Spec 507 refactoring and multiple anti-pattern resolution efforts (Specs 438, 495, 057, 497). **Use case**: Learning the orchestration pattern, proven architectural compliance, research-only or simple workflows, when extensive external documentation is valuable.

3. **/coordinate**: Provides unique wave-based parallel execution (40-60% time savings) while maintaining clean architecture (2,500-3,000 lines, 46-54% smaller than /orchestrate). Includes workflow scope auto-detection and concise verification formatting. **Use case**: Performance-critical implementation workflows without PR automation, manual PR creation workflows, when wave-based parallelization provides significant time savings.

### Command Selection Decision Tree

```
Does workflow require GitHub PR automation?
  → Yes: Use /orchestrate (only command with PR automation)
  → No: Continue to next question

Does workflow include implementation phase (Phase 3)?
  → Yes: Use /coordinate (40-60% time savings via wave-based execution)
  → No: Continue to next question

Does workflow require research + planning only?
  → Yes: Use /supervise OR /coordinate (equivalent for non-implementation workflows)

Is this a learning or reference scenario?
  → Yes: Use /supervise (smallest, most documented, proven compliance)

Does workflow need dashboard/metrics tracking?
  → Yes: Use /orchestrate (only command with interactive dashboard)
```

### Interoperability Strategy

Commands can be used interchangeably based on workflow phase requirements:

1. **Research-only workflows**: Start with /supervise (smallest, simplest)
2. **Research-and-plan workflows**: Use /coordinate or /supervise (equivalent performance)
3. **Implementation workflows (manual PRs)**: Use /coordinate (wave-based 40-60% time savings)
4. **Implementation workflows (GitHub PRs)**: Use /orchestrate (automatic PR creation)
5. **Mixed workflows**: Start with /coordinate for Phases 0-2, switch to /orchestrate for Phase 3 if PR automation needed

### Documentation Improvements

**Create Selection Guide** in `.claude/docs/guides/orchestration-command-selection.md`:
- Decision tree for command selection
- Feature comparison matrix
- Migration path examples
- Interoperability patterns

**Update CLAUDE.md** (lines 202-246):
- Add command selection guidance
- Document unique features per command
- Provide use case recommendations
- Include interoperability examples

**Extract Common Patterns** to `.claude/docs/concepts/patterns/`:
- Pure orchestration prohibition (from /coordinate)
- Concise verification pattern (from /coordinate)
- External documentation approach (from /supervise)
- Wave-based execution pattern (from /coordinate)

## Constraints and Trade-offs

### Trade-offs by Command

**/orchestrate Trade-offs**:
- **Pro**: Complete feature set (PR automation, dashboard, metrics), comprehensive inline documentation, proven production use
- **Con**: Largest file size (5,438 lines), highest complexity, no wave-based parallel execution, most maintenance burden

**/supervise Trade-offs**:
- **Pro**: Smallest file size (1,939 lines), simplest implementation, comprehensive external documentation, proven architectural compliance, most extensively validated
- **Con**: No wave-based execution (sequential only), no PR automation, no dashboard tracking, 40-60% slower for implementation phases

**/coordinate Trade-offs**:
- **Pro**: Wave-based parallel execution (40-60% time savings), workflow scope auto-detection, concise verification (90% token reduction), clean architecture, 46-54% smaller than /orchestrate
- **Con**: No PR automation (manual PRs required), no dashboard tracking, 29% larger than /supervise due to wave infrastructure, requires all 8 libraries (fail-fast if missing)

### Deprecation Risks

**If /orchestrate is deprecated**:
- **Loss**: PR automation (no replacement), interactive dashboard (no replacement), comprehensive metrics tracking (no replacement)
- **Impact**: Teams using GitHub workflows must manually create PRs, no visual progress feedback, reduced performance visibility
- **Mitigation**: Not feasible without significant development effort to port features to /coordinate

**If /supervise is deprecated**:
- **Loss**: Smallest reference implementation (1,939 lines vs 2,500-3,000), comprehensive external documentation, proven minimal complexity baseline
- **Impact**: No minimal orchestration reference, increased onboarding complexity for new users, loss of extensively validated baseline
- **Mitigation**: Partial (use /coordinate for most workflows, but complexity increases by 29%)

**If both are deprecated**:
- **Loss**: All above losses combined
- **Impact**: Single command must serve all use cases, increased complexity for simple workflows, no reference implementation, mandatory wave infrastructure even for sequential workflows
- **Mitigation**: Not recommended

### Context Management Considerations

All commands target <30% context usage through:
- Metadata extraction (80-90% reduction)
- Progressive context pruning after each phase
- Structured return formats (path + summary, not full content)
- Forward message pattern (pass subagent responses directly)

**Wave-Based Execution Context Impact** (/coordinate):
- Parallel execution may increase peak context usage (multiple agents active simultaneously)
- Mitigated through metadata-only passing and aggressive pruning
- Actual impact: Minimal (<5% increase) due to structured agent communication

**Dashboard Context Impact** (/orchestrate):
- Dashboard state tracking adds minimal context overhead (~100 tokens)
- In-place ANSI updates eliminate history accumulation
- Graceful fallback to PROGRESS markers for incompatible terminals

## References

### Individual Research Reports
1. [/orchestrate Unique Features and Capabilities](./001_orchestrate_unique_features_and_capabilities.md) - PR automation, interactive dashboard, comprehensive metrics tracking
2. [/supervise Unique Features and Capabilities](./002_supervise_unique_features_and_capabilities.md) - Fail-fast error handling, external documentation ecosystem, sequential execution validation
3. [/coordinate Unique Features and Capabilities](./003_coordinate_unique_features_and_capabilities.md) - Workflow scope auto-detection, wave-based parallel execution, streamlined architecture
4. [Comparative Analysis and Migration Feasibility](./004_comparative_analysis_and_migration_feasibility.md) - Comprehensive comparison, migration scenarios, command selection guidance

### Command Files
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (5,438 lines) - Full-featured orchestration with PR automation and dashboards
- `/home/benjamin/.config/.claude/commands/supervise.md` (1,939 lines) - Proven minimal reference implementation
- `/home/benjamin/.config/.claude/commands/coordinate.md` (2,500-3,000 lines) - Wave-based orchestration with clean architecture

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (671 lines) - Research agent used by all commands
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Planning agent used by all commands
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Wave orchestration agent (/coordinate only)
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Phase execution agent (all commands)
- `/home/benjamin/.config/.claude/agents/github-specialist.md` (574 lines) - PR automation agent (/orchestrate only)
- `/home/benjamin/.config/.claude/agents/test-specialist.md` - Test execution agent (all commands)
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` - Debug investigation agent (all commands)
- `/home/benjamin/.config/.claude/agents/doc-writer.md` - Documentation agent (all commands)

### Library Files (Shared by All Commands)
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` - Workflow scope detection and phase execution control
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Error classification and diagnostic generation
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore and field access
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Progress markers and event logging
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Topic directory structure creation
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Context reduction via metadata-only passing
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context optimization between phases
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh` - Wave calculation and topological sorting (/coordinate only)
- `/home/benjamin/.config/.claude/lib/progress-dashboard.sh` (351 lines) - Interactive dashboard rendering (/orchestrate only)

### Documentation References
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern (shared)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - Error handling pattern (shared)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md` - Resume capability (shared)
- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md` - Debugging procedures (shared)
- `/home/benjamin/.config/.claude/docs/guides/supervise-guide.md` (277 lines, 7.2 KB) - /supervise usage guide
- `/home/benjamin/.config/.claude/docs/reference/supervise-phases.md` (568 lines, 14.3 KB) - /supervise phase reference

### Specification References
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90% delegation rate)
- Spec 495 (2025-10-27): /coordinate and /research delegation failures resolution
- Spec 057 (2025-10-27): /supervise robustness improvements (fail-fast error handling)
- Spec 497 (Unified improvements): All orchestration commands architectural compliance validation
- Spec 507: /supervise refactoring and validation (40-60% faster than estimated)
- Spec 508: Concise verification pattern (/coordinate)
- Spec 510: Coordinate error and formatting improvements

### Standards Documentation
- `/home/benjamin/.config/CLAUDE.md:323-339` - Orchestration commands overview
- `/home/benjamin/.config/CLAUDE.md:248-267` - Performance targets and context reduction metrics
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Standard 11 (Imperative Agent Invocation Pattern)

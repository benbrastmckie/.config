# Rarely-Used Commands Analysis Research Report

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Rarely-Used Commands Analysis
- **Report Type**: Codebase analysis
- **Complexity Level**: 2

## Executive Summary

Analysis of ten rarely-used commands reveals three distinct categories: structural utilities (collapse, expand, list, analyze), alternative planning interfaces (plan-from-template, plan-wizard, refactor), legacy orchestrators (supervise, orchestrate), and testing commands (test, test-all). Most commands serve specialized use cases and remain relevant, though supervise and orchestrate have been superseded by /coordinate as the production-ready orchestration solution. Commands show clear separation of concerns with minimal overlap, though documentation could be consolidated.

## Findings

### 1. Command Categories and Purpose

#### Structural Utilities (4 commands)

**collapse** (/home/benjamin/.config/.claude/commands/collapse.md:1-689)
- **Purpose**: Reverse phase/stage expansion by merging expanded content back into parent plan files
- **Two modes**: Auto-analysis (analyzes all phases/stages, collapses simple ones) and Explicit (collapse specific phase/stage by number)
- **Operations**: Supports Level 2→1 (stage collapse) and Level 1→0 (phase collapse)
- **Agent usage**: Delegates to complexity-estimator and plan-structure-manager agents for auto-analysis mode
- **Use case**: Simplifying plans after implementation when detail no longer warrants separate files
- **Dependencies**: Counterpart to /expand command, uses plan-core-bundle.sh library

**analyze** (/home/benjamin/.config/.claude/commands/analyze.md:1-352)
- **Purpose**: Analyze system performance metrics and patterns for agents, metrics, or all
- **Types**: agents (performance rankings, tool usage, error analysis), metrics (command usage trends, bottlenecks), patterns (not implemented - reserved for future)
- **Timeframe**: Accepts days parameter (default: 30 days)
- **Data sources**: .claude/agents/agent-registry.json and .claude/data/metrics/*.jsonl files
- **Output**: ASCII bar charts, efficiency scores, star ratings, trend indicators, data-driven recommendations
- **Use case**: Understanding agent performance, identifying optimization opportunities, guiding workflow improvements
- **Note**: Pattern analysis removed due to limited value in single-user environment; templates provide better alternative

**list** (/home/benjamin/.config/.claude/commands/list.md:1-260)
- **Purpose**: List implementation artifacts (plans, reports, summaries) with metadata-only reads
- **Types**: plans (all structure levels L0/L1/L2), reports, summaries, all
- **Options**: --recent N, --incomplete (plans only), search-pattern filtering
- **Optimization**: 88% context reduction for plans, 85-90% for reports via metadata extraction
- **Progressive plan support**: Detects and displays Level 0 (single-file), Level 1 (phase-expanded), Level 2 (stage-expanded)
- **Use case**: Quick artifact discovery, status checking, finding incomplete plans
- **Performance**: Uses lib/artifact-creation.sh and lib/artifact-registry.sh for efficient metadata extraction

**expand** (/home/benjamin/.config/.claude/commands/expand.md - not read but referenced in collapse.md:6)
- **Purpose**: Expand phases/stages into separate files for detailed planning (counterpart to collapse)
- **Referenced**: Collapse command mentions expand as the opposite operation

#### Alternative Planning Interfaces (3 commands)

**plan-from-template** (/home/benjamin/.config/.claude/commands/plan-from-template.md:1-280)
- **Purpose**: Generate implementation plans from reusable templates with variable substitution
- **Categories**: backend, feature, debugging, documentation, testing, migration, research, refactoring (8 categories)
- **Template count**: 11 standard templates in .claude/commands/templates/
- **Process**: Load template → prompt for variables → apply substitution → generate numbered plan
- **Options**: --list-categories, --category <name>, <template-name>
- **Performance**: 60-80% faster than manual planning for common patterns
- **Use case**: CRUD operations, API endpoints, standard refactoring patterns
- **Dependencies**: Uses parse-template.sh and substitute-variables.sh libraries

**plan-wizard** (/home/benjamin/.config/.claude/commands/plan-wizard.md:1-271)
- **Purpose**: Interactive guided plan creation with optional research integration
- **Workflow**: 5-7 steps - feature description → component identification → complexity assessment → research decision → research execution → plan generation
- **Intelligence**: Suggests components based on keywords, recommends research based on complexity
- **Research integration**: Launches parallel research-specialist agents before planning
- **Complexity levels**: Simple (1-2 phases), Medium (2-4 phases), Complex (4-6 phases), Critical (6+ phases)
- **Use case**: New users, uncertain scope, want guidance and suggestions
- **Output**: Delegates to /plan command with collected context

**refactor** (/home/benjamin/.config/.claude/commands/refactor.md:1-374)
- **Purpose**: Analyze code for refactoring opportunities and generate detailed reports
- **Scope**: Accepts file/directory/module or specific concerns
- **Analysis**: Standards compliance, code quality, structure/architecture, testing gaps, documentation issues
- **Priority levels**: Critical, High, Medium, Low with effort (Quick Win to Large) and risk (Safe to High Risk) estimates
- **Agent usage**: Delegates to code-reviewer agent for systematic analysis
- **Report structure**: Follows .claude/docs/reference/refactor-structure.md standard
- **Use case**: Pre-feature refactoring, code quality improvement, standards compliance checking
- **Output**: Refactoring report in specs/reports/NNN_refactoring_*.md

#### Legacy Orchestrators (2 commands)

**supervise** (/home/benjamin/.config/.claude/commands/supervise.md:1-436)
- **Purpose**: Multi-agent workflow orchestration using state machine architecture
- **Status**: Superseded by /coordinate as production-ready solution
- **Architecture**: State-driven (initialize → research → plan → implement → test → debug → document → complete)
- **States**: 8 total states with atomic transitions
- **State persistence**: Uses workflow-state-machine.sh and state-persistence.sh libraries
- **Agent delegation**: research-specialist, plan-architect, implementer-coordinator, test-specialist, debug-analyst, doc-writer
- **Use case**: Educational/reference for state machine pattern; /coordinate preferred for production
- **Line count**: ~436 lines vs ~2,500-3,000 for /coordinate

**orchestrate** (/home/benjamin/.config/.claude/commands/orchestrate.md:1-619)
- **Purpose**: Multi-agent workflow orchestration (original implementation, now superseded)
- **Status**: Superseded by /coordinate (48.9% code reduction, 67% performance improvement)
- **Architecture**: 7-phase workflow with state machine (same states as supervise)
- **Options**: --parallel, --sequential, --create-pr, --dry-run
- **Scope detection**: research-only, research-and-plan, full-implementation, debug-only
- **Context reduction**: <30% via metadata extraction
- **Use case**: Legacy/reference; /coordinate is production-ready replacement
- **Line count**: ~619 lines (command file), 5,438 total vs 2,500-3,000 for /coordinate

#### Testing Commands (2 commands)

**test** (/home/benjamin/.config/.claude/commands/test.md:1-150)
- **Purpose**: Run project-specific tests based on CLAUDE.md testing protocols
- **Arguments**: <feature/module/file> [test-type]
- **Test types**: unit, integration, all, nearest, file, suite
- **Project detection**: Supports node (npm test), rust (cargo test), go (go test), python (pytest), lua (Neovim)
- **Agent delegation**: Delegates to test-specialist for complex framework detection
- **Use case**: Targeted testing during development, single feature/module verification
- **Line count**: ~150 lines (lean, focused)

**test-all** (/home/benjamin/.config/.claude/commands/test-all.md:1-131)
- **Purpose**: Run complete test suite for the project with optional coverage
- **Arguments**: [coverage] (optional: "coverage" to include coverage report)
- **Framework support**: Neovim (:TestSuite), Node.js (npm test), Python (pytest), Rust (cargo test), Go (go test)
- **Parallelization**: Uses parallel test execution where supported (pytest -n auto, npm --parallel)
- **Coverage analysis**: Generates reports, identifies untested code, suggests areas needing tests
- **Agent usage**: test-specialist for comprehensive diagnostics and coverage analysis
- **Use case**: Pre-commit validation, CI/CD verification, coverage gap identification
- **Line count**: ~131 lines

### 2. Usage Patterns and Documentation References

**High Documentation Coverage** (referenced in 100+ docs files):
- orchestrate: Referenced extensively in guides, specs (100+ files) - historical artifact of being the original orchestrator
- test: Referenced in testing protocols, command guides, implementation plans
- supervise: Referenced in state machine documentation, architecture guides

**Moderate Documentation Coverage**:
- collapse/expand: Referenced in plan structure guides, progressive organization docs
- list: Referenced in artifact organization, workflow guides
- analyze: Referenced in performance optimization, agent development guides

**Lower Documentation Coverage**:
- plan-from-template: Mentioned in planning guides, template documentation
- plan-wizard: Mentioned in user onboarding, planning alternatives
- refactor: Referenced in code quality guides, standards compliance docs
- test-all: Referenced alongside test command in testing documentation

**Actual Usage in Specs** (from grep results):
- Plans frequently reference /implement, /plan, /coordinate workflows
- Test commands referenced in debugging and validation phases
- Orchestrate/supervise referenced in older specs (pre-/coordinate era)
- Structural utilities (collapse, expand, list) used in plan management workflows

### 3. Dependencies Between Commands

**Command Relationships**:
- collapse ↔ expand: Bidirectional structural operations (expand creates structure, collapse merges it)
- plan-from-template → plan: Template-based planning delegates to /plan command
- plan-wizard → plan: Wizard collects context then delegates to /plan command
- refactor → plan: Refactoring reports inform implementation planning
- test ← test-all: test-all is comprehensive version of targeted test command
- supervise/orchestrate/coordinate: Three generations of orchestration (coordinate is current production)

**Dependent Commands** (from metadata):
- test-all: parent-commands: test, implement
- plan-from-template: dependent-commands: plan, implement
- plan-wizard: dependent-commands: plan, report
- refactor: dependent-commands: report, plan, implement
- supervise/orchestrate/coordinate: dependent-commands: research, plan, implement, debug, test, document

**Agent Dependencies**:
- collapse: complexity-estimator, plan-structure-manager (auto-analysis mode only)
- analyze: None (direct analysis)
- list: None (direct file operations)
- plan-from-template: None (template substitution only)
- plan-wizard: research-specialist (parallel, if research requested)
- refactor: code-reviewer (single agent delegation)
- supervise/orchestrate: 6-7 agents (research-specialist, plan-architect, implementer-coordinator, test-specialist, debug-analyst, doc-writer)
- test: test-specialist (complex scenarios only)
- test-all: test-specialist (comprehensive diagnostics)

### 4. Current Status and Relevance

**Active and Essential**:
- test: Core testing functionality, actively used during development
- test-all: CI/CD integration, comprehensive validation
- list: Artifact discovery, status checking
- collapse: Plan simplification after implementation
- refactor: Code quality analysis, pre-feature refactoring

**Active but Specialized**:
- plan-from-template: Fast planning for common patterns (60-80% faster)
- plan-wizard: Guided experience for new users or uncertain scope
- analyze: Performance monitoring, optimization opportunities

**Superseded but Maintained**:
- orchestrate: Superseded by /coordinate (production-ready, 48.9% smaller, 67% faster)
- supervise: Superseded by /coordinate (reference implementation for state machine pattern)

**Command Reference Status** (/home/benjamin/.config/.claude/docs/reference/command-reference.md:106-159):
- /coordinate: Marked as "Production-Ready ✓ - Stable, tested, recommended for all workflows"
- /orchestrate: Listed but documentation notes /coordinate is preferred
- /supervise: Referenced in architecture docs but not promoted for production use

### 5. Technical Implementation Quality

**Well-Designed** (clear separation, good delegation):
- collapse: Clean orchestrator pattern, delegates complexity analysis to agents
- refactor: Single-responsibility, clean agent delegation to code-reviewer
- plan-wizard: Interactive UX layer over /plan command
- test: Lean implementation with optional agent delegation

**Feature-Complete**:
- analyze: Comprehensive metrics (agents, commands, trends), ASCII visualizations, efficiency scores
- list: Progressive plan support (L0/L1/L2), metadata-only reads for performance
- plan-from-template: 11 templates across 8 categories, full variable substitution

**Complex but Necessary**:
- orchestrate/supervise: Large files (619/436 lines) with state machine complexity, but superseded by /coordinate

**Line Count Analysis**:
- Smallest: test (~150 lines), test-all (~131 lines) - focused, single-purpose
- Medium: analyze (~352 lines), list (~260 lines), plan-from-template (~280 lines), plan-wizard (~271 lines), refactor (~374 lines)
- Large: supervise (~436 lines), orchestrate (~619 lines), collapse (~689 lines)

## Recommendations

### 1. Documentation Consolidation

**Create Command Usage Decision Tree**:
- When to use each planning interface: /plan vs /plan-from-template vs /plan-wizard
- When to use each orchestrator: /coordinate (production) vs /orchestrate (legacy) vs /supervise (educational)
- Testing strategy: /test (targeted) vs /test-all (comprehensive)

**Cross-Reference Improvements**:
- plan-from-template.md should clearly link to available templates and /plan-wizard as alternative
- plan-wizard.md should explain when templates are better than wizard
- orchestrate.md and supervise.md should have prominent notices redirecting to /coordinate
- collapse.md should reference /expand command more clearly

### 2. Deprecation and Archival Strategy

**Orchestrate and Supervise Commands**:
- Add deprecation notices to orchestrate.md and supervise.md frontmatter
- Update command-reference.md to mark these as "LEGACY - Use /coordinate instead"
- Consider moving to .claude/commands/legacy/ directory
- Keep as reference implementations for state machine pattern
- Redirect all orchestration documentation to /coordinate

**Rationale**: Commands are superseded (48.9% code reduction, 67% performance improvement with /coordinate), but valuable as educational references for state machine architecture.

### 3. Feature Enhancement Opportunities

**Analyze Command**:
- Implement pattern analysis (currently not implemented, shows "reserved for future")
- Add command comparison mode: `/analyze agents --compare agent1 agent2`
- Export reports to specs/reports/ instead of console only

**List Command**:
- Add filtering by status (pending/in-progress/completed)
- Support JSON output mode for programmatic use
- Add --summary flag for statistics only

**Plan-from-template**:
- Add custom variable validation (type checking beyond string/array/boolean)
- Support template inheritance (extend existing templates)
- Add --dry-run mode to preview generated plan

### 4. Command Catalog Organization

**Maintain Current Structure** - No consolidation needed:
- Structural utilities (collapse, expand, list, analyze) serve distinct purposes with no overlap
- Planning interfaces (plan, plan-from-template, plan-wizard) target different use cases
- Testing commands (test, test-all) have clear scope separation
- Orchestrators have already consolidated to /coordinate

**Reasoning**: Each command addresses specific use case with minimal functional overlap. Consolidation would reduce usability and increase complexity.

### 5. Usage Promotion

**Underutilized High-Value Commands**:
- plan-from-template: 60-80% faster planning for common patterns, should be promoted in onboarding
- refactor: Systematic code quality analysis, valuable for pre-feature planning
- analyze: Performance insights for system optimization, valuable for workflow improvement

**Promotion Strategy**:
- Add examples to command-reference.md quickstart section
- Create workflow guides showing when to use each command
- Include in /setup command's suggested next steps

## References

### Command Files Analyzed
- /home/benjamin/.config/.claude/commands/collapse.md (lines 1-689)
- /home/benjamin/.config/.claude/commands/analyze.md (lines 1-352)
- /home/benjamin/.config/.claude/commands/list.md (lines 1-260)
- /home/benjamin/.config/.claude/commands/plan-from-template.md (lines 1-280)
- /home/benjamin/.config/.claude/commands/plan-wizard.md (lines 1-271)
- /home/benjamin/.config/.claude/commands/refactor.md (lines 1-374)
- /home/benjamin/.config/.claude/commands/supervise.md (lines 1-436)
- /home/benjamin/.config/.claude/commands/orchestrate.md (lines 1-619)
- /home/benjamin/.config/.claude/commands/test-all.md (lines 1-131)
- /home/benjamin/.config/.claude/commands/test.md (lines 1-150)

### Documentation References
- /home/benjamin/.config/.claude/docs/reference/command-reference.md (lines 1-200)
- /home/benjamin/.config/.claude/docs/ (100+ files referencing these commands)
- /home/benjamin/.config/.claude/specs/ (100+ plans/reports referencing command usage)

### Related Standards
- /home/benjamin/.config/CLAUDE.md - Project standards and command protocols
- /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md - Command selection guide
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md - State machine architecture

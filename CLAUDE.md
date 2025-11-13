# Worktree Task: optimize_claude

## Task Metadata
- **Type**: feature
- **Branch**: feature/optimize_claude
- **Created**: 2025-10-09 16:45
- **Worktree**: ../.config-feature-optimize_claude
- **Session ID**: optimize_claude-1760053547

## Objective
[Describe the main goal for this worktree]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on optimize_claude in the feature/optimize_claude worktree. The goal is to..."

## Task Notes
[Add worktree-specific context, links, or decisions]


---

# Project Configuration (Inherited from Main Worktree)

# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index for this project.

## Project Standards and Guidelines

### Core Documentation
- [Claude Code Documentation](.claude/docs/README.md) - Complete index of patterns, guides, workflows, and reference documentation for working with .claude/ system
- [Neovim Configuration Guidelines](nvim/CLAUDE.md) - Coding standards, style guide, and architecture documentation for Neovim configuration
- [Code Standards](nvim/docs/CODE_STANDARDS.md) - Lua coding conventions, module structure, and development process
- [Documentation Standards](nvim/docs/DOCUMENTATION_STANDARDS.md) - Documentation structure, style guide, and content standards
- [Specifications Directory](nvim/specs/) - Implementation plans, research reports, and technical specifications

<!-- SECTION: directory_protocols -->
### Directory Protocols

[Used by: /research, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory uses a topic-based structure (`specs/{NNN_topic}/`) with artifact subdirectories (plans/, reports/, summaries/, debug/). Plans use progressive organization (Level 0 → Level 1 → Level 2) and support phase dependencies for wave-based parallel execution.

Key concepts:
- **Topic-based structure**: All artifacts for a feature in one numbered directory
- **Plan levels**: Single file → Phase expansion → Stage expansion (on-demand)
- **Phase dependencies**: Enable parallel execution of independent phases (40-60% time savings)
- **Artifact lifecycle**: Debug reports committed, others gitignored

See [Directory Protocols](.claude/docs/concepts/directory-protocols.md) for complete structure, examples, and dependency syntax.
<!-- END_SECTION: directory_protocols -->

<!-- SECTION: testing_protocols -->
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

### Claude Code Testing
- **Test Location**: `.claude/tests/`
- **Test Runner**: `./run_all_tests.sh`
- **Test Pattern**: `test_*.sh` (Bash test scripts)
- **Coverage Target**: ≥80% for modified code, ≥60% baseline
- **Test Categories**:
  - `test_parsing_utilities.sh` - Plan parsing functions
  - `test_command_integration.sh` - Command workflows
  - `test_progressive_*.sh` - Expansion/collapse operations
  - `test_state_management.sh` - Checkpoint operations
  - `test_shared_utilities.sh` - Utility library functions
  - `test_adaptive_planning.sh` - Adaptive planning integration (16 tests)
  - `test_revise_automode.sh` - /revise auto-mode integration (18 tests)
- **Validation Scripts**:
  - `validate_executable_doc_separation.sh` - Verifies executable/documentation separation pattern compliance (file size, guide existence, cross-references)

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua` files in `tests/` or adjacent to source
- **Linting**: `<leader>l` to run linter via nvim-lint
- **Formatting**: `<leader>mp` to format code via conform.nvim
- **Custom Tests**: See individual project documentation

### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes
<!-- END_SECTION: testing_protocols -->

<!-- SECTION: code_standards -->
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Error Handling**: Use appropriate error handling for language (pcall for Lua, try-catch for others)
- **Documentation**: Every directory must have a README.md
- **Character Encoding**: UTF-8 only, no emojis in file content

### Language-Specific Standards
- **Lua**: See [Neovim Configuration Guidelines](nvim/CLAUDE.md) for detailed Lua standards
- **Markdown**: Use Unicode box-drawing for diagrams, follow CommonMark spec
- **Shell Scripts**: Follow ShellCheck recommendations, use bash -e for error handling

### Command and Agent Architecture Standards
[Used by: All slash commands and agent development]

- **Command files** (`.claude/commands/*.md`) are AI execution scripts, not traditional code
- **Executable instructions** must be inline, not replaced by external references
- **Templates** must be complete and copy-paste ready (agent prompts, JSON schemas, bash commands)
- **Critical warnings** (CRITICAL, IMPORTANT, NEVER) must stay in command files
- **Reference files** (`shared/`, `templates/`, `docs/`) provide supplemental context only
- **Imperative Language**: All required actions use MUST/WILL/SHALL (never should/may/can) - See [Imperative Language Guide](.claude/docs/guides/imperative-language-guide.md)
- **Behavioral Injection**: Commands invoke agents via Task tool with context injection (not SlashCommand) - See [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- **Verification and Fallback**: All file creation operations require MANDATORY VERIFICATION checkpoints - See [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md)
- See [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) for complete guidelines

### Architectural Separation

**Executable/Documentation Separation Pattern**: Commands and agents separate lean executable logic from comprehensive documentation to eliminate meta-confusion loops and enable independent evolution.

**Pattern**:
- **Executable Files** (`.claude/commands/*.md`, `.claude/agents/*.md`): Lean execution scripts (<250 lines for commands, <400 lines for agents) containing bash blocks, phase markers, and minimal inline comments (WHAT not WHY)
- **Guide Files** (`.claude/docs/guides/*-command-guide.md`): Comprehensive task-focused documentation (unlimited length) with architecture, examples, troubleshooting, and design decisions

**Templates**:
- New Command: Start with [_template-executable-command.md](.claude/docs/guides/_template-executable-command.md)
- Command Guide: Use [_template-command-guide.md](.claude/docs/guides/_template-command-guide.md)

**Complete Pattern Documentation**:
- [Executable/Documentation Separation Pattern](.claude/docs/concepts/patterns/executable-documentation-separation.md) - Complete pattern with case studies and metrics
- [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern) - Practical implementation instructions
- [Standard 14](.claude/docs/reference/command_architecture_standards.md#standard-14-executabledocumentation-file-separation) - Formal architectural requirement

**Benefits**: 70% average reduction in executable file size, zero meta-confusion incidents, independent documentation growth, fail-fast execution

### Development Guides
- [Command Development Guide](.claude/docs/guides/command-development-guide.md) - Complete guide to creating and maintaining slash commands
- [Agent Development Guide](.claude/docs/guides/agent-development-guide.md) - Complete guide to creating and maintaining specialized agents
- [Model Selection Guide](.claude/docs/guides/model-selection-guide.md) - Guide to choosing Claude model tiers (Haiku/Sonnet/Opus) for agents with cost/quality optimization

### Internal Link Conventions
[Used by: /document, /plan, /implement, all documentation]

**Standard**: All internal markdown links must use relative paths from the current file location.

**Format**:
- Same directory: `[File](file.md)`
- Parent directory: `[File](../file.md)`
- Subdirectory: `[File](subdir/file.md)`
- With anchor: `[Section](file.md#section-name)`

**Prohibited**:
- Absolute filesystem paths: `/home/user/.config/file.md`
- Repository-relative without base: `.claude/docs/file.md` (from outside .claude/)

**Validation**:
- Run `.claude/scripts/validate-links-quick.sh` before committing
- Full validation: `.claude/scripts/validate-links.sh`

**Template Placeholders** (Allowed):
- `{variable}` - Template variable
- `NNN_topic` - Placeholder pattern
- `$ENV_VAR` - Environment variable

**Historical Documentation** (Preserve as-is):
- Spec reports, summaries, and completed plans may have broken links documenting historical states
- Only fix if link prevents understanding current system

See [Link Conventions Guide](.claude/docs/guides/link-conventions-guide.md) for complete standards.
<!-- END_SECTION: code_standards -->

<!-- SECTION: development_philosophy -->
## Development Philosophy

[Used by: /refactor, /implement, /plan, /document]

This project prioritizes clean, coherent systems over backward compatibility. Refactors should create well-designed interfaces without legacy burden. Documentation should be present-focused and timeless, avoiding historical markers like "(New)" or "previously".

Core values: clarity, quality, coherence, maintainability.

### Architectural Principles

- **Clean separation between executable logic and documentation**: Commands and agents use two-file pattern (lean executable + comprehensive guide) enabling fail-fast execution and independent documentation growth without context bloat
- **Single source of truth**: Each piece of information exists in exactly one authoritative location
- **Progressive disclosure**: Information revealed when needed, not all upfront
- **Context window optimization**: Minimize context consumption through metadata extraction and aggressive pruning

### Clean-Break and Fail-Fast Approach

This configuration maintains a **clean-break, fail-fast evolution philosophy**:

**Clean Break**:
- Delete obsolete code immediately after migration
- No deprecation warnings, compatibility shims, or transition periods
- No archives beyond git history
- Configuration and code describe what they are, not what they were

**Fail Fast**:
- Missing files produce immediate, obvious bash errors
- Tests pass or fail immediately (no monitoring periods)
- Breaking changes break loudly with clear error messages
- No silent fallbacks or graceful degradation

**Critical Distinction - Fallback Types** (Spec 057):
- **Bootstrap fallbacks**: PROHIBITED (hide configuration errors through silent function definitions)
- **Verification fallbacks**: REQUIRED (detect tool/agent failures immediately, terminate with diagnostics)
- **Optimization fallbacks**: ACCEPTABLE (performance caches only, graceful degradation for non-critical features)

Standard 0 (Execution Enforcement) uses verification checkpoints to detect errors immediately, not hide them. Orchestrators verify file creation and fail-fast when agents don't create expected artifacts. See [Fail-Fast Policy Analysis](.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md) for complete taxonomy.

**Avoid Cruft**:
- No historical commentary in active files
- No backward compatibility layers
- No migration tracking spreadsheets (use git commits)
- No "what changed" documentation (use git log)

**Rationale**: Configuration should focus on being what it is without extra commentary on top. Clear, immediate failures are better than hidden complexity masking problems.

See [Writing Standards](.claude/docs/concepts/writing-standards.md) for complete refactoring principles and documentation standards.
<!-- END_SECTION: development_philosophy -->

<!-- SECTION: adaptive_planning -->
## Adaptive Planning
[Used by: /implement]

### Overview
`/implement` includes intelligent plan revision capabilities that automatically detect when replanning is needed during execution.

### Automatic Triggers
1. **Complexity Detection**: Phase complexity score >8 or >10 tasks triggers phase expansion
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase suggests missing prerequisites
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` for discovered out-of-scope work

### Behavior
- Automatically invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases, or updates tasks)
- Continues implementation with revised plan
- Maximum 2 replans per phase prevents infinite loops

### Logging
- **Log File**: `.claude/data/logs/adaptive-planning.log`
- **Log Rotation**: 10MB max, 5 files retained
- **Query Logs**: Use functions from `.claude/lib/unified-logger.sh`

### Loop Prevention
- Replan counters tracked in checkpoints
- Max 2 replans per phase enforced
- Replan history logged for audit trail
- User escalation when limit exceeded

### Utilities
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh` - See [Checkpoint Recovery Pattern](.claude/docs/concepts/patterns/checkpoint-recovery.md)
- **Complexity Analysis**: `.claude/lib/complexity-utils.sh`
- **Adaptive Logging**: `.claude/lib/unified-logger.sh`
- **Error Handling**: `.claude/lib/error-handling.sh`
- **Context Management**: See [Context Management Pattern](.claude/docs/concepts/patterns/context-management.md) for pruning and reduction techniques
<!-- END_SECTION: adaptive_planning -->

<!-- SECTION: adaptive_planning_config -->
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds

The following thresholds control when plans are automatically expanded or revised during creation and implementation.

- **Expansion Threshold**: 8.0 (phases with complexity score above this threshold are automatically expanded to separate files)
- **Task Count Threshold**: 10 (phases with more tasks than this threshold are expanded regardless of complexity score)
- **File Reference Threshold**: 10 (phases referencing more files than this threshold increase complexity score)
- **Replan Limit**: 2 (maximum number of automatic replans allowed per phase during implementation, prevents infinite loops)

### Adjusting Thresholds

Different projects have different complexity needs. Adjust thresholds to match your project:

**Research-Heavy Project** (detailed documentation preferred):
- Expansion Threshold: 5.0
- Task Count Threshold: 7
- File Reference Threshold: 8

**Simple Web Application** (larger inline phases acceptable):
- Expansion Threshold: 10.0
- Task Count Threshold: 15
- File Reference Threshold: 15

**Mission-Critical System** (maximum organization):
- Expansion Threshold: 3.0
- Task Count Threshold: 5
- File Reference Threshold: 5

### Threshold Ranges

- **Expansion Threshold**: 0.0 - 15.0 (recommended: 3.0 - 12.0)
- **Task Count Threshold**: 5 - 20 (recommended: 5 - 15)
- **File Reference Threshold**: 5 - 30 (recommended: 5 - 20)
- **Replan Limit**: 1 - 5 (recommended: 1 - 3)
<!-- END_SECTION: adaptive_planning_config -->

<!-- SECTION: development_workflow -->
## Development Workflow

Standard workflow: research → plan → implement → test → commit → summarize. The spec updater agent manages artifacts in topic-based directories and maintains cross-references. Adaptive planning adjusts plans during implementation.

Key patterns:
- **5-phase workflow**: Reports, plans, execution, summaries, adaptive adjustments
- **Spec updater integration**: Artifact management, lifecycle tracking, gitignore compliance
- **Plan hierarchy updates**: Automatic checkbox propagation across plan levels
- **Git workflow**: Feature branches, atomic commits, test before commit
- **Checkpoint Recovery**: State preservation for resumable workflows - See [Checkpoint Recovery Pattern](.claude/docs/concepts/patterns/checkpoint-recovery.md)
- **Parallel Execution**: Wave-based implementation for 40-60% time savings - See [Parallel Execution Pattern](.claude/docs/concepts/patterns/parallel-execution.md)

See [Development Workflow](.claude/docs/concepts/development-workflow.md) for spec updater details, artifact lifecycle, and integration patterns.
<!-- END_SECTION: development_workflow -->

<!-- SECTION: hierarchical_agent_architecture -->
## Hierarchical Agent Architecture
[Used by: /orchestrate, /implement, /plan, /debug]

### Overview
Multi-level agent coordination system that minimizes context window consumption through metadata-based context passing and recursive supervision. Agents delegate work to subagents and pass report references (not full content) between levels.

### Key Features
- **Metadata Extraction**: Extract title + 50-word summary from reports/plans (99% context reduction) - See [Metadata Extraction Pattern](.claude/docs/concepts/patterns/metadata-extraction.md)
- **Forward Message Pattern**: Pass subagent responses directly without re-summarization - See [Forward Message Pattern](.claude/docs/concepts/patterns/forward-message.md)
- **Recursive Supervision**: Supervisors can manage sub-supervisors for complex workflows - See [Hierarchical Supervision Pattern](.claude/docs/concepts/patterns/hierarchical-supervision.md)
- **Context Pruning**: Aggressive cleanup of completed phase data - See [Context Management Pattern](.claude/docs/concepts/patterns/context-management.md) and [Context Budget Management Tutorial](.claude/docs/workflows/context-budget-management.md)
- **Subagent Delegation**: Commands can delegate complex tasks to specialized subagents - See [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- **Imperative Agent Invocation**: All agent invocations use imperative pattern (not documentation-only YAML blocks) - See [Standard 11](.claude/docs/reference/command_architecture_standards.md#standard-11) and [Anti-Pattern Documentation](.claude/docs/concepts/patterns/behavioral-injection.md#anti-pattern-documentation-only-yaml-blocks)
- **Workflow Scope Detection**: Automatic detection of workflow requirements - See [Workflow Scope Detection Pattern](.claude/docs/concepts/patterns/workflow-scope-detection.md)
- **LLM-Based Classification (2-Mode System)**: Semantic workflow classification with 98%+ accuracy using llm-only mode (default) or regex-only mode (offline). Enhanced topic generation with detailed descriptions and filename slugs. See [LLM Classification Pattern](.claude/docs/concepts/patterns/llm-classification-pattern.md) and [Enhanced Topic Generation Guide](.claude/docs/guides/enhanced-topic-generation-guide.md)
- **Phase 0 Optimization**: Pre-calculation of paths for 85% token reduction - See [Phase 0 Optimization Guide](.claude/docs/guides/phase-0-optimization.md)

### Context Reduction Metrics
- **Target**: <30% context usage throughout workflows
- **Achieved**: 92-97% reduction through metadata-only passing
- **Performance**: 60-80% time savings with parallel subagent execution

### Utilities
- **Metadata Extraction**: `.claude/lib/metadata-extraction.sh`
  - `extract_report_metadata()` - Extract title, summary, file paths, recommendations
  - `extract_plan_metadata()` - Extract complexity, phases, time estimates
  - `load_metadata_on_demand()` - Generic metadata loader with caching
- **Plan Parsing**: `.claude/lib/plan-core-bundle.sh`
  - `parse_plan_file()` - Parse plan structure and phases
  - `extract_phase_info()` - Extract phase details and tasks
  - `get_plan_metadata()` - Get plan-level metadata
- **Context Management**: `.claude/lib/context-pruning.sh`
  - `prune_subagent_output()` - Clear full outputs after metadata extraction
  - `prune_phase_metadata()` - Remove phase data after completion
  - `apply_pruning_policy()` - Automatic pruning by workflow type
- **Workflow Classification**: `.claude/lib/workflow-llm-classifier.sh`, `.claude/lib/workflow-scope-detection.sh`
  - `classify_workflow_comprehensive()` - Main classification function
  - `classify_workflow_llm()` - LLM-based semantic classification with enhanced topics
  - `classify_workflow_regex_comprehensive()` - Traditional regex-based classification
  - `detect_workflow_scope()` - Backward compatibility wrapper
  - Modes: llm-only (default, online), regex-only (offline) - See [Workflow Classification Guide](.claude/docs/guides/workflow-classification-guide.md)

### Agent Templates
- **Implementation Researcher** (`.claude/agents/implementation-researcher.md`)
  - Analyzes codebase before implementation phases
  - Identifies patterns, utilities, integration points
  - Returns 50-word summary + artifact path
- **Debug Analyst** (`.claude/agents/debug-analyst.md`)
  - Investigates potential root causes in parallel
  - Returns structured findings + proposed fixes
  - Enables parallel hypothesis testing
- **Sub-Supervisor** (`.claude/docs/patterns/hierarchical-supervision.md`)
  - Manages 2-3 specialized subagents per domain
  - Returns aggregated metadata only to parent
  - Enables 10+ research topics (vs 4 without recursion)

### Command Integration
- **`/implement`**: Delegates codebase exploration for complex phases (complexity ≥8)
- **`/plan`**: Delegates research for ambiguous features (2-3 parallel research agents)
- **`/debug`**: Delegates root cause analysis for complex bugs (parallel investigations)
- **`/orchestrate`**: Supports recursive supervision for large-scale workflows (10+ topics)
- **`/supervise`**: Multi-phase workflow orchestration (research → plan → implement → test → debug → document)

### Validation and Troubleshooting

All orchestration commands enforce [Standard 11 (Imperative Agent Invocation Pattern)](.claude/docs/reference/command_architecture_standards.md#standard-11), which requires:
- Imperative instructions (`**EXECUTE NOW**: USE the Task tool...`)
- No code block wrappers around Task invocations
- Direct reference to agent behavioral files (`.claude/agents/*.md`)
- Explicit completion signals (e.g., `REPORT_CREATED:`)
- Fail-fast error handling with diagnostic commands

**Validation Tools**:
- `.claude/lib/validate-agent-invocation-pattern.sh` - Detect anti-patterns
- `.claude/tests/test_orchestration_commands.sh` - Comprehensive testing

**Resources**:
- [Behavioral Injection Pattern - Anti-Pattern Documentation](.claude/docs/concepts/patterns/behavioral-injection.md) - Complete case studies
- [Orchestration Troubleshooting Guide](.claude/docs/guides/orchestration-troubleshooting.md) - Debugging procedures

### Usage Example
```bash
# /implement automatically invokes research subagent for complex phases
/implement specs/042_auth/plans/001_implementation.md

# Result: specs/042_auth/artifacts/phase_3_exploration.md created
# /implement receives: {path, 50-word summary, key_findings[]}
# Context reduction: 5000 tokens → 250 tokens (95%)
```

See [Hierarchical Agent Architecture Guide](.claude/docs/concepts/hierarchical_agents.md) for complete documentation, patterns, and best practices.
<!-- END_SECTION: hierarchical_agent_architecture -->

<!-- SECTION: state_based_orchestration -->
## State-Based Orchestration Architecture
[Used by: /coordinate, /orchestrate, /supervise, custom orchestrators]

### Overview
State-based orchestration uses explicit state machines with validated transitions to manage multi-phase workflows. Replaces implicit phase numbers with named states, enabling fail-fast validation, atomic transitions, and coordinated checkpoint management.

### Core Components

**0. Bash Block Execution Model** ([Documentation](.claude/docs/concepts/bash-block-execution-model.md))
- Subprocess isolation constraint: each bash block runs in separate process
- Validated patterns for cross-block state management
- Fixed semantic filenames, save-before-source pattern, library re-sourcing
- Anti-patterns to avoid ($$-based IDs, export assumptions, premature traps)
- Discovered and validated through Specs 620/630 (100% test pass rate)

**1. State Machine Library** (`.claude/lib/workflow-state-machine.sh`)
- 8 explicit states: initialize, research, plan, implement, test, debug, document, complete
- Transition table validation (prevents invalid state changes)
- Atomic state transitions with checkpoint coordination
- 50 comprehensive tests (100% pass rate)

**2. State Persistence Library** (`.claude/lib/state-persistence.sh`)
- GitHub Actions-style workflow state files
- Selective file-based persistence (7 critical items, 70% of analyzed state)
- Graceful degradation to stateless recalculation
- 67% performance improvement (6ms → 2ms for CLAUDE_PROJECT_DIR detection)

**3. Checkpoint Schema V2.0**
- State machine as first-class citizen in checkpoint structure
- Supervisor coordination support for hierarchical workflows
- Error state tracking with retry logic (max 2 retries per state)
- Backward compatible with V1.3 (auto-migration on load)

**4. Hierarchical Supervisors** (State-Aware)
- Research supervisor: 95.6% context reduction (10,000 → 440 tokens)
- Implementation supervisor: 53% time savings via parallel execution
- Testing supervisor: Sequential lifecycle coordination
- 19 comprehensive tests (100% pass rate)

### Performance Achievements

**Code Reduction**: 48.9% (3,420 → 1,748 lines across 3 orchestrators)
- Exceeded 39% target by 9.9%
- /coordinate: 1,084 → 800 lines (26.2%)
- /orchestrate: 557 → 551 lines (1.1%)
- /supervise: 1,779 → 397 lines (77.7%)

**State Operation Performance**: 67% improvement (6ms → 2ms)
**Context Reduction**: 95.6% via hierarchical supervisors
**Time Savings**: 53% via parallel execution
**Reliability**: 100% file creation maintained

### Key Architectural Principles

1. **Explicit Over Implicit**: Named states (STATE_RESEARCH) vs phase numbers (1)
2. **Validated Transitions**: State machine enforces valid state changes
3. **Centralized Lifecycle**: Single state machine library owns all state operations
4. **Selective Persistence**: File-based for expensive operations, stateless for cheap calculations
5. **Hierarchical Context Reduction**: Pass metadata summaries, not full content

### When to Use State-Based Orchestration

**Use when**:
- Workflow has multiple distinct phases (3+ states)
- Conditional transitions exist (test → debug vs test → document)
- Checkpoint resume required (long-running workflows)
- Multiple orchestrators share similar patterns
- Context reduction through hierarchical supervision needed

**Use simpler approaches when**:
- Workflow is linear with no branches
- Single-purpose command with no state coordination
- Workflow completes in <5 minutes
- State overhead exceeds benefits (<3 phases)

### Resources

- **[State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md)** (2,000+ lines)
  - Complete architecture reference
  - State machine design, selective persistence patterns
  - Hierarchical supervisor coordination
  - Performance characteristics and benchmarks

- **[State Machine Orchestrator Development](.claude/docs/guides/state-machine-orchestrator-development.md)** (1,100+ lines)
  - Creating new orchestrators using state machine
  - Adding states and transitions
  - Implementing state handlers
  - Integrating hierarchical supervisors

- **[State Machine Migration Guide](.claude/docs/guides/state-machine-migration-guide.md)** (1,000+ lines)
  - Migrating from phase-based to state-based
  - Before/after code examples
  - Common migration issues and solutions

- **[Performance Validation Report](.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/004_performance_validation_report.md)**
  - Comprehensive performance metrics
  - Test results (409 tests, 63/81 suites passing)
  - Detailed analysis of all achievements

### Implementation Status

**Phase 7 Complete** (2025-11-08):
- All performance targets met or exceeded
- 127 core state machine tests passing (100%)
- Comprehensive documentation complete
- Production-ready architecture
<!-- END_SECTION: state_based_orchestration -->

<!-- SECTION: project_commands -->
## Project-Specific Commands

### Claude Code Commands

Located in `.claude/commands/`:
- `/orchestrate <workflow>` - Multi-agent workflow coordination (research → plan → implement → debug → document)
- `/coordinate <workflow>` - Clean multi-agent orchestration with wave-based parallel implementation and fail-fast error handling
  - **Architecture**: [State Management Documentation](.claude/docs/architecture/coordinate-state-management.md) - Subprocess isolation patterns and decision matrix
  - **Performance**: 41% initialization overhead reduction (528ms saved via state persistence caching), 100% reliability (zero unbound variables/verification failures)
  - **Usage Guide**: [/coordinate Command Guide](.claude/docs/guides/coordinate-command-guide.md) - Complete architecture, usage examples, troubleshooting
- `/implement [plan-file]` - Execute implementation plans phase-by-phase with testing and commits
  - **Usage Guide**: [/implement Command Guide](.claude/docs/guides/implement-command-guide.md) - Complete usage, adaptive planning, and agent delegation
- `/research <topic>` - Hierarchical multi-agent research with automatic decomposition (replaces archived /report)
- `/plan <feature>` - Create implementation plans in specs/plans/
  - **Usage Guide**: [/plan Command Guide](.claude/docs/guides/plan-command-guide.md) - Research delegation, complexity analysis, standards integration
- `/debug <issue>` - Investigate issues and create diagnostic reports without code changes
  - **Usage Guide**: [/debug Command Guide](.claude/docs/guides/debug-command-guide.md) - Parallel hypothesis testing, root cause analysis
- `/test <target>` - Run project-specific tests per Testing Protocols
  - **Usage Guide**: [/test Command Guide](.claude/docs/guides/test-command-guide.md) - Multi-framework testing, error analysis, coverage tracking
- `/document [change-description] [scope]` - Update all relevant documentation based on recent code changes
  - **Usage Guide**: [/document Command Guide](.claude/docs/guides/document-command-guide.md) - Standards compliance, cross-references, timeless writing
- `/plan-from-template <name>` - Generate plans from reusable templates (11 categories)
- `/plan-wizard` - Interactive plan creation with guided prompts
- `/setup [--enhance-with-docs]` - Configure or update this CLAUDE.md file; --enhance-with-docs discovers project documentation and automatically enhances CLAUDE.md

**Orchestration**: Three orchestration commands available (**Use /coordinate for production workflows**):

- `/coordinate` - **Production-Ready** - Wave-based parallel execution and fail-fast error handling (2,500-3,000 lines, recommended default)
- `/orchestrate` - **In Development** - Full-featured orchestration with PR automation and dashboard tracking (5,438 lines, experimental features may have inconsistent behavior)
- `/supervise` - **In Development** - Sequential orchestration with proven architectural compliance (1,779 lines, minimal reference being stabilized)
  - **Usage Guide**: [/supervise Usage Guide](.claude/docs/guides/supervise-guide.md) - Examples and common patterns
  - **Phase Reference**: [/supervise Phase Reference](.claude/docs/reference/supervise-phases.md) - Detailed phase documentation

All orchestration commands provide 7-phase workflow with parallel research (2-4 agents), automated complexity evaluation, and conditional debugging. /coordinate provides wave-based parallel implementation achieving 40-60% time savings. Performance: <30% context usage throughout.

**Command Selection**: See [Command Selection Guide](.claude/docs/guides/orchestration-best-practices.md#command-selection) for detailed comparison, decision tree, and maturity status of each command.

**Best Practices**: See [Orchestration Best Practices Guide](.claude/docs/guides/orchestration-best-practices.md) for unified framework covering Phase 0-7, context budget management, and library integration.

**Reliability**:
- Agent delegation rate: >90% (all orchestration commands verified)
- File creation reliability: 100% (mandatory verification checkpoints)
- Bootstrap reliability: 100% (fail-fast exposes configuration errors immediately)
- Troubleshooting: See [Orchestration Troubleshooting Guide](.claude/docs/guides/orchestration-troubleshooting.md)

**Template-Based Planning**: Fast plan generation (60-80% faster) using templates for common patterns (CRUD, refactoring, testing, migrations). See `.claude/commands/templates/README.md`.

**Unified Location Detection**: All workflow commands use standardized location detection library (85% token reduction, 25x speedup vs agent-based detection). See [Library API Reference](.claude/docs/reference/library-api.md) for implementation details.

**Command Documentation Pattern**: Commands follow executable/documentation separation:
- **Executable files** (`.claude/commands/*.md`): Lean execution scripts (<250 lines)
- **Command guides** (`.claude/docs/guides/*-command-guide.md`): Comprehensive documentation
- **Templates**: See [Executable Template](.claude/docs/guides/_template-executable-command.md) and [Guide Template](.claude/docs/guides/_template-command-guide.md)
- **Benefits**: Eliminates meta-confusion loops, improves maintainability
- **Pattern Documentation**: [Executable/Documentation Separation Pattern](.claude/docs/concepts/patterns/executable-documentation-separation.md) - Complete pattern with case studies and metrics
- **Implementation Guide**: [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern)
- **Standard**: [Standard 14](.claude/docs/reference/command_architecture_standards.md#standard-14-executabledocumentation-file-separation) - Formal architectural requirement

For detailed usage, see `.claude/commands/README.md` and individual command files in `.claude/commands/`.
<!-- END_SECTION: project_commands -->

<!-- SECTION: quick_reference -->
## Quick Reference

### Common Tasks
- **Run Tests**: `:TestSuite` or `/test-all`
- **Format Code**: `<leader>mp`
- **Check Linting**: `<leader>l`
- **Find Files**: `<C-p>` (Telescope)
- **Search Project**: `<leader>sg` (Telescope grep)

### Setup Utilities
- **Test Detection**: `.claude/lib/detect-testing.sh [dir]` - Score testing infrastructure (0-6)
- **Optimize CLAUDE.md**: `.claude/lib/optimize-claude-md.sh CLAUDE.md --dry-run` - Analyze bloat
- **Generate READMEs**: `.claude/lib/generate-readme.sh --generate-all [dir]` - Documentation coverage

See [Setup Guide](.claude/docs/guides/setup-command-guide.md) for detailed usage patterns and troubleshooting.

### Command and Agent Reference
- [Command Reference](.claude/docs/reference/command-reference.md) - Complete catalog of all slash commands with syntax and examples
- [Agent Reference](.claude/docs/reference/agent-reference.md) - Complete catalog of all specialized agents with capabilities and usage

### Command Development
- **New Command**: Start with [_template-executable-command.md](.claude/docs/guides/_template-executable-command.md)
- **Command Guide**: Use [_template-command-guide.md](.claude/docs/guides/_template-command-guide.md)
- **Pattern Guide**: [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern) for complete separation pattern details
- **Validation**: Run `.claude/tests/validate_executable_doc_separation.sh` to verify pattern compliance

### Navigation
- [Neovim Configuration](nvim/)
- [Specifications](nvim/specs/)
- [Commands](.claude/commands/)
<!-- END_SECTION: quick_reference -->

<!-- SECTION: documentation_policy -->
## Documentation Policy
[Used by: /document, /plan]

### README Requirements
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs

### Documentation Format
- Use clear, concise language
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams (see nvim/CLAUDE.md)
- No emojis in file content (UTF-8 encoding issues)
- Follow CommonMark specification
- No historical commentary (see Development Philosophy → Documentation Standards)

### Documentation Updates
- Update documentation with code changes
- Keep examples current with implementation
- Document breaking changes prominently
- Remove any historical markers when updating existing docs
<!-- END_SECTION: documentation_policy -->

<!-- SECTION: standards_discovery -->
## Standards Discovery
[Used by: all commands]

### Discovery Method
Commands should discover standards by:
1. Searching upward from current directory for CLAUDE.md
2. Checking for subdirectory-specific CLAUDE.md files
3. Merging/overriding: subdirectory standards extend parent standards

### Subdirectory Standards
- Subdirectory CLAUDE.md files can override parent standards
- Always check most specific (deepest) CLAUDE.md first
- Fall back to parent standards for missing sections

### Fallback Behavior
When CLAUDE.md not found or incomplete:
- Use sensible language-specific defaults
- Suggest creating/updating CLAUDE.md with `/setup`
- Continue with graceful degradation
<!-- END_SECTION: standards_discovery -->

## Notes
This CLAUDE.md was automatically configured with the `/setup` command.
For updates or improvements, run `/setup` again or edit manually following the established patterns.

Standards sections are marked with `[Used by: commands]` metadata for discoverability.



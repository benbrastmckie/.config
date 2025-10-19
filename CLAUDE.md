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
- [Neovim Configuration Guidelines](nvim/CLAUDE.md) - Coding standards, style guide, and architecture documentation for Neovim configuration
- [Code Standards](nvim/docs/CODE_STANDARDS.md) - Lua coding conventions, module structure, and development process
- [Documentation Standards](nvim/docs/DOCUMENTATION_STANDARDS.md) - Documentation structure, style guide, and content standards
- [Specifications Directory](nvim/specs/) - Implementation plans, research reports, and technical specifications

<!-- SECTION: directory_protocols -->
### Directory Protocols

[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries]

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
- See [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) for complete guidelines
<!-- END_SECTION: code_standards -->

<!-- SECTION: development_philosophy -->
## Development Philosophy

[Used by: /refactor, /implement, /plan, /document]

This project prioritizes clean, coherent systems over backward compatibility. Refactors should create well-designed interfaces without legacy burden. Documentation should be present-focused and timeless, avoiding historical markers like "(New)" or "previously".

Core values: clarity, quality, coherence, maintainability.

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
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh`
- **Complexity Analysis**: `.claude/lib/complexity-utils.sh`
- **Adaptive Logging**: `.claude/lib/unified-logger.sh`
- **Error Handling**: `.claude/lib/error-handling.sh`
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

See [Development Workflow](.claude/docs/concepts/development-workflow.md) for spec updater details, artifact lifecycle, and integration patterns.
<!-- END_SECTION: development_workflow -->

<!-- SECTION: hierarchical_agent_architecture -->
## Hierarchical Agent Architecture
[Used by: /orchestrate, /implement, /plan, /debug]

### Overview
Multi-level agent coordination system that minimizes context window consumption through metadata-based context passing and recursive supervision. Agents delegate work to subagents and pass report references (not full content) between levels.

### Key Features
- **Metadata Extraction**: Extract title + 50-word summary from reports/plans (99% context reduction)
- **Forward Message Pattern**: Pass subagent responses directly without re-summarization
- **Recursive Supervision**: Supervisors can manage sub-supervisors for complex workflows
- **Context Pruning**: Aggressive cleanup of completed phase data
- **Subagent Delegation**: Commands can delegate complex tasks to specialized subagents

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

### Agent Templates
- **Implementation Researcher** (`.claude/agents/implementation-researcher.md`)
  - Analyzes codebase before implementation phases
  - Identifies patterns, utilities, integration points
  - Returns 50-word summary + artifact path
- **Debug Analyst** (`.claude/agents/debug-analyst.md`)
  - Investigates potential root causes in parallel
  - Returns structured findings + proposed fixes
  - Enables parallel hypothesis testing
- **Sub-Supervisor** (`.claude/templates/sub_supervisor_pattern.md`)
  - Manages 2-3 specialized subagents per domain
  - Returns aggregated metadata only to parent
  - Enables 10+ research topics (vs 4 without recursion)

### Command Integration
- **`/implement`**: Delegates codebase exploration for complex phases (complexity ≥8)
- **`/plan`**: Delegates research for ambiguous features (2-3 parallel research agents)
- **`/debug`**: Delegates root cause analysis for complex bugs (parallel investigations)
- **`/orchestrate`**: Supports recursive supervision for large-scale workflows (10+ topics)

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

<!-- SECTION: project_commands -->
## Project-Specific Commands

### Claude Code Commands

Located in `.claude/commands/`:
- `/orchestrate <workflow>` - Multi-agent workflow coordination (research → plan → implement → debug → document)
- `/implement [plan-file]` - Execute implementation plans phase-by-phase with testing and commits
- `/report <topic>` - Generate research documentation in specs/reports/
- `/plan <feature>` - Create implementation plans in specs/plans/
- `/plan-from-template <name>` - Generate plans from reusable templates (11 categories)
- `/plan-wizard` - Interactive plan creation with guided prompts
- `/test <target>` - Run project-specific tests per Testing Protocols
- `/setup [--enhance-with-docs]` - Configure or update this CLAUDE.md file; --enhance-with-docs discovers project documentation and automatically enhances CLAUDE.md

**Orchestration**: 7-phase workflow with parallel research (2-4 agents), automated complexity evaluation, wave-based implementation, and conditional debugging. Performance: <30% context usage, 40-80% time savings vs sequential.

**Template-Based Planning**: Fast plan generation (60-80% faster) using templates for common patterns (CRUD, refactoring, testing, migrations). See `.claude/templates/README.md`.

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


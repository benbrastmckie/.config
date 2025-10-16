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

### Directory Protocols

#### Specifications Structure (`specs/`)
[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory uses a uniform topic-based structure where all artifacts for a feature are organized together:

**Structure**: `specs/{NNN_topic}/{artifact_type}/NNN_artifact_name.md`

**Topic Directories** (`{NNN_topic}`):
- Three-digit numbered directories (001, 002, 003...)
- Each topic contains all artifacts for a feature or area
- Topic name describes the feature (e.g., `042_authentication`, `001_cleanup`)

**Artifact Types** (subdirectories within each topic):
- `plans/` - Implementation plans
- `reports/` - Research reports
- `summaries/` - Implementation summaries
- `debug/` - Debug reports (COMMITTED to git for issue tracking)
- `scripts/` - Investigation scripts (temporary)
- `outputs/` - Test outputs (temporary)
- `artifacts/` - Operation artifacts (optional cleanup)
- `backups/` - Backups (optional cleanup)

**Artifact Numbering**:
- Each artifact type uses three-digit numbering within the topic (001, 002, 003...)
- Numbering resets per topic directory
- Example: `specs/042_auth/plans/001_user_auth.md`, `specs/042_auth/plans/002_session.md`

**Location**: specs/ directories can exist at project root or in subdirectories (e.g., `.claude/specs/`) for scoped specifications.

**Important**: Most specs/ artifacts are gitignored (plans/, reports/, summaries/, scripts/, outputs/, artifacts/, backups/). Debug reports in `debug/` subdirectories are COMMITTED to git for issue tracking.

##### Directory Structure Example

```
{project}/
├── specs/
│   ├── 001_cleanup/
│   │   ├── plans/
│   │   │   ├── 001_refactor_utilities.md
│   │   │   └── 002_fix_artifact_bugs.md
│   │   ├── reports/
│   │   │   └── 001_cleanup_analysis.md
│   │   ├── summaries/
│   │   │   └── 002_implementation_summary.md
│   │   └── debug/
│   │       └── 001_path_resolution.md
│   └── 042_authentication/
│       ├── plans/
│       │   ├── 001_user_authentication.md
│       │   └── 002_session_management.md
│       ├── reports/
│       │   ├── 001_auth_patterns.md
│       │   ├── 002_security_practices.md
│       │   └── 003_alternatives.md
│       ├── summaries/
│       │   └── 001_implementation_summary.md
│       ├── debug/
│       │   └── 001_token_refresh.md
│       ├── scripts/
│       ├── outputs/
│       ├── artifacts/
│       └── backups/
└── .claude/
    └── specs/
        └── 001_config/
            ├── plans/
            ├── reports/
            └── summaries/
```

**Uniform Structure Benefits**:
- All artifacts for a feature in one directory
- Easy to find related plans, reports, summaries, debug reports
- Consistent numbering within each artifact type
- Clear separation between committed (debug/) and gitignored artifacts
- Supports both project-root (`specs/`) and scoped (`.claude/specs/`) locations

##### Plan Structure Levels

Plans use progressive organization that grows based on actual complexity discovered during implementation:

**Level 0: Single File** (All plans start here)
- Format: `NNN_plan_name.md`
- All phases and tasks inline in single file
- Use: All features start here, regardless of anticipated complexity

**Level 1: Phase Expansion** (Created on-demand via `/expand-phase`)
- Format: `NNN_plan_name/` directory with some phases in separate files
- Created when a phase proves too complex during implementation
- Structure:
  - `NNN_plan_name.md` (main plan with summaries)
  - `phase_N_name.md` (expanded phase details)

**Level 2: Stage Expansion** (Created on-demand via `/expand-stage`)
- Format: Phase directories with stage subdirectories
- Created when phases have complex multi-stage workflows
- Structure:
  - `NNN_plan_name/` (plan directory)
    - `phase_N_name/` (phase directory)
      - `phase_N_overview.md`
      - `stage_M_name.md` (stage details)

**Progressive Expansion**: Use `/expand-phase <plan> <phase-num>` to extract complex phases. Use `/expand-stage <phase> <stage-num>` to extract complex stages. Structure grows organically based on implementation needs.

**Collapse Operations**: Use `/collapse-phase` and `/collapse-stage` to merge content back and simplify structure.

##### Phase Dependencies and Wave-Based Execution

Plans support phase dependency declarations that enable parallel execution of independent phases during implementation.

**Dependency Syntax**:
```markdown
### Phase N: [Phase Name]

**Dependencies**: [] or [1, 2, 3]
**Risk**: Low|Medium|High
**Estimated Time**: X-Y hours
```

**Dependency Format**:
- `Dependencies: []` - No dependencies (independent phase, can run in parallel)
- `Dependencies: [1]` - Depends on phase 1 (waits for phase 1 to complete)
- `Dependencies: [1, 2]` - Depends on phases 1 and 2
- `Dependencies: [1, 3, 5]` - Depends on multiple phases

**Rules**:
- Dependencies are phase numbers (integers)
- A phase can only depend on earlier phases (no forward dependencies)
- Circular dependencies are detected and rejected during wave calculation
- Self-dependencies are invalid

**Wave-Based Execution**:
- Orchestrator calculates execution waves using topological sorting (Kahn's algorithm)
- Independent phases within a wave execute in parallel (40-60% time savings)
- Sequential phases execute in dependency order
- Wave execution is automatic when using `/orchestrate`

**Example**:
```markdown
### Phase 1: Foundation Setup
**Dependencies**: []  # No dependencies - Wave 1

### Phase 2: Database Schema
**Dependencies**: [1]  # Depends on Phase 1 - Wave 2

### Phase 3: API Endpoints
**Dependencies**: [1]  # Depends on Phase 1 - Wave 2 (parallel with Phase 2)

### Phase 4: Integration Tests
**Dependencies**: [2, 3]  # Depends on Phases 2 and 3 - Wave 3
```

This creates 3 execution waves:
- Wave 1: Phase 1
- Wave 2: Phases 2 and 3 (parallel execution)
- Wave 3: Phase 4

See `.claude/docs/phase_dependencies.md` for detailed dependency syntax and examples.

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

## Development Philosophy
[Used by: /refactor, /implement, /plan, /document]

### Clean-Break Refactors
- **Prioritize coherence over compatibility**: Clean, well-designed refactors are preferred over maintaining backward compatibility
- **System integration**: What matters is that existing commands and agents work well together in the current implementation
- **No legacy burden**: Don't compromise current design to support old formats or deprecated patterns
- **Migration is acceptable**: Breaking changes are acceptable when they improve system quality

### Documentation Standards
- **Present-focused**: Document the current implementation accurately and clearly
- **No historical reporting**: Don't document changes, updates, or migration paths in main documentation
- **What, not when**: Focus on what the system does now, not how it evolved
- **Clean narrative**: Documentation should read as if the current implementation always existed
- **Ban historical markers**: Never use labels like "(New)", "(Old)", "(Original)", "(Current)", "(Updated)", or version indicators in feature descriptions
- **Timeless writing**: Avoid phrases like "previously", "now supports", "recently added", "in the latest version"
- **No migration guides**: Do not create migration guides or compatibility documentation for refactors

### Rationale
This project values:
1. **Clarity**: Clean, consistent documentation that accurately reflects current state
2. **Quality**: Well-designed systems over backward-compatible compromises
3. **Coherence**: Commands, agents, and utilities that work seamlessly together
4. **Maintainability**: Code that is easy to understand and modify today

When refactoring, prefer to:
- Create clean, consistent interfaces
- Remove deprecated patterns entirely
- Update documentation to reflect only current implementation
- Ensure all components work together harmoniously

Backward compatibility is secondary to these goals.

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
- **Log File**: `.claude/logs/adaptive-planning.log`
- **Log Rotation**: 10MB max, 5 files retained
- **Query Logs**: Use functions from `.claude/lib/adaptive-planning-logger.sh`

### Loop Prevention
- Replan counters tracked in checkpoints
- Max 2 replans per phase enforced
- Replan history logged for audit trail
- User escalation when limit exceeded

### Utilities
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh`
- **Complexity Analysis**: `.claude/lib/complexity-utils.sh`
- **Adaptive Logging**: `.claude/lib/adaptive-planning-logger.sh`
- **Error Handling**: `.claude/lib/error-handling.sh`

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

## Development Workflow

### Planning and Implementation
1. Create research reports in `specs/reports/` for complex topics
2. Generate implementation plans in `specs/plans/` based on research
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in `specs/summaries/` linking plans to code
5. Adaptive planning automatically adjusts plans during implementation

### Spec Updater Integration
[Used by: /plan, /expand, /implement, /orchestrate]

The spec updater agent manages artifacts in topic-based directory structure:

**Agent Role**: `.claude/agents/spec-updater.md`
- Creates artifacts in appropriate topic subdirectories
- Maintains cross-references between artifacts
- Manages artifact lifecycle and gitignore compliance
- Ensures topic-based organization consistency

**Topic-Based Structure**: `specs/{NNN_topic}/`
- `reports/` - Research reports (gitignored)
- `plans/` - Sub-plans (gitignored)
- `summaries/` - Implementation summaries (gitignored)
- `debug/` - Debug reports (COMMITTED for issue tracking)
- `scripts/` - Investigation scripts (gitignored, temporary)
- `outputs/` - Test outputs (gitignored, cleaned after workflow)
- `artifacts/` - Operation artifacts (gitignored)
- `backups/` - Backups (gitignored)

**Spec Updater Checklist** (included in all plan templates):
- Ensure plan is in topic-based directory structure
- Create standard subdirectories if needed
- Update cross-references if artifacts moved
- Create implementation summary when complete
- Verify gitignore compliance (debug/ committed, others ignored)

**Artifact Lifecycle**:

1. **Core Planning Artifacts** (reports/, plans/, summaries/)
   - Lifecycle: Created during planning/research, preserved
   - Gitignore: YES (local working artifacts)
   - Cleanup: Never (preserved for reference)

2. **Debug Reports** (debug/)
   - Lifecycle: Created during debugging, preserved permanently
   - Gitignore: NO (COMMITTED for issue tracking)
   - Cleanup: Never (part of project history)

3. **Investigation Scripts** (scripts/)
   - Lifecycle: Created during debugging, temporary
   - Gitignore: YES (temporary workflow scripts)
   - Cleanup: Automatic after workflow completion
   - Retention: 0 days (removed immediately after workflow)

4. **Test Outputs** (outputs/)
   - Lifecycle: Created during testing, temporary
   - Gitignore: YES (regenerable test artifacts)
   - Cleanup: Automatic after verification
   - Retention: 0 days (removed after test validation)

5. **Operation Artifacts** (artifacts/)
   - Lifecycle: Created during expansion/collapse, optional cleanup
   - Gitignore: YES (operational metadata)
   - Cleanup: Optional (can be preserved for analysis)
   - Retention: 30 days (configurable)

6. **Backups** (backups/)
   - Lifecycle: Created during migrations/operations
   - Gitignore: YES (large files, regenerable)
   - Cleanup: Optional cleanup after verification
   - Retention: 30 days (configurable)

**Shell Utilities** (`.claude/lib/artifact-operations.sh`):
- `create_topic_artifact <topic-dir> <type> <name> <content>` - Create artifact
- `cleanup_topic_artifacts <topic-dir> <type> [age-days]` - Clean specific type
- `cleanup_all_temp_artifacts <topic-dir>` - Clean all temporary artifacts

**Usage Pattern**:
- Plans created by `/plan` include spec updater checklist
- Orchestrator invokes spec updater at phase boundaries
- `/expand` preserves spec updater checklist in expanded files
- Implementation phase uses spec updater for artifact management

**Plan Hierarchy Updates** (`.claude/lib/checkbox-utils.sh`):
- Automatically updates checkboxes across plan hierarchy levels after phase completion
- Functions: `update_checkbox()`, `propagate_checkbox_update()`, `mark_phase_complete()`, `verify_checkbox_consistency()`
- Supports Level 0 (single file), Level 1 (expanded phases), Level 2 (stages → phases → main)
- Integration points:
  - `/implement` Step 5: Invokes spec-updater agent after git commit success
  - `/orchestrate` Documentation Phase: Updates hierarchy after implementation complete
  - Checkpoint field: `hierarchy_updated` tracks update status
- Ensures parent/grandparent plan files stay synchronized with child progress

### Git Workflow
- Feature branches for new development
- Clean, atomic commits with descriptive messages
- Test before committing
- Document breaking changes

## Project-Specific Commands

### Claude Code Commands
Located in `.claude/commands/`:
- `/orchestrate <workflow-description>` - Coordinate specialized agents through complete development workflows
- `/implement [plan-file]` - Execute implementation plans
- `/report <topic>` - Generate research documentation
- `/plan <feature>` - Create implementation plans
- `/plan-from-template <template-name>` - Generate plans from reusable templates
- `/plan-wizard` - Interactive plan creation with guided prompts
- `/test <target>` - Run project-specific tests
- `/setup` - Configure or update this CLAUDE.md file

#### /orchestrate - Multi-Agent Workflow Coordination

The /orchestrate command coordinates specialized agents through end-to-end development workflows with automated complexity evaluation, plan expansion, and wave-based parallel execution.

**Workflow Phases**:
1. **Research** (Parallel): research-specialist agents investigate patterns, practices, alternatives (2-4 agents)
2. **Planning** (Sequential): plan-architect synthesizes research into structured implementation plan
3. **Complexity Evaluation** (Automated): complexity-estimator analyzes plan phases for expansion needs
4. **Plan Expansion** (Adaptive): plan-expander agents expand complex phases (complexity ≥8 or >10 tasks)
5. **Implementation** (Wave-Based): code-writer agents execute independent phases in parallel waves
6. **Debugging** (Conditional): debug-specialist investigates failures, code-writer applies fixes (max 3 iterations)
7. **Documentation** (Sequential): doc-writer updates docs and generates workflow summary

**Agent Coordination Patterns**:
- **Parallel execution**: Research agents and independent phases run concurrently (single message, multiple Task invocations)
- **Sequential execution**: Planning, documentation execute in order
- **Wave-based execution**: Phases grouped by dependencies, independent phases execute in parallel
- **Conditional execution**: Debugging only triggers on test failures
- **Iteration limiting**: Max 3 debug iterations before user escalation

**Enhanced Capabilities**:
- **Automated Complexity Evaluation**: Uses hybrid threshold + agent-based scoring to identify complex phases
- **Automatic Plan Expansion**: Expands phases with complexity ≥8 or >10 tasks to separate files
- **Wave-Based Parallelization**: Analyzes phase dependencies and executes independent phases in parallel (40-60% time savings)
- **Continuous Context Preservation**: Spec updater maintains <30% context usage throughout workflow
- **Plan Hierarchy Updates**: Automatically updates all plan levels (main → phase → stage) after completion

**Usage**: `/orchestrate <workflow-description> [--create-pr]`

**Example**: `/orchestrate Add user authentication with email and password`

**Artifacts Generated**:
- Research reports: `specs/{NNN_topic}/reports/NNN_report.md`
- Implementation plan: `specs/{NNN_topic}/plans/001_feature.md` (or expanded directory structure)
- Workflow summary: `specs/{NNN_topic}/summaries/001_summary.md`
- Debug reports (if needed): `specs/{NNN_topic}/debug/NNN_report.md`
- Complexity evaluation results: Saved in workflow checkpoint

**State Management**:
- TodoWrite tracks all 7 workflow phases
- Checkpoints saved at phase boundaries for resumption
- Progress markers (PROGRESS:) emitted for real-time visibility
- Error history tracked for debugging and recovery
- Wave execution state tracked for parallel phase coordination

**Performance Targets**:
- Context usage: <30% throughout workflow
- Parallel research: 60-80% time savings vs sequential
- Wave-based implementation: 40-60% time savings vs sequential
- Complexity evaluation accuracy: >80% vs manual assessment

See `.claude/commands/orchestrate.md` for detailed workflow patterns and agent invocation examples.
See `.claude/templates/orchestration-patterns.md` for agent prompt templates and integration patterns.

#### Template-Based Planning

The template system provides rapid plan generation from reusable templates.

**Available Commands**:
- `/plan-from-template <template-name>` - Generate plan from template with variable substitution
- `/plan-wizard` - Interactive guided plan creation with optional research

**When to use templates**:
- Common patterns (CRUD, API endpoints, refactoring, migrations)
- Fast plan generation (60-80% faster than manual planning)
- Consistent structure across similar features
- Standardized workflows (testing, documentation, debugging)

**Template Categories**:
- `backend` - API endpoints, backend services
- `feature` - General features, CRUD operations
- `refactoring` - Code consolidation, structural improvements
- `testing` - Test suite setup and enhancement
- `documentation` - Documentation updates and generation
- `research` - Research reports and analysis
- `debugging` - Debug workflows and troubleshooting
- `migration` - Data and code migrations

**Usage Examples**:
```bash
# Direct template usage
/plan-from-template crud-feature

# Interactive wizard with research
/plan-wizard

# List available templates
/plan-from-template --list

# List by category
/plan-from-template --category feature
```

**Template System Components**:
- Templates: `.claude/templates/*.yaml` (11 standard templates)
- Utilities: `.claude/lib/parse-template.sh`, `.claude/lib/substitute-variables.sh`
- Integration: `.claude/lib/template-integration.sh`

See `.claude/templates/README.md` for template structure and creation guide.

## Quick Reference

### Common Tasks
- **Run Tests**: `:TestSuite` or `/test-all`
- **Format Code**: `<leader>mp`
- **Check Linting**: `<leader>l`
- **Find Files**: `<C-p>` (Telescope)
- **Search Project**: `<leader>sg` (Telescope grep)

### Navigation
- [Neovim Configuration](nvim/)
- [Specifications](nvim/specs/)
- [Commands](.claude/commands/)

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

## Notes
This CLAUDE.md was automatically configured with the `/setup` command.
For updates or improvements, run `/setup` again or edit manually following the established patterns.

Standards sections are marked with `[Used by: commands]` metadata for discoverability.


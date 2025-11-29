# /todo Command and Project Tracking Standards - Research Report

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: /todo command implementation and TODO.md standards
- **Report Type**: codebase analysis

## Executive Summary

Research reveals a comprehensive foundation for creating a /todo command that automatically tracks project progress in .claude/specs/ and updates .claude/TODO.md. The system has well-defined directory protocols with topic-based organization (specs/NNN_topic/), multiple artifact types (plans/, reports/, summaries/, debug/), and clear completion markers ([COMPLETE] status). Haiku model usage is established across 7 commands for fast classification tasks. Implementation can leverage existing patterns from /errors command (query/report modes), unified-location-detection.sh (specs traversal), and research-specialist agent (Haiku-based analysis).

## Findings

### 1. Existing Command Structure

**Location**: /home/benjamin/.config/.claude/commands/

Commands follow a consistent three-part structure with frontmatter, behavioral instructions, and bash execution blocks:

**Frontmatter Pattern** (lines 1-14 in plan.md, errors.md, build.md):
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description> [--file <path>] [--complexity 1-4]
description: Research and create new implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/plan-command-guide.md
---
```

**Common Patterns**:
- Bash blocks with three-tier library sourcing (error-handling.sh, state-persistence.sh, workflow-state-machine.sh)
- Error logging integration via `ensure_error_log_exists()`, `setup_bash_error_trap()`
- Argument parsing with optional flags (--complexity, --file, --query, --summary)
- State machine integration for workflow commands
- Dual-mode operation (e.g., /errors has default report mode and --query mode)

**Key Files Examined**:
- /home/benjamin/.config/.claude/commands/plan.md:1-150 - Research-and-plan workflow with complexity flag parsing
- /home/benjamin/.config/.claude/commands/errors.md:1-150 - Dual mode (report/query) with multiple filter flags
- /home/benjamin/.config/.claude/commands/build.md:1-150 - Build workflow with resume checkpoints

### 2. Specs Directory Structure and Organization

**Location**: /home/benjamin/.config/.claude/specs/

**Topic-Based Organization** (directory-protocols.md:44-55):
```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED to git)
    ├── scripts/        # Investigation scripts (gitignored, temporary)
    ├── outputs/        # Test outputs (gitignored, temporary)
    ├── artifacts/      # Operation artifacts (gitignored)
    └── backups/        # Backups (gitignored)
```

**Topic Naming Convention**:
- Format: `NNN_topic_name/` where NNN is 000-999
- Example: `950_revise_refactor_subagent_delegation/`
- LLM-based naming via topic-naming-agent (Haiku model)
- Fallback: `NNN_no_name_error/` on agent failure

**Artifact Organization**:
- Plans: `{topic}/plans/001-{plan-name}.md` (kebab-case with hyphens)
- Reports: `{topic}/reports/001-{report-name}.md`
- Summaries: `{topic}/summaries/001-{summary-name}.md`

**Current Specs Count**: 183 directories (from bash ls output)

**Example Complete Project** (952_fix_failing_tests_coverage/):
- plans/001-fix-failing-tests-coverage-plan.md
- reports/001_failing_tests_analysis.md
- summaries/002_iteration_2_summary.md
- summaries/003_iteration_3_final_summary.md

### 3. Current TODO.md File Format

**Location**: /home/benjamin/.config/.claude/TODO.md

**Existing Structure** (lines 1-175):
```markdown
# TODO

## In Progress
- [ ] **README compliance audit updates** - ... [path/to/plan.md]
  - Phase 1 complete, Phase 2 in progress
  - Target: 95%+ compliance

## Not Started
- [x] **Error log status tracking** - ... [path/to/plan.md]
- [x] **/revise subagent delegation fix** - ... [path/to/plan.md]

## Backlog
**Refactoring/Enhancement Ideas**:
- Retry semantic directory topic names
- Make /plan, /build follow standards consistently

**Related Research**:
- Haiku parallel subagents: [path/to/report.md]

## Superseded
- [~] **Make /build persistent** - Superseded by Plan 899 [path]

## Abandoned
- [x] **Error logging infrastructure** - Helper functions unnecessary [path]
  - **Reason**: Infrastructure already complete
  - **Analysis**: Functions would trade context for generic messages

## Completed
**November 27-29, 2025**:
- [x] **Orchestrator subagent delegation** - ... [path/to/plan.md]
  - All 12 phases complete
  - Created reusable hard barrier pattern
- [x] **Fix failing tests** - ... [path/to/plan.md]
```

**Key Observations**:
- Checkbox syntax: `[ ]` for not started, `[x]` for started/complete, `[~]` for superseded
- Date-based grouping in Completed section
- Bullet list with plan titles, brief descriptions, and file paths
- Sub-bullets for phase status and achievements
- Hierarchical organization: In Progress → Not Started → Backlog → Superseded → Abandoned → Completed

**Inconsistencies Identified**:
- "Not Started" section contains `[x]` checkboxes (should be `[ ]`)
- No standard format for indented sub-items (summaries/reports)
- Manual date grouping in Completed section

### 4. Documentation Standards

**Location**: /home/benjamin/.config/.claude/docs/

**Relevant Standards Files**:
- docs/concepts/directory-protocols.md - Topic-based artifact organization (150 lines examined)
- docs/reference/standards/command-reference.md - Command catalog and patterns (100 lines examined)
- docs/reference/standards/documentation-standards.md (referenced in CLAUDE.md)
- docs/guides/commands/ - Individual command guides (referenced)

**Key Standards** (from CLAUDE.md):
- README requirements for active development directories
- Documentation format: clear, concise, code examples, Unicode diagrams
- No emojis in file content
- CommonMark specification compliance
- No historical commentary

**Command Documentation Pattern** (command-reference.md:69-87):
```markdown
### /build
**Purpose**: Build-from-plan workflow
**Usage**: `/build [plan-file] [starting-phase] [--dry-run]`
**Type**: orchestrator
**Arguments**: ...
**Agents Used**: implementer-coordinator, debug-analyst
**Output**: Implemented features with commits
**Workflow**: `implement → test → [debug OR document] → complete`
**See**: [build.md](../../commands/build.md)
```

### 5. Plan Completion Status Detection

**Completion Markers Found** (from grep analysis):

**Primary Marker - Metadata Status Field** (952_fix_failing_tests_coverage/plans/001-...:10):
```markdown
- **Status**: [COMPLETE]
```

**Secondary Markers - Phase Headers** (grep results):
```markdown
### Phase 1: Fix Test Path Resolution [COMPLETE]
### Phase 2: Update agents/README.md [COMPLETE]
```

**Detection Patterns**:
1. **Metadata Block Status**: Line matching `^\*\*Status\*\*: \[COMPLETE\]`
2. **All Phases Complete**: All phase headers have `[COMPLETE]` marker
3. **Status Field Variations**:
   - `**Status**: [COMPLETE]`
   - `**Status**: [IN PROGRESS]`
   - `**Status**: [NOT STARTED]`
   - `**Status**: COMPLETE (100% - All N phases complete)`

**Alternative Status Indicators**:
- Completion percentage: `**Status**: ✅ 100% Complete`
- Phase-specific: `**Status**: All commands updated, documentation complete`
- Deferred status: `**Status**: DEFERRED as optional enhancement`

**File Locations**:
- /home/benjamin/.config/.claude/specs/849_claude_planoutputmd.../plans/001...plan.md - Multiple status variations
- /home/benjamin/.config/.claude/specs/952_fix_failing_tests_coverage/plans/001...plan.md:10 - `[COMPLETE]` marker

### 6. Haiku Model Usage Patterns

**Current Haiku Usage** (from grep analysis):

**Agent Files Using Haiku**:
- errors-analyst.md:4 - `model: claude-3-5-haiku-20241022`
- test-executor.md:4 - `model: haiku-4.5`
- workflow-classifier.md - `model: haiku` (fast classification)
- topic-naming-agent (referenced in topic-utils.sh:30)

**Haiku Use Cases** (agents/README.md:97-478):
- Classification tasks (workflow types, complexity assessment)
- Deterministic operations (document conversion, artifact updates)
- Fast structural analysis (parsing, pattern recognition)
- Coordination tasks (wave-based execution)

**Model Selection Pattern**:
```yaml
---
model: haiku-4.5
model-justification: Fast complexity assessment, deterministic output
fallback-model: haiku-4.5
---
```

**Performance Characteristics**:
- Fast response times (suitable for batch operations)
- Lower cost for high-volume tasks
- Deterministic outputs for classification
- Suitable for structured data extraction

**Commands Using Haiku Agents** (directory-protocols.md:80-83):
- /plan, /research, /debug, /optimize-claude (topic naming)
- /errors (error analysis via errors-analyst)
- /setup (analyze mode)
- /repair (error grouping)

### 7. Command Documentation Standards

**Documentation Requirements** (from CLAUDE.md and command-reference.md):

**Frontmatter Fields** (standard across all commands):
```yaml
allowed-tools: [list]
argument-hint: <required> [optional] [--flags]
description: One-line command purpose
command-type: primary|utility|orchestrator
dependent-agents: [list]
library-requirements:
  - library.sh: ">=version"
documentation: See .claude/docs/guides/commands/{command}-guide.md
```

**Command File Structure**:
1. Frontmatter (YAML metadata)
2. Command title and purpose
3. Workflow type and expected outputs
4. Block-based execution instructions (Block 1a, Block 1b, Block 2, etc.)
5. Bash blocks with inline instructions
6. State machine integration (for workflow commands)
7. Agent invocation patterns (Task tool usage)

**Command Guide Structure** (referenced but not examined):
- Purpose and overview
- Usage examples
- Argument reference
- Workflow details
- Integration with other commands

**Standards Compliance** (from code-standards.md reference):
- Three-tier library sourcing pattern
- Error logging integration
- Output suppression (2>/dev/null)
- Consolidated bash blocks (2-3 per phase)
- Idempotent state transitions

## Recommendations

### 1. /todo Command Design

**Command Type**: utility (similar to /errors query mode)

**Proposed Frontmatter**:
```yaml
---
allowed-tools: Bash, Read, Glob, Write, Task
argument-hint: [--clean] [--dry-run]
description: Update TODO.md with current project progress from specs directory
command-type: utility
dependent-agents:
  - todo-analyzer (Haiku model for fast plan analysis)
library-requirements:
  - unified-location-detection.sh: ">=1.0.0"
documentation: See .claude/docs/guides/commands/todo-command-guide.md
---
```

**Workflow**:
1. **Discovery Phase**: Glob all specs/*/plans/*.md files
2. **Analysis Phase**: Invoke todo-analyzer (Haiku) to check each plan's completion status
3. **Categorization Phase**: Group plans by status (In Progress, Not Started, Backlog, Completed, etc.)
4. **Update Phase**: Write to TODO.md with organized sections
5. **Clean Mode** (--clean flag): Identify completed projects, generate cleanup plan

**Key Functions**:
- `scan_project_directories()`: Glob specs/*/ to find all projects
- `check_plan_status()`: Extract status from plan metadata and phase markers
- `categorize_plan()`: Determine TODO.md section (In Progress, Not Started, etc.)
- `find_related_artifacts()`: Glob reports/, summaries/ for each project
- `update_todo_file()`: Write organized TODO.md with proper section hierarchy
- `generate_cleanup_plan()`: Create plan to remove completed projects (--clean mode)

### 2. TODO.md Organization Standards

**Proposed Standard Structure**:
```markdown
# TODO

## In Progress
- [ ] **{Plan Title}** - {Brief description} [{path/to/plan.md}]
  - {Current phase status}
  - Related reports: [{path/to/report.md}]
  - Related summaries: [{path/to/summary.md}]

## Not Started
- [ ] **{Plan Title}** - {Brief description} [{path/to/plan.md}]

## Backlog
{Ideas and future work - manual curation}

## Superseded
- [~] **{Plan Title}** - Superseded by {reason} [{path/to/plan.md}]

## Abandoned
- [x] **{Plan Title}** - {Reason for abandonment} [{path/to/plan.md}]
  - **Reason**: {Brief explanation}

## Completed
**{Date Range}**:
- [x] **{Plan Title}** - {Brief description} [{path/to/plan.md}]
  - {Key achievements}
  - Related reports: [{path/to/report.md}]
  - Related summaries: [{path/to/summary.md}]
```

**Checkbox Convention**:
- `[ ]` - Not started
- `[x]` - Started, in progress, or complete
- `[~]` - Superseded

**Section Ordering** (top to bottom):
1. In Progress
2. Not Started
3. Backlog (manually curated)
4. Superseded
5. Abandoned
6. Completed (date-grouped, newest first)

**Artifact Inclusion Rules**:
- Include ALL reports and summaries as indented bullet points under each plan
- Format: `  - Related reports: [report-title](path/to/report.md)`
- Reports and summaries discovered via Glob: `specs/{topic}/reports/*.md`, `specs/{topic}/summaries/*.md`

### 3. Haiku Agent for Plan Analysis

**Proposed Agent**: todo-analyzer.md

**Frontmatter**:
```yaml
---
allowed-tools: Read
model: haiku-4.5
model-justification: Fast batch analysis of plan status across 100+ projects
fallback-model: haiku-4.5
description: Analyze plan files to determine completion status and extract metadata
---
```

**Agent Responsibilities**:
1. Read plan file
2. Extract metadata (title, status field)
3. Check all phase headers for [COMPLETE] markers
4. Determine overall status (In Progress, Not Started, Complete, etc.)
5. Return structured JSON: `{"status": "complete", "title": "...", "phases_complete": 8, "phases_total": 8}`

**Batch Invocation Pattern**:
- Process plans in parallel batches (10-20 at a time)
- Aggregate results for TODO.md generation
- Fast response (Haiku optimized for this task)

### 4. --clean Flag Implementation

**Purpose**: Identify completed projects and create cleanup plan

**Workflow**:
1. Scan all projects with `[COMPLETE]` status
2. Verify all phases complete (no partial completions)
3. Check for active references in TODO.md
4. Generate plan to:
   - Move completed project directories to archive/
   - Remove from TODO.md (move to Completed section)
   - Create archive manifest

**Safety Checks**:
- Require explicit confirmation before cleanup
- Create backup of TODO.md before modifications
- Archive (don't delete) completed projects
- Log all cleanup operations

### 5. Integration with Existing Systems

**Library Dependencies**:
- unified-location-detection.sh:detect_specs_directory() - Get specs root path
- topic-utils.sh (for reference, not primary use)
- error-handling.sh:log_command_error() - Log failures

**Error Logging**:
- Log plan parsing failures: `log_command_error "parse_error" "Failed to parse plan: $path"`
- Log agent invocation failures: `parse_subagent_error "$output" "todo-analyzer"`

**Standards Compliance**:
- Three-tier library sourcing
- Error trap setup: `setup_bash_error_trap "/todo" "todo_$(date +%s)" "$USER_ARGS"`
- Output suppression with 2>/dev/null
- Consolidated bash blocks (Setup → Execute → Update)

## References

### Command Files
- /home/benjamin/.config/.claude/commands/plan.md:1-150
- /home/benjamin/.config/.claude/commands/errors.md:1-150
- /home/benjamin/.config/.claude/commands/build.md:1-150
- /home/benjamin/.config/.claude/commands/README.md

### Library Files
- /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh:1-150
- /home/benjamin/.config/.claude/lib/plan/topic-utils.sh:1-100

### Documentation Files
- /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md:1-150
- /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md:1-100
- /home/benjamin/.config/CLAUDE.md (project configuration)

### Plan Files
- /home/benjamin/.config/.claude/specs/952_fix_failing_tests_coverage/plans/001-fix-failing-tests-coverage-plan.md:1-100
- /home/benjamin/.config/.claude/specs/950_revise_refactor_subagent_delegation/plans/001-revise-refactor-subagent-delegation-plan.md:1-200

### TODO File
- /home/benjamin/.config/.claude/TODO.md:1-175

### Agent Files
- /home/benjamin/.config/.claude/agents/research-specialist.md:1-684
- /home/benjamin/.config/.claude/agents/errors-analyst.md:4-6 (model reference)
- /home/benjamin/.config/.claude/agents/README.md:97-478 (Haiku usage patterns)

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [001-todo-command-project-tracking-standards-plan.md](../plans/001-todo-command-project-tracking-standards-plan.md)
- **Implementation**: [Will be updated by /build]
- **Date**: 2025-11-29

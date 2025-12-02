# TODO.md Organization Standards

## Purpose

This document defines the comprehensive standards for organizing and maintaining the `.claude/TODO.md` file, including section hierarchy, checkbox conventions, entry formatting, and artifact inclusion rules.

## Section Hierarchy

The TODO.md file follows a strict 7-section hierarchy that reflects project lifecycle status:

### Section Order (Required)

1. **In Progress** - Actively being worked on
2. **Not Started** - Planned but not yet started
3. **Research** - Research-only projects (no plans) from `/research` or `/errors` commands
4. **Saved** - Demoted items from "Not Started" or "In Progress" to revisit later
5. **Backlog** - Manually curated ideas and future enhancements
6. **Abandoned** - Intentionally stopped, superseded, or discontinued (with documented reasons)
7. **Completed** - Successfully finished (date-grouped)

### Section Definitions

| Section | Purpose | Auto-Updated | Checkbox |
|---------|---------|--------------|----------|
| In Progress | Plans currently being implemented | Yes | `[x]` |
| Not Started | Plans created but not started | Yes | `[ ]` |
| Research | Research-only projects without plans | Yes | `[ ]` |
| Saved | Demoted items to revisit later | No (manual) | `[ ]` |
| Backlog | Manually curated future ideas | No (preserved) | None or `[ ]` |
| Abandoned | Intentionally stopped or superseded | Yes | `[x]` |
| Completed | Successfully finished | Yes | `[x]` |

## Checkbox Conventions

### Standard Checkboxes

- `[ ]` - Not started (used in "Not Started", "Research", "Saved" sections)
- `[x]` - Started, in progress, complete, or abandoned (used in "In Progress", "Completed", "Abandoned" sections)

### Usage Rules

1. **Not Started** section entries MUST use `[ ]` checkbox
2. **In Progress** section entries MUST use `[x]` checkbox
3. **Research** section entries MUST use `[ ]` checkbox
4. **Saved** section entries MUST use `[ ]` checkbox
5. **Completed** section entries MUST use `[x]` checkbox
6. **Abandoned** section entries MUST use `[x]` checkbox (includes superseded items)
7. **Backlog** section entries may use `[ ]` or no checkbox (manual curation)

## Entry Format

### Standard Entry Structure

```markdown
- [checkbox] **{Plan Title}** - {Brief description} [{relative/path/to/plan.md}]
  - {Phase status or key achievements}
  - Related reports: [{report-title}](relative/path/to/report.md)
  - Related summaries: [{summary-title}](relative/path/to/summary.md)
```

### Components

| Component | Description | Required |
|-----------|-------------|----------|
| Checkbox | Status indicator (`[ ]`, `[x]`, `[~]`) | Yes |
| Plan Title | Bold plan name | Yes |
| Brief description | One-line summary | Yes |
| Plan path | Relative path in brackets | Yes |
| Phase status | Current progress info (indented) | Optional |
| Related artifacts | Reports/summaries as indented bullets | Optional |

### Examples

**In Progress Entry**:
```markdown
- [x] **README compliance audit updates** - Update 58 READMEs for Purpose/Navigation section compliance [.claude/specs/958_readme_compliance_audit_updates/plans/001-readme-compliance-audit-updates-plan.md]
  - Phase 1 complete (library subdirectories), Phase 2 in progress (top-level directories)
  - Target: 95%+ compliance (83+/87 READMEs)
```

**Completed Entry**:
```markdown
- [x] **Orchestrator subagent delegation** - Comprehensive fix for 13 commands to enforce subagent delegation [.claude/specs/950_revise_refactor_subagent_delegation/plans/001-revise-refactor-subagent-delegation-plan.md]
  - All 12 phases complete: /revise, /build, /expand, /collapse, /errors, /research, /debug, /repair fixed
  - Created reusable hard barrier pattern documentation and barrier-utils.sh library
```

**Abandoned Entry** (includes superseded items):
```markdown
- [x] **Error logging infrastructure completion** - Helper functions deemed unnecessary after comprehensive analysis [.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md]
  - **Reason**: Error logging infrastructure already 100% complete across all 12 commands
  - **Alternative**: Focus on Plan 883 (Commands Optimize Refactor) for measurable improvements

- [x] **Make /build persistent** - Superseded by Plan 899 (Build iteration infrastructure) [.claude/specs/881_build_persistent_workflow_refactor/plans/001_build_persistent_workflow_refactor_plan.md]
  - **Reason**: Superseded by [901_plan_integration_overlap_analysis](specs/901_plan_integration_overlap_analysis/reports/001_plan_integration_overlap_analysis.md)
```

**Research Entry** (no plan, reports only):
```markdown
- [ ] **Error patterns analysis** - Error log analysis from /errors command [.claude/specs/935_errors_repair_research/]
  - Reports: [Error Analysis](.claude/specs/935_errors_repair_research/reports/001_error_analysis.md)
```

**Saved Entry** (demoted from Not Started or In Progress):
```markdown
- [ ] **Buffer Hook Reversion** - Systematic removal of buffer-hook integration from research workflow [.claude/specs/980_revert_research_buffer_hook/plans/001-revert-research-buffer-hook-plan.md]
  - **Demoted from**: Not Started (2025-11-30)
  - **Reason**: Lower priority; revisit after core workflow improvements complete
```

## Artifact Inclusion Rules

### Discovery Pattern

Related artifacts are discovered via Glob patterns:
- Reports: `specs/{topic}/reports/*.md`
- Summaries: `specs/{topic}/summaries/*.md`

### Inclusion Order

1. Reports first (chronological by filename)
2. Summaries second (chronological by filename)

### Path Format

- Use relative paths from TODO.md location
- Format: `[{artifact-title}](relative/path/to/artifact.md)`

### Example with Artifacts

```markdown
- [x] **Haiku parallel subagents research** - Research report on Haiku subagent patterns [.claude/specs/20251121_convert_docs_plan_improvements_research/plans/001-research-plan.md]
  - Related reports: [Haiku Parallel Subagents](.claude/specs/20251121_convert_docs_plan_improvements_research/reports/001_haiku_parallel_subagents.md)
  - Related summaries: [Research Summary](.claude/specs/20251121_convert_docs_plan_improvements_research/summaries/001_research_summary.md)
```

## Date Grouping (Completed Section Only)

### Format

Completed entries are grouped by date ranges with headers:

```markdown
## Completed

**November 27-29, 2025**:

- [x] **Plan A** - Description [path]
- [x] **Plan B** - Description [path]

**November 26, 2025**:

- [x] **Plan C** - Description [path]
```

### Rules

1. Use bold date range headers (e.g., `**November 27-29, 2025**:`)
2. Newest entries at top
3. Group by consecutive days when work occurred
4. Single-day groups use single date (e.g., `**November 26, 2025**:`)

## Research Section

### Purpose

The Research section tracks spec directories that contain research reports but no implementation plans. These are typically created by:
- `/research` command (research-only workflows)
- `/errors` command (error analysis reports)

### Auto-Detection Rules

The `/todo` command identifies Research entries by:
1. Directory exists in `specs/` with `reports/` subdirectory
2. Directory has NO files in `plans/` subdirectory (or no `plans/` subdirectory)
3. Directory is not manually placed in other sections

### Entry Format

Research entries link to the directory (not a plan file):

```markdown
- [ ] **{Topic Title}** - {Brief description from report} [.claude/specs/{NNN_topic}/]
  - Reports: [Report Title](.claude/specs/{NNN_topic}/reports/001-report.md)
```

### Example Research Section

```markdown
## Research

- [ ] **Error patterns analysis** - Analysis of command error patterns [.claude/specs/935_errors_repair_research/]
  - Reports: [Error Analysis](.claude/specs/935_errors_repair_research/reports/001_error_analysis.md)

- [ ] **Haiku subagent patterns** - Research on parallel subagent orchestration [.claude/specs/20251121_convert_docs_plan_improvements_research/]
  - Reports: [Haiku Parallel Subagents](.claude/specs/20251121_convert_docs_plan_improvements_research/reports/001_haiku_parallel_subagents.md)
  - Reports: [Orchestrator Command Standards](.claude/specs/20251121_convert_docs_plan_improvements_research/reports/002_orchestrator_command_standards.md)
```

## Saved Section

### Purpose

The Saved section holds items demoted from "Not Started" or "In Progress" that the user wants to revisit later. Unlike Abandoned items, Saved items are intentionally preserved for future consideration.

### Manual Curation

The Saved section is manually curated and NOT auto-updated by the `/todo` command.

### Preservation Rules

1. `/todo` command MUST preserve existing Saved content
2. Items are moved manually from "Not Started" or "In Progress"
3. Each entry SHOULD include "Demoted from" and "Reason" metadata
4. Items can be promoted back to "Not Started" when ready

### Entry Format

```markdown
- [ ] **{Plan Title}** - {Brief description} [{plan-path}]
  - **Demoted from**: {Not Started|In Progress} ({date})
  - **Reason**: {Why this was saved for later}
```

### Example Saved Section

```markdown
## Saved

- [ ] **Buffer Hook Reversion** - Systematic removal of buffer-hook integration [.claude/specs/980_revert_research_buffer_hook/plans/001-revert-research-buffer-hook-plan.md]
  - **Demoted from**: Not Started (2025-11-30)
  - **Reason**: Lower priority; revisit after core workflow improvements complete

- [ ] **README compliance audit** - Update 58 READMEs for compliance [.claude/specs/958_readme_compliance_audit_updates/plans/001-readme-compliance-audit-updates-plan.md]
  - **Demoted from**: In Progress (2025-11-28)
  - **Reason**: Paused for higher-priority error repair work
```

## Backlog Preservation

### Policy

The Backlog section is manually curated and NOT auto-updated by the `/todo` command.

### Preservation Rules

1. `/todo` command MUST preserve existing Backlog content
2. New Backlog items added manually by users
3. Structure within Backlog is user-defined (may use sub-headers)
4. Related research links within Backlog are preserved as-is

### Example Backlog Structure

```markdown
## Backlog

**Refactoring/Enhancement Ideas**:

- Retry semantic directory topic names and other fail-points
- Refactor subagent applications throughout commands
  - [Research report](specs/research/reports/001_subagent_patterns.md)
- Make commands update TODO.md automatically

**Related Research**:

- Haiku parallel subagents: [Report](.claude/specs/research/reports/001_haiku.md)
- Orchestrator patterns: [Report](.claude/specs/research/reports/002_orchestrator.md)
```

## Status Classification Logic

### Automatic Status Detection

The `/todo` command uses plan metadata to classify status:

| Plan Status Field | TODO.md Section |
|------------------|-----------------|
| `[COMPLETE]` | Completed |
| `[IN PROGRESS]` | In Progress |
| `[NOT STARTED]` | Not Started |
| `DEFERRED` | Backlog |
| `SAVED` | Saved |
| `SUPERSEDED` | Abandoned |
| `ABANDONED` | Abandoned |
| (no plan file) | Research |

### Research Detection (Special Case)

Directories with reports but no plans are classified as Research:
1. Has `reports/` subdirectory with `.md` files
2. Has NO `plans/` subdirectory OR `plans/` is empty
3. Not manually placed in Saved/Backlog sections

### Fallback Detection

If Status field is missing, detection uses phase markers:
- All phases `[COMPLETE]` -> Completed
- Some phases complete -> In Progress
- No phases complete -> Not Started

## Validation Criteria

The following are checked by validation scripts:

### Structure Validation

- [ ] All 7 sections present in correct order
- [ ] Each section uses correct header format (`## Section Name`)
- [ ] Completed section has date grouping headers

### Entry Validation

- [ ] Each entry uses correct checkbox for its section
- [ ] Plan title is bold
- [ ] Plan path is in brackets and valid
- [ ] Indented sub-items use consistent formatting

### Link Validation

- [ ] Plan paths exist and are accessible
- [ ] Artifact links (reports/summaries) point to existing files
- [ ] Relative paths are correct from TODO.md location

## Usage by Commands

### Automatic TODO.md Updates

Six commands automatically update TODO.md when creating or modifying plans and reports:

- **/build**: Updates at START (→ In Progress) and COMPLETION (→ Completed)
- **/plan**: Updates after new plan creation (→ Not Started)
- **/research**: Updates after report creation (→ Research)
- **/debug**: Updates after debug report creation (→ Research)
- **/repair**: Updates after repair plan creation (→ Not Started)
- **/revise**: Updates after plan modification (status unchanged)

All commands use the signal-triggered delegation pattern, delegating to `/todo` for consistent classification and formatting. See [Command-TODO Integration Guide](/home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md) for implementation details.

### /todo Command

- Scans specs/ directories
- Classifies plans by status
- Updates TODO.md (preserving Backlog and Saved sections)
- Includes related artifacts
- Can be invoked manually or triggered automatically by other commands

## Anti-Patterns

### Incorrect Checkbox Usage

```markdown
# WRONG: [ ] in Completed section
- [ ] **Completed plan** - Description [path]

# WRONG: [x] in Not Started section
- [x] **Planned plan** - Description [path]
```

### Missing Plan Path

```markdown
# WRONG: No path in brackets
- [x] **Some plan** - Description

# CORRECT
- [x] **Some plan** - Description [.claude/specs/topic/plans/001-plan.md]
```

### Inconsistent Artifact Format

```markdown
# WRONG: Mixed formats
- Related: reports/001.md
- See also: summaries/001.md

# CORRECT
- Related reports: [Report Title](reports/001-report.md)
- Related summaries: [Summary Title](summaries/001-summary.md)
```

## Navigation

- [Parent: Standards Reference](README.md)
- [Related: Command Reference](command-reference.md)
- [Related: Documentation Standards](documentation-standards.md)

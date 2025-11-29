# TODO.md Organization Standards

## Purpose

This document defines the comprehensive standards for organizing and maintaining the `.claude/TODO.md` file, including section hierarchy, checkbox conventions, entry formatting, and artifact inclusion rules.

## Section Hierarchy

The TODO.md file follows a strict 6-section hierarchy that reflects project lifecycle status:

### Section Order (Required)

1. **In Progress** - Actively being worked on
2. **Not Started** - Planned but not yet started
3. **Backlog** - Manually curated ideas and future enhancements
4. **Superseded** - Replaced by newer plans
5. **Abandoned** - Intentionally stopped (with documented reasons)
6. **Completed** - Successfully finished (date-grouped)

### Section Definitions

| Section | Purpose | Auto-Updated | Checkbox |
|---------|---------|--------------|----------|
| In Progress | Plans currently being implemented | Yes | `[x]` |
| Not Started | Plans created but not started | Yes | `[ ]` |
| Backlog | Manually curated future ideas | No (preserved) | None or `[ ]` |
| Superseded | Replaced by newer plans | Yes | `[~]` |
| Abandoned | Intentionally stopped | Yes | `[x]` |
| Completed | Successfully finished | Yes | `[x]` |

## Checkbox Conventions

### Standard Checkboxes

- `[ ]` - Not started (used in "Not Started" section)
- `[x]` - Started, in progress, or complete (used in "In Progress", "Completed", "Abandoned" sections)
- `[~]` - Superseded (used in "Superseded" section)

### Usage Rules

1. **Not Started** section entries MUST use `[ ]` checkbox
2. **In Progress** section entries MUST use `[x]` checkbox
3. **Completed** section entries MUST use `[x]` checkbox
4. **Superseded** section entries MUST use `[~]` checkbox
5. **Abandoned** section entries MUST use `[x]` checkbox
6. **Backlog** section entries may use `[ ]` or no checkbox (manual curation)

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

**Superseded Entry**:
```markdown
- [~] **Make /build persistent** - Superseded by Plan 899 (Build iteration infrastructure) [.claude/specs/881_build_persistent_workflow_refactor/plans/001_build_persistent_workflow_refactor_plan.md] -> See [901_plan_integration_overlap_analysis](specs/901_plan_integration_overlap_analysis/reports/001_plan_integration_overlap_analysis.md)
```

**Abandoned Entry**:
```markdown
- [x] **Error logging infrastructure completion** - Helper functions deemed unnecessary after comprehensive analysis [.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md]
  - **Reason**: Error logging infrastructure already 100% complete across all 12 commands
  - **Alternative**: Focus on Plan 883 (Commands Optimize Refactor) for measurable improvements
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
| `SUPERSEDED` | Superseded |
| `ABANDONED` | Abandoned |

### Fallback Detection

If Status field is missing, detection uses phase markers:
- All phases `[COMPLETE]` -> Completed
- Some phases complete -> In Progress
- No phases complete -> Not Started

## Validation Criteria

The following are checked by validation scripts:

### Structure Validation

- [ ] All 6 sections present in correct order
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

### /todo Command

- Scans specs/ directories
- Classifies plans by status
- Updates TODO.md (preserving Backlog)
- Includes related artifacts

### /build Command

- May update TODO.md on completion
- Moves entries from "Not Started" to "In Progress"
- On completion, moves to "Completed" section

### /plan Command

- Creates new entries in "Not Started" section
- Follows entry format standards

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

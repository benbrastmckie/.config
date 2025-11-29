# /todo Command - Complete Guide

**Executable**: `.claude/commands/todo.md`

**Quick Start**: Run `/todo` to scan projects and update TODO.md with current status.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)
6. [See Also](#see-also)

---

## Overview

### Purpose

The `/todo` command provides two modes for managing the `.claude/TODO.md` project tracking file:

1. **Update Mode** (default): Scans all specs/ directories, classifies plan status, and updates TODO.md with current project status
2. **Clean Mode** (`--clean` flag): Identifies completed projects older than 30 days and generates a cleanup plan for archival

### When to Use

- **Project Status Overview**: Get a current snapshot of all projects across the codebase
- **TODO.md Synchronization**: Keep TODO.md in sync with actual plan file status
- **Completed Project Cleanup**: Generate cleanup plans for old completed projects
- **Artifact Discovery**: Discover related reports and summaries for each project

### When NOT to Use

- **Individual Plan Updates**: Use `/build` to update specific plan status
- **Creating New Plans**: Use `/plan` to create new implementation plans
- **Manual TODO Tracking**: Backlog section is manually curated and preserved

---

## Architecture

### Design Principles

1. **Fast Classification**: Haiku model for batch plan status classification
2. **Backlog Preservation**: Manual Backlog entries are never auto-modified
3. **6-Section Hierarchy**: Consistent organization across all TODO.md files
4. **Artifact Linking**: Automatic discovery and linking of reports/summaries
5. **Date Grouping**: Completed section uses date-grouped entries

### Section Hierarchy

```
## In Progress     [x] checkbox - actively being worked on
## Not Started     [ ] checkbox - planned but not started
## Backlog         Manual curation - preserved by /todo
## Superseded      [~] checkbox - replaced by newer plans
## Abandoned       [x] checkbox - intentionally stopped
## Completed       [x] checkbox - date-grouped entries
```

### Entry Format

```markdown
- [checkbox] **{Plan Title}** - {Brief description} [{path}]
  - {Phase status or key achievements}
  - Related reports: [{report-title}](path/to/report.md)
  - Related summaries: [{summary-title}](path/to/summary.md)
```

### Integration Points

- **Agents**: todo-analyzer (haiku-4.5 for fast batch classification)
- **Library**: `.claude/lib/todo/todo-functions.sh` (>=1.0.0)
- **Error Handling**: `.claude/lib/core/error-handling.sh` (>=1.0.0)
- **Location Detection**: `.claude/lib/core/unified-location-detection.sh` (>=1.0.0)
- **Specs Directory**: `.claude/specs/{NNN_topic}/plans/*.md`
- **Output**: `.claude/TODO.md`

### Data Flow

**Update Mode (Default)**:
1. **Discovery**: Scan specs/ directories for topic folders
2. **Plan Collection**: Find all plan files in each topic's plans/ directory
3. **Classification**: Invoke todo-analyzer agent for batch status classification
4. **Artifact Discovery**: Find related reports/summaries via Glob patterns
5. **Generation**: Generate TODO.md content with proper sections and formatting
6. **Preservation**: Extract and preserve existing Backlog content
7. **Output**: Write updated TODO.md (or display preview if --dry-run)

**Clean Mode**:
1. **Discovery**: Same as Update Mode
2. **Filtering**: Filter completed projects older than 30 days
3. **Plan Generation**: Generate cleanup plan with archive phases
4. **Output**: Write cleanup plan to specs/ for execution via /build

### Hard Barrier Pattern

The `/todo` command uses the **hard barrier subagent delegation pattern** to enforce mandatory delegation to the todo-analyzer agent. This architectural pattern ensures 100% delegation success and prevents the orchestrator from bypassing agent invocation.

**Block Structure**:
```
Block 1: Setup and Discovery
  - Scan specs/ directories
  - Collect plan file paths
  - Initialize state machine

Block 2a: Status Classification Setup
  - State transition to CLASSIFY
  - Pre-calculate paths for subagent
  - Persist variables for verification
  - Checkpoint: "Setup complete - ready for todo-analyzer invocation"

Block 2b: Status Classification Execution [CRITICAL BARRIER]
  - MANDATORY Task tool invocation to todo-analyzer
  - Batch classification of all discovered plans
  - No fallback possible (verification block enforces)

Block 2c: Status Classification Verification
  - Fail-fast if classified results missing
  - Verify file existence, size, JSON validity
  - Count classified plans
  - Checkpoint: "Verification complete - N plans classified"

Block 3: Generate TODO.md
  - State transition to GENERATE
  - Read classified results from Block 2c
  - Generate TODO.md content with proper sections
  - Preserve Backlog content

Block 4: Write TODO.md File
  - State transition to COMPLETE
  - Write TODO.md or display preview (--dry-run)
  - Completion signal
```

**Why Hard Barrier Pattern**:
- **Architectural Compliance**: Consistent with other orchestrator commands (/build, /repair, /errors)
- **100% Delegation**: Structurally impossible to bypass todo-analyzer invocation
- **Reusable Agent**: todo-analyzer can be called from other workflows
- **Fail-Fast**: Verification block catches missing agent outputs immediately
- **Error Recovery**: Checkpoint markers and error logging enable debugging

**Fallback Removal Rationale**:
Previous versions included fallback logic that would bypass the todo-analyzer agent when results were missing. This violated the hard barrier requirement and caused inconsistent classification (e.g., Plans with Status: [COMPLETE] remaining in "In Progress" section). The fallback was removed to enforce architectural compliance.

---

## Usage Examples

### Basic Usage

```bash
# Update TODO.md with current project status
/todo

# Preview changes without modifying files
/todo --dry-run

# Generate cleanup plan for completed projects
/todo --clean

# Preview cleanup plan
/todo --clean --dry-run
```

### Typical Workflow

```bash
# 1. Check current status
/todo --dry-run

# 2. Update if satisfied with preview
/todo

# 3. Review updated TODO.md
cat .claude/TODO.md

# 4. Periodically clean up old completed projects
/todo --clean
/build <cleanup-plan-path>
```

### Integration with Other Commands

```bash
# After completing work with /build
/build specs/plans/001_feature.md
/todo  # Update TODO.md to reflect completion

# After creating new plan with /plan
/plan "New feature description"
/todo  # Update TODO.md to include new plan

# Cleanup workflow
/todo --clean --dry-run    # Preview cleanup candidates
/todo --clean              # Generate cleanup plan
/build <cleanup-plan>      # Execute cleanup
```

---

## Advanced Topics

### Status Classification Algorithm

The todo-analyzer agent uses this algorithm to classify plan status:

```
1. IF Status field contains "[COMPLETE]" OR "100%":
     status = "completed"

2. ELSE IF Status field contains "[IN PROGRESS]":
     status = "in_progress"

3. ELSE IF Status field contains "[NOT STARTED]":
     status = "not_started"

4. ELSE IF Status field contains "SUPERSEDED" OR "DEFERRED":
     status = "superseded"

5. ELSE IF Status field contains "ABANDONED":
     status = "abandoned"

6. ELSE IF Status field is missing:
     # Fallback: Count phase markers
     IF all phases have [COMPLETE]:
       status = "completed"
     ELSE IF any phase has [COMPLETE]:
       status = "in_progress"
     ELSE:
       status = "not_started"
```

### Backlog Preservation

The Backlog section is **never** auto-updated. Content is preserved exactly as-is:

```markdown
## Backlog

**Refactoring Ideas**:
- Retry semantic directory naming
- Implement caching layer

**Future Enhancements**:
- Dark mode support
- Multi-language support
```

This allows manual curation of future ideas, research links, and low-priority items.

### Artifact Discovery

Related artifacts are discovered using these Glob patterns:

```
Reports:    specs/{topic}/reports/*.md
Summaries:  specs/{topic}/summaries/*.md
```

Artifacts are linked in the entry as indented bullets:

```markdown
- [x] **Feature plan** - Implementation completed [path/to/plan.md]
  - All 5 phases complete
  - Related reports: [001-analysis](reports/001-analysis.md)
  - Related summaries: [001-summary](summaries/001-summary.md)
```

### Cleanup Plan Generation

The `--clean` flag generates a 4-phase cleanup plan:

1. **Create Archive Directory**: Prepare archive with manifest
2. **Archive Projects**: Move each completed project directory
3. **Update TODO.md**: Remove archived entries from Completed section
4. **Verification**: Confirm all operations succeeded

Cleanup only targets completed projects older than 30 days.

---

## Troubleshooting

### Common Issues

#### No Projects Found

```
Found 0 topic directories
```

**Cause**: No specs/ directories or no plans in plans/ subdirectories.

**Solution**: Ensure plans are in `specs/{NNN_topic}/plans/*.md` format.

#### Backlog Content Lost

**Cause**: If Backlog section header is missing or malformed.

**Solution**: Ensure `## Backlog` header exists exactly as shown. Backup is created at `TODO.md.backup`.

#### Status Misclassification

**Cause**: Plan missing Status metadata field.

**Solution**: Add explicit Status field to plan metadata:
```markdown
## Metadata
- **Status**: [IN PROGRESS]
```

#### Classification Timeout

**Cause**: Too many plans for single batch classification.

**Solution**: Plans are processed individually in batches. Check for very large specs/ directories.

#### Verification Failure: Classified Results Missing

```
ERROR: VERIFICATION FAILED - Classified results file missing
Expected: /path/to/.claude/tmp/todo_classified_*.json
```

**Cause**: todo-analyzer agent failed to complete or didn't write results file.

**Solution**:
1. Check todo-analyzer agent completion: Look for `PLANS_CLASSIFIED:` signal in output
2. Verify agent has Write tool access in frontmatter
3. Re-run `/todo` command from beginning (Block 2c will fail-fast if agent incomplete)
4. Check error log: `/errors --command /todo --type verification_error`

**Why This Happens**:
The hard barrier pattern enforces mandatory agent delegation. If the todo-analyzer agent doesn't complete successfully, Block 2c verification will fail-fast with recovery instructions. This prevents the command from proceeding with invalid or missing data.

#### Verification Failure: Invalid JSON

```
ERROR: VERIFICATION FAILED - Invalid JSON in classified results
```

**Cause**: todo-analyzer wrote malformed JSON to results file.

**Solution**:
1. Check results file: `cat ~/.claude/tmp/todo_classified_*.json`
2. Verify JSON syntax: `jq empty ~/.claude/tmp/todo_classified_*.json`
3. Review todo-analyzer output format in agent file
4. Re-run `/todo` command (verification ensures data integrity)

### Recovery Options

```bash
# Restore from backup
cp .claude/TODO.md.backup .claude/TODO.md

# Manual validation
bash -c 'source .claude/lib/todo/todo-functions.sh && validate_todo_structure .claude/TODO.md'
```

### Error Log Integration

Check for /todo command errors:

```bash
/errors --command /todo --limit 5
```

---

## See Also

- [TODO Organization Standards](../../reference/standards/todo-organization-standards.md) - Complete TODO.md formatting standards
- [Command Reference](../../reference/standards/command-reference.md#todo) - Quick command reference
- [/plan Command Guide](plan-command-guide.md) - Creating new plans
- [/build Command Guide](build-command-guide.md) - Executing plans
- [todo-analyzer Agent](../../reference/standards/agent-reference.md#todo-analyzer) - Agent used for classification

---

## Navigation

- [Commands Guide Index](README.md)
- [Parent: Guides](../README.md)

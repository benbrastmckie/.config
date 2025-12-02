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
2. **Clean Mode** (`--clean` flag): Identifies all cleanup-eligible projects (Completed and Abandoned sections) and generates a cleanup plan for archival (no age threshold)

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
2. **Section Preservation**: Manual Backlog and Saved entries are never auto-modified
3. **7-Section Hierarchy**: Consistent organization per TODO Organization Standards
4. **Research Auto-Detection**: Auto-populates research-only directories
5. **Artifact Linking**: Automatic discovery and linking of reports/summaries
6. **Date Grouping**: Completed section uses date-grouped entries

### Section Hierarchy

```
## In Progress     [x] checkbox - actively being worked on
## Not Started     [ ] checkbox - planned but not started
## Research        [ ] checkbox - research-only directories (auto-detected)
## Saved           [ ] checkbox - manually demoted items (preserved)
## Backlog         [ ] checkbox - manual prioritization queue (preserved)
## Abandoned       [x]/[~] checkbox - intentionally stopped or superseded
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

**Clean Mode** (Section-Based):
1. **TODO.md Parsing**: Parse TODO.md directly to extract entries from Completed and Abandoned sections
2. **Section-Based Filtering**: Extract topic numbers from TODO.md entries (not plan file classification)
3. **Directory Mapping**: Map topic numbers to existing specs/ directories
4. **Direct Execution**: Create git commit, verify uncommitted changes, remove eligible directories
5. **Output**: Display execution summary with git commit hash and recovery instructions

**Research Auto-Detection**:
- Scans specs/ for directories with reports/ but no plans/ (or empty plans/)
- Extracts title/description from first report file
- Adds entry to Research section linking to directory
- Typical use case: /research and /errors command outputs

**Key Insight**: Clean mode honors manual categorization in TODO.md (e.g., moving a plan to Abandoned section) rather than relying on plan file metadata. This ensures user intent is respected during cleanup.

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

# Generate cleanup plan for eligible projects (Completed, Abandoned, Superseded)
/todo --clean

# Preview cleanup plan (dry-run)
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

# 4. Periodically clean up eligible projects (Completed, Abandoned, Superseded)
/todo --clean
/build <cleanup-plan-path>
/todo  # Rescan to update TODO.md after cleanup
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
/todo --clean --dry-run    # Preview cleanup candidates (Completed, Abandoned, Superseded)
/todo --clean              # Generate cleanup plan (no age filtering)
/build <cleanup-plan>      # Execute cleanup (git verification, archive, removal)
/todo                      # Rescan to update TODO.md
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

### Direct Cleanup Execution (Section-Based)

The `--clean` flag directly removes eligible project directories after creating a mandatory git commit for recovery:

**Section-Based Approach**: Cleanup parses TODO.md sections directly rather than relying on plan file classification. This means:
- Manual categorization in TODO.md is honored (e.g., moving a plan to Abandoned section triggers cleanup)
- No dependency on plan file `**Status**:` metadata field
- Entries missing from TODO.md (already removed) are skipped automatically

**Execution Steps**:
1. **Parse TODO.md**: Extract all entries from Completed, Abandoned, and Superseded sections
2. **Extract Topic Numbers**: Parse topic numbers from entry format (`**Title (NNN)**`) or plan path (`specs/NNN_topic/`)
3. **Map Directories**: Find existing specs/ directories matching topic numbers
4. **Git Commit**: Create pre-cleanup snapshot with message "chore: pre-cleanup snapshot before /todo --clean (N projects)"
5. **Uncommitted Check**: Skip directories with uncommitted changes
6. **Directory Removal**: Remove eligible project directories
7. **Summary**: Display removal counts (removed, skipped, failed) and git commit hash

**Target Sections**: Completed, Abandoned, and Superseded entries in TODO.md
**Age Filtering**: None - all entries in target sections are included regardless of age
**TODO.md**: Preserved and NOT modified during cleanup (re-run `/todo` after cleanup to update)
**Recovery**: Use `git revert <commit-hash>` to restore removed directories

**Manual Categorization Workflow**:
```bash
# 1. Manually move a plan to Abandoned section in TODO.md
# 2. Add reason note under the entry
# 3. Run cleanup to remove it
/todo --clean
# 4. Rescan to update TODO.md
/todo
```

**Standard Cleanup Workflow**:
1. `/todo --clean --dry-run` - Preview cleanup candidates (grouped by section)
2. `/todo --clean` - Execute cleanup with git commit
3. `/todo` - Rescan and update TODO.md

**Recovery Workflow** (if needed):
1. Get commit hash from cleanup output
2. `git revert <commit-hash>` - Restore all removed directories
3. Resolve any merge conflicts (unlikely)
4. `/todo` - Rescan to update TODO.md

### Clean Mode Output Format

The `/todo --clean` command produces a standardized 4-section console summary (matching /plan and /build output format):

**Example Output**:
```
=== /todo --clean Complete ===

Summary: Removed 193 eligible projects after git commit a1b2c3d4. Skipped 2 projects with uncommitted changes. Failed: 0.

Artifacts:
  📝 Git Commit: a1b2c3d4567890abcdef1234567890abcdef1234
  ✓ Removed: 193 projects
  ⚠ Skipped: 2 projects (uncommitted changes)
  ✗ Failed: 0 projects

Next Steps:
  • Rescan projects: /todo
  • Review changes: git show a1b2c3d4
  • View commit log: git log --oneline -5
  • Recovery (if needed): git revert a1b2c3d4

CLEANUP_COMPLETED: removed=193 skipped=2 failed=0 commit=a1b2c3d4567890abcdef1234567890abcdef1234
```

**Output Sections**:
1. **Summary**: Execution results (removed count, git commit hash, skipped/failed counts)
2. **Artifacts**: Git commit hash and removal statistics
3. **Next Steps**: Four actionable commands (rescan, review, log, recovery)
4. **Completion Signal**: `CLEANUP_COMPLETED: removed=N skipped=N failed=N commit=<hash>` for orchestrator parsing

**Dry-Run Preview Output** (Section-Based):
```
=== Cleanup Preview (Dry Run) ===

Eligible projects: 40

Cleanup candidates (grouped by section):

Completed (22 projects):
  - 965_optimize_plan_command_performance
  - 787_state_machine_persistence_bug
  - 822_quick_reference_integration
  - 918_topic_naming_standards_kebab_case
  ... (12 more)

Abandoned (14 projects):
  - 902_error_logging_infrastructure_completion
  - 122_revise_errors_repair
  - 799_coordinate_command_all_its_dependencies_order
  - 805_when_plans_created_command_want_metadata_include
  ... (4 more)

Superseded (4 projects):
  - 848_when_using_claude_code_neovim_greggh_plugin
  - 881_build_persistent_workflow_refactor
  - 885_repair_plans_research_analysis
  - 884_build_error_logging_discrepancy

To execute cleanup (with git commit), run: /todo --clean
```

**Default Mode Output**:
```
=== /todo Complete ===

Summary: Scanned 245 project directories and updated TODO.md with current status. Projects organized by status: In Progress, Not Started, Backlog, Superseded, Abandoned, Completed.

Artifacts:
  📄 TODO.md: /home/user/.config/.claude/TODO.md

Next Steps:
  • Review changes: cat /home/user/.config/.claude/TODO.md
  • Generate cleanup plan: /todo --clean
  • Preview cleanup: /todo --clean --dry-run

TODO_UPDATED: /home/user/.config/.claude/TODO.md
```

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

**Solution**: Ensure `## Backlog` header exists exactly as shown. Git snapshot created before update.

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

The `/todo` command creates git commits before modifying TODO.md. To recover:

**View Recent Changes**:
```bash
git log --oneline -5 .claude/TODO.md
```

**Restore Previous Version**:
```bash
# Find the snapshot commit (message starts with "chore: snapshot TODO.md")
git log --oneline .claude/TODO.md

# Restore from that commit
git checkout <commit-hash> -- .claude/TODO.md
```

**Common Scenarios**:

1. **Undo last /todo update**: `git checkout HEAD~1 -- .claude/TODO.md`
2. **Compare current vs previous**: `git diff HEAD~1 .claude/TODO.md`
3. **Restore specific section**: View diff, manually cherry-pick changes

**Manual Validation** (after recovery):
```bash
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

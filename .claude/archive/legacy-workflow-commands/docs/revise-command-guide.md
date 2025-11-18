# /revise Command - Complete Guide

**Executable**: `.claude/commands/revise.md`

**Quick Start**: Run `/revise "description of changes"` to revise the most recent plan.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

The `/revise` command modifies implementation plans or research reports according to user-provided details. It creates backups, applies changes systematically, and preserves completion markers for already-executed phases.

### When to Use

- Updating plans after scope changes
- Adding new phases or tasks
- Modifying existing phase details
- Incorporating feedback from reviews
- Adjusting estimates or dependencies

### When NOT to Use

- Executing implementation code (use `/implement`)
- Running tests (use project test commands)
- Creating new plans from scratch (use `/plan`)
- Deleting entire plans (manual file deletion)

---

## Architecture

### Design Principles

- **Non-destructive**: Always creates backups before modifications
- **Preservation**: Maintains completion markers for executed phases
- **Dual Mode**: Interactive (default) or automated (for workflows)

### Patterns Used

- Backup-before-modify pattern
- Revision history tracking
- Auto-mode for programmatic usage

### Integration Points

- **list command**: Find available plans
- **expand command**: Expand revised phases if complexity increases
- **research reports**: Can revise reports as well as plans
- **coordinate workflow**: Uses auto-mode for adaptive planning

### Data Flow

```
User Request → Mode Detection → Plan Discovery → Backup Creation
                                                       ↓
      Completion ← History Update ← Change Application ← Verification
```

---

## Usage Examples

### Example 1: Interactive Mode (Default)

```bash
/revise "Add authentication logging to Phase 3"
```

**Expected Output**:
```
PROGRESS: Mode: Interactive
PROGRESS: Finding most recent plan...
PROGRESS: Found: specs/027_auth/plans/027_auth_plan.md
PROGRESS: Creating backup...
PROGRESS: Applying revision...
REVISION_COMPLETE: Plan updated successfully
Backup: specs/027_auth/plans/027_auth_plan.backup_20231101_143022.md
```

**Explanation**:
Interactive mode finds the most recent plan, creates a backup, and applies the requested changes.

### Example 2: With Research Context

```bash
/revise "Incorporate performance findings" /path/to/reports/perf_analysis.md
```

**Expected Output**:
```
PROGRESS: Loading context from report...
PROGRESS: Extracting relevant findings...
PROGRESS: Applying to plan Phase 4...
REVISION_COMPLETE: Plan updated with context
```

**Explanation**:
The revise command can use research reports as context to inform the changes.

### Example 3: Auto-Mode (For Workflows)

```bash
/revise "Add retry logic" --auto-mode --context '{"revision_type":"add_phase","phase_number":5,"reason":"resilience"}'
```

**Expected Output**:
```json
{
  "status": "success",
  "revision_type": "add_phase",
  "phase_number": 5,
  "backup_path": "specs/027_auth/plans/027_auth_plan.backup_*.md"
}
```

**Explanation**:
Auto-mode provides JSON input/output for programmatic usage in workflows like adaptive planning.

### Example 4: Revise Specific Phase

```bash
/revise "Update Phase 2 testing approach to include integration tests"
```

**Expected Output**:
```
PROGRESS: Identifying Phase 2...
PROGRESS: Current tasks: 8, Adding: 3
PROGRESS: Updating testing section...
REVISION_COMPLETE: Phase 2 updated
```

**Explanation**:
Specify the phase in your revision description to target specific sections.

---

## Advanced Topics

### Performance Considerations

- Backup creation adds minimal overhead
- Large plans (1000+ lines) take slightly longer
- Auto-mode optimized for workflow integration

### Revision Types (Auto-Mode)

- `add_phase`: Add new phase
- `modify_phase`: Update existing phase
- `add_tasks`: Add tasks to phase
- `update_estimates`: Change time/complexity estimates
- `update_dependencies`: Modify phase dependencies

### Backup Strategy

- Backups created with timestamp suffix
- Format: `{plan_name}.backup_{YYYYMMDD_HHMMSS}.md`
- Located in same directory as plan
- Manual cleanup recommended periodically

### Preserving Completion Status

The revise command preserves:
- `[x]` markers for completed tasks
- Phase completion status
- Git commit references
- Checkpoint information

### Auto-Mode Context JSON

```json
{
  "revision_type": "add_phase",
  "phase_number": 5,
  "reason": "Adding deployment phase",
  "phase_content": "Optional phase content",
  "dependencies": [3, 4]
}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: No Plan Found

**Symptoms**:
- "No recent plan found" error
- Command completes with no changes

**Cause**:
No plans in specs directory or path incorrect

**Solution**:
```bash
# List available plans
/list plans

# Check specs directory
ls -la .claude/specs/*/plans/
```

#### Issue 2: Backup Creation Failed

**Symptoms**:
- "Failed to create backup" error
- Revision aborted

**Cause**:
Permission issues or disk space

**Solution**:
```bash
# Check permissions
ls -la $(dirname <plan-path>)

# Check disk space
df -h .
```

#### Issue 3: Invalid Auto-Mode JSON

**Symptoms**:
- "Invalid JSON - missing revision_type" error
- Auto-mode fails immediately

**Cause**:
Malformed JSON context

**Solution**:
```bash
# Validate JSON
echo '{"revision_type":"add_phase"}' | jq .

# Check required fields
# - revision_type (required)
# - phase_number (optional)
# - reason (optional)
```

#### Issue 4: Completed Phase Modified

**Symptoms**:
- Warning about modifying completed phase
- Completion markers may be affected

**Cause**:
Revising a phase marked as complete

**Solution**:
```bash
# Review phase status before revision
grep "\[x\]" <plan-path> | wc -l

# Be explicit about preserving status
/revise "Update Phase 2 (preserve completion status)"
```

### Debug Mode

Check revision history in the plan:
```bash
# View revision history section
grep -A 20 "## Revision History" <plan-path>
```

### Getting Help

- Check [Command Reference](.claude/docs/reference/command-reference.md) for quick syntax
- Review [Adaptive Planning Guide](.claude/docs/workflows/adaptive-planning-guide.md) for auto-mode usage
- See related commands: `/plan`, `/expand`, `/implement`

---

## See Also

- [Adaptive Planning Guide](.claude/docs/workflows/adaptive-planning-guide.md)
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md)
- [Command Reference](.claude/docs/reference/command-reference.md)

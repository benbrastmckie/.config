# Backup Patterns Analysis Report

## Research Objective
Identify all code locations creating `.backup` files for TODO.md and document the current backup strategy for migration to git-based recovery.

## Research Status
- **Status**: Complete
- **Complexity**: 3
- **Created**: 2025-12-01
- **Completed**: 2025-12-01

## Executive Summary

The codebase uses two distinct backup strategies:
1. **File-based backups** - Creates `.backup` and `.backup-TIMESTAMP` files (83+ files currently exist)
2. **Git-based backups** - Used by `/todo --clean` mode for pre-cleanup snapshots

The /todo command creates TODO.md backups in Block 3 (lines 700-710) using workflow-scoped naming (`TODO.md.backup_${WORKFLOW_ID}`). Additionally, the library function `update_todo_file()` creates simple `.backup` files. This dual backup strategy should be replaced with git commits for better recovery and cleaner filesystem.

## Findings

### 1. TODO.md Backup Creation Locations

#### Primary Location: /todo Command Block 3
**File**: `/home/benjamin/.config/.claude/commands/todo.md`
**Lines**: 700-710

```bash
# === BACKUP CURRENT TODO.md ===
if [ -f "$TODO_PATH" ]; then
  echo "Creating backup: $BACKUP_TODO_PATH"
  cp "$TODO_PATH" "$BACKUP_TODO_PATH"

  # Keep only 5 most recent backups
  BACKUP_DIR=$(dirname "$BACKUP_TODO_PATH")
  BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}/TODO.md.backup_"* 2>/dev/null | wc -l)
  if [ "$BACKUP_COUNT" -gt 5 ]; then
    echo "Cleaning old backups (keeping 5 most recent)"
    ls -1t "${BACKUP_DIR}/TODO.md.backup_"* | tail -n +6 | xargs rm -f
  fi
else
  echo "No existing TODO.md to backup (first run)"
fi
```

**Backup Pattern**: `${TODO_PATH}.backup_${WORKFLOW_ID}`
**Example**: `.claude/TODO.md.backup_todo_1764634696`
**Retention**: Keep 5 most recent backups, auto-delete older ones

#### Secondary Location: todo-functions.sh Library
**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`
**Lines**: 958-961

```bash
# update_todo_file() function
if [ -f "$todo_path" ]; then
  cp "$todo_path" "${todo_path}.backup"
fi
```

**Backup Pattern**: `${TODO_PATH}.backup` (simple, no timestamp)
**Example**: `.claude/TODO.md.backup`
**Retention**: Overwritten on each run (single backup)

### 2. Existing Git-Based Backup Precedent

The `/todo --clean` mode already uses git commits for recovery:

**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`
**Function**: `create_cleanup_git_commit()` (lines 1316-1349)

```bash
create_cleanup_git_commit() {
  local project_count="${1:-0}"

  # Stage all changes
  if ! git add . 2>/dev/null; then
    echo "ERROR: Failed to stage changes for git commit" >&2
    return 1
  fi

  # Create commit with standardized message
  local commit_message="chore: pre-cleanup snapshot before /todo --clean (${project_count} projects)"
  if ! git commit -m "$commit_message" 2>/dev/null; then
    # ...error handling...
  fi

  # Get commit hash
  COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
  echo "Created pre-cleanup commit: $COMMIT_HASH"
  echo "Recovery command: git revert $COMMIT_HASH"
  return 0
}
```

**Usage**: Called in `execute_cleanup_removal()` before removing project directories
**Commit Message Format**: `chore: pre-cleanup snapshot before /todo --clean (N projects)`
**Recovery Method**: `git revert $COMMIT_HASH`

This demonstrates that git-based recovery is already proven and working in production for the cleanup workflow.

### 3. Backup File Inventory

Current backup files on filesystem:

```
/home/benjamin/.config/.claude/TODO.md.backup                    (3.2K, simple backup)
/home/benjamin/.config/.claude/TODO.md.backup_todo_1764628443    (2.0K, workflow-scoped)
/home/benjamin/.config/.claude/TODO.md.backup_todo_1764634696    (2.8K, workflow-scoped)
```

**Total backup files in .claude/**: 83 files
**Categories**:
- TODO.md backups: 3 files
- Error log backups: 7+ files (`.jsonl.backup_TIMESTAMP`)
- Checkpoint backups: 10+ files (`.json.backup`)
- Spec backups: 20+ files (`.md.backup-TIMESTAMP`)

### 4. Backup Utility Libraries

Two utility scripts exist for file-based backups:

#### backup-command-file.sh
**Path**: `/home/benjamin/.config/.claude/lib/util/backup-command-file.sh`
**Purpose**: Create timestamped backups before editing
**Format**: `<file>.backup-YYYYMMDD_HHMMSS`
**Features**:
- Integrity verification (size and SHA256 checksum)
- Logging to `backup-operations.log`
- Used for command file modifications

#### rollback-command-file.sh
**Path**: `/home/benjamin/.config/.claude/lib/util/rollback-command-file.sh`
**Purpose**: Restore previous backup
**Features**:
- Creates safety backup before rollback
- Verification of restored file integrity
- Logging of rollback operations

These utilities are primarily for command files, not TODO.md.

### 5. Documentation References

#### Backup Policy Document
**Path**: `/home/benjamin/.config/.claude/docs/reference/templates/backup-policy.md`

Key sections:
- **Retention Guidelines**: Defines retention periods for different file types
- **Backup Best Practices**: States "Git is primary backup" (line 222)
- **Quote**: "Backups are temporary safety net, git is permanent history"

This document already establishes the principle that git should be the primary backup mechanism.

#### Related Documentation
Files mentioning backup strategies:
- `.claude/docs/concepts/directory-protocols.md`
- `.claude/docs/workflows/spec_updater_guide.md`
- `.claude/docs/workflows/development-workflow.md`
- `.claude/docs/guides/patterns/revision-specialist-agent-guide.md`

### 6. Other Backup Patterns in Codebase

**Plan Architect Agent** (`.claude/agents/plan-architect.md:292`):
```bash
cp "$EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH.backup.$(date +%Y%m%d_%H%M%S)"
```

**Checkpoint Utils** (`.claude/lib/workflow/checkpoint-utils.sh`):
- Creates `.backup` files for checkpoint JSON files
- Used for workflow state recovery

**Test Files**:
- `.claude/tests/features/compliance/test_bash_error_integration.sh:33`
- Creates backups of error log for test isolation

## Analysis

### Why File-Based Backups Were Used

1. **Atomic Operations**: Immediate recovery without git commands
2. **Workflow Isolation**: Each workflow gets its own backup
3. **Simple Implementation**: Standard `cp` command
4. **No Git Dependency**: Works even if git is not available

### Problems with Current Approach

1. **Filesystem Clutter**: 83+ backup files scattered across directories
2. **Manual Cleanup**: Requires manual or scripted cleanup (limited to 5 most recent)
3. **Inconsistent Naming**: Two different patterns (`.backup` vs `.backup_${WORKFLOW_ID}`)
4. **No History**: File backups don't preserve change history
5. **No Context**: Backups lack information about why they were created
6. **Redundant**: Git already tracks all changes

### Advantages of Git-Based Backups

1. **Built-in History**: Full change tracking with commit messages
2. **Clean Filesystem**: No backup file clutter
3. **Rich Context**: Commit messages explain what changed and why
4. **Better Recovery**: Can view diffs, cherry-pick changes, etc.
5. **Already Working**: `/todo --clean` proves git-based recovery works
6. **Standards Aligned**: Matches existing backup-policy.md guidelines

## Recommendations

### 1. Migration Strategy

**Phase 1**: Replace file-based backups in /todo command
- Remove backup creation in Block 3 (lines 700-710)
- Add git commit before TODO.md modification
- Update error recovery instructions to use git

**Phase 2**: Update todo-functions.sh library
- Remove `cp "$todo_path" "${todo_path}.backup"` from `update_todo_file()`
- Ensure callers use git commits instead

**Phase 3**: Update documentation
- Revise backup-policy.md to deprecate file-based backups for TODO.md
- Update todo-command-guide.md recovery instructions
- Add git-based recovery examples

**Phase 4**: Cleanup existing backups
- Remove existing TODO.md.backup* files after verification
- Update .gitignore to prevent future backup file commits (if needed)

### 2. Proposed Git Commit Pattern

Following the existing `/todo --clean` pattern:

```bash
# Before modifying TODO.md
if ! git diff --quiet .claude/TODO.md 2>/dev/null; then
  git add .claude/TODO.md
  git commit -m "chore: snapshot TODO.md before /todo update

Preserving current state for recovery if needed.

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${USER_ARGS}"
fi
```

**Commit Message Format**:
- Type: `chore:` (non-functional change)
- Scope: Snapshot/backup operations
- Body: Include workflow context

**Recovery Command**: `git revert <commit-hash>` or `git checkout <commit-hash> -- .claude/TODO.md`

### 3. Standards Updates Required

#### Files to Update:

1. **`.claude/docs/reference/templates/backup-policy.md`**
   - Add section: "Git-Based Backup for TODO.md"
   - Deprecate file-based backups for TODO.md
   - Document git commit pattern and recovery commands

2. **`.claude/docs/guides/commands/todo-command-guide.md`**
   - Update recovery section (line 484 currently shows `cp .claude/TODO.md.backup`)
   - Replace with git-based recovery examples
   - Add troubleshooting for git recovery scenarios

3. **`.claude/docs/reference/standards/code-standards.md`**
   - Add guideline: "Use git commits for TODO.md backups"
   - Reference backup-policy.md for details

4. **Create new guide**: `.claude/docs/guides/recovery/git-based-recovery.md`
   - Document git recovery patterns for all file types
   - Include examples for TODO.md, plans, command files
   - Common recovery scenarios and troubleshooting

### 4. Implementation Checklist

- [ ] Remove backup creation in `/todo` command Block 3
- [ ] Add git commit before TODO.md modification
- [ ] Remove `cp` backup in `update_todo_file()` function
- [ ] Update BACKUP_TODO_PATH variable usage (remove or repurpose)
- [ ] Update error messages referencing backup files
- [ ] Add git commit error handling
- [ ] Test recovery scenarios (revert, checkout)
- [ ] Update documentation (4 files listed above)
- [ ] Clean up existing TODO.md.backup* files
- [ ] Update .gitignore if needed

## Conclusion

The current file-based backup strategy for TODO.md is redundant given that:
1. All changes are already tracked in git
2. The `/todo --clean` workflow successfully uses git commits for recovery
3. Project standards (backup-policy.md) state "git is permanent history"

Migrating to git-based backups will:
- Eliminate 3+ backup files per TODO.md update
- Provide better recovery with full commit history
- Align with existing standards and proven patterns
- Reduce filesystem clutter (83+ backup files currently exist)

The migration is low-risk because:
- Git-based recovery is already proven in `/todo --clean`
- Changes are isolated to 2 code locations (command + library)
- Documentation updates are straightforward
- Rollback is possible via git revert

**Next Step**: Create implementation plan for migration to git-based TODO.md backups.


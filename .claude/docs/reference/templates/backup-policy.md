# Backup File Retention Policy

## Overview

Automated backups are created when modifying critical command files, plans, and configuration. This policy defines retention guidelines for backup files.

## Git-Based Backup for TODO.md

**Status**: Standard (as of 2025-12-01)

The `/todo` command uses git commits for backup instead of file-based backups:

**Backup Pattern**:
- Automatic git commit created before TODO.md modification
- Commit only created if uncommitted changes exist
- Commit message includes workflow context and command arguments

**Commit Message Format**:
```
chore: snapshot TODO.md before /todo update

Preserving current state for recovery if needed.

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${ARGS}
```

**Recovery Commands**:
```bash
# View recent TODO.md commits
git log --oneline .claude/TODO.md

# Restore TODO.md from specific commit
git checkout <commit-hash> -- .claude/TODO.md

# Revert entire TODO.md update commit
git revert <commit-hash>

# View diff between current and previous version
git diff HEAD~1 .claude/TODO.md
```

**Deprecation Notice**:
File-based backups (`.backup`, `.backup_${WORKFLOW_ID}`) are deprecated for TODO.md as of 2025-12-01. Git provides superior recovery with full history and context.

## Backup File Naming Convention

All backup files follow this naming pattern:
```
{original_filename}.backup-{YYYYMMDD}_{HHMMSS}
```

Examples:
- `coordinate.md.backup-20251027_144342`
- `001_unified_implementation_plan.md.backup-20251027_134544`

## Retention Guidelines

### Critical Command Files (`.claude/commands/`)

**Files**: `/orchestrate`, `/coordinate`, `/research`, `/supervise`, etc.

**Retention Policy**:
- Keep most recent backup: **Permanent** (until next major refactor)
- Keep backups from successful fixes: **30 days**
- Remove backups after verification period

**Rationale**: Command files are complex orchestration scripts. Keeping recent backups enables quick rollback if issues discovered.

**Verification Period**: 7-14 days of production use

### Implementation Plans (`.claude/specs/NNN_topic/plans/`)

**Retention Policy**:
- Keep plan file backups: **Until plan completion**
- Remove after implementation summary created
- Keep one backup if plan archived for reference

**Rationale**: Plans are iteratively refined. Backups enable rollback during active development. Once complete and summarized, original plan serves as historical record.

### Agent Files (`.claude/agents/`)

**Retention Policy**:
- Keep most recent backup: **Permanent**
- Keep backups from behavior changes: **30 days**

**Rationale**: Agent behavioral files define execution patterns. Preserve ability to rollback behavioral changes.

### Library Files (`.claude/lib/`)

**Retention Policy**:
- Keep most recent backup: **Permanent**
- Keep backups from API changes: **60 days**

**Rationale**: Library API changes affect multiple commands. Longer retention enables diagnosis of cascading failures.

## Current Backups (Spec 497)

### Command File Backups

Created during Phases 1-3 (2025-10-27):

```
.claude/commands/coordinate.md.backup-20251027_144342  (Phase 1 start - 86K)
.claude/commands/coordinate.md.backup-20251027_144901  (Phase 1 end - 86K)
.claude/commands/supervise.md.backup-20251027_150123   (Phase 2 - 75K)
.claude/commands/research.md.backup-20251027_151656    (Phase 3 - 27K)
```

**Changes Made**:
- **coordinate.md**: Fixed 9 agent invocations (YAML → imperative)
- **research.md**: Fixed 3 agent invocations + ~10 bash blocks
- **supervise.md**: Enhanced error handling, removed fallbacks

**Verification Status** (2025-10-27):
- All 12 tests passing in unified test suite
- Delegation rate >90% for all three commands
- File creation reliability 100%
- Zero TODO files created after fixes

**Retention Decision**:
- **Keep until**: 2025-11-10 (14 days verification period)
- **Remove after**: Confirmation no regression in production use
- **Keep one backup**: Most recent per command (permanent)

### Plan File Backups

Created during plan revisions:

```
.claude/specs/497.../001_unified_implementation_plan.md.backup-20251027_134544  (Revision 1)
.claude/specs/497.../001_unified_implementation_plan.md.backup-rev2-20251027_135741  (Revision 2)
.claude/specs/497.../001_unified_implementation_plan.md.backup-20251027_143300  (Pre-Phase 1)
```

**Revisions**:
- Revision 1: Simplified Phase 2 (removed startup marker)
- Revision 2: Restored fallback removal tasks
- Pre-Phase 1: Backup before implementation started

**Retention Decision**:
- **Remove after**: Implementation summary created
- **Phase Status**: Phase 5 in progress (documentation phase)
- **Keep until**: Summary document complete

## Cleanup Commands

### List All Backups

```bash
# List all backup files with sizes
find . -name "*.backup-*" -ls

# Count backups by directory
find . -name "*.backup-*" -type f | cut -d/ -f1-5 | sort | uniq -c

# Total size of backups
find . -name "*.backup-*" -exec du -ch {} + | grep total$
```

### Remove Expired Backups

```bash
# Remove backups older than 30 days
find . -name "*.backup-*" -mtime +30 -delete

# Remove specific backup
rm .claude/commands/coordinate.md.backup-20251027_144342

# Remove all backups for spec 497 (after completion)
rm .claude/specs/497_*/plans/*.backup-*
rm .claude/commands/*.backup-20251027_*
```

### Archive Backups (Alternative to Deletion)

```bash
# Create archive directory
mkdir -p .claude/data/backups/archived/

# Move old backups to archive
find . -name "*.backup-*" -mtime +30 -exec mv {} .claude/data/backups/archived/ \;

# Compress archived backups
tar -czf .claude/data/backups/spec497_backups.tar.gz .claude/data/backups/archived/*.backup-20251027_*
```

## Rollback Procedures

### Rolling Back Command File

If issues discovered after implementation:

```bash
# 1. Identify backup to restore
ls -lah .claude/commands/coordinate.md.backup-*

# 2. Compare current with backup
diff .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-20251027_144342

# 3. Restore backup
cp .claude/commands/coordinate.md.backup-20251027_144342 .claude/commands/coordinate.md

# 4. Verify rollback
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md

# 5. Test command
/coordinate "test workflow" --dry-run
```

### Rolling Back Plan File

```bash
# 1. Restore previous plan version
cp .claude/specs/497.../001_unified_implementation_plan.md.backup-20251027_134544 \
   .claude/specs/497.../001_unified_implementation_plan.md

# 2. Review changes
git diff .claude/specs/497.../001_unified_implementation_plan.md
```

## Backup Verification

Before removing backups, verify:

1. **Tests passing**: `.claude/tests/test_orchestration_commands.sh` all pass
2. **Production use**: Commands used successfully for 7-14 days
3. **No regressions**: No new issues reported
4. **Git committed**: Changes committed to version control
5. **Summary created**: Implementation summary documents changes

## Automated Cleanup

### Cron Job (Optional)

```bash
# Add to crontab (runs monthly)
0 0 1 * * find /home/benjamin/.config/.claude -name "*.backup-*" -mtime +30 -delete
```

### Git Hook (Pre-Commit)

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Warn about uncommitted backups

backup_count=$(find .claude -name "*.backup-*" -type f | wc -l)
if [ "$backup_count" -gt 0 ]; then
  echo "Warning: $backup_count backup files found"
  echo "Consider cleaning up after verifying changes"
fi
```

## Backup Best Practices

1. **Always backup before edits**: Use `.claude/lib/util/backup-command-file.sh`
2. **Test after restore**: Run validation and tests after rollback
3. **Document retention decisions**: Note why keeping or removing
4. **Archive before deletion**: Compress old backups rather than delete immediately
5. **Git is primary backup**: Backups are temporary safety net, git is permanent history

## References

- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Backup procedures
- [Orchestration Troubleshooting Guide](../guides/orchestration/orchestration-troubleshooting.md) - Rollback scenarios
- Backup utility: `.claude/lib/util/backup-command-file.sh`
- Rollback utility: `.claude/lib/util/rollback-command-file.sh`

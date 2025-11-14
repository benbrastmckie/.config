# Troubleshooting: Duplicate Slash Commands

## Problem Description

Multiple entries appear for the same slash command in Claude Code autocomplete, causing confusion and showing different versions of the same command.

## Symptoms

- Typing `/command-name` shows TWO entries in autocomplete
- One entry labeled "(user)", another labeled "(project)"
- Descriptions may differ between the two entries
- Command may behave differently depending on which entry is selected
- Missing features or flags in one version vs the other

## Root Cause

Claude Code searches for custom slash commands in two locations:

1. **Project-level**: `.claude/commands/` (repository root)
   - Team-shared, version-controlled
   - Shows "(project)" label
2. **Personal-level**: `~/.claude/commands/` (user home directory)
   - Individual, cross-project use
   - Shows "(user)" label

**Important**: Claude Code does NOT prioritize one over the other. If both locations have a command with the same name, BOTH will appear in autocomplete. The official documentation states: "Conflicts between user and project level commands are not supported."

## Common Scenarios

### Scenario 1: Outdated User-Level Command

**Situation**: You copied project commands to `~/.claude/commands/` for personal use, but the project commands have since been updated.

**Result**: User-level commands become outdated and conflict with newer project-level versions.

**Example**: The `/setup` command was refactored from 2206 lines to 311 lines (86% reduction) following executable/documentation separation pattern. User-level copy remained at old 2206-line version, missing new flags like `--validate` and `--enhance-with-docs`.

### Scenario 2: Experimental User Command

**Situation**: You created a user-level command to test ideas before committing to project.

**Result**: After committing to project, both versions exist.

### Scenario 3: Systematic Duplication

**Situation**: Many or all project commands were copied to user-level directory at once.

**Result**: Widespread duplicates affecting multiple commands (25+ in the discovered case).

## Solution Steps

### Step 1: Identify Duplicate Commands

```bash
# List user-level commands
ls -la ~/.claude/commands/

# List project-level commands
ls -la .claude/commands/

# Find commands present in both locations
comm -12 <(ls ~/.claude/commands/ | grep '.md$' | sort) <(ls .claude/commands/ | grep '.md$' | sort)
```

### Step 2: Compare Versions

```bash
# Compare specific command
diff ~/.claude/commands/command-name.md .claude/commands/command-name.md

# Check file sizes
wc -l ~/.claude/commands/command-name.md .claude/commands/command-name.md

# Compare metadata (argument hints, descriptions)
grep -E "^(argument-hint|description|allowed-tools):" ~/.claude/commands/command-name.md .claude/commands/command-name.md
```

### Step 3: Determine Which to Keep

**Decision Matrix**:

| Criteria | Keep User-Level | Keep Project-Level |
|----------|----------------|-------------------|
| Latest features | ❌ Usually outdated | ✅ Current version |
| Team consistency | ❌ Personal only | ✅ Team-shared |
| Version control | ❌ Not tracked | ✅ Git tracked |
| Updates | ❌ Manual sync | ✅ Auto via git pull |

**Recommendation**: In most cases, keep the project-level command and remove the user-level duplicate.

### Step 4: Backup and Remove

```bash
# Create backup with timestamp
cp ~/.claude/commands/command-name.md ~/.claude/commands/command-name.md.backup-$(date +%Y%m%d)

# Remove user-level command
rm ~/.claude/commands/command-name.md

# Verify removal
ls ~/.claude/commands/command-name.md  # Should show "No such file"
```

### Step 5: Verify Fix

After Claude Code reloads commands (automatic or restart):

1. Type `/command-name` in Claude Code
2. Verify ONLY ONE entry appears in autocomplete
3. Confirm it shows the expected label ("(project)" or "(user)")
4. Test command execution to ensure it works
5. Verify all expected flags/features are present

## Rollback Procedure

If issues arise after removing a command:

```bash
# Restore from backup
mv ~/.claude/commands/command-name.md.backup-YYYYMMDD ~/.claude/commands/command-name.md

# Restart Claude Code to reload commands
```

## Systematic Cleanup (Multiple Duplicates)

If you have many duplicates (25+ commands), use this approach:

### Option A: Remove All User-Level Commands

If you don't use user-level commands for cross-project functionality:

```bash
# Backup entire directory
cp -r ~/.claude/commands ~/.claude/commands.backup-$(date +%Y%m%d)

# Remove all user-level commands
rm ~/.claude/commands/*.md

# Keep backup for rollback
```

### Option B: Selective Removal

Keep only truly personal commands that don't conflict with project commands:

```bash
# Backup first
cp -r ~/.claude/commands ~/.claude/commands.backup-$(date +%Y%m%d)

# Find duplicates
comm -12 <(ls ~/.claude/commands/ | grep '.md$' | sort) <(ls .claude/commands/ | grep '.md$' | sort) > duplicates.txt

# Review duplicates
cat duplicates.txt

# Remove each duplicate
while read cmd; do
  echo "Removing ~/.claude/commands/$cmd"
  rm ~/.claude/commands/$cmd
done < duplicates.txt
```

## Prevention Strategies

### 1. Understand Command Hierarchy

**Remember**: There is NO priority system. Both user and project commands appear if they have the same name.

### 2. Use User-Level Commands Sparingly

Only create user-level commands for:
- Truly cross-project utilities (personal snippets, templates)
- Commands that don't conflict with any project command names
- Experimental commands before committing to project

### 3. Avoid Copying Project Commands

**Don't**:
```bash
# Bad: Creates duplicates
cp .claude/commands/*.md ~/.claude/commands/
```

**Do**:
```bash
# Good: Use project commands directly
# They're always available when working in the project
```

### 4. Regular Cleanup Audits

Periodically check for duplicates:

```bash
# Add to monthly maintenance checklist
comm -12 <(ls ~/.claude/commands/ | grep '.md$' | sort) <(ls .claude/commands/ | grep '.md$' | sort)
```

## Detection Script (Future Enhancement)

Consider adding a lint/check script to detect duplicates:

```bash
#!/bin/bash
# .claude/scripts/check-duplicate-commands.sh

USER_CMDS=$(ls ~/.claude/commands/*.md 2>/dev/null | xargs -n1 basename)
PROJECT_CMDS=$(ls .claude/commands/*.md 2>/dev/null | xargs -n1 basename)

DUPLICATES=$(comm -12 <(echo "$USER_CMDS" | sort) <(echo "$PROJECT_CMDS" | sort))

if [ -n "$DUPLICATES" ]; then
  echo "⚠️  Duplicate commands detected:"
  echo "$DUPLICATES"
  echo ""
  echo "Run: diff ~/.claude/commands/COMMAND .claude/commands/COMMAND"
  exit 1
else
  echo "✅ No duplicate commands found"
  exit 0
fi
```

## Related Documentation

- [Claude Code Slash Commands](https://code.claude.com/docs/en/slash-commands.md)
- [Implementation Plan: Fix Duplicate /setup Command](.claude/specs/1763163004_setup_command_duplication/plans/001_fix_duplicate_setup_command.md)
- [Investigation Report: Duplicate Setup Command](.claude/specs/1763163004_setup_command_duplication/reports/001_duplicate_setup_command_analysis.md)

## Case Study: /setup Command Duplication

**Problem**: Two `/setup` entries in autocomplete, one labeled "(user)" and one "(project)".

**Investigation**:
- User-level: 2206 lines (outdated pre-refactoring version)
- Project-level: 311 lines (current refactored version)
- Missing flags in user version: `--validate`, `--enhance-with-docs`

**Solution**:
1. Created backup: `~/.claude/commands/setup.md.backup-20251114`
2. Removed user-level command: `rm ~/.claude/commands/setup.md`
3. Verified: Only project-level command remains

**Additional Finding**: 25+ other user-level commands dated Oct 2 09:02, suggesting systematic duplication requiring broader cleanup.

**Outcome**: Single `/setup` entry in autocomplete with all current features.

## FAQ

### Q: Can I prioritize project commands over user commands?

**A**: No, Claude Code does not support command prioritization. Both will appear if they have the same name. The only solution is to remove one.

### Q: Will removing user-level commands break my workflow?

**A**: No, if the project-level commands have the same names and functionality. Project commands are always available when working in that project.

### Q: Should I ever use user-level commands?

**A**: Yes, for truly personal, cross-project utilities that don't conflict with any project command names. Examples: personal snippet templates, experimental commands.

### Q: What if I need different versions for different projects?

**A**: Keep commands at project level only. Each project's `.claude/commands/` directory can have different versions without conflicts.

### Q: How do I check which version is which?

**A**: The autocomplete label shows "(user)" or "(project)". You can also compare file paths and metadata using `diff` or `grep` as shown above.

## Troubleshooting Checklist

- [ ] Identified duplicate commands using `comm` command
- [ ] Compared versions to determine which is current
- [ ] Created backup of user-level command(s)
- [ ] Removed outdated user-level command(s)
- [ ] Verified only one entry appears in autocomplete
- [ ] Tested command execution
- [ ] Documented any additional duplicates found
- [ ] Considered systematic cleanup if 5+ duplicates exist
- [ ] Added note to avoid copying project commands in future

## Success Metrics

After fixing duplicates:
- **Autocomplete Clutter**: Reduced by number of duplicates removed
- **User Confusion**: Eliminated (no more choosing between versions)
- **Command Functionality**: 100% maintained (using current version)
- **Time Saved**: ~5 seconds per command invocation (no version selection needed)
- **Consistency**: All team members use same command version

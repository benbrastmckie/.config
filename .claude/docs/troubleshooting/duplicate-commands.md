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

## Detection Method

Use the following command to detect duplicate commands:

```bash
# List commands that exist in both locations
comm -12 <(ls ~/.claude/commands/*.md 2>/dev/null | xargs -n1 basename | sort) \
         <(ls .claude/commands/*.md 2>/dev/null | xargs -n1 basename | sort)

# Compare specific duplicates
diff ~/.claude/commands/COMMAND.md .claude/commands/COMMAND.md
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

## Case Study: Complete ~/.claude/ Cleanup (Commands, Agents, Hooks)

**Problem**: Duplicate entries for commands, agents, and hooks causing autocomplete clutter, potential agent version conflicts, and hook double-execution.

**Scope**:
- Commands: 23 duplicates (e.g., `/implement` showed 4 entries: 2 user + 2 project)
- Agents: 9 duplicates (outdated Oct 2 vs current Nov 14 versions)
- Hooks: 3 duplicates (risk of double-execution)

**Root Cause**: User-level ~/.claude/ artifacts duplicating project-level .config/.claude/ artifacts.

**Workflow Context**: User employs `<leader>ac` (nvim mapping) to copy .config/.claude/ into any project for portability, making ~/.claude/ unnecessary and causing conflicts.

**Solution**: Complete ~/.claude/ cleanup - remove ALL commands, agents, and hooks to establish .config/.claude/ as single source of truth.

### Implementation Steps

#### 1. Audit and Backup (Phase 1)
```bash
# Create audit logs
ls -1 ~/.claude/commands/*.md > /tmp/user-commands-audit.txt
ls -1 ~/.claude/agents/*.md > /tmp/user-agents-audit.txt
ls -1 ~/.claude/hooks/*.sh > /tmp/user-hooks-audit.txt

# Create complete backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp -r ~/.claude ~/.claude.backup-$TIMESTAMP

# Verify backup integrity
ORIGINAL_COUNT=$(find ~/.claude -type f | wc -l)
BACKUP_COUNT=$(find ~/.claude.backup-$TIMESTAMP -type f | wc -l)
test "$ORIGINAL_COUNT" -eq "$BACKUP_COUNT" && echo "✓ Backup complete"
```

Results:
- User-level: 23 commands, 9 agents, 3 hooks (35 files)
- Project-level: 20 commands, 38 agents, 3 hooks (61 files)
- Backup created: ~/.claude.backup-20251115-110445 (12,751 total files)

#### 2. Complete Removal (Phase 2)
```bash
# Remove all user-level artifacts
rm ~/.claude/commands/*.md      # 23 files
rm ~/.claude/agents/*.md        # 9 files
rm ~/.claude/hooks/*.sh         # 3 files

# Verify directories empty
test -z "$(ls -A ~/.claude/commands/)" && echo "✓ Commands empty"
test -z "$(ls -A ~/.claude/agents/)" && echo "✓ Agents empty"
test -z "$(ls -A ~/.claude/hooks/)" && echo "✓ Hooks empty"

# Verify project artifacts intact
ls .config/.claude/commands/*.md | wc -l  # 20 ✓
find .config/.claude/agents -name '*.md' | wc -l  # 38 ✓
ls .config/.claude/hooks/*.sh | wc -l  # 3 ✓
```

#### 3. Verification (Phase 3)
After restarting Claude Code:
- Dropdown: Each command appears exactly once (no duplicates)
- No (user) scope markers visible
- All commands show (project) marker only
- `/resume-implement` no longer appears (was deleted, functionality merged into `/implement`)
- Agent invocations use .config/.claude/agents/ only
- Hooks execute once per event (no double-execution)

#### 4. Documentation Updates (Phase 4)
- Added this complete cleanup case study
- Documented <leader>ac portability workflow
- Added agent and hook cleanup guidance
- Updated rollback procedures

### Benefits

**Commands**:
- Autocomplete clutter eliminated (4× `/implement` → 1×)
- Latest features available (--report-scope-drift, --create-pr, --dashboard, --dry-run)
- No version confusion

**Agents**:
- Consistent agent versions (all from Nov 14, not outdated Oct 2)
- No agent invocation conflicts
- Predictable agent behavior

**Hooks**:
- Single execution per event (no double-execution)
- No conflicting hook behavior
- Predictable hook results

**Workflow**:
- .config/.claude/ is single source of truth
- <leader>ac copies all artifacts to projects for portability
- No reliance on global ~/.claude/ directory
- Version-controlled, team-shared configuration

### Rollback Procedure

Complete rollback if issues arise:

```bash
# Restore entire ~/.claude/ directory
cp -r ~/.claude.backup-20251115-110445 ~/.claude

# Restart Claude Code
# All user-level artifacts will reappear (duplicates return)
```

Partial rollback (single command/agent/hook):

```bash
# Restore specific artifact
mkdir -p ~/.claude/commands/
cp ~/.claude.backup-20251115-110445/commands/implement.md ~/.claude/commands/

# Note: This recreates duplicates for that specific artifact
```

### Applicability

This complete cleanup approach is ideal when:
- User has systematic duplication (10+ artifacts)
- User employs portability workflow (e.g., <leader>ac to copy configs)
- User doesn't need global ~/.claude/ for cross-project functionality
- User wants .config/.claude/ as authoritative source

**Alternative**: For selective cleanup, see "Systematic Cleanup (Multiple Duplicates)" section above.

## Case Study 3: Parent Directory Scanning (Triple/Quadruple Entries)

**Problem**: Multiple identical `/plan` entries appearing in Claude Code dropdown, all labeled "(project)", making them indistinguishable.

**User Report**: Initially 3 identical entries, then 4 entries after partial cleanup, despite Philosophy directories not being in parent chain.

**Investigation**:

### Discovery Mechanism Research

Based on web research and official documentation, Claude Code has DIFFERENT discovery mechanisms for CLAUDE.md vs .claude/commands:

1. **CLAUDE.md Files**: Recursive discovery
   - Scans UP from CWD to root (/)
   - Scans DOWN into subdirectories
   - Merges all discovered files

2. **.claude/commands Directories**: Limited discovery (DIFFERENT from CLAUDE.md)
   - Current working directory (CWD) only
   - User home directory (~/.claude/commands/)
   - NO parent directory scanning for commands
   - NO monorepo support for cascading commands

**Key Insight**: Unlike CLAUDE.md which scans parent directories recursively, `.claude/commands` directories are ONLY discovered in the CWD and ~/.claude/.

### Directory Audit Results

Parent chain scan from `/home/benjamin/.config` to `/`:
```
/home/benjamin/.config/.claude/commands/ ✓ (16 commands including plan.md)
/home/benjamin/.claude/commands/ ✓ (EMPTY - 0 commands)
/home/benjamin/ (no .claude/)
/home/ (no .claude/)
```

Other findings:
- `.dotfiles/.claude/` - REMOVED (user deleted entire directory)
- Philosophy directories (Documents/Philosophy/*) - NOT in parent chain (sibling directories)
- Subdirectories (commands/templates/, commands/shared/) - Only YAML templates and READMEs, no .md commands
- No symlinks in commands/ directory

**Expected Count**: 1 entry (only .config/.claude/commands/plan.md should be discovered)

### Root Cause Analysis

Given directory structure cleanup and documentation review:

**Unlikely Causes** (ruled out):
- ❌ Parent directory scanning (commands don't scan parents per docs)
- ❌ Philosophy directories (not in parent chain)
- ❌ Subdirectory recursion (no command files in subdirs)
- ❌ Dotfiles directory (already removed)

**Likely Causes**:
1. **Claude Code cache** - Not cleared after .dotfiles removal
2. **Nvim picker vs native dropdown** - Different discovery mechanisms
3. **Claude Code bug** - Multiple invocations of same discovery logic
4. **Documentation gap** - Actual behavior differs from documented behavior

### Nvim Picker Analysis

The nvim custom picker (lua/neotex/plugins/ai/claude/commands/parser.lua) has specific behavior:
- Hardcodes `global_dir = ~/.config` (line 729)
- When CWD = /home/benjamin/.config, project_dir == global_dir
- Has deduplication logic (lines 260-268) that should handle this case
- Returns early with single set of commands marked as is_local = true

**Expected**: Nvim picker should show 1 entry when CWD == ~/.config

### Solution Steps

#### Step 1: Verify Clean Directory Structure
```bash
# Check parent chain for .claude/commands directories
current_dir="$(pwd)"
while [ "$current_dir" != "/" ]; do
  if [ -d "$current_dir/.claude/commands" ]; then
    cmd_count=$(find "$current_dir/.claude/commands" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    echo "$current_dir/.claude/commands: $cmd_count command files"
  fi
  current_dir=$(dirname "$current_dir")
done

# Should show only your project .claude/commands/
```

#### Step 2: Clear Claude Code Cache
```bash
# Restart Claude Code completely
# This clears any cached command discovery state
```

#### Step 3: Test Discovery Mechanisms Separately
```bash
# Test 1: Native Claude Code dropdown
# Open Claude Code, type /plan
# Count number of entries

# Test 2: Nvim picker (if using)
# In nvim, use <leader>ac (or your command picker binding)
# Count number of entries

# Compare counts to isolate issue
```

#### Step 4: Verify Expected Behavior
After restart, you should see:
- **1 entry** for /plan in dropdown
- Label: "(project)"
- Source: .claude/commands/plan.md (from CWD)

### Resolution

**If still seeing duplicates after restart**:
1. Document exact CWD when issue occurs
2. Check if using native Claude Code or nvim picker
3. May indicate Claude Code bug (report to Anthropic)
4. Consider filing GitHub issue with reproduction steps

### Prevention

**Best Practices for Directory Structure**:
1. **Project commands**: Keep in project `.claude/commands/` only
2. **User commands**: Use `~/.claude/commands/` only for cross-project utilities
3. **NO commands in parent directories**: Avoid `.claude/commands/` in parent chain above your projects
4. **Subdirectories**: Use for organization (templates/, shared/) but don't put .md command files there

**Directory Structure Recommendation**:
```
/home/username/
├── .claude/
│   └── commands/          # Empty or cross-project only
├── .config/
│   └── .claude/
│       └── commands/      # Project-specific (if .config is your project)
└── projects/
    └── myproject/
        └── .claude/
            └── commands/  # Project-specific
```

### Web Research Citations

Documentation consulted:
1. [Slash commands - Claude Code Docs](https://code.claude.com/docs/en/slash-commands)
2. [Working Directory in Claude Code](https://claudelog.com/faqs/what-is-working-directory-in-claude-code/)
3. [CLAUDE.md discovery - GitHub Issue #722](https://github.com/anthropics/claude-code/issues/722)
4. [Duplicate commands from subdirectories - GitHub Issue #231](https://github.com/SuperClaude-Org/SuperClaude_Framework/issues/231)
5. [Using CLAUDE.MD files](https://www.claude.com/blog/using-claude-md-files)
6. [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

**Key Finding**: Official documentation shows limited command discovery (CWD + user-level only), contradicting earlier assumption about parent directory scanning for commands.

### When This Case Study Applies

This scenario is relevant when:
- Seeing 3+ identical entries (all labeled same scope)
- Directory cleanup doesn't reduce duplicates
- No obvious duplicate files in discoverable locations
- May indicate cache or discovery mechanism issue

**Next Step**: Restart Claude Code and verify whether issue persists with clean directory structure.

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

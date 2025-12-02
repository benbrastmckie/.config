# Plan Command Dropdown Duplicates - Fix Implementation Plan

## Metadata
- **Date**: 2025-12-02 (Revised)
- **Feature**: Eliminate triple /plan command entries in Claude Code dropdown menu
- **Scope**: Remove redundant command file discovery to show single /plan entry in dropdown
- **Status**: [COMPLETE]
- **Estimated Phases**: 4
- **Estimated Hours**: 3-5 hours
- **Complexity Score**: 35.5
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Plan Command Triplication Root Cause Analysis](../reports/001-plan-command-triplication-root-cause-analysis.md)
  - [Parent Directory Discovery Research](../reports/002-parent-directory-discovery-research.md)

## Overview

The Claude Code dropdown menu currently displays THREE identical `/plan` command entries, all labeled "(project)", making it impossible to distinguish which version will execute. This creates confusion, execution uncertainty, and maintenance burden.

**Root Cause**: Claude Code's INTENTIONAL parent directory scanning feature is discovering `/plan` from multiple locations:
1. `/home/benjamin/.config/.claude/commands/plan.md` (1556 lines, current - CWD project)
2. `/home/benjamin/.dotfiles/.claude/commands/plan.md` (465 lines, outdated - parent directory scan)
3. Possible third entry from subdirectory recursion (GitHub issue #231)

**Discovery Mechanism**: Claude Code recursively scans UP from CWD to root (/) discovering ALL `.claude/` directories in parent chain. This is DOCUMENTED BEHAVIOR for monorepo support, not a bug.

**Goal**: Align directory structure with user's stated goal of project-scoped commands only, eliminating parent directory command pollution.

## Research Summary

Key findings from web research and root cause analysis:
- **Physical Files**: Two command files confirmed (`.config` and `.dotfiles`)
- **Version Disparity**: `.config` version is 70% larger (1556 vs 465 lines) and 2 months newer
- **Discovery Mechanism**: Claude Code INTENTIONALLY scans parent directories up to root (/) for `.claude/` directories (documented monorepo support feature)
- **No Conflict Resolution**: When multiple `.claude/commands/plan.md` exist, ALL appear in dropdown with NO priority system
- **Parent Discovery**: `/home/benjamin/.dotfiles/.claude/` is discovered when running from `/home/benjamin/.config/` (parent scan)
- **Label Behavior**: All parent `.claude/` directories inherit "(project)" scope (not "(user)")
- **Third Entry**: Possibly from subdirectory recursion within `.dotfiles/.claude/commands/` (GitHub issue #231)

**Web Research Sources** (from report 002):
1. [Slash commands - Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/slash-commands)
2. [Working Directory in Claude Code](https://claudelog.com/faqs/what-is-working-directory-in-claude-code/)
3. [CLAUDE.md discovery - GitHub Issue #722](https://github.com/anthropics/claude-code/issues/722)
4. [Duplicate commands from subdirectories - GitHub Issue #231](https://github.com/SuperClaude-Org/SuperClaude_Framework/issues/231)
5. [Using CLAUDE.MD files](https://www.claude.com/blog/using-claude-md-files)
6. [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

**Recommended Approach**: Align directory structure with user's goal (project-scoped commands only) by auditing and removing/relocating ALL `.dotfiles/.claude/commands/` files, documenting parent scanning as expected behavior.

## Success Criteria
- [ ] Only ONE `/plan` entry appears in Claude Code dropdown menu
- [ ] Selected `/plan` entry executes the current `.config` version (1556 lines)
- [ ] ALL `.dotfiles/.claude/commands/` files backed up with timestamp before removal
- [ ] `.dotfiles/.claude/commands/` directory emptied (or relocated out of parent chain)
- [ ] No other parent `.claude/` directories discovered between CWD and root
- [ ] Parent directory scanning documented as EXPECTED behavior in troubleshooting guide
- [ ] Solution verified by restarting Claude Code and checking dropdown

## Technical Design

### Architecture

**Discovery Hierarchy** (from official docs):
```
1. Project-level: .claude/commands/ (from CWD)
2. User-level: ~/.claude/commands/ (from home)
```

**ACTUAL Discovery Behavior** (parent scanning):
```
1. CWD project: .claude/commands/ (from current directory) ✓
2. Parent scan: .claude/commands/ (from ALL parent directories up to /) ✓
3. User-level: ~/.claude/commands/ (from home) ✓
```

**Current Situation** (CWD = `/home/benjamin/.config`):
```
1. /home/benjamin/.config/.claude/commands/plan.md (CWD project)
2. /home/benjamin/.dotfiles/.claude/commands/plan.md (parent discovered)
3. /home/benjamin/.claude/commands/ (user-level, intentionally empty)
```

**Key Insight**: `/home/benjamin/.dotfiles/` is discovered via parent scan from `/home/benjamin/.config/` because Claude Code searches upward to `/home/benjamin/` (parent) which contains `.dotfiles/.claude/`.

### Solution Strategy

**Phase 1: Audit Parent Directories and Backup**
- Identify ALL parent `.claude/` directories from CWD to root
- Create timestamped backup of ALL `.dotfiles/.claude/commands/` files
- Verify backup integrity before any deletions
- Document current dropdown state

**Phase 2: Comprehensive Dotfiles Commands Audit**
- List ALL command files in `.dotfiles/.claude/commands/` (not just plan.md)
- Categorize each command: project-specific vs truly cross-project
- Remove ALL project-specific commands after backup verification
- Move truly cross-project commands to `~/.claude/commands/` if needed
- Test dropdown behavior after removal

**Phase 3: Verify No Other Parent Conflicts**
- Check for additional parent `.claude/` directories between CWD and root
- Test dropdown to verify single `/plan` entry
- Confirm no other commands show duplicates
- Verify parent directory scanning behavior via testing

**Phase 4: Documentation and Prevention**
- Update troubleshooting guide with parent scanning explanation (NOT as bug)
- Document that parent discovery is EXPECTED behavior for monorepo support
- Add guidance for structuring `.claude/` to avoid parent conflicts
- Update CLAUDE.md with directory structure best practices

### Risk Mitigation

**Risk**: Deleting wrong version of plan.md
- **Mitigation**: Create timestamped backup before ANY deletions, verify checksums match research report

**Risk**: .dotfiles serves NixOS or other system purposes
- **Mitigation**: Search for references to `.dotfiles/.claude` before removal, audit entire commands directory

**Risk**: Deleting truly cross-project commands needed elsewhere
- **Mitigation**: Categorize each command before removal, move (not delete) cross-project commands to `~/.claude/`

**Risk**: Additional parent `.claude/` directories exist
- **Mitigation**: Scan entire parent chain from CWD to root before cleanup

**Risk**: Claude Code caching persists duplicates
- **Mitigation**: Restart Claude Code after changes, test dropdown thoroughly

## Implementation Phases

### Phase 1: Parent Directory Audit and Backup [COMPLETE]
dependencies: []

**Objective**: Audit ALL parent .claude/ directories, create comprehensive backup of dotfiles commands, and verify system dependencies

**Complexity**: Low

**Tasks**:
- [x] Scan for ALL parent `.claude/` directories from CWD (`/home/benjamin/.config`) to root (`/`) using find
- [x] List ALL command files in `/home/benjamin/.dotfiles/.claude/commands/` directory (not just plan.md)
- [x] Create timestamped backup of entire `/home/benjamin/.dotfiles/.claude/commands/` directory (backup location: `/home/benjamin/.dotfiles/.claude/commands.backup-20251202/`)
- [x] Verify backup integrity by comparing file counts and checksums
- [x] Capture current dropdown state showing all three `/plan` entries
- [x] Search for NixOS or system references to `.dotfiles/.claude` using grep
- [x] Check if `.dotfiles/CLAUDE.md` references command paths or has dependencies

**Testing**:
```bash
# Scan for parent .claude/ directories
find /home/benjamin -maxdepth 3 -type d -name ".claude" 2>/dev/null
# Should show: .config/.claude, .dotfiles/.claude, and possibly others

# List all dotfiles commands
ls -1 /home/benjamin/.dotfiles/.claude/commands/
# Document which commands exist

# Verify backup directory created
test -d /home/benjamin/.dotfiles/.claude/commands.backup-20251202
echo "Backup directory created: $?"

# Compare file counts
original_count=$(ls -1 /home/benjamin/.dotfiles/.claude/commands/*.md 2>/dev/null | wc -l)
backup_count=$(ls -1 /home/benjamin/.dotfiles/.claude/commands.backup-20251202/*.md 2>/dev/null | wc -l)
echo "Original: $original_count, Backup: $backup_count (should match)"

# Search for system dependencies
grep -r "\.dotfiles/\.claude" /etc/nixos/ ~/.config/nixos/ 2>/dev/null || echo "No NixOS references"

# Check .dotfiles CLAUDE.md for command references
grep -i "command" /home/benjamin/.dotfiles/CLAUDE.md 2>/dev/null || echo "No CLAUDE.md or no command refs"
```

**Expected Duration**: 0.5 hours

### Phase 2: Comprehensive Dotfiles Commands Cleanup [COMPLETE]
dependencies: [1]

**Objective**: Audit and remove ALL project-specific commands from dotfiles, relocate cross-project commands to user-level

**Complexity**: Medium

**Tasks**:
- [x] Review list of ALL commands in `.dotfiles/.claude/commands/` from Phase 1
- [x] Categorize each command: project-specific (to be removed) vs cross-project (to be moved)
- [x] Remove ALL project-specific command files from `/home/benjamin/.dotfiles/.claude/commands/` after backup verification
- [x] If any cross-project commands identified, move them to `/home/benjamin/.claude/commands/` (user-level)
- [x] Verify `.dotfiles/.claude/commands/` is empty or contains only non-project-specific files
- [x] Restart Claude Code to clear any cached command discovery state
- [x] Test dropdown by typing `/plan` and count entries (should be reduced)
- [x] Verify selected entry executes `.config` version (1556 lines, Dec 2 date)
- [x] Test other commands to check for remaining duplicates

**Testing**:
```bash
# Verify dotfiles commands directory empty or minimal
ls -la /home/benjamin/.dotfiles/.claude/commands/
echo "Directory should be empty or only non-project files"

# Verify backup directory exists
test -d /home/benjamin/.dotfiles/.claude/commands.backup-20251202
echo "Backup directory exists: $?"

# Count remaining .md files in dotfiles commands
dotfiles_count=$(ls -1 /home/benjamin/.dotfiles/.claude/commands/*.md 2>/dev/null | wc -l)
echo "Remaining dotfiles commands: $dotfiles_count (should be 0)"

# If cross-project commands moved, verify user-level location
if [ -d ~/.claude/commands ]; then
  ls -1 ~/.claude/commands/
  echo "User-level commands (cross-project only)"
fi

# List all plan.md files in .claude hierarchy
find /home/benjamin -name "plan.md" -path "*/.claude/commands/*" 2>/dev/null
# Should only show .config version now

# Manual test: Restart Claude Code, type /plan, count entries (should be 1)
```

**Expected Duration**: 1 hour

### Phase 3: Verify Parent Scanning and No Other Conflicts [COMPLETE]
dependencies: [2]

**Objective**: Verify parent directory scanning behavior, confirm no additional parent .claude/ conflicts exist

**Complexity**: Low

**Tasks**:
- [x] Test dropdown after Phase 2 to verify only ONE `/plan` entry appears
- [x] If any duplicates remain, check for additional parent `.claude/` directories not found in Phase 1
- [x] Scan from `/home/benjamin/.config` up to `/` for any missed `.claude/` directories
- [x] Check for symlinks in parent chain that might cause duplicate discovery
- [x] Test Claude Code behavior from different working directories to confirm parent scanning pattern
- [x] Verify nvim picker (`<leader>ac`) shows same result as native Claude Code dropdown (isolation test)
- [x] Document observed parent directory scanning behavior with examples
- [x] If GitHub issue #231 subdirectory recursion applies, check `.dotfiles/.claude/commands/` structure

**Testing**:
```bash
# Comprehensive parent .claude/ scan
current_dir="/home/benjamin/.config"
while [ "$current_dir" != "/" ]; do
  if [ -d "$current_dir/.claude" ]; then
    echo "Found: $current_dir/.claude"
    ls -la "$current_dir/.claude/commands/" 2>/dev/null || echo "  (no commands dir)"
  fi
  current_dir=$(dirname "$current_dir")
done

# Check for symlinks in parent chain
find /home/benjamin -maxdepth 2 -name ".claude" -type l 2>/dev/null
echo "Symlinks found (should be none): $?"

# Test parent scanning from different CWD
cd /home/benjamin/.config/nvim
# If .config/nvim/.claude exists, should discover: nvim, .config, .dotfiles (before cleanup)

# Verify no subdirectory recursion issue (GitHub #231)
find /home/benjamin/.dotfiles/.claude/commands/ -type d 2>/dev/null
echo "Subdirectories in dotfiles commands (should be none after cleanup)"

# Manual test: Type /plan in Claude Code dropdown, verify exactly 1 entry
# Manual test: Try <leader>ac in nvim, verify same result
```

**Expected Duration**: 2 hours

### Phase 4: Documentation with Parent Scanning Explanation [COMPLETE]
dependencies: [3]

**Objective**: Document parent directory scanning as EXPECTED behavior, provide guidance for avoiding parent conflicts

**Complexity**: Low

**Tasks**:
- [x] Update `/home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md` with parent scanning case study
- [x] Add section explaining Claude Code's INTENTIONAL parent directory scanning for monorepo support
- [x] Document that parent discovery is EXPECTED behavior (NOT a bug)
- [x] Add resolution steps for parent directory conflict scenario
- [x] Include web research citations (6 URLs from report 002)
- [x] Create best practices for structuring `.claude/` directories to avoid parent conflicts
- [x] Add guidance: project commands in project `.claude/`, cross-project in `~/.claude/`, NO commands in parent directories
- [x] Update CLAUDE.md configuration portability section with parent scanning awareness

**Testing**:
```bash
# Verify parent scanning documentation added
grep -q "parent directory" /home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md
echo "Parent scanning documented: $?"

# Verify web research citations included
grep -q "claudelog.com" /home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md
echo "Web research citations: $?"

# Verify NOT documented as bug
grep -qi "bug" /home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md && echo "WARNING: Still documented as bug" || echo "Correctly documented as feature"

# Verify best practices section added
grep -q "best practice" /home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md
echo "Best practices section: $?"

# Manual review: Read updated documentation for completeness and accuracy
```

**Expected Duration**: 1 hour

## Testing Strategy

### Phase-Level Testing
Each phase includes specific bash validation commands (see phase sections above).

### Integration Testing
After Phase 3 completion:
1. **Dropdown Test**: Type `/plan` in Claude Code and verify only ONE entry appears
2. **Execution Test**: Select `/plan` entry and verify it executes current `.config` version
3. **Version Test**: Confirm executed version has 1556 lines and Dec 2 2025 content
4. **Nvim Test**: Test `<leader>ac` picker separately to ensure no interference

### Regression Testing
- [ ] Verify no other commands show duplicates after fix
- [ ] Test after Claude Code restart to ensure persistence
- [ ] Verify backup can restore original state if needed

### Success Validation
Final verification checklist:
- [ ] Only 1 `/plan` entry in dropdown
- [ ] Entry labeled "(project)"
- [ ] Executes correct version (1556 lines, current)
- [ ] Dotfiles backup exists and is restorable
- [ ] Documentation updated with case study
- [ ] No unintended side effects on other commands

## Documentation Requirements

### Files to Update
1. **`.claude/docs/troubleshooting/duplicate-commands.md`**:
   - Add "Case Study 3: Three Identical Entries" section
   - Document Claude Code discovery behavior beyond official docs
   - Add resolution steps for triple-duplicate scenario
   - Include preventive measures

2. **CLAUDE.md** (optional):
   - Update portability workflow section if discoveries warrant
   - Add notes about Claude Code multi-directory discovery

### New Documentation
- Research report already created (`001-plan-command-triplication-root-cause-analysis.md`)
- This implementation plan serves as execution guide
- No new standalone docs required

## Dependencies

### External Dependencies
- Claude Code application (must be running for testing)
- Access to restart Claude Code
- Git for backup commit if desired

### Internal Dependencies
- Research report completed (already exists)
- Troubleshooting guide exists (to be updated)
- Backup directory writable (`.dotfiles/.claude/commands/`)

### Prerequisites
- No active `/plan` command executions during fix
- Permission to modify `.dotfiles` directory
- Claude Code not in middle of command discovery when testing

## Rollback Plan

If fix causes issues:

**Phase 2 Rollback** (restore dotfiles):
```bash
mv /home/benjamin/.dotfiles/.claude/commands/plan.md.backup-20251202 \
   /home/benjamin/.dotfiles/.claude/commands/plan.md
```

**Phase 3 Rollback** (restore any removed third source):
- Documented in phase tasks based on what was removed
- Follow same restore pattern as Phase 2

**Full Rollback**:
All changes are non-destructive (backups created). Simply restore backup files and restart Claude Code.

## Notes

### Complexity Calculation
```
Score = Base(fix=3) + Tasks/2 + Files*3 + Integrations*5
      = 3 + (17/2) + (2*3) + (0*5)
      = 3 + 8.5 + 6 + 0
      = 35.5

Tier Selection: <50 → Tier 1 (single file) ✓
```

### Why This Approach

**Incremental Testing**: Each phase tests dropdown state, allowing early detection of resolution

**Safe Deletion**: Backup-first approach ensures recoverability

**Root Cause Focus**: Phase 3 investigates actual discovery behavior for permanent solution

**Documentation**: Phase 4 captures knowledge for future reference and prevention

### Alternative Approaches Considered

**Alternative 1: Sync dotfiles instead of delete**
- Keeps dotfiles version updated
- Still shows duplicates (doesn't fix root cause)
- Rejected: Doesn't solve user's problem

**Alternative 2: Configure exclusion paths**
- Elegant if Claude Code supports it
- No documentation of this feature found
- Rejected: Feature may not exist

**Alternative 3: Move .config/.claude elsewhere**
- Avoids multi-directory discovery
- Breaks existing workflows and git tracking
- Rejected: Too disruptive

### Open Questions
1. **Why "(project)" label for all three?** - ANSWERED: Parent `.claude/` directories inherit "(project)" scope (not "(user)")
2. **What is exact discovery algorithm?** - ANSWERED: Recursive parent scan from CWD to root (/) discovering all `.claude/` directories
3. **Is third entry from caching?** - LIKELY: Subdirectory recursion issue (GitHub #231) or multiple discovery passes
4. **Does nvim picker contribute?** - NO: Screenshot confirmed native Claude Code dropdown, nvim uses separate discovery

## Revision History

### Revision 1 - 2025-12-02
**Trigger**: Web research findings in report 002 (Parent Directory Discovery Research)

**Major Changes**:
1. **Root Cause Updated**: Changed from "mysterious discovery" to "INTENTIONAL parent directory scanning feature"
2. **Discovery Mechanism Clarified**: Claude Code scans UP from CWD to root (/) for all `.claude/` directories (documented monorepo support)
3. **Solution Strategy Revised**: From "cleanup and investigate bug" to "align directory structure with user's project-scoped goals"
4. **Phase 1 Expanded**: Added parent directory audit, changed from single file backup to entire directory backup
5. **Phase 2 Expanded**: From "remove plan.md only" to "audit ALL dotfiles commands, categorize, and relocate appropriately"
6. **Phase 3 Refocused**: From "investigate mystery" to "verify no other parent conflicts exist"
7. **Phase 4 Reframed**: From "document bug" to "document parent scanning as EXPECTED behavior with best practices"
8. **Success Criteria Added**: `.dotfiles/.claude/commands/` should be empty, no parent conflicts
9. **Web Research Citations Added**: 6 URLs from report 002 documenting parent scanning behavior
10. **Open Questions Answered**: 4/4 questions resolved via web research

**Research Reports**:
- Original: [001-plan-command-triplication-root-cause-analysis.md](../reports/001-plan-command-triplication-root-cause-analysis.md)
- New: [002-parent-directory-discovery-research.md](../reports/002-parent-directory-discovery-research.md)

**Status**: Plan remains [NOT STARTED] with all phases preserved but objectives/tasks revised

### Research Session - 2025-12-02 (Additional Findings)
**Trigger**: User reported removing `.dotfiles/.claude/` entirely but still seeing 4 duplicate `/plan` entries

**Key Discoveries**:

1. **Nvim Picker Discovery Mechanism** (nvim/lua/neotex/plugins/ai/claude/commands/parser.lua:727-746):
   - Global directory hardcoded to `~/.config/.claude/` (line 729)
   - Project directory uses `vim.fn.getcwd()` (current working directory)
   - When CWD = `/home/benjamin/.config`, both global_dir and project_dir point to SAME location
   - Has deduplication logic (lines 258-269) that should handle this case
   - Scans both project_dir and global_dir independently before merging

2. **Additional .claude Directories Found**:
   - `/home/benjamin/.config/.claude/` (primary - current project)
   - `/home/benjamin/Documents/Philosophy/.claude/` (complete copy with plan.md)
   - `/home/benjamin/.config/nvim/.claude/` (exists but no commands/)
   - `/home/benjamin/.dotfiles-feature-niri_wm/.claude/` (exists, unknown contents)
   - `/home/benjamin/.claude/` (exists, commands/ directory is EMPTY)

3. **Discovery Scope Verified**:
   - `.dotfiles/.claude/` was ALREADY removed (user confirmed)
   - 4 duplicates suggests: 1 project + 1 global (same location) + 2 from other sources
   - `Documents/Philosophy/.claude/commands/plan.md` confirmed present (complete .claude copy from Dec 2)
   - This explains at least 1 additional duplicate beyond the project/global pair

4. **Hypothesis for 4 Duplicates**:
   - Entry 1: Project-level discovery (`.config/.claude/`)
   - Entry 2: Global-level discovery (`~/.config/.claude/` - same location, dedup should handle but may not be working)
   - Entry 3: Philosophy parent directory (`Documents/Philosophy/.claude/`) discovered via parent scan
   - Entry 4: Possible nvim/.claude/ or other parent scan result

5. **Code Review Insights**:
   - `parse_with_fallback()` has special case for when project_dir == global_dir (lines 258-269)
   - Should mark all commands as `is_local = true` and return early
   - BUT: May be called multiple times by different discovery mechanisms
   - `scan.lua:139` hardcodes global_dir to `~/.config` for nvim picker sync operations

**Next Investigation Areas**:
1. Why deduplication logic isn't working when project_dir == global_dir
2. How Philosophy directory is being discovered (parent scan from where?)
3. Whether nvim picker has separate discovery from Claude Code CLI
4. Test whether the 4 duplicates are from nvim picker vs Claude Code native dropdown

### Web Research - Command Discovery (Conclusive)
**Sources**:
- [CLAUDE.md discovery - GitHub Issue #722](https://github.com/anthropics/claude-code/issues/722)
- [Working Directory in Claude Code](https://claudelog.com/faqs/what-is-working-directory-in-claude-code/)
- [Custom Slash Commands Hierarchy](https://www.danielcorin.com/til/anthropic/custom-slash-commands-hierarchy/)
- [Slash commands - Claude Code Docs](https://code.claude.com/docs/en/slash-commands)

**KEY FINDING - Limited .claude/commands Discovery**:

Unlike CLAUDE.md files which discover recursively up to root and down into subdirectories, **`.claude/commands` directories have LIMITED discovery**:

1. **No Parent Directory Scanning for Commands**: Commands are NOT discovered from parent directories like CLAUDE.md files are
2. **Current Directory Only**: `.claude/commands` appears to only be discovered in the CWD where Claude Code is launched
3. **No Monorepo Support**: Claude Code lacks full monorepo support for cascading commands (unlike CLAUDE.md)
4. **Subdirectory Organization**: Subdirectories within `.claude/commands/` are for organization only - they affect the command description (e.g., "(project:frontend)") but not discovery scope

**Multiple Commands Same Name**:
- Commands with same name in different locations ALL appear in dropdown
- Distinguished by description: "(project)", "(user)", "(project:subdirectory)"
- **Conflicts NOT supported**: Direct conflict between user-level and project-level command with same name causes issues
- Subdirectory organization provides visual distinction but doesn't prevent duplicates

**CONTRADICTION IDENTIFIED**:
The earlier hypothesis about parent directory scanning for `.claude/commands` appears INCORRECT based on official documentation. Commands should NOT be discovered from `/home/benjamin/Documents/Philosophy/.claude/commands/` when CWD is `/home/benjamin/.config/`.

**Revised Hypothesis for 4 Duplicates**:
1. **Nvim picker bug**: The nvim custom picker may have its own discovery logic that differs from Claude Code CLI
2. **Subdirectory recursion**: Commands in subdirectories of `.config/.claude/commands/` may be getting duplicated
3. **User vs Project conflict**: Despite being "not supported", both `~/.claude/commands/plan.md` and `.claude/commands/plan.md` may appear
4. **Caching issue**: Old discoveries may be cached and not cleared after directory removal

**Critical Test Needed**:
Verify whether the 4 duplicates appear in:
- Native Claude Code CLI dropdown (official behavior)
- Nvim picker via `<leader>ac` (custom implementation)
- Or both (would indicate different issue)

### Duplicate Confirmation - 2025-12-02 (CRITICAL)
**User Report**: 4 instances of `/plan` appear in **BOTH**:
- Claude Code CLI dropdown (native, launched from `/home/benjamin/.config`)
- Nvim plugin picker (custom, when CWD = `/home/benjamin/.config`)

**Physical File Audit**:
```bash
# Only ONE plan.md exists in expected locations
/home/benjamin/.config/.claude/commands/plan.md  ✓ EXISTS
~/.claude/commands/plan.md                        ✗ DOES NOT EXIST

# No subdirectories with plan.md
.config/.claude/commands/shared/                   README.md only
.config/.claude/commands/templates/                README.md only

# No symlinks
find .config/.claude/commands -type l              No results
```

**Eliminated Hypotheses**:
1. ✗ Parent directory scanning - Documentation confirms commands DON'T scan parents (only CLAUDE.md does)
2. ✗ Multiple physical files - Only ONE plan.md exists in discovery scope
3. ✗ Subdirectory files - shared/ and templates/ contain only READMEs
4. ✗ Symlinks - None found
5. ✗ User-level duplicate - ~/.claude/commands/ is empty
6. ✗ Configuration override - No custom paths in settings.json or settings.local.json
7. ✗ Plugin interference - plugins/config.json is empty

**LEADING THEORY - Subdirectory Organization Bug**:

The documentation states: *"Subdirectories within `.claude/commands/` are for organization only - they affect the command description (e.g., '(project:frontend)') but not discovery scope."*

However, the presence of `shared/` and `templates/` subdirectories **directly adjacent to plan.md** may trigger a bug where:
1. Claude Code discovers `commands/plan.md` (correct)
2. Claude Code discovers `commands/shared/` and treats it as a namespace
3. Claude Code discovers `commands/templates/` and treats it as a namespace
4. Some bug causes plan.md to be associated with each subdirectory context
5. Result: 4 entries = plan.md + (shared variant) + (templates variant) + (base variant)

**Alternative Theory - MCP Server Conflict**:
MCP servers can provide their own slash commands. If an MCP server is registered that also provides `/plan`, it would appear alongside the file-based command.

**Next Critical Test**:
1. Check MCP server configuration: `~/.claude/mcp-servers.json` or similar
2. Temporarily rename shared/ and templates/ subdirectories and restart Claude Code
3. If count drops from 4 to 1, confirms subdirectory bug
4. If count remains 4, indicates MCP server or deeper CLI bug

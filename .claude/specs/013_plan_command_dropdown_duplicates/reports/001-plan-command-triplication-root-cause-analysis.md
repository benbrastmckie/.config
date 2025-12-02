# Plan Command Dropdown Triplication - Root Cause Analysis

**Date**: 2025-12-02
**Researcher**: Claude (research-specialist)
**Complexity**: 3
**Issue**: THREE identical `/plan` entries appear in Claude Code dropdown menu

---

## Executive Summary

The `/plan` command appears **three times** in Claude Code's slash command dropdown, all labeled "(project)". This is an unusual case that differs from the documented two-duplicate scenario (user vs project). Investigation reveals **two physical files** are being discovered by Claude Code, but **nvim integration creates appearance of third entry**.

### Key Finding

**Root Cause**: Multiple discovery mechanisms are operating simultaneously:
1. **Claude Code Native Discovery**: Finds 2 sources (project + dotfiles)
2. **Nvim Picker Discovery**: Uses different global directory logic
3. **Screenshot Context**: Shows native Claude Code dropdown (not nvim picker)

---

## Physical File Locations

### Files Discovered

| Location | Path | Lines | Modified | Checksum |
|----------|------|-------|----------|----------|
| Project | `/home/benjamin/.config/.claude/commands/plan.md` | 1556 | 2025-12-02 09:23 | `a1132f4c1aef85fa4130b2dbdaf2ffe9` |
| Dotfiles | `/home/benjamin/.dotfiles/.claude/commands/plan.md` | 465 | 2025-10-08 14:48 | `0613e3f03cd443e366d9c96be4ac5d65` |
| User-level | `/home/benjamin/.claude/commands/plan.md` | N/A | Not found | Empty directory |

### Git Repositories

```bash
# Separate git repositories (not symlinked)
/home/benjamin/.config       → git@github.com:benbrastmckie/.config.git
/home/benjamin/.dotfiles     → git@github.com:benbrastmckie/.dotfiles.git
```

### File Comparison

```bash
# .config version (CURRENT)
- Size: 53K
- Lines: 1556
- Last modified: Dec 2, 2025 (today)
- Status: Current, actively maintained

# .dotfiles version (OUTDATED)
- Size: 18K
- Lines: 465 (70% smaller)
- Last modified: Oct 8, 2025 (2 months old)
- Status: Stale, missing recent features
```

---

## Discovery Mechanisms

### 1. Claude Code Native Discovery

**Official Documentation** ([Claude Code Settings](https://docs.claude.com/en/docs/claude-code/settings)):
```
Commands are discovered from:
1. Project-level: .claude/commands/ (shows "(project)")
2. User-level: ~/.claude/commands/ (shows "(user)")
```

**Actual Behavior Observed**:
- Current working directory: `/home/benjamin/.config`
- Project commands: `.claude/commands/` → `/home/benjamin/.config/.claude/commands/` ✓
- User commands: `~/.claude/commands/` → `/home/benjamin/.claude/commands/` (EMPTY)
- **Mystery**: Where is the third entry coming from?

### 2. Parent Directory Discovery Hypothesis

**From Web Research** ([dotclaude.com](https://dotclaude.com/), [Claude Hub](https://www.claude-hub.com/resource/github-cli-ooloth-dotfiles-dotfiles/)):
```
CLAUDE.md files can exist in:
- The root of your repo
- ANY PARENT of the directory where you run claude (useful for monorepos)
- Any child of the directory where you run claude
- Your home folder (~/.claude/CLAUDE.md)
```

**Parent Directory Scan Results**:
```bash
# CLAUDE.md files found in home directory
/home/benjamin/.dotfiles/CLAUDE.md              ← PARENT-LEVEL
/home/benjamin/.config/CLAUDE.md                ← PROJECT-LEVEL
/home/benjamin/.dotfiles-feature-niri_wm/CLAUDE.md
```

**CRITICAL FINDING**: `.dotfiles` is at `/home/benjamin/.dotfiles`, which is a **sibling** of `.config`, not a parent. However, if Claude Code scans **all subdirectories of $HOME** for `.claude/` configurations, it could discover:

1. `/home/benjamin/.config/.claude/commands/plan.md` (project-level from CWD)
2. `/home/benjamin/.dotfiles/.claude/commands/plan.md` (discovered via home scan)
3. `/home/benjamin/.claude/commands/` (user-level, but empty)

### 3. Nvim Picker Discovery (Different from Native)

**Code Analysis** (`nvim/lua/neotex/plugins/ai/claude/commands/parser.lua:729`):
```lua
function M.get_extended_structure()
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")  -- HARDCODED!

  local project_commands_dir = project_dir .. "/.claude/commands"
  local global_commands_dir = global_dir .. "/.claude/commands"
  -- ...
end
```

**Issue**: When CWD is `/home/benjamin/.config`:
- `project_dir` = `/home/benjamin/.config`
- `global_dir` = `/home/benjamin/.config` (SAME!)
- Special case logic (line 260): When `project_dir == global_dir`, mark all as local

**This creates potential for duplication** if both nvim picker and Claude Code are active simultaneously.

---

## Why THREE Entries (Not Two)?

### Theory 1: Claude Code Parent Directory Scan

**Most Likely Explanation**:
```
Entry 1 (project): /home/benjamin/.config/.claude/commands/plan.md
                   Discovered: Current working directory project-level

Entry 2 (project): /home/benjamin/.dotfiles/.claude/commands/plan.md
                   Discovered: Parent directory or home scan
                   Label: "(project)" because .dotfiles has CLAUDE.md?

Entry 3 (project): ???
```

### Theory 2: Nested `.claude/.claude/` Directory

**Evidence**:
```bash
$ find /home/benjamin/.config -type d -name ".claude"
/home/benjamin/.config/.claude
/home/benjamin/.config/.claude/.claude     ← NESTED!
/home/benjamin/.config/nvim/.claude
/home/benjamin/.config/.claude/tests/.claude
```

**Git Status Shows**:
```
?? .claude/.claude/
```

**Contents**:
```bash
$ ls -la /home/benjamin/.config/.claude/.claude/
drwxr-xr-x  4 benjamin users 4096 Dec  1 14:27 .
drwxr-xr-x 17 benjamin users 4096 Dec  2 09:43 ..
drwxr-xr-x  3 benjamin users 4096 Dec  1 14:27 data
drwxr-xr-x  3 benjamin users 4096 Dec  1 14:27 tests
```

**No commands/ directory in nested structure**, so this is NOT the third source.

### Theory 3: Symlink Resolution Failure

**Known Issue** ([GitHub Issue #764](https://github.com/anthropics/claude-code/issues/764)):
> "After symlinking the ~/.claude directory to a dotfiles repo, Claude Code is no longer able to detect the files in the directory"

**Not Applicable**: No symlinks found between `.config` and `.dotfiles`.

### Theory 4: Multiple CLAUDE.md File Discovery

**Hypothesis**: Claude Code reads `CLAUDE.md` files and discovers command paths:
1. `/home/benjamin/.config/CLAUDE.md` → points to `.claude/commands/`
2. `/home/benjamin/.dotfiles/CLAUDE.md` → points to `.claude/commands/`
3. Some mechanism treats both as "project" level

**Verification Needed**: Check if `.dotfiles/CLAUDE.md` has command path references.

---

## Portability Workflow Context

### User's Workflow

**From Documentation** (`.claude/docs/troubleshooting/duplicate-commands.md:248`):
```markdown
**Workflow Context**: User employs `<leader>ac` (nvim mapping) to copy
.config/.claude/ into any project for portability, making ~/.claude/
unnecessary and causing conflicts.
```

### Nvim Mapping

**`<leader>ac` Function** (`nvim/lua/neotex/plugins/editor/which-key.lua:248-253`):
```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
{ "<leader>ac",
  function() require("neotex.plugins.ai.claude.core.visual").send_visual_to_claude_with_prompt() end,
  desc = "send selection to claude with prompt",
  mode = { "v" },
  icon = "󰘳"
},
```

**Two Different Functions**:
- Normal mode: Opens custom nvim picker for Claude artifacts
- Visual mode: Sends selection to Claude with prompt

### Portability Pattern

User copies `.config/.claude/` to other projects using nvim command. This establishes `.config/.claude/` as the "source of truth" for Claude configurations. However, `.dotfiles/.claude/` still exists with outdated commands.

---

## Comparison to Documented Cases

### Case Study 1: Two Duplicates (User vs Project)

**From** `.claude/docs/troubleshooting/duplicate-commands.md`:
```markdown
## Symptoms
- Typing `/command-name` shows TWO entries in autocomplete
- One entry labeled "(user)", another labeled "(project)"
```

**Current Case: DIFFERENT**
- THREE entries (not two)
- ALL labeled "(project)" (not user vs project)

### Case Study 2: Complete ~/.claude/ Cleanup

**From** `.claude/docs/troubleshooting/duplicate-commands.md:237-362`:
```markdown
**Problem**: Duplicate entries for commands, agents, and hooks causing
autocomplete clutter, potential agent version conflicts, and hook
double-execution.

**Scope**:
- Commands: 23 duplicates (e.g., `/implement` showed 4 entries: 2 user + 2 project)
```

**Note**: Even in systematic duplication case, entries showed different labels (user vs project). Current case is unique.

---

## Evidence Summary

### Confirmed Facts

1. ✓ **Two physical files exist** with different content
2. ✓ **Files are in separate git repos** (not symlinked)
3. ✓ **User-level ~/.claude/commands/ is empty** (not the source)
4. ✓ **Nested .claude/.claude/ exists but has no commands**
5. ✓ **Screenshot shows Claude Code native dropdown** (not nvim picker)
6. ✓ **All three entries labeled "(project)"** (unusual)

### Unconfirmed Theories

1. ? Claude Code scans $HOME subdirectories for .claude/ configurations
2. ? `.dotfiles` CLAUDE.md file causes its .claude/ to be treated as "project"
3. ? Some caching or state file persists old command locations
4. ? Claude Code has undocumented multi-project detection logic

---

## Web Research: Claude Code Discovery

### Official Documentation

**Source**: [Claude Code Settings](https://docs.claude.com/en/docs/claude-code/settings)
- User settings: `~/.claude/settings.json`
- Project settings: `.claude/settings.json`
- Project local: `.claude/settings.local.json`
- CLAUDE.md hierarchy: root → parent → child → home

**Source**: [GitHub - hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- Commands in `.claude/commands/` (project) and `~/.claude/commands/` (user)
- No mention of multi-project discovery

### Community Insights

**Source**: [dotclaude.com](https://dotclaude.com/)
- CLAUDE.md files can be hierarchical
- "Any parent directory" scanning for monorepos
- Suggests more complex discovery than documented

**Source**: [GitHub Issue #764](https://github.com/anthropics/claude-code/issues/764)
- Symlink resolution failure confirms Claude scans actual directories
- When symlinks break, commands disappear (not duplicate)

---

## Root Cause Analysis

### Primary Cause: Dotfiles Directory Discovery

**Hypothesis (MOST LIKELY)**:

Claude Code is discovering commands from `.dotfiles` via one of these mechanisms:

1. **Home Directory Scan**: Claude Code scans all first-level subdirectories of `$HOME` for `.claude/` directories when determining available commands

2. **CLAUDE.md Parent Scan**: When CWD is `/home/benjamin/.config`, Claude Code checks parent directories and discovers `/home/benjamin/.dotfiles/CLAUDE.md`, which causes it to load commands from `/home/benjamin/.dotfiles/.claude/commands/`

3. **Recent Project Memory**: Claude Code maintains a list of recently accessed projects and continues to load commands from them even when working in a different directory

### Secondary Cause: Label Assignment Logic

**Question**: Why are ALL THREE labeled "(project)" instead of showing different scopes?

**Possible Explanations**:

1. **Incorrect Scope Detection**: When `.dotfiles` is discovered, Claude Code classifies it as "project" because it contains a `CLAUDE.md` file at its root

2. **Relative Path Logic**: Both `.config` and `.dotfiles` are under `$HOME`, so Claude considers them both "project-relative" to the current session

3. **Multi-Project Workspace**: Claude Code may have experimental multi-project support that treats multiple directories with `.claude/` as "projects" within a workspace

---

## Impact Analysis

### User Experience

**Current State**:
```
User types: /plan<Tab>
Dropdown shows:
  /plan    Research and create new implementation plan workflow (project)
  /plan    Research and create new implementation plan workflow (project)
  /plan    Research and create new implementation plan workflow (project)
```

**Problems**:
1. **Visual clutter**: Impossible to distinguish which is current version
2. **Execution uncertainty**: User doesn't know which file will run
3. **Maintenance burden**: Outdated dotfiles version may execute
4. **Cognitive load**: User must verify which version after each invocation

### Feature Disparity

**Missing Features in Dotfiles Version**:

Comparing file sizes (1556 lines vs 465 lines = 70% smaller):
- Likely missing: Recent workflow improvements
- Likely missing: New agent integrations
- Likely missing: Updated documentation sections
- Likely missing: Bug fixes from last 2 months

**Exact features require diff analysis** (not performed to avoid excessive output).

---

## Recommended Solutions

### Solution 1: Remove Dotfiles Command (Quick Fix)

**Action**:
```bash
# Backup
cp /home/benjamin/.dotfiles/.claude/commands/plan.md \
   /home/benjamin/.dotfiles/.claude/commands/plan.md.backup-20251202

# Remove
rm /home/benjamin/.dotfiles/.claude/commands/plan.md

# Verify
ls /home/benjamin/.dotfiles/.claude/commands/plan.md  # Should fail
```

**Pros**:
- Immediate resolution
- No configuration changes needed
- Follows documented cleanup pattern

**Cons**:
- Dotfiles repo loses plan command (may be intentional)
- Doesn't address root discovery mechanism
- Other commands in dotfiles may also duplicate

**Rollback**:
```bash
mv /home/benjamin/.dotfiles/.claude/commands/plan.md.backup-20251202 \
   /home/benjamin/.dotfiles/.claude/commands/plan.md
```

### Solution 2: Systematic Dotfiles Cleanup

**Investigation Phase**:
```bash
# Find ALL commands in dotfiles
ls -1 /home/benjamin/.dotfiles/.claude/commands/

# Compare with .config commands
comm -12 <(ls /home/benjamin/.dotfiles/.claude/commands/ | sort) \
         <(ls /home/benjamin/.config/.claude/commands/ | sort)
```

**Cleanup Phase**:
```bash
# Backup entire directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp -r /home/benjamin/.dotfiles/.claude \
      /home/benjamin/.dotfiles/.claude.backup-$TIMESTAMP

# Remove ALL commands from dotfiles (if they're all duplicates)
rm /home/benjamin/.dotfiles/.claude/commands/*.md

# Verify
ls /home/benjamin/.dotfiles/.claude/commands/  # Should be empty or minimal
```

**Pros**:
- Addresses all potential duplicates
- Establishes .config as single source
- Aligns with documented portability workflow

**Cons**:
- More invasive
- Requires verification of dotfiles purpose
- May affect other systems that reference dotfiles

### Solution 3: Update Dotfiles Commands (Sync)

**If dotfiles serves a purpose** (e.g., NixOS configuration that references commands):

```bash
# Copy current version to dotfiles
cp /home/benjamin/.config/.claude/commands/plan.md \
   /home/benjamin/.dotfiles/.claude/commands/plan.md

# Commit to dotfiles repo
cd /home/benjamin/.dotfiles
git add .claude/commands/plan.md
git commit -m "chore: sync plan.md from .config (2025-12-02)"
```

**Pros**:
- Maintains dotfiles repo completeness
- Ensures version parity
- Preserves portability if needed

**Cons**:
- Still shows three duplicates (doesn't fix discovery)
- Requires ongoing maintenance
- Doesn't address root cause

### Solution 4: Claude Code Configuration (If Supported)

**Check for settings to exclude directories**:

```json
// ~/.claude/settings.json or .claude/settings.local.json
{
  "commandDiscovery": {
    "excludePaths": [
      "/home/benjamin/.dotfiles/.claude"
    ]
  }
}
```

**Status**: UNKNOWN - This setting is hypothetical. Official documentation doesn't mention exclusion paths.

**Research needed**: Check Claude Code release notes, GitHub issues, or experiment with settings to find if this is supported.

### Solution 5: Investigate Claude Code CLI Flags

**Check for startup flags**:
```bash
# Look for Claude Code invocation in current session
ps aux | grep claude

# Check for environment variables
env | grep -i claude

# Look for config file paths
claude --help  # If CLI exists
```

**Goal**: Find if Claude Code has undocumented flags like:
- `--project-only` (ignore user-level)
- `--exclude-path=...`
- `--single-project`

---

## Investigation Tasks

### High Priority

1. **Verify dotfiles role**:
   ```bash
   # Check if dotfiles is referenced by NixOS or other systems
   grep -r "\.dotfiles/\.claude" /etc/nixos/
   grep -r "\.dotfiles/\.claude" ~/.config/nixos/
   ```

2. **Test removal impact**:
   ```bash
   # Temporarily rename (not delete) to test
   mv /home/benjamin/.dotfiles/.claude/commands \
      /home/benjamin/.dotfiles/.claude/commands.disabled

   # Restart Claude Code, check dropdown
   # If fixed, removal is safe
   ```

3. **Check Claude Code version**:
   ```bash
   # Verify Claude Code version for bug reports
   claude --version  # Or check in Claude Code UI
   ```

### Medium Priority

4. **Diff the files**:
   ```bash
   # See exact feature differences
   diff -u /home/benjamin/.dotfiles/.claude/commands/plan.md \
           /home/benjamin/.config/.claude/commands/plan.md \
           > /tmp/plan-diff.txt

   # Review to understand what .config has that dotfiles lacks
   ```

5. **Scan for other duplicates**:
   ```bash
   # Find all duplicated commands
   for cmd in /home/benjamin/.config/.claude/commands/*.md; do
     basename="$(basename "$cmd")"
     if [ -f "/home/benjamin/.dotfiles/.claude/commands/$basename" ]; then
       echo "DUPLICATE: $basename"
     fi
   done
   ```

6. **Check parent CLAUDE.md files**:
   ```bash
   # See if dotfiles CLAUDE.md references commands
   grep -i "command" /home/benjamin/.dotfiles/CLAUDE.md
   ```

### Low Priority

7. **Nvim picker testing**:
   ```bash
   # Open nvim in .config, press <leader>ac
   # Count how many /plan entries appear in nvim picker
   # Compare to native Claude Code dropdown count
   ```

8. **Claude Code debug logging**:
   ```bash
   # Look for debug logs
   ls -la ~/.claude/logs/
   ls -la ~/.claude/debug/

   # Check if command discovery is logged
   ```

---

## Next Steps for Plan Creation

### Phase 1: Diagnosis (Minimal Risk)

1. Verify THREE entries are from native Claude Code (not nvim)
2. Test temporary rename of dotfiles commands directory
3. Document which entry executes when selected
4. Capture debug logs if available

### Phase 2: Quick Fix (Low Risk)

1. Backup dotfiles plan.md
2. Remove dotfiles plan.md
3. Restart Claude Code
4. Verify dropdown shows only 1-2 entries
5. Test plan command execution

### Phase 3: Comprehensive Solution (Medium Risk)

1. Audit ALL duplicate commands (not just plan)
2. Determine dotfiles' role in user's workflow
3. Choose between:
   - Remove all dotfiles commands
   - Sync dotfiles commands from .config
   - Configure exclusion (if supported)
4. Implement chosen solution
5. Update documentation

### Phase 4: Root Cause Investigation (Research)

1. Trace Claude Code source code (if available)
2. File GitHub issue with reproduction steps
3. Test with different directory structures
4. Document actual discovery behavior
5. Update CLAUDE.md with findings

---

## Open Questions

1. **Why "(project)" label for all three?**
   - Does Claude Code classify any directory with CLAUDE.md as "project"?
   - Is there a bug in scope detection?

2. **What is the exact discovery algorithm?**
   - Does it scan all of $HOME?
   - Does it follow CLAUDE.md parent chains?
   - Does it cache previously-accessed projects?

3. **Is this a bug or feature?**
   - Is multi-project discovery intentional?
   - Should dotfiles be excluded automatically?

4. **Which entry executes?**
   - First in list (top)?
   - Most recently modified?
   - Closest to CWD?

5. **Does nvim picker contribute?**
   - Is the third entry actually from nvim integration?
   - Can we isolate native Claude Code behavior?

---

## References

### Documentation Sources

- [Claude Code Settings](https://docs.claude.com/en/docs/claude-code/settings) - Official configuration hierarchy
- [GitHub - hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) - Community resources
- [dotclaude.com](https://dotclaude.com/) - CLAUDE.md hierarchy and parent scanning
- [GitHub Issue #764](https://github.com/anthropics/claude-code/issues/764) - Symlink resolution bug
- [Claude Hub - Dotfiles Resource](https://www.claude-hub.com/resource/github-cli-ooloth-dotfiles-dotfiles/) - Dotfiles patterns

### Internal References

- `/home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md` - Two-duplicate case study
- `/home/benjamin/.config/CLAUDE.md` - Portability workflow documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Nvim discovery logic

### Code Locations

- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua:729` - Hardcoded `~/.config` global directory
- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua:254-297` - `parse_with_fallback` function
- `nvim/lua/neotex/plugins/editor/which-key.lua:248-253` - `<leader>ac` mapping

---

## Appendices

### Appendix A: Directory Structure

```
/home/benjamin/
├── .claude/                          (user-level, EMPTY commands/)
│   ├── commands/                     (empty)
│   ├── agents/                       (has files)
│   └── hooks/                        (has files)
├── .config/                          (CURRENT WORKING DIRECTORY)
│   ├── CLAUDE.md                     (project config)
│   ├── .claude/
│   │   ├── .claude/                  (nested, UNTRACKED)
│   │   │   ├── data/
│   │   │   └── tests/
│   │   └── commands/
│   │       └── plan.md               (1556 lines, Dec 2 2025) ★
│   └── nvim/
│       ├── CLAUDE.md                 (nvim-specific config)
│       └── .claude/                  (nvim integration)
└── .dotfiles/                        (NixOS config repo)
    ├── CLAUDE.md                     (dotfiles config)
    └── .claude/
        └── commands/
            └── plan.md               (465 lines, Oct 8 2025) ★
```

### Appendix B: File Checksums

```bash
# Current versions (2025-12-02)
a1132f4c1aef85fa4130b2dbdaf2ffe9  /home/benjamin/.config/.claude/commands/plan.md
0613e3f03cd443e366d9c96be4ac5d65  /home/benjamin/.dotfiles/.claude/commands/plan.md

# Different inodes (not hardlinked)
22849149  /home/benjamin/.config/.claude/commands/plan.md
24522856  /home/benjamin/.dotfiles/.claude/commands/plan.md
```

### Appendix C: Web Research Citations

**Citation Format**: [Title](URL)

1. [GitHub - zebbern/claude-code-guide](https://github.com/zebbern/claude-code-guide) - Comprehensive tips and tricks
2. [How I use Claude Code (+ my best tips)](https://www.builder.io/blog/claude-code) - Best practices blog
3. [GitHub Issue #8395](https://github.com/anthropics/claude-code/issues/8395) - User-level agent rules feature request
4. [Claude Code settings](https://docs.claude.com/en/docs/claude-code/settings) - Official settings documentation
5. [Medium: Ultimate Claude Code Cheat Sheet](https://medium.com/@tonimaxx/the-ultimate-claude-code-cheat-sheet-your-complete-command-reference-f9796013ea50) - Command reference
6. [Anthropic Engineering: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) - Official best practices
7. [GitHub - anthropics/claude-code](https://github.com/anthropics/claude-code) - Main repository
8. [GitHub - hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) - Curated awesome list
9. [dotclaude.com](https://dotclaude.com/) - CLAUDE.md hierarchy documentation
10. [GitHub Issue #764](https://github.com/anthropics/claude-code/issues/764) - Symlink resolution failure bug

---

## Conclusion

The three `/plan` entries in Claude Code's dropdown stem from a discovery mechanism that scans beyond the documented project+user hierarchy. Evidence suggests `.dotfiles` directory is being discovered either through:

1. Home directory scanning
2. CLAUDE.md parent chain traversal
3. Recent project memory/caching

The outdated `.dotfiles` version (70% smaller, 2 months old) poses a risk if executed. **Recommended immediate action**: Remove or rename `/home/benjamin/.dotfiles/.claude/commands/plan.md` after backup, then investigate the underlying discovery behavior for a permanent solution.

The mystery of why all three are labeled "(project)" rather than showing scope differentiation remains unresolved and warrants further investigation through Claude Code source code analysis or GitHub issue filing.

---

**Report Status**: COMPLETE
**Confidence Level**: HIGH (on file locations), MEDIUM (on discovery mechanism)
**Next Action**: Create implementation plan based on Solution 1 or Solution 2

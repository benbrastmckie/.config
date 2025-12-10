# Unmapped Commands Inventory

**Date**: 2025-12-09
**Topic**: goose.nvim command mapping analysis
**Status**: Research in progress

## Objective
Identify all goose.nvim commands that currently lack key mappings, categorize them by function, and propose new key assignments following the established lowercase naming convention.

## Research Progress
- [x] Locate all Goose* command definitions
- [x] Extract current key mappings
- [x] Compare commands vs mappings
- [x] Categorize unmapped commands
- [x] Propose new key assignments

## Findings

### Research Phase 1: Command Discovery

**Source Files Analyzed**:
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/api.lua` - Main command definitions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` - Plugin configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Key mappings
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/init.lua` - Custom picker command

### All Available Goose Commands (24 total)

**Core Commands**:
1. `Goose` - Open goose. Close if opened
2. `GooseToggleFocus` - Toggle focus between goose and last window
3. `GooseOpenInput` - Opens and focuses on input window on insert mode
4. `GooseOpenInputNewSession` - Opens and focuses on input window (new session)
5. `GooseOpenOutput` - Opens and focuses on output window
6. `GooseClose` - Close UI windows
7. `GooseStop` - Stop goose while it is running

**UI Commands**:
8. `GooseToggleFullscreen` - Toggle between normal and fullscreen mode
9. `GooseTogglePane` - Toggle between input and output panes

**Mode Commands**:
10. `GooseModeChat` - Set goose mode to chat (tool calling disabled)
11. `GooseModeAuto` - Set goose mode to auto (full agent capabilities)

**Configuration Commands**:
12. `GooseConfigureProvider` - Quick provider and model switch
13. `GooseOpenConfig` - Open goose config file

**Session Commands**:
14. `GooseSelectSession` - Select and load a goose session
15. `GooseInspectSession` - Inspect current session as JSON

**Execution Commands**:
16. `GooseRun` - Run goose with a prompt (continue last session)
17. `GooseRunNewSession` - Run goose with a prompt (new session)

**Diff/Review Commands**:
18. `GooseDiff` - Opens a diff tab of modified file since last prompt
19. `GooseDiffNext` - Navigate to next file diff
20. `GooseDiffPrev` - Navigate to previous file diff
21. `GooseDiffClose` - Close diff view tab
22. `GooseRevertAll` - Revert all file changes since last prompt
23. `GooseRevertThis` - Revert current file changes since last prompt
24. `GooseSetReviewBreakpoint` - Set a review breakpoint to track changes

**Custom Commands** (defined in local config):
25. `GooseRecipes` - Open Goose recipe picker (custom neotex implementation)

### Currently Mapped Commands

From `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 362-417):

| Key | Command | Description | Mode |
|-----|---------|-------------|------|
| `<leader>ag` | `Goose` | goose toggle | n, v |
| `<leader>ai` | `GooseOpenInput` | goose input | n |
| `<leader>ao` | `GooseOpenOutput` | goose output | n |
| `<leader>af` | `GooseToggleFullscreen` | goose fullscreen | n |
| `<leader>ad` | `GooseDiff` | goose diff | n |
| `<leader>aA` | `GooseModeAuto` | goose auto mode | n |
| `<leader>aC` | `GooseModeChat` | goose chat mode | n |
| `<leader>aR` | Recipe picker (lua function) | goose run recipe (sidebar) | n |
| `<leader>ab` | Provider status (lua function) | goose backend/provider | n |
| `<leader>aq` | `GooseClose` | goose quit | n |

**Total Mapped**: 10 out of 25 commands (40%)

### Unmapped Commands Analysis

**15 commands currently lack key mappings**:

#### Category 1: Focus/Pane Management (2 commands)
- `GooseToggleFocus` - Toggle focus between goose and last window
- `GooseTogglePane` - Toggle between input and output panes

#### Category 2: Session Management (3 commands)
- `GooseOpenInputNewSession` - Open input with new session
- `GooseSelectSession` - Select and load a session
- `GooseInspectSession` - Inspect current session as JSON

#### Category 3: Execution (3 commands)
- `GooseRun` - Run with prompt (continue session)
- `GooseRunNewSession` - Run with prompt (new session)
- `GooseStop` - Stop goose while running

#### Category 4: Configuration (2 commands)
- `GooseConfigureProvider` - Already mapped to `<leader>ab` (provider status wrapper)
- `GooseOpenConfig` - Open config file

#### Category 5: Diff/Review Navigation (5 commands)
- `GooseDiffNext` - Navigate to next file diff
- `GooseDiffPrev` - Navigate to previous file diff
- `GooseDiffClose` - Close diff view
- `GooseRevertAll` - Revert all file changes
- `GooseRevertThis` - Revert current file changes
- `GooseSetReviewBreakpoint` - Set review breakpoint

**Note**: `GooseConfigureProvider` is technically mapped via the wrapper function at `<leader>ab`, so effectively 14 unmapped commands.

### Proposed New Key Assignments (Lowercase Only)

Following the established convention of lowercase letters within `<leader>a` namespace:

#### High Priority Mappings

| Proposed Key | Command | Description | Category |
|--------------|---------|-------------|----------|
| `<leader>at` | `GooseToggleFocus` | toggle focus | Focus/Pane |
| `<leader>ap` | `GooseTogglePane` | toggle pane | Focus/Pane |
| `<leader>as` | `GooseSelectSession` | select session | Session |
| `<leader>an` | `GooseOpenInputNewSession` | new session input | Session |
| `<leader>aj` | `GooseInspectSession` | inspect session json | Session |
| `<leader>ak` | `GooseStop` | kill/stop goose | Execution |
| `<leader>ar` | `GooseRun` | run with prompt | Execution |
| `<leader>au` | `GooseRunNewSession` | run new session | Execution |
| `<leader>ac` | `GooseOpenConfig` | config file | Configuration |

#### Diff/Review Navigation Mappings

| Proposed Key | Command | Description | Category |
|--------------|---------|-------------|----------|
| `<leader>aj` | `GooseDiffNext` | diff next | Diff/Review |
| `<leader>ak` | `GooseDiffPrev` | diff prev | Diff/Review |
| `<leader>ax` | `GooseDiffClose` | diff close | Diff/Review |
| `<leader>az` | `GooseRevertAll` | revert all changes | Diff/Review |
| `<leader>ah` | `GooseRevertThis` | revert this file | Diff/Review |
| `<leader>aw` | `GooseSetReviewBreakpoint` | set breakpoint | Diff/Review |

### Mapping Conflicts to Resolve

**Current conflicts with existing `<leader>a` mappings**:

1. **`<leader>at`** - Currently mapped to "toggle tts"
   - Proposed: Move TTS toggle to different namespace (perhaps `<leader>r` for run/settings)
   - Alternative: Use `<leader>aT` for Goose toggle focus (but violates lowercase convention)

2. **`<leader>as`** - Currently mapped to "claude sessions"
   - Proposed: Move Claude sessions to `<leader>av` (view sessions) which is already used for view worktrees
   - Alternative: Consolidate Claude session/worktree commands

3. **`<leader>ac`** - Currently mapped to "claude commands"
   - Proposed: Move to `<leader>aL` (Claude launcher) or merge with another Claude command
   - Alternative: Use `<leader>ag` for config (but `ag` is already goose toggle)

4. **`<leader>ar`** - Currently mapped to "restore closed worktree"
   - Proposed: Move Claude worktree restore to different key
   - Alternative: Use `<leader>aR` (but violates lowercase convention and conflicts with recipe picker)

5. **`<leader>an`** - Currently mapped to "new lectic file" (conditional, only in lectic files)
   - Conflict level: Low (only appears in .lec/.md files)
   - Proposed: Keep lectic mapping, Goose mapping takes precedence in non-lectic contexts

### Alternative Lowercase Keys Available

**Currently unused lowercase keys in `<leader>a` namespace**:
- `<leader>ah` - Available (proposed for GooseRevertThis)
- `<leader>aj` - Available (proposed for GooseInspectSession or GooseDiffNext)
- `<leader>ak` - Available (proposed for GooseStop or GooseDiffPrev)
- `<leader>al` - Used conditionally for lectic
- `<leader>an` - Used conditionally for lectic
- `<leader>ap` - Available (proposed for GooseTogglePane)
- `<leader>ar` - Used for restore worktree
- `<leader>as` - Used for claude sessions
- `<leader>at` - Used for toggle tts
- `<leader>au` - Available (proposed for GooseRunNewSession)
- `<leader>aw` - Available (proposed for GooseSetReviewBreakpoint)
- `<leader>ax` - Available (proposed for GooseDiffClose)
- `<leader>ay` - Used for toggle yolo mode
- `<leader>az` - Available (proposed for GooseRevertAll)

### Recommendations

**Option 1: Minimal Disruption** (Keep existing mappings, use only available keys)
- Use available keys: h, j, k, p, u, w, x, z
- Map only highest priority commands
- Leave some commands unmapped

**Option 2: Reorganize AI Namespace** (Recommended)
- Move TTS toggle to `<leader>r` namespace (run/settings)
- Move Claude worktree commands to `<leader>g` namespace (git-related)
- Consolidate Claude session/commands under fewer keys
- Free up `<leader>at`, `<leader>as`, `<leader>ac`, `<leader>ar` for Goose

**Option 3: Subgroups**
- Create `<leader>ag` as goose group trigger (use which-key subgroups)
- Use second-level mappings like `<leader>agt` for toggle focus
- Keeps all goose commands under single prefix
- More hierarchical but requires extra keypress

## Summary

This report identifies **15 unmapped commands** (14 effectively unmapped) out of 25 total goose.nvim commands. Currently only 40% of available commands have key mappings.

**Key Findings**:
1. **Unmapped Categories**:
   - Focus/Pane Management (2 commands)
   - Session Management (3 commands)
   - Execution (3 commands)
   - Configuration (1 command effectively)
   - Diff/Review Navigation (5 commands)

2. **Available Keys**: h, j, k, p, u, w, x, z (8 unused lowercase keys in `<leader>a`)

3. **Conflicts**: Mapping all commands requires resolving conflicts with existing Claude, Lectic, and TTS mappings

4. **Recommended Approach**: Option 2 (Reorganize AI Namespace) provides the cleanest solution by:
   - Moving non-AI commands (TTS) to appropriate namespaces
   - Consolidating related commands (Claude sessions/worktrees)
   - Freeing up keys for comprehensive Goose mapping
   - Maintaining lowercase convention throughout

**Next Steps**:
1. Decide on reorganization strategy (Option 1, 2, or 3)
2. Create implementation plan for key remapping
3. Update which-key.lua with new mappings
4. Update documentation to reflect changes
5. Test for mapping conflicts

## Status
**COMPLETE** - All goose.nvim commands inventoried, current mappings analyzed, conflicts identified, and three reorganization options proposed.

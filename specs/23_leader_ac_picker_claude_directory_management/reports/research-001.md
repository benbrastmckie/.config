# Research Report: Task #23

**Task**: 23 - leader_ac_picker_claude_directory_management
**Started**: 2026-02-02T12:00:00Z
**Completed**: 2026-02-02T12:15:00Z
**Effort**: 1-2 hours (analysis complete)
**Dependencies**: None
**Sources/Inputs**: Neovim picker implementation, .claude/ directory structure
**Artifacts**: specs/23_leader_ac_picker_claude_directory_management/reports/research-001.md
**Standards**: neovim-lua.md, report-format.md

## Executive Summary

- The `<leader>ac` picker currently supports 9 artifact types for display and 11 artifact types for sync operations
- Analysis of .claude/ directory reveals 14 distinct subdirectories, of which 10 contain portable configuration content
- Three gaps identified: agents/, output/, and systemd/ directories are not accessible through the picker
- The picker's "Load All" functionality supports comprehensive sync including context/ and rules/ (not shown in picker UI)

## Context and Scope

The `<leader>ac` keybinding in normal mode triggers `:ClaudeCommands` which opens a Telescope-based picker for browsing and managing Claude artifacts. This research examines whether the picker covers all relevant .claude/ directory contents for configuration portability.

## Findings

### Current Picker Architecture

The picker is implemented at:
- **Entry point**: `nvim/lua/neotex/plugins/editor/which-key.lua:248` - binds `<leader>ac` to `:ClaudeCommands`
- **Picker module**: `nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua`
- **Entry creation**: `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua`
- **Parser**: `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua`
- **Sync operations**: `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

### Artifact Types Currently Displayed in Picker

| Section | Entry Type | File Pattern | Directory |
|---------|------------|--------------|-----------|
| [Commands] | command | *.md | commands/ |
| [Skills] | skill | SKILL.md | skills/skill-*/ |
| [Hook Events] | hook_event | *.sh | hooks/ |
| [Tests] | test | test_*.sh | tests/ |
| [Scripts] | script | *.sh | scripts/ |
| [Templates] | template | *.yaml | templates/ |
| [Lib] | lib | *.sh | lib/ |
| [Docs] | doc | *.md | docs/ |

**Note**: The lib/ directory does not exist in the current .claude/ structure.

### Artifact Types Supported by "Load All" Sync

The sync module (`sync.lua`) supports 11 artifact types for the "Load All" operation:

1. commands (*.md)
2. hooks (*.sh)
3. templates (*.yaml)
4. lib (*.sh) - directory not present in current structure
5. docs (*.md)
6. scripts (*.sh)
7. tests (test_*.sh)
8. skills (*.md, *.yaml)
9. rules (*.md) - NOT displayed in picker UI
10. context (*.md) - NOT displayed in picker UI
11. settings (settings.json) - NOT displayed in picker UI

### Actual .claude/ Directory Structure

```
.claude/
├── agents/                  # Agent definitions (*.md) - NOT in picker
│   ├── archive/
│   ├── document-converter-agent.md
│   ├── general-implementation-agent.md
│   ├── general-research-agent.md
│   ├── latex-implementation-agent.md
│   ├── meta-builder-agent.md
│   ├── neovim-implementation-agent.md
│   ├── neovim-research-agent.md
│   ├── planner-agent.md
│   └── typst-implementation-agent.md
├── commands/                # Slash commands - IN PICKER
├── context/                 # Context documents - IN SYNC (not picker)
│   ├── core/
│   └── project/
├── docs/                    # Documentation - IN PICKER
├── hooks/                   # Event hooks - IN PICKER
├── logs/                    # Runtime logs - NOT portable
├── output/                  # Command output files - NOT in picker
├── rules/                   # Claude Code rules - IN SYNC (not picker)
├── scripts/                 # Standalone scripts - IN PICKER
├── settings.json            # Settings - IN SYNC (not picker)
├── settings.local.json      # Local settings - NOT portable
├── skills/                  # Skills - IN PICKER
├── systemd/                 # Systemd units - NOT in picker
│   ├── claude-refresh.service
│   └── claude-refresh.timer
└── templates/               # Workflow templates - IN PICKER
```

### Gap Analysis

| Directory | Portable | In Picker UI | In Sync | Gap Status |
|-----------|----------|--------------|---------|------------|
| agents/ | Yes | No | No | GAP - missing |
| commands/ | Yes | Yes | Yes | OK |
| context/ | Yes | No | Yes | Partial - sync only |
| docs/ | Yes | Yes | Yes | OK |
| hooks/ | Yes | Yes | Yes | OK |
| logs/ | No | N/A | N/A | N/A - runtime only |
| output/ | Partial | No | No | GAP - could be useful |
| rules/ | Yes | No | Yes | Partial - sync only |
| scripts/ | Yes | Yes | Yes | OK |
| settings.json | Yes | No | Yes | Partial - sync only |
| skills/ | Yes | Yes | Yes | OK |
| systemd/ | Yes | No | No | GAP - missing |
| templates/ | Yes | Yes | Yes | OK |
| tests/ | Yes | Yes | Yes | OK |

### Identified Gaps

1. **agents/** - Agent definitions (9 active agents) are not accessible through the picker. These are critical for configuration portability as they define the AI agent behaviors.

2. **systemd/** - Contains service and timer units for automated refresh. These are portable system integration files.

3. **output/** - Contains command output files (implement.md, plan.md, research.md, etc.). These could be useful for reference or debugging.

4. **context/** - Has 30+ context documents but only accessible via "Load All" sync, not browsable in picker.

5. **rules/** - Has 7 rule files but only accessible via "Load All" sync, not browsable in picker.

### Picker Keybindings

| Key | Action | Scope |
|-----|--------|-------|
| Enter | Execute command / open file | All types |
| Ctrl-l | Load artifact locally | Commands, skills, hooks |
| Ctrl-u | Update from global | All types |
| Ctrl-s | Save to global | All types |
| Ctrl-e | Edit file | All types |
| Ctrl-n | Create new command | Commands |
| Ctrl-r | Run script with args | Scripts |
| Ctrl-t | Run test | Tests |

## Recommendations

### Priority 1: Add agents/ Support

Add a new `[Agents]` section to the picker for browsing and managing agent definitions:
- Entry type: `agent`
- File pattern: `*.md`
- Directory: `agents/`
- Exclude: `archive/` subdirectory

### Priority 2: Add rules/ and context/ to Picker UI

These are currently only in sync operations. Adding them to the picker UI would improve discoverability:
- `[Rules]` section for rules/*.md
- `[Context]` section for context/**/*.md (recursive)

### Priority 3: Consider systemd/ Support

For NixOS/systemd users, having systemd service/timer files in the picker would be useful:
- Entry type: `systemd`
- File patterns: `*.service`, `*.timer`
- Directory: `systemd/`

### Implementation Approach

1. **Parser changes** (`parser.lua`):
   - Add `scan_agents_directory()` function
   - Add `parse_agents_with_fallback()` function
   - Include agents in `get_extended_structure()` return

2. **Entries changes** (`entries.lua`):
   - Add `create_agents_entries()` function
   - Add `create_rules_entries()` function
   - Add `create_context_entries()` function
   - Include new sections in `create_picker_entries()`

3. **Sync changes** (`sync.lua`):
   - Add agents to `scan_all_artifacts()` and `execute_sync()`
   - Add systemd if supporting

4. **Init changes** (`picker/init.lua`):
   - Add action handlers for new entry types

## Decisions

1. agents/ is the highest priority gap as it contains core agent definitions
2. context/ and rules/ should be added to picker for consistency with sync
3. output/ is lower priority as it's more debugging than configuration
4. logs/ is explicitly excluded as it's runtime-only

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking picker UI layout | Low | Medium | Test with many entries |
| Performance with recursive scans | Low | Low | context/ already uses recursive in sync |
| Confusion between similar types | Medium | Low | Clear section headers with descriptions |

## Appendix

### Search Queries Used
- Grep for `leader.*ac` in nvim/
- Glob for `*.lua` in picker module tree
- Bash find for .claude/ directory structure

### Files Examined
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua`

### Current .claude/ Statistics
- Total directories: 14 (excluding archive)
- Portable content directories: 10
- Currently in picker: 7 directories
- Currently in sync: 10 directories
- Gaps requiring picker support: 3 (agents, context UI, rules UI)

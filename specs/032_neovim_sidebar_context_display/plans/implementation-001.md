# Implementation Plan: Task #32

- **Task**: 32 - Improve Neovim sidebar panel to display Claude Code context usage
- **Status**: [COMPLETED]
- **Effort**: 2-3 hours
- **Dependencies**: lualine.nvim, greggh/claude-code.nvim, jq
- **Research Inputs**: [research-001.md](../reports/research-001.md), [research-002.md](../reports/research-002.md), [research-003.md](../reports/research-003.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Implement context usage display for Claude Code terminal buffers in Neovim using a push-based architecture. Claude Code's statusLine hook writes JSON data to a file, Neovim watches the file with `vim.uv.new_fs_event()`, and a custom lualine extension displays context percentage with visual progress bar, token counts, model name, cost, and cursor position.

### Research Integration

- **research-001.md**: Identified Claude Code statusline JSON API with `context_window` data structure and community threshold conventions (Green < 50%, Yellow 50-80%, Red > 80%)
- **research-002.md**: Detailed lualine extension architecture, buffer detection patterns for claude-code terminals, and component structure (line 382 defines target format)
- **research-003.md**: Established push-based architecture using statusLine hook with `vim.uv.new_fs_event()` for efficient file watching without polling

## Goals & Non-Goals

**Goals**:
- Display context usage in lualine for Claude Code terminal buffers
- Show format: `TERMINAL | 42% [████░░░░░░] 85k/200k | Opus | $0.31 | 1234:1`
- Use push-based updates via Claude Code statusLine hook
- Color-code context percentage based on usage thresholds

**Non-Goals**:
- Sidebar panel (research showed lualine approach is cleaner)
- Support for multiple simultaneous Claude instances (future enhancement)
- Polling-based updates (inefficient)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Status file not created initially | Medium | High | Retry loop in setup(), graceful nil return |
| Partial file read during write | Low | Low | Atomic write pattern (write to .tmp, then mv) |
| fs_event not firing on some platforms | Medium | Low | Add FocusGained fallback autocommand |
| JSON parse errors | Low | Low | pcall wrapper, return cached data |

## Implementation Phases

### Phase 1: Claude Code Hook Configuration [NOT STARTED]

**Goal**: Configure Claude Code to push context data to a known file path

**Tasks**:
- [ ] Create statusline push script at `~/.claude/hooks/statusline-push.sh`
- [ ] Make script executable
- [ ] Update `~/.claude/settings.json` with statusLine configuration
- [ ] Test hook by running Claude Code and verifying file creation

**Timing**: 30 minutes

**Files to create**:
- `~/.claude/hooks/statusline-push.sh` - Shell script to write JSON and output Claude display
- `~/.claude/settings.json` - Add/merge statusLine configuration

**Verification**:
- Run Claude Code and verify `/tmp/claude-context.json` is created
- Verify JSON contains `context_window` and `model` fields

---

### Phase 2: Neovim Context Reader Module [NOT STARTED]

**Goal**: Create Lua module to read and cache context data with file watching

**Tasks**:
- [ ] Create `lua/neotex/util/claude-context.lua` module
- [ ] Implement `get_context()` function with caching
- [ ] Implement `invalidate_cache()` function for watcher callbacks
- [ ] Implement `setup()` function with `vim.uv.new_fs_event()` file watcher
- [ ] Add FocusGained fallback autocommand
- [ ] Test module loads without errors

**Timing**: 45 minutes

**Files to create**:
- `lua/neotex/util/claude-context.lua` - Context reader with file watcher

**Verification**:
- `:lua require("neotex.util.claude-context").setup()` runs without error
- `:lua print(vim.inspect(require("neotex.util.claude-context").get_context()))` returns data or nil

---

### Phase 3: Lualine Extension and Integration [NOT STARTED]

**Goal**: Create lualine extension for Claude Code buffers with context display

**Tasks**:
- [ ] Create `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` extension
- [ ] Implement progress bar helper function
- [ ] Implement context component with color thresholds
- [ ] Implement model and cost component
- [ ] Set filetype for Claude terminal buffers in claudecode.lua autocmd
- [ ] Update lualine.lua to remove "terminal" from disabled_buftypes
- [ ] Add claude-code extension to lualine extensions list
- [ ] Initialize claude-context module in claudecode.lua config

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/ai/claudecode.lua` - Add filetype and context module setup
- `lua/neotex/plugins/ui/lualine.lua` - Add extension, adjust disabled_buftypes

**Files to create**:
- `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` - Custom extension

**Verification**:
- Open Claude Code terminal (`:ClaudeCode`)
- Verify lualine shows context display when Claude has context data
- Verify color changes based on percentage thresholds

---

### Phase 4: Testing and Documentation [NOT STARTED]

**Goal**: Verify complete integration and document usage

**Tasks**:
- [ ] Test full workflow: start Claude, verify display updates
- [ ] Test color thresholds at different percentages
- [ ] Test FocusGained fallback works
- [ ] Test graceful handling when no status file exists
- [ ] Verify no errors in `:messages` output
- [ ] Create implementation summary

**Timing**: 30 minutes

**Verification**:
- Full integration test passes
- No Lua errors in headless mode
- Display updates when context changes

## Testing & Validation

- [ ] Shell script creates valid JSON at `/tmp/claude-context.json`
- [ ] Lua module loads: `nvim --headless -c "lua require('neotex.util.claude-context')" -c "q"`
- [ ] Extension loads: `nvim --headless -c "lua require('neotex.plugins.ui.lualine.extensions.claude-code')" -c "q"`
- [ ] Lualine displays context for Claude terminal buffers
- [ ] Colors change at 50% and 80% thresholds
- [ ] No errors when status file missing

## Artifacts & Outputs

- `~/.claude/hooks/statusline-push.sh` - Claude hook script
- `~/.claude/settings.json` - Updated with statusLine config
- `lua/neotex/util/claude-context.lua` - Context reader module
- `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` - Lualine extension
- `lua/neotex/plugins/ai/claudecode.lua` - Modified with filetype and setup
- `lua/neotex/plugins/ui/lualine.lua` - Modified with extension
- `specs/032_neovim_sidebar_context_display/summaries/implementation-summary-YYYYMMDD.md`

## Rollback/Contingency

1. Remove statusLine from `~/.claude/settings.json`
2. Delete `~/.claude/hooks/statusline-push.sh`
3. Delete `lua/neotex/util/claude-context.lua`
4. Delete `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua`
5. Revert changes to `claudecode.lua` and `lualine.lua`
6. Remove `/tmp/claude-context.json`

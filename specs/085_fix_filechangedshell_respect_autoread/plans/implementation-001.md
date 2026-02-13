# Implementation Plan: Task #85

- **Task**: 85 - Fix FileChangedShell autocmd to respect buffer-local autoread setting
- **Status**: [NOT STARTED]
- **Effort**: 0.5 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

The global FileChangedShell autocmd in `lua/neotex/config/autocmds.lua` unconditionally reloads all changed files via `vim.v.fcs_choice = "reload"`, bypassing buffer-local `autoread = false` settings. This causes Himalaya compose buffers to reload despite having autoread explicitly disabled by task 84. The fix requires adding a conditional check for `vim.bo[args.buf].autoread == false` before reloading.

### Research Integration

Research report research-001.md confirmed:
- The FileChangedShell autocmd at lines 68-84 unconditionally sets `fcs_choice = "reload"`
- `vim.v.fcs_choice = ""` prevents automatic reload (desired for autoread=false buffers)
- Task 84 correctly sets `vim.bo[buf].autoread = false` for compose buffers
- The fix is a 2-line change inserting an `elseif` branch

## Goals & Non-Goals

**Goals**:
- Respect buffer-local `autoread = false` settings in FileChangedShell handler
- Preserve existing automatic reload behavior for buffers with autoread enabled (default)
- Fix Himalaya compose buffer header format changes caused by unwanted reloads

**Non-Goals**:
- Modify task 84's implementation (it is correct)
- Add user prompts or notifications for autoread=false buffers
- Change the deleted file handling logic

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking other buffers with explicit autoread=false | Low | Very Low | This is correct behavior - respecting explicit settings |
| Performance impact from additional check | None | None | Single boolean comparison, negligible overhead |

## Implementation Phases

### Phase 1: Modify FileChangedShell Autocmd [NOT STARTED]

**Goal**: Add conditional check for buffer-local autoread before reloading

**Tasks**:
- [ ] Add `elseif vim.bo[args.buf].autoread == false then` branch before the else
- [ ] Set `vim.v.fcs_choice = ""` for autoread=false buffers (no reload)
- [ ] Add comment explaining the behavior

**Timing**: 10 minutes

**Files to modify**:
- `lua/neotex/config/autocmds.lua` - Add autoread check in FileChangedShell callback (lines 79-82)

**Verification**:
- Lua syntax check passes (`nvim --headless -c "luafile lua/neotex/config/autocmds.lua" -c "q"`)
- Module loads without errors

---

### Phase 2: Verify Implementation [NOT STARTED]

**Goal**: Confirm the fix works correctly for both autoread=true and autoread=false buffers

**Tasks**:
- [ ] Test that normal buffers still auto-reload on external changes (existing behavior preserved)
- [ ] Test that buffers with explicit `autoread = false` do not reload on external changes
- [ ] Verify Neovim starts without errors

**Timing**: 10 minutes

**Verification**:
- `nvim --headless -c "checkhealth" -c "q"` passes
- Module loads: `nvim --headless -c "lua require('neotex.config.autocmds').setup()" -c "q"`

## Testing & Validation

- [ ] Lua syntax validation passes
- [ ] Module loads without errors in headless mode
- [ ] Neovim checkhealth reports no issues
- [ ] Normal files auto-reload when changed externally (default behavior)
- [ ] Buffers with `autoread = false` do not auto-reload when changed externally

## Artifacts & Outputs

- `lua/neotex/config/autocmds.lua` - Modified FileChangedShell autocmd
- `specs/085_fix_filechangedshell_respect_autoread/summaries/implementation-summary-20260213.md` - Implementation summary

## Rollback/Contingency

If the change causes issues:
1. Revert the autocmds.lua change using git
2. The original behavior (unconditional reload) will be restored
3. No other files are modified by this task

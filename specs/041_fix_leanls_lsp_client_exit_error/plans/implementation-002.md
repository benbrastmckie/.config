# Implementation Plan: Task #41 (Revised)

- **Task**: 41 - fix_leanls_lsp_client_exit_error
- **Status**: [NOT STARTED]
- **Effort**: 30-45 minutes
- **Dependencies**: None (NixOS timezone fix already applied in dotfiles task #17)
- **Research Inputs**: [specs/041_fix_leanls_lsp_client_exit_error/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-002.md (this file)
- **Previous Version**: plans/implementation-001.md (superseded)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Revision Notes

**v002 (2026-02-04)**: Plan revised following completion of dotfiles task #17 which fixed the NixOS `/etc/localtime` issue via `lib.mkForce` in `configuration.nix`. The watchdog error and leanls exit code 1 are now resolved at the system level. This plan now focuses solely on the remaining issue: **Invalid buffer id error** in lean.nvim infoview when closing Lean buffers.

**Removed from scope**:
- Phase 1 (TZ Environment Propagation) - Resolved by NixOS system-level fix
- TZ-related portions of Phase 3 and 4 - No longer needed

**Remaining scope**:
- Buffer validity guard for infoview WinLeave autocmd error

## Overview

This revised plan addresses the remaining error: "Invalid buffer id" in lean.nvim's infoview.lua:964 when closing Lean buffers while the infoview is open. The error occurs in the WinLeave autocmd when the buffer is deleted before the autocmd completes.

### Research Integration

Key findings relevant to remaining issue (from research-001.md):
- Invalid buffer id error occurs at infoview.lua:964 in `__update_extmark_style` function
- The WinLeave autocmd calls `__hide_extmark` which tries to access a deleted buffer
- Neovim's buffer management allows deletion before autocmds complete
- Solution: Add BufDelete autocmd to close infoview before buffer deletion

## Goals & Non-Goals

**Goals**:
- Prevent "Invalid buffer id" errors when closing Lean buffers with infoview open
- Maintain compatibility with existing lean.nvim keymaps and functionality

**Non-Goals**:
- Upstream contribution to lean.nvim (out of scope for this task)
- NixOS system-level configuration changes (already completed in task #17)
- TZ environment variable handling (resolved at system level)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Autocmd modifications may affect infoview behavior | Low | Low | Use pcall and buffer validation guards |
| Local workaround may conflict with lean.nvim updates | Low | Low | Keep changes minimal and isolated |

## Implementation Phases

### Phase 1: Add Buffer Validity Guard [NOT STARTED]

**Goal**: Prevent "Invalid buffer id" errors when closing Lean buffers

**Tasks**:
- [ ] Create BufDelete autocmd in lean_group augroup for lean filetype
- [ ] Close infoview before buffer deletion to avoid WinLeave autocmd error
- [ ] Use pcall wrapper to safely handle any remaining edge cases
- [ ] Add comment documenting the fix and upstream issue reference

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/text/lean.lua` - Add BufDelete autocmd in config function

**Implementation approach**:
```lua
-- In the lean_group augroup, add:
vim.api.nvim_create_autocmd("BufDelete", {
  group = lean_group,
  pattern = "*.lean",
  callback = function(args)
    -- Close infoview before buffer deletion to prevent
    -- "Invalid buffer id" error in WinLeave autocmd
    -- See: lean.nvim infoview.lua:964 __update_extmark_style
    pcall(function()
      local infoview = require("lean.infoview")
      if infoview.get_current_infoview() then
        infoview.close()
      end
    end)
  end,
  desc = "Close infoview before Lean buffer deletion",
})
```

**Verification**:
- Open a Lean file with infoview
- Close the Lean buffer with `<leader>d` or `<leader>k`
- Verify no "Invalid buffer id" error appears

---

### Phase 2: Test and Verify [NOT STARTED]

**Goal**: Comprehensive testing of the buffer validity fix

**Tasks**:
- [ ] Open Lean file and toggle infoview with `<leader>ri`
- [ ] Close Lean buffer with infoview open using `<leader>d`
- [ ] Close Lean buffer with infoview open using `<leader>k`
- [ ] Test closing buffer via `:bd` command
- [ ] Verify no errors in `:messages`
- [ ] Verify infoview can be reopened on new Lean file

**Timing**: 15 minutes

**Files to modify**: None (testing only)

**Verification**:
- All buffer close methods work without errors
- No "Invalid buffer id" notifications
- Infoview continues to function normally

## Testing & Validation

- [ ] Close Lean buffer with infoview open - no "Invalid buffer id" error
- [ ] All keybinding close methods work (`<leader>d`, `<leader>k`, `:bd`)
- [ ] Infoview can be reopened after buffer close
- [ ] No regressions in normal lean.nvim functionality

## Artifacts & Outputs

- `lua/neotex/plugins/text/lean.lua` (modified) - BufDelete autocmd added
- `specs/041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-YYYYMMDD.md` - Summary of changes

## Rollback/Contingency

If the changes cause issues:
1. Revert changes to lean.lua: `git checkout lua/neotex/plugins/text/lean.lua`
2. Manual workaround: Close infoview (`<leader>ri`) before closing Lean buffers

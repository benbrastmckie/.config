# Implementation Plan: Task #41 (Revised v3)

- **Task**: 41 - fix_leanls_lsp_client_exit_error
- **Status**: [NOT STARTED]
- **Effort**: 45-60 minutes
- **Dependencies**: None
- **Research Inputs**:
  - [research-001.md](../reports/research-001.md) - Root cause analysis
  - [research-002.md](../reports/research-002.md) - NixOS /etc/localtime alternatives
- **Artifacts**: plans/implementation-003.md (this file)
- **Previous Versions**:
  - plans/implementation-001.md (superseded - included TZ fix)
  - plans/implementation-002.md (superseded - lacked tmpfiles recommendation)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Revision Notes

**v003 (2026-02-04)**: Plan revised based on supplementary research (research-002.md) comparing NixOS /etc/localtime alternatives. Added optional Phase 0 for implementing the recommended `systemd.tmpfiles.rules` approach as an alternative to the current `lib.mkForce` solution.

**Key insight from research-002.md**:
- `systemd.tmpfiles.rules` creates the symlink while preserving automatic-timezoned functionality
- Current `lib.mkForce` defeats location-based timezone detection
- Both approaches are valid; tmpfiles is cleaner for multi-timezone users

**Scope**:
- **Phase 0 (Optional)**: NixOS tmpfiles.rules configuration (cleaner /etc/localtime solution)
- **Phase 1 (Required)**: Buffer validity guard for infoview error
- **Phase 2 (Required)**: Testing and verification

## Overview

This plan addresses two related issues:

1. **NixOS /etc/localtime** (Optional): The current `lib.mkForce` fix works but disables automatic timezone detection. Research-002.md recommends `systemd.tmpfiles.rules` as a cleaner alternative that creates the symlink while preserving automatic-timezoned functionality.

2. **Invalid buffer id error** (Required): lean.nvim's infoview.lua:964 throws "Invalid buffer id" when closing Lean buffers while the infoview is open.

## Goals & Non-Goals

**Goals**:
- (Optional) Implement cleaner NixOS /etc/localtime solution via tmpfiles.rules
- Prevent "Invalid buffer id" errors when closing Lean buffers with infoview open
- Maintain compatibility with existing lean.nvim keymaps and functionality

**Non-Goals**:
- Upstream contribution to lean.nvim (out of scope)
- Modifying automatic-timezoned behavior

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| tmpfiles may conflict with timedated | Medium | Low | Test with nixos-rebuild test; revert to lib.mkForce if issues |
| Autocmd modifications may affect infoview | Low | Low | Use pcall and buffer validation guards |
| Local workaround may conflict with lean.nvim updates | Low | Low | Keep changes minimal and isolated |

## Implementation Phases

### Phase 0: NixOS tmpfiles.rules Configuration [OPTIONAL] [NOT STARTED]

**Goal**: Replace `lib.mkForce` with cleaner `tmpfiles.rules` approach that works with automatic-timezoned

**Decision point**: Skip this phase if you want to keep the current `lib.mkForce` solution.

**Tasks**:
- [ ] Edit configuration.nix to add systemd.tmpfiles.rules
- [ ] Remove or comment out `time.timeZone = lib.mkForce "America/Los_Angeles"`
- [ ] Run `nixos-rebuild test` to verify
- [ ] Run `nixos-rebuild switch` to apply

**Timing**: 15 minutes

**Files to modify** (in ~/.dotfiles or NixOS config):
- `configuration.nix` - Add tmpfiles.rules, modify time.timeZone

**Implementation**:
```nix
# configuration.nix
{
  services.automatic-timezoned.enable = true;

  # Create /etc/localtime symlink for apps that need it
  # automatic-timezoned will update TZ via timedated, but some apps
  # (like lean4/lake) check /etc/localtime directly
  systemd.tmpfiles.rules = [
    # L+ = create symlink, replace if exists
    # Use UTC as fallback - automatic-timezoned updates via timedated
    "L+ /etc/localtime - - - - /etc/zoneinfo/UTC"
  ];

  # Remove or comment out the forced timezone
  # time.timeZone = lib.mkForce "America/Los_Angeles";  # No longer needed
}
```

**Verification**:
- `ls -la /etc/localtime` shows symlink exists
- `timedatectl status` shows timezone
- Open Lean file - no watchdog errors

**Rollback**: If issues arise, restore `time.timeZone = lib.mkForce "America/Los_Angeles"` and remove tmpfiles.rules.

---

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

**Goal**: Comprehensive testing of all fixes

**Tasks**:
- [ ] Open Lean file and toggle infoview with `<leader>ri`
- [ ] Close Lean buffer with infoview open using `<leader>d`
- [ ] Close Lean buffer with infoview open using `<leader>k`
- [ ] Test closing buffer via `:bd` command
- [ ] Verify no errors in `:messages`
- [ ] Verify infoview can be reopened on new Lean file
- [ ] (If Phase 0 done) Verify no watchdog errors in LSP log
- [ ] (If Phase 0 done) Verify timezone detection still works after travel/VPN

**Timing**: 15 minutes

**Files to modify**: None (testing only)

**Verification**:
- All buffer close methods work without errors
- No "Invalid buffer id" notifications
- Infoview continues to function normally
- (Optional) No watchdog errors, timezone detection works

## Testing & Validation

- [ ] Close Lean buffer with infoview open - no "Invalid buffer id" error
- [ ] All keybinding close methods work (`<leader>d`, `<leader>k`, `:bd`)
- [ ] Infoview can be reopened after buffer close
- [ ] No regressions in normal lean.nvim functionality
- [ ] (If Phase 0) `ls -la /etc/localtime` shows valid symlink
- [ ] (If Phase 0) No watchdog errors in ~/.local/state/nvim/lsp.log

## Artifacts & Outputs

- `lua/neotex/plugins/text/lean.lua` (modified) - BufDelete autocmd added
- (Optional) `configuration.nix` (modified) - tmpfiles.rules added
- `specs/041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-YYYYMMDD.md` - Summary of changes

## Rollback/Contingency

**For Phase 0 (NixOS)**:
1. Restore `time.timeZone = lib.mkForce "America/Los_Angeles"`
2. Remove `systemd.tmpfiles.rules` entry
3. Run `nixos-rebuild switch`

**For Phase 1 (Neovim)**:
1. Revert changes to lean.lua: `git checkout lua/neotex/plugins/text/lean.lua`
2. Manual workaround: Close infoview (`<leader>ri`) before closing Lean buffers

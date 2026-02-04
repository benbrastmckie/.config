# Implementation Plan: Task #41

- **Task**: 41 - fix_leanls_lsp_client_exit_error
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [specs/041_fix_leanls_lsp_client_exit_error/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

This plan addresses three related errors when working with Lean files in Neovim: (1) watchdog error due to missing `/etc/localtime` on NixOS, (2) leanls exit code 1 caused by timezone issues affecting lake, and (3) invalid buffer id error in infoview.lua when closing Lean buffers. The research identified that the current TZ environment fix in lean.lua only applies to leanls but not lake subprocesses, and the buffer error requires a defensive guard when closing buffers with infoview open.

### Research Integration

Key findings from research-001.md:
- NixOS does not create `/etc/localtime`; Lean toolchain requires TZ environment variable
- Current fix in lean.lua (lines 103-109) sets TZ for leanls but lake workers do not inherit it
- Invalid buffer id error occurs in WinLeave autocmd when buffer is deleted while infoview is open
- Neovim 0.11.6 fixed some LSP buffer id issues, but lean.nvim's buffer management needs local workaround

## Goals & Non-Goals

**Goals**:
- Ensure TZ environment variable propagates to all Lean toolchain processes (leanls, lake, workers)
- Prevent "Invalid buffer id" errors when closing Lean buffers with infoview open
- Maintain compatibility with existing lean.nvim keymaps and functionality

**Non-Goals**:
- Upstream contribution to lean.nvim (out of scope for this task)
- NixOS system-level configuration changes (recommend in docs only)
- Modifying lake or Lean toolchain behavior

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| TZ setting may not propagate to all subprocesses | Medium | Medium | Test with `lake build` command verification |
| Local workaround may conflict with lean.nvim updates | Low | Low | Keep changes minimal and isolated |
| Autocmd modifications may affect infoview behavior | Low | Low | Use pcall and buffer validation guards |

## Implementation Phases

### Phase 1: Enhance TZ Environment Propagation [NOT STARTED]

**Goal**: Ensure timezone environment variable is available to all Lean processes

**Tasks**:
- [ ] Add global TZ environment variable via `vim.env.TZ` before lean.nvim setup
- [ ] Verify TZ is inherited by setting it early in config function
- [ ] Add comment documenting NixOS-specific timezone fix

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/text/lean.lua` - Enhance TZ configuration

**Verification**:
- Open a Lean file and check LSP log for absence of watchdog errors
- Verify leanls starts without exit code 1

---

### Phase 2: Add Buffer Validity Guard [NOT STARTED]

**Goal**: Prevent "Invalid buffer id" errors when closing Lean buffers

**Tasks**:
- [ ] Create autocmd to close infoview before buffer deletion
- [ ] Add BufDelete autocmd in lean_group for lean filetype
- [ ] Use pcall to safely handle any remaining edge cases

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/text/lean.lua` - Add BufDelete autocmd

**Verification**:
- Open a Lean file with infoview
- Close the Lean buffer with `<leader>d` or `<leader>k`
- Verify no "Invalid buffer id" error appears

---

### Phase 3: Add Documentation and Fallback [NOT STARTED]

**Goal**: Document the fixes and add a manual workaround note

**Tasks**:
- [ ] Add comment block explaining the NixOS timezone issue and workaround
- [ ] Add comment noting the buffer validity fix and upstream issue reference
- [ ] Add troubleshooting section in the file's header comments

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/text/lean.lua` - Update documentation comments

**Verification**:
- Review comments for clarity and completeness
- Ensure upstream issue references are included

---

### Phase 4: Test and Verify [NOT STARTED]

**Goal**: Comprehensive testing of all fixes

**Tasks**:
- [ ] Open Lean file and verify no watchdog errors in `~/.local/state/nvim/lsp.log`
- [ ] Test infoview toggle with `<leader>ri`
- [ ] Close Lean buffer with infoview open and verify no errors
- [ ] Run `:checkhealth` to verify overall Neovim health
- [ ] Test `lake build` in a Lean project to verify TZ propagation

**Timing**: 25 minutes

**Files to modify**: None (testing only)

**Verification**:
- All tests pass without errors
- LSP log shows clean startup
- No error notifications during buffer close

## Testing & Validation

- [ ] Open Lean file - no watchdog errors in LSP log
- [ ] leanls starts successfully (no exit code 1)
- [ ] Close Lean buffer with infoview open - no "Invalid buffer id" error
- [ ] `:checkhealth` passes
- [ ] `lake build` executes without timezone-related errors

## Artifacts & Outputs

- `lua/neotex/plugins/text/lean.lua` (modified) - Enhanced configuration with fixes
- `specs/041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-YYYYMMDD.md` - Summary of changes

## Rollback/Contingency

If the changes cause issues:
1. Revert changes to lean.lua using git: `git checkout lua/neotex/plugins/text/lean.lua`
2. Manual workaround: Close infoview (`<leader>ri`) before closing Lean buffers
3. Alternative: Set TZ in shell profile (`export TZ="UTC"` in ~/.bashrc or ~/.zshrc)

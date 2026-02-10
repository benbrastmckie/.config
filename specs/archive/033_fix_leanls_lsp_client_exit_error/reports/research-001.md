# Research Report: Task #41

**Task**: 41 - fix_leanls_lsp_client_exit_error
**Started**: 2026-02-04T12:00:00Z
**Completed**: 2026-02-04T12:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: LSP log analysis, lean.nvim source code, GitHub issues, NixOS timezone documentation
**Artifacts**: This report
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The **watchdog error** (`/etc/localtime` not found) is a NixOS-specific issue where `/etc/localtime` does not exist. The current fix in `lean.lua` sets `TZ` for `leanls` but lake spawns subprocesses that don't inherit this.
- The **leanls exit code 1** error is typically caused by lake build failures or environment issues, often related to the same timezone problem.
- The **Invalid buffer id** error in `infoview.lua:964` occurs when closing a Lean buffer while the infoview is open - the WinLeave autocmd tries to update extmarks on a deleted buffer.

## Context & Scope

The user reported three related errors when working with Lean files in Neovim:

1. `Client leanls quit with exit code 1 and signal 0`
2. `Watchdog error: no such file or directory (error code: 2), file: /etc/localtime`
3. WinLeave autocommand error in `lean.nvim infoview.lua:964` with "Invalid buffer id" when killing buffer

This research investigates the root causes and proposes fixes for the Neovim configuration.

## Findings

### 1. Watchdog Error - /etc/localtime Not Found

**Root Cause**: NixOS does not create `/etc/localtime` by default. Instead, it uses the `TZ` environment variable for timezone configuration. Verified on this system:

```
$ ls -la /etc/localtime
ls: cannot access '/etc/localtime': No such file or directory
```

The Lean toolchain (specifically lake's watchdog process) attempts to access `/etc/localtime` for timezone operations and fails.

**Current Configuration**: The lean.lua config (lines 103-109) already has a partial fix:

```lua
vim.lsp.config('leanls', {
  cmd_env = {
    TZ = os.getenv("TZ") or "UTC"
  }
})
```

**Problem**: This only sets the environment for the main `leanls` process, but lake spawns subprocesses (workers, watchdogs) that may not inherit this environment variable.

**Solution**: Need to ensure TZ is set globally for the entire Lean toolchain. Options:
1. Set `TZ` in the shell environment (system-wide or in shell config)
2. Configure NixOS to create `/etc/localtime` symlink via `time.timeZone`
3. Pass additional environment variables through lean.nvim's configuration

**References**:
- [NixOS nixpkgs PR #113555](https://github.com/NixOS/nixpkgs/pull/113555) - NixOS locale TZ handling
- [NixOS nixpkgs issue #67673](https://github.com/NixOS/nixpkgs/issues/67673) - systemd-timedated localtime issue

### 2. leanls Exit Code 1

**Root Cause**: The leanls language server exits with code 1 when it fails to initialize properly. This is typically caused by:
1. Lake build failures (often related to the timezone issue above)
2. Missing dependencies or toolchain issues
3. Project configuration problems

**Correlation**: The LSP log shows a clear pattern - watchdog errors occur, then leanls exits. The timezone issue is likely the primary cause.

**References**:
- [lean.nvim issue #260](https://github.com/Julian/lean.nvim/issues/260) - Lean 4 server crashing
- [lean.nvim issue #322](https://github.com/Julian/lean.nvim/issues/322) - Client quit with exit code

### 3. Invalid Buffer ID Error on WinLeave

**Error Location**: `infoview.lua:964`

**Stack Trace Analysis**:
```lua
-- Line 964 in infoview.lua
local extmark_pos = buffer:extmark(self.__extmark_ns, self.__extmark, {})
```

This calls `vim.api.nvim_buf_get_extmark_by_id()` which requires a valid buffer ID.

**Root Cause**: The WinLeave autocommand (line 686 in infoview.lua) triggers when leaving the infoview window:

```lua
pin_buffer:create_autocmd('WinLeave', {
  group = pin_augroup,
  callback = function()
    new_info.pin:__hide_extmark()
  end,
})
```

When the user kills a Lean buffer (via `<leader>d` or `<leader>k`), the following sequence occurs:
1. Buffer deletion triggers window close events
2. WinLeave fires for the infoview
3. `__hide_extmark()` calls `__update_extmark_style()`
4. `__update_extmark_style()` attempts to access `self.__extmark_buffer` which may reference the deleted buffer
5. `nvim_buf_get_extmark_by_id()` fails with "Invalid buffer id"

**Relevant Issue**: [lean.nvim issue #188](https://github.com/Julian/lean.nvim/issues/188) - "Weird Error message when closing a lean file occasionally"

**Workaround**: Close the infoview (with `<LocalLeader>i` or `<leader>ri`) before closing the Lean buffer.

**Proper Fix**: The `__update_extmark_style()` function should validate buffer validity before accessing it:

```lua
function Pin:__update_extmark_style(buffer, line, col)
  if not buffer then
    if not self.__extmark then
      return
    end
    buffer = self.__extmark_buffer
    -- ADD: Check if buffer is still valid
    if not buffer or not vim.api.nvim_buf_is_valid(buffer.bufnr) then
      return
    end
    local extmark_pos = buffer:extmark(self.__extmark_ns, self.__extmark, {})
    -- ...
  end
end
```

### 4. Neovim Version Compatibility

**Current Version**: Neovim v0.11.6

The system is running Neovim 0.11.6, which fixed some LSP-related "Invalid buffer id" issues in v0.11.3. The remaining issue is specific to lean.nvim's buffer management, not Neovim core.

## Recommendations

### Immediate Fixes (Configuration Changes)

1. **Fix Timezone for Entire Lean Environment**:
   Add to shell configuration (`~/.bashrc`, `~/.zshrc`, or NixOS config):
   ```bash
   export TZ="America/Los_Angeles"  # or your timezone
   ```

   Or in NixOS `configuration.nix`:
   ```nix
   time.timeZone = "America/Los_Angeles";
   ```

2. **Add Buffer Validity Check in lean.lua**:
   Wrap the infoview operations in a protected call or add an autocmd to close infoview when Lean buffers are deleted.

3. **Workaround for Invalid Buffer Error**:
   Close infoview before closing Lean files using `<leader>ri`.

### Long-term Fix (Upstream Contribution)

Submit a PR to lean.nvim to add buffer validity checks in `Pin:__update_extmark_style()` and `Pin:__hide_extmark()` functions.

## Decisions

1. **Timezone Fix Approach**: Recommend system-level TZ configuration (either shell or NixOS) rather than trying to pass it through Neovim config, as lake subprocesses need it too.

2. **Buffer Error Mitigation**: Implement a local workaround in the Neovim config rather than waiting for upstream fix.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| TZ setting doesn't propagate to lake workers | Medium | Test with `lake build` in terminal first |
| Local workaround may conflict with future lean.nvim updates | Low | Keep workaround minimal, monitor upstream |
| NixOS config changes require rebuild | Low | Document both shell and NixOS approaches |

## Appendix

### LSP Log Evidence

The LSP log at `~/.local/state/nvim/lsp.log` shows consistent watchdog errors:

```
[ERROR][2026-02-04 18:52:05] .../lean/stderr.lua:92  "rpc"  "lake"  "stderr"
"Watchdog error: no such file or directory (error code: 2)\n  file: /etc/localtime\n"
```

These errors appear throughout January and February 2026, correlating with Lean file usage.

### Affected Files

- `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua` - Lean plugin configuration
- `/home/benjamin/.local/share/nvim/lazy/lean.nvim/lua/lean/infoview.lua` - Upstream plugin (line 964)

### Search Queries Used

1. "lean.nvim leanls exit code 1 LSP client quit error"
2. "lean4 lake watchdog error no such file or directory /etc/localtime NixOS"
3. "lean.nvim infoview.lua Invalid buffer id WinLeave autocommand error"

### References

- [lean.nvim GitHub](https://github.com/Julian/lean.nvim)
- [lean.nvim issue #188](https://github.com/Julian/lean.nvim/issues/188) - Buffer closing error
- [lean.nvim issue #260](https://github.com/Julian/lean.nvim/issues/260) - Server crashing
- [lean.nvim issue #342](https://github.com/Julian/lean.nvim/issues/342) - Neovim 0.11 deprecations
- [Neovim issue #35146](https://github.com/neovim/neovim/issues/35146) - LSP Invalid buffer id (fixed in 0.11.3)
- [leanprover/lean4 issue #1219](https://github.com/leanprover/lean4/issues/1219) - Watchdog getting stuck
- [NixOS nixpkgs issue #67673](https://github.com/NixOS/nixpkgs/issues/67673) - localtime issues

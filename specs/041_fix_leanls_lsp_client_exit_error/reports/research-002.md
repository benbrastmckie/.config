# Research Report: Task #41 (Supplementary)

**Task**: 41 - fix_leanls_lsp_client_exit_error
**Started**: 2026-02-04T12:00:00Z
**Completed**: 2026-02-04T12:45:00Z
**Effort**: 1 hour
**Dependencies**: None
**Sources/Inputs**: NixOS discourse, GitHub nixpkgs, automatic-timezoned source, systemd tmpfiles documentation
**Artifacts**: This supplementary report
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- Five alternative approaches to fix the missing `/etc/localtime` issue on NixOS
- Current `lib.mkForce` solution is reasonable but not the cleanest
- **Recommended**: `systemd.tmpfiles.rules` approach - works with automatic-timezoned and doesn't require hardcoding timezone
- Neovim-specific `cmd_env` fix is already implemented and serves as defense-in-depth

## Context & Scope

This is supplementary research to research-001.md. The user has already implemented a fix using `lib.mkForce "America/Los_Angeles"` in their NixOS configuration.nix. This research explores whether cleaner alternatives exist that:
1. Work with automatic-timezoned (location-based timezone)
2. Don't require hardcoding a timezone
3. Create the `/etc/localtime` symlink that lean4/lake expects

## Findings

### 1. Current Solution: lib.mkForce in configuration.nix

**Implementation**:
```nix
time.timeZone = lib.mkForce "America/Los_Angeles";
```

**How it works**: The `lib.mkForce` sets priority to 50, overriding automatic-timezoned's `time.timeZone = null` (priority ~1000).

**Trade-offs**:
| Pro | Con |
|-----|-----|
| Simple, single line | Hardcodes timezone (no automatic updates) |
| Creates /etc/localtime symlink | Defeats purpose of automatic-timezoned |
| Sets TZ environment variable | Requires manual update when traveling |

**Verdict**: Works, but undermines location-based timezone detection.

### 2. Alternative: systemd.tmpfiles.rules (RECOMMENDED)

**Implementation**:
```nix
# In configuration.nix
systemd.tmpfiles.rules = [
  "L+ /etc/localtime - - - - /etc/zoneinfo/UTC"
];
```

Or dynamically (requires TZ to be set elsewhere):
```nix
systemd.tmpfiles.rules = [
  "L+ /etc/localtime - - - - /etc/zoneinfo/${config.time.timeZone or "UTC"}"
];
```

**How it works**: systemd-tmpfiles creates the symlink at boot and on-demand. The `L+` modifier replaces existing files.

**Trade-offs**:
| Pro | Con |
|-----|-----|
| Works alongside automatic-timezoned | May conflict with timedated updates |
| No hardcoded timezone (can use UTC) | Requires understanding tmpfiles syntax |
| Standard systemd mechanism | May need additional testing |

**Verdict**: Best balance - creates the symlink apps expect without disabling automatic-timezoned. The symlink serves as fallback for apps that don't check TZ.

**References**:
- [systemd.tmpfiles.rules - MyNixOS](https://mynixos.com/nixpkgs/option/systemd.tmpfiles.rules)
- [tmpfiles.d manpage](https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html)

### 3. Alternative: Home Manager environment.sessionVariables

**Implementation**:
```nix
# In home.nix
home.sessionVariables = {
  TZ = "America/Los_Angeles";  # or :/etc/localtime
};
```

**How it works**: Sets TZ environment variable for all user sessions via shell profile.

**Trade-offs**:
| Pro | Con |
|-----|-----|
| User-level, no system rebuild | Doesn't create /etc/localtime |
| Can use TZ=:/etc/localtime if symlink exists | Only works when shell is sourced |
| Integrates with Home Manager ecosystem | May not propagate to all processes |

**Verdict**: Useful supplement but doesn't solve the core issue (missing symlink). Best used alongside tmpfiles or mkForce.

**References**:
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home-manager not respecting system TZ](https://discourse.nixos.org/t/home-manager-not-respecting-system-tz/12135)

### 4. Alternative: Per-Project direnv Configuration

**Implementation**:
```bash
# .envrc in Lean project root
export TZ="America/Los_Angeles"
```

**How it works**: direnv automatically loads/unloads environment variables when entering/leaving directories.

**Trade-offs**:
| Pro | Con |
|-----|-----|
| Per-project control | Requires .envrc in every project |
| No system-wide changes | Must run `direnv allow` for each project |
| Can commit to git for team use | Doesn't fix /etc/localtime missing |
| Works with nix-direnv integration | Only active in terminal sessions |

**Verdict**: Good for per-project overrides but too granular for this issue. Useful if different Lean projects need different timezones.

**References**:
- [direnv documentation](https://direnv.com/)
- [5 Ways to Manage Environment Variables with direnv](https://www.sixfeetup.com/blog/direnv-manage-environment-variables)

### 5. Alternative: Neovim-specific cmd_env (Already Implemented)

**Current Implementation** (in lean.lua lines 103-109):
```lua
vim.lsp.config('leanls', {
  cmd_env = {
    TZ = os.getenv("TZ") or "UTC"
  }
})
```

**How it works**: Passes TZ environment variable to the leanls LSP process.

**Trade-offs**:
| Pro | Con |
|-----|-----|
| No NixOS config changes | Only affects direct leanls process |
| Defense-in-depth | Lake subprocesses may not inherit |
| Already implemented | Doesn't fix /etc/localtime missing |

**Verdict**: Keep as defense-in-depth. Handles the case where system TZ is not set but user's shell has it defined.

**References**:
- [Neovim LSP docs](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

### 6. Alternative: NixOS Wrapper Script (makeWrapper)

**Implementation** (in a NixOS overlay):
```nix
lean4Wrapped = pkgs.symlinkJoin {
  name = "lean4-wrapped";
  paths = [ pkgs.lean4 ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/lake \
      --set TZ "America/Los_Angeles"
  '';
};
```

**Trade-offs**:
| Pro | Con |
|-----|-----|
| Isolated to lean toolchain | Complex Nix expression |
| No global changes | Must maintain wrapper |
| Survives system updates | May not cover all lean binaries |

**Verdict**: Overkill for this issue. Useful if lean specifically needs different behavior.

**References**:
- [makeWrapper and wrapProgram](https://gist.github.com/CMCDragonkai/9b65cbb1989913555c203f4fa9c23374)

### 7. Automatic-timezoned Behavior Analysis

**Key finding**: automatic-timezoned explicitly sets `time.timeZone = null` to allow dynamic updates via systemd-timedated. This intentionally prevents `/etc/localtime` from being created at system activation time.

The daemon:
1. Uses geoclue2 for location detection
2. Calls systemd-timedated to update timezone
3. timedated would normally update /etc/localtime, but NixOS's read-only /etc handling interferes

**Why the symlink is missing**: When `time.timeZone = null`, NixOS's timezone.nix module does not create `/etc/localtime`. This is by design - the expectation is that timedated manages it dynamically.

**The gap**: On NixOS, timedated can update the timezone (via dbus), but the actual /etc/localtime symlink creation may fail or be inconsistent due to NixOS's declarative /etc management.

**References**:
- [automatic-timezoned GitHub](https://github.com/maxbrunet/automatic-timezoned)
- [NixOS nixpkgs timezone.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/timezone.nix)

## Comparison Matrix

| Approach | Creates Symlink | Works with auto-tz | Hardcodes TZ | Complexity | Recommendation |
|----------|-----------------|---------------------|--------------|------------|----------------|
| lib.mkForce | Yes | No | Yes | Low | Current solution |
| tmpfiles.rules | Yes | Yes | Optional | Medium | **RECOMMENDED** |
| Home Manager vars | No | Yes | Yes | Low | Supplement only |
| direnv | No | N/A | Per-project | Low | Too granular |
| cmd_env (Neovim) | No | N/A | Fallback | Low | Keep as defense |
| makeWrapper | No | N/A | Yes | High | Overkill |

## Recommended Implementation

### Primary: systemd.tmpfiles.rules

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
}
```

**Testing required**: Verify that automatic-timezoned's timedated calls properly update the symlink after tmpfiles creates it.

### Secondary: Keep Neovim cmd_env

The existing lean.lua fix provides defense-in-depth. Keep it as-is:
```lua
vim.lsp.config('leanls', {
  cmd_env = {
    TZ = os.getenv("TZ") or "UTC"
  }
})
```

## Decisions

1. **tmpfiles.rules over lib.mkForce**: The tmpfiles approach works with automatic-timezoned rather than against it.

2. **Keep existing Neovim fix**: Defense-in-depth is valuable. The cmd_env fix handles edge cases where system TZ isn't propagated.

3. **UTC as fallback**: Using UTC for the initial symlink is safe - automatic-timezoned will update it if location is detected.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| tmpfiles may conflict with timedated | Medium | Test after implementation; revert to lib.mkForce if issues |
| geoclue2 not providing location | Low | UTC fallback is reasonable; lean doesn't need accurate time |
| Symlink not updating on timezone change | Low | Restart timedated service; or use lib.mkForce as backup |

## Next Steps

1. Test `systemd.tmpfiles.rules` approach with `nixos-rebuild test`
2. Verify lean4 builds work after the change
3. Monitor for timedated interaction issues
4. Document chosen approach in implementation plan

## Appendix

### Search Queries Used

1. "NixOS automatic-timezoned /etc/localtime missing symlink issue 2025"
2. "NixOS time.timeZone null automatic-timezoned workaround 2025"
3. "NixOS systemd tmpfiles /etc/localtime symlink alternative"
4. "lean4 lake TZ environment variable timezone configuration"
5. "neovim lspconfig cmd_env TZ timezone LSP configuration"
6. "Home Manager environment.variables TZ timezone NixOS"
7. "NixOS makeWrapper wrapProgram environment variable TZ"

### References

- [services.automatic-timezoned.enable - MyNixOS](https://mynixos.com/nixpkgs/option/services.automatic-timezoned.enable)
- [automatic-timezoned GitHub](https://github.com/maxbrunet/automatic-timezoned)
- [systemd.tmpfiles.rules - MyNixOS](https://mynixos.com/nixpkgs/option/systemd.tmpfiles.rules)
- [tmpfiles.d manpage](https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [direnv documentation](https://direnv.com/)
- [NixOS nixpkgs timezone.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/timezone.nix)
- [localtimed fails to set time zone - Issue #68489](https://github.com/NixOS/nixpkgs/issues/68489)
- [systemd-timedated missing /etc/localtime - Issue #67673](https://github.com/NixOS/nixpkgs/issues/67673)
- [NixOS locale TZ handling - PR #113555](https://github.com/NixOS/nixpkgs/pull/113555)

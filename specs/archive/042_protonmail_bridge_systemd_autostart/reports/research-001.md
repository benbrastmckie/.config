# Research Report: Task #52

**Task**: ProtonMail Bridge systemd autostart configuration
**Date**: 2026-02-10
**Focus**: systemd user service best practices, ProtonMail Bridge requirements and configuration

## Summary

This research identifies the optimal approach for creating a systemd user service to auto-start ProtonMail Bridge on login. The system already has ProtonMail Bridge v3.21.2 installed via Nix, with existing mbsync and Himalaya configurations that depend on it running. The recommended approach is to add a home-manager systemd user service configuration to the existing `~/.dotfiles/home.nix` file, following the pattern already established for ydotool and gmail-oauth2-refresh services.

## Findings

### 1. Current System State

**ProtonMail Bridge Installation**:
- Installed at `/home/benjamin/.nix-profile/bin/protonmail-bridge`
- Version: 3.21.2
- Config directory: `~/.config/protonmail/bridge-v3/`
- Data directory: `~/.local/share/protonmail/bridge-v3/`
- Vault and keychain already configured (vault.enc, keychain.json present)

**Existing Email Infrastructure**:
- mbsync configured in `~/.mbsyncrc` with logos account connecting to 127.0.0.1:1143
- Himalaya configured in `~/.config/himalaya/config.toml` with logos SMTP via 127.0.0.1:1025
- Password stored in GNOME keyring: `secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai`

**Desktop Environment**:
- NixOS with GNOME desktop
- Home-manager managing user services
- Existing systemd user services: ydotool, gmail-oauth2-refresh

### 2. ProtonMail Bridge CLI Options

The bridge supports several relevant flags:
- `--noninteractive, -n` - Start in non-interactive mode (required for systemd)
- `--log-level, -l value` - Set log level (panic, fatal, error, warn, info, debug)
- `--cli, -c` - Start command line interface (for initial setup only)
- `--grpc, -g` - Start gRPC service

For systemd service operation, use `protonmail-bridge --noninteractive`.

### 3. Systemd User Service Best Practices

**Service File Locations** (ascending precedence):
1. `/usr/lib/systemd/user/` - Package-provided units
2. `~/.local/share/systemd/user/` - Home directory packages
3. `/etc/systemd/user/` - System-wide user units
4. `~/.config/systemd/user/` - User's personal units (home-manager uses this)

**Key Service Configuration Options**:
- `After=graphical-session.target` - Ensures graphical session is ready (keyring available)
- `WantedBy=default.target` or `WantedBy=graphical-session.target` - Auto-start on login
- `Restart=always` - Auto-restart on failure
- `Type=simple` - Standard daemon type

**Environment Considerations**:
- User services do NOT inherit environment from `.bashrc` or `.profile`
- Use `systemd.user.sessionVariables` in home-manager for environment
- GNOME keyring is accessible after graphical-session.target

### 4. Home-Manager Integration Pattern

The existing `home.nix` already defines two systemd user services:

```nix
# Existing pattern from home.nix
systemd.user.services.ydotool = {
  Unit = {
    Description = "ydotool daemon for input automation";
    After = [ "graphical-session.target" ];
  };
  Service = {
    Type = "simple";
    ExecStart = "${pkgs.ydotool}/bin/ydotoold";
    Restart = "on-failure";
    Environment = "PATH=/run/current-system/sw/bin";
  };
  Install = {
    WantedBy = [ "default.target" ];
  };
};
```

This pattern should be followed for the ProtonMail Bridge service.

### 5. ProtonMail Bridge Specific Requirements

**Authentication Flow**:
1. Initial setup requires GUI or CLI interactive mode
2. After login, credentials stored in vault.enc (already done)
3. Non-interactive mode uses stored credentials

**Port Binding**:
- IMAP: 127.0.0.1:1143
- SMTP: 127.0.0.1:1025

**Dependencies**:
- GNOME keyring or pass for credential storage
- Network connectivity (starts after network, but bridge handles offline gracefully)
- Graphical session for keyring access

### 6. Integration with mbsync/Himalaya

**Dependency Chain**:
1. ProtonMail Bridge must start first (systemd service)
2. mbsync connects to local bridge (127.0.0.1:1143)
3. Himalaya sends via bridge (127.0.0.1:1025)

**Readiness Detection**:
- Bridge binds to ports 1143/1025 when ready
- No explicit socket activation support
- Simple approach: rely on mbsync retry logic or add startup delay

### 7. Official Home-Manager Module

Home-manager includes an official protonmail-bridge module at:
`github.com/nix-community/home-manager/blob/master/modules/services/protonmail-bridge.nix`

The module provides:
```nix
services.protonmail-bridge = {
  enable = true;
  logLevel = "info";  # Optional
  # nonInteractive is implicit
}
```

However, this module may not be available in the current home-manager version. A manual service definition provides more control and consistency with existing patterns.

## Recommendations

### Primary Recommendation: Add systemd user service to home.nix

Add the following to `~/.dotfiles/home.nix`:

```nix
# ProtonMail Bridge service for local IMAP/SMTP access
systemd.user.services.protonmail-bridge = {
  Unit = {
    Description = "ProtonMail Bridge - Local IMAP/SMTP server";
    After = [ "graphical-session.target" ];
  };
  Service = {
    Type = "simple";
    ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
    Restart = "on-failure";
    RestartSec = 10;
  };
  Install = {
    WantedBy = [ "default.target" ];
  };
};
```

### Alternative: Use official home-manager module

If the module is available:
```nix
services.protonmail-bridge = {
  enable = true;
  logLevel = "info";
};
```

### Verification Commands

After implementation:
```bash
# Rebuild home-manager configuration
home-manager switch

# Check service status
systemctl --user status protonmail-bridge

# Verify ports are listening
ss -tlnp | grep -E '1143|1025'

# Test mbsync connection
mbsync -V logos-inbox

# View service logs
journalctl --user -u protonmail-bridge -f
```

### Failure Handling

If bridge fails to start:
1. Check logs: `journalctl --user -u protonmail-bridge`
2. Verify vault exists: `ls ~/.config/protonmail/bridge-v3/vault.enc`
3. Test interactive mode: `protonmail-bridge --cli` then `info` command
4. Re-authenticate if needed: `protonmail-bridge` (GUI) or `--cli` + `login`

## References

- [Arch Wiki: systemd/User](https://wiki.archlinux.org/title/Systemd/User) - Comprehensive user service documentation
- [Home-Manager protonmail-bridge module](https://github.com/nix-community/home-manager/blob/master/modules/services/protonmail-bridge.nix) - Official module source
- [NixOS Discourse: Writing a service for protonmail-bridge](https://discourse.nixos.org/t/writing-a-service-for-protonmail-bridge/10623) - Community discussion
- [Headless ProtonBridge Guide](https://ndo.dev/posts/headless_protonbridge) - Server setup reference
- [Baeldung: Creating User Services with systemd](https://www.baeldung.com/linux/systemd-create-user-services) - Best practices guide

## Next Steps

1. Add systemd user service configuration to `~/.dotfiles/home.nix`
2. Rebuild with `home-manager switch`
3. Verify service starts automatically on next login
4. Test email sync with `mbsync logos` and `himalaya list -a logos`
5. Optionally add service notification on failure

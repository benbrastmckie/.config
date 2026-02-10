# ProtonMail Bridge Systemd Setup

**Purpose**: Configuration and management of ProtonMail Bridge as a systemd user service for automatic startup on login.

---

## Overview

ProtonMail Bridge provides local IMAP and SMTP servers that enable standard email clients to work with ProtonMail's encrypted email service. This guide covers the systemd user service configuration that ensures Bridge starts automatically on login.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Login                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              systemd user service                           │
│         protonmail-bridge.service                           │
│                                                             │
│   ExecStart: protonmail-bridge --noninteractive             │
│              --log-level info                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              ProtonMail Bridge                              │
│                                                             │
│   IMAP: 127.0.0.1:1143                                     │
│   SMTP: 127.0.0.1:1025                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌───────────────────┐   ┌───────────────────┐
│     mbsync        │   │    himalaya       │
│   (IMAP sync)     │   │   (IMAP + SMTP)   │
│                   │   │                   │
│ ~/Mail/Logos/     │   │ email compose     │
└───────────────────┘   └───────────────────┘
```

### Key Components

| Component | Purpose | Port |
|-----------|---------|------|
| ProtonMail Bridge | Local IMAP/SMTP proxy | 1143 (IMAP), 1025 (SMTP) |
| systemd user service | Automatic startup | N/A |
| GNOME keyring | Password storage | N/A |
| mbsync | Mail synchronization | Connects to 1143 |
| himalaya | Email client | Connects to 1143, 1025 |

---

## Service Management

### Check Service Status

```bash
# Full status with recent logs
systemctl --user status protonmail-bridge

# Quick status check
systemctl --user is-active protonmail-bridge
```

**Expected Output** (healthy service):
```
● protonmail-bridge.service - ProtonMail Bridge
     Loaded: loaded (/home/benjamin/.config/systemd/user/protonmail-bridge.service; enabled; preset: ignored)
     Active: active (running) since Tue 2026-02-10 12:35:35 PST; 2min ago
   Main PID: 1588062 (protonmail-brid)
```

### Start, Stop, Restart

```bash
# Start service
systemctl --user start protonmail-bridge

# Stop service
systemctl --user stop protonmail-bridge

# Restart service (after config changes)
systemctl --user restart protonmail-bridge
```

### Enable/Disable Automatic Startup

```bash
# Enable on login (current state)
systemctl --user enable protonmail-bridge

# Disable automatic startup
systemctl --user disable protonmail-bridge

# Check if enabled
systemctl --user is-enabled protonmail-bridge
```

---

## Log Inspection

### View Recent Logs

```bash
# Last 50 log entries
journalctl --user -u protonmail-bridge --no-pager -n 50

# Follow logs in real-time
journalctl --user -u protonmail-bridge -f

# Logs since last boot
journalctl --user -u protonmail-bridge -b
```

### Log Locations

| Log Type | Location |
|----------|----------|
| systemd journal | `journalctl --user -u protonmail-bridge` |
| Bridge application logs | `~/.cache/protonmail/bridge-v3/logs/` |

### Common Log Messages

**Normal startup**:
```
Started ProtonMail Bridge.
```

**Keyring warning (non-fatal)**:
```
WARN Failed to add test credentials to keychain error="pass not initialized..."
```
This warning is expected if `pass` is not configured. Bridge falls back to GNOME keyring.

---

## Verification Checklist

After service starts, verify these conditions:

### 1. Service Running

```bash
systemctl --user is-active protonmail-bridge
# Expected: active
```

### 2. Ports Listening

```bash
ss -tlnp | grep -E ':(1143|1025)\s'
```

**Expected Output**:
```
LISTEN 0 4096 127.0.0.1:1025 0.0.0.0:* users:(("protonmail-brid",...))
LISTEN 0 4096 127.0.0.1:1143 0.0.0.0:* users:(("protonmail-brid",...))
```

### 3. Vault File Present

```bash
ls -la ~/.config/protonmail/bridge-v3/vault.enc
```

The `vault.enc` file stores encrypted account credentials.

### 4. Email Clients Connect

```bash
# Test mbsync connection
mbsync -V logos-inbox

# Test himalaya connection
himalaya envelope list -a logos
```

---

## Configuration Reference

### Service File Location

The systemd service is managed by NixOS/home-manager:

```
~/.config/systemd/user/protonmail-bridge.service
```

**Note**: This is a Nix-managed file. Edit your `home.nix` to make changes.

### Current Service Configuration

```ini
[Unit]
Description=ProtonMail Bridge
After=network.target

[Service]
ExecStart=/nix/store/.../bin/protonmail-bridge --noninteractive --log-level info
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

### Key Files

| Purpose | Path |
|---------|------|
| Service file | `~/.config/systemd/user/protonmail-bridge.service` |
| Bridge config | `~/.config/protonmail/bridge-v3/` |
| Vault (credentials) | `~/.config/protonmail/bridge-v3/vault.enc` |
| Bridge logs | `~/.cache/protonmail/bridge-v3/logs/` |
| mbsync config | `~/.mbsyncrc` |
| himalaya config | `~/.config/himalaya/config.toml` |

---

## Integration with Email Stack

### mbsync Configuration

The logos account in `~/.mbsyncrc` connects to Bridge:

```
IMAPAccount logos
Host 127.0.0.1
Port 1143
User benjamin@logos-labs.ai
PassCmd "secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai"
SSLType None
AuthMechs LOGIN
```

**Note**: `SSLType None` is correct because Bridge runs locally. Traffic between Bridge and ProtonMail servers is encrypted.

### himalaya Configuration

The logos account in `~/.config/himalaya/config.toml`:

```toml
[accounts.logos]
email = "benjamin@logos-labs.ai"

# Uses maildir synced by mbsync
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Logos"

# SMTP via Bridge
message.send.backend.type = "smtp"
message.send.backend.host = "127.0.0.1"
message.send.backend.port = 1025
message.send.backend.encryption = "none"
```

### Sync Workflow

1. **Bridge** connects to ProtonMail servers (encrypted)
2. **mbsync** syncs mail from Bridge to local maildir (`~/Mail/Logos/`)
3. **himalaya** reads from maildir and sends via Bridge SMTP

---

## Troubleshooting

### Service Won't Start

**Symptoms**: `systemctl --user status protonmail-bridge` shows "failed" or "inactive"

**Diagnosis**:
```bash
# Check for startup errors
journalctl --user -u protonmail-bridge -n 100

# Check if binary exists
ls -la $(which protonmail-bridge)
```

**Common Causes**:
- Bridge binary not in PATH (rebuild with `home-manager switch`)
- Previous instance still running
- Corrupted vault file

**Resolution**:
```bash
# If old process stuck
pkill -f protonmail-bridge
systemctl --user start protonmail-bridge
```

---

### Authentication Failure

**Symptoms**: Bridge starts but email clients report "authentication failed"

**Diagnosis**:
```bash
# Check if password is in keyring
secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai
```

**Resolution** - Re-authenticate via GUI:
```bash
# Stop service
systemctl --user stop protonmail-bridge

# Start interactive mode
protonmail-bridge

# In GUI: Sign out and sign back in
# Copy new bridge password
# Store in keyring:
secret-tool store --label="Protonmail Bridge - Logos Labs" \
  service protonmail-bridge \
  username benjamin@logos-labs.ai

# Restart service
systemctl --user start protonmail-bridge
```

**Alternative** - Re-authenticate via CLI:
```bash
systemctl --user stop protonmail-bridge
protonmail-bridge --cli

# At bridge> prompt:
login benjamin@logos-labs.ai
# Enter ProtonMail password when prompted
# Copy the bridge password shown
# Ctrl+D to exit

# Store in keyring (paste bridge password when prompted):
secret-tool store --label="Protonmail Bridge - Logos Labs" \
  service protonmail-bridge \
  username benjamin@logos-labs.ai

systemctl --user start protonmail-bridge
```

---

### Port Conflict

**Symptoms**: `ss -tlnp` shows different process on ports 1143 or 1025

**Diagnosis**:
```bash
# Find what's using the port
sudo lsof -i :1143
sudo lsof -i :1025
```

**Resolution**:
```bash
# Kill conflicting process
sudo kill -9 <PID>

# Restart Bridge
systemctl --user restart protonmail-bridge
```

---

### Vault Corruption

**Symptoms**: Bridge fails with vault-related errors

**Diagnosis**:
```bash
journalctl --user -u protonmail-bridge | grep -i vault
```

**Resolution** (requires re-authentication):
```bash
# Stop service
systemctl --user stop protonmail-bridge

# Backup and remove vault
mv ~/.config/protonmail/bridge-v3/vault.enc ~/.config/protonmail/bridge-v3/vault.enc.bak

# Re-authenticate
protonmail-bridge
# Sign in via GUI, then close

# Restart service
systemctl --user start protonmail-bridge
```

---

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "pass not initialized" | `pass` password store not configured | Ignore (uses GNOME keyring instead) |
| "Connection refused" | Bridge not running | Start service |
| "Authentication failed" | Wrong password in keyring | Re-store password |
| "Cannot open vault" | Corrupted vault.enc | Delete and re-authenticate |

---

## Related Documentation

- [Himalaya Manual Setup Guide](himalaya-manual-setup-guide.md) - Full email stack configuration
- [NixOS Workflows](NIX_WORKFLOWS.md) - NixOS/home-manager rebuilds

---

## Quick Reference

### Daily Commands

```bash
# Check status
systemctl --user status protonmail-bridge

# Sync email
mbsync logos

# List emails
himalaya envelope list -a logos
```

### After Reboot

Service starts automatically. Verify with:
```bash
systemctl --user is-active protonmail-bridge && ss -tlnp | grep 1143
```

### After ProtonMail Password Change

```bash
# Stop service, re-authenticate, update keyring, restart
systemctl --user stop protonmail-bridge
protonmail-bridge  # Sign in with new password
# Store new bridge password in keyring
systemctl --user start protonmail-bridge
```

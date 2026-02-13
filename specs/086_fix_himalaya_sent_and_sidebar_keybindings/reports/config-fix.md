# Himalaya Sent Folder Configuration Fix

**Issue**: Sent emails (replies) not showing up in the Sent folder when using himalaya in Neovim.

**Root Cause**: The himalaya configuration uses Gmail IMAP-style folder aliases (e.g., `[Gmail].Sent Mail`) but the maildir backend has different folder names (e.g., `Sent`).

## Configuration Fix

The configuration is managed via Nix home-manager. The following change needs to be made to the himalaya configuration:

### Current (Incorrect) Configuration

```toml
[accounts.gmail.folder.aliases]
sent = "[Gmail].Sent Mail"
```

### Fixed Configuration

```toml
[accounts.gmail.folder.aliases]
sent = "Sent"
```

## Verification Steps

1. List available folders to confirm correct names:
   ```bash
   himalaya folder list -a gmail
   ```

2. After updating the configuration, verify sent folder access:
   ```bash
   himalaya envelope list -a gmail -f Sent
   ```

3. Send a test reply and verify it appears in the Sent folder:
   - Open Himalaya in Neovim
   - Reply to any email
   - Switch to the Sent folder and confirm the reply appears

## Location of Configuration

The himalaya configuration is typically located at:
- `~/.config/himalaya/config.toml` (standalone installation)
- Managed by Nix home-manager module (if using NixOS/Nix)

## Related Issue

This is a configuration issue, not a Neovim plugin issue. The Neovim himalaya plugin correctly delegates folder operations to the himalaya CLI, which relies on proper folder aliases.

# Gmail OAuth Authentication Integration

## Problem Overview

### Current Authentication Architecture

The Himalaya email client uses a multi-layered authentication system:

1. **Gmail OAuth2 Tokens**: Access tokens (short-lived) and refresh tokens (long-lived)
2. **mbsync Integration**: External sync tool that requires valid OAuth tokens
3. **Systemd Automation**: Background service that refreshes tokens automatically
4. **Environment Dependencies**: OAuth client ID required for token refresh operations

### Issues Encountered

#### 1. **Token Expiration Cascade**
- Gmail OAuth access tokens expire regularly (typically every hour)
- When tokens expire, both mbsync and manual sync operations fail
- User sees generic "Mail sync failed" errors without clear indication of cause

#### 2. **Environment Variable Isolation**
- `GMAIL_CLIENT_ID` set in user shell (`private.fish`) 
- Systemd services run in isolated environment without shell variables
- Background token refresh fails with "invalid_client" error
- Manual refresh works (shell context) but automatic refresh fails (systemd context)

#### 3. **Multi-Method Sync Complexity**
- `<leader>ms` ’ Uses mbsync (requires OAuth tokens via systemd)
- Manual OAuth refresh ’ Tests Himalaya native IMAP (works directly)
- Different code paths with different failure modes
- Inconsistent user experience between manual and automated operations

#### 4. **Configuration Maintainability**
- Sensitive OAuth client ID needs to be available across machines
- Current approach requires manual file creation on each system
- Conflicts with public GitHub repository (no secrets in version control)
- Environment variable sourcing not portable across NixOS rebuilds

### Root Cause Analysis

The fundamental issue is **environment context isolation** between:
- User shell environment (where `GMAIL_CLIENT_ID` is set)
- Systemd user services (where token refresh runs)
- Different sync mechanisms (mbsync vs native Himalaya)

This creates a fragile authentication chain where manual operations work but automated background refresh fails.

## Solution: NixOS Home-Manager Integration

### Option 2: Environment Variables in Home-Manager

#### Implementation

```nix
# In home-manager configuration
{
  # Set environment variable system-wide
  home.sessionVariables = {
    GMAIL_CLIENT_ID = "810486121108-i3d8dloc9hc0rg7g6ee9cj1tl8l1m0i8.apps.googleusercontent.com";
  };
  
  # Configure systemd service with proper environment
  systemd.user.services.gmail-oauth2-refresh = {
    Unit = {
      Description = "Refresh Gmail OAuth2 tokens";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.refresh-gmail-oauth2}/bin/refresh-gmail-oauth2";
      Environment = [ 
        "GMAIL_CLIENT_ID=${config.home.sessionVariables.GMAIL_CLIENT_ID}" 
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
  
  # Ensure timer is configured
  systemd.user.timers.gmail-oauth2-refresh = {
    Unit.Description = "Timer for Gmail OAuth2 token refresh";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
```

#### Benefits

1. **Environment Consistency**
   - Same `GMAIL_CLIENT_ID` available in shell and systemd contexts
   - Eliminates environment isolation issues
   - Consistent behavior across manual and automated operations

2. **Configuration Portability**
   - Declarative configuration via Nix
   - Automatic setup on new machines via `home-manager switch`
   - No manual file creation or environment setup required

3. **Maintainability**
   - Single source of truth in home-manager config
   - Version controlled configuration (OAuth client ID is semi-public)
   - Reproducible across different machines and NixOS rebuilds

4. **Security Appropriate**
   - OAuth client IDs are designed to be semi-public identifiers
   - Real secrets (refresh/access tokens) remain in secure keyring
   - No exposure of sensitive authentication data

### Implementation Steps

1. **Add to home-manager configuration**:
   ```nix
   home.sessionVariables.GMAIL_CLIENT_ID = "810486121108-i3d8dloc9hc0rg7g6ee9cj1tl8l1m0i8.apps.googleusercontent.com";
   ```

2. **Update systemd service configuration**:
   ```nix
   systemd.user.services.gmail-oauth2-refresh.Service.Environment = [
     "GMAIL_CLIENT_ID=${config.home.sessionVariables.GMAIL_CLIENT_ID}"
   ];
   ```

3. **Rebuild home-manager**:
   ```bash
   home-manager switch
   ```

4. **Verify systemd service**:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart gmail-oauth2-refresh.service
   ```

### Expected Outcome

- **Automatic OAuth refresh** works reliably in background
- **Manual sync operations** (`<leader>ms`) work consistently  
- **No environment setup** required on new machines
- **Seamless user experience** with transparent authentication
- **Maintainable configuration** through declarative Nix setup

This solution addresses the core authentication reliability issues while maintaining security best practices and configuration portability across NixOS installations.
# Research Report: Task #78

**Task**: 78 - fix_himalaya_smtp_authentication_failure
**Started**: 2026-02-13T18:00:00Z
**Completed**: 2026-02-13T18:15:00Z
**Effort**: 1-2 hours (fix and re-authentication)
**Dependencies**: None (CLI fix only)
**Sources/Inputs**: Himalaya config, keyring analysis, Google OAuth2 documentation, web research
**Artifacts**: - /home/benjamin/.config/nvim/specs/078_fix_himalaya_smtp_authentication_failure/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- **Root Cause Identified**: The Gmail OAuth2 refresh token has been expired or revoked by Google, causing all SMTP authentication attempts to fail with error 535 5.7.8
- The access token in the keyring was last refreshed on 2026-02-11, but the underlying refresh token is no longer valid
- **Fix Required**: User must re-run the Himalaya OAuth2 configuration wizard to obtain fresh tokens via interactive browser authentication

## Context & Scope

### Problem Statement
When attempting to send emails via Himalaya's `<leader>me` keybinding, the operation fails with:
```
Error: Authentication failed: Code: 535, Enhanced code: 5.7.8,
Message: Username and Password not accepted.
```

### Investigation Scope
1. Himalaya CLI configuration analysis
2. System keyring token inspection
3. OAuth2 token refresh mechanism verification
4. Gmail SMTP authentication requirements

## Findings

### Current Configuration

The Himalaya config at `~/.config/himalaya/config.toml` correctly configures Gmail SMTP with OAuth2:

```toml
[accounts.gmail]
message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 465
message.send.backend.login = "benbrastmckie@gmail.com"
message.send.backend.encryption.type = "tls"
message.send.backend.auth.type = "oauth2"
message.send.backend.auth.method = "xoauth2"
message.send.backend.auth.client-id = "${GMAIL_CLIENT_ID}"
# Tokens stored in keyring
message.send.backend.auth.client-secret.keyring = "gmail-smtp-oauth2-client-secret"
message.send.backend.auth.access-token.keyring = "gmail-smtp-oauth2-access-token"
message.send.backend.auth.refresh-token.keyring = "gmail-smtp-oauth2-refresh-token"
```

Configuration is valid and follows the correct Himalaya OAuth2 pattern.

### Keyring Token State

Tokens found in GNOME keyring via `secret-tool`:

| Token Type | Status | Last Modified |
|------------|--------|---------------|
| Access Token | Present | 2026-02-11 21:05:07 |
| Refresh Token | Present (but invalid) | 2026-02-04 21:40:51 |
| Client Secret | Present | 2026-02-04 22:56:19 |

### Root Cause Analysis

Running the OAuth2 refresh script reveals the actual error:

```bash
$ refresh-gmail-oauth2
Failed to refresh OAuth2 token. Response: {
  "error": "invalid_grant",
  "error_description": "Token has been expired or revoked."
}
```

**The refresh token itself has been invalidated by Google.**

### Why Refresh Tokens Expire

Google OAuth2 refresh tokens can become invalid for several reasons:

1. **Testing Mode Expiration**: If the Google Cloud project's OAuth consent screen is in "Testing" status (not "Production"), refresh tokens expire after 7 days
2. **User Revocation**: The user revoked access in Google Account settings
3. **Password Change**: User changed their Google password while the token had Gmail scopes
4. **Inactivity**: Refresh token not used for 6 months
5. **Token Limit**: Google account exceeded maximum number of refresh tokens (50 per account per OAuth client)

Given the refresh token was created on 2026-02-04 (9 days ago), the most likely cause is **Testing Mode 7-day expiration**.

### Neovim Plugin OAuth Handling

The Himalaya Neovim plugin includes OAuth refresh logic in `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/sync/oauth.lua`:

- Detects OAuth vs password authentication accounts
- Attempts automatic token refresh via `refresh-gmail-oauth2` script
- Handles refresh cooldowns and error states

However, when the refresh token itself is invalid, automatic refresh cannot succeed - user re-authentication is required.

## Recommendations

### Immediate Fix (Required)

Re-run the Himalaya OAuth2 configuration wizard in a terminal:

```bash
himalaya account configure gmail
```

This will:
1. Open a browser for Google OAuth2 consent
2. Obtain new access and refresh tokens
3. Store them in the system keyring

### Optional: Prevent Future Expiration

If the Google Cloud project is in Testing mode, consider:

1. **Publish to Production** in Google Cloud Console > APIs & Services > OAuth consent screen
   - This removes the 7-day token expiration limit
   - Requires providing app information and privacy policy

2. **Alternative: Use App Password** instead of OAuth2
   - Simpler but less secure
   - Requires enabling 2FA on Google account
   - Generate app password at https://myaccount.google.com/apppasswords
   - Update config to use `auth.type = "password"` instead of OAuth2

### Configuration for App Password (Alternative)

If OAuth2 continues to be problematic:

```toml
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "secret-tool lookup service gmail-app-password"
```

Then store the app password:
```bash
secret-tool store --label="Gmail App Password" service gmail-app-password
```

## Decisions

- **Decision 1**: Re-authentication via `himalaya account configure gmail` is the correct fix
- **Decision 2**: OAuth2 is preferred over App Password for security (retaining current approach)
- **Decision 3**: No code changes needed in the Himalaya Neovim plugin - it correctly handles OAuth refresh attempts

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Token expires again in 7 days (Testing mode) | User should check OAuth consent screen status in Google Cloud Console |
| Re-auth requires interactive browser | Must be done from terminal with browser access, not headless |
| Keyring access issues | Ensure GNOME keyring is unlocked before running configure |

## Appendix

### Search Queries Used
- "Himalaya email client OAuth2 Gmail SMTP authentication failed 535 5.7.8"
- "Google OAuth2 invalid_grant Token has been expired or revoked refresh token"
- "Gmail SMTP OAuth2 XOAUTH2 configuration"

### References
- [Himalaya GitHub Repository](https://github.com/pimalaya/himalaya)
- [Google OAuth2 invalid_grant Troubleshooting](https://nango.dev/blog/google-oauth-invalid-grant-token-has-been-expired-or-revoked)
- [Gmail OAuth2 Token Expiration Issues](https://support.google.com/mail/thread/353965077)
- [Google OAuth2 XOAUTH2 Protocol](https://developers.google.com/workspace/gmail/imap/xoauth2-protocol)
- [SMTP Error 535 5.7.8 Troubleshooting](https://www.warmy.io/blog/understanding-and-fixing-the-smtp-535-error-incorrect-authentication-data/)

### Relevant Files
- Config: `~/.config/himalaya/config.toml`
- OAuth module: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/sync/oauth.lua`
- CLI utility: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/utils/cli.lua`
- Refresh script: `/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2`

### Commands for Verification

```bash
# Verify current token state
secret-tool search --all service himalaya-cli

# Attempt token refresh (will fail with invalid_grant)
refresh-gmail-oauth2

# Re-authenticate (the fix)
himalaya account configure gmail

# Test send after re-auth
himalaya message send --account gmail <<EOF
To: test@example.com
Subject: Test

Test message.
EOF
```

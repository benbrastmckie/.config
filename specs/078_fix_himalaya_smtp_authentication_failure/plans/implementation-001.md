# Implementation Plan: Fix Himalaya SMTP Authentication Failure

- **Task**: 78 - fix_himalaya_smtp_authentication_failure
- **Status**: [NOT STARTED]
- **Effort**: 0.5-1 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

The Gmail SMTP authentication failure (error 535 5.7.8) is caused by an expired/revoked OAuth2 refresh token, not a configuration or code issue. The research confirms the Himalaya configuration is correct and the Neovim plugin OAuth handling is working as designed. The fix requires user re-authentication via the Himalaya CLI to obtain fresh tokens.

### Research Integration

Key findings from research-001.md:
- Root cause: OAuth2 refresh token invalid (`invalid_grant` error from Google)
- Most likely reason: Google Cloud project in "Testing" mode with 7-day token expiration
- Configuration validated: `~/.config/himalaya/config.toml` correctly configured
- No code changes needed: Plugin correctly handles OAuth refresh attempts

## Goals & Non-Goals

**Goals**:
- Re-authenticate Gmail OAuth2 via Himalaya CLI
- Verify SMTP sending works after re-authentication
- Document the root cause and preventive measures

**Non-Goals**:
- Modify Neovim plugin code (no changes needed)
- Change from OAuth2 to App Password (OAuth2 is more secure)
- Publish Google Cloud project to Production (optional future improvement)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Token expires again in 7 days | High | High (if Testing mode) | User should check OAuth consent screen status |
| GNOME keyring locked during re-auth | Medium | Low | Ensure desktop session is active |
| Browser unavailable for OAuth flow | High | Low | Must run from terminal with browser access |

## Implementation Phases

### Phase 1: Re-authenticate Gmail OAuth2 [NOT STARTED]

**Goal**: Obtain fresh OAuth2 tokens via interactive browser authentication

**Tasks**:
- [ ] Run `himalaya account configure gmail` in terminal
- [ ] Complete Google OAuth2 consent flow in browser
- [ ] Verify new tokens stored in GNOME keyring

**Timing**: 5-10 minutes

**Verification**:
- `secret-tool search --all service himalaya-cli` shows updated access token timestamp

---

### Phase 2: Verify SMTP Functionality [NOT STARTED]

**Goal**: Confirm email sending works after re-authentication

**Tasks**:
- [ ] Send test email via Himalaya CLI
- [ ] Send test email via Neovim `<leader>me`
- [ ] Verify no authentication errors

**Timing**: 5-10 minutes

**Verification**:
- CLI command `himalaya message send` succeeds
- Neovim `<leader>me` completes without error 535

---

### Phase 3: Document Prevention (Optional) [NOT STARTED]

**Goal**: Prevent future 7-day token expiration

**Tasks**:
- [ ] Check Google Cloud Console OAuth consent screen status
- [ ] If in Testing mode, consider publishing to Production
- [ ] Document token expiration behavior for future reference

**Timing**: 15-30 minutes (optional)

**Verification**:
- OAuth consent screen status noted
- Understanding of token lifecycle confirmed

## Testing & Validation

- [ ] Test email successfully delivered via CLI
- [ ] Test email successfully sent via Neovim keybinding
- [ ] No authentication errors in Himalaya output
- [ ] Access token timestamp updated in keyring

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (after completion)

## Rollback/Contingency

If OAuth2 re-authentication fails:
1. Check Google account security settings at https://myaccount.google.com/security
2. Verify 2FA is enabled (required for OAuth2)
3. Check if app access was revoked at https://myaccount.google.com/connections
4. As last resort, consider App Password authentication (less secure but simpler)

Configuration for App Password fallback (only if OAuth2 cannot be restored):
```toml
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "secret-tool lookup service gmail-app-password"
```

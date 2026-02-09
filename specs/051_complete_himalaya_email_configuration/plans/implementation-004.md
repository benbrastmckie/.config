# Implementation Plan: Task #51

- **Date**: 2026-02-09 (Revised)
- **Feature**: Complete Himalaya email configuration for dual accounts (Protonmail + Gmail)
- **Status**: [IMPLEMENTING]
- **Estimated Hours**: 1.5-2 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)
- **Revision Notes**: v004 - Protonmail fully working (Bridge login, SMTP fix via task 21). Remaining: Gmail OAuth, Neovim plugin, docs.

## Overview

Complete the Himalaya email configuration in Neovim for two accounts: the primary Protonmail account (benjamin@logos-labs.ai) and the secondary Gmail account (benbrastmckie@gmail.com).

### What's Already Done

**Via dotfiles task 20** (`/home/benjamin/.dotfiles/specs/20_update_himalaya_setup/`):
- Protonmail Bridge package installed via Nix
- Himalaya CLI logos account configured in config.toml
- mbsync logos channels configured in mbsyncrc
- Mail/Logos maildir directory structure created

**Via dotfiles task 21** (`/home/benjamin/.dotfiles/specs/21_fix_himalaya_smtp_logos_account/`):
- Fixed SMTP backend configuration (correct field paths: `login`, `auth.cmd`)
- Himalaya now shows both accounts with Maildir + SMTP backends

**Manually completed by user**:
- Protonmail Bridge running (ports 1143/1025 listening)
- Bridge password stored in keyring
- mbsync syncing Protonmail successfully (856 emails synced)
- Himalaya can list emails from logos account

### Current Status (Verified)

```
| NAME  | BACKENDS      | DEFAULT |
|-------|---------------|---------|
| gmail | Maildir, SMTP | yes     |
| logos | Maildir, SMTP |         |
```

- Protonmail: 856 emails synced to ~/Mail/Logos/
- Bridge: Running on 127.0.0.1:1143 (IMAP), 127.0.0.1:1025 (SMTP)
- Password: Stored in GNOME keyring

### What Remains

1. **Gmail OAuth refresh** - Restore Gmail account sync (may already work)
2. **Neovim plugin configuration** - Add logos account support
3. **Documentation updates** - Ensure all docs are accurate

## Goals & Non-Goals

**Goals**:
- Restore Gmail account synchronization by refreshing OAuth2 tokens
- Update Neovim plugin account configuration for dual-account support
- Update all related documentation to reflect the correct configuration

**Non-Goals**:
- Modifying Nix configuration (already done in dotfiles tasks 20, 21)
- Protonmail Bridge setup (already complete)
- Creating new OAuth2 credentials for Gmail (reuse existing client)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| OAuth2 refresh token expired | High | Low | Re-authenticate via Google OAuth flow if refresh fails |
| Documentation drift | Medium | Medium | Update docs immediately after each config change |

## Implementation Phases

### Phase 1: Restore Gmail Account [COMPLETED]

**Goal**: Refresh OAuth2 tokens and verify Gmail synchronization works

**Tasks**:
- [x] Run the existing OAuth2 refresh script: `refresh-gmail-oauth2`
- [x] Verify token was stored in GNOME keyring
- [x] Test mbsync with Gmail INBOX: `mbsync -V gmail-inbox`
- [x] Verify emails appear in local maildir: `ls ~/Mail/Gmail/INBOX/{cur,new}`
- [x] Test Himalaya CLI reads Gmail: `himalaya list -a gmail`

**Timing**: 30 minutes

**Files to modify**: None (using existing scripts and configuration)

**Verification**:
- mbsync completes without authentication errors
- Email messages appear in ~/Mail/Gmail/INBOX/
- `himalaya list -a gmail` shows recent emails

---

### Phase 2: Update Neovim Plugin Configuration [NOT STARTED]

**Goal**: Add Logos Labs account to Neovim himalaya plugin for dual-account support

**Tasks**:
- [ ] Locate account configuration in Neovim plugin:
  `~/.config/nvim/lua/neotex/plugins/tools/himalaya/config/accounts.lua`
- [ ] Add logos account configuration with mbsync channel mappings
- [ ] Verify account switching commands exist: `:HimalayaAccountSwitch`
- [ ] Test account switching in Neovim: `:HimalayaAccountSwitch logos`
- [ ] Test sync command: `:HimalayaSync`
- [ ] Test email listing: `:HimalayaListEmails`

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/accounts.lua` - Add logos account configuration

**Expected Configuration**:
```lua
M.defaults = {
  gmail = {
    -- existing gmail config
  },
  logos = {
    email = nil,  -- Auto-detect from himalaya config
    display_name = nil,  -- Auto-detect
    mbsync = {
      inbox_channel = "logos-inbox",
      all_channel = "logos",
    }
  }
}
```

**Verification**:
- `:HimalayaAccountSwitch logos` switches to Logos Labs account
- `:HimalayaListEmails` shows Protonmail emails when logos account active
- `:HimalayaSync` triggers mbsync for the active account
- `:HimalayaAccountSwitch gmail` switches back to Gmail account

---

### Phase 3: Update Documentation [NOT STARTED]

**Goal**: Ensure all documentation accurately reflects the current configuration and conforms to existing standards

**Tasks**:
- [ ] Audit existing himalaya plugin README files for accuracy
- [ ] Update plugin module documentation to reflect dual-account support:
  - Document account switching workflow
  - Document mbsync integration for both Gmail (OAuth2) and Protonmail (Bridge)
- [ ] Create or update configuration reference documentation:
  - List all Himalaya-related keymaps and commands
  - Document the two-tier architecture (mbsync + Himalaya)
  - Include troubleshooting section for common issues (OAuth expiry, Bridge connection)
- [ ] Update the manual setup guide (`docs/himalaya-manual-setup-guide.md`):
  - Mark Protonmail Bridge setup as complete
  - Mark Nix configuration sections as complete
  - Update completion checklist
- [ ] Verify documentation follows nvim/CLAUDE.md standards:
  - Clear purpose explanations
  - Module documentation with code examples
  - Navigation links to parent/child directories
  - No emojis in file content
- [ ] Ensure config examples in docs match actual configuration values

**Timing**: 45 minutes

**Files to review/modify**:
- `lua/neotex/plugins/tools/himalaya/README.md` - Main plugin documentation
- `lua/neotex/plugins/tools/himalaya/config/README.md` - Config module docs
- `docs/himalaya-manual-setup-guide.md` - Update to reflect completed steps
- Any other himalaya-related README files

**Verification**:
- All himalaya README files exist and are complete
- Configuration examples match actual values
- Account names (gmail, logos) are consistently documented
- No references to incorrect providers (e.g., "Google Workspace" for Protonmail)
- Manual setup guide reflects current state (Phases 2-4 marked complete)

---

## Testing & Validation

- [ ] Gmail OAuth2 token refresh completes successfully
- [ ] mbsync syncs Gmail without authentication errors
- [ ] Himalaya CLI lists emails from both accounts
- [ ] Neovim plugin switches between accounts correctly
- [ ] Full sync of both accounts completes: `mbsync -a`
- [ ] All documentation is accurate and follows standards

## Artifacts & Outputs

- plans/implementation-004.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Updated lua/neotex/plugins/tools/himalaya/config/accounts.lua
- Updated himalaya plugin README documentation
- Updated docs/himalaya-manual-setup-guide.md

## Dependencies on External Work

This plan depends on work completed in the dotfiles repository:
- **Task 20**: Protonmail Bridge, Himalaya config, mbsync channels, maildir creation
- **Task 21**: Fixed SMTP backend configuration for logos account

## Rollback/Contingency

**Gmail rollback**: OAuth2 refresh is non-destructive. If it fails, existing refresh token remains. Worst case: re-authenticate via Google OAuth flow.

**Neovim plugin rollback**: Remove logos account from accounts.lua. Plugin will use only gmail account.

**Documentation rollback**: Git revert any documentation changes if they introduce errors.

# Implementation Plan: Task #51

- **Date**: 2026-02-09 (Revised)
- **Feature**: Complete Himalaya email configuration for dual accounts (Protonmail + Gmail)
- **Status**: [NOT STARTED]
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)
- **Revision Notes**: v003 - Phases 2-4 completed via dotfiles task 20. Remaining: Gmail OAuth, Bridge login, Neovim plugin, docs.

## Overview

Complete the Himalaya email configuration in Neovim for two accounts: the primary Protonmail account (benjamin@logos-labs.ai) and the secondary Gmail account (benbrastmckie@gmail.com).

### What's Already Done (via dotfiles task 20)

The following were implemented in `/home/benjamin/.dotfiles/specs/20_update_himalaya_setup/`:
- Protonmail Bridge package installed via Nix
- Himalaya CLI logos account configured in config.toml
- mbsync logos channels configured in mbsyncrc
- Mail/Logos maildir directory structure created

### What Remains

1. **Gmail OAuth refresh** - Restore Gmail account sync
2. **Protonmail Bridge login** - Manual step to authenticate and store password
3. **Neovim plugin configuration** - Add logos account support
4. **Documentation updates** - Ensure all docs are accurate

## Goals & Non-Goals

**Goals**:
- Restore Gmail account synchronization by refreshing OAuth2 tokens
- Complete Protonmail Bridge login and password storage
- Update Neovim plugin account configuration for dual-account support
- Update all related documentation to reflect the correct configuration

**Non-Goals**:
- Modifying Nix configuration (already done in dotfiles task 20)
- Creating new OAuth2 credentials for Gmail (reuse existing client)
- Changing the overall maildir-based architecture

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| OAuth2 refresh token expired | High | Low | Re-authenticate via Google OAuth flow if refresh fails |
| Bridge password not stored | Medium | High | Manual step required - user must complete |
| Documentation drift | Medium | Medium | Update docs immediately after each config change |

## Implementation Phases

### Phase 1: Restore Gmail Account [NOT STARTED]

**Goal**: Refresh OAuth2 tokens and verify Gmail synchronization works

**Tasks**:
- [ ] Run the existing OAuth2 refresh script: `refresh-gmail-oauth2`
- [ ] Verify token was stored in GNOME keyring
- [ ] Test mbsync with Gmail INBOX: `mbsync -V gmail-inbox`
- [ ] Verify emails appear in local maildir: `ls ~/Mail/Gmail/INBOX/{cur,new}`
- [ ] Test Himalaya CLI reads Gmail: `himalaya list -a gmail`

**Timing**: 30 minutes

**Files to modify**: None (using existing scripts and configuration)

**Verification**:
- mbsync completes without authentication errors
- Email messages appear in ~/Mail/Gmail/INBOX/
- `himalaya list -a gmail` shows recent emails

---

### Phase 2: Complete Protonmail Bridge Setup [NOT STARTED] [MANUAL]

**Goal**: Login to Protonmail Bridge and store password in keyring

**Note**: This phase requires manual user intervention - cannot be automated.

**Tasks**:
- [ ] Start Protonmail Bridge: `protonmail-bridge`
- [ ] Log in with benjamin@logos-labs.ai credentials
- [ ] Navigate to account settings and copy the bridge password
- [ ] Store bridge password in GNOME keyring:
  ```bash
  secret-tool store --label="Protonmail Bridge - Logos Labs" \
    service protonmail-bridge \
    username benjamin@logos-labs.ai
  ```
- [ ] Verify Bridge is listening: `ss -tlnp | grep -E '1143|1025'`
- [ ] Test mbsync with Protonmail: `mbsync -V logos-inbox`
- [ ] Test Himalaya with Protonmail: `himalaya list -a logos`

**Timing**: 30 minutes (manual)

**Files to modify**: None (Bridge configuration is managed by Bridge UI)

**Verification**:
- Bridge password stored in keyring: `secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai`
- mbsync syncs Protonmail without errors
- `himalaya list -a logos` shows emails

---

### Phase 3: Update Neovim Plugin Configuration [NOT STARTED]

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

**Verification**:
- `:HimalayaAccountSwitch logos` switches to Logos Labs account
- `:HimalayaListEmails` shows Protonmail emails when logos account active
- `:HimalayaSync` triggers mbsync for the active account
- `:HimalayaAccountSwitch gmail` switches back to Gmail account

---

### Phase 4: Update Documentation [NOT STARTED]

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
- [ ] Update the manual setup guide to reflect completed steps:
  - Mark Nix configuration sections as complete
  - Update completion checklist
- [ ] Verify documentation follows nvim/CLAUDE.md standards:
  - Clear purpose explanations
  - Module documentation with code examples
  - Navigation links to parent/child directories
  - No emojis in file content
- [ ] Ensure config examples in docs match actual configuration values

**Timing**: 60 minutes

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
- Manual setup guide reflects current state

---

## Testing & Validation

- [ ] Gmail OAuth2 token refresh completes successfully
- [ ] mbsync syncs Gmail without authentication errors
- [ ] Protonmail Bridge accepts connections on ports 1143/1025
- [ ] mbsync syncs Protonmail via Bridge to local maildir
- [ ] Himalaya CLI lists emails from both accounts
- [ ] Neovim plugin switches between accounts correctly
- [ ] Full sync of both accounts completes: `mbsync -a`
- [ ] All documentation is accurate and follows standards

## Artifacts & Outputs

- plans/implementation-003.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Updated lua/neotex/plugins/tools/himalaya/config/accounts.lua
- Updated himalaya plugin README documentation
- Updated docs/himalaya-manual-setup-guide.md

## Dependencies on External Work

This plan depends on work completed in the dotfiles repository:
- **Task 20**: `/home/benjamin/.dotfiles/specs/20_update_himalaya_setup/plans/implementation-001.md`
  - Added protonmail-bridge to home.packages
  - Added logos account to himalaya config.toml
  - Added logos channels to mbsyncrc
  - Added Logos maildir to activation script

## Rollback/Contingency

**Gmail rollback**: OAuth2 refresh is non-destructive. If it fails, existing refresh token remains. Worst case: re-authenticate via Google OAuth flow.

**Neovim plugin rollback**: Remove logos account from accounts.lua. Plugin will use only gmail account.

**Documentation rollback**: Git revert any documentation changes if they introduce errors.

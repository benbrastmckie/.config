# Implementation Plan: Task #51

- **Task**: 51 - Complete Himalaya Email Configuration
- **Status**: [NOT STARTED]
- **Effort**: 3-5 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Complete the Himalaya email configuration in Neovim for two accounts: the primary Protonmail account (benjamin@logos-labs.ai) and the secondary Gmail account (benbrastmckie@gmail.com). The current architecture uses a two-tier system: mbsync for IMAP synchronization to local maildir, and Himalaya reading from the local maildir. Gmail has expired OAuth2 tokens requiring refresh, while the Protonmail account needs full setup including Protonmail Bridge installation, mbsync configuration, and Himalaya integration.

### Research Integration

Key findings from research-001.md:
- Gmail OAuth2 tokens have expired, causing authentication failures with mbsync
- Protonmail account requires Protonmail Bridge running locally (IMAP on 127.0.0.1:1143, SMTP on 127.0.0.1:1025)
- Neovim himalaya plugin has comprehensive architecture (70+ modules) with existing OAuth management
- Existing Nix-managed refresh script at `/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2`

## Goals & Non-Goals

**Goals**:
- Restore Gmail account synchronization by refreshing OAuth2 tokens
- Set up Protonmail Bridge for the Logos Labs account
- Configure mbsync channels for Protonmail IMAP sync
- Configure Himalaya CLI to read from Protonmail maildir
- Update Neovim plugin account configuration for dual-account support
- Verify both accounts synchronize email to local maildir storage

**Non-Goals**:
- Modifying the existing Nix configuration (use existing refresh script)
- Creating new OAuth2 credentials for Gmail (reuse existing client)
- Changing the overall maildir-based architecture
- Adding additional email accounts beyond the two specified

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| OAuth2 refresh token expired | High | Low | Re-authenticate via Google OAuth flow if refresh fails |
| Protonmail Bridge not installed | Medium | Medium | Install via Nix or official package, verify running |
| Bridge password lost/unknown | Medium | Medium | Generate new bridge password from Protonmail Bridge UI |
| Port conflicts with Bridge | Low | Low | Verify ports 1143/1025 are free before configuration |
| Large initial sync for Protonmail | Medium | High | Use MaxMessages in mbsync or sync folders incrementally |

## Implementation Phases

### Phase 1: Restore Gmail Account [NOT STARTED]

**Goal**: Refresh OAuth2 tokens and verify Gmail synchronization works

**Tasks**:
- [ ] Run the existing OAuth2 refresh script: `refresh-gmail-oauth2`
- [ ] Verify token was stored in GNOME keyring: `secret-tool lookup service gmail-oauth2 username benbrastmckie@gmail.com`
- [ ] Test mbsync with Gmail INBOX: `mbsync -V gmail-inbox`
- [ ] Verify emails appear in local maildir: `ls ~/Mail/Gmail/INBOX/{cur,new}`
- [ ] Test Himalaya CLI reads Gmail: `himalaya list -a gmail`

**Timing**: 30 minutes

**Files to modify**:
- None (using existing scripts and configuration)

**Verification**:
- mbsync completes without authentication errors
- Email messages appear in ~/Mail/Gmail/INBOX/
- `himalaya list -a gmail` shows recent emails

---

### Phase 2: Set Up Protonmail Bridge [NOT STARTED]

**Goal**: Install and configure Protonmail Bridge for local IMAP/SMTP access

**Tasks**:
- [ ] Check if Protonmail Bridge is already installed: `which protonmail-bridge`
- [ ] If not installed, install via NixOS package or download from proton.me
- [ ] Start Protonmail Bridge: `protonmail-bridge` (GUI) or `protonmail-bridge --noninteractive`
- [ ] Log in with benjamin@logos-labs.ai credentials
- [ ] Navigate to account settings and copy the bridge password
- [ ] Store bridge password in GNOME keyring:
  ```bash
  secret-tool store --label="Protonmail Bridge - Logos Labs" \
    service protonmail-bridge \
    username benjamin@logos-labs.ai
  ```
- [ ] Verify Bridge is listening: `ss -tlnp | grep -E '114[3]|1025'`

**Timing**: 45 minutes

**Files to modify**:
- None (Bridge configuration is managed by Bridge UI)

**Verification**:
- Protonmail Bridge is running and listening on ports 1143 (IMAP) and 1025 (SMTP)
- Bridge password is stored in GNOME keyring
- `secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai` returns password

---

### Phase 3: Configure mbsync for Protonmail [NOT STARTED]

**Goal**: Add mbsync configuration to sync Protonmail via Bridge to local maildir

**Tasks**:
- [ ] Create maildir structure for Logos Labs account:
  ```bash
  mkdir -p ~/Mail/Logos/{INBOX,Sent,Drafts,Trash,Archive}/{cur,new,tmp}
  ```
- [ ] Add Protonmail IMAP account configuration to ~/.mbsyncrc
- [ ] Add Protonmail maildir store configuration
- [ ] Add channel configurations for INBOX, Sent, Drafts, Trash, Archive
- [ ] Add channel group for batch syncing
- [ ] Test individual channel: `mbsync -V logos-inbox`
- [ ] Test full account sync: `mbsync logos`

**Timing**: 45 minutes

**Files to modify**:
- `~/.mbsyncrc` - Add Protonmail account, stores, channels, and group

**Verification**:
- mbsync connects to Protonmail Bridge without errors
- Email messages appear in ~/Mail/Logos/INBOX/
- All configured channels sync successfully

---

### Phase 4: Configure Himalaya CLI for Protonmail [NOT STARTED]

**Goal**: Add Logos Labs account to Himalaya CLI configuration

**Tasks**:
- [ ] Read current Himalaya config: `cat ~/.config/himalaya/config.toml`
- [ ] Add logos account section with maildir backend pointing to ~/Mail/Logos
- [ ] Configure SMTP backend for sending via Bridge (127.0.0.1:1025)
- [ ] Set password retrieval from keyring
- [ ] Test Himalaya with logos account: `himalaya list -a logos`
- [ ] Test sending (dry-run or to self): `himalaya write -a logos`

**Timing**: 30 minutes

**Files to modify**:
- `~/.config/himalaya/config.toml` - Add logos account section (Note: may be Nix-managed symlink, update Nix config if needed)

**Verification**:
- `himalaya account list` shows both gmail and logos accounts
- `himalaya list -a logos` displays emails from Protonmail account
- `himalaya check -a logos` shows account status without errors

---

### Phase 5: Update Neovim Plugin Configuration [NOT STARTED]

**Goal**: Add Logos Labs account to Neovim himalaya plugin for dual-account support

**Tasks**:
- [ ] Locate account configuration in Neovim plugin:
  `~/.config/nvim/lua/neotex/plugins/tools/himalaya/config/accounts.lua`
- [ ] Add logos account configuration with mbsync channel mappings
- [ ] Verify account switching commands exist: `:HimalayaAccountSwitch`
- [ ] Test account switching in Neovim: `:HimalayaAccountSwitch logos`
- [ ] Test sync command: `:HimalayaSync`
- [ ] Test email listing: `:HimalayaListEmails`
- [ ] Test composing email from logos account

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/accounts.lua` - Add logos account configuration

**Verification**:
- `:HimalayaAccountSwitch logos` switches to Logos Labs account
- `:HimalayaListEmails` shows Protonmail emails when logos account active
- `:HimalayaSync` triggers mbsync for the active account
- `:HimalayaAccountSwitch gmail` switches back to Gmail account

---

## Testing & Validation

- [ ] Gmail OAuth2 token refresh completes successfully
- [ ] mbsync syncs Gmail without authentication errors
- [ ] Protonmail Bridge starts and accepts connections on ports 1143/1025
- [ ] mbsync syncs Protonmail via Bridge to local maildir
- [ ] Himalaya CLI lists emails from both accounts
- [ ] Neovim plugin switches between accounts correctly
- [ ] Email composition works from both accounts (test with self-send)
- [ ] Full sync of both accounts completes: `mbsync -a`

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Updated ~/.mbsyncrc with Protonmail configuration
- Updated ~/.config/himalaya/config.toml with logos account (or Nix equivalent)
- Updated lua/neotex/plugins/tools/himalaya/config/accounts.lua

## Rollback/Contingency

**Gmail rollback**: OAuth2 refresh is non-destructive. If it fails, existing refresh token remains. Worst case: re-authenticate via Google OAuth flow.

**Protonmail rollback**: Bridge installation and mbsync configuration are additive. Remove added sections from ~/.mbsyncrc and delete ~/Mail/Logos/ to restore previous state.

**Himalaya rollback**: Remove logos account section from config.toml. Himalaya will default to gmail account.

**Neovim plugin rollback**: Remove logos account from accounts.lua. Plugin will use only gmail account.

**Emergency reset**: If sync conflicts corrupt maildir, delete local maildir directories and re-sync from server (emails remain on server).

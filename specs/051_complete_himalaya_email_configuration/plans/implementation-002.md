# Implementation Plan: Task #51

- **Date**: 2026-02-08 (Revised)
- **Feature**: Complete Himalaya email configuration for dual accounts (Protonmail + Gmail)
- **Status**: [NOT STARTED]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)
- **Revision Notes**: Added Phase 6 for documentation updates to ensure all configuration docs are correct and complete

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
- Update all related documentation to reflect the correct configuration

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
| Documentation drift | Medium | Medium | Update docs immediately after each config change |

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

**mbsync Configuration Block**:
```mbsync
# Logos Labs IMAP account (via Protonmail Bridge)
IMAPAccount logos
Host 127.0.0.1
Port 1143
User benjamin@logos-labs.ai
PassCmd "secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai"
SSLType None
AuthMechs LOGIN

IMAPStore logos-remote
Account logos

MaildirStore logos-local
Inbox ~/Mail/Logos/
SubFolders Maildir++

Channel logos-inbox
Far :logos-remote:INBOX
Near :logos-local:
Create Both
Expunge Both
SyncState *

Channel logos-sent
Far :logos-remote:Sent
Near :logos-local:Sent
Create Both
Expunge Both
SyncState *

Channel logos-drafts
Far :logos-remote:Drafts
Near :logos-local:Drafts
Create Both
Expunge Both
SyncState *

Channel logos-trash
Far :logos-remote:Trash
Near :logos-local:Trash
Create Both
Expunge Both
SyncState *

Group logos
Channel logos-inbox
Channel logos-sent
Channel logos-drafts
Channel logos-trash
```

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

**Himalaya Configuration Block**:
```toml
[accounts.logos]
default = false
email = "benjamin@logos-labs.ai"
display-name = "Benjamin Brast-McKie"
downloads-dir = "/home/benjamin/Downloads"

# Uses local maildir as backend (synced by mbsync from Protonmail Bridge)
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Logos"
backend.maildirpp = true

# SMTP via Protonmail Bridge for sending
message.send.backend.type = "smtp"
message.send.backend.host = "127.0.0.1"
message.send.backend.port = 1025
message.send.backend.auth.type = "password"
message.send.backend.auth.login = "benjamin@logos-labs.ai"
message.send.backend.auth.password.keyring = "protonmail-bridge benjamin@logos-labs.ai"
message.send.backend.encryption = "none"
```

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

### Phase 6: Update Documentation [NOT STARTED]

**Goal**: Ensure all documentation accurately reflects the current configuration and conforms to existing standards

**Tasks**:
- [ ] Audit existing himalaya plugin README files for accuracy:
  - `lua/neotex/plugins/tools/himalaya/README.md` (if exists)
  - Check for outdated account references or configuration examples
- [ ] Update plugin module documentation to reflect dual-account support:
  - Document account switching workflow
  - Document mbsync integration for both Gmail (OAuth2) and Protonmail (Bridge)
- [ ] Create or update configuration reference documentation:
  - List all Himalaya-related keymaps and commands
  - Document the two-tier architecture (mbsync + Himalaya)
  - Include troubleshooting section for common issues (OAuth expiry, Bridge connection)
- [ ] Verify documentation follows nvim/CLAUDE.md standards:
  - Clear purpose explanations
  - Module documentation with code examples
  - Navigation links to parent/child directories
  - No emojis in file content
  - Unicode box-drawing for diagrams if needed
- [ ] Update any inline code comments that reference email configuration
- [ ] Ensure config examples in docs match actual configuration values

**Timing**: 60 minutes

**Files to review/modify**:
- `lua/neotex/plugins/tools/himalaya/README.md` - Main plugin documentation
- `lua/neotex/plugins/tools/himalaya/core/README.md` - Core module docs (if exists)
- `lua/neotex/plugins/tools/himalaya/sync/README.md` - Sync module docs (if exists)
- `lua/neotex/plugins/tools/himalaya/config/README.md` - Config module docs (if exists)
- Any other himalaya-related README files

**Documentation Standards** (from nvim/CLAUDE.md):
- Purpose section explaining directory role
- Module documentation for each file
- Usage examples with syntax highlighting
- Navigation links (parent/subdirectory READMEs)
- Clear, concise language
- No emojis in file content

**Verification**:
- All himalaya README files exist and are complete
- Configuration examples match actual values
- Account names (gmail, logos) are consistently documented
- No references to incorrect providers (e.g., "Google Workspace" for Protonmail)
- Documentation follows CommonMark specification

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
- [ ] All documentation is accurate and follows standards

## Artifacts & Outputs

- plans/implementation-002.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Updated ~/.mbsyncrc with Protonmail configuration
- Updated ~/.config/himalaya/config.toml with logos account (or Nix equivalent)
- Updated lua/neotex/plugins/tools/himalaya/config/accounts.lua
- Updated himalaya plugin README documentation

## Rollback/Contingency

**Gmail rollback**: OAuth2 refresh is non-destructive. If it fails, existing refresh token remains. Worst case: re-authenticate via Google OAuth flow.

**Protonmail rollback**: Bridge installation and mbsync configuration are additive. Remove added sections from ~/.mbsyncrc and delete ~/Mail/Logos/ to restore previous state.

**Himalaya rollback**: Remove logos account section from config.toml. Himalaya will default to gmail account.

**Neovim plugin rollback**: Remove logos account from accounts.lua. Plugin will use only gmail account.

**Documentation rollback**: Git revert any documentation changes if they introduce errors.

**Emergency reset**: If sync conflicts corrupt maildir, delete local maildir directories and re-sync from server (emails remain on server).

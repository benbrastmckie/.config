# Research Report: Task #51

**Task**: 51 - Complete Himalaya Email Configuration
**Started**: 2026-02-08T00:00:00Z
**Completed**: 2026-02-08T00:30:00Z
**Effort**: 3-5 hours
**Dependencies**: OAuth2 token refresh for primary Gmail account
**Sources/Inputs**: Local configuration files, Himalaya CLI documentation, mbsync configuration, system keyring
**Artifacts**: specs/051_complete_himalaya_email_configuration/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- Gmail account (benbrastmckie@gmail.com) is partially configured with maildir backend but OAuth2 tokens have expired
- Logos Labs account (benjamin@logos-labs.ai) is not configured at all and requires full setup
- Neovim himalaya plugin is comprehensive with 70+ modules for email, sync, UI, and OAuth management
- Current architecture uses mbsync for IMAP sync with XOAUTH2, storing emails in local maildir format
- Two main gaps: OAuth token refresh and adding the second account with full synchronization

## Context and Scope

The user wants to complete Himalaya email configuration in Neovim with:
1. Primary account: benjamin@logos-labs.ai (Google Workspace)
2. Secondary account: benbrastmckie@gmail.com (Gmail)

Both accounts should have full local maildir storage with IMAP synchronization.

## Findings

### 1. Current Himalaya CLI Configuration

**Location**: `~/.config/himalaya/config.toml` (symlinked from Nix store)

**Current State**:
```toml
[accounts.gmail]
default = true
email = "benbrastmckie@gmail.com"
display-name = "Benjamin Brast-McKie"
downloads-dir = "/home/benjamin/Downloads"

# Uses local maildir as backend (not IMAP)
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Gmail"
backend.maildirpp = true

# SMTP via OAuth2 for sending
message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 465
message.send.backend.auth.type = "oauth2"
message.send.backend.auth.method = "xoauth2"
# ... OAuth2 tokens stored in keyring
```

**Key Insight**: Himalaya reads from local maildir (synced by mbsync), not directly from IMAP. This is a two-tier architecture:
1. mbsync handles IMAP<->Maildir synchronization
2. Himalaya reads from local maildir

### 2. mbsync (isync) Configuration

**Location**: `~/.mbsyncrc`

**Current Setup**:
- Gmail account configured with XOAUTH2 authentication
- Uses `secret-tool` to retrieve OAuth access token from GNOME keyring
- Full folder sync including: INBOX, Sent, Drafts, Trash, All Mail, Spam
- Channel groups for batch syncing
- Maildir++ format for subfolder organization

**Current Issue**: OAuth2 access token has expired, causing authentication failures:
```
IMAP command 'AUTHENTICATE XOAUTH2 ...' returned an error: [AUTHENTICATIONFAILED] Invalid credentials (Failure)
```

### 3. OAuth2 Token Management

**Components**:
1. Refresh script: `/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2`
2. Environment variables: `GMAIL_CLIENT_ID`, `SASL_PATH` (set in environment)
3. Keyring storage (GNOME keyring via secret-tool):
   - `gmail-smtp-oauth2-access-token` - Current access token (expired)
   - `gmail-smtp-oauth2-refresh-token` - Persistent refresh token
   - `gmail-smtp-oauth2-client-secret` - OAuth client secret

**Token Refresh Process**:
1. Script retrieves refresh token from keyring
2. Makes POST request to Google OAuth2 token endpoint
3. Stores new access token in keyring
4. mbsync retrieves token via `PassCmd "secret-tool lookup ..."`

### 4. Local Maildir Storage

**Current Structure**:
```
/home/benjamin/Mail/
├── Contacts/           # Contact storage
└── Gmail/              # Gmail maildir
    ├── INBOX/
    │   ├── cur/
    │   ├── new/
    │   └── tmp/
    ├── Sent/
    ├── Drafts/
    ├── Trash/
    ├── All Mail/
    ├── Spam/
    ├── EuroTrip/       # Custom folders
    ├── CrazyTown/
    └── Letters/
```

**Current State**: INBOX directories are empty (0 emails), indicating no successful sync has occurred recently.

### 5. Neovim Plugin Architecture

**Location**: `~/.config/nvim/lua/neotex/plugins/tools/himalaya/`

**Module Structure** (70+ Lua files):
- `init.lua` - Plugin entry point with setup()
- `core/` - Config, state, events, logging, API
- `sync/` - mbsync integration, OAuth management, coordinator
- `ui/` - Email list, preview, composer, notifications
- `commands/` - User commands (email, sync, UI, utility)
- `features/` - Attachments, contacts, accounts, headers
- `data/` - Cache, maildir, drafts, search, templates
- `config/` - Account, folder, OAuth, UI configuration

**Key Features**:
- Automatic OAuth token refresh on authentication failure
- mbsync integration with progress tracking
- Draft management with maildir-based storage
- Multi-instance coordination (multiple Neovim instances)
- Async operations throughout

### 6. Gap Analysis: What's Missing

#### For Gmail Account (benbrastmckie@gmail.com)

| Item | Status | Action Needed |
|------|--------|---------------|
| Himalaya config | [DONE] | - |
| mbsync config | [DONE] | - |
| OAuth2 client ID | [DONE] | - |
| OAuth2 tokens | [EXPIRED] | Run token refresh |
| Local maildir | [EXISTS] | Needs sync |
| Neovim plugin | [DONE] | - |

**Immediate Fix**: Refresh OAuth2 token by running:
```bash
refresh-gmail-oauth2
```

Or use Neovim command `:HimalayaOAuthRefresh` if available.

#### For Logos Labs Account (benjamin@logos-labs.ai)

| Item | Status | Action Needed |
|------|--------|---------------|
| Himalaya config | [MISSING] | Add account section |
| mbsync config | [MISSING] | Add IMAP/channels |
| OAuth2 client | [UNKNOWN] | May need separate Google Cloud project |
| OAuth2 tokens | [MISSING] | Run `himalaya account configure` |
| Local maildir | [MISSING] | Will be created on first sync |
| Neovim plugin | [PARTIAL] | May need account config |

## Recommendations

### Phase 1: Fix Gmail Account (30 minutes)

1. **Refresh OAuth2 token**:
   ```bash
   refresh-gmail-oauth2
   ```

2. **Test mbsync**:
   ```bash
   mbsync -V gmail-inbox
   ```

3. **Verify in Neovim**:
   ```vim
   :HimalayaListEmails
   ```

### Phase 2: Add Logos Labs Account (2-3 hours)

1. **Create OAuth2 Credentials**:
   - For Google Workspace accounts, you may need to use the same OAuth2 client as Gmail
   - Or create a new OAuth2 client in Google Cloud Console for the Workspace domain
   - Ensure the Google Workspace admin has enabled "Less secure apps" or OAuth2 access

2. **Configure Himalaya**:
   ```bash
   himalaya account configure logos
   ```
   This will launch the interactive wizard.

3. **Add to config.toml** (manual alternative):
   ```toml
   [accounts.logos]
   email = "benjamin@logos-labs.ai"
   display-name = "Benjamin Brast-McKie"

   backend.type = "maildir"
   backend.root-dir = "/home/benjamin/Mail/Logos"
   backend.maildirpp = true

   message.send.backend.type = "smtp"
   message.send.backend.host = "smtp.gmail.com"
   message.send.backend.port = 465
   message.send.backend.auth.type = "oauth2"
   message.send.backend.auth.method = "xoauth2"
   message.send.backend.auth.client-id = "${GMAIL_CLIENT_ID}"
   message.send.backend.auth.client-secret.keyring = "logos-smtp-oauth2-client-secret"
   message.send.backend.auth.access-token.keyring = "logos-smtp-oauth2-access-token"
   message.send.backend.auth.refresh-token.keyring = "logos-smtp-oauth2-refresh-token"
   # ... additional OAuth2 config
   ```

4. **Add mbsync configuration** to `~/.mbsyncrc`:
   ```mbsync
   # Logos Labs IMAP account
   IMAPAccount logos
   Host imap.gmail.com
   Port 993
   User benjamin@logos-labs.ai
   AuthMechs XOAUTH2
   PassCmd "secret-tool lookup service himalaya-cli username logos-smtp-oauth2-access-token"
   TLSType IMAPS

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

   # ... additional channels for Sent, Drafts, etc.

   Group logos
   Channel logos-inbox
   # ... additional channels
   ```

5. **Create OAuth2 refresh script** for Logos account:
   - Either modify existing script to accept account parameter
   - Or create `refresh-logos-oauth2` script

6. **Create maildir structure**:
   ```bash
   mkdir -p ~/Mail/Logos/{INBOX,Sent,Drafts,Trash}/{cur,new,tmp}
   ```

### Phase 3: Update Neovim Plugin Configuration (1 hour)

1. **Add account to Neovim config** in `config/accounts.lua`:
   ```lua
   M.defaults = {
     gmail = { ... },
     logos = {
       email = nil,  -- Auto-detect
       display_name = nil,  -- Auto-detect
       mbsync = {
         inbox_channel = "logos-inbox",
         all_channel = "logos",
       }
     }
   }
   ```

2. **Add account switching commands** (may already exist):
   - `:HimalayaAccountSwitch logos`
   - `:HimalayaAccountSwitch gmail`

3. **Test the integration**:
   ```vim
   :HimalayaAccountSwitch logos
   :HimalayaSync
   :HimalayaListEmails
   ```

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| OAuth2 client quota issues | Low | Can reuse same client for both accounts |
| Google Workspace admin blocks OAuth | Medium | Contact admin or use App Password |
| Token expiration during sync | Medium | Auto-refresh mechanism exists in plugin |
| Maildir sync conflicts | Low | Lock files prevent concurrent access |
| Large initial sync | Medium | Use `MaxMessages` in mbsync for quick first sync |

## Appendix

### Search Queries Used
- "himalaya email CLI multi-account configuration IMAP 2025"
- "himalaya CLI google workspace oauth2 XOAUTH2 configuration"
- "mbsync isync multiple gmail accounts configuration xoauth2"

### Key References
- [Himalaya GitHub](https://github.com/pimalaya/himalaya) - Official CLI repository
- [isync ArchWiki](https://wiki.archlinux.org/title/Isync) - mbsync configuration guide
- [Google OAuth2 XOAUTH2 Protocol](https://developers.google.com/workspace/gmail/imap/xoauth2-protocol) - Authentication mechanism
- [mbsync XOAUTH2 Guide](https://nfraprado.net/post/setting-up-mbsync-to-work-with-xoauth2.html) - Setup tutorial

### Local Files Examined
- `~/.config/himalaya/config.toml` - Himalaya CLI configuration
- `~/.mbsyncrc` - mbsync (isync) configuration
- `~/.config/nvim/lua/neotex/plugins/tools/himalaya/` - Neovim plugin (70+ files)
- `/home/benjamin/Mail/Gmail/` - Local maildir storage
- `/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2` - Token refresh script

### Environment
- OS: NixOS Linux 6.18.8
- Himalaya: v1.1.0 (+wizard +pgp-commands +oauth2 +sendmail +imap +smtp +keyring +maildir)
- isync (mbsync): 1.5.1
- Keyring: GNOME keyring via secret-tool

# Research Report: Task #53

**Task**: 53 - himalaya_multi_email_config
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None - CLI configuration already complete
**Sources/Inputs**: Himalaya docs, local config files, plugin source code
**Artifacts**: - specs/053_himalaya_multi_email_config/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- Himalaya CLI is already fully configured for both Gmail and Logos (Protonmail) accounts
- The custom neovim plugin already has comprehensive multi-account support built-in
- mbsync configuration is complete for both accounts and working
- Minor configuration gaps exist in the neovim plugin's accounts.lua defaults for Logos
- No new implementation required - only configuration updates and testing

## Context and Scope

The user requested research on configuring himalaya for multi-email account support (Gmail + Protonmail/Logos). Investigation revealed that the foundational work is already complete:

1. **Himalaya CLI**: Both accounts configured in `~/.config/himalaya/config.toml`
2. **mbsync**: Both accounts configured in `~/.mbsyncrc` with working sync groups
3. **Neovim Plugin**: Custom himalaya plugin with full multi-account architecture

## Findings

### 1. Himalaya CLI Configuration (COMPLETE)

**Location**: `~/.config/himalaya/config.toml`

Both accounts are properly configured:

```toml
# Gmail account (default)
[accounts.gmail]
default = true
email = "benbrastmckie@gmail.com"
display-name = "Benjamin Brast-McKie"
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Gmail"
message.send.backend.type = "smtp"
# ... OAuth2 configuration for SMTP

# Logos Labs account (Protonmail Bridge)
[accounts.logos]
default = false
email = "benjamin@logos-labs.ai"
display-name = "Benjamin Brast-McKie"
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Logos"
message.send.backend.type = "smtp"
message.send.backend.host = "127.0.0.1"
message.send.backend.port = 1025
message.send.backend.encryption.type = "none"
message.send.backend.auth.cmd = "secret-tool lookup service protonmail-bridge username benjamin@logos-labs.ai"
```

**Verified Working**:
```bash
$ himalaya account list
| NAME  | BACKENDS      | DEFAULT |
|-------|---------------|---------|
| gmail | Maildir, SMTP | yes     |
| logos | Maildir, SMTP |         |

$ himalaya envelope list -a logos
# Returns emails from Logos account

$ himalaya envelope list -a gmail
# Returns emails from Gmail account
```

### 2. mbsync Configuration (COMPLETE)

**Location**: `~/.mbsyncrc`

Both accounts have full channel configurations:

| Account | Channels | Status |
|---------|----------|--------|
| Gmail | inbox, sent, drafts, trash, all, spam, folders | Working |
| Logos | inbox, sent, drafts, trash, archive | Working |

Both use Maildir++ format with proper folder structures.

### 3. Neovim Plugin Architecture (EXTENSIVE)

**Location**: `~/.config/nvim/lua/neotex/plugins/tools/himalaya/`

The custom himalaya plugin has comprehensive multi-account support:

#### Account Management
- `features/accounts.lua` - Account operations (get_all, get_account, switch_account, add_account, remove_account, unified inbox)
- `config/accounts.lua` - Account configuration and state
- `config/init.lua` - Unified config facade with account methods

#### Account Switching Commands
| Command | Function |
|---------|----------|
| `:HimalayaAccounts` | Show account picker |
| `:HimalayaAccountSwitch [name]` | Switch to account |
| `:HimalayaAccountList` | List all accounts |
| `:HimalayaNextAccount` | Cycle to next account |
| `:HimalayaPreviousAccount` | Cycle to previous account |
| `:HimalayaRefreshAccounts` | Reload account config |

#### Keyboard Shortcuts
- `a` in list view - Switch account (configurable)
- Account switcher uses telescope/native picker

#### Sync Integration
- `sync/mbsync.lua` - mbsync wrapper with OAuth handling
- `sync/manager.lua` - Unified sync orchestration
- Account-specific channel selection based on current account

### 4. Configuration Gap Analysis

**Issue Found**: The `config/accounts.lua` defaults reference a `logos` account but may not have complete folder mappings.

**Current Defaults**:
```lua
M.defaults = {
  gmail = {
    email = nil,  -- Auto-detected from himalaya config
    display_name = nil,  -- Auto-detected from himalaya config
    mbsync = {
      inbox_channel = "gmail-inbox",
      all_channel = "gmail",
    }
  },
  logos = {
    email = nil,  -- Auto-detected from himalaya config
    display_name = nil,  -- Auto-detected from himalaya config
    mbsync = {
      inbox_channel = "logos-inbox",
      all_channel = "logos",
    }
  }
}
```

**Folder Configuration Gap**: The `config/folders.lua` only has default mappings for Gmail. Logos folder mappings are missing:

```lua
-- Current (Gmail only)
M.defaults = {
  gmail = {
    maildir_path = "~/Mail/Gmail/",
    folder_map = {
      ["INBOX"] = "INBOX",
      ["[Gmail]/All Mail"] = "All_Mail",
      -- ... Gmail-specific mappings
    }
  }
  -- Logos is missing!
}
```

### 5. Plugin Features for Multi-Account

#### Unified Inbox
The plugin supports unified inbox across all accounts:
```lua
-- features/accounts.lua
function M.get_unified_inbox(options)
  -- Aggregates emails from all accounts
  -- Sorts by date
  -- Adds account attribution to each email
end
```

#### Account Statistics
```lua
function M.get_account_stats(account_name)
  -- Returns: name, email, type, last_sync, unread_count, folder_count, active
end
```

#### Dynamic Account Discovery
The plugin reads account details from himalaya's TOML config at runtime, so email addresses and display names are auto-populated.

## Recommendations

### 1. Add Logos Folder Mappings

Update `config/folders.lua` to include Logos folder configuration:

```lua
logos = {
  maildir_path = "~/Mail/Logos/",
  folder_map = {
    ["INBOX"] = "INBOX",
    ["Sent"] = "Sent",
    ["Drafts"] = "Drafts",
    ["Trash"] = "Trash",
    ["Archive"] = "Archive",
  },
  local_to_imap = {
    ["INBOX"] = "INBOX",
    ["Sent"] = "Sent",
    ["Drafts"] = "Drafts",
    ["Trash"] = "Trash",
    ["Archive"] = "Archive",
  }
}
```

### 2. Update OAuth Handling for Logos

The Logos account uses password authentication via Protonmail Bridge, not OAuth2. The `sync/oauth.lua` module should skip OAuth validation for non-OAuth accounts.

**Current behavior**: OAuth validation may be incorrectly triggered for Logos account.

**Recommendation**: Add account type check before OAuth validation:
```lua
-- Skip OAuth for non-OAuth accounts (like Protonmail Bridge)
if account_config.auth_type == 'password' then
  return true  -- No OAuth needed
end
```

### 3. Test Account Switching Workflow

Verify the following scenarios work correctly:

1. Switch from Gmail to Logos: `:HimalayaAccountSwitch logos`
2. View Logos inbox: Should show Protonmail emails
3. Sync Logos: `mbsync logos` should work via `:HimalayaSyncInbox`
4. Compose from Logos: SMTP via Bridge should work
5. Switch back to Gmail: `:HimalayaAccountSwitch gmail`

### 4. Configure Auto-Sync for Both Accounts

Currently auto-sync uses the current account's inbox channel. Consider:
- Sync both accounts on timer
- Or sync only the currently active account

## Decisions

1. **No new plugin needed**: The existing custom plugin has full multi-account support
2. **Configuration-only changes**: Update folder mappings in `config/folders.lua`
3. **OAuth skip for Logos**: Add password-auth detection to skip OAuth for Bridge accounts
4. **Testing priority**: Account switching and sync operations for Logos

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OAuth validation fails for Logos | Medium | Medium | Add auth type detection |
| Folder mapping errors | Low | Low | Protonmail uses standard folder names |
| Sync conflicts between accounts | Low | Low | Plugin already has per-account sync |
| Bridge connection issues | Low | Medium | Bridge already tested and working |

## Appendix

### Search Queries Used
- "himalaya email client multi account configuration TOML 2025 2026"
- "himalaya.nvim neovim plugin account switching multiple accounts"

### Key Documentation References
- [Himalaya GitHub - config.sample.toml](https://github.com/pimalaya/himalaya/blob/master/config.sample.toml)
- [himalaya.nvim Plugin](https://github.com/JostBrand/himalaya.nvim) - Note: User has custom plugin, not this one
- Local: `~/.config/nvim/docs/himalaya-manual-setup-guide.md` - Comprehensive setup guide already exists

### Files Examined
- `~/.config/himalaya/config.toml` - CLI configuration
- `~/.mbsyncrc` - mbsync channel configuration
- `lua/neotex/plugins/tools/himalaya/config/accounts.lua` - Account config
- `lua/neotex/plugins/tools/himalaya/config/folders.lua` - Folder mappings
- `lua/neotex/plugins/tools/himalaya/features/accounts.lua` - Account operations
- `lua/neotex/plugins/tools/himalaya/commands/ui.lua` - Account commands
- `lua/neotex/plugins/tools/himalaya/sync/mbsync.lua` - Sync integration

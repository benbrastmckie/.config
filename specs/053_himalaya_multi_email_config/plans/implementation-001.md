# Implementation Plan: Task #53

- **Task**: 53 - himalaya_multi_email_config
- **Status**: [IMPLEMENTING]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Configure the existing Himalaya neovim plugin to fully support the Logos (Protonmail) account alongside Gmail. Research confirms that CLI and mbsync configurations are complete; only the neovim plugin requires folder mappings and OAuth handling adjustments. This is a configuration-only task with minimal code changes.

### Research Integration

From research-001.md:
- Himalaya CLI is fully configured for both accounts (`~/.config/himalaya/config.toml`)
- mbsync channels are working for both Gmail and Logos
- Plugin architecture already supports multi-account (features/accounts.lua)
- Gap: `config/folders.lua` missing Logos folder mappings
- Gap: `sync/oauth.lua` may incorrectly trigger OAuth validation for password-auth accounts

## Goals & Non-Goals

**Goals**:
- Add Logos folder mappings to `config/folders.lua`
- Update OAuth handling to skip validation for password-auth accounts (Protonmail Bridge)
- Verify account switching workflow works correctly
- Test sync and compose operations for Logos account

**Non-Goals**:
- Modifying Himalaya CLI configuration (already complete)
- Modifying mbsync configuration (already working)
- Adding new plugin features or commands
- Unified inbox implementation (already exists in plugin)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| OAuth validation incorrectly triggers for Logos | Medium | Medium | Add auth_type detection before OAuth calls |
| Folder mapping errors break operations | Low | Low | Protonmail uses standard folder names (INBOX, Sent, etc.) |
| SMTP sending fails via Bridge | Medium | Low | Bridge already tested and working in CLI |

## Implementation Phases

### Phase 1: Add Logos Folder Mappings [COMPLETED]

**Goal**: Configure folder mappings for Logos account in the himalaya plugin

**Tasks**:
- [ ] Add Logos folder configuration to `M.defaults` in `config/folders.lua`
- [ ] Include maildir_path, folder_map, and local_to_imap mappings
- [ ] Match folder names to mbsync channel configuration (INBOX, Sent, Drafts, Trash, Archive)

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/folders.lua` - Add Logos account to M.defaults

**Verification**:
- Open Neovim and verify `:lua print(vim.inspect(require('neotex.plugins.tools.himalaya.config.folders').defaults))` shows Logos configuration
- Verify folder paths resolve correctly for Logos account

---

### Phase 2: Update OAuth Handling for Password-Auth [IN PROGRESS]

**Goal**: Prevent OAuth validation from triggering for accounts using password authentication

**Tasks**:
- [ ] Add auth_type detection function to determine if account uses OAuth or password
- [ ] Modify `M.ensure_token()` to skip OAuth for password-auth accounts
- [ ] Modify `M.is_valid()` to return true immediately for password-auth accounts
- [ ] Add `is_oauth_account()` helper function that checks himalaya config

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/sync/oauth.lua` - Add password-auth detection and early-return logic

**Verification**:
- Test that OAuth refresh is not triggered when using Logos account
- Verify no OAuth-related errors appear in logs for Logos operations

---

### Phase 3: Integration Testing [NOT STARTED]

**Goal**: Verify complete multi-account workflow functions correctly

**Tasks**:
- [ ] Test account listing: `:HimalayaAccountList` shows both Gmail and Logos
- [ ] Test account switching: `:HimalayaAccountSwitch logos` changes active account
- [ ] Test folder listing: Verify Logos folders display correctly
- [ ] Test inbox sync: `:HimalayaSyncInbox` works for Logos account
- [ ] Test email viewing: Can read emails from Logos inbox
- [ ] Test compose: Can compose and send from Logos account (optional, requires Bridge running)

**Timing**: 30 minutes

**Files to modify**:
- None (testing only)

**Verification**:
- All listed operations complete without errors
- Account indicator shows correct account after switching
- Emails display correctly from both accounts

---

### Phase 4: Documentation and Cleanup [NOT STARTED]

**Goal**: Update documentation to reflect multi-account support

**Tasks**:
- [ ] Update himalaya plugin README if present
- [ ] Add comments to folders.lua explaining Logos configuration
- [ ] Verify no debug code or test artifacts remain

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/folders.lua` - Add documentation comments
- `docs/himalaya-manual-setup-guide.md` - Update if multi-account section exists (optional)

**Verification**:
- Code comments are clear and helpful
- No TODO or FIXME markers left unaddressed

## Testing & Validation

- [ ] `:HimalayaAccountList` shows both gmail and logos accounts
- [ ] `:HimalayaAccountSwitch logos` successfully switches to Logos
- [ ] Logos inbox displays emails without OAuth errors
- [ ] `:HimalayaSyncInbox` syncs Logos without triggering OAuth refresh
- [ ] Account switching back to Gmail works correctly
- [ ] Gmail operations still function as before (regression test)

## Artifacts & Outputs

- `lua/neotex/plugins/tools/himalaya/config/folders.lua` (modified)
- `lua/neotex/plugins/tools/himalaya/sync/oauth.lua` (modified)
- `specs/053_himalaya_multi_email_config/summaries/implementation-summary-YYYYMMDD.md` (created at completion)

## Rollback/Contingency

If implementation causes issues:
1. Revert changes to `folders.lua` and `oauth.lua` via git
2. Logos account remains usable via CLI (`himalaya -a logos`)
3. Gmail functionality should be unaffected as existing defaults are preserved

No database or external state changes are made, so rollback is straightforward via git revert.

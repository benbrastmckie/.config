# Research Report: Task #77

**Task**: 77 - Fix himalaya sidebar folder selection
**Started**: 2026-02-13T12:00:00Z
**Completed**: 2026-02-13T12:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis, himalaya CLI documentation
**Artifacts**: This research report
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The folder selection menu (triggered by 'c' key) is missing "INBOX" because himalaya's `folder list` command does not return it for Maildir++ backends
- Folders appear in arbitrary order because neither the CLI output nor the `pick_folder` function applies any sorting
- The fix requires modifying `utils.get_folders()` to ensure INBOX is always present and sorting folders by usage priority

## Context & Scope

When pressing 'c' in the himalaya sidebar, a folder selection picker appears. Users report two issues:
1. "Inbox" (INBOX) is not listed in the available folders
2. Folders appear in arbitrary order rather than by usage priority

The scope of this research covers:
- Understanding how folders are retrieved (`utils.get_folders`)
- Understanding how the folder picker displays them (`email_list.pick_folder`)
- Identifying why INBOX is missing
- Determining how to add folder priority ordering

## Findings

### Existing Configuration

**Files involved:**
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/utils.lua` (lines 52-124) - `get_folders` and `scan_maildir_folders`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua` (lines 1988-2030) - `pick_folder`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/folders.lua` - folder configuration

**Current flow:**
1. `pick_folder()` calls `utils.get_folders(account_name)`
2. `get_folders()` calls `himalaya folder list --output json`
3. If CLI returns results, they're converted and returned directly
4. No sorting is applied; folders are shown in the order returned by CLI

### Root Cause Analysis

**Issue 1: Missing INBOX**

The himalaya CLI `folder list` command for Maildir++ backends does NOT return INBOX. Actual output:
```json
[
  {"name":"Spam","desc":"/home/benjamin/Mail/Gmail/.Spam"},
  {"name":"All_Mail","desc":"/home/benjamin/Mail/Gmail/.All_Mail"},
  {"name":"EuroTrip","desc":"/home/benjamin/Mail/Gmail/.EuroTrip"},
  {"name":"Sent","desc":"/home/benjamin/Mail/Gmail/.Sent"},
  {"name":"Letters","desc":"/home/benjamin/Mail/Gmail/.Letters"},
  {"name":"Drafts","desc":"/home/benjamin/Mail/Gmail/.Drafts"},
  {"name":"CrazyTown","desc":"/home/benjamin/Mail/Gmail/.CrazyTown"},
  {"name":"Trash","desc":"/home/benjamin/Mail/Gmail/.Trash"}
]
```

The `scan_maildir_folders()` fallback function (lines 94-124) correctly adds INBOX manually:
```lua
-- Always include INBOX
table.insert(folders, { name = "INBOX", path = "/" })
```

However, this fallback is only called when CLI execution fails. Since the CLI succeeds (just without INBOX), the fallback is never triggered.

**Issue 2: Arbitrary Folder Ordering**

The CLI returns folders in arbitrary order (appears to be filesystem scan order). The `pick_folder` function (lines 2003-2012) simply iterates through the returned folders without sorting:
```lua
for _, folder in ipairs(folders) do
  local folder_name = type(folder) == "table" and folder.name or folder
  ...
end
```

### Maildir Structure

The maildir at `~/Mail/Gmail/` has:
- `INBOX/` (without dot prefix) - standard Maildir inbox location
- `.Drafts/`, `.Sent/`, `.Trash/`, etc. (with dot prefix) - Maildir++ subfolders

Himalaya with `maildirpp = true` scans for dot-prefixed folders but doesn't automatically include the root maildir as INBOX.

### Plugin Documentation

The himalaya CLI documentation confirms:
- `himalaya folder list` lists all existing folders
- No built-in sorting options exist
- The `folder.alias.inbox` config option tells himalaya what folder to use for INBOX operations but doesn't affect folder list output

## Recommendations

### Implementation Approach

**Location:** `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/utils.lua`, function `get_folders()`

**Changes required:**

1. **Always ensure INBOX is present** after CLI call succeeds:
```lua
-- After getting CLI results, ensure INBOX is present
local has_inbox = false
for _, folder in ipairs(folders) do
  if folder.name == 'INBOX' then
    has_inbox = true
    break
  end
end
if not has_inbox then
  table.insert(folders, 1, { name = 'INBOX', path = '/' })
end
```

2. **Apply priority sorting** to folders:
```lua
-- Define folder priority (lower number = higher priority)
local folder_priority = {
  ['INBOX'] = 1,
  ['Sent'] = 2,
  ['Drafts'] = 3,
  ['All_Mail'] = 4,
  ['Trash'] = 5,
  -- All other folders get priority 100
}

-- Sort folders by priority
table.sort(folders, function(a, b)
  local name_a = type(a) == 'table' and a.name or a
  local name_b = type(b) == 'table' and b.name or b
  local priority_a = folder_priority[name_a] or 100
  local priority_b = folder_priority[name_b] or 100
  if priority_a == priority_b then
    return name_a < name_b  -- Alphabetical for same priority
  end
  return priority_a < priority_b
end)
```

### Lazy Loading Strategy

No additional lazy loading required - the code is already part of the himalaya plugin which loads on demand.

### Keymap Suggestions

No keymap changes needed. The 'c' key already correctly triggers `main.pick_folder()` which delegates to `email_list.pick_folder()`.

## Decisions

1. **Modify `utils.get_folders` rather than `pick_folder`**: The folder list is used in multiple places (move email, commands, etc.), so fixing at the source ensures consistency.

2. **Use explicit priority list rather than alphabetical**: User experience is better when frequently-used folders appear first.

3. **Keep fallback `scan_maildir_folders` function**: It provides redundancy when CLI fails and already has the INBOX fix.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Hardcoded priority list may not match all accounts | Use sensible defaults; non-listed folders alphabetized after priority ones |
| INBOX name might differ across backends | Check for 'INBOX' case-insensitively; config aliases handle backend differences |
| Sorting might cause performance impact | Folder lists are typically small (<20 items); sorting is O(n log n) |

## Appendix

### Search Queries Used
- Local grep for `pick_folder`, `get_folders`, `folder.*select`
- Web search: "himalaya email CLI folder list command 2024 2025 documentation"

### References
- [Himalaya GitHub Repository](https://github.com/pimalaya/himalaya) - Official CLI documentation
- Local config: `~/.config/himalaya/config.toml` - Shows `folder.alias.inbox = "INBOX"`
- Himalaya CLI help: `himalaya folder list --help`

### Code Locations

| Function | File | Lines |
|----------|------|-------|
| `get_folders` | utils.lua | 52-92 |
| `scan_maildir_folders` | utils.lua | 94-124 |
| `pick_folder` | email_list.lua | 1988-2030 |
| Folder configuration | config/folders.lua | Full file |
| 'c' keybinding | config/ui.lua | 339-344, 455-460 |

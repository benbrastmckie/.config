# Implementation Plan: Fix Himalaya Sidebar Folder Selection

- **Task**: 77 - Fix himalaya sidebar folder selection
- **Status**: [IMPLEMENTING]
- **Effort**: 1 hour
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Fix the himalaya sidebar folder selection picker to include INBOX (missing due to himalaya CLI not returning it for Maildir++ backends) and sort folders by usage priority. The fix requires modifying `utils.get_folders()` to ensure INBOX is always present and apply priority-based sorting.

### Research Integration

Research report identified:
- Root cause: himalaya CLI `folder list` does not return INBOX for Maildir++ backends
- The fallback `scan_maildir_folders()` correctly adds INBOX but is only called when CLI fails
- No sorting is applied to CLI results - folders appear in filesystem scan order
- Fix location: `utils.get_folders()` function in `lua/neotex/plugins/tools/himalaya/utils.lua` (lines 52-92)

## Goals & Non-Goals

**Goals**:
- Ensure INBOX always appears in folder list regardless of CLI output
- Sort folders by usage priority: INBOX, Sent, Drafts, All_Mail, Trash first
- Alphabetize remaining folders after priority ones

**Non-Goals**:
- Changing himalaya CLI behavior
- Modifying `pick_folder` UI logic
- Adding user-configurable priority ordering

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| INBOX name differs across backends | M | L | Case-sensitive check for "INBOX"; himalaya config handles aliases |
| Hardcoded priorities miss user folders | L | M | Non-listed folders sorted alphabetically after priority ones |
| Sorting affects performance | L | L | Folder lists are small (<20 items); O(n log n) negligible |

## Implementation Phases

### Phase 1: Implement INBOX Guarantee and Priority Sorting [COMPLETED]

**Goal**: Modify `utils.get_folders()` to ensure INBOX is always present and folders are sorted by usage priority.

**Tasks**:
- [ ] Add INBOX presence check after CLI results
- [ ] Insert INBOX at position 1 if missing
- [ ] Define folder priority map (INBOX=1, Sent=2, Drafts=3, All_Mail=4, Trash=5, others=100)
- [ ] Implement `table.sort` with priority-aware comparator
- [ ] Alphabetize folders with same priority

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils.lua` - Add INBOX check and sorting to `get_folders()` function (after line 89, before `return folders`)

**Code Changes**:

After the folder conversion loop (line 89) and before `return folders` (line 91), add:

```lua
-- Ensure INBOX is present (himalaya CLI may not return it for Maildir++)
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

-- Define folder priority (lower number = higher priority)
local folder_priority = {
  ['INBOX'] = 1,
  ['Sent'] = 2,
  ['Drafts'] = 3,
  ['All_Mail'] = 4,
  ['Trash'] = 5,
}

-- Sort folders by priority, then alphabetically
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

**Verification**:
- Code compiles without errors
- INBOX always appears first in folder list
- Priority folders appear before other folders
- Non-priority folders are alphabetized

---

### Phase 2: Verification and Testing [IN PROGRESS]

**Goal**: Verify the fix works correctly with headless Neovim testing.

**Tasks**:
- [ ] Run headless Neovim to verify module loads without errors
- [ ] Test `utils.get_folders()` returns INBOX first
- [ ] Test priority folders appear in correct order
- [ ] Test non-priority folders are alphabetized

**Timing**: 30 minutes

**Files to modify**:
- None (verification only)

**Verification Commands**:

```bash
# Verify module loads without syntax errors
nvim --headless -c "lua require('neotex.plugins.tools.himalaya.utils')" -c "q"

# Verify INBOX is first and folders are sorted (requires himalaya account)
nvim --headless -c "lua local u = require('neotex.plugins.tools.himalaya.utils'); local f = u.get_folders('Gmail'); for i, folder in ipairs(f) do print(i, folder.name) end" -c "q"
```

**Expected Output Order**:
1. INBOX
2. Sent
3. Drafts
4. All_Mail
5. Trash
6. (remaining folders alphabetically)

**Verification**:
- Module loads without errors
- INBOX appears first
- Priority folders appear in order (1-5)
- Remaining folders alphabetized

## Testing & Validation

- [ ] Module loads without Lua syntax errors
- [ ] `get_folders()` returns INBOX as first element
- [ ] Priority folders (Sent, Drafts, All_Mail, Trash) appear in positions 2-5
- [ ] Non-priority folders appear alphabetically after position 5
- [ ] Pressing 'c' in himalaya sidebar shows INBOX in picker
- [ ] Folder order in picker matches priority specification

## Artifacts & Outputs

- `lua/neotex/plugins/tools/himalaya/utils.lua` - Modified with INBOX guarantee and sorting
- `specs/077_fix_himalaya_sidebar_folder_selection/summaries/implementation-summary-YYYYMMDD.md` - Implementation summary

## Rollback/Contingency

If the fix causes issues:
1. Revert changes to `utils.lua` using git: `git checkout lua/neotex/plugins/tools/himalaya/utils.lua`
2. The original behavior (arbitrary order, missing INBOX) will be restored
3. No data loss risk - this is a display/ordering change only

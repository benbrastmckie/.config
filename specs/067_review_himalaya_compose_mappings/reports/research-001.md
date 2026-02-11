# Research Report: Task #67

**Task**: 67 - Review and revise himalaya compose buffer mappings
**Started**: 2026-02-11T12:00:00Z
**Completed**: 2026-02-11T12:30:00Z
**Effort**: Low (1-2 hours)
**Dependencies**: Tasks 64, 65 (related keymap fixes)
**Sources/Inputs**: Local configuration analysis, which-key.lua, email_composer.lua, config/ui.lua
**Artifacts**: This research report
**Standards**: report-format.md

## Executive Summary

- The compose buffer DOES have a send mapping via which-key at `<leader>ms` with `cond = is_compose_buffer`, but it appears AFTER the unconditional `<leader>ms` (sync inbox) in the same wk.add block, causing the conditional mapping to be overridden
- Current compose mappings use 3-letter patterns (`<leader>mcd`, `<leader>mce`, etc.) which violates the 2-letter maximum requirement
- The send capability exists but is not accessible due to mapping priority issue and the mapping is also available at `<leader>mce` which uses 3 letters
- Solution: Add a dedicated `<leader>ms` send mapping in a compose-buffer-only which-key registration that takes precedence

## Context & Scope

The task requires:
1. Adding a send email capability to compose buffers
2. Ensuring all compose mappings use maximum 2 letters after leader (e.g., `<leader>ms` not `<leader>mce`)

## Findings

### Current Compose Buffer Mapping Structure

#### which-key.lua Mappings (lines 534-559)

The main mail group has:
```lua
-- Line 542 - unconditional sync inbox
{ "<leader>ms", "<cmd>HimalayaSyncInbox<CR>", desc = "sync inbox", icon = "..." },

-- Line 549 - conditional send (compose only) - ADDED LATER IN SAME BLOCK
{ "<leader>ms", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "...", cond = is_compose_buffer },
```

**Problem**: Both mappings are in the same `wk.add()` block with the same key. The unconditional mapping at line 542 takes precedence because it comes first and has no condition.

#### Compose-specific subgroup (lines 553-559)

```lua
{ "<leader>mc", group = "compose", icon = "...", cond = is_compose_buffer },
{ "<leader>mcd", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", ... },
{ "<leader>mcD", "<cmd>HimalayaDiscard<CR>", desc = "discard email", ... },
{ "<leader>mce", "<cmd>HimalayaSend<CR>", desc = "send email", ... },
{ "<leader>mcq", "<cmd>HimalayaDiscard<CR>", desc = "quit (discard)", ... },
```

**Problem**: These use 3 letters (`<leader>mcd`, `<leader>mce`) which violates the 2-letter requirement.

### config/ui.lua Compose Keymaps (lines 392-431)

```lua
-- Compose buffer keymaps
{ save_draft = '<C-d>' },
{ discard = '<C-q>' },
{ attach = '<C-a>' },
{ help = '?' }
-- NO send mapping here (was <C-s> but removed due to spelling conflict)
```

The send mapping was deliberately removed in task 65 with a comment:
```lua
-- Note: <C-s> removed to avoid conflict with spelling operations
-- Use <leader>mce (which-key) to send emails instead
```

### email_composer.lua Comments (lines 137-141)

```lua
-- NOTE: Leader mappings are now defined in which-key.lua
-- The following mappings have been moved:
-- <leader>ms - Send email -> HimalayaSend command
-- <leader>mc - Cancel compose -> Moved to <leader>mq in which-key
-- <leader>md - Delete draft -> HimalayaSaveDraft command
```

This comment suggests the intended design was `<leader>ms` for send, but it's not working.

### Analysis of 2-Letter Requirement

Current mappings that violate 2-letter rule:
| Current | Letters | Purpose |
|---------|---------|---------|
| `<leader>mcd` | 3 | save draft |
| `<leader>mcD` | 3 | discard email |
| `<leader>mce` | 3 | send email |
| `<leader>mcq` | 3 | quit (discard) |

Proposed 2-letter alternatives:
| Proposed | Letters | Purpose | Notes |
|----------|---------|---------|-------|
| `<leader>ms` | 2 | send email | Conflicts with sync inbox - needs conditional |
| `<leader>md` | 2 | save draft | Available (not used in mail group) |
| `<leader>mq` | 2 | quit/discard | Available (not used in mail group) |
| `<leader>mD` | 2 | discard (confirm) | Alternative with shift |

### Conflict Analysis

The `<leader>m` namespace in which-key.lua:
| Key | Current Use | Conditional? |
|-----|-------------|--------------|
| `<leader>ma` | switch account | No |
| `<leader>mf` | change folder | No |
| `<leader>mF` | recreate folders | No |
| `<leader>mh` | health check | No |
| `<leader>mi` | sync status | No |
| `<leader>mm` | toggle sidebar | No |
| `<leader>ms` | sync inbox | No (conflict!) |
| `<leader>mS` | full sync | No |
| `<leader>mt` | toggle auto-sync | No |
| `<leader>mw` | write email | No |
| `<leader>mW` | setup wizard | No |
| `<leader>mx` | cancel syncs | No |
| `<leader>mX` | backup & fresh | No |

Available single letters after `<leader>m`:
- `<leader>mb` - unused
- `<leader>mc` - used for compose group
- `<leader>md` - unused (can be draft)
- `<leader>me` - used for email actions group
- `<leader>mg` - unused
- `<leader>mj` - unused
- `<leader>mk` - unused
- `<leader>ml` - unused
- `<leader>mn` - unused
- `<leader>mo` - unused
- `<leader>mp` - unused
- `<leader>mq` - unused (can be quit/discard)
- `<leader>mr` - unused
- `<leader>mu` - unused
- `<leader>mv` - unused
- `<leader>my` - unused
- `<leader>mz` - unused

## Recommendations

### Option 1: Conditional Override (Recommended)

Use which-key's condition system properly by registering compose-only mappings in a SEPARATE `wk.add()` call that runs AFTER the general mail mappings.

```lua
-- First: General mail mappings
wk.add({
  { "<leader>ms", "<cmd>HimalayaSyncInbox<CR>", desc = "sync inbox", ... },
  -- other unconditional mappings
})

-- Second: Compose-buffer overrides (registered later, takes precedence when condition met)
wk.add({
  { "<leader>ms", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "...", cond = is_compose_buffer },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "...", cond = is_compose_buffer },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "discard", icon = "...", cond = is_compose_buffer },
})
```

### Option 2: Different Namespace

Keep `<leader>ms` for sync and use different keys for compose:
```lua
{ "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", cond = is_compose_buffer },  -- e for email/execute
{ "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", cond = is_compose_buffer },
{ "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit", cond = is_compose_buffer },
```

But this conflicts with `<leader>me` (email actions group).

### Option 3: Use Context-Sensitive `<leader>ms`

The ideal UX is:
- In compose buffer: `<leader>ms` = **s**end email
- In email list: `<leader>ms` = **s**ync inbox

This is achievable with proper which-key conditional registration.

## Proposed Mapping Scheme

For compose buffers (2-letter maximum):

| Key | Action | Mnemonic |
|-----|--------|----------|
| `<leader>ms` | send email | **m**ail **s**end |
| `<leader>md` | save draft | **m**ail **d**raft |
| `<leader>mq` | quit/discard | **m**ail **q**uit |

The existing 3-letter `<leader>mc*` group can remain for discoverability but the 2-letter shortcuts should be the primary access method.

## Implementation Steps

1. **Separate compose mappings into their own wk.add block** after the general mail mappings

2. **Add 2-letter compose shortcuts**:
   - `<leader>ms` = send (overrides sync in compose buffers)
   - `<leader>md` = save draft
   - `<leader>mq` = quit/discard

3. **Keep existing `<leader>mc*` subgroup** for which-key discoverability

4. **Update config/ui.lua comment** to reflect new mappings

5. **Update email_composer.lua comment** to match actual mappings

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| which-key condition not overriding | Test with compose buffer to verify conditional mapping takes precedence |
| User confusion about `<leader>ms` meaning | Document in help menu that `<leader>ms` is context-sensitive |
| Breaking existing muscle memory | Keep `<leader>mce` as alternative send mapping |

## Appendix

### Files to Modify

1. `lua/neotex/plugins/editor/which-key.lua`
   - Restructure compose mappings registration order
   - Add 2-letter compose shortcuts

2. `lua/neotex/plugins/tools/himalaya/config/ui.lua`
   - Update comment about which mappings to use

3. `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`
   - Update comment to reflect actual mappings

4. `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`
   - Update help menu to show 2-letter compose shortcuts

### HimalayaSend Command Path

```
which-key (<leader>ms / <leader>mce)
  -> :HimalayaSend command (commands/email.lua:51-67)
    -> main.send_email() (commands/email.lua:62)
      -> main.send_current_email() (ui/main.lua:115-121)
        -> email_composer.send_email(buf) (ui/main.lua:118)
```

The command infrastructure works correctly; only the mapping visibility is broken.

# Research Report: Task #82

**Task**: 82 - fix_nil_check_active_editor_himalaya
**Started**: 2026-02-13T12:00:00Z
**Completed**: 2026-02-13T12:15:00Z
**Effort**: 0.5-1 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**: - /home/benjamin/.config/nvim/specs/082_fix_nil_check_active_editor_himalaya/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The error occurs because `check_active_editor_and_prompt` is called but never defined anywhere in the codebase
- The `HimalayaWrite` command in `email.lua` calls two non-existent functions from `main.lua`
- Root cause: Incomplete refactoring - functions were referenced but never implemented
- Fix: Replace calls to missing functions with calls to existing equivalent functions

## Context & Scope

When pressing `<leader>mw` (mapped to `:HimalayaWrite`), Neovim throws an error:
```
E5108: Error executing lua: ...himalaya/commands/email.lua:29: attempt to call field 'check_active_editor_and_prompt' (a nil value)
```

The investigation focused on:
1. The `HimalayaWrite` command definition in `email.lua`
2. The `main.lua` UI module that is required
3. Searching for the missing function definition throughout the codebase

## Findings

### Error Location

File: `lua/neotex/plugins/tools/himalaya/commands/email.lua`

```lua
-- Lines 24-43:
commands.HimalayaWrite = {
  fn = function(opts)
    local main = require('neotex.plugins.tools.himalaya.ui.main')

    -- Check for active editor and prompt save
    local result = main.check_active_editor_and_prompt()  -- LINE 29: NIL ERROR
    if result == 'cancelled' then
      return
    elseif result == 'switching' then
      -- Will switch after save completes
      return
    end

    -- Get account override from args
    local account_override = nil
    if opts.args and opts.args ~= '' then
      account_override = opts.args
    end

    main.write_email(nil, nil, account_override)  -- LINE 43: ALSO MISSING
  end,
  ...
}
```

### Missing Functions

Two functions are called but do not exist:

1. **`main.check_active_editor_and_prompt()`** - Called at line 29
   - Not defined anywhere in the codebase
   - Purpose (inferred from context): Check if there's an active email composer and prompt user to save

2. **`main.write_email(nil, nil, account_override)`** - Called at line 43
   - Not defined anywhere in the codebase
   - Purpose (inferred): Open a new email compose window

### Existing Equivalent Functions

The `main.lua` module DOES have a function that serves the same purpose:

```lua
-- From main.lua lines 85-89:
function M.compose_email(to_address)
  local buf = email_composer.create_compose_buffer({ to = to_address })
  return coordinator.open_compose_buffer_in_window(buf)
end
```

Additionally, the `email_composer.lua` module has:

```lua
-- From email_composer.lua lines 638-643:
function M.is_composing()
  local buf = vim.api.nvim_get_current_buf()
  return M.is_compose_buffer(buf)
end
```

### Root Cause Analysis

This is an incomplete refactoring issue. The `HimalayaWrite` command was written to call functions that were either:
1. Planned but never implemented
2. Renamed during a refactor but the caller was not updated

The `compose_email` function in `main.lua` provides the core functionality needed, but the `HimalayaWrite` command references non-existent function names.

### Additional Issue in Same Command

The `HimalayaDiscard` command at line 86-101 also has an issue - it calls `main.close_without_saving()` without first requiring `main`, though `main` is in scope from the closure.

## Recommendations

### Implementation Approach

**Option A: Direct Fix (Recommended)**

Replace the missing function calls with existing equivalents:

1. Remove the `check_active_editor_and_prompt` call entirely, or replace with `email_composer.is_composing()` check if needed
2. Replace `main.write_email(nil, nil, account_override)` with `main.compose_email(account_override)`

```lua
commands.HimalayaWrite = {
  fn = function(opts)
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')

    -- Optional: Check if already composing
    if email_composer.is_composing() then
      local notify = require('neotex.util.notifications')
      notify.himalaya('Already composing an email', notify.categories.INFO)
      return
    end

    -- Get account override from args
    local account_override = nil
    if opts.args and opts.args ~= '' then
      account_override = opts.args
    end

    main.compose_email(account_override)
  end,
  opts = {
    nargs = '?',
    desc = 'Compose new email (optional: specify account)'
  }
}
```

**Option B: Implement Missing Functions**

If the intended behavior was to prompt users about unsaved drafts before opening a new compose window, implement `check_active_editor_and_prompt` in `main.lua`:

```lua
function M.check_active_editor_and_prompt()
  local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')

  if email_composer.is_composing() then
    -- Prompt user about existing draft
    -- Return 'cancelled', 'switching', or 'continue'
    return 'cancelled'  -- For now, just block
  end

  return 'continue'
end

function M.write_email(to, cc, account)
  return M.compose_email(to)
end
```

### Recommended Fix

Use Option A (Direct Fix) as it:
- Uses existing, tested code
- Requires minimal changes
- Maintains backward compatibility with existing keymaps

## Decisions

- Recommend replacing missing function calls with existing equivalents
- The `is_composing()` check is optional but provides better UX
- No need to implement the full "prompt and save" workflow if it was not working before

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Loss of intended "prompt to save" functionality | Can implement later if needed; current state is completely broken |
| Breaking other callers of write_email | No other callers exist in codebase |
| Regression in compose behavior | compose_email is well-tested and used elsewhere |

## Appendix

### Search Queries Used

1. `grep "check_active_editor" himalaya/` - Found only the call site
2. `grep "function.*check_active_editor" himalaya/` - No definitions
3. `grep "write_email" himalaya/` - Found only the call site
4. `grep "compose_email" main.lua` - Found the existing function

### Files Analyzed

- `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Error location
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Module being required
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Composer functionality
- `lua/neotex/plugins/editor/which-key.lua` - Keymap confirmation

### References

- Keymap: `<leader>mw` mapped to `:HimalayaWrite` in which-key.lua:529
- Command registration: email.lua setup function

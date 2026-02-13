# Implementation Plan: Task #82

- **Task**: 82 - fix_nil_check_active_editor_himalaya
- **Status**: [COMPLETE]
- **Effort**: 0.5-1 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

The `<leader>mw` keymap (mapped to `:HimalayaWrite`) fails because it calls two non-existent functions: `main.check_active_editor_and_prompt()` and `main.write_email()`. The 'e' key in the Himalaya sidebar works correctly by calling `main.compose_email()`. The fix is to replace the broken function calls with the same `main.compose_email()` call that the 'e' key uses, making both keymaps behave identically.

### Research Integration

Research report (research-001.md) identified:
- Root cause: Incomplete refactoring - functions `check_active_editor_and_prompt` and `write_email` were referenced but never implemented
- Working equivalent: `main.compose_email(to_address)` in main.lua (lines 86-89) is the correct function
- Sidebar 'e' key pattern: Uses `pcall(require, ...)` with `main.compose_email()` call (ui.lua lines 347-352)

## Goals & Non-Goals

**Goals**:
- Make `<leader>mw` behave identically to pressing 'e' in the Himalaya sidebar
- Fix the nil value error when calling `:HimalayaWrite`
- Maintain the account override feature (optional argument)

**Non-Goals**:
- Implementing the "prompt and save" workflow that was originally intended but never built
- Adding new compose functionality beyond what currently works
- Modifying the sidebar 'e' key behavior

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| compose_email signature mismatch with account_override | M | L | Verified: compose_email accepts opts table with account field |
| Loss of intended save-prompt UX | L | M | Can implement later; current state is completely broken |
| Breaking existing callers | L | L | No other callers of write_email exist; compose_email is well-tested |

## Implementation Phases

### Phase 1: Fix HimalayaWrite Command [COMPLETED]

**Goal**: Replace broken function calls with working `compose_email()` call to match sidebar 'e' key behavior.

**Tasks**:
- [ ] Edit `lua/neotex/plugins/tools/himalaya/commands/email.lua` to fix `HimalayaWrite` command
- [ ] Remove call to non-existent `main.check_active_editor_and_prompt()`
- [ ] Replace call to `main.write_email(nil, nil, account_override)` with `main.compose_email(account_override)`
- [ ] Optionally add `is_composing()` check for better UX (prevents opening multiple composers)

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Fix `HimalayaWrite` command (lines 24-48)

**Verification**:
- Open Neovim without errors
- Press `<leader>mw` - should open email composer without errors
- Press 'e' in Himalaya sidebar - should behave identically
- Test with account argument: `:HimalayaWrite personal` - should work

---

### Phase 2: Verification and Testing [COMPLETED]

**Goal**: Verify the fix works correctly and both keymaps produce identical behavior.

**Tasks**:
- [ ] Test `<leader>mw` keymap opens composer correctly
- [ ] Test `:HimalayaWrite` command opens composer correctly
- [ ] Test `:HimalayaWrite <account>` command with account argument works
- [ ] Test 'e' key in Himalaya sidebar for comparison
- [ ] Verify no regressions in email sending workflow

**Timing**: 15 minutes

**Verification**:
- All tests pass without errors
- Compose buffer opens correctly
- Account override is respected when provided

## Testing & Validation

- [ ] `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.commands.email')" -c "q"` - Module loads without errors
- [ ] Manual test: Press `<leader>mw` in normal mode - Opens email composer
- [ ] Manual test: Run `:HimalayaWrite` - Opens email composer
- [ ] Manual test: Run `:HimalayaWrite personal` - Opens composer with 'personal' account
- [ ] Manual test: Open sidebar, press 'e' - Behavior matches `<leader>mw`

## Artifacts & Outputs

- `specs/082_fix_nil_check_active_editor_himalaya/plans/implementation-001.md` (this file)
- `specs/082_fix_nil_check_active_editor_himalaya/summaries/implementation-summary-YYYYMMDD.md` (on completion)

## Rollback/Contingency

If the fix causes issues:
1. Revert changes to `lua/neotex/plugins/tools/himalaya/commands/email.lua` using git
2. The `compose_email` function is well-tested and used by the sidebar, so issues are unlikely
3. If account override handling needs different approach, can modify the opts table passed to `create_compose_buffer`

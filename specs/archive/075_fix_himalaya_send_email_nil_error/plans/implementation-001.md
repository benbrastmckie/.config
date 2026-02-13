# Implementation Plan: Task #75

- **Task**: 75 - fix_himalaya_send_email_nil_error
- **Status**: [COMPLETED]
- **Effort**: 0.5 hours
- **Dependencies**: None
- **Research Inputs**: specs/075_fix_himalaya_send_email_nil_error/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Fix two nil value errors in the Himalaya email commands module. The `HimalayaSend` command calls a non-existent `main.send_email()` function (should be `main.send_current_email()`), and the `HimalayaDiscard` command calls a non-existent `composer.close()` function (should be `main.close_without_saving()`).

### Research Integration

Research confirmed that:
- `main.send_current_email()` exists at line 115 of main.lua and provides the correct API
- `main.close_without_saving()` exists at line 129 of main.lua for discarding emails
- Both functions include proper buffer validation and error handling

## Goals & Non-Goals

**Goals**:
- Fix the nil value error when sending emails with `<leader>me`
- Fix the nil value error when discarding emails via HimalayaDiscard command
- Maintain existing error checking behavior (is_composing validation)

**Non-Goals**:
- Refactoring other Himalaya commands
- Adding new functionality to email composition
- Modifying the keybinding mappings

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Function signature mismatch | Medium | Low | Verified via research that both functions require no arguments |
| Side effects from function change | Low | Low | Both replacement functions have equivalent behavior plus better error handling |

## Implementation Phases

### Phase 1: Apply Function Name Fixes [COMPLETED]

**Goal**: Correct the two invalid function calls in commands/email.lua

**Tasks**:
- [ ] Change `main.send_email()` to `main.send_current_email()` at line 62
- [ ] Change `composer.close()` to `main.close_without_saving()` at line 96

**Timing**: 5 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Fix lines 62 and 96

**Verification**:
- Grep for `main.send_email()` should return no results
- Grep for `composer.close()` in HimalayaDiscard context should return no results

---

### Phase 2: Verify Fixes Work [COMPLETED]

**Goal**: Confirm the fixes resolve the nil value errors

**Tasks**:
- [ ] Run Neovim headless test to verify module loads without error
- [ ] Verify that the HimalayaSend and HimalayaDiscard commands are properly defined

**Timing**: 5 minutes

**Files to modify**:
- None (verification only)

**Verification**:
- `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.commands.email')" -c "q"` exits cleanly
- No Lua errors in headless output

## Testing & Validation

- [ ] Module loads without errors in headless Neovim
- [ ] HimalayaSend command executes without nil errors
- [ ] HimalayaDiscard command executes without nil errors

## Artifacts & Outputs

- Modified file: `lua/neotex/plugins/tools/himalaya/commands/email.lua`
- Implementation summary (upon completion)

## Rollback/Contingency

If fixes cause unexpected behavior:
1. Revert the two line changes using git checkout
2. Re-examine main.lua and email_composer.lua for alternative function names
3. Consider whether is_composing() check is still appropriate

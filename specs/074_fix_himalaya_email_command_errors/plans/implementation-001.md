# Implementation Plan: Task #74

- **Task**: 74 - Fix Multiple Himalaya Email Command Errors
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

This plan addresses three related errors in the Himalaya email plugin: (1) `is_composing()` function does not exist causing nil call errors, (2) folder comparison loops treating folder tables as strings, and (3) reply/forward commands failing to find selected emails. The research identified clear root causes for errors 1 and 2, and diagnostic approaches for error 3.

### Research Integration

- Error 1: `composer.is_composing()` calls fail because function does not exist in `email_composer.lua`
- Error 2: `utils.get_folders()` returns `{name, path}` tables but code uses them as strings
- Error 3: `get_current_email_id()` returns nil when `line_map` or `emails` state not populated

## Goals & Non-Goals

**Goals**:
- Fix `is_composing` nil error by adding wrapper function to email_composer.lua
- Fix `folder:lower()` nil error by extracting `.name` from folder tables
- Add diagnostic logging to debug reply/forward email selection issue
- Maintain backward compatibility with existing code patterns

**Non-Goals**:
- Refactoring the email_list state management system
- Adding new features to the Himalaya plugin
- Modifying the himalaya CLI integration

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| is_composing fix breaks edge cases | Low | Low | Use current buffer check matching existing is_compose_buffer pattern |
| Folder type change affects other code | Medium | Low | Use defensive `type(folder) == "table"` check |
| Reply/forward issue has deeper cause | Medium | Medium | Add logging first, then fix based on diagnostic output |

## Implementation Phases

### Phase 1: Fix is_composing Nil Error [NOT STARTED]

**Goal**: Add `is_composing()` wrapper function to email_composer.lua to fix nil call errors in email.lua

**Tasks**:
- [ ] Add `is_composing()` function to email_composer.lua that checks if current buffer is a compose buffer
- [ ] Verify the function works with existing `is_compose_buffer()` implementation
- [ ] Test HimalayaSend, HimalayaSaveDraft, HimalayaDiscard commands

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Add is_composing() wrapper function

**Verification**:
- Open compose buffer and run `:HimalayaSend` - should not error
- Run `:HimalayaSend` outside compose buffer - should show "No email is being composed" message

---

### Phase 2: Fix folder:lower() Nil Error [NOT STARTED]

**Goal**: Fix archive and spam functions to correctly handle folder tables instead of strings

**Tasks**:
- [ ] Update `do_archive_current_email()` in main.lua to extract `.name` from folder tables
- [ ] Update `do_spam_current_email()` with same fix
- [ ] Update `archive_selected_emails()` batch operation
- [ ] Update `spam_selected_emails()` batch operation

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Fix folder comparison in 4 functions

**Verification**:
- Select email in sidebar and press 'a' (archive) - should not error with nil:lower()
- Select email and press 's' (spam) - should not error with nil:lower()
- Select multiple emails and test batch archive/spam operations

---

### Phase 3: Add Reply/Forward Diagnostics [NOT STARTED]

**Goal**: Add diagnostic logging to understand why reply/forward commands fail to find selected emails

**Tasks**:
- [ ] Add debug logging to `get_current_email_id()` function
- [ ] Add improved error messages to `reply_current_email()` with context
- [ ] Add improved error messages to `reply_all_current_email()`
- [ ] Add improved error messages to `forward_current_email()`
- [ ] Document findings for potential follow-up fix

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Add diagnostic logging and improved error messages

**Verification**:
- Press 'r' on email in sidebar - should show detailed error if fails (not just "No email to reply to")
- Check log output for diagnostic information about state
- If fix is identified during diagnostics, implement and verify

---

### Phase 4: Verification and Testing [NOT STARTED]

**Goal**: Comprehensive testing of all fixes and ensure no regressions

**Tasks**:
- [ ] Test compose buffer commands: send, save draft, discard
- [ ] Test archive operation from sidebar
- [ ] Test spam operation from sidebar
- [ ] Test reply, reply-all, forward operations
- [ ] Verify no new errors in checkhealth

**Timing**: 30 minutes

**Files to modify**: None (testing only)

**Verification**:
- Run `nvim --headless -c "lua require('neotex.plugins.tools.himalaya')" -c "q"` - should load without errors
- All keybindings in himalaya sidebar should function without nil errors

## Testing & Validation

- [ ] `nvim --headless -c "checkhealth"` passes for himalaya plugin
- [ ] Compose buffer operations (send, save, discard) work without nil errors
- [ ] Archive operation works without folder:lower() error
- [ ] Spam operation works without folder:lower() error
- [ ] Reply/forward either works or provides diagnostic information

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (post-implementation)

## Rollback/Contingency

If fixes introduce regressions:
1. Revert email_composer.lua changes (Phase 1)
2. Revert main.lua changes (Phases 2-3)
3. Git history provides clean restore points for each phase

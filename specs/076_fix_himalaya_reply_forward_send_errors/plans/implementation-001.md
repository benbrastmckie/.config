# Implementation Plan: Task #76

- **Task**: 76 - Fix Himalaya reply/forward/send errors
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

This plan addresses two distinct bugs in the Himalaya email client integration:

1. **Reply/Forward/Reply-All failures**: The `get_email_by_id()` function uses the non-existent `envelope get` CLI command, causing "Email not found" errors when replying or forwarding emails.

2. **Email send failures**: The `send_email()` function uses the deprecated `send` command instead of the v1.1.0 `message send` command.

The fix requires updating CLI command syntax in `utils.lua` and `cli.lua` to match himalaya v1.1.0 API, plus adding a helper function to parse `message read` output for reply/forward operations.

### Research Integration

Research report (research-001.md) identified:
- `envelope get` does not exist in himalaya v1.1.0 (only `envelope list` and `envelope thread`)
- `send` must be `message send` in v1.1.0
- The async module already uses correct v1.1.0 syntax (can be used as reference)
- Reply/forward operations require: from, to, cc, subject, date, message_id, references, body

## Goals & Non-Goals

**Goals**:
- Fix reply, reply-all, and forward operations to work with himalaya v1.1.0
- Fix email send to use correct `message send` CLI syntax
- Ensure backward compatibility with cached email data
- Maintain consistent error handling patterns

**Non-Goals**:
- Refactoring the entire himalaya integration
- Adding new features to email composer
- Optimizing email caching strategy
- Supporting older himalaya CLI versions

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `message read` output format differs from expected | High | Medium | Parse actual CLI output, test with real emails |
| stdin handling for `message send` may differ | Medium | Low | Verify temp file approach works with v1.1.0 |
| Breaking existing functionality | High | Low | Test all operations before/after changes |
| Cache invalidation issues | Medium | Low | Ensure cache returns compatible structure |

## Implementation Phases

### Phase 1: Fix send_email() Command Syntax [NOT STARTED]

**Goal**: Update the send command to use `message send` instead of `send`

**Tasks**:
- [ ] Update `utils.lua` line 222 from `{ 'send' }` to `{ 'message', 'send' }`
- [ ] Update `cli.lua` line 105 to detect `message` and `send` for loading message
- [ ] Update `cli.lua` line 213 to check for `message` command instead of just `send`
- [ ] Verify temp file stdin approach works with `message send`

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils.lua` - Fix send_email() command
- `lua/neotex/plugins/tools/himalaya/utils/cli.lua` - Update command detection logic

**Verification**:
- Compose and send a test email
- Verify no "unrecognized subcommand" error
- Check sent email appears in Sent folder

---

### Phase 2: Add parse_message_read_result() Helper [NOT STARTED]

**Goal**: Create helper function to extract email data from `message read` output for reply/forward

**Tasks**:
- [ ] Analyze `himalaya message read <id> -a <account> -o json` output format
- [ ] Create `parse_message_read_result(result, email_id)` function in utils.lua
- [ ] Extract required fields: from, to, cc, subject, date, message_id, references, body
- [ ] Handle edge cases: missing fields, HTML-only emails, multipart messages

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils.lua` - Add new helper function

**Verification**:
- Test helper with various email formats (plain text, HTML, multipart)
- Verify all required fields are extracted correctly
- Test with emails having/missing optional fields

---

### Phase 3: Update get_email_by_id() to Use message read [NOT STARTED]

**Goal**: Replace non-existent `envelope get` with `message read` command

**Tasks**:
- [ ] Replace lines 263-268 in utils.lua with `message read` command
- [ ] Call parse_message_read_result() to transform output
- [ ] Maintain cache-first behavior (check cache before CLI call)
- [ ] Add appropriate error handling for CLI failures

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils.lua` - Update get_email_by_id()

**Verification**:
- Test reply on email not in cache
- Test reply on email in cache (should use cached data)
- Verify forward operation works
- Verify reply-all operation works

---

### Phase 4: Integration Testing and Edge Cases [NOT STARTED]

**Goal**: Verify all operations work correctly end-to-end

**Tasks**:
- [ ] Test reply operation from email list sidebar
- [ ] Test reply operation from email preview window
- [ ] Test reply-all operation
- [ ] Test forward operation
- [ ] Test send operation with compose buffer
- [ ] Test with draft emails (should use existing maildir path)
- [ ] Verify error messages are user-friendly for invalid email IDs

**Timing**: 45 minutes

**Files to modify**:
- None (testing only)

**Verification**:
- All keybindings (r, R, f) work without errors
- Email composition window opens with correct pre-filled data
- Sent emails are delivered successfully
- Error messages are clear when operations fail

## Testing & Validation

- [ ] Reply (r) key opens compose with quoted original message
- [ ] Reply-All (R) key includes all original recipients in Cc
- [ ] Forward (f) key opens compose with forwarded message body
- [ ] Send operation completes without CLI errors
- [ ] Draft emails continue to work (use maildir path, not CLI)
- [ ] Cached emails work correctly (no CLI call needed)
- [ ] Non-cached emails are fetched via `message read`
- [ ] Error notifications are user-friendly

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-{DATE}.md (after completion)
- Modified files:
  - `lua/neotex/plugins/tools/himalaya/utils.lua`
  - `lua/neotex/plugins/tools/himalaya/utils/cli.lua`

## Rollback/Contingency

If implementation causes issues:
1. Revert changes to utils.lua and cli.lua via git
2. Keep original `envelope get` fallback commented for reference
3. Document himalaya version requirements in plugin documentation

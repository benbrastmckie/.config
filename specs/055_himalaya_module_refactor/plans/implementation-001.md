# Implementation Plan: Himalaya Module Refactor

- **Task**: 55 - himalaya_module_refactor
- **Status**: [NOT STARTED]
- **Effort**: 6-8 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md), [research-002.md](../reports/research-002.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Refactor the himalaya email module to implement a progressive 3-state preview interaction model. The current implementation has critical UX gaps: preview mode is disabled by default with no mechanism to enable it, the `<CR>` keymap calls an undefined `handle_enter()` function, and selection toggle is broken. This plan implements the user's desired UX where first `<CR>` opens preview mode (j/k switches between emails), second `<CR>` focuses preview (j/k scrolls content), and third `<CR>` opens email in a full buffer, with `<ESC>` regressing through states.

### Research Integration

From research-001.md:
- Identified 90+ file architecture with sophisticated draft/sync infrastructure
- Critical gaps: broken `<CR>` (undefined handle_enter), broken `<Space>` (undefined toggle_selection)
- Preview only works when `preview_mode` is true, but nothing enables it
- Recommended mutt-style keybindings and proper email reading buffer

From research-002.md:
- Root cause: CursorHold guard checks `is_preview_mode()` which always returns false
- Designed 3-state enum: OFF -> SWITCH -> FOCUS -> BUFFER_OPEN
- Provided concrete implementation patterns for state machine and keymaps
- Identified existing infrastructure to leverage (core/state.lua, email_preview.lua focus functions)

## Goals & Non-Goals

**Goals**:
- Implement 3-state progressive preview interaction (OFF -> SWITCH -> FOCUS -> BUFFER_OPEN)
- Fix broken `<CR>` keymap by implementing `handle_enter()` with state-aware behavior
- Enable preview mode on first `<CR>` with j/k updating preview to different emails
- Implement preview focus mode where j/k scrolls content within preview
- Add `<ESC>` handlers to regress through states
- Fix broken selection toggle (`<Space>` keymap)
- Create email reader buffer for full email viewing

**Non-Goals**:
- Refactoring the entire module architecture
- Adding new himalaya CLI integrations (thread view, flag management)
- Changing the existing draft/compose workflow
- Implementing batch operations (delete selected, move selected)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking existing compose/draft workflow | High | Low | All changes are additive; preserve existing infrastructure |
| Focus management errors (invalid window handles) | Medium | Medium | Always validate window handles with pcall before operations |
| State desynchronization when windows closed externally | Medium | Low | Add WinClosed autocmd to reset state |
| Keymap conflicts in different modes | Medium | Medium | Use buffer-local keymaps set/cleared on state transition |

## Implementation Phases

### Phase 1: Implement State Machine Infrastructure [NOT STARTED]

**Goal**: Add the 3-state enum and state tracking to email_preview.lua

**Tasks**:
- [ ] Add PREVIEW_STATE enum (OFF, SWITCH, FOCUS, BUFFER_OPEN) to email_preview.lua
- [ ] Update preview_state table to use enum instead of boolean preview_mode
- [ ] Add sidebar_cursor_line to preview_state for cursor position tracking
- [ ] Implement state getter functions: get_mode(), is_mode(mode)
- [ ] Export PREVIEW_STATE enum for use by other modules

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua` - Add state enum and tracking

**Verification**:
- Load module without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.email_preview')" -c "q"`
- PREVIEW_STATE.OFF, SWITCH, FOCUS, BUFFER_OPEN are accessible
- get_mode() returns PREVIEW_STATE.OFF initially

---

### Phase 2: Implement State Transition Functions [NOT STARTED]

**Goal**: Add functions to transition between states (enter/exit for each mode)

**Tasks**:
- [ ] Implement enter_switch_mode() - shows preview, sets mode to SWITCH
- [ ] Implement enter_focus_mode() - stores cursor, focuses preview window, sets mode to FOCUS
- [ ] Implement exit_focus_mode() - returns focus to sidebar, restores cursor, sets mode to SWITCH
- [ ] Implement exit_switch_mode() - hides preview, sets mode to OFF
- [ ] Implement open_email_in_buffer() - opens email in full buffer, sets mode to BUFFER_OPEN

**Timing**: 1.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua` - Add transition functions

**Verification**:
- Can call enter_switch_mode() and mode changes to SWITCH
- Can call enter_focus_mode() and focus moves to preview window
- exit_focus_mode() returns focus to sidebar correctly
- exit_switch_mode() hides preview and resets to OFF

---

### Phase 3: Implement handle_enter() in email_list.lua [NOT STARTED]

**Goal**: Add the missing handle_enter() function that delegates to state machine

**Tasks**:
- [ ] Implement handle_enter() function that checks current state and calls appropriate transition
- [ ] Implement get_email_id_from_line(line) helper if not already present
- [ ] Implement open_current_email_in_buffer() for terminal state transition
- [ ] Ensure proper error handling for missing email selection

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Add handle_enter() and helpers

**Verification**:
- First `<CR>` in sidebar opens preview (enters SWITCH mode)
- Second `<CR>` focuses preview (enters FOCUS mode)
- Third `<CR>` from focus opens email in buffer

---

### Phase 4: Implement CursorMoved Handler for SWITCH Mode [NOT STARTED]

**Goal**: Make j/k navigation update preview when in SWITCH mode

**Tasks**:
- [ ] Add CursorMoved autocmd that checks if mode is SWITCH
- [ ] On cursor movement in SWITCH mode, update preview to show current email
- [ ] Ensure CursorMoved handler does nothing in OFF mode (preserve current behavior)
- [ ] Ensure CursorMoved handler does nothing in FOCUS mode (cursor frozen in sidebar)

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Modify setup_hover_preview() or add new autocmd

**Verification**:
- Enter SWITCH mode with `<CR>`
- Move cursor with j/k and preview updates to show different email
- In OFF mode, j/k just moves cursor (no preview)

---

### Phase 5: Implement Focus Mode Keymaps [NOT STARTED]

**Goal**: Set up keymaps for preview buffer when in FOCUS mode

**Tasks**:
- [ ] Implement setup_focus_keymaps(buf) function in email_preview.lua
- [ ] Add j/k keymaps for scrolling preview content
- [ ] Add page scrolling keymaps (C-d, C-u, C-f, C-b)
- [ ] Add `<CR>` keymap to open email in buffer
- [ ] Add `<ESC>` and `q` keymaps to return to SWITCH mode
- [ ] Call setup_focus_keymaps when entering focus mode

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua` - Add setup_focus_keymaps()

**Verification**:
- Enter FOCUS mode and j/k scrolls preview content
- `<ESC>` returns to SWITCH mode with cursor at previous position
- C-d/C-u page scrolls work in FOCUS mode

---

### Phase 6: Add ESC Handler to Sidebar [NOT STARTED]

**Goal**: Make `<ESC>` in sidebar state-aware for regressing through states

**Tasks**:
- [ ] Add `<ESC>` keymap to sidebar buffer that checks current state
- [ ] In SWITCH mode, `<ESC>` calls exit_switch_mode()
- [ ] In OFF mode, `<ESC>` does nothing (or could close sidebar - TBD)
- [ ] Ensure `<ESC>` keymap is buffer-local and only active in sidebar

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Add ESC keymap to setup_email_list_keymaps()

**Verification**:
- In SWITCH mode, `<ESC>` hides preview and returns to OFF mode
- In OFF mode, `<ESC>` does not error or produce unexpected behavior
- State progression: OFF -> SWITCH (CR) -> OFF (ESC) works correctly

---

### Phase 7: Fix Selection Toggle [NOT STARTED]

**Goal**: Implement the missing toggle_selection() function

**Tasks**:
- [ ] Implement toggle_selection() in email_list.lua
- [ ] Get email_id and email_data from current cursor line
- [ ] Call state.toggle_email_selection(email_id, email_data)
- [ ] Call update_selection_display() to refresh checkbox UI
- [ ] Verify `<Space>` keymap correctly calls toggle_selection()

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Add toggle_selection()

**Verification**:
- `<Space>` on email line toggles checkbox from [ ] to [x]
- `<Space>` again toggles back to [ ]
- Multiple emails can be selected

---

### Phase 8: Implement Email Reader Buffer [NOT STARTED]

**Goal**: Create a proper buffer for reading emails (terminal BUFFER_OPEN state)

**Tasks**:
- [ ] Create new module ui/email_reader.lua (or extend email_preview.lua)
- [ ] Implement open_email_buffer(email_id) function
- [ ] Create buffer with himalaya-email filetype
- [ ] Fetch email content via himalaya CLI
- [ ] Apply proper syntax highlighting and formatting
- [ ] Set up buffer-local keymaps (q to close, r to reply, f to forward, d to delete)
- [ ] On buffer close, reset state to OFF and return focus to sidebar

**Timing**: 1.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` (new file)
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua` - Call email_reader from open_email_in_buffer()

**Verification**:
- Third `<CR>` opens email in proper buffer (split to right of sidebar)
- Email content is displayed with proper formatting
- `q` closes buffer and returns to sidebar in OFF mode
- Reply/forward keymaps work from reader buffer

---

### Phase 9: Add WinClosed Handler for State Cleanup [NOT STARTED]

**Goal**: Handle external window closure to prevent state desynchronization

**Tasks**:
- [ ] Add WinClosed autocmd for preview window
- [ ] On preview window closed, reset state to OFF
- [ ] Add WinClosed autocmd for sidebar window
- [ ] On sidebar closed, clean up all preview state
- [ ] Add WinClosed autocmd for email reader buffer
- [ ] On reader closed, reset state to OFF

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua` - Add WinClosed handlers

**Verification**:
- Manually close preview window (e.g., :q), state resets to OFF
- Close sidebar, all himalaya state is cleaned up
- Close email reader, returns to sidebar in OFF mode

---

### Phase 10: Integration Testing and Polish [NOT STARTED]

**Goal**: Verify complete workflow and fix edge cases

**Tasks**:
- [ ] Test complete state progression: OFF -> SWITCH -> FOCUS -> BUFFER_OPEN
- [ ] Test state regression: BUFFER_OPEN -> (close) -> OFF, FOCUS -> SWITCH -> OFF
- [ ] Test edge cases: rapid key presses, invalid email_id, empty inbox
- [ ] Verify selection toggle works independently of preview state
- [ ] Test interaction with existing features (compose, sync, folder switching)
- [ ] Fix any discovered issues

**Timing**: 1 hour

**Files to modify**:
- Any files needing fixes based on testing

**Verification**:
- Full UX workflow matches specification from research-002.md
- No regressions in existing functionality
- Error cases handled gracefully

## Testing & Validation

- [ ] Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya')" -c "q"`
- [ ] First `<CR>` shows preview pane and enters SWITCH mode
- [ ] j/k in SWITCH mode updates preview to show different email
- [ ] Second `<CR>` focuses preview pane (cursor visible in preview)
- [ ] j/k in FOCUS mode scrolls preview content
- [ ] `<ESC>` from FOCUS returns to SWITCH (cursor back in sidebar)
- [ ] `<ESC>` from SWITCH hides preview entirely (OFF mode)
- [ ] Third `<CR>` opens email in full buffer
- [ ] `q` from email buffer closes and returns to sidebar
- [ ] `<Space>` toggles email selection checkbox
- [ ] Existing compose/draft workflow still functions

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Modified files:
  - `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
  - `lua/neotex/plugins/tools/himalaya/config/ui.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` (new)

## Rollback/Contingency

If implementation causes issues:
1. Git revert to pre-implementation state
2. Restore original email_preview.lua, email_list.lua, config/ui.lua
3. The new email_reader.lua can simply be deleted
4. No database/state changes - only Lua module modifications

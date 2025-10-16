# Alternative Keymap Strategies for Preview Focus

**Report ID**: 042
**Date**: 2025-10-08
**Status**: Research Complete

## Executive Summary

This report analyzes alternative approaches to handling Esc keymap for returning from preview focus in Telescope pickers. The current buffer-local keymap approach has a race condition where the buffer becomes invalid between validation and `vim.keymap.set()`. Five alternative strategies are evaluated with code examples, pros/cons analysis, and a recommended approach.

## Context

### Current Implementation
Location: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:2773-2778`

```lua
-- Tab handler: Focus preview pane for scrolling
map("i", "<Tab>", function()
  local picker = action_state.get_current_picker(prompt_bufnr)
  local preview_winid = picker.previewer.state.winid
  local preview_bufnr = picker.previewer.state.bufnr

  -- Validate window and buffer
  if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) or
     not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
    return
  end

  -- Switch focus to preview window
  vim.api.nvim_set_current_win(preview_winid)

  -- Set buffer-local Esc mapping to return to picker
  vim.keymap.set("n", "<Esc>", function()
    preview_focused = false
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })
end)
```

### Problem
The buffer validation passes, but then the buffer is invalidated (likely deleted/recreated) between the validation check and `vim.keymap.set()`, causing the error:

```
E5108: Error executing lua: .../lua/neotex/plugins/ai/claude/commands/picker.lua:2773: Invalid buffer id: XXXX
```

### Research Questions
1. Can Neovim support window-local keymaps?
2. Can global keymaps with conditional logic work reliably?
3. Can autocmds provide a more robust approach?
4. Does vim.schedule/defer_fn solve the timing issue?
5. Are there Telescope-native approaches?

## Research Findings

### 1. Window-Local Keymaps

**API Support**: Neovim does NOT support window-local keymaps natively.

**Evidence**:
- GitHub Issue #16263: Feature request for window-local mappings
- `vim.keymap.set()` only supports:
  - Global mappings (default)
  - Buffer-local mappings (`buffer = bufnr` or `buffer = true`)
- No `win` parameter exists for `vim.keymap.set()`

**Conclusion**: Window-local keymaps are not available as a solution.

### 2. Telescope Preview Buffer Lifecycle

**Key Findings**:
- Preview buffers are created/cached by `new_buffer_previewer()`
- Buffers can be cached based on `get_buffer_by_name()`
- Teardown function cleans up buffers when picker closes
- `keep_last_buf = true` can preserve last preview buffer
- Buffers may be deleted/recreated when selection changes

**Relevance**: Preview buffers can be deleted at selection change, explaining the race condition.

### 3. vim.schedule Timing Guarantees

**Behavior**:
- `vim.schedule()` schedules callback to run "soon" in the event loop
- Used to defer operations to when the API is safe to call
- No exact timing guarantees - just "when safe"
- Required for API calls from vim.uv callbacks

**Limitations**:
- Doesn't guarantee buffer will still be valid when callback runs
- Could delay the problem but not solve it
- May create user-visible lag

### 4. Telescope Keymap Mechanisms

**Built-in Preview Scrolling**:
```lua
mappings = {
  i = {
    ["<C-u>"] = actions.preview_scrolling_up,
    ["<C-d>"] = actions.preview_scrolling_down,
  }
}
```

**Key Finding**: Telescope has built-in actions for preview scrolling that don't require focusing the preview window. These operate on the preview from the prompt buffer.

**attach_mappings Pattern**:
- Receives `prompt_bufnr` and `map` function
- Should return `true` to keep default mappings
- Can override actions with `actions.select_default:replace()`

## Alternative Strategies

### Strategy 1: Use Telescope's Built-in Preview Scrolling Actions

**Approach**: Instead of focusing the preview window, use Telescope's built-in preview scrolling actions.

**Code Example**:
```lua
attach_mappings = function(prompt_bufnr, map)
  local actions = require("telescope.actions")

  -- Use built-in preview scrolling instead of focusing
  map("i", "<C-d>", actions.preview_scrolling_down)
  map("i", "<C-u>", actions.preview_scrolling_up)
  map("i", "<C-f>", actions.preview_scrolling_down)
  map("i", "<C-b>", actions.preview_scrolling_up)

  -- No need for Tab to focus preview or Esc to return
  return true
end
```

**Pros**:
- No buffer validity issues - operates from prompt buffer
- No complex state management needed
- Standard Telescope pattern used across ecosystem
- No race conditions possible
- User stays in prompt buffer (can still search/filter)

**Cons**:
- Different UX from current Tab-focus approach
- Can't use normal vim motions (j/k, gg, G, etc.) in preview
- Limited to Telescope's preview scrolling actions
- User can't select/copy text from preview easily

**Reliability**: Very High - No buffer validity issues possible

### Strategy 2: Global Keymap with Window Context Check

**Approach**: Set a global Esc mapping that checks if current window is the preview window before acting.

**Code Example**:
```lua
attach_mappings = function(prompt_bufnr, map)
  local preview_winid = nil
  local picker_prompt_win = nil

  map("i", "<Tab>", function()
    local picker = action_state.get_current_picker(prompt_bufnr)
    preview_winid = picker.previewer.state.winid
    picker_prompt_win = picker.prompt_win

    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
      vim.api.nvim_set_current_win(preview_winid)

      -- Set global Esc mapping with window check
      vim.keymap.set("n", "<Esc>", function()
        local current_win = vim.api.nvim_get_current_win()
        if current_win == preview_winid then
          -- Return to picker
          if picker_prompt_win and vim.api.nvim_win_is_valid(picker_prompt_win) then
            vim.api.nvim_set_current_win(picker_prompt_win)
          end
        else
          -- Normal Esc behavior - return to normal mode or close
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        end
      end, { desc = "Return from Telescope preview" })
    end
  end)

  -- Clean up global Esc mapping when picker closes
  vim.api.nvim_create_autocmd("User", {
    pattern = "TelescopeClose",
    once = true,
    callback = function()
      pcall(vim.keymap.del, "n", "<Esc>")
    end,
  })

  return true
end
```

**Pros**:
- No buffer validity issues
- Allows full preview window focus
- Can use normal vim motions in preview
- Window check is reliable

**Cons**:
- Global keymap pollution (affects all normal mode Esc)
- Cleanup required when picker closes
- Could interfere with other plugins/workflows
- Must handle normal Esc fallback correctly
- Risk of orphaned global mapping if cleanup fails

**Reliability**: Medium - Global mapping risks, but no buffer issues

### Strategy 3: Autocmd-Based Keymap Management

**Approach**: Use BufEnter/BufLeave autocmds to set/unset the Esc keymap dynamically.

**Code Example**:
```lua
attach_mappings = function(prompt_bufnr, map)
  local augroup = vim.api.nvim_create_augroup("TelescopePreviewEsc", { clear = true })

  map("i", "<Tab>", function()
    local picker = action_state.get_current_picker(prompt_bufnr)
    local preview_winid = picker.previewer.state.winid
    local preview_bufnr = picker.previewer.state.bufnr

    if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) then
      return
    end

    -- Switch to preview window
    vim.api.nvim_set_current_win(preview_winid)

    -- Set up autocmd to add keymap when entering preview buffer
    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      buffer = preview_bufnr,
      callback = function(args)
        -- Only set keymap if buffer is still valid
        if vim.api.nvim_buf_is_valid(args.buf) then
          pcall(vim.keymap.set, "n", "<Esc>", function()
            if vim.api.nvim_win_is_valid(picker.prompt_win) then
              vim.api.nvim_set_current_win(picker.prompt_win)
            end
          end, { buffer = args.buf, nowait = true })
        end
      end,
    })

    -- Clean up keymap when leaving preview buffer
    vim.api.nvim_create_autocmd("BufLeave", {
      group = augroup,
      buffer = preview_bufnr,
      callback = function(args)
        pcall(vim.keymap.del, "n", "<Esc>", { buffer = args.buf })
      end,
    })
  end)

  -- Clean up autocmds when picker closes
  vim.api.nvim_create_autocmd("User", {
    pattern = "TelescopeClose",
    once = true,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, augroup)
    end,
  })

  return true
end
```

**Pros**:
- Keymap only exists when buffer is actually entered
- Automatic cleanup on buffer leave
- No global mapping pollution
- Can use pcall for safety

**Cons**:
- Complex setup with multiple autocmds
- Autocmd overhead for every buffer enter/leave
- Still possible buffer could be deleted before BufEnter fires
- Requires careful cleanup management
- More code to maintain

**Reliability**: Medium-High - Safer than direct buffer mapping, but still some timing risk

### Strategy 4: vim.schedule Deferred Keymap Setting

**Approach**: Use vim.schedule to defer keymap setting until after window switch completes.

**Code Example**:
```lua
attach_mappings = function(prompt_bufnr, map)
  map("i", "<Tab>", function()
    local picker = action_state.get_current_picker(prompt_bufnr)
    local preview_winid = picker.previewer.state.winid
    local preview_bufnr = picker.previewer.state.bufnr

    if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) or
       not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
      return
    end

    -- Switch focus to preview window
    vim.api.nvim_set_current_win(preview_winid)

    -- Defer keymap setting to next event loop cycle
    vim.schedule(function()
      -- Re-validate buffer before setting keymap
      if vim.api.nvim_buf_is_valid(preview_bufnr) then
        vim.keymap.set("n", "<Esc>", function()
          if vim.api.nvim_win_is_valid(picker.prompt_win) then
            vim.api.nvim_set_current_win(picker.prompt_win)
          end
        end, { buffer = preview_bufnr, nowait = true })
      end
    end)

    vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
  end)

  return true
end
```

**Pros**:
- Minimal code change from current approach
- Defers keymap setting to when API is fully safe
- Still buffer-local (no global pollution)
- Re-validates buffer before setting

**Cons**:
- No timing guarantees - buffer could still be deleted
- Might delay keymap availability (user presses Esc before it's set)
- Doesn't actually solve the root problem
- Could create user-visible lag
- Still possible for buffer to be invalid

**Reliability**: Low-Medium - May reduce frequency but doesn't eliminate issue

### Strategy 5: Hybrid Approach - State Tracking Without Buffer Keymap

**Approach**: Track preview focus state and override select_default to handle Esc-like behavior without setting buffer keymaps.

**Code Example**:
```lua
attach_mappings = function(prompt_bufnr, map)
  local preview_focused = false
  local preview_winid = nil

  -- Tab: Focus preview window (no keymap setting)
  map("i", "<Tab>", function()
    local picker = action_state.get_current_picker(prompt_bufnr)
    preview_winid = picker.previewer.state.winid

    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
      preview_focused = true
      vim.api.nvim_set_current_win(preview_winid)
      vim.api.nvim_echo({{" Preview focused - Press <C-c> to return to picker ", "Normal"}}, false, {})
    end
  end)

  -- Ctrl-c in normal mode: Return from preview to picker
  map("n", "<C-c>", function()
    if preview_focused then
      local picker = action_state.get_current_picker(prompt_bufnr)
      preview_focused = false
      if picker and picker.prompt_win and vim.api.nvim_win_is_valid(picker.prompt_win) then
        vim.api.nvim_set_current_win(picker.prompt_win)
        vim.api.nvim_echo({{"", "Normal"}}, false, {})
      end
    end
  end)

  -- Reset state on selection change
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = prompt_bufnr,
    callback = function()
      preview_focused = false
    end,
  })

  return true
end
```

**Pros**:
- No buffer validity issues at all
- Uses non-conflicting key (<C-c> instead of Esc)
- Simple state management
- No cleanup required
- Very reliable

**Cons**:
- Different key from Esc (user must learn <C-c>)
- Esc still closes picker instead of returning to it
- Different UX than expected
- Doesn't intercept normal Esc behavior

**Reliability**: Very High - No buffer operations

## Comparison Matrix

| Strategy | Reliability | Complexity | Buffer Issues | Global Pollution | UX Impact |
|----------|-------------|------------|---------------|------------------|-----------|
| 1. Built-in Actions | Very High | Low | None | None | High (no focus) |
| 2. Global Keymap | Medium | Medium | None | High | Low |
| 3. Autocmd-Based | Medium-High | High | Minimal | None | Low |
| 4. vim.schedule | Low-Medium | Low | Possible | None | Low-Medium |
| 5. Hybrid (<C-c>) | Very High | Low | None | None | Medium |

## Recommended Approach

### Primary Recommendation: Strategy 2 (Global Keymap with Cleanup)

**Rationale**:
1. **Eliminates buffer validity issues** - No buffer-local keymaps
2. **Preserves full preview focus UX** - Users can use normal vim motions
3. **Manageable complexity** - Clear setup and cleanup path
4. **Controlled global impact** - Only active during picker lifetime

**Implementation Guidance**:

```lua
attach_mappings = function(prompt_bufnr, map)
  local preview_winid = nil
  local picker_prompt_win = nil
  local esc_keymap_set = false

  -- Tab handler: Focus preview window
  map("i", "<Tab>", function()
    local picker = action_state.get_current_picker(prompt_bufnr)
    if not picker or not picker.previewer or not picker.previewer.state then
      return
    end

    preview_winid = picker.previewer.state.winid
    picker_prompt_win = picker.prompt_win

    if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) then
      return
    end

    -- Switch to preview window
    vim.api.nvim_set_current_win(preview_winid)

    -- Set global Esc keymap (only once)
    if not esc_keymap_set then
      vim.keymap.set("n", "<Esc>", function()
        local current_win = vim.api.nvim_get_current_win()

        -- Check if we're in the preview window
        if current_win == preview_winid and vim.api.nvim_win_is_valid(current_win) then
          -- Return to picker prompt
          if picker_prompt_win and vim.api.nvim_win_is_valid(picker_prompt_win) then
            vim.api.nvim_set_current_win(picker_prompt_win)
            vim.api.nvim_echo({{"", "Normal"}}, false, {})
            return
          end
        end

        -- Fallback: Normal Esc behavior (close picker or normal mode)
        local esc_key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc_key, "n", false)
      end, { desc = "Return from Telescope preview or normal Esc" })

      esc_keymap_set = true
    end

    vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
  end)

  -- Cleanup: Remove global Esc mapping when picker closes
  local cleanup = function()
    if esc_keymap_set then
      pcall(vim.keymap.del, "n", "<Esc>")
      esc_keymap_set = false
    end
  end

  -- Hook into picker close
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = prompt_bufnr,
    once = true,
    callback = cleanup,
  })

  return true
end
```

### Alternative Recommendation: Strategy 1 (Built-in Preview Scrolling)

**When to Use**: If you can accept limited preview interaction and want maximum reliability.

**Benefits**:
- Zero buffer issues
- Simplest implementation
- Standard Telescope pattern

**Tradeoffs**:
- Can't use vim motions in preview
- Can't select/copy text from preview
- Different UX from Tab-focus approach

## Implementation Checklist

For Strategy 2 (Global Keymap):
- [ ] Replace buffer-local keymap with global keymap
- [ ] Add window context check in Esc handler
- [ ] Implement cleanup on picker close (BufLeave autocmd)
- [ ] Add flag to prevent duplicate keymap setting
- [ ] Test Esc behavior in preview window
- [ ] Test Esc behavior outside preview window
- [ ] Test cleanup on picker close
- [ ] Verify no orphaned global mappings

For Strategy 1 (Built-in Actions):
- [ ] Remove Tab handler for preview focus
- [ ] Add preview scrolling keymaps (<C-d>, <C-u>, etc.)
- [ ] Update keyboard shortcuts documentation
- [ ] Test preview scrolling from prompt buffer

## Edge Cases to Consider

1. **Multiple Pickers Open**: If multiple Telescope pickers open simultaneously, ensure cleanup is specific to each picker
2. **Picker Close During Preview Focus**: Ensure cleanup runs even if picker closed while in preview
3. **Rapid Tab Presses**: Prevent duplicate keymap setting
4. **Preview Buffer Deletion**: Handle case where preview buffer is deleted while focused
5. **Window Close Events**: Ensure cleanup on window close, not just buffer leave

## References

- [Neovim Issue #16263 - Window-local mappings](https://github.com/neovim/neovim/issues/16263)
- [Telescope Issue #859 - Race condition with termopen](https://github.com/nvim-telescope/telescope.nvim/issues/859)
- [Neovim API Documentation - nvim_set_keymap](https://neovim.io/doc/user/api.html)
- Current implementation: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:2773-2778`

## Conclusion

The global keymap approach (Strategy 2) provides the best balance of reliability, UX preservation, and maintainability. While it introduces a global mapping, the window context check and proper cleanup ensure it only affects the intended workflow. The built-in preview scrolling approach (Strategy 1) is recommended as a simpler alternative if full preview focus is not required.

Both strategies completely eliminate the buffer validity race condition that plagues the current buffer-local keymap approach.

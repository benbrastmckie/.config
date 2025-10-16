# Implementation Plan: Heading README Preview

**Plan ID**: 032
**Status**: Not Started
**Created**: 2025-10-07
**Complexity**: Low

## Overview

Enhance categorical headings in the Claude commands picker to preview README.md content from associated .claude/ directories instead of displaying generic placeholder text.

## Context

### Current Behavior
- Category headings ([Commands], [Hook Events], [TTS Files]) show generic text: "This is a category heading..."
- Location: picker.lua lines 444-454 in create_command_previewer()
- Entry structure includes `is_heading` flag and `ordinal` field (commands, hooks, tts)

### Directory Mapping
- `[Commands]` (ordinal: commands) → .claude/commands/README.md
- `[Hook Events]` (ordinal: hooks) → .claude/hooks/README.md
- `[TTS Files]` (ordinal: tts) → .claude/tts/README.md

### README Availability
- All primary directories have comprehensive README.md files
- Content ranges from 100-750+ lines of well-structured markdown
- Content is suitable for preview display with syntax highlighting

## Success Criteria

- [PENDING] Category headings preview README content when selected
- [PENDING] Markdown syntax highlighting applied to README previews
- [PENDING] Preview limited to first 100-150 lines to prevent overflow
- [PENDING] Fallback to current behavior if README missing
- [PENDING] Works for all three categories (commands, hooks, tts)

## Implementation Phases

### Phase 1: Enhance Heading Preview Logic

**Complexity**: Low (2/10)
**Estimated Time**: 15-20 minutes

**Objective**: Modify create_command_previewer() to detect heading entries and display README content.

**Tasks**:

1. **Detect Heading Entry**
   - Location: picker.lua lines 444-454 in `define_preview` function
   - Check for `entry.value.is_heading` flag (already present)
   - Extract `entry.value.ordinal` field to determine directory

2. **Construct README Path**
   - Map ordinal value to directory:
     - "commands" → ".claude/commands/README.md"
     - "hooks" → ".claude/hooks/README.md"
     - "tts" → ".claude/tts/README.md"
   - Support both project-local and global paths:
     - Check `vim.fn.getcwd() .. "/.claude/" .. ordinal .. "/README.md"` first
     - Fall back to `vim.fn.expand("~/.config/.claude/" .. ordinal .. "/README.md")`
   - Use `vim.fn.filereadable()` to verify file exists

3. **Read README Content**
   - Use `io.open()` with error handling (pcall)
   - Read lines with `file:lines()` iterator
   - Store lines in table for preview display
   - Close file handle properly

4. **Display README with Highlighting**
   - Use `vim.api.nvim_buf_set_lines()` to set preview buffer content
   - Set markdown filetype with `vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")`
   - Clear previous content before setting new lines

5. **Add Fallback Behavior**
   - If README not found or read fails, display current generic text
   - Log error to notifications if file should exist but can't be read
   - Graceful degradation maintains picker functionality

**Files Modified**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`

**Example Implementation**:
```lua
-- Show info for heading entries
if entry.value.is_heading then
  local ordinal = entry.value.ordinal or "Unknown"
  local readme_path = nil

  -- Try local project first, then global
  local local_path = vim.fn.getcwd() .. "/.claude/" .. ordinal .. "/README.md"
  local global_path = vim.fn.expand("~/.config/.claude/" .. ordinal .. "/README.md")

  if vim.fn.filereadable(local_path) == 1 then
    readme_path = local_path
  elseif vim.fn.filereadable(global_path) == 1 then
    readme_path = global_path
  end

  if readme_path then
    -- Read README content
    local success, file = pcall(io.open, readme_path, "r")
    if success and file then
      local lines = {}
      for line in file:lines() do
        table.insert(lines, line)
      end
      file:close()

      -- Display README content with markdown highlighting
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
      return
    end
  end

  -- Fallback to current generic text
  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
    "Category: " .. ordinal,
    "",
    entry.value.display or "",
    "",
    "This is a category heading to organize artifacts in the picker.",
    "Navigate past this entry to view items in this category."
  })
  return
end
```

**Test Plan**:
- Navigate to [Commands] heading → should show commands/README.md
- Navigate to [Hook Events] heading → should show hooks/README.md
- Navigate to [TTS Files] heading → should show tts/README.md
- Verify markdown syntax highlighting active
- Test both local and global README paths

### Phase 2: Add Preview Line Limit

**Complexity**: Low (1/10)
**Estimated Time**: 5-10 minutes

**Objective**: Limit README preview to prevent buffer overflow and improve performance.

**Tasks**:

1. **Implement Line Limiting**
   - Modify Phase 1 code to limit lines read from README
   - Set constant: `local MAX_PREVIEW_LINES = 150`
   - Only read first 150 lines from file
   - Break loop after reaching limit

2. **Add Truncation Indicator**
   - If README has more lines than limit, add indicator
   - Check total line count with `vim.fn.readfile(readme_path)`
   - Append truncation message if needed:
     ```lua
     if total_lines > MAX_PREVIEW_LINES then
       table.insert(lines, "")
       table.insert(lines, "...")
       table.insert(lines, string.format("[Preview truncated - showing first %d of %d lines]",
         MAX_PREVIEW_LINES, total_lines))
     end
     ```

3. **Optimize Line Reading**
   - Use counter to track lines read
   - Break early to avoid reading entire large file
   - Example:
     ```lua
     local line_count = 0
     for line in file:lines() do
       table.insert(lines, line)
       line_count = line_count + 1
       if line_count >= MAX_PREVIEW_LINES then
         break
       end
     end
     ```

**Files Modified**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`

**Test Plan**:
- Verify preview stops at 150 lines
- Check truncation indicator appears for long READMEs
- Confirm performance is good with large README files
- Test with README shorter than 150 lines (no indicator)

### Phase 3: Testing and Validation

**Complexity**: Low (1/10)
**Estimated Time**: 10-15 minutes

**Objective**: Comprehensive testing of README preview functionality across all scenarios.

**Tasks**:

1. **Test All Category Headings**
   - Open picker with `:lua require('neotex.plugins.ai.claude.commands.picker').show_commands_picker()`
   - Navigate to [Commands] heading:
     - Verify commands/README.md content displays
     - Check markdown syntax highlighting (headers, code blocks, lists)
     - Confirm scrolling works in preview pane
   - Navigate to [Hook Events] heading:
     - Verify hooks/README.md content displays
     - Check formatting and highlighting
   - Navigate to [TTS Files] heading:
     - Verify tts/README.md content displays
     - Check content accuracy

2. **Test Path Resolution**
   - Test in project with local .claude/commands/README.md → should use local
   - Test in project without local README → should use global ~/.config/.claude/
   - Test in .config directory → should use local (same as global)
   - Verify correct path shown in preview

3. **Test Fallback Behavior**
   - Temporarily rename a README to test fallback:
     - Move commands/README.md
     - Navigate to [Commands] heading
     - Verify generic text displays (original behavior)
     - Restore README
   - Test with unreadable file permissions
   - Verify no errors or crashes

4. **Test Line Limiting**
   - Identify which README is longest (likely commands/README.md)
   - Verify preview shows exactly 150 lines (count in preview)
   - Check truncation indicator appears
   - Verify indicator shows correct total line count
   - Test README with <150 lines → no indicator

5. **Test Performance**
   - Open picker and navigate between headings rapidly
   - Verify no lag or delay when switching previews
   - Check no memory leaks or buffer issues
   - Monitor Neovim performance with large READMEs

6. **Test Markdown Rendering**
   - Verify syntax highlighting for:
     - Headers (# ## ###)
     - Code blocks (```)
     - Lists (-, *, numbered)
     - Bold and italic text
     - Links
   - Check box-drawing characters render correctly
   - Verify no encoding issues

**Files Modified**: None (testing only)

**Success Validation**:
- All three category headings show correct README content
- Markdown highlighting works properly
- Line limiting prevents overflow
- Fallback behavior works when README missing
- No performance degradation
- No errors or warnings in Neovim messages

## Dependencies

### External Dependencies
- Telescope.nvim (already installed)
- Neovim >= 0.9.0 (for buf_set_option API)
- Markdown filetype plugin (for syntax highlighting)

### Internal Dependencies
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` (existing)
- `.claude/commands/README.md` (exists globally)
- `.claude/hooks/README.md` (exists globally)
- `.claude/tts/README.md` (exists globally)

### Standards
- Follows Neovim Lua coding standards (nvim/CLAUDE.md)
- Uses pcall for error handling
- Maintains existing picker functionality
- 2-space indentation, ~100 char line length

## Risk Assessment

**Risk Level**: Low

**Potential Issues**:
1. Large README files may cause preview lag
   - **Mitigation**: 150-line limit prevents performance issues

2. Missing README files could break preview
   - **Mitigation**: Fallback to current generic text

3. Markdown syntax may not render properly
   - **Mitigation**: Use standard vim markdown filetype

4. Path resolution may fail in edge cases
   - **Mitigation**: Test both local and global paths, verify with filereadable()

## Implementation Notes

### Code Location
- File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
- Function: `create_command_previewer()`
- Lines: 444-454 (current heading preview logic)

### Lua Best Practices
- Use `pcall` for file operations
- Close file handles properly
- Validate paths with `vim.fn.filereadable()`
- Set buffer options with `vim.api.nvim_buf_set_option()`
- Use local variables for constants (MAX_PREVIEW_LINES)

### Testing Approach
- Manual testing via picker interaction
- Test all category headings
- Test fallback scenarios
- Verify performance with large files
- Check markdown rendering quality

## Completion Criteria

This plan is complete when:
- [PENDING] All category headings preview README.md content
- [PENDING] Markdown syntax highlighting works correctly
- [PENDING] Preview limited to 150 lines with truncation indicator
- [PENDING] Fallback behavior handles missing READMEs gracefully
- [PENDING] No performance degradation or errors
- [PENDING] All test scenarios pass successfully

## Related Documentation

- Picker implementation: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
- Commands README: `/home/benjamin/.config/.claude/commands/README.md`
- Hooks README: `/home/benjamin/.config/.claude/hooks/README.md`
- TTS README: `/home/benjamin/.config/.claude/tts/README.md`
- Neovim standards: `/home/benjamin/.config/nvim/CLAUDE.md`

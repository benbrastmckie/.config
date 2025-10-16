# Preserve CLAUDE.md Content in Worktrees Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases completed successfully on 2025-09-30. See [implementation summary](../summaries/019_preserve_claudemd_in_worktrees_summary.md) for details.

## Metadata
- **Date**: 2025-09-30
- **Plan Number**: 019
- **Feature**: Preserve main CLAUDE.md content when creating worktrees with `<leader>aw`
- **Scope**: Modify worktree creation to copy and merge CLAUDE.md from main worktree
- **Estimated Phases**: 4
- **Complexity**: Medium
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**:
  - `specs/reports/029_worktree_claude_md_preservation.md`

## Overview

Currently, when creating a new worktree with `<leader>aw`, the system generates a fresh CLAUDE.md file using a task-focused template. This overwrites the main worktree's comprehensive CLAUDE.md, which contains project standards, testing protocols, code style guidelines, and navigation links.

This implementation will modify the `_create_context_file()` function to:
1. Detect the main worktree's CLAUDE.md location
2. Read its project configuration content
3. Create a hierarchical CLAUDE.md with task metadata at the top and project configuration below
4. Maintain backward compatibility for repositories without a main CLAUDE.md

## Success Criteria

- [x] New worktrees preserve all project configuration from main CLAUDE.md
- [x] Task-specific metadata appears clearly separated at the top
- [x] System falls back gracefully when main CLAUDE.md doesn't exist
- [x] User receives notification indicating CLAUDE.md was preserved
- [x] Configuration option allows disabling preservation if desired
- [x] All edge cases (missing file, permission errors, git root detection failure) handled
- [x] Existing worktree functionality remains unchanged

## Technical Design

### Architecture

```
create_worktree_with_claude()
  |
  +---> _create_context_file()
          |
          +---> M._get_main_claudemd_path()  [NEW]
          |       |
          |       +---> git rev-parse --show-toplevel
          |       +---> Check CLAUDE.md readability
          |       +---> Return path or nil
          |
          +---> Format task metadata section
          +---> Read main CLAUDE.md (if exists)
          +---> Merge: task metadata + separator + main content
          +---> Write merged content to worktree
```

### Component Changes

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua`

1. **New helper function** `M._get_main_claudemd_path()` (after line 156)
   - Uses `git rev-parse --show-toplevel` to find repository root
   - Checks if CLAUDE.md exists and is readable
   - Returns absolute path or nil

2. **Modified function** `M._create_context_file()` (lines 157-177)
   - Calls `_get_main_claudemd_path()` to locate main CLAUDE.md
   - Reads main CLAUDE.md content if available
   - Merges task metadata with project configuration
   - Adds clear separator and heading for inherited content
   - Falls back to template-only if main CLAUDE.md unavailable

3. **Updated template** `M.config.context_template` (lines 36-61)
   - Change title from "Task:" to "Worktree Task:"
   - Change "Metadata" to "Task Metadata"
   - Change "Notes" to "Task Notes"
   - Clarify these are worktree-specific sections

4. **New config options** `M.config` (lines 15-62)
   - `preserve_main_claudemd` (boolean, default: true)
   - `claudemd_separator` (string, default: "---")
   - `claudemd_inherited_heading` (string, default shown below)

### Data Flow

1. User triggers `<leader>aw` → `create_worktree_with_claude()`
2. Git worktree created with new branch
3. `_create_context_file()` called
4. Helper function locates main worktree CLAUDE.md
5. Task metadata formatted from template
6. Main CLAUDE.md content read (if available)
7. Content merged: task section + separator + project section
8. Combined content written to worktree CLAUDE.md
9. Notification informs user of preservation status
10. Terminal tab opens with new CLAUDE.md

### Edge Case Handling

| Scenario | Behavior |
|----------|----------|
| Main CLAUDE.md exists | Copy and merge content |
| Main CLAUDE.md missing | Use template-only (current behavior) |
| Main CLAUDE.md empty | Use template-only |
| Main CLAUDE.md unreadable | Use template-only, notify user |
| Git root detection fails | Use template-only |
| Config disabled preservation | Use template-only |

## Implementation Phases

### Phase 1: Add Helper Function for CLAUDE.md Detection [COMPLETED]
**Objective**: Create utility function to locate main worktree's CLAUDE.md
**Complexity**: Low
**File**: `worktree.lua`

Tasks:
- [x] Add `M._get_main_claudemd_path()` function after line 156
- [x] Implement `git rev-parse --show-toplevel` to find repo root
- [x] Check if `{git_root}/CLAUDE.md` exists and is readable
- [x] Return absolute path string or nil
- [x] Handle git command errors gracefully (check `vim.v.shell_error`)
- [x] Add inline documentation explaining function purpose

Implementation:
```lua
-- Locate main worktree's CLAUDE.md file
-- @return string|nil Absolute path to main CLAUDE.md, or nil if not found
function M._get_main_claudemd_path()
  -- Get git repository root (main worktree)
  local git_root_list = vim.fn.systemlist("git rev-parse --show-toplevel")

  if vim.v.shell_error ~= 0 or #git_root_list == 0 then
    return nil
  end

  local git_root = git_root_list[1]
  local main_claude = git_root .. "/CLAUDE.md"

  -- Check if file exists and is readable
  if vim.fn.filereadable(main_claude) == 1 then
    return main_claude
  end

  return nil
end
```

Testing:
```bash
# Manual testing in Neovim
:lua require('neotex.plugins.ai.claude.core.worktree')._get_main_claudemd_path()

# Expected outcomes:
# - In main worktree: returns "/home/benjamin/.config/CLAUDE.md"
# - In nested directory: returns "/home/benjamin/.config/CLAUDE.md"
# - Without CLAUDE.md: returns nil
```

**Validation**:
- [x] Function returns correct path in main worktree
- [x] Function returns nil when CLAUDE.md doesn't exist
- [x] Function handles git errors without crashing
- [x] Function works in nested directories

---

### Phase 2: Update Context Template [COMPLETED]
**Objective**: Modify template to clarify task-specific vs project-wide sections
**Complexity**: Low
**File**: `worktree.lua:36-61`

Tasks:
- [x] Change heading from `# Task: %s` to `# Worktree Task: %s`
- [x] Change `## Metadata` to `## Task Metadata`
- [x] Change `## Notes` to `## Task Notes`
- [x] Update placeholder text to emphasize worktree-specific nature
- [x] Maintain all existing format string placeholders (`%s`)
- [x] Verify string interpolation still works correctly

Implementation:
```lua
context_template = [[
# Worktree Task: %s

## Task Metadata
- **Type**: %s
- **Branch**: %s
- **Created**: %s
- **Worktree**: %s
- **Session ID**: %s

## Objective
[Describe the main goal for this worktree]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on %s in the %s worktree. The goal is to..."

## Task Notes
[Add worktree-specific context, links, or decisions]
]],
```

Testing:
```lua
-- Test string formatting
local test_feature = "test-feature"
local test_type = "feature"
local result = string.format(M.config.context_template,
  test_feature, test_type, "branch", "date", "path", "id", test_feature, "branch")
print(result)
```

**Validation**:
- [x] Template renders correctly with test data
- [x] All placeholders filled properly
- [x] Markdown formatting preserved
- [x] Headings clearly indicate task-specific sections

---

### Phase 3: Add Configuration Options [COMPLETED]
**Objective**: Add new config options for CLAUDE.md preservation behavior
**Complexity**: Low
**File**: `worktree.lua:15-62`

Tasks:
- [x] Add `preserve_main_claudemd = true` to M.config
- [x] Add `claudemd_separator = "---"` to M.config
- [x] Add `claudemd_inherited_heading` with default value
- [x] Add inline comments explaining each option
- [x] Ensure options integrate with existing config structure
- [x] Verify config merging in `setup()` function works

Implementation:
```lua
M.config = {
  -- ... existing config ...

  -- CLAUDE.md preservation settings
  preserve_main_claudemd = true,  -- Copy main CLAUDE.md to new worktrees
  claudemd_separator = "---",     -- Markdown separator between sections
  claudemd_inherited_heading = "# Project Configuration (Inherited from Main Worktree)",
}
```

Testing:
```lua
-- Test config merging
local worktree = require('neotex.plugins.ai.claude.core.worktree')
worktree.setup({ preserve_main_claudemd = false })
print(worktree.config.preserve_main_claudemd)  -- Should print: false
```

**Validation**:
- [x] Config options accessible via M.config
- [x] Default values set correctly
- [x] Options can be overridden in setup()
- [x] No conflicts with existing config structure

---

### Phase 4: Modify _create_context_file() Function [COMPLETED]
**Objective**: Implement CLAUDE.md merging logic with preservation
**Complexity**: Medium
**File**: `worktree.lua:157-177`

Tasks:
- [x] Check `preserve_main_claudemd` config option
- [x] Call `_get_main_claudemd_path()` to locate main CLAUDE.md
- [x] Read main CLAUDE.md content if available
- [x] Format task metadata section using template
- [x] Merge sections: task + separator + inherited heading + main content
- [x] Handle edge cases (nil path, empty file, read errors)
- [x] Add user notification indicating preservation status
- [x] Write merged content to worktree CLAUDE.md
- [x] Maintain backward compatibility (fallback to template-only)

Implementation:
```lua
function M._create_context_file(worktree_path, feature, type, branch, session_id)
  if not M.config.create_context_file then
    return nil
  end

  local context_file = worktree_path .. "/CLAUDE.md"

  -- Build task metadata section
  local task_section = string.format(
    M.config.context_template,
    feature,
    type,
    branch,
    os.date("%Y-%m-%d %H:%M"),
    worktree_path,
    session_id or "N/A",
    feature,
    branch
  )

  local content
  local preserved = false

  -- Try to preserve main CLAUDE.md if enabled
  if M.config.preserve_main_claudemd then
    local main_claude_path = M._get_main_claudemd_path()

    if main_claude_path then
      -- Read main CLAUDE.md content
      local ok, main_lines = pcall(vim.fn.readfile, main_claude_path)

      if ok and #main_lines > 0 then
        local main_content = table.concat(main_lines, "\n")

        -- Combine: task metadata + separator + inherited content
        content = task_section .. "\n\n" ..
          M.config.claudemd_separator .. "\n\n" ..
          M.config.claudemd_inherited_heading .. "\n\n" ..
          main_content

        preserved = true
      end
    end
  end

  -- Fallback: use template-only
  if not preserved then
    content = task_section
  end

  -- Write to worktree
  vim.fn.writefile(vim.split(content, "\n"), context_file)

  -- Notify user
  if preserved then
    vim.notify(
      "Created worktree CLAUDE.md (preserved main configuration)",
      vim.log.levels.INFO
    )
  end

  return context_file
end
```

Testing:
```bash
# Test with main CLAUDE.md present
# 1. Create test worktree
<leader>aw
# Enter feature name: test-preservation
# Select type: feature

# 2. Verify worktree CLAUDE.md
cat ../test-preservation/CLAUDE.md | head -50

# Expected:
# - Task metadata at top
# - Separator line (---)
# - Inherited heading
# - Main CLAUDE.md content

# Test without main CLAUDE.md
# 1. Temporarily move main CLAUDE.md
mv CLAUDE.md CLAUDE.md.backup

# 2. Create worktree
<leader>aw
# Enter feature name: test-fallback
# Select type: feature

# 3. Verify fallback behavior
cat ../test-fallback/CLAUDE.md

# Expected:
# - Only task metadata (no project config)
# - No separator or inherited heading

# 4. Restore main CLAUDE.md
mv CLAUDE.md.backup CLAUDE.md

# Test with preservation disabled
# 1. Open Neovim init.lua
# 2. Add to worktree setup: preserve_main_claudemd = false
# 3. Restart Neovim
# 4. Create worktree and verify template-only behavior
```

**Validation**:
- [x] Main CLAUDE.md content preserved when available
- [x] Clear separation between task and project sections
- [x] Graceful fallback when main CLAUDE.md missing
- [x] User notification displays correctly
- [x] Config option disables preservation when false
- [x] Read errors handled without crashes
- [x] Content formatting correct (no extra newlines, proper markdown)

---

## Testing Strategy

### Unit Testing
Each phase includes inline testing validation to ensure:
- Individual functions work correctly
- Edge cases handled properly
- Configuration options functional
- Error conditions don't crash system

### Integration Testing
After all phases complete:
1. Test complete workflow from `<leader>aw` to CLAUDE.md creation
2. Verify terminal tab opens with correct CLAUDE.md
3. Test session switching still works
4. Ensure no regression in existing worktree functionality

### Manual Testing Scenarios
1. **Standard case**: Main CLAUDE.md exists, preservation enabled
2. **Fallback case**: No main CLAUDE.md, should use template only
3. **Disabled case**: Preservation disabled in config
4. **Error case**: Main CLAUDE.md unreadable (permission error)
5. **Empty case**: Main CLAUDE.md exists but is empty
6. **Git error case**: Not in git repository or git command fails

### Test Commands
```bash
# Lint code
<leader>l

# Format code
<leader>mp

# Reload configuration
:source ~/.config/nvim/init.lua

# Test worktree creation
<leader>aw

# Inspect generated CLAUDE.md
:e ../worktree-name/CLAUDE.md

# Check session state
:lua print(vim.inspect(require('neotex.plugins.ai.claude.core.worktree').sessions))
```

## Documentation Requirements

### Code Documentation
- [x] Inline comments in `_get_main_claudemd_path()` explaining logic
- [x] Function docstring with return type annotation
- [x] Inline comments in `_create_context_file()` explaining merge logic
- [x] Config option comments explaining each setting

### User Documentation
- [ ] Update `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`
  - Add section on CLAUDE.md preservation
  - Document configuration options
  - Explain hierarchical structure
- [ ] Update `/home/benjamin/.config/nvim/docs/MAPPINGS.md:116`
  - Note that `<leader>aw` preserves CLAUDE.md
  - Link to detailed documentation

### Commit Messages
Follow project standard format:
```
feat: preserve main CLAUDE.md in worktree creation

- Add _get_main_claudemd_path() helper function
- Modify _create_context_file() to merge content
- Update context template for clarity
- Add config options for preservation behavior

Implements hierarchical CLAUDE.md structure:
- Task metadata at top (worktree-specific)
- Project configuration below (inherited from main)

Falls back gracefully when main CLAUDE.md unavailable.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Dependencies

### External Dependencies
None - uses only Neovim built-in functions and git commands

### Internal Dependencies
- `vim.fn.systemlist()` - Execute git commands
- `vim.fn.readfile()` - Read main CLAUDE.md
- `vim.fn.writefile()` - Write merged CLAUDE.md
- `vim.fn.filereadable()` - Check file existence
- `vim.v.shell_error` - Check command success
- `vim.notify()` - User notifications

### Git Requirements
- Repository must be initialized (already required for worktrees)
- `git rev-parse --show-toplevel` must work (standard git command)

## Risk Assessment

### Low Risk
- Helper function is isolated and simple
- Template changes are cosmetic
- Config options have sensible defaults
- Fallback behavior maintains current functionality

### Medium Risk
- File read operations could fail (permissions, corruption)
- Git root detection could fail in edge cases
- Content merging could produce formatting issues

### Mitigation Strategies
1. **Wrap file operations in pcall**: Catch read errors gracefully
2. **Check shell error codes**: Verify git commands succeed
3. **Test edge cases thoroughly**: Empty files, missing files, permission errors
4. **Maintain backward compatibility**: Template-only fallback always available
5. **User notification**: Inform user of preservation status

## Notes

### Design Decisions
- **Concatenation over smart merge**: Simpler implementation, clearer separation
- **Separator heading**: Makes inherited content explicit and discoverable
- **Config-driven**: Allows users to disable if they prefer template-only
- **Graceful degradation**: System works with or without main CLAUDE.md

### Future Enhancements (Out of Scope)
1. Command to re-sync CLAUDE.md from main worktree
2. Smart merge algorithm for cleaner integration
3. Notification system for main CLAUDE.md changes
4. Symlink approach instead of content copy
5. Support for worktree-specific CLAUDE.md sections

### Performance Considerations
- File read adds minimal overhead (one-time operation during worktree creation)
- Git command execution negligible (already using git extensively)
- No impact on session switching or existing worktree operations

### Breaking Changes
None - this is purely additive functionality with backward compatibility

## References

### Research Report
- `/home/benjamin/.config/nvim/specs/reports/029_worktree_claude_md_preservation.md`

### Source Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua`
- `/home/benjamin/.config/CLAUDE.md`

### Related Functions
- `M.create_worktree_with_claude()` - Main entry point
- `M._create_context_file()` - File creation logic
- `M._spawn_terminal_tab()` - Terminal integration
- `M.switch_session()` - Session switching

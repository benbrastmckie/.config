# Worktree CLAUDE.md Preservation Research Report

## Metadata
- **Date**: 2025-09-30
- **Report Number**: 029
- **Scope**: Analysis of `<leader>aw` worktree creation and CLAUDE.md file handling
- **Primary Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/`
- **Key Files Analyzed**: `worktree.lua`

## Executive Summary

The current `<leader>aw` implementation creates a new CLAUDE.md file from a template when creating worktrees, which overwrites any existing CLAUDE.md content. Users want to preserve the main worktree's CLAUDE.md content (project configuration index) while adding task-specific metadata.

### Key Findings
1. CLAUDE.md creation happens in `_create_context_file()` at line 157-177
2. The function uses a hardcoded template focused on task metadata
3. No mechanism exists to copy or merge existing CLAUDE.md content
4. Main worktree has a comprehensive CLAUDE.md (project standards index)
5. New worktrees should inherit base content + add task-specific sections

## Background

### Current Behavior
When `<leader>aw` creates a new worktree:
1. User enters feature name and selects type (feature/bugfix/etc.)
2. Git worktree is created with new branch
3. New CLAUDE.md is written using `context_template`
4. Template only contains task-specific metadata
5. Project configuration from main CLAUDE.md is lost

### User Expectation
Users want new worktrees to:
1. Preserve all project standards from main CLAUDE.md
2. Add task-specific metadata at the top
3. Maintain consistent project documentation across worktrees
4. Avoid losing important project configuration

## Current State Analysis

### File Creation Flow

```
create_worktree_with_claude() (line 180)
  |
  +---> _create_context_file() (line 223)
          |
          +---> Uses M.config.context_template
          +---> Writes to worktree_path/CLAUDE.md (line 162)
          +---> Returns context_file path
```

### Current Template Structure
Located in `M.config.context_template` (lines 36-61):

```markdown
# Task: %s

## Metadata
- **Type**: %s
- **Branch**: %s
- **Created**: %s
- **Worktree**: %s
- **Session ID**: %s

## Objective
[Describe the main goal]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on %s in the %s worktree. The goal is to..."

## Notes
[Add any relevant context, links, or decisions]
```

### Main CLAUDE.md Structure
The main worktree has a comprehensive CLAUDE.md (85 lines) containing:
- Project Configuration Index
- Project Standards and Guidelines
- Core Documentation links
- Directory Protocols
- Testing Protocols
- Code Style Standards
- Development Workflow
- Git Workflow
- Project-Specific Commands
- Quick Reference
- Navigation links

## Technical Analysis

### Implementation Location
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua:157-177`

```lua
function M._create_context_file(worktree_path, feature, type, branch, session_id)
  if not M.config.create_context_file then
    return nil
  end

  local context_file = worktree_path .. "/CLAUDE.md"
  local content = string.format(
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

  vim.fn.writefile(vim.split(content, "\n"), context_file)
  return context_file
end
```

### Problem Points
1. **Line 162**: Hardcoded path `worktree_path .. "/CLAUDE.md"`
2. **Lines 163-173**: Only uses template content, no merging
3. **Line 175**: Direct write with no preservation check
4. No reference to main worktree CLAUDE.md location

## Recommended Solution

### Approach: Hierarchical CLAUDE.md Structure

Create a two-part CLAUDE.md in new worktrees:
1. **Task Metadata Section** (top) - Worktree-specific information
2. **Project Configuration** (bottom) - Copied from main CLAUDE.md

### Implementation Strategy

#### Step 1: Detect Main Worktree CLAUDE.md
```lua
local function get_main_claudemd_path()
  -- Get git root (main worktree)
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 then
    local main_claude = git_root .. "/CLAUDE.md"
    if vim.fn.filereadable(main_claude) == 1 then
      return main_claude
    end
  end
  return nil
end
```

#### Step 2: Modify _create_context_file()
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

  -- Try to read main CLAUDE.md
  local main_claude_path = get_main_claudemd_path()
  local content

  if main_claude_path then
    local main_content = table.concat(vim.fn.readfile(main_claude_path), "\n")

    -- Combine: task metadata + separator + main content
    content = task_section .. "\n\n" ..
      "---\n\n" ..
      "# Project Configuration (Inherited from Main Worktree)\n\n" ..
      main_content
  else
    -- Fallback: just use task template
    content = task_section
  end

  vim.fn.writefile(vim.split(content, "\n"), context_file)
  return context_file
end
```

#### Step 3: Update Template Configuration
Add separator between task info and project config:

```lua
M.config.context_template = [[
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
]]
```

### Alternative Approach: Smart Merge

Instead of simple concatenation, parse the main CLAUDE.md and intelligently merge:
1. Keep task metadata at top
2. Merge task-specific notes with project notes section
3. Preserve all project configuration sections
4. Add worktree indicator to headings

This is more complex but provides cleaner integration.

## Benefits of Recommended Solution

### Advantages
1. **Preservation**: All project standards preserved in every worktree
2. **Consistency**: Every worktree has same base configuration
3. **Discoverability**: New contributors see full project docs in any worktree
4. **Task Context**: Clear separation between task and project information
5. **Backward Compatible**: Falls back gracefully if main CLAUDE.md doesn't exist
6. **No User Action**: Automatic preservation without user intervention

### Trade-offs
1. **File Size**: CLAUDE.md files will be larger (85+ lines)
2. **Duplication**: Project config duplicated across worktrees
3. **Sync Issues**: Changes to main CLAUDE.md won't auto-propagate to existing worktrees

## Implementation Considerations

### Edge Cases
1. **No main CLAUDE.md**: Fallback to template-only (current behavior)
2. **Permission errors**: Handle read/write failures gracefully
3. **Git root detection fails**: Fallback to template-only
4. **Main CLAUDE.md is empty**: Use template-only

### User Experience
1. **Notification**: Inform user if main CLAUDE.md was copied
2. **Configuration**: Allow users to disable preservation via config
3. **Manual Override**: Provide function to re-sync from main CLAUDE.md

### Testing Requirements
1. Test with existing main CLAUDE.md
2. Test without main CLAUDE.md (new repos)
3. Test with unreadable main CLAUDE.md
4. Test git root detection in nested directories
5. Verify content formatting and structure

## Configuration Options

### Proposed Config Extension
```lua
M.config = {
  -- ... existing config ...

  preserve_main_claudemd = true,  -- Enable preservation (default: true)
  claudemd_separator = "---",     -- Separator between sections
  claudemd_inherited_heading = "# Project Configuration (Inherited from Main Worktree)",
}
```

## Related Files and Functions

### Key Functions
- `M.create_worktree_with_claude()` - Main entry point (line 180)
- `M._create_context_file()` - File creation logic (line 157)
- `M._generate_worktree_path()` - Path generation
- `M._generate_branch_name()` - Branch naming
- `M._spawn_terminal_tab()` - Terminal tab creation (line 256)

### Integration Points
- `worktree.lua:223` - Context file creation call
- `worktree.lua:334` - Terminal opens with CLAUDE.md
- `worktree.lua:440` - Session switching opens CLAUDE.md

## References

### Source Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua:157-177`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua:180-253`
- `/home/benjamin/.config/CLAUDE.md` (main project configuration)

### Related Documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`
- `/home/benjamin/.config/nvim/docs/MAPPINGS.md:116` (`<leader>aw` documentation)

### Configuration
- Template definition: `worktree.lua:36-61`
- Config structure: `worktree.lua:15-62`

## Next Steps

### Immediate Actions
1. Implement `get_main_claudemd_path()` helper function
2. Modify `_create_context_file()` to copy and merge content
3. Update template to clarify task vs project sections
4. Add configuration options for preservation behavior

### Future Enhancements
1. Command to re-sync CLAUDE.md from main worktree
2. Smart merge algorithm for cleaner integration
3. Notification system for CLAUDE.md changes in main worktree
4. Option to link instead of copy (symlink approach)
5. Support for worktree-specific CLAUDE.md sections

## Conclusion

The solution requires modifying the `_create_context_file()` function to:
1. Detect the main worktree's CLAUDE.md location
2. Read its contents
3. Combine task metadata with project configuration
4. Write the merged content to the new worktree

This approach balances preservation of project standards with task-specific context, while maintaining backward compatibility and graceful fallback behavior.

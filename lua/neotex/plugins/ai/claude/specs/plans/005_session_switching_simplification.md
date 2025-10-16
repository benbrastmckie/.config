# Session Switching Simplification Implementation Plan

## Metadata
- **Date**: 2025-09-29
- **Feature**: Simplify Claude session management and fix session switching
- **Scope**: Remove unnecessary complexity and implement direct terminal approach
- **Estimated Phases**: 3
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**: `/home/benjamin/.config/nvim/lua/neotex/ai-claude/specs/reports/006_session_switching_and_complexity_analysis.md`

## Overview

This plan addresses the critical session switching failure and removes ~1450 lines of unnecessary complexity from the Claude session management system. The research report identified that the `claude-code.nvim` plugin prevents session switching when Claude is already open, and that 90% of the codebase provides no value.

We'll implement a minimal solution (~50 lines) that bypasses the plugin limitations by using direct terminal commands, which always work correctly.

## Success Criteria

- [ ] Session switching works when Claude is already open
- [ ] Most recent session opens correctly from picker
- [ ] Code reduced from ~1500 lines to ~50 lines
- [ ] Direct Claude CLI errors shown to users (no obscuring)
- [ ] All session operations complete in <100ms
- [ ] No unnecessary validations or state management

## Technical Design

### Core Principle: Direct Terminal Control

Instead of fighting with plugin limitations, we'll use Neovim's native terminal functionality:

```lua
-- Kill existing, open new - simple and bulletproof
vim.cmd("silent! %bdelete! term://*//*claude*")
vim.cmd("terminal claude --resume " .. session_id)
```

### Minimal Architecture

```
┌──────────────────────────────────────────────┐
│           Simplified Session System           │
├──────────────────────────────────────────────┤
│  simple-sessions.lua (~50 lines total)        │
│  - get_sessions()     - List session files    │
│  - open_session()     - Kill old, start new   │
│  - show_picker()      - Telescope interface   │
└──────────────────────────────────────────────┘
                    ↓
        Direct terminal commands (no plugin)
```

### Files to Delete (1450+ lines)
- `core/session-manager.lua` - 462 lines of pointless validation
- `utils/claude-code.lua` - 115 lines of broken plugin wrapper
- Most of `core/session.lua` - Keep only 10% of 460 lines
- 80% of `native-sessions.lua` - Keep only session listing

## Implementation Phases

### Phase 1: Create Minimal Session Management
**Objective**: Implement complete session management in ~50 lines
**Complexity**: Low

Tasks:
- [ ] Create `lua/neotex/ai-claude/simple-sessions.lua` with core functions
- [ ] Implement `get_sessions()` to list session files (10 lines)
- [ ] Implement `open_session()` with buffer cleanup (10 lines)
- [ ] Create `show_picker()` for Telescope integration (15 lines)
- [ ] Update keymaps to use new simple system

Testing:
```bash
# Test session opening
:lua require('neotex.ai-claude.simple-sessions').open_session('test-id')

# Test picker
:lua require('neotex.ai-claude.simple-sessions').show_picker()
```

Expected outcomes:
- Sessions open correctly even when Claude is already running
- Most recent session works from picker
- Direct Claude CLI errors shown to user

### Phase 2: Remove Unnecessary Complexity
**Objective**: Delete all unnecessary code and clean up remaining files
**Complexity**: Low

Tasks:
- [ ] Delete `core/session-manager.lua` entirely (462 lines)
- [ ] Delete `utils/claude-code.lua` entirely (115 lines)
- [ ] Simplify `core/session.lua` - keep only smart toggle (reduce to ~50 lines)
- [ ] Simplify `native-sessions.lua` - keep only get_project_folder (reduce to ~100 lines)
- [ ] Update `init.lua` to remove references to deleted modules
- [ ] Remove all state management and validation code

Testing:
```bash
# Ensure nothing breaks after deletion
:checkhealth
:lua print(vim.inspect(require('neotex.ai-claude')))

# Test all session operations still work
<leader>as  # Should show picker
<C-c>       # Should toggle Claude
```

Expected outcomes:
- ~1450 lines of code removed
- All functionality still works
- No more validation errors or complex state management

### Phase 3: Plugin Integration Cleanup
**Objective**: Update plugin configuration to work with simplified system
**Complexity**: Low

Tasks:
- [ ] Update `plugins/ai/claudecode.lua` to remove complex initialization
- [ ] Simplify which-key mappings in `plugins/editor/which-key.lua`
- [ ] Remove references to session-manager in all files
- [ ] Update any autocmds that reference deleted modules
- [ ] Clean up any remaining complexity in session handling

Testing:
```bash
# Full integration test
:Lazy reload  # Reload all plugins
<leader>as    # Open picker, select various sessions
<C-c>         # Toggle with existing session

# Performance test - should be instant
:lua local start = vim.loop.hrtime(); require('neotex.ai-claude.simple-sessions').open_session('test'); print((vim.loop.hrtime() - start) / 1000000 .. 'ms')
```

Expected outcomes:
- Clean plugin integration
- All operations complete in <100ms
- No errors or warnings in :checkhealth

## Testing Strategy

### Functional Tests
1. **Session Switching**: Open Claude, then select different session - must switch
2. **Most Recent Session**: First item in picker must open correctly
3. **Empty Session List**: Handle gracefully with clear message
4. **Invalid Session ID**: Claude CLI shows its own error message

### Performance Tests
- All operations complete in <100ms (no validations = fast)
- No noticeable lag when switching sessions
- Instant picker display

### Edge Cases
- Multiple Neovim instances (each manages its own Claude)
- Corrupted session files (Claude CLI handles gracefully)
- Missing Claude CLI (clear error message)

## Documentation Requirements

### Code Documentation
- [ ] Document the 3 core functions in simple-sessions.lua
- [ ] Add "SIMPLIFIED" header to modified files
- [ ] Update README to explain simplification

### Migration Notes
- [ ] Document which files were deleted and why
- [ ] Explain the direct terminal approach
- [ ] Note that all validation was unnecessary

## Dependencies

### Required
- Neovim 0.7+ (for terminal functionality)
- Claude CLI (must be in PATH)
- Telescope (for picker UI)

### Removed Dependencies
- claude-code.nvim (no longer needed for core functionality)
- plenary.nvim Path module (use vim.fn instead)
- Complex state management

## Risk Assessment

### Low Risk
- **Breaking existing workflows**: Direct terminal approach is more reliable
- **Data loss**: No data is modified, only how we open it
- **Performance issues**: Removing code makes it faster

### Mitigations
- Keep backup of deleted files in git history
- Test each phase thoroughly before proceeding
- Can revert individual phases if needed

## Notes

### Design Philosophy
> "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away." - Antoine de Saint-Exupéry

The current system is a perfect example of over-engineering. By removing 90% of the code, we get better functionality, clearer errors, and easier maintenance.

### Key Insights from Research
1. The Claude CLI handles all edge cases gracefully - we don't need validation
2. The plugin wrapper was the problem, not the solution
3. Direct terminal commands always work
4. Less code = fewer bugs

### Implementation Priority
Focus on getting Phase 1 working first. Once we prove the simple approach works, removing the complex code in Phase 2 becomes risk-free.

This plan will transform a broken 1500-line system into a working 50-line solution.
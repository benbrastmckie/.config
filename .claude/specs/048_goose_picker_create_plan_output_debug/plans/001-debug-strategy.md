# Debug Strategy: Goose Picker Quote Nesting Fix

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix nested single-quote collision in TermExec command causing recipe execution failure
- **Status**: [NOT STARTED]
- **Estimated Hours**: 1-1 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001-goose-picker-quote-nesting-analysis.md)

## Overview

The goose picker recipe execution fails with "a value is required for '--recipe'" due to nested single-quote collision in execution.lua line 31. The `shell_escape()` function wraps recipe paths in single quotes, but TermExec's `cmd='...'` parameter also uses single quotes, causing Vim's parser to terminate the string prematurely.

This is a minimal one-line fix changing line 31 from single to double quotes.

## Root Cause Summary

**Problem**: Line 31 in execution.lua:
```lua
vim.cmd(string.format("TermExec cmd='%s'", cmd))
```

**Issue**: When `cmd` contains single-quoted paths from `shell_escape()`, Vim's parser sees:
```vim
TermExec cmd='goose run --recipe '/path/to/recipe.yaml' --interactive'
             ^                      ^
             |                      |
        String starts          String ENDS (prematurely!)
```

**Result**: Recipe path is lost, goose CLI receives empty `--recipe` flag.

## Success Criteria
- [ ] Recipe execution via `<leader>aR` picker succeeds with correct path
- [ ] TermExec receives complete command string without quote collision
- [ ] Test recipe (create-plan.yaml) executes successfully

## Technical Design

### Fix Approach
Change TermExec parameter delimiter from single quotes to double quotes, allowing single-quoted paths inside.

**Before**:
```lua
vim.cmd(string.format("TermExec cmd='%s'", cmd))
```

**After**:
```lua
vim.cmd(string.format("TermExec cmd=\"%s\"", cmd))
```

**Result**: Vim parser correctly handles:
```vim
TermExec cmd="goose run --recipe '/path/to/recipe.yaml' --interactive"
```

### Why This Works
- Double quotes delimit the `cmd` parameter for Vim's parser
- Single quotes inside double-quoted string are treated as literal characters
- No escaping collision between shell_escape and TermExec syntax
- Minimal change, low risk

## Implementation Phases

### Phase 1: Apply One-Line Fix [NOT STARTED]
dependencies: []

**Objective**: Change TermExec parameter delimiter to double quotes in execution.lua

**Complexity**: Low

**Tasks**:
- [ ] Edit `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` line 31
- [ ] Change `vim.cmd(string.format("TermExec cmd='%s'", cmd))` to `vim.cmd(string.format("TermExec cmd=\"%s\"", cmd))`
- [ ] Save file

**Testing**:
```bash
# Verify syntax correctness
nvim --headless -c "luafile /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua" -c "quit"
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1
```

**Expected Duration**: 0.1 hours

### Phase 2: Manual Verification [NOT STARTED]
dependencies: [1]

**Objective**: Verify recipe execution via picker works correctly

**Complexity**: Low

**Tasks**:
- [ ] Open Neovim
- [ ] Invoke picker with `<leader>aR`
- [ ] Select create-plan recipe
- [ ] Provide feature_description when prompted
- [ ] Verify goose run executes with correct recipe path (no "value is required" error)
- [ ] Observe ToggleTerm output shows recipe executing

**Automation Metadata**:
- automation_type: manual
- validation_method: visual
- skip_allowed: false
- artifact_outputs: []

**Note**: Manual verification required because:
1. Interactive picker requires user input (Telescope selection)
2. Recipe parameter prompting uses `vim.fn.input()` (blocking UI)
3. ToggleTerm execution displays real-time output (visual verification)
4. No programmatic API to simulate picker workflow

**Validation**:
```
User observes:
1. Picker opens successfully
2. Recipe selection triggers parameter prompt
3. TermExec executes goose CLI command
4. Recipe runs without "value is required" error
5. Command string visible in ToggleTerm shows quoted path
```

**Expected Duration**: 0.15 hours

## Testing Strategy

### Syntax Validation
Lua syntax check ensures no typos or formatting errors after edit.

### Manual Execution Test
User-driven test confirms:
- Picker workflow intact
- Parameter prompting functional
- TermExec integration working
- Quote escaping correct

### Edge Case Considerations
The fix handles:
- Paths with spaces (shell_escape single quotes work inside TermExec double quotes)
- Paths with single quotes (shell_escape `'\''` pattern preserved)
- Empty parameter sets (command construction unchanged)

## Documentation Requirements

No documentation changes required:
- Internal implementation fix (no API changes)
- User-facing behavior unchanged (picker still works the same way)
- No new features or interfaces

## Dependencies

### External Dependencies
- ToggleTerm plugin (already installed, no changes)
- goose CLI (already installed, no changes)

### File Dependencies
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` (modification target)
- `/home/benjamin/.config/.goose/recipes/create-plan.yaml` (test recipe)

## Risk Assessment

**Risk Level**: Very Low

**Mitigations**:
- Single line change (minimal blast radius)
- Quote escaping is well-understood Vim/Lua pattern
- shell_escape function unchanged (proven implementation)
- Easy rollback (revert single line)

## Notes

### Alternative Solution (Not Chosen)
Could refactor `build_command()` to use double quotes throughout and remove `shell_escape()`, but this:
- Increases test surface area (multiple functions modified)
- Requires comprehensive edge case testing (spaces, quotes, special chars)
- Adds risk without proportional benefit

### Minimal Fix Rationale
One-line change is preferred because:
- Proven pattern (double quotes allow single quotes inside)
- No cascading changes required
- Easy to verify and rollback
- Fast resolution for critical blocker

# Modularize Large Files

## Metadata
- **Phase**: Phase 3 - Long-Term Refactoring
- **Priority**: High Impact, High Effort
- **Estimated Time**: 4-6 hours (across multiple sessions)
- **Difficulty**: Hard
- **Status**: Not Started
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#41-largecomplex-files-requiring-refactoring)

## Problem Statement

Four files exceed 1,600+ lines with mixed concerns, making them difficult to maintain, test, and understand:

1. **worktree.lua** (2,343 lines) - Git worktrees + Claude sessions + terminal management
2. **picker.lua** (2,003 lines) - Telescope picker + display + formatting + actions
3. **email_list.lua** (1,683 lines) - Email UI + filtering + sorting + rendering
4. **main.lua** (1,620 lines) - Himalaya UI orchestration + commands + state

**Impact**:
- Difficult to locate specific functionality
- High cognitive load for modifications
- Testing complexity (hard to test individual concerns)
- Merge conflict risk (many developers touching same file)
- Code reuse limited (concerns tightly coupled)

## Refactoring Strategy

### Principles
1. **Single Responsibility**: Each module handles one concern
2. **Public API Preservation**: Existing callers should not break
3. **Incremental Migration**: Refactor one file at a time
4. **Testing First**: Ensure tests exist before refactoring
5. **Backward Compatibility**: Use `init.lua` to maintain old API

### Approach
For each file:
1. Create new directory structure
2. Extract logical modules
3. Create `init.lua` with public API
4. Migrate implementation to modules
5. Test thoroughly
6. Update imports in codebase

## Priority 1: worktree.lua (2,343 lines)

### Current State
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua`

**Concerns Mixed**:
- Git worktree operations (creation, deletion, listing)
- Claude session management (tracking, switching)
- Terminal lifecycle (spawning, monitoring)
- UI/Picker logic (Telescope integration)
- State tracking (worktree metadata)

### Desired Structure
```
lua/neotex/plugins/ai/claude/core/worktree/
├── init.lua          (100 lines: Public API, backward compat)
├── git_ops.lua       (400 lines: git worktree create/delete/list)
├── session.lua       (500 lines: Claude session management)
├── terminal.lua      (400 lines: Terminal spawn/monitor/close)
├── ui.lua            (300 lines: Picker/display logic)
├── state.lua         (200 lines: Worktree state tracking)
└── README.md         (Module documentation)
```

### Implementation Plan

**Phase 1.1: Preparation** (30 min)
1. Create backup: `cp worktree.lua worktree.lua.backup`
2. Create directory: `mkdir worktree/`
3. Create `init.lua` skeleton with public API
4. Identify all exported functions

**Phase 1.2: Extract git_ops.lua** (1 hour)
1. Identify all git worktree operation functions
2. Move to `git_ops.lua`
3. Define clear interface:
   ```lua
   -- git_ops.lua
   local M = {}

   function M.create_worktree(path, branch) end
   function M.delete_worktree(path) end
   function M.list_worktrees() end
   function M.get_worktree_status(path) end

   return M
   ```
4. Update `init.lua` to use `git_ops`
5. Test git operations work

**Phase 1.3: Extract session.lua** (1.5 hours)
1. Identify Claude session management code
2. Move to `session.lua`
3. Define interface:
   ```lua
   -- session.lua
   local M = {}

   function M.create_session(worktree_path) end
   function M.get_session(worktree_path) end
   function M.switch_session(worktree_path) end
   function M.close_session(worktree_path) end

   return M
   ```
4. Test session operations

**Phase 1.4: Extract terminal.lua** (1 hour)
1. Identify terminal management code
2. Move to `terminal.lua`
3. Define interface:
   ```lua
   -- terminal.lua
   local M = {}

   function M.spawn_terminal(config) end
   function M.monitor_terminal(term_id) end
   function M.close_terminal(term_id) end

   return M
   ```

**Phase 1.5: Extract ui.lua** (45 min)
1. Move Telescope picker logic
2. Define interface for picker UI

**Phase 1.6: Extract state.lua** (30 min)
1. Move state tracking logic
2. Define state interface

**Phase 1.7: Integration** (1 hour)
1. Wire all modules in `init.lua`
2. Ensure public API unchanged
3. Update all imports in codebase
4. Remove `worktree.lua.backup` if successful

## Priority 2: picker.lua (2,003 lines)

### Current State
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`

**Concerns Mixed**:
- Telescope integration (picker setup, config)
- Display formatting (entry display, highlighting)
- Filtering logic (command filtering, search)
- Action handlers (command execution)

### Desired Structure
```
lua/neotex/plugins/ai/claude/commands/picker/
├── init.lua       (300 lines: Telescope integration)
├── display.lua    (500 lines: Formatting/rendering)
├── filters.lua    (400 lines: Filtering logic)
├── actions.lua    (800 lines: Command execution)
└── README.md
```

### Implementation Plan
Similar phased approach as worktree.lua:
1. Preparation (30 min)
2. Extract actions.lua (1.5 hours)
3. Extract display.lua (1 hour)
4. Extract filters.lua (45 min)
5. Integration (45 min)

## Priority 3: email_list.lua (1,683 lines)

### Current State
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

**Concerns Mixed**:
- Email list rendering
- Filtering logic
- Sorting algorithms
- UI state management

### Desired Structure
```
lua/neotex/plugins/tools/himalaya/ui/email_list/
├── init.lua      (200 lines: Public interface)
├── filter.lua    (400 lines: Filtering logic)
├── sort.lua      (300 lines: Sorting algorithms)
├── render.lua    (700 lines: Display rendering)
└── README.md
```

### Implementation Plan
Similar phased approach (estimated 3 hours)

## Priority 4: main.lua (1,620 lines)

### Current State
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua`

**Concerns Mixed**:
- UI orchestration
- Command handling
- State management

### Desired Structure
```
lua/neotex/plugins/tools/himalaya/ui/main/
├── init.lua      (300 lines: Orchestration)
├── commands.lua  (600 lines: Command dispatch)
├── state.lua     (700 lines: UI state management)
└── README.md
```

### Implementation Plan
Similar phased approach (estimated 2.5 hours)

## Testing Strategy

### Pre-Refactoring
1. **Document current behavior**:
   - Run comprehensive tests
   - Record all function behaviors
   - Screenshot UI states

2. **Create regression tests**:
   - Test all public API functions
   - Test edge cases
   - Document expected outputs

### During Refactoring
1. **Module-level testing**:
   - Test each extracted module independently
   - Verify interface contracts
   - Check error handling

2. **Integration testing**:
   - Test modules working together
   - Verify public API unchanged
   - Test all use cases

### Post-Refactoring
1. **Regression testing**:
   - Re-run all pre-refactoring tests
   - Compare outputs
   - Fix any discrepancies

2. **Performance testing**:
   - Measure before/after performance
   - Ensure no degradation
   - Document improvements (if any)

## Success Criteria

### Per File
- [ ] Original file deleted
- [ ] New directory structure created
- [ ] All modules have clear interfaces
- [ ] Public API preserved
- [ ] All tests passing
- [ ] No regressions reported
- [ ] README.md documents new structure
- [ ] Code size reduced by modularization (no duplicate code)

### Overall
- [ ] 4 large files modularized
- [ ] Total file count increased but max file size reduced
- [ ] No file exceeds 800 lines
- [ ] All imports updated
- [ ] Documentation updated
- [ ] Performance maintained or improved

## Performance Impact

**Expected Improvements**:
- **No performance change** (same code, better organized)
- **Faster iteration**: Easier to modify specific concerns
- **Better testing**: Can test modules independently
- **Reduced cognitive load**: Developers understand code faster

**Potential Risks**:
- Slight overhead from module loading (negligible in Lua)
- More files to navigate (mitigated by clear structure)

## Rollback Plan

### Per File
1. Keep `.backup` file until fully tested
2. If issues arise, restore from backup:
   ```bash
   mv worktree/ worktree_refactored/
   mv worktree.lua.backup worktree.lua
   ```
3. Fix issues in refactored version
4. Re-attempt migration

### Nuclear Option
- Git revert all changes
- Return to monolithic files
- Document what went wrong
- Plan improved approach

## Notes

- **Incremental approach**: Do one file per session to avoid fatigue
- **Testing critical**: Without tests, refactoring is risky
- **API compatibility**: Users of these modules should not notice changes
- **Documentation**: README.md crucial for understanding new structure

## Recommended Order

1. **worktree.lua** (highest priority, most complex)
2. **picker.lua** (high usage, well-understood patterns)
3. **email_list.lua** (lower priority, himalaya-specific)
4. **main.lua** (lower priority, himalaya-specific)

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua`

## References
- Report Section: [4.1 Large/Complex Files](../../reports/039_nvim_config_improvement_opportunities.md#41-largecomplex-files-requiring-refactoring)
- Complexity target: No file >800 lines
- Estimated total time: 10-15 hours across multiple sessions

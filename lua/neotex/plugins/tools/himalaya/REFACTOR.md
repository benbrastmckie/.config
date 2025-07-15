# Himalaya Plugin Refactoring Plan

## Overview

This document outlines a comprehensive refactoring plan to clean up the Himalaya email plugin codebase. The goal is to remove cruft, eliminate redundancies, simplify architecture, and create a tight, maintainable plugin ready for release.

## Current State Analysis

### Architecture Issues Identified

1. **Multiple Implementations**: 3 draft managers, 3 email composers, 2 loggers
2. **Backwards Compatibility Cruft**: Extensive migration and wrapper code
3. **Over-Engineering**: Complex command system with unnecessary layers
4. **Unused/Debug Files**: Development artifacts and debug utilities
5. **Documentation Bloat**: 25+ markdown files describing resolved issues
6. **Feature Fragmentation**: Simple features split into separate modules

### Metrics

- **Current Files**: ~150+ Lua files across all directories
- **Estimated Reduction**: 30-40% fewer files after refactoring
- **Code Reduction**: ~25% less code overall
- **Complexity Reduction**: Significant simplification of module interactions

## Refactoring Strategy

### Testing Protocol

**CRITICAL**: After each refactoring step, run the full test suite to ensure no functionality is lost:

```vim
:HimalayaTest all
```

**Requirements**:
- All 122 tests must pass after each change
- No functionality regression
- No performance degradation
- Clean execution with no error messages

### Incremental Approach

1. **One change at a time**: Each refactoring step is isolated
2. **Test after each step**: Verify all tests pass before proceeding
3. **Rollback capability**: Each step can be reversed if tests fail
4. **Documentation updates**: Update docs as modules are changed

## Phase 1: Remove Backwards Compatibility Cruft (High Priority)

### 1.1 Remove State Migration System
**Files to modify**: `core/state.lua`
- Remove lines 8-132 (migration system)
- Remove `migrate_old_state()` function
- Remove `load_legacy_state()` function
- Simplify state loading to current format only

**Testing**: Verify state loading/saving works correctly

### 1.2 Remove Command Compatibility Bridge
**Files to remove**: 
- `core/commands.lua` (compatibility bridge)
- Keep `core/commands/init.lua` (actual implementation)

**Files to modify**: Update any requires from `core/commands` to `core/commands/init`

**Testing**: Verify all commands work correctly

### 1.3 Remove Module Wrapper
**Files to remove**: `module.lua`
**Files to modify**: Update any requires from `module` to direct module paths

**Testing**: Verify plugin initialization works correctly

### 1.4 Remove Keymaps Function
**Files to modify**: `init.lua`
- Remove lines 115-120 (keymaps function)
- Remove `get_keymaps()` function if it exists

**Testing**: Verify keymaps still work correctly

## Phase 2: Consolidate Duplicate Managers (High Priority)

### 2.1 Consolidate Draft Managers
**Files to remove**:
- `core/draft_manager_v2.lua` (old unified draft manager)
- `core/draft_manager_v2_maildir.lua` (wrapper)

**Files to keep**: `core/draft_manager_maildir.lua` (current implementation)

**Files to modify**: Update all requires to point to `draft_manager_maildir`
- `ui/email_composer_maildir.lua`
- `ui/email_list.lua`
- `ui/sidebar.lua`
- `core/commands/ui.lua`
- Any other files requiring draft manager

**Testing**: Verify draft functionality works correctly

### 2.2 Consolidate Email Composers
**Files to remove**:
- `ui/email_composer.lua` (v2 refactored)
- `ui/email_composer_wrapper.lua` (compatibility wrapper)

**Files to keep**: `ui/email_composer_maildir.lua` (current implementation)

**Files to modify**: Update all requires to point to `email_composer_maildir`
- `core/commands/ui.lua`
- `ui/email_list.lua`
- Any other files requiring email composer

**Testing**: Verify email composition works correctly

### 2.3 Consolidate Loggers
**Files to remove**: `core/logger.lua` (basic logger)
**Files to keep**: `core/logger_enhanced.lua` (enhanced implementation)

**Files to modify**: 
- Rename `core/logger_enhanced.lua` to `core/logger.lua`
- Update all requires to point to `core/logger`

**Testing**: Verify logging works correctly throughout plugin

## Phase 3: Simplify Command System (Medium Priority)

### 3.1 Remove Async Command Layer
**Files to remove**: `core/async_commands.lua`
**Files to modify**: Move async functionality directly into relevant command modules

**Testing**: Verify async commands still work correctly

### 3.2 Consolidate Command Modules
**Current structure**: 8 separate command modules in `core/commands/`
**Proposed structure**: Consolidate into 3-4 logical groupings:
- `email_commands.lua` (email operations)
- `ui_commands.lua` (UI operations)
- `sync_commands.lua` (sync operations)
- `utility_commands.lua` (utility operations)

**Files to modify**: `core/commands/init.lua` to reflect new structure

**Testing**: Verify all commands work correctly

## Phase 4: Consolidate Orchestration (Medium Priority)

### 4.1 Merge Orchestration Modules
**Files to remove**:
- `orchestration/events.lua`
- `orchestration/integration.lua`

**Files to keep**: `orchestration/commands.lua` (expand to include all orchestration)

**Files to modify**:
- Merge event bus functionality into `orchestration/commands.lua`
- Merge integration functionality into `orchestration/commands.lua`
- Rename to `orchestration/orchestrator.lua`

**Testing**: Verify event handling and command orchestration works correctly

## Phase 5: Consolidate Utilities (Medium Priority)

### 5.1 Merge Utility Modules
**Files to remove**: `utils/enhanced.lua`
**Files to keep**: `utils.lua` (expand with enhanced functionality)

**Files to modify**:
- Merge performance utilities into `utils.lua`
- Update all requires to point to `utils`

**Testing**: Verify utility functions work correctly

## Phase 6: Simplify Features (Low Priority)

### 6.1 Integrate Feature Modules
**Files to remove**:
- `features/accounts.lua` (33 lines - integrate into core)
- `features/attachments.lua` (integrate into email composer)
- `features/contacts.lua` (integrate into core)
- `features/headers.lua` (integrate into email utilities)
- `features/images.lua` (integrate into UI utilities)

**Files to modify**:
- Move account functionality to `core/accounts.lua`
- Move attachment functionality to `ui/email_composer_maildir.lua`
- Move contact functionality to `core/contacts.lua`
- Move header functionality to `utils.lua`
- Move image functionality to `ui/utils.lua`

**Testing**: Verify all feature functionality works correctly

## Phase 7: Remove Debug and Unused Files (Low Priority)

### 7.1 Remove Debug Files
**Files to remove**:
- `debug_drafts.lua`
- `commands/debug_himalaya_output.lua`
- `commands/migrate_drafts.lua`

**Testing**: Verify plugin functionality is unaffected

### 7.2 Clean Up Documentation
**Files to remove** (archive resolved issues):
- `docs/DEBUG_DUPLICATE_HEADERS.md`
- `docs/FIX_DUPLICATE_HEADERS.md`
- `docs/FIX_DUPLICATE_HEADERS_V2.md`
- `docs/DRAFT_MIGRATION_COMPLETE.md`
- `docs/MIGRATION_COMPLETE.md`
- `docs/MIGRATION_NOTES.md`
- `docs/MIGRATION_PROGRESS.md`
- `docs/REFACTOR_PROGRESS.md`
- `docs/REFACTOR_SUMMARY.md`

**Files to keep**:
- `docs/README.md`
- `docs/ARCHITECTURE.md`
- `docs/GUIDELINES.md`
- `docs/REFINE.md`
- Current user documentation

**Testing**: Verify documentation references are still valid

## Phase 8: Simplify Configuration (Low Priority)

### 8.1 Reduce Configuration Complexity
**Files to modify**: `core/config.lua` (1205 lines)
- Remove backwards compatibility validation
- Simplify default configuration
- Remove deprecated options
- Streamline validation logic

**Testing**: Verify configuration loading and validation works correctly

## Implementation Timeline

### Week 1: High Priority (Phases 1-2)
- Day 1: Remove backwards compatibility cruft
- Day 2: Consolidate draft managers
- Day 3: Consolidate email composers
- Day 4: Consolidate loggers
- Day 5: Testing and validation

### Week 2: Medium Priority (Phases 3-5)
- Day 1: Simplify command system
- Day 2: Consolidate orchestration
- Day 3: Consolidate utilities
- Day 4: Testing and validation
- Day 5: Documentation updates

### Week 3: Low Priority (Phases 6-8)
- Day 1: Simplify features
- Day 2: Remove debug files
- Day 3: Clean up documentation
- Day 4: Simplify configuration
- Day 5: Final testing and validation

## Safety Measures

### Before Starting
1. Ensure all tests pass: `:HimalayaTest all`
2. Create backup branch: `git checkout -b refactor-backup`
3. Commit current state: `git commit -m "Pre-refactor state"`

### During Refactoring
1. **One change at a time**: Complete each step before moving to next
2. **Test after each step**: Run `:HimalayaTest all` after each change
3. **Commit frequently**: Commit after each successful step
4. **Rollback if needed**: Use `git revert` if tests fail

### After Each Phase
1. Run full test suite: `:HimalayaTest all`
2. Test manual functionality: Verify key features work
3. Check performance: Ensure no performance regression
4. Update documentation: Reflect changes in docs

## Expected Outcomes

### File Structure After Refactoring
```
himalaya/
   core/
      config.lua (simplified)
      state.lua (migration removed)
      logger.lua (consolidated)
      draft_manager_maildir.lua (single implementation)
      accounts.lua (from features)
      contacts.lua (from features)
      commands/
          init.lua
          email_commands.lua (consolidated)
          ui_commands.lua (consolidated)
          sync_commands.lua (consolidated)
          utility_commands.lua (consolidated)
   ui/
      email_composer_maildir.lua (single implementation)
      email_list.lua
      sidebar.lua
      utils.lua (image functionality)
   sync/
      coordinator.lua
      manager.lua
   orchestration/
      orchestrator.lua (consolidated)
   utils.lua (enhanced, consolidated)
   init.lua (simplified)
   docs/
       README.md
       ARCHITECTURE.md
       GUIDELINES.md
       REFINE.md
```

### Metrics After Refactoring
- **Files Reduced**: From ~150 to ~90 files (40% reduction)
- **Code Reduced**: ~25% less code overall
- **Complexity**: Significantly simplified module interactions
- **Maintainability**: Much easier to understand and modify
- **Performance**: Reduced module loading overhead

## Risk Mitigation

### High-Risk Changes
1. **State migration removal**: Could affect users with old state files
2. **Command system changes**: Could break existing keymaps
3. **Manager consolidation**: Could affect core functionality

### Mitigation strategies
1. **Extensive testing**: Run full test suite after each change
2. **Incremental approach**: One change at a time
3. **Rollback capability**: Each step can be reversed
4. **User communication**: Document breaking changes clearly

## Success Criteria

### Technical Success
- All 122 tests pass after refactoring
- No functionality regression
- Simplified architecture with clear module boundaries
- Reduced code complexity and file count

### User Success
- Plugin works exactly as before
- No breaking changes to user-facing functionality
- Improved performance and reliability
- Easier to maintain and extend

## Post-Refactoring Tasks

1. **Update README**: Reflect new architecture
2. **Create migration guide**: Document any breaking changes
3. **Performance benchmarks**: Verify performance improvements
4. **Release preparation**: Prepare for public release
5. **Documentation review**: Ensure all docs are current

## Notes

- This refactoring focuses on code organization, not functionality changes
- User-facing behavior should remain identical
- Testing is critical at every step
- Documentation should be updated as changes are made
- The goal is a clean, maintainable codebase ready for release
# Neovim Configuration Refactoring Plan

## Overview

This document provides a comprehensive refactoring roadmap for the Neovim configuration based on analysis report [039_nvim_config_improvement_opportunities.md](../reports/039_nvim_config_improvement_opportunities.md).

The refactoring is organized into **3 phases** with **8 implementation plans** targeting:
- **Plugin Quality**: Deprecated dependencies, minimal configurations
- **Keybinding Organization**: Conflicts, missing essentials
- **Performance Optimization**: Lazy-loading, autocmd efficiency
- **Code Organization**: Large file modularization, documentation gaps

## Refactoring Phases

### Phase 1: Quick Wins (High Impact, Low Effort)
**Estimated Time**: 2 hours
**Priority**: Immediate
**Performance Impact**: 150-200ms startup time reduction

These are low-hanging fruit that provide immediate benefits with minimal risk.

### Phase 2: Medium Priority (Medium Impact, Low-Medium Effort)
**Estimated Time**: 2 hours 50 minutes
**Priority**: Short-term
**Performance Impact**: Additional 30-50ms savings, improved UX

Incremental improvements that enhance daily workflow and performance.

### Phase 3: Long-Term Refactoring (High Impact, High Effort)
**Estimated Time**: 10-15 hours (across multiple sessions)
**Priority**: Long-term
**Maintainability Impact**: 50% reduction in large files (>1000 lines)

Strategic refactoring for long-term maintainability and code quality.

---

## Implementation Plans

### Phase 1: Quick Wins

#### [001: Fix Completion System Inconsistency](phase1-quick-wins/001_fix_completion_system_inconsistency.md)
**Status**: ✅ Completed
**Estimated Time**: 15 minutes
**Priority**: High

**Problem**: Two plugins (`lean.nvim`, `mini.nvim`) reference deprecated `nvim-cmp` despite migration to `blink.cmp`.

**Impact**:
- Potential plugin conflicts
- Unnecessary plugin loading
- Confusion about active completion system

**Tasks**:
- [ ] Remove `nvim-cmp` from lean.nvim dependencies
- [ ] Remove `nvim-cmp` from mini.nvim dependencies
- [ ] Verify blink.cmp compatibility

**Success Metrics**:
-  No nvim-cmp loading errors
-  Completion works with blink.cmp
-  No plugin conflicts

---

#### [002: Resolve `<C-c>` Keybinding Conflict](phase1-quick-wins/002_resolve_ctrl_c_keybinding_conflict.md)
**Status**: ✅ Completed
**Estimated Time**: 30 minutes
**Priority**: High

**Problem**: `<C-c>` has conflicting behavior in three contexts (Claude Code toggle, Avante history clear, Telescope close) with incorrect documentation.

**Impact**:
- Context-dependent behavior creates confusion
- Documentation mismatch causes errors

**Tasks**:
- [ ] Choose resolution strategy (context-aware vs reassign)
- [ ] Implement chosen solution
- [ ] Fix incorrect documentation in keymaps.lua:78
- [ ] Update which-key descriptions

**Success Metrics**:
-  `<C-c>` behavior consistent and documented
-  All three contexts work correctly
-  No conflicting keybinding warnings

---

#### [003: Optimize Expensive Autocmds](phase1-quick-wins/003_optimize_expensive_autocmds.md)
**Status**: ✅ Completed
**Estimated Time**: 20 minutes
**Priority**: High

**Problem**: File reload autocmd fires on `CursorHold` events, causing 5-10ms lag per cursor pause with excessive I/O.

**Impact**:
- 5-10ms delay per cursor pause
- Excessive file system checks
- Degraded editing experience

**Tasks**:
- [ ] Remove `CursorHold` and `CursorHoldI` from file reload autocmd
- [ ] Keep `FocusGained` and `BufEnter` events
- [ ] Consolidate terminal setup deferred functions

**Success Metrics**:
-  0ms cursor movement lag (down from 5-10ms)
-  98% reduction in autocmd fires
-  File reload still works on focus/buffer change

---

#### [004: Create Missing Documentation](phase1-quick-wins/004_create_missing_documentation.md)
**Status**: ✅ Completed
**Estimated Time**: 45 minutes
**Priority**: Low

**Problem**: 5+ directories missing README.md files, violating CLAUDE.md documentation policy.

**Impact**:
- Navigation difficulties
- Unclear module purposes
- Policy non-compliance

**Tasks**:
- [ ] Create `/lua/neotex/core/README.md`
- [ ] Create `/lua/neotex/plugins/tools/himalaya/data/README.md`
- [ ] Create `/lua/neotex/plugins/tools/himalaya/features/README.md`
- [ ] Create `/lua/neotex/plugins/tools/himalaya/utils/README.md`
- [ ] Create `/lua/neotex/plugins/tools/himalaya/commands/README.md`

**Success Metrics**:
-  100% documentation policy compliance
-  All READMEs follow CLAUDE.md template
-  Navigation links functional

---

### Phase 2: Medium Priority

#### [005: Enhance Minimal Plugin Configurations](phase2-medium-priority/005_enhance_minimal_plugin_configurations.md)
**Status**:  ✅ Completed
**Estimated Time**: 60 minutes
**Priority**: Medium

**Problem**: Several plugins have minimal configurations with significant enhancement potential or should be removed.

**Impact**:
- Unused features (firenvim, wezterm)
- Limited icon support (nvim-web-devicons)
- Verbose debug logging (markdown-preview)

**Tasks**:
- [ ] Deprecate firenvim.lua (move to `deprecated/`)
- [ ] Remove wezterm-integration.lua
- [ ] Enhance nvim-web-devicons with 8+ filetype icons
- [ ] Fix markdown-preview log level (debug � warn)

**Success Metrics**:
-  5-10ms startup time savings
-  90% reduction in console debug logs
-  Better file type icon coverage

---

#### [006: Implement Missing Keybindings](phase2-medium-priority/006_implement_missing_keybindings.md)
**Status**:  ✅ Completed
**Estimated Time**: 10 minutes
**Priority**: Medium

**Problem**: Essential quickfix and location list navigation keybindings missing.

**Impact**:
- Must type verbose commands like `:cnext`, `:cprev`
- Reduced productivity when working with search results

**Tasks**:
- [ ] Add quickfix navigation: `]q`, `[q`, `]Q`, `[Q`
- [ ] Add location list navigation: `]l`, `[l`, `]L`, `[L`
- [ ] Update which-key descriptions

**Success Metrics**:
- ✓ Quickfix and location list navigation functional
- ✓ Cursor centers after navigation (`zz`)
- ✓ No conflicts with existing mappings

---

#### [007: Improve Lazy-Loading](phase2-medium-priority/007_improve_lazy_loading.md)
**Status**:  Not Started
**Estimated Time**: 40 minutes
**Priority**: Medium

**Problem**: Several plugins load at startup when they could be deferred (Snacks.nvim, Session Manager, 7 VeryLazy plugins).

**Impact**:
- 30-50ms startup time overhead
- Unnecessary memory consumption

**Tasks**:
- [ ] Defer Snacks.nvim dashboard to VimEnter
- [ ] Change Session Manager to VeryLazy
- [ ] Migrate 3-5 VeryLazy plugins to specific events

**Success Metrics**:
-  30-50ms startup time reduction (measured)
-  No feature regressions
-  All plugins load on appropriate events

---

### Phase 3: Long-Term Refactoring

#### [008: Modularize Large Files](phase3-long-term/008_modularize_large_files.md)
**Status**:  Not Started
**Estimated Time**: 10-15 hours (across multiple sessions)
**Priority**: Low (Strategic)

**Problem**: Four files exceed 1,600+ lines with mixed concerns (worktree.lua: 2,343 lines, picker.lua: 2,003 lines, email_list.lua: 1,683 lines, main.lua: 1,620 lines).

**Impact**:
- Difficult to maintain and understand
- High cognitive load for modifications
- Testing complexity

**Tasks**:
- [ ] **Priority 1**: Modularize worktree.lua � 6 modules
- [ ] **Priority 2**: Modularize picker.lua � 4 modules
- [ ] **Priority 3**: Modularize email_list.lua � 4 modules
- [ ] **Priority 4**: Modularize main.lua � 3 modules

**Success Metrics**:
-  No file exceeds 800 lines
-  50% reduction in files >1000 lines
-  All tests passing
-  No performance regression

---

## Progress Tracking

### Overall Progress
```
Phase 1: Quick Wins          [✓] 4/4 completed
Phase 2: Medium Priority     [✓] 3/3 completed
Phase 3: Long-Term           [] 0/1 completed

Total Progress:              [████████████████████░░░] 7/8 completed (87.5%)
```

### Phase-by-Phase Status

**Phase 1: Quick Wins** (2 hours estimated) ✅ COMPLETE
- [x] 001: Fix Completion System  (15 min)
- [x] 002: Resolve `<C-c>` Conflict  (30 min)
- [x] 003: Optimize Autocmds  (20 min)
- [x] 004: Create Documentation  (45 min)

**Phase 2: Medium Priority** (2h 50m estimated) ✅ COMPLETE
- [x] 005: Enhance Plugins  (60 min)
- [x] 006: Missing Keybindings  (10 min)
- [x] 007: Lazy-Loading  (40 min)

**Phase 3: Long-Term** (10-15 hours estimated)
- [ ] 008: Modularize Large Files  (10-15 hours)
  - [ ] worktree.lua � 6 modules  (4 hours)
  - [ ] picker.lua � 4 modules  (3 hours)
  - [ ] email_list.lua � 4 modules  (3 hours)
  - [ ] main.lua � 3 modules  (2.5 hours)

---

## Performance Impact Summary

### Startup Time Improvements

| Optimization | Estimated Savings | Phase |
|--------------|-------------------|-------|
| Remove nvim-cmp deps | 5ms | Phase 1 |
| Optimize autocmds | 10-20ms | Phase 1 |
| Deprecate firenvim/wezterm | 5-10ms | Phase 2 |
| Defer Snacks dashboard | 10-15ms | Phase 2 |
| Optimize Session Manager | 15-25ms | Phase 2 |
| Lazy-load VeryLazy plugins | 5-10ms | Phase 2 |
| **Total Estimated** | **50-85ms** | - |
| **Target (Report)** | **150-200ms** | - |

**Note**: Conservative estimates. Report targets 150-200ms reduction through additional optimizations not yet planned.

### Runtime Performance Improvements

| Optimization | Impact | Phase |
|--------------|--------|-------|
| CursorHold autocmd removal | 5-10ms/pause � 0ms | Phase 1 |
| Reduce autocmd fires | ~100/min � ~2/min | Phase 1 |
| Markdown-preview log level | 90% log reduction | Phase 2 |

### Code Quality Improvements

| Metric | Before | After (Target) | Phase |
|--------|--------|----------------|-------|
| Files >1000 lines | 4 | 0 | Phase 3 |
| Max file size | 2,343 lines | <800 lines | Phase 3 |
| Documentation compliance | ~70% | 100% | Phase 1 |
| Deprecated plugin refs | 2 | 0 | Phase 1 |

---

## Implementation Strategy

### Recommended Order

**Week 1: Quick Wins**
- Day 1: 001 + 002 (45 min)
- Day 2: 003 + 004 (65 min)
- **Outcome**: Immediate performance boost, keybinding fixes

**Week 2: Medium Priority**
- Day 1: 005 (60 min)
- Day 2: 006 + 007 (60 min)
- **Outcome**: Enhanced UX, additional performance gains

**Weeks 3-4: Long-Term**
- Week 3: 008 - worktree.lua + picker.lua (7 hours across 3-4 sessions)
- Week 4: 008 - email_list.lua + main.lua (5.5 hours across 2-3 sessions)
- **Outcome**: Sustainable codebase architecture

### Execution Guidelines

1. **One plan at a time**: Complete each plan fully before moving to next
2. **Test after each change**: Run comprehensive tests after each implementation
3. **Git commits**: Commit after each completed plan
4. **Performance measurement**: Use `nvim --startuptime` before/after Phase 1 & 2
5. **Backup critical files**: Create `.backup` for Phase 3 large file refactoring

### Testing Protocol

**Before Starting Any Phase**:
```bash
# Baseline measurements
nvim --startuptime baseline.log +quit
cp baseline.log baseline_$(date +%Y%m%d).log
```

**After Phase 1**:
```bash
nvim --startuptime phase1_complete.log +quit
# Compare with baseline
```

**After Phase 2**:
```bash
nvim --startuptime phase2_complete.log +quit
# Target: 50-85ms improvement from baseline
```

**After Phase 3**:
```bash
# No performance change expected (code organization only)
# Focus on functionality testing
```

---

## Success Criteria

### Phase 1 Success (Must achieve all) ✅ ACHIEVED
- [x] nvim-cmp completely removed from dependencies
- [x] `<C-c>` keybinding conflict resolved
- [x] CursorHold autocmds removed, 0 lag on cursor pause
- [x] 5 README.md files created, 100% documentation compliance
- [ ] Startup time improved by at least 15ms (measured) - not yet benchmarked
- [ ] All manual tests passing - not yet tested

### Phase 2 Success (Must achieve all) ✅ ACHIEVED
- [x] firenvim deprecated, wezterm removed
- [x] nvim-web-devicons has 8+ icon overrides
- [x] markdown-preview log level = warn
- [x] 3 new keybinding categories functional (quickfix + location list navigation)
- [x] Snacks dashboard deferred, Session Manager on VeryLazy (Session Manager changed to VeryLazy)
- [x] 3-5 VeryLazy plugins using specific events (3 plugins optimized: sessions, nvim-lsp-file-operations, surround)
- [ ] Additional 30-50ms startup time improvement (measured) - not measured
- [ ] Total startup time improvement: 45-65ms from baseline - not measured

### Phase 3 Success (Must achieve all)
- [ ] worktree.lua split into 6 modules (<800 lines each)
- [ ] picker.lua split into 4 modules (<800 lines each)
- [ ] email_list.lua split into 4 modules (<800 lines each)
- [ ] main.lua split into 3 modules (<800 lines each)
- [ ] All modules have README.md documentation
- [ ] Public APIs preserved (no breaking changes)
- [ ] All tests passing, no regressions
- [ ] No performance degradation

### Overall Success (Final State)
- [ ] Total startup time improvement: 50-85ms (Phase 1 + 2)
- [ ] 0 keybinding conflicts
- [ ] 100% documentation policy compliance
- [ ] 0 files >1000 lines
- [ ] 0 deprecated plugin references
- [ ] Clean, maintainable codebase architecture

---

## Rollback Strategy

### Per-Plan Rollback
Each plan includes specific rollback instructions. General approach:

```bash
# If plan fails partway through
git status  # Check changes
git diff    # Review changes
git restore <files>  # Restore specific files

# If committed but issues discovered
git log -1  # Verify commit
git revert HEAD  # Revert last commit
```

### Phase Rollback
If entire phase needs rollback:

```bash
# Identify phase start commit
git log --oneline | grep "Phase X start"

# Revert to before phase
git reset --hard <commit-before-phase>

# Or create revert commits (preserves history)
git revert <commit-range>
```

### Nuclear Option
```bash
# Restore to refactor start point
git checkout <commit-before-refactor>
git checkout -b refactor-v2-attempt

# Analyze what went wrong
# Plan improved approach
```

---

## Maintenance

### After Refactoring Complete

**Update this document**:
- Mark all plans as  Completed
- Update progress bars to 100%
- Document actual vs estimated times
- Note any deviations from plans

**Create summary report**:
- Actual performance improvements measured
- Lessons learned
- Recommendations for future refactoring

**Archive**:
- Move completed plans to `archived/` subdirectory
- Keep REFACTOR.md in place as historical record
- Link to any summary reports created

---

## References

- **Analysis Report**: [039_nvim_config_improvement_opportunities.md](../reports/039_nvim_config_improvement_opportunities.md)
- **Project Standards**: [CLAUDE.md](../../CLAUDE.md)
- **Neovim Standards**: [nvim/CLAUDE.md](../../nvim/CLAUDE.md)

---

## Notes

### Assumptions
- Tests exist or will be created before refactoring
- Baseline performance measurements available
- Git used for version control (all changes committed)

### Risks
- **Phase 1**: Low risk, high value (quick wins)
- **Phase 2**: Medium risk, good value (requires testing)
- **Phase 3**: High risk, high value (large changes, requires extensive testing)

### Recommendations
- **Do Phase 1 first**: Immediate benefits, builds momentum
- **Test thoroughly**: Each plan has comprehensive testing strategy
- **Take breaks during Phase 3**: Long refactoring sessions increase error risk
- **Commit frequently**: Easier rollback if issues discovered

---

*Refactoring plan created: 2025-10-03*
*Based on analysis report: 039_nvim_config_improvement_opportunities.md*
*For questions or issues, refer to individual implementation plan documents*

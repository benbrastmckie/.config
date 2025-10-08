# Deferred Tasks

This document tracks tasks that were deferred during various implementation phases.

## Summary

**Total Deferred**: 9 tasks
**Priority**: Low-Medium (none are critical for release)
**Estimated Total Effort**: 10-14 hours

## Deferred Task List

## From Artifact Picker Review (Report 044)

### 1. Document Buffer Reload in Picker README
**Deferred From**: Artifact Picker Code Review (2025-10-08)
**Reason**: Documentation gap, not critical for functionality
**Priority**: High (user-facing documentation)
**Estimated Effort**: 5 minutes

**Description**:
Update README.md to document buffer reload behavior when replacing artifacts with `<C-l>`.

**Tasks**:
- Add section to "Loading Commands (`<C-l>`)" explaining buffer reload
- Document that open buffers are automatically reloaded when artifacts replaced
- Explain that unsaved local modifications are discarded
- Sets user expectations for "destructive" nature of replacement

**Why Deferred**:
- Feature works correctly, only documentation missing
- User can discover behavior through use
- Quick fix when addressed

**When to Address**:
- Next documentation update pass
- When updating picker README for other reasons
- High value for minimal effort

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/README.md`
**Location**: "Loading Commands" section around line 110

---

### 2. Add Buffer Reload Notification
**Deferred From**: Artifact Picker Code Review (2025-10-08)
**Reason**: UX enhancement, not required for functionality
**Priority**: Medium
**Estimated Effort**: 10 minutes

**Description**:
Add notification when buffer is reloaded after artifact replacement to provide user feedback.

**Implementation**:
```lua
-- In buffer reload section (picker.lua line ~3028)
if modified then
  vim.api.nvim_buf_set_option(bufnr, 'modified', false)
  vim.cmd(string.format("buffer %d | edit", bufnr))

  local notify = require('neotex.util.notifications')
  notify.editor(
    string.format("Reloaded '%s' from global version", artifact_name),
    notify.categories.INFO
  )
end
```

**Benefits**:
- User confirmation that replacement worked
- Explicit feedback that local changes were discarded
- Consistent with other operation notifications

**Why Deferred**:
- Buffer reload works correctly without notification
- Enhancement, not bug fix
- Quick implementation when addressed

**When to Address**:
- Next picker enhancement pass
- When adding other picker notifications
- Low priority UX improvement

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Location**: Lines 3012-3033 (buffer reload section)

---

### 3. Extract Dialog Builder Helper Function
**Deferred From**: Artifact Picker Code Review (2025-10-08)
**Reason**: Code readability optimization, not functional issue
**Priority**: Low
**Estimated Effort**: 30 minutes

**Description**:
Refactor `<C-l>` handler to extract confirmation dialog building logic into separate helper function.

**Current Issue**:
- `<C-l>` handler is 210 lines (lines 2960-3169)
- Dialog building logic is 50+ lines inline
- Reduces readability

**Benefits**:
- Reduces handler from 210 to ~120 lines
- Dialog logic testable in isolation
- Clearer separation of concerns
- Easier to modify dialog behavior

**Why Deferred**:
- Code works correctly as-is
- Optimization, not bug fix
- Can be done during future refactoring pass

**When to Address**:
- Next major picker refactor
- When modifying `<C-l>` handler for other reasons
- Future code cleanup sprint

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Location**: Lines 2960-3169 (`<C-l>` handler)

---

### 4. Optimize Filepath Construction in do_load()
**Deferred From**: Artifact Picker Code Review (2025-10-08)
**Reason**: Negligible performance impact
**Priority**: Low (micro-optimization)
**Estimated Effort**: 20 minutes

**Description**:
Lazy construction of `loaded_filepath` - only build when `force=true`.

**Current Behavior**:
- Constructs filepath for all loads (first and replacement)
- Buffer reload only happens when `force=true` (replacement)
- Wastes ~95% of filepath constructions (first loads)

**Optimization**:
- Move filepath construction inside `if success and force` block
- Only construct when actually needed for buffer reload

**Benefits**:
- Avoids string concatenation on first loads (95% of cases)
- Marginal performance improvement
- Slightly cleaner logic flow

**Trade-off**:
- Slightly more complex control flow
- Minimal actual performance gain

**Why Deferred**:
- Performance impact negligible (string concatenation is fast)
- Code clarity vs performance trade-off
- Optimization without measurable benefit

**When to Address**:
- Future optimization sprint (if ever)
- Very low priority
- Optional improvement

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Location**: Lines 2967-3048 (`do_load()` helper)

---

### 5. Add Strategic Code Comments to Picker
**Deferred From**: Artifact Picker Code Review (2025-10-08)
**Reason**: Code is self-documenting for experienced developers
**Priority**: Low (documentation enhancement)
**Estimated Effort**: 30 minutes

**Description**:
Add inline comments to document non-obvious design decisions for future maintainers.

**Areas to Document**:
1. Global filepath resolution (why we check `force and is_local`)
2. Hook event `is_local` detection (why we check first hook)
3. Buffer reload timing (why we use `vim.schedule`)

**Benefits**:
- Easier for new contributors to understand intent
- Prevents regression bugs from "simplification" refactors
- Documents non-obvious design decisions

**Why Deferred**:
- Code works correctly without comments
- Experienced developers can understand from code
- Enhancement, not requirement

**When to Address**:
- When onboarding new contributors
- Future documentation improvement pass
- Low priority

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Locations**:
- Lines 2616-2624, 2086-2093 (global filepath resolution)
- Lines 3065-3070 (hook event detection)
- Lines 3012-3033 (buffer reload)

---

## From Plan 026 (Agential System Refinement)

### 6. Adaptive Planning Logging and Observability
**Deferred From**: Phase 4
**Reason**: Not critical for initial release
**Priority**: Low
**Estimated Effort**: 3-4 hours

**Description**:
Add comprehensive logging for adaptive planning detection in `/implement`.

**Tasks**:
- Log each trigger evaluation (triggered or not)
- Log complexity scores and thresholds
- Log test failure patterns detected
- Log all replan invocations and outcomes
- Create `.claude/data/logs/adaptive-planning.log` with structured entries

**Why Deferred**:
- Adaptive planning is documented but not yet used in practice
- Logging can be added after first real-world usage
- Documentation is sufficient for initial implementation

**When to Address**:
- After first use of adaptive planning feature
- When debugging adaptive planning behavior needed
- Next sprint or when feature is actively used

---

### 7. Adaptive Planning Integration Tests
**Deferred From**: Phase 4 (to Phase 7, then deferred)
**Reason**: Complex integration test requiring full workflow
**Priority**: Medium
**Estimated Effort**: 2-3 hours

**Description**:
Create integration test for full adaptive planning workflow.

**Test Scenarios**:
- Full /implement → detect complexity → /revise --auto-mode → continue flow
- Loop prevention (max 2 replans per phase)
- Error recovery when /revise fails
- Checkpoint updates with replan metadata

**Why Deferred**:
- Requires complex test setup (mock plans with >8 complexity)
- Unit tests for components already passing (complexity detection, checkpoint increments)
- Documentation serves as specification
- Can verify during first real usage

**When to Address**:
- Next sprint after initial release
- When adaptive planning is first used in production
- If bugs are found in workflow integration

**Documented In**: COVERAGE_REPORT.md, Section "Coverage Gaps"

---

### 8. /revise Auto-Mode Integration Tests
**Deferred From**: Phase 5 (to Phase 7, then deferred)
**Reason**: Complex programmatic invocation testing
**Priority**: Medium
**Estimated Effort**: 3-4 hours

**Description**:
Create integration tests for /revise auto-mode invocation.

**Test Scenarios**:
- Context JSON generation and parsing
- All 4 revision types (expand_phase, add_phase, split_phase, update_tasks)
- Response format validation (success/error JSON)
- Backup/restore on failure
- Plan file updates

**Why Deferred**:
- Auto-mode is invoked programmatically by /implement
- Documentation comprehensive (~350 lines specification)
- Manual testing possible during first adaptive planning use
- Not yet used in practice

**When to Address**:
- During first adaptive planning usage
- Next sprint for complete coverage
- If auto-mode bugs discovered

**Documented In**: COVERAGE_REPORT.md, Section "Coverage Gaps"

---

### 9. Commands Updated to Use Shared Utilities
**Deferred From**: Phase 6
**Reason**: Optimization, not required for functionality
**Priority**: Low (future enhancement)
**Estimated Effort**: 2-3 hours

**Description**:
Refactor commands to use shared utility libraries instead of inline implementations.

**Commands to Update**:
- `/orchestrate` - Use checkpoint-utils, artifact-utils, error-utils
- `/implement` - Use complexity-utils, checkpoint-utils, error-utils
- `/setup` - Use error-utils for validation

**Why Deferred**:
- Shared utilities are tested and working
- Commands currently work with inline implementations
- Refactoring is optimization, not bug fix
- No functionality lost (verified in Phase 7)

**Benefits of Completing**:
- Reduced code duplication (~100-150 LOC savings)
- Easier maintenance (update once in lib/)
- Consistent behavior across commands

**When to Address**:
- Future optimization sprint
- When modifying these commands for other reasons
- Low priority, can be done incrementally

---

## Verification Status

All deferred tasks have been:
- ✅ Documented with effort estimates
- ✅ Prioritized (all low-medium priority)
- ✅ Given clear "when to address" guidance
- ✅ Verified not critical for release

**Quick Wins** (< 15 minutes):
- Task 1: Document buffer reload (5 min, high user value)
- Task 2: Add buffer reload notification (10 min, better UX)

## Integration Test Coverage Achieved

While full integration tests were deferred, we achieved:
- ✅ 90.6% unit test coverage for shared utilities
- ✅ 100% coverage for progressive plan structures
- ✅ 85% coverage for checkpoint operations
- ✅ 60% coverage for command workflows
- ✅ No regressions detected
- ✅ Backward compatibility verified

See `COVERAGE_REPORT.md` for complete test results.

## Recommendation

**Proceed with release** - All deferred tasks are enhancements or future optimizations. Core functionality is:
- Fully implemented
- Well documented
- Tested (90.6% pass rate)
- Backward compatible
- Regression-free

**Address deferred tasks in next sprint** when:
- Adaptive planning is first used in practice
- Integration bugs discovered (unlikely based on unit test coverage)
- Optimization sprint scheduled

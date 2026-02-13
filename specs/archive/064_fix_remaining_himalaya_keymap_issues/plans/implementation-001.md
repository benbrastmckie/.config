# Implementation Plan: Task #64

- **Task**: 64 - Fix remaining himalaya keymap issues
- **Status**: [COMPLETED]
- **Effort**: 1-2 hours
- **Dependencies**: Task #63 (completed)
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Fix three confirmed bugs in the himalaya email plugin after task 63: (1) nil check missing in move command format_item function, (2) invalid keymap syntax in search module using `{ buffer = buf }` with nvim_buf_set_keymap, and (3) compose send keymap calling non-existent `composer.send()` instead of `composer.send_email(buf)`. All fixes are targeted single-line or small block changes with clear verification paths.

### Research Integration

Research report (research-001.md) confirmed:
- Issues 2/5 (d/r/R errors, help menu) are NOT bugs - working as designed
- Three actual bugs require fixes with specific line locations identified
- Optional improvements (error messages, help clarification) deferred as low priority

## Goals & Non-Goals

**Goals**:
- Fix move command nil error by adding defensive type check
- Fix search keymap syntax using correct vim.keymap.set API
- Fix compose send handler to call correct function with buffer argument

**Non-Goals**:
- Improving error messages for cursor-position-aware actions (low priority)
- Adding help menu clarification about Space vs Leader (optional)
- Refactoring the broader keymap architecture

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Fix introduces regression | Medium | Low | Verify with nvim --headless load test |
| Search has multiple affected lines | Low | Medium | Research identified pattern, apply to all lines 763-785 |
| Compose keymap in wrong scope | Medium | Low | Verify compose buffer is active when keymap triggers |

## Implementation Phases

### Phase 1: Fix Core Bugs [COMPLETED]

**Goal**: Address all three confirmed bugs with targeted fixes

**Tasks**:
- [x] Fix `ui/main.lua` line 1502 - add nil/type check before `folder:lower()`
- [x] Fix `data/search.lua` lines 763-785 - convert `nvim_buf_set_keymap` to `vim.keymap.set` with proper options
- [x] Fix `config/ui.lua` lines 395-400 - change `composer.send()` to `composer.send_email(buf)`

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Add nil check in format_item function
- `lua/neotex/plugins/tools/himalaya/data/search.lua` - Fix keymap syntax for search buffer
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Fix send function call

**Verification**:
- Run `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.main')" -c "q"` - no errors
- Run `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.data.search')" -c "q"` - no errors
- Run `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.config.ui')" -c "q"` - no errors

---

### Phase 2: Verify and Document [COMPLETED]

**Goal**: Confirm fixes work correctly and document changes

**Tasks**:
- [x] Run full himalaya module load test
- [x] Verify no new warnings in :checkhealth
- [x] Create implementation summary

**Timing**: 30 minutes

**Files to modify**:
- None (verification only)
- `specs/064_fix_remaining_himalaya_keymap_issues/summaries/implementation-summary-YYYYMMDD.md` - Create summary

**Verification**:
- `nvim --headless -c "checkhealth" -c "q"` - no himalaya-related errors
- All three modules load without error
- Manual verification paths documented in summary

## Testing & Validation

- [x] Module loads without error: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya')" -c "q"`
- [x] Search keymap creates buffer-local mapping correctly
- [x] Move command handles nil folder gracefully
- [x] Compose send keymap resolves to valid function

## Artifacts & Outputs

- `plans/implementation-001.md` (this file)
- `summaries/implementation-summary-YYYYMMDD.md`

## Rollback/Contingency

If fixes cause regressions:
1. Revert individual changes with git
2. Each fix is independent - can be reverted separately
3. Original code preserved in git history from task 63

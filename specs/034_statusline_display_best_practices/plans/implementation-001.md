# Implementation Plan: Task #34

- **Task**: 34 - statusline_display_best_practices
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [specs/034_statusline_display_best_practices/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Improve the visual presentation of the Claude Code statusline by removing bracket notation around the progress bar. The current format `42% [████░░░░░░] 85k/200k` will become `42% ████░░░░░░ 85k/200k`. This is a minimal change to a single line in the claude-code.lua extension file, with optional enhancements for bold styling at high usage.

### Research Integration

The research report (research-001.md) identified that:
- The bracket wrapper `[%s]` in claude-code.lua line 42 causes visual clutter
- The underlying claude-context.lua already uses clean Unicode blocks
- Current color thresholds (50%/80%) are appropriate and need no change
- Bold styling is already applied but could be conditional on high usage

## Goals & Non-Goals

**Goals**:
- Remove bracket wrapper from progress bar display
- Maintain all existing functionality (colors, thresholds, caching)
- Preserve backward compatibility with existing configuration

**Non-Goals**:
- Adding fractional block characters (out of scope for this task)
- Changing color thresholds
- Adding adaptive width based on terminal size
- Modifying the token formatting

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Unicode rendering differences | Low | Low | Using same block chars already in use |
| Visual regression | Low | Low | Single line change, easy to verify |
| Breaking existing users | Low | Very Low | Change is purely visual, no API change |

## Implementation Phases

### Phase 1: Remove Bracket Wrapper [NOT STARTED]

**Goal**: Update the context_component format string to remove brackets around progress bar

**Tasks**:
- [ ] Edit `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` line 42
- [ ] Change `string.format("%s [%s] %s", pct_str, bar, tokens)` to `string.format("%s %s %s", pct_str, bar, tokens)`
- [ ] Update the comment on line 33 to reflect new format

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` - Remove brackets from format string

**Verification**:
- [ ] Load Neovim and verify module loads: `nvim --headless -c "lua require('neotex.plugins.ui.lualine.extensions.claude-code')" -c "q"`
- [ ] Visual inspection in Claude terminal buffer shows format without brackets

---

### Phase 2: Verification and Testing [NOT STARTED]

**Goal**: Verify the change works correctly in a live Neovim session

**Tasks**:
- [ ] Start Neovim with Claude Code terminal
- [ ] Verify statusline displays in new format: `42% ████░░░░░░ 85k/200k | Model | $X.XX`
- [ ] Verify color transitions still work at 50% and 80% thresholds
- [ ] Verify bold styling applies correctly
- [ ] Test with no context file present (graceful degradation)

**Timing**: 15 minutes

**Files to modify**: None (verification only)

**Verification**:
- [ ] New format displays correctly in statusline
- [ ] All color thresholds work as expected
- [ ] No errors in Neovim messages

---

## Testing & Validation

- [ ] Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.ui.lualine.extensions.claude-code')" -c "q"`
- [ ] Statusline displays correctly in Claude terminal buffers
- [ ] Color transitions work at 50% and 80% thresholds
- [ ] Graceful handling when context file is missing

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (after completion)

## Rollback/Contingency

Rollback is trivial - revert the single line change:
```lua
-- Rollback: restore brackets if needed
return string.format("%s [%s] %s", pct_str, bar, tokens)
```

The change is isolated to one line with no dependencies, making rollback straightforward via git revert.

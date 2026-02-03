# Implementation Plan: Task #34

- **Task**: 34 - statusline_display_best_practices
- **Date**: 2026-02-03 (Revised)
- **Feature**: Improve Claude Code statusline display with Unicode progress bar
- **Status**: [COMPLETED]
- **Estimated Hours**: 0.5-1 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)

## Overview

The current Claude Code terminal statusline displays a progress bar using ASCII bracket notation like `[[=][=][=][-][-][-][-][-][-][-]]` which is visually cluttered. This plan updates the shell hook script to use clean Unicode block characters (`█░`) instead.

**Root Cause**: The statusline-push.sh script (lines 62-66) generates the progress bar using `[=]` and `[-]` characters in a bash loop, which is what appears in Claude Code's terminal output.

**Note**: The Neovim lualine modules (`claude-code.lua` and `claude-context.lua`) are **already correct** - they use Unicode block characters. The original plan mistakenly targeted the Lua files. This revised plan correctly targets the shell script.

### Key Files

| File | Purpose | Change Needed |
|------|---------|---------------|
| `~/.claude/hooks/statusline-push.sh` | Claude Code terminal output | Replace `[=]`/`[-]` with `█`/`░` |
| `lua/neotex/util/claude-context.lua` | Neovim context reader | No change (already correct) |
| `lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` | Neovim lualine extension | No change (already correct) |

## Goals & Non-Goals

**Goals**:
- Replace ASCII `[=][-]` progress bar with Unicode `█░` block characters in statusline-push.sh
- Remove surrounding brackets from progress bar output
- Maintain all existing functionality (JSON file generation, cost/model display)

**Non-Goals**:
- Modifying Neovim Lua modules (they're already correct)
- Adding fractional block characters
- Changing color thresholds in lualine

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Terminal Unicode support | Low | Very Low | Modern terminals (kitty, wezterm, etc.) support Unicode block chars |
| Shell script encoding | Low | Low | Ensure script is saved as UTF-8 |

## Implementation Phases

### Phase 1: Update Progress Bar Generation in Shell Script [COMPLETED]

**Goal**: Replace ASCII bracket notation with Unicode block characters in statusline-push.sh

**Tasks**:
- [ ] Edit `~/.claude/hooks/statusline-push.sh` lines 62-66
- [ ] Replace `[=]` with `█` (U+2588 Full Block)
- [ ] Replace `[-]` with `░` (U+2591 Light Shade)
- [ ] Update the printf format on line 72 to remove surrounding brackets

**Current code (lines 62-66)**:
```bash
bar_filled=$((percentage_int / 10))
bar_empty=$((10 - bar_filled))
bar=""
for ((i=0; i<bar_filled; i++)); do bar+="[=]"; done
for ((i=0; i<bar_empty; i++)); do bar+="[-]"; done
```

**New code**:
```bash
bar_filled=$((percentage_int / 10))
bar_empty=$((10 - bar_filled))
bar=""
for ((i=0; i<bar_filled; i++)); do bar+="█"; done
for ((i=0; i<bar_empty; i++)); do bar+="░"; done
```

**Current printf (line 72)**:
```bash
printf "%d%% [%s] %dk/%dk | %s | %s" "$percentage_int" "$bar" "$used_k" "$limit_k" "$model" "$cost_fmt"
```

**New printf**:
```bash
printf "%d%% %s %dk/%dk | %s | %s" "$percentage_int" "$bar" "$used_k" "$limit_k" "$model" "$cost_fmt"
```

**Files to modify**:
- `/home/benjamin/.claude/hooks/statusline-push.sh`

**Timing**: 15 minutes

**Verification**:
- [ ] Script is saved with UTF-8 encoding
- [ ] Run script manually with test input to verify output format

---

### Phase 2: Verification and Testing [COMPLETED]

**Goal**: Verify the change works correctly in Claude Code terminal

**Tasks**:
- [ ] Test script manually with sample JSON input
- [ ] Start a new Claude Code session to trigger the statusline hook
- [ ] Verify statusline displays new format: `42% ████░░░░░░ 85k/200k | Sonnet 4.5 | $14.60`
- [ ] Verify JSON file generation still works correctly
- [ ] Test at various percentage levels (0%, 30%, 50%, 80%, 100%)

**Test command**:
```bash
echo '{"context_window":{"used_percentage":35,"context_window_size":200000},"model":{"display_name":"Sonnet 4.5"},"cost":{"total_cost_usd":14.60}}' | ~/.claude/hooks/statusline-push.sh
```

**Expected output**:
```
35% ███░░░░░░░ 70k/200k | Sonnet 4.5 | $14.60
```

**Timing**: 15 minutes

**Files to modify**: None (verification only)

**Verification**:
- [ ] Script output shows Unicode block characters
- [ ] No brackets around progress bar
- [ ] JSON file in /tmp/claude-context.json is still generated correctly
- [ ] Neovim lualine (when applicable) continues working

---

## Testing & Validation

- [ ] Script test with manual JSON input shows correct format
- [ ] New Claude Code session shows Unicode progress bar
- [ ] `/tmp/claude-context.json` file is still generated correctly
- [ ] Neovim lualine extension (if active) still works

## Artifacts & Outputs

- plans/implementation-002.md (this file, revised)
- summaries/implementation-summary-YYYYMMDD.md (after completion)

## Rollback/Contingency

Rollback is trivial - restore the original loop in statusline-push.sh:
```bash
for ((i=0; i<bar_filled; i++)); do bar+="[=]"; done
for ((i=0; i<bar_empty; i++)); do bar+="[-]"; done
# And restore brackets in printf:
printf "%d%% [%s] %dk/%dk | %s | %s" ...
```

Git revert is straightforward since the change is isolated to one file.

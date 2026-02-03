# Research Report: Task #34

**Task**: 34 - statusline_display_best_practices
**Started**: 2026-02-03T12:00:00Z
**Completed**: 2026-02-03T12:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Plugin docs, community examples, Unicode standards, lualine documentation
**Artifacts**: specs/034_statusline_display_best_practices/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- Current `[[-][-][-]]` progress bar notation is visually cluttered and should be replaced with Unicode block characters
- Unicode block elements (U+2588-U+258F) provide smooth 1/8th increments for progress visualization
- Information density can be improved by removing redundant visual elements and using compact formats
- Color thresholds (50%/80%) are appropriate; consider adding intermediate gradient colors
- Recommended format: `42% ████░░░░░░ 85k/200k | Sonnet 4.5 | $0.31`

## Context & Scope

Research focused on best practices for displaying Claude Code context usage information in Neovim's lualine statusline. Current implementation shows:
```
30% [[=][=][=][-][-][-][-][-][-][-]] 60k/200k | Sonnet 4.5 | $9.74
```

Goals:
1. Identify optimal Unicode characters for progress bars
2. Determine compact information display patterns
3. Research color coding conventions for usage thresholds
4. Examine AI tool statusline integrations

## Findings

### Existing Configuration Analysis

The current implementation in `/home/benjamin/.config/nvim/lua/neotex/util/claude-context.lua` already includes:
- Progress bar generation with `get_progress_bar(width)` using `string.rep("█", filled) .. string.rep("░", empty)`
- Color thresholds: green (<50%), yellow (50-80%), red (>80%)
- Token formatting with k-suffix abbreviation

The issue is in the extension file (`claude-code.lua`) which wraps the bar in brackets: `string.format("%s [%s] %s", pct_str, bar, tokens)`

### Unicode Progress Bar Characters

**Primary Block Elements (U+2588-U+258F)** - Recommended for high-resolution progress:
| Code | Char | Width |
|------|------|-------|
| U+2588 | `█` | Full block (100%) |
| U+2589 | `▉` | 7/8 block |
| U+258A | `▊` | 3/4 block |
| U+258B | `▋` | 5/8 block |
| U+258C | `▌` | Half block |
| U+258D | `▍` | 3/8 block |
| U+258E | `▎` | 1/4 block |
| U+258F | `▏` | 1/8 block |

**Shade Characters** - Alternative for simpler displays:
| Code | Char | Usage |
|------|------|-------|
| U+2591 | `░` | Light shade (empty) |
| U+2592 | `▒` | Medium shade |
| U+2593 | `▓` | Dark shade |
| U+2588 | `█` | Full block (filled) |

**Compact Alternatives**:
- `▱▰` - Outlined/filled rectangles (minimal width)
- `○◐●` - Circle fill progression (3 states)
- `⬜⬛` - White/black squares

**Sources**: [Mike42 CLI Progress Bars](https://mike42.me/blog/2018-06-make-better-cli-progress-bars-with-unicode-block-characters), [Unicode Progress Bars](https://changaco.oy.lc/unicode-progress-bars/)

### Lualine Best Practices

**Component Structure**:
```lua
{
  function() return formatted_string end,
  color = function()
    -- Dynamic color based on thresholds
    return { fg = color_hex, gui = "bold" }
  end,
  cond = function() return has_data end,
}
```

**Information Density Recommendations**:
1. Remove redundant brackets around progress bar
2. Use single separator character (`|` or space) between elements
3. Consider combining percentage with progress bar (redundant info)
4. Use compact number formatting (85k not 85000)

**Refresh Rate**: Current 1000ms is appropriate; avoid faster rates for non-critical info.

**Sources**: [lualine.nvim GitHub](https://github.com/nvim-lualine/lualine.nvim), [LazyVim UI Configuration](http://www.lazyvim.org/plugins/ui)

### AI Tool Statusline Patterns

**Copilot Status Plugins** display states using icons:
- Idle: ` ` (simple icon)
- Loading: ` ` (spinner animation)
- Error: ` ` (warning icon)
- Enabled/Disabled toggle states

**ccstatusline for Claude Code** displays:
- Progress bars: 32-char full or 16-char compact modes
- Token breakdown: input/output/cached/total
- Model name: "Claude 3.5 Sonnet" format
- Session cost: USD with currency symbol
- Dynamic context limits (1M for Sonnet 4.5, 200k otherwise)

**Key Insight**: Most AI statusline integrations focus on connection state rather than token usage. Token/cost display is less common but increasingly valuable for cost-aware users.

**Sources**: [copilot-status.nvim](https://github.com/jonahgoldwastaken/copilot-status.nvim), [ccstatusline](https://github.com/sirmalloc/ccstatusline)

### Color Coding Conventions

**Standard Threshold Pattern** (traffic light model):
| Level | Color | Hex Example | Threshold |
|-------|-------|-------------|-----------|
| Low | Green | #98c379 | 0-50% |
| Medium | Yellow/Orange | #e5c07b | 50-80% |
| High | Red | #e06c75 | 80-100% |

**Accessibility Considerations**:
- 8% of males have red-green color vision deficiency
- Always pair color with another indicator (bold text, icon change)
- Bloomberg recommends avoiding pure color-only semantic meaning

**Enhanced Gradient** (optional):
| Range | Color | Meaning |
|-------|-------|---------|
| 0-30% | Bright green | Plenty of room |
| 30-50% | Dim green | Normal usage |
| 50-70% | Yellow | Moderate usage |
| 70-85% | Orange | Approaching limit |
| 85-100% | Red | Near capacity |

**Sources**: [Bloomberg Accessibility](https://www.bloomberg.com/company/stories/designing-the-terminal-for-color-accessibility/), [Terminal Colors](https://jvns.ca/blog/2024/10/01/terminal-colours/)

### Nerd Font Icons for Enhancement

Relevant icons from Nerd Fonts:
| Icon | Name | Usage |
|------|------|-------|
| `󰧑` | nf-md-brain | AI indicator |
| `󰊤` | nf-md-memory | Token/context |
| `$` | Dollar sign | Cost display |
| `󰄉` | nf-md-percent | Percentage |
| `` | Battery icons | Capacity levels |

**Source**: [Nerd Fonts Cheat Sheet](https://www.nerdfonts.com/cheat-sheet)

## Recommendations

### Recommended Display Format

**Option A - Compact with Progress Bar** (recommended):
```
42% ████░░░░░░ 85k/200k | Sonnet 4.5 | $0.31
```
- Width: ~42 characters
- Clear visual progress indicator
- All key metrics visible

**Option B - Ultra-Compact**:
```
42% 85k/200k | Sonnet 4.5 | $0.31
```
- Width: ~32 characters
- Percentage implies progress
- Better for narrow terminals

**Option C - Icon-Enhanced**:
```
󰧑 42% ████░░░░░░ 85k | Sonnet 4.5 | $0.31
```
- AI icon prefix for identification
- Limit-only shown (limit is fixed per model)
- Width: ~40 characters

### Implementation Changes

1. **Remove bracket wrapper** in `claude-code.lua`:
   ```lua
   -- Before
   return string.format("%s [%s] %s", pct_str, bar, tokens)
   -- After
   return string.format("%s %s %s", pct_str, bar, tokens)
   ```

2. **Consider fractional blocks** for smoother progress:
   ```lua
   local block_chars = { "░", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█" }
   ```

3. **Add bold styling** to percentage at high usage:
   ```lua
   color = function()
     local level = ctx_module.get_usage_level()
     local gui = level == "high" and "bold" or nil
     return { fg = get_usage_color(level), gui = gui }
   end
   ```

4. **Optional: Adaptive width** based on terminal size

### Alternative: Segmented Progress Bar

Instead of continuous blocks, use discrete segments for cleaner appearance:
```
42% [==----------] 85k/200k
```
Using `=` for filled and `-` for empty (current style without nested brackets)

Or with Unicode:
```
42% ██▓░░░░░░░░ 85k/200k
```
Using partial blocks at the boundary

## Decisions

1. **Progress bar style**: Use simple `█░` blocks without surrounding brackets
2. **Width**: 10 characters for progress bar (current width is appropriate)
3. **Color thresholds**: Keep current 50%/80% thresholds
4. **Format order**: percentage -> bar -> tokens -> model -> cost (current order is intuitive)
5. **Separators**: Use pipe with spaces ` | ` between major sections

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Unicode rendering issues | Test in multiple terminal emulators; provide ASCII fallback |
| Color accessibility | Bold text at high usage provides secondary indicator |
| Information overflow on narrow terminals | Consider hiding bar or tokens when window < threshold |
| Performance impact | Current 1000ms refresh is sufficient; no change needed |

## Appendix

### Search Queries Used
- "lualine nvim progress bar unicode characters statusline 2025"
- "neovim statusline AI copilot token usage display format"
- "terminal progress bar unicode block characters best practices"
- "neovim lualine compact statusline information density"
- "powerline symbols nerdfont icons progress percentage statusline"

### Key References
- [lualine.nvim Documentation](https://github.com/nvim-lualine/lualine.nvim)
- [Unicode Block Elements](https://mike42.me/blog/2018-06-make-better-cli-progress-bars-with-unicode-block-characters)
- [Unicode Progress Bars Generator](https://changaco.oy.lc/unicode-progress-bars/)
- [ccstatusline for Claude Code](https://github.com/sirmalloc/ccstatusline)
- [Nerd Fonts Cheat Sheet](https://www.nerdfonts.com/cheat-sheet)
- [Bloomberg Terminal Accessibility](https://www.bloomberg.com/company/stories/designing-the-terminal-for-color-accessibility/)

### Current Implementation Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/lualine/extensions/claude-code.lua` - Extension config
- `/home/benjamin/.config/nvim/lua/neotex/util/claude-context.lua` - Context reader module
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/lualine.lua` - Main lualine config

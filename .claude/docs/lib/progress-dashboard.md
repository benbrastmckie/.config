# progress-dashboard.sh

Progress dashboard rendering utility for real-time visual feedback during implementation workflows.

## Overview

`progress-dashboard.sh` provides a professional progress visualization system with:
- **Terminal capability detection** - Automatically detects ANSI support
- **ANSI rendering** - In-place updates using ANSI escape codes
- **Unicode box-drawing** - Professional layout with Unicode characters
- **Graceful fallback** - Falls back to PROGRESS markers on unsupported terminals
- **Parallel execution support** - Wave-based execution visualization

## Features

### Terminal Capability Detection

Automatically detects terminal capabilities and selects the best rendering mode:

```bash
capabilities=$(detect_terminal_capabilities)
# Returns JSON: {"ansi_supported": true/false, "reason": "...", "colors": N}
```

**Detection checks:**
1. `$TERM` environment variable (rejects "dumb" terminals)
2. Interactive shell (`-t 1` test)
3. `tput` availability
4. Color support (requires ≥8 colors)

**Fallback reasons:**
- `dumb_terminal` - TERM=dumb or unset
- `non_interactive` - Not connected to a TTY
- `tput_missing` - tput command not found
- `insufficient_colors` - Less than 8 colors available

### ANSI Rendering Mode

When terminal supports ANSI codes, renders an in-place updating dashboard:

```
┌───────────────────────────────────────────────────────────────┐
│ Implementation Progress: Authentication System                 │
├───────────────────────────────────────────────────────────────┤
│ Phase 1: Setup..................... ✓ Complete                │
│ Phase 2: Implementation............ → In Progress             │
│ Phase 3: Testing................... ⬚ Pending                 │
├───────────────────────────────────────────────────────────────┤
│ Progress: [████████████░░░░░░░░] 40% (2/5 phases)            │
│ Elapsed: 5m 23s  |  Estimated Remaining: ~8m 12s             │
├───────────────────────────────────────────────────────────────┤
│ Current Task: Running integration tests                       │
│ Last Test: auth_module_test........ ✓ PASS                   │
├───────────────────────────────────────────────────────────────┤
│ Wave Info: Wave 2 of 3 (2 phases) - Parallel                 │
└───────────────────────────────────────────────────────────────┘
```

**Features:**
- **Phase status tracking** - Visual indicators for each phase
- **Progress bar** - Percentage and count display
- **Time estimates** - Elapsed and estimated remaining time
- **Test results** - Last test status with color coding
- **Wave information** - Parallel execution visualization

### Fallback Mode

On unsupported terminals, uses traditional PROGRESS markers:

```
PROGRESS: Phase 2/5 - Authentication System
```

## Usage

### Basic Integration

```bash
#!/usr/bin/env bash
source .claude/lib/progress-dashboard.sh

# Initialize dashboard (reserves screen space)
initialize_dashboard "My Implementation Plan" 5

# Update phase status
update_dashboard_phase 2 "in_progress" "Installing dependencies"

# Render full dashboard with all details
render_dashboard \
  "My Plan" \
  2 \
  5 \
  '[{"number":1,"name":"Setup","status":"completed"},{"number":2,"name":"Implementation","status":"in_progress"}]' \
  323 \
  492 \
  "Running tests" \
  '{"name":"auth_test","status":"pass"}' \
  '{"wave_num":2,"total_waves":3,"phases_in_wave":2,"parallel":true}'

# Clear dashboard on completion
clear_dashboard
```

### Integration with /implement

The dashboard is automatically used by `/implement` when the `--dashboard` flag is provided:

```bash
/implement plan.md --dashboard
```

**Behavior:**
1. Detects terminal capabilities on startup
2. Initializes dashboard if ANSI supported
3. Updates in-place during phase execution
4. Falls back to PROGRESS markers if not supported
5. Clears dashboard on completion or error

### Terminal Compatibility

**Supported terminals:**
- bash with TERM=xterm-256color
- zsh with color support
- tmux with 256 colors
- screen with color support
- iTerm2, Terminal.app (macOS)
- GNOME Terminal, Konsole (Linux)

**Unsupported terminals:**
- Emacs shell (`TERM=dumb`)
- Non-interactive contexts (pipes, redirects)
- Terminals without tput
- Terminals with <8 colors

## API Reference

### detect_terminal_capabilities()

Detects terminal support for ANSI rendering.

**Returns:** JSON object
```json
{
  "ansi_supported": true,
  "colors": 256,
  "reason": "full_support"
}
```

**Usage:**
```bash
caps=$(detect_terminal_capabilities)
ansi_supported=$(echo "$caps" | jq -r '.ansi_supported')
```

---

### render_dashboard()

Renders the complete dashboard with all information.

**Parameters:**
1. `plan_name` - Implementation plan name
2. `current_phase` - Current phase number (1-indexed)
3. `total_phases` - Total number of phases
4. `phase_list` - JSON array of phase info
5. `elapsed_seconds` - Elapsed time in seconds
6. `estimated_remaining` - Estimated remaining seconds
7. `current_task` - Description of current task
8. `last_test_result` - JSON: `{"name": "test_name", "status": "pass|fail"}`
9. `wave_info` - JSON: `{"wave_num": N, "total_waves": N, "phases_in_wave": N, "parallel": true/false}`

**Phase list format:**
```json
[
  {"number": 1, "name": "Setup", "status": "completed"},
  {"number": 2, "name": "Implementation", "status": "in_progress"},
  {"number": 3, "name": "Testing", "status": "pending"}
]
```

**Phase status values:**
- `completed` - Phase finished successfully
- `in_progress` - Phase currently executing
- `pending` - Phase not yet started
- `skipped` - Phase skipped
- `failed` - Phase failed

---

### initialize_dashboard()

Initializes dashboard by reserving screen space.

**Parameters:**
1. `plan_name` - Implementation plan name
2. `total_phases` - Total number of phases

**Usage:**
```bash
initialize_dashboard "Authentication System" 5
```

**Note:** Prints 11 empty lines to reserve space for dashboard updates.

---

### update_dashboard_phase()

Updates phase status (placeholder for state management).

**Parameters:**
1. `phase_num` - Phase number to update
2. `phase_status` - New status (completed|in_progress|pending|skipped|failed)
3. `current_task` - Description of current task

**Usage:**
```bash
update_dashboard_phase 2 "in_progress" "Running integration tests"
```

---

### clear_dashboard()

Clears dashboard area on completion or error.

**Usage:**
```bash
clear_dashboard
```

**Behavior:** Moves cursor up 11 lines and clears each line.

---

### render_progress_markers()

Fallback rendering using traditional PROGRESS markers.

**Parameters:**
1. `plan_name` - Plan name
2. `current_phase` - Current phase number
3. `total_phases` - Total phases

**Output:**
```
PROGRESS: Phase 2/5 - Authentication System
```

## ANSI Escape Codes Reference

### Cursor Movement

- `\033[{n}A` - Move cursor up n lines
- `\033[{n}B` - Move cursor down n lines
- `\033[{n}C` - Move cursor right n columns
- `\033[{n}D` - Move cursor left n columns
- `\033[s` - Save cursor position
- `\033[u` - Restore cursor position
- `\033[H` - Move cursor to home (0,0)

### Screen Manipulation

- `\033[2J` - Clear entire screen
- `\033[2K` - Clear entire line
- `\033[0J` - Clear from cursor to end of screen

### Colors (Foreground)

- `\033[30m` - Black
- `\033[31m` - Red
- `\033[32m` - Green
- `\033[33m` - Yellow
- `\033[34m` - Blue
- `\033[35m` - Magenta
- `\033[36m` - Cyan
- `\033[37m` - White
- `\033[0m` - Reset

### Text Formatting

- `\033[1m` - Bold
- `\033[2m` - Dim
- `\033[4m` - Underline

## Unicode Box-Drawing Characters

```
┌─┬─┐  Top row: TL, H, T, H, TR
├─┼─┤  Middle:  ML, H, C, H, MR
└─┴─┘  Bottom:  BL, H, B, H, BR
```

**Characters used:**
- `┌` (U+250C) - Top-left corner
- `┐` (U+2510) - Top-right corner
- `└` (U+2514) - Bottom-left corner
- `┘` (U+2518) - Bottom-right corner
- `─` (U+2500) - Horizontal line
- `│` (U+2502) - Vertical line
- `├` (U+251C) - Middle-left
- `┤` (U+2524) - Middle-right

## Status Icons

- `✓` (U+2713) - Complete
- `→` (U+2192) - In Progress
- `⬚` (U+2B1A) - Pending
- `⊘` (U+2298) - Skipped
- `✗` (U+2717) - Failed

## Integration Examples

### With Checkpoint State

```bash
# Load checkpoint
checkpoint=$(restore_checkpoint "implement" "my_project")
current_phase=$(echo "$checkpoint" | jq -r '.current_phase')
total_phases=$(echo "$checkpoint" | jq -r '.total_phases')

# Initialize dashboard
initialize_dashboard "My Project" "$total_phases"

# Update from checkpoint
update_dashboard_phase "$current_phase" "in_progress" "Resuming from checkpoint"
```

### With Wave-Based Execution

```bash
# During parallel phase execution
wave_info='{
  "wave_num": 2,
  "total_waves": 3,
  "phases_in_wave": 2,
  "parallel": true
}'

render_dashboard \
  "My Plan" \
  "$current_phase" \
  "$total_phases" \
  "$phase_list" \
  "$elapsed" \
  "$remaining" \
  "Executing phases 2 and 3 in parallel" \
  "$test_result" \
  "$wave_info"
```

### With Test Results

```bash
# After running tests
test_result='{"name":"integration_test_suite","status":"pass"}'

render_dashboard \
  "$plan_name" \
  "$current_phase" \
  "$total_phases" \
  "$phase_list" \
  "$elapsed" \
  "$remaining" \
  "All tests passed" \
  "$test_result" \
  '{}'
```

## Performance Considerations

- **Minimal overhead** - Only rerenders when state changes
- **Efficient ANSI codes** - Uses cursor positioning instead of clearing screen
- **Automatic fallback** - No performance penalty on unsupported terminals
- **No flickering** - Cursor save/restore prevents visual glitches

## Troubleshooting

### Dashboard not rendering

**Check:**
1. Is `--dashboard` flag provided?
2. Is terminal interactive? (test with `[[ -t 1 ]]`)
3. Is `$TERM` set correctly?
4. Is `tput` available?
5. Does terminal support ≥8 colors? (test with `tput colors`)

**Debug:**
```bash
source .claude/lib/progress-dashboard.sh
caps=$(detect_terminal_capabilities)
echo "$caps" | jq .
```

### Rendering artifacts

**Causes:**
- Terminal size changed during rendering
- Output from other processes
- Signal interruption

**Solutions:**
- Clear and re-render: `clear_dashboard && initialize_dashboard ...`
- Use fallback mode: Set `TERM=dumb` to force PROGRESS markers

### Unicode characters not displaying

**Cause:** Terminal doesn't support UTF-8

**Solution:** Ensure `$LANG` is set to UTF-8 locale:
```bash
export LANG=en_US.UTF-8
```

## Related

- `checkpoint-utils.sh` - State management for dashboard updates
- `workflow-metrics.sh` - Performance metrics displayed in dashboard
- `/implement` command - Primary consumer of dashboard
- `/orchestrate` command - Uses dashboard for multi-agent workflows

## Version

Added in Plan 043 Phase 3 (2025-10-13)

Schema: Dashboard rendering v1.0

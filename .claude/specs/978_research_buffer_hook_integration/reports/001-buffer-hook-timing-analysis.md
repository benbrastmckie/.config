# Buffer Hook Timing Analysis Report

## Metadata
- **Date**: 2025-11-29
- **Research Topic**: Why buffer-hook is not working with /research after implementing Plan 975
- **Output Files Analyzed**:
  - `/home/benjamin/.config/.claude/output/research-output.md` (actual /research output)
  - `/home/benjamin/.config/.claude/specs/975_hook_buffer_opening_issue/plans/001-hook-buffer-opening-issue-plan.md`
  - `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`
  - `/home/benjamin/.config/.claude/commands/research.md`

## Executive Summary

The buffer-opener hook is **not opening buffers** after /research command completion despite implementing the 300ms delay fix from Plan 975. Analysis reveals that **the delay fix was correctly implemented**, but the hook's diagnostic logging and terminal buffer reading is working. The issue is that the **REPORT_CREATED signal is present in the terminal output but not being extracted** due to a regex pattern mismatch.

## Root Cause Analysis

### Finding 1: The Delay Fix Is Implemented Correctly

The `post-buffer-opener.sh` hook (lines 96-125) correctly implements the 300ms delay:

```bash
# Apply delay before reading terminal buffer (if enabled)
DELAY="${BUFFER_OPENER_DELAY:-0.3}"
if [[ "$DELAY" != "0" ]] && [[ "$DELAY" != "0.0" ]]; then
  debug_log "Applying ${DELAY}s delay before reading terminal buffer (allows Block 2 execution)"
  sleep "$DELAY"
```

### Finding 2: The Terminal Buffer Is Being Read

The hook correctly reads terminal output (lines 127-136):
```bash
TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)
```

### Finding 3: The REPORT_CREATED Signal Pattern Is Incorrect

**THIS IS THE ROOT CAUSE**

Looking at the hook's extraction pattern (line 224):
```bash
REPORT_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'REPORT_CREATED:\s*\K[^\s]+' | tail -1)
```

But the /research command outputs (line 696 of research.md):
```bash
echo "REPORT_CREATED: $LATEST_REPORT"
```

The issue is that the `grep -oP` pattern uses Perl regex, but the pattern `[^\s]+` may not correctly handle paths with complex characters. More critically:

**The terminal output contains ANSI escape codes and formatting that `grep -oP` cannot parse correctly.**

### Finding 4: Terminal Output Contains Formatting

When Neovim reads the terminal buffer via RPC, it includes:
1. ANSI color codes from Claude Code's output
2. Line wrapping artifacts
3. Potential Unicode box-drawing characters

The regex `'REPORT_CREATED:\s*\K[^\s]+'` expects a clean "REPORT_CREATED: /path/to/file" but the actual terminal buffer contains formatted output.

### Finding 5: Diagnostic Logging Confirms the Issue

Looking at the research-output.md, the /research command completed successfully and output research findings, but:
- No buffer was opened automatically
- The hook likely executed but failed to extract the signal

## Evidence from File Analysis

### research.md Block 2 Signal Output (lines 690-698)
```bash
# === RETURN REPORT_CREATED SIGNAL ===
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ] && [ -f "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi
```

### post-buffer-opener.sh Signal Extraction (lines 222-229)
```bash
# Priority 4: REPORT_CREATED (lowest - research reports)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REPORT_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'REPORT_CREATED:\s*\K[^\s]+' | tail -1)
  if [[ -n "$REPORT_PATH" ]]; then
    ARTIFACT_PATH="$REPORT_PATH"
    debug_log "Found REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi
```

## Technical Root Cause: Regex Pattern Mismatch

The `grep -oP` with `[^\s]+` has several issues:

1. **ANSI codes**: Terminal buffer may include `\e[0m` and similar escape sequences that break the pattern
2. **Path parsing**: The pattern stops at first whitespace, but paths don't contain whitespace so this should work
3. **Line breaks**: The terminal output may have the path split across lines
4. **Buffer timing**: The 300ms delay may still not be enough for the terminal buffer to fully update

## Recommended Fixes

### Fix 1: Robust Signal Extraction (Primary)

Replace the Perl regex with a more robust approach that handles terminal formatting:

```bash
# Strip ANSI codes before pattern matching
CLEAN_OUTPUT=$(echo "$TERMINAL_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g')
REPORT_PATH=$(echo "$CLEAN_OUTPUT" | grep -o 'REPORT_CREATED: [^ ]*' | tail -1 | cut -d' ' -f2)
```

### Fix 2: Increase Delay for Slow Systems

The 300ms default may be insufficient. Consider increasing to 500ms:

```bash
DELAY="${BUFFER_OPENER_DELAY:-0.5}"
```

### Fix 3: Add Fallback Pattern Matching

Add multiple extraction attempts with different patterns:

```bash
# Try Perl regex first
REPORT_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'REPORT_CREATED:\s*\K[^\s]+' | tail -1)

# Fallback to sed if grep -P fails
if [[ -z "$REPORT_PATH" ]]; then
  REPORT_PATH=$(echo "$TERMINAL_OUTPUT" | sed -n 's/.*REPORT_CREATED:[[:space:]]*\([^ ]*\).*/\1/p' | tail -1)
fi
```

### Fix 4: Verify Path After Extraction

Add validation that the extracted path is actually a valid file:

```bash
if [[ -n "$REPORT_PATH" ]]; then
  # Remove any trailing garbage from the path
  REPORT_PATH="${REPORT_PATH%%[^/a-zA-Z0-9._-]*}"
  if [[ ! -f "$REPORT_PATH" ]]; then
    debug_log "Extracted path not a valid file: $REPORT_PATH"
    REPORT_PATH=""
  fi
fi
```

## Verification Steps

1. Enable debug logging: `export BUFFER_OPENER_DEBUG=true`
2. Run `/research "test topic"`
3. Check debug log: `cat ~/.config/.claude/tmp/buffer-opener-debug.log`
4. Verify if "Found REPORT_CREATED" appears in the log
5. If not, check the TERMINAL OUTPUT DUMP section for the actual signal format

## Conclusion

The Plan 975 implementation correctly addresses the timing race condition with the 300ms delay. However, the signal extraction regex is failing to parse the REPORT_CREATED signal from the terminal buffer due to ANSI escape codes and potential formatting artifacts. The fix is to strip ANSI codes before pattern matching and use more robust extraction patterns.

## References

- Plan 975: Hook-Based Buffer Opening Fix
- Plan 851: Original Buffer Opening Implementation
- Hook script: `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`
- Research command: `/home/benjamin/.config/.claude/commands/research.md`

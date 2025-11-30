# Buffer Hook Signal Extraction Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Fix buffer-opener hook signal extraction for /research command
- **Scope**: Repair signal extraction regex to handle terminal formatting artifacts
- **Estimated Phases**: 3
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 24.0
- **Research Reports**:
  - [Buffer Hook Timing Analysis](../reports/001-buffer-hook-timing-analysis.md)

## Overview

Plan 975 correctly implemented the 300ms delay to address the Stop hook timing race condition. However, the buffer-opener hook is still not opening buffers after /research command completion. The root cause is that the **signal extraction regex fails to parse REPORT_CREATED from terminal output** due to ANSI escape codes and formatting artifacts embedded in the Neovim terminal buffer.

This plan implements robust signal extraction that strips ANSI codes before pattern matching and uses multiple fallback patterns for reliability.

## Research Summary

Key findings from the timing analysis report:

**Root Cause**: The `grep -oP 'REPORT_CREATED:\s*\K[^\s]+'` pattern fails because:
1. Terminal buffer contains ANSI escape codes (`\e[0m`, etc.)
2. The Perl regex doesn't handle these embedded codes
3. The path extraction stops early or returns empty

**Solution**: Strip ANSI codes before pattern matching, use robust sed-based extraction as fallback, and validate extracted paths.

## Success Criteria

**Phase 1 - ANSI Code Stripping**:
- [ ] Terminal output is cleaned of all ANSI escape sequences before pattern matching
- [ ] Debug log shows clean output in diagnostic dump

**Phase 2 - Robust Signal Extraction**:
- [ ] REPORT_CREATED signal extracted successfully from /research output
- [ ] PLAN_CREATED signal extracted successfully from /plan output
- [ ] Multiple fallback patterns ensure reliability
- [ ] Extracted paths are validated as existing files

**Phase 3 - Verification and Documentation**:
- [ ] /research command buffer opens automatically
- [ ] /plan command buffer opens automatically
- [ ] Debug logging shows extraction success
- [ ] Hooks README updated with troubleshooting guidance

## Technical Design

### Architecture Overview

The fix modifies only `post-buffer-opener.sh` without changing any workflow commands:

```
Current Flow (Broken):
1. Hook reads terminal buffer (with ANSI codes)
2. grep -oP tries to match pattern
3. ANSI codes break pattern matching → extraction fails
4. No buffer opens

Fixed Flow:
1. Hook reads terminal buffer (with ANSI codes)
2. Strip ANSI escape codes from output
3. Apply pattern matching on clean output
4. Use fallback patterns if primary fails
5. Validate extracted path exists
6. Open buffer if valid
```

### Component Changes

**File**: `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`

**Change 1**: Add ANSI stripping function (after line 55)
```bash
# Strip ANSI escape codes from input for reliable pattern matching
strip_ansi() {
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}
```

**Change 2**: Clean terminal output before extraction (after line 136)
```bash
# Clean terminal output for pattern matching
CLEAN_OUTPUT=$(echo "$TERMINAL_OUTPUT" | strip_ansi)
debug_log "Cleaned output (${#CLEAN_OUTPUT} chars after ANSI removal)"
```

**Change 3**: Update signal extraction to use clean output and fallback patterns (lines 181-229)
- Use `CLEAN_OUTPUT` instead of `TERMINAL_OUTPUT` for all pattern matching
- Add sed-based fallback for each signal type
- Add path validation after extraction

### Technology Choices

- **sed for ANSI stripping**: Portable, no dependencies, reliable
- **Multiple extraction patterns**: Primary (grep -oP) + fallback (sed) ensures reliability
- **Path validation**: Prevents opening non-existent files
- **No command changes**: Maintains Plan 851/975 architecture

## Implementation Phases

### Phase 1: Add ANSI Code Stripping [NOT STARTED]
dependencies: []

**Objective**: Add function to strip ANSI escape codes from terminal output before pattern matching

**Complexity**: Low

Tasks:
- [ ] Add `strip_ansi()` function after debug_log function (line 55)
- [ ] Add CLEAN_OUTPUT variable after TERMINAL_OUTPUT capture (line 137)
- [ ] Add debug log entry showing cleaned character count
- [ ] Test ANSI stripping with various terminal output formats

**Code Changes**:

After line 55, add:
```bash
# Strip ANSI escape codes from input for reliable pattern matching
# Handles: colors (\e[31m), cursor movement (\e[1A), reset (\e[0m), etc.
strip_ansi() {
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | sed 's/\x1b\][0-9]*;[^\x07]*\x07//g'
}
```

After line 136, add:
```bash
# Strip ANSI codes for reliable pattern matching
CLEAN_OUTPUT=$(echo "$TERMINAL_OUTPUT" | strip_ansi)
debug_log "Cleaned terminal output (${#CLEAN_OUTPUT} chars, removed $((${#TERMINAL_OUTPUT} - ${#CLEAN_OUTPUT})) ANSI bytes)"
```

**Expected Duration**: 20 minutes

### Phase 2: Implement Robust Signal Extraction [NOT STARTED]
dependencies: [1]

**Objective**: Update all signal extraction patterns to use cleaned output and add fallback extraction methods

**Complexity**: Medium

Tasks:
- [ ] Update PLAN_CREATED extraction to use CLEAN_OUTPUT with fallback
- [ ] Update PLAN_REVISED extraction to use CLEAN_OUTPUT with fallback
- [ ] Update summary_path extraction to use CLEAN_OUTPUT with fallback
- [ ] Update DEBUG_REPORT_CREATED extraction to use CLEAN_OUTPUT with fallback
- [ ] Update REPORT_CREATED extraction to use CLEAN_OUTPUT with fallback
- [ ] Add path validation after each extraction
- [ ] Test all signal types with actual command output

**Code Changes**:

Replace extraction block (lines 181-229) with robust versions:

```bash
# === Extract completion signals with priority logic ===
# Priority 1: PLAN_CREATED or PLAN_REVISED (highest)
ARTIFACT_PATH=""

# Function to extract path with fallback patterns
extract_signal_path() {
  local signal_name="$1"
  local input="$2"
  local path=""

  # Primary: Perl regex
  path=$(echo "$input" | grep -oP "${signal_name}:\s*\K[^\s]+" 2>/dev/null | tail -1)

  # Fallback: sed-based extraction
  if [[ -z "$path" ]]; then
    path=$(echo "$input" | sed -n "s/.*${signal_name}:[[:space:]]*\([^[:space:]]*\).*/\1/p" | tail -1)
  fi

  # Validate path exists
  if [[ -n "$path" ]] && [[ -f "$path" ]]; then
    echo "$path"
  else
    # Path doesn't exist, might have trailing garbage
    local cleaned_path="${path%%[^/a-zA-Z0-9._-]*}"
    if [[ -n "$cleaned_path" ]] && [[ -f "$cleaned_path" ]]; then
      echo "$cleaned_path"
    fi
  fi
}

# Check for PLAN_CREATED (highest priority)
if [[ -z "$ARTIFACT_PATH" ]]; then
  PLAN_PATH=$(extract_signal_path "PLAN_CREATED" "$CLEAN_OUTPUT")
  if [[ -n "$PLAN_PATH" ]]; then
    ARTIFACT_PATH="$PLAN_PATH"
    debug_log "Found PLAN_CREATED: $ARTIFACT_PATH"
  fi
fi

# Check for PLAN_REVISED (same priority as PLAN_CREATED)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REVISED_PATH=$(extract_signal_path "PLAN_REVISED" "$CLEAN_OUTPUT")
  if [[ -n "$REVISED_PATH" ]]; then
    ARTIFACT_PATH="$REVISED_PATH"
    debug_log "Found PLAN_REVISED: $ARTIFACT_PATH"
  fi
fi

# Priority 2: IMPLEMENTATION_COMPLETE with summary_path (for /build)
if [[ -z "$ARTIFACT_PATH" ]]; then
  SUMMARY_PATH=$(extract_signal_path "summary_path" "$CLEAN_OUTPUT")
  if [[ -n "$SUMMARY_PATH" ]]; then
    ARTIFACT_PATH="$SUMMARY_PATH"
    debug_log "Found summary_path: $ARTIFACT_PATH"
  fi
fi

# Priority 3: DEBUG_REPORT_CREATED
if [[ -z "$ARTIFACT_PATH" ]]; then
  DEBUG_PATH=$(extract_signal_path "DEBUG_REPORT_CREATED" "$CLEAN_OUTPUT")
  if [[ -n "$DEBUG_PATH" ]]; then
    ARTIFACT_PATH="$DEBUG_PATH"
    debug_log "Found DEBUG_REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi

# Priority 4: REPORT_CREATED (lowest - research reports)
if [[ -z "$ARTIFACT_PATH" ]]; then
  REPORT_PATH=$(extract_signal_path "REPORT_CREATED" "$CLEAN_OUTPUT")
  if [[ -n "$REPORT_PATH" ]]; then
    ARTIFACT_PATH="$REPORT_PATH"
    debug_log "Found REPORT_CREATED: $ARTIFACT_PATH"
  fi
fi
```

**Expected Duration**: 45 minutes

### Phase 3: Verification and Documentation [NOT STARTED]
dependencies: [2]

**Objective**: Verify the fix works for all workflow commands and update documentation

**Complexity**: Low

Tasks:
- [ ] Test /research with BUFFER_OPENER_DEBUG=true
- [ ] Verify debug log shows "Found REPORT_CREATED: /path"
- [ ] Verify buffer opens automatically after /research
- [ ] Test /plan and verify buffer opens automatically
- [ ] Update hooks README with ANSI stripping details
- [ ] Add troubleshooting entry for signal extraction failures
- [ ] Run regression tests on other hooks (metrics, TTS)

Testing:
```bash
# Enable debug mode
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0.3

# Test /research
# In Neovim terminal: /research "test buffer opening"
# Check: cat ~/.config/.claude/tmp/buffer-opener-debug.log
# Expected: "Found REPORT_CREATED: /path/to/report.md"

# Test /plan
# In Neovim terminal: /plan "test feature"
# Expected: "Found PLAN_CREATED: /path/to/plan.md"
```

Documentation Updates:
- Add "ANSI Code Handling" section to hooks README
- Add troubleshooting for "Signal found but path invalid" errors
- Update Plan 975 with reference to this fix

**Expected Duration**: 30 minutes

## Testing Strategy

### Phase 1 Testing
- Verify strip_ansi function removes common ANSI codes
- Test with actual Neovim terminal buffer output
- Confirm no data loss during stripping

### Phase 2 Testing
- Test each signal type extraction with known good paths
- Test extraction with paths containing special characters (spaces, dots)
- Test fallback pattern activation when primary fails
- Test path validation rejects invalid paths

### Phase 3 Testing
- End-to-end testing of /research buffer opening
- End-to-end testing of /plan buffer opening
- Regression testing of existing hook functionality
- Performance testing (ensure delay + processing < 1s)

## Dependencies

### Internal Dependencies
- Existing post-buffer-opener.sh hook (Plan 851/975)
- Workflow commands outputting completion signals

### External Dependencies
- sed command (standard Unix utility)
- Neovim RPC API (existing dependency)

## Risk Assessment

### Low Risk
- **All changes isolated to post-buffer-opener.sh**: No command modifications
- **Backward compatible**: Existing patterns retained as primary, fallbacks added
- **Easy rollback**: Single file change, git revert if needed

### Mitigation Strategies
- Test each change incrementally with debug logging
- Keep existing regex patterns as primary (add fallbacks, don't replace)
- Validate paths before opening to prevent errors

## Rollback Plan

If the fix introduces issues:

1. **Quick disable**: `export BUFFER_OPENER_ENABLED=false`
2. **Git revert**: `git checkout HEAD~1 .claude/hooks/post-buffer-opener.sh`
3. **Selective rollback**: Remove only the strip_ansi changes if fallback patterns work

## Success Metrics

- **Signal Extraction Rate**: 100% (all valid signals extracted)
- **Buffer Open Rate**: ≥95% for /research and /plan commands
- **Latency**: <1s from command completion to buffer open
- **Regression Rate**: 0% (no existing functionality broken)

## Notes

### Why This Fixes the Issue

The Plan 975 timing fix (300ms delay) successfully ensures Block 2 executes before the hook reads the terminal buffer. However, the REPORT_CREATED signal was present but invisible to the regex due to ANSI codes. This fix makes the signal visible by stripping formatting before pattern matching.

### Relationship to Plan 975

This is a **continuation** of Plan 975, not a replacement. Plan 975 fixed the timing issue; this plan fixes the extraction issue discovered during testing.

### Testing Recommendation

After implementation, run `/research` 10 times in Neovim terminal with debug enabled. All 10 should result in automatic buffer opening. If fewer than 9/10 succeed, increase BUFFER_OPENER_DELAY to 0.5.

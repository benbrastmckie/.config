# Root Cause Analysis: Cross-Project Spec Numbering Issue

## Problem Statement

When using `/research-plan` in the Logos project (`/home/benjamin/Documents/Philosophy/Projects/Logos/`), the spec numbering continued from the config project (`/home/benjamin/.config/`) instead of starting fresh. Specifically:
- Logos specs: 001, 002, 003, 004, 005, 006, 007, 008, 009, **679, 680**
- The jump from 009 to 679 indicates cross-project contamination

## Root Cause Analysis

### Primary Cause: Outdated Command Version in Logos Project

The Logos project contains an older version of `/research-plan.md` that uses the **unsafe count-based numbering algorithm**:

```bash
# Logos project - OLD pattern (lines 155-159)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
```

While the config project uses the **safe atomic allocation pattern**:

```bash
# Config project - NEW pattern (lines 164-176)
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
TOPIC_NUMBER="${RESULT%|*}"
```

### Secondary Cause: Environment Variable Leakage

The cross-project contamination (009 -> 679) occurred because:

1. **Likely scenario**: `CLAUDE_PROJECT_DIR` was inherited from a previous session pointing to `/home/benjamin/.config`
2. **Alternative**: Claude Code loaded commands from `~/.claude/commands/` (global user directory) instead of project-local commands
3. **Result**: The command read the `.config` specs directory (which had numbers in the 670s) instead of Logos specs

### Evidence

The jump from 009 to 679 is inconsistent with both algorithms:
- Count-based would give 010 (if counting 9 directories)
- Max-based would give 010 (if max is 009)

This proves the command was looking at the wrong specs directory during creation of 679 and 680.

## Additional Issues Identified

### Issue 1: No Rollover Behavior (User Requirement)

The current `allocate_and_create_topic()` function has no rollover logic:
- When numbers exceed 999, the function produces 4-digit numbers (1000, 1001, etc.)
- User wants: Numbers should roll over to 000 when exceeding 999

### Issue 2: First Number is 001, Not 000 (User Requirement)

The current implementation starts from 001:

```bash
# unified-location-detection.sh:193-194
if [ -z "$max_num" ]; then
  echo "001"
```

User wants: First topic should be 000, not 001.

### Issue 3: Project Detection Not Validated

The `detect_project_root()` function in `unified-location-detection.sh` trusts:
1. `CLAUDE_PROJECT_DIR` environment variable (if set)
2. Git root detection
3. Fallback to current directory

There's no validation that the detected project matches the user's intent, which can lead to cross-project contamination when environment variables leak between sessions.

## Impact Assessment

### Severity: Medium
- Data integrity not affected (files still created)
- User confusion from unexpected numbering
- Potential for continued contamination if not fixed

### Affected Components
1. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - `allocate_and_create_topic()` and `get_next_topic_number()`
2. All commands using directory allocation: `/research-plan`, `/fix`, `/research-report`, `/research`, `/plan`
3. External projects with outdated command versions

## Proposed Solutions

### Solution 1: Add Rollover Behavior (000-999 cycle)

Modify `allocate_and_create_topic()` to implement modulo-based rollover:

```bash
# Calculate next number with rollover
if [ -z "$max_num" ]; then
  topic_number="000"  # Start from 000
else
  # Increment and rollover at 1000
  next_num=$(( (10#$max_num + 1) % 1000 ))
  topic_number=$(printf "%03d" "$next_num")
fi
```

**Considerations**:
- Need collision detection when rolling over (if 000 already exists)
- Could add suffix or find next available number
- Or simply continue from max+1 with warning

### Solution 2: Start from 000

Change initial number from "001" to "000" in both functions.

### Solution 3: Add Project Validation (Diagnostic Output)

Add diagnostic output showing which project directory is being used:

```bash
echo "INFO: Using project directory: $project_root" >&2
echo "INFO: Specs directory: $specs_root" >&2
```

This helps users catch cross-project issues immediately.

### Solution 4: Version Sync Mechanism

Create a mechanism to detect and warn about outdated command versions in other projects. This is a future enhancement.

## Recommended Implementation Priority

1. **High**: Implement rollover behavior (000-999 cycle)
2. **High**: Change initial number to 000
3. **Medium**: Add diagnostic output for project directory
4. **Low**: Version sync mechanism (future enhancement)

## References

- Existing plan: `/home/benjamin/.config/.claude/specs/753_unified_specs_directory_numbering/plans/001_unified_atomic_topic_allocation_plan.md`
- Core library: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
- Affected commands: `research-plan.md`, `fix.md`, `research-report.md`, `research.md`, `plan.md`

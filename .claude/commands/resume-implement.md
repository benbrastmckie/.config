---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: [plan-file] [phase-number]
description: Resume implementation from the most recent incomplete plan or a specific plan/phase
command-type: secondary
dependent-commands: implement, list-plans, update-plan
---

# Resume Implementation

I'll help you resume an incomplete implementation plan from where you left off.

## Progressive Plan Support

This command supports all three progressive structure levels:
- **Level 0**: Single-file plans (`NNN_name.md`)
- **Level 1**: Phase-expanded plans (`NNN_name/` with some phase files)
- **Level 2**: Stage-expanded plans (phase directories with stage files)

Resume detection works consistently across all levels using progressive parsing utilities.

## How It Works

### Without Arguments:
When you run `/resume-implement` with no arguments, I will:
1. **Find the most recent incomplete plan** by:
   - Searching all `specs/plans/` directories for both files and directories
   - Sorting by modification time (newest first)
   - Detecting structure level using `parse-adaptive-plan.sh detect_structure_level`
   - Checking for incomplete phase markers
2. **Identify the resume point**:
   - Read phase completion markers in appropriate files
   - Find first phase lacking `[COMPLETED]` marker or with unchecked tasks
3. **Continue implementation** from that point

### With Plan File or Directory:
`/resume-implement <plan-path>`
- Accepts both `.md` files (Level 0) and directories (Level 1/2)
- Auto-detects structure level and finds first incomplete phase
- Resume the plan from its first incomplete phase

### With Plan and Phase:
`/resume-implement <plan-path> <phase-number>`
- Resume the specified plan from the specified phase
- Works with all progressive structure levels

## Detection Patterns

### Incomplete Plan Detection:

Check for incomplete phases by reading appropriate files:
- **Level 0**: Check phase headings in main plan file for `[COMPLETED]` markers
- **Level 1**: If phase is expanded, check phase file; otherwise check main plan
- **Level 2**: Check stage files and phase overview files for completion

### Complete Plan Markers:
- All phases have `[COMPLETED]` marker in heading
- **Level 0**: All tasks `[x]`, all phases marked `[COMPLETED]` in main plan
- **Level 1**: All expanded phase files show completion, main plan shows completion
- **Level 2**: All stages complete, all phase files complete, main plan complete

## Auto-Discovery Process

```bash
# Find most recent plans (both files and directories)
# Level 0 plans
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null | head -10

# Level 1/2 plans (directories with main plan files)
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" -exec ls -t {} + 2>/dev/null | head -10

# For each plan, detect structure level and check status
for plan in $plans; do
  LEVEL=$(.claude/utils/parse-adaptive-plan.sh detect_structure_level "$plan")

  # Read phases and check completion markers
  # Look for first phase without [COMPLETED] marker or with unchecked tasks
  # Resume from that phase
done
```

## Resume Behavior

When resuming, I will:
1. **Show plan status**:
   - Display completed phases (marked with `[COMPLETED]`)
   - Show current phase to resume
   - List remaining tasks
   - Check for partial summary for additional context
2. **Continue from breakpoint**:
   - Skip completed phases/tasks
   - Start with first incomplete phase
   - Resume at exact point where implementation stopped
3. **Maintain continuity**:
   - Reference previous commits
   - Continue updating same partial summary
   - Pick up Implementation Progress tracking
   - Continue phase numbering sequence

## Partial Summary Support

**Check for Partial Summary:**
- Look for `[specs-dir]/summaries/NNN_partial.md`
- If exists: Shows previous progress and resume point
- Partial summary includes:
  - Which phases were completed
  - Last commit hash
  - Resume instructions
  - Implementation notes

**Resume Workflow (Tier-Aware):**
1. Detect plan tier using `parse-adaptive-plan.sh detect_tier`
2. Get plan overview path appropriate for tier
3. Use parsing utility to find last completed phase (works across all tiers)
4. Check partial summary for additional context
5. Resume from first incomplete phase
6. Continue updating same partial summary after each phase (using tier-aware completion marking)
7. Finalize summary when all phases complete

## Example Usage

```bash
# Resume most recent incomplete plan (any level)
/resume-implement

# Resume specific Level 0 plan from where it left off
/resume-implement specs/plans/025_feature_name.md

# Resume specific Level 1/2 plan from where it left off
/resume-implement specs/plans/026_complex_feature/

# Resume from specific phase (works with any level)
/resume-implement specs/plans/025_feature_name.md 3
/resume-implement specs/plans/026_complex_feature/ 2
```

## Relationship to /implement

This command is equivalent to:
- `/implement` (with no args) - Both auto-detect incomplete plans
- `/implement <plan>` - When plan has incomplete phases
- `/implement <plan> <phase>` - With explicit phase specification

The main difference is that `/resume-implement` is more explicit about continuing previous work, while `/implement` can be used for both new and resuming implementations.

Let me find and resume your incomplete implementation plan.
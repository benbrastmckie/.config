---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: [plan-file] [phase-number]
description: Resume implementation from the most recent incomplete plan or a specific plan/phase
command-type: secondary
dependent-commands: implement, list-plans, update-plan
---

# Resume Implementation

I'll help you resume an incomplete implementation plan from where you left off.

## Adaptive Plan Support

This command supports all three plan structure tiers:
- **Tier 1**: Single-file plans (`NNN_name.md`)
- **Tier 2**: Phase-directory plans (`NNN_name/` with phase files)
- **Tier 3**: Hierarchical tree plans (phase directories with stage files)

Resume detection works consistently across all tiers using `parse-adaptive-plan.sh`.

## How It Works

### Without Arguments:
When you run `/resume-implement` with no arguments, I will:
1. **Find the most recent incomplete plan** by:
   - Searching all `specs/plans/` directories for both files and directories
   - Sorting by modification time (newest first)
   - Detecting tier using `parse-adaptive-plan.sh detect_tier`
   - Checking for incomplete markers (works across all tiers)
2. **Identify the resume point**:
   - Use parsing utility to get phase list
   - Check status of each phase using `get_status`
   - Find first phase with status "incomplete" or "not_started"
3. **Continue implementation** from that point

### With Plan File or Directory:
`/resume-implement <plan-path>`
- Accepts both `.md` files (Tier 1) and directories (Tier 2/3)
- Auto-detects tier and finds first incomplete phase
- Resume the plan from its first incomplete phase

### With Plan and Phase:
`/resume-implement <plan-path> <phase-number>`
- Resume the specified plan from the specified phase
- Works with all tier structures

## Detection Patterns (Tier-Aware)

### Incomplete Plan Detection Using Parsing Utility:

**Tier 1 (Single File)**:
- Use `get_status` to check each phase
- Returns: "incomplete" if has unchecked tasks `- [ ]`
- Returns: "not_started" if phase has no task progress
- Phase heading lacks `[COMPLETED]` marker

**Tier 2 (Phase Directory)**:
- Check status of each phase file
- Phase file has unchecked tasks or missing completion marker
- Overview shows phase not complete

**Tier 3 (Hierarchical Tree)**:
- Check status across stage files
- Any stage file with unchecked tasks indicates incomplete
- Phase overview or main overview not marked complete

### Complete Plan Markers:
- All phases return status "complete" from `get_status`
- **Tier 1**: All tasks `[x]`, all phases have `[COMPLETED]`
- **Tier 2**: All phase files complete, overview shows completion
- **Tier 3**: All stages complete, all phase overviews complete, main overview complete

## Auto-Discovery Process (Tier-Aware)

```bash
# Find most recent plans (both files and directories)
# Tier 1 plans
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null | head -10

# Tier 2/3 plans (directories with overview files)
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" -exec ls -t {} + 2>/dev/null | head -10

# For each plan, detect tier and check status
for plan in $plans; do
  TIER=$(.claude/utils/parse-adaptive-plan.sh detect_tier "$plan")

  # Get all phases
  PHASES=$(.claude/utils/parse-adaptive-plan.sh list_phases "$plan")

  # Check each phase status
  for phase_num in $PHASES; do
    STATUS=$(.claude/utils/parse-adaptive-plan.sh get_status "$plan" "$phase_num")
    if [[ "$STATUS" != "complete" ]]; then
      echo "Resume from: $plan, Phase: $phase_num"
      break
    fi
  done
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
# Resume most recent incomplete plan (any tier)
/resume-implement

# Resume specific Tier 1 plan from where it left off
/resume-implement specs/plans/025_feature_name.md

# Resume specific Tier 2/3 plan from where it left off
/resume-implement specs/plans/026_complex_feature/

# Resume from specific phase (works with any tier)
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
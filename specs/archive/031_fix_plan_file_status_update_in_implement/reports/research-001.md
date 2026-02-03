# Research Report: Task #31

**Task**: fix_plan_file_status_update_in_implement
**Date**: 2026-02-02
**Focus**: Plan file status verification in /implement GATE OUT and sed command improvements in skills Stage 7

## Summary

Plan file status updates are documented in 3 of 4 implementation skills but not executed reliably. The `/implement` command's GATE OUT checkpoint does not verify plan file status, only state.json and TODO.md status. The neovim-implementation skill is missing plan file update code entirely. The sed commands in other skills lack error checking and verification.

## Findings

### 1. implement.md GATE OUT Verification Gap

The `/implement` command's GATE OUT checkpoint (lines 81-123) verifies:
- **Return validation**: status, summary, artifacts, metadata fields
- **Artifact existence**: checks if summary file exists on disk
- **state.json status**: confirms status matches task status ("completed" or "implementing")
- **TODO.md status**: implicitly through skill postflight

**Missing**: Plan file status verification. The GATE OUT does not check that the plan file's `- **Status**: [...]` field has been updated to match the task completion state.

### 2. Implementation Skills Plan File Update Patterns

**skill-implementer (general/meta/markdown)**: Lines 91-98 (preflight) and 266-272 (postflight Stage 7)
```bash
# Preflight (Stage 2)
plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    sed -i "s/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [IMPLEMENTING]/" "$plan_file"
fi

# Postflight (Stage 7) - for "implemented" status
plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    sed -i "s/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [COMPLETED]/" "$plan_file"
fi
```

**skill-latex-implementation**: Lines 70-78 (preflight) and 283-289 (postflight)
- Same pattern as skill-implementer

**skill-typst-implementation**: Lines 70-78 (preflight) and 282-288 (postflight)
- Same pattern as skill-implementer

**skill-neovim-implementation**: MISSING
- No preflight plan file update
- No postflight plan file update
- Only locates plan path for passing to subagent (line 54-59)

### 3. sed Command Issues

Current sed commands have several problems:

**a) No error checking**: The sed command runs silently - if it fails or doesn't match, no error is reported.

**b) No verification**: After sed runs, there's no check that the status was actually updated.

**c) Inconsistent file finding**: Uses `ls -1 | sort -V | tail -1` which may not find the file if:
- Directory structure differs
- Multiple plan files exist with unexpected naming

**d) In-place edit risks**: `sed -i` modifies file in place; on failure leaves file corrupted or unchanged with no indication.

### 4. Existing Verification Patterns in Codebase

The `preflight-postflight.md` document (lines 152-222 of postflight-pattern.md) shows a "Defense in Depth" pattern for verification:

```bash
# Verify status was actually updated
actual_status=$(jq -r --arg num "$task_number" \
  '.active_projects[] | select(.project_number == ($num | tonumber)) | .status' \
  specs/state.json)

if [ "$actual_status" != "$target_status" ]; then
  echo "WARNING: Postflight verification failed - status not updated"
fi
```

A similar pattern should be applied to plan file status verification.

### 5. Plan File Status Field Format

From existing plan files (e.g., `specs/archive/030_migrate_existing_directories_padded/plans/implementation-001.md`):
```markdown
**Status**: [COMPLETED]
```

The sed pattern `^\- \*\*Status\*\*: \[.*\]$` matches lines like:
```
- **Status**: [NOT STARTED]
```

However, some plans may have the Status field without the leading `- ` bullet, which would not match.

## Recommendations

### Recommendation 1: Add Plan File Verification to implement.md GATE OUT

Add a new verification step (4a) to CHECKPOINT 2: GATE OUT:

```markdown
4a. **Verify Plan File Status Updated**

   **If result.status == "implemented":**
   ```bash
   # Find plan file
   padded_num=$(printf "%03d" "$task_number")
   project_name=$(jq -r --arg num "$task_number" \
     '.active_projects[] | select(.project_number == ($num | tonumber)) | .project_name' \
     specs/state.json)
   plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)

   if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
       # Check plan file has [COMPLETED] status
       if ! grep -q "^\*\*Status\*\*: \[COMPLETED\]" "$plan_file" && \
          ! grep -q "^\- \*\*Status\*\*: \[COMPLETED\]" "$plan_file"; then
           echo "WARNING: Plan file status not updated to [COMPLETED], updating now..."
           # Defensive update (both patterns)
           sed -i "s/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [COMPLETED]/" "$plan_file"
           sed -i "s/^\*\*Status\*\*: \[.*\]$/**Status**: [COMPLETED]/" "$plan_file"
       fi
   fi
   ```
```

### Recommendation 2: Add Missing Plan File Updates to skill-neovim-implementation

Add the same preflight and postflight plan file update code from skill-implementer to skill-neovim-implementation:

**Stage 2 (Preflight)** - After line 77, add:
```markdown
**Update plan file** (if exists): Update the Status field in plan metadata:
```bash
plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    sed -i "s/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [IMPLEMENTING]/" "$plan_file"
    sed -i "s/^\*\*Status\*\*: \[.*\]$/**Status**: [IMPLEMENTING]/" "$plan_file"
fi
```

**Stage 7 (Postflight)** - Add new plan file update section after state.json update:
```markdown
**Update plan file** (if exists): Update the Status field to `[COMPLETED]`:
```bash
plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    sed -i "s/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [COMPLETED]/" "$plan_file"
    sed -i "s/^\*\*Status\*\*: \[.*\]$/**Status**: [COMPLETED]/" "$plan_file"
    # Verify update
    if grep -q "Status.*\[COMPLETED\]" "$plan_file"; then
        echo "Plan file status updated to [COMPLETED]"
    else
        echo "WARNING: Plan file status update may have failed"
    fi
fi
```

### Recommendation 3: Improve sed Commands with Error Checking and Verification

Update all skills (skill-implementer, skill-latex-implementation, skill-typst-implementation) Stage 7 sed commands to include:

```bash
# Find plan file
plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)

if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    # Update status (handle both bullet and non-bullet patterns)
    sed -i "s/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [COMPLETED]/" "$plan_file"
    sed -i "s/^\*\*Status\*\*: \[.*\]$/**Status**: [COMPLETED]/" "$plan_file"

    # Verify update succeeded
    if grep -q "Status.*\[COMPLETED\]" "$plan_file"; then
        echo "Plan file status updated to [COMPLETED]: $plan_file"
    else
        echo "WARNING: Plan file status update failed for $plan_file"
        echo "Expected pattern '- **Status**: [COMPLETED]' not found"
    fi
else
    echo "Note: No plan file found (may be expected for tasks without plans)"
fi
```

## Implementation Impact

| File | Changes Required |
|------|-----------------|
| `.claude/commands/implement.md` | Add GATE OUT step 4a for plan file verification |
| `.claude/skills/skill-neovim-implementation/SKILL.md` | Add preflight (Stage 2) and postflight (Stage 7) plan file updates |
| `.claude/skills/skill-implementer/SKILL.md` | Add verification output to Stage 7 sed commands |
| `.claude/skills/skill-latex-implementation/SKILL.md` | Add verification output to Stage 7 sed commands |
| `.claude/skills/skill-typst-implementation/SKILL.md` | Add verification output to Stage 7 sed commands |

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| sed command fails silently | Plan file left in wrong state | Add grep verification after sed |
| Plan file format varies | sed pattern doesn't match | Support both bullet and non-bullet patterns |
| Multiple plan file versions | Wrong file updated | Use `sort -V | tail -1` to get latest |
| Plan file doesn't exist | Unnecessary error | Check file exists before updating |

## References

- `/home/benjamin/.config/nvim/.claude/commands/implement.md` - GATE OUT checkpoint (lines 81-123)
- `/home/benjamin/.config/nvim/.claude/skills/skill-implementer/SKILL.md` - Stage 7 plan file updates (lines 266-295)
- `/home/benjamin/.config/nvim/.claude/skills/skill-neovim-implementation/SKILL.md` - Missing plan file updates
- `/home/benjamin/.config/nvim/.claude/context/core/orchestration/postflight-pattern.md` - Defense in depth verification pattern

## Next Steps

Create implementation plan with:
- Phase 1: Add plan file verification to implement.md GATE OUT
- Phase 2: Add missing plan file updates to skill-neovim-implementation
- Phase 3: Update sed commands in all implementation skills with verification output

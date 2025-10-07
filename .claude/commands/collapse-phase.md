---
allowed-tools: Read, Write, Edit, Bash
argument-hint: <plan-path> <phase-num>
description: Collapse an expanded phase back into the main plan (Level 1 → Level 0)
command-type: workflow
---

# Collapse Phase to Main Plan

I'll merge an expanded phase file back into the main plan and clean up the directory structure if this is the last expanded phase (Level 1 → Level 0 or Level 1 → Level 1).

## Arguments

- `$1` (required): Path to plan directory or main plan file (e.g., `specs/plans/025_feature/` or `specs/plans/025_feature/025_feature.md`)
- `$2` (required): Phase number to collapse (e.g., `2`)

## Objective

Reverse phase expansion by merging expanded phase content back into the main plan, maintaining all task completion status, and cleaning up the directory structure if this was the last expanded phase.

**Operations**:
- Merge phase content back to main plan
- Delete phase file after successful merge
- Update metadata (Structure Level, Expanded Phases)
- Clean up directory if last phase (Level 1 → Level 0)
- Preserve all content and completion status

## Process

### 1. Analyze Current Structure

Determine the plan's current structure level and validate inputs.

```bash
# Normalize plan path (handle both directory and file paths)
if [[ -f "$plan_path" ]] && [[ "$plan_path" == *.md ]]; then
  # User provided file path - extract directory
  plan_dir=$(dirname "$plan_path")
  plan_base=$(basename "$plan_path" .md)

  # Check if directory exists
  if [[ -d "$plan_dir/$plan_base" ]]; then
    plan_path="$plan_dir/$plan_base"
  else
    error "Plan has not been expanded (no directory found)"
  fi
elif [[ -d "$plan_path" ]]; then
  # Directory provided - OK
  plan_base=$(basename "$plan_path")
else
  error "Invalid plan path: $plan_path"
fi

# Detect structure level
source .claude/lib/parse-adaptive-plan.sh
structure_level=$(detect_structure_level "$plan_path")

if [[ "$structure_level" != "1" ]]; then
  error "Plan must be Level 1 (phase expansion) to collapse phases. Current level: $structure_level"
fi

# Identify main plan file
main_plan="$plan_path/$plan_base.md"
[[ ! -f "$main_plan" ]] && error "Main plan file not found: $main_plan"
```

**Validation**:
- [ ] Plan path resolves to valid directory
- [ ] Structure Level is 1 (phase expansion exists)
- [ ] Main plan file exists and is readable

### 2. Validate Collapse Operation

Verify that the phase exists and can be safely collapsed.

```bash
# Construct phase file path
phase_file="$plan_path/phase_${phase_num}_*.md"
phase_files=($(ls $phase_file 2>/dev/null))

if [[ ${#phase_files[@]} -eq 0 ]]; then
  error "Phase $phase_num not found in $plan_path/"
elif [[ ${#phase_files[@]} -gt 1 ]]; then
  error "Multiple phase $phase_num files found (ambiguous)"
fi

phase_file="${phase_files[0]}"
phase_name=$(basename "$phase_file" .md)

echo "Found phase file: $phase_name.md"

# Check if phase has expanded stages (Level 2)
phase_dir="$plan_path/$phase_name"
if [[ -d "$phase_dir" ]]; then
  error "Phase $phase_num has expanded stages. Collapse stages first with /collapse-stage"
fi
```

**Validation**:
- [ ] Phase file exists and is unique
- [ ] Phase does not have expanded stages (Level 2)
- [ ] Phase file is readable

### 3. Extract Phase Content

Read the complete phase content from the expanded phase file.

```bash
# Read phase content (will be merged back into main plan)
if [[ ! -r "$phase_file" ]]; then
  error "Cannot read phase file: $phase_file"
fi

# Extract phase heading to identify section in main plan
phase_heading=$(grep "^### Phase $phase_num:" "$phase_file" | head -1)
if [[ -z "$phase_heading" ]]; then
  error "Phase heading not found in $phase_file"
fi

echo "Phase heading: $phase_heading"
```

**Extraction**:
- Read full phase file content
- Identify phase heading for section matching
- Validate content is non-empty

### 4. Detect Last Item

Use shared utility to check if this is the last expanded phase.

```bash
# Source shared utilities
source .claude/lib/progressive-planning-utils.sh

# Check if this is the last expanded phase
if detect_last_item "$plan_path" "phase" "$phase_num"; then
  is_last_phase=true
  echo "This is the LAST expanded phase (Level 1 → Level 0)"
else
  is_last_phase=false
  echo "Other expanded phases exist (Level 1 → Level 1)"
fi
```

**Detection**:
- Use `detect_last_item()` from shared utilities
- Determine if directory cleanup needed
- Set transition type (1→0 or 1→1)

### 5. Merge Content

Use shared utility to merge phase content back into main plan.

```bash
# Create backup of main plan
backup_file="${main_plan}.backup.$$"
cp "$main_plan" "$backup_file"

# Merge phase content back to main plan
echo "Merging phase content into main plan..."

# Use shared utility for merging
merged_content=$(merge_markdown_sections "$phase_file" "$main_plan" "$phase_heading")

# Write merged content to temp file
temp_plan="${main_plan}.tmp"
echo "$merged_content" > "$temp_plan"

# Validate merge succeeded
if ! validate_content_preservation "$phase_file" "$temp_plan" "$phase_heading"; then
  rm -f "$temp_plan"
  error "Content validation failed - merge may have lost content"
fi

# Replace main plan with merged version
mv "$temp_plan" "$main_plan"
echo "✓ Content merged successfully"
```

**Merging**:
- Create backup before merging
- Use `merge_markdown_sections()` from shared utilities
- Validate content preservation
- Replace main plan atomically

### 6. Update Metadata

Use shared utility to update plan metadata.

```bash
# Update metadata in main plan
echo "Updating metadata..."

# Use shared utility to update Expanded Phases and Structure Level
updated_metadata=$(update_expansion_metadata "$main_plan" "collapse" "phase" "$phase_num")

# Write updated metadata
echo "$updated_metadata" > "${main_plan}.tmp"
mv "${main_plan}.tmp" "$main_plan"

# If last phase, ensure Structure Level is 0
if [[ "$is_last_phase" == true ]]; then
  # Manually ensure Structure Level is 0 (update_expansion_metadata sets it)
  sed -i 's/^- \*\*Structure Level\*\*: 1$/- \*\*Structure Level\*\*: 0/' "$main_plan"

  # Remove Expanded Phases line entirely
  sed -i '/^- \*\*Expanded Phases\*\*:/d' "$main_plan"
fi

echo "✓ Metadata updated"
```

**Metadata Updates**:
- Use `update_expansion_metadata()` from shared utilities
- Remove phase from Expanded Phases list
- Set Structure Level to 0 if last phase
- Remove Expanded Phases metadata if last phase

### 7. Directory Cleanup

If this was the last phase, move main plan to root and remove directory.

```bash
if [[ "$is_last_phase" == true ]]; then
  echo "Performing directory cleanup (Level 1 → Level 0)..."

  # Target path for main plan (move to parent directory)
  parent_dir=$(dirname "$plan_path")
  target_plan="$parent_dir/$plan_base.md"

  # Move main plan to parent directory
  mv "$main_plan" "$target_plan"

  # Delete phase file
  rm "$phase_file"

  # Remove now-empty plan directory
  rmdir "$plan_path" 2>/dev/null || {
    echo "Warning: Directory not empty, manual cleanup may be needed: $plan_path"
  }

  # Remove backup
  rm -f "$backup_file"

  echo "✓ Directory cleanup complete"
  echo "  Main plan: $target_plan"
else
  # Just delete the phase file (directory retained)
  echo "Removing phase file..."
  rm "$phase_file"

  # Remove backup
  rm -f "$backup_file"

  echo "✓ Phase file removed"
  echo "  Directory retained (other phases still expanded)"
  echo "  Main plan: $main_plan"
fi
```

**Cleanup**:
- If last phase: Move main plan to parent, remove directory
- If not last: Only delete phase file
- Remove backup files
- Validate cleanup completed

### 8. Validation

Verify that the collapse operation completed successfully.

```bash
# Final validation
echo ""
echo "=== Collapse Validation ==="

if [[ "$is_last_phase" == true ]]; then
  # Validate Level 0 structure
  [[ -f "$target_plan" ]] && echo "✓ Main plan at root: $target_plan"
  [[ ! -d "$plan_path" ]] && echo "✓ Plan directory removed"

  # Check metadata
  structure=$(grep "^- \*\*Structure Level\*\*:" "$target_plan" || echo "- **Structure Level**: 0")
  if [[ "$structure" == *"0"* ]]; then
    echo "✓ Structure Level: 0"
  else
    echo "✗ Structure Level not updated correctly"
  fi

  # Check Expanded Phases removed
  if ! grep -q "^- \*\*Expanded Phases\*\*:" "$target_plan"; then
    echo "✓ Expanded Phases metadata removed"
  else
    echo "⚠ Expanded Phases metadata still present (expected removal)"
  fi

else
  # Validate Level 1 structure (phase removed, directory retained)
  [[ -f "$main_plan" ]] && echo "✓ Main plan: $main_plan"
  [[ ! -f "$phase_file" ]] && echo "✓ Phase file removed"
  [[ -d "$plan_path" ]] && echo "✓ Directory retained"

  # Check metadata
  structure=$(grep "^- \*\*Structure Level\*\*:" "$main_plan")
  if [[ "$structure" == *"1"* ]]; then
    echo "✓ Structure Level: 1"
  else
    echo "✗ Structure Level incorrect"
  fi

  # Check Expanded Phases updated
  expanded=$(grep "^- \*\*Expanded Phases\*\*:" "$main_plan" || echo "")
  if [[ -n "$expanded" ]] && [[ ! "$expanded" == *"$phase_num"* ]]; then
    echo "✓ Phase $phase_num removed from Expanded Phases"
  else
    echo "⚠ Expanded Phases not updated correctly"
  fi
fi

echo ""
echo "✅ Phase $phase_num collapsed successfully"
```

**Validation Checks**:
- [ ] Phase content merged into main plan
- [ ] Phase file deleted
- [ ] Metadata updated correctly
- [ ] Directory state correct (removed if last, retained otherwise)
- [ ] No content loss during merge

## Quality Checklist

Before completing the collapse operation, verify:

- [ ] Phase content fully extracted and preserved
- [ ] Metadata updated correctly (Structure Level, Expanded Phases)
- [ ] Directory removed only if last phase
- [ ] Plan file integrity validated
- [ ] No content loss during merge
- [ ] All references to phase file updated
- [ ] Backup created and removed after success
- [ ] Error handling tested (rollback on failure)

## Error Handling

### Scenario 1: Phase File Not Found

**Symptom**: Phase file does not exist in plan directory

**Recovery**:
```bash
# List available phases
echo "Error: Phase $phase_num not found"
echo "Available phases:"
ls -1 "$plan_path"/phase_*.md 2>/dev/null | sed 's/.*phase_/  Phase /' | sed 's/_.*//'

# Check Structure Level
echo "Plan Structure Level: $(detect_structure_level "$plan_path")"
exit 1
```

### Scenario 2: Merge Conflict (Duplicate Sections)

**Symptom**: Main plan already contains full phase content

**Recovery**:
```bash
# Manual intervention required
echo "Error: Merge conflict detected"
echo "Main plan may already contain full phase content"
echo ""
echo "Options:"
echo "1. Review main plan manually: $main_plan"
echo "2. Review phase file manually: $phase_file"
echo "3. Manually merge and then delete phase file"
echo ""
echo "Backup created: $backup_file"
exit 1
```

### Scenario 3: Metadata Parsing Failure

**Symptom**: Cannot parse or update metadata

**Recovery**:
```bash
# Rollback operation
echo "Error: Metadata update failed"
echo "Rolling back changes..."

# Restore from backup
mv "$backup_file" "$main_plan"

echo "Changes rolled back. Main plan restored from backup."
echo "Original phase file preserved: $phase_file"
exit 1
```

### Scenario 4: Directory Removal Failure

**Symptom**: Cannot remove directory after last phase collapse

**Recovery**:
```bash
# Leave directory, warn user
echo "Warning: Could not remove directory: $plan_path"
echo ""
echo "Manual cleanup required:"
echo "  rm -rf $plan_path"
echo ""
echo "Phase content has been merged successfully."
echo "Directory cleanup is safe to perform manually."
# Continue (do not exit)
```

### Scenario 5: Phase Has Expanded Stages

**Symptom**: Phase directory exists (Level 2)

**Recovery**:
```bash
echo "Error: Phase $phase_num has expanded stages (Level 2)"
echo "You must collapse all stages first before collapsing the phase."
echo ""
echo "Collapse stages with:"
echo "  /collapse-stage $phase_dir <stage-num>"
echo ""
echo "Available stages:"
ls -1 "$phase_dir"/stage_*.md 2>/dev/null | sed 's/.*stage_/  Stage /' | sed 's/_.*//'
exit 1
```

## Validation Examples

### Example 1: Simple Collapse (Single Phase Expanded)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
└── phase_2_implementation.md       # Only expanded phase
```

**Command:**
```bash
/collapse-phase specs/plans/025_feature/ 2
```

**After:**
```
specs/plans/025_feature.md          # Main plan at root (Level 0)
```

**Expected Output:**
```
Found phase file: phase_2_implementation.md
Phase heading: ### Phase 2: Implementation
This is the LAST expanded phase (Level 1 → Level 0)
Merging phase content into main plan...
✓ Content merged successfully
Updating metadata...
✓ Metadata updated
Performing directory cleanup (Level 1 → Level 0)...
✓ Directory cleanup complete
  Main plan: specs/plans/025_feature.md

=== Collapse Validation ===
✓ Main plan at root: specs/plans/025_feature.md
✓ Plan directory removed
✓ Structure Level: 0
✓ Expanded Phases metadata removed

✅ Phase 2 collapsed successfully
```

### Example 2: Multiple Phases Expanded (Not Last)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
├── phase_2_implementation.md       # Phase to collapse
└── phase_5_deployment.md           # Another expanded phase
```

**Command:**
```bash
/collapse-phase specs/plans/025_feature/ 2
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Phase 2 content merged back
└── phase_5_deployment.md           # Unchanged
```

**Expected Output:**
```
Found phase file: phase_2_implementation.md
Phase heading: ### Phase 2: Implementation
Other expanded phases exist (Level 1 → Level 1)
Merging phase content into main plan...
✓ Content merged successfully
Updating metadata...
✓ Metadata updated
Removing phase file...
✓ Phase file removed
  Directory retained (other phases still expanded)
  Main plan: specs/plans/025_feature/025_feature.md

=== Collapse Validation ===
✓ Main plan: specs/plans/025_feature/025_feature.md
✓ Phase file removed
✓ Directory retained
✓ Structure Level: 1
✓ Phase 2 removed from Expanded Phases

✅ Phase 2 collapsed successfully
```

### Example 3: Last Phase Collapse with Directory Removal

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
└── phase_5_deployment.md           # Last expanded phase
```

**Command:**
```bash
/collapse-phase specs/plans/025_feature/ 5
```

**After:**
```
specs/plans/025_feature.md          # Main plan moved to root, all inline
```

**Expected Output:**
```
Found phase file: phase_5_deployment.md
Phase heading: ### Phase 5: Deployment
This is the LAST expanded phase (Level 1 → Level 0)
Merging phase content into main plan...
✓ Content merged successfully
Updating metadata...
✓ Metadata updated
Performing directory cleanup (Level 1 → Level 0)...
✓ Directory cleanup complete
  Main plan: specs/plans/025_feature.md

=== Collapse Validation ===
✓ Main plan at root: specs/plans/025_feature.md
✓ Plan directory removed
✓ Structure Level: 0
✓ Expanded Phases metadata removed

✅ Phase 5 collapsed successfully
```

## Key Principles

1. **Content Preservation**: All phase content, tasks, and completion status must be preserved exactly
2. **Atomic Operations**: Use backups and temp files to prevent partial failures
3. **Validation**: Verify content integrity before and after merge
4. **Clean Transitions**: Properly update metadata and structure for Level 1→0 or Level 1→1
5. **Reversibility**: Collapse can be undone via `/expand-phase`

## Integration with Other Commands

### Uses Shared Utilities
- `detect_last_item()` - Check if last phase
- `merge_markdown_sections()` - Merge content back to main plan
- `update_expansion_metadata()` - Update Structure Level and Expanded Phases
- `validate_content_preservation()` - Verify merge succeeded

### Uses Parse Utilities
- `detect_structure_level()` - Determine current plan level
- `parse-adaptive-plan.sh` - Structure detection functions

### Complementary Commands
- `/expand-phase` - Opposite operation (Level 0→1 or Level 1→1)
- `/collapse-stage` - Must collapse stages before collapsing phase
- `/list-plans` - Show expansion status

## Standards Applied

Following CLAUDE.md Code Standards:
- **Indentation**: 2 spaces, expandtab (in code examples)
- **Error Handling**: Comprehensive validation and rollback
- **Documentation**: Clear operation description with examples
- **File Operations**: Safe atomic operations with temp files

## Notes

- Phase files must not have expanded stages (Level 2) before collapse
- Collapsing a phase does NOT mark it as complete or incomplete
- Task completion status is preserved during collapse
- Main plan structure is restored exactly as before expansion
- Collapse is fully reversible via `/expand-phase`
- Use backups before collapse for extra safety

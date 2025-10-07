---
allowed-tools: Read, Write, Edit, Bash
argument-hint: <phase-path> <stage-num>
description: Collapse an expanded stage back into the phase file (Level 2 → Level 1)
command-type: workflow
---

# Collapse Stage to Phase File

I'll merge an expanded stage file back into the phase file and clean up the phase directory if this is the last expanded stage (Level 2 → Level 1 or Level 2 → Level 2).

## Arguments

- `$1` (required): Path to phase directory or phase file (e.g., `specs/plans/025_feature/phase_2_impl/` or `specs/plans/025_feature/phase_2_impl/phase_2_impl.md`)
- `$2` (required): Stage number to collapse (e.g., `1`)

## Objective

Reverse stage expansion by merging expanded stage content back into the phase file, maintaining all task completion status, updating three-way metadata (stage → phase → main plan), and cleaning up the directory structure if this was the last expanded stage.

**Operations**:
- Merge stage content back to phase file
- Delete stage file after successful merge
- Update three-way metadata (phase file + main plan)
- Clean up directory if last stage (Level 2 → Level 1)
- Preserve all content and completion status

## Process

### 1. Analyze Current Structure

Determine the phase's current structure level and validate inputs.

```bash
# Normalize phase path (handle both directory and file paths)
if [[ -f "$phase_path" ]] && [[ "$phase_path" == *.md ]]; then
  # User provided file path - extract directory
  phase_dir=$(dirname "$phase_path")
  phase_base=$(basename "$phase_path" .md)

  # Check if phase directory exists
  if [[ -d "$phase_dir/$phase_base" ]]; then
    phase_path="$phase_dir/$phase_base"
  else
    error "Phase has not been expanded (no directory found)"
  fi
elif [[ -d "$phase_path" ]]; then
  # Directory provided - OK
  phase_base=$(basename "$phase_path")
else
  error "Invalid phase path: $phase_path"
fi

# Detect parent plan directory
plan_dir=$(dirname "$phase_path")
plan_base=$(basename "$plan_dir")

# Check if plan is at root or in subdirectory
if [[ -f "$plan_dir.md" ]]; then
  # Plan is Level 0 (single file) - impossible to have Level 2
  error "Parent plan is Level 0 (no phase expansion). Cannot have expanded stages."
elif [[ -f "$plan_dir/$plan_base.md" ]]; then
  # Plan is Level 1 or Level 2
  main_plan="$plan_dir/$plan_base.md"
else
  error "Cannot locate main plan file for: $plan_dir"
fi

# Identify phase file
phase_file="$phase_path/$phase_base.md"
[[ ! -f "$phase_file" ]] && error "Phase file not found: $phase_file"

# Extract phase number from directory name
phase_num=$(echo "$phase_base" | grep -oP 'phase_\K\d+' | head -1)
[[ -z "$phase_num" ]] && error "Cannot extract phase number from: $phase_base"

echo "Phase directory: $phase_path"
echo "Phase file: $phase_file"
echo "Phase number: $phase_num"
echo "Main plan: $main_plan"
```

**Validation**:
- [ ] Phase path resolves to valid directory
- [ ] Phase file exists and is readable
- [ ] Main plan file exists
- [ ] Phase number extracted correctly

### 2. Validate Collapse Operation

Verify that the stage exists and can be safely collapsed.

```bash
# Construct stage file path
stage_file="$phase_path/stage_${stage_num}_*.md"
stage_files=($(ls $stage_file 2>/dev/null))

if [[ ${#stage_files[@]} -eq 0 ]]; then
  error "Stage $stage_num not found in $phase_path/"
elif [[ ${#stage_files[@]} -gt 1 ]]; then
  error "Multiple stage $stage_num files found (ambiguous)"
fi

stage_file="${stage_files[0]}"
stage_name=$(basename "$stage_file" .md)

echo "Found stage file: $stage_name.md"

# Check that stage file is readable
[[ ! -r "$stage_file" ]] && error "Cannot read stage file: $stage_file"
```

**Validation**:
- [ ] Stage file exists and is unique
- [ ] Stage file is readable
- [ ] No nested expansions (stages don't expand further)

### 3. Extract Stage Content

Read the complete stage content from the expanded stage file.

```bash
# Read stage content (will be merged back into phase file)
if [[ ! -r "$stage_file" ]]; then
  error "Cannot read stage file: $stage_file"
fi

# Extract stage heading to identify section in phase file
# Stage headings are #### (4 hashes), not ### (3 hashes)
stage_heading=$(grep "^#### Stage $stage_num:" "$stage_file" | head -1)
if [[ -z "$stage_heading" ]]; then
  # Try alternate format without colon
  stage_heading=$(grep "^#### Stage $stage_num[^:]" "$stage_file" | head -1)
fi

if [[ -z "$stage_heading" ]]; then
  error "Stage heading not found in $stage_file"
fi

echo "Stage heading: $stage_heading"
```

**Extraction**:
- Read full stage file content
- Identify stage heading for section matching
- Validate content is non-empty

### 4. Detect Last Item

Use shared utility to check if this is the last expanded stage.

```bash
# Source shared utilities
source .claude/lib/progressive-planning-utils.sh

# Check if this is the last expanded stage
if detect_last_item "$phase_path" "stage" "$stage_num"; then
  is_last_stage=true
  echo "This is the LAST expanded stage (Level 2 → Level 1)"
else
  is_last_stage=false
  echo "Other expanded stages exist (Level 2 → Level 2)"
fi
```

**Detection**:
- Use `detect_last_item()` from shared utilities
- Determine if directory cleanup needed
- Set transition type (2→1 or 2→2)

### 5. Merge Content

Use shared utility to merge stage content back into phase file.

```bash
# Create backup of phase file
backup_file="${phase_file}.backup.$$"
cp "$phase_file" "$backup_file"

# Merge stage content back to phase file
echo "Merging stage content into phase file..."

# Use shared utility for merging
# Note: Stage headings use #### (4 hashes)
merged_content=$(merge_markdown_sections "$stage_file" "$phase_file" "$stage_heading")

# Write merged content to temp file
temp_phase="${phase_file}.tmp"
echo "$merged_content" > "$temp_phase"

# Validate merge succeeded
if ! validate_content_preservation "$stage_file" "$temp_phase" "$stage_heading"; then
  rm -f "$temp_phase"
  error "Content validation failed - merge may have lost content"
fi

# Replace phase file with merged version
mv "$temp_phase" "$phase_file"
echo "✓ Content merged successfully"
```

**Merging**:
- Create backup before merging
- Use `merge_markdown_sections()` from shared utilities
- Validate content preservation
- Replace phase file atomically

### 6. Update Metadata (Three-Way Synchronization)

Update metadata in both phase file AND main plan (three-way sync).

```bash
echo "Updating metadata (three-way sync: stage → phase → main plan)..."

# === PART 1: Update Phase File Metadata ===

# Update Expanded Stages in phase file
phase_updated=$(update_expansion_metadata "$phase_file" "collapse" "stage" "$stage_num")
echo "$phase_updated" > "${phase_file}.tmp"
mv "${phase_file}.tmp" "$phase_file"

# If last stage, remove Expanded Stages metadata from phase file
if [[ "$is_last_stage" == true ]]; then
  sed -i '/^- \*\*Expanded Stages\*\*:/d' "$phase_file"
  echo "✓ Phase file metadata updated (Expanded Stages removed)"
else
  echo "✓ Phase file metadata updated (Stage $stage_num removed from list)"
fi

# === PART 2: Update Main Plan Metadata ===

# Create backup of main plan
backup_main="${main_plan}.backup.$$"
cp "$main_plan" "$backup_main"

# Update main plan's Expanded Stages dictionary
# Format: - **Expanded Stages**: {2: [1, 3], 5: [1]}
if [[ "$is_last_stage" == true ]]; then
  # Remove phase entry entirely from dictionary
  # This is complex - need to parse dictionary and remove phase_num entry

  awk -v phase="$phase_num" '
    /^- \*\*Expanded Stages\*\*:/ {
      # Extract dictionary content
      match($0, /\{(.*)\}/, arr)
      dict = arr[1]

      # Remove this phase entry
      # Handle various formats: "2: [1]", "2: [1, 3]", etc.
      gsub(phase ": \\[[^]]*\\],? ?", "", dict)
      gsub(", }", "}", dict)
      gsub("{, ", "{", dict)

      # Print updated line
      if (dict == "" || dict == " ") {
        print "- **Expanded Stages**: {}"
      } else {
        print "- **Expanded Stages**: {" dict "}"
      }
      next
    }
    { print }
  ' "$main_plan" > "${main_plan}.tmp"

  mv "${main_plan}.tmp" "$main_plan"
  echo "✓ Main plan metadata updated (Phase $phase_num entry removed)"

else
  # Remove stage from phase's stage list in dictionary
  # This requires more complex awk parsing

  awk -v phase="$phase_num" -v stage="$stage_num" '
    /^- \*\*Expanded Stages\*\*:/ {
      # Extract dictionary content
      match($0, /\{(.*)\}/, arr)
      dict = arr[1]

      # Find and update this phase entry
      # Parse phase entries: "2: [1, 3], 5: [1]"
      split(dict, entries, /,[ ]*([0-9]+:)/)

      # Build new dictionary (simplified approach)
      new_dict = dict

      # Remove stage from phase list
      # Pattern: "phase: [stages]"
      pattern = phase ": \\[([^]]*)\\]"
      if (match(new_dict, pattern, m)) {
        old_list = m[1]
        # Remove stage from list
        gsub("(^|, )" stage "($|,)", "", old_list)
        gsub(", ,", ",", old_list)
        gsub("^, ", "", old_list)
        gsub(", $", "", old_list)

        # Replace in dictionary
        if (old_list == "") {
          # If list now empty, remove phase entry
          gsub(phase ": \\[[^]]*\\],? ?", "", new_dict)
        } else {
          gsub(phase ": \\[[^]]*\\]", phase ": [" old_list "]", new_dict)
        }
      }

      # Clean up formatting
      gsub(", }", "}", new_dict)
      gsub("{, ", "{", new_dict)

      print "- **Expanded Stages**: {" new_dict "}"
      next
    }
    { print }
  ' "$main_plan" > "${main_plan}.tmp"

  mv "${main_plan}.tmp" "$main_plan"
  echo "✓ Main plan metadata updated (Stage $stage_num removed from Phase $phase_num)"
fi

# Update main plan Structure Level if needed
if [[ "$is_last_stage" == true ]]; then
  # Check if any other phases have expanded stages
  remaining_stages=$(grep "^- \*\*Expanded Stages\*\*:" "$main_plan" | grep -o '{.*}' | grep -o '[0-9]*: \[' | wc -l)

  if [[ $remaining_stages -eq 0 ]]; then
    # No more expanded stages - set Level to 1
    sed -i 's/^- \*\*Structure Level\*\*: 2$/- \*\*Structure Level\*\*: 1/' "$main_plan"
    # Remove Expanded Stages metadata entirely
    sed -i '/^- \*\*Expanded Stages\*\*:/d' "$main_plan"
    echo "✓ Main plan Structure Level set to 1 (no more expanded stages)"
  fi
fi

# Remove main plan backup
rm -f "$backup_main"
```

**Three-Way Metadata Updates**:
1. Update phase file Expanded Stages list
2. Update main plan Expanded Stages dictionary
3. Update main plan Structure Level if needed
4. Remove metadata fields if last stage

### 7. Directory Cleanup

If this was the last stage, move phase file to parent and remove directory.

```bash
if [[ "$is_last_stage" == true ]]; then
  echo "Performing directory cleanup (Level 2 → Level 1)..."

  # Target path for phase file (move to parent directory)
  parent_dir=$(dirname "$phase_path")
  target_phase="$parent_dir/$phase_base.md"

  # Move phase file to parent directory
  mv "$phase_file" "$target_phase"

  # Delete stage file
  rm "$stage_file"

  # Remove now-empty phase directory
  rmdir "$phase_path" 2>/dev/null || {
    echo "Warning: Directory not empty, manual cleanup may be needed: $phase_path"
  }

  # Remove backup
  rm -f "$backup_file"

  echo "✓ Directory cleanup complete"
  echo "  Phase file: $target_phase"
else
  # Just delete the stage file (directory retained)
  echo "Removing stage file..."
  rm "$stage_file"

  # Remove backup
  rm -f "$backup_file"

  echo "✓ Stage file removed"
  echo "  Directory retained (other stages still expanded)"
  echo "  Phase file: $phase_file"
fi
```

**Cleanup**:
- If last stage: Move phase file to parent, remove directory
- If not last: Only delete stage file
- Remove backup files
- Validate cleanup completed

### 8. Validation

Verify that the collapse operation completed successfully.

```bash
# Final validation
echo ""
echo "=== Collapse Validation ==="

if [[ "$is_last_stage" == true ]]; then
  # Validate Level 1 structure
  [[ -f "$target_phase" ]] && echo "✓ Phase file at parent: $target_phase"
  [[ ! -d "$phase_path" ]] && echo "✓ Phase directory removed"

  # Check phase file metadata
  if ! grep -q "^- \*\*Expanded Stages\*\*:" "$target_phase"; then
    echo "✓ Phase file Expanded Stages metadata removed"
  else
    echo "⚠ Phase file Expanded Stages metadata still present (expected removal)"
  fi

  # Check main plan metadata
  main_stages=$(grep "^- \*\*Expanded Stages\*\*:" "$main_plan" || echo "")
  if [[ -z "$main_stages" ]] || [[ ! "$main_stages" == *"$phase_num"* ]]; then
    echo "✓ Main plan metadata updated (Phase $phase_num entry removed or empty)"
  else
    echo "⚠ Main plan metadata may not be updated correctly"
  fi

else
  # Validate Level 2 structure (stage removed, directory retained)
  [[ -f "$phase_file" ]] && echo "✓ Phase file: $phase_file"
  [[ ! -f "$stage_file" ]] && echo "✓ Stage file removed"
  [[ -d "$phase_path" ]] && echo "✓ Directory retained"

  # Check phase file metadata
  expanded=$(grep "^- \*\*Expanded Stages\*\*:" "$phase_file" || echo "")
  if [[ -n "$expanded" ]] && [[ ! "$expanded" == *"$stage_num"* ]]; then
    echo "✓ Stage $stage_num removed from phase Expanded Stages"
  else
    echo "⚠ Phase Expanded Stages not updated correctly"
  fi

  # Check main plan metadata
  main_stages=$(grep "^- \*\*Expanded Stages\*\*:" "$main_plan" || echo "")
  if [[ -n "$main_stages" ]]; then
    echo "✓ Main plan metadata updated"
  else
    echo "⚠ Main plan Expanded Stages metadata missing"
  fi
fi

echo ""
echo "✅ Stage $stage_num collapsed successfully"
```

**Validation Checks**:
- [ ] Stage content merged into phase file
- [ ] Stage file deleted
- [ ] Phase file metadata updated
- [ ] Main plan metadata updated
- [ ] Directory state correct (removed if last, retained otherwise)
- [ ] No content loss during merge

## Quality Checklist

Before completing the collapse operation, verify:

- [ ] Stage content fully extracted and preserved
- [ ] Three-way metadata updated correctly (phase file + main plan)
- [ ] Directory removed only if last stage
- [ ] Phase file integrity validated
- [ ] Main plan integrity validated
- [ ] No content loss during merge
- [ ] All references to stage file updated
- [ ] Backup created and removed after success
- [ ] Error handling tested (rollback on failure)
- [ ] Dictionary parsing handles edge cases (empty lists, last entry, etc.)

## Error Handling

### Scenario 1: Stage File Not Found

**Symptom**: Stage file does not exist in phase directory

**Recovery**:
```bash
# List available stages
echo "Error: Stage $stage_num not found"
echo "Available stages:"
ls -1 "$phase_path"/stage_*.md 2>/dev/null | sed 's/.*stage_/  Stage /' | sed 's/_.*//'

# Check if directory exists
[[ -d "$phase_path" ]] || echo "Phase directory does not exist: $phase_path"
exit 1
```

### Scenario 2: Merge Conflict (Duplicate Sections)

**Symptom**: Phase file already contains full stage content

**Recovery**:
```bash
# Manual intervention required
echo "Error: Merge conflict detected"
echo "Phase file may already contain full stage content"
echo ""
echo "Options:"
echo "1. Review phase file manually: $phase_file"
echo "2. Review stage file manually: $stage_file"
echo "3. Manually merge and then delete stage file"
echo ""
echo "Backup created: $backup_file"
exit 1
```

### Scenario 3: Metadata Parsing Failure

**Symptom**: Cannot parse or update three-way metadata

**Recovery**:
```bash
# Rollback operation
echo "Error: Metadata update failed"
echo "Rolling back changes..."

# Restore from backups
mv "$backup_file" "$phase_file"
mv "$backup_main" "$main_plan"

echo "Changes rolled back. Files restored from backups."
echo "Original stage file preserved: $stage_file"
exit 1
```

### Scenario 4: Directory Removal Failure

**Symptom**: Cannot remove directory after last stage collapse

**Recovery**:
```bash
# Leave directory, warn user
echo "Warning: Could not remove directory: $phase_path"
echo ""
echo "Manual cleanup required:"
echo "  rm -rf $phase_path"
echo ""
echo "Stage content has been merged successfully."
echo "Directory cleanup is safe to perform manually."
# Continue (do not exit)
```

### Scenario 5: Main Plan Not Found

**Symptom**: Cannot locate main plan file for metadata update

**Recovery**:
```bash
echo "Error: Cannot locate main plan file"
echo "Expected locations:"
echo "  - $plan_dir/$plan_base.md"
echo "  - $plan_dir.md"
echo ""
echo "Phase file has been updated, but main plan metadata NOT synchronized."
echo "Manual metadata update required in main plan."
echo ""
echo "Backup created: $backup_file"
exit 1
```

## Validation Examples

### Example 1: Simple Collapse (Single Stage Expanded)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Phase file
    └── stage_1_backend.md          # Only expanded stage
```

**Command:**
```bash
/collapse-stage specs/plans/025_feature/phase_2_implementation/ 1
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Metadata updated (Level 2→1)
└── phase_2_implementation.md       # Moved to parent (Level 1)
```

**Expected Output:**
```
Phase directory: specs/plans/025_feature/phase_2_implementation
Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md
Phase number: 2
Main plan: specs/plans/025_feature/025_feature.md
Found stage file: stage_1_backend.md
Stage heading: #### Stage 1: Backend Implementation
This is the LAST expanded stage (Level 2 → Level 1)
Merging stage content into phase file...
✓ Content merged successfully
Updating metadata (three-way sync: stage → phase → main plan)...
✓ Phase file metadata updated (Expanded Stages removed)
✓ Main plan metadata updated (Phase 2 entry removed)
✓ Main plan Structure Level set to 1 (no more expanded stages)
Performing directory cleanup (Level 2 → Level 1)...
✓ Directory cleanup complete
  Phase file: specs/plans/025_feature/phase_2_implementation.md

=== Collapse Validation ===
✓ Phase file at parent: specs/plans/025_feature/phase_2_implementation.md
✓ Phase directory removed
✓ Phase file Expanded Stages metadata removed
✓ Main plan metadata updated (Phase 2 entry removed or empty)

✅ Stage 1 collapsed successfully
```

### Example 2: Multiple Stages Expanded (Not Last)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Phase file
    ├── stage_1_backend.md          # Stage to collapse
    └── stage_2_frontend.md         # Another expanded stage
```

**Command:**
```bash
/collapse-stage specs/plans/025_feature/phase_2_implementation/ 1
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Metadata updated
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Stage 1 content merged back
    └── stage_2_frontend.md         # Unchanged
```

**Expected Output:**
```
Phase directory: specs/plans/025_feature/phase_2_implementation
Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md
Phase number: 2
Main plan: specs/plans/025_feature/025_feature.md
Found stage file: stage_1_backend.md
Stage heading: #### Stage 1: Backend Implementation
Other expanded stages exist (Level 2 → Level 2)
Merging stage content into phase file...
✓ Content merged successfully
Updating metadata (three-way sync: stage → phase → main plan)...
✓ Phase file metadata updated (Stage 1 removed from list)
✓ Main plan metadata updated (Stage 1 removed from Phase 2)
Removing stage file...
✓ Stage file removed
  Directory retained (other stages still expanded)
  Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md

=== Collapse Validation ===
✓ Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md
✓ Stage file removed
✓ Directory retained
✓ Stage 1 removed from phase Expanded Stages
✓ Main plan metadata updated

✅ Stage 1 collapsed successfully
```

### Example 3: Last Stage of One Phase (Others Have Stages)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Expanded Stages: {2: [1], 5: [1, 2]}
├── phase_2_implementation/
│   ├── phase_2_implementation.md
│   └── stage_1_backend.md          # Last stage of phase 2
└── phase_5_deployment/
    ├── phase_5_deployment.md
    ├── stage_1_setup.md
    └── stage_2_migrate.md
```

**Command:**
```bash
/collapse-stage specs/plans/025_feature/phase_2_implementation/ 1
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Expanded Stages: {5: [1, 2]} (Level 2)
├── phase_2_implementation.md       # Collapsed to Level 1
└── phase_5_deployment/
    ├── phase_5_deployment.md
    ├── stage_1_setup.md
    └── stage_2_migrate.md
```

**Expected Output:**
```
Phase directory: specs/plans/025_feature/phase_2_implementation
Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md
Phase number: 2
Main plan: specs/plans/025_feature/025_feature.md
Found stage file: stage_1_backend.md
Stage heading: #### Stage 1: Backend Implementation
This is the LAST expanded stage (Level 2 → Level 1)
Merging stage content into phase file...
✓ Content merged successfully
Updating metadata (three-way sync: stage → phase → main plan)...
✓ Phase file metadata updated (Expanded Stages removed)
✓ Main plan metadata updated (Phase 2 entry removed)
Performing directory cleanup (Level 2 → Level 1)...
✓ Directory cleanup complete
  Phase file: specs/plans/025_feature/phase_2_implementation.md

=== Collapse Validation ===
✓ Phase file at parent: specs/plans/025_feature/phase_2_implementation.md
✓ Phase directory removed
✓ Phase file Expanded Stages metadata removed
✓ Main plan metadata updated (Phase 2 entry removed or empty)

✅ Stage 1 collapsed successfully
```

## Key Principles

1. **Content Preservation**: All stage content, tasks, and completion status must be preserved exactly
2. **Three-Way Synchronization**: Update stage → phase file → main plan atomically
3. **Atomic Operations**: Use backups and temp files to prevent partial failures
4. **Validation**: Verify content integrity and metadata consistency
5. **Clean Transitions**: Properly update metadata and structure for Level 2→1 or Level 2→2
6. **Reversibility**: Collapse can be undone via `/expand-stage`

## Integration with Other Commands

### Uses Shared Utilities
- `detect_last_item()` - Check if last stage
- `merge_markdown_sections()` - Merge content back to phase file
- `update_expansion_metadata()` - Update phase file metadata
- `validate_content_preservation()` - Verify merge succeeded

### Uses Parse Utilities
- `parse-adaptive-plan.sh` - Structure detection functions

### Complementary Commands
- `/expand-stage` - Opposite operation (Level 1→2 or Level 2→2)
- `/collapse-phase` - Used after collapsing all stages (requires Level 1)
- `/list-plans` - Show expansion status

## Standards Applied

Following CLAUDE.md Code Standards:
- **Indentation**: 2 spaces, expandtab (in code examples)
- **Error Handling**: Comprehensive validation and rollback
- **Documentation**: Clear operation description with examples
- **File Operations**: Safe atomic operations with temp files

## Notes

- Stage files are merged back maintaining original format
- Collapsing a stage does NOT mark it as complete or incomplete
- Task completion status is preserved during collapse
- Phase file structure is restored exactly as before expansion
- Collapse is fully reversible via `/expand-stage`
- Must collapse all stages before collapsing the phase itself
- Three-way metadata synchronization is complex - uses backups with rollback
- Dictionary parsing handles edge cases (empty lists, single entries, multiple phases)

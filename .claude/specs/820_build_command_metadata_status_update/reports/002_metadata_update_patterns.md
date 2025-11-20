# Metadata Update Patterns Research

## Overview

This report documents the existing patterns for metadata updates in the codebase and recommends the implementation approach for plan status updates.

## Existing Metadata Update Functions

### Pattern 1: Simple Field Update (plan-core-bundle.sh)

**Function**: `update_structure_level()`
**Location**: `.claude/lib/plan/plan-core-bundle.sh:277-307`

```bash
update_structure_level() {
  local plan_file="$1"
  local level="$2"

  # Check if metadata exists
  if grep -q "^- \*\*Structure Level\*\*:" "$plan_file"; then
    # Update existing
    sed -i "s/^- \*\*Structure Level\*\*:.*/- **Structure Level**: $level/" "$plan_file"
  else
    # Add after other metadata
    local temp_file=$(mktemp)
    awk -v lvl="$level" '
      /^- \*\*Structure Tier\*\*:/ {
        print
        print "- **Structure Level**: " lvl
        next
      }
      { print }
    ' "$plan_file" > "$temp_file"
    mv "$temp_file" "$plan_file"
  fi
}
```

**Key Characteristics**:
- Uses grep to check if field exists
- Uses sed for inline replacement
- Uses awk to add new field after related metadata
- Handles both update and create cases

### Pattern 2: List Metadata Update (plan-core-bundle.sh)

**Function**: `update_expanded_phases()`
**Location**: `.claude/lib/plan/plan-core-bundle.sh:310-346`

This handles list-style metadata like `[1, 2, 3]`. Not relevant for status updates.

### Pattern 3: Phase Heading Markers (checkbox-utils.sh)

**Function**: `add_complete_marker()`
**Location**: `.claude/lib/plan/checkbox-utils.sh:468-498`

```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  # First remove any existing status marker
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase && !/\[COMPLETE\]/) {
        sub(/$/, " [COMPLETE]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}
```

**Key Characteristics**:
- Removes existing markers before adding new one
- Uses awk for pattern matching and substitution
- Appends to end of line with `sub(/$/, " [MARKER]")`
- Works on phase headings (### Phase N:)

## Recommended Implementation Pattern

For `update_plan_status()`, we should combine:
- **Pattern 1's existence check** (grep + sed for update)
- **Pattern 3's approach** of using a cleanup function first

### Proposed Implementation

```bash
# Update plan metadata status field
# Usage: update_plan_status <plan_path> <status>
# status: "NOT STARTED", "IN PROGRESS", "COMPLETE", "BLOCKED"
update_plan_status() {
  local plan_path="$1"
  local status="$2"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # Validate status value
  case "$status" in
    "NOT STARTED"|"IN PROGRESS"|"COMPLETE"|"BLOCKED")
      ;;
    *)
      error "Invalid status: $status"
      return 1
      ;;
  esac

  # Check if Status field exists in metadata
  if grep -q "^- \*\*Status\*\*:" "$plan_path"; then
    # Update existing - handle any bracket content
    sed -i "s/^- \*\*Status\*\*:.*/- **Status**: [$status]/" "$plan_path"
  else
    # Add after Date field (first metadata field typically)
    local temp_file=$(mktemp)
    awk -v stat="$status" '
      /^- \*\*Date\*\*:/ {
        print
        print "- **Status**: [" stat "]"
        added = 1
        next
      }
      /^- \*\*Feature\*\*:/ && !added {
        print "- **Status**: [" stat "]"
        print
        added = 1
        next
      }
      { print }
    ' "$plan_path" > "$temp_file"
    mv "$temp_file" "$plan_path"
  fi

  return 0
}
```

### Helper Function: Check All Phases Complete

```bash
# Check if all phases in a plan are marked complete
# Usage: check_all_phases_complete <plan_path>
# Returns: 0 if all complete, 1 if any incomplete
check_all_phases_complete() {
  local plan_path="$1"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # Count total phases
  local total_phases=$(grep -c "^### Phase [0-9]" "$plan_path" 2>/dev/null || echo "0")

  if [[ "$total_phases" -eq 0 ]]; then
    # No phases found, consider complete
    return 0
  fi

  # Count phases with [COMPLETE] marker
  local complete_phases=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$plan_path" 2>/dev/null || echo "0")

  if [[ "$complete_phases" -eq "$total_phases" ]]; then
    return 0
  else
    return 1
  fi
}
```

## Integration Points

### Build Command Block 1 (Starting Implementation)

Add after state machine initialization:
```bash
# Update plan status to IN PROGRESS
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
if type update_plan_status &>/dev/null; then
  update_plan_status "$PLAN_FILE" "IN PROGRESS"
  echo "Plan status updated to [IN PROGRESS]"
fi
```

### Build Command Block 4 (Completion)

Add after all phases marked complete:
```bash
# Check if all phases complete and update metadata status
if check_all_phases_complete "$PLAN_FILE"; then
  update_plan_status "$PLAN_FILE" "COMPLETE"
  echo "✓ Plan metadata status updated to [COMPLETE]"
else
  echo "⚠ Some phases incomplete, status not updated"
fi
```

## Error Handling Considerations

1. **Missing Status Field**: Add after Date or Feature field if not present
2. **Invalid Status Value**: Return error, don't modify file
3. **File Not Found**: Return error early
4. **Mixed Completion States**: Only update to COMPLETE when ALL phases complete

## Testing Strategy

```bash
# Test 1: Update existing status
echo "- **Status**: [NOT STARTED]" > test.md
update_plan_status test.md "COMPLETE"
grep -q '\[COMPLETE\]' test.md && echo "PASS" || echo "FAIL"

# Test 2: All phases complete check
cat > test.md << 'EOF'
### Phase 1: Setup [COMPLETE]
### Phase 2: Build [COMPLETE]
EOF
check_all_phases_complete test.md && echo "PASS: All complete" || echo "FAIL"

# Test 3: Partial completion
cat > test.md << 'EOF'
### Phase 1: Setup [COMPLETE]
### Phase 2: Build [IN PROGRESS]
EOF
check_all_phases_complete test.md && echo "FAIL" || echo "PASS: Partial detected"
```

## Conclusion

The recommended approach:
1. Add `update_plan_status()` and `check_all_phases_complete()` to `checkbox-utils.sh`
2. Follow existing Pattern 1 for field updates
3. Integrate into `/build` at two points: Block 1 (start) and Block 4 (completion)
4. Validate with test cases covering all status transitions

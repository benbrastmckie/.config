# Topic Number Allocation Fix Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Fix topic number allocation to wrap correctly at 999→000
- **Scope**: Rename incorrectly allocated directory, add validation guards
- **Estimated Phases**: 3
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0 (Single File)
- **Complexity Score**: 12.0
- **Research Reports**:
  - [Topic Number Allocation Analysis](../reports/001-topic-number-allocation-analysis.md)

## Overview

Topic number 1000 was incorrectly allocated when it should have wrapped to 003. This occurred because the orchestrator executed manual bash blocks that bypassed the proper `initialize_workflow_paths()` function, using ad-hoc topic number calculation without modulo wrapping.

**Root Cause**: Manual bash execution bypassed documented workflow, missing the `% 1000` modulo operation.

**Solution**:
1. Rename the incorrectly allocated directory from 1000_* to the next available number
2. Update any references to the old path
3. Add validation to catch future allocation errors

## Research Summary

The analysis confirmed:
- The `allocate_and_create_topic()` function in unified-location-detection.sh correctly implements wrapping: `$(( (10#$max + 1) % 1000 ))`
- The bug was in manual bash code that used `$((${LAST_NUM:-0} + 1))` without wrapping
- The /repair command itself is correctly implemented; the issue was orchestrator bypass

## Success Criteria

- [ ] Directory 1000_repair_todo_20251201_111414 is renamed to 004_repair_todo_20251201_111414
- [ ] Plan file path references are updated in TODO.md
- [ ] Topic number validation passes (all numbers are 3-digit, 000-999)
- [ ] No directory names start with 1000 or higher in specs/

## Technical Design

### Phase 1: Directory Rename

Rename the incorrectly allocated directory:
- FROM: `.claude/specs/1000_repair_todo_20251201_111414/`
- TO: `.claude/specs/004_repair_todo_20251201_111414/`

### Phase 2: Reference Update

Update references in:
- `.claude/TODO.md` - plan file paths

### Phase 3: Validation

Add a validation check to ensure no directories have numbers >= 1000.

---

## Implementation Phases

### Phase 1: Rename Incorrectly Allocated Directory
**Status**: [NOT STARTED]
**Dependencies**: none

**Objective**: Rename 1000_repair_todo_20251201_111414 to use correct topic number 004

**Tasks**:
- [ ] Verify current directory state in specs/
- [ ] Determine next available number after wrapping (should be 004)
- [ ] Rename directory: `mv 1000_repair_todo_20251201_111414 004_repair_todo_20251201_111414`
- [ ] Verify rename succeeded

**Validation**:
```bash
# Verify no 1000+ directories exist
ls -1d .claude/specs/[0-9]* | grep -E '/[0-9]{4,}_' && echo "FAIL: Found 4+ digit topic numbers" || echo "PASS: All topic numbers are 3 digits"
```

---

### Phase 2: Update References
**Status**: [NOT STARTED]
**Dependencies**: [Phase 1]

**Objective**: Update file references that point to the old 1000_* path

**Tasks**:
- [ ] Check TODO.md for references to 1000_repair_todo_20251201_111414
- [ ] Update path references to use 004_repair_todo_20251201_111414
- [ ] Check if any other files reference the old path

**Validation**:
```bash
# Search for any remaining references to 1000_
grep -r "1000_repair_todo" .claude/ && echo "FAIL: Found old references" || echo "PASS: No old references"
```

---

### Phase 3: Add Validation Guard
**Status**: [NOT STARTED]
**Dependencies**: [Phase 2]

**Objective**: Add validation to catch future topic number allocation errors

**Tasks**:
- [ ] Create validation script `.claude/scripts/validate-topic-numbers.sh`
- [ ] Script should check all specs/ directories for valid 3-digit numbers
- [ ] Add to pre-commit hook validation (optional)

**Validation Script**:
```bash
#!/usr/bin/env bash
# validate-topic-numbers.sh - Ensures all topic directories use 3-digit numbers (000-999)

SPECS_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}/.claude/specs"

invalid_dirs=$(ls -1d "$SPECS_ROOT"/[0-9]* 2>/dev/null | while read dir; do
  num=$(basename "$dir" | grep -oE '^[0-9]+')
  if [ ${#num} -ne 3 ] || [ "$num" -gt 999 ]; then
    echo "$dir"
  fi
done)

if [ -n "$invalid_dirs" ]; then
  echo "ERROR: Found directories with invalid topic numbers (must be 000-999):"
  echo "$invalid_dirs"
  exit 1
fi

echo "PASS: All topic directories have valid 3-digit numbers"
exit 0
```

---

## Testing Strategy

### Unit Tests
1. Verify directory rename completed successfully
2. Verify no references to old path remain
3. Verify validation script catches invalid numbers

### Integration Tests
1. Run /todo to verify TODO.md still parses correctly
2. Run /plan to verify new topic allocation wraps correctly

---

## Documentation Requirements

- Update troubleshooting docs if any mention topic number allocation
- No new user-facing documentation needed (internal fix)

---

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| unified-location-detection.sh | Library | Existing (correct) |
| workflow-initialization.sh | Library | Existing (correct) |

---

## Notes

- The core allocation logic is correct; this is a cleanup of a one-time error
- Future prevention relies on orchestrators following documented bash blocks
- Consider adding topic number validation to the pre-commit hook for ongoing protection

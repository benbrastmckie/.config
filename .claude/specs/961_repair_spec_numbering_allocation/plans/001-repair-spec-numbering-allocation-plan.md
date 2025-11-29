# Fix /repair Command Spec Directory Numbering

## Metadata
- **Date**: 2025-11-29
- **Feature**: Fix /repair command to always allocate new spec directory numbers
- **Scope**: Modify topic naming to generate unique topic names for /repair workflows
- **Estimated Phases**: 4
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 35.0
- **Research Reports**:
  - [Repair Numbering Bug Analysis](/home/benjamin/.config/.claude/specs/961_repair_spec_numbering_allocation/reports/001_repair_numbering_bug_analysis.md)
  - [Timestamp-Based Naming Revision](/home/benjamin/.config/.claude/specs/961_repair_spec_numbering_allocation/reports/002_repair_timestamp_naming_revision.md)

## Overview

The /repair command currently reuses existing spec directories when topic names match due to idempotent behavior in workflow-initialization.sh (lines 553-560). While this is desirable for most commands, it's problematic for /repair because:

1. Each repair run represents a NEW error analysis at a different point in time
2. Reusing old directories loses historical tracking of different repair attempts
3. Users expect fresh spec directories when running /repair

This plan implements **direct timestamp-based naming** for /repair, completely bypassing the topic-naming-agent (Haiku LLM subagent). Instead of invoking an agent to generate semantic names, the command will construct topic names directly in bash using timestamps and optional filter context.

## Research Summary

Research analysis (002_repair_timestamp_naming_revision.md) revealed:

- The current /repair uses topic-naming-agent (Haiku LLM subagent) which adds 2-3 second latency and has ~2-5% failure rate
- LLM-based naming requires ~150 lines of code (agent invocation + validation + fallback)
- Direct timestamp-based naming can achieve the same uniqueness guarantee with ~15 lines of bash
- Performance comparison: <10ms (timestamp) vs 2-3s (LLM), zero failures vs ~2-5% failure rate
- Timestamp approach provides built-in chronological sorting and eliminates API costs
- Filter context (--command, --type) can be included in the topic name for semantic value

## Success Criteria

- [ ] /repair generates unique timestamp-based topic names for each invocation
- [ ] Topic names include filter context (--command or --type) when provided
- [ ] Idempotent reuse is bypassed due to timestamp uniqueness
- [ ] Historical repair runs are preserved in separate directories
- [ ] LLM-based naming completely removed (zero API calls)
- [ ] Tests verify unique allocation on consecutive /repair runs
- [ ] Documentation explains timestamp naming pattern with examples

## Technical Design

### Architecture Decision

Replace the entire LLM-based topic naming flow (lines 277-426 in repair.md) with direct timestamp-based topic name generation. This eliminates the topic-naming-agent Task invocation, output file validation, and fallback logic.

### Implementation Approach

**Direct Timestamp-Based Naming** (RECOMMENDED)
```bash
# Generate timestamp-based topic name directly (REPLACES lines 277-426)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -n "$ERROR_COMMAND" ]; then
  # Include command context: /repair --command /build → repair_build_20251129_143022
  COMMAND_SLUG=$(echo "$ERROR_COMMAND" | sed 's:^/::' | tr '-' '_')
  TOPIC_NAME="repair_${COMMAND_SLUG}_${TIMESTAMP}"
elif [ -n "$ERROR_TYPE" ]; then
  # Include error type: /repair --type state_error → repair_state_error_20251129_143022
  ERROR_TYPE_SLUG=$(echo "$ERROR_TYPE" | tr '-' '_')
  TOPIC_NAME="repair_${ERROR_TYPE_SLUG}_${TIMESTAMP}"
else
  # Generic repair: /repair → repair_20251129_143022
  TOPIC_NAME="repair_${TIMESTAMP}"
fi

NAMING_STRATEGY="timestamp_direct"
echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
```

**Key Benefits**:
- Eliminates ~150 lines of LLM invocation/validation code
- Zero API costs vs $0.003 per run
- <10ms latency vs 2-3 seconds
- Zero failure rate vs ~2-5% LLM failures
- Built-in chronological sorting
- Guaranteed uniqueness via timestamp

### Component Interactions

```
/repair command
  └─> Direct timestamp generation (bash)
      └─> TOPIC_NAME="repair_${TIMESTAMP}" (e.g., "repair_build_20251129_143022")
          └─> CLASSIFICATION_JSON with pre-calculated topic name
              └─> workflow-initialization.sh (initialize_workflow_paths)
                  └─> validate_topic_directory_slug() (validates format)
                      └─> allocate_and_create_topic()
                          └─> Creates new numbered directory (e.g., 962_repair_build_20251129_143022/)
```

**No LLM Agent Invocation**: The topic-naming-agent Task call is completely removed.

### Files Modified

1. **/home/benjamin/.config/.claude/commands/repair.md**
   - **Lines 270-303**: REMOVE entire topic-naming-agent Task invocation block
   - **Lines 374-426**: REMOVE entire agent output validation block
   - **Lines 277** (new): ADD direct timestamp-based topic name generation (~15 lines)
   - **Lines 432**: KEEP CLASSIFICATION_JSON creation (uses pre-calculated topic name)
   - **Lines 435**: KEEP initialize_workflow_paths() call (no changes)

## Implementation Phases

### Phase 1: Replace LLM Naming with Direct Timestamp Generation [COMPLETE]
dependencies: []

**Objective**: Remove topic-naming-agent invocation and replace with direct timestamp-based topic name generation

**Complexity**: Medium

Tasks:
- [x] Read current repair.md to identify exact line ranges for removal
- [x] DELETE lines 277-303 (Task tool invocation for topic-naming-agent)
- [x] DELETE lines 374-426 (agent output file validation and fallback logic)
- [x] DELETE lines 270-273 (TOPIC_NAMING_INPUT_FILE creation)
- [x] DELETE lines 427-429 (temp file cleanup)
- [x] ADD timestamp generation logic after line 274 (Block 1 completion):
  ```bash
  # Generate timestamp-based topic name directly
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)

  if [ -n "$ERROR_COMMAND" ]; then
    COMMAND_SLUG=$(echo "$ERROR_COMMAND" | sed 's:^/::' | tr '-' '_')
    TOPIC_NAME="repair_${COMMAND_SLUG}_${TIMESTAMP}"
  elif [ -n "$ERROR_TYPE" ]; then
    ERROR_TYPE_SLUG=$(echo "$ERROR_TYPE" | tr '-' '_')
    TOPIC_NAME="repair_${ERROR_TYPE_SLUG}_${TIMESTAMP}"
  else
    TOPIC_NAME="repair_${TIMESTAMP}"
  fi

  NAMING_STRATEGY="timestamp_direct"
  echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
  ```
- [x] KEEP lines 432-435 (CLASSIFICATION_JSON creation and initialize_workflow_paths call)
- [x] Verify TOPIC_NAME is available for CLASSIFICATION_JSON creation

Testing:
```bash
# Verify timestamp format is valid
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "$TIMESTAMP" | grep -Eq '^[0-9]{8}_[0-9]{6}$'
[ $? -eq 0 ] && echo "PASS: Valid timestamp format" || echo "FAIL: Invalid timestamp"

# Verify topic name passes validation regex
TOPIC_NAME="repair_build_${TIMESTAMP}"
echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'
[ $? -eq 0 ] && echo "PASS: Valid topic name" || echo "FAIL: Invalid topic name"
```

**Expected Duration**: 1.5 hours

### Phase 2: Validate Unique Topic Name Generation [COMPLETE]
dependencies: [1]

**Objective**: Test that timestamp-based naming generates unique names for consecutive /repair runs

**Complexity**: Low

Tasks:
- [x] Run /repair twice with 1-second delay between invocations
- [x] Verify different timestamps generated for each run
- [x] Verify topic names include filter context when --command or --type provided
- [x] Verify topic names pass validation regex: `^[a-z0-9_]{5,40}$`
- [x] Verify two distinct spec directories created (no reuse)
- [x] Test edge case: same-second invocations (should have different timestamps due to second precision)

Testing:
```bash
# Test with --command filter
/repair --command /build --since 1h
FIRST_DIR=$(ls -1dt .claude/specs/[0-9][0-9][0-9]_repair_build_* 2>/dev/null | head -1)
sleep 1
/repair --command /build --since 1h
SECOND_DIR=$(ls -1dt .claude/specs/[0-9][0-9][0-9]_repair_build_* 2>/dev/null | head -1)

# Verify different directories
[ "$FIRST_DIR" != "$SECOND_DIR" ] && echo "PASS: Unique directories" || echo "FAIL: Directories match"

# Test with --type filter
/repair --type state_error --since 1h
THIRD_DIR=$(ls -1dt .claude/specs/[0-9][0-9][0-9]_repair_state_error_* 2>/dev/null | head -1)

# Verify naming pattern includes filter
echo "$THIRD_DIR" | grep -q "repair_state_error_" && echo "PASS: Type in name" || echo "FAIL: Type missing"
```

**Expected Duration**: 1 hour

### Phase 3: Integration Testing with Idempotent Bypass [COMPLETE]
dependencies: [2]

**Objective**: Verify timestamp uniqueness bypasses idempotent reuse and other commands remain unaffected

**Complexity**: Medium

Tasks:
- [x] Run /repair with identical filters 3+ times (2-second intervals)
- [x] Verify each run creates new numbered directory (timestamp guarantees uniqueness)
- [x] Verify allocate_and_create_topic() allocates sequential numbers correctly
- [x] Verify idempotent behavior still works for other commands (/plan, /research)
- [x] Verify no "existing topic" match occurs (timestamps always unique)
- [x] Verify directory numbering increments correctly (962, 963, 964...)

Testing:
```bash
# Test consecutive /repair runs with identical filters
for i in 1 2 3; do
  /repair --type state_error --since 1h
  sleep 2  # Ensure different timestamps
done

# Verify 3 different spec directories created
UNIQUE_DIRS=$(ls -1dt .claude/specs/[0-9][0-9][0-9]_repair_state_error_* 2>/dev/null | head -3 | wc -l)
[ "$UNIQUE_DIRS" -eq 3 ] && echo "PASS: Each run created new directory" || echo "FAIL: Directory reused"

# Verify sequential numbering
SPEC_NUMS=$(ls -1d .claude/specs/[0-9][0-9][0-9]_repair_state_error_* 2>/dev/null | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort -n | tail -3)
echo "$SPEC_NUMS" | grep -q "962.*963.*964" && echo "PASS: Sequential numbers" || echo "INFO: Numbers may not be consecutive (other commands running)"

# Verify other commands still have idempotent behavior
/plan "test feature" --complexity 1
PLAN_DIR_1=$(ls -1dt .claude/specs/*test_feature* 2>/dev/null | head -1)
/plan "test feature" --complexity 1
PLAN_DIR_2=$(ls -1dt .claude/specs/*test_feature* 2>/dev/null | head -1)
[ "$PLAN_DIR_1" = "$PLAN_DIR_2" ] && echo "PASS: /plan idempotent" || echo "FAIL: /plan not idempotent"
```

**Expected Duration**: 1.5 hours

### Phase 4: Documentation and Cleanup [COMPLETE]
dependencies: [3]

**Objective**: Document timestamp-based naming pattern and update related documentation

**Complexity**: Low

Tasks:
- [x] Update repair.md documentation section explaining timestamp-based topic naming
- [x] Add comment in code explaining direct timestamp generation (no LLM)
- [x] Document in repair-command-guide.md that each run creates new timestamped spec directory
- [x] Add examples showing naming patterns for different filter combinations
- [x] Update topic-naming-with-llm.md to note /repair as exception (uses timestamps, not LLM)
- [x] Update TODO.md to mark this task complete
- [x] Clean up any test fixtures created during development

Testing:
```bash
# Verify documentation mentions timestamp naming
grep -q "timestamp-based" .claude/commands/repair.md
grep -q "repair_.*_[0-9]\{8\}_[0-9]\{6\}" .claude/docs/guides/commands/repair-command-guide.md

# Verify comment explains no LLM usage
grep -q "Generate timestamp-based topic name directly" .claude/commands/repair.md
grep -q "bypasses topic-naming-agent" .claude/commands/repair.md || grep -q "no LLM invocation" .claude/commands/repair.md

# Verify exception documented
grep -q "/repair.*exception" .claude/docs/guides/development/topic-naming-with-llm.md || echo "Add exception note"
```

**Expected Duration**: 1 hour

### Phase 5: Update Error Log Status [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED

Tasks:
- [x] Verify all fixes are working (tests pass, no new errors generated)
- [x] Update error log entries to RESOLVED status:
  ```bash
  source .claude/lib/core/error-handling.sh
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "${PLAN_PATH}")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```
- [x] Verify no FIX_PLANNED errors remain for this plan:
  ```bash
  REMAINING=$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c "$(basename "$(dirname "$(dirname "${PLAN_PATH}")")" )" || echo "0")
  [ "$REMAINING" -eq 0 ] && echo "All errors resolved" || echo "WARNING: $REMAINING errors still FIX_PLANNED"
  ```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Tests
- Test timestamp format generation (`date +%Y%m%d_%H%M%S`)
- Test command slug sanitization (strip leading `/`, convert `-` to `_`)
- Test type slug sanitization (convert `-` to `_`)
- Test topic name validation regex (`^[a-z0-9_]{5,40}$`)
- Test all three naming branches (base, --command, --type)

### Integration Tests
- Full /repair workflow with timestamp-based unique directory allocation
- Verify idempotent behavior preserved for /plan and /research
- Test consecutive /repair runs with 1-2 second intervals
- Verify no LLM agent invocation (no topic-naming-agent Task call)
- Verify CLASSIFICATION_JSON creation with pre-calculated topic name

### Regression Tests
- Existing /repair functionality (error filtering, report generation, planning)
- Other commands using workflow-initialization.sh (no impact expected)
- Verify validate_topic_directory_slug() accepts timestamp-based names
- Verify allocate_and_create_topic() works with timestamp names

### Coverage Requirements
- All three naming branches covered (base, --command, --type)
- Edge cases: rapid consecutive runs, very long command names (truncation)
- Cross-command interaction: /repair (timestamp) vs /plan (LLM) naming
- No temp file creation/cleanup needed (validate removal)

## Documentation Requirements

### User-Facing Documentation
- Update `/repair` command help text to explain timestamp-based unique directory creation
- Add examples to repair-command-guide.md showing naming patterns:
  - `/repair` → `962_repair_20251129_143022/`
  - `/repair --command /build` → `963_repair_build_20251129_143530/`
  - `/repair --type state_error` → `964_repair_state_error_20251129_144105/`
- Document that /repair is the only command using timestamp naming (exception)

### Developer Documentation
- Comment in repair.md explaining direct timestamp generation (no LLM)
- Add note in topic-naming-with-llm.md about /repair exception
- Update CHANGELOG.md with behavior change (LLM → timestamp)
- Document performance improvement (2-3s speedup per /repair run)

### Code Comments
- Inline comment explaining timestamp-based naming: "Generate timestamp-based topic name directly (bypasses topic-naming-agent)"
- Comment explaining why: "Ensures unique allocation for each repair run (historical error tracking)"
- Comment noting filter context inclusion: "Include --command or --type in topic name for semantic value"

## Dependencies

### External Dependencies
- None (uses standard bash `date` command, `sed`, `tr`)

### Internal Dependencies
- workflow-initialization.sh (validate_topic_directory_slug validates format, idempotent check fails due to timestamp uniqueness)
- unified-location-detection.sh (allocate_and_create_topic allocates new numbers correctly)
- state-persistence.sh (TOPIC_NAME persisted for later blocks)

### No Longer Used
- topic-naming-agent.md (REMOVED - no longer invoked for /repair)
- Task tool for LLM agent invocation (REMOVED from repair.md)
- TOPIC_NAMING_INPUT_FILE and TOPIC_NAME_FILE temp files (REMOVED)

### Prerequisites
- Research reports 001_repair_numbering_bug_analysis.md and 002_repair_timestamp_naming_revision.md completed
- Understanding of timestamp uniqueness guaranteeing bypass of idempotent reuse
- Understanding that other commands (/plan, /research) still use LLM-based naming

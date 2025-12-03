# Lean Command Metadata and Phase Header Update Implementation Plan

## Metadata

- **Date**: 2025-12-03
- **Feature**: Remove mandatory Lean File metadata requirement and add real-time phase header progress tracking to /lean command
- **Scope**: Enhance /lean command flexibility with optional metadata discovery and integrate checkbox-utils.sh for real-time progress visibility
- **Status**: [COMPLETE]
- **Estimated Hours**: 6-8 hours
- **Complexity Score**: 45.0
- **Structure Level**: 0
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Command Metadata and Phase Header Updates Research](../reports/001_research_report.md)

## Overview

The /lean command currently has two limitations compared to /implement:

1. **Mandatory Lean File Metadata**: The command requires `**Lean File**: /path` in plan metadata, failing if missing. This is overly restrictive since different phases may work on different Lean files.

2. **Missing Real-Time Progress Tracking**: lean-coordinator and lean-implementer agents don't update phase status markers ([IN PROGRESS], [COMPLETE]) during execution. Users cannot track progress by inspecting the plan file during long proof sessions.

This plan addresses both issues by implementing optional metadata with fallback discovery and integrating checkbox-utils.sh progress tracking following the /implement pattern.

## Research Summary

The research report analyzed the /lean command workflow and identified:

**Issue 1 Solution**: Make Lean File metadata optional with 3-tier fallback discovery:
1. Check plan metadata (backward compatible)
2. Scan phase tasks for .lean file references
3. Search topic directory for .lean files

**Issue 2 Solution**: Integrate checkbox-utils.sh in lean-implementer following /implement pattern:
- Add `add_in_progress_marker()` at phase start (non-fatal)
- Add `add_complete_marker()` at phase completion (with fallback)
- Pass phase_number from lean-coordinator to lean-implementer

**Key Patterns Identified**:
- Graceful degradation for progress markers (non-fatal error handling)
- Fallback to mark_phase_complete() if add_complete_marker() validation fails
- Dynamic file discovery (no mandatory metadata)

## Success Criteria

- [ ] Lean File metadata is optional with backward compatibility
- [ ] 3-tier fallback discovery works (metadata → task scan → directory search)
- [ ] Clear error message with 3 options if all discovery methods fail
- [ ] Phase markers update in real-time during execution
- [ ] lean-implementer sources checkbox-utils.sh (non-fatal)
- [ ] lean-implementer marks phases [IN PROGRESS] and [COMPLETE]
- [ ] lean-coordinator passes phase_number to lean-implementer
- [ ] Progress tracking degrades gracefully if library unavailable
- [ ] All existing /lean functionality preserved
- [ ] Real-time progress visible via `cat plan.md` during execution

## Technical Design

### Architecture Changes

**1. Lean File Discovery (Block 1a Enhancement)**:
- Modify /lean command Block 1a (lines 154-173)
- Add 3-tier fallback discovery logic:
  - Tier 1: Extract from plan metadata (optional)
  - Tier 2: Scan phase tasks for .lean file references using grep
  - Tier 3: Find .lean files in topic directory
- Maintain validation that discovered file exists
- Provide informative error with discovery options if all tiers fail

**2. Progress Tracking Integration (lean-implementer)**:
- Add checkbox-utils.sh sourcing at agent initialization
- Add progress tracking setup section after continuation handling
- Mark phase [IN PROGRESS] before theorem proving loop
- Mark phase [COMPLETE] after successful theorem completion
- Use non-fatal error handling (warnings, not failures)
- Implement fallback to mark_phase_complete() if validation fails

**3. Phase Number Propagation (lean-coordinator)**:
- Extract phase_number from theorem_tasks array
- Pass phase_number in lean-implementer invocation
- Update input contract documentation

**4. Error Handling Strategy**:
- Progress marker failures are non-fatal (log warnings)
- Gracefully degrade if checkbox-utils.sh unavailable
- Fallback to mark_phase_complete() if add_complete_marker() fails
- Continue theorem proving even if markers fail

### Integration Points

- /lean command Block 1a: Lean file discovery logic
- lean-implementer agent: Progress tracking initialization and completion
- lean-coordinator agent: Phase number extraction and propagation
- checkbox-utils.sh library: add_in_progress_marker(), add_complete_marker(), mark_phase_complete()

### Backward Compatibility

- Plans with existing Lean File metadata work unchanged
- Plans without metadata use fallback discovery
- File-based mode (non-plan) works unchanged
- Progress tracking only applies to plan-based mode

## Implementation Phases

### Phase 1: Optional Lean File Metadata with Fallback Discovery [COMPLETE]
dependencies: []

**Objective**: Make Lean File metadata optional in /lean command Block 1a with 3-tier fallback discovery

**Complexity**: Low

**Tasks**:
- [x] Read current /lean command Block 1a (lines 154-173)
- [x] Replace mandatory metadata check with 3-tier discovery:
  - [x] Tier 1: Check plan metadata using existing grep pattern (backward compatible)
  - [x] Tier 2: If empty, scan phase tasks for .lean file paths using grep -oP
  - [x] Tier 3: If still empty, search topic directory using find
- [x] Update error handling:
  - [x] Change validation_error message to show 3 discovery options
  - [x] Keep file_error for discovered file not found
- [x] Add informative echo statements for discovery method used
- [x] Preserve file existence validation for discovered file

**Testing**:
```bash
# Test Case 1: Plan with metadata (backward compatibility)
# Verify metadata path used, echo "Lean File: /path (from metadata)"

# Test Case 2: Plan without metadata, task references
# Verify task scan works, echo "Lean File: /path (from task scan)"

# Test Case 3: Plan without metadata, directory has .lean file
# Verify directory search works, echo "Lean File: /path (from directory)"

# Test Case 4: No discovery methods succeed
# Verify error shows 3 options
```

**Expected Duration**: 2 hours

### Phase 2: Progress Tracking Integration in lean-implementer [COMPLETE]
dependencies: [1]

**Objective**: Integrate checkbox-utils.sh progress tracking in lean-implementer agent for real-time phase marker updates

**Complexity**: Medium

**Tasks**:
- [x] Read lean-implementer.md input contract (lines 48-63)
- [x] Add phase_number parameter to input contract:
  - [x] Document as optional parameter (plan-based mode only)
  - [x] Default empty or 0 for file-based mode
- [x] Add progress tracking initialization after continuation handling:
  - [x] Source checkbox-utils.sh with 2>/dev/null (non-fatal)
  - [x] Check if plan_path provided and non-empty
  - [x] Call add_in_progress_marker() with error suppression
  - [x] Log warning on failure, continue execution
- [x] Add phase completion marker after theorem proving loop:
  - [x] Call add_complete_marker() after all theorems processed
  - [x] Implement fallback to mark_phase_complete() on validation failure
  - [x] Log warnings on marker failures
  - [x] Always continue (non-fatal)
- [x] Update lean-implementer documentation:
  - [x] Document new phase_number parameter
  - [x] Document progress tracking behavior
  - [x] Document graceful degradation on failures

**Testing**:
```bash
# Test Case 1: Plan-based mode with phase_number
# Verify [IN PROGRESS] appears, then [COMPLETE] after execution

# Test Case 2: File-based mode (no plan_path)
# Verify progress tracking skipped, no errors

# Test Case 3: checkbox-utils.sh unavailable
# Verify warning logged, theorem proving continues

# Test Case 4: add_complete_marker validation fails
# Verify fallback to mark_phase_complete, marker added
```

**Expected Duration**: 3 hours

### Phase 3: Phase Number Propagation in lean-coordinator [COMPLETE]
dependencies: [2]

**Objective**: Update lean-coordinator to extract phase_number from theorem_tasks and pass to lean-implementer invocations

**Complexity**: Low

**Tasks**:
- [x] Read lean-coordinator.md Task invocation section (lines 287-375)
- [x] Extract phase_number from theorem_tasks array:
  - [x] Parse phase_number from first theorem object in batch
  - [x] Default to wave_number if phase_number not present
- [x] Update lean-implementer Task invocation:
  - [x] Add phase_number parameter to input contract
  - [x] Pass extracted phase_number value
- [x] Update lean-coordinator documentation:
  - [x] Document phase_number extraction logic
  - [x] Document phase_number passing to implementer
- [x] Verify propagation doesn't affect file-based mode

**Testing**:
```bash
# Test Case 1: Wave with multiple theorems, same phase
# Verify all implementers receive correct phase_number

# Test Case 2: Wave with theorems from different phases
# Verify each implementer receives correct phase_number for its theorem

# Test Case 3: File-based mode (no phases)
# Verify phase_number omitted or 0, no errors
```

**Expected Duration**: 1.5 hours

### Phase 4: Integration Testing and Documentation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Validate end-to-end functionality with comprehensive test cases and update documentation

**Complexity**: Medium

**Tasks**:
- [x] Create test plan with Lean File metadata:
  - [x] Run /lean with metadata, verify backward compatibility
  - [x] Verify progress markers appear in real-time
- [x] Create test plan without Lean File metadata:
  - [x] Tasks reference .lean file, verify task scan discovery
  - [x] No task references, .lean in directory, verify directory discovery
  - [x] Verify progress markers work with discovered file
- [x] Test Level 1 expanded plan structure:
  - [x] Verify markers appear in both phase files and parent plan
  - [x] Test propagate_progress_marker() integration
- [x] Test graceful degradation scenarios:
  - [x] Simulate checkbox-utils.sh unavailable
  - [x] Simulate add_complete_marker() validation failure
  - [x] Verify warnings logged, execution continues
- [x] Test file-based mode (no plan):
  - [x] Verify Lean file processed directly
  - [x] Verify progress tracking skipped (no plan_path)
- [x] Update command documentation:
  - [x] Document optional Lean File metadata
  - [x] Document 3-tier discovery fallback
  - [x] Document real-time progress tracking
  - [x] Add examples for all discovery methods
- [x] Update lean-implementer documentation:
  - [x] Document phase_number parameter
  - [x] Document progress tracking integration
- [x] Update lean-coordinator documentation:
  - [x] Document phase_number propagation

**Testing**:
```bash
# Integration Test 1: Full workflow with metadata
/lean plan.md --prove-all
# Verify: Metadata used, all markers appear in real-time

# Integration Test 2: Full workflow without metadata
/lean plan-no-metadata.md --prove-all
# Verify: Discovery succeeds, markers appear

# Integration Test 3: Real-time visibility check
# Terminal 1: /lean plan.md --prove-all
# Terminal 2: watch -n 1 "grep -E '^### Phase.*\[' plan.md"
# Verify: Markers update during execution

# Integration Test 4: Level 1 plan (expanded phases)
/lean plan-with-phases/plan.md --prove-all
# Verify: Markers in phase_N.md and parent plan

# Integration Test 5: Graceful degradation
# Rename checkbox-utils.sh temporarily
/lean plan.md --prove-all
# Verify: Warning logged, theorem proving continues
```

**Expected Duration**: 2.5 hours

## Testing Strategy

### Unit Testing

**Phase 1**: Test each discovery tier independently
- Metadata extraction with valid/invalid formats
- Task scanning with various .lean path patterns
- Directory search with single/multiple .lean files
- Error handling with no discovery success

**Phase 2**: Test progress tracking functions
- add_in_progress_marker() with valid/invalid inputs
- add_complete_marker() with complete/incomplete phases
- mark_phase_complete() fallback behavior
- Non-fatal error handling (warnings, not exits)

**Phase 3**: Test phase_number propagation
- Extraction from theorem_tasks array
- Passing to lean-implementer invocations
- Behavior with missing phase_number field

### Integration Testing

**End-to-End Workflows**:
1. Plan with metadata → Verify backward compatibility, progress tracking
2. Plan without metadata, task references → Verify task scan, progress tracking
3. Plan without metadata, directory file → Verify directory scan, progress tracking
4. Level 1 expanded plan → Verify hierarchical marker propagation
5. File-based mode → Verify direct processing, no progress tracking

**Error Recovery Testing**:
1. checkbox-utils.sh unavailable → Verify warning, continue
2. add_complete_marker() validation fails → Verify fallback, continue
3. All discovery tiers fail → Verify informative error with options

### Performance Testing

- Verify discovery adds <500ms overhead per invocation
- Verify progress marker updates <100ms per phase
- Verify no performance regression for existing workflows

## Documentation Requirements

### Command Documentation Updates

**File**: `.claude/commands/lean.md`
- Update Block 1a description with optional metadata and discovery
- Add section documenting 3-tier fallback discovery
- Add examples for each discovery method
- Document progress tracking in plan-based mode
- Update error messages documentation

### Agent Documentation Updates

**File**: `.claude/agents/lean-implementer.md`
- Update input contract with phase_number parameter
- Add progress tracking section documenting integration
- Document graceful degradation behavior
- Add examples showing progress marker updates

**File**: `.claude/agents/lean-coordinator.md`
- Document phase_number extraction from theorem_tasks
- Document phase_number passing to lean-implementer
- Update Task invocation examples

### User-Facing Documentation

**File**: `.claude/docs/guides/commands/lean-command-guide.md` (if exists)
- Add section on Lean File discovery methods
- Add real-time progress tracking examples
- Document `watch` command for monitoring progress

## Dependencies

### External Dependencies

- bash 4.0+ (for array handling)
- grep with -oP flag (PCRE support)
- find command (directory traversal)
- awk (phase number extraction)

### Internal Dependencies

**Libraries**:
- checkbox-utils.sh (lines 440-508): add_in_progress_marker(), add_complete_marker()
- checkbox-utils.sh (lines 188-277): mark_phase_complete()
- checkbox-utils.sh (lines 554-590): verify_phase_complete()

**Commands**:
- /lean command (Block 1a: lines 154-173)

**Agents**:
- lean-implementer (lines 48-63: input contract, lines 105+: integration points)
- lean-coordinator (lines 287-375: Task invocations)

### Version Requirements

- checkbox-utils.sh: >=1.0 (existing functions)
- /lean command: Current version
- Lean 4 project: No changes required
- lean-lsp-mcp: No changes required

## Risk Assessment

### Low Risk

- Phase 1 (Metadata discovery): Backward compatible, graceful fallback
- Phase 3 (Phase number propagation): Simple parameter passing

### Medium Risk

- Phase 2 (Progress tracking): Complex integration, multiple failure modes
  - Mitigation: Non-fatal error handling throughout
  - Mitigation: Extensive testing of fallback scenarios

### Technical Risks

1. **Progress marker validation failures**: add_complete_marker() may fail if tasks incomplete
   - Mitigation: Fallback to mark_phase_complete() (force marking)
   - Mitigation: Log warnings for debugging

2. **Library sourcing failures**: checkbox-utils.sh may be unavailable
   - Mitigation: Non-fatal sourcing with 2>/dev/null
   - Mitigation: Type checks before function calls

3. **Level 1 plan compatibility**: Expanded phases require special handling
   - Mitigation: checkbox-utils.sh already supports Level 1 via propagate_progress_marker()
   - Mitigation: Test thoroughly with expanded plans

## Notes

### Design Decisions

**Decision 1**: Make metadata optional vs remove entirely
- **Choice**: Optional with fallback discovery
- **Rationale**: Backward compatibility, explicit metadata still useful for clarity

**Decision 2**: Non-fatal vs fatal progress marker failures
- **Choice**: Non-fatal (warnings only)
- **Rationale**: Theorem proving is core functionality, progress tracking is enhancement

**Decision 3**: Fallback discovery order (metadata → tasks → directory)
- **Choice**: Metadata first (explicit), then tasks (contextual), then directory (scan)
- **Rationale**: Prefer explicit over implicit, prefer task context over filesystem scan

### Implementation Notes

**Progress Tracking Pattern** (from /implement):
```bash
# Source library (non-fatal)
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "Warning: Progress tracking unavailable" >&2
}

# Mark IN PROGRESS (non-fatal)
if type add_in_progress_marker &>/dev/null; then
  add_in_progress_marker "$plan_path" "$phase_num" 2>/dev/null || {
    echo "Warning: Failed to add [IN PROGRESS] marker" >&2
  }
fi

# After completion, mark COMPLETE (with fallback)
if type add_complete_marker &>/dev/null; then
  add_complete_marker "$plan_path" "$phase_num" 2>/dev/null || {
    # Fallback to force marking
    if type mark_phase_complete &>/dev/null; then
      mark_phase_complete "$plan_path" "$phase_num" 2>/dev/null || {
        echo "Warning: All marker methods failed" >&2
      }
    fi
  }
fi
```

**Discovery Pattern** (new):
```bash
# Tier 1: Metadata (optional)
LEAN_FILE=$(grep -E "^\*\*Lean File\*\*:|^- \*\*Lean File\*\*:" "$PLAN_FILE" | sed ...)

# Tier 2: Task scan
if [ -z "$LEAN_FILE" ]; then
  LEAN_FILE=$(grep -oP '(?<=\s)/[^\s]+\.lean' "$PLAN_FILE" | head -1)
fi

# Tier 3: Directory search
if [ -z "$LEAN_FILE" ]; then
  TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
  LEAN_FILE=$(find "$TOPIC_PATH" -name "*.lean" -type f | head -1)
fi

# Validation
if [ -z "$LEAN_FILE" ]; then
  echo "ERROR: No Lean file found. Specify via:" >&2
  echo "  1. Plan metadata: **Lean File**: /path" >&2
  echo "  2. Task description: - [ ] Prove theorem in /path.lean" >&2
  echo "  3. Topic directory: Place .lean file in topic" >&2
  exit 1
fi
```

### Future Enhancements

- Auto-discovery of multiple .lean files for multi-file projects
- Progress tracking for file-based mode (theorem-level markers)
- Time estimates based on proof complexity
- Parallel progress tracking dashboard (not just `cat plan.md`)

## Validation Checklist

Before marking plan complete:
- [ ] All 4 phases have clear objectives
- [ ] All phases have specific tasks with file references
- [ ] All phases have testing sections
- [ ] All phases have estimated durations
- [ ] Dependencies are explicit ([1], [2], [1,2,3])
- [ ] Success criteria are measurable
- [ ] Technical design addresses both issues
- [ ] Research findings incorporated
- [ ] Backward compatibility preserved
- [ ] Error handling is comprehensive
- [ ] Documentation updates planned
- [ ] All file paths are absolute

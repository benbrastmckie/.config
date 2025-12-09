# Implementation Plan: Optimize /lean-implement Command

## Metadata

- **Date**: 2025-12-08
- **Feature**: Optimize /lean-implement command performance and infrastructure integration
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-11 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [lean-implement Command Optimization Analysis](../reports/001-optimize-lean-implement-command-analysis.md)

## Objective

Improve /lean-implement command performance by 96% context reduction through brief summary parsing, fix continuation plan failures with improved phase number extraction, and enhance infrastructure integration by adopting validation-utils.sh library and defensive parsing patterns. Research identified 7 optimization opportunities with cumulative benefits: Phase 1-3 fixes reduce code duplication by 80% and context usage by 24%, while laying foundation for future wave-based parallelization (Phase 4).

## Success Criteria

- [ ] Phase number extraction works with non-contiguous phase numbers (continuation plans)
- [ ] Validation logic replaced with validation-utils.sh library (24 lines removed)
- [ ] Brief summary parsing implemented (9,600 tokens saved per iteration)
- [ ] Defensive work_remaining conversion handles JSON array format
- [ ] Context aggregation and checkpoint saving operational
- [ ] Tier-2 classification keywords refined (reduced false positives)
- [ ] Documentation updated: lean-implement-command-guide.md, plan-metadata-standard.md, command-reference.md
- [ ] All tests pass with new optimizations

## Phases

### Phase 1: Core Fixes (Low-Hanging Fruit) [COMPLETE]

**Duration**: 2-3 hours

This phase implements critical fixes for continuation plan support and code duplication reduction.

**Tasks**:

- [x] **Task 1.1**: Fix phase number extraction in Block 1a-classify (lines 502-516)
  - Replace `seq 1 "$TOTAL_PHASES"` with direct grep extraction: `grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n`
  - Update loop to iterate over extracted phase numbers: `for phase_num in $PHASE_NUMBERS; do`
  - Verify with continuation plan test (phases 5, 7, 9 only)
  - File: `.claude/commands/lean-implement.md` Block 1a-classify

- [x] **Task 1.2**: Replace inline validation with validation-utils.sh library (lines 134-163)
  - Remove `validate_lean_implement_prerequisites()` function (30 lines)
  - Add validation-utils.sh to Tier 1 library sourcing
  - Replace validation call with: `validate_workflow_prerequisites || exit 1`
  - Add Lean-specific graceful degradation check: `command -v lake &>/dev/null` with WARNING
  - File: `.claude/commands/lean-implement.md` Block 1a

- [x] **Task 1.3**: Add defensive work_remaining parsing (lines 970-981)
  - Add JSON array detection: `if [[ "$WORK_REMAINING_NEW" =~ ^[[:space:]]*\[ ]]; then`
  - Convert JSON array to space-separated string: strip `[]`, remove commas, normalize whitespace
  - Add INFO log: "Converting work_remaining from JSON array to space-separated string"
  - Test with mock coordinator output: `work_remaining: ["Phase_3", "Phase_4"]`
  - File: `.claude/commands/lean-implement.md` Block 1c

- [x] **Task 1.4**: Refine tier-2 classification keywords (lines 462-480)
  - Move software indicators before file extension check
  - Require proof-related context with .lean extension: `grep -qE '\\.(lean)\\b' && grep -qE 'theorem\\b|lemma\\b|proof\\b'`
  - Add test case: Phase with task "Update Perpetuity.lean documentation" (should classify as software)
  - File: `.claude/commands/lean-implement.md` Block 1a-classify

**Checkpoint**: Run against continuation plan with phases 4, 6, 8; verify classification succeeds and validation uses library functions.

### Phase 2: Context Optimization (High Impact) [COMPLETE]

**Duration**: 4-6 hours

This phase implements brief summary parsing for 96% context reduction and context aggregation for graceful exhaustion handling.

**Tasks**:

- [x] **Task 2.1**: Implement brief summary parsing from coordinator return signal (lines 936-1000)
  - Parse coordinator output fields from return signal (not file): `coordinator_type`, `summary_brief`, `phases_completed`, `work_remaining`, `context_usage_percent`
  - Use sed/grep pattern: `grep -E "^field_name:" | sed 's/^field_name:[[:space:]]*//' | head -1`
  - Add fallback to file parsing with WARNING: "Coordinator output missing summary_brief, falling back to file parsing"
  - Test backward compatibility with legacy summaries (no summary_brief field)
  - Expected context reduction: 2,000 tokens → 400 tokens per iteration
  - File: `.claude/commands/lean-implement.md` Block 1c

- [x] **Task 2.2**: Add context aggregation section after parsing coordinator output (new section in Block 1c)
  - Extract context usage from parsed CONTEXT_USAGE_PERCENT variable
  - Validate numeric format with defensive check: `[[ "$CONTEXT_USAGE_PERCENT" =~ ^[0-9]+$ ]]`
  - Compare against CONTEXT_THRESHOLD (default: 90%)
  - Add WARNING log when threshold exceeded: "Context usage at ${AGGREGATED_CONTEXT}% (threshold: ${CONTEXT_THRESHOLD}%)"
  - File: `.claude/commands/lean-implement.md` Block 1c

- [x] **Task 2.3**: Implement checkpoint saving on context threshold exceeded (new section in Block 1c)
  - Source checkpoint-utils.sh library (Tier 2)
  - Build checkpoint data JSON with jq: plan_path, topic_path, iteration, max_iterations, work_remaining, context_usage_percent, halt_reason
  - Call `save_checkpoint "lean_implement" "$WORKFLOW_ID" "$checkpoint_data"`
  - Set `REQUIRES_CONTINUATION="false"` to trigger halt
  - Log checkpoint file path: "Checkpoint saved: $checkpoint_file"
  - File: `.claude/commands/lean-implement.md` Block 1c

- [x] **Task 2.4**: Update iteration decision logic to respect context threshold halt
  - Check REQUIRES_CONTINUATION="false" in iteration decision (line 1037)
  - Emit appropriate halt message: "Context threshold exceeded, checkpoint saved for resume"
  - Persist halt_reason in workflow state: "context_threshold_exceeded"
  - Test with mocked context usage: 95%
  - File: `.claude/commands/lean-implement.md` Block 1c

**Checkpoint**: Run 5-iteration workflow with mocked context usage progression (50%, 65%, 78%, 92%, completion). Verify checkpoint saved at 92%, workflow halts gracefully, and brief summary parsing reduces token count.

### Phase 3: Documentation Updates [COMPLETE]

**Duration**: 2 hours

This phase updates documentation to reflect new optimizations and patterns.

**Tasks**:

- [x] **Task 3.1**: Update lean-implement-command-guide.md
  - Add troubleshooting section: "Continuation Plans" with phase number extraction explanation
  - Document brief summary parsing pattern with context reduction metrics
  - Add context aggregation section with checkpoint examples
  - Include configuration options: CONTEXT_THRESHOLD environment variable
  - File: `.claude/docs/guides/commands/lean-implement-command-guide.md`

- [x] **Task 3.2**: Update plan-metadata-standard.md
  - Add optional metadata field documentation: `implementer:` (values: lean, software)
  - Document usage in hybrid Lean/software plans
  - Add example plan snippet showing phase-level implementer field
  - Note: Tier 1 classification priority (strongest signal)
  - File: `.claude/docs/reference/standards/plan-metadata-standard.md`

- [x] **Task 3.3**: Update command-reference.md
  - Verify /lean-implement entry reflects current capabilities
  - Add context management features: threshold, checkpoint saving
  - Document execution modes: auto, lean-only, software-only
  - Add brief summary parsing benefit: "96% context reduction per iteration"
  - File: `.claude/docs/reference/standards/command-reference.md`

**Checkpoint**: Manual verification of documentation examples; ensure all cross-references valid.

### Phase 4: Testing and Validation [COMPLETE]

**Duration**: 2-3 hours

This phase creates test cases and validates all optimizations work correctly.

**Tasks**:

- [x] **Task 4.1**: Create continuation plan test case
  - Generate plan with non-contiguous phases: 1, 3, 5, 7
  - Mark phases 1, 3 as COMPLETE
  - Run /lean-implement starting at phase 5
  - Verify phase classification succeeds without "Phase 2: [SKIPPED - no content]" errors
  - Test file: `.claude/tests/commands/lean-implement/continuation-plan-test.md`

- [x] **Task 4.2**: Create context threshold test case
  - Create mock plan with 3 phases
  - Mock coordinator to return increasing context usage: 65%, 82%, 95%
  - Set CONTEXT_THRESHOLD=90
  - Verify checkpoint saved when context reaches 95%
  - Verify workflow halts with "context_threshold_exceeded" reason
  - Test file: `.claude/tests/commands/lean-implement/context-threshold-test.sh`

- [x] **Task 4.3**: Create brief summary parsing test
  - Mock coordinator return signal with summary_brief field
  - Verify parsing extracts fields correctly
  - Test fallback to file parsing when summary_brief missing
  - Measure token count reduction: full file vs brief parsing
  - Test file: `.claude/tests/commands/lean-implement/brief-summary-parsing-test.sh`

- [x] **Task 4.4**: Create work_remaining defensive parsing test
  - Mock coordinator with JSON array output: `["Phase_3", "Phase_4"]`
  - Verify conversion to space-separated: "Phase_3 Phase_4"
  - Mock coordinator with string output: "Phase_3 Phase_4" (no conversion)
  - Test both formats produce correct state machine behavior
  - Test file: `.claude/tests/commands/lean-implement/work-remaining-parsing-test.sh`

- [x] **Task 4.5**: Run integration test with mixed Lean/software plan
  - Use existing hybrid plan from research (045_complete_soundness_metalogic_plan)
  - Run /lean-implement in dry-run mode
  - Verify classification output matches expected routing map
  - Verify no regressions in coordinator invocation
  - Document results in test summary

**Checkpoint**: All tests pass; no regressions in existing functionality.

## Infrastructure Improvements (Future Work)

The research identified three infrastructure enhancement opportunities deferred to future optimization cycle:

### Shared Phase Routing Library (Deferred)
- **Complexity**: Medium (6-8 hours)
- **Benefit**: Single source of truth for phase classification across commands
- **File**: `.claude/lib/workflow/phase-routing.sh`
- **Functions**: `extract_phase_numbers()`, `classify_phase_type()`, `build_routing_map()`

### Context Budget Management Library (Deferred)
- **Complexity**: Medium (6-8 hours)
- **Benefit**: Centralized context estimation and checkpoint coordination
- **File**: `.claude/lib/workflow/context-budget.sh`
- **Functions**: `estimate_context_usage()`, `check_context_threshold()`

### Wave-Based Parallel Coordinator Invocation (Deferred)
- **Complexity**: High (12-16 hours)
- **Benefit**: 40-60% time savings for mixed Lean/software plans with independent phases
- **Scope**: Major refactor of Blocks 1a-classify and 1b for wave analysis and parallel Task invocation
- **Challenge**: Routing map wave structure, metric aggregation from simultaneous coordinators, error handling complexity

## Notes

### Implementation Strategy

Implement Phases 1-3 immediately (8-11 hours total) for maximum ROI:
- Phase 1: Core fixes prevent continuation plan failures, reduce duplication
- Phase 2: Context optimization provides 24% reduction in 5-iteration workflows
- Phase 3: Documentation ensures discoverability and maintainability

Defer Phase 4 infrastructure improvements (24+ hours) to future cycle when complexity/benefit ratio improves.

### Key Design Decisions

1. **Brief Summary Parsing**: Parse coordinator return signal (stdout), fallback to file only on missing fields (backward compatibility)
2. **Validation Library Adoption**: Replace 30 lines inline validation with 2 lines library call (validation-utils.sh)
3. **Phase Number Extraction**: Direct grep extraction instead of sequential iteration (handles continuation plans correctly)
4. **Context Threshold**: Default 90%, configurable via CONTEXT_THRESHOLD environment variable
5. **Defensive Parsing**: Convert JSON array to space-separated string (coordinator output format variance)

### Testing Approach

- **Unit Tests**: Isolated tests for phase extraction, parsing, validation library integration
- **Integration Tests**: Full workflow test with mixed Lean/software plan
- **Regression Tests**: Verify no existing functionality broken (coordinator invocation, state machine, checkpoints)
- **Performance Tests**: Measure context reduction with brief summary parsing (target: 96% reduction = 9,600 tokens saved per iteration)

### Backward Compatibility

All changes maintain backward compatibility:
- Brief summary parsing falls back to file reading if field missing
- Phase number extraction works with both contiguous and non-contiguous numbering
- Defensive work_remaining parsing handles both JSON array and space-separated string formats
- Validation library adoption doesn't change validation behavior, only implementation

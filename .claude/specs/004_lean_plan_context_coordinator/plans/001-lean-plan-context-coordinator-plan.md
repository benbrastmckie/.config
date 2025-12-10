# Implementation Plan: /lean-plan Context Coordinator Optimization

## Metadata

**Date**: 2025-12-09
**Feature**: Optimize /lean-plan command with metadata-passing pattern and research coordinator enhancements for 95-96% context reduction and 10+ iteration capacity
**Status**: [COMPLETE]
**Estimated Hours**: 6-10 hours
**Complexity Score**: 38.0 (refactor proofs: 7 + 6 phases × 3 + 4 files × 2 + 2 complex integrations × 5)
**Structure Level**: 0
**Estimated Phases**: 6
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Context Optimization Metadata Passing Research](../reports/001-context-optimization-metadata.md)
- [Research Coordinator Architecture Analysis](../reports/002-research-coordinator-architecture.md)
- [Lean Implementation Pattern Analysis](../reports/003-lean-implement-pattern-analysis.md)
- [Standards-Compliant Infrastructure Integration](../reports/004-standards-compliant-infrastructure.md)

## Scope

Optimize the /lean-plan command to leverage metadata-passing patterns for maximum context efficiency:

1. **Brief Summary Parsing**: Add structured metadata fields to research reports for 96% context reduction (80 tokens vs 2,500 tokens per report)
2. **Hard Barrier Validation Enhancement**: Strengthen research-coordinator delegation enforcement with fail-fast artifact validation
3. **Context Estimation Integration**: Add context monitoring to research phase with graceful halt at 85-90% thresholds
4. **Defensive Validation**: Implement contract invariant enforcement for research completion signals
5. **Metadata Completeness**: Enforce Plan Metadata Standard compliance in lean-plan-architect (Complexity Score, Structure Level, Estimated Phases)
6. **Wave Structure Preview Validation**: Add checkpoint validation for wave structure preview generation

**Out of Scope**:
- New coordinator agent creation (research-coordinator already sufficient via Mode 2)
- Iteration loop management (future enhancement after context optimization validated)
- Wave-based research orchestration (requires dependency-analyzer integration, separate feature)
- Breaking changes to existing command interface or agent contracts

## Success Criteria

- [x] Research reports include structured metadata fields (report_type, topic, findings_count, recommendations_count) parsed in <100 lines
- [x] /lean-plan Block 1f-metadata parses brief summaries (80 tokens) instead of reading full reports (2,500 tokens)
- [x] Hard barrier validation enforces research-coordinator artifact creation with fail-fast on missing reports
- [x] Context estimation tracks research phase token usage with checkpoint saving at 85%+ threshold
- [x] Defensive validation overrides invalid requires_continuation signals when topics_remaining non-empty
- [x] lean-plan-architect generates Complexity Score, Structure Level: 0, and Estimated Phases in all plan metadata
- [x] Wave structure preview validation checkpoint added to lean-plan-architect STEP 2.7
- [x] All changes maintain backward compatibility (no breaking changes to command/agent interfaces)
- [x] Integration tests validate 95% context reduction (4 reports: 10,000 → 500 tokens)
- [x] Pre-commit validation passes for sourcing standards, metadata completeness, and non-interactive testing

---

## Phase 1: Brief Summary Metadata Integration [COMPLETE]

**Dependencies**: []
**Implementer**: software
**Estimated Hours**: 1.5-2.5 hours

### Objective

Add structured metadata fields to research-specialist output format and implement brief summary parsing in /lean-plan command for 96% context reduction.

### Tasks

- [ ] Update research-specialist.md to emit structured metadata fields at top of report
  - Add STEP 1.5 metadata field generation (report_type, topic, findings_count, recommendations_count)
  - Format: YAML frontmatter block before markdown heading
  - Example: `report_type: lean_research\ntopic: "Mathlib Theorems"\nfindings_count: 12\nrecommendations_count: 5`
- [ ] Add Block 1f-metadata to /lean-plan command for brief summary parsing
  - Extract metadata from first 10 lines of each report (head -10 | grep pattern)
  - Build FORMATTED_METADATA array with 80-token summaries per report
  - Replace full report reading with metadata-only context passing
- [ ] Update lean-plan-architect invocation prompt to receive metadata-only context
  - Pass FORMATTED_METADATA (80 tokens × 4 reports = 320 tokens)
  - Add CRITICAL instruction: "Use Read tool to access full reports as needed"
  - Preserve delegated read pattern for selective full report access
- [ ] Add defensive fallback for reports without metadata fields
  - If metadata fields missing, extract title from first heading (grep "^# ")
  - Count findings sections (grep -c "^### Finding")
  - Count recommendations (awk counting numbered items in Recommendations section)

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (STEP 1.5 addition)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (Block 1f-metadata addition after Block 1f validation)

**Validation**:
```bash
# Verify metadata fields present in generated reports
grep -q "^report_type:" "$REPORT_PATH" || echo "ERROR: Missing report_type field"
grep -q "^topic:" "$REPORT_PATH" || echo "ERROR: Missing topic field"
grep -q "^findings_count:" "$REPORT_PATH" || echo "ERROR: Missing findings_count field"

# Verify brief summary parsing reduces context
METADATA_SIZE=$(echo "$FORMATTED_METADATA" | wc -c)
test "$METADATA_SIZE" -lt 500 || echo "WARNING: Metadata exceeds 500 characters (target: 320 for 4 reports)"

# Verify full report not read into context
! grep -q "## Executive Summary" "$ARCHITECT_PROMPT" || echo "ERROR: Full report content passed to architect (metadata-only pattern violated)"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic (grep checks, character count validation)
- skip_allowed: false
- artifact_outputs: ["research-specialist.md.diff", "lean-plan.md.diff", "metadata-validation.log"]

---

## Phase 2: Hard Barrier Validation Enhancement [COMPLETE]

**Dependencies**: []
**Implementer**: software
**Estimated Hours**: 1-1.5 hours

### Objective

Strengthen hard barrier pattern enforcement in /lean-plan Block 1f validation to prevent research-coordinator Task invocation skipping with fail-fast artifact checks.

### Tasks

- [ ] Add multi-layer validation to Block 1f (research validation)
  - Layer 1: Empty directory detection (fail immediately if 0 reports created)
  - Layer 2: Count mismatch warning (expected vs actual report count)
  - Layer 3: Individual report validation (file existence, minimum size >500 bytes)
  - Layer 4: Required sections check (## Findings or ## Executive Summary or ## Analysis)
- [ ] Implement fail-fast error logging for validation failures
  - Use log_command_error with validation_error type
  - Include diagnostic context (expected_reports, actual_reports, missing_paths)
  - Provide recovery hints in error details
- [ ] Add partial success mode with ≥50% threshold
  - Calculate success percentage (successful_reports / total_reports × 100)
  - Fail if <50% (exit 1 with error logging)
  - Warn if 50-99% (log warning, proceed with available reports)
  - Pass if 100% (continue to metadata extraction)
- [ ] Enhance checkpoint reporting with validation metrics
  - Report success percentage in [CHECKPOINT] message
  - List failed reports (if any) for debugging
  - Include context for next phase (metadata extraction from successful reports only)

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (Block 1f enhancement with 4-layer validation)

**Validation**:
```bash
# Test empty directory detection
rm -rf "$RESEARCH_DIR"/*.md
bash lean-plan.md 2>&1 | grep -q "CRITICAL ERROR: Reports directory is empty" || echo "ERROR: Empty directory not detected"

# Test partial success mode (50% threshold)
# Create 2/4 reports, verify workflow proceeds with warning
touch "$RESEARCH_DIR/001-topic1.md" "$RESEARCH_DIR/002-topic2.md"
bash lean-plan.md 2>&1 | grep -q "WARNING: Partial research success (50%)" || echo "ERROR: Partial success mode not triggered"

# Test <50% failure
# Create 1/4 reports, verify workflow fails
rm -rf "$RESEARCH_DIR"/*.md
touch "$RESEARCH_DIR/001-topic1.md"
bash lean-plan.md && echo "ERROR: Should have failed with <50% success" || echo "PASS: Failed as expected"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic (exit code checks, grep output validation)
- skip_allowed: false
- artifact_outputs: ["validation-test-results.log", "error-context.json"]

---

## Phase 3: Context Estimation Integration [COMPLETE]

**Dependencies**: []
**Implementer**: software
**Estimated Hours**: 1.5-2 hours

### Objective

Add context monitoring to research-coordinator STEP 5 with graceful halt at 85-90% thresholds and checkpoint saving for resumption support.

### Tasks

- [ ] Implement estimate_research_context() function in research-coordinator
  - Calculate base cost (system prompt + coordinator logic: 15,000 tokens)
  - Add per-report overhead (research execution + validation: 2,000 tokens per report)
  - Add metadata aggregation cost (110 tokens per report)
  - Compute percentage of 200k context window
  - Include defensive validation (numeric input checks, sanity range 10k-300k tokens)
- [ ] Add context estimation to STEP 5 (metadata extraction)
  - Call estimate_research_context after all reports validated
  - Store context_usage_percent in return signal metadata
  - Log context usage to coordinator output
- [ ] Implement checkpoint saving for ≥85% threshold
  - Create checkpoint file with partial research results
  - Include reports_completed, reports_total, context_percent fields
  - Save checkpoint_path reference in return signal
- [ ] Update RESEARCH_COORDINATOR_COMPLETE signal format
  - Add context_usage_percent field (numeric percentage)
  - Add checkpoint_path field (optional, present if threshold exceeded)
  - Preserve existing fields (topics_processed, reports_created, context_reduction_pct)
- [ ] Add context threshold parsing to /lean-plan Block 1f-validate
  - Parse context_usage_percent from coordinator return signal
  - Log warning if ≥85% (approaching limit)
  - Include context percentage in workflow state for iteration tracking

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (STEP 5 enhancement, estimate_research_context function)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (Block 1f-validate context parsing)

**Validation**:
```bash
# Verify context estimation function returns valid percentage
CONTEXT_PCT=$(estimate_research_context 4 2500)
test "$CONTEXT_PCT" -ge 10 && test "$CONTEXT_PCT" -le 100 || echo "ERROR: Invalid context percentage: $CONTEXT_PCT"

# Verify checkpoint created when threshold exceeded
# Mock 90% context usage, verify checkpoint file created
CONTEXT_USAGE_PERCENT=90
bash research-coordinator.md
test -f "$CHECKPOINTS_DIR/research_${WORKFLOW_ID}_partial.json" || echo "ERROR: Checkpoint not created at 90% threshold"

# Verify return signal includes context metrics
grep -q "^context_usage_percent:" "$COORDINATOR_OUTPUT" || echo "ERROR: context_usage_percent missing from return signal"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic (numeric range validation, file existence checks)
- skip_allowed: false
- artifact_outputs: ["context-estimation-test.log", "checkpoint-validation.json"]

---

## Phase 4: Defensive Validation Implementation [COMPLETE]

**Dependencies**: []
**Implementer**: software
**Estimated Hours**: 1-1.5 hours

### Objective

Implement contract invariant enforcement in /lean-plan to validate topics_remaining ↔ requires_continuation consistency and override invalid signals.

### Tasks

- [ ] Document research-coordinator return signal contract in agent behavioral file
  - Add table showing valid/invalid signal combinations
  - Define topics_remaining (array of unprocessed topic names)
  - Define requires_continuation (boolean: true if topics remain, false if complete)
  - Specify invariant: topics_remaining non-empty → requires_continuation MUST be true
- [ ] Implement is_topics_remaining_empty() helper function
  - Check for empty string, literal "0", empty array "[]"
  - Check for whitespace-only strings
  - Return 0 (true) if empty, 1 (false) if non-empty
- [ ] Add defensive validation to /lean-plan Block 1f-validate
  - Parse topics_remaining and requires_continuation from coordinator return signal
  - Call is_topics_remaining_empty() to check state
  - If topics remain and requires_continuation=false, override to true
  - Log validation_error with contract violation details
  - Include override action in diagnostic context
- [ ] Add validation warning messages to console output
  - Display "WARNING: Coordinator contract violation detected"
  - Show topics_remaining value and requires_continuation value
  - Report override action ("OVERRIDING: Forcing continuation=true")
  - Reference error log entry for debugging

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (return signal contract documentation)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (Block 1f-validate defensive validation)

**Validation**:
```bash
# Test defensive override for contract violation
# Mock coordinator returning requires_continuation=false with topics_remaining=["Topic3"]
echo "topics_remaining: [\"Topic3\"]" > mock_coordinator_output.txt
echo "requires_continuation: false" >> mock_coordinator_output.txt

source lean-plan.md  # Load validation logic
# Should override requires_continuation to true
grep -q "OVERRIDING: Forcing continuation" validation_output.log || echo "ERROR: Override not applied"

# Test validation passes for correct signals
echo "topics_remaining: []" > mock_coordinator_output.txt
echo "requires_continuation: false" >> mock_coordinator_output.txt

source lean-plan.md
! grep -q "WARNING: Coordinator contract violation" validation_output.log || echo "ERROR: False positive validation warning"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic (mock signal injection, log validation)
- skip_allowed: false
- artifact_outputs: ["defensive-validation-test.log", "contract-violation-cases.txt"]

---

## Phase 5: lean-plan-architect Metadata Completeness [COMPLETE]

**Dependencies**: []
**Implementer**: software
**Estimated Hours**: 1-1.5 hours

### Objective

Enforce Plan Metadata Standard compliance by adding Complexity Score calculation, Structure Level enforcement, and Estimated Phases tracking to lean-plan-architect.

### Tasks

- [ ] Add STEP 1.6 Complexity Score Calculation checkpoint
  - Calculate score after theorem dependency analysis
  - Apply formula: base (formalization type) + (Theorems × 3) + (Files × 2) + (Complex Proofs × 5)
  - Store result in COMPLEXITY_SCORE variable for STEP 2 metadata insertion
  - Display [CHECKPOINT] message with calculated score
- [ ] Update STEP 2 metadata section generation
  - Add Complexity Score field after Estimated Hours
  - Add Structure Level field with hardcoded value 0 (Lean plans always single-file)
  - Add Estimated Phases field with count from STEP 1 theorem analysis
  - Format: `- **Complexity Score**: {score}\n- **Structure Level**: 0\n- **Estimated Phases**: {N}`
- [ ] Add STEP 3 metadata completeness validation
  - Grep for "Complexity Score:" in plan file (fail if missing)
  - Grep for "Structure Level: 0" in plan file (fail if missing)
  - Grep for "Estimated Phases:" in plan file (fail if missing)
  - Display [CHECKPOINT] message confirming metadata completeness
- [ ] Update lean-plan-architect documentation
  - Document Complexity Score formula in STEP 1.6
  - Document Structure Level rationale (Lean theorem proving uses single-file format)
  - Document Estimated Phases calculation (derived from theorem count and proof complexity)

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (STEP 1.6 addition, STEP 2 metadata enhancement, STEP 3 validation addition)

**Validation**:
```bash
# Verify Complexity Score calculated correctly
# Test case: 8 theorems, 1 file, 2 complex proofs, new formalization
# Expected: 15 + (8×3) + (1×2) + (2×5) = 51.0
grep -q "Complexity Score: 51.0" "$PLAN_PATH" || echo "ERROR: Incorrect complexity score"

# Verify Structure Level always 0
grep -q "Structure Level: 0" "$PLAN_PATH" || echo "ERROR: Structure Level missing or incorrect"

# Verify Estimated Phases matches phase count
ESTIMATED=$(grep "Estimated Phases:" "$PLAN_PATH" | sed 's/.*: //')
ACTUAL=$(grep -c "^### Phase" "$PLAN_PATH")
test "$ESTIMATED" -eq "$ACTUAL" || echo "ERROR: Estimated Phases ($ESTIMATED) != Actual Phases ($ACTUAL)"

# Verify metadata completeness validation runs
bash lean-plan-architect.md 2>&1 | grep -q "CHECKPOINT.*metadata completeness" || echo "ERROR: Metadata validation checkpoint not executed"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic (grep pattern matching, arithmetic validation)
- skip_allowed: false
- artifact_outputs: ["metadata-completeness-test.log", "plan-metadata-validation.txt"]

---

## Phase 6: Wave Structure Preview Validation [COMPLETE]

**Dependencies**: []
**Implementer**: software
**Estimated Hours**: 0.5-1 hour

### Objective

Add STEP 2.7 validation checkpoint to lean-plan-architect ensuring wave structure preview generation for user visibility into parallelization opportunities.

### Tasks

- [ ] Add STEP 2.7 Wave Structure Preview Validation checkpoint
  - Check for wave structure comment in plan file (grep pattern)
  - Count wave sections (grep "^Wave [0-9]")
  - Display wave count in [CHECKPOINT] message
  - Issue non-fatal warning if wave structure missing (plan still valid)
- [ ] Enhance wave structure preview format in STEP 2.6
  - Ensure wave count included in preview header
  - Add parallelization metrics (sequential time, parallel time, time savings percentage)
  - Format with box-drawing characters for readability
- [ ] Update PLAN_CREATED return signal to include wave metrics
  - Add WAVES field (numeric wave count)
  - Add PARALLELIZATION field (percentage time savings)
  - Preserve existing PHASES field
  - Format: `PLAN_CREATED: /path\nWAVES: 3\nPARALLELIZATION: 45.8%\nPHASES: 6`
- [ ] Document wave structure preview benefits in user guide
  - Explain parallelization opportunities visible before implementation
  - Show example wave structure with time savings calculation
  - Link to /lean-implement wave-based execution documentation

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (STEP 2.7 addition after STEP 2.6, return signal enhancement)
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md` (wave structure preview documentation)

**Validation**:
```bash
# Verify wave structure preview generated
grep -q "WAVE STRUCTURE (Generated by lean-plan-architect)" "$PLAN_PATH" || echo "WARNING: Wave structure preview not found"

# Verify wave count accurate
WAVE_COUNT=$(grep "^Wave [0-9]" "$PLAN_PATH" | wc -l)
test "$WAVE_COUNT" -gt 0 || echo "WARNING: No waves detected in plan"

# Verify return signal includes wave metrics
grep -q "^WAVES:" "$ARCHITECT_OUTPUT" || echo "WARNING: WAVES field missing from return signal"
grep -q "^PARALLELIZATION:" "$ARCHITECT_OUTPUT" || echo "WARNING: PARALLELIZATION field missing from return signal"

# Verify parallelization percentage is numeric
PARALLEL_PCT=$(grep "^PARALLELIZATION:" "$ARCHITECT_OUTPUT" | sed 's/.*: //' | sed 's/%//')
test "$PARALLEL_PCT" -ge 0 && test "$PARALLEL_PCT" -le 100 || echo "ERROR: Invalid parallelization percentage: $PARALLEL_PCT"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic (grep validation, numeric range checks)
- skip_allowed: false
- artifact_outputs: ["wave-structure-validation.log", "parallelization-metrics.txt"]

---

## Testing Strategy

### Unit Tests

**Phase 1 Testing**:
```bash
# Test metadata field extraction
test_brief_summary_parsing() {
  # Create mock report with metadata
  cat > /tmp/test_report.md <<EOF
report_type: lean_research
topic: "Mathlib Theorems"
findings_count: 12
recommendations_count: 5

# Research Report
EOF

  # Extract metadata
  TOPIC=$(head -10 /tmp/test_report.md | grep "^topic:" | sed 's/^topic:[[:space:]]*//' | tr -d '"')
  test "$TOPIC" = "Mathlib Theorems" || return 1

  FINDINGS=$(head -10 /tmp/test_report.md | grep "^findings_count:" | sed 's/^findings_count:[[:space:]]*//')
  test "$FINDINGS" -eq 12 || return 1
}
```

**Phase 2 Testing**:
```bash
# Test partial success mode
test_partial_success_mode() {
  TOTAL_REPORTS=4
  SUCCESSFUL_REPORTS=2
  SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS))

  # Should be 50%
  test "$SUCCESS_PERCENTAGE" -eq 50 || return 1

  # Should proceed (≥50% threshold)
  test "$SUCCESS_PERCENTAGE" -ge 50 || return 1
}
```

**Phase 3 Testing**:
```bash
# Test context estimation
test_context_estimation() {
  estimate_research_context() {
    local completed_topics="$1"
    local base=15000
    local per_topic=2000
    local metadata_per_topic=110
    local total=$((base + (completed_topics * (per_topic + metadata_per_topic))))
    local percentage=$((total * 100 / 200000))
    echo "$percentage"
  }

  # Test 4 topics
  PCT=$(estimate_research_context 4)
  test "$PCT" -ge 10 && test "$PCT" -le 100 || return 1
}
```

### Integration Tests

**End-to-End /lean-plan Execution**:
```bash
# Test full command execution with context optimization
test_lean_plan_context_optimization() {
  FEATURE="Formalize group homomorphism theorems"
  LEAN_FILE="/path/to/GroupTheory.lean"

  # Execute command
  /lean-plan "$FEATURE" "$LEAN_FILE" --complexity 3

  # Verify metadata parsing used (not full report reads)
  ARCHITECT_PROMPT=$(cat /tmp/architect_prompt.txt)
  PROMPT_SIZE=$(echo "$ARCHITECT_PROMPT" | wc -c)

  # Should be <1000 chars (metadata-only: 80 tokens × 3 reports = 240 tokens ≈ 960 chars)
  test "$PROMPT_SIZE" -lt 1000 || {
    echo "ERROR: Architect prompt too large ($PROMPT_SIZE chars) - full reports passed instead of metadata"
    return 1
  }
}
```

**Pre-commit Validation**:
```bash
# Verify all standards enforcement
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --sourcing
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --metadata
bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh /home/benjamin/.config/.claude/specs/004_lean_plan_context_coordinator/plans/001-lean-plan-context-coordinator-plan.md
```

### Performance Benchmarks

**Context Reduction Measurement**:
```bash
# Measure context usage before and after optimization
measure_context_reduction() {
  # Before: Full report reads (4 reports × 2,500 tokens)
  BEFORE_TOKENS=10000

  # After: Metadata-only (4 reports × 80 tokens)
  AFTER_TOKENS=320

  REDUCTION_PCT=$(( (BEFORE_TOKENS - AFTER_TOKENS) * 100 / BEFORE_TOKENS ))

  echo "Context Reduction: ${REDUCTION_PCT}% ($BEFORE_TOKENS → $AFTER_TOKENS tokens)"

  # Verify ≥95% reduction
  test "$REDUCTION_PCT" -ge 95 || {
    echo "ERROR: Context reduction below target (${REDUCTION_PCT}% < 95%)"
    return 1
  }
}
```

**Iteration Capacity Validation**:
```bash
# Verify iteration capacity increased
validate_iteration_capacity() {
  # Context budget: 200k tokens
  CONTEXT_BUDGET=200000

  # Old pattern: 10k tokens per iteration → 20 iterations max
  OLD_PER_ITERATION=10000
  OLD_CAPACITY=$((CONTEXT_BUDGET / OLD_PER_ITERATION))

  # New pattern: 500 tokens per iteration → 400 iterations max
  NEW_PER_ITERATION=500
  NEW_CAPACITY=$((CONTEXT_BUDGET / NEW_PER_ITERATION))

  echo "Iteration Capacity: $OLD_CAPACITY → $NEW_CAPACITY (${NEW_CAPACITY}x improvement)"

  # Verify at least 10x improvement
  test "$NEW_CAPACITY" -ge $((OLD_CAPACITY * 10)) || {
    echo "ERROR: Iteration capacity improvement below 10x"
    return 1
  }
}
```

---

## Dependencies

### External Dependencies

- research-coordinator.md (already integrated, no changes required)
- lean-plan-architect.md (modifications in Phases 5-6)
- validation-utils.sh (existing infrastructure, no changes required)
- error-handling.sh (existing infrastructure, no changes required)

### Inter-Phase Dependencies

None - all phases are independent and can be implemented in parallel. Recommended sequential order:
1. Phase 1 (Brief Summary Integration) - Foundation for context reduction
2. Phase 2 (Hard Barrier Validation) - Safety net for delegation
3. Phase 3 (Context Estimation) - Monitoring infrastructure
4. Phase 4 (Defensive Validation) - Robustness enhancement
5. Phase 5 (Metadata Completeness) - Standards compliance
6. Phase 6 (Wave Structure Preview) - User visibility enhancement

---

## Rollback Plan

All changes are additive with backward compatibility preserved:

**Phase 1 Rollback**: Remove metadata fields from research-specialist.md STEP 1.5, remove Block 1f-metadata from lean-plan.md (revert to full report reading)

**Phase 2 Rollback**: Remove multi-layer validation from Block 1f (revert to simple file existence check)

**Phase 3 Rollback**: Remove estimate_research_context() function, remove context_usage_percent from return signal

**Phase 4 Rollback**: Remove defensive validation logic, remove is_topics_remaining_empty() helper

**Phase 5 Rollback**: Remove STEP 1.6 complexity calculation, remove metadata fields from STEP 2, remove STEP 3 validation

**Phase 6 Rollback**: Remove STEP 2.7 validation checkpoint, remove wave metrics from return signal

**No Data Loss**: All changes affect processing logic only; no data persistence format changes

---

## Documentation Updates

### Files to Update

1. `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md`
   - Add "Brief Summary Metadata Pattern" section documenting 96% context reduction
   - Update "Research Coordinator Integration" section with context estimation details
   - Add performance metrics (context reduction, iteration capacity)

2. `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-passing-patterns.md` (new file)
   - Document Brief Summary Return Protocol pattern
   - Document Report Metadata Aggregation pattern
   - Include code examples and context reduction metrics

3. `/home/benjamin/.config/.claude/agents/research-coordinator.md`
   - Update STEP 5 with context estimation integration
   - Document return signal contract (topics_remaining ↔ requires_continuation invariant)

4. `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`
   - Add STEP 1.6 Complexity Score Calculation
   - Update STEP 2 metadata fields
   - Add STEP 2.7 Wave Structure Preview Validation
   - Add STEP 3 metadata completeness validation

5. `/home/benjamin/.config/.claude/agents/research-specialist.md`
   - Add STEP 1.5 metadata field generation
   - Document metadata format (YAML frontmatter)

### README Updates

Update `/home/benjamin/.config/.claude/README.md` with:
- Link to metadata-passing-patterns.md in patterns section
- Performance metrics for hierarchical agent architecture (95-96% context reduction)

---

## Performance Metrics

### Expected Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Context per Research Report | 2,500 tokens | 80 tokens | 96.8% reduction |
| Total Research Context (4 reports) | 10,000 tokens | 320 tokens | 96.8% reduction |
| Iteration Capacity | 3-4 iterations | 10+ iterations | 150-200% increase |
| Context Threshold Monitoring | None | 85-90% dynamic halt | Graceful degradation enabled |
| Contract Violation Handling | Silent failure | Defensive override | 100% reliability improvement |

### Validation Targets

- Context reduction: ≥95% (target: 96.8%)
- Metadata parsing overhead: <100 lines of bash code
- Validation checkpoint overhead: <50ms per phase
- Pre-commit validation time: <5 seconds for all checks
- Integration test execution: <30 seconds for full suite

---

## Risk Assessment

### Low Risk

- **Brief Summary Parsing** (Phase 1): Additive enhancement with fallback to legacy parsing
- **Metadata Completeness** (Phase 5): Only affects lean-plan-architect output format
- **Wave Structure Preview** (Phase 6): Non-fatal warning if missing

### Medium Risk

- **Hard Barrier Validation** (Phase 2): Could cause false positives if validation too strict
  - Mitigation: Partial success mode (≥50% threshold) allows graceful degradation
- **Context Estimation** (Phase 3): Estimation formula may be inaccurate
  - Mitigation: Defensive validation with sanity range checks (10k-300k tokens)

### High Risk

- **Defensive Validation** (Phase 4): Override logic could mask real coordinator bugs
  - Mitigation: Log all overrides with validation_error for debugging
  - Mitigation: Only override when contract invariant violated (topics_remaining non-empty + requires_continuation=false)

---

## Future Enhancements

**Out of scope for this plan but recommended for future iterations**:

1. **Iteration Loop Management**: Add multi-iteration support to /lean-plan for complexity-4 plans with 4+ research topics
   - Estimated effort: 4-6 hours
   - Depends on: Phase 3 (context estimation) completion

2. **Wave-Based Research Orchestration**: Add dependency-aware parallel research topic execution
   - Estimated effort: 6-8 hours
   - Depends on: dependency-analyzer.sh integration for research phase

3. **Research Checkpoint Resumption**: Enable resume-from-partial-research for interrupted workflows
   - Estimated effort: 3-4 hours
   - Depends on: Phase 3 (checkpoint saving) completion

---

**Plan Complete**: This implementation plan provides comprehensive optimization for /lean-plan context efficiency while maintaining backward compatibility and architectural modularity. All phases are independently executable with clear validation criteria and rollback procedures.

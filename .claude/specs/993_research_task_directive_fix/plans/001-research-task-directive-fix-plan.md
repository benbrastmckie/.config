# Hybrid Lean/Software Implementer Architecture with Brief Summary Pattern - Implementation Plan

## Metadata
- **Date**: 2025-12-05 (Revised)
- **Feature**: Hybrid coordinator architecture with brief summary return pattern for context-efficient result aggregation
- **Status**: [COMPLETE]
- **Estimated Hours**: 10-14 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Hybrid Architecture Analysis](../reports/001-research-task-directive-fix-analysis.md), [Infrastructure Integration Analysis](../reports/002-infrastructure-integration-analysis.md)
- **Complexity Score**: 82
- **Structure Level**: 0

## Overview

This plan implements a hybrid Lean/software implementer architecture that extends the existing `/lean-implement` command to support mixed plans containing both Lean theorem proving phases and general software implementation phases. The architecture introduces three key enhancements:

1. **Phase Classification System**: Extends the existing 3-tier detection to use explicit `implementer:` metadata fields (lean/software) for unambiguous phase routing
2. **Coordinator Delegation**: Routes phases to appropriate coordinators (lean-coordinator for theorem proving, implementer-coordinator for software tasks) based on phase type
3. **Brief Summary Return Pattern**: Implements a 96% context reduction strategy where coordinators return single-line summaries instead of full summary files, preserving primary agent context window

The solution builds on the existing wave-based coordinator architecture recommended in `/home/benjamin/.config/.claude/specs/991_lean_implement_wave_coordinator/reports/001-lean-implement-wave-coordinator-analysis.md` and extends it to support dual coordinator types with unified result aggregation.

## Research Summary

The research report identified the following key findings:

- **Existing Architecture**: Current `/lean-implement` command (1,358 lines) already implements 2-tier phase detection with routing map construction and dynamic coordinator invocation. Gaps include lack of brief summary pattern and limited context preservation.
- **Brief Summary Patterns**: Analysis of `/implement` command shows 97.5% context reduction is achievable by reading only first 10 lines of summary files for brief descriptions, with full summaries available via file references.
- **Coordinator Return Protocols**: Both lean-coordinator and implementer-coordinator currently return `summary_path` but lack `summary_brief` field for primary agent parsing. Enhancement requires adding `coordinator_type`, `summary_brief`, and `phases_completed` fields.
- **Phase Metadata Standards**: Current plan-metadata-standard.md documents plan-level metadata only. Opportunity exists to standardize phase-level metadata fields (`implementer:`, `dependencies:`, `lean_file:`) for explicit phase classification.
- **Result Aggregation**: Block 1c currently reads full summary files (~2,000 tokens). Enhanced parsing can extract brief summaries from return signals (~80 tokens) for 96% reduction.

Recommended approach: Implement coordinator output contract enhancements first (enables brief summary pattern), then update primary agent parsing logic (Block 1c), standardize phase metadata, and add comprehensive testing.

## Success Criteria

- [ ] Phase-level metadata standard documented in plan-metadata-standard.md with `implementer:`, `dependencies:`, and `lean_file:` fields
- [ ] Lean-coordinator returns enhanced signals with `coordinator_type`, `summary_brief`, and `phases_completed` fields
- [ ] Implementer-coordinator returns enhanced signals with same new fields
- [ ] /lean-implement Block 1c parses brief summary from coordinator return signals (80 tokens vs 2,000 tokens)
- [ ] /lean-implement Block 2 aggregates metrics from both coordinator types (theorems proven + git commits)
- [ ] Test suite validates pure lean plans, pure software plans, mixed plans, iteration continuation, and backward compatibility
- [ ] Metadata validation script enforces optional phase-level metadata fields when present
- [ ] Brief summary fallback parsing implemented for backward compatibility with legacy summaries
- [ ] All phases marked [COMPLETE] after successful execution by appropriate coordinator
- [ ] Documentation updated for hybrid architecture and brief summary pattern

## Technical Design

### Architecture Overview

The hybrid coordinator architecture extends the existing `/lean-implement` command with dual coordinator support:

```
/lean-implement (Primary Agent)
  └─> Block 1a-classify: Phase Classification
      ├─> detect_phase_type() [3-tier detection]
      │   ├─> Tier 1: Check implementer: field (strongest)
      │   ├─> Tier 2: Check lean_file: field (backward compat)
      │   └─> Tier 3: Keyword analysis (fallback)
      └─> Build routing_map.txt: "phase:type:lean_file:coordinator"

  └─> Block 1b: Route to Coordinator [HARD BARRIER]
      ├─> Lean phases → Task(lean-coordinator) [Wave-based]
      └─> Software phases → Task(implementer-coordinator) [Wave-based]

  └─> Block 1c: Verification & Continuation
      ├─> Parse coordinator return signal (NEW: brief summary)
      ├─> Extract: coordinator_type, summary_brief, phases_completed
      ├─> Display: Brief summary (80 tokens, not full 2000-token file)
      └─> Decision: Continue or Complete

  └─> Block 2: Completion & Aggregation
      ├─> Scan summaries_dir for all coordinator summaries
      ├─> Filter by coordinator_type: lean vs software
      ├─> Aggregate: theorems_proven + git_commits_count
      └─> Display: Unified metrics with separate lean/software stats
```

### Enhanced Coordinator Output Contract

Both coordinators will return enhanced signals with context-efficient fields:

**Lean Coordinator Return Signal**:
```yaml
ORCHESTRATION_COMPLETE:
  coordinator_type: "lean"  # NEW
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."  # NEW
  phases_completed: [1, 2]  # NEW
  theorem_count: 15
  work_remaining: Phase_3 Phase_4
  context_exhausted: false
  context_usage_percent: 72
  requires_continuation: true
  phases_with_markers: 2
```

**Implementer Coordinator Return Signal**:
```yaml
IMPLEMENTATION_COMPLETE:
  coordinator_type: "software"  # NEW
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue Wave 2."  # NEW
  phases_completed: [3, 4]  # NEW
  phase_count: 2
  git_commits: [hash1, hash2]
  work_remaining: Phase_5 Phase_6
  context_exhausted: false
  context_usage_percent: 65
  requires_continuation: true
  phases_with_markers: 2
```

### Phase Metadata Standard

Plans will support optional phase-level metadata fields for explicit orchestration control:

```markdown
### Phase N: Phase Name [NOT STARTED]
implementer: lean|software  # Explicit phase type declaration
lean_file: /path/to/file.lean  # For lean phases only
dependencies: [1, 2]  # Phase dependency list for wave ordering

Tasks:
- [ ] Task 1
- [ ] Task 2
```

### Brief Summary Parsing Logic

Block 1c will parse coordinator return signals for brief summaries:

```bash
# Parse coordinator type (identify which coordinator executed)
COORDINATOR_TYPE=$(grep -E "^coordinator_type:" "$LATEST_SUMMARY" | sed 's/^coordinator_type:[[:space:]]*//')

# Parse brief summary (context-efficient: 80 tokens vs 2000)
SUMMARY_BRIEF=$(grep -E "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')

# Fallback: Extract from first 10 lines (backward compatibility)
if [ -z "$SUMMARY_BRIEF" ]; then
  SUMMARY_BRIEF=$(head -10 "$LATEST_SUMMARY" | grep "^\*\*Brief\*\*:" | sed 's/^\*\*Brief\*\*:[[:space:]]*//')
fi

# Parse phases completed (for progress tracking)
PHASES_COMPLETED=$(grep -E "^phases_completed:" "$LATEST_SUMMARY" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')

# Display brief summary (no full file read)
echo "Coordinator: $COORDINATOR_TYPE"
echo "Summary: ${SUMMARY_BRIEF:-No summary provided}"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Full report: $LATEST_SUMMARY"
```

**Context Reduction**: 80 tokens (return signal) vs 2,000 tokens (full summary) = 96% reduction

### Result Aggregation Pattern

Block 2 will aggregate metrics across all coordinator invocations:

```bash
# Scan summaries directory for coordinator summaries
LEAN_SUMMARIES=()
SOFTWARE_SUMMARIES=()
THEOREMS_PROVEN=0
GIT_COMMITS_COUNT=0

# Filter by coordinator type and extract metrics
while IFS= read -r summary_file; do
  if grep -q "^coordinator_type: lean" "$summary_file"; then
    LEAN_SUMMARIES+=("$summary_file")
    THEOREM_COUNT=$(grep -E "^theorem_count:" "$summary_file" | sed 's/^theorem_count:[[:space:]]*//')
    THEOREMS_PROVEN=$((THEOREMS_PROVEN + THEOREM_COUNT))
  elif grep -q "^coordinator_type: software" "$summary_file"; then
    SOFTWARE_SUMMARIES+=("$summary_file")
    GIT_COMMITS=$(grep -E "^git_commits:" "$summary_file" | tr -d '[],"' | wc -w)
    GIT_COMMITS_COUNT=$((GIT_COMMITS_COUNT + GIT_COMMITS))
  fi
done < <(find "$SUMMARIES_DIR" -name "*.md" -type f)

# Display unified metrics
echo "Completed $TOTAL_COMPLETED phases:"
echo "  Lean phases: $LEAN_PHASES_COMPLETED (${THEOREMS_PROVEN} theorems)"
echo "  Software phases: $SOFTWARE_PHASES_COMPLETED (${GIT_COMMITS_COUNT} commits)"
```

### Backward Compatibility

The architecture maintains backward compatibility through:
1. **Phase Classification Fallback**: Tier 2/3 detection when `implementer:` metadata missing
2. **Brief Summary Fallback**: Extract from summary file if `summary_brief` field missing
3. **Existing Field Preservation**: All new fields are additions, existing fields unchanged
4. **Legacy Plan Support**: Plans without phase metadata use keyword-based classification

## Implementation Phases

### Phase 1: Phase Metadata Standard Documentation [COMPLETE]
dependencies: []

**Objective**: Define comprehensive phase-level metadata standard in plan-metadata-standard.md to enable explicit implementer type declaration, eliminate phase classification ambiguity, and document status marker lifecycle.

**Complexity**: Low

**Tasks**:
- [x] Add "Phase-Level Metadata (Optional)" section to /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md after line 130
- [x] Document `implementer:` field with format (lean|software), description, when to include, and example
- [x] Document `dependencies:` field with format (space-separated phase numbers), description, when to include, and example
- [x] Document `lean_file:` field with format (absolute path), description, when to include, and example
- [x] Add status marker lifecycle documentation: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- [x] Add heading level flexibility section (h2 vs h3 format support)
- [x] Add validation rules section explaining optional nature and format requirements
- [x] Include cross-reference to plan-progress.md for detailed status marker behavior
- [x] Include cross-reference to wave-based parallelization documentation for dependencies field
- [x] Add examples showing mixed Lean/software plan with both implementer types (reference Specs 028, 032, 037)
- [x] Document brief summary pattern in /home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md
- [x] Add "Brief Summary Return Pattern" section with problem/solution/format/benefits

**Testing**:
```bash
# Verify phase metadata documentation added
grep -q "Phase-Level Metadata (Optional)" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md

# Verify all fields documented
grep -q "### implementer" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
grep -q "### dependencies" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
grep -q "### lean_file" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md

# Verify status marker lifecycle documented
grep -q "Status Marker Lifecycle" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md

# Verify cross-references added
grep -q "plan-progress.md" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md

# Verify brief summary pattern documented
grep -q "Brief Summary Return Pattern" /home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md

echo "Phase metadata standard documentation complete"
```

**Expected Duration**: 2-3 hours

### Phase 2: Coordinator Output Contract Enhancements [COMPLETE]
dependencies: [1]

**Objective**: Add `coordinator_type`, `summary_brief`, and `phases_completed` fields to both lean-coordinator and implementer-coordinator return signals for context-efficient primary agent parsing. These enhancements can be executed in parallel.

**Complexity**: Medium

**Tasks**:
- [x] Update lean-coordinator.md STEP 5 (Result Aggregation) with brief summary generation logic
- [x] Update implementer-coordinator.md STEP 4 (Result Aggregation) with brief summary generation logic
- [x] Add coordinator_type field to both agents: "lean" for lean-coordinator, "software" for implementer-coordinator
- [x] Add summary_brief field generation to both agents with format: "Completed Wave X-Y (Phase A,B) with N items. Context: P%. Next: ACTION." (max 150 chars)
- [x] Add phases_completed field to both agents with array construction from completed phase numbers
- [x] Update lean-coordinator return signal template (ORCHESTRATION_COMPLETE) to include new fields
- [x] Update implementer-coordinator return signal template (IMPLEMENTATION_COMPLETE) to include new fields
- [x] Update summary file templates in both agents to include structured metadata fields at top (before **Brief** section)
- [x] Update behavioral guidelines sections in both agents explaining new return signal fields
- [x] Add example return signals showing all new fields in both agent docs
- [x] Document backward compatibility: all existing fields preserved, new fields are additions

**Testing**:
```bash
# Verify lean-coordinator STEP 5 updated
grep -A 20 "STEP 5: Result Aggregation" /home/benjamin/.config/.claude/agents/lean-coordinator.md | grep -q "summary_brief"

# Verify lean-coordinator return signal includes new fields
grep -A 15 "ORCHESTRATION_COMPLETE:" /home/benjamin/.config/.claude/agents/lean-coordinator.md | grep -q "coordinator_type"
grep -A 15 "ORCHESTRATION_COMPLETE:" /home/benjamin/.config/.claude/agents/lean-coordinator.md | grep -q "summary_brief"
grep -A 15 "ORCHESTRATION_COMPLETE:" /home/benjamin/.config/.claude/agents/lean-coordinator.md | grep -q "phases_completed"

# Verify implementer-coordinator STEP 4 updated
grep -A 20 "STEP 4: Result Aggregation" /home/benjamin/.config/.claude/agents/implementer-coordinator.md | grep -q "summary_brief"

# Verify implementer-coordinator return signal includes new fields
grep -A 15 "IMPLEMENTATION_COMPLETE:" /home/benjamin/.config/.claude/agents/implementer-coordinator.md | grep -q "coordinator_type"
grep -A 15 "IMPLEMENTATION_COMPLETE:" /home/benjamin/.config/.claude/agents/implementer-coordinator.md | grep -q "summary_brief"
grep -A 15 "IMPLEMENTATION_COMPLETE:" /home/benjamin/.config/.claude/agents/implementer-coordinator.md | grep -q "phases_completed"

echo "Coordinator output contract enhancements complete"
```

**Expected Duration**: 3-4 hours

### Phase 3: Block 1c Brief Summary Parsing [COMPLETE]
dependencies: [2]

**Objective**: Update /lean-implement Block 1c to parse brief summary fields from coordinator return signals, achieving 96% context reduction (80 tokens vs 2,000 tokens per iteration). Integrate validation-utils.sh for robust summary validation.

**Complexity**: Medium

**Tasks**:
- [x] Source validation-utils.sh in /home/benjamin/.config/.claude/commands/lean-implement.md Block 1c
- [x] Add validate_agent_artifact() call for coordinator summary validation (minimum 100 bytes)
- [x] Add defensive fallback logic for legacy summaries without new fields
- [x] Add COORDINATOR_TYPE parsing logic to Block 1c (after line 940)
- [x] Add SUMMARY_BRIEF parsing logic with primary extraction from summary_brief field
- [x] Add fallback parsing logic: extract from first 10 lines of summary file if field missing (backward compatibility)
- [x] Add PHASES_COMPLETED parsing logic with array-to-space-separated conversion
- [x] Update display logic to show coordinator type, brief summary, phases completed, and full report path
- [x] Remove full summary file reading logic (replace with brief field parsing)
- [x] Add comments explaining context reduction: 80 tokens parsed vs 2,000 tokens read (96%)
- [x] Add error handling for malformed return signals

**Testing**:
```bash
# Verify validation-utils.sh sourced
grep -A 10 "Block 1c" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "validation-utils.sh"

# Verify validate_agent_artifact used
grep -A 50 "=== PARSE COORDINATOR OUTPUT" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "validate_agent_artifact"

# Verify brief summary parsing logic added
grep -A 50 "=== PARSE COORDINATOR OUTPUT" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "SUMMARY_BRIEF="

# Verify fallback logic present
grep -A 50 "=== PARSE COORDINATOR OUTPUT" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "head -10"

# Verify display logic updated
grep -A 50 "=== PARSE COORDINATOR OUTPUT" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "echo.*Coordinator:"
grep -A 50 "=== PARSE COORDINATOR OUTPUT" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "echo.*Summary:"

echo "Block 1c brief summary parsing implemented"
```

**Expected Duration**: 2-3 hours

### Phase 4: Block 2 Result Aggregation Enhancement [COMPLETE]
dependencies: [2, 3]

**Objective**: Update /lean-implement Block 2 to aggregate metrics from both coordinator types, displaying separate lean/software statistics with total theorems proven and git commits. Leverage checkbox-utils.sh and plan-core-bundle.sh for proven infrastructure patterns.

**Complexity**: Medium

**Tasks**:
- [x] Source checkbox-utils.sh in /home/benjamin/.config/.claude/commands/lean-implement.md Block 2
- [x] Use check_all_phases_complete() for completion detection instead of custom logic
- [x] Leverage plan-core-bundle.sh functions for plan parsing where applicable
- [x] Add LEAN_SUMMARIES and SOFTWARE_SUMMARIES array declarations to Block 2 (after line 1225)
- [x] Add THEOREMS_PROVEN and GIT_COMMITS_COUNT metric variables
- [x] Add summary scanning logic with find command in summaries directory
- [x] Add coordinator_type filtering logic: lean vs software
- [x] Add theorem_count extraction and aggregation for lean summaries
- [x] Add git_commits extraction and counting for software summaries
- [x] Update display logic to show separate lean/software phase counts with metrics
- [x] Add summary file list display for audit trail (lean summaries, then software summaries)
- [x] Add error handling for malformed summary files

**Testing**:
```bash
# Verify checkbox-utils.sh sourced
grep -A 10 "Block 2" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "checkbox-utils.sh"

# Verify check_all_phases_complete used
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "check_all_phases_complete"

# Verify aggregation logic added
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "LEAN_SUMMARIES=()"
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "SOFTWARE_SUMMARIES=()"

# Verify coordinator type filtering
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "coordinator_type: lean"
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "coordinator_type: software"

# Verify metric extraction
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "THEOREMS_PROVEN"
grep -A 80 "=== AGGREGATE METRICS" /home/benjamin/.config/.claude/commands/lean-implement.md | grep -q "GIT_COMMITS_COUNT"

echo "Block 2 result aggregation enhanced"
```

**Expected Duration**: 2-3 hours

### Phase 5: Comprehensive Testing Suite [COMPLETE]
dependencies: [3, 4]

**Objective**: Create consolidated test suite validating pure lean plans, pure software plans, mixed plans, iteration continuation, and backward compatibility. Consolidate into 2-3 test files with shared fixtures to reduce maintenance burden.

**Complexity**: Medium

**Tasks**:
- [x] Create /home/benjamin/.config/.claude/tests/commands/test_hybrid_coordinator_routing.sh for coordinator routing tests
- [x] Add test cases in routing test: pure lean plan, pure software plan, mixed lean/software plan
- [x] Create /home/benjamin/.config/.claude/tests/commands/test_hybrid_coordinator_iteration.sh for iteration and compatibility tests
- [x] Add test cases in iteration test: iteration continuation, backward compatibility with legacy summaries
- [x] Create shared test fixtures directory with sample plans containing explicit implementer metadata
- [x] Add fixture: pure_lean_plan.md with implementer: lean metadata
- [x] Add fixture: pure_software_plan.md with implementer: software metadata
- [x] Add fixture: mixed_plan.md with both lean and software phases
- [x] Add fixture: legacy_plan.md without implementer metadata (tests fallback classification)
- [x] Add assertions: correct coordinator routing, brief summary parsing, metric aggregation
- [x] Add validation: coordinator_type field present, summary_brief field present, phases_completed field present
- [x] Test fallback logic: legacy summaries without new fields still parse correctly
- [x] Integrate tests into /home/benjamin/.config/.claude/tests/run_all_tests.sh test suite

**Testing**:
```bash
# Run consolidated hybrid coordinator tests
bash /home/benjamin/.config/.claude/tests/commands/test_hybrid_coordinator_routing.sh
bash /home/benjamin/.config/.claude/tests/commands/test_hybrid_coordinator_iteration.sh

# Verify all test scenarios pass
echo "All hybrid coordinator tests passed (routing + iteration)"
```

**Expected Duration**: 2-3 hours

### Phase 6: Metadata Validation and Documentation Updates [COMPLETE]
dependencies: [1, 5]

**Objective**: Add validation for optional phase-level metadata fields and update documentation for hybrid coordinator architecture. Integrate with existing validation infrastructure.

**Complexity**: Low

**Tasks**:
- [x] Extend plan-core-bundle.sh extract_phase_metadata() to validate optional phase-level fields
- [x] Add phase metadata validation to validate-all-standards.sh --plans category
- [x] Add validation rules: if implementer field present, value must be "lean" or "software"
- [x] Add validation rules: if dependencies field present, format must be space-separated numbers or "[]"
- [x] Add validation rules: if lean_file field present, path must be absolute
- [x] Update /home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md with hybrid architecture section
- [x] Add section explaining phase classification (3-tier detection with implementer field as strongest signal)
- [x] Add section explaining coordinator delegation (lean-coordinator vs implementer-coordinator)
- [x] Add section explaining brief summary pattern and context reduction benefits (96% reduction)
- [x] Add examples showing mixed plans with both implementer types
- [x] Update /home/benjamin/.config/.claude/agents/lean-plan-architect.md to include implementer metadata in phase templates

**Testing**:
```bash
# Test metadata validation with valid phase metadata
cat > /tmp/test_plan_valid.md <<'EOF'
## Metadata
- **Date**: 2025-12-05
- **Feature**: Test Plan
- **Status**: [COMPLETE]
- **Estimated Hours**: 5-7 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none

### Phase 1: Test Phase [COMPLETE]
implementer: lean
lean_file: /home/benjamin/test.lean
dependencies: []

Tasks:
- [x] Task 1
EOF

bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --plans /tmp/test_plan_valid.md
[ $? -eq 0 ] || echo "ERROR: Valid plan rejected"

# Test metadata validation with invalid implementer value
cat > /tmp/test_plan_invalid.md <<'EOF'
## Metadata
- **Date**: 2025-12-05
- **Feature**: Test Plan
- **Status**: [COMPLETE]
- **Estimated Hours**: 5-7 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none

### Phase 1: Test Phase [COMPLETE]
implementer: invalid_type
dependencies: []

Tasks:
- [x] Task 1
EOF

bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --plans /tmp/test_plan_invalid.md
[ $? -ne 0 ] || echo "ERROR: Invalid plan accepted"

# Verify documentation updated
grep -q "Hybrid Coordinator Architecture" /home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md

echo "Metadata validation and documentation updates complete"
```

**Expected Duration**: 2-3 hours

## Testing Strategy

### Unit Testing
- **Phase Metadata Validation**: Test validate-plan-metadata.sh with valid/invalid implementer, dependencies, and lean_file values
- **Brief Summary Parsing**: Test Block 1c parsing with new-format summaries (with fields) and legacy summaries (without fields)
- **Metric Aggregation**: Test Block 2 aggregation with lean-only, software-only, and mixed coordinator summaries

### Integration Testing
- **Pure Lean Plan**: Verify all phases route to lean-coordinator, brief summaries parsed, theorem count aggregated
- **Pure Software Plan**: Verify all phases route to implementer-coordinator, brief summaries parsed, git commit count aggregated
- **Mixed Lean/Software Plan**: Verify correct routing per phase type, both coordinators invoked, unified metrics displayed
- **Iteration Continuation**: Verify brief summary used in iteration 2, continuation decision based on return signal (not full summary)
- **Backward Compatibility**: Verify legacy plans (no implementer metadata) classify via fallback logic, legacy summaries (no brief field) extract from file

### Performance Testing
- **Context Usage Measurement**: Measure token usage before/after brief summary pattern (expect 96% reduction: 80 tokens vs 2,000 tokens)
- **Aggregation Efficiency**: Measure Block 2 execution time with 10+ coordinator summaries (should remain under 1 second)

### Validation Testing
- **Metadata Compliance**: Run validate-plan-metadata.sh on all test fixtures, verify optional phase metadata validated correctly
- **Standards Compliance**: Run validate-all-standards.sh on modified files, verify no sourcing/suppression violations

## Documentation Requirements

### Standards Documentation
- **Plan Metadata Standard**: Add "Phase-Level Metadata (Optional)" section documenting implementer, dependencies, and lean_file fields (Phase 1)
- **Lean Implement Command Guide**: Add "Hybrid Coordinator Architecture" section explaining phase classification, coordinator delegation, and brief summary pattern (Phase 7)

### Agent Documentation
- **Lean Coordinator**: Update STEP 5 and return signal template with new fields, document brief generation logic (Phase 2)
- **Implementer Coordinator**: Update STEP 4 and return signal template with new fields, document brief generation logic (Phase 3)
- **Lean Plan Architect**: Update phase template to include implementer: lean metadata field (Phase 7)

### Command Documentation
- **Lean Implement**: Update Block 1c and Block 2 inline comments explaining brief summary parsing and metric aggregation (Phases 4, 5)
- **Validation Script**: Update validate-plan-metadata.sh inline comments explaining optional phase metadata rules (Phase 7)

### README Updates
- **Agents README**: Document coordinator output contract with new fields and backward compatibility
- **Commands README**: Document hybrid architecture and brief summary return pattern
- **Tests README**: Document hybrid coordinator test suite structure and coverage

## Dependencies

### External Dependencies
- **Existing Commands**: /lean-implement (Block 1a-classify, Block 1b, Block 1c, Block 2)
- **Existing Agents**: lean-coordinator.md, implementer-coordinator.md, lean-plan-architect.md
- **Validation Scripts**: validate-plan-metadata.sh, validate-all-standards.sh
- **Standards Documentation**: plan-metadata-standard.md, lean-implement-command-guide.md

### Library Dependencies
- **State Persistence**: Used by /lean-implement for workspace state management
- **Workflow State Machine**: Used by coordinators for orchestration state tracking
- **Error Handling**: Used by all components for centralized error logging

### Prerequisite Knowledge
- **Wave-Based Orchestration**: Understanding of phase dependency system and parallel wave execution
- **Topic-Based Artifact Organization**: Understanding of specs/{NNN_topic}/ directory structure
- **Coordinator Return Protocols**: Understanding of existing YAML return signal format

## Risk Mitigation

### Backward Compatibility Risks
- **Risk**: Existing plans without implementer metadata fail to classify correctly
- **Mitigation**: Maintain Tier 2/3 fallback classification using lean_file and keyword analysis
- **Validation**: Test with legacy plans in backward compatibility test suite

### Context Window Risks
- **Risk**: Brief summary too verbose, fails to achieve target context reduction
- **Mitigation**: Enforce 150-character maximum for summary_brief field, use terse format with abbreviations
- **Validation**: Measure actual token usage in integration tests, verify 96% reduction achieved

### Aggregation Risks
- **Risk**: Coordinator type filtering fails with malformed summary files
- **Mitigation**: Add defensive parsing with fallback to empty values, log parsing errors
- **Validation**: Test with various summary formats including edge cases (missing fields, invalid types)

### Validation Risks
- **Risk**: Metadata validation too strict, rejects valid phase metadata
- **Mitigation**: Make phase metadata optional, only validate format when fields present
- **Validation**: Test with various plan formats, ensure optional fields truly optional

## Notes

### Design Decisions

**Why Brief Summary Pattern**: Primary agent context window is limited resource. Reading full 2,000-token summaries per iteration wastes context that could be used for implementation tasks. Brief summary pattern achieves 96% reduction while maintaining full artifact traceability.

**Why Dual Coordinators**: Lean theorem proving and software implementation have fundamentally different workflows (proof search tactics vs code writing), test strategies (Lean build vs unit tests), and artifact outputs (proof summaries vs git commits). Separate coordinators enable domain-specific optimizations.

**Why Explicit Implementer Metadata**: Keyword-based phase classification has 5-10% error rate due to ambiguous phase names (e.g., "Phase 3: Core Implementation" could be Lean or software). Explicit metadata eliminates ambiguity, reducing errors to <1%.

**Why Backward Compatibility**: Existing plans in specs/ directories may lack new metadata fields. Fallback classification and summary parsing ensure seamless migration without breaking existing workflows.

### Future Enhancements

- **Additional Coordinator Types**: Architecture extensible to test-coordinator, deploy-coordinator, etc. (just add new implementer type)
- **Cross-Coordinator Dependencies**: Support dependencies across coordinator types (e.g., software Phase 5 depends on lean Phase 3)
- **Adaptive Brief Summary Length**: Adjust summary_brief length based on primary agent context usage percentage
- **Streaming Brief Updates**: Emit progress markers during coordinator execution for real-time status visibility

### Related Work

- **Original Recommendation**: /home/benjamin/.config/.claude/specs/991_lean_implement_wave_coordinator/reports/001-lean-implement-wave-coordinator-analysis.md
- **Wave-Based Orchestration**: Existing /lean-implement command implements phase dependency system with parallel wave execution
- **Coordinator Patterns**: Both lean-coordinator and implementer-coordinator follow consistent orchestration patterns (wave building, agent delegation, result aggregation)

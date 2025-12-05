# Lean-Implement Command Design Implementation Plan

## Metadata
- **Date**: 2025-12-04
- **Feature**: /lean-implement command with hybrid Lean/software coordination
- **Scope**: Design and implement a unified command that intelligently routes phases to lean-coordinator (theorem proving) or implementer-coordinator (software implementation) based on task type detection
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Complexity Score**: 142.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean-Implement Hybrid Coordination Research](../reports/001-lean-implement-hybrid-coordination-research.md)

## Overview

The /lean-implement command enables unified execution of mixed Lean/software implementation plans by intelligently routing phases to appropriate coordinators (lean-coordinator for theorem proving, implementer-coordinator for software development). The command acts as a router-orchestrator that classifies phases, manages cross-coordinator state, handles iteration continuity, and aggregates results from both coordinator types.

## Research Summary

Research findings from the hybrid coordination analysis:

**Key Findings**:
- Both /lean-build and /implement follow 4-block orchestration pattern with hard barriers, iteration management, and phase marker recovery
- lean-coordinator uses Opus 4.5 for complex proof search; implementer-coordinator uses Haiku 4.5 for deterministic orchestration
- Phase type detection can leverage strong indicators: lean_file metadata, .lean extensions, theorem/lemma keywords for Lean; file extensions (.ts, .js, .py) and action verbs for software
- Both coordinators share iteration management patterns: continuation_context, work_remaining, context_exhausted, requires_continuation
- Routing map data structure enables phase tracking across coordinators with per-phase metadata (coordinator type, status, summary_path)

**Recommended Approach**:
- Command-level model: Sonnet 4.5 (routing logic deterministic)
- Router-orchestrator pattern with 5-block structure (Setup, Classification, Route to Coordinator, Verification, Completion)
- 2-tier phase classification: lean_file metadata (Tier 1), keyword/extension analysis (Tier 2)
- Shared workflow context: workflow_id, topic_path, continuation_context, iteration
- Preserve backward compatibility with existing /lean-build and /implement commands

## Success Criteria

- [x] Command correctly classifies Lean vs software phases (>95% accuracy on test cases)
- [x] Routes phases to appropriate coordinator (lean-coordinator or implementer-coordinator)
- [x] Manages cross-coordinator iteration continuity with shared workflow_id
- [x] Handles mixed plans with both Lean and software phases
- [x] Aggregates metrics from both coordinator types in unified console summary
- [x] Preserves all /lean-build features (MCP rate limits, wave-based proving, multi-file support)
- [x] Preserves all /implement features (auto-resume, dry-run, checkpoint resumption)
- [x] No breaking changes to existing commands

## Technical Design

### Architecture Overview

**Router-Orchestrator Pattern**:
- Command acts as intelligent router (not executor)
- Phase classification via 2-tier detection algorithm
- Coordinator invocation via Task tool with input contracts
- Cross-coordinator state persistence via workflow state machine
- Result aggregation from multiple coordinator types

**Block Structure** (5 blocks):
1. **Block 1a**: Setup & Phase Classification
   - Parse arguments (plan file, mode, iterations)
   - Classify each phase as "lean" or "software"
   - Build routing map: {phase_number: {phase_type, coordinator, lean_file, status}}
   - Initialize workflow state and iteration variables

2. **Block 1b**: Route to Coordinator [HARD BARRIER]
   - Determine current phase type from routing map
   - Invoke appropriate coordinator via Task tool:
     - If lean: lean-coordinator with lean-specific inputs (lean_file_path, max_attempts, rate_limit)
     - If software: implementer-coordinator with software-specific inputs (plan_path, context_threshold)
   - Pass shared context: topic_path, continuation_context, iteration

3. **Block 1c**: Verification & Continuation Decision
   - Validate summary creation (hard barrier)
   - Parse coordinator output (work_remaining, context_exhausted, requires_continuation)
   - Update routing map with completion status
   - Determine iteration continuation or completion

4. **Block 1d**: Phase Marker Recovery
   - Validate [COMPLETE] markers for all coordinators
   - Recover missing markers using checkbox-utils.sh

5. **Block 2**: Completion & Summary
   - Aggregate metrics from all coordinators
   - Display unified console summary
   - Emit IMPLEMENTATION_COMPLETE signal

**Phase Classification Algorithm**:

```bash
detect_phase_type() {
  local phase_content="$1"
  local phase_num="$2"

  # Tier 1: Check for lean_file metadata (strongest signal)
  if grep -q "^lean_file:" <<< "$phase_content"; then
    echo "lean"
    return 0
  fi

  # Tier 2: Keyword and extension analysis
  # Lean indicators
  if grep -qiE '\.(lean)\b|theorem\b|lemma\b|sorry\b|tactic\b|mathlib\b|lean_(goal|build|leansearch)' <<< "$phase_content"; then
    echo "lean"
    return 0
  fi

  # Software indicators
  if grep -qE '\.(ts|js|py|sh|md|json|yaml|toml)\b' <<< "$phase_content"; then
    echo "software"
    return 0
  fi

  if grep -qiE 'implement\b|create\b|write tests\b|setup\b|configure\b|deploy\b|build\b' <<< "$phase_content"; then
    echo "software"
    return 0
  fi

  # Default: software (conservative)
  echo "software"
}
```

**Routing Map Data Structure**:

```json
{
  "routing_map": {
    "1": {
      "phase_type": "software",
      "coordinator": "implementer-coordinator",
      "status": "complete",
      "summary_path": "/path/to/summaries/phase_1_summary.md"
    },
    "2": {
      "phase_type": "lean",
      "coordinator": "lean-coordinator",
      "lean_file": "/path/to/file.lean",
      "status": "in_progress",
      "summary_path": "/path/to/summaries/phase_2_summary.md"
    }
  },
  "current_phase": 2,
  "total_phases": 5,
  "lean_phases": [2, 4],
  "software_phases": [1, 3, 5]
}
```

**Cross-Coordinator State Continuity**:
- Shared workflow_id across all coordinators
- Routing map persisted in workflow state
- Continuation context passed between coordinators
- Per-coordinator iteration tracking (LEAN_ITERATION, SOFTWARE_ITERATION)

**Model Selection**:
- Command level: Sonnet 4.5 (routing logic, state management)
- Lean coordinator: Opus 4.5 (preserved from lean-coordinator.md frontmatter)
- Software coordinator: Haiku 4.5 (preserved from implementer-coordinator.md frontmatter)

### Standards Alignment

**Code Standards**:
- Three-tier sourcing pattern (error-handling.sh, state-persistence.sh, workflow-state-machine.sh)
- Fail-fast handlers for Tier 1 libraries
- Checkpoint format v2.1 with iteration fields
- Comment WHAT code does (not WHY)

**Error Logging**:
- Initialize error log: ensure_error_log_exists
- Set metadata: COMMAND_NAME="/lean-implement", WORKFLOW_ID, USER_ARGS
- Log errors: log_command_error with error_type (validation_error, agent_error, state_error, etc.)
- Parse subagent errors: parse_subagent_error for coordinator failures

**Testing Protocols**:
- Unit tests: Phase classification algorithm (test_lean_implement_phase_classification.sh)
- Integration tests: Mixed plan execution (test_lean_implement_mixed_plan.sh)
- Edge case tests: Ambiguous phases, coordinator failures, iteration continuity

**Documentation Policy**:
- Command guide: /home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md
- Update command reference with syntax and examples
- Add troubleshooting guide for routing errors

## Implementation Phases

### Phase 1: Command Scaffolding and Argument Parsing [COMPLETE]
dependencies: []

**Objective**: Create /lean-implement command file with argument parsing, project detection, and state initialization

**Complexity**: Medium

**Tasks**:
- [x] Create .claude/commands/lean-implement.md file using /lean-build.md as template
- [x] Implement frontmatter with model: opus-4.5, allowed-tools, argument-hint
- [x] Add Block 1a: Setup & State Initialization
  - [x] Capture arguments via temp file pattern (plan_file, mode, --max-iterations, --context-threshold)
  - [x] Detect project directory (git-based or .claude/ marker)
  - [x] Source three-tier libraries (error-handling, state-persistence, workflow-state-machine)
  - [x] Initialize workflow state with WORKFLOW_ID="lean_implement_$(date +%s)"
  - [x] Initialize error logging (ensure_error_log_exists, set COMMAND_NAME/USER_ARGS)
- [x] Add argument validation (plan file exists, mode valid, iterations numeric)
- [x] Persist base variables to workflow state (COMMAND_NAME, WORKFLOW_ID, PLAN_FILE, MODE, MAX_ITERATIONS)

**Testing**:
```bash
# Test argument parsing
bash .claude/commands/lean-implement.md <<< "echo 'plan.md --mode=auto --max-iterations=3' > ~/.claude/tmp/lean_implement_arg_*.txt"

# Verify variables persisted
cat ~/.claude/tmp/workflow_lean_implement_*.sh | grep -E "PLAN_FILE|MODE|MAX_ITERATIONS"
```

**Expected Duration**: 3 hours

---

### Phase 2: Phase Classification Algorithm [COMPLETE]
dependencies: [1]

**Objective**: Implement 2-tier phase type detection algorithm (Lean vs software) and build routing map

**Complexity**: High

**Tasks**:
- [x] Create .claude/lib/lean/phase-classifier.sh library
  - [x] Function: detect_phase_type(phase_content, phase_num)
  - [x] Tier 1: Check for lean_file metadata (strongest signal)
  - [x] Tier 2: Keyword analysis (theorem, lemma, sorry, tactic, Mathlib)
  - [x] Tier 2: Extension analysis (.lean, .ts, .js, .py, .sh, .md)
  - [x] Tier 2: Action verb analysis (implement, create, write tests, setup)
  - [x] Default: Return "software" for ambiguous phases
- [x] Function: build_routing_map(plan_file)
  - [x] Parse plan file to extract all phase headings and content
  - [x] For each phase: call detect_phase_type
  - [x] Build routing map JSON with phase_num, phase_type, coordinator
  - [x] Extract lean_file metadata for Lean phases (using lean-build.md Tier 1/Tier 2 pattern)
  - [x] Count lean_phases and software_phases
- [x] Persist routing map to workflow state as JSON string
- [x] Add logging for classification decisions (DEBUG mode)

**Testing**:
```bash
# Test phase classification
source .claude/lib/lean/phase-classifier.sh

# Test Lean phase detection
PHASE_CONTENT="lean_file: Modal.lean
Tasks:
- [ ] Prove theorem_K"
detect_phase_type "$PHASE_CONTENT" 1  # Expected: "lean"

# Test software phase detection
PHASE_CONTENT="Tasks:
- [ ] Create auth.ts with JWT generation
- [ ] Write unit tests"
detect_phase_type "$PHASE_CONTENT" 2  # Expected: "software"

# Test ambiguous phase (default to software)
PHASE_CONTENT="Tasks:
- [ ] Integration testing"
detect_phase_type "$PHASE_CONTENT" 3  # Expected: "software"
```

**Expected Duration**: 4 hours

---

### Phase 3: Coordinator Routing Logic [COMPLETE]
dependencies: [1, 2]

**Objective**: Implement coordinator invocation logic with input contract preparation for lean-coordinator and implementer-coordinator

**Complexity**: High

**Tasks**:
- [x] Add Block 1b: Route to Coordinator [HARD BARRIER]
  - [x] Load routing map from workflow state
  - [x] Determine current phase from routing map (CURRENT_PHASE variable)
  - [x] Extract phase metadata (phase_type, lean_file, coordinator)
  - [x] Prepare input contract based on phase type:
    - [x] If lean: Build lean-coordinator input (lean_file_path, topic_path, artifact_paths, max_attempts, plan_path, execution_mode, continuation_context, max_iterations)
    - [x] If software: Build implementer-coordinator input (plan_path, topic_path, summaries_dir, artifact_paths, continuation_context, iteration, max_iterations, context_threshold)
  - [x] Invoke appropriate coordinator via Task tool
  - [x] Add progress tracking instructions (checkbox-utils.sh sourcing, add_in_progress_marker, mark_phase_complete, add_complete_marker)
- [x] Add coordinator selection logic (if/else based on phase_type)
- [x] Validate required metadata present before invocation (lean_file for Lean phases, plan_path for software phases)

**Testing**:
```bash
# Test lean-coordinator invocation (dry-run)
# Create test plan with Lean phase
cat > /tmp/test_lean_phase.md << 'EOF'
### Phase 1: Prove Theorems [IN PROGRESS]
lean_file: /path/to/Modal.lean

Tasks:
- [ ] Prove theorem_K
EOF

# Run command (should route to lean-coordinator)
/lean-implement /tmp/test_lean_phase.md --dry-run

# Verify routing map shows lean coordinator
cat ~/.claude/tmp/workflow_lean_implement_*.sh | grep "lean-coordinator"
```

**Expected Duration**: 5 hours

---

### Phase 4: Iteration Management and Verification [COMPLETE]
dependencies: [3]

**Objective**: Implement cross-coordinator iteration continuity, verification hard barrier, and continuation decision logic

**Complexity**: High

**Tasks**:
- [x] Add Block 1c: Verification & Continuation Decision
  - [x] Restore workflow state from WORKFLOW_ID
  - [x] Validate summary file existence (hard barrier - find latest summary in SUMMARIES_DIR)
  - [x] Parse coordinator output signals (work_remaining, context_exhausted, requires_continuation, context_usage_percent, checkpoint_path)
  - [x] Update routing map with completion status (mark current phase complete)
  - [x] Check for stuck state (work_remaining unchanged for 2 iterations)
  - [x] Determine next phase from routing map (find next [NOT STARTED] or [IN PROGRESS] phase)
  - [x] Iteration decision logic:
    - [x] If requires_continuation=true AND iteration < max_iterations: Update ITERATION, CONTINUATION_CONTEXT, CURRENT_PHASE, loop to Block 1b
    - [x] If all phases complete: Proceed to Block 1d
    - [x] If stuck or max iterations: Log error, proceed to Block 1d
- [x] Add iteration loop variables (ITERATION, CONTINUATION_CONTEXT, LAST_WORK_REMAINING, STUCK_COUNT)
- [x] Persist iteration state for cross-block accessibility

**Testing**:
```bash
# Test iteration continuation logic
# Simulate coordinator output with requires_continuation=true
cat > /tmp/test_summary.md << 'EOF'
work_remaining: Phase_2 Phase_3
context_exhausted: false
context_usage_percent: 75%
requires_continuation: true
EOF

# Verify iteration decision (should continue to next iteration)
# Check ITERATION variable incremented, CONTINUATION_CONTEXT set
```

**Expected Duration**: 4 hours

---

### Phase 5: Phase Marker Recovery and Aggregation [COMPLETE]
dependencies: [4]

**Objective**: Implement phase marker validation/recovery for both coordinator types and result aggregation

**Complexity**: Medium

**Tasks**:
- [x] Add Block 1d: Phase Marker Validation and Recovery
  - [x] Source checkbox-utils.sh library
  - [x] Count total phases and phases with [COMPLETE] marker
  - [x] Iterate through all phases in routing map
  - [x] For each phase: verify_phase_complete, add [COMPLETE] marker if missing
  - [x] Update plan metadata status to COMPLETE if all phases done
  - [x] Persist validation results (PHASES_WITH_MARKER, TOTAL_PHASES)
- [x] Add result aggregation logic
  - [x] Iterate through routing map to collect per-coordinator metrics
  - [x] Count lean_phases_completed and software_phases_completed
  - [x] Extract theorems_proven from Lean summaries (parse PROOF_COMPLETE signals)
  - [x] Extract files_created, git_commits from software summaries (parse IMPLEMENTATION_COMPLETE signals)

**Testing**:
```bash
# Test phase marker recovery
# Create plan with completed tasks but missing [COMPLETE] marker
cat > /tmp/test_recovery.md << 'EOF'
### Phase 1: Setup [IN PROGRESS]
Tasks:
- [x] Task 1
- [x] Task 2
EOF

# Run recovery logic
source .claude/lib/plan/checkbox-utils.sh
verify_phase_complete /tmp/test_recovery.md 1  # Should return true
add_complete_marker /tmp/test_recovery.md 1

# Verify marker added
grep "\[COMPLETE\]" /tmp/test_recovery.md
```

**Expected Duration**: 2 hours

---

### Phase 6: Console Summary and Completion [COMPLETE]
dependencies: [5]

**Objective**: Design unified console summary format, aggregate metrics from both coordinators, and emit completion signal

**Complexity**: Low

**Tasks**:
- [x] Add Block 2: Completion & Summary
  - [x] Parse final metrics from routing map and summaries
  - [x] Design console summary format (4-section: Summary/Phases/Artifacts/Next Steps)
  - [x] Aggregate metrics:
    - [x] Total phases (from routing map)
    - [x] Lean phases completed (count lean phases with status=complete)
    - [x] Software phases completed (count software phases with status=complete)
    - [x] Theorems proven (from Lean summaries)
    - [x] Files created (from software summaries)
    - [x] Git commits (from software summaries)
  - [x] Display unified console summary with emoji markers
  - [x] Emit IMPLEMENTATION_COMPLETE signal with:
    - [x] total_phases, lean_phases_completed, software_phases_completed
    - [x] theorems_proven, files_created, git_commits
    - [x] plan_file, topic_path, summary_paths (lean and software)
    - [x] work_remaining, context_exhausted, requires_continuation
- [x] Add cleanup (temp files, preserve state for /test)

**Testing**:
```bash
# Test console summary format
# Create mock routing map and summaries
# Verify summary displays:
# - Total phases: 5
# - Lean phases: 2 (theorems proven: 10)
# - Software phases: 3 (files created: 8, git commits: 3)
# - Summary paths for both coordinator types
```

**Expected Duration**: 2 hours

---

### Phase 7: Testing and Documentation [COMPLETE]
dependencies: [6]

**Objective**: Create comprehensive test suite, usage examples, and documentation

**Complexity**: Medium

**Tasks**:
- [x] Create test plans (mixed Lean/software):
  - [x] Test plan 1: Modal logic proofs + TypeScript proof checker UI (3 Lean phases, 2 software phases)
  - [x] Test plan 2: All-Lean plan (should work identical to /lean-build)
  - [x] Test plan 3: All-software plan (should work identical to /implement)
  - [x] Test plan 4: Ambiguous phase classification edge cases
- [x] Create unit tests:
  - [x] test_lean_implement_phase_classification.sh (phase detection algorithm)
  - [x] test_lean_implement_routing_map.sh (routing map construction)
- [x] Create integration tests:
  - [x] test_lean_implement_mixed_plan.sh (end-to-end mixed plan execution)
  - [x] test_lean_implement_coordinator_failures.sh (coordinator failure isolation)
  - [x] test_lean_implement_iteration_continuity.sh (cross-coordinator iteration)
- [x] Create documentation:
  - [x] Command guide: .claude/docs/guides/commands/lean-implement-command-guide.md
    - [x] Usage syntax and examples
    - [x] Mode options (auto, lean-only, software-only)
    - [x] Phase classification rules
    - [x] Iteration management
    - [x] Troubleshooting guide
  - [x] Update command reference: .claude/docs/reference/standards/command-reference.md
    - [x] Add /lean-implement entry with description and syntax
  - [x] Add troubleshooting section for routing errors

**Testing**:
```bash
# Run all test suites
bash .claude/tests/commands/test_lean_implement_phase_classification.sh
bash .claude/tests/commands/test_lean_implement_routing_map.sh
bash .claude/tests/integration/test_lean_implement_mixed_plan.sh

# Verify all tests pass
# Expected: 0 failures
```

**Expected Duration**: 4 hours

---

## Testing Strategy

### Unit Tests
- **Phase Classification**: Test detect_phase_type with Lean, software, and ambiguous phases
- **Routing Map Construction**: Test build_routing_map with various plan structures
- **Coordinator Selection**: Verify correct coordinator invoked based on phase type

### Integration Tests
- **Mixed Plan Execution**: End-to-end test with 3 Lean + 2 software phases
- **Coordinator Failure Isolation**: Verify lean failure doesn't block software phases
- **Iteration Continuity**: Test cross-coordinator continuation context passing

### Edge Case Tests
- **Ambiguous Phase Classification**: Verify default to software for unclear phases
- **Empty Routing Map**: Test plan with no classifiable phases
- **Coordinator Timeout**: Verify timeout handling and recovery

### Test Coverage Target
- Unit tests: 90%+ coverage of phase-classifier.sh functions
- Integration tests: 80%+ coverage of command blocks
- Edge cases: All error paths exercised (validation_error, agent_error, state_error)

### Test Execution
```bash
# Run unit tests
bash .claude/tests/commands/test_lean_implement_phase_classification.sh

# Run integration tests
bash .claude/tests/integration/test_lean_implement_mixed_plan.sh

# Run full test suite
bash .claude/tests/run_all_lean_implement_tests.sh
```

## Documentation Requirements

### Command Guide
Create .claude/docs/guides/commands/lean-implement-command-guide.md:
- Usage syntax and examples
- Mode options (auto, lean-only, software-only)
- Phase classification rules
- Input contract specifications
- Iteration management details
- Troubleshooting guide

### Command Reference Update
Update .claude/docs/reference/standards/command-reference.md:
- Add /lean-implement entry
- Describe hybrid coordination capability
- Link to command guide

### Troubleshooting Guide
Add section to command guide:
- Phase classification errors (how to override with metadata)
- Coordinator invocation failures (check agent output)
- Routing map persistence issues (state file corruption)
- Iteration continuity errors (checkpoint path validation)

## Dependencies

### External Dependencies
- lean-coordinator agent (Opus 4.5 model)
- implementer-coordinator agent (Haiku 4.5 model)
- dependency-analyzer.sh utility (shared by both coordinators)
- lean-lsp-mcp server (for Lean theorem proving)

### Library Dependencies
- error-handling.sh (>=1.0.0)
- state-persistence.sh (>=1.6.0)
- workflow-state-machine.sh (>=2.0.0)
- checkpoint-utils.sh (>=1.0.0)
- checkbox-utils.sh (>=1.0.0)

### Workflow Dependencies
- /lean-plan or /create-plan for plan creation
- /test for test execution after implementation
- /todo for task tracking updates

## Risks and Mitigation

### Risk 1: Phase Classification Accuracy
**Description**: Algorithm may misclassify ambiguous phases
**Mitigation**:
- Default to software (conservative)
- Allow manual override via lean_file metadata
- Log classification decisions for user review
- Add classification confidence score to routing map

### Risk 2: Cross-Coordinator State Corruption
**Description**: Shared workflow_id may cause state conflicts
**Mitigation**:
- Use separate iteration counters (LEAN_ITERATION, SOFTWARE_ITERATION)
- Validate state restoration before coordinator invocation
- Checkpoint before coordinator transitions
- Error logging for state_error diagnostics

### Risk 3: Coordinator Failure Propagation
**Description**: One coordinator failure may block entire workflow
**Mitigation**:
- Isolate failures (mark phases blocked, continue independent work)
- Log coordinator errors with parse_subagent_error
- Aggregate partial results in final summary
- Add --skip-failed flag for continuation

### Risk 4: Performance Degradation
**Description**: Routing overhead may slow execution
**Mitigation**:
- Cache routing map in workflow state (avoid re-parsing)
- Use parallel execution within coordinators (wave-based)
- Profile critical path (phase classification, state persistence)
- Optimize regex patterns in detect_phase_type

## Future Enhancements

### Enhancement 1: Mode Options
- `--mode=auto`: Automatic phase detection (default)
- `--mode=lean-only`: Skip software phases, execute only Lean
- `--mode=software-only`: Skip Lean phases, execute only software

### Enhancement 2: Phase Splitting
- Detect mixed Lean/software tasks within single phase
- Split into virtual sub-phases (5a: Lean, 5b: software)
- Update routing map with sub-phase entries

### Enhancement 3: Confidence Scoring
- Add classification confidence to routing map
- Warn user for low-confidence classifications
- Suggest metadata additions for clarity

### Enhancement 4: Performance Metrics
- Track coordinator execution time
- Calculate time savings from wave-based parallelization
- Display per-coordinator metrics in summary

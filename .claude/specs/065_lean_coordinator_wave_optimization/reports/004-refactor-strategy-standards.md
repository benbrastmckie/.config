# Research Report: Refactoring Strategy & Standards Compliance

## Executive Summary

This report analyzes the optimal refactoring strategy for lean-coordinator optimization to support plan-driven execution while maintaining .claude/docs/ standards compliance. The analysis covers clean-break vs. incremental approaches, testing/validation requirements, documentation updates, and a phased refactoring sequence to minimize breaking changes.

**Key Findings**:
1. **Clean-break refactoring is NOT appropriate** - This is an internal agent enhancement requiring backward compatibility with existing /lean-build workflows
2. **Incremental change with extension pattern** - Add plan-driven features alongside file-based mode without breaking existing functionality
3. **Comprehensive validation required** - 48 existing tests (100% pass rate) must remain green, plus new tests for plan-driven features
4. **Documentation debt is minimal** - Most architectural patterns already documented in hierarchical-agents-examples.md Example 8

---

## Research Question 1: Clean-Break vs. Incremental Change

### Decision Tree Analysis

Following the Clean-Break Development Standard decision tree:

**Question 1**: Is this an internal system with controlled consumers?
- **Answer**: YES - lean-coordinator is invoked exclusively by /lean-build command
- **Action**: Continue to Question 2

**Question 2**: Can all callers be updated in a single PR/commit?
- **Answer**: NO - /lean-build has TWO execution modes:
  - `execution_mode=file-based` (current, must preserve)
  - `execution_mode=plan-based` (new, to be added)
- **Analysis**: Breaking file-based mode would regress existing workflows
- **Action**: Consider splitting into smaller atomic changes

**Question 3**: Does maintaining backwards compatibility add >20 lines of code?
- **Answer**: NO - Dual-mode support requires ~15-20 lines (mode detection + conditional routing)
- **Pattern**: Simple conditional branching based on `execution_mode` parameter
- **Action**: Incremental change is appropriate

**Question 4**: Is there a data migration component?
- **Answer**: NO - No checkpoint format changes, no state machine changes
- **Action**: No migration script needed

### Decision Outcome: INCREMENTAL CHANGE

**Rationale**:
1. **Backward Compatibility Required**: /lean-build workflows using file-based mode must continue working
2. **Low Compatibility Overhead**: Mode detection is ~15 lines, well below 20-line threshold
3. **Risk Mitigation**: Atomic replacement carries unacceptable risk for existing proof workflows
4. **Extension Pattern**: Add new capabilities alongside existing functionality

**Pattern to Apply**: Interface Unification with Extension (Clean-Break Standard, Pattern 2 variant)

```markdown
BEFORE: Single execution mode
- lean-coordinator receives lean_file_path only
- Processes all sorry markers in file
- Returns PROOF_COMPLETE

AFTER: Dual execution modes (backward compatible)
- lean-coordinator receives execution_mode parameter
- IF execution_mode=file-based: Original behavior (preserved)
- IF execution_mode=plan-based: New wave-based orchestration
- Returns PROOF_COMPLETE with mode-specific metadata
```

---

## Research Question 2: Testing & Validation Requirements

### Existing Test Coverage Analysis

**Current Test Suite** (from hierarchical-agents-examples.md Example 8):
- `test_lean_plan_coordinator.sh`: 21 tests (100% pass rate) - research-coordinator integration
- `test_lean_implement_coordinator.sh`: 27 tests (100% pass rate) - implementer-coordinator integration
- **Total**: 48 tests, 0 failures

**Test Categories Validated**:
1. Artifact path pre-calculation (Block 1a)
2. Hard barrier enforcement (Block 1b)
3. Brief summary parsing (Block 1c)
4. Coordinator delegation (no bypass)
5. Summary metadata extraction
6. Partial success mode (≥50% threshold)
7. Context usage estimation

### Required New Tests for Plan-Driven Mode

**Test Suite Structure** (following testing-protocols.md):

```bash
# test_lean_coordinator_plan_mode.sh (new file)
# Tests plan-driven execution mode with dependency analysis

test_plan_structure_detection() {
  # Verify STEP 1: Level 0 vs Level 1 detection
  # Validate phase file discovery
}

test_dependency_analysis_invocation() {
  # Verify STEP 2: dependency-analyzer utility invocation
  # Parse wave structure from analysis results
}

test_wave_execution_orchestration() {
  # Verify STEP 4: Wave-by-wave execution
  # Parallel implementer invocation within waves
  # Synchronization between waves
}

test_phase_number_extraction() {
  # Verify phase_number metadata extraction from plan
  # Pass to lean-implementer for progress tracking
}

test_progress_tracking_forwarding() {
  # Verify progress tracking instructions forwarded to implementers
  # Validate checkbox-utils integration (non-fatal if unavailable)
}

test_file_based_mode_preservation() {
  # CRITICAL: Verify file-based mode still works
  # No regression in existing behavior
  # execution_mode=file-based uses original code path
}

test_dual_mode_compatibility() {
  # Verify both modes coexist without conflicts
  # Mode detection based on execution_mode parameter
  # No cross-contamination of artifacts
}

test_blocking_detection_and_revision() {
  # Verify STEP 5.5: Blocking dependency detection
  # Trigger lean-plan-updater when context allows
  # Revision depth tracking (max 2 revisions)
}
```

**Expected Test Count**: 35-40 new tests (lean-coordinator plan-driven mode)

**Validation Commands** (from code-standards.md):
```bash
# Run lean-coordinator specific tests
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh

# Run all lean integration tests
bash .claude/scripts/validate-all-standards.sh --all

# Pre-commit validation
bash .claude/scripts/validate-all-standards.sh --staged
```

### Preserved Tests Requirements

**CRITICAL**: All 48 existing tests MUST continue passing after refactor.

**Test Execution Pattern**:
```bash
# Before refactor
bash .claude/tests/integration/test_lean_implement_coordinator.sh
# Expected: 27/27 PASS

# After refactor
bash .claude/tests/integration/test_lean_implement_coordinator.sh
# Required: 27/27 PASS (no regression)

bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Required: 35/35 PASS (new tests)
```

**Coverage Threshold** (from testing-protocols.md):
- Baseline: ≥60%
- Modified code: ≥80%
- Target for new plan-driven code: 85%

### Agent Behavioral Compliance Testing

Following testing-protocols.md Agent Behavioral Compliance section:

**Required Compliance Tests**:
1. **File Creation Compliance**: Verify lean-coordinator creates summary at summaries_dir
2. **Completion Signal Format**: Validate PROOF_COMPLETE signal includes all required fields
3. **STEP Structure Validation**: Confirm 5 STEPs present and sequentially numbered
4. **Imperative Language**: Check MUST/WILL/SHALL usage (not should/may/can)
5. **Verification Checkpoints**: Ensure self-validation before PROOF_COMPLETE return
6. **File Size Limits**: Validate agent file ≤40KB (currently 1173 lines = ~50KB - RISK IDENTIFIED)

**File Size Risk**: lean-coordinator.md at 1173 lines likely exceeds 40KB limit.
- **Mitigation**: Consider splitting into lean-coordinator.md (≤400 lines) + lean-coordinator-guide.md
- **Pattern**: Executable/Documentation Separation (code-standards.md Standard 14)
- **Benefit**: 70% reduction in executable file size, fail-fast execution

---

## Research Question 3: Documentation Updates Required

### Documentation Inventory

**Already Documented** (hierarchical-agents-examples.md Example 8):
- ✓ Dual coordinator integration pattern
- ✓ Context reduction metrics (95-96%)
- ✓ Validation results (48 tests, 100% pass)
- ✓ Expected behavior for /lean-plan and /lean-implement
- ✓ Wave-based orchestration architecture

**Documentation Debt**:
1. **lean-coordinator.md**: STEP 1 (Plan Structure Detection) - Already present, lines 71-96
2. **lean-coordinator.md**: STEP 2 (Dependency Analysis) - Already present, lines 98-137
3. **lean-coordinator.md**: File-Based Mode Auto-Conversion - Already present, lines 55-69
4. **lean-coordinator.md**: STEP 5.5 (Blocking Detection) - Already present, lines 703-903
5. **clean-break-development.md**: Exception documentation pattern - Template provided, lines 345-378

**Updates Required**:

#### 1. lean-coordinator.md (Minor Updates Only)

No major structural changes needed. Current documentation already covers plan-driven mode.

**Minor Clarifications**:
- STEP 1: Add note about backward compatibility with file-based mode
- STEP 2: Clarify dependency-analyzer is optional for file-based mode
- Output Format: Document `execution_mode` field in PROOF_COMPLETE signal

**File Size Optimization** (RECOMMENDED):
```markdown
# Current: lean-coordinator.md (1173 lines, ~50KB)
# Split into:

# lean-coordinator.md (≤400 lines, executable)
- Role, Core Responsibilities, Workflow STEPs 1-5
- Input Format, Output Format, Error Protocol
- Minimal inline comments (WHAT not WHY)

# lean-coordinator-guide.md (unlimited, comprehensive)
- Architecture deep-dive
- Wave orchestration patterns
- MCP rate limit coordination strategies
- Performance tuning, troubleshooting
- Design decisions (WHY commentary)
```

**Benefit**: Follows Standard 14 (Executable/Documentation Separation), enables fail-fast execution, eliminates meta-confusion

#### 2. hierarchical-agents-examples.md Example 8 (Minimal Updates)

**Current Status**: Already documents dual coordinator integration (lines 894-1169)

**Minor Additions**:
- Add "Plan-Driven Mode" subsection under Implementation: /lean-implement
- Document execution_mode parameter in input contract
- Update integration test counts (48 → 83+ after new tests added)

**No Breaking Changes**: All existing content preserved

#### 3. /lean-build Command File (Implementation Required)

**New Block**: execution_mode Parameter Detection
```markdown
## Block 0b: Execution Mode Detection

```bash
# Determine execution mode based on plan_file presence
if [[ -f "$PLAN_FILE" ]]; then
  EXECUTION_MODE="plan-based"
  echo "[INFO] Plan file detected: $PLAN_FILE"
  echo "[INFO] Execution mode: plan-based (wave orchestration)"
else
  EXECUTION_MODE="file-based"
  echo "[INFO] No plan file provided"
  echo "[INFO] Execution mode: file-based (all theorems in file)"
fi

# Persist for coordinator invocation
append_workflow_state "EXECUTION_MODE" "$EXECUTION_MODE"
```
```

**Coordinator Invocation Update**:
```yaml
Task {
  prompt: |
    Read and follow: .claude/agents/lean-coordinator.md

    Input:
    - execution_mode: ${EXECUTION_MODE}  # NEW PARAMETER
    - plan_path: ${PLAN_FILE}  # May be empty for file-based
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths: {...}
}
```

#### 4. New Testing Guide (Optional but Recommended)

**File**: `.claude/docs/guides/testing/lean-coordinator-testing-guide.md`

**Purpose**: Consolidate testing patterns for lean-coordinator validation

**Sections**:
1. Test Suite Overview (existing 48 + new 35-40)
2. Test Isolation Patterns (prevent production directory pollution)
3. Dual-Mode Test Matrix (file-based vs plan-based)
4. Behavioral Compliance Checklist
5. Debugging Test Failures

---

## Research Question 4: Safest Refactoring Sequence

### Phased Refactoring Plan

**Principle**: Minimize blast radius, validate at each step, preserve existing functionality

#### Phase 1: Documentation Preparation (RISK: LOW)

**Objective**: Update documentation before code changes to establish contracts

**Tasks**:
1. ✓ Read existing documentation (hierarchical-agents-examples.md Example 8)
2. Update lean-coordinator.md:
   - Add backward compatibility notes to STEP 1-2
   - Document execution_mode parameter in Input Format
   - Add dual-mode behavior to Output Format
3. Create clean-break-exception comment template:
   ```bash
   # clean-break-exception: Dual-mode support for file-based backward compatibility
   # Expiration: N/A (permanent extension pattern)
   # Justification: /lean-build existing workflows require file-based mode preservation
   ```
4. Commit documentation updates separately

**Validation**: Documentation linter passes (`validate-all-standards.sh --links`)

**Rollback**: Git revert documentation commit (no code impact)

#### Phase 2: Test Infrastructure (RISK: LOW)

**Objective**: Create test scaffolding before implementation

**Tasks**:
1. Create `test_lean_coordinator_plan_mode.sh` with 8 initial tests:
   - test_plan_structure_detection (stub)
   - test_dependency_analysis_invocation (stub)
   - test_wave_execution_orchestration (stub)
   - test_phase_number_extraction (stub)
   - test_progress_tracking_forwarding (stub)
   - test_file_based_mode_preservation (CRITICAL - verifies no regression)
   - test_dual_mode_compatibility (stub)
   - test_blocking_detection_and_revision (stub)
2. Run test suite - all tests should SKIP (not implemented yet)
3. Commit test scaffolding

**Validation**: Test suite runs without errors (all SKIP)

**Rollback**: Delete test file (no code impact)

#### Phase 3: Mode Detection Logic (RISK: MEDIUM)

**Objective**: Add execution mode detection without changing core logic

**Tasks**:
1. Update lean-coordinator.md STEP 0 (new):
   ```markdown
   ### STEP 0: Execution Mode Detection

   Parse execution_mode from input:
   - IF execution_mode=file-based: Skip STEP 1-2, proceed to STEP 4 with all theorems
   - IF execution_mode=plan-based: Execute STEP 1-2 for dependency analysis
   ```
2. Add mode detection conditional (lean-coordinator implementation):
   ```bash
   if [[ "$execution_mode" == "file-based" ]]; then
     # Existing behavior - no plan parsing, no dependency analysis
     WAVE_STRUCTURE='{"waves": [{"theorems": [...all theorems from file...]}]}'
   elif [[ "$execution_mode" == "plan-based" ]]; then
     # New behavior - plan parsing, dependency analysis
     bash dependency-analyzer.sh "$plan_path" > /tmp/wave_structure.json
   fi
   ```
3. Update 1 test: test_file_based_mode_preservation (verify existing behavior)

**Validation**:
- Run test_lean_coordinator_plan_mode.sh
- Expected: 1/8 PASS (file-based mode), 7/8 SKIP
- Run all existing tests: 48/48 PASS (no regression)

**Rollback**: Git revert single commit (mode detection only)

#### Phase 4: Plan Structure Detection (RISK: MEDIUM)

**Objective**: Implement STEP 1 for plan-based mode only

**Tasks**:
1. Implement plan structure detection (Level 0 vs Level 1)
2. Build phase file list
3. Update test: test_plan_structure_detection (verify detection logic)

**Validation**:
- Run test_lean_coordinator_plan_mode.sh
- Expected: 2/8 PASS, 6/8 SKIP
- Run all existing tests: 48/48 PASS (no regression)

**Rollback**: Git revert Phase 4 commit (no impact on file-based mode)

#### Phase 5: Dependency Analysis Integration (RISK: HIGH)

**Objective**: Implement STEP 2 dependency analysis invocation

**Tasks**:
1. Add dependency-analyzer.sh invocation
2. Parse wave structure JSON
3. Validate dependency graph (cycle detection)
4. Update tests:
   - test_dependency_analysis_invocation
   - test_wave_execution_orchestration (partial - wave structure only)

**Validation**:
- Run test_lean_coordinator_plan_mode.sh
- Expected: 3/8 PASS, 5/8 SKIP
- Run all existing tests: 48/48 PASS (no regression)

**Rollback**: Git revert Phase 5 commit (dependency analysis isolated)

#### Phase 6: Wave Orchestration (RISK: CRITICAL)

**Objective**: Implement STEP 4 wave-by-wave execution

**Tasks**:
1. Implement wave execution loop
2. Parallel implementer invocation within waves
3. Wave synchronization (barrier before next wave)
4. Update tests:
   - test_wave_execution_orchestration (complete implementation)
   - test_dual_mode_compatibility

**Validation**:
- Run test_lean_coordinator_plan_mode.sh
- Expected: 5/8 PASS, 3/8 SKIP
- Run all existing tests: 48/48 PASS (no regression)

**Risk Mitigation**:
- Commit wave orchestration in isolated branch
- Run full test suite before merging
- If test failures: rollback to Phase 5, analyze, retry

**Rollback**: Git revert Phase 6 commit (wave orchestration isolated)

#### Phase 7: Progress Tracking Integration (RISK: LOW)

**Objective**: Add phase_number extraction and progress tracking forwarding

**Tasks**:
1. Extract phase_number from theorem metadata
2. Forward progress tracking instructions to lean-implementer
3. Update tests:
   - test_phase_number_extraction
   - test_progress_tracking_forwarding

**Validation**:
- Run test_lean_coordinator_plan_mode.sh
- Expected: 7/8 PASS, 1/8 SKIP
- Run all existing tests: 48/48 PASS (no regression)

**Rollback**: Git revert Phase 7 commit (progress tracking isolated)

#### Phase 8: Blocking Detection & Revision (RISK: MEDIUM)

**Objective**: Implement STEP 5.5 blocking dependency detection

**Tasks**:
1. Parse implementer outputs for partial theorems
2. Calculate context budget
3. Invoke lean-plan-updater when viable
4. Update test: test_blocking_detection_and_revision

**Validation**:
- Run test_lean_coordinator_plan_mode.sh
- Expected: 8/8 PASS (all tests complete)
- Run all existing tests: 48/48 PASS (no regression)

**Rollback**: Git revert Phase 8 commit (blocking detection isolated)

#### Phase 9: Integration Testing (RISK: LOW)

**Objective**: End-to-end validation with /lean-build command

**Tasks**:
1. Update /lean-build with execution_mode detection
2. Run full workflow test:
   - File-based mode: Verify existing behavior
   - Plan-based mode: Verify wave orchestration
3. Run complete test suite: 83+ tests (48 existing + 35 new)

**Validation**:
- All tests PASS
- No production directory pollution (test isolation)
- Coverage ≥85% for new code

**Rollback**: Git revert /lean-build changes only (lean-coordinator changes preserved)

#### Phase 10: Documentation Finalization (RISK: LOW)

**Objective**: Update all documentation with final implementation details

**Tasks**:
1. Update hierarchical-agents-examples.md Example 8 with test counts
2. Add lean-coordinator-testing-guide.md (optional)
3. Update CHANGELOG.md with feature summary
4. Commit documentation

**Validation**: Documentation linter passes

**Rollback**: Git revert documentation commit

### Rollback Strategy Summary

**Per-Phase Rollback**: Each phase is isolated in separate git commit
- Rollback single phase: `git revert <commit-hash>`
- Rollback multiple phases: `git revert <commit1>..<commitN>`

**Full Rollback**: Revert all 10 phases in reverse order
```bash
git log --oneline --grep="Phase [0-9]" | tac | awk '{print $1}' | xargs git revert
```

**Emergency Rollback**: If critical bug in production
```bash
git revert $(git log --oneline --since="2025-12-09" --grep="lean-coordinator" --format="%H") --no-commit
git commit -m "EMERGENCY: Revert lean-coordinator plan-driven mode (critical bug)"
```

---

## Risk Assessment

### High-Risk Areas

1. **Wave Orchestration Logic** (Phase 6)
   - **Risk**: Complex parallel execution, synchronization barriers
   - **Mitigation**: Extensive testing, isolated commit, full test suite validation
   - **Rollback**: Git revert Phase 6 commit

2. **Dependency Analysis Integration** (Phase 5)
   - **Risk**: Circular dependency detection, wave structure parsing
   - **Mitigation**: Use existing dependency-analyzer.sh utility (already tested)
   - **Rollback**: Git revert Phase 5 commit

3. **File Size Limit Violation** (lean-coordinator.md)
   - **Risk**: 1173 lines (~50KB) exceeds 40KB limit
   - **Mitigation**: Split into lean-coordinator.md + lean-coordinator-guide.md (Standard 14)
   - **Benefit**: 70% size reduction, fail-fast execution, eliminates meta-confusion

### Medium-Risk Areas

1. **Mode Detection Logic** (Phase 3)
   - **Risk**: Incorrect mode detection breaks both modes
   - **Mitigation**: Defensive conditionals, explicit error messages, test both modes
   - **Rollback**: Git revert Phase 3 commit

2. **Blocking Detection** (Phase 8)
   - **Risk**: Context budget calculation errors, revision depth tracking
   - **Mitigation**: Conservative estimates, max revision depth limit (2)
   - **Rollback**: Git revert Phase 8 commit

### Low-Risk Areas

1. **Documentation Updates** (Phase 1, 10)
   - **Risk**: Minimal - documentation errors don't break code
   - **Mitigation**: Documentation linter validation
   - **Rollback**: Git revert documentation commits

2. **Test Infrastructure** (Phase 2)
   - **Risk**: Minimal - tests don't affect production code
   - **Mitigation**: Run test suite before commit
   - **Rollback**: Delete test file

3. **Progress Tracking** (Phase 7)
   - **Risk**: Minimal - graceful degradation if checkbox-utils unavailable
   - **Mitigation**: Non-fatal errors, informational output only
   - **Rollback**: Git revert Phase 7 commit

---

## Standards Compliance Checklist

### Clean-Break Development Standard
- [x] Decision tree analysis completed (incremental change chosen)
- [x] Backward compatibility justified (<20 lines overhead)
- [ ] Exception documented if needed (dual-mode is extension, not exception)

### Code Standards
- [x] Three-tier sourcing pattern (already enforced in lean-coordinator)
- [x] Error logging integration (error-handling.sh already sourced)
- [x] Output suppression patterns (2>/dev/null for library sourcing)
- [x] No eager subdirectory creation (agents handle lazy creation)
- [ ] File size limit: RISK - lean-coordinator.md ~50KB (limit 40KB)
  - **Mitigation**: Apply Standard 14 (Executable/Documentation Separation)

### Testing Protocols
- [x] Test discovery patterns (integration tests in .claude/tests/integration/)
- [x] Coverage threshold ≥80% for modified code
- [x] Test isolation (CLAUDE_SPECS_ROOT override, cleanup traps)
- [x] Agent behavioral compliance tests (file creation, completion signal, STEPs)
- [x] Non-interactive execution (automated, programmatic validation)

### Documentation Standards
- [x] README requirements (hierarchical-agents-examples.md already exists)
- [x] Documentation format (CommonMark, UTF-8, no emojis in files)
- [x] No historical commentary (timeless writing policy)
- [ ] Executable/Documentation separation (RECOMMENDED for lean-coordinator.md)

### Hierarchical Agent Architecture
- [x] Supervisor pattern (lean-coordinator orchestrates lean-implementer)
- [x] Hard barrier enforcement (validation blocks, fail-fast)
- [x] Context reduction (metadata-only passing, brief summaries)
- [x] Wave-based orchestration (dependency analysis, parallel execution)

---

## Recommendations

### Critical Actions (MUST)

1. **Apply Incremental Change Pattern**
   - Add plan-driven mode alongside file-based mode
   - Preserve backward compatibility for existing workflows
   - Mode detection overhead: ~15 lines (acceptable)

2. **Preserve All 48 Existing Tests**
   - Run complete test suite after each phase
   - Required: 48/48 PASS (no regression)
   - Fail-fast on any test failures

3. **Add 35-40 New Tests for Plan-Driven Mode**
   - test_lean_coordinator_plan_mode.sh
   - Coverage target: ≥85% for new code
   - Test isolation: CLAUDE_SPECS_ROOT override

4. **Follow Phased Refactoring Sequence**
   - Phases 1-10 as documented above
   - Isolated commits per phase for easy rollback
   - Validation at each step before proceeding

### Recommended Actions (SHOULD)

1. **Apply Standard 14: Executable/Documentation Separation**
   - Split lean-coordinator.md (1173 lines) into:
     - lean-coordinator.md (≤400 lines, executable)
     - lean-coordinator-guide.md (unlimited, comprehensive)
   - Benefit: 70% size reduction, fail-fast execution, no meta-confusion

2. **Create Lean Coordinator Testing Guide**
   - File: .claude/docs/guides/testing/lean-coordinator-testing-guide.md
   - Consolidate testing patterns, dual-mode test matrix
   - Debugging workflows for test failures

3. **Document Dual-Mode Architecture in Example 8**
   - Update hierarchical-agents-examples.md
   - Add execution_mode parameter documentation
   - Update test counts (48 → 83+)

### Optional Actions (MAY)

1. **Create Visual Architecture Diagrams**
   - Dual-mode flow chart (file-based vs plan-based)
   - Wave orchestration sequence diagram
   - Use Unicode box-drawing (per code-standards.md)

2. **Add Performance Benchmarks**
   - Compare file-based vs plan-based execution time
   - Measure context reduction (target: 95-96%)
   - Document time savings (target: 40-60%)

---

## Conclusion

The optimal refactoring strategy for lean-coordinator optimization is **incremental change with extension pattern**, not clean-break refactoring. This approach:

1. **Preserves backward compatibility** for existing /lean-build file-based workflows
2. **Adds plan-driven mode** alongside existing functionality with minimal overhead (~15 lines)
3. **Maintains test coverage** (48 existing tests preserved, 35-40 new tests added)
4. **Follows .claude/docs/ standards** (clean-break decision tree, testing protocols, code standards)
5. **Enables safe rollback** via phased commit structure (10 isolated phases)

**Next Steps**:
1. Create implementation plan using /create-plan with this research report
2. Implement phases 1-10 sequentially with validation at each step
3. Monitor test suite (target: 83+ tests, 100% pass rate)
4. Apply Standard 14 for lean-coordinator.md size optimization (recommended)

**Success Criteria**:
- ✓ All 48 existing tests pass (no regression)
- ✓ 35-40 new tests pass (≥85% coverage)
- ✓ Both execution modes functional (file-based, plan-based)
- ✓ Documentation updated (hierarchical-agents-examples.md, lean-coordinator.md)
- ✓ Standards compliance (clean-break, testing, code, documentation)

---

RESEARCH_COMPLETE: /home/benjamin/.config/.claude/specs/065_lean_coordinator_wave_optimization/reports/004-refactor-strategy-standards.md

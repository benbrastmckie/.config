# Coordinate Command Robustness Improvements Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: Fix critical bugs and improve robustness of /coordinate command
- **Scope**: State machine initialization, verification checkpoints, bash preprocessing safety, documentation
- **Estimated Phases**: 4 phases (Critical Fixes → Stabilization → Documentation → Standardization)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/717_coordinate_command_error_analysis_performance/reports/001_coordinate_command_error_analysis_performance/OVERVIEW.md
  - /home/benjamin/.config/.claude/specs/717_coordinate_command_error_analysis_performance/reports/001_coordinate_command_error_analysis_performance/001_state_machine_initialization_failure_analysis.md
  - /home/benjamin/.config/.claude/specs/717_coordinate_command_error_analysis_performance/reports/001_coordinate_command_error_analysis_performance/002_bash_history_expansion_preprocessing_errors.md
  - /home/benjamin/.config/.claude/specs/717_coordinate_command_error_analysis_performance/reports/001_coordinate_command_error_analysis_performance/003_state_variable_verification_timing_issues.md
  - /home/benjamin/.config/.claude/specs/717_coordinate_command_error_analysis_performance/reports/001_coordinate_command_error_analysis_performance/004_coordinate_library_sourcing_and_persistence_patterns.md

## Overview

The /coordinate command has critical initialization bugs preventing execution. Research identified four interconnected issues:

1. **State Machine Initialization Failure**: `sm_init()` exports variables to bash environment but doesn't persist to state file, while verification expects file persistence
2. **Bash History Expansion Preprocessing Errors**: Bash tool preprocessing occurs before runtime `set +H`, causing "!: command not found" errors
3. **State Variable Verification Timing Issues**: Verification at line 308 checks state file BEFORE manual state persistence (lines 340-343)
4. **Library Sourcing and Persistence Patterns**: Sophisticated state persistence architecture serves as best practice reference

**Root Cause**: Architectural contract mismatch between `sm_init()` export behavior (environment variables) and coordinate.md verification expectations (state file persistence), combined with verification executing before state file writes complete.

**Impact**: Command fails deterministically at initialization, blocking all usage. No workaround exists - this is a P0 blocker.

**Solution Strategy**: Fix `sm_init()` to persist state variables to file, reorder verification checkpoint to execute after state persistence, apply bash preprocessing workarounds, and document architectural contracts.

## Success Criteria
- [ ] /coordinate command completes Phase 0 initialization without errors
- [ ] State file contains all 5 required variables (WORKFLOW_SCOPE, TERMINAL_STATE, CURRENT_STATE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON)
- [ ] Verification checkpoint passes after state persistence completes
- [ ] No bash preprocessing errors during execution
- [ ] All existing tests pass (historical test suite: 47/47 target)
- [ ] Documentation clearly describes state persistence contracts

## Technical Design

### Architecture Decisions

**Decision 1: sm_init() State Persistence Strategy**

*Options considered*:
- Option A: Have `sm_init()` call `append_workflow_state()` internally for all classification variables
- Option B: Keep `sm_init()` as environment-only, document that callers must persist manually
- Option C: Refactor `sm_init()` with optional parameter for file persistence

*Selected: Option A*

Rationale:
- Aligns with COMPLETED_STATES persistence pattern (workflow-state-machine.sh:144-145)
- Eliminates ordering dependencies between init and verification
- Provides single source of truth for state initialization
- Minimal impact: `sm_init()` already sources state-persistence.sh

Trade-offs:
- Couples state machine library with state persistence (acceptable - already coupled via append_workflow_state usage elsewhere)
- Requires testing all commands using workflow-state-machine.sh (/coordinate, /orchestrate, /supervise)

**Decision 2: Verification Checkpoint Placement**

*Options considered*:
- Option A: Move verification from line 308 to after line 343 (after all append_workflow_state calls)
- Option B: Add pre-verification of environment variables at line 308, keep state file verification at 346
- Option C: Remove verification entirely (rely on function return codes)

*Selected: Option A + partial Option B*

Rationale:
- Line 308 verification is fundamentally misplaced (checks file before writes complete)
- Environment variable verification provides early failure detection
- State file verification after persistence ensures data integrity
- Two-stage verification (environment → file) provides clear diagnostic context

Implementation:
- Add environment variable verification after `sm_init()` (line ~240)
- Move state file verification to after line 343
- Verify all 5 state machine variables (add TERMINAL_STATE, CURRENT_STATE)

**Decision 3: Bash Preprocessing Safety Pattern**

*Options considered*:
- Option A: Apply exit code capture pattern to all `if ! function_call` locations
- Option B: Use positive conditional logic where possible (`if function_call; then else`)
- Option C: Use test command negation (`if [ $? -ne 0 ]`)

*Selected: Option A as primary, Option B where clearer*

Rationale:
- Exit code capture pattern validated across 15+ historical specifications
- Explicit, readable, and fail-safe
- Positive logic sometimes less clear (inverted semantics)
- Test command pattern acceptable for simple cases

Pattern:
```bash
# BEFORE (unsafe):
if ! sm_init "$args"; then
  echo "ERROR: Initialization failed"
  exit 1
fi

# AFTER (safe):
sm_init "$args"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Initialization failed"
  exit 1
fi
```

### Component Interactions

**Modified Components**:
1. `.claude/lib/workflow-state-machine.sh` - `sm_init()` function (lines 391-402)
2. `.claude/commands/coordinate.md` - verification checkpoint placement (lines 308, 340-343)
3. `.claude/commands/coordinate.md` - bash preprocessing safety (multiple locations with `if ! `)

**Integration Points**:
- `sm_init()` → `append_workflow_state()` → state file persistence
- Verification checkpoints → `verify_state_variables()` → state file grep
- Error handling → `handle_state_error()` → diagnostic output

**Dependency Graph**:
```
sm_init() (modified)
  ├─> extract_classification_from_json() [unchanged]
  ├─> append_workflow_state() [new calls added]
  └─> verify_state_variables() [moved to correct location]
       └─> verify_state_variable() [unchanged]
```

### Data Flow

**Before Fix** (broken):
```
1. workflow-classifier agent returns CLASSIFICATION_JSON
2. sm_init() extracts values, exports to bash environment
3. ❌ VERIFICATION CHECKPOINT (line 308) - checks state file (empty)
4. append_workflow_state() writes to state file (lines 340-343)
5. ✓ State file now contains variables (too late)
```

**After Fix** (correct):
```
1. workflow-classifier agent returns CLASSIFICATION_JSON
2. sm_init() extracts values, exports to bash environment, persists to state file
3. ✓ Environment variable verification - checks exports succeeded
4. append_workflow_state() writes additional variables (if needed)
5. ✓ State file verification - checks all 5 variables present
```

## Implementation Phases

### Phase 1: Critical Fixes (P0 - Blocks All Usage) [COMPLETED]
**Objective**: Fix initialization bugs preventing command execution
**Complexity**: Medium
**Estimated Time**: 25 minutes

Tasks:
- [x] **Task 1.1**: Modify `sm_init()` to persist classification variables to state file (.claude/lib/workflow-state-machine.sh:391-402)
  - Add `append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"` after line 395
  - Add `append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"` after line 396
  - Add `append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"` after line 399
  - Follow COMPLETED_STATES persistence pattern (lines 144-145)
  - Verify state-persistence.sh is already sourced (it is - line 8)
  - Estimated: 10 minutes

- [x] **Task 1.2**: Reorder verification checkpoint in coordinate.md
  - Remove or comment out verification at line 308 (premature check)
  - Move comprehensive verification to after line 343 (after all state persistence)
  - Verify all 5 variables: WORKFLOW_SCOPE, TERMINAL_STATE, CURRENT_STATE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
  - Update error message to describe state file persistence failure (not environment export)
  - Use verification pattern from lines 162-164 (verify_file_created + handle_state_error)
  - Estimated: 15 minutes

Testing:
```bash
# Test 1: Verify sm_init creates state file entries
cd /home/benjamin/.config
source .claude/lib/workflow-state-machine.sh
source .claude/lib/state-persistence.sh
STATE_FILE="/tmp/test_state_$(date +%s).sh"
export STATE_FILE
CLASSIFICATION_JSON='{"scope":"research-only","complexity":2,"topics":["topic1","topic2"]}'
sm_init "$CLASSIFICATION_JSON" "coordinate"
# Verify state file contains exports
grep "WORKFLOW_SCOPE" "$STATE_FILE"
grep "RESEARCH_COMPLEXITY" "$STATE_FILE"
grep "RESEARCH_TOPICS_JSON" "$STATE_FILE"
# Expected: All 3 grep commands succeed

# Test 2: Run coordinate command through initialization
/coordinate "test workflow classification"
# Expected: No verification errors, state machine initializes successfully
```

Validation:
- Coordinate command completes Phase 0 without errors
- State file exists and contains WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
- Verification checkpoint reports success

### Phase 2: Stabilization (P1 - Improves Reliability) [COMPLETED]
**Objective**: Apply bash preprocessing safety patterns and add environment variable verification
**Complexity**: Medium
**Estimated Time**: 50 minutes

Tasks:
- [x] **Task 2.1**: Audit coordinate.md for vulnerable bash preprocessing patterns
  - Search for all `if ! ` patterns in coordinate.md
  - Identify which patterns use function calls (preprocessing vulnerable)
  - Document locations and contexts for replacement
  - Estimated: 10 minutes

- [x] **Task 2.2**: Apply exit code capture pattern to vulnerable locations
  - Replace `if ! function_call` with exit code capture pattern
  - Target locations likely include: sm_transition calls, verification checkpoints
  - Pattern: `function_call; EXIT=$?; if [ $EXIT -ne 0 ]; then ...`
  - Maintain error messages and exit codes (no behavior change)
  - Estimated: 20 minutes

- [x] **Task 2.3**: Add environment variable verification after sm_init() (.claude/commands/coordinate.md:~240)
  - Insert verification block after sm_init completes
  - Check WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON are exported
  - Use `[ -z "${VAR:-}" ]` pattern to detect missing variables
  - Provide clear error messages distinguishing environment vs file persistence failures
  - Estimated: 20 minutes

Testing:
```bash
# Test 1: Preprocessing safety - verify no "!: command not found" errors
/coordinate "complex workflow with multiple phases"
# Expected: No preprocessing errors in output, clean execution

# Test 2: Environment variable verification triggers on sm_init failure
# Manually break sm_init to test error handling (restore after test)
# Expected: Clear error message about environment variable missing

# Test 3: Run coordinate command through full workflow
/coordinate "research authentication patterns and create implementation plan"
# Expected: Completes research phase, transitions to planning phase
```

Validation:
- No bash preprocessing errors during coordinate execution
- Environment variable verification provides actionable diagnostics
- Error messages clearly distinguish environment export vs state file persistence failures

### Phase 3: Documentation (P2 - Prevents Future Issues)
**Objective**: Document state persistence contracts and architectural patterns
**Complexity**: Low
**Estimated Time**: 45 minutes

Tasks:
- [ ] **Task 3.1**: Document sm_init() state persistence contract (.claude/lib/workflow-state-machine.sh:391-402)
  - Add function header documentation describing:
    - Purpose: Initialize state machine and persist classification variables
    - Parameters: CLASSIFICATION_JSON, command_name
    - Environment: Exports WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
    - State File: Persists same variables using append_workflow_state
    - Returns: 0 on success, 1 on validation failure
  - Reference COMPLETED_STATES pattern as canonical example (lines 144-145)
  - Document calling pattern: sm_init → verify environment → verify state file
  - Estimated: 15 minutes

- [ ] **Task 3.2**: Expand state reloading comments in coordinate.md
  - Replace terse comment "Re-load workflow state (needed after Task invocation)" (line ~330)
  - Add comprehensive block explaining:
    - Subprocess isolation: Each bash block runs in separate subprocess (different PID)
    - State restoration requirements: Environment variables don't persist across blocks
    - File-based persistence: GitHub Actions pattern enables cross-block communication
    - Ordering dependencies: Load state before using state variables
  - Reference .claude/docs/concepts/bash-block-execution-model.md for details
  - Estimated: 10 minutes

- [ ] **Task 3.3**: Document bash tool preprocessing limitations
  - Create/update .claude/docs/troubleshooting/bash-tool-limitations.md
  - Explain preprocessing architecture:
    - Bash tool wrapper executes BEFORE runtime bash interpretation
    - `set +H` is runtime directive, cannot affect preprocessing stage
    - Timeline: Preprocessing (history expansion) → Runtime (set +H executes)
  - Provide workaround patterns:
    - Exit code capture: `func; EXIT=$?; if [ $EXIT -ne 0 ]`
    - Positive logic: `if func; then else ...`
    - Test command: `if [ $? -ne 0 ]` after explicit call
  - Reference historical specs: 620, 641, 672, 685, 700
  - Estimated: 20 minutes

Testing:
```bash
# Documentation validation - verify references are accurate
# Test 1: Check sm_init documentation describes actual behavior
cat .claude/lib/workflow-state-machine.sh | grep -A 20 "^sm_init()"
# Expected: Function header with parameters, environment, state file, returns

# Test 2: Verify bash-block-execution-model.md exists and describes subprocess isolation
cat .claude/docs/concepts/bash-block-execution-model.md | grep -i "subprocess"
# Expected: Documentation explains PID differences and state restoration

# Test 3: Check bash-tool-limitations.md contains preprocessing timeline explanation
cat .claude/docs/troubleshooting/bash-tool-limitations.md | grep -i "preprocessing"
# Expected: Clear explanation of preprocessing vs runtime timeline
```

Validation:
- Function contracts documented with parameters, behavior, returns
- Inline comments explain subprocess isolation and restoration patterns
- Troubleshooting guide provides preprocessing architecture explanation with workarounds

### Phase 4: Standardization (P3 - Long-term Improvements)
**Objective**: Standardize state persistence patterns across all orchestrators
**Complexity**: High
**Estimated Time**: 4 hours

Tasks:
- [ ] **Task 4.1**: Audit /orchestrate and /supervise commands for state persistence patterns
  - Identify if commands use workflow-state-machine.sh
  - Check state persistence mechanisms (file-based vs other)
  - Document current state ID patterns (PID-based, timestamp-based, fixed filename)
  - Identify differences from /coordinate's pattern
  - Estimated: 30 minutes

- [ ] **Task 4.2**: Migrate /orchestrate to coordinate's state ID file pattern
  - Replace PID-based workflow IDs with timestamp-based IDs
  - Use fixed semantic filename pattern: `${COMMAND_NAME}_state_id.txt`
  - Update state file initialization and restoration logic
  - Verify subprocess isolation handling matches coordinate pattern
  - Test orchestrate command through full workflow
  - Estimated: 1 hour

- [ ] **Task 4.3**: Migrate /supervise to coordinate's state ID file pattern (if needed)
  - Assess if /supervise uses different pattern (may already be compliant)
  - Apply same timestamp-based ID and fixed filename pattern
  - Update documentation to reference coordinate as canonical example
  - Test supervise command functionality
  - Estimated: 1 hour

- [ ] **Task 4.4**: Create library sourcing order standard (Standard 15 extraction)
  - Extract coordinate.md's 5-step sourcing pattern to new document
  - Create .claude/docs/reference/library-sourcing-order.md
  - Document pattern:
    1. Source state persistence libraries first
    2. Load state from files (using fixed semantic filename)
    3. Source error handling libraries
    4. Source verification helpers
    5. Source additional domain-specific libraries
  - Explain rationale: State must be available before verification, error handling needed throughout
  - Reference from all orchestration commands (coordinate, orchestrate, supervise)
  - Estimated: 1 hour

- [ ] **Task 4.5**: Create validation test suite for bash preprocessing safety
  - Create .claude/tests/test_bash_preprocessing_safety.sh
  - Implement checks:
    - Scan all .md commands for unprotected `if ! ` patterns
    - Verify `set +H` appears in all bash blocks
    - Check for indirect history expansion (`!$`, `!!`, etc)
    - Validate exit code capture pattern usage
  - Integrate into .claude/tests/run_all_tests.sh
  - Run suite and fix any findings
  - Estimated: 30 minutes

Testing:
```bash
# Test 1: Verify /orchestrate uses timestamp-based workflow IDs
/orchestrate "test workflow"
# Check that .claude/tmp/orchestrate_state_id.txt exists and contains timestamp ID
cat .claude/tmp/orchestrate_state_id.txt
# Expected: timestamp-based ID (orchestrate_1731600000 format)

# Test 2: Verify library sourcing order standard is referenced
grep -r "library-sourcing-order.md" .claude/commands/
# Expected: coordinate.md, orchestrate.md, supervise.md all reference the standard

# Test 3: Run validation test suite
.claude/tests/test_bash_preprocessing_safety.sh
# Expected: 0 failures, all commands follow preprocessing safety patterns

# Test 4: Full regression testing
.claude/tests/run_all_tests.sh
# Expected: All tests pass (maintain 47/47 coordinate tests, others as baseline)
```

Validation:
- All orchestrators use consistent state ID file pattern (timestamp-based, fixed filename)
- Library sourcing order standard documented and referenced by all commands
- Validation test suite integrated into CI/CD, catches preprocessing vulnerabilities
- Full regression test suite passes (100% success rate target)

## Testing Strategy

### Unit Tests
1. **sm_init() State Persistence**
   - Test: Call `sm_init()` with valid CLASSIFICATION_JSON, verify state file contains all 3 variables
   - Assertion: `grep "WORKFLOW_SCOPE" "$STATE_FILE"` succeeds
   - Assertion: `grep "RESEARCH_COMPLEXITY" "$STATE_FILE"` succeeds
   - Assertion: `grep "RESEARCH_TOPICS_JSON" "$STATE_FILE"` succeeds

2. **Verification Checkpoint Ordering**
   - Test: Mock state file operations, verify verification executes after append_workflow_state
   - Assertion: Verification function called AFTER state persistence function
   - Assertion: No verification errors when variables are present

3. **Environment Variable Exports**
   - Test: Call `sm_init()`, check environment contains exported variables
   - Assertion: `[ -n "${WORKFLOW_SCOPE:-}" ]` succeeds
   - Assertion: Variables have correct values from CLASSIFICATION_JSON

### Integration Tests
1. **Full Coordinate Command Execution**
   - Test: `/coordinate "research auth patterns and create plan"`
   - Verify: Completes Phase 0 initialization without errors
   - Verify: State file created with all 5 variables
   - Verify: Transitions through states correctly (research → plan)

2. **Cross-Bash-Block State Restoration**
   - Test: Execute coordinate workflow with multiple bash blocks
   - Verify: State loads correctly in second bash block
   - Verify: WORKFLOW_ID persists across blocks
   - Verify: No "variable not found" errors

3. **Preprocessing Safety**
   - Test: Scan coordinate.md for `if ! ` patterns
   - Verify: All patterns use exit code capture or positive logic
   - Verify: No "!: command not found" errors during execution

### Regression Tests
1. **Historical Test Suite**
   - Test: Run existing coordinate tests (Spec 620 baseline: 47/47 pass rate)
   - Target: Maintain 100% pass rate
   - Verify: No existing functionality broken by changes

2. **Multi-Workflow Concurrency**
   - Test: Run two `/coordinate` invocations concurrently
   - Verify: Timestamp-based IDs prevent collision
   - Verify: Each workflow maintains separate state file
   - Verify: No state file corruption or race conditions

3. **State File Cleanup**
   - Test: Execute coordinate workflow to completion
   - Verify: Trap handlers execute on success
   - Verify: Temporary files cleaned up (state files, workflow description files)
   - Verify: No .claude/tmp pollution after cleanup

### Performance Tests
1. **Verification Overhead Measurement**
   - Baseline: Measure coordinate execution time before comprehensive verification
   - Modified: Measure execution time after adding verification checkpoints
   - Target: <50ms overhead for verification (15-30ms expected)
   - Acceptance: <2% total execution time increase

2. **State File I/O Performance**
   - Test: Measure time for append_workflow_state operations
   - Baseline: ~2-5ms per variable (grep + echo operations)
   - Verify: No degradation with additional persistence calls
   - Target: <10ms total for 5 variable persistence

## Documentation Requirements

### Updated Files
1. `.claude/lib/workflow-state-machine.sh` - Function header documentation for sm_init()
2. `.claude/commands/coordinate.md` - Expanded state reloading comments
3. `.claude/docs/troubleshooting/bash-tool-limitations.md` - Preprocessing architecture explanation
4. `.claude/docs/reference/library-sourcing-order.md` - New standard document (Standard 15)

### Documentation Standards
- Follow .claude/docs/DOCUMENTATION_STANDARDS.md format
- Use present-focused language (no "previously" or historical markers)
- Include code examples with actual file paths
- Reference related documents (bash-block-execution-model.md, etc)
- Provide troubleshooting guidance for common errors

### Content Requirements
- **Function Documentation**: Parameters, environment, state file, returns, errors
- **Architectural Patterns**: Subprocess isolation, state persistence, verification checkpoints
- **Workaround Patterns**: Exit code capture, positive logic, test command negation
- **References**: Link to historical specs validating patterns (620, 641, 672, 685, 700)

## Dependencies

### External Dependencies
- None (all changes are internal to .claude/ infrastructure)

### Internal Dependencies
- `.claude/lib/workflow-state-machine.sh` - Core library for state management
- `.claude/lib/state-persistence.sh` - GitHub Actions pattern implementation
- `.claude/lib/verification-helpers.sh` - Verification checkpoint functions
- `.claude/lib/error-handling.sh` - Error reporting and handling

### Tool Dependencies
- `jq` - JSON parsing (already required, used by workflow-classifier)
- `bash` (v4.0+) - Associative arrays and process substitution
- `grep`, `sed`, `awk` - Text processing for state file operations

## Risk Assessment

### High Risk Items

**Risk 1: sm_init() Modification Affects Multiple Commands**
- **Impact**: Breaking changes to /orchestrate, /supervise if not tested
- **Probability**: Medium (depends on implementation coordination)
- **Severity**: High (blocks all orchestration commands)
- **Mitigation**:
  - Test all commands using workflow-state-machine.sh before release
  - Add optional backward compatibility parameter to sm_init if needed
  - Document migration guide for custom orchestrators
  - Run full regression suite across all orchestration commands

**Risk 2: State File Format Changes Break Workflow Recovery**
- **Impact**: In-progress workflows cannot resume after updates
- **Probability**: Low (no format changes proposed, only timing fixes)
- **Severity**: High (data loss for long-running workflows)
- **Mitigation**:
  - Maintain GitHub Actions export format (no changes needed)
  - Add version detection to state file headers if future changes needed
  - Test workflow resumption before/after changes
  - Document state file format stability guarantee

### Medium Risk Items

**Risk 3: Verification Performance Overhead**
- **Impact**: Slower command execution, higher context budget usage
- **Probability**: Low (15-30ms overhead is negligible)
- **Severity**: Medium (could affect very tight context budgets)
- **Mitigation**:
  - Measure performance before/after changes
  - Optimize verification if overhead exceeds 50ms
  - Use batched grep operations for multiple variable checks
  - Document verification performance characteristics

**Risk 4: Incomplete Preprocessing Pattern Coverage**
- **Impact**: Bash preprocessing errors still occur in edge cases
- **Probability**: Medium (complex bash patterns hard to audit completely)
- **Severity**: Medium (individual command failures, not systemic)
- **Mitigation**:
  - Implement validation test suite (Task 4.5) to catch patterns
  - Run test suite on every commit (CI/CD integration)
  - Document reporting process for new preprocessing issues
  - Maintain knowledge base of workaround patterns

### Low Risk Items

**Risk 5: Documentation Drift Over Time**
- **Impact**: Documentation becomes outdated as code evolves
- **Probability**: Medium (documentation often lags code changes)
- **Severity**: Low (doesn't affect functionality, reduces maintainability)
- **Mitigation**:
  - Include documentation updates in same commit as code changes
  - Require documentation review in PR process
  - Add documentation coverage checks to test suite
  - Schedule quarterly documentation audits

## Notes

### Comparison with /optimize-claude Command

The research suggested comparing with /optimize-claude command as a reference for robust orchestration. Key observations:

**Similarities**:
- Both use state machine architecture for multi-phase workflows
- Both delegate to specialized agents (research, analysis, planning)
- Both use verification checkpoints to ensure agent artifact creation
- Both implement fail-fast error handling

**Differences**:
1. **Complexity**: /optimize-claude is simpler (5 sequential phases) vs /coordinate (dynamic state machine with branching)
2. **State Persistence**: /optimize-claude uses simpler path-based state vs /coordinate's full state machine
3. **Verification**: /optimize-claude has inline file existence checks vs /coordinate's comprehensive state verification
4. **Error Handling**: /optimize-claude exits immediately on agent failure vs /coordinate's recovery mechanisms

**Lessons Learned**:
- /optimize-claude's inline verification pattern (`if [ ! -f "$REPORT" ]; then ERROR; exit 1`) is clear and effective
- Simpler workflows may not need full state machine machinery
- Fail-fast verification immediately after agent invocation prevents cascading failures
- Clear progress messages improve user experience ("Stage 1: Research...", "Stage 2: Analysis...")

**Applied to This Plan**:
- Use /optimize-claude's verification pattern for clarity (Task 1.2)
- Document when to use simple verification vs full state machine (Task 3.1)
- Emphasize fail-fast philosophy in coordinate.md comments (Task 3.2)

### Additional Considerations

**Backward Compatibility**: Phase 1-3 changes maintain backward compatibility (no API changes, only internal fixes). Phase 4 requires coordination across commands but doesn't break existing workflows.

**Incremental Deployment**: Each phase can be deployed independently:
- Phase 1: Immediate deployment (fixes critical bug)
- Phase 2: Deploy after Phase 1 validation (adds safety, no breaking changes)
- Phase 3: Documentation-only (no functional changes)
- Phase 4: Requires coordination (deploy after testing all orchestrators)

**Rollback Strategy**: If Phase 1 introduces regressions:
1. Revert sm_init() changes (restore environment-only behavior)
2. Keep verification at original location (line 308)
3. Document known issue (verification fails, workaround: manual state persistence)
4. Investigate alternative fix (Option B or C from Decision 1)

**Long-term Vision**: This plan establishes patterns for robust orchestration that can be adopted by other commands (/implement, /document, /test). The standardization in Phase 4 creates foundation for consistent state management across entire .claude/ infrastructure.

### Success Metrics

**Immediate (Phase 1)**:
- Coordinate command initialization success rate: 0% → 100%
- Time to first working execution: Currently blocked → <1 minute

**Short-term (Phase 2-3)**:
- Bash preprocessing errors: Multiple known cases → 0 occurrences
- Documentation coverage: Partial → Comprehensive (contracts, patterns, workarounds)
- Developer onboarding time: Estimated 50% reduction with better docs

**Long-term (Phase 4)**:
- Orchestration command consistency: 3 different patterns → 1 standard pattern
- Test coverage: 47/47 coordinate tests → Full suite for all orchestrators
- Maintenance burden: Estimated 40% reduction with standardization

## References

### Research Reports
- [OVERVIEW.md](../reports/001_coordinate_command_error_analysis_performance/OVERVIEW.md) - Comprehensive synthesis of all findings
- [State Machine Initialization Failure Analysis](../reports/001_coordinate_command_error_analysis_performance/001_state_machine_initialization_failure_analysis.md)
- [Bash History Expansion Preprocessing Errors](../reports/001_coordinate_command_error_analysis_performance/002_bash_history_expansion_preprocessing_errors.md)
- [State Variable Verification Timing Issues](../reports/001_coordinate_command_error_analysis_performance/003_state_variable_verification_timing_issues.md)
- [Coordinate Library Sourcing and Persistence Patterns](../reports/001_coordinate_command_error_analysis_performance/004_coordinate_library_sourcing_and_persistence_patterns.md)

### Primary Source Files
- `.claude/commands/coordinate.md` (2,371 lines) - Command implementation
- `.claude/commands/optimize-claude.md` (326 lines) - Reference for robust orchestration
- `.claude/lib/workflow-state-machine.sh` (825 lines) - State machine library
- `.claude/lib/state-persistence.sh` (393 lines) - GitHub Actions state pattern
- `.claude/lib/verification-helpers.sh` (368 lines) - Verification checkpoints

### Supporting Documentation
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns
- `.claude/docs/troubleshooting/bash-tool-limitations.md` - Preprocessing constraints
- `.claude/docs/guides/coordinate-command-guide.md` - Coordinate architecture and usage
- `.claude/docs/guides/orchestration-best-practices.md` - Production patterns

### Historical Specifications
- Spec 620: Fix coordinate bash history expansion errors (47/47 test pass rate)
- Spec 641: Array serialization preprocessing workaround
- Spec 672: State persistence fail-fast validation
- Spec 685: Bash tool limitations documentation
- Spec 700: Comprehensive bash history expansion analysis

### Standards References
- Standard 0: Execution Enforcement (fail-fast verification checkpoints)
- Standard 13: CLAUDE_PROJECT_DIR detection and usage
- Standard 14: Command architecture (executable/documentation separation)
- Standard 15: Library sourcing order (to be extracted in Phase 4)

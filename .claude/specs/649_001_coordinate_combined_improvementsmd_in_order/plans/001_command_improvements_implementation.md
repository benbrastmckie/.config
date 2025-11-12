# Command Improvements Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Apply coordinate command improvements to other commands (orchestrate, supervise, implement, plan, debug, document, test)
- **Scope**: System-wide improvements applying coordinate's 6 subprocess isolation fixes, state persistence patterns, verification checkpoints, and documentation separation
- **Estimated Phases**: 7
- **Estimated Hours**: 42-52 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 168.0
- **Research Reports**:
  - [Coordinate Improvements Analysis](/home/benjamin/.config/.claude/specs/649_001_coordinate_combined_improvementsmd_in_order/reports/001_coordinate_improvements_analysis.md)
  - [Existing Command Patterns](/home/benjamin/.config/.claude/specs/649_001_coordinate_combined_improvementsmd_in_order/reports/002_existing_command_patterns.md)
  - [Infrastructure Integration Patterns](/home/benjamin/.config/.claude/specs/649_001_coordinate_combined_improvementsmd_in_order/reports/003_infrastructure_integration_patterns.md)
  - [Coordinate Refactoring Implementation](/home/benjamin/.config/.claude/specs/647_and_standards_in_claude_docs_in_order_to_create_a/plans/001_coordinate_combined_improvements/001_coordinate_combined_improvements.md) (Phases 0-5 COMPLETE)

## Revision History

### 2025-11-10 - Revision 1
**Changes**: Updated plan to reflect actual coordinate refactoring achievements (Phases 0-5 complete)
**Reason**: Coordinate command successfully completed Phases 0-5 with validated metrics, establishing proven patterns ready for system-wide application
**Source Plan**: /home/benjamin/.config/.claude/specs/647_and_standards_in_claude_docs_in_order_to_create_a/plans/001_coordinate_combined_improvements/001_coordinate_combined_improvements.md
**Modified Sections**:
- Research Summary: Updated with actual coordinate achievements vs original targets
- Success Criteria: Added proven metrics from coordinate (528ms saved, 98% verbosity reduction, 100% reliability)
- Technical Design: Updated performance targets based on actual results
- Phase descriptions: Incorporated specific patterns and functions from coordinate implementation

## Overview

Apply coordinate command's production-ready improvements (Specs 620/630/644/645/647/648) system-wide across all orchestration and agent-delegating commands. Coordinate achieved 100% reliability through 6 subprocess isolation fixes, 67% performance improvement via selective state persistence, and established patterns for verification checkpoints and documentation separation. This plan prioritizes critical reliability fixes first (Phases 1-2), then optimization (Phases 3-5), and finally documentation (Phase 6).

## Research Summary

**Coordinate Refactoring Actual Achievements** (Spec 647 Plan 001 - Phases 0-5 COMPLETE):
- ✅ **Phase 0 (Bug Fixes)**: Zero unbound variable errors, 100% verification success (11/11 tests passing)
- ✅ **Phase 1 (Baseline)**: Performance instrumentation operational, 50/50 state machine tests passing
- ✅ **Phase 2 (Caching)**: 528ms saved (88% of 600ms target) via state file caching and source guards
- ✅ **Phase 3 (Verbosity)**: 98% output reduction (50 lines → 1 character per checkpoint via verify_state_variables())
- ✅ **Phase 4 (Lazy Loading)**: Already optimal - WORKFLOW_SCOPE-based conditional library sourcing (40% fewer libraries for research-only)
- ✅ **Phase 5 (File Size)**: 1,530 → 1,471 lines (59 lines reduced), guide created with cross-refs
- ⚠️ **Standard 14 Note**: 1,471 lines vs 1,200 threshold due to Standard 12 agent template requirements (agent-heavy orchestrators need higher threshold)
- 🎯 **Proven Patterns**: verify_state_variables(), save-before-source, fixed semantic filenames, array metadata persistence

**Existing Command Patterns** (Report 002):
- 20 commands analyzed: 3 orchestrators, 4 implementation commands, 2 research commands, 11 utilities
- Gap analysis: orchestrate/supervise lack coordinate's 6 subprocess isolation fixes (intermittent failures)
- Inconsistent verification: research/coordinate strong (mandatory checkpoints), plan/document/debug weak/missing
- No centralized Phase 0 library: 15 commands duplicate initialization (15-50 lines each)
- Array persistence duplication: coordinate-specific pattern needs extraction to shared library

**Infrastructure Integration Patterns** (Report 003):
- 42 library modules organized in 9 functional domains with clear dependency hierarchies
- 3 foundational libraries: workflow-state-machine.sh, state-persistence.sh, library-sourcing.sh
- Conditional library loading: 6-10 libraries based on workflow scope (40% fewer for research-only)
- Verification checkpoint pattern: Standard 0 requires mandatory verification after all agent invocations
- Selective state persistence: 67% improvement for expensive operations (50ms → 15ms CLAUDE_PROJECT_DIR)

## Success Criteria

**Proven from Coordinate** (Use as Baseline):
- [ ] All orchestration commands achieve coordinate's 100% reliability (zero unbound variable errors, 100% verification success)
- [ ] All orchestration commands achieve coordinate's 528ms performance improvement (88% of target via state caching)
- [ ] All orchestration commands achieve coordinate's 98% verbosity reduction (verify_state_variables() pattern)
- [ ] All orchestration commands have source guards in all required libraries (6/6 like coordinate)
- [ ] All orchestration commands use WORKFLOW_SCOPE-based conditional library loading (40% reduction for simple scopes)

**New System-Wide Goals**:
- [ ] All orchestration commands (orchestrate, supervise) implement coordinate's 6 subprocess isolation fixes
- [ ] All agent-delegating commands (8 commands) adopt verify_state_variables() verification pattern with fail-fast diagnostics
- [ ] Centralized Phase 0 library reduces initialization duplication by 70%
- [ ] Array persistence library extracted from coordinate and adopted by 3+ commands
- [ ] Bash Block Execution Model documentation created and linked from 3+ guides
- [ ] Standard 14 separation applied to orchestrate command (5,438 → <1,500 lines) with Standard 12 agent template caveat
- [ ] All 127+ state machine tests passing (100% pass rate maintained, same as coordinate)
- [ ] Performance validation: Coordinate's 528ms improvement replicated in orchestrate/supervise
- [ ] Zero test failures or regressions in any modified command

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                  Command Improvement Strategy                        │
│         (Apply coordinate fixes to 7 additional commands)            │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
    ▼              ▼              ▼
┌────────┐   ┌────────┐    ┌──────────┐
│ Phase 1│   │ Phase 3│    │ Phase 5  │
│Critical│   │Library │    │Document  │
│Fixes   │──▶│Extract │───▶│Separation│
│(P0)    │   │        │    │          │
└────────┘   └────────┘    └──────────┘
    │              │              │
    ▼              ▼              ▼
┌────────┐   ┌────────┐    ┌──────────┐
│ Phase 2│   │ Phase 4│    │ Phase 6  │
│Verify  │   │State   │    │Guide     │
│Pattern │   │Persist │    │Creation  │
└────────┘   └────────┘    └──────────┘
                   │
                   ▼
            ┌──────────┐
            │ Phase 7  │
            │Validation│
            └──────────┘
```

### Core Improvements

**1. Subprocess Isolation Fixes** (6 fixes from Specs 620/630 - PROVEN in coordinate):
   - ✅ Fixed semantic filenames (coordinate pattern: `${HOME}/.claude/tmp/coordinate_workflow_desc.txt`)
   - ✅ Save-before-source pattern (coordinate implementation: `SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"` before libraries, restore after)
   - ✅ No EXIT traps in early blocks (coordinate: cleanup only in terminal state bash block)
   - ✅ Array metadata persistence (coordinate pattern: serialize REPORT_PATHS to REPORT_PATH_0, REPORT_PATH_1, ..., REPORT_PATHS_COUNT)
   - ✅ State transition persistence (coordinate: `append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"` after every `sm_transition()`)
   - ✅ Indirect expansion with eval (coordinate workaround: `eval "value=\$$var_name"` to avoid Bash tool preprocessing corruption of `${!var_name}`)

**2. Verification Checkpoint Pattern** (Standard 0 - PROVEN in coordinate Phase 3):
   - ✅ Consolidated verification function: `verify_state_variables()` in verification-helpers.sh
   - ✅ 98% verbosity reduction: 50 lines → 1 character (✓) on success path
   - ✅ Fail-fast diagnostics preserved on failure path: comprehensive troubleshooting output
   - ✅ Pattern: check variable count, grep for `^export VAR_NAME=` in state file, display failures with file context
   - **Coordinate Result**: State file verification went from 55 lines inline code → 14 lines using function (74% reduction)

**3. Selective State Persistence** (PROVEN in coordinate Phase 2 - 528ms saved, 88% of target):
   - ✅ Source guards in all 6 required libraries (unified-logger.sh was last, now complete)
   - ✅ CLAUDE_PROJECT_DIR already optimal via state-persistence.sh (600ms → 72ms baseline measurement)
   - ✅ GitHub Actions-style state file pattern: fixed semantic filename for cross-block persistence
   - ✅ Graceful degradation: fallback to stateless recalculation if state file missing
   - **Coordinate Result**: 528ms cumulative savings (88% of 600ms target achieved through source guards + existing state persistence)

**4. Conditional Library Loading** (PROVEN in coordinate Phase 4 - already optimal):
   - ✅ WORKFLOW_SCOPE-based library arrays (lines 134-147 in coordinate.md)
   - ✅ research-only: 6 libraries (40% reduction vs full-implementation's 10)
   - ✅ research-and-plan: 8 libraries
   - ✅ full-implementation: 10 libraries
   - ✅ debug-only: 8 libraries
   - ✅ Combined with Phase 2 source guards for optimal performance
   - **Coordinate Result**: Already implemented, no additional work needed (discovered in Phase 4)

**5. Documentation Separation** (Standard 14 - coordinate Phase 5 - partial achievement):
   - ✅ coordinate-command-guide.md created: 980 lines comprehensive documentation
   - ✅ Bidirectional cross-references validated
   - ✅ File size: 1,530 → 1,471 lines (59 lines, 3.9% reduction via streamlined comments)
   - ⚠️ Note: 1,471 lines exceeds 1,200 orchestrator threshold due to Standard 12 agent template requirements
   - **Recommendation**: Consider Standard 14 amendment for agent-heavy orchestrators (≥5 agent invocations) to allow 1,500-line threshold

### Command Priority Matrix

| Command | Priority | Reason | Estimated Effort |
|---------|----------|--------|------------------|
| /orchestrate | CRITICAL | 5,438 lines, missing all 6 fixes, in development status | 12-16 hours |
| /supervise | CRITICAL | Missing all 6 fixes, sequential only (no wave parallelism) | 8-10 hours |
| /implement | HIGH | Missing verification checkpoints, Phase 0 duplication | 6-8 hours |
| /plan | MEDIUM | Weak verification, missing fallback creation | 4-6 hours |
| /debug | MEDIUM | No verification checkpoints, no fallback mechanism | 4-6 hours |
| /document | LOW | No explicit verification, but lower agent delegation rate | 3-4 hours |
| /test | LOW | Minimal agent delegation, simpler architecture | 2-3 hours |

Total: 39-53 hours (matches 42-52 hour estimate)

## Implementation Phases

### Phase 1: Apply Subprocess Isolation Fixes to Orchestration Commands
dependencies: []

**Objective**: Apply coordinate's 6 subprocess isolation fixes to /orchestrate and /supervise, eliminating intermittent workflow failures due to state loss between bash blocks

**Complexity**: High

**Commands Affected**: /orchestrate (5,438 lines), /supervise (397 lines after refactor)

**Tasks**:
- [ ] **Fix 1: Replace $$-based filenames** in orchestrate.md and supervise.md
  - [ ] Search for all /tmp/*$$* patterns: `grep -n '\$\$' .claude/commands/{orchestrate,supervise}.md`
  - [ ] Replace with semantic fixed names: `${HOME}/.claude/tmp/orchestrate_workflow_desc.txt` (orchestrate.md)
  - [ ] Replace with semantic fixed names: `${HOME}/.claude/tmp/supervise_workflow_desc.txt` (supervise.md)
  - [ ] Update cleanup logic to use fixed filenames
- [ ] **Fix 2: Implement save-before-source pattern** for library variable scoping
  - [ ] Identify variables set before library sourcing: WORKFLOW_DESCRIPTION, WORKFLOW_SCOPE, WORKFLOW_ID
  - [ ] Add save pattern before library-sourcing.sh: `SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"`
  - [ ] Restore after sourcing: `WORKFLOW_DESCRIPTION="$SAVED_WORKFLOW_DESC"`
  - [ ] Apply to orchestrate.md lines 87-121 (current library sourcing section)
  - [ ] Apply to supervise.md lines 68-85 (current library sourcing section)
- [ ] **Fix 3: Remove EXIT traps from early blocks**
  - [ ] Audit trap statements: `grep -n 'trap.*EXIT' .claude/commands/{orchestrate,supervise}.md`
  - [ ] Move all cleanup logic to terminal completion bash block (last block only)
  - [ ] Document rationale: traps fire at block exit not workflow exit
- [ ] **Fix 4: Implement array metadata persistence**
  - [ ] Identify arrays needing cross-block persistence: REPORT_PATHS, SUBTOPIC_REPORT_PATHS
  - [ ] Add count persistence: `append_workflow_state "REPORT_PATHS_COUNT" "${#REPORT_PATHS[@]}"`
  - [ ] Add indexed persistence: `for ((i=0; i<${#REPORT_PATHS[@]}; i++)); do append_workflow_state "REPORT_PATH_${i}" "${REPORT_PATHS[$i]}"; done`
  - [ ] Implement reconstruction in load blocks: read count, loop to rebuild array
- [ ] **Fix 5: Add state transition persistence**
  - [ ] Add `append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"` after every `sm_transition()` call
  - [ ] Count sm_transition calls: `grep -c 'sm_transition' .claude/commands/{orchestrate,supervise}.md`
  - [ ] Verify state persistence covers all transitions (typically 8-12 transitions per orchestrator)
- [ ] **Fix 6: Replace nameref with indirect expansion**
  - [ ] Search for nameref usage: `grep -n 'local -n' .claude/commands/{orchestrate,supervise}.md`
  - [ ] Replace with indirect expansion: `${!var_name}` pattern for set -u compatibility
  - [ ] Add set +H at start of all bash blocks (history expansion prevention)
- [ ] **Create test suite** for subprocess isolation (model: .claude/tests/test_coordinate_integration.sh)
  - [ ] Test fixed filename persistence across blocks
  - [ ] Test save-before-source pattern preserves variables
  - [ ] Test array reconstruction accuracy
  - [ ] Test state transition persistence
  - [ ] Target: 100% pass rate before production deployment

**Testing**:
```bash
# Unit tests for each fix
cd /home/benjamin/.config/.claude/tests

# Test 1: Fixed filename persistence
bash test_orchestrate_fixed_filenames.sh
# Expected: File exists at fixed location after block 1, readable in block 2

# Test 2: Save-before-source pattern
bash test_orchestrate_variable_scoping.sh
# Expected: WORKFLOW_DESCRIPTION preserved after library sourcing

# Test 3: Array persistence
bash test_orchestrate_array_persistence.sh
# Expected: REPORT_PATHS array reconstructed correctly in block 2

# Test 4: State transition persistence
bash test_orchestrate_state_transitions.sh
# Expected: CURRENT_STATE matches expected state after each transition

# Integration test
bash test_orchestrate_integration.sh
# Expected: Full workflow completes without unbound variable errors

# Performance validation
bash test_orchestrate_performance.sh
# Expected: Overhead <5ms, state file growth <1KB
```

**Expected Duration**: 12-14 hours
- orchestrate.md: 8-10 hours (complex, 5,438 lines)
- supervise.md: 4-5 hours (simpler, 397 lines)

**Phase 1 Completion Requirements**:
- [ ] All 6 fixes applied to both commands
- [ ] Test suite created with 100% pass rate
- [ ] Performance overhead <5ms validated
- [ ] State file growth <1KB validated
- [ ] Git commit created: `fix(649): apply subprocess isolation fixes to orchestrate and supervise`
- [ ] Update this plan file with Phase 1 completion status

---

### Phase 2: Standardize Verification Checkpoint Pattern
dependencies: [1]

**Objective**: Apply coordinate's verification checkpoint pattern (Standard 0) to all 8 agent-delegating commands, achieving 100% artifact creation reliability

**Complexity**: Medium

**Commands Affected**: /plan, /document, /debug, /test, /orchestrate (strengthen existing), /supervise (strengthen existing), /research (strengthen existing), /implement (strengthen existing)

**Tasks**:
- [ ] **Audit existing verification patterns** in all 8 commands
  - [ ] Search for verification checkpoints: `grep -A 10 'MANDATORY VERIFICATION' .claude/commands/*.md`
  - [ ] Identify commands with strong implementation (research, coordinate): use as reference
  - [ ] Identify commands with weak/missing implementation (plan, document, debug, test): prioritize
  - [ ] Document findings in verification audit report
- [ ] **Extract verification pattern to shared library** (verification-helpers.sh already exists)
  - [ ] Review existing verification-helpers.sh: `cat .claude/lib/verification-helpers.sh`
  - [ ] Add consolidated function: `verify_file_created() { ... }`
  - [ ] Function signature: `verify_file_created "$EXPECTED_PATH" "$AGENT_NAME" "$FALLBACK_CONTENT_TEMPLATE"`
  - [ ] Implement 3-attempt retry with 500ms delay
  - [ ] Implement fallback creation from template or agent output
  - [ ] Implement re-verification after fallback
  - [ ] Implement fail-fast with diagnostic commands if re-verification fails
- [ ] **Apply verification pattern to /plan command**
  - [ ] Locate agent invocation: plan-architect agent (lines ~200-250)
  - [ ] Add pre-calculation: `EXPECTED_PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"`
  - [ ] Add mandatory verification checkpoint after agent completion
  - [ ] Implement fallback: create minimal plan from agent output if missing
  - [ ] Add re-verification and fail-fast
- [ ] **Apply verification pattern to /document command**
  - [ ] Locate agent invocations: documentation analysis agents
  - [ ] Add pre-calculation for all expected documentation files
  - [ ] Add mandatory verification checkpoint (currently missing entirely)
  - [ ] Implement fallback: create placeholder documentation with TODOs
- [ ] **Apply verification pattern to /debug command**
  - [ ] Locate agent invocations: debug-analyst agents (parallel hypothesis testing)
  - [ ] Add pre-calculation for diagnostic report paths
  - [ ] Add mandatory verification checkpoint (currently no fallback mechanism)
  - [ ] Implement fallback: create diagnostic report from agent output snippets
- [ ] **Apply verification pattern to /test command**
  - [ ] Audit agent delegation rate (should be minimal for test command)
  - [ ] If agents invoked, add verification checkpoints
  - [ ] If no agents, document rationale for skipping this command
- [ ] **Strengthen existing verification in /research**
  - [ ] Review current implementation (lines 345-438 in research.md)
  - [ ] Migrate to use verify_file_created() function from verification-helpers.sh
  - [ ] Reduce inline verification code by 90% (strong → consolidated)
- [ ] **Strengthen existing verification in /implement**
  - [ ] Review current implementation (scattered checkpoints)
  - [ ] Consolidate to use verify_file_created() function
  - [ ] Add fallback creation for implementation-researcher artifacts
- [ ] **Strengthen existing verification in /orchestrate and /supervise**
  - [ ] Consolidate scattered verification logic
  - [ ] Use verify_file_created() for all agent invocations (8-12 per orchestrator)
- [ ] **Create test suite** for verification pattern
  - [ ] Test 3-attempt retry mechanism
  - [ ] Test fallback creation triggers correctly
  - [ ] Test re-verification detects fallback creation
  - [ ] Test fail-fast with diagnostics when fallback fails
  - [ ] Target: 100% file creation reliability across all commands

**Testing**:
```bash
# Test verification pattern in isolation
cd /home/benjamin/.config/.claude/tests

# Test verification helper function
bash test_verification_helpers.sh
# Expected: verify_file_created() succeeds with real file
# Expected: verify_file_created() creates fallback for missing file
# Expected: verify_file_created() fails fast if fallback creation fails

# Test each command's verification integration
for cmd in plan document debug research implement orchestrate supervise; do
  bash test_${cmd}_verification.sh
  # Expected: 100% artifact creation rate (agent success OR fallback creation)
done

# Integration test: end-to-end workflow with intentional agent failures
bash test_verification_fallback_integration.sh
# Expected: Workflow continues after fallback creation
# Expected: Fallback files contain diagnostic information
```

**Expected Duration**: 8-10 hours
- verification-helpers.sh enhancement: 2 hours
- /plan, /document, /debug application: 3-4 hours (1 hour each)
- /research, /implement strengthening: 1-2 hours
- /orchestrate, /supervise strengthening: 2 hours
- Test suite creation: 2 hours

**Phase 2 Completion Requirements**:
- [ ] verify_file_created() function implemented in verification-helpers.sh
- [ ] All 8 commands use verification checkpoint pattern
- [ ] Test suite shows 100% artifact creation reliability
- [ ] 90% verbosity reduction achieved (inline code → function call)
- [ ] Git commit created: `feat(649): standardize verification checkpoint pattern across commands`
- [ ] Update this plan file with Phase 2 completion status

---

### Phase 3: Extract Common Phase 0 Initialization Library
dependencies: [1, 2]

**Objective**: Eliminate 15-50 lines of duplicate initialization code across 15 commands by extracting to centralized command-initialization.sh library (70% reduction target)

**Complexity**: Medium

**Commands Affected**: All 15 commands with Phase 0 initialization

**Tasks**:
- [ ] **Create command-initialization.sh library**
  - [ ] Location: /home/benjamin/.config/.claude/lib/command-initialization.sh
  - [ ] Function: `init_command_environment()` - CLAUDE_PROJECT_DIR detection, library sourcing, state restoration
  - [ ] Function: `parse_standard_arguments()` - --dry-run, --create-pr, --dashboard, --help flags
  - [ ] Function: `validate_command_prerequisites()` - Check required files, tools, configuration
  - [ ] Use coordinate's workflow-initialization.sh (346 lines) as model
  - [ ] Add error handling: fail-fast if prerequisites missing with diagnostic commands
- [ ] **Document library API** in command-initialization.sh header
  - [ ] Function signatures with parameter descriptions
  - [ ] Return codes and error handling
  - [ ] Usage examples for simple commands vs orchestrators
  - [ ] Integration with existing library-sourcing.sh pattern
- [ ] **Migrate 2 simple commands** as pilot (test, document)
  - [ ] Replace 15-30 lines of inline initialization with single function call
  - [ ] Verify behavior unchanged: run command test suite before/after
  - [ ] Document migration in commit message
- [ ] **Migrate orchestration commands** (orchestrate, supervise, coordinate)
  - [ ] Replace 30-50 lines of initialization with function call
  - [ ] Preserve orchestrator-specific logic (state machine init, workflow scope detection)
  - [ ] Verify 127+ state machine tests still pass
- [ ] **Migrate remaining commands** (implement, plan, research, debug, utilities)
  - [ ] Systematic migration: 1-2 commands per day to manage risk
  - [ ] Run command-specific tests after each migration
  - [ ] Document any edge cases or command-specific requirements
- [ ] **Deprecate inline initialization patterns**
  - [ ] Add deprecation notice to command development guide
  - [ ] Update _template-executable-command.md to use command-initialization.sh
  - [ ] Create validation script to detect inline initialization in new commands
- [ ] **Create test suite** for command-initialization.sh
  - [ ] Test CLAUDE_PROJECT_DIR detection in various scenarios (git repo, worktree, non-git)
  - [ ] Test argument parsing for all standard flags
  - [ ] Test prerequisite validation with missing dependencies
  - [ ] Test library sourcing with conditional workflow scopes

**Testing**:
```bash
# Test command-initialization.sh in isolation
cd /home/benjamin/.config/.claude/tests

# Test initialization function
bash test_command_initialization.sh
# Expected: CLAUDE_PROJECT_DIR set correctly
# Expected: Standard arguments parsed correctly
# Expected: Prerequisites validated with clear error messages

# Test each migrated command
for cmd in test document orchestrate supervise coordinate implement plan research debug; do
  # Before migration
  bash ${cmd}_original_test.sh > /tmp/${cmd}_before.log

  # Migrate command
  # ... apply migration ...

  # After migration
  bash ${cmd}_test.sh > /tmp/${cmd}_after.log

  # Compare behavior (should be identical)
  diff /tmp/${cmd}_before.log /tmp/${cmd}_after.log
  # Expected: No differences (behavior preserved)
done
```

**Expected Duration**: 10-12 hours
- Library creation: 3-4 hours
- Pilot migration (2 commands): 2 hours
- Orchestrator migration (3 commands): 3-4 hours
- Remaining commands (10 commands): 2-3 hours
- Test suite creation: 2 hours

**Phase 3 Completion Requirements**:
- [ ] command-initialization.sh library created and documented
- [ ] All 15 commands migrated to use centralized initialization
- [ ] 70% code reduction validated (15-50 lines → 5-15 lines per command)
- [ ] All command test suites passing (behavior unchanged)
- [ ] _template-executable-command.md updated
- [ ] Git commit created: `refactor(649): extract Phase 0 initialization to command-initialization.sh`
- [ ] Update this plan file with Phase 3 completion status

---

### Phase 4: Extract and Apply Array Persistence Library
dependencies: [1]

**Objective**: Extract coordinate's array persistence pattern to shared library and apply to 3+ commands needing array persistence (orchestrate, supervise, research)

**Complexity**: Low

**Commands Affected**: /coordinate (extract from), /orchestrate (apply to), /supervise (apply to), /research (apply to)

**Tasks**:
- [ ] **Create array-persistence.sh library**
  - [ ] Location: /home/benjamin/.config/.claude/lib/array-persistence.sh
  - [ ] Function: `save_array_to_state()` - Serialize array to workflow state file
  - [ ] Function: `restore_array_from_state()` - Deserialize array from workflow state file
  - [ ] Function: `validate_array_state()` - Verify array state complete (no missing indices)
  - [ ] Reference pattern: coordinate.md lines 175-187 (current coordinate-specific implementation)
  - [ ] Handle bash history expansion issues: use C-style for loops `for ((i=0; i<count; i++))`
  - [ ] Add error handling: detect missing indices, validate count accuracy
- [ ] **Document library API** in array-persistence.sh header
  - [ ] Function signatures with array name and workflow ID parameters
  - [ ] Serialization format: ARRAY_NAME_COUNT, ARRAY_NAME_0, ARRAY_NAME_1, ...
  - [ ] Usage examples for indexed arrays and associative arrays (if supported)
  - [ ] Limitations: bash-specific (no JSON alternative yet)
- [ ] **Migrate coordinate.md to use array-persistence.sh**
  - [ ] Replace inline array serialization (lines 175-187) with `save_array_to_state()`
  - [ ] Replace inline array reconstruction with `restore_array_from_state()`
  - [ ] Verify state machine tests still pass (127+ tests)
  - [ ] Measure code reduction: expect 20-30 lines → 5-10 lines
- [ ] **Apply to orchestrate.md**
  - [ ] Identify arrays needing persistence: REPORT_PATHS (research reports), PLAN_PATHS (multiple plans)
  - [ ] Add save_array_to_state() calls in initialization block
  - [ ] Add restore_array_from_state() calls in subsequent blocks
  - [ ] Test array reconstruction accuracy with 3-5 element arrays
- [ ] **Apply to supervise.md**
  - [ ] Identify arrays needing persistence: similar to orchestrate
  - [ ] Apply array persistence functions
  - [ ] Test sequential workflow with array state
- [ ] **Apply to research.md**
  - [ ] Identify arrays: SUBTOPIC_REPORT_PATHS (2-4 parallel research agents)
  - [ ] Apply array persistence functions
  - [ ] Test hierarchical research with array reconstruction
- [ ] **Create test suite** for array-persistence.sh
  - [ ] Test save and restore with various array sizes (0, 1, 10, 100 elements)
  - [ ] Test missing index detection
  - [ ] Test count mismatch detection
  - [ ] Test history expansion safety (no ! errors with set +H)

**Testing**:
```bash
# Test array-persistence.sh in isolation
cd /home/benjamin/.config/.claude/tests

# Test array persistence functions
bash test_array_persistence.sh
# Expected: save_array_to_state() serializes correctly
# Expected: restore_array_from_state() reconstructs accurately
# Expected: validate_array_state() detects missing indices

# Test each command's array persistence
for cmd in coordinate orchestrate supervise research; do
  bash test_${cmd}_array_persistence.sh
  # Expected: Arrays persist across bash blocks
  # Expected: Array size matches original
  # Expected: Array elements match original values
done

# Performance test
bash test_array_persistence_performance.sh
# Expected: Overhead <2ms for arrays up to 10 elements
# Expected: State file growth ~100 bytes per array element
```

**Expected Duration**: 6-8 hours
- Library creation: 2-3 hours
- coordinate.md migration: 1 hour
- orchestrate/supervise/research application: 2-3 hours
- Test suite creation: 1-2 hours

**Phase 4 Completion Requirements**:
- [ ] array-persistence.sh library created and documented
- [ ] coordinate.md migrated to use library (20-30 line reduction)
- [ ] 3+ commands (orchestrate, supervise, research) use library
- [ ] Test suite shows 100% array reconstruction accuracy
- [ ] Performance validated: <2ms overhead, ~100 bytes per element
- [ ] Git commit created: `refactor(649): extract array persistence to shared library`
- [ ] Update this plan file with Phase 4 completion status

---

### Phase 5: Apply Selective State Persistence Pattern
dependencies: [1, 4]

**Objective**: Apply coordinate's selective state persistence pattern (67% improvement) to orchestrate, supervise, and implement commands for expensive operations

**Complexity**: Medium

**Commands Affected**: /orchestrate, /supervise, /implement

**Tasks**:
- [ ] **Audit commands for expensive operations** (>30ms recalculation cost)
  - [ ] Instrument orchestrate.md: add `date +%s%N` timestamps around key operations
  - [ ] Instrument supervise.md: measure operation times
  - [ ] Instrument implement.md: identify expensive complexity calculations
  - [ ] Collect baseline metrics: CLAUDE_PROJECT_DIR detection, git operations, file scans, complexity analysis
  - [ ] Document findings: operation name, current time, recalculation frequency, persistence benefit
- [ ] **Apply state persistence to CLAUDE_PROJECT_DIR detection**
  - [ ] Add to orchestrate.md: `append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"` in block 1
  - [ ] Add to supervise.md: same pattern
  - [ ] Add to implement.md: same pattern
  - [ ] Validate 67% improvement: 50ms git rev-parse → 15ms file read
- [ ] **Apply state persistence to workflow scope detection**
  - [ ] Add to orchestrate.md: `append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"`
  - [ ] Add to supervise.md: same pattern
  - [ ] Benefit: avoid re-parsing workflow description in every block
- [ ] **Apply state persistence to complexity scores**
  - [ ] Add to implement.md: `append_workflow_state "PHASE_COMPLEXITY_SCORE" "$COMPLEXITY_SCORE"`
  - [ ] Benefit: avoid re-calculating complexity for phases (hybrid threshold + agent evaluation)
  - [ ] Particularly valuable for agent-based evaluation (30-120s per calculation)
- [ ] **Apply state persistence to topic paths**
  - [ ] Add to all 3 commands: `append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"`
  - [ ] Benefit: avoid topic number recalculation and sanitization
- [ ] **Implement graceful degradation fallback**
  - [ ] For each persisted item, add fallback recalculation if load fails
  - [ ] Pattern: `CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"`
  - [ ] Log when fallback triggered: useful for debugging state file corruption
- [ ] **Create performance benchmark suite**
  - [ ] Measure before/after for each operation
  - [ ] Target: 67% improvement for CLAUDE_PROJECT_DIR (proven in coordinate)
  - [ ] Target: 50-80% improvement for workflow scope (avoid re-parsing)
  - [ ] Target: 90-99% improvement for complexity scores (avoid agent re-evaluation)

**Testing**:
```bash
# Performance benchmarking
cd /home/benjamin/.config/.claude/tests

# Baseline measurements (before state persistence)
bash benchmark_orchestrate_operations.sh --baseline
# Record: CLAUDE_PROJECT_DIR detection time, workflow scope detection time, etc.

# Apply state persistence
# ... implement changes ...

# Performance measurements (after state persistence)
bash benchmark_orchestrate_operations.sh --after-persistence
# Expected: 67% improvement for CLAUDE_PROJECT_DIR (50ms → 15ms)
# Expected: 50-80% improvement for workflow scope
# Expected: State file size increase <1KB

# Graceful degradation test
bash test_state_persistence_fallback.sh
# Delete state file mid-workflow
# Expected: Fallback recalculation succeeds
# Expected: Warning logged about fallback usage

# Integration test with all 3 commands
for cmd in orchestrate supervise implement; do
  bash test_${cmd}_state_persistence.sh
  # Expected: Performance improvement validated
  # Expected: All tests passing
done
```

**Expected Duration**: 6-8 hours
- Operation audit and instrumentation: 2 hours
- State persistence application to 3 commands: 3-4 hours
- Graceful degradation implementation: 1 hour
- Performance benchmarking: 2 hours

**Phase 5 Completion Requirements**:
- [ ] Expensive operations identified and documented
- [ ] State persistence applied to 3 commands
- [ ] 67% improvement validated for CLAUDE_PROJECT_DIR detection
- [ ] Graceful degradation fallback implemented and tested
- [ ] Performance benchmark suite shows cumulative improvement ≥50%
- [ ] Git commit created: `perf(649): apply selective state persistence to orchestrate, supervise, implement`
- [ ] Update this plan file with Phase 5 completion status

---

### Phase 6: Apply Standard 14 Documentation Separation to Orchestrate
dependencies: [1, 2, 3, 5]

**Objective**: Apply coordinate's Standard 14 pattern to orchestrate command, reducing from 5,438 lines to <1,500 lines (72% reduction) via documentation extraction

**Complexity**: High

**Commands Affected**: /orchestrate (primary), /supervise (secondary if time permits)

**Tasks**:
- [ ] **Analyze orchestrate.md content distribution**
  - [ ] Count bash blocks: `grep -c '```bash' .claude/commands/orchestrate.md`
  - [ ] Count documentation sections: headings, examples, troubleshooting prose
  - [ ] Estimate execution-critical vs documentation: aim for 30% executable, 70% documentation split
  - [ ] Document findings: which sections move to guide, which stay in executable
- [ ] **Create orchestrate-command-guide.md structure** (model: coordinate-command-guide.md)
  - [ ] Location: /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md
  - [ ] Section 1: Overview (500-800 lines) - Architecture, workflow states, scope detection
  - [ ] Section 2: Usage Examples (600-1,000 lines) - Complete workflows with expected outputs
  - [ ] Section 3: State Handlers (400-600 lines) - Detailed phase documentation
  - [ ] Section 4: Advanced Topics (400-800 lines) - Parallel execution, PR automation, dashboard
  - [ ] Section 5: Troubleshooting (500-1,000 lines) - Common failures, diagnostics, recovery
  - [ ] Section 6: Integration Patterns (300-500 lines) - Library dependencies, agent coordination
  - [ ] Section 7: Performance Metrics (200-400 lines) - Context reduction, execution time
  - [ ] Section 8: References (100-200 lines) - Links to standards, libraries, specs
  - [ ] Target: 3,000-5,000 lines comprehensive guide
- [ ] **Extract documentation from orchestrate.md to guide**
  - [ ] Extract architecture explanations (WHY): state machine rationale, scope detection logic, etc.
  - [ ] Extract usage examples: complete workflow invocations, error scenarios, edge cases
  - [ ] Extract troubleshooting content: failure modes with symptoms, diagnostic commands, recovery procedures
  - [ ] Extract performance documentation: context reduction metrics, execution time benchmarks
  - [ ] Extract integration patterns: library usage, agent coordination patterns
  - [ ] Preserve cross-references: link from executable to guide sections
  - [ ] Target extraction: 3,500-4,000 lines moved from orchestrate.md to guide
- [ ] **Reduce orchestrate.md to execution-critical only**
  - [ ] Keep all bash blocks (execution logic)
  - [ ] Keep phase markers and structural comments
  - [ ] Keep WHAT comments (minimal inline: "Initialize state machine", "Invoke research agents")
  - [ ] Remove WHY comments ("Why state machine: explicit states prevent implicit phase bugs...")
  - [ ] Add cross-reference comments: "See orchestrate-command-guide.md Section 2 for usage examples"
  - [ ] Target size: <1,500 lines (72% reduction from 5,438)
- [ ] **Create bidirectional cross-references**
  - [ ] orchestrate.md → guide: "See [Troubleshooting Guide](../docs/guides/orchestrate-command-guide.md#troubleshooting) for diagnostics"
  - [ ] guide → orchestrate.md: "Executable command file: [orchestrate.md](../../commands/orchestrate.md)"
  - [ ] Add table of contents to guide with deep links
  - [ ] Add "Quick Reference" section in guide linking to common operations in executable
- [ ] **Validate separation with Standard 14 script**
  - [ ] Run: `.claude/tests/validate_executable_doc_separation.sh .claude/commands/orchestrate.md`
  - [ ] Check: orchestrate.md ≤1,500 lines (within threshold)
  - [ ] Check: orchestrate-command-guide.md ≥500 lines (comprehensive documentation)
  - [ ] Check: bidirectional cross-references present
  - [ ] Check: no duplicate content between executable and guide
- [ ] **Apply to supervise.md if time permits** (secondary priority)
  - [ ] Current size: 397 lines (already compliant with <400 agent threshold)
  - [ ] Evaluate if guide needed: less complex than orchestrate
  - [ ] If created: follow same extraction pattern

**Testing**:
```bash
# Validate Standard 14 compliance
cd /home/benjamin/.config/.claude/tests

# Run validation script
bash validate_executable_doc_separation.sh .claude/commands/orchestrate.md
# Expected: File size ≤1,500 lines
# Expected: Guide exists at .claude/docs/guides/orchestrate-command-guide.md
# Expected: Guide ≥500 lines
# Expected: Cross-references bidirectional

# Context reduction validation
bash test_orchestrate_context_reduction.sh
# Before: ~2,500 tokens for orchestrate.md (5,438 lines)
# After: ~1,000 tokens for orchestrate.md (≤1,500 lines)
# Expected: 60% context reduction

# Behavioral equivalence test
bash test_orchestrate_behavior.sh --before-separation > /tmp/orchestrate_before.log
# ... apply separation ...
bash test_orchestrate_behavior.sh --after-separation > /tmp/orchestrate_after.log
diff /tmp/orchestrate_before.log /tmp/orchestrate_after.log
# Expected: No differences (behavior preserved)

# Guide quality validation
bash validate_guide_completeness.sh .claude/docs/guides/orchestrate-command-guide.md
# Expected: All sections present
# Expected: Code examples formatted correctly
# Expected: Cross-references valid (no broken links)
```

**Expected Duration**: 10-12 hours
- Content analysis: 2 hours
- Guide structure creation: 2 hours
- Documentation extraction: 4-5 hours
- Executable reduction: 1-2 hours
- Cross-reference creation: 1 hour
- Validation and testing: 2 hours

**Phase 6 Completion Requirements**:
- [ ] orchestrate-command-guide.md created (3,000-5,000 lines)
- [ ] orchestrate.md reduced to ≤1,500 lines (72% reduction validated)
- [ ] Bidirectional cross-references complete
- [ ] Standard 14 validation script passes
- [ ] 60% context reduction achieved (2,500 → 1,000 tokens)
- [ ] Behavioral equivalence test passes (no regressions)
- [ ] Git commit created: `docs(649): apply Standard 14 separation to orchestrate command`
- [ ] Update this plan file with Phase 6 completion status

---

### Phase 7: Create Bash Block Execution Model Documentation and Final Validation
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Create authoritative bash block execution model documentation and validate all improvements with comprehensive testing

**Complexity**: Medium

**Tasks**:
- [ ] **Create bash-block-execution-model.md documentation**
  - [ ] Location: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md
  - [ ] Section 1: Technical Background - Subprocess vs subshell, Claude Code Bash tool behavior
  - [ ] Section 2: Validation Test - Demonstrate PID changes, export failures, function loss
  - [ ] Section 3: What Persists - Files, file-based state only
  - [ ] Section 4: What Doesn't Persist - Exports, environment variables, functions, traps (unless re-sourced)
  - [ ] Section 5: Recommended Patterns - 6 fixes from coordinate (fixed filenames, save-before-source, etc.)
  - [ ] Section 6: Anti-Patterns - $$-based filenames, assuming exports work, EXIT traps in early blocks, assuming functions persist
  - [ ] Section 7: Examples - Coordinate implementation, orchestrate/supervise application
  - [ ] Foundation: coordinate's .claude/docs/architecture/coordinate-state-management.md as starting point
  - [ ] Target: 800-1,200 lines comprehensive reference
- [ ] **Link documentation from multiple guides**
  - [ ] Add to orchestration-best-practices.md: "See [Bash Block Execution Model](../concepts/bash-block-execution-model.md)"
  - [ ] Add to command-development-guide.md: prerequisite reading for orchestration commands
  - [ ] Add to state-machine-orchestrator-development.md: integration with state persistence
  - [ ] Add to .claude/commands/README.md: link from "Creating Orchestration Commands" section
- [ ] **Run comprehensive test suite** (all commands)
  - [ ] Run all 127+ state machine tests: `cd .claude/tests && bash test_state_machine.sh`
  - [ ] Run orchestrate integration tests: `bash test_orchestrate_integration.sh`
  - [ ] Run supervise integration tests: `bash test_supervise_integration.sh`
  - [ ] Run implement integration tests: `bash test_implement_integration.sh`
  - [ ] Run plan/debug/document tests: verify verification checkpoints working
  - [ ] Run research tests: verify array persistence working
  - [ ] Target: 100% pass rate across all test suites (zero regressions)
- [ ] **Validate performance improvements**
  - [ ] CLAUDE_PROJECT_DIR caching: validate 67% improvement (50ms → 15ms)
  - [ ] Workflow scope caching: validate 50-80% improvement
  - [ ] State file overhead: validate <5ms per operation, <2KB total state
  - [ ] Context reduction: validate 40-60% for orchestrate (Standard 14 separation)
  - [ ] Verification checkpoint overhead: validate <100ms per checkpoint (3 retries × 500ms max)
- [ ] **Validate reliability improvements**
  - [ ] Zero unbound variable errors across all commands
  - [ ] 100% artifact creation rate (agent success OR fallback creation)
  - [ ] Zero "command not found" errors (library re-sourcing working)
  - [ ] Zero test failures or regressions
- [ ] **Create migration summary report**
  - [ ] Document all 7 phases completed
  - [ ] List affected commands with before/after metrics (file size, performance, reliability)
  - [ ] Document performance improvements: cumulative savings across all commands
  - [ ] Document reliability improvements: zero P0 bugs system-wide
  - [ ] Document code reduction: centralized libraries vs inline duplication
  - [ ] Create reusable pattern catalog: other commands can adopt improvements
- [ ] **Update CLAUDE.md project configuration**
  - [ ] Update command_commands section: reflect production-ready status of orchestrate/supervise
  - [ ] Update development_workflow section: reference bash block execution model
  - [ ] Update code_standards section: reference command-initialization.sh, array-persistence.sh
  - [ ] Update testing_protocols section: reference verification checkpoint tests

**Testing**:
```bash
# Comprehensive test suite execution
cd /home/benjamin/.config/.claude/tests

# Run all test files
for test_file in test_*.sh; do
  echo "Running $test_file..."
  bash "$test_file" || echo "FAILURE: $test_file"
done

# Expected output:
# Running test_state_machine.sh... (127+ tests PASS)
# Running test_orchestrate_integration.sh... (PASS)
# Running test_supervise_integration.sh... (PASS)
# Running test_implement_integration.sh... (PASS)
# Running test_plan_verification.sh... (PASS)
# Running test_debug_verification.sh... (PASS)
# Running test_document_verification.sh... (PASS)
# Running test_research_array_persistence.sh... (PASS)
# ... (all tests PASS)

# Performance validation script
bash validate_performance_improvements.sh
# Expected: 67% improvement for CLAUDE_PROJECT_DIR caching
# Expected: 50-80% improvement for workflow scope caching
# Expected: <5ms state persistence overhead
# Expected: 40-60% context reduction for orchestrate

# Reliability validation script
bash validate_reliability_improvements.sh
# Expected: Zero unbound variable errors
# Expected: 100% artifact creation rate
# Expected: Zero "command not found" errors

# Generate summary report
bash generate_migration_summary.sh > /home/benjamin/.config/.claude/specs/649_*/reports/004_migration_summary.md
```

**Expected Duration**: 8-10 hours
- Bash block execution model documentation: 4-5 hours
- Cross-reference linking: 1 hour
- Comprehensive test suite execution: 2 hours
- Performance/reliability validation: 1-2 hours
- Migration summary report: 1-2 hours

**Phase 7 Completion Requirements**:
- [ ] bash-block-execution-model.md created (800-1,200 lines)
- [ ] Documentation linked from 4+ guides
- [ ] All 127+ tests passing (100% pass rate)
- [ ] Performance improvements validated (67% CLAUDE_PROJECT_DIR, 50-80% workflow scope)
- [ ] Reliability improvements validated (zero P0 bugs)
- [ ] Migration summary report created
- [ ] CLAUDE.md updated with new references
- [ ] Git commit created: `docs(649): create bash block execution model documentation and complete validation`
- [ ] Update this plan file with Phase 7 completion status

---

## Testing Strategy

### Unit Testing

**Library Testing**:
- `test_command_initialization.sh` - Phase 0 library functions
- `test_array_persistence.sh` - Array serialization/deserialization accuracy
- `test_verification_helpers.sh` - Verification checkpoint pattern (retry, fallback, fail-fast)
- `test_state_persistence.sh` - Selective state persistence with graceful degradation

**Command Testing**:
- `test_orchestrate_*.sh` - Subprocess isolation fixes, verification, state persistence, behavior equivalence
- `test_supervise_*.sh` - Similar to orchestrate
- `test_implement_*.sh` - Verification checkpoints, Phase 0 centralization
- `test_plan_*.sh`, `test_debug_*.sh`, `test_document_*.sh` - Verification pattern application

**Target**: 50+ new unit tests, 100% pass rate

### Integration Testing

**End-to-End Workflows**:
- Research-only workflow (test Phase 0 centralization, array persistence)
- Research-and-plan workflow (test verification checkpoints)
- Full-implementation workflow (test state persistence, subprocess isolation)
- Error scenarios (test verification fallback creation)

**Performance Benchmarking**:
- CLAUDE_PROJECT_DIR caching: 67% improvement target (50ms → 15ms)
- Workflow scope caching: 50-80% improvement target
- State persistence overhead: <5ms per operation target
- Context reduction: 40-60% for orchestrate target

**Target**: 10+ integration tests covering all 7 commands

### Regression Testing

**Existing Test Suites**:
- All 127+ state machine tests must continue passing
- Command-specific test suites for orchestrate, supervise, implement, plan, research, debug, document
- Behavioral equivalence: before/after comparison for all modified commands

**Target**: Zero regressions, 100% pass rate maintained

### Validation Testing

**Standard Compliance**:
- `.claude/tests/validate_executable_doc_separation.sh` - Standard 14 (orchestrate ≤1,500 lines)
- Verification checkpoint presence in all 8 agent-delegating commands
- Phase 0 centralization in all 15 commands

**Performance Validation**:
- 67% improvement for CLAUDE_PROJECT_DIR (proven in coordinate, replicate in orchestrate/supervise/implement)
- Cumulative performance improvement ≥50% across all commands

**Reliability Validation**:
- Zero unbound variable errors
- 100% artifact creation rate
- Zero "command not found" errors

**Target**: All validation criteria met

## Documentation Requirements

### New Documentation

1. **bash-block-execution-model.md** (Phase 7)
   - Location: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md
   - Content: Technical background, validation test, recommended patterns, anti-patterns, examples
   - Target: 800-1,200 lines comprehensive reference
   - Links: From 4+ guides (orchestration-best-practices.md, command-development-guide.md, etc.)

2. **orchestrate-command-guide.md** (Phase 6)
   - Location: /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md
   - Content: 8 sections (Overview, Usage Examples, State Handlers, Advanced Topics, Troubleshooting, Integration, Performance, References)
   - Target: 3,000-5,000 lines
   - Cross-references: Bidirectional with orchestrate.md

3. **command-initialization.sh API documentation** (Phase 3)
   - Location: Header of /home/benjamin/.config/.claude/lib/command-initialization.sh
   - Content: Function signatures, return codes, usage examples, integration patterns

4. **array-persistence.sh API documentation** (Phase 4)
   - Location: Header of /home/benjamin/.config/.claude/lib/array-persistence.sh
   - Content: Function signatures, serialization format, usage examples, limitations

5. **verification-helpers.sh API documentation** (Phase 2)
   - Location: Header of /home/benjamin/.config/.claude/lib/verification-helpers.sh (update existing)
   - Content: verify_file_created() function signature, retry mechanism, fallback pattern

### Updated Documentation

1. **CLAUDE.md** (Phase 7)
   - Update command_commands section: production-ready status
   - Update development_workflow section: bash block execution model reference
   - Update code_standards section: new library references
   - Update testing_protocols section: verification checkpoint tests

2. **_template-executable-command.md** (Phase 3)
   - Update Phase 0 initialization pattern: use command-initialization.sh
   - Add verification checkpoint template (Standard 0)

3. **Command Development Guide** (Phase 7)
   - Add bash block execution model as prerequisite reading
   - Add verification checkpoint pattern section
   - Add Phase 0 centralization section

4. **Orchestration Best Practices Guide** (Phase 7)
   - Link to bash block execution model
   - Add subprocess isolation best practices
   - Add state persistence decision matrix

## Dependencies

### External Dependencies
- Bash 4.0+ (for associative arrays in array-persistence.sh)
- Git (for CLAUDE_PROJECT_DIR detection, existing dependency)
- Core utilities: grep, sed, awk (existing dependencies)

### Internal Dependencies
- All .claude/lib/ libraries (42 modules)
- State machine library: workflow-state-machine.sh (8 states, transition validation)
- State persistence library: state-persistence.sh (GitHub Actions pattern)
- Library sourcing: library-sourcing.sh (deduplication)
- Error handling: error-handling.sh (fail-fast classification)
- Unified logger: unified-logger.sh (progress emission)

### Phase Dependencies
- Phase 1 (subprocess isolation fixes) must complete before Phases 4-5 (state persistence, array persistence)
- Phase 2 (verification checkpoints) independent of other phases
- Phase 3 (Phase 0 centralization) independent but benefits from Phase 1-2 completion
- Phase 6 (Standard 14 separation) requires Phases 1-3-5 complete (orchestrate must be stable before documentation extraction)
- Phase 7 (documentation and validation) requires all prior phases complete

### Risk Mitigation
- Sequential phase execution (no parallel attempts) reduces integration risk
- Pilot migrations (2 simple commands in Phase 3) validate patterns before full rollout
- Comprehensive testing after each phase prevents regression accumulation
- Behavioral equivalence tests ensure command functionality preserved

## Notes

**Complexity Calculation**:
- Base (enhance existing commands): 7
- Tasks (84 tasks): 84/2 = 42
- Files (20 command files + 5 new libraries + 10 library updates + 5 test files): 40 × 3 = 120
- Integrations (42 library modules, 8 architectural standards): 50 × 0.5 = 25
- **Total**: 7 + 42 + 120 + 25 = 194.0 (originally) → adjusted to 168.0 based on research complexity

**Migration Strategy**:
- **Risk-Layered Approach**: Critical fixes first (Phase 1-2), then optimization (Phase 3-5), finally documentation (Phase 6-7)
- **Pilot Migrations**: Start with 2 simple commands (test, document) in Phase 3 to validate patterns
- **Incremental Rollout**: 1-2 commands per day to manage risk and validate testing
- **Behavioral Preservation**: Before/after comparison for all modified commands

**Performance Targets** (Based on Coordinate Actual Results):
- ✅ State persistence + source guards: 528ms saved (coordinate actual: 600ms baseline → 72ms optimized)
- ✅ Verification verbosity: 98% output reduction (coordinate actual: 50 lines → 1 character per checkpoint)
- ✅ Conditional library loading: 40% fewer libraries for simple scopes (coordinate actual: 6 vs 10 libraries)
- ⚠️ Context reduction: Limited by Standard 12 (coordinate actual: 3.9% vs 40% target due to agent templates)
- ✅ State file overhead: <1KB (coordinate actual: 1,628 bytes for full state)
- 🎯 **Replication Goal**: Match coordinate's 528ms improvement in orchestrate/supervise (currently 0ms baseline)

**Success Metrics**:
- Reliability: Zero P0 bugs system-wide (unbound variables, missing artifacts, command not found)
- Performance: ≥50% cumulative improvement across state persistence operations
- Code Reduction: 70% Phase 0 duplication elimination, 72% orchestrate size reduction
- Test Coverage: 100% pass rate maintained, 50+ new unit tests created
- Documentation: 1 authoritative reference (bash block execution model) + 1 comprehensive guide (orchestrate)

**Reusability**:
- All patterns extracted to shared libraries (command-initialization.sh, array-persistence.sh, verification-helpers.sh)
- Bash block execution model documentation enables future command development without repeating subprocess isolation bugs
- Standard 14 separation pattern (orchestrate) provides template for other complex commands (supervise, implement)
- Verification checkpoint pattern (Standard 0) established as non-negotiable requirement for all agent-delegating commands

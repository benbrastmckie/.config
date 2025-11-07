# /coordinate Subprocess Isolation Fix Implementation Plan

## Metadata
- **Date**: 2025-11-07
- **Feature**: Systematic library sourcing fix for /coordinate command subprocess isolation
- **Scope**: Fix all 19 bash blocks in /coordinate to properly source libraries
- **Estimated Phases**: 5
- **Estimated Hours**: 3.5
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/coordinate Bash Block Analysis](/home/benjamin/.config/.claude/specs/605_claude_specs_coordinate_outputmd_well_existing/reports/001_coordinate_bash_blocks_analysis.md)
  - [Library Sourcing Infrastructure](/home/benjamin/.config/.claude/specs/605_claude_specs_coordinate_outputmd_well_existing/reports/002_library_sourcing_infrastructure.md)
  - [Orchestration Commands Subprocess Patterns](/home/benjamin/.config/.claude/specs/605_claude_specs_coordinate_outputmd_well_existing/reports/003_orchestration_commands_subprocess_patterns.md)
  - [Original Fix Plan](/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md)

## Overview

The /coordinate command currently fails at Phase 1 execution due to subprocess isolation - library functions sourced in Phase 0 are not available in subsequent bash blocks because each Bash tool invocation runs in a fresh subprocess. This plan implements a systematic fix by creating a reusable initialization script (`coordinate-subprocess-init.sh`) and updating all 19 bash blocks to source it.

**Root Cause**: Bash Tool subprocess isolation - each bash block runs in a separate subprocess that does not inherit functions from previous blocks.

**Current State**: Only 1 out of 19 blocks (5%) properly sources libraries before using functions.

**Solution**: Create reusable `coordinate-subprocess-init.sh` library and source it at the beginning of every bash block (except Phase 0 Step 1).

## Research Summary

Based on comprehensive analysis from 4 research reports:

**Key Findings**:
- 18 out of 19 bash blocks will fail due to missing library sourcing
- First failure point: Phase 1 Research Start (line 344: `should_run_phase: command not found`)
- Functions are NOT inherited between Bash tool invocations (subprocess isolation)
- Exported variables ARE inherited but many blocks re-initialize them instead of using exports
- Other orchestration commands (/orchestrate, /implement, /supervise) use different patterns that avoid this issue

**Recommended Approach** (from library infrastructure analysis):
- Create `coordinate-subprocess-init.sh` consolidating 80+ lines of sourcing logic into reusable script
- Reduces each block from 80+ lines to 3 lines (95% code reduction)
- Workflow-scope-aware library loading (research-only: 6 libs, research-and-plan: 8 libs, full-implementation: 11 libs)
- Includes inline helper functions (`display_brief_summary()`, `transition_to_phase()`)

**Alternative Patterns Evaluated**:
- Pattern A (Simple Independent Blocks): Not applicable - /coordinate uses 10+ library functions per block
- Pattern B (Single-Block-with-Loop): Not applicable - /coordinate's 19-block architecture is intentional
- Pattern C (Reusable Init Script): ✅ RECOMMENDED - best fit for /coordinate's design

## Success Criteria

- [ ] coordinate-subprocess-init.sh created and tested independently
- [ ] All 19 bash blocks updated with proper library sourcing
- [ ] Phase 1 Research executes without "command not found" errors
- [ ] Complete research-and-plan workflow succeeds end-to-end
- [ ] All workflow scopes work (research-only, research-and-plan, full-implementation, debug-only)
- [ ] No regressions in checkpoint/resume functionality
- [ ] Test suite passes with new subprocess initialization pattern
- [ ] Documentation updated with subprocess isolation pattern guidance

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ /coordinate command (19 bash blocks)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 0 Step 1: Initial Setup                             │
│  ├─ Sources libraries comprehensively                      │
│  └─ Exports variables (WORKFLOW_SCOPE, TOPIC_PATH, etc.)   │
│                                                             │
│  Phase 0 Step 2-3, Phase 1-6 (18 blocks):                  │
│  ├─ OLD: Functions unavailable ❌                          │
│  └─ NEW: Source coordinate-subprocess-init.sh ✅           │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ coordinate-subprocess-init.sh                               │
├─────────────────────────────────────────────────────────────┤
│ 1. Detect CLAUDE_PROJECT_DIR (Standard 13)                  │
│ 2. Detect WORKFLOW_SCOPE (from export or default)          │
│ 3. Source library-sourcing.sh                               │
│ 4. Determine required libraries by scope:                   │
│    - research-only: 6 libraries                             │
│    - research-and-plan: 8 libraries                         │
│    - full-implementation: 11 libraries                      │
│    - debug-only: 9 libraries                                │
│ 5. Call source_required_libraries()                         │
│ 6. Define helper functions:                                 │
│    - display_brief_summary()                                │
│    - transition_to_phase()                                  │
└─────────────────────────────────────────────────────────────┘
```

### Library Dependencies by Workflow Scope

**research-only** (6 libraries):
- workflow-detection.sh
- workflow-scope-detection.sh
- unified-logger.sh
- unified-location-detection.sh
- overview-synthesis.sh
- verification-helpers.sh

**research-and-plan** (8 libraries, adds):
- metadata-extraction.sh
- checkpoint-utils.sh

**full-implementation** (11 libraries, adds):
- dependency-analyzer.sh
- context-pruning.sh
- error-handling.sh

**debug-only** (9 libraries, same as research-and-plan + error-handling)

### Critical Functions Required

| Function | Library | Used In Blocks | Failure Impact |
|----------|---------|----------------|----------------|
| `should_run_phase()` | workflow-detection.sh | 4 phase start blocks | CRITICAL - Phase execution control |
| `emit_progress()` | unified-logger.sh | 13 blocks | HIGH - Progress tracking broken |
| `verify_file_created()` | verification-helpers.sh | 7 verification blocks | HIGH - Verification failures |
| `save_checkpoint()` | checkpoint-utils.sh | 5 blocks | MEDIUM - Resume capability lost |
| `display_brief_summary()` | Inline helper | 4 blocks | LOW - User experience |

## Implementation Phases

### Phase 1: Create coordinate-subprocess-init.sh Library
dependencies: []

**Objective**: Create reusable initialization script that sources all required libraries and defines helper functions based on workflow scope.

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/lib/coordinate-subprocess-init.sh` with complete implementation (file: /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh)
  - Include Standard 13 CLAUDE_PROJECT_DIR detection
  - Include workflow scope detection (use exported value or default to research-and-plan)
  - Include library-sourcing.sh sourcing with fail-fast error handling
  - Include case statement for scope-based library selection
  - Include source_required_libraries() call with error handling
  - Include display_brief_summary() function definition (from coordinate.md:150-174)
  - Include transition_to_phase() function definition (from coordinate.md:177-205)
  - Include DEBUG mode function verification (optional, DEBUG_COORDINATE_INIT=1)
- [ ] Add comprehensive header comments explaining purpose, usage, workflow scopes, error handling, and performance
- [ ] Ensure script uses `return 1` instead of `exit 1` (must be sourceable)
- [ ] Verify file is executable and properly formatted

**Testing**:
```bash
# Test 1: Verify file exists
test -f /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
echo "✓ Script file exists"

# Test 2: Test each workflow scope sources successfully
for scope in research-only research-and-plan full-implementation debug-only; do
  (WORKFLOW_SCOPE=$scope source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh) || exit 1
  echo "✓ $scope scope loaded"
done

# Test 3: Verify critical functions available after sourcing
(
  WORKFLOW_SCOPE=research-and-plan
  source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh

  for func in should_run_phase emit_progress verify_file_created save_checkpoint display_brief_summary transition_to_phase; do
    if command -v "$func" >/dev/null 2>&1; then
      echo "✓ $func available"
    else
      echo "✗ $func MISSING" >&2
      exit 1
    fi
  done
)

# Test 4: Verify library count matches expected for each scope
(
  WORKFLOW_SCOPE=full-implementation
  source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
  [ "${#REQUIRED_LIBS[@]}" -eq 11 ] && echo "✓ full-implementation loaded 11 libraries" || exit 1
)
```

**Expected Duration**: 30 minutes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(605): complete Phase 1 - Create coordinate-subprocess-init.sh`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Fix Critical Blocks (Research + Planning Workflows)
dependencies: [1]

**Objective**: Fix the 3 most critical bash blocks to enable research-and-plan workflows (minimal viable fix).

**Complexity**: Medium

**Tasks**:
- [ ] Fix Block 5: Phase 1 Research Start (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 341-381)
  - Add sourcing at line 342 (immediately after bash block start, before line 344)
  - Pattern: `source "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/lib/coordinate-subprocess-init.sh"`
  - Remove redundant CLAUDE_PROJECT_DIR detection (lines 371-375)
  - Remove redundant library-sourcing.sh sourcing (lines 377-378)
  - Remove redundant `if command -v emit_progress` check (line 347-349) - function always available after sourcing
  - Verify `should_run_phase`, `display_brief_summary`, and `emit_progress` calls work after sourcing
- [ ] Fix Block 6: Phase 1 Research Verification (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 406-467)
  - Add sourcing at line 407 (before first `emit_progress` call at line 409)
  - Remove redundant CLAUDE_PROJECT_DIR detection (lines 412-416)
  - Remove partial verification-helpers.sh sourcing (lines 418-423) - now included in init script
  - Verify `emit_progress`, `verify_file_created`, `save_checkpoint`, `store_phase_metadata` calls work
- [ ] Fix Block 8: Phase 2 Planning Start (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 530-565)
  - Add sourcing at line 531 (before `should_run_phase` call at line 533)
  - Verify `should_run_phase`, `display_brief_summary`, `emit_progress` calls work

**Testing**:
```bash
# Test 1: Phase 1 Research block syntax check
bash -n /home/benjamin/.config/.claude/commands/coordinate.md
# (Note: Will fail since .md not executable, but validates bash blocks individually)

# Test 2: Integration test - Run research-only workflow
# Expected: Phase 1 completes without "command not found" errors
# /coordinate "research bash best practices"

# Test 3: Integration test - Run research-and-plan workflow
# Expected: Phases 1-2 complete successfully
# /coordinate "research and plan a simple test feature"
```

**Expected Duration**: 45 minutes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(605): complete Phase 2 - Fix critical Phase 1-2 blocks`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Fix Remaining High-Priority Blocks (Complete Research-and-Plan)
dependencies: [2]

**Objective**: Fix additional blocks needed for complete research-and-plan workflow functionality.

**Complexity**: Medium

**Tasks**:
- [ ] Fix Block 9: Phase 2 Planning Verification (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 591-654)
  - Add sourcing at line 592
  - Verify all functions available: `verify_file_created`, `emit_progress`, `save_checkpoint`, `store_phase_metadata`, `apply_pruning_policy`
- [ ] Fix Block 7: Phase 1 Overview Synthesis (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 492-523)
  - Add sourcing at line 493
  - Verify functions: `verify_file_created`, `emit_progress`, `should_synthesize_overview`, `calculate_overview_path`
  - Note: This block is conditional (only runs for research-only workflows with ≥2 reports)
- [ ] Fix Block 4: Verification Helpers Loading (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 317-333)
  - Add sourcing at line 318 (or consider removing this block entirely - now redundant)
  - Simplify to just use init script like other blocks
- [ ] Fix Block 2: Phase 0 Step 2 Function Verification (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 115-225)
  - Add sourcing at line 118 (before verification loop at line 130)
  - Keep inline function definitions (display_brief_summary, transition_to_phase) for now
  - Note: These functions are now also in init script, creating intentional redundancy

**Testing**:
```bash
# Test 1: Complete research-and-plan workflow
# /coordinate "research git best practices and plan implementation"
# Expected: Phases 0-2 complete successfully, plan file created

# Test 2: Research-only workflow with overview synthesis
# /coordinate "research lua patterns, error handling, and testing"
# Expected: 3 reports created, overview synthesized

# Test 3: Verify checkpoint/resume functionality
# Start workflow, interrupt after Phase 1, resume
# Expected: Resumes at Phase 2 without re-running Phase 1
```

**Expected Duration**: 45 minutes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(605): complete Phase 3 - Fix high-priority blocks for research-and-plan`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Fix All Remaining Blocks (Full Workflow Support)
dependencies: [3]

**Objective**: Fix remaining 11 bash blocks to enable full-implementation and conditional workflows (debug, documentation).

**Complexity**: Medium

**Tasks**:
- [ ] Fix Block 10: Phase 3 Implementation Start (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 660-704)
  - Add sourcing at line 661
  - Verify functions: `should_run_phase`, `emit_progress`, `analyze_dependencies`
- [ ] Fix Block 11: Phase 3 Implementation Verification (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 736-784)
  - Add sourcing at line 737
  - Verify functions: `emit_progress`, `save_checkpoint`, `store_phase_metadata`, `apply_pruning_policy`
- [ ] Fix Block 12: Phase 4 Testing Start (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 792-803)
  - Add sourcing at line 793
  - Verify functions: `should_run_phase`, `emit_progress`
- [ ] Fix Block 13: Phase 4 Testing Verification (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 830-868)
  - Add sourcing at line 831
  - Verify functions: `emit_progress`, `save_checkpoint`, `store_phase_metadata`
- [ ] Fix Block 14: Phase 5 Debug Start (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 876-890)
  - Add sourcing at line 877
  - Verify functions: `emit_progress`
- [ ] Fix Block 15: Phase 5 Debug Iteration 1 (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 913-925)
  - Add sourcing at line 914
  - Verify functions: `verify_file_created`
- [ ] Fix Block 16: Phase 5 Debug Iteration 2 (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 947-953)
  - Add sourcing at line 948 (only if functions used - review shows none)
  - Optional: May not need sourcing if block only parses agent output
- [ ] Fix Block 17: Phase 5 Debug Complete (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 977-1008)
  - Add sourcing at line 978
  - Verify functions: `emit_progress`, `store_phase_metadata`
- [ ] Fix Block 18: Phase 6 Documentation Start (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 1016-1028)
  - Add sourcing at line 1017
  - Verify functions: `emit_progress`, `display_brief_summary`
- [ ] Fix Block 19: Phase 6 Documentation Verification (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 1055-1080)
  - Add sourcing at line 1056
  - Verify functions: `verify_file_created`, `emit_progress`, `store_phase_metadata`, `prune_workflow_metadata`, `display_brief_summary`
- [ ] Optimize Block 3: Phase 0 Step 3 Path Initialization (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 227-309)
  - Consider simplification: Remove redundant library sourcing (lines 240-260)
  - Option A: Keep as-is (defensive programming)
  - Option B: Add init script sourcing, remove redundant sourcing
  - Recommendation: Option A for now, revisit in future refactor

**Testing**:
```bash
# Test 1: Full-implementation workflow
# /coordinate "research, plan, and implement a simple test utility"
# Expected: Phases 0-4 complete successfully

# Test 2: Debug workflow (force test failure)
# /coordinate "implement feature with intentional bug"
# Expected: Phase 5 triggers, debug reports created

# Test 3: Documentation workflow
# /coordinate "document recent changes to library system"
# Expected: Phase 6 completes, documentation updated

# Test 4: All workflow scopes
for scope in research-only research-and-plan full-implementation debug-only; do
  echo "Testing: $scope"
  # Run appropriate test for each scope
done
```

**Expected Duration**: 60 minutes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(605): complete Phase 4 - Fix all remaining blocks for full workflow support`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Testing, Documentation, and Validation
dependencies: [4]

**Objective**: Comprehensive testing, documentation updates, and final validation of subprocess isolation fix.

**Complexity**: Low

**Tasks**:
- [ ] Create comprehensive test suite (file: /home/benjamin/.config/.claude/tests/test_coordinate_subprocess_isolation.sh)
  - Test 1: Verify coordinate-subprocess-init.sh sources successfully for all scopes
  - Test 2: Verify all critical functions available after sourcing
  - Test 3: Test library count matches expected for each scope (6, 8, 11, 9)
  - Test 4: Verify helper functions (display_brief_summary, transition_to_phase) execute correctly
  - Test 5: Integration test for each workflow scope
  - Test 6: Verify no "command not found" errors in any phase
  - Test 7: Checkpoint/resume functionality regression test
  - Add to `.claude/tests/run_all_tests.sh` with high priority
- [ ] Update coordinate command guide (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md)
  - Add section: "Subprocess Isolation Pattern"
  - Explain why every bash block needs library sourcing
  - Document coordinate-subprocess-init.sh usage
  - Add troubleshooting section for subprocess isolation issues
  - Include before/after code examples
- [ ] Update command development guide (file: /home/benjamin/.config/.claude/docs/guides/command-development-guide.md)
  - Add section: "Subprocess Isolation Patterns for Multi-Bash-Block Commands"
  - Document three patterns: A (Simple Independent), B (Single-Loop), C (Reusable Init Script)
  - Explain when to use each pattern
  - Include decision matrix and examples from /orchestrate, /implement, /coordinate
  - Add guidance: "Create per-command init scripts when Pattern C applies"
- [ ] Create architectural decision document (file: /home/benjamin/.config/.claude/docs/architecture/subprocess-isolation-decisions.md)
  - Document analysis of orchestration command patterns
  - Rationale for command-specific vs. generalized solutions
  - Decision: coordinate-subprocess-init.sh is command-specific (not generalized)
  - Future guidance for other multi-bash-block commands
- [ ] Run full validation suite
  - Execute all workflow scopes end-to-end
  - Verify no "command not found" errors
  - Verify checkpoint/resume functionality intact
  - Verify all exported variables properly inherited
  - Performance regression check (should be minimal overhead <100ms per block)
- [ ] Update plan with completion status and metrics
  - Total blocks fixed: 19
  - Code reduction: 80+ lines → 3 lines per block (95% reduction)
  - Token savings: ~73,150 tokens across all blocks
  - Test coverage: ≥80% for subprocess initialization pattern

**Testing**:
```bash
# Run comprehensive test suite
/home/benjamin/.config/.claude/tests/test_coordinate_subprocess_isolation.sh

# Run all tests including new tests
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Manual validation of each workflow scope
/coordinate "research bash best practices"  # research-only
/coordinate "research and plan git workflow"  # research-and-plan
/coordinate "research, plan, and implement test utility"  # full-implementation

# Performance check
time (WORKFLOW_SCOPE=full-implementation source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh)
# Expected: <100ms for 11 libraries
```

**Expected Duration**: 60 minutes

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(605): complete Phase 5 - Testing, documentation, and validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Test coordinate-subprocess-init.sh independently for all 4 workflow scopes
- Verify function availability after sourcing for each scope
- Verify library counts match expected (6, 8, 11, 9 libraries)
- Test helper functions (display_brief_summary, transition_to_phase) execute correctly

### Integration Testing
- Test each workflow scope end-to-end (research-only, research-and-plan, full-implementation, debug-only)
- Verify no "command not found" errors at any phase
- Verify checkpoint/resume functionality works correctly
- Verify exported variables properly inherited across bash blocks

### Regression Testing
- Verify Phase 0 functionality unchanged
- Verify all existing /coordinate features work (parallel research, wave-based implementation, etc.)
- Verify performance overhead is minimal (<100ms per bash block)
- Run existing .claude/tests/ suite to ensure no regressions

### Validation Testing
- Manual workflow execution for each scope
- Error message clarity verification (fail-fast with actionable diagnostics)
- Documentation accuracy verification (examples work as documented)

## Documentation Requirements

### Files to Update
1. **coordinate-command-guide.md** - Add subprocess isolation pattern section
2. **command-development-guide.md** - Add multi-bash-block patterns section
3. **subprocess-isolation-decisions.md** (new) - Document architectural decisions

### Documentation Sections
- Subprocess isolation root cause explanation
- coordinate-subprocess-init.sh usage and rationale
- Before/after code examples
- Troubleshooting guide for "command not found" errors
- Pattern comparison (Simple Independent, Single-Loop, Reusable Init Script)
- Decision matrix for choosing subprocess isolation patterns

## Dependencies

### Library Dependencies
- `.claude/lib/library-sourcing.sh` - Core library sourcing utility
- `.claude/lib/workflow-detection.sh` - Workflow control functions
- `.claude/lib/unified-logger.sh` - Progress logging
- `.claude/lib/checkpoint-utils.sh` - Checkpoint operations
- `.claude/lib/verification-helpers.sh` - File verification
- `.claude/lib/context-pruning.sh` - Context management
- `.claude/lib/workflow-initialization.sh` - Path initialization
- `.claude/lib/overview-synthesis.sh` - Overview synthesis decisions
- `.claude/lib/dependency-analyzer.sh` - Wave-based execution analysis

### External Dependencies
- Git (for Standard 13 CLAUDE_PROJECT_DIR detection)
- Bash 4.0+ (for associative arrays in libraries)
- Standard POSIX utilities (grep, wc, test)

### Standards Compliance
- **Standard 13**: CLAUDE_PROJECT_DIR detection via `git rev-parse --show-toplevel`
- **Standard 14**: Executable/documentation separation (init script is executable, guides are documentation)
- **Verification and Fallback Pattern**: Fail-fast error handling with detailed diagnostics
- **Behavioral Injection Pattern**: Helper functions defined inline, not delegated to agents

## Risk Assessment

### High Risk
- Breaking existing /coordinate workflows during fix application
- **Mitigation**: Incremental fixes (Phase 2 critical blocks first), test after each phase, version control

### Medium Risk
- Performance degradation from repetitive library sourcing
- **Mitigation**: Library sourcing is cached by bash, overhead measured at <100ms per block

### Low Risk
- Inconsistent variable values between blocks (some re-initialize instead of using exports)
- **Mitigation**: init script uses `${VARIABLE:-default}` pattern, preserves exports where available

### Negligible Risk
- Function name conflicts between libraries
- **Mitigation**: All libraries use descriptive, unique function names

## Performance Considerations

### Token Reduction
- Per bash block: 80+ lines → 3 lines = ~3,850 tokens saved
- Across all 19 blocks: ~73,150 tokens saved (95% reduction in sourcing overhead)
- Context window efficiency: Significant improvement in multi-phase workflows

### Execution Performance
- Library sourcing overhead: ~50-100ms for full-implementation scope (11 libraries)
- Minimal impact: <2 seconds total overhead across all 19 blocks
- Deduplication: library-sourcing.sh automatically removes duplicates

### Caching Behavior
- Bash caches sourced scripts within subprocess lifetime
- No re-parsing overhead for repeated function calls within same block
- Fresh sourcing required for each new bash block (inherent subprocess isolation)

## Future Enhancements

### Short-Term (Post-Implementation)
1. Audit /supervise for similar subprocess isolation issues (latent risk identified in research)
2. Consider extracting redundant inline functions from Block 2 to init script
3. Optimize Block 3 to use init script instead of redundant sourcing

### Medium-Term
1. Create automated validation in command testing suite for subprocess isolation
2. Add defensive verification checkpoints to other multi-bash-block commands
3. Document pattern in command development guide for future command authors

### Long-Term
1. Evaluate generalized command-subprocess-init.sh if multiple commands need pattern
2. Consider templating system for command-specific init scripts
3. Systematic prevention across all commands via automated testing

## References

### Research Reports
- [Bash Block Analysis Report](/home/benjamin/.config/.claude/specs/605_claude_specs_coordinate_outputmd_well_existing/reports/001_coordinate_bash_blocks_analysis.md) - Complete inventory of 19 blocks, function usage, failure analysis
- [Library Sourcing Infrastructure Report](/home/benjamin/.config/.claude/specs/605_claude_specs_coordinate_outputmd_well_existing/reports/002_library_sourcing_infrastructure.md) - Complete coordinate-subprocess-init.sh specification
- [Orchestration Commands Subprocess Patterns Report](/home/benjamin/.config/.claude/specs/605_claude_specs_coordinate_outputmd_well_existing/reports/003_orchestration_commands_subprocess_patterns.md) - Pattern comparison, generalization analysis
- [Original Fix Plan](/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md) - Initial analysis and fix approach

### Source Files
- `/home/benjamin/.config/.claude/commands/coordinate.md` (1,095 lines, 19 bash blocks)
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` - Core library sourcing utilities
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` - Workflow control functions
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Progress logging functions

### Documentation
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` - Command usage guide (to be updated)
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` - Command development patterns (to be updated)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Standards 13, 14
- `/home/benjamin/.config/CLAUDE.md` - Project standards and testing protocols

## Metrics and Success Tracking

### Code Metrics
- **Bash blocks updated**: 0/19 (target: 19/19)
- **Code reduction**: 0% (target: 95% - from 80+ lines to 3 lines per block)
- **Token savings**: 0 tokens (target: ~73,150 tokens)
- **Test coverage**: 0% (target: ≥80%)

### Functional Metrics
- **Workflow scopes working**: 0/4 (research-only, research-and-plan, full-implementation, debug-only)
- **"command not found" errors**: 18 blocks failing (target: 0 blocks failing)
- **Checkpoint/resume functionality**: Not tested (target: Working)

### Quality Metrics
- **Test suite passing**: Not created (target: 100% pass rate)
- **Documentation complete**: 0/3 files (target: 3/3 files updated)
- **Performance overhead**: Not measured (target: <100ms per block)

## Notes

This plan follows the research-backed approach from 4 comprehensive research reports analyzing 19 bash blocks, 9+ library files, and 3 orchestration command patterns. The solution is intentionally command-specific (not generalized) based on finding that /coordinate's multi-bash-block architecture is unique among orchestration commands.

The fix maintains backward compatibility (exported variables preserved), fail-fast error handling (library sourcing failures exit immediately with diagnostics), and minimal performance overhead (~50-100ms per block).

# /coordinate Command: Bash Block Library Sourcing Analysis

## Metadata
- **Date**: 2025-11-07
- **Agent**: research-specialist
- **Topic**: Analyze /coordinate command bash blocks and identify library sourcing fixes
- **Report Type**: codebase analysis
- **Related Files**:
  - `.claude/commands/coordinate.md`
  - `.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md`
  - `.claude/specs/coordinate_output.md`

## Executive Summary

The /coordinate command contains 19 bash blocks across 7 phases, with only 1 block (5%) properly sourcing libraries before use. This causes critical failures due to Bash tool subprocess isolation - each bash block runs in a fresh subprocess that does not inherit functions from previous blocks. The fix plan document correctly identifies the root cause and proposes creating a reusable `coordinate-subprocess-init.sh` library, which would reduce each block's sourcing boilerplate from 80+ lines to just 2 lines.

**Critical Finding**: 18 out of 19 bash blocks will fail when executed due to missing library sourcing, with Phase 1 Research being the first failure point (line 344: `should_run_phase: command not found`).

## Findings

### 1. Complete Bash Block Inventory (19 Blocks Total)

#### Phase 0: Initialization (3 blocks)

**Block 1: Phase 0 Step 1 - Library Loading**
- **Lines**: 21-113
- **Library Sourcing**: ✅ COMPLETE (properly sources all libraries)
- **Functions Used**: None (only defines and exports)
- **Status**: ✅ WORKS CORRECTLY
- **Sourcing Pattern**:
  ```bash
  source "${LIB_DIR}/workflow-scope-detection.sh"
  source "$LIB_DIR/library-sourcing.sh"
  source_required_libraries "${REQUIRED_LIBS[@]}"
  ```
- **Note**: This is the ONLY block that sources libraries correctly before using functions

**Block 2: Phase 0 Step 2 - Function Verification**
- **Lines**: 115-225
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `should_run_phase` (line 130, verification only)
  - `emit_progress` (line 130, verification only)
  - `save_checkpoint` (line 130, verification only)
  - `restore_checkpoint` (line 130, verification only)
  - `display_brief_summary` (line 150, defined inline)
  - `transition_to_phase` (line 177, defined inline)
  - `restore_checkpoint` (line 209, actual use)
  - `emit_progress` (line 217, actual use)
- **Status**: ⚠️ PARTIAL FAILURE - verification loop reports all functions missing, but continues execution
- **Critical Issue**: Attempts to verify functions exist without sourcing libraries that define them
- **Inline Function Definitions**: Defines `display_brief_summary()` and `transition_to_phase()` but these are lost in subsequent subprocesses

**Block 3: Phase 0 Step 3 - Path Initialization**
- **Lines**: 227-309
- **Library Sourcing**: ✅ RE-SOURCES (redundant but functional)
- **Functions Used**:
  - `detect_workflow_scope` (line 253)
  - `initialize_workflow_paths` (line 288)
  - `emit_progress` (line 303, 304)
  - `reconstruct_report_paths_array` (line 300)
- **Status**: ✅ WORKS (but redundant sourcing)
- **Sourcing Pattern**:
  ```bash
  source "${LIB_DIR}/workflow-scope-detection.sh"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh"
  ```
- **Note**: Re-initializes variables instead of using exported values from Step 1

#### Verification Helpers Block (1 block)

**Block 4: Verification Helpers Loading**
- **Lines**: 317-333
- **Library Sourcing**: ✅ SOURCES verification-helpers.sh
- **Functions Used**: None in this block (loads for use by later blocks)
- **Status**: ✅ WORKS
- **Critical Issue**: Later blocks don't inherit this sourcing due to subprocess isolation

#### Phase 1: Research (3 blocks)

**Block 5: Research Start - Phase Execution Check**
- **Lines**: 341-381
- **Library Sourcing**: ⚠️ TOO LATE (line 377-378, AFTER function calls)
- **Functions Used BEFORE sourcing**:
  - `should_run_phase` (line 344) ❌ NOT AVAILABLE
  - `display_brief_summary` (line 346) ❌ NOT AVAILABLE
  - `emit_progress` (line 351, 380) ❌ NOT AVAILABLE
- **Functions Used AFTER sourcing**:
  - `source_required_libraries` (line 378) ✅ Available
- **Status**: ❌ FIRST CRITICAL FAILURE - "should_run_phase: command not found"
- **Error Location**: Line 344 (confirmed in console output)

**Block 6: Research Verification**
- **Lines**: 406-467
- **Library Sourcing**: ⚠️ PARTIAL (only sources verification-helpers.sh at lines 418-423)
- **Functions Used**:
  - `emit_progress` (line 409, 444, 445, 451, 503, 521) ❌ NOT AVAILABLE
  - `verify_file_created` (line 433) ⚠️ Available after line 418
  - `save_checkpoint` (line 514) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 518) ❌ NOT AVAILABLE
  - `should_synthesize_overview` (line 455) ❌ NOT AVAILABLE
  - `calculate_overview_path` (line 456) ❌ NOT AVAILABLE
  - `get_synthesis_skip_reason` (line 497) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS - multiple missing functions
- **Note**: Only sources verification-helpers.sh, missing unified-logger, checkpoint-utils, overview-synthesis

**Block 7: Overview Synthesis (conditional)**
- **Lines**: 492-523
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `verify_file_created` (line 495) ❌ NOT AVAILABLE
  - `emit_progress` (line 503, 521) ❌ NOT AVAILABLE
  - `save_checkpoint` (line 514) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 518) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS (if reached)
- **Note**: This block is within the same bash invocation as Block 6 (lines 492-523 are part of 406-523)

#### Phase 2: Planning (2 blocks)

**Block 8: Planning Start**
- **Lines**: 530-565
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `should_run_phase` (line 533) ❌ NOT AVAILABLE
  - `display_brief_summary` (line 535) ❌ NOT AVAILABLE
  - `emit_progress` (line 540) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

**Block 9: Planning Verification**
- **Lines**: 591-654
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `verify_file_created` (line 596) ❌ NOT AVAILABLE
  - `emit_progress` (line 604, 616, 634) ❌ NOT AVAILABLE
  - `save_checkpoint` (line 628) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 631) ❌ NOT AVAILABLE
  - `apply_pruning_policy` (line 632) ❌ NOT AVAILABLE
  - `should_run_phase` (line 637) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

#### Phase 3: Wave-Based Implementation (2 blocks)

**Block 10: Implementation Start**
- **Lines**: 660-704
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `should_run_phase` (line 663) ❌ NOT AVAILABLE
  - `emit_progress` (line 669) ❌ NOT AVAILABLE
  - `analyze_dependencies` (line 675) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

**Block 11: Implementation Verification**
- **Lines**: 736-784
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `emit_progress` (line 752, 783) ❌ NOT AVAILABLE
  - `save_checkpoint` (line 777) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 779) ❌ NOT AVAILABLE
  - `apply_pruning_policy` (line 780) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

#### Phase 4: Testing (2 blocks)

**Block 12: Testing Start**
- **Lines**: 792-803
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `should_run_phase` (line 795) ❌ NOT AVAILABLE
  - `emit_progress` (line 801) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

**Block 13: Testing Verification**
- **Lines**: 830-868
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `emit_progress` (line 838, 849, 867) ❌ NOT AVAILABLE
  - `save_checkpoint` (line 863) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 865) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

#### Phase 5: Debug - Conditional (4 blocks)

**Block 14: Debug Start**
- **Lines**: 876-890
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `emit_progress` (line 880, 889) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

**Block 15: Debug Iteration - Verification**
- **Lines**: 913-925
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `verify_file_created` (line 918) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

**Block 16: Debug - Apply Fixes**
- **Lines**: 947-953
- **Library Sourcing**: ❌ NONE
- **Functions Used**: None (parses agent output only)
- **Status**: ⚠️ WORKS (no function calls)

**Block 17: Debug - Completion**
- **Lines**: 977-1008
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `emit_progress` (line 1002, 1007) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 1005) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

#### Phase 6: Documentation - Conditional (2 blocks)

**Block 18: Documentation Start**
- **Lines**: 1016-1028
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `emit_progress` (line 1020) ❌ NOT AVAILABLE
  - `display_brief_summary` (line 1025) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

**Block 19: Documentation Verification**
- **Lines**: 1055-1080
- **Library Sourcing**: ❌ NONE
- **Functions Used**:
  - `verify_file_created` (line 1060) ❌ NOT AVAILABLE
  - `emit_progress` (line 1063, 1072) ❌ NOT AVAILABLE
  - `store_phase_metadata` (line 1070) ❌ NOT AVAILABLE
  - `prune_workflow_metadata` (line 1071) ❌ NOT AVAILABLE
  - `display_brief_summary` (line 1078) ❌ NOT AVAILABLE
- **Status**: ❌ FAILS

### 2. Library Sourcing Status Summary

| Status | Count | Percentage | Blocks |
|--------|-------|------------|--------|
| ✅ Complete sourcing | 1 | 5% | Block 1 (Phase 0 Step 1) |
| ✅ Redundant but functional | 1 | 5% | Block 3 (Phase 0 Step 3) |
| ⚠️ Partial sourcing | 2 | 11% | Block 2 (verification only), Block 6 (partial) |
| ⚠️ Late sourcing (after use) | 1 | 5% | Block 5 (Phase 1 start) |
| ❌ No sourcing | 14 | 74% | Blocks 4, 7-19 |
| **TOTAL** | **19** | **100%** | |

### 3. Function Dependency Analysis

#### Critical Functions Required Across All Phases

**Workflow Control Functions** (workflow-detection.sh)
- `should_run_phase()` - Required by: Blocks 5, 8, 10, 12 (all phase start blocks)
- Missing in: 4/4 blocks (100% failure rate)

**Progress Logging Functions** (unified-logger.sh)
- `emit_progress()` - Required by: Blocks 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 17, 18, 19 (13 blocks)
- Missing in: 13/13 blocks (100% failure rate)

**Checkpoint Functions** (checkpoint-utils.sh)
- `save_checkpoint()` - Required by: Blocks 6, 7, 9, 11, 13 (5 blocks)
- `restore_checkpoint()` - Required by: Block 2 (1 block)
- `store_phase_metadata()` - Required by: Blocks 6, 7, 9, 11, 13, 17, 19 (7 blocks)
- Missing in: All blocks except Block 2 (which calls but doesn't source)

**Verification Functions** (verification-helpers.sh)
- `verify_file_created()` - Required by: Blocks 6, 7, 9, 11, 13, 15, 19 (7 blocks)
- Missing in: 6/7 blocks (Block 6 sources it, but too late for other blocks)

**Context Management Functions** (context-pruning.sh)
- `apply_pruning_policy()` - Required by: Blocks 9, 11 (2 blocks)
- `prune_workflow_metadata()` - Required by: Block 19 (1 block)
- Missing in: 3/3 blocks (100% failure rate)

**Workflow Initialization Functions** (workflow-initialization.sh)
- `initialize_workflow_paths()` - Required by: Block 3 (1 block)
- `reconstruct_report_paths_array()` - Required by: Block 3 (1 block)
- Properly sourced in Block 3

**Overview Synthesis Functions** (overview-synthesis.sh)
- `should_synthesize_overview()` - Required by: Block 6 (1 block)
- `calculate_overview_path()` - Required by: Block 6 (1 block)
- `get_synthesis_skip_reason()` - Required by: Block 6 (1 block)
- Missing in: 1/1 blocks (100% failure rate)

**Dependency Analysis Functions** (dependency-analyzer.sh)
- `analyze_dependencies()` - Required by: Block 10 (1 block)
- Missing in: 1/1 blocks (100% failure rate)

**Helper Functions** (defined inline in Block 2, need to be available everywhere)
- `display_brief_summary()` - Required by: Blocks 5, 8, 18, 19 (4 blocks)
- `transition_to_phase()` - Not currently used (defined but never called)
- Missing in: 4/4 blocks (100% failure rate)

### 4. Variable Inheritance Analysis

**Exported Variables from Phase 0 Step 1** (Block 1, lines 27-81):
```bash
export CLAUDE_PROJECT_DIR
export LIB_DIR
export WORKFLOW_DESCRIPTION
export WORKFLOW_SCOPE
export PHASES_TO_EXECUTE
export SKIP_PHASES
```

**Variable Re-initialization Issues**:
- Block 3 (lines 237-268) re-detects `WORKFLOW_SCOPE` instead of using exported value
- Block 3 (lines 260-266) re-calculates `PHASES_TO_EXECUTE` and `SKIP_PHASES`
- Many blocks re-detect `CLAUDE_PROJECT_DIR` instead of using exported value

**Recommendation**: Use exported variables via `${VARIABLE:-default}` pattern instead of re-calculating

### 5. Subprocess Isolation Root Cause

**How Bash Tool Works**:
Each `USE the Bash tool:` invocation creates a **fresh subprocess**:

```
┌─────────────────────────────────────┐
│ Block 1: Phase 0 Step 1             │
│ - Sources libraries                 │
│ - Defines functions in memory       │
│ - Exports variables                 │
│ - Subprocess EXITS                  │
└─────────────────────────────────────┘
              ↓
   Functions LOST (bash doesn't export functions to child processes)
   Variables LOST (except those explicitly exported)
              ↓
┌─────────────────────────────────────┐
│ Block 2: Phase 0 Step 2             │
│ - Fresh subprocess (clean slate)    │
│ - Exported vars available           │
│ - Functions NOT available           │
│ - Result: "command not found"       │
└─────────────────────────────────────┘
```

**What Gets Inherited**:
| Item | Inherited? | Reason |
|------|-----------|--------|
| Exported variables | ✅ YES | Shell passes to child processes |
| Non-exported variables | ❌ NO | Lost when subprocess exits |
| Functions | ❌ NO | Never inherited, even with `export -f` (not POSIX) |
| Sourced library state | ❌ NO | Must re-source in each subprocess |

### 6. Priority Fix List by Workflow Scope Impact

**CRITICAL (Blocks all workflows)**:
1. Block 5 (Phase 1 Research Start, line 341) - FIRST FAILURE POINT
   - Impact: No workflow can proceed past initialization
   - Functions needed: `should_run_phase`, `display_brief_summary`, `emit_progress`

2. Block 6 (Phase 1 Research Verification, line 406) - SECOND FAILURE POINT
   - Impact: Research phase cannot complete
   - Functions needed: All logging, checkpoint, verification functions

**HIGH (Blocks research-and-plan workflows)**:
3. Block 8 (Phase 2 Planning Start, line 530)
   - Impact: research-and-plan workflows fail
   - Functions needed: `should_run_phase`, `emit_progress`

4. Block 9 (Phase 2 Planning Verification, line 591)
   - Impact: Planning phase cannot complete
   - Functions needed: All verification, checkpoint, pruning functions

**MEDIUM (Blocks full-implementation workflows)**:
5. Block 10 (Phase 3 Implementation Start, line 660)
6. Block 11 (Phase 3 Implementation Verification, line 736)
7. Block 12 (Phase 4 Testing Start, line 792)
8. Block 13 (Phase 4 Testing Verification, line 830)

**LOW (Blocks conditional workflows)**:
9. Blocks 14-17 (Phase 5 Debug, lines 876-1008) - Only runs if tests fail
10. Blocks 18-19 (Phase 6 Documentation, lines 1016-1080) - Only runs after implementation

### 7. Verification of Fix Plan Recommendations

The fix plan document (`coordinate_subprocess_isolation_fix_plan.md`) proposes creating a reusable `coordinate-subprocess-init.sh` library. This analysis **CONFIRMS** the fix plan is correct:

**Fix Plan Strengths**:
✅ Correctly identifies subprocess isolation as root cause
✅ Correctly identifies all 19 bash blocks
✅ Correctly identifies Block 5 (Phase 1 Research) as first failure point
✅ Proposes optimal solution: reusable sourcing script
✅ Provides complete code for `coordinate-subprocess-init.sh`
✅ Documents proper testing approach

**Fix Plan Completeness**:
✅ Includes all required libraries for each workflow scope
✅ Includes inline function definitions (`display_brief_summary`, `transition_to_phase`)
✅ Provides before/after code examples
✅ Prioritizes fixes by workflow scope impact
✅ Documents success criteria

**Analysis Additions Beyond Fix Plan**:
- This report provides line-by-line function usage analysis for each block
- This report identifies which specific functions are called before/after sourcing
- This report quantifies failure rates (18/19 blocks = 95% failure rate)
- This report confirms variable re-initialization issues in Block 3

## Recommendations

### Immediate Actions (Fix Critical Path)

1. **Create `coordinate-subprocess-init.sh`** (HIGHEST PRIORITY)
   - Location: `.claude/lib/coordinate-subprocess-init.sh`
   - Content: Use code from fix plan document (lines 384-486)
   - Test: Verify function availability after sourcing
   - Estimated effort: 30 minutes

2. **Fix Block 5 (Phase 1 Research Start)** (CRITICAL)
   - Add sourcing at line 342 (before line 344)
   - Remove redundant sourcing at lines 371-378
   - Test: Run research-only workflow
   - Estimated effort: 10 minutes

3. **Fix Block 6 (Phase 1 Research Verification)** (CRITICAL)
   - Add sourcing at line 407
   - Remove partial sourcing at lines 418-423
   - Test: Verify research phase completes
   - Estimated effort: 10 minutes

4. **Fix Blocks 8-9 (Phase 2 Planning)** (HIGH)
   - Add sourcing at lines 531, 592
   - Test: Run research-and-plan workflow
   - Estimated effort: 15 minutes

### Systematic Completion (Fix All Blocks)

5. **Fix Blocks 10-13 (Phases 3-4)** (MEDIUM)
   - Add sourcing at lines 661, 737, 793, 831
   - Test: Run full-implementation workflow
   - Estimated effort: 20 minutes

6. **Fix Blocks 14-19 (Phases 5-6)** (LOW)
   - Add sourcing at lines 877, 914, 978, 1017, 1056
   - Test: Run debug and documentation workflows
   - Estimated effort: 20 minutes

### Code Quality Improvements

7. **Optimize Block 3 Variable Initialization**
   - Use exported variables instead of re-calculating
   - Pattern: `WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-research-and-plan}"`
   - Reduces redundant computation
   - Estimated effort: 10 minutes

8. **Optimize Block 2 Function Definitions**
   - Move `display_brief_summary()` and `transition_to_phase()` to `coordinate-subprocess-init.sh`
   - Eliminates inline definitions in Block 2
   - Estimated effort: 15 minutes

9. **Update Block 4 (Verification Helpers)**
   - Remove standalone verification-helpers sourcing
   - Now included in `coordinate-subprocess-init.sh`
   - Estimated effort: 5 minutes

### Documentation and Testing

10. **Update Command Guide**
    - Document subprocess isolation pattern
    - Explain why every block needs sourcing
    - Add troubleshooting section
    - File: `.claude/docs/guides/coordinate-command-guide.md`
    - Estimated effort: 30 minutes

11. **Create Automated Tests**
    - Test `coordinate-subprocess-init.sh` sourcing
    - Test each workflow scope independently
    - Verify checkpoint/resume functionality
    - File: `.claude/tests/test_coordinate_subprocess_isolation.sh`
    - Estimated effort: 45 minutes

### Total Estimated Effort
- **Critical path (get to working state)**: 1 hour 5 minutes
- **Complete fix (all 19 blocks)**: 2 hours 15 minutes
- **With testing and documentation**: 3 hours 30 minutes

## References

### Primary Files Analyzed
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-1085)
  - Block 1: Lines 21-113 (Phase 0 Step 1)
  - Block 2: Lines 115-225 (Phase 0 Step 2)
  - Block 3: Lines 227-309 (Phase 0 Step 3)
  - Block 4: Lines 317-333 (Verification Helpers)
  - Block 5: Lines 341-381 (Phase 1 Research Start) ← **FIRST FAILURE**
  - Block 6: Lines 406-467 (Phase 1 Research Verification)
  - Block 7: Lines 492-523 (Overview Synthesis)
  - Block 8: Lines 530-565 (Phase 2 Planning Start)
  - Block 9: Lines 591-654 (Phase 2 Planning Verification)
  - Block 10: Lines 660-704 (Phase 3 Implementation Start)
  - Block 11: Lines 736-784 (Phase 3 Implementation Verification)
  - Block 12: Lines 792-803 (Phase 4 Testing Start)
  - Block 13: Lines 830-868 (Phase 4 Testing Verification)
  - Block 14: Lines 876-890 (Phase 5 Debug Start)
  - Block 15: Lines 913-925 (Phase 5 Debug Verification)
  - Block 16: Lines 947-953 (Phase 5 Debug Apply)
  - Block 17: Lines 977-1008 (Phase 5 Debug Complete)
  - Block 18: Lines 1016-1028 (Phase 6 Documentation Start)
  - Block 19: Lines 1055-1080 (Phase 6 Documentation Verification)

### Library Files Referenced
- `.claude/lib/workflow-detection.sh` - Defines `should_run_phase()`
- `.claude/lib/workflow-scope-detection.sh` - Defines `detect_workflow_scope()`
- `.claude/lib/unified-logger.sh` - Defines `emit_progress()`
- `.claude/lib/checkpoint-utils.sh` - Defines checkpoint and metadata functions
- `.claude/lib/verification-helpers.sh` - Defines `verify_file_created()`
- `.claude/lib/context-pruning.sh` - Defines pruning functions
- `.claude/lib/workflow-initialization.sh` - Defines path initialization functions
- `.claude/lib/overview-synthesis.sh` - Defines overview synthesis functions
- `.claude/lib/dependency-analyzer.sh` - Defines `analyze_dependencies()`
- `.claude/lib/library-sourcing.sh` - Defines `source_required_libraries()`

### Supporting Documentation
- `/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md` - Comprehensive fix plan (verified accurate)
- `/home/benjamin/.config/.claude/specs/coordinate_output.md` - Console output showing actual failure at line 344
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` - Command documentation (needs update)

### Error Evidence
- Console log line 46: `should_run_phase: command not found` (Block 5, line 344)
- Console log line 101: `emit_progress: command not found` (manual fix attempt)
- Fix plan lines 22-100: Detailed error trace analysis (confirmed accurate)

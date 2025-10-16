# Phase 5 Utility Extraction - Modular lib/ Organization

## Metadata
- **Date**: 2025-10-14
- **Revision**: 1 (2025-10-14)
- **Feature**: Re-extract Phase 5 utilities for aggressive lib/ splitting
- **Scope**: Modularize auto-analysis-utils.sh and extract shared utilities from lib/ scripts
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Commits**:
  - Original: c79c628 (Part 1), ccfd422 (Part 2)
  - Reverted: a6a7b62 (Part 1), 8829aa2 (Part 2)
- **Related Plans**: Plan 043 Phase 5 (Refactoring, Dry-Run Mode & Documentation)

## Revision History

### 2025-10-14 - Revision 1
**Changes**: Integrated testing best practices and bug fixes from Plan 043 Phase 5
**Reason**: Leverage lessons learned from completed Plan 043 Phase 5 implementation
**Modified Sections**: Testing Strategy, Bug Fixes, Test Coverage Goals
**Key Integrations**:
- Added test infrastructure considerations (grep -c, arithmetic with set -e, boolean jq extraction)
- Added test coverage goals (≥70% for new utilities, zero regressions)
- Added preemptive bug fixes discovered during Plan 043 Phase 5
- Added recommended new test scripts (test_timestamp_utils.sh, test_validation_utils.sh)
- Emphasized run_all_tests.sh validation after Phase 4

## Overview

This plan re-implements the Phase 5 utility extraction that was reverted on Oct 13, 2025. The original extraction split 1,677 lines of code into focused, maintainable modules but was mistakenly reverted. We will recreate this modular structure to achieve:

**Part 1: Shared Utility Extraction (365 lines)**
- `timestamp-utils.sh` (122 lines): Platform-independent timestamp operations
- `validation-utils.sh` (243 lines): Common validation and parameter checking

**Part 2: Auto-Analysis Modularization (1,260 lines)**
- `agent-invocation.sh` (131 lines): Agent prompt construction
- `phase-analysis.sh` (211 lines): Phase expansion/collapse analysis
- `stage-analysis.sh` (195 lines): Stage expansion/collapse analysis
- `artifact-management.sh` (723 lines): Reporting and artifact registry

**Benefits**:
- Clear separation of concerns (each module < 800 lines)
- Reduced code duplication across lib/ scripts
- Easier testing and maintenance
- Better code organization and discoverability
- Backward compatibility maintained via wrapper pattern

## Success Criteria

- [ ] timestamp-utils.sh created with 6 timestamp functions
- [ ] validation-utils.sh created with 11 validation functions
- [ ] auto-analysis-utils.sh modularized into 4 focused modules
- [ ] All existing consumers updated to source new utilities
- [ ] Backward compatibility maintained (auto-analysis-utils.sh as wrapper)
- [ ] All tests passing (36 adaptive planning tests, auto-analysis tests)
- [ ] No circular dependencies introduced
- [ ] Cross-platform compatibility preserved (Linux/macOS)

## Technical Design

### Architecture Decisions

**1. Shared Utilities Pattern**
```
.claude/lib/
├── timestamp-utils.sh      # Pure timestamp operations
├── validation-utils.sh     # Pure validation functions
├── error-utils.sh          # Error handling (existing)
└── [consumers]             # Source utilities as needed
```

**Design Principles**:
- No circular dependencies: Shared utilities do NOT source error-utils.sh
- Simple local error() function in each utility for standalone operation
- All functions exported for sourcing scripts
- Cross-platform support (GNU/BSD command variants)

**2. Auto-Analysis Modularization Pattern**
```
.claude/lib/
├── auto-analysis-utils.sh       # Thin wrapper (sources all modules)
├── agent-invocation.sh          # Agent coordination
├── phase-analysis.sh            # Phase operations
├── stage-analysis.sh            # Stage operations
└── artifact-management.sh       # Reporting & registry
```

**Design Principles**:
- Wrapper maintains backward compatibility
- Each module exports its functions
- Clear functional boundaries
- Module size target: ~400 lines (max 800)

### Dependency Graph

```
timestamp-utils.sh (standalone)
    ↑
    ├── checkpoint-utils.sh
    ├── adaptive-planning-logger.sh
    └── [other consumers]

validation-utils.sh (standalone)
    ↑
    └── [future consumers]

auto-analysis-utils.sh (wrapper)
    ├── sources: agent-invocation.sh
    ├── sources: phase-analysis.sh
    ├── sources: stage-analysis.sh
    └── sources: artifact-management.sh
```

### Module Specifications

#### timestamp-utils.sh (122 lines)

**Functions**:
- `get_file_mtime <file>`: Get file modification time (cross-platform)
- `format_timestamp <seconds>`: Format Unix time to ISO 8601
- `get_unix_time`: Get current Unix timestamp
- `get_iso_date`: Get current date (YYYY-MM-DD)
- `get_iso_timestamp`: Get current ISO 8601 timestamp
- `compare_timestamps <ts1> <ts2>`: Compare two timestamps (-1/0/1)
- `timestamp_diff <ts1> <ts2>`: Calculate difference in seconds

**Cross-Platform Handling**:
```bash
# macOS (BSD): stat -f %m
# Linux (GNU): stat -c %Y
get_file_mtime() {
  if stat -f %m "$1" 2>/dev/null; then
    return 0  # BSD (macOS)
  else
    stat -c %Y "$1"  # GNU (Linux)
  fi
}
```

#### validation-utils.sh (243 lines)

**Functions**:
- `require_param <name> <value> [description]`: Validate parameter exists
- `validate_file_exists <path> [name]`: Check file exists
- `validate_dir_exists <path> [name]`: Check directory exists
- `validate_number <value> [name]`: Validate integer
- `validate_positive_number <value> [name]`: Validate positive integer
- `validate_float <value> [name]`: Validate floating-point number
- `validate_choice <value> <choices> [name]`: Validate value in set
- `validate_boolean <value> [name]`: Validate true/false/yes/no/0/1
- `validate_not_empty <value> [name]`: Validate non-empty string
- `validate_file_readable <path> [name]`: Check file readable
- `validate_file_writable <path> [name]`: Check file writable
- `validate_path_safe <path>`: Security check for path traversal

**Usage Example**:
```bash
source "${SCRIPT_DIR}/validation-utils.sh"

require_param "plan_path" "$plan_path" "Path to implementation plan"
validate_file_exists "$plan_path" "Plan file"
validate_positive_number "$phase_num" "Phase number"
validate_choice "$mode" "auto interactive" "Revision mode"
```

#### agent-invocation.sh (131 lines)

**Functions**:
- `invoke_complexity_estimator <plan_path> <context>`: Construct agent prompt and invoke complexity analysis

**Responsibilities**:
- Build agent prompts with proper escaping
- Handle agent invocation via Task tool
- Parse agent responses
- Extract complexity scores and recommendations

#### phase-analysis.sh (211 lines)

**Functions**:
- `analyze_phases_for_expansion <plan_path>`: Analyze inline phases for expansion candidates
- `analyze_phases_for_collapse <plan_dir>`: Analyze expanded phases for collapse candidates

**Responsibilities**:
- Phase complexity calculation
- Expansion/collapse candidate identification
- Phase metadata extraction

#### stage-analysis.sh (195 lines)

**Functions**:
- `analyze_stages_for_expansion <phase_path>`: Analyze inline stages for expansion
- `analyze_stages_for_collapse <phase_dir>`: Analyze expanded stages for collapse

**Responsibilities**:
- Stage complexity calculation
- Expansion/collapse candidate identification
- Stage metadata extraction

#### artifact-management.sh (723 lines)

**Functions**:
- `generate_analysis_report <plan_path> <analysis_data>`: Generate analysis report
- `register_operation_artifact <operation> <artifact_path>`: Register operation artifacts
- `review_plan_hierarchy <plan_path>`: Review and visualize plan structure
- `run_second_round_analysis <plan_path>`: Execute second-round complexity analysis
- `present_recommendations_for_approval <recommendations>`: Present and get user approval
- `generate_recommendations_report <recommendations>`: Generate recommendation report

**Responsibilities**:
- Report generation (markdown formatting)
- Artifact registry management
- Parallel execution coordination
- User interaction and approval workflows

### File Size Comparison

**Before Extraction**:
```
auto-analysis-utils.sh:  1,779 lines (monolith)
checkpoint-utils.sh:       769 lines (includes timestamp functions)
adaptive-planning-logger:   ~200 lines (includes timestamp calls)
```

**After Extraction**:
```
Shared Utilities:
  timestamp-utils.sh:      122 lines
  validation-utils.sh:     243 lines

Auto-Analysis Modules:
  auto-analysis-utils.sh:   62 lines (wrapper)
  agent-invocation.sh:     131 lines
  phase-analysis.sh:       211 lines
  stage-analysis.sh:       195 lines
  artifact-management.sh:  723 lines

Updated Consumers:
  checkpoint-utils.sh:     ~700 lines (removed timestamp functions)
  adaptive-planning-logger: ~195 lines (sources timestamp-utils)
```

**Net Result**:
- Total lines: ~2,587 (vs ~2,748 before) = 6% reduction
- Better organization: 7 focused modules vs 3 monoliths
- Reusability: timestamp/validation utilities available to all scripts

## Implementation Phases

### Phase 1: Part 1 - Extract Shared Utilities (timestamp, validation) [COMPLETED]

**Objective**: Create timestamp-utils.sh and validation-utils.sh, update consumers

**Complexity**: Medium

**Tasks**:

- [x] Create `.claude/lib/timestamp-utils.sh` with 7 functions:
  - `get_file_mtime()`: Cross-platform file mtime (BSD/GNU stat)
  - `format_timestamp()`: Unix seconds → ISO 8601
  - `get_unix_time()`: Current Unix timestamp
  - `get_iso_date()`: Current date (YYYY-MM-DD)
  - `get_iso_timestamp()`: Current ISO 8601 timestamp
  - `compare_timestamps()`: Compare two timestamps
  - `timestamp_diff()`: Calculate timestamp difference
  - Include simple local `error()` function (no error-utils.sh dependency)
  - Export all functions
  - Add comprehensive header documentation

- [x] Create `.claude/lib/validation-utils.sh` with 12 validation functions:
  - `require_param()`: Parameter existence validation
  - `validate_file_exists()`: File existence check
  - `validate_dir_exists()`: Directory existence check
  - `validate_number()`: Integer validation
  - `validate_positive_number()`: Positive integer validation
  - `validate_float()`: Floating-point validation
  - `validate_choice()`: Value in set validation
  - `validate_boolean()`: Boolean value validation
  - `validate_not_empty()`: Non-empty string validation
  - `validate_file_readable()`: File readability check
  - `validate_file_writable()`: File writability check
  - `validate_path_safe()`: Security validation (path traversal prevention)
  - Include simple local `error()` function
  - Export all functions
  - Add comprehensive header documentation

- [x] Update `.claude/lib/checkpoint-utils.sh`:
  - Add `source "${BASH_SOURCE%/*}/timestamp-utils.sh"` at top
  - Remove local `get_file_mtime()` implementation
  - Replace with call to sourced function
  - Verify all timestamp operations use timestamp-utils functions

- [x] Update `.claude/lib/adaptive-planning-logger.sh`:
  - Add `source "${BASH_SOURCE%/*}/timestamp-utils.sh"` at top
  - Update all timestamp function calls to use timestamp-utils
  - Verify logging operations work correctly

- [x] Search for other potential consumers in `.claude/lib/`:
  ```bash
  grep -l "stat -[fc]" .claude/lib/*.sh
  grep -l "date.*ISO" .claude/lib/*.sh
  ```
  - Update any other scripts using timestamp operations
  - Ensure consistent use of timestamp-utils.sh

**Testing**:
```bash
# Unit test timestamp-utils
bash -c 'source .claude/lib/timestamp-utils.sh && get_unix_time && get_iso_date && get_iso_timestamp'

# Unit test validation-utils
bash -c 'source .claude/lib/validation-utils.sh && validate_number 42 "test" && validate_file_exists ".claude/lib/validation-utils.sh"'

# Integration: Run adaptive planning tests
cd .claude/tests && ./test_adaptive_planning.sh

# Should pass all 36 tests:
# - 12 complexity threshold tests
# - 12 replan limit tests
# - 12 scope drift tests

# Verify checkpoint-utils still works
cd .claude/tests && ./test_state_management.sh
```

**Validation**:
- [ ] All timestamp functions work on both macOS and Linux
- [ ] All validation functions correctly accept/reject test inputs
- [ ] No circular dependencies (timestamp/validation do NOT source error-utils)
- [ ] Consumers correctly source and use new utilities
- [ ] All adaptive planning tests pass (36 tests)
- [ ] All state management tests pass

**Git Commit**:
```
feat: Phase 5 Part 1 - Extract shared utilities (timestamp, validation)

Created two new shared utility libraries to reduce code duplication:

New Utilities:
- timestamp-utils.sh: Platform-independent timestamp operations
  - get_file_mtime: Cross-platform file modification time
  - format_timestamp: ISO 8601 timestamp formatting
  - get_unix_time, get_iso_date, get_iso_timestamp
  - compare_timestamps, timestamp_diff

- validation-utils.sh: Common validation and parameter checking
  - require_param: Parameter existence validation
  - validate_file_exists, validate_dir_exists
  - validate_number, validate_positive_number, validate_float
  - validate_choice, validate_boolean, validate_not_empty
  - validate_file_readable, validate_file_writable
  - validate_path_safe: Security validation for paths

Updated Files:
- checkpoint-utils.sh: Now uses get_file_mtime from timestamp-utils
- adaptive-planning-logger.sh: Sources timestamp-utils

Design Notes:
- Both utilities avoid circular dependencies by not sourcing error-utils.sh
- Simple error() function defined locally in each utility
- Cross-platform support for GNU (Linux) and BSD (macOS) commands
- All functions exported for use by sourcing scripts

Tests: All adaptive planning and state management tests pass ✓

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 2: Part 2 Stage 1 - Extract Agent Invocation Module

**Objective**: Extract agent invocation logic from auto-analysis-utils.sh into agent-invocation.sh

**Complexity**: Low

**Tasks**:

- [ ] Read `.claude/lib/auto-analysis-utils.sh` and identify agent invocation section:
  - Function: `invoke_complexity_estimator()`
  - Dependencies: Task tool integration, prompt construction
  - Line count: ~131 lines

- [ ] Create `.claude/lib/agent-invocation.sh`:
  - Extract `invoke_complexity_estimator()` function
  - Include all prompt construction logic
  - Add agent response parsing
  - Export all functions
  - Add comprehensive header documentation:
    ```bash
    #!/usr/bin/env bash
    # agent-invocation.sh - Agent coordination and invocation
    # Part of .claude/lib/ modular utilities
    #
    # Functions:
    #   invoke_complexity_estimator - Construct prompts and invoke complexity analysis agent
    ```

- [ ] Verify no dependencies on other auto-analysis functions:
  - Should be standalone (only needs Task tool, no other auto-analysis modules)
  - If dependencies found, include them or refactor

- [ ] Update `.claude/lib/auto-analysis-utils.sh`:
  - Add `source "${BASH_SOURCE%/*}/agent-invocation.sh"` at appropriate location
  - Remove extracted `invoke_complexity_estimator()` function
  - Verify wrapper maintains backward compatibility

**Testing**:
```bash
# Unit test agent-invocation
bash -c 'source .claude/lib/agent-invocation.sh && type invoke_complexity_estimator'

# Integration: Test auto-analysis orchestration
cd .claude/tests && ./test_auto_analysis_orchestration.sh

# Verify all auto-analysis functions accessible
bash -c 'source .claude/lib/auto-analysis-utils.sh && type invoke_complexity_estimator'
```

**Validation**:
- [ ] agent-invocation.sh is standalone (no unmet dependencies)
- [ ] invoke_complexity_estimator() function works identically
- [ ] auto-analysis-utils.sh wrapper sources module correctly
- [ ] Backward compatibility maintained
- [ ] Auto-analysis tests pass

**Git Commit**:
```
feat: Phase 5 Part 2.1 - Extract agent-invocation module

Extracted agent coordination logic from auto-analysis-utils.sh:

Module Created:
- agent-invocation.sh (131 lines)
  - invoke_complexity_estimator: Agent prompt construction and invocation

Updated Main File:
- auto-analysis-utils.sh: Sources agent-invocation module

Benefits:
- Clear separation: Agent coordination isolated from analysis logic
- Standalone module: No dependencies on other auto-analysis modules
- Maintainability: Agent prompt changes isolated to single file

Tests: Auto-analysis orchestration tests pass ✓

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 3: Part 2 Stage 2 - Extract Analysis Modules (phase, stage)

**Objective**: Extract phase-analysis.sh and stage-analysis.sh from auto-analysis-utils.sh

**Complexity**: Medium

**Tasks**:

- [ ] Create `.claude/lib/phase-analysis.sh` (211 lines):
  - Extract `analyze_phases_for_expansion()` function
  - Extract `analyze_phases_for_collapse()` function
  - Include phase metadata extraction logic
  - Include phase complexity calculation
  - Export all functions
  - Add comprehensive header documentation

- [ ] Create `.claude/lib/stage-analysis.sh` (195 lines):
  - Extract `analyze_stages_for_expansion()` function
  - Extract `analyze_stages_for_collapse()` function
  - Include stage metadata extraction logic
  - Include stage complexity calculation
  - Export all functions
  - Add comprehensive header documentation

- [ ] Identify shared helper functions between phase/stage analysis:
  - If significant overlap (>50 lines), consider creating `analysis-common.sh`
  - Otherwise, duplicate small helpers in each module
  - Document decision in commit message

- [ ] Update `.claude/lib/auto-analysis-utils.sh`:
  - Add `source "${BASH_SOURCE%/*}/phase-analysis.sh"`
  - Add `source "${BASH_SOURCE%/*}/stage-analysis.sh"`
  - Remove extracted functions
  - Verify wrapper maintains backward compatibility

- [ ] Verify cross-module dependencies:
  - Check if phase-analysis needs stage-analysis or vice versa
  - Ensure clean dependency chain (no circular references)
  - Document any inter-module dependencies

**Testing**:
```bash
# Unit test phase-analysis
bash -c 'source .claude/lib/phase-analysis.sh && type analyze_phases_for_expansion && type analyze_phases_for_collapse'

# Unit test stage-analysis
bash -c 'source .claude/lib/stage-analysis.sh && type analyze_stages_for_expansion && type analyze_stages_for_collapse'

# Integration: Test progressive structure operations
cd .claude/tests && ./test_progressive_expansion.sh
cd .claude/tests && ./test_progressive_collapse.sh

# Verify auto-analysis wrapper works
bash -c 'source .claude/lib/auto-analysis-utils.sh && type analyze_phases_for_expansion && type analyze_stages_for_expansion'

# Run full auto-analysis orchestration test
cd .claude/tests && ./test_auto_analysis_orchestration.sh
```

**Validation**:
- [ ] phase-analysis.sh exports all phase functions
- [ ] stage-analysis.sh exports all stage functions
- [ ] No circular dependencies between modules
- [ ] auto-analysis-utils.sh wrapper sources both modules
- [ ] All progressive structure tests pass
- [ ] Auto-analysis orchestration tests pass
- [ ] Backward compatibility maintained

**Git Commit**:
```
feat: Phase 5 Part 2.2 - Extract phase and stage analysis modules

Extracted analysis logic from auto-analysis-utils.sh into focused modules:

Modules Created:
- phase-analysis.sh (211 lines)
  - analyze_phases_for_expansion: Analyze inline phases for expansion
  - analyze_phases_for_collapse: Analyze expanded phases for collapse
  - Phase complexity calculation and metadata extraction

- stage-analysis.sh (195 lines)
  - analyze_stages_for_expansion: Analyze inline stages for expansion
  - analyze_stages_for_collapse: Analyze expanded stages for collapse
  - Stage complexity calculation and metadata extraction

Updated Main File:
- auto-analysis-utils.sh: Sources phase-analysis and stage-analysis modules

Benefits:
- Clear separation: Phase and stage operations isolated
- Parallel testing: Each module can be tested independently
- Reduced coupling: Analysis logic separated from reporting

Tests: Progressive expansion/collapse and orchestration tests pass ✓

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 4: Part 2 Stage 3 - Extract Artifact Management and Finalize [COMPLETED]

**Objective**: Extract artifact-management.sh and finalize auto-analysis-utils.sh wrapper

**Complexity**: Medium

**Tasks**:

- [x] Create `.claude/lib/artifact-management.sh` (678 lines):
  - Extract `generate_analysis_report()` function
  - Extract `register_operation_artifact()` function
  - Extract `get_artifact_path()` function
  - Extract `validate_operation_artifacts()` function
  - Extract `review_plan_hierarchy()` function
  - Extract `run_second_round_analysis()` function
  - Extract `present_recommendations_for_approval()` function
  - Extract `generate_recommendations_report()` function
  - Include all report formatting and artifact registry logic
  - Export all functions
  - Add comprehensive header documentation

- [x] Update `.claude/lib/auto-analysis-utils.sh`:
  - Add `source "${BASH_SOURCE%/*}/artifact-management.sh"`
  - Remove all extracted functions
  - Now a wrapper (~638 lines, includes parallel execution functions):
    ```bash
    #!/usr/bin/env bash
    # Auto-Analysis Utilities - Modular Wrapper
    # Sources all auto-analysis modules for backward compatibility

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Source all auto-analysis modules
    source "${SCRIPT_DIR}/agent-invocation.sh"
    source "${SCRIPT_DIR}/phase-analysis.sh"
    source "${SCRIPT_DIR}/stage-analysis.sh"
    source "${SCRIPT_DIR}/artifact-management.sh"

    # All functions now available through sourced modules
    # No additional functions needed - modules handle everything
    ```
  - Include improved documentation explaining modular structure
  - List all available functions (from modules)

- [x] Verify all module dependencies:
  - agent-invocation.sh: Standalone ✓
  - phase-analysis.sh: Standalone ✓
  - stage-analysis.sh: Standalone ✓
  - artifact-management.sh: Standalone ✓
  - Proper sourcing order prevents undefined function errors ✓

- [x] Update any direct consumers of auto-analysis-utils.sh:
  - Verified wrapper maintains backward compatibility
  - All functions accessible via wrapper

- [x] Perform full module size audit:
  ```
  135 lines: agent-invocation.sh ✓ (< 800)
  203 lines: phase-analysis.sh ✓ (< 800)
  196 lines: stage-analysis.sh ✓ (< 800)
  678 lines: artifact-management.sh ✓ (< 800)
  638 lines: auto-analysis-utils.sh ✓ (< 800, includes parallel functions)
  ```
  - All modules meet < 800 line target ✓

**Testing**:
```bash
# Unit test artifact-management
bash -c 'source .claude/lib/artifact-management.sh && type generate_analysis_report && type register_operation_artifact'

# Test wrapper sources all modules
bash -c 'source .claude/lib/auto-analysis-utils.sh && type invoke_complexity_estimator && type analyze_phases_for_expansion && type generate_analysis_report'

# Run complete test suite for auto-analysis
cd .claude/tests && ./test_auto_analysis_orchestration.sh

# Run progressive structure tests
cd .claude/tests && ./test_progressive_expansion.sh
cd .claude/tests && ./test_progressive_collapse.sh

# Verify no broken imports in commands
cd .claude/tests && ./test_command_integration.sh

# Run full adaptive planning test suite (uses auto-analysis)
cd .claude/tests && ./test_adaptive_planning.sh
```

**Validation**:
- [x] artifact-management.sh exports all reporting functions ✓
- [x] auto-analysis-utils.sh is a modular wrapper (638 lines with parallel functions) ✓
- [x] All modules properly sourced in correct order ✓
- [x] No undefined function errors when wrapper sourced ✓
- [x] Test suite run: 28 suites passed, 182 individual tests ✓
- [x] Module sizes meet targets (< 800 lines each) ✓

**Final Module Inventory**:
```
.claude/lib/
├── timestamp-utils.sh          123 lines ✓
├── validation-utils.sh         244 lines ✓
├── agent-invocation.sh         135 lines ✓
├── phase-analysis.sh           203 lines ✓
├── stage-analysis.sh           196 lines ✓
├── artifact-management.sh      678 lines ✓
└── auto-analysis-utils.sh      638 lines ✓ (wrapper + parallel execution)
                              ─────────────
                              2,217 lines total (modular organization)
```

**Git Commit**:
```
feat: Phase 5 Part 2.3 - Extract artifact management and finalize modularization

Completed auto-analysis-utils.sh modularization:

Module Created:
- artifact-management.sh (723 lines)
  - generate_analysis_report: Report generation with markdown formatting
  - register_operation_artifact: Artifact registry management
  - review_plan_hierarchy: Plan structure visualization
  - run_second_round_analysis: Second-round complexity analysis
  - present_recommendations_for_approval: User interaction workflows
  - generate_recommendations_report: Recommendation report generation
  - Parallel execution coordination

Finalized Main File:
- auto-analysis-utils.sh (62 lines)
  - Now a thin wrapper that sources all modules
  - Maintains complete backward compatibility
  - Improved documentation listing all available functions

Complete Module Structure:
- agent-invocation.sh:     131 lines ✓
- phase-analysis.sh:       211 lines ✓
- stage-analysis.sh:       195 lines ✓
- artifact-management.sh:  723 lines ✓
- auto-analysis-utils.sh:   62 lines ✓ (wrapper)

Benefits:
- Clear separation of concerns across 4 focused modules
- Each module under 800 lines (target: ~400 lines)
- Easy to maintain, test, and extend
- Complete backward compatibility via wrapper pattern
- All functions properly exported and accessible

Tests: All auto-analysis, progressive structure, command integration, and adaptive planning tests pass ✓

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Testing Strategy

### Test Infrastructure Considerations

**Known Test Infrastructure Issues** (from Plan 043 Phase 5):
- `grep -c "pattern" || echo "0"` produces "0\n0" when no matches (fixed with `|| true` + empty checks)
- Arithmetic operations with `set -e`: `((VAR++))` fails, use `VAR=$((VAR + 1))`
- Boolean extraction in jq: `.field // default` treats false as falsy (use explicit null checks)

These issues should be avoided in any new test scripts created for this plan.

### Unit Testing Approach

**Per-Module Validation**:
1. Source module independently
2. Verify all functions defined (`type function_name`)
3. Test basic function behavior with known inputs
4. Verify cross-platform compatibility (if applicable)

**Example Unit Test**:
```bash
#!/usr/bin/env bash
# test_timestamp_utils.sh

source "$(dirname "$0")/../lib/timestamp-utils.sh"

# Test 1: get_unix_time returns numeric value
timestamp=$(get_unix_time)
[[ "$timestamp" =~ ^[0-9]+$ ]] || { echo "FAIL: Invalid timestamp"; exit 1; }

# Test 2: get_iso_date returns YYYY-MM-DD format
iso_date=$(get_iso_date)
[[ "$iso_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "FAIL: Invalid ISO date"; exit 1; }

# Test 3: get_file_mtime works on test file
mtime=$(get_file_mtime "$0")
[[ "$mtime" =~ ^[0-9]+$ ]] || { echo "FAIL: Invalid file mtime"; exit 1; }

echo "PASS: All timestamp utility tests passed"
```

### Recommended New Test Scripts

Based on Plan 043 Phase 5's comprehensive testing approach, consider creating:

**1. test_timestamp_utils.sh** (new)
- Test all 7 timestamp functions with known inputs
- Test cross-platform compatibility (BSD vs GNU stat)
- Test edge cases (file not found, invalid timestamps)
- Verify ISO 8601 formatting accuracy
- Expected: ~15-20 tests

**2. test_validation_utils.sh** (new)
- Test all 12 validation functions
- Test positive and negative cases for each validator
- Test edge cases (empty strings, null, invalid types)
- Test path traversal security validation
- Expected: ~25-30 tests

**3. test_shared_utilities_integration.sh** (new)
- Test timestamp-utils integration with checkpoint-utils
- Test timestamp-utils integration with adaptive-planning-logger
- Verify no circular dependencies
- Test sourcing order correctness
- Expected: ~10-15 tests

### Integration Testing Approach

**Existing Test Suites** (must pass after each phase):

1. **test_adaptive_planning.sh** (36 tests)
   - Tests adaptive planning integration
   - Uses checkpoint-utils.sh (which uses timestamp-utils)
   - Validates complexity thresholds and replan limits
   - Must pass after Phase 1

2. **test_state_management.sh**
   - Tests checkpoint operations
   - Uses checkpoint-utils.sh heavily
   - Validates checkpoint creation/restoration
   - Must pass after Phase 1

3. **test_auto_analysis_orchestration.sh**
   - Tests complete auto-analysis workflow
   - Uses all auto-analysis modules
   - Validates expansion/collapse operations
   - Must pass after Phases 2-4

4. **test_progressive_expansion.sh** & **test_progressive_collapse.sh**
   - Test phase/stage expansion and collapse
   - Use phase-analysis and stage-analysis modules
   - Must pass after Phase 3

5. **test_command_integration.sh**
   - Tests /expand, /collapse, /implement commands
   - Verifies commands work with modularized utilities
   - Must pass after Phase 4

### Test Coverage Goals

Following Plan 043 Phase 5's standards:
- **Unit test coverage**: ≥70% for new utilities (timestamp, validation)
- **Integration test coverage**: All major workflows with utility integration
- **Regression test coverage**: Verify no behavior changes from modularization
- **Zero regressions**: All existing tests must continue passing

### Regression Testing

**After Each Phase**:
```bash
cd .claude/tests

# Phase 1: After shared utilities extraction
./test_adaptive_planning.sh || exit 1
./test_state_management.sh || exit 1
# If created: ./test_timestamp_utils.sh || exit 1
# If created: ./test_validation_utils.sh || exit 1

# Phase 2: After agent-invocation extraction
./test_auto_analysis_orchestration.sh || exit 1

# Phase 3: After phase/stage analysis extraction
./test_progressive_expansion.sh || exit 1
./test_progressive_collapse.sh || exit 1
./test_auto_analysis_orchestration.sh || exit 1

# Phase 4: After artifact-management extraction (full suite)
./test_adaptive_planning.sh || exit 1
./test_state_management.sh || exit 1
./test_auto_analysis_orchestration.sh || exit 1
./test_progressive_expansion.sh || exit 1
./test_progressive_collapse.sh || exit 1
./test_command_integration.sh || exit 1

# Run full test suite to verify zero regressions
./run_all_tests.sh  # Should exit 0
```

### Bug Fixes to Apply

Based on Plan 043 Phase 5's bug discoveries, apply these fixes preemptively:

**1. Boolean Extraction in checkpoint-utils.sh**:
```bash
# BAD (treats false as falsy):
tests_passing=$(jq -r '.tests_passing // true' checkpoint.json)

# GOOD (explicit null check):
tests_passing=$(jq -r 'if .tests_passing == null then "true" else (.tests_passing | tostring) end' checkpoint.json)
```

**2. Arithmetic with set -e**:
```bash
# BAD (fails with set -e when result is 0):
((test_count++))

# GOOD:
test_count=$((test_count + 1))
```

**3. grep -c with fallback**:
```bash
# BAD (produces "0\n0" when no matches):
count=$(grep -c "pattern" file || echo "0")

# GOOD:
count=$(grep -c "pattern" file || true)
[[ -z "$count" ]] && count=0
```

### Backward Compatibility Validation

**After Phase 4 Complete**:
```bash
# Test 1: Verify auto-analysis-utils.sh wrapper exposes all functions
source .claude/lib/auto-analysis-utils.sh

# All original functions should still be available
type invoke_complexity_estimator >/dev/null || { echo "FAIL: invoke_complexity_estimator not found"; exit 1; }
type analyze_phases_for_expansion >/dev/null || { echo "FAIL: analyze_phases_for_expansion not found"; exit 1; }
type analyze_phases_for_collapse >/dev/null || { echo "FAIL: analyze_phases_for_collapse not found"; exit 1; }
type analyze_stages_for_expansion >/dev/null || { echo "FAIL: analyze_stages_for_expansion not found"; exit 1; }
type analyze_stages_for_collapse >/dev/null || { echo "FAIL: analyze_stages_for_collapse not found"; exit 1; }
type generate_analysis_report >/dev/null || { echo "FAIL: generate_analysis_report not found"; exit 1; }
type register_operation_artifact >/dev/null || { echo "FAIL: register_operation_artifact not found"; exit 1; }

echo "PASS: All functions accessible via wrapper"

# Test 2: Verify commands that source auto-analysis-utils still work
grep -l "auto-analysis-utils.sh" .claude/commands/*.md | while read -r cmd; do
  echo "Validating: $cmd"
  # Commands should parse without errors
done

echo "PASS: All commands compatible with modular structure"
```

### Performance Testing (Optional)

**Sourcing Time Comparison**:
```bash
# Before: Single monolith
time bash -c 'source .claude/lib/auto-analysis-utils.sh'

# After: Modular structure (sources 4 modules)
time bash -c 'source .claude/lib/auto-analysis-utils.sh'

# Expected: Minimal difference (< 10ms)
```

**Module Size Validation**:
```bash
# Verify all modules meet size targets
for module in agent-invocation phase-analysis stage-analysis artifact-management; do
  lines=$(wc -l < ".claude/lib/${module}.sh")
  if [[ $lines -gt 800 ]]; then
    echo "WARNING: ${module}.sh exceeds 800 lines (${lines})"
  else
    echo "PASS: ${module}.sh = ${lines} lines"
  fi
done
```

## Documentation Requirements

### Module Documentation

**Each New Module Must Include**:

1. **Header Comment Block**:
```bash
#!/usr/bin/env bash
# module-name.sh - Brief description
# Part of .claude/lib/ modular utilities
#
# Purpose:
#   Detailed description of module purpose and responsibilities
#
# Functions:
#   function_name - Brief description
#   another_function - Brief description
#
# Dependencies:
#   - List any sourced modules or external tools
#
# Usage:
#   source "${BASH_SOURCE%/*}/module-name.sh"
#   function_name arg1 arg2
#
# Notes:
#   - Any important design decisions or limitations
```

2. **Function Documentation**:
```bash
# Brief one-line description of function
#
# Arguments:
#   $1 - Description of first argument
#   $2 - Description of second argument (optional)
#
# Returns:
#   0 - Success
#   1 - Error condition 1
#   2 - Error condition 2
#
# Output:
#   Description of what function outputs to stdout/stderr
#
# Example:
#   result=$(function_name "arg1" "arg2")
function_name() {
  # Implementation
}
```

### README Updates

**Update `.claude/lib/README.md`**:

Add new section after "Module Organization":

```markdown
### Shared Utilities

**timestamp-utils.sh**
Platform-independent timestamp operations. Provides cross-platform (Linux/macOS) functions for file modification times, ISO 8601 formatting, and timestamp comparisons.

Functions:
- `get_file_mtime <file>` - Get file modification time (Unix seconds)
- `format_timestamp <seconds>` - Format Unix time to ISO 8601
- `get_unix_time` - Current Unix timestamp
- `get_iso_date` - Current date (YYYY-MM-DD)
- `get_iso_timestamp` - Current ISO 8601 timestamp
- `compare_timestamps <ts1> <ts2>` - Compare timestamps (-1/0/1)
- `timestamp_diff <ts1> <ts2>` - Calculate difference in seconds

**validation-utils.sh**
Common validation and parameter checking functions. Provides consistent validation across all lib/ scripts.

Functions:
- `require_param <name> <value> [desc]` - Validate parameter exists
- `validate_file_exists <path> [name]` - Check file exists
- `validate_dir_exists <path> [name]` - Check directory exists
- `validate_number <value> [name]` - Validate integer
- `validate_positive_number <value> [name]` - Validate positive integer
- `validate_float <value> [name]` - Validate float
- `validate_choice <value> <choices> [name]` - Validate value in set
- `validate_boolean <value> [name]` - Validate boolean
- `validate_not_empty <value> [name]` - Validate non-empty
- `validate_file_readable <path> [name]` - Check readable
- `validate_file_writable <path> [name]` - Check writable
- `validate_path_safe <path>` - Security check for path traversal

### Auto-Analysis Modules

**auto-analysis-utils.sh** (wrapper)
Thin wrapper that sources all auto-analysis modules. Maintains backward compatibility for scripts that source auto-analysis-utils.sh. All functionality provided by sourced modules.

**agent-invocation.sh**
Agent coordination and complexity estimation. Handles Task tool integration and agent prompt construction.

Functions:
- `invoke_complexity_estimator <plan_path> <context>` - Invoke complexity analysis agent

**phase-analysis.sh**
Phase expansion and collapse analysis. Analyzes phase complexity and identifies expansion/collapse candidates.

Functions:
- `analyze_phases_for_expansion <plan_path>` - Find phases to expand
- `analyze_phases_for_collapse <plan_dir>` - Find phases to collapse

**stage-analysis.sh**
Stage expansion and collapse analysis. Analyzes stage complexity within phases.

Functions:
- `analyze_stages_for_expansion <phase_path>` - Find stages to expand
- `analyze_stages_for_collapse <phase_dir>` - Find stages to collapse

**artifact-management.sh**
Report generation and artifact registry. Handles analysis report formatting, artifact tracking, and user interaction workflows.

Functions:
- `generate_analysis_report <plan_path> <data>` - Generate analysis report
- `register_operation_artifact <op> <path>` - Register artifacts
- `review_plan_hierarchy <plan_path>` - Review plan structure
- `run_second_round_analysis <plan_path>` - Second-round analysis
- `present_recommendations_for_approval <recs>` - User approval workflow
- `generate_recommendations_report <recs>` - Generate recommendation report
```

### CHANGELOG Entry

**Add to `.claude/CHANGELOG.md`** (or create if doesn't exist):

```markdown
## [Unreleased]

### Added
- **Shared Utilities**: New modular utilities for timestamp operations and validation
  - `timestamp-utils.sh` (122 lines): Cross-platform timestamp functions
  - `validation-utils.sh` (243 lines): Common validation functions

- **Auto-Analysis Modules**: Modularized auto-analysis-utils.sh into focused modules
  - `agent-invocation.sh` (131 lines): Agent coordination
  - `phase-analysis.sh` (211 lines): Phase expansion/collapse analysis
  - `stage-analysis.sh` (195 lines): Stage expansion/collapse analysis
  - `artifact-management.sh` (723 lines): Reporting and artifact registry

### Changed
- **auto-analysis-utils.sh**: Refactored from 1,779-line monolith to 62-line wrapper
- **checkpoint-utils.sh**: Now sources timestamp-utils.sh instead of defining timestamp functions locally
- **adaptive-planning-logger.sh**: Now sources timestamp-utils.sh

### Benefits
- **Better Organization**: 1,687 lines across 6 focused modules vs 3 monoliths
- **Reduced Duplication**: Shared timestamp/validation utilities available to all scripts
- **Easier Maintenance**: Each module < 800 lines (target ~400)
- **Clear Boundaries**: Separation of concerns between agent coordination, analysis, and reporting
- **Backward Compatible**: auto-analysis-utils.sh wrapper maintains all existing functionality

### Testing
- All adaptive planning tests pass (36 tests)
- All state management tests pass
- All auto-analysis orchestration tests pass
- All progressive expansion/collapse tests pass
- All command integration tests pass
```

## Dependencies

### External Dependencies
- **bash**: Version 4.0+ (for associative arrays and other modern features)
- **stat**: Both GNU (Linux) and BSD (macOS) variants supported
- **date**: Both GNU (Linux) and BSD (macOS) variants supported
- **grep, sed, awk**: Standard Unix text processing tools

### Internal Dependencies

**Phase 1 Dependencies**:
- None (creates new standalone utilities)

**Phase 2 Dependencies**:
- Phase 1 must be complete (may need timestamp/validation utils)

**Phase 3 Dependencies**:
- Phase 1 must be complete
- Phase 2 should be complete (phase/stage analysis may use agent invocation)

**Phase 4 Dependencies**:
- All previous phases must be complete
- artifact-management.sh uses functions from agent-invocation, phase-analysis, stage-analysis

### Sourcing Order

**Critical**: Modules must be sourced in correct order to avoid undefined function errors.

**Recommended Order** (in auto-analysis-utils.sh):
```bash
# 1. Standalone modules first (no inter-module dependencies)
source "${SCRIPT_DIR}/agent-invocation.sh"

# 2. Analysis modules (may use agent-invocation for complexity estimation)
source "${SCRIPT_DIR}/phase-analysis.sh"
source "${SCRIPT_DIR}/stage-analysis.sh"

# 3. Artifact management last (uses all previous modules)
source "${SCRIPT_DIR}/artifact-management.sh"
```

## Risk Assessment

### High Risk Areas

**1. Circular Dependencies**
- **Risk**: Modules source each other creating circular dependency
- **Likelihood**: Medium (if not careful with sourcing)
- **Impact**: High (scripts fail to load)
- **Mitigation**:
  - Design modules to be standalone or one-way dependent
  - Document dependency graph clearly
  - Test each module independently before integration
  - Use wrapper pattern (auto-analysis-utils.sh sources all, modules don't source each other)

**2. Backward Compatibility Breakage**
- **Risk**: Existing scripts that source auto-analysis-utils.sh break
- **Likelihood**: Low (wrapper pattern maintains compatibility)
- **Impact**: High (commands and scripts fail)
- **Mitigation**:
  - auto-analysis-utils.sh remains as wrapper sourcing all modules
  - All original function names preserved
  - Comprehensive integration testing before each commit
  - Test command_integration.sh specifically checks command compatibility

**3. Cross-Platform Issues**
- **Risk**: timestamp-utils.sh fails on macOS or Linux
- **Likelihood**: Medium (stat/date commands differ between platforms)
- **Impact**: Medium (timestamp operations fail)
- **Mitigation**:
  - Implement cross-platform detection (BSD vs GNU)
  - Test on both macOS and Linux if possible
  - Fallback to simple date commands if stat fails
  - Document platform-specific behavior

### Medium Risk Areas

**1. Function Export Issues**
- **Risk**: Functions not properly exported from modules
- **Likelihood**: Low (bash exports functions to sourced scripts by default)
- **Impact**: Medium (undefined function errors)
- **Mitigation**:
  - Use `export -f function_name` if needed
  - Test each module independently
  - Verify all functions accessible after sourcing wrapper

**2. Module Size Targets**
- **Risk**: artifact-management.sh exceeds 800-line target
- **Likelihood**: Medium (it's already 723 lines)
- **Impact**: Low (organizational concern, not functional)
- **Mitigation**:
  - Accept 723 lines as reasonable for report generation module
  - Consider further splitting if grows beyond 800 lines in future
  - Prioritize functional clarity over arbitrary line limits

**3. Test Suite Maintenance**
- **Risk**: New modules require new test cases
- **Likelihood**: High (new code needs tests)
- **Impact**: Medium (reduced test coverage)
- **Mitigation**:
  - Create unit tests for timestamp-utils and validation-utils
  - Existing integration tests cover auto-analysis modules
  - Run full regression suite after each phase

### Low Risk Areas

**1. Performance Regression**
- **Risk**: Sourcing multiple modules slower than single file
- **Likelihood**: Low (sourcing overhead is minimal)
- **Impact**: Low (< 10ms difference expected)
- **Mitigation**:
  - Measure sourcing time before/after if concerned
  - Optimize if >50ms performance regression observed
  - Modular benefits outweigh minimal performance cost

**2. Documentation Drift**
- **Risk**: README.md becomes outdated after changes
- **Likelihood**: Medium (docs require manual updates)
- **Impact**: Low (confusion for developers, not functional)
- **Mitigation**:
  - Update README.md in each phase commit
  - Include documentation updates in phase tasks
  - Review documentation in final validation

## Notes

### Design Rationale

**Why Aggressive Splitting?**

The original Phase 5 revert was a mistake. Modular organization provides significant benefits:

1. **Maintainability**: 400-line modules are easier to understand than 1,779-line monoliths
2. **Testability**: Each module can be tested independently
3. **Reusability**: Shared utilities (timestamp, validation) available to all scripts
4. **Clarity**: Clear functional boundaries (agent coordination vs analysis vs reporting)
5. **Extensibility**: New functionality can be added to appropriate module without navigating massive files

**Why Wrapper Pattern?**

The auto-analysis-utils.sh wrapper maintains complete backward compatibility:
- Existing scripts continue to work without modification
- All function names preserved
- Single source statement loads all functionality
- Clean migration path (can update consumers gradually to source specific modules)

**Why These Specific Modules?**

Module boundaries chosen based on functional cohesion:
- **timestamp-utils**: Pure timestamp operations (no business logic)
- **validation-utils**: Pure validation functions (no business logic)
- **agent-invocation**: Agent coordination isolated from analysis
- **phase-analysis**: Phase operations separate from stage operations
- **stage-analysis**: Stage operations separate from phase operations
- **artifact-management**: Reporting and artifact tracking separate from analysis logic

### Alternative Approaches Considered

**Alternative 1: Keep Monoliths**
- **Pros**: No risk of breaking changes, simpler dependencies
- **Cons**: Harder to maintain, more code duplication, poor organization
- **Verdict**: Rejected - maintenance burden too high for growing codebase

**Alternative 2: More Aggressive Splitting**
- **Example**: Split artifact-management.sh into report-generation.sh + artifact-registry.sh + parallel-execution.sh
- **Pros**: Smaller modules (< 300 lines each)
- **Cons**: More files to manage, more sourcing overhead, diminishing returns
- **Verdict**: Deferred - current split is sufficient, can revisit if modules grow

**Alternative 3: Single Phase (All at Once)**
- **Pros**: Faster completion, single commit
- **Cons**: Harder to debug if issues arise, larger risk, all-or-nothing testing
- **Verdict**: Rejected - phased approach safer for mission-critical utilities

### Success Metrics

**Quantitative Metrics**:
- [ ] 6 new/updated modules created (timestamp, validation, agent-invocation, phase-analysis, stage-analysis, artifact-management)
- [ ] 1,687 lines of modular code (vs 1,779 lines monolithic)
- [ ] All modules < 800 lines (target ~400)
- [ ] 100% backward compatibility (all existing scripts work)
- [ ] 100% test pass rate (all test suites green)
- [ ] 0 circular dependencies

**Qualitative Metrics**:
- [ ] Improved code readability (modules easy to understand)
- [ ] Clear functional boundaries (no ambiguity about module purpose)
- [ ] Comprehensive documentation (README, module headers, function comments)
- [ ] Developer confidence (comfortable modifying modular code vs monoliths)

### Future Enhancements

**Potential Follow-Up Work**:

1. **Additional Shared Utilities**:
   - `logging-utils.sh`: Standardized logging across all scripts
   - `error-handling-utils.sh`: Enhanced error handling patterns
   - `config-utils.sh`: Configuration management utilities

2. **Further Auto-Analysis Refinement**:
   - Split artifact-management.sh if it grows beyond 800 lines
   - Add `report-templates/` directory for report formatting
   - Extract parallel execution logic to `parallel-utils.sh`

3. **Testing Enhancements**:
   - Add unit tests for each module in `.claude/tests/lib/`
   - Create `test_all_lib_utilities.sh` comprehensive test runner
   - Add performance benchmarks for sourcing time

4. **Documentation Improvements**:
   - Create visual dependency graph (using graphviz)
   - Add usage examples to each module header
   - Create developer guide: "Working with .claude/lib/ utilities"

5. **Backward Compatibility Phase-Out** (optional, future):
   - Gradually update consumers to source specific modules
   - Eventually deprecate auto-analysis-utils.sh wrapper
   - Requires broader refactoring effort, low priority

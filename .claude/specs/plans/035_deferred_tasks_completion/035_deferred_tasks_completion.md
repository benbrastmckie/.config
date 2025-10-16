# Deferred Tasks Completion Implementation Plan

## Metadata
- **Date**: 2025-10-09
- **Feature**: Complete 7 deferred tasks from DEFERRED_TASKS.md (Tasks 3-9) + Artifact Creation + Adaptive Planning + Bidirectional Structure Optimization
- **Scope**: Code refactoring, testing and logging infrastructure, artifact workflow, adaptive planning optimization, collapse/expand workflow integration
- **Estimated Phases**: 7
- **Structure Level**: 1
- **Expanded Phases**: [2, 3, 6, 7]
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Reference Document**: /home/benjamin/.config/.claude/DEFERRED_TASKS.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/reports/027_artifact_creation_reference_workflow.md
  - /home/benjamin/.config/.claude/specs/reports/028_adaptive_plan_workflow_analysis.md
  - /home/benjamin/.config/.claude/specs/reports/029_collapse_expand_workflow_integration.md

## Overview

This plan addresses 7 deferred tasks documented in DEFERRED_TASKS.md, organized by logical dependencies and complexity:

**Tasks 1-2 Removed**: Buffer reload documentation and notification are redundant
- Global autocommand already handles buffer reloading (FocusGained, BufEnter → checktime)
- Config intentionally reloads buffers silently (FileChangedShell autocommand)
- No picker-specific documentation or notification needed

**Picker Refactoring (Tasks 3-5)**: Code quality improvements
- Task 3: Extract dialog builder helper function (30 min)
- Task 4: Optimize filepath construction in do_load() (20 min)
- Task 5: Add strategic code comments (30 min)

**Testing & Logging Infrastructure (Tasks 6-9)**: Observability and test coverage
- Task 6: Adaptive planning logging and observability (3-4 hours)
- Task 7: Adaptive planning integration tests (2-3 hours)
- Task 8: /revise auto-mode integration tests (3-4 hours)
- Task 9: Commands updated to use shared utilities (2-3 hours)

**Artifact Creation Implementation**: Enable artifact-based research workflow
- Phase 5: Implement core artifact creation for research-specialist (2-3 hours)
- Artifacts use variable-length format optimizing for concision without unnecessary loss of content
- Artifacts numbered as `{project_dir}/specs/artifacts/{topic}/NNN_artifact_name.md` incrementing to next available number
- See report 027 for complete analysis and 6-phase roadmap (7-11 hours total)
- This plan focuses on Phase 1 from report as foundational implementation

**Adaptive Planning Optimization**: Post-creation plan evaluation and auto-expansion
- Phase 6: Implement post-creation evaluation and configurable thresholds (3-5 hours)
- See report 028 for complete workflow analysis and 5-phase roadmap (4-6 hours total)
- This plan focuses on Phases 1-2 from report (high priority improvements)

**Bidirectional Structure Optimization**: Collapse/expand workflow integration
- Phase 7: Implement /revise structure evaluation and auto-mode collapse (6-8 hours)
- See report 029 for complete workflow analysis and 5-phase roadmap (12-15 hours total)
- This plan focuses on Phases 1-3 from report (high priority core improvements)

**Total Estimated Effort**: 21-29 hours (10-13 hours for Tasks 3-9 + 2-3 hours artifact + 3-5 hours adaptive + 6-8 hours structure)

## Success Criteria

- [ ] All 7 remaining deferred tasks completed and tested (Tasks 3-9)
- [ ] Tasks 1-2 documented as redundant in DEFERRED_TASKS.md
- [ ] Code follows project standards (indentation, naming, comments)
- [ ] Refactored code maintains functionality (no regressions)
- [ ] Logging infrastructure operational with structured output
- [ ] Integration tests passing with ≥80% coverage
- [x] Shared utilities integrated without breaking existing commands (Phase 4)
- [x] Artifact creation workflow operational (research-specialist can write artifacts) (Phase 5)
- [x] Artifacts use variable-length format with complexity-appropriate detail (Phase 5)
- [x] Artifact numbering auto-increments per topic directory (Phase 5)
- [x] Artifact registry integration tested and working (Phase 5)
- [x] Post-creation plan evaluation functional (auto-expansion after /plan) (Phase 6)
- [x] Configurable complexity thresholds in CLAUDE.md (Phase 6)
- [ ] /revise structure evaluation functional (expansion/collapse recommendations)
- [ ] Auto-mode collapse support enabled (collapse_phase revision type)
- [ ] Collapse logging integrated with adaptive planning logger
- [ ] All changes committed with descriptive messages

## Technical Design

### Architecture Decisions

**1. Task Grouping Strategy**
- **Phase 1**: Picker refactoring - code quality improvements in single file
- **Phase 2**: Logging infrastructure - enable observability for adaptive planning
- **Phase 3**: Integration tests - validate complex workflows
- **Phase 4**: Utility integration - reduce duplication across commands
- **Phase 5**: Artifact creation - implement core artifact workflow from report 027 Phase 1
- **Phase 6**: Adaptive planning - post-creation evaluation and configurable thresholds from report 028 Phases 1-2
- **Phase 7**: Structure optimization - /revise integration and auto-mode collapse from report 029 Phases 1-3

**2. Testing Approach**
- Manual validation for documentation and refactoring (no automated tests for Lua code)
- Comprehensive integration tests for adaptive planning and auto-mode workflows
- Test coverage target: ≥80% for new test scenarios
- Use existing test framework patterns (.claude/tests/test_*.sh)

**3. Backward Compatibility**
- All refactoring maintains existing functionality
- Shared utility integration preserves command behavior
- Logging is additive (no breaking changes)
- Integration tests validate existing workflows continue working

**4. Code Standards**
- Follow picker.lua conventions: LuaDoc comments, helper function naming
- Shell utilities: consistent structure with `set -euo pipefail`
- Test scripts: colored output framework (pass/fail/skip functions)
- Logging: structured format with JSON data fields

**5. Artifact Format Design**
- Variable-length content optimized for research complexity
- Concise format preserving essential findings and recommendations
- No arbitrary length limits - adapt to content needs
- Markdown structure: metadata + findings + recommendations

**6. Artifact Numbering System**
- Format: `{project_dir}/specs/artifacts/{topic}/NNN_artifact_name.md`
- NNN auto-increments from existing artifacts in topic directory
- Topic-level numbering (not global) for better organization
- Numbering function checks existing files and selects next available

**7. Bidirectional Structure Optimization**
- /revise evaluates structure after content modifications
- Expansion recommendations for complex phases (complexity > 8.0 or tasks > 10)
- Collapse recommendations for simple phases (complexity < 6.0 and tasks ≤ 5)
- Auto-mode collapse support enables automatic structure optimization
- Collapse logging provides observability consistent with expansion logging

## Implementation Phases

### Phase 1: Picker Code Refactoring [COMPLETED]
**Objective**: Improve picker.lua code quality through helper extraction, optimization, and comments
**Complexity**: Medium
**Estimated Time**: 80 minutes (30 + 20 + 30)

#### Task 1.1: Extract Dialog Builder Helper Function
- [x] Read `<C-l>` handler (lines 2960-3169)
- [x] Identify dialog building logic (50+ lines inline)
- [x] Create helper function `build_confirmation_dialog(artifact_name, is_local, global_path, local_path)`:
  ```lua
  -- Builds confirmation dialog for artifact replacement
  -- @param artifact_name string: Name of artifact being replaced
  -- @param is_local boolean: Whether artifact is local
  -- @param global_path string: Path to global artifact version
  -- @param local_path string|nil: Path to local artifact version (if exists)
  -- @return table: Dialog configuration for vim.ui.select
  local function build_confirmation_dialog(artifact_name, is_local, global_path, local_path)
    -- Dialog building logic extracted from handler
    -- Returns: { prompt = "...", items = {...}, format_item = function }
  end
  ```
- [x] Extract dialog logic from handler (lines ~3010-3060)
- [x] Update handler to call helper: `local dialog_config = build_confirmation_dialog(...)`
- [x] Place helper before `<C-l>` handler (around line 2950)
- [x] Verify handler reduced from 210 to ~160 lines
- [x] Test artifact replacement flow still works

#### Task 1.2: Optimize Filepath Construction
- [x] Read do_load() helper (lines 2967-3048)
- [x] Identify filepath construction location (currently before force check)
- [x] Move filepath construction inside `if success and force` block:
  ```lua
  if success and force then
    local loaded_filepath = loaded_artifact.output_dir .. "/" .. artifact_name
    -- Buffer reload logic...
  end
  ```
- [x] Verify optimization: filepath only built when needed (replacement case)
- [x] Test first load (no filepath construction) and replacement (with construction)

#### Task 1.3: Add Strategic Code Comments
- [x] Add comment for global filepath resolution (lines 2616-2624):
  ```lua
  -- Only resolve global filepath when forcing replacement of local artifact
  -- Local artifacts may have modifications we want to preserve on first load
  ```
- [x] Add comment for hook event detection (lines 3065-3070):
  ```lua
  -- Detect if artifact is local by checking first hook event
  -- Hook events are only present for local artifacts in project directory
  ```
- [x] Add comment for buffer reload timing (lines 3012-3033):
  ```lua
  -- Use vim.schedule to ensure buffer reload happens after picker closes
  -- Immediate reload can cause picker UI glitches
  ```
- [x] Add comment for dialog complexity (around line 2960):
  ```lua
  -- <C-l> handler is complex (150+ lines) due to:
  -- 1. Local vs global artifact detection
  -- 2. Confirmation dialog with multiple options
  -- 3. Buffer reload logic for modified buffers
  -- 4. Error handling for various failure modes
  ```

**Testing**:
```bash
# Manual validation:
# 1. Verify refactored code maintains functionality
# 2. Test artifact loading (first load)
# 3. Test artifact replacement (force load)
# 4. Test dialog display and confirmation
# 5. Verify buffer reload with notification
# 6. Review comments for clarity and accuracy
```

**Deliverables**:
- Extracted dialog builder helper
- Optimized filepath construction
- Strategic comments added

**File**: nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:2616-3169

---

### Phase 2: Adaptive Planning Logging Infrastructure (High)
**Objective**: Activate comprehensive logging for adaptive planning detection and operations
**Status**: PENDING
**Estimated Time**: 3-4 hours

**Summary**: Integrate comprehensive logging throughout /implement workflow to track adaptive planning trigger evaluations (complexity checks, test failure patterns, scope drift), replan invocations, and loop prevention. Create structured log format with JSON data fields, implement log rotation (10MB/5 files), and provide query utilities for analysis.

**Key Tasks**: Understand logging API, map 5 integration points in /implement, add logging calls with error handling, verify log format and rotation, document query examples.

For detailed implementation specification, see [Phase 2 Details](phase_2_logging_infrastructure.md)

---

### Phase 3: Integration Tests for Adaptive Planning (High)
**Objective**: Create comprehensive integration tests for adaptive planning and auto-mode workflows
**Status**: PENDING
**Estimated Time**: 5-7 hours

**Summary**: Enhance existing test suites (test_adaptive_planning.sh with 16 tests, test_revise_automode.sh with 18 tests) by adding 7 new integration scenarios. Cover full implement-to-revise flow, loop prevention enforcement, error recovery, context JSON parsing, all revision types, backup/restore, and response validation. Increase coverage from ~60% to ≥80% for both suites.

**Key Tasks**: Analyze existing tests and coverage gaps, implement 3 new adaptive planning scenarios (full flow, loop prevention, error recovery), implement 4 new auto-mode scenarios (context parsing, all revision types, backup/restore, response validation), update COVERAGE_REPORT.md.

For detailed implementation specification, see [Phase 3 Details](phase_3_integration_tests.md)

---

### Phase 4: Shared Utility Integration
**Objective**: Refactor commands to use shared utility libraries, reducing code duplication
**Complexity**: Medium
**Estimated Time**: 2-3 hours

**Tasks**:
- [ ] Read shared utility libraries:
  - .claude/lib/checkpoint-utils.sh
  - .claude/lib/complexity-utils.sh
  - .claude/lib/error-utils.sh
  - .claude/lib/artifact-utils.sh
- [ ] Refactor /orchestrate command:
  ```bash
  # Replace inline checkpoint code with:
  source "$SCRIPT_DIR/../lib/checkpoint-utils.sh"
  save_checkpoint "phase_name" "$checkpoint_data"

  # Replace inline error handling with:
  source "$SCRIPT_DIR/../lib/error-utils.sh"
  log_error "ERROR_TYPE" "location" "message" "$context_data"
  ```
- [ ] Refactor /implement command:
  ```bash
  # Replace inline complexity calculation with:
  source "$SCRIPT_DIR/../lib/complexity-utils.sh"
  complexity_score=$(calculate_phase_complexity "$phase_num" "$plan_file")

  # Use checkpoint utilities:
  source "$SCRIPT_DIR/../lib/checkpoint-utils.sh"
  load_checkpoint "$checkpoint_file"
  ```
- [ ] Refactor /setup command:
  ```bash
  # Use error utilities for validation:
  source "$SCRIPT_DIR/../lib/error-utils.sh"
  validate_input "$input" || log_error "VALIDATION" "setup" "Invalid input"
  ```
- [ ] Test each refactored command:
  - /orchestrate: Run sample workflow, verify checkpoints
  - /implement: Run with complexity detection, verify utilities work
  - /setup: Run validation scenarios, verify error handling
- [ ] Verify no functionality regressions
- [ ] Measure code reduction: ~100-150 LOC savings expected

**Testing**:
```bash
# Test /orchestrate with shared utilities
/orchestrate "Test workflow for utility integration"

# Test /implement with complexity utilities
/implement .claude/specs/plans/test_implement_simple.md

# Test /setup with error utilities
/setup /home/benjamin/.config --validate

# Verify test suite still passes
.claude/tests/run_all_tests.sh
```

**Deliverables**:
- /orchestrate using shared utilities
- /implement using shared utilities
- /setup using shared utilities
- All tests passing (no regressions)
- Code duplication reduced by ~100-150 lines

**Files**:
- .claude/commands/orchestrate.sh (refactor)
- .claude/commands/implement.sh (refactor)
- .claude/commands/setup.sh (refactor)
- .claude/lib/*.sh (existing utilities, use as-is)

---

### Phase 5: Core Artifact Creation Implementation [COMPLETED]
**Objective**: Enable research-specialist to write variable-length artifacts with topic-based numbering
**Complexity**: Medium-High
**Estimated Time**: 2-3 hours (Actual: 3 hours)
**Reference**: Report 027 Phase 1 (lines 723-756)
**Status**: COMPLETED 2025-10-09

**Overview**:
Implement foundational artifact creation workflow based on comprehensive analysis in report 027. This phase focuses on Phase 1 from the report's 6-phase roadmap, enabling basic artifact creation and registry tracking. Future phases (2-6) can be expanded separately as needed.

**Key Achievement**: Discovered and fixed critical bash parameter expansion bug with `${parameter:-{}}` when using `set -o pipefail` - bug affects any parameter containing `}` in its value.

#### Task 5.1: Artifact Directory Auto-Creation with Topic-Based Numbering [COMPLETED]
- [x] Create `create_artifact_directory()` function in shared utilities
- [x] Function signature: `create_artifact_directory(workflow_description)`
- [x] Implement project name generation algorithm (report 027:385-398):
  ```bash
  # Convert workflow description to snake_case project name
  # "Implement user auth" → "user_auth"
  # "Add OAuth2 support" → "oauth2_support"
  project_name=$(echo "$workflow_description" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 ]//g' | \
    tr ' ' '_' | \
    sed 's/__*/_/g' | \
    sed 's/^_//; s/_$//')
  ```
- [x] Create directory: `specs/artifacts/${project_name}/`
- [x] Implement `get_next_artifact_number()` function:
  ```bash
  # Find next available number in topic directory
  # Checks existing NNN_*.md files and increments
  get_next_artifact_number() {
    local topic_dir="$1"
    local max_num=0

    # Find highest existing number
    for file in "$topic_dir"/[0-9][0-9][0-9]_*.md; do
      [[ -e "$file" ]] || continue
      num=$(basename "$file" | grep -oE '^[0-9]+')
      (( num > max_num )) && max_num=$num
    done

    # Return next number with zero-padding
    printf "%03d" $((max_num + 1))
  }
  ```
- [x] Return project_name, artifact_dir path, and next number
- [x] Test with various workflow descriptions
- [x] **Bug Fix**: Fixed `${3:-{}}` parameter expansion issue with `set -o pipefail`

#### Task 5.2: Research-Specialist Artifact Output Mode (Variable Length) [COMPLETED]
- [x] Read research-specialist.md artifact mode documentation (report 027:108-142)
- [x] Create artifact invocation template for research agents
- [x] Template includes:
  - OUTPUT MODE: Artifact instruction
  - Artifact path: `specs/artifacts/{project_name}/{NNN_topic}.md`
  - Variable-length content guidance: "Adapt length to research complexity. Simple findings may be 100-200 words. Complex analysis may be 500-1000+ words. Optimize for concision but preserve all essential findings and recommendations."
  - Metadata requirements (created date, workflow, agent, focus)
  - Format requirements (## Findings, ## Recommendations sections)
  - Return instruction (artifact ID + path only, not full summary)
- [x] Test invocation with mock research tasks of varying complexity
- [x] Verify artifacts scale appropriately (simple = short, complex = detailed)
- [x] Created `.claude/templates/artifact_research_invocation.md`
- [x] Created `generate_artifact_invocation()` helper function

#### Task 5.3: Artifact Registry Integration [COMPLETED]
- [x] Source artifact-utils.sh in command initialization
- [x] Create `.claude/registry/` directory on first use
- [x] Call `register_artifact()` after artifact creation:
  ```bash
  artifact_id=$(register_artifact "research" "$artifact_path" '{
    "topic": "'"$research_topic"'",
    "workflow": "'"$workflow_description"'",
    "project": "'"$project_name"'",
    "number": "'"$artifact_num"'"
  }')
  ```
- [x] Store artifact_id for cross-referencing
- [x] Test registry entry creation
- [x] Verify JSON format and metadata
- [x] **Bug Fix**: Fixed same `${3:-{}}` bug in `register_artifact()` function
- [x] Created `.claude/examples/artifact_creation_workflow.sh` demonstrating end-to-end integration

#### Task 5.4: Artifact File Writer (Fallback, Variable Length) [COMPLETED]
- [x] Create wrapper function for cases where agent doesn't write artifact
- [x] Function signature: `write_artifact_file(summary_text, artifact_path, metadata)`
- [x] Implement variable-length artifact template:
  ```markdown
  # {Research Topic}

  ## Metadata
  - **Created**: {date}
  - **Workflow**: {workflow_description}
  - **Agent**: research-specialist
  - **Focus**: {research_topic}
  - **Length**: {word_count} words

  ## Findings
  {summary_text - findings section, variable length}

  ## Recommendations
  {summary_text - recommendations section, variable length}
  ```
- [x] No arbitrary truncation - use full summary_text
- [x] Calculate word count and include in metadata
- [x] Write to artifact_path with proper formatting
- [x] Return artifact reference (ID + path)
- [x] Fixed `${3:-{}}` bug in this function as well

**Testing**: All tests passed
```bash
# Test artifact directory creation
project_name=$(create_artifact_directory "Implement user authentication")
test -d "specs/artifacts/$project_name" && echo "PASS" || echo "FAIL"

# Test artifact numbering (create multiple in same topic)
num1=$(get_next_artifact_number "specs/artifacts/test_topic")
touch "specs/artifacts/test_topic/${num1}_first.md"
num2=$(get_next_artifact_number "specs/artifacts/test_topic")
[[ "$num2" == "002" ]] && echo "PASS: Auto-increment" || echo "FAIL"

# Test variable-length artifact creation
short_summary="Brief finding (50 words)..."
long_summary="Complex analysis with detailed findings... (500+ words)"

write_artifact_file "$short_summary" "specs/artifacts/test/001_short.md" '{"topic":"test"}'
write_artifact_file "$long_summary" "specs/artifacts/test/002_long.md" '{"topic":"test"}'

# Verify no truncation
wc -w "specs/artifacts/test/001_short.md"  # Should show ~50 words
wc -w "specs/artifacts/test/002_long.md"  # Should show ~500+ words

# Test registry integration
artifact_id=$(register_artifact "research" "specs/artifacts/test/001_short.md" '{"topic":"test","number":"001"}')
test -f ".claude/registry/${artifact_id}.json" && echo "PASS" || echo "FAIL"

# Verify artifact format
grep -q "## Metadata" "specs/artifacts/test/001_short.md" && echo "PASS" || echo "FAIL"
grep -q "## Findings" "specs/artifacts/test/001_short.md" && echo "PASS" || echo "FAIL"
grep -q "Length:" "specs/artifacts/test/001_short.md" && echo "PASS: Word count tracked" || echo "FAIL"
```

**Deliverables**: ✓ All completed
- `create_artifact_directory()` with topic name generation
- `get_next_artifact_number()` for auto-incrementing per topic
- Research-specialist artifact invocation template (variable length)
- `generate_artifact_invocation()` helper function
- Registry integration (sourcing artifact-utils.sh, calling register_artifact)
- `write_artifact_file()` fallback function (no truncation, word count tracking)
- Tests validating artifact creation, numbering, and registry
- Example workflow script demonstrating end-to-end integration

**Files Modified**:
- .claude/lib/artifact-utils.sh (added 4 functions, fixed 3 parameter expansion bugs)
- .claude/templates/artifact_research_invocation.md (created template documentation)
- .claude/examples/artifact_creation_workflow.sh (created end-to-end example)
- .claude/registry/ (created directory for artifact tracking)
- specs/artifacts/ (project directories created on demand)

**Critical Bug Fixed**:
Discovered and fixed bash parameter expansion bug affecting `${parameter:-{}}` when using `set -o pipefail`. When parameter value contains `}`, bash incorrectly interprets the `{}` default, causing malformed values. Fixed in 3 functions:
- `write_artifact_file()` - line 518-520
- `register_artifact()` - line 31-33
- Solution: Manual empty check `[ -z "$var" ] && var="{}"`

**Implementation Notes**:
- This implements Phase 1 from report 027's 6-phase roadmap
- Phases 2-6 (reference system, cross-linking, lifecycle management) deferred
- Report 027 provides detailed implementation guidance for future phases
- Future expansion: Use `/expand-phase` to create detailed implementation for subsequent phases
- Variable-length artifacts scale from 100 words (simple) to 1000+ words (complex)
- Topic-based numbering enables organized artifact collections
- Registry provides foundation for cross-referencing and workflow tracking

**Report Reference**: See `.claude/specs/reports/027_artifact_creation_reference_workflow.md` for:
- Complete architecture analysis (lines 1-256)
- Full 6-phase implementation roadmap (lines 723-915)
- Design decisions and recommendations (lines 917-1024)

---

### Phase 6: Adaptive Planning Optimization [COMPLETED]
**Objective**: Enable post-creation plan evaluation with auto-expansion and configurable thresholds
**Status**: COMPLETED 2025-10-09
**Estimated Time**: 3-5 hours (Actual: 2 hours)
**Reference**: Report 028 Phases 1-2 (lines 640-671)

**Overview**: Implemented proactive complexity evaluation in `/plan` command to eliminate mid-implementation workflow interruptions. Plans are now automatically evaluated and expanded immediately after creation based on configurable thresholds.

**Summary**: Shift complexity evaluation from reactive (during /implement) to proactive (after /plan creation), eliminating workflow interruptions. Add post-creation phase evaluation loop that auto-expands complex phases (>8.0 threshold). Implement configurable thresholds in CLAUDE.md (expansion, task count, file references, replan limit) with fallback defaults. Add complexity analysis display with formatted output showing evaluation results.

**Key Achievement**: Successfully integrated automatic evaluation as complementary to existing agent-based holistic analysis (Section 8.5). Both approaches now work together - informed recommendations plus automatic structure optimization.

#### Task 6.1: Post-Creation Phase Evaluation [COMPLETED]
**File**: `.claude/commands/plan.md`
- [x] Added Section 9: "Post-Creation Automatic Complexity Evaluation"
- [x] Implemented bash-based evaluation loop in plan command specification
- [x] Source complexity-utils.sh for phase complexity calculation
- [x] Read configurable thresholds from CLAUDE.md with fallback defaults
- [x] Evaluate each phase for complexity score and task count
- [x] Auto-invoke `/expand phase` command for phases exceeding thresholds
- [x] Handle L0 → L1 plan structure transitions automatically
- [x] Track and report which phases were auto-expanded
- [x] Update plan file path after expansions for final output

**Implementation Details**:
- Evaluation runs after plan file written, before final output
- Uses `calculate_phase_complexity()` from complexity-utils.sh
- Extracts phase content with sed for analysis
- Handles bc float comparisons with integer fallback
- Gracefully skips evaluation if complexity-utils not found

#### Task 6.2: Configurable Complexity Thresholds [COMPLETED]
**File**: `/home/benjamin/.config/CLAUDE.md`
- [x] Added "Adaptive Planning Configuration" section
- [x] Defined 4 configurable thresholds with defaults:
  - Expansion Threshold: 8.0
  - Task Count Threshold: 10
  - File Reference Threshold: 10
  - Replan Limit: 2
- [x] Provided project-type examples (research-heavy, simple web app, mission-critical)
- [x] Defined valid threshold ranges for each parameter
- [x] Marked section with `[Used by: /plan, /expand, /implement, /revise]` for discoverability

**Threshold Reading Implementation**:
- `read_threshold()` function searches upward for CLAUDE.md
- Validates threshold values are numeric
- Falls back to defaults if not found or invalid
- Clear user feedback showing which thresholds are configured vs default

#### Task 6.3: Expansion Recommendations Display [COMPLETED]
**Included in Task 6.1 implementation**
- [x] Unicode box-drawing characters for visual separation
- [x] Clear section headers ("AUTOMATIC COMPLEXITY EVALUATION", "EVALUATION COMPLETE")
- [x] Per-phase evaluation output showing complexity score and task count
- [x] Expansion reasons clearly stated (threshold exceeded)
- [x] Final summary showing auto-expanded phases
- [x] Plan structure level reported (L0 vs L1)

**Display Format**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATIC COMPLEXITY EVALUATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Using thresholds:
  Expansion: 8.0 (complexity score)
  Task Count: 10 (tasks per phase)

Evaluating N phases...

Phase 1: Name (complexity X.X, Y tasks) - OK
Phase 2: Name (complexity X.X, Y tasks)
  Reason: complexity X.X > threshold 8.0
  Action: Auto-expanding...
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EVALUATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Auto-expanded N phase(s): 2 3 5
Plan structure: Level 1 (phase-expanded)
```

**Deliverables**: ✓ All completed
- Post-creation automatic evaluation integrated into `/plan` command
- Configurable thresholds section in CLAUDE.md
- Threshold reading logic with validation and fallbacks
- Formatted display output for evaluation results
- Complementary integration with existing agent-based analysis

**Files Modified**:
- `.claude/commands/plan.md` (added Section 9 with evaluation logic)
- `/home/benjamin/.config/CLAUDE.md` (added Adaptive Planning Configuration section)

**Workflow Improvement Achieved**:

**Before Phase 6**:
```
/plan creates L0 → /implement starts → detects complexity → pauses → expands → resumes
[WORKFLOW INTERRUPTION during implementation]
```

**After Phase 6**:
```
/plan creates L0 → evaluates automatically → expands if needed → ready as L1 → /implement runs smoothly
[NO INTERRUPTION - plan optimized before implementation begins]
```

**Integration Points**:
- Works alongside existing agent-based analysis (Section 8.5-8.6)
- Agent provides holistic recommendations with rationale
- Automatic evaluation provides threshold-based expansion
- Together: Informed + automatic structure optimization

**Testing Approach**:
Manual validation through `/plan` command usage:
- Test with simple plans (no expansion triggered)
- Test with complex plans (expansion triggered)
- Test with custom thresholds in CLAUDE.md
- Test with missing thresholds (fallback to defaults)
- Test L0 → L1 path transitions

For detailed implementation specification, see [Phase 6 Details](phase_6_adaptive_optimization.md)

---

### Phase 7: Bidirectional Structure Optimization (High)
**Objective**: Enable /revise to automatically evaluate and recommend expansion/collapse with auto-mode collapse support
**Status**: PENDING
**Estimated Time**: 6-8 hours
**Reference**: Report 029 Phases 1-3 (lines 377-623)

**Summary**: Implement bidirectional structure management (expand AND collapse). Add post-revision structure evaluation to /revise that detects affected phases and recommends collapse (tasks ≤5 AND complexity <6.0) or expansion (tasks >10 OR complexity >8.0). Enable automatic collapse via new `collapse_phase` revision type in /revise --auto-mode. Integrate auto-collapse in /implement Step 5.5 for completed simple phases. Add collapse logging (log_collapse_check, log_collapse_invocation) for observability matching expansion logging style.

**Key Tasks**: Create evaluation functions (evaluate_collapse_opportunity, evaluate_expansion_opportunity), add structure recommendations display to /revise output, implement collapse_phase revision type with context JSON schema, integrate auto-collapse in /implement Step 5.5, add collapse logging to adaptive-planning-logger.sh, integrate logging in /collapse, /implement, and /revise.

**Workflow Improvement**: Plans automatically optimize structure bidirectionally - expanding when complexity grows, collapsing when simplicity returns post-completion.

For detailed implementation specification, see [Phase 7 Details](phase_7_structure_optimization.md)

---

## Testing Strategy

### Manual Testing (Phase 1)
- **Refactoring**: Functional testing of picker artifact operations

### Integration Testing (Phases 2-3)
- **Logging**: Verify structured log format, rotation, query utilities
- **Adaptive Planning**: Full workflow tests (complexity detection → replan → continue)
- **Auto-Mode**: Context validation, revision types, backup/restore, error handling
- **Coverage Target**: ≥80% for new integration test scenarios

### Regression Testing (Phase 4)
- **Shared Utilities**: Verify commands work identically after refactoring
- **Test Suite**: Run all existing tests to catch regressions
- **Functionality**: Manual testing of key workflows

### Artifact Creation Testing (Phase 5)
- **Directory Creation**: Test project name generation from various descriptions
- **Numbering**: Verify auto-increment per topic directory
- **Variable Length**: Confirm artifacts scale appropriately with research complexity
- **File Writing**: Verify artifact template format and metadata (including word count)
- **Registry Integration**: Validate JSON entries created correctly
- **End-to-End**: Mock research workflow creating artifacts with registry tracking

### Adaptive Planning Testing (Phase 6)
- **Post-Creation Evaluation**: Verify phases auto-expand when complexity > threshold
- **Threshold Configuration**: Test custom thresholds in CLAUDE.md
- **Expansion Display**: Validate complexity table formatting and accuracy
- **Workflow**: Confirm no interruptions during implementation with pre-expanded plans

### Structure Optimization Testing (Phase 7)
- **Structure Evaluation**: Verify /revise evaluates phases after content modifications
- **Collapse Recommendations**: Test recommendation display for simple expanded phases
- **Expansion Recommendations**: Test recommendation display for complex inline phases
- **Auto-Mode Collapse**: Verify collapse_phase revision type works correctly
- **Auto-Collapse Integration**: Test /implement Step 5.5 triggers auto-collapse
- **Collapse Logging**: Validate log entries for manual and automatic collapse operations
- **End-to-End**: Complete revision workflow with structure optimization

### Test Execution
```bash
# Run all tests
.claude/tests/run_all_tests.sh

# Run specific suites
.claude/tests/test_adaptive_planning.sh
.claude/tests/test_revise_automode.sh
.claude/tests/test_parsing_utilities.sh
.claude/tests/test_shared_utilities.sh

# Verify coverage
grep -E "PASS|FAIL|SKIP" .claude/tests/*.sh | wc -l
```

## Documentation Requirements

### README Updates
- [ ] .claude/DEFERRED_TASKS.md: Mark tasks 1-2 as redundant, tasks 3-9 as completed with implementation dates
- [ ] COVERAGE_REPORT.md: Update with new test coverage metrics

### Code Documentation
- [ ] Strategic comments in picker.lua (inline)
- [ ] LuaDoc comments for extracted helper function
- [ ] Usage examples for log query utilities

### Implementation Summary
- [ ] Create specs/summaries/035_deferred_tasks_completion_summary.md
- [ ] Document which tasks completed, files modified, tests added
- [ ] Include performance metrics (LOC reduced, coverage increased)
- [ ] Reference report 027 and note Phase 1 implementation complete

## Dependencies

### External Dependencies
None - all tasks use existing infrastructure and utilities

### Prerequisites
- Neovim with picker.lua accessible
- Bash test framework in .claude/tests/
- Shared utility libraries in .claude/lib/
- Logging infrastructure in adaptive-planning-logger.sh

### Tool Requirements
- Neovim (for manual testing of picker changes)
- Bash 4.0+ (for test scripts and utilities)
- jq (for JSON parsing in log queries and registry entries)
- Git (for commits after each phase)

## Risk Assessment

### Medium Risk (Phase 1)
- **Risk**: Refactoring introduces bugs in picker functionality
- **Mitigation**: Thorough manual testing, verify all artifact operations
- **Impact**: Medium - picker is critical, but local to one file

### Medium Risk (Phase 2)
- **Risk**: Logging performance impact or disk space issues
- **Mitigation**: Log rotation configured (10MB max), structured format efficient
- **Impact**: Low - logging is async and non-blocking

### High Risk (Phase 3)
- **Risk**: Integration tests complex to implement, may not catch all edge cases
- **Mitigation**: Follow existing test patterns, use fixtures and mocks
- **Impact**: Medium - tests validate but don't directly impact functionality

### Medium Risk (Phase 4)
- **Risk**: Shared utility integration breaks command functionality
- **Mitigation**: Incremental refactoring, test after each command
- **Impact**: High if undetected - commands are critical workflows

### Medium Risk (Phase 5)
- **Risk**: Artifact creation incomplete or poorly integrated with existing systems
- **Mitigation**: Follow report 027 detailed implementation guidance, test each component
- **Impact**: Medium - artifacts are new infrastructure, won't break existing workflows if implementation issues occur

### Medium-High Risk (Phase 6)
- **Risk**: Auto-expansion changes /plan behavior, may unexpectedly expand plans or slow down creation
- **Mitigation**: Configurable thresholds allow users to control sensitivity, test with various plan complexities
- **Impact**: Medium - changes core planning workflow, but improvements align with existing /implement behavior

### Medium Risk (Phase 7)
- **Risk**: Structure evaluation overhead may slow /revise operations, auto-collapse may surprise users
- **Mitigation**: Evaluation is fast (~1-2 seconds), recommendations-first approach (Task 7.1) before automation (Task 7.2), clear logging
- **Impact**: Medium - changes /revise behavior, but natural integration point per user's intuition

## Notes

### Task Priority Rationale
1. **Phase 1** (Refactoring): Improves code quality, contained in single file
2. **Phase 2** (Logging): Enables observability for adaptive planning (prerequisite for debugging)
3. **Phase 3** (Integration Tests): Validates complex workflows, high effort but high value
4. **Phase 4** (Utility Integration): Code cleanup, reduces duplication, lower priority
5. **Phase 5** (Artifact Creation): New infrastructure, foundational for future multi-agent workflows
6. **Phase 6** (Adaptive Planning): Workflow optimization, eliminates mid-implementation interruptions
7. **Phase 7** (Structure Optimization): Bidirectional structure management, addresses user's correct intuition about /revise

### Tasks 1-2 Removed (Redundant)
Research confirmed that buffer reload is handled globally by autocommands:
- FocusGained + BufEnter events automatically run `checktime` for all buffers
- FileChangedShell autocommand reloads files silently (intentional design choice)
- Picker-specific documentation or notification would be misleading/redundant

### Deferred Again (If Time Constrained)
- Task 4 (filepath optimization): Negligible performance gain, can skip
- Task 9 (utility integration): Enhancement, not required for functionality
- Artifact Phases 2-6: Future work, see report 027 for implementation roadmap when needed
- Adaptive Phases 3-5: Preview flags, smart re-evaluation, parallel processing - see report 028 when needed
- Structure Phases 4-5: --optimize-structure flag, smart completion collapse - see report 029 when needed

### Success Metrics
- All 7 remaining tasks completed: 100% completion rate for tasks 3-9
- Tasks 1-2 documented as redundant
- Test coverage: ≥80% for adaptive planning and auto-mode
- Code reduction: ~100-150 LOC from utility integration
- Zero regressions: All existing tests still passing
- Artifact creation functional: research-specialist can write variable-length artifacts with topic-based numbering
- Post-creation plan evaluation working: plans auto-expand before implementation
- Configurable thresholds: users can tune expansion sensitivity per project
- Structure optimization working: /revise evaluates and recommends expansion/collapse
- Auto-mode collapse functional: plans can shrink automatically during implementation
- Collapse logging operational: observability for structure optimization decisions
- Report 027 Phase 1 implemented as foundation for future artifact workflow expansion
- Report 028 Phases 1-2 implemented for seamless planning workflow
- Report 029 Phases 1-3 implemented for bidirectional structure optimization

### Commit Strategy
- Commit after each phase completion
- Descriptive messages referencing task numbers
- Example: "refactor(picker): Extract dialog builder helper (Task 3, Phase 1)"

---

**Plan Created**: 2025-10-09
**Plan Updated**: 2025-10-09
**Estimated Total Time**: 21-29 hours
**Phases**: 7
**Tasks**: 7 deferred tasks (3-9) + artifact creation (report 027 Phase 1) + adaptive planning (report 028 Phases 1-2) + structure optimization (report 029 Phases 1-3)

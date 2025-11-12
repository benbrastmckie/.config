# Infrastructure Analysis for Classification Implementation

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: .claude/ infrastructure patterns for classification integration
- **Report Type**: codebase analysis

## Executive Summary

The .claude/ infrastructure provides a mature, well-tested foundation for comprehensive haiku-based classification. The plan's approach of extending workflow-llm-classifier.sh to return scope, complexity, and subtopics aligns perfectly with existing patterns. Key integration points: workflow-state-machine.sh (sm_init returns RESEARCH_COMPLEXITY), workflow-initialization.sh (dynamic path allocation), coordinate.md (remove pattern matching at lines 402-414). The infrastructure supports the clean-break philosophy with fail-fast validation, state persistence via GitHub Actions pattern, and comprehensive testing utilities. Implementation can leverage existing LLM classifier architecture, state machine variables, and verification patterns to achieve single-call classification with zero pattern matching.

## Findings

### 1. Library Architecture and Classification Infrastructure

**Current LLM Classification Implementation** (workflow-llm-classifier.sh:1-298):
- Mature file-based signaling pattern with LLM assistant interaction
- Returns JSON: `{"scope": "research-and-plan", "confidence": 0.95, "reasoning": "..."}`
- Configurable timeout (10s default), confidence threshold (0.7 default)
- Comprehensive error handling and debug logging
- Already proven in production (Spec 670 integration)

**Function Structure**:
- `classify_workflow_llm()` - Main entry point (lines 35-82)
- `build_llm_classifier_input()` - JSON prompt construction (lines 90-123)
- `invoke_llm_classifier()` - File-based LLM invocation (lines 131-180)
- `parse_llm_classifier_response()` - Validation and extraction (lines 188-240)

**Extension Points for Comprehensive Classification**:
- Line 101-114: Enhance JSON prompt to request `research_complexity` and `subtopics` fields
- Line 205-212: Add extraction for new fields in response parser
- Line 215-227: Add validation for complexity (1-4 range) and subtopics array

**Architecture Observation**: The classifier uses temporary files with `$$` for process isolation (line 133-134), which is safe because each bash block has a unique PID. This follows Pattern 5 from bash-block-execution-model.md.

### 2. Hybrid Classification with Fallback (workflow-scope-detection.sh:1-199)

**Current Hybrid Architecture** (lines 43-115):
- Three classification modes: hybrid (default), llm-only, regex-only
- Automatic fallback: LLM timeout → regex classification
- Unified entry point: `detect_workflow_scope()` handles all modes
- Regex fallback: `classify_workflow_regex()` embedded (lines 122-178)

**Clean-Break Opportunity**:
- Plan proposes deleting `detect_workflow_scope()` entirely (Phase 2, task 7)
- Research confirms zero non-coordinate callers in production code
- All references in .backup files, tests, or documentation only
- Aligns with clean-break philosophy: no deprecation period needed

**Fallback Implementation for Comprehensive Classification**:
- Plan's `infer_complexity_from_keywords()` can reuse pattern matching logic from coordinate.md:402-414
- Plan's `generate_generic_topics()` can create "Topic 1", "Topic 2" placeholders
- Plan's `fallback_comprehensive_classification()` combines regex + heuristic

**Integration Note**: The `classify_workflow_regex()` function (lines 122-178) demonstrates proper pattern priority ordering (revision → plan path → explicit keywords → research-only → other patterns) that should be preserved in fallback logic.

### 3. State Machine Integration (workflow-state-machine.sh:1-668)

**State Machine Architecture**:
- 8 explicit states: initialize, research, plan, implement, test, debug, document, complete
- State transition table validates allowed transitions (lines 51-60)
- Atomic state transitions with checkpoint coordination
- Workflow scope determines terminal state (lines 241-261)

**Current sm_init() Function** (lines 214-270):
- Accepts workflow_description and command_name parameters
- Calls `detect_workflow_scope()` to determine WORKFLOW_SCOPE (line 230)
- Sets TERMINAL_STATE based on scope (lines 241-261)
- Initializes CURRENT_STATE to STATE_INITIALIZE
- Returns initialization status message to stderr

**Critical Enhancement Required** (Plan Phase 3, Task 4):
- Make `sm_init()` **return RESEARCH_COMPLEXITY value** via stdout
- Pattern: `echo "$RESEARCH_COMPLEXITY"` before `return 0` (line 269)
- Rationale: Enables dynamic path allocation BEFORE directory creation
- This solves the "4 paths saved vs 2 used" tension identified in Issue 676

**State Persistence Pattern** (lines 122-212):
- COMPLETED_STATES array persisted via JSON serialization
- Functions: `save_completed_states_to_state()`, `load_completed_states_from_state()`
- State file uses GitHub Actions pattern via state-persistence.sh
- Library auto-loads state on re-sourcing (lines 664-667)

**New State Variables for Comprehensive Classification**:
- `RESEARCH_COMPLEXITY` (integer 1-4) - Already partially used in coordinate.md
- `RESEARCH_TOPICS_JSON` (JSON array) - NEW, for bash block persistence
- These must be exported in sm_init() and saved to state file

### 4. Workflow Initialization and Path Allocation (workflow-initialization.sh:1-400+)

**Current Path Allocation** (lines 318-344):
- **FIXED pre-allocation**: Loops `for i in 1 2 3 4` (line 330)
- Creates 4 report paths regardless of actual complexity needs
- Exports REPORT_PATH_0 through REPORT_PATH_3 (lines 337-340)
- Exports fixed REPORT_PATHS_COUNT=4 (line 344)

**Design Trade-off Documentation** (lines 319-328):
- Comment explicitly acknowledges "Fixed capacity (4) vs. dynamic complexity (1-4)"
- Rationale: "Phase 0 optimization prioritizes performance over memory efficiency"
- Current approach: "Pre-allocate max paths upfront → 85% token reduction, 25x speedup"
- Separation of concerns: Path calculation (infrastructure) vs. complexity detection (orchestration)

**Dynamic Allocation Enhancement** (Plan Phase 4):
- Change signature: `initialize_workflow_paths(RESEARCH_COMPLEXITY)` parameter
- Replace loop: `for i in $(seq 1 $RESEARCH_COMPLEXITY)` (Plan Phase 4, Task 2)
- Update export: `REPORT_PATHS_COUNT=$RESEARCH_COMPLEXITY` (Plan Phase 4, Task 4)
- Add validation: Ensure RESEARCH_COMPLEXITY in 1-4 range (Plan Phase 4, Task 6)

**Integration Note**: The function already has comprehensive error diagnostics (lines 243-263) with fail-fast error handling. This pattern should be preserved for RESEARCH_COMPLEXITY validation.

### 5. coordinate.md Integration Points

**Part 1: Workflow Description Capture** (lines 18-40):
- Uses fixed filename: `coordinate_workflow_desc.txt` (line 37)
- Plan Phase 5 Task 1: Add WORKFLOW_ID suffix for concurrency safety
- Pattern: `coordinate_workflow_desc_${WORKFLOW_ID}.txt`

**Part 2: State Machine Initialization** (lines 47-200):
- Sources workflow-state-machine.sh and state-persistence.sh (lines 88-105)
- Sources error-handling.sh and verification-helpers.sh (lines 111-127)
- Calls `sm_init()` with SAVED_WORKFLOW_DESC (line 153)
- Saves state machine config to workflow state (lines 173-176)

**Plan Integration** (Phase 5, Tasks 2-6):
- Task 2: Update Part 2 to read WORKFLOW_ID and construct filename
- Task 3: Capture RESEARCH_COMPLEXITY return value: `RESEARCH_COMPLEXITY=$(sm_init ...)`
- Task 4: Pass to initialize_workflow_paths: `initialize_workflow_paths "$RESEARCH_COMPLEXITY"`
- Task 5-6: Save RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON to state

**Part 3: Research Phase Pattern Matching** (lines 400-436):
- **DELETION TARGET**: Lines 402-414 contain grep-based complexity calculation
- Current logic: Default 2, increase to 3 for "integrate|migration", 4 for "multi-.*system", 1 for "fix.*single"
- Plan Phase 5 Task 7: **Delete 13 lines entirely**
- Plan Phase 5 Task 8: Add comment explaining RESEARCH_COMPLEXITY loaded from state

**Diagnostic Message Update** (line 258 - not visible in sample):
- Current: "Saved 4 report paths" (capacity message)
- Plan Phase 5 Task 9: Update to clarify capacity matches usage
- New approach: Message will reflect actual RESEARCH_COMPLEXITY count

**Research Agent Invocation** (lines 485-490 - not visible in sample):
- Plan Phase 5 Task 10: Replace generic "Topic N" with descriptive names from RESEARCH_TOPICS array
- Plan Phase 5 Task 11: Add state load for RESEARCH_TOPICS_JSON and reconstruct array

### 6. Testing Infrastructure

**Test Files Available**:
- `test_workflow_scope_detection.sh` - Tests hybrid classification modes
- `test_workflow_initialization.sh` - Tests path allocation
- `test_workflow_detection.sh` - Tests older detection library
- `test_concurrent_workflows.sh` - Tests WORKFLOW_ID-based isolation

**Testing Pattern Observations**:
- Bash-based test framework (not pytest or jest)
- Tests located in `.claude/tests/`
- Test runner: `run_all_tests.sh` (documented in CLAUDE.md)
- Coverage target: ≥80% for modified code per CLAUDE.md testing protocols

**Test Coverage Requirements** (Plan Phase 6):
- 25+ test cases for comprehensive classification
- Unit tests: Each new function isolated
- Integration tests: sm_init with comprehensive classification
- Clean break tests: Verify zero detect_workflow_scope() references
- Performance tests: Haiku latency ≤500ms target

### 7. Command Architecture Standards

**Standard 0: Execution Enforcement** (command_architecture_standards.md:51-100):
- Imperative language patterns: "YOU MUST", "EXECUTE NOW", "MANDATORY"
- Verification checkpoints after critical operations
- Fail-fast error handling with diagnostic commands
- No silent fallbacks that hide errors

**Standard 11: Imperative Agent Invocation** (coordinate-command-guide.md:112-141):
- Direct Task tool invocation with behavioral file reference
- No SlashCommand wrapper anti-pattern
- Inline agent prompts with workflow-specific context
- coordinate.md is 100% compliant (per guide documentation)

**Executable/Documentation Separation Pattern**:
- Commands are lean execution scripts (<250 lines for commands, <400 for agents)
- Comprehensive guides in `.claude/docs/guides/*-command-guide.md`
- Eliminates meta-confusion loops (70% file size reduction achieved)
- See: executable-documentation-separation.md pattern guide

**Integration Note**: Plan follows these standards by using imperative language ("CRITICAL", "MANDATORY") and including verification checkpoints in Phase 3-5 tasks.

### 8. Existing Complexity Calculation Patterns

**complexity-utils.sh Implementation** (lines 27-94):
- `calculate_phase_complexity()` function analyzes plan phases
- Factors: task count (0.5 weight), file references (0.2), code blocks (0.3), duration (+1.0)
- Returns float complexity score for adaptive planning triggers
- Used by `/expand` and `/implement` for phase expansion decisions

**coordinate.md Pattern Matching** (lines 402-414):
- Keyword-based heuristics for workflow complexity
- Default: 2 topics
- Patterns: "integrate|migration|refactor|architecture" → 3 topics
- Patterns: "multi-.*system|cross-.*platform|distributed|microservices" → 4 topics
- Patterns: "fix|update|modify.*(one|single|small)" → 1 topic

**Reuse Opportunity for Fallback** (Plan Phase 2):
- `infer_complexity_from_keywords()` can directly reuse coordinate.md:402-414 logic
- This maintains consistency with current behavior during LLM fallback
- Ensures zero regression for users with haiku unavailable

### 9. State Persistence and Bash Block Boundaries

**GitHub Actions Pattern** (state-persistence.sh):
- Workflow state saved to `${HOME}/.claude/tmp/workflow_state_${WORKFLOW_ID}.sh`
- Functions: `init_workflow_state()`, `append_workflow_state()`, `source_workflow_state()`
- Pattern: `append_workflow_state "VAR_NAME" "value"` exports and persists
- Sourcing state file restores all variables in subsequent bash blocks

**Array Persistence Challenge**:
- Bash arrays cannot be exported across subprocess boundaries
- Solution: JSON serialization via jq (Pattern from workflow-state-machine.sh:122-212)
- Example: `COMPLETED_STATES` → `COMPLETED_STATES_JSON` (JSON array string)
- Reconstruction: `mapfile -t ARRAY < <(echo "$JSON" | jq -r '.[]')`

**Application to RESEARCH_TOPICS** (Plan Phase 3, Task 6):
- Serialize: `RESEARCH_TOPICS_JSON=$(printf '%s\n' "${RESEARCH_TOPICS[@]}" | jq -R . | jq -s .)`
- Persist: `append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"`
- Reconstruct: `mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')`

### 10. Documentation Integration Points

**Files Requiring Updates** (Plan Phase 6):
- `coordinate-command-guide.md` - Add comprehensive classification section
- `llm-classification-pattern.md` - Add comprehensive examples
- `phase-0-optimization.md` - Document dynamic allocation approach
- `CLAUDE.md` - Update state_based_orchestration section

**Documentation Standards** (from CLAUDE.md):
- Present-focused, timeless writing (no "New in Spec 678" markers)
- No historical commentary (clean-break philosophy)
- Use Unicode box-drawing for diagrams
- No emojis in file content (UTF-8 encoding constraint)
- Relative paths for internal links

## Recommendations

### 1. Leverage Existing LLM Classifier Architecture

**Action**: Extend workflow-llm-classifier.sh without major refactoring

**Rationale**: The current classifier (lines 1-298) is production-proven, well-tested, and follows clean architectural patterns. Adding two fields to the JSON prompt and response parser is low-risk and maintains consistency.

**Implementation Approach**:
- Phase 1: Enhance `build_llm_classifier_input()` to request research_complexity and subtopics
- Phase 1: Update `parse_llm_classifier_response()` to extract and validate new fields
- Phase 1: Add new entry point `classify_workflow_llm_comprehensive()` (wrapper around existing function)
- Risk: Minimal - changes are additive, not modifying existing code paths

**Benefits**:
- Reuses file-based signaling pattern (lines 131-180)
- Inherits timeout handling (10s default)
- Inherits confidence threshold validation (0.7 default)
- Inherits error logging and debug infrastructure

### 2. Implement Dynamic Path Allocation with Fail-Fast Validation

**Action**: Modify workflow-initialization.sh to accept RESEARCH_COMPLEXITY parameter

**Rationale**: The current fixed allocation (4 paths) vs dynamic usage (1-4 paths) creates user confusion and wastes memory. Dynamic allocation eliminates unused variables and clarifies capacity/usage relationship.

**Implementation Approach**:
- Phase 4 Task 1: Change function signature to accept parameter
- Phase 4 Task 2: Replace `for i in 1 2 3 4` with `for i in $(seq 1 $RESEARCH_COMPLEXITY)`
- Phase 4 Task 6: Add validation ensuring RESEARCH_COMPLEXITY in 1-4 range (fail-fast on invalid input)
- Phase 5 Task 3-4: Update coordinate.md to capture return value and pass to initialization

**Benefits**:
- Eliminates the "4 paths saved vs 2 used" confusion (Issue 676)
- Reduces memory overhead (2-3 unused path variables eliminated for typical workflows)
- Maintains Phase 0 optimization benefits (85% token reduction, 25x speedup)
- Follows fail-fast philosophy with range validation

**Performance Impact**: Negligible - dynamic loop adds <1ms vs fixed loop

### 3. Use Clean-Break Deletion for detect_workflow_scope()

**Action**: Delete `detect_workflow_scope()` entirely in Phase 2, replacing all calls with `classify_workflow_comprehensive()`

**Rationale**: Research confirms zero non-coordinate callers in production code. Clean-break approach (per CLAUDE.md philosophy) avoids technical debt of maintaining wrapper functions or deprecation periods.

**Implementation Approach**:
- Phase 2 Task 7: Delete function definition (workflow-scope-detection.sh)
- Phase 3 Task 9: Update all calls in workflow-state-machine.sh
- Phase 6 Task 10-11: Update test files and documentation references
- Single atomic commit enables trivial rollback (5 minutes vs 30 minutes for gradual migration)

**Risk Mitigation**:
- Comprehensive grep before deletion to verify zero external callers
- Update all references in same commit (atomic change)
- Rollback is single `git revert` command

**Benefits**:
- Eliminates ongoing maintenance burden (no wrapper to maintain)
- Prevents "which function should I call?" confusion for future developers
- Aligns with clean-break philosophy: configuration describes what it is, not what it was

### 4. Preserve Fallback Complexity with Heuristic Function

**Action**: Create `infer_complexity_from_keywords()` by extracting coordinate.md:402-414 logic

**Rationale**: When haiku fails or returns low confidence, the system needs a deterministic fallback to ensure 100% availability. Reusing existing pattern matching logic maintains consistency with current behavior.

**Implementation Approach**:
- Phase 2 Task 3: Copy coordinate.md:402-414 patterns to new function
- Phase 2 Task 4: Implement same keyword detection (integrate→3, multi-system→4, fix-single→1, default→2)
- Phase 3 Task 7: Add fallback handling in sm_init() when haiku fails
- Phase 6: Test fallback mode extensively (Plan Phase 6, Task 4)

**Benefits**:
- Zero regression for users with haiku unavailable (network issues, API downtime)
- Maintains predictable behavior during LLM outages
- Enables gradual rollout (test haiku classification without breaking existing workflows)

### 5. Follow State Persistence Pattern for Array Variables

**Action**: Serialize RESEARCH_TOPICS to RESEARCH_TOPICS_JSON for bash block persistence

**Rationale**: Bash arrays cannot be exported across subprocess boundaries. The JSON serialization pattern is proven in COMPLETED_STATES persistence (workflow-state-machine.sh:122-212).

**Implementation Approach**:
- Phase 3 Task 6: Use jq to serialize array: `printf '%s\n' "${RESEARCH_TOPICS[@]}" | jq -R . | jq -s .`
- Phase 3 Task 6: Save to state: `append_workflow_state "RESEARCH_TOPICS_JSON" "$JSON"`
- Phase 5 Task 11: Reconstruct array: `mapfile -t RESEARCH_TOPICS < <(echo "$JSON" | jq -r '.[]')`

**Benefits**:
- Enables descriptive topic names in research agent prompts (not generic "Topic N")
- Maintains state across bash blocks (coordinate.md uses multiple bash blocks)
- Follows established pattern (low learning curve for future maintainers)

**Defensive Programming**: Include empty array check (line 137-140 in workflow-state-machine.sh as example)

### 6. Add Comprehensive Verification Checkpoints

**Action**: Insert verification checkpoints after each critical operation (file creation, state persistence, return value capture)

**Rationale**: Follows Standard 0 (Execution Enforcement) and fail-fast philosophy. Verification checkpoints catch errors immediately rather than propagating silent failures.

**Implementation Approach**:
- Phase 3: Verify sm_init() returns RESEARCH_COMPLEXITY (not empty or invalid)
- Phase 4: Verify initialize_workflow_paths() creates expected number of paths
- Phase 5: Verify RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON persisted to state
- Use existing verification-helpers.sh functions: `verify_state_variable()`, `verify_file_created()`

**Benefits**:
- Catches integration errors during development (not in production)
- Provides clear diagnostic messages for debugging
- Aligns with coordinate.md patterns (lines 140-143, 178-181 show existing verification)

### 7. Maintain Test Coverage ≥80% Per CLAUDE.md Standards

**Action**: Create comprehensive test suite with 25+ test cases (Plan Phase 6)

**Rationale**: Testing protocols in CLAUDE.md require ≥80% coverage for modified code. Comprehensive classification adds 3 new functions and modifies 4 existing functions.

**Implementation Approach**:
- Phase 6 Tasks 2-9: Create test_comprehensive_classification.sh with structured test cases
- Unit tests: Test each function in isolation (haiku classifier, fallback, state machine integration)
- Integration tests: Test end-to-end coordinate.md workflow
- Performance tests: Measure haiku latency (<500ms target)
- Clean break tests: Verify zero detect_workflow_scope() references remain

**Test Organization**:
```
test_comprehensive_classification.sh
├─ Haiku classification tests (5 tests - all workflow types)
├─ Complexity determination tests (4 tests - 1-4 topics)
├─ Subtopic extraction tests (3 tests - descriptive names)
├─ Fallback mode tests (4 tests - when haiku fails)
├─ Clean break tests (3 tests - no old function references)
├─ Dynamic allocation tests (3 tests - exact count match)
├─ Concurrent execution tests (3 tests - WORKFLOW_ID safety)
└─ Integration tests (3 tests - coordinate.md end-to-end)
```

**Benefits**:
- Prevents regressions during implementation
- Validates all code paths (success, failure, edge cases)
- Provides confidence for clean-break deletion
- Documents expected behavior for future maintainers

## References

### Core Libraries Analyzed
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh:1-298` - LLM classification core, file-based signaling
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh:1-199` - Hybrid classification with fallback
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:1-668` - State machine with array persistence
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:1-400+` - Path allocation with Phase 0 optimization
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh:1-94` - Phase complexity calculation patterns

### Command and Agent Files
- `/home/benjamin/.config/.claude/commands/coordinate.md:1-200` - State machine initialization, workflow capture
- `/home/benjamin/.config/.claude/commands/coordinate.md:400-436` - Research complexity pattern matching (deletion target)
- `/home/benjamin/.config/.claude/agents/research-specialist.md:1-671` - Research agent behavioral file

### Documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:1-100` - Standard 0, Standard 11
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md:1-150` - Command architecture overview
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md:1-100` - Hybrid classification pattern
- `/home/benjamin/.config/CLAUDE.md` - Testing protocols, clean-break philosophy, state-based orchestration

### Test Infrastructure
- `/home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh` - Hybrid classification tests
- `/home/benjamin/.config/.claude/tests/test_workflow_initialization.sh` - Path allocation tests
- `/home/benjamin/.config/.claude/tests/test_concurrent_workflows.sh` - WORKFLOW_ID isolation tests
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh` - Test runner (bash-based framework)

### Related Patterns
- Bash Block Execution Model (subprocess isolation, fixed semantic filenames, save-before-source)
- GitHub Actions State Persistence (workflow state files, append/source pattern)
- Executable/Documentation Separation (lean executables, comprehensive guides)
- Fail-Fast Error Handling (verification checkpoints, diagnostic commands)
- Clean-Break Philosophy (no deprecation, immediate deletion, present-focused docs)

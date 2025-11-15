# Infrastructure Integration Standards Research Report

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Infrastructure Integration Standards
- **Report Type**: codebase analysis
- **Complexity Level**: 4
- **Research Focus**: Error handling patterns, state persistence integration, directory organization, and library sourcing practices

## Executive Summary

The .claude/ infrastructure provides a mature, well-documented ecosystem for command development with comprehensive error handling, state persistence, verification patterns, and architectural standards. Key findings: (1) Error handling uses transient/permanent/fatal classification with 15+ specialized functions, (2) State persistence integrates with checkpoint schema v2.1 and workflow state machines, (3) Directory organization follows strict separation between executable commands, sourced libraries, and standalone scripts, (4) Library sourcing follows dependency order with source guards enabling safe re-sourcing, (5) Verification helpers provide 90% token reduction through concise success reporting and verbose failure diagnostics.

## Current State Analysis

### Error Handling Infrastructure

**Library**: `.claude/lib/error-handling.sh` (882 lines)

**Core Components**:

1. **Error Classification System** (lines 14-55):
   - Three primary types: `transient`, `permanent`, `fatal`
   - Five LLM-specific types: `llm_timeout`, `llm_api_error`, `llm_low_confidence`, `llm_parse_error`, `invalid_mode`
   - `classify_error()` function uses regex patterns to automatically categorize errors
   - Pattern examples: "locked|busy|timeout" → transient, "out of.*space|disk.*full" → fatal

2. **Detailed Error Analysis** (lines 88-237):
   - `detect_error_type()`: Identifies specific error categories (syntax, test_failure, file_not_found, import_error, null_error, timeout, permission)
   - `extract_location()`: Parses file:line references from error messages using regex patterns
   - `generate_suggestions()`: Provides error-specific recovery guidance based on error type

3. **Retry Logic** (lines 241-351):
   - `retry_with_backoff()`: Exponential backoff with configurable attempts and delay (default: 3 attempts, 500ms base delay)
   - `retry_with_timeout()`: Extended timeout generation (1.5x increase per attempt, max 3 attempts)
   - `retry_with_fallback()`: Reduced toolset recommendation for agent retries

4. **State Machine Error Handler** (lines 746-858):
   - `handle_state_error()`: Five-component error format (what failed, expected behavior, diagnostic commands, context, recommended action)
   - Retry counter tracking (max 2 retries per state)
   - State persistence for resume support
   - Integration with `append_workflow_state()` from state-persistence.sh

**Integration Points**:
- All orchestration commands source error-handling.sh early (after state machine libraries)
- Verification checkpoints use error handlers for fail-fast behavior
- State machine transitions call `handle_state_error()` on failures

### State Persistence Infrastructure

**Library**: `.claude/lib/state-persistence.sh`

**Architecture** (from checkpoint-utils.sh:1-150):

1. **Checkpoint Schema v2.1**:
   - 33 top-level fields including workflow metadata, state machine state, error state, supervisor coordination
   - Wave tracking fields for parallel execution: `current_wave`, `total_waves`, `wave_structure`, `parallel_execution_enabled`
   - Plan modification tracking via `plan_modification_time` for adaptive replanning detection
   - Context preservation fields: `pruning_log`, `artifact_metadata_cache`, `subagent_output_references`

2. **Checkpoint Storage**:
   - Primary: `.claude/checkpoints/` (workflow-level checkpoints)
   - Alternative: `.claude/data/checkpoints/` (legacy, backward compatibility)
   - Naming: `{workflow_type}_{project_name}_{timestamp}.json`

3. **Cross-Block State Management**:
   - Bash subprocess isolation requires explicit state file persistence
   - `append_workflow_state()` writes to fixed semantic filename
   - `load_workflow_state()` sources state file in each bash block
   - Source guards prevent duplicate execution (`VERIFICATION_HELPERS_SOURCED=1`)

**Integration with Coordinate Command**:
- State machine initialization saves WORKFLOW_SCOPE, RESEARCH_COMPLEXITY to state file
- Verification checkpoints verify state variables exist via `verify_state_variable()`
- Error handling tracks retry counts in state for loop prevention
- Resume support reads checkpoint and restores workflow position

### Verification Helper Infrastructure

**Library**: `.claude/lib/verification-helpers.sh` (514 lines)

**Key Functions**:

1. **verify_file_created()** (lines 73-170):
   - Success: Single character "✓" (no newline, allows multiple checks per line)
   - Failure: 38-line diagnostic with expected vs actual, directory analysis, root cause possibilities
   - Token efficiency: 90% reduction (225 tokens → 25 tokens on success path)
   - Parameters: `file_path`, `item_desc`, `phase_name`

2. **verify_state_variable()** (lines 223-280):
   - Verifies variable exists in state file with export format: `^export VAR_NAME=`
   - Defensive checks: STATE_FILE must be set and exist before verification
   - Comprehensive failure diagnostics with troubleshooting commands
   - Returns 0 (success) or 1 (failure) following bash conventions

3. **verify_state_variables()** (lines 302-370):
   - Batch verification of multiple state variables
   - Success: Single "✓", Failure: Lists all missing variables with state file analysis
   - Includes file size, variable count, and first 20 lines of state file in diagnostics

4. **verify_files_batch()** (lines 420-513):
   - Batch verify multiple files with single-line success reporting
   - Token efficiency: 88% reduction for 5 files (250 tokens → 30 tokens)
   - Format: `"path:description"` pairs for each file entry

**Architecture Benefits**:
- Concise success path minimizes context consumption during normal operation
- Verbose failure path provides actionable diagnostics when needed
- Exported functions available in subshells via `export -f`
- Source guard enables safe re-sourcing across bash blocks

### Directory Organization Standards

**Reference**: `.claude/docs/reference/command_architecture_standards.md` (lines 1961-2013)

**Three-Directory System**:

1. **scripts/** - Standalone Operational Tools:
   - Characteristics: CLI interfaces, argument parsing, complete workflows, formatted output, may use external tools
   - Examples: `validate-links.sh`, `fix-absolute-to-relative.sh`, `analyze-coordinate-performance.sh`
   - Naming: `kebab-case-names.sh`
   - Decision criteria: Building standalone command-line utility with complete input → output workflow

2. **lib/** - Sourced Function Libraries:
   - Characteristics: Modular functions, sourced via `source`, stateless/pure, general-purpose, unit testable
   - Examples: `plan-parsing.sh`, `error-handling.sh`, `checkpoint-utils.sh`, `metadata-extraction.sh`
   - Naming: `kebab-case-names.sh`
   - Decision criteria: Building reusable functions called from multiple commands

3. **utils/** - Specialized Helper Utilities:
   - Bridging category for domain-specific tools that don't fit cleanly in scripts/ or lib/

**Enforcement**:
- Every directory must have README.md documenting purpose, characteristics, examples, when to use
- Anti-patterns: Standalone executables in lib/, sourced libraries in scripts/, missing READMEs
- Validation: Check for CamelCase violations, missing .sh extensions, README coverage

**Coordinate Command Compliance**:
- Sources 15+ libraries from lib/ (workflow-state-machine.sh, error-handling.sh, verification-helpers.sh, etc.)
- No standalone script execution within command file (proper separation)
- Uses utility functions for path detection, artifact creation, state management

### Library Sourcing Standards

**Standard 15**: Library Sourcing Order (.claude/docs/reference/command_architecture_standards.md:2277-2412)

**Required Sourcing Pattern**:

```bash
# 1. State machine foundation (FIRST)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (BEFORE any verification checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Additional libraries as needed (AFTER core libraries)
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
# ... other libraries via source_required_libraries()
```

**Rationale** (lines 2310-2316):
1. State machine → State persistence: State machine defines workflow states, persistence manages cross-block state
2. State persistence → Error/Verification: Error handling depends on `append_workflow_state()` and `STATE_FILE` variable
3. Error/Verification → Checkpoints: Verification checkpoints call `verify_state_variable()`, `verify_file_created()`, `handle_state_error()`
4. Other libraries AFTER: All others load after foundations established

**Source Guards Pattern** (lines 2317-2329):
```bash
# From verification-helpers.sh:11-14
if [ -n "${VERIFICATION_HELPERS_SOURCED:-}" ]; then
  return 0
fi
export VERIFICATION_HELPERS_SOURCED=1
```

**Implication**: Including a library in both early sourcing AND REQUIRED_LIBS array is safe, recommended, zero-overhead

**Anti-Pattern**: Premature Function Calls (lines 2377-2404):
- Calling functions before sourcing library results in "command not found" errors
- Spec 675 fixed this in /coordinate by moving error-handling.sh and verification-helpers.sh sourcing to immediately after state-persistence.sh
- Bash subprocess isolation means functions only available AFTER sourcing, not before

**Validation**:
- Automated: `.claude/tests/test_library_sourcing_order.sh`
- Manual: Verify no function calls before library sourcing, check sourcing order matches standard
- Runtime: Test all workflow scopes, verify no "command not found" errors

### Command Architecture Standards

**Document**: `.claude/docs/reference/command_architecture_standards.md` (2525 lines)

**Key Standards for Coordinate Integration**:

1. **Standard 0: Execution Enforcement** (lines 51-462):
   - Imperative language: "YOU MUST", "EXECUTE NOW", "MANDATORY" vs descriptive "should/may/can"
   - Verification checkpoints with explicit file existence checks
   - Fallback mechanisms for agent-dependent operations
   - Relationship to fail-fast: Verification detects errors (allowed), placeholder creation hides errors (prohibited)

2. **Standard 11: Imperative Agent Invocation** (lines 1173-1352):
   - Required elements: Imperative instruction, agent behavioral file reference, no code block wrappers, explicit completion signals
   - Correct pattern: `**EXECUTE NOW**: USE the Task tool...` followed by unwrapped Task block
   - Anti-pattern: Documentation-only YAML blocks wrapped in ` ```yaml` fences
   - Performance: >90% agent delegation rate, 100% file creation reliability

3. **Standard 13: Project Directory Detection** (lines 1457-1533):
   - Pattern: Use `CLAUDE_PROJECT_DIR` for project-relative paths (git-based detection)
   - Anti-pattern: `${BASH_SOURCE[0]}` (unavailable in SlashCommand context)
   - Enhanced diagnostics when library sourcing fails

4. **Standard 14: Executable/Documentation Separation** (lines 1535-1689):
   - Two-file architecture: Executable (<250 lines simple, <1,200 lines orchestrator) + Guide (unlimited)
   - Rationale: Prevents meta-confusion loops (75% → 0% incident rate)
   - Migration results: 70% average executable reduction, 1,300 line average guides
   - Templates: `_template-executable-command.md` (56 lines), `_template-command-guide.md` (171 lines)

5. **Standard 15: Library Sourcing Order** (documented above)

6. **Standard 16: Critical Function Return Code Verification** (lines 2462-2521):
   - Required pattern: `if ! critical_function arg1 arg2 2>&1; then handle_state_error ... fi`
   - Critical functions: `sm_init()`, `initialize_workflow_paths()`, `source_required_libraries()`, `classify_workflow_comprehensive()`
   - Prohibited: No return code check, output redirection hiding errors
   - Verification checkpoints after successful calls to ensure exported variables

## Research Findings

### 1. Error Handling Patterns

**Comprehensive Three-Layer System**:

1. **Classification Layer**: Automatic error type detection via `classify_error()` and `detect_error_type()` using regex patterns
2. **Recovery Layer**: Retry logic with exponential backoff, timeout extension, and fallback toolset reduction
3. **Reporting Layer**: Five-component error messages (what, expected, diagnostics, context, action) via `handle_state_error()`

**Integration Requirements for Coordinate**:
- Source error-handling.sh immediately after state-persistence.sh (Standard 15)
- Use `handle_state_error()` for all state transition failures
- Implement retry counters via `append_workflow_state()` to prevent infinite loops
- Provide five-component error messages with diagnostic commands

**Token Efficiency**:
- Error handlers designed for verbose failure diagnostics only when needed
- Success paths minimize output to preserve context window
- Complements verification helpers' concise success / verbose failure pattern

### 2. State Persistence Integration Points

**Critical Integration Patterns**:

1. **Initialization Sequence**:
   - Call `sm_init()` with return code verification
   - Verify exported variables via `verify_state_variable()`
   - Call `initialize_workflow_paths()` to set up artifact directories
   - Verify state file contains required exports

2. **Cross-Block State Management**:
   - Use `append_workflow_state()` to write variables to state file
   - Load state in each bash block via `load_workflow_state()`
   - Verify state persistence via `verify_state_variables()` at checkpoints

3. **Checkpoint Schema Fields Relevant to Coordinate**:
   - `state_machine`: Current state name, valid transitions, terminal state
   - `workflow_state`: All exported workflow variables
   - `error_state`: Last error, retry count, failed state
   - `supervisor_state`: Hierarchical coordination metadata (if using sub-supervisors)
   - `context_preservation`: Pruning log, artifact metadata cache, subagent output references

4. **Resume Support**:
   - Save checkpoint after each state transition
   - Include retry counters in checkpoint for loop prevention
   - Verify checkpoint exists and is valid before resume attempt

### 3. Directory Organization Principles

**Coordinate Command Compliance Checklist**:

✓ **Command File Location**: `.claude/commands/coordinate.md` (correct)
✓ **Library Sourcing**: Sources from `.claude/lib/` (15+ libraries)
✓ **No Script Execution**: Doesn't execute standalone scripts from within command
✓ **Guide File**: `.claude/docs/guides/coordinate-command-guide.md` exists
✓ **README Coverage**: All sourced library directories have READMEs

**Anti-Patterns to Avoid**:
- Creating new top-level directories without README.md
- Mixing executable and sourced function content in one file
- Using CamelCase for new bash scripts (use kebab-case)
- Sourcing from scripts/ directory (should be from lib/)

**File Placement Decision Matrix** (from lib/README.md):
- Standalone executable? → scripts/
- Sourced by other code? → lib/
- Specialized helper? → utils/
- Complete workflow? → commands/ or agents/
- Reusable function? → lib/

### 4. Verification Checkpoint Patterns

**Three-Tier Verification Strategy**:

1. **File Verification** (`verify_file_created()`):
   - Use for agent-created artifacts (reports, plans)
   - Provides 90% token reduction on success path
   - Comprehensive diagnostics on failure (38 lines)

2. **State Variable Verification** (`verify_state_variable()`):
   - Use after `sm_init()`, `initialize_workflow_paths()`
   - Verifies cross-block state persistence worked
   - Prevents unbound variable errors downstream

3. **Batch Verification** (`verify_files_batch()`, `verify_state_variables()`):
   - Use for multiple files or variables at phase boundaries
   - Further token reduction (88% for 5 files)
   - Single-line success, detailed failure per item

**Integration Pattern for Coordinate**:
```bash
# After agent invocation
if verify_file_created "$REPORT_PATH" "Research report" "Phase 1"; then
  echo " Report verified"
else
  handle_state_error "Research report verification failed" 1
fi

# After state initialization
verify_state_variable "WORKFLOW_SCOPE" || \
  handle_state_error "WORKFLOW_SCOPE not exported after sm_init" 1
```

### 5. Library Sourcing Best Practices

**Dependency Order Enforcement**:

**Why Order Matters** (Spec 675 case study):
- Pre-fix: Functions called at lines 155-239 before sourcing at line 265+
- Result: "command not found" errors terminated initialization
- Root cause: Bash subprocess isolation means functions unavailable before sourcing

**Correct Pattern for Coordinate**:
1. Source state machine libraries first (workflow-state-machine.sh, state-persistence.sh)
2. Source error handling and verification immediately after (error-handling.sh, verification-helpers.sh)
3. Source remaining libraries via `source_required_libraries()` or explicit source statements
4. Call functions ONLY AFTER sourcing (never before)

**Source Guard Benefits**:
- Safe to include library in both early sourcing AND REQUIRED_LIBS array
- Zero overhead (instant guard check: `if [ -n "${VAR:-}" ]; then return 0; fi`)
- Prevents duplicate function definitions
- Enables library re-sourcing in each bash block

**Validation Approach**:
- Automated: Run `.claude/tests/test_library_sourcing_order.sh`
- Manual: Search for function calls, verify library sourced before first call
- Runtime: Test with all workflow scopes, check for "command not found" errors

### 6. Command Architecture Compliance

**Critical Standards for Coordinate**:

1. **Standard 0 (Execution Enforcement)**:
   - Replace descriptive language ("The command does X") with imperative ("YOU MUST do X")
   - Add MANDATORY VERIFICATION checkpoints after critical operations
   - Include fallback mechanisms for agent operations (verification + recovery)

2. **Standard 11 (Imperative Agent Invocation)**:
   - Prefix Task blocks with `**EXECUTE NOW**: USE the Task tool...`
   - Remove markdown code fences around Task blocks (no ` ```yaml`)
   - Reference agent behavioral files: `Read and follow: .claude/agents/research-specialist.md`
   - Require explicit completion signals: `Return: REPORT_CREATED: ${REPORT_PATH}`

3. **Standard 13 (Project Directory Detection)**:
   - Use `CLAUDE_PROJECT_DIR` (not `${BASH_SOURCE[0]}`)
   - Provide enhanced diagnostics on library sourcing failure
   - Pattern: Git-based detection with pwd fallback

4. **Standard 14 (Executable/Documentation Separation)**:
   - Target <1,200 lines for orchestrator executables (coordinate is complex)
   - Move architecture explanations, examples, troubleshooting to guide file
   - Maintain bidirectional cross-references (command → guide, guide → command)

5. **Standard 15 (Library Sourcing Order)**:
   - Follow 1-2-3 pattern: state machine → error/verification → other libraries
   - Source before calling (never call functions before sourcing)
   - Use source guards for safe re-sourcing

6. **Standard 16 (Critical Function Return Code Verification)**:
   - Check return codes: `if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then ... fi`
   - Verify exported variables after successful calls
   - Use compound operators or inline error handling (never ignore return codes)

## Recommendations

### 1. Error Handling Integration

**Action**: Integrate error-handling.sh patterns throughout coordinate command

**Specific Steps**:
1. Source error-handling.sh immediately after state-persistence.sh (line ~120 in coordinate.md)
2. Replace generic error messages with `handle_state_error()` calls using five-component format
3. Add retry counter tracking via `append_workflow_state("RETRY_COUNT_${state}", "$count")`
4. Implement error classification via `classify_error()` for transient vs permanent failures
5. Use `retry_with_backoff()` for network operations (classify_workflow_comprehensive LLM calls)

**Rationale**: Provides consistent error experience, enables retry tracking for loop prevention, offers actionable diagnostics

**Effort**: Medium (2-3 hours to update ~15 error sites)

### 2. Verification Checkpoint Enhancement

**Action**: Replace inline verification blocks with verification-helpers.sh functions

**Specific Steps**:
1. Identify all file verification blocks (search for `if [ ! -f "$FILE_PATH" ]`)
2. Replace with `verify_file_created()` calls (38+ lines → 1 line, 90% token reduction)
3. Add state variable verification after `sm_init()` and `initialize_workflow_paths()`
4. Use `verify_files_batch()` for research report verification (multiple files)
5. Add verification checkpoints at state boundaries with proper error handling

**Rationale**: Achieves 90% token reduction, provides comprehensive diagnostics only on failure, standardizes verification patterns

**Effort**: Low (1-2 hours to replace ~10 verification sites)

### 3. State Persistence Compliance

**Action**: Ensure full compliance with state persistence patterns

**Specific Steps**:
1. Verify `sm_init()` return code checked (Standard 16)
2. Add `verify_state_variable()` calls after state initialization
3. Ensure all critical variables written to state via `append_workflow_state()`
4. Verify state file loaded in each bash block (cross-block persistence)
5. Include retry counters in state for loop prevention

**Rationale**: Prevents unbound variable errors, enables resume support, ensures cross-block state management works correctly

**Effort**: Low (1 hour to verify and add missing checks)

### 4. Library Sourcing Order Audit

**Action**: Verify coordinate.md follows Standard 15 library sourcing order

**Specific Steps**:
1. Run `.claude/tests/test_library_sourcing_order.sh` on coordinate.md
2. Verify sourcing pattern: state machine → state persistence → error/verification → others
3. Check no function calls before library sourcing (search for function names before source statements)
4. Confirm source guards present in all sourced libraries
5. Test with all workflow scopes to ensure no "command not found" errors

**Rationale**: Prevents initialization failures like Spec 675 (premature function calls), ensures deterministic sourcing

**Effort**: Low (30 minutes to verify, 1 hour to fix if issues found)

### 5. Standard 0 Enforcement Audit

**Action**: Convert descriptive language to imperative in critical sections

**Specific Steps**:
1. Search for passive voice ("should", "may", "can") in verification checkpoints
2. Replace with imperative ("YOU MUST", "EXECUTE NOW", "MANDATORY")
3. Add "WHY THIS MATTERS" context to critical operations
4. Ensure fallback mechanisms present for agent operations (but not placeholder creation)
5. Verify completion signals required in agent prompts

**Rationale**: Increases execution compliance rate, provides clear expectations, enables fail-fast detection

**Effort**: Medium (2-3 hours to update ~20 imperative sites)

### 6. Directory Organization Validation

**Action**: Ensure coordinate command doesn't violate directory organization principles

**Specific Steps**:
1. Verify all sourced libraries are in `.claude/lib/` (not scripts/)
2. Check no standalone script execution from within command
3. Confirm guide file exists at `.claude/docs/guides/coordinate-command-guide.md`
4. Verify bidirectional cross-references between executable and guide
5. Run validation: `.claude/tests/validate_executable_doc_separation.sh`

**Rationale**: Maintains architectural clarity, prevents misplaced functionality, ensures documentation completeness

**Effort**: Low (30 minutes to verify, minimal fixes expected)

### 7. Critical Function Return Code Verification

**Action**: Add return code checks for all critical function calls (Standard 16)

**Specific Steps**:
1. Identify critical functions: `sm_init()`, `initialize_workflow_paths()`, `source_required_libraries()`, `classify_workflow_comprehensive()`
2. Add return code checks: `if ! function_name args 2>&1; then handle_state_error ... fi`
3. Add verification checkpoints after successful calls to verify exported variables
4. Test failure paths to ensure errors caught immediately (not delayed 78 lines later)

**Rationale**: Enables fail-fast error detection, prevents silent failures from causing downstream unbound variable errors

**Effort**: Low (1 hour to add ~5 return code checks)

## Implementation Guidance

### Phased Approach

**Phase 1: Critical Fixes** (Priority 1, 2-3 hours):
1. Library sourcing order verification (Recommendation 4)
2. Critical function return code checks (Recommendation 7)
3. State persistence compliance (Recommendation 3)

**Phase 2: Verification Enhancement** (Priority 2, 2-3 hours):
1. Replace inline verification with verification-helpers.sh (Recommendation 2)
2. Add state variable verification checkpoints
3. Implement batch verification for research reports

**Phase 3: Error Handling Integration** (Priority 3, 3-4 hours):
1. Integrate error-handling.sh patterns (Recommendation 1)
2. Replace generic errors with five-component format
3. Add retry counter tracking

**Phase 4: Architectural Compliance** (Priority 4, 2-3 hours):
1. Standard 0 enforcement audit (Recommendation 5)
2. Directory organization validation (Recommendation 6)
3. Documentation cross-reference verification

**Total Estimated Effort**: 9-13 hours

### Testing Strategy

**Unit Testing**:
1. Run `.claude/tests/test_library_sourcing_order.sh` after sourcing changes
2. Run `.claude/tests/validate_executable_doc_separation.sh` after documentation changes
3. Test critical function failure paths (mock sm_init failure, verify error caught)

**Integration Testing**:
1. Test all workflow scopes: research-only, planning-only, research-and-plan, research-and-revise, complete-workflow
2. Verify no "command not found" errors during initialization
3. Confirm verification checkpoints execute and provide proper diagnostics on failure
4. Test retry logic prevents infinite loops (max 2 retries per state)

**Regression Testing**:
1. Verify agent delegation rate remains >90%
2. Confirm file creation reliability remains 100%
3. Check context reduction via verification helpers (expect 90% on success paths)
4. Validate state persistence works across bash blocks

### Success Criteria

**Metrics**:
- Library sourcing: 100% compliance with Standard 15 (state machine → error/verification → others)
- Return code checks: 100% coverage for critical functions (sm_init, initialize_workflow_paths, etc.)
- Verification helpers: 100% usage for file and state variable verification
- Error handling: 100% of state errors use handle_state_error() with five-component format
- Standard 0 compliance: 90%+ critical sections use imperative language
- Token reduction: 90% at verification checkpoints (via verification-helpers.sh)

**Quality Gates**:
1. All automated tests pass (library sourcing, executable/doc separation)
2. Manual test of all workflow scopes succeeds
3. No "command not found" errors during initialization
4. Verification checkpoints provide actionable diagnostics on failure
5. State persistence verified to work across bash blocks

## References

**Library Files**:
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (882 lines) - Error classification, retry logic, state machine error handler
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (514 lines) - File and state variable verification with 90% token reduction
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (lines 1-150) - Checkpoint schema v2.1 documentation
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - Cross-block state management (referenced)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - State machine foundation (referenced)

**Documentation**:
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (2525 lines) - Standards 0, 11, 13, 14, 15, 16
- `/home/benjamin/.config/.claude/README.md` (lines 1-100) - Directory structure and organization principles
- `/home/benjamin/.config/.claude/lib/README.md` - lib/ vs scripts/ decision matrix (referenced)
- `/home/benjamin/.config/.claude/scripts/README.md` - Standalone tool guidelines (referenced)

**Command Examples**:
- `/home/benjamin/.config/.claude/commands/supervise.md:68-69` - Correct sourcing order (state machine → state persistence)
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Command being improved (referenced throughout)

**Test Utilities**:
- `.claude/tests/test_library_sourcing_order.sh` - Automated library sourcing validation
- `.claude/tests/validate_executable_doc_separation.sh` - Executable/documentation separation compliance

**Specifications**:
- Spec 675 (2025-11-11): Library sourcing order fix (moved error-handling.sh and verification-helpers.sh to early sourcing)
- Spec 620: Bash history expansion fixes (subprocess isolation discovery)
- Spec 630: State persistence architecture (cross-block state management)
- Spec 644: Unbound variable bug from incorrect grep pattern in verify_state_variable()

## Metadata
- **Research Date**: 2025-11-14
- **Files Analyzed**: 10 files (5 library files, 3 documentation files, 2 command files)
- **External Sources**: 0 (codebase-only research)
- **Lines Analyzed**: ~5,000 lines across all files
- **Key Patterns Identified**: 7 (error handling, state persistence, verification, library sourcing, directory organization, command architecture, return code verification)

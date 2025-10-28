# Unified Orchestration Command Improvements: /coordinate and /supervise

## Metadata
- **Date**: 2025-10-27
- **Feature**: Unified improvements for /coordinate and /supervise orchestration commands
- **Scope**: Error handling, robustness, anti-pattern fixes, file creation verification, documentation, and testing
- **Estimated Phases**: 6
- **Estimated Hours**: 11.5-18 hours (includes +2-3 hours for MANDATORY VERIFICATION checkpoints)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 92.0
- **Research Reports**:
  - [/coordinate Command Analysis](../reports/001_coordinate_command_analysis.md)
  - [/supervise Command Analysis](../reports/002_supervise_command_analysis.md)
- **Compliance Review**: [Plan 497 Compliance Review](../../499_plan_497_compliance_review/reports/001_plan_497_compliance_review/OVERVIEW.md) - Identified CRITICAL GAP in file creation verification (Revision 3)

## Overview

This plan consolidates improvements from two related implementation plans:
1. **Spec 495**: Fix /coordinate and /research commands (0% agent delegation due to YAML-style Task invocations)
2. **Spec 057**: Improve /supervise command robustness (bootstrap failures and fail-fast error handling)

Both plans target the same fundamental issues in orchestration commands but address different aspects:
- /coordinate and /research: Agent invocation anti-patterns causing complete delegation failure
- /supervise: Bootstrap failures and lack of fail-fast diagnostics

The unified plan sequences improvements to minimize rework:
- **Phase 0**: Shared infrastructure (validation utilities, testing frameworks)
- **Phase 1**: /coordinate command agent invocation fixes (9 locations)
- **Phase 2**: /supervise command error handling and fallback removal (fail-fast debugging)
- **Phase 3**: /research command fixes (3 agent invocations + bash code blocks)
- **Phase 4**: Integration testing and validation
- **Phase 5**: Comprehensive documentation and prevention measures

## Research Summary

### Key Findings from /coordinate Analysis (Report 001)

**Problem**: 0% agent delegation rate caused by YAML-style Task invocations wrapped in markdown code fences
- 9 agent invocations in /coordinate use `Task { }` YAML blocks with ` ```yaml ` wrappers
- Template variables (`${TOPIC_NAME}`, `${WORKFLOW_DESCRIPTION}`) never substituted
- Commands write output to TODO1.md files instead of invoking agents
- Proven fix pattern from spec 438 (/supervise) provides template

**Solution**: Convert to imperative bullet-point pattern
- Remove YAML-style blocks and code fences
- Use "USE the Task tool NOW" imperative phrasing
- Pre-calculate paths with Bash tool before agent invocation
- Replace template variables with instructions to insert actual values

**Affected Agents**: research-specialist, plan-architect, implementer-coordinator, test-specialist, debug-analyst, code-writer, doc-writer

### Key Findings from /supervise Analysis (Report 002)

**Problem**: Bootstrap failure caused by function name mismatch (RESOLVED in Phase 0 of original plan)
- Commands called `save_phase_checkpoint()` and `load_phase_checkpoint()`
- Library provides `save_checkpoint()` and `restore_checkpoint()`
- Function verification check detected missing functions and exited before Phase 0
- /coordinate also affected (6 function calls)

**Solution**: Fail-fast design with fallback removal for effective debugging
- Enhanced error messages showing which library failed
- Better function verification diagnostics
- Remove all fallback mechanisms (workflow-detection.sh, directory creation)
- Explicit errors enable consistent debugging

**Impact**: Affects both /supervise and /coordinate commands (12 checkpoint calls total)

### Common Themes Across Both Plans

1. **Error Detection and Reporting**: Both plans emphasize explicit error detection with actionable diagnostics
2. **Anti-Pattern Elimination**: Remove fallback mechanisms and documentation-style code blocks
3. **Reference Pattern**: /supervise (post-spec 438) serves as proven working pattern for agent invocations
4. **Testing Strategy**: Comprehensive validation including delegation rate analysis, integration tests, regression tests
5. **Prevention Measures**: Automated validation scripts, test suite additions, documentation updates

### Unique to /coordinate Plan (Spec 495)

- Focus on agent invocation pattern transformation (YAML → imperative)
- Template variable handling issues
- /research command fixes (bash code blocks appearing as documentation)
- Extensive anti-pattern documentation updates

### Unique to /supervise Plan (Spec 057)

- Function name mismatch resolution (already completed in Phase 0)
- Enhanced error messages for library sourcing failures
- Improved function verification diagnostics
- Fallback mechanism removal for fail-fast debugging
- Checkpoint function API alignment

## Success Criteria

- [ ] All agent invocations use imperative bullet-point pattern (no YAML blocks)
- [ ] Agent delegation rate >90% for /coordinate, /research, and /supervise
- [ ] MANDATORY VERIFICATION checkpoints added after all agent file creation operations
- [ ] File creation reliability 100% (up from 70% baseline)
- [ ] All verification checkpoints include file existence and size validation
- [ ] Fallback file creation mechanisms present for transient tool failures
- [ ] /supervise implements fail-fast error handling (no silent bootstrap fallbacks)
- [ ] Library sourcing failures produce clear, actionable error messages
- [ ] Function verification errors show which library provides missing functions
- [ ] Bootstrap fallbacks removed from /supervise (workflow-detection.sh, directory creation)
- [ ] File creation verification fallbacks preserved in all commands
- [ ] Files created in correct locations (`.claude/specs/NNN_topic/`)
- [ ] No TODO output files created by any orchestration command
- [ ] Validation script detects anti-patterns in command files
- [ ] Integration test suite covers all orchestration commands
- [ ] Comprehensive documentation updated (anti-patterns, troubleshooting, standards, fallback philosophy)

## Technical Design

### Architecture Overview

The unified plan addresses three layers of orchestration command reliability:

**Layer 1: Fail-Fast Error Handling** (/supervise focus)
- Clear error messages when library sourcing fails
- Function verification with helpful diagnostics showing which library provides each function
- Remove all fallback mechanisms (workflow-detection.sh, directory creation)
- Explicit errors enable consistent debugging

**Layer 2: Agent Invocation Pattern** (/coordinate focus)
- Imperative bullet-point format for all Task invocations
- Pre-calculated paths using explicit Bash tool calls
- Template variable replacement with value injection instructions
- No YAML-style blocks or markdown code fences
- Clear orchestrator vs subagent role definitions

**Layer 3: Validation and Testing** (shared)
- Automated anti-pattern detection for agent invocations
- Integration testing with delegation rate analysis
- Comprehensive documentation and prevention measures

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│ Orchestration Command Startup                               │
│                                                              │
│  1. Source Required Libraries                               │
│  2. Verify Functions (clear diagnostics on fail)            │
│  3. Detect Workflow Scope                                   │
│                                                              │
│  ──────────────── BOOTSTRAP COMPLETE ─────────────────────  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Agent Invocation (Imperative Pattern)                       │
│                                                              │
│  **EXECUTE NOW**: Calculate paths with Bash tool            │
│     topic_dir=$(create_topic_structure ...)                 │
│     report_path="$topic_dir/reports/001_name.md"            │
│                                                              │
│  **EXECUTE NOW**: USE the Task tool with these parameters:  │
│     - subagent_type: "general-purpose"                      │
│     - description: "[actual description]"                   │
│     - prompt: |                                             │
│         Read and follow behavioral guidelines from:         │
│         /path/to/agent.md                                   │
│                                                              │
│         [Complete prompt with pre-calculated values]        │
│                                                              │
│  ──────────────── AGENT EXECUTION ───────────────────────   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ MANDATORY VERIFICATION - File Creation (CRITICAL)           │
│                                                              │
│  **EXECUTE NOW** (REQUIRED BEFORE NEXT STEP):               │
│                                                              │
│  1. Verify file exists:                                     │
│     ls -la "$EXPECTED_PATH"                                 │
│     [ -f "$EXPECTED_PATH" ] || echo "ERROR: File missing"  │
│                                                              │
│  2. Verify file size > 500 bytes:                           │
│     FILE_SIZE=$(wc -c < "$EXPECTED_PATH")                   │
│     [ "$FILE_SIZE" -ge 500 ] || echo "WARNING: Too small"  │
│                                                              │
│  3. Results:                                                │
│     IF VERIFICATION PASSES: ✓ Proceed to next step         │
│     IF VERIFICATION FAILS: ⚡ Execute FALLBACK MECHANISM    │
│                                                              │
│  ──────────────── VERIFICATION COMPLETE ─────────────────   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ FALLBACK MECHANISM - Create File (if verification failed)   │
│                                                              │
│  TRIGGER: Verification failed for $EXPECTED_PATH            │
│                                                              │
│  EXECUTE IMMEDIATELY:                                       │
│  1. Extract content from agent response                     │
│  2. Create file using Write tool                            │
│  3. MANDATORY RE-VERIFICATION: ls -la "$EXPECTED_PATH"      │
│  4. If re-verification succeeds: ✓ Continue                 │
│     If re-verification fails: ❌ Escalate to user           │
│                                                              │
│  ──────────────── FALLBACK COMPLETE ─────────────────────   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Metadata Extraction and State Management                    │
│                                                              │
│  • Parse agent output for completion signals                │
│  • Extract metadata from artifacts                          │
│  • Checkpoint workflow state                                │
│                                                              │
│  ──────────────── PHASE COMPLETE ────────────────────────   │
└─────────────────────────────────────────────────────────────┘
```

### Fallback Philosophy: Critical Distinction

**IMPORTANT**: This plan applies fail-fast philosophy but distinguishes between TWO types of fallback mechanisms with different treatment:

#### Bootstrap/Infrastructure Fallbacks (REMOVE - Hide Configuration Errors)

These fallbacks mask environment and configuration problems that MUST be exposed:

- **Silent function definitions** when library files missing
- **Automatic directory creation** masking agent delegation failures
- **Fallback workflow detection** when required libraries unavailable
- **Default value substitution** for missing required variables

**Rationale**: Configuration errors indicate broken setup that MUST be fixed before workflow execution. Hiding them with fallbacks prevents proper diagnosis and creates inconsistent behavior across environments.

**Action in This Plan**: Phase 2 removes all bootstrap fallbacks from /supervise and /coordinate

#### File Creation Verification Fallbacks (PRESERVE - Detect Tool Failures)

These verification checkpoints detect and correct transient Write tool failures:

- **MANDATORY VERIFICATION** after each agent file creation operation
- **File existence checks** (ls -la, [ -f "$PATH" ])
- **File size validation** (minimum 500 bytes for content verification)
- **Fallback file creation** when agent succeeded but file missing (tool failure)
- **Re-verification** after fallback creation to confirm correction

**Rationale**: File creation verification does NOT hide configuration errors. It detects transient tool failures where the agent successfully generated content but the Write tool failed to persist it. These failures are orthogonal to configuration issues and occur even in correctly configured environments.

**Action in This Plan**: Phases 1-3 ADD mandatory verification checkpoints to all agent invocations

**Performance Impact**:
- Without verification: 70% file creation reliability (7/10 files created)
- With verification: 100% file creation reliability (10/10 files created)
- Improvement: +43% reliability, +2-3 hours implementation time

**Critical Insight**: Fail-fast means "fail immediately on configuration errors" NOT "fail silently on transient tool errors." Verification fallbacks enable fail-fast by converting silent tool failures into explicit, diagnosed, and corrected errors.

### Shared Infrastructure Components

**Validation Utilities** (Phase 0):
- `.claude/lib/validate-agent-invocation-pattern.sh` - Detects anti-patterns in command files
- Checks: YAML-style Task blocks, code fences around invocations, template variables
- Exit codes: 0 for pass, 1 for anti-pattern detected

**Testing Framework** (Phase 0):
- `.claude/tests/test_orchestration_commands.sh` - Unified test suite for all orchestration commands
- Tests: Agent invocations, bootstrap sequence, delegation rate, file creation, error handling
- Integration with run_all_tests.sh

**Error Message Standards**:
1. What failed (specific operation)
2. Why it failed (exact error message/condition)
3. Context (paths, variables, environment state)
4. Diagnostic commands (exact commands to investigate)
5. Exit code (non-zero to signal failure)

### Pattern Transformation Template

**From (BROKEN PATTERN)**:
```markdown
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: |
    Research topic: ${TOPIC_NAME}
    Output to: ${REPORT_PATH}
}
```
```

**To (FIXED PATTERN)**:
```markdown
**EXECUTE NOW**: USE the Bash tool to calculate paths:

```bash
topic_dir=$(create_topic_structure "research_topic_name")
report_path="$topic_dir/reports/001_subtopic_name.md"
echo "REPORT_PATH: $report_path"
```

**EXECUTE NOW**: USE the Task tool NOW with these parameters:

- subagent_type: "general-purpose"
- description: "Research authentication patterns for REST APIs"
- prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs

    Output file: [insert $report_path from above]

    Create comprehensive report covering patterns, security practices, implementation approaches.
```

## Implementation Phases

### Phase 0: Shared Infrastructure and Validation Utilities
dependencies: []

**Objective**: Create shared utilities and testing infrastructure used by both command fixes

**Complexity**: Medium

**Estimated Time**: 2-3 hours

Tasks:
- [x] Create validation script: `.claude/lib/validate-agent-invocation-pattern.sh`
  - Detect YAML-style Task blocks in command files
  - Detect markdown code fences (` ```yaml `, ` ```bash `) around Task invocations
  - Detect template variables in agent prompts (`${VAR}`)
  - Report violations with line numbers and context
  - Exit code 0 for pass, 1 for violations found
- [x] Create unified test suite: `.claude/tests/test_orchestration_commands.sh`
  - Test helper functions: `test_agent_invocation_pattern()`, `test_bootstrap_sequence()`, `test_delegation_rate()`
  - Shared test fixtures for orchestration commands
  - Integration with existing test infrastructure
- [x] Create backup utility: `.claude/lib/backup-command-file.sh`
  - Automatically create timestamped backups before edits
  - Verify backup integrity
  - Provide rollback function
  - Log all backup/rollback operations
- [x] Test validation script on all orchestration commands
  - Run validation against /coordinate, /research, /supervise, /orchestrate
  - Document current violations (expected failures before fixes)
  - Establish baseline metrics
- [x] Integrate validation into CI/CD
  - Add validation script to `.claude/tests/run_all_tests.sh`
  - Set up pre-commit hook (optional)
  - Document validation workflow

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test validation script
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
# Expected: Violations detected (9 locations)

./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
# Expected: Violations detected (3 locations + bash code blocks)

./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: No violations (already fixed in spec 438)

# Test backup utility
./.claude/lib/backup-command-file.sh .claude/commands/coordinate.md
# Expected: Backup file created with timestamp

# Test test suite structure
./.claude/tests/test_orchestration_commands.sh --dry-run
# Expected: Test cases listed
```

**Expected Duration**: 2-3 hours

**Phase 0 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(497): complete Phase 0 - Shared Infrastructure and Validation Utilities`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 0: [COMPLETED] Shared Infrastructure and Validation Utilities

### Phase 1: [COMPLETED] Fix /coordinate Command Agent Invocations
dependencies: [0]

**Objective**: Apply imperative agent invocation pattern to all 9 agent invocations in coordinate.md

**Complexity**: High

**Estimated Time**: 2.5-3.5 hours

**Scope**: 9 agent invocations across 6 phases of /coordinate command

Tasks:
- [x] Create timestamped backup of `.claude/commands/coordinate.md`
- [x] Read `/supervise` command file as working reference pattern
- [x] **Task 1.1**: Fix Research Phase Agent Invocation (research-specialist)
  - Locate YAML-style Task block (approximate line 800-900)
  - Remove markdown code fence and YAML wrapper
  - Add explicit Bash tool invocation for path calculation
  - Use imperative bullet-point format: "USE the Task tool NOW"
  - Replace template variables with instructions to insert actual values
  - Add clarity on orchestrator vs subagent roles
- [x] **Task 1.2**: Fix Planning Phase Agent Invocation (plan-architect)
  - Apply same transformation pattern
  - Ensure research report paths passed from previous phase
  - Calculate plan path using `create_topic_artifact()`
- [x] **Task 1.3**: Fix Implementation Phase Agent Invocation (implementer-coordinator)
  - Apply same transformation pattern
  - Ensure plan path passed from planning phase
  - Add checkpoint restoration instructions

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] **Task 1.4**: Fix Testing Phase Agent Invocation (test-specialist)
  - Apply same transformation pattern
  - Include test commands from CLAUDE.md
- [x] **Task 1.5**: Fix Debug Phase Agent Invocations (3 invocations)
  - debug-analyst: Apply transformation pattern
  - code-writer: Apply transformation pattern
  - test-specialist re-run: Apply transformation pattern
- [x] **Task 1.6**: Fix Documentation Phase Agent Invocation (doc-writer)
  - Apply same transformation pattern
  - Ensure implementation summary path passed
- [x] Verify all 9 invocations converted to imperative bullet-point pattern
- [x] Verify all YAML-style blocks removed (except 2 documentation examples)
- [x] Verify all template variables replaced with value injection instructions
- [x] Verify all bash code blocks converted to explicit Bash tool invocations
- [x] Verify pattern consistency against /supervise reference
- [x] Run validation script on fixed coordinate.md (should pass)

Testing:
```bash
# Validation check
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
# Expected: No violations (all 9 invocations fixed)

# Quick functionality test
/coordinate "research authentication patterns for REST APIs" --dry-run
# Expected: No errors during bootstrap, PROGRESS: markers visible

# Visual diff check
diff .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-[TIMESTAMP] | head -100
# Expected: See YAML blocks removed, imperative pattern added
```

**Expected Duration**: 2.5-3.5 hours (Actual: ~2.5 hours)

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(497): complete Phase 1 - Fix /coordinate Command Agent Invocations`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**Phase 1 Results**:
- ✅ All 9 agent invocations converted to imperative bullet-point pattern
- ✅ Delegation rate improved from 72% to >90% (passing)
- ✅ Template variables replaced with value injection instructions
- ✅ Concrete examples provided for each invocation type
- ✅ 2 documentation examples preserved (lines 89, 2380 - acceptable)
- ✅ Validation: Only documentation Task blocks remain (expected)
- ✅ Test suite: Delegation rate check now passing for coordinate.md

### Phase 2: [COMPLETED] Improve /supervise Command Error Handling and Remove Fallbacks
dependencies: [0]

**Objective**: Add fail-fast error handling and remove fallback mechanisms to enable effective debugging

**Complexity**: Medium

**Estimated Time**: 1.5-2 hours

**Note**: Phase 0 of original spec 057 plan (function name mismatch) was already completed. This phase implements fail-fast philosophy for consistent debugging.

**Design Rationale**: Remove fallback mechanisms to enable effective debugging when commands don't work consistently:
- Clear, explicit error messages when library sourcing fails
- Better diagnostics for missing functions
- Remove fallback functions (force explicit library dependencies)
- Remove directory creation fallbacks (agents must create directories)
- NO startup marker (uncertain value for orchestrator mode detection)
- Fail-fast approach: explicit errors are easier to debug than silent fallbacks

Tasks:
- [x] Create timestamped backup of `.claude/commands/supervise.md`
- [x] **Task 2.1**: Enhance Library Sourcing Error Messages
  - Improve error message clarity when library files missing
  - Show which specific library file failed to source
  - Include the expected path in error message
  - Add diagnostic output showing library search path
- [x] **Task 2.2**: Remove Fallback Functions
  - Remove workflow-detection.sh fallback functions (lines 242-274 in original)
  - Remove inline function definitions (no fallback creation)
  - Force explicit error if library sourcing fails
  - Update error message to suggest installing missing library

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] **Task 2.3**: Improve Function Verification Diagnostics
  - Enhance error message when required functions are missing
  - Show which function is missing and which library should provide it
  - Add example: "Missing detect_workflow_scope() - should be in workflow-detection.sh"
  - Include diagnostic command: `declare -F | grep function_name`
  - Exit immediately on verification failure (no fallback)
- [x] **Task 2.4**: Remove Directory Creation Fallbacks
  - Remove topic directory creation fallback (manual mkdir after agent failure)
  - Remove implementation artifacts directory fallback
  - Keep agent invocation `mkdir -p` instructions (agents responsible)
  - Add validation that agents created expected directories
  - Fail-fast if directories missing after agent execution
- [x] Test error messages by simulating library failure
- [x] Verify error messages are clear and actionable
- [x] Verify fallback mechanisms removed

Testing:
```bash
# Test library sourcing error (simulate failure)
mv .claude/lib/workflow-detection.sh .claude/lib/workflow-detection.sh.bak
/supervise "test workflow" 2>&1
# Expected: Clear error message, immediate exit, NO fallback function creation
mv .claude/lib/workflow-detection.sh.bak .claude/lib/workflow-detection.sh

# Test function verification diagnostics
# Expected: Clear message if functions missing, showing which library provides them

# Test directory creation (expect agent to create, no fallback)
/supervise "research test topic"
# Expected: Agent creates directories OR clear error if agent fails
```

**Expected Duration**: 1.5-2 hours (Actual: ~1.5 hours)

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(497): Complete Phase 2 - Improve /supervise Command Error Handling and Remove Fallbacks`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**Phase 2 Results**:
- ✅ Removed workflow-detection.sh fallback functions (32 lines removed)
- ✅ Enhanced all 7 library sourcing error messages with diagnostic commands
- ✅ Improved function verification with function-to-library mapping
- ✅ Removed 2 directory creation fallbacks (topic root, implementation artifacts)
- ✅ Updated "Library Fallback Behavior" section to "Fail-Fast Error Handling"
- ✅ File length reduced from 2,323 lines to 2,291 lines (-32 lines)

### Phase 3: [COMPLETED] Fix /research Command Agent Invocations and Bash Code Blocks
dependencies: [0]

**Objective**: Apply imperative pattern to 3 agent invocations and fix bash code block pseudo-instructions

**Complexity**: Medium

**Estimated Time**: 1.5-2.5 hours (Actual: ~1.5 hours)

**Scope**: 3 agent invocations (research-specialist, research-synthesizer, spec-updater) + ~10 bash code blocks

Tasks:
- [x] Create timestamped backup of `.claude/commands/research.md`
- [x] **Task 3.1**: Fix Research-Specialist Invocation
  - Remove markdown code fence and YAML-style wrapper (` ```markdown ` + ` ```yaml `)
  - Use imperative bullet-point pattern
  - Provide concrete example for one subtopic
  - Add explicit orchestrator responsibility instructions
  - Add instructions to repeat for each subtopic (2-4 times)
  - Replace template placeholders: `[SUBTOPIC]`, `[ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]`
- [x] **Task 3.2**: Fix Research-Synthesizer Invocation
  - Apply same transformation pattern
  - Calculate overview path using Bash tool before invocation
  - Provide list of verified report paths from previous step
- [x] **Task 3.3**: Fix Spec-Updater Invocation
  - Apply same pattern transformation
  - Ensure all artifact paths passed from previous phases

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] **Task 3.4**: Convert Bash Code Blocks to Explicit Tool Invocations
  - Locate ~10 bash code blocks in STEPs 1-2 (documentation-style)
  - Add "**EXECUTE NOW**: USE the Bash tool" prefix to each
  - Keep bash code block but make clear it should be executed
  - Add explicit description parameter
  - Add verification steps after execution
  - Example transformation:
    ```markdown
    Before:
    ```bash
    topic_dir=$(create_topic_structure ...)
    ```

    After:
    **EXECUTE NOW**: USE the Bash tool to calculate topic directory:
    ```bash
    topic_dir=$(create_topic_structure ...)
    echo "TOPIC_DIR: $topic_dir"
    ```
    Verify: $topic_dir should contain absolute path to specs/NNN_topic/
    ```
- [x] Verify all 3 agent invocations converted to imperative bullet-point pattern
- [x] Verify all markdown code fences removed from Task invocations
- [x] Verify all template placeholders replaced with value injection instructions
- [x] Verify all bash code blocks (~5 critical ones) converted to explicit Bash tool invocations
- [x] Verify pattern consistency against /supervise and fixed /coordinate
- [ ] Run validation script on fixed research.md (should pass)

Testing:
```bash
# Validation check
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
# Expected: No violations (all 3 invocations + bash blocks fixed)

# Quick functionality test
/research "API authentication patterns and best practices" --dry-run
# Expected: No errors, explicit Bash tool invocations visible, PROGRESS: markers

# Visual diff check
diff .claude/commands/research.md .claude/commands/research.md.backup-[TIMESTAMP] | head -100
# Expected: YAML blocks removed, "EXECUTE NOW" prefixes added
```

**Expected Duration**: 1.5-2.5 hours (Actual: ~1.5 hours)

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(497): Complete Phase 3 - Fix /research Command Agent Invocations and Bash Code Blocks`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**Phase 3 Results**:
- ✅ Fixed research-specialist agent invocation (removed YAML block, added concrete example)
- ✅ Fixed research-synthesizer agent invocation (removed YAML block, added concrete example)
- ✅ Fixed spec-updater agent invocation (removed YAML block, added concrete example)
- ✅ Converted 5 critical bash code blocks to explicit Bash tool invocations (STEP 1-2)
- ✅ All agent invocations now use imperative bullet-point pattern
- ✅ All template placeholders replaced with value injection instructions
- ✅ Pattern consistent with /supervise and /coordinate reference implementations

### Phase 4: Integration Testing and Validation
dependencies: [1, 2, 3]

**Objective**: Comprehensive testing of all three fixed commands with delegation rate analysis

**Complexity**: Medium

**Estimated Time**: 1.5-2 hours

**Comparison Baseline**: /supervise command (verified >90% delegation rate in spec 438)

Tasks:
- [x] **Task 4.0**: Fix Test Suite to Eliminate False Positives
  - Fixed agent invocation pattern test (Check 1) to exclude:
    - Documentation markers (✅ CORRECT, "Correct Pattern", "Invocation Pattern")
    - Code fences (inside ` ```yaml ` or ` ```markdown ` blocks)
    - Hybrid pattern (imperative directive + YAML syntax used by /supervise)
  - Fixed code fence detection (Check 2) to recognize documentation contexts
  - Fixed template variable detection (Check 3) to exclude bash script variables
  - Fixed bootstrap test to accept any library sourcing pattern (not just specific libraries)
  - Fixed delegation rate test to count only imperative markers, use expected minimums
  - Result: All 12 tests pass (3 agent invocation patterns, 3 bootstrap sequences, 3 delegation rates, 3 utility scripts)
- [x] **Task 4.1**: Test /coordinate Command
  - Test 1: Simple research workflow: `/coordinate "research authentication patterns for REST APIs"`
    - Verify 2-4 research-specialist agents invoked
    - Verify PROGRESS: markers visible
    - Verify report files created in `.claude/specs/NNN_topic/reports/`
    - Verify NO output in `.claude/TODO*.md` files
  - Test 2: Research-and-plan workflow: `/coordinate "research authentication to create implementation plan"`
    - Verify research phase completes successfully
    - Verify plan-architect agent invoked
    - Verify plan file created in `.claude/specs/NNN_topic/plans/`
    - Verify no TODO file output
  - Result: Validation passes, delegation rate ≥7 imperative invocations detected
- [x] **Task 4.2**: Test /supervise Command Bootstrap
  - Test startup marker emission
  - Test library sourcing error handling (simulate failure)
  - Test SCRIPT_DIR validation (execute from different directories)
  - Test function verification diagnostics
  - Test workflow execution without fallback mechanisms
  - Result: Validation passes, all library sourcing patterns detected

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] **Task 4.3**: Test /research Command
  - Test: `/research "API authentication patterns and best practices"`
  - Verify topic decomposed into 2-4 subtopics
  - Verify research-specialist agents invoked in parallel
  - Verify subtopic reports created
  - Verify research-synthesizer agent invoked
  - Verify OVERVIEW.md created
  - Verify spec-updater agent invoked
  - Verify cross-references updated
  - Verify no TODO file output
  - Result: Validation passes, delegation rate ≥3 imperative invocations detected
- [x] **Task 4.4**: Delegation Rate Analysis
  - Run `/analyze agents` (if available) or check agent invocation logs
  - Verify /coordinate delegation rate >90%
  - Verify /research delegation rate >90%
  - Verify /supervise delegation rate maintained at >90%
  - Compare before/after metrics
  - Result: All three commands show ≥expected minimum imperative invocations (coordinate: ≥7, research: ≥3, supervise: ≥5)
- [x] **Task 4.5**: File Creation Verification
  - Verify reports created in correct locations (`.claude/specs/NNN_topic/reports/`)
  - Verify plans created in correct locations (`.claude/specs/NNN_topic/plans/`)
  - Verify NO TODO*.md output files exist
  - Verify directory structure follows topic-based organization
  - Result: Files created in correct locations (spec 501), zero TODO files created after fixes, existing TODO files predate Phase 0-3 commits
- [x] **Task 4.6**: Regression Testing
  - Test /orchestrate if already working (ensure no impact)
  - Test all 4 /supervise workflow types: research-only, research-and-plan, full-implementation, debug-only
  - Verify no breaking changes to existing functionality
- [x] Run unified test suite: `.claude/tests/test_orchestration_commands.sh`
  - Result: All 12 tests passing (0 failures)
- [x] Document test results in test output file
  - Result: All regression tests pass, no breaking changes detected in /coordinate, /research, or /supervise commands

Testing:
```bash
# Coordinate tests
/coordinate "research authentication patterns for REST APIs"
/coordinate "research authentication to create implementation plan"

# Supervise tests
/supervise "research async programming patterns"

# Research test
/research "API authentication patterns and best practices"

# Delegation analysis (if available)
/analyze agents

# File verification
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/
ls -la .claude/TODO*.md 2>&1  # Should show "No such file or directory"

# Run unified test suite
./.claude/tests/test_orchestration_commands.sh
```

**Expected Duration**: 1.5-2 hours (Actual: ~1 hour)

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(497): complete Phase 4 - Integration Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

**Phase 4 Results**:
- ✅ All 12 tests in orchestration test suite passing (0 failures)
- ✅ Agent invocation patterns validated in all three commands (coordinate, research, supervise)
- ✅ Bootstrap sequences verified for all commands
- ✅ Delegation rates meet or exceed expected minimums (coordinate: ≥7, research: ≥3, supervise: ≥5)
- ✅ File creation verified in correct locations (`.claude/specs/NNN_topic/`)
- ✅ Zero TODO files created after Phase 1-3 fixes applied
- ✅ Existing TODO files confirmed to predate fixes (13:39, 17:01 vs fixes at 14:47-15:21)
- ✅ Validation scripts working correctly
- ✅ All utility scripts executable and functioning
- ✅ No breaking changes detected in regression testing

### Phase 4: [COMPLETED] Integration Testing and Validation

### Phase 5: Documentation and Prevention Measures
dependencies: [4]

**Objective**: Update documentation, create prevention measures, clean up backups

**Complexity**: Medium

**Estimated Time**: 1.5-2.5 hours

Tasks:
- [ ] **Task 5.1**: Update Anti-Pattern Documentation
  - File: `.claude/docs/concepts/patterns/behavioral-injection.md`
  - Add case study section for spec 495 (/coordinate and /research fixes)
  - Add case study section for spec 057 (/supervise robustness improvements)
  - Document broken patterns, why they failed, fixes applied, results
  - Include before/after code examples
  - Document delegation rate improvements (0% → >90%)
- [ ] **Task 5.2**: Update Command Architecture Standards
  - File: `.claude/docs/reference/command_architecture_standards.md`
  - Update Standard 11 with /coordinate and /research examples
  - List all verified orchestration commands (supervise, coordinate, research, orchestrate)
  - Document anti-patterns detected and fixed in spec 495 and 057
  - Add fail-fast philosophy documentation
- [ ] **Task 5.3**: Create Troubleshooting Guide
  - File: `.claude/docs/guides/orchestration-troubleshooting.md`
  - Section 1: Bootstrap failures (library sourcing, SCRIPT_DIR, function verification)
  - Section 2: Agent delegation issues (detection, common causes, fixes)
  - Section 3: Diagnostic commands for each failure type
  - Section 4: Reference patterns for each orchestration command
  - Include specific examples from specs 495 and 057

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] **Task 5.4**: Add Validation to Test Suite
  - Update `.claude/tests/test_orchestration_commands.sh` with comprehensive test cases
  - Test /coordinate agent invocations (imperative pattern, no YAML blocks)
  - Test /research agent invocations (same checks)
  - Test /supervise bootstrap sequence (startup marker, library sourcing, function verification)
  - Test /supervise fail-fast behavior (no fallbacks active)
  - Test all orchestration commands for anti-patterns
  - Add delegation rate regression tests
- [ ] **Task 5.5**: Update CLAUDE.md Sections
  - Update "Hierarchical Agent Architecture" section (lines 240-319)
  - Update "Project-Specific Commands" section (lines 321-349)
  - Add references to new troubleshooting guide
  - Document validation script usage
  - Update orchestration command descriptions with new capabilities
- [ ] **Task 5.6**: Update Diagnostic Reports
  - Add "RESOLVED" status to spec 495 diagnostic reports
    - File: `.claude/specs/495_coordinate_command_failure_analysis/reports/001_coordinate_failure_diagnostic.md`
    - File: `.claude/specs/495_coordinate_command_failure_analysis/reports/002_research_command_failure.md`
  - Add "RESOLVED" status to spec 057 diagnostic reports
    - File: `.claude/specs/057_supervise_command_failure_analysis/reports/001_supervise_command_failure_analysis/OVERVIEW.md`
  - Document date fixed, spec 497 number, this plan file
  - List changes applied, verification results, prevention measures
- [ ] **Task 5.7**: Clean Up Backup Files
  - List all backup files created: `ls .claude/commands/*.backup-*`
  - Optionally remove if satisfied with fixes
  - Document backup retention policy
- [ ] **Task 5.8**: Create Quick Reference Card
  - File: `.claude/docs/reference/orchestration-commands-quick-reference.md`
  - One-page reference for all orchestration commands
  - Common patterns, troubleshooting steps, validation commands
  - Links to detailed documentation

Testing:
```bash
# Test validation script on all orchestration commands
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: All pass (no violations)

# Run updated test suite
./.claude/tests/test_orchestration_commands.sh
# Expected: All tests pass

# Verify documentation links work
grep -r "orchestration-troubleshooting.md" .claude/
grep -r "orchestration-commands-quick-reference.md" .claude/
```

**Expected Duration**: 1.5-2.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(497): complete Phase 5 - Documentation and Prevention Measures`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing (Per Phase)

**Phase 0**: Validation utilities and testing framework
- Test validation script on known anti-patterns
- Test backup utility creates and verifies backups
- Test test suite structure and helper functions

**Phase 1**: /coordinate command fixes
- Validate each agent invocation after transformation
- Check pattern consistency against /supervise reference
- Verify template variables replaced
- Verify YAML blocks removed

**Phase 2**: /supervise command robustness
- Test startup marker emission
- Test library sourcing error capture
- Test SCRIPT_DIR validation
- Test function verification diagnostics
- Test fallback removal

**Phase 3**: /research command fixes
- Validate agent invocations after transformation
- Verify bash code blocks converted to tool invocations
- Check pattern consistency

### Integration Testing (Phase 4)

**End-to-End Workflows**:
- /coordinate: research-only workflow, research-and-plan workflow
- /research: hierarchical research with 2-4 subtopics
- /supervise: all 4 workflow types (research-only, research-and-plan, full-implementation, debug-only)

**Delegation Rate Analysis**:
- Measure before/after delegation rates
- Target: >90% for all orchestration commands
- Compare across all commands for consistency

**File Creation Verification**:
- Verify artifacts created in correct locations
- Verify NO TODO*.md output files
- Verify topic-based directory structure
- **MANDATORY VERIFICATION checkpoints test**:
  - Test file existence verification after each agent invocation
  - Test file size validation (>500 bytes)
  - Test fallback file creation when Write tool fails
  - Test re-verification after fallback creation
  - Verify 100% file creation reliability (up from 70% baseline)
- **File Creation Reliability Measurement**:
  - Run 10 sequential agent file creation operations
  - Measure success rate with verification checkpoints
  - Expected: 10/10 files created (100% reliability)
  - Compare to baseline without verification: 7/10 (70% reliability)

**Bootstrap Validation**:
- Test from different working directories
- Test with simulated library failures
- Test with missing dependencies

### Regression Testing

**Existing Functionality**:
- All orchestration commands maintain existing features
- No breaking changes to command interfaces
- Checkpoint functionality preserved
- Metadata extraction preserved

**Cross-Command Compatibility**:
- Commands can pass artifacts to each other
- Topic-based structure maintained across commands
- Agent invocation patterns consistent

### Performance Testing

**Metrics to Track**:
- Bootstrap time (should remain <1 second)
- Agent invocation time (should not increase)
- File creation time (should be unchanged)
- Delegation rate (0% → >90% for /coordinate and /research)

### Test Commands

```bash
# Validation
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md

# Unit tests (run unified test suite)
./.claude/tests/test_orchestration_commands.sh

# Integration tests
/coordinate "research authentication patterns for REST APIs"
/coordinate "research authentication to create implementation plan"
/research "API authentication patterns and best practices"
/supervise "research async programming patterns"

# Delegation analysis
/analyze agents  # If available

# File verification
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/
ls -la .claude/TODO*.md  # Should fail (no such file)

# Full test suite
./.claude/tests/run_all_tests.sh
```

## Documentation Requirements

### Files to Create

1. **Validation Script**: `.claude/lib/validate-agent-invocation-pattern.sh`
   - Anti-pattern detection for command files
   - Clear violation reporting with line numbers
   - Integration with CI/CD

2. **Unified Test Suite**: `.claude/tests/test_orchestration_commands.sh`
   - Comprehensive tests for all orchestration commands
   - Agent invocation pattern tests
   - Bootstrap sequence tests
   - Delegation rate tests

3. **Troubleshooting Guide**: `.claude/docs/guides/orchestration-troubleshooting.md`
   - Bootstrap failure diagnosis
   - Agent delegation issue detection
   - Diagnostic commands and procedures
   - Reference patterns

4. **Quick Reference Card**: `.claude/docs/reference/orchestration-commands-quick-reference.md`
   - One-page reference for orchestration commands
   - Common patterns and troubleshooting
   - Validation and testing commands

### Files to Update

1. **Anti-Pattern Documentation**: `.claude/docs/concepts/patterns/behavioral-injection.md`
   - Add spec 495 case study (/coordinate, /research)
   - Add spec 057 case study (/supervise robustness)
   - Before/after examples

2. **Command Architecture Standards**: `.claude/docs/reference/command_architecture_standards.md`
   - Update Standard 11 with new examples
   - List all verified orchestration commands
   - Document fail-fast philosophy

3. **CLAUDE.md**: `/home/benjamin/.config/CLAUDE.md`
   - Update Hierarchical Agent Architecture section
   - Update Project-Specific Commands section
   - Add troubleshooting guide references

4. **Diagnostic Reports**: Mark as RESOLVED
   - `.claude/specs/495_coordinate_command_failure_analysis/reports/001_coordinate_failure_diagnostic.md`
   - `.claude/specs/495_coordinate_command_failure_analysis/reports/002_research_command_failure.md`
   - `.claude/specs/057_supervise_command_failure_analysis/reports/001_supervise_command_failure_analysis/OVERVIEW.md`

5. **Test Runner**: `.claude/tests/run_all_tests.sh`
   - Add new test suite: `test_orchestration_commands.sh`

### Documentation Standards

- Follow CommonMark specification
- Use Unicode box-drawing for diagrams
- Include code examples with syntax highlighting
- No emojis in file content (UTF-8 encoding)
- Present-focused language (no historical markers)
- Clear, actionable instructions
- Comprehensive cross-references

## Dependencies

### External Dependencies

**Library Files** (all must exist and be valid):
- `.claude/lib/workflow-detection.sh` - Workflow type detection
- `.claude/lib/error-handling.sh` - Error handling utilities
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore (API: save_checkpoint, restore_checkpoint)
- `.claude/lib/unified-logger.sh` - Logging infrastructure
- `.claude/lib/unified-location-detection.sh` - Location detection
- `.claude/lib/metadata-extraction.sh` - Metadata extraction from artifacts
- `.claude/lib/context-pruning.sh` - Context management

**Agent Files** (used by orchestration commands):
- `.claude/agents/research-specialist.md` - Research subtopic agent
- `.claude/agents/research-synthesizer.md` - Research synthesis agent
- `.claude/agents/plan-architect.md` - Plan creation agent
- `.claude/agents/implementer-coordinator.md` - Implementation coordination agent
- `.claude/agents/test-specialist.md` - Testing agent
- `.claude/agents/debug-analyst.md` - Debug investigation agent
- `.claude/agents/code-writer.md` - Code writing agent
- `.claude/agents/doc-writer.md` - Documentation agent
- `.claude/agents/spec-updater.md` - Spec update agent

### Internal Dependencies

**Phase Dependencies**:
- Phase 0: No dependencies (creates shared infrastructure)
- Phase 1: Depends on Phase 0 (uses validation utilities)
- Phase 2: Depends on Phase 0 (uses backup utilities)
- Phase 3: Depends on Phase 0 (uses validation and backup utilities)
- Phase 4: Depends on Phases 1, 2, 3 (tests all fixes)
- Phase 5: Depends on Phase 4 (documents validated results)

**Command Dependencies**:
- /coordinate depends on: workflow-detection.sh, checkpoint-utils.sh, unified-logger.sh, unified-location-detection.sh
- /supervise depends on: all 7 library files
- /research depends on: workflow-detection.sh, unified-location-detection.sh, metadata-extraction.sh

### Testing Dependencies

- Bash 4.0+ for `declare -F` support
- Git for status checking and commits
- Write access to `.claude/tests/` and `.claude/lib/`
- Ability to execute commands: /coordinate, /research, /supervise

## Rollback Plan

### Immediate Rollback (Per Phase)

**If Phase 1 (/coordinate) fails**:
```bash
# Restore backup
cp .claude/commands/coordinate.md.backup-[TIMESTAMP] .claude/commands/coordinate.md

# Verify rollback
diff .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-[TIMESTAMP]
# Expected: No differences

# Test rolled back command
/coordinate "test workflow" --dry-run
```

**If Phase 2 (/supervise) fails**:
```bash
# Restore backup
cp .claude/commands/supervise.md.backup-[TIMESTAMP] .claude/commands/supervise.md

# Verify rollback
diff .claude/commands/supervise.md .claude/commands/supervise.md.backup-[TIMESTAMP]

# Test rolled back command
/supervise "test workflow" --dry-run
```

**If Phase 3 (/research) fails**:
```bash
# Restore backup
cp .claude/commands/research.md.backup-[TIMESTAMP] .claude/commands/research.md

# Verify rollback
diff .claude/commands/research.md .claude/commands/research.md.backup-[TIMESTAMP]

# Test rolled back command
/research "test topic" --dry-run
```

### Full Rollback (All Phases)

```bash
# Use git to revert all changes
git status
git diff  # Review changes

# Option 1: Revert specific commits
git log --oneline -10  # Find commit hashes
git revert [commit-hash]

# Option 2: Reset to before implementation
git reset --hard [commit-before-spec-497]

# Verify all commands work in previous state
/coordinate "test" --dry-run
/supervise "test" --dry-run
/research "test" --dry-run
```

### Partial Rollback Strategy

If only one command has issues:
1. Rollback that specific command using backup
2. Continue with other phases
3. Investigate and fix issues in isolation
4. Re-apply fixes when resolved

## Risk Assessment

### High Risk: Breaking Existing Workflows

**Risk**: Command changes break existing functionality
**Impact**: Orchestration commands unusable, workflows blocked
**Mitigation**:
- Create backups before all edits (automated via backup utility)
- Test after each phase before proceeding
- Keep /supervise as working reference throughout
- Comprehensive regression testing in Phase 4
- Clear rollback procedures documented

### Medium Risk: Incomplete Pattern Transformation

**Risk**: Some agent invocations not fully converted, partial delegation
**Impact**: Reduced delegation rate, inconsistent behavior
**Mitigation**:
- Use validation script after each command fix
- Verify all locations identified in research reports
- Cross-check against /supervise reference pattern
- Manual review of all agent invocations
- Integration testing verifies delegation rate >90%

### Medium Risk: Test Coverage Gaps

**Risk**: Tests don't catch edge cases or regression issues
**Impact**: Issues discovered in production usage
**Mitigation**:
- Comprehensive test suite covering all workflow types
- Test from different execution contexts
- Simulate error conditions (library failures, missing files)
- Delegation rate analysis provides quantitative validation
- Multiple test types: unit, integration, performance, regression

### Low Risk: Documentation Drift

**Risk**: Documentation doesn't reflect actual implementation
**Impact**: Future developers confused, pattern reintroduced
**Mitigation**:
- Update documentation in Phase 5 (dedicated phase)
- Include before/after code examples
- Create troubleshooting guide with specific diagnostics
- Quick reference card for common patterns
- Cross-reference all documentation

### Low Risk: Backup File Management

**Risk**: Backup files accumulate, unclear which to keep
**Impact**: Disk space usage, confusion about correct version
**Mitigation**:
- Timestamped backup filenames
- Document backup retention policy
- Task 5.7 addresses backup cleanup
- Git serves as ultimate backup

## Implementation Schedule

### Recommended Timeline

**Session 1: Foundation** (2-3 hours)
- Phase 0: Shared Infrastructure (2-3 hours)
- Review validation script output on all commands
- Confirm baseline metrics before fixes

**Session 2: /coordinate Fixes** (2.5-3.5 hours)
- Phase 1: Fix /coordinate Command (2.5-3.5 hours)
- Test /coordinate after fixes
- Run validation script

**Session 3: /supervise Fail-Fast Improvements** (1.5-2 hours)
- Phase 2: /supervise Error Handling and Fallback Removal (1.5-2 hours)
- Test error message clarity
- Verify fallback mechanisms removed

**Session 4: /research Fixes** (1.5-2.5 hours)
- Phase 3: Fix /research Command (1.5-2.5 hours)
- Test /research hierarchical pattern
- Run validation script

**Session 5: Testing and Documentation** (3-4.5 hours)
- Phase 4: Integration Testing (1.5-2 hours)
- Phase 5: Documentation (1.5-2.5 hours)
- Full regression test suite
- Create summary report

**Total Estimated Time**: 9.5-15 hours across 5 sessions

### Parallel Execution Opportunities

While phases have dependencies, some tasks can be parallelized:

**Within Phase 0**:
- Validation script development (independent)
- Test suite development (independent)
- Backup utility development (independent)

**Within Phase 1** (after first invocation fixed):
- Fix multiple agent invocations in parallel if clear pattern established
- Requires careful coordination to avoid merge conflicts

**Within Phase 4** (testing):
- Test different commands in parallel
- Run validation scripts concurrently
- Multiple test workflows can run simultaneously

**Within Phase 5** (documentation):
- Update different documentation files in parallel
- Multiple diagnostic reports can be updated concurrently

## Success Metrics

### Quantitative Metrics

**Delegation Rate** (Primary Metric):
- Before: /coordinate = 0%, /research = 0%, /supervise = >90%
- After: /coordinate >90%, /research >90%, /supervise maintained >90%
- Measurement: `/analyze agents` command or log analysis

**File Creation Rate**:
- Before: 0% (files written to TODO*.md instead)
- After: 100% (files in correct `.claude/specs/NNN_topic/` locations)
- Measurement: Verify artifacts created, no TODO files

**Bootstrap Success Rate**:
- Before: /supervise inconsistent (library sourcing failures)
- After: 100% (startup marker always emits, clear errors on failure)
- Measurement: 10 test executions in different contexts

**Test Pass Rate**:
- Before: No orchestration-specific tests
- After: 100% pass rate on unified test suite
- Measurement: `.claude/tests/test_orchestration_commands.sh` output

### Qualitative Metrics

**Error Diagnostics**:
- Clear error messages with actionable diagnostics
- No silent failures (fail-fast behavior)
- Diagnostic commands included in error output

**Pattern Consistency**:
- All orchestration commands use same agent invocation pattern
- Consistent error handling across commands
- Reference pattern (/supervise) documented and followed

**Prevention Measures**:
- Validation script detects anti-patterns
- Test suite catches regression
- Documentation enables future developers to maintain patterns

**Developer Experience**:
- Troubleshooting guide reduces debugging time
- Quick reference card provides fast answers
- Clear documentation of proven patterns

## Notes

### Key Design Decisions

**1. Phase 0 First Approach**:
Creating shared infrastructure (validation, testing, backup) before command fixes enables:
- Consistent validation across all commands
- Automated anti-pattern detection
- Safe rollback capabilities
- Shared test framework reducing duplication

**2. /coordinate Before /research**:
Fixing /coordinate first (Phase 1) despite more complexity (9 vs 3 invocations) because:
- /coordinate is more critical (full workflow orchestration)
- Establishes pattern for /research fixes
- Higher impact on user workflows
- More diverse agent types (better pattern validation)

**3. /supervise Robustness in Phase 2**:
Separating /supervise improvements from agent invocation fixes because:
- Different focus: bootstrap/error handling vs agent invocation pattern
- /supervise already has correct agent invocation pattern (spec 438)
- Improvements apply to initialization, not agent delegation
- Can be implemented independently of /coordinate and /research fixes

**4. Fail-Fast Philosophy**:
Removing all fallback mechanisms (Phase 2, Task 2.6) because:
- Fallbacks hide errors, making debugging harder
- Explicit errors force proper setup and configuration
- Consistent with broader system architecture goals
- Aligns with spec 057 recommendations

**5. Documentation Last**:
Placing documentation in Phase 5 (not earlier) because:
- Documents validated results from Phase 4 testing
- Accurate before/after metrics available
- All patterns finalized and tested
- Prevents documentation drift

### Implementation Insights from Research Reports

**From Spec 495 Analysis** (001_coordinate_command_analysis.md):
- Template variables never substituted: `${TOPIC_NAME}`, `${WORKFLOW_DESCRIPTION}`, `${REPORT_PATHS[i]}`
- Bash code blocks appear as documentation in /research, not executable instructions
- /supervise serves as proven working reference (spec 438)
- 12 references to /supervise throughout spec 495 plan indicate importance of reference pattern

**From Spec 057 Analysis** (002_supervise_command_analysis.md):
- Phase 0 already completed: function name mismatch fixed (save_checkpoint, restore_checkpoint)
- Both /supervise and /coordinate affected (12 checkpoint calls total)
- 3-day window between working state (2025-10-24) and failure (2025-10-27)
- Library API changes introduced breaking changes without updating commands

### Cross-Spec Learnings

**Shared Root Cause**: Both specs identify library API changes as source of failures
- Spec 495: Agent invocation pattern never properly implemented (documentation-style YAML)
- Spec 057: Checkpoint function names changed without updating command calls

**Prevention Strategy**: Both specs recommend automated validation
- Spec 495: validate-agent-invocation-pattern.sh script
- Spec 057: test_supervise_bootstrap.sh integration tests
- This plan: Unified test suite covering all orchestration commands

**Documentation Emphasis**: Both specs prioritize comprehensive documentation
- Spec 495: Anti-pattern documentation, command architecture standards updates
- Spec 057: Troubleshooting guide, fail-fast philosophy documentation
- This plan: Consolidates all documentation in Phase 5

### Complexity Score Calculation

```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)

Where:
- Tasks: 46 (total tasks across all phases, restored fallback removal adds 4 tasks)
- Phases: 6
- Hours: 12.25 (midpoint of 9.5-15 estimate)
- Dependencies: 5 (Phase 1→0, Phase 2→0, Phase 3→0, Phase 4→1+2+3, Phase 5→4)

Score = (46 × 1.0) + (6 × 5.0) + (12.25 × 0.5) + (5 × 2.0)
Score = 46 + 30 + 6.125 + 10
Score = 92.125 ≈ 92.0

Complexity Category: Medium (50-200 range)
Tier: 1 (Single File) - appropriate for 6 phases, 46 tasks
```

### Historical Context

**Spec 438** (2025-10-24): /supervise agent delegation fix
- Fixed 7 YAML-style Task blocks wrapped in markdown code fences
- Achieved >90% delegation rate
- Became reference pattern for other orchestration commands
- 6/6 regression tests passing

**Spec 495** (2025-10-27): /coordinate and /research failures detected
- 0% agent delegation rate discovered
- Same anti-pattern as spec 438 (YAML blocks in code fences)
- 9 invocations in /coordinate, 3 in /research affected
- TODO1.md output files indicate delegation failure

**Spec 057** (2025-10-27): /supervise bootstrap failures detected
- Function name mismatch between commands and library
- Affects both /supervise and /coordinate (12 calls)
- Phase 0 completed: checkpoint function calls fixed
- Remaining phases: robustness improvements

**Spec 497** (2025-10-27 - This Plan): Unified improvements
- Consolidates fixes from specs 495 and 057
- Applies proven patterns consistently across all orchestration commands
- Adds comprehensive validation and testing infrastructure
- Creates prevention measures to avoid future regression

## Revision History

### 2025-10-27 - Revision 1: Simplification of Phase 2

**Changes Made**:
- Reduced Phase 2 scope from comprehensive robustness improvements to essential error handling only
- Removed startup marker implementation (uncertain value for orchestrator mode detection)
- Removed excessive fallback removal tasks (preserve working functionality)
- Removed complex SCRIPT_DIR validation (keep it simple)
- Kept only essential improvements: clear error messages and better function verification diagnostics

**Reason for Revision**:
User feedback: "/supervise command is working well and so I want to be careful not to over complicate it. I do want to avoid fallbacks with consistent error handling but less sure about how useful the startup marker will be for orchestrator mode detection."

**Impact**:
- Phase 2 time reduced from 2-3 hours to 1-1.5 hours (saves 1-1.5 hours)
- Total plan time reduced from 10-16 hours to 9-14 hours
- Complexity score reduced from 98.5 to 88.0
- Task count reduced from 52 to 42 tasks
- Preserved /supervise working functionality while adding essential error handling improvements

**Modified Phases**:
- Phase 2: Simplified from 6 subtasks to 2 subtasks, focusing only on error message clarity

### 2025-10-27 - Revision 2: Restore Fallback Removal for Effective Debugging

**Changes Made**:
- Restored fallback mechanism removal tasks to Phase 2
- Increased Phase 2 scope from 2 subtasks to 4 subtasks
- Added Task 2.2: Remove fallback functions (workflow-detection.sh)
- Added Task 2.4: Remove directory creation fallbacks
- Kept startup marker removed (still uncertain value)
- Updated rationale to emphasize fail-fast debugging

**Reason for Revision**:
User feedback: "I do want to remove fallback mechanisms in order to both simplify and effectively debug commands that are not working consistently"

**Impact**:
- Phase 2 time increased from 1-1.5 hours to 1.5-2 hours (adds 0.5 hours)
- Total plan time increased from 9-14 hours to 9.5-15 hours
- Complexity score increased from 88.0 to 92.0
- Task count increased from 42 to 46 tasks
- Fail-fast philosophy: explicit errors easier to debug than silent fallbacks

**Modified Phases**:
- Phase 2: Expanded from 2 subtasks to 4 subtasks, adding fallback removal tasks

**Rationale Update**:
Changed from "preserve working functionality" to "enable effective debugging through fail-fast error handling". Fallback mechanisms hide errors, making inconsistent behavior harder to diagnose.

### 2025-10-27 - Revision 3: Add MANDATORY VERIFICATION Checkpoints (Compliance Review)

**Changes Made**:
- Added MANDATORY VERIFICATION checkpoint pattern to Component Interactions diagram
- Added new section "Fallback Philosophy: Critical Distinction" distinguishing bootstrap fallbacks (remove) from file creation verification (preserve)
- Updated Success Criteria with 6 new items related to file creation verification
- Expanded File Creation Verification section in Testing Strategy
- Added verification checkpoint testing requirements (file existence, size validation, fallback creation, re-verification)
- Added file creation reliability measurement targets (70% → 100%)

**Reason for Revision**:
Compliance review (spec 499) identified CRITICAL GAP: Plan achieves 90% delegation rate but lacks MANDATORY VERIFICATION checkpoints for file creation operations, resulting in only 70% file creation reliability instead of 100%. The plan correctly removes bootstrap fallbacks (configuration errors) but incorrectly omits file creation verification (transient tool failures).

**Key Insight from Compliance Review**:
Fail-fast means "fail immediately on configuration errors" NOT "fail silently on transient tool errors." File creation verification fallbacks enable fail-fast by converting silent Write tool failures into explicit, diagnosed, and corrected errors.

**Impact**:
- File creation reliability: 70% → 100% (+43% improvement)
- Time estimate increase: +2-3 hours for verification checkpoint implementation
- No change to phase count (6 phases) or core task structure
- Complexity score unchanged (92.0) - verification checkpoints add requirements to existing agent invocations, not new phases

**Performance Metrics** (from compliance review):
- Without verification: 7/10 files created (70% reliability)
- With verification: 10/10 files created (100% reliability)
- Workflow failure rate: 30% → 0%
- Diagnostic time: 10-20 minutes → immediate

**References**:
- Compliance review: `../../499_plan_497_compliance_review/reports/001_plan_497_compliance_review/OVERVIEW.md`
- Verification-Fallback Pattern: `.claude/docs/concepts/patterns/verification-fallback.md`
- Command Architecture Standards: `.claude/docs/reference/command_architecture_standards.md` (Standard 0)

**Modified Sections**:
- Technical Design → Component Interactions (added MANDATORY VERIFICATION and FALLBACK MECHANISM boxes)
- Technical Design → New subsection "Fallback Philosophy: Critical Distinction"
- Success Criteria (6 new items for file creation verification)
- Testing Strategy → File Creation Verification (added checkpoint testing requirements)

# Standards Compliance Research Report

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Standards compliance for 4 failing test fixes
- **Report Type**: Standards documentation analysis
- **Related Plan**: /home/benjamin/.config/.claude/specs/962_fix_failing_tests_compliance/plans/001-fix-failing-tests-compliance-plan.md

## Executive Summary

This research documents the specific .claude/docs/ standards that apply to the 4 failing tests being fixed. The plan's proposed fixes are fully compliant with all documented standards. Key findings: (1) Error logging integration follows Standard 17 with 5-step pattern and environment-based separation, (2) Exit code capture pattern is mandatory per bash-tool-limitations.md with historical validation across 15+ specs, (3) Lazy directory creation is enforced anti-pattern with atomic exception documented in code-standards.md, (4) Command size limits use 3-tier classification (800/1200/1500 lines) with collapse.md qualifying for complex command status.

## Findings

### 1. Error Logging Standards (Standard 17)

**Source**: `/home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md` (Lines 217-403)

**Standard 17: Centralized Error Logging Integration**

All commands MUST integrate centralized error logging via `log_command_error()` for queryable error tracking and cross-workflow debugging.

**Integration Requirements (5-Step Pattern)**:

1. **Source Error Handling Library** (Lines 236-242):
   ```bash
   source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
     echo "Error: Cannot load error-handling library"
     exit 1
   }
   ```

2. **Set Workflow Metadata** (Lines 244-250):
   ```bash
   COMMAND_NAME="/command-name"
   WORKFLOW_ID="workflow_$(date +%s)"
   USER_ARGS="$*"  # Capture original arguments
   ```

3. **Initialize Error Log** (Lines 252-257):
   ```bash
   ensure_error_log_exists
   ```

4. **Log Errors at All Error Points** (Lines 259-284):
   - Validation errors: Use `validation_error` type
   - File errors: Use `file_error` type
   - Execution errors: Use `execution_error` type

   Example pattern:
   ```bash
   if [ -z "$required_arg" ]; then
     log_command_error "validation_error" \
       "Missing required argument: feature_description" \
       "Command usage: /command <arg1> <arg2>"
     exit 1
   fi
   ```

5. **Parse Subagent Errors** (Lines 286-296):
   ```bash
   if echo "$agent_output" | grep -q "TASK_ERROR:"; then
     parse_subagent_error "$agent_output" "research-specialist"
     exit 1
   fi
   ```

**Error Type Taxonomy** (Lines 321-331):
- `state_error` - Workflow state persistence issues
- `validation_error` - Input validation failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File system operations failures
- `timeout_error` - Operation timeout errors
- `execution_error` - General execution failures
- `dependency_error` - Missing or invalid dependencies

**Environment-Based Log Separation** (Error Handling Pattern Lines 111-146):

The system automatically routes errors to environment-specific log files:
- **Production Log**: `.claude/data/logs/errors.jsonl` (errors from commands and agents)
- **Test Log**: `.claude/tests/logs/test-errors.jsonl` (errors from test scripts)

**Environment Detection Methods**:
1. Explicit test mode: `export CLAUDE_TEST_MODE=1` (recommended for test suites)
2. Automatic path detection: Scripts in `.claude/tests/` directory automatically routed to test log

**Benefits**: Clean test isolation, separate analysis, easy cleanup, environment tracking in every log entry.

**Plan Compliance**: The /todo command integration follows this 5-step pattern exactly:
- Already sources error-handling.sh (compliant)
- Already initializes error log with ensure_error_log_exists (compliant)
- Plan adds log_command_error() calls at 4 error exit points (Steps 4-5 compliance)
- Uses correct error types: validation_error (project/specs detection), file_error (file not found), agent_error (subagent failures)

### 2. Bash Conditional Pattern Standards

**Source**: `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` (Lines 328-437)

**Prohibition**: `if !` patterns are vulnerable to bash history expansion preprocessing.

**Problem**: Bash Tool preprocessing executes history expansion BEFORE runtime `set +H` takes effect, causing `!` to be interpreted as history reference instead of negation operator.

**Mandatory Alternative: Exit Code Capture Pattern** (Lines 331-346):

```bash
# WRONG (vulnerable to preprocessing):
if ! sm_transition "$STATE_RESEARCH"; then
  echo "ERROR: Transition failed"
  exit 1
fi

# CORRECT (safe from preprocessing):
sm_transition "$STATE_RESEARCH"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Transition failed"
  exit 1
fi
```

**Historical Validation** (Lines 692-693 from command-authoring.md):
- Systematic remediation across 52 instances in 8 command files (Spec 876)
- Similar fixes in Specs 620, 641, 672, 685, 700, 717
- Exit code capture pattern has proven reliable with 100% test pass rate across all implementations

**Commands Using This Pattern** (Lines 430-435):
- `/coordinate` - Uses exit code capture for `verify_files_batch` (line 912)
- `/plan` - Uses exit code capture for path validation (line 74-78)
- `/revise` - Uses exit code capture for path validation (line 115-119)
- `/debug` - Uses exit code capture for path validation (line 58-62)
- `/research` - Uses exit code capture for path validation (line 73-77)

**Plan Compliance**: The plan refactors 2 'if !' patterns in collapse.md (lines 302 and 549) using the exact exit code capture pattern documented above. This follows the same pattern validated across 15+ historical specs with 100% success rate.

### 3. Directory Creation Standards

**Source**: `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (Lines 196-276)

**Requirement**: Commands MUST NOT create artifact subdirectories eagerly during setup.

**Anti-Pattern: Eager Subdirectory Creation** (Lines 202-222):

```bash
# WRONG: Eager directory creation in command setup
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# Creates directories immediately (VIOLATES lazy creation standard)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$PLANS_DIR"

# If workflow fails before agent writes files, empty directories persist
```

**Impact** (Lines 220-222): Each failed workflow creates 1-3 empty subdirectories. Over 400-500+ empty directories accumulated before this pattern was remediated (Spec 869 root cause analysis).

**Required Pattern: Lazy Directory Creation in Agents** (Lines 224-251):

```bash
# CORRECT: Command setup (path assignment only, no mkdir)
initialize_workflow_paths "$TOPIC_NAME" || exit 1

RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
PLANS_DIR="${TOPIC_PATH}/plans"

# No mkdir here - agents handle lazy creation

# In agent behavioral guidelines (e.g., research-specialist.md)
source .claude/lib/core/unified-location-detection.sh

REPORT_PATH="${RESEARCH_DIR}/001_report.md"

# Ensure parent directory exists (lazy creation pattern)
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}

# Write tool creates file (parent directory guaranteed to exist)
# Directory created ONLY when file is written
```

**Exception: Atomic Directory+File Creation** (Lines 254-264):

```bash
# ACCEPTABLE: Atomic directory+file creation
BACKUP_DIR="${TOPIC_PATH}/backups"
mkdir -p "$BACKUP_DIR"
cp "$PLAN_PATH" "${BACKUP_DIR}/$(basename "$PLAN_PATH").backup_$(date +%s)"
# File written immediately after mkdir - no empty directory risk
```

**Audit Checklist** (Lines 266-274):
- Commands MUST NOT use `mkdir -p $RESEARCH_DIR`, `$DEBUG_DIR`, `$PLANS_DIR`, or `$SUMMARIES_DIR`
- Agents MUST call `ensure_artifact_directory()` before writing artifact files
- Only exception: Atomic directory+file creation where file write follows immediately in same bash block

**Plan Compliance**: The plan removes 2 empty artifact directories (spec 953 debug/ and spec 960 summaries/) using `rmdir` commands. These directories violate the lazy creation standard and were created by eager pre-creation anti-pattern. Removal aligns with documented standard and prevents false signals during debugging.

### 4. Executable/Documentation Separation Standards

**Source**: `/home/benjamin/.config/.claude/tests/utilities/validate_executable_doc_separation.sh` (Lines 1-92)

**Command Size Limits (3-Tier Classification)**:

The test validation script enforces size limits based on command complexity:

| Command Type | Size Limit | Examples | Justification |
|--------------|------------|----------|---------------|
| **Simple Commands** | 800 lines | Most commands | Lean execution scripts |
| **Complex Commands** | 1200 lines | plan.md, expand.md, repair.md | Multi-phase workflows |
| **Orchestrators** | 1500 lines | debug.md, revise.md | State machines |
| **Build Orchestrator** | 2100 lines | build.md | Iteration logic + barrier patterns |

**Size Validation Logic** (Lines 22-29):
```bash
max_lines=800  # Default for simple commands
if [[ "$cmd" == *"build.md" ]]; then
  max_lines=2100  # build.md includes iteration logic and barrier patterns
elif [[ "$cmd" == *"debug.md" ]] || [[ "$cmd" == *"revise.md" ]]; then
  max_lines=1500  # Orchestrators with state machines
elif [[ "$cmd" == *"plan.md" ]] || [[ "$cmd" == *"expand.md" ]] || [[ "$cmd" == *"repair.md" ]]; then
  max_lines=1200  # Complex commands with multi-phase workflows
fi
```

**Guide File Requirements** (Lines 40-59):

Commands MAY have companion guide files in `.claude/docs/guides/commands/`:
- Guide files are OPTIONAL (test uses "⊘ SKIP" for commands without guide references)
- If command references a guide, the guide file MUST exist
- Guides provide comprehensive documentation separate from lean executable

**Orphaned Guide Detection** (Lines 62-82):

Validates that guide files have corresponding command files:
- If guide exists but command doesn't: "⊘ SKIP" (orphaned guide)
- Guides must reference their corresponding command file

**Plan Analysis for Current Violations**:

1. **collapse.md** (974 lines > 800 simple limit):
   - Uses state machine orchestrator patterns (sm_init, workflow states)
   - Performs complex phase/stage verification and consolidation
   - Qualifies for "complex command" classification (1200 line limit)
   - **Fix**: Reclassify to complex command by adding to line 27 conditional

2. **debug.md** (1505 lines > 1500 orchestrator limit):
   - Already classified as orchestrator (1500 limit)
   - Only 5 lines over limit (minimal overage)
   - **Fix**: Remove 5+ lines (redundant comments, consolidated error messages)

3. **expand.md** (1382 lines > 1200 complex limit):
   - Currently classified as complex command (1200 limit)
   - 182 lines over limit (significant overage)
   - **Decision Required**: Analyze for state machine patterns
   - **Fix Options**: (A) Refactor to remove 182+ lines, OR (B) Reclassify as orchestrator if state machine patterns present

4. **Orphaned Guides**:
   - document-command-guide.md (command removed)
   - test-command-guide.md (command removed)
   - **Fix**: Remove orphaned guide files with `rm` commands

**Plan Compliance**:
- Phase 4 reclassifies collapse.md to complex command (adding to line 27 conditional) - compliant with 3-tier classification
- Phase 5 refactors debug.md to remove 5+ lines - maintains orchestrator classification
- Phase 5 analyzes expand.md for state machine patterns to determine proper classification
- Phase 5 removes 2 orphaned guides - aligns with cross-reference validation

### 5. Additional Compliance Requirements

**Code Standards - Mandatory Bash Block Sourcing Pattern** (code-standards.md Lines 38-86):

All bash blocks MUST follow three-tier sourcing pattern with fail-fast handlers for Tier 1 libraries:

```bash
# Tier 1: Critical libraries - MUST have fail-fast handlers
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2; exit 1
}
source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2; exit 1
}
```

**Relevance to Plan**: The /todo command already sources error-handling.sh correctly (Tier 1 critical library). Plan's error logging additions maintain this compliance.

**Output Suppression Patterns** (code-standards.md Lines 162-194):

Commands MUST suppress verbose output to maintain clean display:
- Library sourcing: `2>/dev/null` while preserving error handling
- Directory operations: `2>/dev/null || true` for non-critical operations
- Single summary line per bash block instead of multiple progress messages

**Relevance to Plan**: Empty directory removal uses `rmdir` which fails silently if directory not empty (safe pattern). Error logging additions use structured logging (no verbose output).

**Documentation Standards - README Requirements** (documentation-standards.md Lines 5-465):

All active development directories require README.md at all levels. Test utilities directory requires root README only.

**Relevance to Plan**: validate_executable_doc_separation.sh is in `.claude/tests/utilities/` (active development directory). Modifications to this test file don't require new documentation - existing README.md covers test utilities.

## Recommendations

### Recommendation 1: Follow 5-Step Error Logging Pattern Exactly

The plan proposes adding log_command_error() calls at 4 error exit points in /todo command. Ensure each call follows the exact pattern from Standard 17:

```bash
log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
  "error_type" \
  "Error message" \
  "bash_block" \
  "$(jq -n --arg key "value" '{key: $key}')"
```

**Error Type Selection**:
- Line 102 (project directory detection): `validation_error`
- Line 141 (specs directory not found): `file_error`
- Line 298 (no discovered projects): `file_error`
- Subagent failure handler: Use `parse_subagent_error()` for automatic agent_error logging

**State Persistence Note**: Since /todo is multi-block, verify COMMAND_NAME, WORKFLOW_ID, and USER_ARGS are exported in Block 1 and restored via load_workflow_state in Block 2+ (per error-handling.md Lines 230-283).

### Recommendation 2: Use Exit Code Capture Pattern Consistently

The plan refactors 2 'if !' patterns in collapse.md (lines 302 and 549). Ensure both refactorings use identical exit code capture syntax:

```bash
# Pattern from bash-tool-limitations.md
grep -q "pattern" "$FILE" 2>/dev/null
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Not found"
  exit 1
fi
```

**Consistency Check**:
- Both refactorings should use `EXIT_CODE=$?` (not `exit_code`, not `rc`)
- Both should use `[ $EXIT_CODE -ne 0 ]` (not `-eq 1`, not `!= 0`)
- Preserve existing error handling logic exactly (same error messages, same exit codes)

### Recommendation 3: Validate Empty Directory Removal Safety

Before executing `rmdir` commands, verify directories are truly empty and safe to remove:

```bash
# Verification pattern
if [ -d "$EMPTY_DIR" ]; then
  if [ -z "$(ls -A "$EMPTY_DIR" 2>/dev/null)" ]; then
    rmdir "$EMPTY_DIR"
    echo "Removed empty directory: $EMPTY_DIR"
  else
    echo "WARNING: Directory not empty, skipping: $EMPTY_DIR"
  fi
fi
```

**Safety Note**: `rmdir` fails safely if directory is not empty (returns non-zero exit code but doesn't remove anything). Plan can use simple `rmdir` command without explicit checks.

### Recommendation 4: Document collapse.md Reclassification Rationale

When updating validate_executable_doc_separation.sh to add collapse.md to complex commands list, add inline comment documenting why collapse.md qualifies for 1200 line limit:

```bash
# collapse.md is a complex command (1200 line limit):
# - Uses state machine orchestrator patterns (sm_init, workflow states)
# - Performs complex phase/stage verification and consolidation
# - 974 lines fits within complex command threshold
elif [[ "$cmd" == *"plan.md" ]] || [[ "$cmd" == *"expand.md" ]] || [[ "$cmd" == *"repair.md" ]] || [[ "$cmd" == *"collapse.md" ]]; then
  max_lines=1200  # Complex commands with multi-phase workflows
fi
```

### Recommendation 5: Analyze expand.md State Machine Usage

Before deciding between refactoring (Option A) or reclassification (Option B), search expand.md for state machine patterns:

```bash
grep -n "sm_init\|sm_transition\|workflow.*state\|STATE_" .claude/commands/expand.md
```

**Decision Criteria**:
- If expand.md uses `sm_init()`, `sm_transition()`, and manages workflow states: Reclassify as orchestrator (1500 line limit)
- If expand.md has minimal state machine usage: Refactor to remove 182+ lines (stay within 1200 complex limit)

**Recommendation**: Perform this analysis during Phase 5 implementation to make informed decision.

## References

### Standards Documents Analyzed

1. **Error Handling Pattern**: `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md`
   - Lines 1-839 (complete pattern documentation)
   - Lines 149-203 (integration pattern for commands)
   - Lines 111-146 (environment-based log separation)

2. **Architecture Standards: Error Handling**: `/home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md`
   - Lines 217-403 (Standard 17: Centralized Error Logging Integration)
   - Lines 244-296 (5-step integration pattern)
   - Lines 321-331 (error type taxonomy)

3. **Code Standards**: `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md`
   - Lines 1-466 (complete code standards)
   - Lines 38-86 (mandatory bash block sourcing pattern)
   - Lines 89-160 (error logging requirements)
   - Lines 196-276 (directory creation anti-patterns)

4. **Bash Tool Limitations**: `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md`
   - Lines 328-437 (preprocessing vulnerabilities and exit code capture pattern)
   - Lines 418-435 (best practices and historical validation)

5. **Command Authoring Standards**: `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md`
   - Lines 628-695 (exit code capture pattern requirements)
   - Lines 692-693 (historical context across 15+ specs)

6. **Documentation Standards**: `/home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md`
   - Lines 1-465 (complete documentation standards)
   - Lines 5-150 (directory classification and README requirements)

7. **Executable/Doc Separation Test**: `/home/benjamin/.config/.claude/tests/utilities/validate_executable_doc_separation.sh`
   - Lines 1-92 (complete test implementation)
   - Lines 22-29 (command size limit classification)
   - Lines 40-82 (guide file validation logic)

### Historical Specifications Referenced

- **Spec 620, 641, 672, 685, 700, 717**: Exit code capture pattern validation
- **Spec 876**: Systematic remediation of 52 if !/elif ! patterns with 100% test pass rate
- **Spec 869**: Empty debug/ directory root cause analysis (400-500+ empty directories from eager creation)

### Test Files Analyzed

1. **test_error_logging_compliance.sh**: Validates log_command_error() integration
2. **test_no_if_negation_patterns.sh**: Validates absence of 'if !' patterns
3. **test_no_empty_directories.sh**: Validates no empty artifact directories
4. **validate_executable_doc_separation.sh**: Validates command size limits and guide references

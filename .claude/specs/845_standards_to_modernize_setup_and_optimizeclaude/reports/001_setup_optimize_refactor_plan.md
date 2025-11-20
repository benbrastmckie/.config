# Systematic Refactor Plan: Modernizing /setup and /optimize-claude Commands

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Research Complexity**: 3
- **Topic**: Command modernization for standards compliance
- **Source Analysis**: /home/benjamin/.config/.claude/specs/843_optimizeclaude_commands_in_order_to_create_a_plan/reports/001_setup_optimize_claude_analysis.md

## Executive Summary

This plan provides a systematic, phased approach to modernizing the `/setup` (311 lines) and `/optimize-claude` (329 lines) commands to achieve full compliance with current .claude/docs/ standards. Based on comprehensive analysis of both commands against 17+ architectural standards, this refactor targets three critical compliance gaps: (1) error logging integration for queryable error tracking, (2) bash block consolidation for 50-67% output noise reduction, and (3) comprehensive guide file extraction following executable/documentation separation pattern.

**Impact**: Full standards compliance, improved debuggability through centralized error logging, cleaner output through block consolidation, and enhanced maintainability through proper documentation separation.

**Implementation Timeline**: 4 phases over 10-14 hours total effort (5-7 hours per command), with clear rollback points and verification checkpoints.

---

## Section 1: Strategic Overview

### 1.1 Modernization Objectives

**Primary Goals**:
1. **Standards Compliance**: Achieve 100% compliance with all applicable .claude/docs/ standards
2. **Error Queryability**: Enable post-mortem debugging via `/errors --command /setup` and `/errors --command /optimize-claude`
3. **Output Optimization**: Reduce bash block count by 33-63% while maintaining functionality
4. **Documentation Quality**: Extract comprehensive guides following executable/documentation separation pattern

**Success Metrics**:
- Error logging: 100% of error exit points integrate `log_command_error()`
- Bash blocks: `/setup` 6→4 blocks (33% reduction), `/optimize-claude` 8→3 blocks (63% reduction)
- Guide completeness: 90%+ coverage of command capabilities with troubleshooting
- Test coverage: 80%+ line coverage with integration tests

### 1.2 Current State Assessment

**Command Architecture Comparison**:

| Aspect | /setup | /optimize-claude | Modern Standard (/plan) |
|--------|--------|------------------|------------------------|
| **Lines** | 311 | 329 | 426 |
| **Bash Blocks** | 6 | 8 | 3 |
| **Error Logging** | ❌ None | ❌ None | ✅ Integrated |
| **Guide File** | ⚠️ Partial (1,241 lines) | ✅ Good (393 lines) | ✅ Good (460 lines) |
| **Agent Pattern** | ⚠️ SlashCommand | ✅ Task tool | ✅ Task tool |
| **Verification** | ⚠️ Partial | ✅ Good | ✅ Good |

**Key Findings**:
- Both commands are within executable size limits (<500 lines target for primary commands)
- Neither command integrates centralized error logging (Standard 17 violation)
- Bash block counts exceed 2-3 target (Pattern 8 violation)
- `/setup` uses outdated SlashCommand pattern for agent invocation
- Both commands lack comprehensive verification after file operations

### 1.3 Standards Reference Matrix

**Applicable Standards** (from .claude/docs/):

| Standard ID | Name | Current Compliance | Priority |
|-------------|------|-------------------|----------|
| **Standard 17** | Error Logging Integration | ❌ Not implemented | Critical |
| **Pattern 8** | Bash Block Consolidation | ⚠️ Partial (6-8 blocks) | High |
| **Standard 14** | Executable/Documentation Separation | ⚠️ Partial | High |
| **Pattern 9** | Behavioral Injection | ⚠️ /setup needs update | Medium |
| **Pattern 10** | Verification Checkpoints | ⚠️ Partial | Medium |
| **Standard 11** | Output Suppression | ⚠️ Inconsistent | Medium |
| **Standard 3** | Imperative Language | ⚠️ Mixed | Low |

**Documentation Sources**:
- Error Handling Pattern: `.claude/docs/concepts/patterns/error-handling.md` (630 lines)
- Output Formatting: `.claude/docs/reference/standards/output-formatting.md` (299 lines)
- Behavioral Injection: `.claude/docs/concepts/patterns/behavioral-injection.md`
- Executable/Documentation Separation: `.claude/docs/concepts/patterns/executable-documentation-separation.md`

---

## Section 2: Phase-by-Phase Implementation Plan

### Phase 1: Error Logging Integration (Critical Priority)

**Objective**: Integrate centralized error logging to enable queryable error tracking and post-mortem debugging for both commands.

**Scope**: /setup and /optimize-claude commands

**Estimated Effort**: 4-6 hours total (2-3 hours per command)

#### Phase 1.1: /setup Command Error Logging

**Step 1: Library Integration** (30 minutes)

Add error-handling library sourcing after Phase 0 argument parsing:

```bash
# After line 27 in setup.md (before MODE parsing)
# Source error handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/setup"
WORKFLOW_ID="setup_$(date +%s)"
USER_ARGS="$*"
```

**Step 2: Validation Error Logging** (45 minutes)

Update all validation error exit points to log before exiting:

**Location 1: Line 49-51** (apply-report validation)
```bash
# Before
if [ "$MODE" = "apply-report" ] && [ -z "$REPORT_PATH" ]; then
  echo "ERROR: --apply-report requires path. Usage: /setup --apply-report <path> [dir]"
  exit 1
fi

# After
if [ "$MODE" = "apply-report" ] && [ -z "$REPORT_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Missing report path for --apply-report flag" \
    "bash_block" \
    '{"usage": "/setup --apply-report <path> [dir]"}'
  echo "ERROR: --apply-report requires path. Usage: /setup --apply-report <path> [dir]" >&2
  exit 1
fi
```

**Location 2: Line 52-54** (report file not found)
```bash
# After
if [ "$MODE" = "apply-report" ] && [ ! -f "$REPORT_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Report file not found: $REPORT_PATH" \
    "bash_block" \
    "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path, suggestion: "Run /setup --analyze first"}')"
  echo "ERROR: Report not found: $REPORT_PATH. Run /setup --analyze first." >&2
  exit 1
fi
```

**Location 3: Line 55-57** (dry-run validation)
```bash
# After
if [ "$DRY_RUN" = true ] && [ "$MODE" != "cleanup" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Invalid flag combination: --dry-run without --cleanup" \
    "bash_block" \
    '{"usage": "/setup --cleanup --dry-run [dir]"}'
  echo "ERROR: --dry-run requires --cleanup" >&2
  exit 1
fi
```

**Step 3: File Operation Error Logging** (60 minutes)

Add verification checkpoints with error logging after file creation:

**Phase 1 (Standard Mode) - After line 127**:
```bash
# After CLAUDE.md generation
if [ ! -f "$CLAUDE_MD_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "CLAUDE.md file not created at expected path" \
    "bash_block" \
    "$(jq -n --arg path "$CLAUDE_MD_PATH" '{expected_path: $path, phase: "standard_mode"}')"
  echo "ERROR: CLAUDE.md not created" >&2
  exit 1
fi

# Verify file has content
CLAUDE_MD_SIZE=$(wc -c < "$CLAUDE_MD_PATH" 2>/dev/null || echo 0)
if [ "$CLAUDE_MD_SIZE" -lt 100 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "CLAUDE.md file created but appears empty or invalid" \
    "bash_block" \
    "$(jq -n --arg path "$CLAUDE_MD_PATH" --argjson size "$CLAUDE_MD_SIZE" '{path: $path, size_bytes: $size, min_expected: 100}')"
  echo "ERROR: CLAUDE.md appears empty or invalid" >&2
  exit 1
fi
```

**Phase 2 (Cleanup Mode) - After line 162**:
```bash
# After cleanup execution
if [ $? -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "Cleanup script (optimize-claude-md.sh) failed" \
    "bash_block" \
    "$(jq -n --arg threshold "$THRESHOLD" --arg dry_run "$DRY_RUN" '{threshold: $threshold, dry_run: $dry_run, script: "optimize-claude-md.sh"}')"
  echo "ERROR: Cleanup failed" >&2
  exit 1
fi
```

**Phase 4 (Analysis Mode) - After line 247**:
```bash
# After report creation
if [ ! -f "$REPORT" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Analysis report not created at expected path" \
    "bash_block" \
    "$(jq -n --arg path "$REPORT" '{expected_path: $path, phase: "analysis_mode"}')"
  echo "ERROR: Report not created" >&2
  exit 1
fi
```

**Step 4: Testing** (60 minutes)

Create test suite `.claude/tests/test_setup_error_logging.sh`:

```bash
#!/usr/bin/env bash
# Test /setup command error logging integration

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test 1: Validation error logged
/setup --apply-report 2>&1 || true
if ! /errors --command /setup --type validation_error --limit 1 | grep -q "Missing report path"; then
  echo "FAIL: Validation error not logged"
  exit 1
fi

# Test 2: File error logged
/setup --apply-report /nonexistent/report.md 2>&1 || true
if ! /errors --command /setup --type file_error --limit 1 | grep -q "Report file not found"; then
  echo "FAIL: File error not logged"
  exit 1
fi

echo "PASS: /setup error logging integration"
```

**Verification Checklist**:
- ✅ All error exit points call `log_command_error()`
- ✅ Workflow metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS) captured
- ✅ Error types match taxonomy (validation_error, file_error, execution_error)
- ✅ Errors queryable via `/errors --command /setup`
- ✅ Context JSON includes actionable debugging information

#### Phase 1.2: /optimize-claude Command Error Logging

**Step 1: Library Integration** (30 minutes)

Add error-handling library sourcing in Phase 1:

```bash
# After line 29 in optimize-claude.md (after unified-location-detection sourcing)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/optimize-claude"
WORKFLOW_ID="optimize_$(date +%s)"
USER_ARGS="$*"
```

**Step 2: Path Validation Error Logging** (30 minutes)

Update path validation errors (lines 46, 61-62):

```bash
# After path allocation validation (line 46)
if [ -z "$TOPIC_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to allocate topic path via unified location detection" \
    "bash_block" \
    '{"location_json": "empty or invalid"}'
  echo "ERROR: Failed to allocate topic path" >&2
  exit 1
fi

# CLAUDE.md not found (line 61)
if [ ! -f "$CLAUDE_MD_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "CLAUDE.md not found at project root" \
    "bash_block" \
    "$(jq -n --arg path "$CLAUDE_MD_PATH" '{expected_path: $path, project_root: "'"$PROJECT_ROOT"'"}')"
  echo "ERROR: CLAUDE.md not found at $CLAUDE_MD_PATH" >&2
  exit 1
fi

# .claude/docs/ not found (line 62)
if [ ! -d "$DOCS_DIR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    ".claude/docs/ directory not found" \
    "bash_block" \
    "$(jq -n --arg path "$DOCS_DIR" '{expected_path: $path, project_root: "'"$PROJECT_ROOT"'"}')"
  echo "ERROR: .claude/docs/ not found at $DOCS_DIR" >&2
  exit 1
fi
```

**Step 3: Agent Error Parsing and Logging** (90 minutes)

Update all verification checkpoints (Phases 3, 5, 7) to parse agent error signals:

**Phase 3 (Research Verification) - Replace lines 124-145**:
```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying research reports..."

# Verify Report 1 (claude-md-analyzer)
if [ ! -f "$REPORT_PATH_1" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Agent claude-md-analyzer failed to create report" \
    "subagent_claude-md-analyzer" \
    "$(jq -n --arg path "$REPORT_PATH_1" '{expected_path: $path, phase: "research", agent: "claude-md-analyzer"}')"
  echo "ERROR: Agent 1 (claude-md-analyzer) failed to create report: $REPORT_PATH_1" >&2
  echo "This is a critical failure. Check agent logs above." >&2
  exit 1
fi

# Verify Report 2 (docs-structure-analyzer)
if [ ! -f "$REPORT_PATH_2" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Agent docs-structure-analyzer failed to create report" \
    "subagent_docs-structure-analyzer" \
    "$(jq -n --arg path "$REPORT_PATH_2" '{expected_path: $path, phase: "research", agent: "docs-structure-analyzer"}')"
  echo "ERROR: Agent 2 (docs-structure-analyzer) failed to create report: $REPORT_PATH_2" >&2
  echo "This is a critical failure. Check agent logs above." >&2
  exit 1
fi

echo "✓ CLAUDE.md analysis: $REPORT_PATH_1"
echo "✓ Docs structure analysis: $REPORT_PATH_2"
echo ""
echo "Bloat Analysis Stage: Analyzing documentation bloat risks..."
echo ""
```

**Phase 5 (Analysis Verification) - Replace lines 212-233**:
```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying analysis reports..."

# Verify Bloat Report
if [ ! -f "$BLOAT_REPORT_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Agent docs-bloat-analyzer failed to create report" \
    "subagent_docs-bloat-analyzer" \
    "$(jq -n --arg path "$BLOAT_REPORT_PATH" '{expected_path: $path, phase: "analysis", agent: "docs-bloat-analyzer"}')"
  echo "ERROR: Agent 3 (docs-bloat-analyzer) failed to create report: $BLOAT_REPORT_PATH" >&2
  echo "This is a critical failure. Check agent logs above." >&2
  exit 1
fi

# Verify Accuracy Report
if [ ! -f "$ACCURACY_REPORT_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Agent docs-accuracy-analyzer failed to create report" \
    "subagent_docs-accuracy-analyzer" \
    "$(jq -n --arg path "$ACCURACY_REPORT_PATH" '{expected_path: $path, phase: "analysis", agent: "docs-accuracy-analyzer"}')"
  echo "ERROR: Agent 4 (docs-accuracy-analyzer) failed to create report: $ACCURACY_REPORT_PATH" >&2
  echo "This is a critical failure. Check agent logs above." >&2
  exit 1
fi

echo "✓ Bloat analysis: $BLOAT_REPORT_PATH"
echo "✓ Accuracy analysis: $ACCURACY_REPORT_PATH"
echo ""
echo "Planning Stage: Generating optimization plan with bloat prevention and quality improvements..."
echo ""
```

**Phase 7 (Plan Verification) - Replace lines 281-293**:
```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying implementation plan..."

if [ ! -f "$PLAN_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Agent cleanup-plan-architect failed to create plan" \
    "subagent_cleanup-plan-architect" \
    "$(jq -n --arg path "$PLAN_PATH" '{expected_path: $path, phase: "planning", agent: "cleanup-plan-architect"}')"
  echo "ERROR: Agent 5 (cleanup-plan-architect) failed to create plan: $PLAN_PATH" >&2
  echo "This is a critical failure. Check agent logs above." >&2
  exit 1
fi

echo "✓ Implementation plan: $PLAN_PATH"
```

**Step 4: Testing** (60 minutes)

Create test suite `.claude/tests/test_optimize_claude_error_logging.sh`:

```bash
#!/usr/bin/env bash
# Test /optimize-claude command error logging integration

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test 1: CLAUDE.md not found error logged
cd "$TEST_DIR"
mkdir -p .claude/docs
/optimize-claude 2>&1 || true
if ! /errors --command /optimize-claude --type file_error --limit 1 | grep -q "CLAUDE.md not found"; then
  echo "FAIL: CLAUDE.md not found error not logged"
  exit 1
fi

# Test 2: Agent error logged on verification failure
# (Requires mock agent failure - manual testing recommended)

echo "PASS: /optimize-claude error logging integration"
```

**Verification Checklist**:
- ✅ All error exit points call `log_command_error()`
- ✅ Workflow metadata captured
- ✅ Agent errors include subagent attribution (source field)
- ✅ Verification checkpoints log before exit
- ✅ Errors queryable via `/errors --command /optimize-claude`

**Phase 1 Deliverables**:
- ✅ Error logging integrated in both commands
- ✅ All error types classified correctly (validation_error, file_error, agent_error, state_error, execution_error)
- ✅ Test suites passing
- ✅ Errors queryable via `/errors` command

---

### Phase 2: Bash Block Consolidation (High Priority)

**Objective**: Reduce bash block count to 2-3 blocks per command following Pattern 8 (Block Count Minimization) for cleaner output and faster execution.

**Scope**: /setup (6→4 blocks) and /optimize-claude (8→3 blocks)

**Estimated Effort**: 2-3 hours total (1-1.5 hours per command)

#### Phase 2.1: /setup Command Block Consolidation

**Current Structure** (6 blocks):
1. Phase 0: Argument parsing (lines 21-61)
2. Phase 1: Standard mode (lines 69-128)
3. Phase 2: Cleanup mode (lines 136-163)
4. Phase 3: Validation mode (lines 171-204)
5. Phase 4: Analysis mode (lines 212-247)
6. Phase 5-6: Report application + Enhancement mode (lines 255-307)

**Target Structure** (4 blocks):

**Block 1: Setup** (Consolidate Phase 0 + error logging init)
```bash
set +H

# === PROJECT DETECTION ===
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# === LIBRARY SOURCING ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# === ERROR LOGGING INITIALIZATION ===
ensure_error_log_exists
COMMAND_NAME="/setup"
WORKFLOW_ID="setup_$(date +%s)"
USER_ARGS="$*"

# === ARGUMENT PARSING ===
MODE="standard"; PROJECT_DIR=""; DRY_RUN=false; THRESHOLD="balanced"; REPORT_PATH=""

for arg in "$@"; do
  case "$arg" in
    --apply-report) shift; MODE="apply-report"; REPORT_PATH="$1"; shift ;;
    --enhance-with-docs) MODE="enhance" ;;
    --cleanup) MODE="cleanup" ;;
    --validate) MODE="validate" ;;
    --analyze) MODE="analyze" ;;
    --dry-run) DRY_RUN=true ;;
    --threshold) shift; THRESHOLD="$1"; shift ;;
    --*) echo "ERROR: Unknown flag: $arg"; exit 1 ;;
    *) [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$arg" ;;
  esac
done

# === VALIDATION ===
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$PWD"
[[ ! "$PROJECT_DIR" = /* ]] && PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"

if [ "$MODE" = "apply-report" ] && [ -z "$REPORT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
    "Missing report path for --apply-report flag" "bash_block" \
    '{"usage": "/setup --apply-report <path> [dir]"}'
  echo "ERROR: --apply-report requires path. Usage: /setup --apply-report <path> [dir]" >&2
  exit 1
fi

if [ "$MODE" = "apply-report" ] && [ ! -f "$REPORT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    "Report file not found: $REPORT_PATH" "bash_block" \
    "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path, suggestion: "Run /setup --analyze first"}')"
  echo "ERROR: Report not found: $REPORT_PATH. Run /setup --analyze first." >&2
  exit 1
fi

if [ "$DRY_RUN" = true ] && [ "$MODE" != "cleanup" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
    "Invalid flag combination: --dry-run without --cleanup" "bash_block" \
    '{"usage": "/setup --cleanup --dry-run [dir]"}'
  echo "ERROR: --dry-run requires --cleanup" >&2
  exit 1
fi

echo "Setup complete: Mode=$MODE | Project=$PROJECT_DIR | Workflow=$WORKFLOW_ID"
export MODE PROJECT_DIR DRY_RUN THRESHOLD REPORT_PATH COMMAND_NAME WORKFLOW_ID USER_ARGS
```

**Block 2: Execute (Mode-Specific)** (Keep phases 1-5 as-is with mode guards)
- Phase 1: Standard mode (if MODE=standard)
- Phase 2: Cleanup mode (if MODE=cleanup)
- Phase 3: Validation mode (if MODE=validate)
- Phase 4: Analysis mode (if MODE=analyze)
- Phase 5: Report application (if MODE=apply-report)

**Block 3: Enhancement Mode** (Keep Phase 6 separate)
- Phase 6: Enhancement mode delegation to /orchestrate

**Block 4: Completion** (Add new cleanup block)
```bash
set +H

# Mode-specific completion messages
case "$MODE" in
  standard)
    echo "✓ CLAUDE.md generation complete: $PROJECT_DIR/CLAUDE.md"
    ;;
  cleanup)
    echo "✓ CLAUDE.md cleanup complete"
    ;;
  validate)
    echo "✓ CLAUDE.md validation complete"
    ;;
  analyze)
    echo "✓ Standards analysis complete"
    ;;
  apply-report)
    echo "✓ Report application complete"
    ;;
  enhance)
    echo "✓ Enhancement workflow initiated"
    ;;
esac

echo "Workflow $WORKFLOW_ID complete"
```

**Consolidation Benefits**:
- **Before**: 6 blocks with repeated library detection and mode checking
- **After**: 4 blocks with single setup, mode-specific execution, separate enhancement, and cleanup
- **Reduction**: 33% fewer blocks
- **Impact**: Cleaner output, faster execution, better organization

#### Phase 2.2: /optimize-claude Command Block Consolidation

**Current Structure** (8 blocks):
1. Phase 1: Path allocation (lines 24-69)
2. Phase 2: Parallel research invocation (Task blocks - not bash)
3. Phase 3: Research verification (lines 123-145)
4. Phase 4: Parallel analysis invocation (Task blocks - not bash)
5. Phase 5: Analysis verification (lines 212-233)
6. Phase 6: Sequential planning invocation (Task block - not bash)
7. Phase 7: Plan verification (lines 281-293)
8. Phase 8: Results display (lines 300-318)

**Target Structure** (3 blocks):

**Block 1: Setup and Path Allocation**
```bash
set -euo pipefail

# === PROJECT DETECTION ===
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# === LIBRARY SOURCING ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# === ERROR LOGGING INITIALIZATION ===
ensure_error_log_exists
COMMAND_NAME="/optimize-claude"
WORKFLOW_ID="optimize_$(date +%s)"
USER_ARGS="$*"

# === HEADER ===
echo "=== /optimize-claude: CLAUDE.md Optimization Workflow ==="
echo ""

# === PATH ALLOCATION ===
LOCATION_JSON=$(perform_location_detection "optimize CLAUDE.md structure")

TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
SPECS_DIR=$(echo "$LOCATION_JSON" | jq -r '.specs_dir')
PROJECT_ROOT=$(echo "$LOCATION_JSON" | jq -r '.project_root')

if [ -z "$TOPIC_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "state_error" \
    "Failed to allocate topic path via unified location detection" "bash_block" \
    '{"location_json": "empty or invalid"}'
  echo "ERROR: Failed to allocate topic path" >&2
  exit 1
fi

# Calculate artifact paths
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
REPORT_PATH_1="${REPORTS_DIR}/001_claude_md_analysis.md"
REPORT_PATH_2="${REPORTS_DIR}/002_docs_structure_analysis.md"
BLOAT_REPORT_PATH="${REPORTS_DIR}/003_bloat_analysis.md"
ACCURACY_REPORT_PATH="${REPORTS_DIR}/004_accuracy_analysis.md"
PLAN_PATH="${PLANS_DIR}/001_optimization_plan.md"

# Set paths for analysis
CLAUDE_MD_PATH="${PROJECT_ROOT}/CLAUDE.md"
DOCS_DIR="${PROJECT_ROOT}/.claude/docs"

# === VALIDATION ===
if [ ! -f "$CLAUDE_MD_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    "CLAUDE.md not found at project root" "bash_block" \
    "$(jq -n --arg path "$CLAUDE_MD_PATH" '{expected_path: $path, project_root: "'"$PROJECT_ROOT"'"}')"
  echo "ERROR: CLAUDE.md not found at $CLAUDE_MD_PATH" >&2
  exit 1
fi

if [ ! -d "$DOCS_DIR" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    ".claude/docs/ directory not found" "bash_block" \
    "$(jq -n --arg path "$DOCS_DIR" '{expected_path: $path, project_root: "'"$PROJECT_ROOT"'"}')"
  echo "ERROR: .claude/docs/ not found at $DOCS_DIR" >&2
  exit 1
fi

echo "Setup complete: Topic=$TOPIC_PATH | Workflow=$WORKFLOW_ID"
echo "Research Stage: Analyzing CLAUDE.md and documentation..."
echo "  → Analyzing CLAUDE.md structure (balanced threshold: 80 lines)"
echo "  → Analyzing .claude/docs/ organization"
echo ""

# Export for agent access
export CLAUDE_MD_PATH DOCS_DIR PROJECT_ROOT REPORT_PATH_1 REPORT_PATH_2
export BLOAT_REPORT_PATH ACCURACY_REPORT_PATH PLAN_PATH
export COMMAND_NAME WORKFLOW_ID USER_ARGS
```

**Block 2: Agent Execution with Inline Verification**
- Keep Phase 2: Parallel research invocation (Task blocks)
- **Inline verification** after research agents complete
- Keep Phase 4: Parallel analysis invocation (Task blocks)
- **Inline verification** after analysis agents complete
- Keep Phase 6: Sequential planning invocation (Task block)
- **Inline verification** after planning agent completes

Replace separate verification bash blocks with inline verification after each agent stage:

```bash
# After Phase 2 (Research agents)
**EXECUTE NOW**: After research agents complete, verify reports in same block:

# Verification function (called after agents return)
verify_reports() {
  local report1="$1"
  local report2="$2"
  local missing=0

  if [ ! -f "$report1" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
      "Agent claude-md-analyzer failed to create report" "subagent_claude-md-analyzer" \
      "$(jq -n --arg path "$report1" '{expected_path: $path, phase: "research", agent: "claude-md-analyzer"}')"
    echo "ERROR: Agent 1 (claude-md-analyzer) failed to create report: $report1" >&2
    ((missing++))
  fi

  if [ ! -f "$report2" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
      "Agent docs-structure-analyzer failed to create report" "subagent_docs-structure-analyzer" \
      "$(jq -n --arg path "$report2" '{expected_path: $path, phase: "research", agent: "docs-structure-analyzer"}')"
    echo "ERROR: Agent 2 (docs-structure-analyzer) failed to create report: $report2" >&2
    ((missing++))
  fi

  return $missing
}

# Call verification after research
verify_reports "$REPORT_PATH_1" "$REPORT_PATH_2" || exit 1
echo "✓ Research complete: 2 reports created"
echo ""
echo "Bloat Analysis Stage: Analyzing documentation bloat risks..."
echo ""
```

**Block 3: Results Display and Completion**
```bash
set +H

# Display results
echo ""
echo "=== Optimization Plan Generated ==="
echo ""
echo "Research Reports:"
echo "  • CLAUDE.md analysis: $REPORT_PATH_1"
echo "  • Docs structure analysis: $REPORT_PATH_2"
echo ""
echo "Analysis Reports:"
echo "  • Bloat analysis: $BLOAT_REPORT_PATH"
echo "  • Accuracy analysis: $ACCURACY_REPORT_PATH"
echo ""
echo "Implementation Plan:"
echo "  • $PLAN_PATH"
echo ""
echo "Next Steps:"
echo "  Review the plan and run: /implement $PLAN_PATH"
echo ""
echo "Workflow $WORKFLOW_ID complete"
```

**Consolidation Benefits**:
- **Before**: 8 blocks (1 setup + 3 verification + 1 display = 5 bash blocks, 3 Task blocks)
- **After**: 3 blocks (1 setup + 1 inline verification + 1 display)
- **Reduction**: 63% fewer bash blocks
- **Impact**: Dramatic output cleanup, single-page command execution view

**Phase 2 Deliverables**:
- ✅ /setup: 6→4 blocks (33% reduction)
- ✅ /optimize-claude: 8→3 blocks (63% reduction)
- ✅ Single summary line per block
- ✅ All functionality preserved
- ✅ Verification checkpoints maintained

---

### Phase 3: Documentation and Consistency (Medium Priority)

**Objective**: Improve guide files, standardize agent invocation patterns, and ensure comprehensive troubleshooting coverage.

**Scope**: Guide file improvements, agent integration consistency, output suppression completeness

**Estimated Effort**: 4-5 hours total (2-2.5 hours per command)

#### Phase 3.1: Guide File Improvements

**Step 1: /setup Guide Extraction** (90 minutes)

Current guide: 1,241 lines with embedded sections that should be extracted

**Extraction Strategy**:

**Keep in setup-command-guide.md**:
- Overview and quick start
- Mode descriptions (6 modes)
- Architecture overview
- Common usage patterns
- Troubleshooting (expand this section)

**Extract to separate files**:
1. `.claude/docs/guides/setup/setup-modes-detailed.md` (lines 266-600)
   - Deep dive into each mode with examples
   - Mode precedence rules
   - Mode combinations and edge cases

2. `.claude/docs/guides/setup/extraction-strategies.md` (lines 601-900)
   - Section extraction algorithms
   - Threshold profiles (aggressive/balanced/conservative)
   - Extraction examples and case studies

3. `.claude/docs/guides/setup/testing-detection-guide.md` (lines 901-1100)
   - Framework detection algorithms
   - Scoring system details
   - Adding custom framework detection

4. `.claude/docs/guides/setup/claude-md-templates.md` (lines 1101-1240)
   - CLAUDE.md structure templates
   - Section templates for different project types
   - Customization examples

**New sections to add**:
- Troubleshooting (expand from current 4 scenarios to 10+)
- Integration with /optimize-claude workflow
- Migration guide for existing projects
- Performance tuning for large codebases

**Updated guide structure**:
```markdown
# /setup Command - Complete Guide

**Executable**: `.claude/commands/setup.md`

## Table of Contents
1. Overview
2. Quick Start
3. Mode Reference
   - Standard Mode
   - Cleanup Mode
   - Validation Mode
   - Analysis Mode
   - Report Application Mode
   - Enhancement Mode
4. Architecture
5. Usage Patterns
   - New project setup
   - Existing project migration
   - Continuous optimization
6. Integration with Other Commands
   - /optimize-claude workflow
   - /orchestrate enhancement
7. Troubleshooting (expanded)
8. Advanced Topics
   - Custom threshold profiles
   - Framework detection customization
   - Template customization
9. Reference
   - Mode precedence rules
   - Command-line flags
   - Environment variables

## See Also
- [Setup Modes Detailed Guide](../setup/setup-modes-detailed.md)
- [Extraction Strategies](../setup/extraction-strategies.md)
- [Testing Detection Guide](../setup/testing-detection-guide.md)
- [CLAUDE.md Templates](../setup/claude-md-templates.md)
```

**Step 2: /optimize-claude Guide Enhancement** (90 minutes)

Current guide: 393 lines with good architecture but limited troubleshooting

**Add sections**:

1. **Agent Development Section** (new, 100 lines)
   - How to create new analyzer agents
   - Agent behavioral guidelines template
   - Agent integration checklist
   - Example: Creating a custom-rule-analyzer agent

2. **Customization Guide** (new, 80 lines)
   - Threshold configuration (aggressive/balanced/conservative)
   - Agent selection and weighting
   - Custom bloat detection rules
   - Output format customization

3. **Troubleshooting Expansion** (expand from 4 to 12+ scenarios)
   - Agent timeout issues
   - Report creation failures
   - Bloat analysis edge cases
   - Accuracy analyzer false positives
   - Plan generation failures
   - Integration with /implement issues

4. **Performance Optimization** (new, 60 lines)
   - Parallel agent execution metrics
   - Reducing analysis time for large projects
   - Caching strategies
   - Incremental optimization

**Updated guide structure**:
```markdown
# /optimize-claude Command - Complete Guide

**Executable**: `.claude/commands/optimize-claude.md`

## Table of Contents
1. Overview
2. Quick Start
3. Architecture
   - Multi-stage agent workflow
   - Path allocation strategy
   - Verification checkpoints
4. Agent Reference
   - claude-md-analyzer
   - docs-structure-analyzer
   - docs-bloat-analyzer
   - docs-accuracy-analyzer
   - cleanup-plan-architect
5. Usage Patterns
   - Basic optimization workflow
   - Targeted section optimization
   - Iterative refinement
6. Customization
   - Threshold profiles
   - Agent selection
   - Custom detection rules
7. Agent Development (new)
   - Creating new analyzer agents
   - Behavioral guidelines template
   - Integration checklist
8. Troubleshooting (expanded)
9. Performance Optimization (new)
10. Integration with Other Commands
    - /setup → /optimize-claude → /implement workflow

## See Also
- [Bloat Analysis Patterns](../../concepts/patterns/bloat-analysis.md)
- [Documentation Quality Standards](../../reference/standards/documentation-quality.md)
```

#### Phase 3.2: Agent Integration Consistency

**Step 1: /setup Phase 6 Refactor** (30 minutes)

Update `/setup` Phase 6 (Enhancement Mode) to use Task tool with behavioral injection instead of SlashCommand:

**Current** (lines 292-307):
```markdown
## Phase 6: Enhancement Mode

**EXECUTE NOW**: Execute when MODE=enhance

```bash
[ "$MODE" != "enhance" ] && echo "Skipping Phase 6" && exit 0

echo "Phase 6: Enhancement (delegating to /orchestrate)"
echo "Project: $PROJECT_DIR"

ORCH_MSG="Analyze documentation at ${PROJECT_DIR}, enhance CLAUDE.md.

Phase 1: Research (parallel) - Docs discovery, test analysis, TDD detection
Phase 2: Planning - Gap analysis
Phase 3: Implementation - Update CLAUDE.md
Phase 4: Documentation - Workflow summary

Project: ${PROJECT_DIR}"

echo "Invoking /orchestrate..."
echo "$ORCH_MSG"
echo "Wait for /orchestrate to complete"
```
```

**Updated** (behavioral injection pattern):
```markdown
## Phase 6: Enhancement Mode

**EXECUTE NOW**: Execute when MODE=enhance

```bash
set +H

[ "$MODE" != "enhance" ] && echo "Skipping Phase 6" && exit 0

echo "Phase 6: Enhancement (delegating to orchestration workflow)"
echo "Project: $PROJECT_DIR"
echo ""
```

**EXECUTE NOW**: USE the Task tool to invoke orchestration workflow.

```
Task {
  subagent_type: "general-purpose"
  description: "Enhance CLAUDE.md with documentation analysis"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md

    **Workflow Context**:
    - Project Directory: ${PROJECT_DIR}
    - Goal: Analyze documentation and enhance CLAUDE.md with discovered patterns
    - Workflow Type: documentation-enhancement

    **Phases**:
    1. Research (parallel) - Docs discovery, test analysis, TDD detection
    2. Planning - Gap analysis and enhancement recommendations
    3. Implementation - Update CLAUDE.md with new sections
    4. Documentation - Workflow summary

    **Critical Requirements**:
    - MUST read CLAUDE.md at ${PROJECT_DIR}/CLAUDE.md before making changes
    - MUST preserve existing sections and only add/enhance
    - MUST create backup before modifications
    - MUST return completion signal: WORKFLOW_COMPLETE

    Execute orchestration workflow per behavioral guidelines.
    Return completion signal with summary of changes made.
  "
}

# Parse completion signal
if echo "$output" | grep -q "WORKFLOW_COMPLETE"; then
  echo "✓ Enhancement complete"
else
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
    "Orchestration workflow failed or did not complete" "subagent_orchestrate" \
    '{"phase": "enhancement", "expected_signal": "WORKFLOW_COMPLETE"}'
  echo "ERROR: Enhancement workflow did not complete successfully" >&2
  exit 1
fi
```
```

**Rationale**: Consistent with modern agent invocation pattern used in /optimize-claude and other recent commands

#### Phase 3.3: Output Suppression Completeness

**Step 1: Audit and Update** (30 minutes per command)

Ensure all library sourcing uses `2>/dev/null` pattern and all success operations are suppressed:

**/setup command**:
- Line 82: `DETECT_OUTPUT=$("${LIB_DIR}/detect-testing.sh" "$PROJECT_DIR" 2>&1)` - Already good
- Line 87: `TESTING_SECTION=$("${LIB_DIR}/generate-testing-protocols.sh" "$TEST_SCORE" "$TEST_FRAMEWORKS" 2>&1)` - Already good
- Line 160: `"${LIB_DIR}/optimize-claude-md.sh" "$CLAUDE_MD_PATH" $FLAGS` - Add output suppression

**Updated**:
```bash
"${LIB_DIR}/optimize-claude-md.sh" "$CLAUDE_MD_PATH" $FLAGS 2>&1 | grep -E "^(ERROR|WARN|✓)" || true
```

**/optimize-claude command**:
- Already has good suppression via `2>/dev/null` on library sourcing
- Consider suppressing intermediate progress from location detection

**Step 2: Single Summary Line Enforcement** (30 minutes per command)

Review all echo statements and consolidate into single summary per block:

**Examples of consolidation**:

Before:
```bash
echo "Starting research..."
echo "Invoking agent 1..."
echo "Invoking agent 2..."
echo "Research complete"
```

After:
```bash
# Perform all operations silently, then single summary
echo "Research complete: 2 agents | 2 reports created"
```

**Phase 3 Deliverables**:
- ✅ /setup guide extracted and reorganized
- ✅ /optimize-claude guide enhanced with 4 new sections
- ✅ /setup Phase 6 uses Task tool with behavioral injection
- ✅ Output suppression complete and consistent
- ✅ Single summary line per block enforced

---

### Phase 4: Enhancement Features (Low Priority - Optional)

**Objective**: Add user-facing enhancement features for improved usability and flexibility.

**Scope**: Threshold configuration, dry-run support, interactive mode

**Estimated Effort**: 2-3 hours total

**Note**: These enhancements are optional and can be deferred to future iterations.

#### Phase 4.1: Threshold Configuration for /optimize-claude

**Add --threshold flag support** (60 minutes)

Currently hardcoded to "balanced" threshold (80 lines). Add flag support:

**Step 1: Argument Parsing** (Phase 1)

Add after path allocation:
```bash
# Parse optional --threshold flag
THRESHOLD="balanced"  # Default

for arg in "$@"; do
  case "$arg" in
    --threshold)
      shift
      THRESHOLD="$1"
      shift
      ;;
    --aggressive)
      THRESHOLD="aggressive"
      shift
      ;;
    --balanced)
      THRESHOLD="balanced"
      shift
      ;;
    --conservative)
      THRESHOLD="conservative"
      shift
      ;;
    *)
      echo "ERROR: Unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

# Validate threshold
case "$THRESHOLD" in
  aggressive|balanced|conservative) ;;
  *)
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
      "Invalid threshold: $THRESHOLD" "bash_block" \
      '{"valid_values": ["aggressive", "balanced", "conservative"]}'
    echo "ERROR: Invalid threshold: $THRESHOLD" >&2
    echo "Valid: aggressive, balanced, conservative" >&2
    exit 1
    ;;
esac

export THRESHOLD
```

**Step 2: Pass to Agents** (Phase 2)

Update claude-md-analyzer agent invocation:
```markdown
Task {
  ...
  prompt: "
    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_PATH: ${CLAUDE_MD_PATH}
    - REPORT_PATH: ${REPORT_PATH_1}
    - THRESHOLD: ${THRESHOLD}  ← Pass threshold
    ...
  "
}
```

**Step 3: Update Guide** (10 minutes)

Document in optimize-claude-command-guide.md:
```markdown
## Usage

### Basic Usage
/optimize-claude

### With Custom Threshold
/optimize-claude --threshold aggressive
/optimize-claude --aggressive  # Shorthand

### Threshold Profiles
- **aggressive**: Extract sections >50 lines (maximum reduction)
- **balanced**: Extract sections >80 lines (default, recommended)
- **conservative**: Extract sections >120 lines (minimal extraction)
```

#### Phase 4.2: Dry-Run Support for /optimize-claude

**Add --dry-run flag support** (60 minutes)

Preview agent workflow without execution:

**Step 1: Argument Parsing**
```bash
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    ...
  esac
done
```

**Step 2: Dry-Run Logic** (Phase 1, after path allocation)
```bash
if [ "$DRY_RUN" = true ]; then
  echo "=== Dry-Run Mode: Preview Only ==="
  echo ""
  echo "Would execute workflow:"
  echo "  1. Research Stage (2 agents, parallel)"
  echo "     → claude-md-analyzer: $REPORT_PATH_1"
  echo "     → docs-structure-analyzer: $REPORT_PATH_2"
  echo ""
  echo "  2. Analysis Stage (2 agents, parallel)"
  echo "     → docs-bloat-analyzer: $BLOAT_REPORT_PATH"
  echo "     → docs-accuracy-analyzer: $ACCURACY_REPORT_PATH"
  echo ""
  echo "  3. Planning Stage (1 agent, sequential)"
  echo "     → cleanup-plan-architect: $PLAN_PATH"
  echo ""
  echo "Estimated time: 3-5 minutes (depends on project size)"
  echo ""
  echo "To execute, run: /optimize-claude"
  echo ""
  exit 0
fi
```

#### Phase 4.3: Interactive Mode for /setup

**Add --interactive flag support** (60 minutes)

Guide users through setup with prompts:

**Step 1: Argument Parsing**
```bash
INTERACTIVE=false

for arg in "$@"; do
  case "$arg" in
    --interactive) INTERACTIVE=true ;;
    ...
  esac
done
```

**Step 2: Interactive Prompts** (Phase 1)
```bash
if [ "$INTERACTIVE" = true ]; then
  echo "=== Interactive Setup ==="
  echo ""

  # Project type
  echo "What type of project is this?"
  echo "1) Web application"
  echo "2) Library/package"
  echo "3) CLI tool"
  echo "4) Documentation"
  read -p "Selection [1-4]: " project_type

  # Testing framework
  echo ""
  echo "Which testing frameworks do you use? (comma-separated)"
  echo "Examples: pytest, jest, vitest, mocha, cargo-test"
  read -p "Frameworks: " test_frameworks

  # Generate custom CLAUDE.md based on responses
  # ...
fi
```

**Phase 4 Deliverables** (Optional):
- ✅ /optimize-claude: --threshold flag support
- ✅ /optimize-claude: --dry-run flag support
- ✅ /setup: --interactive flag support
- ✅ Guide documentation updated

---

## Section 3: Testing and Validation Strategy

### 3.1 Test Suite Architecture

**Test Organization**:
```
.claude/tests/
├── test_setup_command.sh                    # /setup integration tests
├── test_setup_error_logging.sh              # /setup error logging tests
├── test_optimize_claude_command.sh          # /optimize-claude integration tests
├── test_optimize_claude_error_logging.sh    # /optimize-claude error logging tests
└── test_command_modernization.sh            # Cross-command integration tests
```

### 3.2 Test Coverage Requirements

**Per-Command Test Coverage**:

**/setup command tests**:
1. ✅ Mode detection (all 6 modes)
2. ✅ Argument parsing (all flags and combinations)
3. ✅ Validation errors (logged and queryable)
4. ✅ File creation (CLAUDE.md, reports, backups)
5. ✅ Standards integration (detect-testing.sh, generate-testing-protocols.sh)
6. ✅ Error logging integration (all exit points)
7. ✅ Bash block count (verify 4 blocks)
8. ✅ Agent invocation (Phase 6 behavioral injection)

**/optimize-claude command tests**:
1. ✅ Path allocation (unified location detection)
2. ✅ Validation errors (CLAUDE.md not found, .claude/docs/ not found)
3. ✅ Agent invocations (5 agents, correct parameters)
4. ✅ Verification checkpoints (3 checkpoints, fail-fast)
5. ✅ Error logging integration (all error types)
6. ✅ Bash block count (verify 3 blocks)
7. ✅ Report creation (4 reports + 1 plan)
8. ✅ Parallel execution (research and analysis stages)

**Cross-Command Integration Tests**:
1. ✅ /setup → /optimize-claude workflow
2. ✅ /optimize-claude → /implement workflow
3. ✅ Error logging integration with /errors command
4. ✅ Standards compliance validation

### 3.3 Test Implementation Examples

**Example 1: /setup Error Logging Test**
```bash
#!/usr/bin/env bash
# test_setup_error_logging.sh

set -euo pipefail

echo "Testing /setup error logging integration..."

# Test 1: Validation error logged
echo "Test 1: Validation error (missing report path)"
/setup --apply-report 2>&1 || true

if /errors --command /setup --type validation_error --limit 1 | grep -q "Missing report path"; then
  echo "✓ PASS: Validation error logged"
else
  echo "✗ FAIL: Validation error not logged"
  exit 1
fi

# Test 2: File error logged
echo "Test 2: File error (report not found)"
/setup --apply-report /nonexistent/report.md 2>&1 || true

if /errors --command /setup --type file_error --limit 1 | grep -q "Report file not found"; then
  echo "✓ PASS: File error logged"
else
  echo "✗ FAIL: File error not logged"
  exit 1
fi

# Test 3: Invalid flag combination
echo "Test 3: Validation error (invalid flag combination)"
/setup --dry-run 2>&1 || true

if /errors --command /setup --type validation_error --limit 1 | grep -q "Invalid flag combination"; then
  echo "✓ PASS: Invalid flag combination logged"
else
  echo "✗ FAIL: Invalid flag combination not logged"
  exit 1
fi

echo ""
echo "All tests passed for /setup error logging"
```

**Example 2: /optimize-claude Block Count Test**
```bash
#!/usr/bin/env bash
# test_optimize_claude_blocks.sh

set -euo pipefail

echo "Testing /optimize-claude bash block count..."

# Run command and capture output
output=$(/optimize-claude 2>&1 || true)

# Count bash block markers (blocks start with "set -euo pipefail" or "set +H")
block_count=$(echo "$output" | grep -c "^set -" || echo 0)

if [ "$block_count" -eq 3 ]; then
  echo "✓ PASS: Correct block count (3 blocks)"
else
  echo "✗ FAIL: Expected 3 blocks, found $block_count"
  exit 1
fi

echo "Block count test passed"
```

**Example 3: Cross-Command Workflow Test**
```bash
#!/usr/bin/env bash
# test_command_modernization.sh

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Testing /setup → /optimize-claude workflow..."

cd "$TEST_DIR"

# Step 1: Create project structure
mkdir -p .claude/docs
touch README.md

# Step 2: Run /setup to create CLAUDE.md
echo "Step 1: Running /setup..."
/setup . 2>&1 || {
  echo "✗ FAIL: /setup failed"
  exit 1
}

if [ ! -f "./CLAUDE.md" ]; then
  echo "✗ FAIL: CLAUDE.md not created"
  exit 1
fi

echo "✓ PASS: /setup created CLAUDE.md"

# Step 3: Run /optimize-claude to generate optimization plan
echo "Step 2: Running /optimize-claude..."
/optimize-claude 2>&1 || {
  echo "✗ FAIL: /optimize-claude failed"
  exit 1
}

# Verify plan created
plan_file=$(find .claude/specs -name "001_optimization_plan.md" 2>/dev/null | head -1)
if [ -z "$plan_file" ]; then
  echo "✗ FAIL: Optimization plan not created"
  exit 1
fi

echo "✓ PASS: /optimize-claude created plan: $plan_file"

# Step 4: Verify errors queryable
echo "Step 3: Testing error queryability..."
/errors --command /setup --limit 5 >/dev/null 2>&1
/errors --command /optimize-claude --limit 5 >/dev/null 2>&1

echo "✓ PASS: Error queries successful"

echo ""
echo "All workflow tests passed"
```

### 3.4 Validation Checklist

**Pre-Deployment Validation**:
- ✅ All test suites pass (100% pass rate)
- ✅ Error logging compliance verified (test_error_logging_compliance.sh)
- ✅ Bash block count verified (manual inspection and automated test)
- ✅ Guide files comprehensive (manual review)
- ✅ Cross-references validated (validate-links-quick.sh)
- ✅ No regressions in existing functionality
- ✅ Performance metrics recorded (execution time before/after)

---

## Section 4: Migration and Rollback Strategy

### 4.1 Phased Migration Timeline

**Week 1: Phase 1 - Error Logging**
- Day 1-2: /setup error logging integration
- Day 3-4: /optimize-claude error logging integration
- Day 5: Testing and verification

**Week 2: Phase 2 - Bash Block Consolidation**
- Day 1-2: /setup block consolidation
- Day 3-4: /optimize-claude block consolidation
- Day 5: Testing and verification

**Week 3: Phase 3 - Documentation and Consistency**
- Day 1-2: Guide file improvements
- Day 3: Agent integration consistency
- Day 4: Output suppression completeness
- Day 5: Testing and validation

**Week 4: Phase 4 - Enhancement Features (Optional)**
- Day 1: Threshold configuration
- Day 2: Dry-run support
- Day 3: Interactive mode
- Day 4-5: Testing and documentation

### 4.2 Backup Strategy

**Pre-Migration Backups**:
```bash
# Create backup directory
mkdir -p .claude/backups/commands/

# Backup commands
cp .claude/commands/setup.md \
   .claude/backups/commands/setup.md.before-modernization

cp .claude/commands/optimize-claude.md \
   .claude/backups/commands/optimize-claude.md.before-modernization

# Backup guides
cp .claude/docs/guides/commands/setup-command-guide.md \
   .claude/backups/commands/setup-command-guide.md.before-modernization

cp .claude/docs/guides/commands/optimize-claude-command-guide.md \
   .claude/backups/commands/optimize-claude-command-guide.md.before-modernization

# Tag git commit
git add .claude/backups/
git commit -m "backup: Pre-modernization backups for /setup and /optimize-claude"
git tag setup-optimize-modernization-start
```

**Per-Phase Backups**:
```bash
# After Phase 1
git commit -m "feat: Phase 1 - Error logging integration for /setup and /optimize-claude"
git tag setup-optimize-phase1-complete

# After Phase 2
git commit -m "feat: Phase 2 - Bash block consolidation for /setup and /optimize-claude"
git tag setup-optimize-phase2-complete

# After Phase 3
git commit -m "feat: Phase 3 - Documentation and consistency improvements"
git tag setup-optimize-phase3-complete

# After Phase 4 (optional)
git commit -m "feat: Phase 4 - Enhancement features"
git tag setup-optimize-phase4-complete
```

### 4.3 Rollback Procedures

**Rollback to Pre-Modernization State**:
```bash
# Option 1: Git revert to tagged commit
git checkout setup-optimize-modernization-start

# Option 2: Restore from backups
cp .claude/backups/commands/setup.md.before-modernization \
   .claude/commands/setup.md

cp .claude/backups/commands/optimize-claude.md.before-modernization \
   .claude/commands/optimize-claude.md

cp .claude/backups/commands/setup-command-guide.md.before-modernization \
   .claude/docs/guides/commands/setup-command-guide.md

cp .claude/backups/commands/optimize-claude-command-guide.md.before-modernization \
   .claude/docs/guides/commands/optimize-claude-command-guide.md

# Verify rollback
/setup --validate
/optimize-claude --help  # Ensure command still loads
```

**Rollback Single Phase**:
```bash
# If Phase 2 causes issues, revert to Phase 1
git revert <phase-2-commit-hash>
git checkout setup-optimize-phase1-complete -- .claude/commands/

# Verify functionality
bash .claude/tests/test_setup_command.sh
bash .claude/tests/test_optimize_claude_command.sh
```

### 4.4 Success Metrics and Validation

**Quantitative Metrics**:

| Metric | Before | Target | Measurement Method |
|--------|--------|--------|-------------------|
| Error logging coverage | 0% | 100% | Count error exit points with log_command_error() |
| Bash block count (/setup) | 6 | 4 | Manual count in command file |
| Bash block count (/optimize-claude) | 8 | 3 | Manual count in command file |
| Guide completeness | 70% | 90% | Manual review checklist |
| Test coverage | 0% | 80% | Coverage report from test suites |
| Error queryability | N/A | 100% | `/errors --command` queries succeed |

**Qualitative Metrics**:
- ✅ User feedback: "Errors are debuggable with /errors command"
- ✅ Developer feedback: "Guide files are comprehensive and helpful"
- ✅ Execution observation: "Output is clean and professional"
- ✅ Maintenance assessment: "Commands are easier to understand and modify"

**Post-Deployment Verification**:
1. Run all test suites (100% pass rate required)
2. Execute /setup with all 6 modes (verify each mode works)
3. Execute /optimize-claude end-to-end (verify all 5 agents succeed)
4. Query errors: `/errors --command /setup --limit 10`
5. Query errors: `/errors --command /optimize-claude --limit 10`
6. Measure execution time (should be same or faster after block consolidation)
7. Review output (should be significantly cleaner)

---

## Section 5: Risk Analysis and Mitigation

### 5.1 Implementation Risks

**Risk 1: Breaking Existing Workflows** (High Impact)

**Likelihood**: Medium
**Impact**: High (users unable to run commands)

**Mitigation**:
- Extensive testing before deployment (80%+ test coverage)
- Backward compatibility validation (existing invocations still work)
- Rollback plan with tagged commits
- Phased migration with verification at each phase

**Risk 2: Error Logging Performance Overhead** (Low Impact)

**Likelihood**: Low
**Impact**: Low (negligible <10ms per log call)

**Mitigation**:
- Performance testing (measure execution time before/after)
- Error logging is append-only (no locking)
- Rotation prevents unbounded growth (10MB threshold)

**Risk 3: Bash Block Consolidation Logic Errors** (Medium Impact)

**Likelihood**: Medium
**Impact**: Medium (command execution fails or produces incorrect results)

**Mitigation**:
- Careful review of consolidated blocks
- Verify all operations preserve order dependencies
- Test each block independently
- Manual verification of output correctness

**Risk 4: Agent Integration Breaking Downstream** (Low Impact)

**Likelihood**: Low
**Impact**: Medium (enhancement mode fails)

**Mitigation**:
- Behavioral injection pattern is well-tested in other commands
- Test orchestration workflow independently
- Fallback to manual orchestration if agent fails

### 5.2 Adoption Risks

**Risk 1: User Confusion with Error Logging** (Low Impact)

**Likelihood**: Low
**Impact**: Low (users unfamiliar with /errors command)

**Mitigation**:
- Document error logging in guide files
- Add examples in troubleshooting sections
- Error messages include suggestion to check `/errors`

**Risk 2: Threshold Configuration Complexity** (Low Impact)

**Likelihood**: Low
**Impact**: Low (users choose wrong threshold)

**Mitigation**:
- Sensible default (balanced)
- Clear documentation of each threshold profile
- Examples in guide showing when to use each

**Risk 3: Guide File Comprehension** (Medium Impact)

**Likelihood**: Medium
**Impact**: Medium (developers struggle to understand system)

**Mitigation**:
- Clear structure with table of contents
- Progressive disclosure (overview → details → advanced)
- Examples throughout
- Cross-references to related documentation

### 5.3 Risk Matrix

| Risk | Likelihood | Impact | Priority | Mitigation Effort |
|------|-----------|--------|----------|------------------|
| Breaking workflows | Medium | High | P1 | High (extensive testing) |
| Logic errors | Medium | Medium | P2 | Medium (careful review) |
| Guide comprehension | Medium | Medium | P3 | Medium (documentation) |
| Error logging overhead | Low | Low | P4 | Low (performance testing) |
| User confusion | Low | Low | P5 | Low (documentation) |
| Agent integration | Low | Medium | P3 | Low (pattern proven) |
| Threshold complexity | Low | Low | P5 | Low (defaults + docs) |

---

## Section 6: Comparison with Reference Commands

### 6.1 Target Architecture Alignment

**Reference Command: /plan** (426 lines, 3 blocks, full standards compliance)

**Alignment Matrix**:

| Standard | /plan (Reference) | /setup (Target) | /optimize-claude (Target) |
|----------|------------------|----------------|--------------------------|
| **Error Logging** | ✅ Integrated | ✅ Integrated | ✅ Integrated |
| **Bash Blocks** | ✅ 3 blocks | ✅ 4 blocks | ✅ 3 blocks |
| **Guide File** | ✅ 460 lines | ✅ Enhanced | ✅ Enhanced |
| **Agent Pattern** | ✅ Task tool | ✅ Task tool | ✅ Task tool |
| **Verification** | ✅ Checkpoints | ✅ Checkpoints | ✅ Checkpoints |
| **Output** | ✅ Suppressed | ✅ Suppressed | ✅ Suppressed |

**Architectural Lessons from /plan**:

1. **Consolidated Setup Block** (lines 36-150)
   - Single block handles: capture, parse, detect, source, initialize, allocate
   - Both /setup and /optimize-claude will adopt this pattern

2. **State Machine Integration**
   - /plan uses workflow-state-machine.sh for state tracking
   - /setup and /optimize-claude are stateless but can benefit from workflow ID tracking

3. **Error Logging Pattern**
   - /plan logs at: validation errors, file errors, agent errors
   - Both commands will adopt identical pattern

4. **Verification Pattern**
   - /plan verifies state file, workflow ID, feature description
   - Both commands will verify file creation and agent completion

### 6.2 Post-Modernization Command Metrics

**Expected Metrics After Modernization**:

| Command | Lines | Blocks | Error Log | Guide | Agent Pattern | Compliance |
|---------|-------|--------|-----------|-------|--------------|-----------|
| /setup | 311 | 4 | ✅ | ✅ | ✅ | 100% |
| /optimize-claude | 329 | 3 | ✅ | ✅ | ✅ | 100% |
| /plan (reference) | 426 | 3 | ✅ | ✅ | ✅ | 100% |

**Consistency Achievement**:
- Both commands will match or exceed /plan standards compliance
- Output formatting consistent across all commands
- Error logging uniform and queryable
- Guide files comprehensive and well-structured

---

## Section 7: Implementation Roadmap Summary

### 7.1 Phase Summary Table

| Phase | Tasks | Effort | Priority | Deliverables |
|-------|-------|--------|----------|-------------|
| **Phase 1** | Error Logging Integration | 4-6 hours | Critical | - Error handling library integrated<br>- All exit points log errors<br>- Errors queryable via /errors<br>- Test suites passing |
| **Phase 2** | Bash Block Consolidation | 2-3 hours | High | - /setup: 6→4 blocks<br>- /optimize-claude: 8→3 blocks<br>- Single summary per block<br>- Functionality preserved |
| **Phase 3** | Documentation & Consistency | 4-5 hours | Medium | - Guide files enhanced<br>- Agent integration standardized<br>- Output suppression complete<br>- Troubleshooting expanded |
| **Phase 4** | Enhancement Features | 2-3 hours | Low (Optional) | - Threshold configuration<br>- Dry-run support<br>- Interactive mode |

**Total Estimated Effort**: 10-14 hours (12-17 hours with optional Phase 4)

### 7.2 Critical Path

**Must-Complete Phases**: 1, 2, 3
**Optional Phase**: 4

**Blockers**:
- Phase 2 depends on Phase 1 (error logging must be in place before consolidation)
- Phase 3 depends on Phase 2 (guide documentation references final block structure)
- Phase 4 independent (can be done anytime after Phase 3)

### 7.3 Success Criteria Summary

**Phase 1 Success**:
- ✅ 100% error exit points integrate log_command_error()
- ✅ Errors queryable via /errors command
- ✅ Test suites for error logging pass

**Phase 2 Success**:
- ✅ /setup: 33% bash block reduction (6→4)
- ✅ /optimize-claude: 63% bash block reduction (8→3)
- ✅ All functionality preserved
- ✅ Output is cleaner and more professional

**Phase 3 Success**:
- ✅ Guide files comprehensive (90%+ capability coverage)
- ✅ /setup uses Task tool with behavioral injection
- ✅ Output suppression consistent
- ✅ Troubleshooting sections expanded

**Phase 4 Success** (Optional):
- ✅ --threshold flag functional
- ✅ --dry-run preview works
- ✅ --interactive mode guides users

**Overall Success**:
- ✅ 100% standards compliance
- ✅ All tests passing
- ✅ No regressions
- ✅ User feedback positive

---

## Section 8: Next Steps and Recommendations

### 8.1 Immediate Actions

1. **Create Feature Branch** (5 minutes)
   ```bash
   git checkout -b feature/modernize-setup-optimize-commands
   ```

2. **Create Backups** (10 minutes)
   ```bash
   mkdir -p .claude/backups/commands/
   # Backup commands and guides
   # Tag initial state
   ```

3. **Start Phase 1** (4-6 hours)
   - Implement error logging for /setup
   - Implement error logging for /optimize-claude
   - Create test suites
   - Verify error queryability

### 8.2 Long-Term Recommendations

**Recommendation 1: Extend Error Logging to All Commands**

Once /setup and /optimize-claude demonstrate successful error logging integration, extend pattern to remaining commands:
- /expand
- /collapse
- /research
- /revise
- /convert-docs
- /document

**Recommendation 2: Create Command Modernization Template**

Document modernization process as reusable template:
```
.claude/docs/guides/development/command-modernization-template.md
- Phase 1: Error logging integration checklist
- Phase 2: Block consolidation guidelines
- Phase 3: Documentation enhancement checklist
- Phase 4: Optional features menu
```

**Recommendation 3: Automated Standards Compliance Checking**

Create validation script:
```bash
.claude/scripts/validate-command-standards.sh <command-name>
# Checks:
# - Error logging integration
# - Bash block count
# - Guide file existence
# - Cross-reference validity
# - Output suppression
```

**Recommendation 4: Performance Benchmarking**

Establish baseline performance metrics for all commands:
```bash
.claude/scripts/benchmark-command.sh <command-name>
# Measures:
# - Execution time
# - Block execution time
# - Agent invocation overhead
# - File I/O time
```

### 8.3 Future Enhancements

**Enhancement 1: Unified Error Dashboard**

Create `/errors --dashboard` mode showing:
- Error frequency by command
- Error trends over time
- Common error patterns
- Resolution suggestions

**Enhancement 2: Command Health Monitoring**

Create `/health` command showing:
- Standards compliance status per command
- Error rates
- Performance metrics
- Recommended optimizations

**Enhancement 3: Interactive Troubleshooting**

Create `/diagnose <command>` command that:
- Analyzes recent errors
- Suggests fixes
- Offers to run repairs automatically

---

## Appendices

### Appendix A: Error Type Reference

**Standard Error Types** (from error-handling.sh):

| Error Type | Usage | Example |
|-----------|-------|---------|
| `validation_error` | Invalid user input | Missing required argument, invalid flag combination |
| `file_error` | File I/O failures | File not found, permission denied, cannot write |
| `agent_error` | Subagent failure | Agent didn't create expected file, agent returned error signal |
| `state_error` | State management issues | State file missing, workflow ID not allocated |
| `execution_error` | General execution failures | Script execution failed, library function error |
| `timeout_error` | Operation timeout | Agent took too long, network timeout |
| `parse_error` | Output parsing failure | Cannot parse JSON, unexpected format |

### Appendix B: Bash Block Consolidation Patterns

**Pattern 1: Setup Block Template**
```bash
set +H  # or set -euo pipefail

# 1. Project detection
# 2. Library sourcing (with 2>/dev/null)
# 3. Error logging initialization
# 4. Argument parsing
# 5. Validation
# 6. Path allocation

echo "Setup complete: [summary]"
export [critical variables]
```

**Pattern 2: Execute Block Template**
```bash
set +H

# Mode guards ([ "$MODE" != "X" ] && exit 0)
# Perform operations silently
# Single summary line

echo "Execution complete: [summary]"
```

**Pattern 3: Cleanup Block Template**
```bash
set +H

# Final verification
# Completion signal
# User-facing summary

echo "Workflow $WORKFLOW_ID complete"
```

### Appendix C: Guide File Structure Template

```markdown
# /command-name Command - Complete Guide

**Executable**: `.claude/commands/command-name.md`

## Table of Contents
1. Overview
2. Quick Start
3. Architecture
4. Usage Patterns
5. Customization
6. Troubleshooting (10+ scenarios)
7. Performance Optimization
8. Integration with Other Commands
9. Advanced Topics
10. Reference

## See Also
- [Related Pattern](...)
- [Related Standard](...)
```

### Appendix D: Agent Behavioral Injection Template

```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name] agent.

```
Task {
  subagent_type: "general-purpose"
  description: "[Brief description]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **Input Paths** (ABSOLUTE):
    - INPUT_PATH: ${INPUT_PATH}
    - OUTPUT_PATH: ${OUTPUT_PATH}

    **CRITICAL**: Create output file at EXACT path provided above.

    **Task**:
    1. [Step 1]
    2. [Step 2]
    3. [Step 3]

    Expected Output:
    - [Output description]
    - Completion signal: REPORT_CREATED: [path]
  "
}
```

# Verification after agent returns
if [ ! -f "$OUTPUT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "Agent [agent-name] failed to create output" \
    "subagent_[agent-name]" \
    "$(jq -n --arg path "$OUTPUT_PATH" '{expected_path: $path}')"
  exit 1
fi
```

### Appendix E: Standards Compliance Checklist

**Per-Command Checklist**:

- [ ] **Standard 17: Error Logging**
  - [ ] Source error-handling.sh
  - [ ] Call ensure_error_log_exists
  - [ ] Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS
  - [ ] Log at all error exit points
  - [ ] Parse agent errors (if applicable)

- [ ] **Pattern 8: Bash Block Consolidation**
  - [ ] Target 2-3 blocks (4 max for complex commands)
  - [ ] Single summary line per block
  - [ ] Consolidate library sourcing
  - [ ] Consolidate validation

- [ ] **Standard 14: Executable/Documentation Separation**
  - [ ] Executable <500 lines (primary commands)
  - [ ] Guide file exists
  - [ ] Bidirectional cross-references
  - [ ] No design rationale in executable

- [ ] **Standard 11: Output Suppression**
  - [ ] Library sourcing uses 2>/dev/null
  - [ ] Success operations suppressed
  - [ ] Errors preserved (stderr)
  - [ ] Single summary per block

- [ ] **Pattern 9: Behavioral Injection**
  - [ ] Use Task tool (not SlashCommand)
  - [ ] Inject context via prompt
  - [ ] Parse completion signals
  - [ ] Log agent errors

- [ ] **Pattern 10: Verification Checkpoints**
  - [ ] Verify file creation
  - [ ] Verify file has content
  - [ ] Fail-fast on verification failure
  - [ ] Log verification failures

---

## Conclusion

This systematic refactor plan provides a comprehensive, phased approach to modernizing the /setup and /optimize-claude commands for full standards compliance. By following the four-phase implementation strategy with clear verification checkpoints, rollback procedures, and test coverage requirements, both commands will achieve:

1. **100% standards compliance** with all applicable .claude/docs/ patterns
2. **Queryable error tracking** via centralized error logging
3. **50-67% output noise reduction** through bash block consolidation
4. **Enhanced maintainability** through comprehensive guide files

The plan minimizes risk through phased migration, extensive testing, and clear rollback procedures, ensuring that existing workflows remain functional while bringing both commands up to modern architectural standards.

**Total Estimated Effort**: 10-14 hours (excluding optional Phase 4)
**Expected Benefits**: Improved debuggability, cleaner output, better documentation, easier maintenance
**Compliance Achievement**: 100% standards compliance upon completion

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/845_standards_to_modernize_setup_and_optimizeclaude/reports/001_setup_optimize_refactor_plan.md

# Orchestration Commands Subprocess Isolation Patterns Research Report

## Metadata
- **Date**: 2025-11-07
- **Agent**: research-specialist
- **Topic**: Subprocess isolation patterns in /orchestrate, /implement, /supervise commands
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

Analysis of /orchestrate, /implement, and /supervise commands reveals three distinct subprocess management patterns. /orchestrate and /implement use single-bash-block designs that avoid subprocess isolation issues entirely, while /supervise uses a comprehensive library sourcing pattern (lines 203-354) in its first bash block. The /coordinate command's multi-bash-block architecture with inconsistent library sourcing is unique among orchestration commands, making coordinate-subprocess-init.sh a command-specific solution rather than a general pattern.

## Findings

### Finding 1: /orchestrate Uses Single-Bash-Block Design (No Subprocess Issues)

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md` (558 lines total)

**Architecture**: 11 bash blocks BUT used as templates within Task invocations, not sequential subprocess execution.

**Key Pattern Analysis**:
- **Line 43-81**: Phase 0 bash block sources unified-location-detection.sh (line 45) and exports variables
- **Lines 89-108**: Phase 1 bash block is SHORT (20 lines) and only calculates research complexity
- **Lines 133-165**: Phase 1 verification bash block is also SHORT (33 lines) - no library functions needed
- **Lines 171-189**: Phase 2 context preparation - no library functions needed
- **Lines 216-242**: Phase 2 verification - simple grep/wc commands, no library functions
- **Lines 248-280**: Phase 3 dependency analysis uses `command -v analyze_dependencies &>/dev/null` pattern (line 252)
- **Lines 309-335**: Phase 3 verification - simple file checks
- **Lines 367-395**: Phase 4 test verification - simple variable extraction
- **Lines 401-494**: Phase 5 debug loop - embedded in conditional, uses simple bash
- **Lines 525-553**: Phase 6 documentation verification - simple file checks

**Critical Difference from /coordinate**:
- /orchestrate bash blocks are SIMPLE and self-contained
- Most blocks do NOT call library functions (grep, wc, echo, simple conditionals only)
- Only Phase 3 uses `command -v` defensive check before calling analyze_dependencies
- **No multi-bash-block workflow coordination** - agents do the work via Task tool

**Library Sourcing Pattern**:
```bash
# Line 45: Only library sourcing in entire command
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
```

**Why /orchestrate Doesn't Have /coordinate's Issue**:
1. Bash blocks are templates shown to user, not sequential execution steps
2. Each bash block is independent (no function calls from previous blocks)
3. Defensive programming: `command -v function_name` checks before use (line 252)
4. Simplicity: Most verification uses basic bash (grep, wc, test -f) not library functions

### Finding 2: /implement Uses Single-Loop Design with Inline Library Sourcing

**File**: `/home/benjamin/.config/.claude/commands/implement.md` (221 lines total)

**Architecture**: 3 bash blocks (Phase 0, Phase 1 loop, Phase 2 finalize)

**Key Pattern Analysis**:
- **Lines 19-87**: Phase 0 initialization
  - Sources ALL required utilities upfront (lines 26-30): error-handling, checkpoint-utils, complexity-utils, adaptive-planning-logger, agent-registry-utils
  - Uses `source "$SCRIPT_DIR/../lib/detect-project-dir.sh"` (line 22)
  - Pattern: `for util in ...; do source "$UTILS_DIR/$util"; done` (lines 27-30)
- **Lines 91-177**: Phase 1 implementation loop
  - Re-sources complexity-utils.sh at line 102: `source "$UTILS_DIR/complexity-utils.sh"`
  - Re-sources error-handling.sh at line 139: `source "$UTILS_DIR/error-handling.sh"`
  - **DEFENSIVE REDUNDANCY**: Re-sources libraries inside loop iterations
- **Lines 182-216**: Phase 2 finalization
  - No library sourcing (uses variables from Phase 0)

**Critical Observation**:
/implement demonstrates **defensive library re-sourcing** within a single large bash block. Lines 102 and 139 re-source libraries that were already sourced in lines 27-30, suggesting awareness of potential subprocess isolation issues.

**Why /implement's Pattern Works**:
1. Only 3 bash blocks total (not 19 like /coordinate)
2. Phase 1 is a single bash block containing a loop, not multiple bash blocks
3. Re-sources libraries WITHIN the same bash block when needed
4. First bash block establishes all dependencies before any execution

### Finding 3: /supervise Uses Comprehensive Library Sourcing in First Block

**File**: `/home/benjamin/.config/.claude/commands/supervise.md` (1,779 lines total)

**Architecture**: 23 bash blocks across 7 phases with COMPREHENSIVE library sourcing in first block

**Key Library Sourcing Pattern** (Lines 203-354):
```bash
# Line 208: SCRIPT_DIR detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Lines 214-230: Source library-sourcing.sh with fail-fast error
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  # ... detailed diagnostic output ...
  exit 1
fi

# Lines 233-236: Source all required libraries
if ! source_required_libraries; then
  exit 1
fi

# Lines 239-246: Source verification-helpers.sh
if [ -f "$SCRIPT_DIR/../lib/verification-helpers.sh" ]; then
  source "$SCRIPT_DIR/../lib/verification-helpers.sh"
else
  echo "ERROR: Required library not found: verification-helpers.sh"
  exit 1
fi

# Lines 251-281: Define helper functions inline (display_brief_summary)

# Lines 285-344: Verify all required functions exist
REQUIRED_FUNCTIONS=("detect_workflow_scope" "should_run_phase" ...)
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done
# ... comprehensive error reporting with library mapping ...
```

**Subsequent Bash Blocks** (all phases after line 354):
- **Line 434**: Phase 0 Step 1 - Simple variable assignment (WORKFLOW_DESCRIPTION="$1")
- **Line 480**: Phase 0 Step 2 - Uses detect_workflow_scope() function WITHOUT re-sourcing
- **Line 547**: Phase 0 Step 3 - Sources workflow-initialization.sh (line 552)
- **Line 590**: Phase 1 execution check - Uses should_run_phase() and display_brief_summary() WITHOUT re-sourcing
- **Line 604**: Phase 1 complexity - Simple grep patterns, no library functions
- **Line 633**: Phase 1 progress - Uses emit_progress() WITHOUT re-sourcing
- **Line 658**: Phase 1 marker - Uses emit_progress() WITHOUT re-sourcing
- **Line 670**: Phase 1 verification - Uses verify_file_created(), emit_progress() WITHOUT re-sourcing
- **Line 789**: Phase 1 overview - Uses should_synthesize_overview(), calculate_overview_path() WITHOUT re-sourcing
- **Line 870**: Phase 2 execution - Uses should_run_phase() WITHOUT re-sourcing
- **Lines 884+**: All remaining phases use library functions WITHOUT re-sourcing

**Critical Finding**: /supervise's pattern ASSUMES functions persist across bash blocks, which would cause the SAME subprocess isolation issue as /coordinate IF bash blocks are executed in separate subprocesses.

**Analysis of /supervise's Risk**:
1. First bash block (lines 203-354) sources ALL libraries
2. All 22 subsequent bash blocks assume functions are available
3. **POTENTIAL ISSUE**: If Bash tool runs each block in separate subprocess, all blocks after the first would fail with "command not found" errors
4. **Status**: Needs testing to determine if /supervise has latent subprocess isolation issues

### Finding 4: Comparison of Subprocess Isolation Patterns

| Command | Total Lines | Bash Blocks | Library Sourcing Strategy | Subprocess Isolation Risk |
|---------|-------------|-------------|---------------------------|---------------------------|
| **/coordinate** | 1,095 | 19 | ❌ Inconsistent (1 sources, 18 don't) | **CRITICAL** - Active failures |
| **/orchestrate** | 558 | 11 | ✅ Minimal (only unified-location-detection) | **LOW** - Blocks are simple/independent |
| **/implement** | 221 | 3 | ✅ Defensive (re-sources within blocks) | **LOW** - Redundant sourcing protects |
| **/supervise** | 1,779 | 23 | ⚠️ First-block-only (assumes persistence) | **MEDIUM** - Latent issue if subprocesses |

### Finding 5: Why /coordinate Has Unique Subprocess Architecture

**Architectural Differences**:

1. **Multi-Phase Bash Orchestration**: /coordinate uses bash blocks as PRIMARY orchestration mechanism (19 blocks)
2. **Function-Heavy Design**: Every phase uses 5-10 library functions (should_run_phase, emit_progress, verify_file_created, save_checkpoint, etc.)
3. **Sequential Dependency**: Each bash block depends on functions from previous blocks
4. **Checkpoint/State Management**: Uses checkpoint-utils.sh functions across multiple blocks

**In Contrast**:
- **/orchestrate**: Agent invocations do coordination, bash blocks are simple wrappers
- **/implement**: Single-loop design, re-sources libraries defensively within loop
- **/supervise**: First bash block is "initialization", assumes functions persist (risky assumption)

### Finding 6: Library Function Usage Patterns

**Functions Used Across Multiple Bash Blocks** (from /coordinate analysis):

| Function | Library | /coordinate Usage | /orchestrate Usage | /implement Usage | /supervise Usage |
|----------|---------|-------------------|--------------------|--------------------|-------------------|
| `should_run_phase()` | workflow-detection.sh | ✅ Phases 1-4 start blocks | ❌ Not used | ❌ Not used | ✅ Phases 1-6 start blocks |
| `emit_progress()` | unified-logger.sh | ✅ All 19 blocks | ❌ Not used | ❌ Not used | ✅ All 23 blocks |
| `verify_file_created()` | verification-helpers.sh | ✅ All verification blocks | ❌ Not used (inline checks) | ❌ Not used | ✅ All verification blocks |
| `save_checkpoint()` | checkpoint-utils.sh | ✅ All verification blocks | ❌ Not used | ✅ Phase 1 loop | ✅ Multiple phases |
| `analyze_dependencies()` | dependency-analyzer.sh | ✅ Phase 3 start | ✅ Phase 3 (defensive) | ❌ Not used | ❌ Not used |

**Key Insight**: /coordinate and /supervise are the ONLY commands that extensively use library functions across multiple bash blocks, making them vulnerable to subprocess isolation.

### Finding 7: Generalization Potential for coordinate-subprocess-init.sh

**Evaluation**: Should coordinate-subprocess-init.sh be generalized to command-subprocess-init.sh?

**Evidence Against Generalization**:
1. **/orchestrate**: Doesn't need it (simple bash blocks, no library functions)
2. **/implement**: Uses different pattern (defensive re-sourcing within single loop block)
3. **/supervise**: Could benefit BUT has different sourcing strategy (first-block comprehensive)

**Evidence For Targeted Fix**:
1. /coordinate's multi-bash-block architecture is unique
2. Other commands either avoid the pattern or use different mitigation strategies
3. coordinate-subprocess-init.sh is correctly scoped to /coordinate's specific needs

**Recommendation**: Keep coordinate-subprocess-init.sh as command-specific solution. If /supervise exhibits subprocess isolation issues during testing, create supervise-subprocess-init.sh separately.

## Recommendations

### Recommendation 1: Implement coordinate-subprocess-init.sh as Planned (Command-Specific)

Create `.claude/lib/coordinate-subprocess-init.sh` as described in the fix plan document. This solution is appropriately scoped to /coordinate's unique multi-bash-block architecture.

**Rationale**:
- /coordinate's 19-bash-block design is unique among orchestration commands
- Other commands use different patterns that don't require this solution
- Command-specific solution is simpler than premature generalization

**Files to Create**:
- `.claude/lib/coordinate-subprocess-init.sh` (lines 386-486 from fix plan)

**Files to Modify**:
- `.claude/commands/coordinate.md` - Add sourcing line to 18 bash blocks (all except Phase 0 Step 1)

### Recommendation 2: Test /supervise for Latent Subprocess Isolation Issues

/supervise uses a first-block-only library sourcing pattern (lines 203-354) that assumes functions persist across subsequent bash blocks. This assumption may be incorrect if Bash tool executes each block in a separate subprocess.

**Testing Procedure**:
1. Run simple /supervise workflow: `/supervise "research lua best practices"`
2. Monitor for "command not found" errors in Phase 1 and beyond
3. If errors occur, verify with: `bash -c 'source lib1.sh; declare -F' ; bash -c 'declare -F'` (functions don't persist)

**If Latent Issue Confirmed**:
- Create `supervise-subprocess-init.sh` following same pattern as coordinate-subprocess-init.sh
- Update all 22 bash blocks after first initialization block
- Document pattern in supervise-command-guide.md

### Recommendation 3: Update Command Development Guide with Subprocess Isolation Patterns

Document three proven patterns for multi-bash-block commands to help future command development avoid subprocess isolation issues.

**File to Update**: `.claude/docs/guides/command-development-guide.md`

**New Section**: "Subprocess Isolation Patterns for Multi-Bash-Block Commands"

**Three Patterns to Document**:

1. **Pattern A: Simple Independent Blocks** (used by /orchestrate)
   - Each bash block is self-contained
   - Minimal library function usage
   - Defensive `command -v` checks before function calls
   - **Use When**: Bash blocks are verification/reporting wrappers around agent invocations

2. **Pattern B: Single-Block-with-Loop** (used by /implement)
   - Single large bash block containing loop
   - Re-source libraries within loop iterations if needed
   - Avoids multiple bash blocks entirely
   - **Use When**: Command executes iterative workflow within bash itself

3. **Pattern C: Reusable Init Script** (used by /coordinate, potentially /supervise)
   - Create command-specific `{command}-subprocess-init.sh`
   - Source at beginning of EVERY bash block (except first)
   - Consolidates library sourcing + helper function definitions
   - **Use When**: Command has 10+ bash blocks with heavy library function usage

**Example Code Blocks**: Include working examples from each command

### Recommendation 4: Add Subprocess Isolation Testing to Command Test Suite

Create automated tests to detect subprocess isolation issues during command development.

**File to Create**: `.claude/tests/test_subprocess_isolation.sh`

**Test Cases**:
1. Test that bash blocks in separate invocations don't inherit functions
2. Test that exported variables DO persist (control case)
3. Test each orchestration command's library sourcing pattern
4. Verify defensive patterns (`command -v` checks) work correctly

**Integration**: Add to `.claude/tests/run_all_tests.sh` with high priority

### Recommendation 5: Document Architectural Decision - No General command-subprocess-init.sh

Update architectural documentation to explain why coordinate-subprocess-init.sh is command-specific rather than generalized.

**File to Update**: `.claude/docs/architecture/subprocess-isolation-decisions.md` (new file)

**Content**:
- Analysis of three command patterns (orchestrate, implement, supervise)
- Rationale for command-specific solutions
- Decision matrix: When to create {command}-subprocess-init.sh vs other patterns
- Future guidance: "Create per-command init scripts only when Pattern C applies"

### Recommendation 6: Add Verification Checkpoints to /supervise

Even if /supervise doesn't currently exhibit subprocess isolation failures, adding verification checkpoints would detect issues early and align with fail-fast philosophy.

**File to Modify**: `.claude/commands/supervise.md`

**Suggested Additions** (after line 354):
```bash
# Verify critical functions persist across subprocess boundary
# (Detection mechanism for subprocess isolation issues)
CRITICAL_FUNCTIONS=("should_run_phase" "emit_progress" "verify_file_created")
for func in "${CRITICAL_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    echo "ERROR: Function $func not available in this subprocess"
    echo "This indicates subprocess isolation issue requiring init script pattern"
    exit 1
  fi
done
```

**Benefit**: Converts latent risk into immediate fail-fast error with actionable diagnostic

## References

### Command Files Analyzed

- `/home/benjamin/.config/.claude/commands/coordinate.md` (1,095 lines, 19 bash blocks)
  - Lines 21-113: Phase 0 Step 1 (only block with comprehensive library sourcing)
  - Lines 341-381: Phase 1 Research Start (first critical failure point)
  - Lines 406-457: Phase 1 Verification (uses verify_file_created without sourcing)
  - Lines 530-589: Phase 2 Planning Start (uses should_run_phase without sourcing)

- `/home/benjamin/.config/.claude/commands/orchestrate.md` (558 lines, 11 bash blocks)
  - Line 45: Single library sourcing (unified-location-detection.sh)
  - Line 252: Defensive `command -v analyze_dependencies` check
  - Pattern: Simple bash blocks with minimal library function usage

- `/home/benjamin/.config/.claude/commands/implement.md` (221 lines, 3 bash blocks)
  - Lines 22-30: Initial library sourcing in Phase 0
  - Line 102: Defensive re-sourcing of complexity-utils.sh within loop
  - Line 139: Defensive re-sourcing of error-handling.sh within loop
  - Pattern: Single-loop design with redundant library sourcing

- `/home/benjamin/.config/.claude/commands/supervise.md` (1,779 lines, 23 bash blocks)
  - Lines 203-354: Comprehensive library sourcing and function verification
  - Lines 214-230: Source library-sourcing.sh with detailed error handling
  - Lines 233-236: Call source_required_libraries() wrapper function
  - Lines 285-344: Verify all required functions available with library mapping
  - Lines 434+: 22 subsequent bash blocks assume functions persist (potential issue)

### Library Files Referenced

- `.claude/lib/library-sourcing.sh` - Consolidated library sourcing utilities
- `.claude/lib/workflow-detection.sh` - Provides should_run_phase(), detect_workflow_scope()
- `.claude/lib/unified-logger.sh` - Provides emit_progress()
- `.claude/lib/checkpoint-utils.sh` - Provides save_checkpoint(), restore_checkpoint()
- `.claude/lib/verification-helpers.sh` - Provides verify_file_created()
- `.claude/lib/unified-location-detection.sh` - Provides perform_location_detection()
- `.claude/lib/workflow-initialization.sh` - Provides initialize_workflow_paths()

### Documentation Referenced

- `/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md` - Complete analysis of /coordinate's subprocess isolation issue with detailed fix plan

### Key Metrics

| Metric | /coordinate | /orchestrate | /implement | /supervise |
|--------|-------------|--------------|------------|------------|
| **Total Lines** | 1,095 | 558 | 221 | 1,779 |
| **Bash Blocks** | 19 | 11 | 3 | 23 |
| **Blocks with Library Sourcing** | 1 (5%) | 1 (9%) | 1 + 2 re-sources | 2 (9%) |
| **Blocks Using Library Functions** | 18 (95%) | 2 (18%) | 2 (67%) | 22 (96%) |
| **Subprocess Isolation Risk** | CRITICAL (active failures) | LOW (simple blocks) | LOW (defensive re-sourcing) | MEDIUM (latent risk) |
| **Mitigation Needed** | Yes (coordinate-subprocess-init.sh) | No (working as designed) | No (pattern already defensive) | Testing needed |

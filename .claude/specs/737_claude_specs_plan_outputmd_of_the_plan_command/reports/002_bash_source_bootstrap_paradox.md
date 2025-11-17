# BASH_SOURCE Pattern Bootstrap Paradox Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: BASH_SOURCE Pattern Bootstrap Paradox
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The BASH_SOURCE bootstrap paradox is a critical architectural constraint in Claude Code's subprocess execution model. BASH_SOURCE[0] returns empty in bash blocks because they execute as separate subprocesses without script metadata, creating a circular dependency: commands need detect-project-dir.sh to find the project directory, but need the project directory path to source detect-project-dir.sh. This paradox was resolved in Spec 732 by replacing SCRIPT_DIR detection with inline git-based CLAUDE_PROJECT_DIR bootstrap, eliminating the external library dependency.

## Findings

### 1. BASH_SOURCE Behavior in Claude Code Subprocess Model

**Location**: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:685-732

Claude Code executes bash blocks as separate subprocesses, not subshells. Each bash block runs independently:

```
Claude Code Session
    ↓
Command Execution (plan.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - BASH_SOURCE[0] = "" (empty)    │
│ - No script metadata preserved   │
│ - Executed as subprocess         │
└──────────────────────────────────┘
```

**Why BASH_SOURCE[0] is Empty**:

From bash-block-execution-model.md:696-701:
- BASH_SOURCE requires execution from a script file (`bash script.sh`)
- Claude Code executes blocks like `bash -c 'commands'`, not from files
- No script metadata (filename, path) is preserved in subprocess context
- Result: BASH_SOURCE[0] returns empty string

**Impact on SCRIPT_DIR Detection**:

The traditional pattern `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` fails:
- `${BASH_SOURCE[0]}` = "" (empty)
- `dirname ""` = "." (current directory)
- `SCRIPT_DIR` resolves to current working directory, not commands directory
- Library paths become incorrect: `/current/dir/../lib/` instead of `/project/.claude/lib/`

### 2. The Bootstrap Paradox

**Location**: /home/benjamin/.config/.claude/commands/plan.md:26-29 (original broken pattern)

The circular dependency creates an impossible bootstrapping scenario:

```
Problem Chain:
1. Need to source detect-project-dir.sh to get CLAUDE_PROJECT_DIR
2. Need SCRIPT_DIR to construct path to detect-project-dir.sh
3. SCRIPT_DIR calculation uses BASH_SOURCE[0]
4. BASH_SOURCE[0] is empty in Claude Code subprocess context
5. SCRIPT_DIR resolves incorrectly
6. Cannot source detect-project-dir.sh
7. Cannot detect CLAUDE_PROJECT_DIR
8. BOOTSTRAP FAILURE
```

**Paradox Visualization**:

```
┌─────────────────────────────────────────┐
│  Need: CLAUDE_PROJECT_DIR               │
│    ↓                                     │
│  Requires: source detect-project-dir.sh │
│    ↓                                     │
│  Path: $SCRIPT_DIR/../lib/              │
│    ↓                                     │
│  Requires: BASH_SOURCE[0]               │
│    ↓                                     │
│  Value: "" (empty in subprocess)        │
│    ↓                                     │
│  SCRIPT_DIR = $(pwd) (WRONG)            │
│    ↓                                     │
│  Path fails: /wrong/path/../lib/        │
│    └─────────────────┐                  │
│                      ↓                   │
│  ✗ BOOTSTRAP PARADOX: Cannot get        │
│    CLAUDE_PROJECT_DIR without library,  │
│    cannot source library without        │
│    CLAUDE_PROJECT_DIR                   │
└─────────────────────────────────────────┘
```

### 3. Affected Commands and Severity

**Location**: /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md:1-117

**Commands Using Broken BASH_SOURCE Pattern**:

1. **/plan** (.claude/commands/plan.md:27-28)
   - **Status**: FIXED in Spec 732
   - **Priority**: HIGH (critical for planning workflow)

2. **/implement** (.claude/commands/implement.md:21)
   - **Status**: BROKEN (requires fix)
   - **Priority**: HIGH (critical for implementation workflow)

3. **/expand** (.claude/commands/expand.md:80, 563)
   - **Status**: BROKEN (requires fix)
   - **Priority**: MEDIUM (used for plan expansion)

4. **/collapse** (.claude/commands/collapse.md:82, 431)
   - **Status**: BROKEN (requires fix)
   - **Priority**: MEDIUM (used for plan collapsing)

**Severity Assessment** (bash_source_audit.md:107-116):
- **Severity**: CRITICAL
- All four commands completely non-functional
- Bootstrap failure prevents any library sourcing
- Affects core workflow commands (planning and implementation)
- User Impact: Complete workflow breakage

### 4. Solution: Inline CLAUDE_PROJECT_DIR Bootstrap

**Location**: /home/benjamin/.config/.claude/commands/plan.md:26-50

**Spec 732 Solution** eliminates the bootstrap paradox by removing external library dependency:

```bash
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
# This eliminates the bootstrap paradox where we need detect-project-dir.sh to find
# the project directory, but need the project directory to source detect-project-dir.sh
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# Validate CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree"
  echo "SOLUTION: Run /plan from within a directory containing .claude/ subdirectory"
  exit 1
fi

export CLAUDE_PROJECT_DIR
```

**Why This Works**:

1. **No External Dependencies**: Doesn't require sourcing any library files
2. **Git-Based Primary Detection**: `git rev-parse --show-toplevel` is fast (2ms) and reliable
3. **Directory Traversal Fallback**: Works in non-git environments by searching for `.claude/` directory
4. **Fail-Fast Validation**: Clear error messages when project directory cannot be found
5. **Breaks Circular Dependency**: Establishes CLAUDE_PROJECT_DIR before attempting to source libraries

### 5. Technical Details: Subprocess Isolation

**Location**: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:9-48

**Subprocess vs Subshell**:

Each bash block is a completely separate process:
- New Process ID ($$) per block
- All environment variables reset (exports lost)
- All bash functions lost (libraries must be re-sourced)
- Trap handlers fire at block exit, not workflow exit
- Only files written to disk persist across blocks

**What Persists** (bash-block-execution-model.md:51-59):
- Files written to filesystem
- State files (via state-persistence.sh)
- Workflow ID (in fixed location file)
- Created directories

**What Does NOT Persist** (bash-block-execution-model.md:61-69):
- Environment variables (even with export)
- Bash functions (must re-source libraries)
- Process ID ($$)
- Trap handlers
- Script metadata (BASH_SOURCE)

### 6. Anti-Pattern Documentation

**Location**: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:685-737

**Anti-Pattern 5: Using BASH_SOURCE for Script Directory Detection**

Documented in bash-block-execution-model.md with:
- Complete problem explanation
- Why it fails in Claude Code context
- Bootstrap paradox description
- Correct inline bootstrap pattern
- Impact assessment (all affected commands listed)

This anti-pattern was added in Spec 732 Phase 2 to prevent future commands from repeating this mistake.

### 7. Integration with State-Based Orchestration

**Location**: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:814-852

The subprocess execution model is foundational to state-based orchestration:

**State Machine Coordination** (lines 818-833):
- State transitions must be persisted to files (cannot use memory)
- append_workflow_state saves to file across subprocess boundaries
- load_workflow_state reconstructs state in new subprocess

**Checkpoint Recovery** (lines 835-851):
- Checkpoint files enable workflow resume across bash blocks
- save_checkpoint writes to persistent storage
- load_checkpoint reads from file in new subprocess

The BASH_SOURCE bootstrap paradox was particularly critical because it prevented the initial state machine setup, blocking all subsequent orchestration.

## Recommendations

### 1. Apply Inline Bootstrap to Remaining Commands

**Priority**: HIGH

Apply the Spec 732 inline bootstrap pattern to:
- /implement (.claude/commands/implement.md:21)
- /expand (.claude/commands/expand.md:80, 563)
- /collapse (.claude/commands/collapse.md:82, 431)

**Action**: Create follow-up spec (e.g., Spec 733) to fix these commands using the identical pattern from plan.md:26-50.

### 2. Create Reusable Bootstrap Snippet

**Priority**: MEDIUM

Extract the inline bootstrap pattern into a documented snippet in command development guides:

**Location**: .claude/docs/guides/command-development-fundamentals.md or _template-bash-block.md

**Benefits**:
- Consistent bootstrap across all commands
- Easy to copy-paste for new commands
- Single source of truth for bootstrap logic
- Prevents BASH_SOURCE anti-pattern from reoccurring

### 3. Update Command Development Standards

**Priority**: MEDIUM

Add explicit warning to command development documentation:

**Recommended Addition** to .claude/docs/guides/command-development-fundamentals.md:

```markdown
## CRITICAL: Do Not Use BASH_SOURCE for Project Detection

BASH_SOURCE[0] returns empty in Claude Code's subprocess execution model.
Always use inline git-based CLAUDE_PROJECT_DIR detection instead.

See bash-block-execution-model.md Anti-Pattern 5 for details.
```

### 4. Add Validation Test for Bootstrap Pattern

**Priority**: LOW

Create test to verify commands use correct bootstrap pattern:

**Test**: .claude/tests/test_command_bootstrap_patterns.sh

**Checks**:
- No BASH_SOURCE usage in Phase 0 initialization
- CLAUDE_PROJECT_DIR detection uses git or directory traversal
- All library sourcing uses absolute paths via $UTILS_DIR
- Clear validation and error messages present

### 5. Document Bootstrap Paradox in Architecture Docs

**Priority**: LOW

Add bootstrap paradox documentation to state-based orchestration overview:

**Location**: .claude/docs/architecture/state-based-orchestration-overview.md

**Section**: "Subprocess Execution Model Constraints"

**Content**: Link to bash-block-execution-model.md Anti-Pattern 5, explain why inline bootstrap is necessary, document relationship to state persistence architecture.

## References

### Primary Code Files

- /home/benjamin/.config/.claude/commands/plan.md:26-50 - Inline bootstrap solution (FIXED)
- /home/benjamin/.config/.claude/commands/implement.md:21 - BASH_SOURCE pattern (BROKEN)
- /home/benjamin/.config/.claude/commands/expand.md:80 - BASH_SOURCE pattern (BROKEN)
- /home/benjamin/.config/.claude/commands/expand.md:563 - BASH_SOURCE pattern (BROKEN)
- /home/benjamin/.config/.claude/commands/collapse.md:82 - BASH_SOURCE pattern (BROKEN)
- /home/benjamin/.config/.claude/commands/collapse.md:431 - BASH_SOURCE pattern (BROKEN)
- /home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-51 - Original library requiring bootstrap

### Documentation Files

- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:9-48 - Subprocess architecture
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:685-737 - Anti-Pattern 5 documentation
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:814-852 - State-based orchestration integration

### Specification Files

- /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/IMPLEMENTATION_SUMMARY.md:1-173 - Spec 732 complete solution
- /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md:1-117 - Affected commands audit
- /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/plans/001_plan_outputmd_in_order_to_identify_the_root_cause_plan.md - Implementation plan

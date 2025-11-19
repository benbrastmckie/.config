# Plan.md Execution Failure Analysis

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Plan command execution failure - detect-project-dir.sh library sourcing error
- **Report Type**: codebase analysis

## Executive Summary

The plan.md command fails at Phase 0 initialization due to incorrect library path resolution using BASH_SOURCE[0]. When Claude Code executes bash blocks from .md files, BASH_SOURCE points to the temporary script location, not the .md file itself, causing detect-project-dir.sh to be sourced from /home/benjamin/.config/../lib/ instead of /home/benjamin/.config/.claude/lib/. The solution is to use Standard 13's inline git-based detection or rely on CLAUDE_PROJECT_DIR being pre-set by the execution environment.

## Findings

### Root Cause: BASH_SOURCE Path Resolution Failure

**Error Analysis:**
- Error location: /home/benjamin/.config/.claude/specs/plan_output.md:240-243
- Failed path: `/home/benjamin/.config/../lib/detect-project-dir.sh`
- Correct path: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh`
- Missing component: `.claude/` directory in the path

**Code Path (plan.md:27-28):**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$SCRIPT_DIR/../lib/detect-project-dir.sh" 2>&1; then
```

**Expected vs Actual:**
- Expected: `SCRIPT_DIR=/home/benjamin/.config/.claude/commands`
- Actual: `SCRIPT_DIR=/home/benjamin/.config`
- Expected resolution: `$SCRIPT_DIR/../lib/` → `/home/benjamin/.config/.claude/lib/`
- Actual resolution: `$SCRIPT_DIR/../lib/` → `/home/benjamin/.config/../lib/`

### Why BASH_SOURCE Fails in Claude Code

**Bash Block Execution Model:**
According to /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-48, each bash block in Claude Code runs as a **separate subprocess**, not a direct script execution.

**Key Discovery:**
- Bash blocks are extracted from .md files and executed as temporary scripts
- BASH_SOURCE[0] points to the **temporary script location**, not the original .md file
- This means SCRIPT_DIR calculation yields the temp directory or current directory, not .claude/commands/

**Evidence from Codebase:**
Research.md command (line 103) uses a different pattern:
```bash
source .claude/lib/detect-project-dir.sh
```
This uses a **relative path from current directory** instead of BASH_SOURCE-based detection.

### Standard 13 Specification

**Documented Standard (coordinate-state-management.md:120-126):**
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection for SlashCommand context
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Current Implementation Divergence:**
Plan.md uses BASH_SOURCE-based sourcing pattern which conflicts with bash block execution model. This pattern works for standalone scripts but fails in Claude Code command context.

### Library File Status

**Verification:**
- File exists: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh` (1540 bytes, Oct 30 08:44)
- File is readable and properly formatted
- Contains correct git-based detection logic
- Problem is **path resolution**, not file absence

### Pattern Inconsistency Across Commands

**Commands Using BASH_SOURCE Pattern:**
- collapse.md:82-83
- implement.md:21-22
- expand.md:80-81
- plan.md:27-28

**Commands Using Alternative Pattern:**
- research.md:103 (uses relative path: `.claude/lib/detect-project-dir.sh`)

This suggests the BASH_SOURCE pattern may be failing across multiple commands, not just plan.md.

## Recommendations

### 1. Use Standard 13 Inline Detection (Immediate Fix)

Replace BASH_SOURCE-based sourcing with inline git detection:

```bash
# STANDARD 13: Detect project directory using git
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Source libraries using CLAUDE_PROJECT_DIR
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
if ! source "$UTILS_DIR/detect-project-dir.sh" 2>&1; then
  echo "ERROR: Failed to source detect-project-dir.sh"
  exit 1
fi
```

**Benefits:**
- Works reliably in bash block execution model
- Matches documented Standard 13 specification
- No dependency on BASH_SOURCE or script location
- Graceful fallback to current directory

### 2. Use Relative Path Pattern (Alternative)

Follow research.md pattern with relative path from current directory:

```bash
# Source from relative path (assumes CWD is project root)
if ! source .claude/lib/detect-project-dir.sh 2>&1; then
  echo "ERROR: Failed to source detect-project-dir.sh"
  echo "DIAGNOSTIC: Current directory: $(pwd)"
  exit 1
fi
```

**Benefits:**
- Simple, proven pattern already in use
- No BASH_SOURCE dependency
- Works when CWD is project root

**Drawbacks:**
- Depends on current working directory being correct
- May fail if command invoked from subdirectory

### 3. Audit and Fix All Commands Using BASH_SOURCE Pattern (Comprehensive)

**Scope:**
Audit all 4+ commands using BASH_SOURCE pattern and migrate to Standard 13:
- /home/benjamin/.config/.claude/commands/collapse.md:82-83
- /home/benjamin/.config/.claude/commands/implement.md:21-22
- /home/benjamin/.config/.claude/commands/expand.md:80-81
- /home/benjamin/.config/.claude/commands/plan.md:27-28

**Migration Process:**
1. Replace BASH_SOURCE calculation with inline git detection
2. Test each command independently
3. Update documentation to reflect Standard 13 as authoritative
4. Add linter rule to prevent future BASH_SOURCE usage in command files

**Benefits:**
- Prevents recurrence across all commands
- Ensures consistency with documented standards
- Improves reliability of command initialization

### 4. Document Bash Block Execution Constraints

**Update Documentation:**
Add explicit warning to /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:

```markdown
## Anti-Pattern: BASH_SOURCE in Command Files

**DO NOT USE** BASH_SOURCE[0] to determine command file location:

```bash
# ❌ ANTI-PATTERN: Fails in bash block execution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/library.sh"
```

**Reason:** Bash blocks execute as temporary scripts, so BASH_SOURCE points to temp location, not .md file.

**✓ CORRECT PATTERN:** Use Standard 13 git-based detection:

```bash
# ✓ RECOMMENDED: Standard 13
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```
```

**Benefits:**
- Prevents future developers from repeating this mistake
- Clarifies limitations of bash block execution model
- Provides authoritative guidance on library sourcing

## References

### Error Evidence
- /home/benjamin/.config/.claude/specs/plan_output.md:240-248 (error output showing path failure)
- /home/benjamin/.config/.claude/specs/plan_output.md:36-38 (BASH_SOURCE calculation in Phase 0)

### Library Files
- /home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-50 (verified to exist and contain correct logic)

### Documentation
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-48 (subprocess isolation explanation)
- /home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md:120-126 (Standard 13 specification)
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:2334-2394 (sourcing order standards)

### Command Files Using BASH_SOURCE Pattern
- /home/benjamin/.config/.claude/commands/collapse.md:82-83
- /home/benjamin/.config/.claude/commands/implement.md:21-22
- /home/benjamin/.config/.claude/commands/expand.md:80-81
- /home/benjamin/.config/.claude/commands/plan.md:27-28

### Command Files Using Alternative Pattern
- /home/benjamin/.config/.claude/commands/research.md:103 (relative path pattern)

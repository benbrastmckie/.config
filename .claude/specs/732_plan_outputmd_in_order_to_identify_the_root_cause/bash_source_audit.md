# BASH_SOURCE Pattern Audit Results

## Summary

Three additional commands use the broken BASH_SOURCE[0] pattern and require the same fix applied to plan.md in Spec 732 Phase 1.

## Affected Commands

### 1. /implement (.claude/commands/implement.md)

**Location**: Line 21
**Previous Pattern**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
```

**Status**: FIXED in Spec 736 Phase 1
**Priority**: HIGH (critical command for implementation workflow)
**Fix Date**: 2025-11-16

### 2. /expand (.claude/commands/expand.md)

**Locations**: Lines 80 and 563
**Previous Pattern**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
```

**Status**: FIXED in Spec 736 Phase 2
**Priority**: MEDIUM (used for plan expansion)
**Fix Date**: 2025-11-16

### 3. /collapse (.claude/commands/collapse.md)

**Locations**: Lines 82 and 431
**Previous Pattern**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
```

**Status**: FIXED in Spec 736 Phase 3
**Priority**: MEDIUM (used for plan collapsing)
**Fix Date**: 2025-11-16

## Root Cause

BASH_SOURCE[0] returns empty string in Claude Code's bash block execution context because:
- Bash blocks execute as separate subprocesses (`bash -c 'commands'` style)
- BASH_SOURCE requires being executed from a script file (`bash script.sh`)
- No script metadata is preserved in subprocess execution

## Recommended Fix

Apply the same inline CLAUDE_PROJECT_DIR bootstrap pattern implemented in plan.md:

```bash
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
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
  echo "SOLUTION: Run command from within a directory containing .claude/ subdirectory"
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Now source libraries using absolute paths
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
source "$UTILS_DIR/workflow-state-machine.sh"
```

## Follow-Up Actions

1. ✓ Created Spec 736 to fix implement.md, expand.md, and collapse.md
2. ✓ Applied same inline bootstrap pattern to all three commands
3. ✓ Tested each command from root, subdirectories, and outside project
4. [ ] Update command development guide with anti-pattern warning
5. [ ] Consider creating a reusable bootstrap snippet for future commands

## Documentation Updated

- ✓ bash-block-execution-model.md: Added Anti-Pattern 5 for BASH_SOURCE
- ✓ Anti-pattern includes full explanation and correct pattern
- ✓ Impact section lists all affected commands

## Testing Performed

- ✓ Confirmed BASH_SOURCE[0] returns empty in bash block context
- ✓ Confirmed SCRIPT_DIR resolves to current directory (not commands directory)
- ✓ Confirmed path resolution fails: `/current/dir/../lib/` vs `/project/.claude/lib/`

## Severity Assessment

**Severity**: RESOLVED
- All four commands (plan, implement, expand, collapse) now using inline bootstrap
- Bootstrap failure issue completely resolved
- Core workflow commands fully functional

**User Impact**: Zero - all commands working correctly

**Resolution**:
- Spec 732 fixed /plan command
- Spec 736 fixed /implement, /expand, /collapse commands
- All fixes use identical inline CLAUDE_PROJECT_DIR bootstrap pattern

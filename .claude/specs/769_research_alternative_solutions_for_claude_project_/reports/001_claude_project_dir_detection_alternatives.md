# Alternative Solutions for CLAUDE_PROJECT_DIR Detection Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Alternative solutions for CLAUDE_PROJECT_DIR detection in build command
- **Report Type**: codebase analysis

## Executive Summary

The /build command fails because it sources state-persistence.sh and workflow-state-machine.sh without first detecting CLAUDE_PROJECT_DIR in bash blocks that run as isolated subprocesses. The /plan command does not face this issue because it performs CLAUDE_PROJECT_DIR detection inline before sourcing libraries. Analysis reveals five alternative approaches: the workflow-state-machine.sh library already contains a self-detecting pattern via detect-project-dir.sh that provides an elegant, centralized solution requiring minimal code changes.

## Findings

### Root Cause Analysis

The build.md command fails in Part 3 (lines 210-214) with:
```
/.claude/lib/state-persistence.sh: No such file or directory
```

**Why /plan works but /build fails:**

1. **In /plan (Part 3, lines 111-134)**: CLAUDE_PROJECT_DIR detection happens inline BEFORE sourcing libraries:
   ```bash
   # Detect project directory (bootstrap pattern)
   if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
     CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
   else
     # Fallback: search upward for .claude/ directory
     ...
   fi
   export CLAUDE_PROJECT_DIR

   # Source libraries in dependency order
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
   ```

2. **In /build (Part 3, lines 210-214)**: Assumes CLAUDE_PROJECT_DIR exists from previous block:
   ```bash
   set +H  # CRITICAL: Disable history expansion
   # Re-source required libraries (subprocess isolation)
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"  # FAILS HERE
   ```

### Current Infrastructure Analysis

**Key Discovery: workflow-state-machine.sh Lines 32-34**

The workflow-state-machine.sh library already contains self-detecting initialization:
```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"
```

This means workflow-state-machine.sh sources detect-project-dir.sh using relative path resolution, which **does not require CLAUDE_PROJECT_DIR to be pre-set**.

**state-persistence.sh Lines 96-100**

The state-persistence.sh library also has built-in detection:
```bash
# Detect CLAUDE_PROJECT_DIR if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

However, this detection only works when the library is sourced correctly - the issue is that `/build` uses `${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh` in the source path itself, which fails before any detection code runs.

**detect-project-dir.sh Pattern (Lines 21-50)**

Provides comprehensive detection:
1. Respects existing CLAUDE_PROJECT_DIR if set
2. Uses git rev-parse --show-toplevel (handles worktrees)
3. Fallback to pwd

### Alternative Approaches Evaluated

#### Option 1: Source Libraries Using Relative Path (SCRIPT_DIR Pattern)

**Description**: Use the same pattern as workflow-state-machine.sh - derive library path from BASH_SOURCE.

**Implementation**:
```bash
# Part 3 fix
set +H  # CRITICAL: Disable history expansion

# Source using relative path resolution (no CLAUDE_PROJECT_DIR needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# For commands in .claude/commands/, libraries are in .claude/lib/
LIB_DIR="${SCRIPT_DIR}/../lib"
source "$LIB_DIR/state-persistence.sh"
source "$LIB_DIR/workflow-state-machine.sh"
```

**Advantages**:
- Zero dependency on CLAUDE_PROJECT_DIR for initial sourcing
- Consistent with workflow-state-machine.sh approach
- Single pattern for all commands

**Disadvantages**:
- Requires understanding that commands are in .claude/commands/ directory
- BASH_SOURCE may not work correctly when command content is pasted vs sourced
- Claude Code commands are executed differently than regular bash scripts

#### Option 2: Inline Detection Before Every Source (Current Plan)

**Description**: Add the canonical detection pattern before every source statement in each bash block.

**Implementation** (per existing plan):
```bash
# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
  fi
fi
export CLAUDE_PROJECT_DIR
```

**Advantages**:
- Self-contained, explicit, easy to understand
- Each bash block is fully independent
- Consistent with /plan command pattern

**Disadvantages**:
- Significant code duplication (16 lines × 6 blocks = 96 lines)
- Maintenance burden when detection logic changes
- Violates DRY principle

#### Option 3: State Machine-Based Variable Persistence

**Description**: Leverage state-persistence.sh to cache CLAUDE_PROJECT_DIR in state file, then load it in subsequent blocks.

**Implementation**:
```bash
# Block 1 (Part 2): Initialize and persist
init_workflow_state "$WORKFLOW_ID"
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"

# Block 2+ (Parts 3-7): Load from state
load_workflow_state "$WORKFLOW_ID"
# CLAUDE_PROJECT_DIR now available
```

**Problem**: This creates a circular dependency - you need CLAUDE_PROJECT_DIR to source state-persistence.sh, but state-persistence.sh is needed to get CLAUDE_PROJECT_DIR from state.

**Advantages**:
- Uses existing infrastructure
- State persistence already tracks other variables

**Disadvantages**:
- **Circular dependency makes this unworkable as sole solution**
- Still need initial detection in Part 2
- Adds complexity without solving root problem

#### Option 4: Centralized Bootstrap Library

**Description**: Create a minimal bootstrap library that detects CLAUDE_PROJECT_DIR and can be sourced with minimal/no dependencies.

**Implementation**:
```bash
# New file: .claude/lib/bootstrap.sh
#!/usr/bin/env bash
# Bootstrap script - sources using pwd-relative path
CLAUDE_CONFIG_DIR="${PWD}/.claude"
if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
  # Search upward
  ...
fi
source "${CLAUDE_CONFIG_DIR}/lib/detect-project-dir.sh"
```

```bash
# In build.md blocks:
source .claude/lib/bootstrap.sh  # Works from repo root
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
```

**Advantages**:
- Single source of truth for bootstrap logic
- Simple first-line inclusion

**Disadvantages**:
- Assumes command runs from repo root (not always true)
- Adds another file to maintain
- Doesn't solve the fundamental path resolution issue

#### Option 5: Environment Variable Export Pattern

**Description**: Export CLAUDE_PROJECT_DIR from Part 2 shell to subsequent blocks through temp file.

**Note**: This is exactly what the current code attempts but fails because bash blocks run as separate subprocesses.

**Implementation**:
```bash
# Part 2: Save to file
echo "$CLAUDE_PROJECT_DIR" > ~/.claude/tmp/project_dir.txt

# Part 3+: Read from file
CLAUDE_PROJECT_DIR=$(cat ~/.claude/tmp/project_dir.txt)
export CLAUDE_PROJECT_DIR
```

**Advantages**:
- Simple file-based persistence
- Already pattern used for WORKFLOW_ID

**Disadvantages**:
- Requires reading file before sourcing libraries
- Still need detection in Part 2
- Slightly slower than inline detection

### Key Insight: Why workflow-state-machine.sh Works Differently

Looking at workflow-state-machine.sh (lines 32-34):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"
```

This pattern works because when workflow-state-machine.sh IS successfully sourced, it uses BASH_SOURCE to find its own location, then sources detect-project-dir.sh relative to itself.

**However**, this doesn't help the /build command because:
1. The source command itself uses `${CLAUDE_PROJECT_DIR}` which is unset
2. The library's self-detection never runs because sourcing fails first

## Recommendations

### Recommendation 1: Implement the Existing Plan (Inline Detection)

**Rationale**: The current proposed fix in the 768 plan is the most pragmatic solution despite code duplication.

**Why this is best**:
1. Already proven in /plan command
2. No architectural changes needed
3. Each bash block fully self-sufficient
4. Clear, explicit, easy to debug

**Trade-off acceptance**: Accept 96 lines of duplication for reliability and clarity.

### Recommendation 2: Create a Detection Snippet Library (Future Enhancement)

**Rationale**: For long-term maintainability, extract the detection pattern to a sourceable snippet.

**Implementation**:
```bash
# .claude/lib/source-detection-snippet.sh (6 lines, not a function)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

This would be sourced inline:
```bash
source .claude/lib/source-detection-snippet.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
```

**Note**: This assumes working directory is repo root, which is typically true for Claude Code commands.

### Recommendation 3: Add Project Root File Persistence (Complement to Plan)

**Rationale**: Once detected in Part 2, persist to file for faster reads in Parts 3-7.

```bash
# Part 2: After detection
echo "$CLAUDE_PROJECT_DIR" > "${HOME}/.claude/tmp/build_project_dir.txt"

# Parts 3-7: Before sourcing
if [ -z "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "${HOME}/.claude/tmp/build_project_dir.txt" ]; then
  CLAUDE_PROJECT_DIR=$(cat "${HOME}/.claude/tmp/build_project_dir.txt")
  export CLAUDE_PROJECT_DIR
fi
```

This provides a fast path while maintaining the full detection as fallback.

### Recommended Implementation Order

1. **Immediate fix**: Implement the 768 plan (inline detection in all blocks)
2. **Enhancement**: Add file-based caching for performance
3. **Future**: Consider centralizing to snippet if pattern spreads to more commands

## References

### Files Analyzed with Line Numbers

1. **/home/benjamin/.config/.claude/specs/768_research_build_errors_from_claude_build_output_md_/plans/001_research_build_errors_from_claude_build__plan.md** (lines 1-273)
   - Existing plan for fixing CLAUDE_PROJECT_DIR detection
   - Technical design section lines 54-77

2. **/home/benjamin/.config/.claude/commands/plan.md** (lines 1-528)
   - Working implementation of inline detection pattern
   - Part 3 detection: lines 111-134
   - Library sourcing: lines 136-149

3. **/home/benjamin/.config/.claude/commands/build.md** (lines 1-773)
   - Failing command with missing detection
   - Part 2 detection: lines 75-92 (works)
   - Part 3 missing detection: lines 210-214 (fails)

4. **/home/benjamin/.config/.claude/lib/state-persistence.sh** (lines 1-499)
   - State persistence library with built-in detection
   - Detection code: lines 96-100
   - init_workflow_state: lines 130-169

5. **/home/benjamin/.config/.claude/lib/workflow-state-machine.sh** (lines 1-910)
   - Self-detecting library pattern
   - SCRIPT_DIR pattern: lines 32-34
   - sm_init function: lines 392-512

6. **/home/benjamin/.config/.claude/lib/detect-project-dir.sh** (lines 1-51)
   - Centralized detection utility
   - Detection logic: lines 21-50

7. **/home/benjamin/.config/.claude/lib/unified-location-detection.sh** (lines 1-621)
   - Comprehensive location detection
   - detect_project_root: lines 94-112
   - allocate_and_create_topic: lines 242-300

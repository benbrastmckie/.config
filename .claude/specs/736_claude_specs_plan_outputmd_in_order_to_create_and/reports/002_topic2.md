# Path Detection Infrastructure Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Path Detection Infrastructure
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The CLAUDE_PROJECT_DIR detection infrastructure uses a multi-tiered bootstrap strategy that evolved from library-dependent sourcing to inline git-based detection. The bootstrap paradox (needing detect-project-dir.sh to find the project directory, but needing the project directory to source detect-project-dir.sh) was resolved in Spec 732 by implementing inline detection with a 3-step precedence order: git repository root → upward directory search for .claude/ → fail-fast error. The .claude/lib/ structure contains 59+ libraries with detect-project-dir.sh (51 lines) serving as a lightweight standalone utility, while unified-location-detection.sh (597 lines) provides comprehensive location detection for workflows. Bootstrap sequence in slash commands follows Standard 13 with inline detection before any library sourcing.

## Findings

### 1. Bootstrap Paradox and Resolution

**Historical Context** (from Spec 732):

**Original Problem** (/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/001_topic1.md):
- Commands used `BASH_SOURCE[0]` to calculate `SCRIPT_DIR` for library sourcing
- Failed pattern: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- In Claude Code's bash block execution, `BASH_SOURCE[0]` returns empty string
- Resulted in incorrect path resolution: `/current/dir/../lib/` instead of `/project/.claude/lib/`

**Bootstrap Paradox**:
- Need detect-project-dir.sh to find CLAUDE_PROJECT_DIR
- Need CLAUDE_PROJECT_DIR to source detect-project-dir.sh from correct location
- BASH_SOURCE doesn't work in bash block execution model (subprocesses, not scripts)

**Resolution** (Spec 732 Phase 1):
Replace library-dependent detection with inline git-based bootstrap:

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
```

**Reference**: /home/benjamin/.config/.claude/commands/plan.md:22-52

### 2. CLAUDE_PROJECT_DIR Detection Precedence Order

**Three-Tiered Detection Strategy**:

**Tier 1: Manual Override** (highest priority)
```bash
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  # Already set by user or environment
  export CLAUDE_PROJECT_DIR
  return 0
fi
```
- Environment variable pre-set by user or parent process
- Used for: manual overrides, test isolation, custom workflows
- Reference: /home/benjamin/.config/.claude/lib/detect-project-dir.sh:22-26

**Tier 2: Git Repository Root** (primary detection)
```bash
if command -v git &>/dev/null; then
  if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    export CLAUDE_PROJECT_DIR
    return 0
  fi
fi
```
- Correctly handles git worktrees (returns worktree root, not main repo)
- Handles submodules and symbolic links
- Performance: ~6ms first call, <1ms cached
- Reference: /home/benjamin/.config/.claude/lib/detect-project-dir.sh:34-40

**Tier 3: Upward Directory Search** (fallback for non-git projects)
```bash
current_dir="$(pwd)"
while [ "$current_dir" != "/" ]; do
  if [ -d "$current_dir/.claude" ]; then
    CLAUDE_PROJECT_DIR="$current_dir"
    break
  fi
  current_dir="$(dirname "$current_dir")"
done
```
- Searches parent directories for .claude/ directory marker
- Used when not in git repository or git unavailable
- Reference: /home/benjamin/.config/.claude/commands/plan.md:32-40

**Tier 4: Fail-Fast Validation** (error if all methods fail)
```bash
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree"
  echo "SOLUTION: Run command from within a directory containing .claude/ subdirectory"
  exit 1
fi
```
- No silent fallback to current directory (violates fail-fast principle)
- Clear diagnostic messages guide user to solution
- Reference: /home/benjamin/.config/.claude/commands/plan.md:44-49

### 3. Library Structure and Roles

**Two Primary Path Detection Libraries**:

**3.1 detect-project-dir.sh** (51 lines, standalone utility):

**Purpose**: Lightweight CLAUDE_PROJECT_DIR detection for standalone scripts
**Location**: /home/benjamin/.config/.claude/lib/detect-project-dir.sh
**Features**:
- Detects and exports CLAUDE_PROJECT_DIR
- 3-tier precedence: manual override → git root → current directory fallback
- Graceful degradation (always succeeds, uses fallback)
- Designed for sourcing by standalone scripts

**Usage Pattern**:
```bash
source "${BASH_SOURCE%/*}/../lib/detect-project-dir.sh"
# CLAUDE_PROJECT_DIR is now set and exported
```

**Key Characteristics**:
- Returns 0 even on fallback (no exit on failure)
- Intended for standalone scripts that handle their own errors
- Minimal dependencies (pure bash + git command)

**Reference**: /home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-51

**3.2 unified-location-detection.sh** (597 lines, workflow orchestration):

**Purpose**: Comprehensive location detection for workflow commands
**Location**: /home/benjamin/.config/.claude/lib/unified-location-detection.sh
**Features**:
- Project root detection: `detect_project_root()`
- Specs directory detection: `detect_specs_directory(project_root)`
- Topic number allocation: `get_next_topic_number(specs_root)`
- Atomic topic creation: `allocate_and_create_topic(specs_root, topic_name)`
- Lazy directory creation: `ensure_artifact_directory(file_path)`
- Research subdirectory support: `create_research_subdirectory(topic_path, research_name)`
- Test isolation support via CLAUDE_SPECS_ROOT override
- Concurrency guarantees via file locks (0% collision rate)

**Key Innovations**:
- **Lazy Directory Creation**: Creates artifact directories only when files written (eliminated 400-500 empty directories)
- **Atomic Topic Allocation**: Holds file lock through both number calculation AND directory creation (eliminates race conditions)
- **Performance**: 80% reduction in mkdir calls, ~2ms lock overhead
- **Test Isolation**: CLAUDE_SPECS_ROOT environment variable override prevents production pollution

**Reference**: /home/benjamin/.config/.claude/lib/unified-location-detection.sh:1-597

**Library Comparison**:

| Feature | detect-project-dir.sh | unified-location-detection.sh |
|---------|----------------------|------------------------------|
| Size | 51 lines | 597 lines |
| Purpose | Standalone CLAUDE_PROJECT_DIR | Complete workflow orchestration |
| Failure Mode | Graceful fallback | Fail-fast on errors |
| Dependencies | None (git only) | None (pure bash + jq) |
| Used By | Older libraries, standalone scripts | /research, /plan, /coordinate, /implement |
| Test Isolation | Manual override only | CLAUDE_SPECS_ROOT + CLAUDE_PROJECT_DIR |
| Concurrency | No locking | File locks for topic allocation |

### 4. Bootstrap Sequence in Slash Commands

**Standard 13 Bootstrap Pattern** (from plan.md lines 22-52):

**Phase 0: Orchestrator Initialization**

**Step 1: Inline CLAUDE_PROJECT_DIR Detection** (BEFORE any library sourcing)
```bash
set +H  # Disable history expansion to prevent bad substitution errors

# STANDARD 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
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
  echo "SOLUTION: Run /plan from within a directory containing .claude/ subdirectory"
  exit 1
fi

# Export for use by sourced libraries
export CLAUDE_PROJECT_DIR
```

**Step 2: Calculate UTILS_DIR** (now safe, CLAUDE_PROJECT_DIR validated)
```bash
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
```

**Step 3: Source Libraries in Dependency Order** (STANDARD 15)
```bash
# Source workflow state machine foundation FIRST
if ! source "$UTILS_DIR/workflow-state-machine.sh" 2>&1; then
  echo "ERROR: Failed to source workflow-state-machine.sh"
  echo "DIAGNOSTIC: Required for state management"
  exit 1
fi

# Source state persistence SECOND
if ! source "$UTILS_DIR/state-persistence.sh" 2>&1; then
  echo "ERROR: Failed to source state-persistence.sh"
  echo "DIAGNOSTIC: Required for workflow state persistence"
  exit 1
fi

# Source error handling THIRD
if ! source "$UTILS_DIR/error-handling.sh" 2>&1; then
  echo "ERROR: Failed to source error-handling.sh"
  echo "DIAGNOSTIC: Required for error classification and recovery"
  exit 1
fi

# Additional libraries...
```

**Reference**: /home/benjamin/.config/.claude/commands/plan.md:22-97

**Alternative Pattern (coordinate.md lines 60-64)**:

**Simplified Bootstrap** (for commands with simpler initialization):
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Differences**:
- No upward directory search fallback
- Uses current directory as final fallback (graceful degradation)
- Shorter code (4 lines vs 31 lines)
- Less diagnostic output
- Still validates git availability

**When to Use**:
- Simple commands without complex initialization
- Commands that don't need upward search capability
- Commands invoked from project root

**Reference**: /home/benjamin/.config/.claude/commands/coordinate.md:60-64

### 5. Library Sourcing Anti-Patterns

**Anti-Pattern: BASH_SOURCE-Based SCRIPT_DIR** (documented in bash-block-execution-model.md:685-736)

**Problem**:
```bash
# ❌ ANTI-PATTERN: BASH_SOURCE-based SCRIPT_DIR (fails in Claude Code)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
```

**Why It Fails**:
- Claude Code executes bash blocks as separate subprocesses (`bash -c 'commands'`)
- BASH_SOURCE[0] requires being executed from a script file (`bash script.sh`)
- In subprocess execution, BASH_SOURCE[0] is empty
- SCRIPT_DIR resolves to current working directory, not commands directory
- Path resolution fails: `/current/dir/../lib/` instead of `/project/.claude/lib/`

**Impact** (from Spec 732 audit):
- **Affected Commands**: /plan, /implement, /expand, /collapse (4 commands)
- **Severity**: CRITICAL (commands completely non-functional)
- **Root Cause**: Bootstrap failure prevents any library sourcing
- **User Impact**: Complete workflow breakage for planning and implementation

**References**:
- /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md:1-117
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:685-736

**Fix Status** (from Spec 732):
- ✓ Fixed: /plan (Spec 732 Phase 1)
- Requires fix: /implement, /expand, /collapse

### 6. detect-project-dir.sh Location and Purpose

**File Location**: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh`

**Purpose** (from file header documentation):
- Detects and exports CLAUDE_PROJECT_DIR dynamically
- Provides centralized project directory detection for Claude Code commands and utilities
- Enables proper git worktree isolation

**Detection Strategy** (3-tier precedence):
1. Respect existing CLAUDE_PROJECT_DIR if already set (manual override)
2. Use git repository root (primary method, handles worktrees correctly)
3. Fallback to current directory (when not in git repo)

**Usage Pattern** (from file documentation):
```bash
source "${BASH_SOURCE%/*}/../lib/detect-project-dir.sh"
# CLAUDE_PROJECT_DIR is now set and exported
```

**Return Behavior**:
- Always returns 0 (success)
- Graceful degradation to current directory fallback
- No fail-fast error (designed for standalone scripts)

**Current Usage Analysis**:

**Libraries Still Using detect-project-dir.sh** (19 files found via grep):
- /home/benjamin/.config/.claude/lib/checkbox-utils.sh:15
- /home/benjamin/.config/.claude/lib/metadata-extraction.sh:7
- /home/benjamin/.config/.claude/lib/workflow-initialization.sh:24
- /home/benjamin/.config/.claude/lib/workflow-detection.sh:14
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:29
- /home/benjamin/.config/.claude/lib/complexity-utils.sh:10
- /home/benjamin/.config/.claude/lib/agent-schema-validator.sh:7
- ... (19 total files)

**Pattern**: These libraries use BASH_SOURCE for self-location:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"
```

**This pattern works in libraries** because:
- Libraries are sourced by commands, not executed as bash blocks
- BASH_SOURCE[0] points to the library file being sourced
- SCRIPT_DIR correctly resolves to .claude/lib/
- Path resolution succeeds: `.claude/lib/detect-project-dir.sh`

**Why Commands Can't Use This Pattern**:
- Commands execute as bash blocks (subprocesses without script metadata)
- BASH_SOURCE[0] is empty in subprocess execution
- Must use inline detection instead

**Reference**: /home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-51

### 7. Path Calculation in .claude/lib Structure

**Directory Organization**:

```
.claude/
├── commands/          # Slash command markdown files
│   ├── plan.md       # Uses inline bootstrap
│   ├── coordinate.md # Uses inline bootstrap
│   └── research.md   # Uses inline bootstrap
├── lib/              # Sourced libraries (59+ files)
│   ├── detect-project-dir.sh              # 51 lines, standalone utility
│   ├── unified-location-detection.sh      # 597 lines, workflow orchestration
│   ├── workflow-state-machine.sh          # Uses detect-project-dir.sh
│   ├── state-persistence.sh               # Uses inline detection
│   └── [56 other libraries]
└── specs/            # Implementation plans and reports
    └── {NNN_topic}/ # Topic-based structure
```

**Path Calculation Patterns by Context**:

**Context 1: Slash Commands** (bash blocks)
```bash
# MUST use inline detection (BASH_SOURCE doesn't work)
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

UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
source "$UTILS_DIR/unified-location-detection.sh"
```

**Context 2: Libraries** (sourced files)
```bash
# CAN use BASH_SOURCE (works when sourced)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"
# CLAUDE_PROJECT_DIR now available
```

**Context 3: Subsequent Bash Blocks** (state persistence)
```bash
# Load CLAUDE_PROJECT_DIR from state file (67% faster: 6ms → 2ms)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "$WORKFLOW_ID"
# CLAUDE_PROJECT_DIR restored from state file
```

**Performance Characteristics**:

| Method | First Call | Cached/Subsequent | Use Case |
|--------|-----------|-------------------|----------|
| Git detection | ~6ms | <1ms (git caches) | First bash block |
| State file load | N/A | ~2ms (file read) | Subsequent blocks |
| BASH_SOURCE + detect-project-dir.sh | ~6ms | N/A (libraries sourced once per block) | Library initialization |
| Upward directory search | Variable (depends on depth) | N/A | Non-git projects |

**References**:
- /home/benjamin/.config/.claude/lib/state-persistence.sh:49-71 (performance optimization rationale)
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md:1037-1055 (performance metrics)

### 8. Bootstrap Sequence Decision Tree

**When Command Executes**:

```
START
  ↓
Is CLAUDE_PROJECT_DIR already set?
  ├─ YES → Use existing value (manual override)
  │         export CLAUDE_PROJECT_DIR
  │         SKIP to UTILS_DIR calculation
  │
  └─ NO → Detect project directory
            ↓
          Is git available AND inside git repository?
            ├─ YES → CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
            │         export CLAUDE_PROJECT_DIR
            │         PROCEED to UTILS_DIR calculation
            │
            └─ NO → Search upward for .claude/ directory
                      ↓
                    current_dir="$(pwd)"
                    while [ "$current_dir" != "/" ]; do
                      if [ -d "$current_dir/.claude" ]; then
                        CLAUDE_PROJECT_DIR="$current_dir"
                        break
                      fi
                      current_dir="$(dirname "$current_dir")"
                    done
                      ↓
                    Is CLAUDE_PROJECT_DIR set AND .claude/ exists?
                      ├─ YES → export CLAUDE_PROJECT_DIR
                      │         PROCEED to UTILS_DIR calculation
                      │
                      └─ NO → echo "ERROR: Failed to detect project directory"
                               echo "DIAGNOSTIC: No git repository..."
                               echo "SOLUTION: Run from directory with .claude/"
                               exit 1 (FAIL-FAST)

UTILS_DIR Calculation:
  UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"

Source Libraries (in dependency order):
  source "$UTILS_DIR/workflow-state-machine.sh"
  source "$UTILS_DIR/state-persistence.sh"
  source "$UTILS_DIR/error-handling.sh"
  source "$UTILS_DIR/verification-helpers.sh"
  source "$UTILS_DIR/unified-location-detection.sh"
  [etc...]

PROCEED to command execution
```

**Key Decision Points**:
1. **Manual override check** (highest priority): Respects pre-set CLAUDE_PROJECT_DIR
2. **Git detection** (primary method): Fast, reliable, handles worktrees
3. **Upward search** (fallback): For non-git projects with .claude/ marker
4. **Validation** (fail-fast): No silent fallback to current directory
5. **Library sourcing** (dependency order): State → error → verification → others

## Recommendations

### 1. Use Inline Bootstrap for All Slash Commands

**Action**: Always use inline CLAUDE_PROJECT_DIR detection in slash command bash blocks, never rely on BASH_SOURCE-based library sourcing.

**Rationale**:
- BASH_SOURCE[0] is empty in Claude Code's bash block execution model
- Inline detection eliminates bootstrap paradox
- Fail-fast validation provides clear error messages
- Spec 732 validated this approach fixes broken commands

**Pattern to Use**:
```bash
set +H  # Disable history expansion

# Inline bootstrap (before ANY library sourcing)
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

# Validate (fail-fast)
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Now safe to source libraries
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
source "$UTILS_DIR/workflow-state-machine.sh"
```

**Reference**: /home/benjamin/.config/.claude/commands/plan.md:22-52

### 2. Maintain Two Distinct Path Detection Libraries

**Action**: Keep both detect-project-dir.sh and unified-location-detection.sh with clear separation of concerns.

**Rationale**:
- **detect-project-dir.sh**: Lightweight (51 lines), designed for library initialization, graceful fallback
- **unified-location-detection.sh**: Comprehensive (597 lines), workflow orchestration, fail-fast, concurrency guarantees
- Different use cases require different failure modes and feature sets

**Usage Guidelines**:
- **Libraries** (.claude/lib/*.sh): Use detect-project-dir.sh for initialization
- **Commands** (.claude/commands/*.md): Use inline bootstrap, then source unified-location-detection.sh for workflows
- **Standalone Scripts**: Use detect-project-dir.sh with graceful degradation

**Do NOT**:
- Merge the two libraries (different purposes, failure modes)
- Use unified-location-detection.sh in library initialization (overkill, circular dependency risk)
- Use detect-project-dir.sh in commands (bootstrap paradox)

**Reference**:
- /home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-51
- /home/benjamin/.config/.claude/lib/unified-location-detection.sh:1-597

### 3. Fix Remaining Commands Using BASH_SOURCE Pattern

**Action**: Apply Spec 732's inline bootstrap fix to /implement, /expand, and /collapse commands.

**Affected Files**:
- /home/benjamin/.config/.claude/commands/implement.md:21
- /home/benjamin/.config/.claude/commands/expand.md:80, 563
- /home/benjamin/.config/.claude/commands/collapse.md:82, 431

**Current Broken Pattern** (lines identified in audit):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
```

**Fix to Apply** (same as plan.md Phase 1):
Replace with inline bootstrap pattern (see Recommendation 1 for full code).

**Priority**:
- HIGH: /implement (critical for implementation workflow)
- MEDIUM: /expand, /collapse (used for plan management)

**Testing**:
- Test from project root
- Test from subdirectories
- Test outside project (should fail with clear error)

**Reference**: /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md:1-117

### 4. Document Bootstrap Sequence as Standard Pattern

**Action**: Create reusable documentation snippet for bootstrap sequence that can be referenced in all slash command development.

**Content to Document**:
1. **Phase 0: Inline Bootstrap** (before any library sourcing)
   - Git-based detection with upward search fallback
   - Fail-fast validation
   - Export CLAUDE_PROJECT_DIR

2. **Phase 1: UTILS_DIR Calculation** (now safe)
   - `UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"`

3. **Phase 2: Library Sourcing** (in dependency order)
   - State management first
   - Error handling second
   - Verification third
   - Others as needed

**Location Suggestion**:
- /home/benjamin/.config/.claude/docs/guides/command-development-fundamentals.md
- Section: "Bootstrap Sequence for Slash Commands"

**Benefits**:
- Prevents future BASH_SOURCE mistakes
- Standardizes bootstrap across all commands
- Reduces duplication (reference instead of copy-paste)
- Makes Standard 13 easily discoverable

**Reference**: /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:685-736 (existing anti-pattern documentation)

### 5. Preserve BASH_SOURCE Pattern in Libraries

**Action**: Keep BASH_SOURCE-based SCRIPT_DIR calculation in libraries (.claude/lib/*.sh files), do NOT migrate to inline detection.

**Rationale**:
- BASH_SOURCE works correctly when libraries are sourced (not executed as bash blocks)
- Libraries are sourced by commands, not executed independently
- Pattern is appropriate for library context: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- 19 libraries currently use this pattern successfully

**When BASH_SOURCE Works**:
- ✓ Libraries being sourced by other scripts
- ✓ Standalone scripts executed with `bash script.sh`
- ✗ Bash blocks in slash commands (subprocess execution)

**Libraries Using This Pattern** (should remain unchanged):
- workflow-state-machine.sh:29
- checkpoint-utils.sh:16
- metadata-extraction.sh:7
- [16 more libraries]

**Reference**: /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:29

## References

### Core Path Detection Libraries
- /home/benjamin/.config/.claude/lib/detect-project-dir.sh (51 lines)
  - Lightweight standalone utility for libraries
  - Lines 22-26: Manual override check
  - Lines 34-40: Git repository detection
  - Lines 47-48: Current directory fallback

- /home/benjamin/.config/.claude/lib/unified-location-detection.sh (597 lines)
  - Comprehensive workflow orchestration
  - Lines 88-106: detect_project_root() function
  - Lines 125-157: detect_specs_directory() function
  - Lines 175-203: get_next_topic_number() with file locking
  - Lines 235-276: allocate_and_create_topic() atomic operation
  - Lines 367-378: ensure_artifact_directory() lazy creation

### Slash Command Bootstrap Examples
- /home/benjamin/.config/.claude/commands/plan.md:22-52
  - Complete inline bootstrap with upward search
  - Fail-fast validation
  - Standard 15 library sourcing order (lines 54-97)

- /home/benjamin/.config/.claude/commands/coordinate.md:60-64
  - Simplified bootstrap pattern
  - Git detection with current directory fallback

- /home/benjamin/.config/.claude/commands/research.md:99
  - Uses relative path for library sourcing (alternative pattern)

### Spec 732 Bootstrap Fix Documentation
- /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/001_topic1.md (1-212)
  - Root cause analysis of BASH_SOURCE failure
  - Lines 15-35: Error analysis and path resolution failure
  - Lines 36-65: Standard 13 specification
  - Lines 89-106: Recommended fix (inline detection)

- /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md (1-117)
  - Complete audit of affected commands
  - Lines 9-43: Three additional broken commands
  - Lines 45-85: Root cause explanation
  - Lines 87-95: Recommended fix to apply

### Bash Block Execution Model Documentation
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md (952 lines)
  - Lines 1-48: Subprocess isolation overview
  - Lines 685-736: Anti-Pattern 5 - BASH_SOURCE usage
  - Lines 703-731: Correct inline detection pattern
  - Lines 733-736: Impact and fix status

### State Persistence Architecture
- /home/benjamin/.config/.claude/lib/state-persistence.sh (393 lines)
  - Lines 49-71: Performance optimization rationale
  - Lines 117-144: init_workflow_state() function
  - Lines 187-229: load_workflow_state() function

- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md (1748 lines)
  - Lines 1037-1055: Performance metrics for path detection
  - Lines 36: 67% performance improvement (6ms → 2ms)

### Library Usage Patterns
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh:29
  - Example of BASH_SOURCE usage in library context (works correctly)

- /home/benjamin/.config/.claude/lib/source-libraries-snippet.sh (45 lines)
  - Documentation-only snippet for bash block library sourcing
  - Lines 13-24: Complete sourcing pattern

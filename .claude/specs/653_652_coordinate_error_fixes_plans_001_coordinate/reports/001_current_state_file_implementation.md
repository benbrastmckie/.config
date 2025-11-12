# Current State File Implementation Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Current state file implementation in /coordinate and state-persistence.sh
- **Report Type**: codebase analysis

## Executive Summary

State files in /coordinate are currently created in `.claude/tmp/` directories using timestamp-based workflow IDs (e.g., `workflow_coordinate_1762798806.sh`). This location was chosen for subprocess isolation compatibility and temporary state management across bash block boundaries. However, a TODO item indicates a planned migration to `.claude/data/workflow/` for better organization and persistence semantics. The current implementation works correctly but mixes temporary workflow state with supervisor checkpoints that should be persistent.

## Findings

### 1. Current State File Location and Naming

**Location**: `.claude/tmp/workflow_${WORKFLOW_ID}.sh`

**Naming Pattern**:
- Workflow ID format: `coordinate_$(date +%s)` (e.g., `coordinate_1762798806`)
- State file: `.claude/tmp/workflow_coordinate_1762798806.sh`
- State ID file: `${HOME}/.claude/tmp/coordinate_state_id.txt` (fixed location for cross-block access)

**Evidence**:
- `state-persistence.sh:129`: `STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"`
- `coordinate.md:108`: `WORKFLOW_ID="coordinate_$(date +%s)"`
- `coordinate.md:110`: `STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")`
- `coordinate.md:114`: `COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"`

**Actual Files in .claude/tmp/**:
```
workflow_cleanup_3197722.sh (171 bytes)
workflow_coordinate_1762798269.sh (480 bytes)
workflow_coordinate_1762798806.sh (517 bytes)
workflow_coordinate_1762798901.sh (517 bytes)
workflow_coordinate_1762799627.sh (1883 bytes)
```

### 2. Rationale for Using .claude/tmp/

**Primary Reason: Subprocess Isolation Compatibility**

The bash block execution model requires that state persist across subprocess boundaries. Files are the ONLY reliable cross-block communication channel.

**Key Design Decision** (from `bash-block-execution-model.md:56-59`):
```
### Persists Across Blocks ✓
| Item | Persistence Method | Example |
| Files | Written to filesystem | echo "data" > /tmp/state.txt |
| State files | Via state-persistence.sh | append_workflow_state "KEY" "value" |
```

**Rationale Points**:

1. **Temporary Nature**: State files represent ephemeral workflow session state, not permanent artifacts
2. **Cleanup Semantics**: `.claude/tmp/` signals these files are safe to delete after workflow completion
3. **Performance**: Fast local filesystem access for high-frequency state updates (append operations every bash block)
4. **Subprocess Coordination**: Fixed location pattern enables cross-block state restoration

**Evidence from state-persistence.sh**:
- Line 108: "Creates state file in .claude/tmp/"
- Line 19: "EXIT trap cleanup (prevent state file leakage)"
- Line 139: "Setting trap in subshell (when called via $(...)) causes immediate cleanup"

### 3. How /coordinate Initializes State Files

**Three-Step Initialization Pattern**:

**Step 1: Calculate Workflow ID** (coordinate.md:107-108)
```bash
WORKFLOW_ID="coordinate_$(date +%s)"
```

**Step 2: Initialize State File** (coordinate.md:110)
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
```

**Step 3: Save ID to Fixed Location** (coordinate.md:113-114)
```bash
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
```

**init_workflow_state() Implementation** (state-persistence.sh:115-142):

```bash
init_workflow_state() {
  local workflow_id="${1:-$$}"

  # Detect CLAUDE_PROJECT_DIR ONCE (performance optimization)
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    export CLAUDE_PROJECT_DIR
  fi

  # Create .claude/tmp if it doesn't exist
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"

  # Create state file
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$workflow_id"
export STATE_FILE="$STATE_FILE"
EOF

  echo "$STATE_FILE"
}
```

**Key Features**:
- **Lazy directory creation**: `mkdir -p` ensures `.claude/tmp/` exists
- **Performance optimization**: CLAUDE_PROJECT_DIR cached in state file (70% faster: 50ms → 15ms)
- **GitHub Actions pattern**: State file contains bash export statements

### 4. State Loading Mechanism

**Load Pattern Used in Every Bash Block** (coordinate.md:272-281):

```bash
# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found"
  exit 1
fi
```

**load_workflow_state() Implementation** (state-persistence.sh:168-182):

```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    # State file exists - source it to restore variables
    source "$state_file"
    return 0
  else
    # Fallback: recalculate if state file missing (graceful degradation)
    init_workflow_state "$workflow_id" >/dev/null
    return 1
  fi
}
```

**Graceful Degradation**: If state file is missing, automatically recreates it (handles edge cases like premature cleanup)

### 5. State File Content Structure

**Example State File** (.claude/tmp/workflow_coordinate_1762798901.sh):

```bash
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
export WORKFLOW_ID="coordinate_1762798901"
export STATE_FILE="/home/benjamin/.config/.claude/tmp/workflow_coordinate_1762798901.sh"
export WORKFLOW_DESCRIPTION="Research bash execution patterns and state management"
export WORKFLOW_SCOPE="research-and-plan"
export TERMINAL_STATE="complete"
export CURRENT_STATE="research"
export TOPIC_PATH="/home/benjamin/.config/.claude/specs/653_..."
export PLAN_PATH="/home/benjamin/.config/.claude/specs/653_.../plans/..."
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="/path/to/report1.md"
export REPORT_PATH_1="/path/to/report2.md"
export REPORT_PATH_2="/path/to/report3.md"
export REPORT_PATH_3="/path/to/report4.md"
```

**Accumulation Pattern**: Each bash block appends new state via `append_workflow_state()` (state-persistence.sh:207-217)

### 6. Relationship with .claude/data/ Directory

**.claude/data/ Structure**:
```
.claude/data/
├── backups/           # Configuration backups
├── checkpoints/       # Implementation progress checkpoints
├── logs/              # Adaptive planning, error logs
├── metrics/           # Command execution metrics
├── registry/          # Artifact registry
└── (workflow/) ← NOT YET CREATED (planned location per TODO)
```

**Current Separation**:
- **Temporary workflow state**: `.claude/tmp/workflow_*.sh` (session-scoped)
- **Persistent artifacts**: `.claude/data/` (permanent)
- **Supervisor checkpoints**: `.claude/tmp/*.json` (should be `.claude/data/checkpoints/`)

**Evidence**:
- `TODO.md:5`: "Instead of capturing workflow descriptions to /home/benjamin/.claude/tmp/, use .claude/data/workflow/"
- `checkpoint-utils.sh:90`: `readonly CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints"`
- `state-persistence.sh:252`: `checkpoint_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/${checkpoint_name}.json"` (supervisor checkpoints in tmp/)

### 7. Cleanup Strategy and Lifecycle

**Current Cleanup**: Manual or via external cleanup script

**Design Decision** (coordinate.md:116-117):
```bash
# NOTE: NO trap handler here! Files must persist for subsequent bash blocks.
# Cleanup will happen manually or via external cleanup script.
```

**Why No Trap in /coordinate**:
- Bash blocks run as separate subprocesses
- EXIT trap in early blocks fires at block exit, NOT workflow exit
- Premature cleanup would delete state needed by later blocks

**Evidence from bash-block-execution-model.md:287-305**:
```
### Pattern 5: Cleanup on Completion Only
**Problem**: Trap handlers in early blocks fire at block exit, not workflow exit.
**Solution**: Only set cleanup traps in final completion function.
```

**Cleanup Scripts Observed**:
```
workflow_cleanup_3197722.sh (171 bytes)
workflow_cleanup_3198524.sh (171 bytes)
... (6 more cleanup scripts)
```

These are likely one-time cleanup utilities, not automatic trap handlers.

### 8. Performance Characteristics

**State File Operations** (state-persistence.sh:41-45):
- CLAUDE_PROJECT_DIR detection: 50ms (git rev-parse) → 15ms (file read) = **70% improvement**
- State file initialization: ~5-10ms (file write)
- State file sourcing: ~2-5ms (bash source)
- Append operation: <1ms (echo >> redirect)
- Graceful degradation overhead: <1ms (file existence check)

**JSON Checkpoint Operations** (state-persistence.sh:225-258):
- Write operation: 5-10ms (temp file + mv + fsync)
- Read operation: 2-5ms (cat + optional jq validation)
- Atomic guarantee: temp file + mv ensures no partial writes

### 9. Fixed Location Pattern for Cross-Block Access

**Problem**: Bash `$$` changes across subprocess boundaries

**Solution**: Fixed semantic filename stored in predictable location

**Implementation**:
1. **Workflow ID saved once**: `${HOME}/.claude/tmp/coordinate_state_id.txt`
2. **Every bash block reads this file**: Deterministic state file path calculation
3. **State file path**: `.claude/tmp/workflow_${WORKFLOW_ID}.sh`

**Evidence from bash-block-execution-model.md:169-191**:
```
### Pattern 1: Fixed Semantic Filenames
❌ ANTI-PATTERN: PID-based filename ($$)
✓ RECOMMENDED: Fixed semantic filename based on workflow context
```

### 10. Implications and Trade-offs

**Advantages of Current .claude/tmp/ Approach**:
1. **Clear semantics**: "tmp" signals ephemeral nature
2. **Fast cleanup**: `rm -rf .claude/tmp/` safe operation
3. **Performance**: Local filesystem, no complex path resolution
4. **Debuggability**: State files visible for troubleshooting

**Disadvantages**:
1. **Persistence confusion**: Supervisor checkpoints mixed with temp state
2. **No automatic cleanup**: Requires manual intervention or external script
3. **$HOME dependency**: State ID file uses $HOME instead of project-relative path
4. **Migration needed**: TODO item indicates planned .claude/data/workflow/ migration

**Debugging Impact**:
- Developers can inspect state files: `cat .claude/tmp/workflow_*.sh`
- State evolution visible: File grows as workflow progresses
- Easy to identify stuck workflows: Old files indicate abandoned sessions

**Persistence Semantics Issue**:
- Supervisor checkpoints (research_supervisor.json, implementation_supervisor.json) should survive workflow cleanup
- Currently stored in `.claude/tmp/` alongside ephemeral state files
- Should be in `.claude/data/checkpoints/` per checkpoint-utils.sh

## Recommendations

### 1. Implement .claude/data/workflow/ Migration (High Priority)

**Action**: Migrate workflow state files from `.claude/tmp/` to `.claude/data/workflow/` as indicated in TODO.md

**Rationale**:
- Better organizational semantics (.data/ for persistent state, .tmp/ for true ephemera)
- Aligns with existing .claude/data/ structure (logs, checkpoints, metrics)
- Enables differentiated cleanup policies (keep recent workflow sessions, purge truly temporary files)

**Implementation**:
1. Update `state-persistence.sh:129` to use `.claude/data/workflow/` instead of `.claude/tmp/`
2. Update `/coordinate` state ID file path to `.claude/data/workflow/coordinate_state_id.txt`
3. Add automatic cleanup of workflow files older than 7 days (retain recent for debugging)

**Impact**: Low risk - state files still files, just different directory

### 2. Separate Supervisor Checkpoints from Workflow State (Medium Priority)

**Action**: Move supervisor checkpoint saves to `.claude/data/checkpoints/` instead of `.claude/tmp/`

**Rationale**:
- Supervisor checkpoints represent reusable research/implementation aggregations
- Should persist beyond single workflow session for metadata extraction by future workflows
- Checkpoint-utils.sh already defines `.claude/data/checkpoints/` as standard location

**Implementation**:
1. Update `state-persistence.sh:252` checkpoint path from `.claude/tmp/` to `.claude/data/checkpoints/`
2. Update supervisor agents (research-sub-supervisor.md:369, implementation-sub-supervisor.md:453)
3. Test that hierarchical supervision still works after path change

**Impact**: Medium - requires coordinated changes across multiple supervisor agents

### 3. Implement Automatic Workflow State Cleanup (Low Priority)

**Action**: Add scheduled cleanup of old workflow state files

**Options**:
- **Option A**: Cron job to delete workflow files >7 days old
- **Option B**: Workflow completion trap in final bash block (display_brief_summary function)
- **Option C**: Startup cleanup on next /coordinate invocation (delete stale files first)

**Recommendation**: Implement Option B + Option C combination:
- Option B ensures successful workflows clean up immediately
- Option C handles abandoned/failed workflows

**Implementation**:
```bash
# In display_brief_summary() function:
cleanup_workflow_state() {
  rm -f "${STATE_FILE}"
  rm -f "${COORDINATE_STATE_ID_FILE}"
}
trap cleanup_workflow_state EXIT
```

### 4. Document Persistence Semantics (Medium Priority)

**Action**: Add explicit documentation clarifying .claude/tmp/ vs .claude/data/ semantics

**Location**: `.claude/docs/concepts/state-persistence-semantics.md`

**Content**:
- `.claude/tmp/`: Ephemeral subprocess state (deleted after workflow)
- `.claude/data/workflow/`: Workflow session state (retained for debugging, auto-purged after 7 days)
- `.claude/data/checkpoints/`: Persistent supervisor aggregations (retained indefinitely)
- `.claude/data/logs/`: Append-only logs (rotated at 10MB)

**Benefit**: Clear guidance for future development

## References

- `/home/benjamin/.config/.claude/lib/state-persistence.sh:1-341` - State persistence implementation
- `/home/benjamin/.config/.claude/commands/coordinate.md:1-1596` - /coordinate command using state files
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-642` - Subprocess isolation patterns
- `/home/benjamin/.config/.claude/TODO.md:5` - Planned migration to .claude/data/workflow/
- `/home/benjamin/.config/.claude/tmp/` - Current state file location (17 files observed)
- `/home/benjamin/.config/.claude/data/` - Persistent artifact storage (10 subdirectories)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:90` - Checkpoint directory definition
- `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md:36` - State file usage example
- `/home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md:37` - State file usage example

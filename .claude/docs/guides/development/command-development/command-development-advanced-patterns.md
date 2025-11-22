# Command Development Guide - Advanced Patterns

**Part 3 of 5** | [Index](command-development-index.md)

This document covers advanced state management patterns, bash block execution model, and optimization techniques.

---

  "timestamp": "$(date -Iseconds)"
}
EOF
)

save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"
```

```bash
# Later invocation (after interruption) - restore state
CHECKPOINT_FILE=".claude/data/checkpoints/implement_${PROJECT_NAME}_latest.json"

if [ -f "$CHECKPOINT_FILE" ]; then
  echo "Found checkpoint - resuming workflow"

  # Restore state from checkpoint
  PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
  CURRENT_PHASE=$(jq -r '.current_phase' "$CHECKPOINT_FILE")
  COMPLETED_PHASES=$(jq -r '.completed_phases[]' "$CHECKPOINT_FILE" | tr '\n' ' ')
  TESTS_PASSING=$(jq -r '.tests_passing' "$CHECKPOINT_FILE")

  # Calculate next phase to execute
  START_PHASE=$((CURRENT_PHASE + 1))

  echo "Resuming from Phase $START_PHASE"
  echo "Completed phases: $COMPLETED_PHASES"
  echo "Tests passing: $TESTS_PASSING"
else
  echo "No checkpoint found - starting from Phase 1"
  START_PHASE=1
fi
```

**Checkpoint File Structure**:

```
.claude/data/checkpoints/
├── implement_myproject_latest.json         # Current state
├── implement_myproject_001.json            # Historical checkpoint 1
├── implement_myproject_002.json            # Historical checkpoint 2
└── implement_myproject_003.json            # Historical checkpoint 3
```

**Checkpoint JSON Schema**:

```json
{
  "command": "implement",
  "plan_path": "/absolute/path/to/plan.md",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua", "file3.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f"],
  "timestamp": "2025-11-05T15:23:45-05:00",
  "metadata": {
    "plan_complexity": 7.5,
    "total_phases": 5,
    "replan_count": 0
  }
}
```

**Checkpoint Lifecycle**:

1. **Creation**: After each phase completes successfully
2. **Update**: `_latest.json` always contains most recent state
3. **Rotation**: Historical checkpoints saved as `_NNN.json` (configurable retention)
4. **Restoration**: Read `_latest.json` on workflow restart
5. **Cleanup**: Delete checkpoints on successful workflow completion (optional)

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Resumability** | Full state restoration after interruption | 50-100ms I/O overhead per checkpoint |
| **Complexity** | Medium (checkpoint-utils.sh library) | Cleanup logic required |
| **Reliability** | Survives process termination | File I/O can fail (disk full, permissions) |
| **State Capacity** | Any size (JSON serialization) | Synchronization between checkpoint and reality |
| **Audit Trail** | Complete workflow history | Storage overhead (50-200KB per checkpoint) |
| **I/O Operations** | 2 per checkpoint (read + write) | N/A |

**Performance Characteristics**:

- **Checkpoint save**: 30-50ms (JSON serialization + file write)
- **Checkpoint load**: 20-30ms (file read + JSON parsing)
- **Total overhead**: 50-100ms per checkpoint
- **Acceptable for**: Hour-long workflows (0.1% overhead)
- **Not acceptable for**: Sub-minute workflows (10%+ overhead)

**Checkpoint Utilities Library**:

The `.claude/lib/workflow/checkpoint-utils.sh` library provides:

```bash
# Save checkpoint with automatic rotation
save_checkpoint() {
  local checkpoint_name="$1"
  local checkpoint_data="$2"
  local checkpoint_dir=".claude/data/checkpoints"

  mkdir -p "$checkpoint_dir"

  # Save as latest
  echo "$checkpoint_data" > "${checkpoint_dir}/${checkpoint_name}_latest.json"

  # Rotate to historical (optional)
  local count=$(ls "${checkpoint_dir}/${checkpoint_name}_"*.json 2>/dev/null | wc -l)
  cp "${checkpoint_dir}/${checkpoint_name}_latest.json" \
     "${checkpoint_dir}/${checkpoint_name}_$(printf '%03d' $count).json"
}

# Load most recent checkpoint
load_checkpoint() {
  local checkpoint_name="$1"
  local checkpoint_file=".claude/data/checkpoints/${checkpoint_name}_latest.json"

  if [ -f "$checkpoint_file" ]; then
    cat "$checkpoint_file"
    return 0
  else
    return 1
  fi
}

# Clean up checkpoints on successful completion
cleanup_checkpoints() {
  local checkpoint_name="$1"
  local checkpoint_dir=".claude/data/checkpoints"

  rm -f "${checkpoint_dir}/${checkpoint_name}"_*.json
  echo "Checkpoints cleaned up for: $checkpoint_name"
}
```

**Cleanup Considerations**:

**Retention Policy Options**:

1. **Keep Latest Only**: Delete historical checkpoints after each save
2. **Keep N Historical**: Retain last N checkpoints (e.g., N=5)
3. **Keep All Until Completion**: Delete all checkpoints only when workflow succeeds
4. **Keep Indefinitely**: Never delete (for audit trail)

**Recommended Policy** (for `/implement`):

```bash
# Keep latest + 3 historical checkpoints
CHECKPOINT_RETENTION=3

save_checkpoint_with_rotation() {
  local name="$1"
  local data="$2"
  local dir=".claude/data/checkpoints"

  # Save latest
  echo "$data" > "${dir}/${name}_latest.json"

  # Count existing historical checkpoints
  local count=$(ls "${dir}/${name}_"[0-9]*.json 2>/dev/null | wc -l)

  # Save new historical checkpoint
  cp "${dir}/${name}_latest.json" "${dir}/${name}_$(printf '%03d' $((count + 1))).json"

  # Clean old checkpoints if exceeds retention limit
  if [ $count -ge $CHECKPOINT_RETENTION ]; then
    ls -t "${dir}/${name}_"[0-9]*.json | tail -n +$((CHECKPOINT_RETENTION + 1)) | xargs rm -f
  fi
}
```

**Cleanup on Success**:

```bash
# After all phases complete successfully
cleanup_checkpoints "implement_${PROJECT_NAME}"
echo "Implementation complete - checkpoints cleaned up"
```

**Synchronization Validation**:

Critical: Checkpoint must accurately reflect reality.

```bash
# After phase completion
run_tests
TEST_STATUS=$?

if [ $TEST_STATUS -eq 0 ]; then
  TESTS_PASSING=true

  # Create git commit
  git add .
  git commit -m "feat: complete Phase $PHASE_NUMBER"
  COMMIT_HASH=$(git rev-parse HEAD)

  # Save checkpoint AFTER commit succeeds
  save_checkpoint "implement_${PROJECT_NAME}" "$(cat <<EOF
{
  "current_phase": $PHASE_NUMBER,
  "tests_passing": true,
  "git_commits": ["$COMMIT_HASH"]
}
EOF
  )"
else
  echo "ERROR: Tests failed - NOT saving checkpoint"
  exit 1
fi
```

**Example Commands Using This Pattern**:

- `/implement` - Primary example (multi-phase implementation with resumability)
- `/revise --auto-mode` - Iterative plan revision with checkpoints
- Long-running orchestration workflows (>10 minutes)

**Advantages**:

- ✓ **Resumability**: Full workflow restoration after any interruption
- ✓ **Audit Trail**: Complete history of workflow progression
- ✓ **State Capacity**: Unlimited (JSON can hold any data structure)
- ✓ **Flexibility**: Schema can evolve without breaking existing checkpoints

**Disadvantages**:

- ✗ **I/O Overhead**: 50-100ms per checkpoint (significant for fast workflows)
- ✗ **Complexity**: Requires checkpoint library, cleanup logic, rotation policy
- ✗ **Synchronization Risk**: Checkpoint may not reflect actual file system state
- ✗ **Failure Modes**: Disk full, permissions errors, JSON parsing failures

**When NOT to Use**:

- Single-invocation workflows (<10 minutes) - overhead not justified
- Simple commands (<5 phases) - resumability not needed
- Fast workflows (<1 minute) - overhead >10% of execution time

**See Also**:
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Detailed implementation
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint utilities library
- Case Study 2: /implement Success Story (section 6.5)

---

#### 6.2.3 Pattern 3: File-based State

**Core Concept**: Heavy computation results cached to files to avoid re-execution on subsequent invocations.

**When to Use**:
- Computation cost >1 second per invocation
- Results reused across multiple command invocations
- Caching justifies 30ms I/O overhead
- Cache invalidation logic manageable

**Pattern Definition**:

File-based state caches expensive computation results (codebase analysis, dependency graphs, large dataset preprocessing) to files, avoiding re-computation on subsequent command invocations.

**Difference from Pattern 2**:
- Pattern 2 (Checkpoints): Intra-workflow state for resumability
- Pattern 3 (File-based): Inter-invocation caching for performance

**Implementation Example**:

```bash
# Expensive codebase analysis (5+ seconds)
ANALYSIS_CACHE=".claude/cache/codebase_analysis_${PROJECT_HASH}.json"

if [ -f "$ANALYSIS_CACHE" ]; then
  # Check cache freshness (modified in last 24 hours?)
  if [ "$(uname)" = "Darwin" ]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -f%m "$ANALYSIS_CACHE") ))
  else
    CACHE_AGE=$(( $(date +%s) - $(stat -c%Y "$ANALYSIS_CACHE") ))
  fi

  if [ $CACHE_AGE -lt 86400 ]; then
    # Cache is fresh - use it
    ANALYSIS_RESULT=$(cat "$ANALYSIS_CACHE")
    echo "Using cached analysis (age: ${CACHE_AGE}s)"
  else
    # Cache is stale - regenerate
    echo "Cache expired (age: ${CACHE_AGE}s) - regenerating analysis..."
    ANALYSIS_RESULT=$(perform_expensive_analysis)
    echo "$ANALYSIS_RESULT" > "$ANALYSIS_CACHE"
  fi
else
  # No cache - compute and save
  echo "No cache found - running expensive analysis (5-10s)..."
  ANALYSIS_RESULT=$(perform_expensive_analysis)
  echo "$ANALYSIS_RESULT" > "$ANALYSIS_CACHE"
fi

# Use ANALYSIS_RESULT in command logic
echo "Analysis complete: $(echo "$ANALYSIS_RESULT" | jq -r '.summary')"
```

**Cache Invalidation Strategies**:

**1. Time-based Invalidation**:

```bash
# Cache expires after 24 hours
MAX_CACHE_AGE=86400  # seconds

if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || stat -f%m "$CACHE_FILE") ))

  if [ $CACHE_AGE -gt $MAX_CACHE_AGE ]; then
    echo "Cache expired - regenerating"
    rm "$CACHE_FILE"
  fi
fi
```

**2. Content-based Invalidation**:

```bash
# Cache invalidated when input files change
INPUT_FILES=("file1.lua" "file2.lua" "file3.lua")
INPUT_HASH=$(cat "${INPUT_FILES[@]}" | md5sum | cut -d' ' -f1)

CACHE_FILE=".claude/cache/analysis_${INPUT_HASH}.json"

if [ ! -f "$CACHE_FILE" ]; then
  echo "Input files changed - cache invalidated"
  RESULT=$(expensive_analysis "${INPUT_FILES[@]}")
  echo "$RESULT" > "$CACHE_FILE"
fi
```

**3. Manual Invalidation**:

```bash
# User flag to bypass cache
if [ "$NO_CACHE" = "true" ]; then
  echo "Cache bypass requested - running fresh analysis"
  RESULT=$(expensive_analysis)
else
  # Use cache if available
  if [ -f "$CACHE_FILE" ]; then
    RESULT=$(cat "$CACHE_FILE")
  else
    RESULT=$(expensive_analysis)
    echo "$RESULT" > "$CACHE_FILE"
  fi
fi
```

**4. Automatic File Modification Detection**:

```bash
# Invalidate cache if any source file modified since cache created
if [ -f "$CACHE_FILE" ]; then
  # Find newest source file
  NEWEST_SOURCE=$(find . -name "*.lua" -type f -exec stat -f%m {} \; | sort -rn | head -1)
  CACHE_MTIME=$(stat -f%m "$CACHE_FILE")

  if [ $NEWEST_SOURCE -gt $CACHE_MTIME ]; then
    echo "Source files modified - cache invalidated"
    rm "$CACHE_FILE"
  fi
fi
```

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Performance** | Avoid 1s+ re-computation | 30ms I/O overhead per cache access |
| **Complexity** | High (cache invalidation logic) | Staleness detection required |
| **Reliability** | Reduces computation load | Cache/reality synchronization issues |
| **Maintainability** | Cleanup logic required | Multiple failure modes (I/O, staleness) |
| **Storage** | Persistent across invocations | Disk space consumption |
| **I/O Operations** | 1 read per cache hit | Disk full errors possible |

**Performance Characteristics**:

- **Cache save**: 20-30ms (JSON serialization + file write)
- **Cache load**: 10-20ms (file read + JSON parsing)
- **Total overhead**: 30ms per cache operation
- **Break-even point**: Computation must cost >30ms to justify caching
- **Recommended threshold**: >1s computation (30x overhead amortization)

**Cache Directory Structure**:

```
.claude/cache/
├── codebase_analysis_abc123.json          # Analysis for project hash abc123
├── codebase_analysis_def456.json          # Analysis for project hash def456
├── dependency_graph_abc123.json           # Dependency graph cache
└── metadata.json                          # Cache metadata (creation times, sizes)
```

**Cleanup Considerations**:

**Cache Size Management**:

```bash
# Limit cache directory size to 100MB
MAX_CACHE_SIZE=$((100 * 1024 * 1024))  # bytes

cleanup_old_caches() {
  local cache_dir=".claude/cache"
  local current_size=$(du -sb "$cache_dir" 2>/dev/null | cut -f1)

  if [ $current_size -gt $MAX_CACHE_SIZE ]; then
    echo "Cache size ($current_size bytes) exceeds limit ($MAX_CACHE_SIZE bytes)"
    echo "Cleaning oldest cache files..."

    # Delete oldest files until under limit
    ls -t "$cache_dir"/*.json | tail -n +10 | xargs rm -f
  fi
}
```

**Automatic Cleanup on Command Exit**:

```bash
# Optional: Clean up caches older than 7 days on command exit
trap 'cleanup_stale_caches' EXIT

cleanup_stale_caches() {
  find .claude/cache -name "*.json" -mtime +7 -delete
  echo "Cleaned up caches older than 7 days"
}
```

**Example Use Cases**:

- **Codebase Complexity Analysis**: Parse all source files, calculate metrics (5-10s)
- **Dependency Graph Generation**: Traverse all imports/requires (3-5s)
- **Documentation Parsing**: Extract API signatures from all files (2-4s)
- **Cross-Repository Reference Resolution**: Query multiple Git repositories (10-30s)

**Example Commands** (hypothetical):

```bash
# /analyze-complexity command (hypothetical)
# Caches complexity metrics to avoid 5s re-computation
CACHE_FILE=".claude/cache/complexity_$(git rev-parse HEAD).json"

if [ -f "$CACHE_FILE" ]; then
  METRICS=$(cat "$CACHE_FILE")
else
  METRICS=$(analyze_complexity_for_all_files)  # 5-10s
  echo "$METRICS" > "$CACHE_FILE"
fi
```

**Advantages**:

- ✓ **Performance**: Avoid expensive re-computation (1s+ → 30ms)
- ✓ **Persistent**: Cache survives across command invocations
- ✓ **Scalable**: Handle large datasets via incremental caching

**Disadvantages**:

- ✗ **Complexity**: Cache invalidation logic required (not trivial)
- ✗ **Staleness Risk**: Cache may not reflect current state (synchronization issues)
- ✗ **Storage Overhead**: Disk space consumed by cache files (50-500MB)
- ✗ **Failure Modes**: Disk full, permissions errors, stale cache bugs

**When NOT to Use**:

- Computation cost <100ms (overhead >30% of computation time)
- Results change frequently (cache hit rate <50%)
- Complex invalidation logic (maintenance burden > time savings)
- Single-invocation workflows (cache not reused)

**Anti-Pattern Warning**:

Do NOT use file-based state for fast variables (<1ms calculation). This is **premature optimization**:

```bash
# ANTI-PATTERN: File-based state for fast variable
CACHE_FILE=".claude/cache/workflow_scope.txt"
if [ -f "$CACHE_FILE" ]; then
  WORKFLOW_SCOPE=$(cat "$CACHE_FILE")  # 30ms I/O
else
  WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms calculation
  echo "$WORKFLOW_SCOPE" > "$CACHE_FILE"
fi
# Result: 30x SLOWER than recalculation!

# CORRECT: Stateless recalculation (Pattern 1)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms, no I/O
```

**See Also**:
- Anti-Pattern 2: Premature Optimization (section 6.4)
- Pattern 1: Stateless Recalculation (for <100ms operations)

---

#### 6.2.4 Pattern 4: Single Large Block

**Core Concept**: All command logic in one bash block, avoiding subprocess boundaries entirely.

**When to Use**:
- Simple utility commands (<300 lines total)
- No subagent invocation needed
- Simple file creation or template expansion operations
- 0ms overhead required

**Pattern Definition**:

Single large block avoids state management by keeping all logic within a single bash subprocess. Variables persist naturally within the process, eliminating recalculation overhead.

**Key Limitation**: Cannot invoke Task tool for subagent delegation (requires multiple bash blocks).

**Implementation Example**:

```bash
#!/usr/bin/env bash
# Simple utility command - all logic in single block

set -e

# Standard 13: CLAUDE_PROJECT_DIR detection
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)

# Parse arguments
FEATURE_NAME="$1"

if [ -z "$FEATURE_NAME" ]; then
  echo "ERROR: Feature name required"
  echo "Usage: /create-spec <feature-name>"
  exit 1
fi

# Variable calculations (persist throughout block)
SANITIZED_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
TIMESTAMP=$(date -Iseconds)
SPEC_NUMBER=$(find .claude/specs -maxdepth 1 -type d -name "[0-9]*" | wc -l)
SPEC_NUMBER=$((SPEC_NUMBER + 1))

# Create topic root directory only (lazy creation pattern)
# Subdirectories are created by agents via ensure_artifact_directory() when files are written
TARGET_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${SPEC_NUMBER}_${SANITIZED_NAME}"
mkdir -p "$TARGET_DIR"

# Create README.md
cat > "${TARGET_DIR}/README.md" <<EOF
# ${FEATURE_NAME}

**Spec Number**: ${SPEC_NUMBER}
**Created**: ${TIMESTAMP}

## Overview

[Feature description here]

## Artifacts

- \`plans/\` - Implementation plans
- \`reports/\` - Research reports
- \`summaries/\` - Implementation summaries
- \`debug/\` - Debug reports

## Status

- [ ] Research
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
EOF

# Verify creation
if [ ! -f "${TARGET_DIR}/README.md" ]; then
  echo "ERROR: File creation failed"
  exit 1
fi

# Output result
echo "✓ Created spec directory:"
echo "  Path: ${TARGET_DIR}"
echo "  Number: ${SPEC_NUMBER}"
echo "  Feature: ${FEATURE_NAME}"
echo "  Timestamp: ${TIMESTAMP}"
echo ""
echo "Next steps:"
echo "  1. Edit ${TARGET_DIR}/README.md with feature description"
echo "  2. Run /research <topic> to create initial research report"
echo "  3. Run /plan <description> to create implementation plan"
```

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Performance** | 0ms overhead (no recalculation) | Cannot invoke subagents (Task tool) |
| **Complexity** | Very Low (straightforward script) | Limited to <300 lines (transformation risk) |
| **Reliability** | No synchronization issues | All logic in single scope |
| **Maintainability** | Single location for all logic | Cannot leverage agent delegation |
| **State Management** | Not needed (variables persist) | N/A |
| **Debugging** | Simple (linear execution) | Large blocks harder to debug |

**Performance Characteristics**:

- **Overhead**: 0ms (no recalculation, no I/O)
- **Execution time**: Linear with script complexity
- **Memory**: Minimal (variables in single process)

**Line Count Threshold**:

Bash blocks >400 lines face increased risk of code transformation bugs. Recommended limits:

- **Safe**: <300 lines
- **Caution**: 300-400 lines
- **High Risk**: >400 lines (consider splitting)

**Limitations**:

**Cannot Invoke Task Tool**:

The Task tool requires separate bash blocks for agent invocations. Single-block commands cannot:

```bash
# IMPOSSIBLE in single-block command
# Task tool invocation requires separate bash block
USE the Task tool with subagent_type=research-specialist...
# This syntax is interpreted as instruction to Claude, not bash code
```

**Multi-block Required for Subagents**:

```bash
# Block 1: Invoke subagent
USE the Task tool with subagent_type=research-specialist
prompt="Research authentication patterns in the codebase"

# Block 2: Process subagent results (separate subprocess)
echo "Subagent completed research"
# Read subagent output and continue workflow
```

**No Phase Boundaries**:

Single-block commands cannot checkpoint progress. If command fails partway through, must restart from beginning.

**Limited Parallelism**:

Cannot launch parallel operations (all execution sequential).

**Use Cases**:

**Perfect For**:
- File creation utilities
- Template expansion commands
- Directory structure initialization
- Configuration file updates
- Simple transformations (<300 lines)

**Not Suitable For**:
- Commands requiring AI reasoning (need subagents)
- Multi-phase workflows (need checkpoints)
- Long-running operations (>5 minutes)
- Complex orchestration (need agent delegation)

**Example Commands** (hypothetical):

- `/create-spec` - Create spec directory structure
- `/init-command` - Initialize new slash command template
- `/update-config` - Update configuration file
- Simple git operations (add, commit, push)

**Advantages**:

- ✓ **Simplicity**: No state management needed
- ✓ **Performance**: 0ms overhead
- ✓ **Reliability**: No synchronization issues
- ✓ **Debugging**: Linear execution, easy to trace

**Disadvantages**:

- ✗ **Cannot Use Task Tool**: No subagent delegation
- ✗ **Line Count Limit**: >400 lines risks transformation bugs
- ✗ **No Resumability**: Must restart from beginning on failure
- ✗ **Limited Complexity**: Cannot handle multi-phase workflows

**When NOT to Use**:

- Command requires subagent invocation (use Pattern 1)
- Command >300 lines (split into multi-block)
- Need resumability (use Pattern 2)
- Complex orchestration workflows (use Pattern 1)

**See Also**:
- Pattern 1: Stateless Recalculation (for multi-block commands)
- Anti-Pattern 3: Over-Consolidation (section 6.4)

---

### 6.3 Decision Framework

#### 6.3.1 Decision Criteria

Use this table to evaluate which pattern fits your command requirements:

| Criteria | Pattern 1: Stateless | Pattern 2: Checkpoints | Pattern 3: File-based | Pattern 4: Single Block |
|----------|---------------------|------------------------|----------------------|------------------------|
| **Variable Count** | <10 | Any | Any | <10 |
| **Recalculation Cost** | <100ms | Any | >1s | N/A |
| **Command Complexity** | Any | >5 phases | Any | <300 lines |
| **Subagent Invocations** | Yes (required) | Yes | Yes | No (limitation) |
| **State Persistence** | Single invocation only | Across interruptions | Across invocations | Single invocation only |
| **Resumability** | No | Yes (checkpoint restore) | No | No |
| **Overhead** | <1ms per variable | 50-100ms per checkpoint | 30ms I/O per cache | 0ms |
| **Complexity** | Low | Medium | High | Very Low |
| **Cleanup Required** | No | Yes (checkpoint rotation) | Yes (cache invalidation) | No |
| **I/O Operations** | None | Read/write JSON | Read/write cache files | None |
| **Failure Modes** | Synchronization drift | Checkpoint corruption | Cache staleness | None (simplicity) |
| **Best For** | Orchestration commands | Long-running workflows | Expensive computation | Simple utilities |

#### 6.3.2 Decision Tree

Use this decision tree to quickly select the appropriate pattern:

```
                    START: Choose State Management Pattern
                                    |
                                    v
                    Does computation take >1 second?
                                    |
                    +---------------+---------------+
                    |                               |
                   YES                             NO
                    |                               |
                    v                               v
            Pattern 3:                 Does workflow have >5 phases
           File-based State               or need resumability?
         (Cache expensive                          |
          computation)              +---------------+---------------+
                                    |                               |
                                   YES                             NO
                                    |                               |
                                    v                               v
                            Pattern 2:                 Does command invoke
                          Checkpoint Files                 subagents?
                       (Multi-phase resumable)                      |
                                                    +---------------+---------------+
                                                    |                               |
                                                   YES                             NO
                                                    |                               |
                                                    v                               v
                                            Pattern 1:                    Is command <300 lines
                                        Stateless Recalc                     total logic?
                                     (Multi-block with                               |
                                      recalculation)                +---------------+---------------+
                                                                    |                               |
                                                                   YES                             NO
                                                                    |                               |
                                                                    v                               v
                                                            Pattern 4:                      Pattern 1:
                                                         Single Large Block              Stateless Recalc
                                                          (Simple utility)            (Split into blocks)
```

**ASCII Box Diagram**:

```
┌─────────────────────────────────────────────────────────────┐
│           State Management Pattern Decision Tree            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Q1: Computation cost >1s?                                  │
│    ├─ YES → Pattern 3 (File-based State)                   │
│    └─ NO → Continue to Q2                                   │
│                                                             │
│  Q2: Multi-phase workflow (>5 phases) or resumable?         │
│    ├─ YES → Pattern 2 (Checkpoint Files)                   │
│    └─ NO → Continue to Q3                                   │
│                                                             │
│  Q3: Invokes subagents (Task tool)?                         │
│    ├─ YES → Pattern 1 (Stateless Recalculation)            │
│    └─ NO → Continue to Q4                                   │
│                                                             │
│  Q4: Command <300 lines total?                              │
│    ├─ YES → Pattern 4 (Single Large Block)                 │
│    └─ NO → Pattern 1 (Stateless Recalc, split blocks)      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Quick Pattern Selection Reference

**Choose Pattern 1 (Stateless Recalculation)** when:
- Command invokes subagents via Task tool
- <10 variables need persistence
- Recalculation cost <100ms
- Single invocation (no resumability needed)
- Example: `/coordinate`, `/orchestrate`

**Choose Pattern 2 (Checkpoint Files)** when:
- Multi-phase workflow (>5 phases)
- Resumability required (interruption tolerance)
- Execution time >10 minutes
- State audit trail needed
- Example: `/implement`, long-running orchestration

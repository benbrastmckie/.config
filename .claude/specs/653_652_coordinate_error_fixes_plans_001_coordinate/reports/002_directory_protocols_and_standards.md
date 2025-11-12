# Directory Protocols and Standards for State File Organization

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Directory protocols and standards for state file organization
- **Report Type**: codebase analysis

## Executive Summary

The .claude/ system uses a two-tier directory structure for state management: `.claude/data/` for persistent workflow artifacts (checkpoints, logs, metrics) that span multiple invocations, and `.claude/tmp/` for ephemeral within-workflow state files that are cleaned up on workflow completion. State persistence libraries use `.claude/tmp/` exclusively, following the GitHub Actions pattern for temporary state that doesn't require retention beyond the current command execution.

## Findings

### 1. Existing State File Organization Standards

#### `.claude/data/` Directory - Persistent Artifacts

**Purpose**: Long-term storage for workflow data that persists across command invocations.

**Structure** (from `.claude/data/README.md:9-21`):
```
data/
├── checkpoints/         Workflow state for resumption
├── logs/                Runtime logs and debug output
├── metrics/             Command performance tracking
└── registry/            Artifact metadata tracking
```

**Characteristics**:
- **Gitignored**: All files gitignored to prevent sensitive/ephemeral data in repository
- **Retention policies**: Checkpoints (7 days), logs (manual rotation), metrics (monthly files), registry (manual cleanup)
- **Use cases**: Cross-invocation persistence, audit trails, performance analysis
- **Created by**: `/implement` (checkpoints), hooks (logs, metrics), workflow orchestrators (registry)

**Key locations**:
- `.claude/data/checkpoints/` - Implementation phase resumption (JSON format)
- `.claude/data/logs/` - Hook execution traces, TTS logs, adaptive planning logs
- `.claude/data/metrics/` - Command performance tracking (JSONL format)
- `.claude/data/registry/` - Artifact metadata for workflow coordination

#### `.claude/tmp/` Directory - Ephemeral State

**Purpose**: Temporary state files for current workflow execution only.

**Structure** (observed from actual directory listing):
```
.claude/tmp/
├── workflow_coordinate_*.sh       # State persistence files (GitHub Actions pattern)
├── workflow_cleanup_*.sh          # Cleanup workflow state
├── supervisor_metadata.json       # JSON checkpoints (transient)
└── benchmarks.jsonl              # Benchmark logs (transient)
```

**Characteristics**:
- **Lifecycle**: Created during workflow, deleted on completion (EXIT trap cleanup)
- **Format**: Bash export statements (`.sh`) and JSON (`.json`, `.jsonl`)
- **Performance**: 67% improvement for expensive operations (6ms → 2ms for CLAUDE_PROJECT_DIR)
- **Pattern**: GitHub Actions-style (`$GITHUB_OUTPUT`, `$GITHUB_STATE`)
- **Library**: Managed by `.claude/lib/state-persistence.sh` (lines 126, 129, 250, 252, 335, 337)

**Key observations**:
- 100+ workflow state files observed in production `.claude/tmp/` directory
- Files use PID-based naming: `workflow_coordinate_1762798269.sh`
- Cleanup handled by EXIT traps, but some orphaned files may remain

### 2. State Persistence Library Standards

**Location**: `.claude/lib/state-persistence.sh` (341 lines)

**Core API** (lines 115-340):
- `init_workflow_state(workflow_id)` - Creates `.claude/tmp/workflow_${workflow_id}.sh`
- `load_workflow_state(workflow_id)` - Loads state file with graceful degradation
- `append_workflow_state(key, value)` - Appends `export KEY="value"` to state file
- `save_json_checkpoint(name, data)` - Creates `.claude/tmp/${name}.json` atomically
- `load_json_checkpoint(name)` - Loads JSON checkpoint, returns `{}` if missing
- `append_jsonl_log(log_name, entry)` - Appends to `.claude/tmp/${log_name}.jsonl`

**State File Format** (line 131-135):
```bash
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="coordinate_12345"
export STATE_FILE="/path/to/project/.claude/tmp/workflow_12345.sh"
export RESEARCH_COMPLETE="true"
export REPORT_PATHS_COUNT="4"
```

**Decision Criteria for File-Based State** (lines 61-68):
1. State accumulates across subprocess boundaries
2. Context reduction requires metadata aggregation (95% reduction)
3. Success criteria validation needs objective evidence
4. Resumability is valuable (multi-hour operations)
5. State is non-deterministic (external API results)
6. Recalculation is expensive (>30ms)
7. Phase dependencies require prior phase outputs

**Usage Pattern**:
- Priority 0 (Performance-Critical): Supervisor metadata, benchmark datasets, parallel execution tracking
- Priority 1 (Enhancement): Migration progress, performance benchmarks, POC metrics
- 70% of analyzed state items use file-based persistence (7 of 10)
- 30% use stateless recalculation (fast, deterministic operations <1ms)

### 3. Directory Protocols from CLAUDE.md

**Topic-Based Structure** (CLAUDE.md lines 44-58, directory-protocols.md lines 36-51):
```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED to git)
    ├── scripts/        # Investigation scripts (gitignored, temporary)
    ├── outputs/        # Test outputs (gitignored, temporary)
    ├── artifacts/      # Operation artifacts (gitignored)
    └── backups/        # Backups (gitignored)
```

**Key Distinction**:
- `specs/{topic}/` directories are for **permanent or semi-permanent artifacts** related to features
- `.claude/data/` is for **cross-invocation persistent runtime data** (checkpoints, logs, metrics)
- `.claude/tmp/` is for **single-invocation ephemeral state** (workflow state files, transient checkpoints)

**Lazy Directory Creation** (directory-protocols.md lines 68-89):
- Subdirectories created **on-demand** when files are written
- 80% reduction in mkdir calls during location detection
- Use `ensure_artifact_directory()` before writing files
- Eliminates 400-500 empty directories across codebase

### 4. Coordinate State Management Architecture

**Pattern**: Selective State Persistence (coordinate-state-management.md lines 534-676)

**Current Implementation**:
- Workflow state: `.claude/tmp/workflow_coordinate_$$.sh` (bash export format)
- JSON checkpoints: `.claude/tmp/supervisor_metadata.json` (atomic writes)
- Benchmark logs: `.claude/tmp/benchmarks.jsonl` (append-only)

**Performance Characteristics** (lines 610-620):
- `init_workflow_state()`: ~6ms (includes git rev-parse)
- `load_workflow_state()`: ~2ms (file read)
- **Improvement**: 67% faster (6ms → 2ms)
- `save_json_checkpoint()`: 5-10ms (atomic write)
- `load_json_checkpoint()`: 2-5ms (cat + jq validation)

**Comparison with `.claude/data/checkpoints/`**:
- **`.claude/tmp/`**: Within-workflow state (seconds to minutes), cleaned up on completion
- **`.claude/data/checkpoints/`**: Cross-invocation resumption (hours to days), 7-day retention

### 5. Verification Checkpoint Pattern Standards

**Critical Pattern** (coordinate-state-management.md lines 722-824):

State file verification must account for **export format**:
```bash
# CORRECT: Include export prefix
if grep -q "^export VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ Variable verified"
fi

# INCORRECT: Missing export prefix (false negatives)
if grep -q "^VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ Variable verified"  # Will never execute!
fi
```

**Historical Bug** (Spec 644, lines 774-784):
- Grep patterns searched for `^REPORT_PATHS_COUNT=`
- Actual format: `export REPORT_PATHS_COUNT="4"`
- Result: Verification failed despite correct state file content
- Fix: Added `export ` prefix to all grep patterns

**Test Coverage**: `.claude/tests/test_coordinate_verification.sh` (3 unit tests)

### 6. No specs/{topic}/data/ or specs/{topic}/state/ Patterns Found

**Search Results**:
- Grepped `.claude/docs/` for `specs/.*/(data|state)` patterns
- Found 6 references, all pointing to `.claude/data/` (not specs directories)
- No existing patterns for topic-specific state directories
- No standards document describing `specs/{NNN_topic}/data/` or similar

**Conclusion**: State management for /coordinate should follow existing `.claude/tmp/` pattern, not create new specs-based state directories.

## Recommendations

### 1. Use `.claude/tmp/` for Coordinate State Files

**Rationale**:
- Established pattern with comprehensive library support (state-persistence.sh)
- Performance-optimized (67% improvement for expensive operations)
- Consistent with GitHub Actions pattern
- Automatic cleanup via EXIT traps
- No new directory standards needed

**Implementation**:
```bash
# Initialize state in Block 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Load state in subsequent blocks
load_workflow_state "coordinate_$$"
```

**File locations**:
- Workflow state: `.claude/tmp/workflow_coordinate_$$.sh`
- Research metadata: `.claude/tmp/research_supervisor_metadata.json`
- Implementation tracking: `.claude/tmp/implementation_supervisor_state.json`
- Benchmark logs: `.claude/tmp/coordinate_benchmarks.jsonl`

### 2. Do NOT Create specs/{topic}/data/ Directories

**Rationale**:
- No existing standards or patterns for topic-specific state
- Would violate directory protocols (specs/ is for plans/reports/summaries/debug)
- State persistence belongs in `.claude/tmp/` (ephemeral) or `.claude/data/` (persistent)
- Topic directories should only contain human-readable artifacts

**Anti-pattern to avoid**:
```
specs/653_coordinate_error_fixes/
├── data/                    # ✗ Don't create this
│   └── state/
│       └── coordinate.sh
```

### 3. Follow Verification Checkpoint Pattern

**Always include export prefix** in grep patterns:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh:216)
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  echo "✓ REPORT_PATHS_COUNT verified"
fi
```

**Add clarifying comments** documenting expected format:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
```

**Test verification logic** to catch false negatives/positives (reference: test_coordinate_verification.sh)

### 4. Use Selective State Persistence Decision Criteria

**File-based state justified when one or more** of these apply:
1. State accumulates across subprocess boundaries (research findings across 4 subagent invocations)
2. Context reduction requires metadata aggregation (95% reduction via supervisor metadata)
3. Recalculation is expensive (>30ms)
4. State is non-deterministic (external API results, user input)
5. Phase dependencies require prior phase outputs

**Stateless recalculation preferred when**:
- Recalculation is fast (<1ms)
- State is deterministic (workflow scope detection)
- No cross-subprocess accumulation needed

### 5. Document State File Locations in Error Messages

**Improve debuggability** by including state file paths in error messages:
```bash
if ! grep -q "^export VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "ERROR: VARIABLE_NAME not found in state file: $STATE_FILE" >&2
  echo "Expected format: export VARIABLE_NAME=\"value\"" >&2
  echo "Actual state file contents:" >&2
  cat "$STATE_FILE" >&2
  exit 1
fi
```

## References

**Documentation**:
- `/home/benjamin/.config/CLAUDE.md` (lines 44-58) - Directory protocols section
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (1,045 lines) - Complete directory standards
- `/home/benjamin/.config/.claude/data/README.md` (114 lines) - Data directory structure
- `/home/benjamin/.config/.claude/data/checkpoints/README.md` (222 lines) - Checkpoint format and lifecycle
- `/home/benjamin/.config/.claude/data/logs/README.md` (424 lines) - Logging standards

**Libraries**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 1-341) - State persistence API
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (lines 744-745) - Coordinate state file references

**Architecture Documentation**:
- `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (lines 1-1485) - Complete state management architecture
- Verification checkpoint pattern (lines 722-824)
- Selective state persistence (lines 534-676)
- Decision criteria (lines 554-576)

**Test Files**:
- `.claude/tests/test_state_persistence.sh` (18 tests, 100% pass rate)
- `.claude/tests/test_coordinate_verification.sh` (3 tests, regression prevention for Spec 644)

**Related Specifications**:
- Spec 600: State persistence library implementation
- Spec 644: Verification checkpoint pattern bug fix
- Spec 597-598: Stateless recalculation pattern validation

# Three-Tier Agent Pattern Guide

## Overview

The three-tier agent pattern extends the hierarchical agent architecture to provide parallel orchestration, context efficiency, and clear separation of concerns. This pattern consists of:

1. **Orchestrator Layer** (slash commands): User-facing entry points with workflow state management
2. **Coordinator Layer** (coordinator agents): Supervisor-based parallel orchestration with metadata aggregation
3. **Specialist Layer** (specialist agents): Deep domain expertise with comprehensive artifact generation

This guide focuses on the testing, debug, and repair domains. For research patterns, see [Research Invocation Standards](../reference/standards/research-invocation-standards.md).

## When to Use Each Pattern

### Decision Matrix

| Scenario | Complexity | Parallel Benefit | Pattern | Example |
|----------|-----------|------------------|---------|---------|
| Simple, single task | 1 | None | 1-tier (direct) | Single test file execution |
| Sequential multi-step | 2 | None | 2-tier (orchestrator → specialist) | Linear debug investigation |
| Parallel independent tasks | 3 | 40-60% time savings | 3-tier (orchestrator → coordinator → specialist) | Multi-module testing |
| Complex multi-domain | 4 | 50-70% time savings | 3-tier with sub-supervisors | Full system validation |

### Pattern Selection Flowchart

```
┌─────────────────────────────────────────┐
│ Does task require parallel execution?   │
└───────────┬─────────────────────────────┘
            │
            ├─── No ──> Can a single specialist complete it?
            │                │
            │                ├─── Yes ──> 1-tier (direct)
            │                │
            │                └─── No ──> 2-tier (orchestrator → specialist)
            │
            └─── Yes ──> 3-tier (orchestrator → coordinator → specialist)
```

## Three-Tier Architecture

### Layer Responsibilities

```
┌─────────────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR (Slash Command)                                        │
│ • User-facing entry point                                           │
│ • Argument parsing and validation                                   │
│ • Workflow state machine management                                 │
│ • Hard barrier enforcement (pre-calculate paths)                    │
│ • Console output and progress reporting                             │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ Passes: paths, topic, context
                             │ Receives: metadata (110 tokens vs 2,500)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│ COORDINATOR (Coordinator Agent)                                     │
│ • Parallel specialist invocation via Task tool                      │
│ • Dependency analysis and wave orchestration                        │
│ • Artifact validation (hard barrier - fail-fast)                    │
│ • Metadata extraction and aggregation                               │
│ • Progress monitoring and failure isolation                         │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ Invokes: parallel Task calls
                             │ Receives: specialist artifacts
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│ SPECIALIST (Specialist Agent)                                       │
│ • Deep domain expertise                                             │
│ • Comprehensive artifact generation                                 │
│ • Structured error return protocol                                  │
│ • Focus on single, well-defined task                                │
└─────────────────────────────────────────────────────────────────────┘
```

### Context Efficiency

The three-tier pattern achieves 95% context reduction through metadata-only passing:

**Without Coordinator** (2-tier):
- 4 specialist reports x 2,500 tokens each = 10,000 tokens to orchestrator

**With Coordinator** (3-tier):
- 4 specialist reports x 2,500 tokens → coordinator
- Coordinator extracts 110 tokens per report = 440 tokens to orchestrator
- **Reduction**: 95.6%

### Time Savings Through Parallelization

**Sequential Execution** (2-tier):
- Phase 1 (3 hrs) → Phase 2 (3 hrs) → Phase 3 (3 hrs) = 9 hours

**Parallel Execution** (3-tier with Wave 2 parallel):
- Wave 1: Phase 1 (3 hrs)
- Wave 2: Phase 2 + Phase 3 (3 hrs parallel)
- Total: 6 hours
- **Savings**: 33%

With more parallel phases, savings increase to 40-60%.

## Hard Barrier Pattern

The hard barrier pattern enforces mandatory subagent delegation by validating artifacts exist at pre-calculated paths.

### Pattern Components

1. **Path Pre-Calculation**: Calculate artifact paths BEFORE invoking subagent
2. **Contract-Based Invocation**: Pass paths as literal values in Task prompt
3. **Artifact Validation**: Verify files exist at paths AFTER subagent returns
4. **Fail-Fast**: Terminate workflow if validation fails

### Implementation Example

```bash
# STEP 1: Pre-calculate paths (before Task invocation)
REPORT_DIR="${TOPIC_PATH}/reports"
mkdir -p "$REPORT_DIR"
REPORT_PATH="${REPORT_DIR}/001-test-results.md"

# STEP 2: Invoke coordinator with literal path
Task {
  prompt: |
    REPORT_PATH: ${REPORT_PATH}  # Literal value, not variable
    Create report at this exact path.
}

# STEP 3: Validate artifact exists (after Task returns)
if [ ! -f "$REPORT_PATH" ]; then
  echo "HARD BARRIER FAILED: Report not found at $REPORT_PATH" >&2
  exit 1
fi
```

### Why Hard Barriers Matter

Without hard barriers, the primary agent can bypass subagent delegation:
- No enforcement that subagent actually ran
- No verification that artifacts were created
- Context pollution from inline implementation

With hard barriers:
- Subagent invocation is mandatory (validation will fail otherwise)
- Artifacts are guaranteed to exist
- Clear separation of concerns enforced

## Metadata-Only Passing

Coordinators extract and pass only metadata between layers, dramatically reducing context usage.

### Metadata Format

```yaml
Report Metadata:
  - path: /absolute/path/to/artifact.md
  - title: Artifact Title
  - key_counts:
      findings: 12
      recommendations: 5
      errors: 0
  - status: [COMPLETE]
  - brief_summary: "One-line summary (max 100 chars)"
```

### Metadata Extraction Example

```bash
extract_metadata() {
  local report_path="$1"

  local title=$(grep -m 1 "^# " "$report_path" | sed 's/^# //')
  local findings=$(grep -c "^### Finding" "$report_path" 2>/dev/null || echo 0)
  local recommendations=$(grep -c "^[0-9]+\." "$report_path" 2>/dev/null || echo 0)

  echo "path: $report_path"
  echo "title: $title"
  echo "findings_count: $findings"
  echo "recommendations_count: $recommendations"
}
```

## Error Return Protocol

Specialists and coordinators use structured error signals for consistent error handling.

### Error Signal Format

```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Human-readable description",
  "details": {"key": "value"}
}

TASK_ERROR: error_type - Brief message
```

### Error Types

| Type | Description | Example |
|------|-------------|---------|
| `state_error` | Workflow state persistence issues | State file not found |
| `validation_error` | Input validation failures | Missing required parameter |
| `agent_error` | Subagent execution failures | Specialist returned error |
| `parse_error` | Output parsing failures | Invalid JSON in response |
| `file_error` | File system operations failures | Cannot create directory |
| `timeout_error` | Operation timeout errors | Task exceeded time limit |
| `execution_error` | General execution failures | Command returned non-zero |
| `dependency_error` | Missing or invalid dependencies | Required library not found |

## Domain-Specific Patterns

### Testing Domain

**Three-Tier Structure**:
- `/test` command (orchestrator)
- `testing-coordinator` (coordinator) - Parallel test-specialist invocation
- `test-specialist` (specialist) - Individual test file/module execution

**Coordinator Responsibilities**:
- Parse test configuration for parallel groups
- Invoke test-specialist for each group in parallel
- Aggregate pass/fail counts and coverage metrics
- Return summary metadata to orchestrator

**Expected Benefits**:
- 40-50% time savings for multi-module test suites
- Parallel test group execution
- Isolated failure reporting per module

### Debug Domain

**Three-Tier Structure**:
- `/debug` command (orchestrator)
- `debug-coordinator` (coordinator) - Parallel investigation vectors
- `debug-specialist` (specialist) - Individual investigation path

**Coordinator Responsibilities**:
- Decompose issue into investigation vectors
- Invoke debug-specialist for each vector in parallel
- Aggregate findings and root cause candidates
- Return ranked hypothesis list to orchestrator

**Expected Benefits**:
- 50-60% time savings for multi-vector investigations
- Parallel root cause exploration
- Comprehensive hypothesis coverage

### Repair Domain

**Three-Tier Structure**:
- `/repair` command (orchestrator)
- `repair-coordinator` (coordinator) - Parallel error dimension analysis
- `repair-specialist` (specialist) - Individual error category analysis

**Coordinator Responsibilities**:
- Categorize errors by dimension (type, command, severity)
- Invoke repair-specialist for each dimension in parallel
- Aggregate repair recommendations
- Return prioritized fix plan to orchestrator

**Expected Benefits**:
- 40-50% time savings for multi-category error analysis
- Parallel dimension exploration
- Holistic repair recommendations

## Migration Guide: Two-Tier to Three-Tier

### Step 1: Identify Parallelization Opportunities

Analyze your current two-tier workflow:
- Are there independent tasks that could run in parallel?
- Do specialists produce large outputs (>1,000 tokens)?
- Would time savings of 40-60% justify the complexity?

If yes to any, consider migration.

### Step 2: Create Coordinator Agent

Use the [coordinator template](../../agents/templates/coordinator-template.md) as a starting point:

1. Define input contract (paths, topics, context)
2. Implement parallel Task invocation
3. Add artifact validation (hard barrier)
4. Implement metadata extraction
5. Define return signal format

### Step 3: Update Orchestrator Command

Modify command to invoke coordinator instead of specialists directly:

**Before (2-tier)**:
```markdown
Task {
  description: "Run tests"
  prompt: "Read test-specialist.md and execute tests..."
}
```

**After (3-tier)**:
```markdown
Task {
  description: "Coordinate test execution"
  prompt: "Read testing-coordinator.md and orchestrate parallel testing..."
}
```

### Step 4: Add Hard Barrier Validation

Add verification block after coordinator returns:

```bash
# Verify coordinator created required artifacts
if [ ! -f "$SUMMARY_PATH" ]; then
  echo "HARD BARRIER FAILED: Summary not created" >&2
  exit 1
fi
```

### Step 5: Update Metadata Passing

Change downstream consumers to receive metadata instead of full content:

**Before**: Pass full test results
**After**: Pass summary path + counts + status

### Step 6: Test Both Paths

Verify both scenarios work:
1. Parallel execution (standard path)
2. Fallback to sequential (if parallel fails)

## Implementation Checklist

When implementing a new three-tier workflow:

- [ ] **Orchestrator Layer**
  - [ ] Argument parsing and validation
  - [ ] Path pre-calculation (hard barrier pattern)
  - [ ] Workflow state initialization
  - [ ] Coordinator invocation via Task tool
  - [ ] Hard barrier validation after coordinator returns
  - [ ] Console summary output

- [ ] **Coordinator Layer**
  - [ ] Input contract parsing (paths, topics, context)
  - [ ] Dependency analysis (if applicable)
  - [ ] Parallel specialist invocation
  - [ ] Artifact validation (fail-fast on missing)
  - [ ] Metadata extraction from each artifact
  - [ ] Aggregated metadata return signal

- [ ] **Specialist Layer**
  - [ ] Input contract verification
  - [ ] Domain-specific artifact generation
  - [ ] Structured error return on failure
  - [ ] Completion signal with path confirmation

## Related Documentation

- [Hierarchical Agent Architecture Overview](hierarchical-agents-overview.md)
- [Hierarchical Agent Examples](hierarchical-agents-examples.md) - Including Example 7: Research Coordinator
- [Research Invocation Standards](../reference/standards/research-invocation-standards.md) - Research-specific patterns
- [Coordinator Template](../../agents/templates/coordinator-template.md) - Reusable coordinator template
- [Hard Barrier Pattern](patterns/hard-barrier-subagent-delegation.md)
- [Error Handling Pattern](patterns/error-handling.md)
- [Command Authoring Standards](../reference/standards/command-authoring.md)

## Changelog

- **2025-12-08**: Initial three-tier pattern guide created (Spec 019 Phase 1)

# Command Development Guide - Examples & Case Studies

**Part 4 of 5** | [Index](command-development-index.md)

This document covers practical examples, case studies, and common implementation patterns.

---


**Choose Pattern 3 (File-based State)** when:
- Computation cost >1 second
- Results reused across invocations
- Caching justifies 30ms I/O overhead
- Cache invalidation logic manageable
- Example: Codebase analysis, dependency graphs

**Choose Pattern 4 (Single Large Block)** when:
- Command <300 lines total
- No subagent invocation needed
- Simple utility operation
- 0ms overhead required
- Example: File creation utilities, template expansion

---

### 6.4 Anti-Patterns

#### Anti-Pattern 1: Fighting the Tool Constraints

**Description**: Attempting to make exports work across Bash tool blocks or using workarounds to bypass subprocess isolation.

**Why It Fails**:
- Bash tool subprocess isolation (GitHub issues #334, #2508)
- Exports don't persist across tool invocations
- Workarounds are fragile and violate fail-fast principle

**Technical Explanation**:

The Bash tool launches each code block in a separate subprocess, not a subshell. This means:

```bash
# Block 1
export VAR="value"
export ANOTHER_VAR="data"

# Block 2 (completely separate subprocess)
echo "$VAR"          # Empty! Export didn't persist
echo "$ANOTHER_VAR"  # Empty! Export didn't persist
```

Subprocess boundaries are fundamental to the tool architecture and cannot be bypassed.

**Real Example from Spec 582**:

Early attempts tried global variable exports:

```bash
# Attempted solution (FAILED)
export WORKFLOW_SCOPE="research-and-plan"
export PHASES_TO_EXECUTE="1 2"

# Later block
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: Variable not set"  # This error occurred!
fi
```

**Why This Happened**:

Developers assumed bash blocks were subshells (where exports persist), not separate subprocesses (where they don't).

**Attempted Workarounds** (all failed):

1. **Global Environment Variables**: `export` doesn't persist
2. **eval $(previous_block)**: Previous block output not accessible
3. **Source Script Files**: Files must be created in separate blocks
4. **Named Pipes**: Complex, fragile, high failure rate

**What to Do Instead**:

Use Pattern 1 (Stateless Recalculation):

```bash
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")

# Block 2 (recalculate, don't rely on export)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
```

Or use Pattern 2 (Checkpoint Files) for complex state:

```bash
# Block 1
save_checkpoint "workflow" '{"scope": "research-only"}'

# Block 2
WORKFLOW_SCOPE=$(load_checkpoint "workflow" | jq -r '.scope')
```

**Lesson Learned**:

Work with tool constraints, not against them. Subprocess isolation is intentional (security, reliability). Accept it and choose appropriate state management pattern.

**Reference**: Specs 582-584 discovery phase

---

#### Anti-Pattern 2: Premature Optimization

**Description**: Using file-based state (Pattern 3) for fast calculations to avoid "code duplication".

**Why It Fails**:
- Adds 30ms I/O overhead for <1ms operation (30x slower!)
- Introduces cache invalidation complexity
- Creates new failure modes (disk full, permissions, staleness)
- Code is more complex, not simpler

**Technical Explanation**:

File I/O overhead (30ms) exceeds recalculation cost (<1ms) for simple variables:

```bash
# ANTI-PATTERN: File-based state for simple variable
VAR_CACHE=".claude/cache/workflow_scope.txt"
if [ -f "$VAR_CACHE" ]; then
  WORKFLOW_SCOPE=$(cat "$VAR_CACHE")  # 30ms I/O
else
  WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms calculation
  echo "$WORKFLOW_SCOPE" > "$VAR_CACHE"
fi
# Total time: 30ms cached, 31ms uncached (30x slower than recalculation!)

# CORRECT: Stateless recalculation (Pattern 1)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms, no I/O, deterministic
```

**Performance Comparison**:

| Approach | First Invocation | Cached Invocation | Complexity | Failure Modes |
|----------|-----------------|-------------------|------------|---------------|
| **Recalculation** | <1ms | <1ms | Low | None |
| **File-based Cache** | 31ms (calc+write) | 30ms (read) | High | 4+ modes |

**Real Example from Spec 585**:

Research validation measured performance:

```bash
# Benchmark: Scope detection recalculation
time detect_workflow_scope "research authentication patterns"
# Result: 0.002s (2ms)

# Benchmark: File I/O (read + write)
time echo "test" > /tmp/bench.txt && cat /tmp/bench.txt
# Result: 0.031s (31ms)

# Verdict: Recalculation 15x faster than file I/O
```

**Why Developers Make This Mistake**:

- **Intuition**: "Code duplication is bad, caching is good"
- **Reality**: Code duplication is <1ms overhead, file caching is 30ms overhead
- **Lesson**: Measure performance before optimizing

**Additional Complexity Costs**:

```bash
# File-based state requires:
# 1. Cache invalidation logic (when to regenerate?)
# 2. Error handling (file not found, permissions, disk full)
# 3. Cleanup logic (prevent unbounded cache growth)
# 4. Testing (cache hit/miss scenarios)

# Stateless recalculation requires:
# - Nothing! Just call function again.
```

**What to Do Instead**:

Accept recalculation cost if <100ms. Only use file-based state when computation cost >1 second justifies I/O overhead.

**Decision Rule**:

```
if computation_cost < 100ms:
    use Pattern 1 (Stateless Recalculation)
elif computation_cost < 1s:
    evaluate trade-off (context-dependent)
else:  # computation_cost > 1s
    use Pattern 3 (File-based State) with cache invalidation
```

**Reference**: Spec 585 research validation

---

#### Anti-Pattern 3: Over-Consolidation

**Description**: Creating >400 line bash blocks to eliminate recalculation overhead.

**Why It Fails**:
- Code transformation risk at >400 lines (tool limitation)
- Readability degradation (harder to understand monolithic block)
- Cannot leverage Task tool for subagent delegation
- Single point of failure (entire block fails if one operation fails)

**Technical Explanation**:

Large bash blocks increase risk of code transformation bugs. The threshold is approximately 300-400 lines (empirically observed):

```bash
# ANTI-PATTERN: Monolithic 500-line block
# Block 1 (500 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)
# ... 450 lines of logic ...
# All logic in single block (no recalculation, but risky transformation)
```

**Why 400 Lines is the Threshold**:

- **Context Window**: Large code blocks consume significant context
- **Transformation Risk**: Claude may inadvertently modify code during tool invocation
- **Debugging Difficulty**: Hard to isolate failures in 500-line block
- **Maintainability**: Large blocks harder to understand and modify

**Real Example from Spec 582**:

Initial attempts consolidated all Phase 0 logic into single block:

**Before Split** (Phase 6 analysis):
- Block size: 421 lines
- Risk: Code transformation bugs (threshold exceeded)
- Performance: 0ms recalculation overhead (but at what cost?)

**After Split** (chosen approach):
```bash
# Block 1: Phase 0 initialization (176 lines) ✓ Under threshold
# Block 2: Research setup (168 lines) ✓ Under threshold
# Block 3: Planning setup (77 lines) ✓ Under threshold
# Total recalculation overhead: <10ms
```

**Performance vs Risk Trade-off**:

| Approach | Overhead | Risk | Maintainability | Subagent Support |
|----------|----------|------|----------------|------------------|
| **Single 500-line block** | 0ms | HIGH | Low | No (Task tool blocked) |
| **3 blocks (<200 lines each)** | <10ms | Low | High | Yes (Task tool works) |

**Verdict**: 10ms overhead acceptable for 3x risk reduction.

**What to Do Instead**:

Split logic into multiple blocks (each <300 lines). Accept recalculation overhead (<10ms total) for safety and maintainability.

**Correct Approach** (from /coordinate after refactor):

```bash
# Block 1: Phase 0 initialization (176 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")
# ... initialization logic ...

# Block 2: Research setup (168 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)  # Recalculate (deterministic)
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # <1ms overhead
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")
# ... research logic ...

# Block 3: Planning setup (77 lines)
CLAUDE_PROJECT_DIR=$(detect_project_dir)  # Recalculate
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")
# ... planning logic ...

# Overhead: 3 blocks × 3 variables × <1ms = <10ms
# Benefit: Risk mitigation + Task tool support
```

**Block Size Guidelines**:

- **Safe**: <300 lines per block
- **Caution**: 300-400 lines (watch for issues)
- **Danger**: >400 lines (high transformation risk)

**When Consolidation is OK**:

If command is simple utility (<300 lines total), use Pattern 4 (Single Large Block):

```bash
# OK: Simple 250-line utility command
# Single block is safe and appropriate
```

**Reference**: Spec 582 discovery, Phase 6 analysis (deferred)

---

#### Anti-Pattern 4: Inconsistent Patterns

**Description**: Mixing state management approaches within same command (e.g., stateless recalculation for some variables, file-based state for others).

**Why It Fails**:
- Cognitive overhead (developers must track which variables use which pattern)
- Debugging complexity (is failure from recalculation or cache staleness?)
- Maintenance burden (multiple patterns to update)
- No performance benefit (overhead is per-pattern, not reduced by mixing)

**Technical Explanation**:

Mixing patterns creates mental model confusion:

```bash
# ANTI-PATTERN: Inconsistent patterns
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Pattern 1: Recalculate
PHASES=$(cat .claude/cache/phases.txt)            # Pattern 3: File-based
CLAUDE_PROJECT_DIR=$(load_checkpoint "state" | jq -r '.project_dir')  # Pattern 2: Checkpoint

# Block 2
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Pattern 1: Recalculate
PHASES=$(cat .claude/cache/phases.txt)            # Pattern 3: File-based
CLAUDE_PROJECT_DIR=$(load_checkpoint "state" | jq -r '.project_dir')  # Pattern 2: Checkpoint

# Developer must remember:
# - WORKFLOW_SCOPE is recalculated (deterministic)
# - PHASES is cached (may be stale)
# - CLAUDE_PROJECT_DIR is checkpointed (may be stale)
# Which variable failed? Was it stale cache or bad recalculation?
```

**Debugging Nightmare**:

```bash
# Bug report: "PHASES_TO_EXECUTE is wrong in Block 3"
# Possible causes:
# 1. Recalculation logic wrong? (check detect_workflow_scope)
# 2. Cache stale? (check .claude/cache/phases.txt modification time)
# 3. Checkpoint corrupted? (check checkpoint JSON integrity)
# 4. Wrong pattern used? (check which Block 3 uses)
# 5. Synchronization issue? (check if Block 1 and Block 3 use same pattern)
# → 5 failure modes to investigate vs 1 (if consistent pattern)
```

**Real Example from Specs 583-584**:

Attempted mixing stateless recalculation with checkpoint-style persistence:

```bash
# Block 1: Initialization
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Stateless
save_checkpoint "state" "{\"phases\": \"$PHASES\"}"  # Checkpoint

# Block 2: Research
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Stateless (consistent)
PHASES=$(load_checkpoint "state" | jq -r '.phases')  # Checkpoint (consistent)

# Block 3: Planning
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Stateless (consistent)
PHASES=$(cat .claude/cache/phases.txt)  # File-based (INCONSISTENT!)

# Bug: Block 3 uses different pattern (file-based cache vs checkpoint)
# Result: PHASES may be different in Block 3 vs Block 2
# Debugging: Which is correct? Cache or checkpoint?
```

**What to Do Instead**:

Choose one pattern and apply consistently throughout command. Exceptions must be clearly documented.

**Correct Approach**:

```bash
# Pattern 1 applied consistently
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")
PHASES=$(calculate_phases "$WORKFLOW_SCOPE")
CLAUDE_PROJECT_DIR=$(detect_project_dir)

# Block 2
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Consistent recalculation
PHASES=$(calculate_phases "$WORKFLOW_SCOPE")      # Consistent recalculation
CLAUDE_PROJECT_DIR=$(detect_project_dir)          # Consistent recalculation

# Block 3
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Consistent
PHASES=$(calculate_phases "$WORKFLOW_SCOPE")      # Consistent
CLAUDE_PROJECT_DIR=$(detect_project_dir)          # Consistent

# Mental model: "All variables are recalculated in every block"
# Debugging: If variable wrong, check calculation function
# Maintenance: Update calculation function once, applies everywhere
```

**Documented Exceptions** (when necessary):

```bash
# Block 1
WORKFLOW_SCOPE=$(detect_workflow_scope "$INPUT")  # Pattern 1: Stateless
CODEBASE_ANALYSIS=$(cat .claude/cache/analysis.json)  # Pattern 3: File-based

# DOCUMENTED EXCEPTION: CODEBASE_ANALYSIS uses file-based caching because:
# 1. Computation cost: 5-10 seconds (too expensive to recalculate)
# 2. Cache invalidation: Content-based (analysis_${PROJECT_HASH}.json)
# 3. Overhead justified: 5s → 30ms (167x speedup)
# All other variables use Pattern 1 (Stateless Recalculation)
```

**Pattern Selection Rule**:

1. Choose primary pattern based on command requirements (see decision framework)
2. Apply primary pattern to ALL variables
3. Only deviate for exceptional cases (document WHY)

**Reference**: Specs 583-584, Spec 597 consistency breakthrough

---

### 6.5 Case Studies

#### Case Study 1: /coordinate - Stateless Recalculation Pattern

**Context**: Specs 582-594 explored various approaches to managing state across /coordinate's 6 bash blocks

**Problem**:
- 6 bash blocks (Phases 0-6) required variable persistence
- Exports don't work (subprocess isolation)
- 10+ variables needed across blocks (WORKFLOW_SCOPE, PHASES_TO_EXECUTE, CLAUDE_PROJECT_DIR, etc.)
- Initial attempts with file-based state added 30ms overhead per block (180ms total)

**Exploration Timeline**:

**Spec 582-584: Discovery Phase** (Fighting tool constraints)
- **Attempted**: Global exports (failed - subprocess isolation)
- **Attempted**: Temporary file persistence (worked but slow - 180ms overhead)
- **Result**: 48-line scope detection duplicated across 2 blocks
- **Learning**: Exports don't persist across bash tool invocations

**Spec 585: Research Validation**
- **Measured**: File I/O overhead = 30ms per operation
- **Measured**: Recalculation overhead = <1ms per variable
- **Conclusion**: File-based state 30x slower for simple variables
- **Decision**: Investigate recalculation-based approach

**Spec 593: Problem Mapping**
- **Identified**: 108 lines of duplicated code across blocks
- **Identified**: 3 synchronization points (CLAUDE_PROJECT_DIR, scope detection, PHASES_TO_EXECUTE)
- **Risk**: Synchronization drift between duplicate code locations
- **Quantified**: 48-line scope detection duplication highest risk

**Spec 597: Breakthrough - Stateless Recalculation**
- **Key Insight**: Accept code duplication as intentional trade-off
- **Pattern**: Recalculate all variables in every block (<1ms overhead each)
- **Benefits**: Deterministic, no I/O, simple mental model
- **Trade-off**: 50-80 lines duplication vs 180ms file I/O savings
- **Performance**: <10ms total overhead vs 180ms (18x faster!)

**Spec 598: Extension to Derived Variables**
- **Extended**: Pattern to PHASES_TO_EXECUTE mapping
- **Added**: Defensive validation after recalculation
- **Fixed**: overview-synthesis.sh missing from REQUIRED_LIBS
- **Result**: 100% reliability, <10ms total overhead

**Solution Implemented**:

```bash
# Every block recalculates what it needs
# Block 1 - Phase 0
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")

# Block 2 - Phase 1 (different subprocess)
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")

# Overhead: <1ms per block × 6 blocks = <6ms total
# Alternative (file-based): 30ms × 6 = 180ms (30x slower)
```

**Outcome**:
- ✓ 16/16 integration tests passing
- ✓ <10ms total recalculation overhead
- ✓ Zero I/O operations (pure computation)
- ✓ Deterministic behavior (no cache staleness)
- ✓ Simple mental model (no state synchronization)

**Lessons Learned**:

1. **Accept Duplication**: 50-80 lines duplication is acceptable trade-off for simplicity
2. **Work With Constraints**: Embrace tool constraints rather than fighting them
3. **Measure Performance**: Validate assumptions with benchmarks (recalc vs file I/O)
4. **Validate Pattern**: Extensive testing (16 integration tests) proves reliability
5. **Document Rationale**: Architecture documentation prevents future misguided refactor attempts

**Applicable To**:
- Multi-block orchestration commands
- Commands with <10 variables requiring persistence
- Workflows with recalculation cost <100ms
- Commands invoking subagents via Task tool

**References**:
- Specs: 582-584 (discovery), 585 (validation), 593 (mapping), 597 (breakthrough), 598 (extension)
- Architecture Doc: `.claude/docs/architecture/coordinate-state-management.md`

---

#### Case Study 2: /implement - Checkpoint Files Pattern

**Context**: Multi-phase implementation workflow requiring resumability after interruptions

**Problem**:
- 5+ phase implementation plans
- Execution time: 2-6 hours per plan
- Interruptions: Network failures, manual stops, system restarts
- State complexity: Current phase, completed phases, test status, git commits

**Pattern Choice Rationale**:

**Why Not Pattern 1 (Stateless Recalculation)?**
- Cannot recalculate "current phase" after interruption (state lost on process termination)
- Cannot determine which phases completed successfully (test results lost)
- Git commit hashes not recoverable (not deterministic from inputs)
- Implementation modifications not recalculable (real file system changes)

**Why Not Pattern 3 (File-based State)?**
- State changes frequently (every phase boundary) → cache churn
- Cache invalidation complex (which phase checkpoint is valid?)
- Not caching computation results - persisting workflow progress (different use case)

**Why Pattern 2 (Checkpoint Files)?**
- ✓ Perfect fit for resumable workflows
- ✓ Phase boundaries are natural checkpoint locations
- ✓ State serialization to JSON straightforward
- ✓ Checkpoint history provides audit trail
- ✓ 50-100ms overhead negligible for hour-long workflows

**Solution Implemented**:

```bash
# Source checkpoint utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh"

# After each phase completion
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $PHASE_NUMBER,
  "completed_phases": [1, 2, 3],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f", "c9e5a2f"],
  "timestamp": "$(date -Iseconds)"
}
EOF
)

save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"

# On workflow restart (after interruption)
if [ -f "$CHECKPOINT_FILE" ]; then
  PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
  START_PHASE=$(($(jq -r '.current_phase' "$CHECKPOINT_FILE") + 1))
  echo "Resuming from phase $START_PHASE"
fi
```

**Outcome**:
- ✓ Full workflow resumability after interruptions
- ✓ 50-100ms overhead per checkpoint (acceptable for hour-long workflows)
- ✓ Audit trail of implementation progress
- ✓ State synchronized with reality (checkpoints after successful phase completion)

**Lessons Learned**:

1. **Right Tool for Job**: Checkpoint pattern perfect for resumable multi-phase workflows
2. **Phase Boundaries**: Natural checkpoint locations provide clear state transitions
3. **Overhead Acceptable**: 50-100ms negligible for hour-long workflows (0.1% overhead)
4. **JSON Serialization**: Flexible state structure, easy to extend with new fields

**Applicable To**:
- Long-running implementation workflows
- Multi-phase operations requiring resumability
- Commands needing audit trail
- Workflows with >5 phases

**References**:
- Implementation: `/implement` command
- Utilities: `.claude/lib/workflow/checkpoint-utils.sh`

---

### 6.6 Cross-References

**Architecture Documentation**:
- [Coordinate State Management Architecture](../architecture/coordinate-state-management.md) - Complete technical analysis with subprocess isolation explanation, decision matrix, troubleshooting guide

**Related Patterns**:
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Detailed checkpoint implementation patterns
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation across bash blocks

**Related Specifications**:
- Spec 597: Stateless Recalculation Breakthrough
- Spec 598: Extension to Derived Variables
- Spec 585: Research Validation (performance measurements)
- Spec 593: Comprehensive Problem Mapping

**Library References**:
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint save/restore utilities
- `.claude/lib/workflow/workflow-detection.sh` - Workflow scope detection
- `.claude/lib/core/unified-location-detection.sh` - Path calculation utilities

**Command Examples**:
- `/coordinate` - Stateless recalculation implementation
- `/implement` - Checkpoint files implementation
- `/orchestrate` - Similar multi-block patterns

**Standards**:
- [CLAUDE.md Development Philosophy](../../CLAUDE.md#development_philosophy) - Clean-break approach, fail-fast principles
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 13 (CLAUDE_PROJECT_DIR detection)

---
## 7. Testing and Validation

### 7.1 Testing Standards Integration

Commands should discover test commands from CLAUDE.md:

#### Test Discovery Procedure

```bash
# 1. Locate CLAUDE.md
CLAUDE_MD=$(find_claude_md)

# 2. Extract Testing Protocols section
TEST_PROTOCOLS=$(extract_section "$CLAUDE_MD" "Testing Protocols")

# 3. Parse test commands
TEST_COMMAND=$(echo "$TEST_PROTOCOLS" | grep -oP 'Test Command: \K.*' | head -1)

# 4. Execute discovered test command
if [ -n "$TEST_COMMAND" ]; then
  eval "$TEST_COMMAND"
else
  # Fallback to language defaults
  if [ -f "package.json" ]; then
    npm test
  elif [ -f "Makefile" ]; then
    make test
  else
    echo "No test command found"
  fi
fi
```

### 7.2 Validation Checklist

Before marking command complete:

**Functional Validation**:
- [ ] Command executes without errors
- [ ] Expected output is produced
- [ ] Output format is correct
- [ ] File modifications are correct
- [ ] No unintended side effects

**Standards Compliance**:
- [ ] Discovers CLAUDE.md correctly
- [ ] Applies discovered standards
- [ ] Handles missing CLAUDE.md gracefully
- [ ] Uses correct terminology
- [ ] Validates compliance before completion

**Agent Integration** (if applicable):
- [ ] Agents invoked with context injection only (no behavioral duplication)
- [ ] Agent prompts reference behavioral files, contain NO STEP sequences
- [ ] Context passed efficiently (metadata-only)
- [ ] Results processed correctly
- [ ] Errors handled gracefully

**User Experience**:
- [ ] Clear progress indicators
- [ ] Helpful error messages
- [ ] Appropriate logging
- [ ] Expected completion message

---

## 8. Common Patterns and Examples

### 8.1 Example: Research Command with Agent Delegation

```markdown
## Workflow for /report Command

### Step 1: Pre-Calculate Report Path

**EXECUTE NOW - Calculate Report Path**

```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$RESEARCH_TOPIC" ".claude/specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001_${TOPIC_SLUG}" "")
echo "Report will be written to: $REPORT_PATH"
```

### Step 2: Invoke Research Agent with Behavioral File Reference

**AGENT INVOCATION - Reference Behavioral File, Inject Context Only**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${RESEARCH_TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Why This Pattern Works**:
- research-specialist.md contains complete behavioral guidelines (646 lines)
- Agent reads behavioral file and follows all step-by-step instructions automatically
- Command only injects workflow-specific context (paths, parameters)
- No duplication: single source of truth maintained in behavioral file
- Reduction: ~150 lines → ~15 lines per invocation (90% reduction)

**✓ CORRECT**: This example shows context injection only (parameters, file paths)

**✗ INCORRECT**: Do not add STEP 1/2/3 instructions inline (reference behavioral file instead). Example of anti-pattern:
```yaml
# ❌ BAD - Duplicating behavioral content
Task {
  prompt: "
    STEP 1: Analyze codebase...
    STEP 2: Create report file...
    STEP 3: Verify and return...
    [150+ lines of agent behavioral procedures]
  "
}
```

See [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md) for decision criteria on what qualifies as context (inline OK) vs behavioral content (reference agent file).

### Step 3: Verify and Fallback

**MANDATORY VERIFICATION - Report File Exists**

```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL: Agent didn't create report file"
  echo "Executing fallback creation..."

  cat > "$REPORT_PATH" <<EOF
# ${RESEARCH_TOPIC}

## Findings
${AGENT_OUTPUT}
EOF
fi

echo "✓ Verified: Report exists at $REPORT_PATH"
```
```

### 8.2 When to Use Inline Templates

**Structural templates** are command execution patterns that MUST be inline. These are NOT behavioral content and should not be moved to agent files.

**Inline Required** - Structural Templates:

1. **Task Invocation Blocks**
   ```yaml
   Task {
     subagent_type: "general-purpose"
     description: "Research topic"
     prompt: "..."
   }
   ```
   - **Why inline**: Commands must parse this structure to invoke agents
   - **Context**: Command/orchestrator responsibility

2. **Bash Execution Blocks**
   ```bash
   # EXECUTE NOW
   source .claude/lib/artifact/artifact-creation.sh
   REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001" "")
   ```
   - **Why inline**: Commands must execute these operations directly
   - **Context**: Command/orchestrator responsibility

3. **Verification Checkpoints**
   ```markdown
   **MANDATORY VERIFICATION**: After agent completes, verify:

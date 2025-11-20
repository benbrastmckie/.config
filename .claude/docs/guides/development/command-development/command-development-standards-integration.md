# Command Development Guide - Standards Integration

**Part 2 of 5** | [Index](command-development-index.md)

This document covers standards discovery, CLAUDE.md integration, and applying project standards in command development.

---

```

#### Standards Reference

This pattern is enforced by:
- **Standard 11**: Imperative Agent Invocation Pattern ([Command Architecture Standards](../reference/architecture/overview.md#standard-11))
- **Behavioral Injection Pattern**: Anti-Pattern section ([Behavioral Injection](../concepts/patterns/behavioral-injection.md#anti-pattern-documentation-only-yaml-blocks))

#### Code-Fenced Task Invocations Prevent Execution

YAML blocks wrapped in code fences (` ```yaml ... ``` `) cause a 0% agent delegation rate. All agent invocations appear as documentation examples rather than executable instructions, leading to silent failure where commands appear to work but no agents are invoked.

**Symptoms**:
- Agent delegation rate: 0%
- File creation rate: 0%
- Commands complete successfully but produce no artifacts

### 5.2.2 Code Fence Priming Effect

**Problem**: Code-fenced Task invocation examples (` ```yaml ... ``` `) establish a "documentation interpretation" pattern that causes Claude to treat subsequent unwrapped Task blocks as non-executable examples. This results in 0% agent delegation rate even when the actual Task invocations are structurally correct and lack code fences.

**Root Cause**: When Claude encounters a code-fenced Task example early in a command file (e.g., lines 62-79), it establishes a mental model that "Task blocks are documentation examples". This interpretation persists and applies to later Task invocations, preventing execution even when they are not code-fenced.

**Detection**:

```bash
# Check for code-fenced Task examples that could cause priming effect
grep -n '```yaml' .claude/commands/*.md | while read match; do
  file=$(echo "$match" | cut -d: -f1)
  line=$(echo "$match" | cut -d: -f2)

  # Check if Task invocation follows
  sed -n "$((line+1)),$((line+15))p" "$file" | grep -q "Task {" && \
    echo "Potential priming effect: $file:$line"
done
```

**Fix Pattern**:

1. **Remove code fences from Task examples**: Convert ` ```yaml ... ``` ` to unwrapped blocks
2. **Add HTML comments for clarity**: Use `<!-- This Task invocation is executable -->` above unwrapped examples (invisible to Claude)
3. **Keep anti-pattern examples fenced**: Examples marked with ❌ should remain code-fenced to prevent accidental execution
4. **Verify tool access**: Ensure agents have required tools (especially Bash) in allowed-tools frontmatter

**Before (Causes Priming Effect)**:

```markdown
**Example Pattern**:
```yaml
# ✅ CORRECT - Task invocation example
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

Later in file...

**EXECUTE NOW**: Invoke research agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: "..."
}

Result: 0% delegation (priming effect from first code-fenced example)
```

**After (No Priming Effect)**:

```markdown
**Example Pattern**:

<!-- This Task invocation is executable -->
# ✅ CORRECT - Task invocation example
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}

Later in file...

**EXECUTE NOW**: Invoke research agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: "..."
}

Result: 100% delegation (no code fences, no priming effect)
```

**Detection Symptoms**:

A single code-fenced Task example early in a command file causes 0% agent delegation rate for all subsequent Task invocations, even when those invocations are structurally correct and lack code fences. The early code-fenced example establishes an interpretation pattern that prevents all later execution.

**Observable Effects**:
- Delegation rate: 0% (all Task invocations treated as documentation)
- Context usage: >80% (metadata extraction disabled)
- Streaming fallback errors: Present
- Parallel agent execution: 0 agents invoked

**Prevention Guidelines**:
- Never wrap executable Task invocations in code fences
- Use HTML comments for annotations (invisible to Claude)
- Move complex examples to external reference files (e.g., `.claude/docs/patterns/`)
- Test delegation rate after adding Task examples
- Ensure agents have Bash in allowed-tools for proper initialization

See also:
- [Behavioral Injection - Code Fence Priming Effect](../concepts/patterns/behavioral-injection.md#anti-pattern-code-fenced-task-examples-create-priming-effect)
- [Test Suite](../../tests/test_supervise_agent_delegation.sh) for validation

### 5.3 Pre-Calculating Topic-Based Artifact Paths

**Why Pre-Calculate Paths?**

**Reasons:**
1. **Control**: Command controls exact artifact locations
2. **Topic Organization**: Enforces `specs/{NNN_topic}/` structure
3. **Consistent Numbering**: Sequential NNN across artifact types
4. **Verification**: Can verify artifact created at expected path
5. **Metadata Extraction**: Know exact path for metadata loading

**Standard Path Calculation Pattern**:

```bash
# Source artifact creation utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

# Step 1: Get or create topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
# Result: specs/042_authentication (creates if doesn't exist)

# Step 2: Calculate artifact path
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security_analysis" "")
# Result: specs/042_authentication/reports/042_security_analysis.md

# Step 3: Use path in agent invocation
echo "Artifact will be created at: $ARTIFACT_PATH"
```

### 5.4 Artifact Verification Patterns

**Verification with Recovery**:

```bash
# Use recovery utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"

EXPECTED_PATH="specs/042_auth/reports/042_security.md"
TOPIC_SLUG="security"  # Search term for recovery

VERIFIED_PATH=$(verify_artifact_or_recover "$EXPECTED_PATH" "$TOPIC_SLUG")

if [ $? -eq 0 ]; then
  echo "✓ Artifact found at: $VERIFIED_PATH"

  if [ "$VERIFIED_PATH" != "$EXPECTED_PATH" ]; then
    echo "⚠ Path mismatch recovered (agent used different number)"
  fi
else
  echo "✗ Artifact not found, recovery failed"
  exit 1
fi
```

### 5.5 Metadata Extraction

**Why Extract Metadata Only?**

**Context Reduction**: 95% reduction in token usage

**Example**:
- Full report: 5000 tokens
- Metadata only: 250 tokens (path + summary + findings)
- Reduction: 95%

**Metadata Extraction Pattern**:

```bash
# Source metadata extraction utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

# Extract report metadata
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")

# Parse metadata fields
SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')
KEY_FINDINGS=$(echo "$REPORT_METADATA" | jq -r '.key_findings[]')
RECOMMENDATIONS=$(echo "$REPORT_METADATA" | jq -r '.recommendations[]')

echo "Report: $REPORT_PATH"
echo "Summary: $SUMMARY"
echo "Findings: $KEY_FINDINGS"
```

See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for complete invocation templates and examples.

---

## 5.5. Using Utility Libraries

### When to Use Libraries vs Agents

Commands should prefer utility libraries over agent invocation when:

**Deterministic Operations** (No AI reasoning needed):
- Location detection from user input
- Topic name sanitization
- Directory structure creation
- Plan file parsing
- Metadata extraction from structured files

**Performance Critical Paths**:
- Workflow initialization
- Checkpoint save/load operations
- Log file writes
- JSON/YAML parsing

**Context Window Optimization**:
- Libraries use 0 tokens (pure bash)
- Agents use 15k-75k tokens per invocation
- Example: `unified-location-detection.sh` saves 65k tokens vs `location-specialist` agent

### Common Library Usage Pattern

```bash
#!/usr/bin/env bash

# Get Claude config directory
CLAUDE_CONFIG="${CLAUDE_CONFIG:-${HOME}/.config}"

# Source the library
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Call library function
LOCATION_JSON=$(perform_location_detection "$USER_INPUT")

# Extract results (with jq fallback)
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
else
  # Fallback without jq
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# MANDATORY VERIFICATION checkpoint
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - directory not created"
  exit 1
fi
```

### Available Libraries

**Core Utilities**:
- `unified-location-detection.sh` - Standardized location detection (<1s, 0 tokens vs 25s, 75k tokens for agent)
- `plan-core-bundle.sh` - Plan parsing and manipulation
- `metadata-extraction.sh` - Report/plan metadata extraction (99% context reduction)
- `checkpoint-utils.sh` - Checkpoint state management

**Agent Support**:
- `# agent-registry-utils.sh (removed)` - Agent registration and discovery
- `hierarchical-agent-support.sh` - Multi-level agent coordination

**Workflow Support**:
- `unified-logger.sh` - Structured logging with rotation
- `error-handling.sh` - Standardized error handling
- `context-pruning.sh` - Context window optimization

See [Library API Reference](../reference/library-api/overview.md) for complete function signatures and [Using Utility Libraries](using-utility-libraries.md) for detailed patterns and examples.

### Library Sourcing Patterns

Commands should choose the appropriate sourcing pattern based on their needs:

#### Pattern 1: Orchestration Commands (Core + Workflow Libraries)

Use `library-sourcing.sh` for orchestration commands that need core libraries plus optional workflow utilities:

```bash
#!/usr/bin/env bash
# Source library-sourcing.sh for automatic core library loading
source "$(dirname "${BASH_SOURCE[0]}")/../lib/core/library-sourcing.sh"

# Load core libraries (7) + additional workflow libraries
# Automatic deduplication prevents re-sourcing duplicates
source_required_libraries "dependency-analyzer.sh" "complexity-utils.sh" || exit 1

# All libraries now available:
# - Core: error-handling, checkpoint-utils, unified-logger, etc.
# - Workflow: dependency-analyzer, complexity-utils
```

**Benefits:**
- Automatic loading of 7 core libraries (error-handling, checkpoint-utils, unified-logger, unified-location-detection, metadata-extraction, context-pruning, workflow-detection)
- Deduplication prevents re-sourcing if library names appear in both core and parameter list
- Consistent library set across all orchestration commands
- Single function call instead of multiple source statements

**When to use:**
- Orchestration commands: `/orchestrate`, `/coordinate`, `/implement`, `/supervise`
- Commands requiring workflow utilities (checkpoints, complexity analysis, parallel execution)
- Commands that need the standard orchestration infrastructure

#### Pattern 2: Specialized Commands (Direct Sourcing)

Use direct sourcing for specialized commands with narrow library needs:

```bash
#!/usr/bin/env bash
# Source only the specific libraries needed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../lib/convert/convert-core.sh"
# Conversion logger not yet implemented

# Call specialized conversion functions
convert_file "$INPUT" "$OUTPUT"
```

**Benefits:**
- Avoids loading unnecessary core libraries
- Faster startup (fewer files sourced)
- Clear dependencies (explicitly lists what's needed)
- Appropriate for single-purpose commands

**When to use:**
- Document conversion commands
- Analysis commands
- Template-based commands
- Any command with 1-3 specific library dependencies

#### Pattern 3: Simple Commands (No Libraries)

Simple commands may not need any libraries:

```bash
#!/usr/bin/env bash
# No library dependencies - direct implementation

echo "Simple command executing..."
# Direct implementation without utility functions
```

**When to use:**
- Commands with trivial logic
- Commands that only invoke other commands/tools
- Commands where utilities would add unnecessary complexity

#### Deduplication Behavior

The `source_required_libraries()` function automatically deduplicates library names to prevent re-sourcing:

```bash
# Example: Duplicate library names
source_required_libraries \
  "dependency-analyzer.sh" \       # NEW (only this sourced)
  "checkpoint-utils.sh" \          # Already in core 7 (skipped)
  "error-handling.sh" \            # Already in core 7 (skipped)
  "metadata-extraction.sh"         # Already in core 7 (skipped)

# Debug output shows:
# DEBUG: Library deduplication: 11 input libraries -> 8 unique libraries (3 duplicates removed)
```

**How it works:**
- Combines core 7 libraries + your additional parameters into single array
- Removes duplicates using O(n²) string matching (acceptable for n≈10 libraries)
- Preserves first occurrence order for unique libraries
- Sources each unique library exactly once

**Performance:**
- Overhead: <0.01ms (negligible)
- Prevents duplicate sourcing that caused /coordinate timeout (>120s → <90s)
- 93% less code than memoization alternative (20 lines vs 310 lines)

#### Artifact Management Libraries

Artifact operations are split across two focused libraries:

```bash
# Artifact file creation and directory management
source .claude/lib/artifact/artifact-creation.sh

# Artifact tracking, querying, and validation
source .claude/lib/artifact/artifact-registry.sh
```

See [Library Classification](../../lib/README.md#library-classification) for complete details on available functions.

### 5.6 Path Calculation Best Practices

**CRITICAL**: Calculate paths in parent command scope, NOT in agent prompts.

#### Why This Matters

The Bash tool used by AI agents escapes command substitution `$(...)` for security purposes. This breaks path calculation that relies on sourcing libraries and capturing function output.

**Error Example**:
```bash
# This WILL FAIL in agent prompt:
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")

# Error: syntax error near unexpected token 'perform_location_detection'
```

#### Recommended Pattern

**Parent Command Responsibilities:**
1. Source libraries
2. Calculate all paths
3. Create directories
4. Pass absolute paths to agents

**Agent Responsibilities:**
1. Receive absolute paths
2. Execute tasks
3. NO path calculation

#### Correct Implementation

```bash
# ✓ CORRECT: Parent command calculates paths
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/core/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")

# Extract all needed paths
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Pre-calculate artifact path
REPORT_PATH="${REPORTS_DIR}/001_${SANITIZED_TOPIC}.md"
mkdir -p "$(dirname "$REPORT_PATH")"

# Pass absolute path to agent (no calculation needed)
Task {
  subagent_type: "general-purpose"
  prompt: "
    **Report Path**: $REPORT_PATH

    Create report at the exact path above.
  "
}
```

```bash
# ✗ WRONG: Attempting calculation in agent prompt
Task {
  prompt: "
    # This will fail due to bash escaping:
    REPORT_PATH=$(calculate_path '$TOPIC')
  "
}
```

#### Working vs Broken Bash Constructs

**Working in Agent Context:**
- Arithmetic: `VAR=$((expr))` ✓
- Sequential: `cmd1 && cmd2` ✓
- Pipes: `cmd1 | cmd2` ✓
- Sourcing: `source file.sh` ✓
- Conditionals: `[[ test ]] && action` ✓

**Broken in Agent Context:**
- Command substitution: `VAR=$(command)` ✗
- Backticks: `` VAR=`command` `` ✗

#### Performance Benefits

This pattern maintains optimal performance:
- Token usage: <11k per detection (85% reduction)
- Execution time: <1s for path calculation
- Reliability: 100% (no escaping issues)

**See also**: [Bash Tool Limitations](../troubleshooting/bash-tool-limitations.md) for detailed explanation and more examples.

---

## 6. State Management Patterns

### 6.1 Introduction - Why State Management Matters

Multi-block commands in Claude Code face a fundamental architectural constraint: **bash blocks execute in separate subprocesses**. This means variable exports and environment changes don't persist between blocks.

**For comprehensive documentation of bash block execution and subprocess isolation patterns, see [Bash Block Execution Model](../concepts/bash-block-execution-model.md)**.

#### The Subprocess Isolation Constraint

When Claude executes bash code blocks via the Bash tool, each block runs in a completely separate subprocess, not a subshell. This architectural decision (GitHub issues #334, #2508) has critical implications:

```bash
# Block 1
export WORKFLOW_SCOPE="research-only"
export PHASES="1 2 3"

# Block 2 (separate subprocess - exports are gone!)
echo "$WORKFLOW_SCOPE"  # Empty!
echo "$PHASES"          # Empty!
```

**Why this matters**:
- Orchestration commands often span 5-7 bash blocks (one per phase)
- Variables like `WORKFLOW_SCOPE`, `PHASES_TO_EXECUTE`, `CLAUDE_PROJECT_DIR` needed across blocks
- Traditional shell programming patterns (export, source, eval) don't work
- State management becomes an explicit design decision

#### Available Patterns Overview

This guide documents 4 proven state management patterns, each optimized for different scenarios:

1. **Pattern 1: Stateless Recalculation** - Recalculate variables in every block (<1ms overhead)
2. **Pattern 2: Checkpoint Files** - Serialize state to `.claude/data/checkpoints/` for resumability
3. **Pattern 3: File-based State** - Cache expensive computation results (>1s operations)
4. **Pattern 4: Single Large Block** - Avoid state management by keeping all logic in one block

Each pattern has clear trade-offs in performance, complexity, and reliability. The decision framework in section 6.3 guides pattern selection based on command requirements.

---

### 6.2 Pattern Catalog

#### 6.2.1 Pattern 1: Stateless Recalculation

**Core Concept**: Every bash block recalculates all variables it needs from scratch. No reliance on previous blocks for state persistence.

**When to Use**:
- Multi-block orchestration commands
- <10 variables requiring persistence
- Recalculation cost <100ms per block
- Single-invocation workflows (no resumability needed)
- Commands invoking subagents via Task tool

**Pattern Definition**:

Stateless recalculation embraces subprocess isolation rather than fighting it. Variables are deterministically recomputed in every bash block using the same input data (`$WORKFLOW_DESCRIPTION`, command arguments, file contents).

**Key Principle**: Accept code duplication as an intentional trade-off for simplicity and reliability.

**Implementation Example** (from /coordinate):

```bash
# Block 1 - Phase 0 Initialization
# Standard 13: CLAUDE_PROJECT_DIR detection
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)

# Detect workflow scope
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Calculate phases to execute
case "$WORKFLOW_SCOPE" in
  "research-only")
    PHASES_TO_EXECUTE="1"
    ;;
  "research-and-plan")
    PHASES_TO_EXECUTE="1 2"
    ;;
  "full-implementation")
    PHASES_TO_EXECUTE="1 2 3 4 5 6"
    ;;
  "debug-only")
    PHASES_TO_EXECUTE="4"
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac

# Defensive validation
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set (WORKFLOW_SCOPE=$WORKFLOW_SCOPE)"
  exit 1
fi
```

```bash
# Block 2 - Phase 1 Research (different subprocess)
# MUST recalculate everything - exports from Block 1 didn't persist

# Recalculate CLAUDE_PROJECT_DIR (same logic as Block 1)
CLAUDE_PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)

# Recalculate workflow scope (same function call as Block 1)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Recalculate phases to execute (same case statement as Block 1)
case "$WORKFLOW_SCOPE" in
  "research-only")
    PHASES_TO_EXECUTE="1"
    ;;
  "research-and-plan")
    PHASES_TO_EXECUTE="1 2"
    ;;
  "full-implementation")
    PHASES_TO_EXECUTE="1 2 3 4 5 6"
    ;;
  "debug-only")
    PHASES_TO_EXECUTE="4"
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac

# Defensive validation (repeated for reliability)
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set (WORKFLOW_SCOPE=$WORKFLOW_SCOPE)"
  exit 1
fi

# Now use PHASES_TO_EXECUTE to determine if Phase 1 should execute
if echo "$PHASES_TO_EXECUTE" | grep -q "1"; then
  # Execute Phase 1 research logic
  echo "Executing Phase 1: Research"
fi
```

**Code Duplication Strategy**:

Notice the CLAUDE_PROJECT_DIR detection, WORKFLOW_SCOPE calculation, and PHASES_TO_EXECUTE mapping are **identical** across blocks. This is intentional:

- **Overhead**: <1ms per variable recalculation
- **Total overhead**: 6 blocks × 3 variables × <1ms = <20ms
- **Alternative** (file-based state): 30ms I/O × 6 blocks = 180ms (9x slower!)
- **Benefit**: Zero I/O operations, deterministic, no synchronization issues

**Library Extraction Strategy**:

For complex calculations (>20 lines), extract to shared library function:

```bash
# .claude/lib/workflow/workflow-scope-detection.sh
detect_workflow_scope() {
  local workflow_description="$1"
  local scope=""

  if echo "$workflow_description" | grep -qiE 'research.*\(report|investigate|analyze'; then
    if echo "$workflow_description" | grep -qiE '\(plan|implement|design\)'; then
      scope="full-implementation"
    elif echo "$workflow_description" | grep -qiE 'create.*plan'; then
      scope="research-and-plan"
    else
      scope="research-only"
    fi
  elif echo "$workflow_description" | grep -qiE '\(debug|fix|troubleshoot\)'; then
    scope="debug-only"
  else
    scope="full-implementation"
  fi

  echo "$scope"
}

export -f detect_workflow_scope
```

Then every block sources the library and calls the function:

```bash
# Every block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-scope-detection.sh"
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Trade-off Analysis**:

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| **Performance** | <1ms overhead per variable | 50-80 lines code duplication |
| **Complexity** | Low (straightforward recalculation) | Synchronization burden (multiple copies) |
| **Reliability** | Deterministic (no I/O failures) | Manual updates required across blocks |
| **Maintainability** | No cleanup logic needed | Changes require multi-location updates |
| **I/O Operations** | None (pure computation) | N/A |
| **State Capacity** | Limited to fast-to-compute variables | Cannot handle expensive operations |

**Performance Characteristics**:

- **Per-variable overhead**: <1ms (measured for /coordinate)
- **Memory usage**: Negligible (variables recreated each block)
- **I/O operations**: Zero (pure computation)
- **Benchmark**: /coordinate with 6 blocks, 10 variables → <20ms total overhead
- **Scalability**: Linear (O(blocks × variables))

**Example Commands Using This Pattern**:

- `/coordinate` - Primary example (6 blocks, 10+ variables, <20ms overhead)
- `/orchestrate` - Similar multi-block workflow coordination
- Custom orchestration commands requiring subagent invocation

**Advantages**:

- ✓ **Simplicity**: No files to manage, no cleanup logic, straightforward mental model
- ✓ **Reliability**: Deterministic behavior, no cache staleness, no I/O failures
- ✓ **Performance**: <1ms per variable beats file I/O (30ms) for simple calculations
- ✓ **Debugging**: Self-contained blocks, no state synchronization issues
- ✓ **Testability**: Each block independently testable

**Disadvantages**:

- ✗ **Code Duplication**: 50-80 lines duplicated across blocks
- ✗ **Synchronization Burden**: Changes require updates across multiple blocks
- ✗ **Limited Applicability**: Cannot handle expensive computation (>100ms recalculation)
- ✗ **No Resumability**: State lost on process termination

**When NOT to Use**:

- Computation cost >100ms per block (consider Pattern 3: File-based State)
- Need resumability after interruptions (use Pattern 2: Checkpoint Files)
- >20 variables requiring persistence (complexity threshold)
- Resumable multi-phase workflows (use Pattern 2)

**Defensive Validation Pattern**:

Always validate critical variables after recalculation:

```bash
# Recalculate
PHASES_TO_EXECUTE=$(calculate_phases "$WORKFLOW_SCOPE")

# Defensive validation
if [ -z "$PHASES_TO_EXECUTE" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set (WORKFLOW_SCOPE=$WORKFLOW_SCOPE)"
  echo "DEBUG: Input was: $WORKFLOW_DESCRIPTION"
  exit 1
fi
```

**Mitigation for Code Duplication**:

1. **Extract to Library**: Functions >20 lines go to `.claude/lib/*.sh`
2. **Automated Testing**: Synchronization validation tests (see section 6.6)
3. **Comments**: Mark synchronization points with warnings
4. **Documentation**: Architecture docs explain duplication rationale

**See Also**:
- [Coordinate State Management Architecture](../architecture/coordinate-state-management.md) - Technical deep-dive
- Case Study 1: /coordinate Success Story (section 6.5)
- Anti-Pattern 2: Premature Optimization (section 6.4)

---

#### 6.2.2 Pattern 2: Checkpoint Files

**Core Concept**: Multi-phase workflows persist state to `.claude/data/checkpoints/` directory for resumability after interruptions.

**When to Use**:
- Multi-phase implementation workflows (>5 phases)
- Commands requiring >10 minutes execution time
- Workflows that may be interrupted (network failures, manual stops)
- Commands needing audit trail (checkpoint history)
- Resumable operations (restart from phase N)

**Pattern Definition**:

Checkpoint files serialize workflow state to JSON at phase boundaries, enabling full state restoration after process termination or interruption.

**Implementation Example** (from /implement):

```bash
# Source checkpoint utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh"

# After Phase 1 completion
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": 1,
  "completed_phases": [1],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua"],
  "git_commits": ["a3f8c2e"],
  "timestamp": "$(date -Iseconds)"
}
EOF
)

save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"
echo "Checkpoint saved: Phase 1 complete"

# After Phase 2 completion
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": ["file1.lua", "file2.lua", "file3.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f"],

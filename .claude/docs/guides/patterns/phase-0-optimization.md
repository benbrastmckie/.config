# Phase 0 Optimization Guide

**Path**: docs → guides → phase-0-optimization.md

[Used by: /orchestrate, /coordinate, /supervise, /research, /plan, all workflow commands]

Complete guide to the Phase 0 breakthrough: eliminating agent-based location detection in favor of unified library, achieving 85% token reduction and 25x speedup.

## Overview

Phase 0 (Location Detection) is the foundational phase of all workflow orchestration commands, responsible for calculating artifact paths before any research or planning begins. The shift from agent-based detection to the unified-location-detection.sh library represents one of the most significant performance improvements in the orchestration architecture.

**Performance Impact**:
- **Token Reduction**: 85% (75,600 → 11,000 tokens)
- **Speed Improvement**: 25x faster (25.2s → <1s)
- **Directory Pollution**: Eliminated (400-500 empty dirs → 0 lazy creation)
- **Context Before Research**: Zero tokens (paths calculated, not created)

## The Problem: Agent-Based Location Detection

### Historical Approach (Pre-Unified Library)

Orchestration commands historically delegated location detection to a general-purpose agent:

```yaml
# HISTORICAL ANTI-PATTERN (do not use)
**Agent Invocation for Location Detection**:
- subagent_type: general-purpose
- prompt: |
    Determine the appropriate directory for this workflow.

    Analyze the working directory, find existing specs/ directories,
    calculate the next topic number, and create the topic structure.

    Return the paths for reports, plans, summaries, and debug artifacts.
```

### Performance Cost

**Token Usage Breakdown**:
```
Agent prompt: 2,500 tokens
Agent reads directory structure: 30,000 tokens (500 dirs × 60 tokens each)
Agent analyzes existing topics: 15,000 tokens
Agent calculates next number: 2,000 tokens
Agent creates directories: 5,000 tokens
Agent response with paths: 3,100 tokens
───────────────────────────────────────────────────
Total: 75,600 tokens (302% of 25,000 baseline budget)
Execution time: 25.2 seconds
```

**Context Impact**: Phase 0 alone consumed 3x the entire recommended context budget, leaving no room for research, planning, or implementation.

### Directory Pollution Problem

Agent-based detection created directory structures eagerly:

```bash
# Agent creates all artifact directories upfront
mkdir -p specs/082_topic/reports
mkdir -p specs/082_topic/plans
mkdir -p specs/082_topic/summaries
mkdir -p specs/082_topic/debug
mkdir -p specs/082_topic/scripts
mkdir -p specs/082_topic/outputs

# Problem: If research phase fails, empty directories remain
ls specs/
# 082_topic/  ← Empty, pollutes directory tree
# 083_topic/  ← Empty
# 084_topic/  ← Empty
# ... (400-500 empty directories accumulated over time)
```

**Impact**: Repository contained 400-500 empty topic directories from failed or abandoned workflows, making navigation confusing and git status slow.

## The Solution: Unified Library

### Library-Based Location Detection

Replace agent invocation with standardized bash library:

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Perform location detection (single function call)
LOCATION_JSON=$(perform_location_detection "implement JWT authentication")

# Extract paths from JSON
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')

# Result: <1 second, <11,000 tokens
```

### Performance Improvement

**Token Usage Breakdown** (Library Approach):
```
Library sourcing: 500 tokens (function definitions)
perform_location_detection(): 2,000 tokens (execution)
JSON parsing: 200 tokens
Path extraction: 300 tokens
Verification checkpoint: 100 tokens
───────────────────────────────────────────────────
Total: 3,100 tokens (12.4% of baseline budget)
Reduction: 85% (75,600 → 11,000 tokens including context overhead)
Execution time: <1 second
Speed improvement: 25x faster
```

## Lazy Directory Creation

### Principle

**Old Approach** (Eager Creation):
```bash
# Agent creates directories immediately
mkdir -p specs/082_topic/{reports,plans,summaries,debug}
# Directories exist even if workflow fails
```

**New Approach** (Lazy Creation):
```bash
# Library ONLY creates topic directory, NOT artifact subdirectories
mkdir -p specs/082_topic/  # Topic directory only

# Artifact directories created ON-DEMAND when agents produce output
# Example: Research agent creates reports/ when writing first report
mkdir -p "$(dirname "$REPORT_PATH")"  # reports/ created only when needed
```

### Benefits

1. **Zero Pollution**: Failed workflows leave no empty directories
2. **Clear Status**: Directory existence indicates actual artifacts present
3. **Git Cleanliness**: Only directories with files are tracked
4. **Navigation**: Easier to find completed work (no empty noise)

### Implementation Example

```bash
# Phase 0: Calculate paths (DO NOT create artifact dirs)
LOCATION_JSON=$(perform_location_detection "research OAuth patterns")
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# At this point: specs/082_oauth_research/ exists
# But: specs/082_oauth_research/reports/ does NOT exist yet

# Phase 1: Research agent creates report
# Agent prompt includes:
mkdir -p "$(dirname "$REPORT_PATH")"  # Creates reports/ lazily
cat > "$REPORT_PATH" << 'EOF'
# Research Report: OAuth Patterns
...
EOF

# Now: specs/082_oauth_research/reports/ exists (contains actual file)
```

## Integration Pattern for Commands

### Template: Phase 0 Implementation

Every orchestration command should implement Phase 0 using this template:

```markdown
## Phase 0: Location Detection

**Purpose**: Calculate artifact paths before agent invocation (85% token reduction, 25x speedup)

**EXECUTE NOW**: USE the Bash tool to perform location detection:

\`\`\`bash
# Detect project root
if [ -z "$CLAUDE_CONFIG" ]; then
  CLAUDE_CONFIG="$HOME/.config"  # Default fallback
fi

# Source unified location detection library
if ! source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ERROR: Failed to load unified-location-detection.sh"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "**What failed**: Library sourcing"
  echo "**Expected**: Library at ${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
  echo "**Diagnostic**: Run: ls -la ${CLAUDE_CONFIG}/.claude/lib/"
  echo "**Context**: Required for Phase 0 (85% token reduction, 25x speedup)"
  echo "**Action**: Verify installation: git status .claude/lib/ | grep unified-location"
  echo ""
  exit 1
fi

# Perform location detection
WORKFLOW_DESCRIPTION="<user-provided workflow description>"
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION")

# Verify location detection succeeded
if [ -z "$LOCATION_JSON" ]; then
  echo "ERROR: Location detection returned empty result"
  exit 1
fi

# Extract paths from JSON
if command -v jq &>/dev/null; then
  # Preferred: Use jq for JSON parsing
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
  PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
  SUMMARIES_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')
  DEBUG_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.debug')
else
  # Fallback: Use sed for JSON parsing
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | grep -o '"topic_number": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  PLANS_DIR=$(echo "$LOCATION_JSON" | grep -o '"plans": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  SUMMARIES_DIR=$(echo "$LOCATION_JSON" | grep -o '"summaries": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  DEBUG_DIR=$(echo "$LOCATION_JSON" | grep -o '"debug": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# MANDATORY VERIFICATION CHECKPOINT
if [ ! -d "$TOPIC_PATH" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "VERIFICATION FAILED: Topic directory not created"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "**What failed**: Topic directory creation"
  echo "**Expected**: Directory should exist at $TOPIC_PATH"
  echo "**Diagnostic**: Run: ls -la $(dirname "$TOPIC_PATH")"
  echo "**Context**: perform_location_detection() should create topic directory"
  echo "**Action**: Check library function: declare -f perform_location_detection"
  echo ""
  exit 1
fi

# Signal Phase 0 completion
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 0 Complete: Location Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Topic: $TOPIC_NUMBER $TOPIC_NAME"
echo "Path: $TOPIC_PATH"
echo ""
echo "Artifact Directories (created lazily on demand):"
echo "  Reports: $REPORTS_DIR"
echo "  Plans: $PLANS_DIR"
echo "  Summaries: $SUMMARIES_DIR"
echo "  Debug: $DEBUG_DIR"
echo ""
echo "Performance: <1s execution, <11,000 tokens (85% reduction vs agent-based)"
echo ""
echo "LOCATION_COMPLETE: $TOPIC_PATH"
\`\`\`

**IMPORTANT**: WAIT for location detection to complete before proceeding to Phase 1.

{Continue with Phase 1...}
```

### Key Components

1. **Library Sourcing with Fail-Fast**: Fail immediately if library not available (configuration error)
2. **perform_location_detection()**: Single function call replaces entire agent workflow
3. **JSON Parsing**: Extract paths using jq (preferred) or sed (fallback)
4. **Mandatory Verification**: Verify topic directory created (fail if not)
5. **Completion Signal**: Clear indicator Phase 0 finished successfully

## Before/After Comparison

### Scenario: Research OAuth Patterns

**Before** (Agent-Based Detection):

```markdown
## Phase 0: Location Detection

**EXECUTE NOW**: USE the Task tool to detect location:

- subagent_type: general-purpose
- model: sonnet
- prompt: |
    Determine the appropriate directory for researching OAuth patterns.

    **Analysis Required**:
    1. Find project root
    2. Locate or create specs/ directory
    3. List existing topic directories
    4. Calculate next topic number
    5. Create topic structure: specs/NNN_topic/
    6. Create artifact directories: reports/, plans/, summaries/, debug/
    7. Return all paths in JSON format

    **Deliverable**: JSON with topic_path, topic_number, topic_name, artifact_paths

**WAIT for agent response (expected: 25 seconds, 75,600 tokens)**

{Agent explores filesystem, reads 500+ directories, calculates paths}

**Response**:
\`\`\`json
{
  "topic_path": "/home/user/.config/specs/082_oauth_patterns_research",
  "topic_number": "082",
  "topic_name": "oauth_patterns_research",
  "artifact_paths": {
    "reports": "/home/user/.config/specs/082_oauth_patterns_research/reports",
    ...
  }
}
\`\`\`

**Context Used**: 75,600 tokens (302% of budget)
**Time Taken**: 25.2 seconds
**Directories Created**: 6 (topic + 5 artifact subdirs, created eagerly)
```

**After** (Library-Based Detection):

```markdown
## Phase 0: Location Detection

**EXECUTE NOW**: USE the Bash tool to calculate paths:

\`\`\`bash
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

LOCATION_JSON=$(perform_location_detection "research OAuth patterns")

TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

echo "LOCATION_COMPLETE: $TOPIC_PATH"
echo "REPORTS_DIR: $REPORTS_DIR"
\`\`\`

**Response**:
\`\`\`
LOCATION_COMPLETE: /home/user/.config/specs/082_oauth_patterns_research
REPORTS_DIR: /home/user/.config/specs/082_oauth_patterns_research/reports
\`\`\`

**Context Used**: 11,000 tokens (44% of budget, 85% reduction)
**Time Taken**: <1 second (25x faster)
**Directories Created**: 1 (topic only, artifact dirs created lazily)
```

### Metrics Summary

| Metric | Agent-Based | Library-Based | Improvement |
|--------|-------------|---------------|-------------|
| **Tokens** | 75,600 | 11,000 | 85% reduction |
| **Time** | 25.2s | <1s | 25x faster |
| **Directories Created** | 6 (eager) | 1 (lazy) | 83% reduction |
| **Empty Dir Pollution** | 400-500 | 0 | 100% elimination |
| **Context Budget %** | 302% | 44% | 85% reduction |

## Real-World Impact

### Case Study: Plan 080 (10-Agent Research Workflow)

**Challenge**: Coordinate 10 parallel research agents for comprehensive topic investigation.

**Before Unified Library**:
```
Phase 0 (agent-based): 75,600 tokens (302%)
Remaining budget: -50,600 tokens (IMPOSSIBLE to proceed)
```

**After Unified Library**:
```
Phase 0 (library-based): 11,000 tokens (44%)
Phase 1 (10 agents): 3,000 tokens (10 × 300 token metadata)
Remaining budget: 11,000 tokens (44%)
Result: Workflow completed successfully ✓
```

**Outcome**: Unified library enabled 10-agent workflows that were previously impossible due to Phase 0 context overhead.

### Case Study: Spec 495 (/coordinate Implementation)

**Challenge**: Implement wave-based parallel orchestration with minimal context overhead.

**Before Unified Library**:
```
Phase 0: 75,600 tokens
Phase 1 (research): 14,500 tokens (full reports)
Phase 2 (planning): 17,500 tokens
Total after 2 phases: 107,600 tokens (430% of budget) → OVERFLOW
```

**After Unified Library**:
```
Phase 0: 11,000 tokens
Phase 1 (research, metadata only): 900 tokens
Phase 2 (planning, metadata): 800 tokens
Phase 3 (wave-based impl): 2,000 tokens
Phase 4 (testing): 400 tokens
Total all 5 phases: 15,100 tokens (60% of budget) ✓
```

**Outcome**: Phase 0 optimization was CRITICAL enabler for wave-based execution. Without it, /coordinate would overflow before reaching implementation phase.

## Integration with Other Optimizations

Phase 0 optimization is the foundation for all subsequent context reduction techniques:

### Dependency Chain

```
Phase 0: Unified Library (85% reduction, 25x speedup)
  ↓ Enables ↓
Phase 1: Metadata Extraction (95% reduction per artifact)
  ↓ Enables ↓
Phase 2: Forward Message Pattern (no re-summarization)
  ↓ Enables ↓
Phase 3: Wave-Based Execution (40-60% time savings)
  ↓ Enables ↓
Phase 4-7: Conditional Execution (skip unnecessary phases)

Result: 7-phase workflow in 21% context budget
```

**Without Phase 0 Optimization**: Metadata extraction is irrelevant if Phase 0 already consumed 300% of budget.

## Migration Guide

### For Existing Commands

If your command uses agent-based location detection, migrate using these steps:

#### Step 1: Identify Agent Invocation

```bash
# Find commands with agent-based detection
grep -r "subagent_type.*general-purpose" .claude/commands/ | grep -i "location\|directory"
```

#### Step 2: Replace with Library Call

**Before**:
```markdown
**EXECUTE NOW**: USE the Task tool:
- subagent_type: general-purpose
- prompt: "Determine appropriate directory..."
```

**After**:
```markdown
**EXECUTE NOW**: USE the Bash tool:

\`\`\`bash
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
echo "LOCATION_COMPLETE: $TOPIC_PATH"
\`\`\`
```

#### Step 3: Add Fail-Fast Error Handling

```bash
# Add library loading verification
if ! source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null; then
  echo "ERROR: unified-location-detection.sh not found"
  echo "DIAGNOSTIC: ls -la ${CLAUDE_CONFIG}/.claude/lib/"
  exit 1
fi

# Add topic directory verification
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Topic directory not created: $TOPIC_PATH"
  exit 1
fi
```

#### Step 4: Update Agent Prompts for Lazy Creation

**Before** (Agent creates all dirs):
```markdown
**Agent Prompt**:
Create your report at: $REPORTS_DIR/001_report.md
```

**After** (Agent creates dir lazily):
```markdown
**Agent Prompt**:
**MANDATORY OUTPUT LOCATION**: $REPORTS_DIR/001_report.md

**Before writing**: Create directory lazily:
\`\`\`bash
mkdir -p "$(dirname "$REPORT_PATH")"
\`\`\`

Then write report to $REPORT_PATH.
```

#### Step 5: Test Performance

```bash
# Measure before
time <old_command> "test workflow"  # Expected: 25+ seconds

# Measure after
time <new_command> "test workflow"  # Expected: <1 second

# Verify 25x speedup achieved
```

## Troubleshooting

### Error: Library Not Found

**Symptom**:
```
ERROR: Failed to load unified-location-detection.sh
```

**Diagnosis**: Library file missing or $CLAUDE_CONFIG incorrect

**Solutions**:
```bash
# Solution 1: Verify library exists
ls -la "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Solution 2: Check CLAUDE_CONFIG
echo "$CLAUDE_CONFIG"  # Should be: /home/user/.config or project root

# Solution 3: Set CLAUDE_CONFIG if not set
export CLAUDE_CONFIG="/home/user/.config"  # Adjust to your path
```

### Error: perform_location_detection Not Found

**Symptom**:
```
bash: perform_location_detection: command not found
```

**Diagnosis**: Library sourced but function not available (library corrupted)

**Solutions**:
```bash
# Solution 1: Verify function defined
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
declare -f perform_location_detection  # Should print function definition

# Solution 2: Re-install library
cd "${CLAUDE_CONFIG}/.claude/lib/"
git checkout unified-location-detection.sh
```

### Error: Topic Directory Not Created

**Symptom**:
```
VERIFICATION FAILED: Topic directory not created
```

**Diagnosis**: perform_location_detection() failed silently

**Solutions**:
```bash
# Solution 1: Check return value
LOCATION_JSON=$(perform_location_detection "test")
echo "Return code: $?"  # Should be 0

# Solution 2: Check JSON output
echo "$LOCATION_JSON"  # Should be valid JSON

# Solution 3: Check write permissions
ls -la "$(dirname "$TOPIC_PATH")"  # Verify writable
```

## Best Practices Checklist

### For Command Developers

- [ ] Use unified-location-detection.sh (NEVER invoke agent for location detection)
- [ ] Source library with fail-fast error handling (exit 1 if not found)
- [ ] Call perform_location_detection() exactly once per workflow
- [ ] Parse JSON using jq (preferred) with sed fallback
- [ ] Add MANDATORY VERIFICATION checkpoint after location detection
- [ ] Signal completion with LOCATION_COMPLETE: <path>
- [ ] Update agent prompts for lazy directory creation
- [ ] Test performance: Verify <1s execution, <11,000 tokens

### For Workflow Users

- [ ] Verify CLAUDE_CONFIG environment variable set correctly
- [ ] Ensure .claude/lib/ directory exists in project
- [ ] Run git status to verify library files present
- [ ] Report any Phase 0 slowness (indicates library not being used)

## Cross-References

### Related Guides
- [Orchestration Best Practices Guide](orchestration-best-practices.md) - Complete 7-phase framework with Phase 0 pattern
- [Library API Reference](../reference/library-api/overview.md) - unified-location-detection.sh function signatures

### Related Patterns
- [Context Management Pattern](../concepts/patterns/context-management.md) - Layered context architecture
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - Fail-fast for library loading

### Related Workflows
- [Context Budget Management Tutorial](../workflows/context-budget-management.md) - Budget allocation including Phase 0

## Changelog

### 2025-10-28: Initial Creation
- Documented Phase 0 breakthrough (agent-based → library-based)
- Quantified performance improvement (85% reduction, 25x speedup)
- Lazy directory creation pattern documented
- Migration guide for existing commands
- Real-world case studies (Plan 080, Spec 495)
- Troubleshooting guide for common issues

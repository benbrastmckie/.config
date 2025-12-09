# Research Coordinator Migration Guide

Complete guide for migrating commands from direct research-specialist invocation to research-coordinator pattern.

## Overview

This guide provides step-by-step instructions for integrating the research-coordinator pattern into planning commands (`/create-plan`, `/research`, `/repair`, `/debug`, `/revise`).

**Target Audience**: Command developers migrating existing commands or implementing new research workflows

**Prerequisites**:
- Existing command uses research-specialist directly (Pattern 1)
- Research complexity ≥ 3 (indicates multi-topic scenarios)
- Familiarity with hard barrier pattern and state persistence

**Migration Benefits**:
- **95% Context Reduction**: Metadata-only passing (7,500 → 330 tokens for 3 topics)
- **40-60% Time Savings**: Parallel execution vs sequential research
- **Improved Quality**: Focused research per topic vs single broad report

---

## Table of Contents

1. [Prerequisites Check](#prerequisites-check)
2. [Migration Steps](#migration-steps)
3. [Testing Checklist](#testing-checklist)
4. [Rollback Procedure](#rollback-procedure)
5. [Reference Implementation](#reference-implementation)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites Check

Before migrating, verify your command meets these requirements:

### Required Components

- [ ] Command has RESEARCH_COMPLEXITY variable (1-4 scale)
- [ ] Command uses state persistence (state-persistence.sh sourced)
- [ ] Command has hard barrier pattern (path pre-calculation → validation)
- [ ] Command invokes research-specialist via Task tool
- [ ] Command has TOPIC_PATH or equivalent directory structure

### Optional Components (Enable Advanced Features)

- [ ] topic-detection-agent integration (automated decomposition for complexity ≥ 3)
- [ ] Multi-report metadata extraction (for downstream agent context)
- [ ] Graceful fallback (single-topic mode when decomposition fails)

### Complexity Assessment

Determine if migration is appropriate:

| Current State | Should Migrate? | Reason |
|--------------|----------------|--------|
| Complexity 1-2, single topic | **No** | Coordinator adds overhead without benefit |
| Complexity 3-4, multi-domain prompts | **Yes** | Enables parallelization and context reduction |
| Lean/Mathlib domain-specific | **No** | Use specialized lean-research-specialist |
| Error analysis (multi-pattern) | **Yes** | /repair, /debug benefit from topic decomposition |

See [Research Invocation Standards](../../reference/standards/research-invocation-standards.md) for complete decision matrix.

---

## Migration Steps

### Step 1: Add Topic Decomposition Block

Insert new Block 1d-topics after existing topic path initialization block.

**Location**: After Block 1c (topic path calculation) or Block 1d (existing research setup)

**Template**: See [Command Patterns Quick Reference - Template 6](../../reference/command-patterns-quick-reference.md#template-6-topic-decomposition-block-heuristic-based)

**Implementation**:

```markdown
## Block 1d-topics: Topic Decomposition

**EXECUTE NOW**: Analyze feature description and decompose into research topics:

```bash
set +H
# Source state persistence for saving topics
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

# Read state for feature description and complexity
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Determine topic count based on complexity
case $RESEARCH_COMPLEXITY in
  1|2) TOPIC_COUNT=1 ;;  # Single topic
  3) TOPIC_COUNT=3 ;;    # 2-3 topics
  4) TOPIC_COUNT=4 ;;    # 4-5 topics
  *) TOPIC_COUNT=2 ;;    # Default
esac

# Heuristic decomposition: Check for multi-topic indicators
MULTI_TOPIC_INDICATORS=0
if echo "$FEATURE_DESCRIPTION" | grep -qE '\band\b|\bor\b|,'; then
  ((MULTI_TOPIC_INDICATORS++))
fi
if [ "$RESEARCH_COMPLEXITY" -ge 3 ]; then
  ((MULTI_TOPIC_INDICATORS++))
fi

# If no multi-topic indicators, fall back to single topic
if [ "$MULTI_TOPIC_INDICATORS" -lt 2 ]; then
  TOPIC_COUNT=1
  echo "Single-topic mode: No multi-topic indicators found"
fi

# Simple topic decomposition (split by conjunctions or use full description)
if [ "$TOPIC_COUNT" -eq 1 ]; then
  TOPICS_LIST="$FEATURE_DESCRIPTION"
else
  # Split by " and ", " or ", or commas (heuristic)
  TOPICS_LIST=$(echo "$FEATURE_DESCRIPTION" | sed 's/ and /|/g; s/ or /|/g; s/, /|/g')
fi

# Pre-calculate report paths (hard barrier pattern)
RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"

# Find existing reports to determine starting number
EXISTING_REPORTS=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)
START_NUM=$((EXISTING_REPORTS + 1))

# Calculate paths for each topic
REPORT_PATHS_LIST=""
IFS='|' read -ra TOPICS_ARRAY <<< "$TOPICS_LIST"
for i in "${!TOPICS_ARRAY[@]}"; do
  REPORT_NUM=$(printf "%03d" $((START_NUM + i)))
  TOPIC_SLUG=$(echo "${TOPICS_ARRAY[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md"

  if [ -z "$REPORT_PATHS_LIST" ]; then
    REPORT_PATHS_LIST="$REPORT_PATH"
  else
    REPORT_PATHS_LIST="${REPORT_PATHS_LIST}|${REPORT_PATH}"
  fi
done

# Persist to state for coordinator and validation
append_workflow_state "TOPICS_LIST" "$TOPICS_LIST"
append_workflow_state "REPORT_PATHS_LIST" "$REPORT_PATHS_LIST"
append_workflow_state "TOPIC_COUNT" "${#TOPICS_ARRAY[@]}"

echo "[CHECKPOINT] Topic decomposition complete"
echo "Context: TOPIC_COUNT=${#TOPICS_ARRAY[@]}, TOPICS_LIST=${TOPICS_LIST}"
echo "Ready for: Research coordinator invocation"
```
\```

**Key Changes from Existing Code**:
- Replaces single REPORT_PATH with REPORT_PATHS_LIST (pipe-separated)
- Adds topic decomposition logic based on RESEARCH_COMPLEXITY
- Pre-calculates all report paths BEFORE coordinator invocation
- Persists TOPICS_LIST and REPORT_PATHS_LIST to state

---

### Step 2: Replace research-specialist with research-coordinator

**Locate**: Existing research-specialist Task invocation block

**Before** (Pattern 1: Direct research-specialist):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research feature for planning"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Input Contract**:
    research_request: "${FEATURE_DESCRIPTION}"
    research_complexity: ${RESEARCH_COMPLEXITY}
    report_path: ${REPORT_PATH}

    Create research report at ${REPORT_PATH}.
    Return: RESEARCH_COMPLETE: ${REPORT_PATH}
}
```

**After** (Pattern 2: research-coordinator):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research across multiple topics"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are acting as a Research Coordinator Agent with the tools and constraints
    defined in that file.

    **Input Contract (Mode 2: Pre-Decomposed)**:
    research_request: "${FEATURE_DESCRIPTION}"
    research_complexity: ${RESEARCH_COMPLEXITY}
    report_dir: ${RESEARCH_DIR}
    topics: ${TOPICS_LIST}
    report_paths: ${REPORT_PATHS_LIST}

    The topics are pipe-separated (|) strings. Parse and delegate to research-specialist
    for each topic in parallel. Create reports at the pre-calculated paths.

    Return: RESEARCH_COMPLETE: {REPORT_COUNT}
}
```

**Key Changes**:
- Agent file: `research-specialist.md` → `research-coordinator.md`
- Contract mode: Single report → Mode 2 (Pre-Decomposed)
- Input: `report_path` → `topics` + `report_paths` (pipe-separated)
- Return: Single path → Report count

---

### Step 3: Update Validation to Multi-Report Loop

**Locate**: Existing report validation block (usually Block 1e or 1f)

**Before** (Single-report validation):
```bash
# Validate research report exists
if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: Research report not found at $REPORT_PATH" >&2
  exit 1
fi

# Check minimum size
FILE_SIZE=$(stat -c%s "$REPORT_PATH" 2>/dev/null)
if [ "$FILE_SIZE" -lt 100 ]; then
  echo "ERROR: Report too small" >&2
  exit 1
fi
```

**After** (Multi-report validation loop):
```bash
# Parse report paths (pipe-separated)
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"

# Validate each report (hard barrier - fail-fast)
TOTAL_REPORTS=${#REPORT_PATHS_ARRAY[@]}
VALID_REPORTS=0

for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "Validating: $REPORT_PATH"

  # File existence check
  if [ ! -f "$REPORT_PATH" ]; then
    echo "ERROR: Report not found at $REPORT_PATH" >&2
    echo "HARD BARRIER FAILED: research-coordinator did not create all reports" >&2
    exit 1
  fi

  # Minimum size check (100 bytes)
  FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH" 2>/dev/null)
  if [ "$FILE_SIZE" -lt 100 ]; then
    echo "ERROR: Report at $REPORT_PATH too small ($FILE_SIZE bytes)" >&2
    exit 1
  fi

  # Content check (must have Findings section)
  if ! grep -q "## Findings" "$REPORT_PATH"; then
    echo "WARNING: Report at $REPORT_PATH missing Findings section" >&2
  fi

  ((VALID_REPORTS++))
done

echo "[CHECKPOINT] Multi-report validation complete"
echo "Context: VALID_REPORTS=${VALID_REPORTS}/${TOTAL_REPORTS}"
echo "Ready for: Metadata extraction"
```

**Key Changes**:
- Loops through REPORT_PATHS_ARRAY instead of validating single path
- Fail-fast on ANY missing or invalid report (hard barrier)
- Counts valid reports for logging
- Cross-platform stat compatibility (macOS vs Linux)

**Template**: See [Command Patterns Quick Reference - Template 9](../../reference/command-patterns-quick-reference.md#template-9-multi-report-validation-loop)

---

### Step 4: (Optional) Add Metadata Extraction

If downstream agents need research context, extract metadata summaries instead of passing full reports.

**Add New Block**: Block 1f-metadata (after validation block)

**Template**: See [Command Patterns Quick Reference - Template 10](../../reference/command-patterns-quick-reference.md#template-10-metadata-extraction-and-aggregation)

**Benefits**:
- **95% Context Reduction**: 2,500 → 110 tokens per report
- **Faster Downstream Agents**: Less content to process
- **Preserved Quality**: plan-architect can still read full reports via paths

**When to Skip**:
- Command terminates after research (e.g., `/research` standalone)
- Downstream agent doesn't need research context
- Full reports passed to terminal output only

---

### Step 5: Update Frontmatter dependent-agents

**Locate**: Frontmatter section at top of command file

**Before**:
```yaml
dependent-agents:
  - research-specialist
  - plan-architect
```

**After**:
```yaml
dependent-agents:
  - research-coordinator
  - topic-detection-agent  # Optional: if using automated decomposition
  - plan-architect
```

**Key Changes**:
- Replace `research-specialist` with `research-coordinator`
- research-specialist is now transitive dependency (invoked by coordinator)
- Add `topic-detection-agent` if using Template 7 (automated decomposition)

**Uniformity Rule**: List only directly invoked agents (via Task tool in command), not transitive dependencies.

See [Research Invocation Standards - Dependent-Agents Standards](../../reference/standards/research-invocation-standards.md#uniformity-requirements)

---

### Step 6: (Optional) Add Automated Topic Detection

For complexity ≥ 3, consider adding topic-detection-agent for improved decomposition quality.

**Insert**: New Block 1d-topics-auto (before Block 1d-topics, conditional execution)

**Template**: See [Command Patterns Quick Reference - Template 7](../../reference/command-patterns-quick-reference.md#template-7-topic-detection-agent-invocation-block-automated)

**Benefits**:
- More accurate topic decomposition (semantic analysis vs heuristics)
- Consistent topic naming across workflows
- Cost-optimized (Haiku model for detection, Sonnet for research)

**Tradeoffs**:
- Adds one more agent invocation (small latency increase)
- Requires graceful fallback if detection fails
- May not improve quality for very clear prompts

**When to Use**:
- Complexity ≥ 3 (multi-topic scenarios)
- Ambiguous or complex feature descriptions
- Commands where decomposition quality is critical

---

## Testing Checklist

After migration, verify all scenarios work correctly:

### Unit Testing (Single Invocation)

- [ ] **Single-topic fallback** (complexity 1-2):
  ```bash
  /COMMAND "Simple focused feature" --complexity 2
  # Should create 1 report, bypass coordinator overhead
  ```

- [ ] **Multi-topic decomposition** (complexity 3):
  ```bash
  /COMMAND "Feature A, Feature B, and Feature C" --complexity 3
  # Should create 2-3 reports via coordinator
  ```

- [ ] **Comprehensive analysis** (complexity 4):
  ```bash
  /COMMAND "Complex multi-domain feature with many concerns" --complexity 4
  # Should create 4-5 reports via coordinator
  ```

### Integration Testing (Multi-Block Flow)

- [ ] **Topic decomposition persists to state**:
  ```bash
  # After Block 1d-topics, verify state file contains TOPICS_LIST
  cat ~/.claude/data/state/$WORKFLOW_ID.sh | grep TOPICS_LIST
  ```

- [ ] **Report paths pre-calculated correctly**:
  ```bash
  # Verify REPORT_PATHS_LIST in state
  cat ~/.claude/data/state/$WORKFLOW_ID.sh | grep REPORT_PATHS_LIST
  ```

- [ ] **Multi-report validation fails fast**:
  ```bash
  # Simulate missing report by removing file mid-execution
  # Should fail with "HARD BARRIER FAILED" error
  ```

- [ ] **Metadata extraction counts correct**:
  ```bash
  # Verify TOTAL_FINDINGS and TOTAL_RECOMMENDATIONS in state
  cat ~/.claude/data/state/$WORKFLOW_ID.sh | grep TOTAL_
  ```

### Error Handling Testing

- [ ] **Topic decomposition returns empty** → Falls back to single-topic mode
- [ ] **topic-detection-agent fails** → Falls back to heuristic decomposition
- [ ] **research-coordinator fails** → Hard barrier validation fails, error logged
- [ ] **Metadata extraction fails** → Uses filename as title fallback

### Performance Testing

- [ ] **Context reduction measured**:
  ```bash
  # Compare token usage before/after migration
  # Expected: 40-60% reduction with metadata-only passing
  ```

- [ ] **Parallel execution time**:
  ```bash
  # Time multi-topic research
  time /COMMAND "Multi-topic feature" --complexity 3
  # Expected: 40-60% faster than sequential baseline
  ```

### Regression Testing

- [ ] **Existing single-topic scenarios still work** (backward compatibility)
- [ ] **Plan quality maintained** (metadata-only input doesn't degrade planning)
- [ ] **Hard barrier pattern still enforced** (fail-fast on missing artifacts)

---

## Rollback Procedure

If migration causes issues, follow this rollback sequence:

### Immediate Rollback (Emergency)

1. **Revert command file** to git HEAD:
   ```bash
   git checkout HEAD -- .claude/commands/COMMAND.md
   ```

2. **Clear state files**:
   ```bash
   rm -rf ~/.claude/data/state/*.sh
   ```

3. **Test reverted command**:
   ```bash
   /COMMAND "Test feature" --complexity 2
   # Verify original behavior restored
   ```

### Partial Rollback (Keep Some Changes)

**Scenario 1: Disable automated topic detection only**
- Comment out Block 1d-topics-auto
- Use heuristic decomposition (Block 1d-topics) only
- Remove topic-detection-agent from dependent-agents

**Scenario 2: Disable coordinator, keep decomposition**
- Revert Block 1e-exec to research-specialist
- Change contract to single report_path (first topic only)
- Keep topic decomposition for future migration

**Scenario 3: Disable metadata extraction only**
- Comment out Block 1f-metadata
- Pass full report paths to downstream agent (no metadata summary)
- Accept higher context usage temporarily

### Post-Rollback Actions

1. **Document failure mode** in hierarchical-agents-troubleshooting.md
2. **Create issue** for debugging and retry
3. **Notify team** if command is shared across workflows

---

## Reference Implementation

### /create-plan (Complete Migration Example)

See `/home/benjamin/.config/.claude/commands/create-plan.md` for fully migrated command:

**Blocks Added**:
1. Block 1d-topics: Topic Decomposition (heuristic)
2. Block 1d-topics-auto: Topic Detection Agent (automated, optional)
3. Block 1e-exec: Research Coordinator Invocation (replaced research-specialist)
4. Block 1f: Multi-Report Validation (replaced single-report check)
5. Block 1f-metadata: Metadata Extraction (optional, for plan-architect context)

**Frontmatter Changes**:
- Added `research-coordinator` to dependent-agents
- Added `topic-detection-agent` to dependent-agents
- Removed `research-specialist` (transitive dependency)

**Testing Results**:
- Single-topic scenarios: Works (fallback to complexity 1-2)
- Multi-topic scenarios: Works (3 reports created in parallel)
- Automated detection: Works (topic-detection-agent invoked for complexity ≥ 3)
- Context reduction: 95% measured (7,500 → 330 tokens for 3 topics)

### /research (Simplified Migration Example)

See `/home/benjamin/.config/.claude/commands/research.md` for simpler migration (no downstream agent):

**Blocks Added**:
1. Block 1d-topics: Topic Decomposition (heuristic only, no automated)
2. Block 1e-exec: Research Coordinator Invocation
3. Block 1f: Multi-Report Validation

**Blocks Skipped**:
- Metadata extraction (not needed, /research terminates after research phase)
- Automated topic detection (complexity usually set manually)

**Testing Results**:
- Multi-topic scenarios: Works (2-3 reports created)
- Parallel execution: 61% time savings measured (180 → 70 seconds for 3 topics)

---

## Troubleshooting

### Issue: Topic decomposition returns empty array

**Symptoms**:
- TOPICS_LIST variable is empty or contains only whitespace
- TOPIC_COUNT is 0
- Fallback to single-topic mode fails

**Causes**:
1. FEATURE_DESCRIPTION not set in state
2. Heuristic logic too strict (no conjunctions detected)
3. sed command fails due to special characters

**Solutions**:
1. Verify FEATURE_DESCRIPTION persisted to state before Block 1d-topics
2. Adjust heuristic thresholds (lower MULTI_TOPIC_INDICATORS requirement)
3. Escape special characters in sed patterns
4. Add debug logging: `echo "FEATURE_DESCRIPTION=${FEATURE_DESCRIPTION}" >&2`

**Prevention**:
- Always fall back to single-topic mode if TOPIC_COUNT < 2
- Log decomposition results for debugging
- Test with various feature description formats

---

### Issue: topic-detection-agent fails or returns malformed JSON

**Symptoms**:
- TOPICS_JSON_PATH file not found
- jq parsing fails with syntax error
- TOPICS_LIST empty after parsing

**Causes**:
1. topic-detection-agent timeout (complex analysis)
2. JSON output truncated or malformed
3. File path mismatch (agent wrote to wrong location)

**Solutions**:
1. Check agent output for error messages
2. Validate JSON with `jq . "$TOPICS_JSON_PATH"` before parsing
3. Fall back to heuristic decomposition (Template 6 logic)
4. Increase timeout if needed (add to agent prompt)

**Prevention**:
- Always implement graceful fallback to heuristic decomposition
- Validate JSON structure before parsing
- Log topic-detection-agent errors to error-handling.sh

**Fallback Pattern**:
```bash
if [ ! -f "$TOPICS_JSON_PATH" ]; then
  echo "WARNING: Topic detection failed, falling back to heuristic decomposition" >&2
  # Execute Template 6 logic here
fi
```

---

### Issue: research-coordinator reports missing (hard barrier failure)

**Symptoms**:
- Multi-report validation fails with "Report not found"
- One or more REPORT_PATH files do not exist
- Hard barrier error: "research-coordinator did not create all reports"

**Causes**:
1. research-coordinator invocation failed (agent error)
2. Path mismatch (coordinator wrote to different location)
3. Parallel execution timeout (some research-specialist workers hung)
4. File system permissions (cannot write to RESEARCH_DIR)

**Solutions**:
1. Check error logs: `/errors --command /COMMAND --type agent_error`
2. Verify REPORT_PATHS_LIST matches coordinator contract
3. Check RESEARCH_DIR permissions: `ls -ld $RESEARCH_DIR`
4. Verify coordinator received correct inputs (log agent prompt)

**Prevention**:
- Validate REPORT_PATHS_LIST persisted to state before invocation
- Use absolute paths (not relative)
- Ensure RESEARCH_DIR created with `mkdir -p`
- Test coordinator isolation with single-topic scenario first

**Debug Commands**:
```bash
# Check state file for paths
cat ~/.claude/data/state/$WORKFLOW_ID.sh | grep REPORT_PATHS_LIST

# Check research directory
ls -la $RESEARCH_DIR/

# Check error logs
/errors --command /create-plan --since 1h --type agent_error
```

---

### Issue: Metadata extraction parsing errors

**Symptoms**:
- TOTAL_FINDINGS count is 0 despite report having findings
- METADATA_SUMMARY variable empty
- grep/sed commands fail with errors

**Causes**:
1. Report structure differs from expected (no "## Findings" section)
2. Findings use different bullet format (not "- " prefix)
3. sed command syntax errors on macOS vs Linux

**Solutions**:
1. Use filename as title fallback: `basename "$REPORT_PATH" .md`
2. Adjust section regex to match actual report format
3. Use cross-platform sed syntax (avoid GNU extensions)
4. Log parsing errors with details

**Prevention**:
- Standardize report structure in research-specialist behavioral file
- Test metadata extraction on sample reports before rollout
- Use portable shell commands (avoid bashisms in sed/grep)

**Fallback Pattern**:
```bash
# Extract title with fallback
TITLE=$(grep -m 1 "^# " "$REPORT_PATH" | sed 's/^# //' || basename "$REPORT_PATH" .md)

# Count findings with fallback to 0
FINDINGS_COUNT=$(sed -n '/## Findings/,/^##/p' "$REPORT_PATH" | grep -c "^- " || echo 0)
```

---

### Issue: Plan quality regression with metadata-only input

**Symptoms**:
- plan-architect produces lower-quality plans after migration
- Plans missing key details from research reports
- User reports degraded planning output

**Causes**:
1. plan-architect not reading full reports despite receiving paths
2. Metadata summary insufficient for planning context
3. plan-architect behavioral file needs update for metadata handling

**Solutions**:
1. Update plan-architect prompt to explicitly read full reports via paths
2. Enrich metadata summary with more details (increase token target)
3. Test plan quality with A/B comparison (before/after migration)
4. Rollback if quality regression confirmed

**Prevention**:
- Include "Read full reports as needed" instruction in plan-architect prompt
- Test plan quality in migration testing phase
- Measure plan quality metrics (phase count, task detail, completeness)

**Quality Validation**:
```bash
# Compare plan before/after migration
diff <(grep "^## Phase" old_plan.md) <(grep "^## Phase" new_plan.md)

# Check plan completeness
grep -c "^- \[" new_plan.md  # Task count
grep -c "^## Phase" new_plan.md  # Phase count
```

---

### Issue: research-coordinator returns empty reports directory

**Symptoms**:
- STEP 4 validation fails with "Reports directory is empty - no reports created"
- No research-specialist invocation logs visible in output
- Invocation trace file missing at `$REPORT_DIR/.invocation-trace.log`

**Root Cause**:
Agent interpreted Task invocation patterns in STEP 3 as documentation rather than executable directives.

**Diagnostic Commands**:
```bash
# Check for empty directory validation error
grep "Reports directory is empty" ~/.claude/output/create-plan-output.md

# Verify execution enforcement markers present in behavioral file
grep -c "EXECUTE NOW - DO NOT SKIP" ~/.config/.claude/agents/research-coordinator.md
# Should return: 3 or more

# Check for invocation trace file
ls -la "$REPORT_DIR/.invocation-trace.log" 2>/dev/null || echo "Trace file not found - Task invocations did not execute"
```

**Solutions**:
1. **Update behavioral file** with execution enforcement markers (if not already present)
2. **Verify STEP 3.5 self-validation checkpoint** exists in `research-coordinator.md`
3. **Run integration test** to confirm fixes: `bash ~/.config/.claude/tests/integration/test_research_coordinator_invocation.sh`
4. **Check empty directory diagnostic output** for structured error information

**Prevention**:
- Ensure research-coordinator.md updated with latest execution enforcement markers (as of 2025-12-09)
- Use "(EXECUTE)" suffix in all STEP headers
- Separate command-author reference documentation from agent execution instructions
- Include "File Structure (Read This First)" section in behavioral file

**Resolution**:
This issue was addressed in spec 037 with comprehensive execution enforcement markers, empty directory validation, and invocation trace logging. If using an older version of research-coordinator.md, update to the latest version.

**Reference**: See [Hierarchical Agents Troubleshooting - Issue 16.5](../../concepts/hierarchical-agents-troubleshooting.md#issue-165-research-coordinator-task-invocations-not-executing-empty-reports-directory)

---

## Related Documentation

### Standards
- [Research Invocation Standards](../../reference/standards/research-invocation-standards.md) - Decision matrix for coordinator vs specialist
- [Command Authoring Standards](../../reference/standards/command-authoring.md) - Research coordinator delegation pattern section
- [Command Patterns Quick Reference](../../reference/command-patterns-quick-reference.md) - Copy-paste templates (6-10)

### Examples
- [Hierarchical Agents Examples - Example 7](../../concepts/hierarchical-agents-examples.md#example-7-research-coordinator-with-parallel-multi-topic-research) - Research coordinator pattern
- [/create-plan Reference Implementation](/home/benjamin/.config/.claude/commands/create-plan.md) - Complete migration example
- [/research Reference Implementation](/home/benjamin/.config/.claude/commands/research.md) - Simplified migration example

### Troubleshooting
- [Hierarchical Agents Troubleshooting](../../concepts/hierarchical-agents-troubleshooting.md) - Coordinator-specific issues
- [Error Handling Pattern](../../concepts/patterns/error-handling.md) - Error logging integration
- [Hard Barrier Pattern](../../concepts/patterns/hard-barrier-subagent-delegation.md) - Validation best practices

---

## Changelog

- **2025-12-08**: Initial migration guide created (Phase 7 of spec 013)
- **2025-12-08**: Added testing checklist and rollback procedures
- **2025-12-08**: Added /create-plan and /research reference implementations

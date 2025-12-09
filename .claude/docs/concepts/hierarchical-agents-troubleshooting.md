# Hierarchical Agent Architecture: Troubleshooting

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Patterns](hierarchical-agents-patterns.md) - Design patterns
- [Examples](hierarchical-agents-examples.md) - Reference implementations

---

## Common Issues

### Issue 1: 0% Agent Delegation Rate

**Symptom**: Agents are never invoked despite Task blocks in command.

**Cause**: Documentation-only YAML blocks (wrapped in code fences).

**Solution**:
```markdown
# WRONG
Example:
```yaml
Task { ... }
```

# CORRECT
**EXECUTE NOW**: Invoke agent

Task { ... }
```

**Verification**:
```bash
# Check for YAML blocks without imperative instruction
grep -B5 '```yaml' .claude/commands/*.md | grep -v 'EXECUTE NOW'
```

---

### Issue 2: Missing Files After Workflow

**Symptom**: Expected files don't exist at specified paths.

**Causes**:
1. Agent returned text instead of creating file
2. Path calculation error
3. Directory doesn't exist

**Solution**:

Add verification checkpoints:
```bash
# Verify file creation
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: File not created at $EXPECTED_PATH"
  exit 1
fi
```

Add path pre-calculation:
```bash
# Ensure directory exists
mkdir -p "$(dirname "$EXPECTED_PATH")"
```

Add agent enforcement:
```markdown
**PRIMARY OBLIGATION**: You MUST create file at exact path.
Return: CREATED: ${PATH}
```

---

### Issue 3: Context Explosion

**Symptom**: Workflow fails with context limit errors.

**Cause**: Passing full content between hierarchy levels.

**Solution**: Use metadata extraction:
```bash
# Extract metadata only
TITLE=$(grep -m1 '^# ' "$REPORT" | sed 's/^# //')
SUMMARY=$(sed -n '/^## Overview/,/^##/p' "$REPORT" | head -c 200)

# Pass metadata, not full content
echo "TITLE: $TITLE"
echo "SUMMARY: $SUMMARY"
echo "PATH: $REPORT"
```

---

### Issue 4: Sequential Instead of Parallel Execution

**Symptom**: Workflow takes 4x expected time.

**Cause**: Agents invoked sequentially.

**Solution**:
```markdown
# WRONG: Sequential
**EXECUTE**: Task 1
[wait]
**EXECUTE**: Task 2

# CORRECT: Parallel (single message)
**EXECUTE NOW**: All tasks

Task { ... task 1 ... }
Task { ... task 2 ... }
Task { ... task 3 ... }
```

---

### Issue 5: Library Sourcing Failures

**Symptom**: `command not found` errors.

**Cause**: Functions called before library sourced.

**Solution**:
```bash
# Source FIRST
source "${LIB_DIR}/verification-helpers.sh"
source "${LIB_DIR}/error-handling.sh"

# THEN call functions
verify_state_variable "VAR_NAME" || exit 1
```

**Verification**:
```bash
# Check sourcing order
grep -n 'source.*lib/' command.md | head -20
grep -n 'verify_\|handle_' command.md | head -5
# Sourcing must come before function calls
```

---

### Issue 6: Behavioral Duplication

**Symptom**: Maintenance burden, inconsistent agent behavior.

**Cause**: Agent behavior duplicated in commands.

**Detection**:
```bash
# Count STEP sequences in commands (should be <5)
grep -c 'STEP [0-9]:' .claude/commands/*.md

# Count PRIMARY OBLIGATION (should be 0)
grep -c 'PRIMARY OBLIGATION' .claude/commands/*.md
```

**Solution**:
1. Move behavior to `.claude/agents/*.md`
2. Use behavioral injection pattern in commands

---

### Issue 7: Missing Verification

**Symptom**: Silent failures, incomplete workflows.

**Cause**: No verification after agent operations.

**Solution**: Add mandatory verification:
```markdown
## Verification Checkpoint

**MANDATORY VERIFICATION**: Check all files exist

```bash
for path in "${EXPECTED_PATHS[@]}"; do
  if [ ! -f "$path" ]; then
    echo "CRITICAL: Missing $path"
    exit 1
  fi
  echo "Verified: $path"
done
```
```

---

### Issue 8: Unclear Agent Contracts

**Symptom**: Agents return unexpected formats.

**Cause**: No defined input/output contract.

**Solution**: Define explicit contracts:
```markdown
## Input Contract
- topic: string (required)
- output_path: string (required, absolute)
- thinking_mode: enum [standard, think, think_hard]

## Output Contract
- CREATED: string (file path)
- TITLE: string (max 50 chars)
- SUMMARY: string (max 200 chars)
- STATUS: enum [complete, partial, failed]
```

---

## Diagnostic Commands

### Check Agent Invocation Pattern

```bash
# Find potentially broken invocations
find .claude/commands -name '*.md' -exec \
  grep -l 'Task {' {} \; | while read f; do
    if ! grep -B3 'Task {' "$f" | grep -q 'EXECUTE NOW\|INVOKE'; then
      echo "WARN: $f may have documentation-only Task blocks"
    fi
done
```

### Check Context Usage

```bash
# Estimate context per command
for cmd in .claude/commands/*.md; do
  lines=$(wc -l < "$cmd")
  echo "$cmd: $lines lines (~$(($lines * 4)) tokens)"
done
```

### Check Behavioral Duplication

```bash
# Find behavioral content in commands
echo "STEP sequences in commands:"
grep -c 'STEP [0-9]:' .claude/commands/*.md | grep -v ':0$'

echo ""
echo "PRIMARY OBLIGATION in commands (should be 0):"
grep -l 'PRIMARY OBLIGATION' .claude/commands/*.md
```

### Check File Creation Rate

```bash
# After running workflow, verify files created
expected=("report1.md" "report2.md" "plan.md")
created=0

for file in "${expected[@]}"; do
  if [ -f "$TOPIC_DIR/$file" ]; then
    ((created++))
  else
    echo "MISSING: $file"
  fi
done

echo "Created: $created/${#expected[@]}"
```

---

## Performance Metrics

### Target Metrics

| Metric | Target | Critical |
|--------|--------|----------|
| Agent delegation rate | >90% | <50% |
| File creation rate | 100% | <80% |
| Context efficiency | >90% reduction | <50% |
| Parallel speedup | 40-60% | <20% |

### Measuring Performance

```bash
# Time sequential vs parallel
time run_sequential_workflow
time run_parallel_workflow

# Context usage
wc -c "$STATE_FILE"  # State file size
wc -l "$COMMAND"     # Command complexity
```

---

## Quick Fixes

### Fix 1: Add Missing Imperative

```bash
# Before YAML Task blocks, add:
**EXECUTE NOW**: USE the Task tool to invoke [agent-name]
```

### Fix 2: Add Missing Verification

```bash
# After agent invocation, add:
if [ ! -f "$EXPECTED" ]; then
  echo "CRITICAL: Agent didn't create $EXPECTED"
  exit 1
fi
```

### Fix 3: Fix Sourcing Order

```bash
# Move library sourcing to top of bash block
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Then use functions
verify_state_variable "NAME" || exit 1
```

### Fix 4: Enable Parallel Execution

```bash
# Send all Tasks in single message, not sequential
# Remove [wait] between Task blocks
```

---

### Issue 9: Research Coordinator Missing Reports

**Symptom**: Hard barrier validation fails with "N research reports missing after coordinator invocation".

**Causes**:
1. Report paths not pre-calculated before coordinator invocation
2. research-specialist failed to create reports (tool access issue)
3. Path mismatch (coordinator calculated different paths)
4. Directory permissions prevent file creation

**Solution 1: Verify Path Pre-Calculation** (Hard Barrier Pattern)
```bash
# Pre-calculate paths BEFORE coordinator invocation
RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"

TOPICS=("Topic 1" "Topic 2" "Topic 3")
REPORT_PATHS=()

for i in "${!TOPICS[@]}"; do
  TOPIC_SLUG=$(echo "${TOPICS[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  REPORT_NUM=$(printf "%03d" $((i + 1)))
  REPORT_PATHS+=("${RESEARCH_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md")
done

# Pass pre-calculated paths to coordinator
append_workflow_state "REPORT_PATHS" "${REPORT_PATHS[*]}"
```

**Solution 2: Add Hard Barrier Validation**
```bash
# After coordinator returns, verify ALL reports exist
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error "validation_error" \
    "${#MISSING_REPORTS[@]} research reports missing" \
    "Missing: ${MISSING_REPORTS[*]}"
  echo "ERROR: Hard barrier validation failed"
  exit 1
fi
```

**Solution 3: Verify research-specialist Tool Access**
```markdown
# Check research-specialist allowed-tools includes Write
grep 'allowed-tools:' .claude/agents/research-specialist.md

# Should include: Write, Read, Bash, Grep, Glob
```

**Diagnostic**:
```bash
# Check if reports directory exists
ls -la "$RESEARCH_DIR"

# Check report file permissions
stat "${RESEARCH_DIR}"/001-*.md 2>/dev/null || echo "No reports created"

# Verify coordinator was invoked (check output)
grep "research-coordinator" .claude/output/lean-plan-output.md
```

---

### Issue 10: Research Coordinator Context Explosion

**Symptom**: Workflow fails with context limit errors despite using research-coordinator.

**Cause**: Metadata extraction not working, coordinator returning full report content instead of metadata.

**Solution 1: Verify Metadata Format**

Check coordinator return signal format:
```
RESEARCH_COMPLETE: 3
reports: [{"path": "...", "title": "...", "findings_count": 12, "recommendations_count": 5}, ...]
total_findings: 30
total_recommendations: 15
```

**Solution 2: Verify Downstream Consumer Uses Paths**

Plan-architect should receive report paths, NOT full content:
```markdown
Task {
  prompt: |
    Read and follow: .claude/agents/lean-plan-architect.md

    **Research Context**:
    Research Reports: 3 reports created
    - /path/to/001-mathlib-theorems.md (12 findings, 5 recs)
    - /path/to/002-proof-automation.md (8 findings, 4 recs)
    - /path/to/003-project-structure.md (10 findings, 6 recs)

    **CRITICAL**: You have access to these report paths via Read tool.
    DO NOT expect full report content in this prompt.
}
```

**Diagnostic**:
```bash
# Measure metadata size (should be ~110 tokens per report)
METADATA='{"path": "...", "title": "...", "findings_count": 12, "recommendations_count": 5}'
echo "$METADATA" | wc -c
# Should be ~100-150 bytes (~30-40 tokens)

# Compare to full report size
wc -c "$RESEARCH_DIR"/001-*.md
# Should be 5,000-15,000 bytes (~1,250-3,750 tokens)

# Context reduction should be 95%+
```

---

### Issue 11: Research Coordinator Partial Success

**Symptom**: Coordinator returns success but some reports missing or empty.

**Cause**: Coordinator using partial success mode (≥50% reports created = continue with warning).

**Solution 1: Check Partial Success Mode**

research-coordinator allows partial success if ≥50% reports created:
```bash
# Verify actual report count vs expected
EXPECTED_REPORTS=3
CREATED_REPORTS=$(find "$RESEARCH_DIR" -name "[0-9][0-9][0-9]-*.md" -type f | wc -l)

if [[ $CREATED_REPORTS -lt $EXPECTED_REPORTS ]]; then
  echo "WARNING: Partial success - $CREATED_REPORTS/$EXPECTED_REPORTS reports created"

  # Fail if <50%
  if [[ $CREATED_REPORTS -lt $((EXPECTED_REPORTS / 2)) ]]; then
    echo "ERROR: Insufficient reports (<50%)"
    exit 1
  fi
fi
```

**Solution 2: Disable Partial Success Mode**

Modify hard barrier validation to require 100%:
```bash
# Fail-fast if ANY report missing (no partial success)
if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  echo "ERROR: ${#MISSING_REPORTS[@]} reports missing (hard barrier failure)"
  exit 1
fi
```

**Diagnostic**:
```bash
# Check which reports are missing
for i in {1..3}; do
  REPORT_NUM=$(printf "%03d" $i)
  REPORT=$(find "$RESEARCH_DIR" -name "${REPORT_NUM}-*.md" -type f)
  if [[ -z "$REPORT" ]]; then
    echo "MISSING: Report $REPORT_NUM"
  else
    echo "EXISTS: $REPORT ($(wc -c < "$REPORT") bytes)"
  fi
done
```

---

## Research Coordinator Specific Issues

### Issue 15: Topic Decomposition Returns Empty Array

**Symptom**: TOPICS_LIST variable is empty or contains only whitespace, TOPIC_COUNT is 0.

**Causes**:
1. FEATURE_DESCRIPTION not set in state
2. Heuristic logic too strict (no conjunctions detected)
3. sed command fails due to special characters in description

**Solution 1: Verify State Persistence**
```bash
# Check if FEATURE_DESCRIPTION persisted to state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: FEATURE_DESCRIPTION not in state" >&2
  exit 1
fi
```

**Solution 2: Add Fallback to Single-Topic Mode**
```bash
# Always fall back if decomposition fails
if [ -z "$TOPICS_LIST" ] || [ "$TOPIC_COUNT" -lt 1 ]; then
  echo "WARNING: Topic decomposition failed, using single-topic mode" >&2
  TOPICS_LIST="$FEATURE_DESCRIPTION"
  TOPIC_COUNT=1
fi
```

**Prevention**:
- Persist FEATURE_DESCRIPTION to state before Block 1d-topics
- Log decomposition results: `echo "TOPICS_LIST=${TOPICS_LIST}" >&2`
- Test with various feature description formats (simple, complex, special chars)

**Reference**: See [Research Coordinator Migration Guide](../guides/development/research-coordinator-migration-guide.md#issue-topic-decomposition-returns-empty-array)

---

### Issue 16: topic-detection-agent Fails or Returns Malformed JSON

**Symptom**: TOPICS_JSON_PATH file not found, jq parsing fails with syntax error.

**Causes**:
1. topic-detection-agent timeout (complex analysis)
2. JSON output truncated or malformed
3. File path mismatch (agent wrote to wrong location)

**Solution 1: Validate JSON Before Parsing**
```bash
# Check if JSON file exists and is valid
if [ ! -f "$TOPICS_JSON_PATH" ]; then
  echo "WARNING: Topic detection output not found, falling back" >&2
  # Execute heuristic decomposition fallback
  exit 0  # Continue with fallback, don't fail workflow
fi

# Validate JSON structure
if ! jq . "$TOPICS_JSON_PATH" >/dev/null 2>&1; then
  echo "WARNING: Malformed JSON from topic-detection, falling back" >&2
  # Execute heuristic decomposition fallback
  exit 0
fi
```

**Solution 2: Implement Graceful Degradation**
```bash
# Try automated detection, fall back to heuristic
AUTOMATED_SUCCESS=false
if [ -f "$TOPICS_JSON_PATH" ] && jq . "$TOPICS_JSON_PATH" >/dev/null 2>&1; then
  TOPICS_LIST=$(jq -r '.topics[] .name' "$TOPICS_JSON_PATH" | paste -sd '|' -)
  TOPIC_COUNT=$(jq '.topics | length' "$TOPICS_JSON_PATH")
  AUTOMATED_SUCCESS=true
fi

if [ "$AUTOMATED_SUCCESS" = "false" ]; then
  # Fall back to heuristic decomposition (Template 6 logic)
  echo "Using heuristic decomposition" >&2
  # ... Template 6 code here ...
fi
```

**Prevention**:
- Always implement graceful fallback to heuristic decomposition
- Validate JSON structure with `jq` before parsing
- Log topic-detection-agent errors to error-handling.sh

**Reference**: See [Command Patterns Quick Reference - Template 7](../reference/command-patterns-quick-reference.md#template-7-topic-detection-agent-invocation-block-automated)

---

### Issue 16.5: research-coordinator Task Invocations Not Executing (Empty Reports Directory)

**Symptom**: research-coordinator returns successfully but reports directory is empty, STEP 4 validation fails with "Reports directory is empty - no reports created" error.

**Root Cause**: Agent interprets Task invocation patterns in STEP 3 as documentation/examples rather than executable directives, skipping research-specialist invocations entirely.

**Diagnostic Indicators**:
1. Error message: "CRITICAL ERROR: Reports directory is empty - no reports created"
2. Error message: "This indicates Task tool invocations did not execute in STEP 3"
3. No research-specialist invocation logs in output
4. Invocation trace file missing at `$REPORT_DIR/.invocation-trace.log`

**Solution 1: Check for Execution Enforcement Markers**

The behavioral file (`/home/benjamin/.config/.claude/agents/research-coordinator.md`) must contain strong execution enforcement markers to prevent misinterpretation:

```bash
# Verify execution markers present
grep -c "EXECUTE NOW - DO NOT SKIP" ~/.config/.claude/agents/research-coordinator.md
# Should return: 3 or more (one per topic index)

grep -q "THIS IS NOT DOCUMENTATION - EXECUTE NOW" ~/.config/.claude/agents/research-coordinator.md && echo "Pre-step warning found"

grep -q "EXECUTION ZONE" ~/.config/.claude/agents/research-coordinator.md && echo "Execution zone marker found"
```

**Solution 2: Verify STEP 3.5 Self-Validation Checkpoint**

Coordinator must self-validate Task invocations before proceeding to STEP 4:

```bash
# Check for self-validation checkpoint
grep -A5 "STEP 3.5.*MANDATORY SELF-VALIDATION" ~/.config/.claude/agents/research-coordinator.md

# Verify fail-fast instruction present
grep -q "FAIL-FAST INSTRUCTION" ~/.config/.claude/agents/research-coordinator.md && echo "Fail-fast checkpoint found"
```

**Solution 3: Enable Invocation Trace Logging**

The invocation trace file captures diagnostic information about Task invocations:

```bash
# After coordinator failure, check for trace file
if [ -f "$REPORT_DIR/.invocation-trace.log" ]; then
  echo "Trace file found - reviewing invocations:"
  cat "$REPORT_DIR/.invocation-trace.log"
else
  echo "Trace file missing - indicates Task invocations never executed"
fi
```

**Solution 4: Check Empty Directory Validation Diagnostic Output**

When STEP 4 detects empty directory, it outputs structured diagnostic information:

```markdown
CRITICAL ERROR: Reports directory is empty - no reports created
Expected: 3 reports
This indicates Task tool invocations did not execute in STEP 3
Root cause: Agent interpreted Task patterns as documentation, not executable directives
Solution: Return to STEP 3 and execute Task tool invocations

Diagnostic Information:
  Topic Count: 3
  Expected Reports: 3
  Created Reports: 0
  Missing Count: 3
```

**Prevention**:
- Ensure `research-coordinator.md` has execution enforcement markers (updated as of 2025-12-09)
- Use "EXECUTE NOW - DO NOT SKIP" directive before each Task invocation
- Add "(EXECUTE)" suffix to all STEP headers
- Separate command-author reference documentation from agent execution instructions
- Include "File Structure (Read This First)" section explaining execution vs documentation

**Resolution Steps**:
1. Update `research-coordinator.md` with latest execution enforcement markers
2. Run integration test: `bash ~/.config/.claude/tests/integration/test_research_coordinator_invocation.sh`
3. Re-invoke coordinator with updated behavioral file
4. Verify invocation trace file created during execution
5. Confirm reports directory populated with expected number of reports

**Reference**: See research-coordinator invocation fix implementation plan (spec 037)

---

### Issue 17: research-coordinator Reports Missing (Hard Barrier Failure)

**Symptom**: Multi-report validation fails with "Report not found at $REPORT_PATH".

**Causes**:
1. research-coordinator invocation failed (agent error)
2. Path mismatch (coordinator wrote to different location)
3. Parallel execution timeout (some research-specialist workers hung)
4. File system permissions (cannot write to RESEARCH_DIR)

**Solution 1: Check Error Logs**
```bash
# Query error logs for agent_error type
/errors --command /create-plan --type agent_error --since 1h

# Check for specific coordinator errors
grep "research-coordinator" ~/.claude/data/errors.jsonl | tail -5
```

**Solution 2: Verify Path Consistency**
```bash
# Check state file for paths
cat ~/.claude/data/state/$WORKFLOW_ID.sh | grep REPORT_PATHS_LIST

# Verify paths are absolute and correct
IFS='|' read -ra PATHS <<< "$REPORT_PATHS_LIST"
for path in "${PATHS[@]}"; do
  if [[ ! "$path" = /* ]]; then
    echo "ERROR: Relative path detected: $path" >&2
    exit 1
  fi
  echo "Expected: $path"
done
```

**Solution 3: Check Directory Permissions**
```bash
# Verify RESEARCH_DIR exists and is writable
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: RESEARCH_DIR does not exist: $RESEARCH_DIR" >&2
  exit 1
fi

if [ ! -w "$RESEARCH_DIR" ]; then
  echo "ERROR: RESEARCH_DIR not writable: $RESEARCH_DIR" >&2
  exit 1
fi
```

**Prevention**:
- Use absolute paths (not relative) for REPORT_PATHS_LIST
- Ensure RESEARCH_DIR created with `mkdir -p` before coordinator invocation
- Validate REPORT_PATHS_LIST persisted to state before invocation
- Test coordinator with single-topic scenario first

**Diagnostic Commands**:
```bash
# Check research directory contents
ls -la "$RESEARCH_DIR/"

# Check for partial report creation
find "$RESEARCH_DIR" -name "[0-9][0-9][0-9]-*.md" -type f

# Verify coordinator received correct contract
grep "topics:" ~/.claude/output/create-plan-output.md
```

**Reference**: See [Hierarchical Agents Examples - Example 7](hierarchical-agents-examples.md#example-7-research-coordinator-with-parallel-multi-topic-research)

---

### Issue 18: Metadata Extraction Parsing Errors

**Symptom**: TOTAL_FINDINGS count is 0 despite report having findings, METADATA_SUMMARY variable empty.

**Causes**:
1. Report structure differs from expected (no "## Findings" section)
2. Findings use different bullet format (not "- " prefix)
3. sed command syntax errors on macOS vs Linux

**Solution 1: Use Filename Fallback for Title**
```bash
# Extract title with robust fallback
TITLE=$(grep -m 1 "^# " "$REPORT_PATH" | sed 's/^# //' 2>/dev/null)
if [ -z "$TITLE" ]; then
  TITLE=$(basename "$REPORT_PATH" .md)
  echo "WARNING: No title found in $REPORT_PATH, using filename" >&2
fi
```

**Solution 2: Use Portable sed/grep Syntax**
```bash
# Count findings with cross-platform compatibility
FINDINGS_COUNT=$(sed -n '/## Findings/,/^##/p' "$REPORT_PATH" | grep -c "^- " 2>/dev/null || echo 0)

# Handle both GNU stat and BSD stat (macOS)
FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH" 2>/dev/null)
```

**Solution 3: Log Parsing Errors with Details**
```bash
# Log parsing failures for debugging
if [ "$FINDINGS_COUNT" -eq 0 ]; then
  echo "WARNING: No findings parsed from $REPORT_PATH" >&2
  echo "  Check report structure for '## Findings' section" >&2
fi
```

**Prevention**:
- Standardize report structure in research-specialist behavioral file
- Test metadata extraction on sample reports before rollout
- Use portable shell commands (avoid bashisms in sed/grep)
- Implement fallbacks for all metadata fields

**Fallback Pattern**:
```bash
# Metadata extraction with comprehensive fallbacks
TITLE=${TITLE:-$(basename "$REPORT_PATH" .md)}
FINDINGS_COUNT=${FINDINGS_COUNT:-0}
RECOMMENDATIONS_COUNT=${RECOMMENDATIONS_COUNT:-0}
```

**Reference**: See [Command Patterns Quick Reference - Template 10](../reference/command-patterns-quick-reference.md#template-10-metadata-extraction-and-aggregation)

---

### Issue 19: Parallel Execution Timeout

**Symptom**: research-coordinator hangs, some research-specialist workers never complete.

**Causes**:
1. research-specialist invocation timeout (complex research)
2. Network issues (if specialists fetch external data)
3. Deadlock in parallel execution

**Solution 1: Add Timeout to Coordinator Prompt**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research (max 10 min per topic)"
  prompt: |
    ...
    **Timeout Policy**: Each research-specialist must complete within 10 minutes.
    If a specialist times out, log error and continue with other topics.
    Partial success is acceptable if ≥50% reports created.
}
```

**Solution 2: Implement Partial Success Validation**
```bash
# Accept partial success if majority of reports created
TOTAL_REPORTS=${#REPORT_PATHS_ARRAY[@]}
VALID_REPORTS=$(find "$RESEARCH_DIR" -name "[0-9][0-9][0-9]-*.md" -type f | wc -l)

if [ "$VALID_REPORTS" -lt "$TOTAL_REPORTS" ]; then
  echo "WARNING: Partial success - $VALID_REPORTS/$TOTAL_REPORTS reports" >&2

  # Require at least 50% success
  if [ "$VALID_REPORTS" -lt $((TOTAL_REPORTS / 2)) ]; then
    echo "ERROR: Insufficient reports (<50%)" >&2
    exit 1
  fi
fi
```

**Prevention**:
- Set reasonable timeout expectations in coordinator prompt
- Test with small topic sets first (2-3 topics)
- Monitor execution time during testing phase

**Reference**: See [Research Invocation Standards](../reference/standards/research-invocation-standards.md)

---

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Coordination](hierarchical-agents-coordination.md)
- [Patterns](hierarchical-agents-patterns.md)
- [Examples](hierarchical-agents-examples.md)
- [Architecture Standards](../reference/architecture/overview.md)

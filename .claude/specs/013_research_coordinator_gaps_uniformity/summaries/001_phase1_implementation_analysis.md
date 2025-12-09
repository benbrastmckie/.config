coordinator_type: software
summary_brief: "Analysis complete for Phase 1 integration. Ready to implement topic decomposition, coordinator invocation, multi-report validation. Context: 30%. Next: Implementation."
phases_completed: []
phase_count: 0
git_commits: []
work_remaining: Phase_1_Task_1 Phase_1_Task_2 Phase_1_Task_3 Phase_1_Task_4 Phase_1_Task_5
context_exhausted: false
context_usage_percent: 30
requires_continuation: true

# Implementation Analysis - Phase 1: research-coordinator Integration into /create-plan

## Work Status

**Completion**: 0/5 tasks (0%)
**Phase**: Phase 1 - IN PROGRESS
**Current Stage**: Analysis Complete, Ready for Implementation

## Analysis Summary

### Current State Assessment

The /create-plan command currently uses direct research-specialist invocation in Block 1e-exec. The command structure is:

1. **Block 1a**: Initial setup and state initialization
2. **Block 1b**: Topic name file path pre-calculation
3. **Block 1b-exec**: Topic naming agent invocation
4. **Block 1c**: Hard barrier validation (topic name)
5. **Block 1d**: Topic path initialization
6. **Block 1e**: Research setup and context barrier
7. **Block 1e-exec**: **Research specialist invocation** (DIRECT, SINGLE REPORT)
8. **Block 1f**: Research output verification (SINGLE REPORT)
9. **Block 2**: Planning phase (plan-architect invocation)

### Integration Points Identified

#### 1. New Block 1d-topics: Topic Decomposition

**Location**: Insert after current Block 1d (topic path initialization), before Block 1e

**Responsibilities**:
- Analyze FEATURE_DESCRIPTION for multi-topic indicators (conjunctions, domain keywords)
- Use RESEARCH_COMPLEXITY to determine topic count:
  - Complexity 1: 1 topic (fallback, no decomposition)
  - Complexity 2: 1-2 topics
  - Complexity 3: 2-3 topics
  - Complexity 4: 4-5 topics
- Implement heuristic-based decomposition:
  - Conjunction detection: "and", "or", commas
  - Domain keyword clustering: authentication, database, API, testing, etc.
  - Phrase segmentation: Split on natural boundaries
- Pre-calculate report paths for each topic: `${RESEARCH_DIR}/001-topic1.md`, `${RESEARCH_DIR}/002-topic2.md`
- Persist TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file using save_state
- Fall back to single topic if decomposition unclear (backward compatibility)

**Implementation Notes**:
- This is a NEW bash block, not a modification
- Must use three-tier sourcing pattern
- Must set up error trap with COMMAND_NAME, WORKFLOW_ID, USER_ARGS
- Must restore state from Block 1d
- Must persist new state variables for Block 1e-exec

#### 2. Modified Block 1e-exec: Research Coordinator Invocation

**Location**: Replace existing Block 1e-exec research-specialist invocation

**Current Pattern** (to be replaced):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: plan workflow

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Expected Output Path: ${REPORT_PATH}
    ...
}
```

**New Pattern** (research-coordinator):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate multi-topic research for ${FEATURE_DESCRIPTION}"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are coordinating research for: plan workflow

    **Input Contract (Hard Barrier Pattern)**:
    - research_request: "${FEATURE_DESCRIPTION}"
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_ARRAY[@]}
    - report_paths: ${REPORT_PATHS_ARRAY[@]}

    **CRITICAL**: You MUST ensure research-specialist writes reports to the EXACT paths specified above.
    The orchestrator has pre-calculated these paths and will validate they exist after you return.

    Execute research coordination according to behavioral guidelines:
    1. Parse topics array (or decompose research_request if topics empty)
    2. Invoke research-specialist for each topic in parallel via Task tool
    3. Validate all reports created at pre-calculated paths (hard barrier)
    4. Extract metadata from each report (title, findings count, recommendations)
    5. Return completion signal: RESEARCH_COMPLETE: {report_count}

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>
}
```

**Key Changes**:
- Agent changed from research-specialist to research-coordinator
- Added topics and report_paths arrays to contract
- Changed output expectation from single REPORT_PATH to multiple REPORT_PATHS_ARRAY
- Updated completion signal from REPORT_CREATED to RESEARCH_COMPLETE

**Research-Coordinator Contract Enhancement**:

The current research-coordinator.md does NOT accept pre-computed topics/report_paths arrays. It only accepts:
- research_request (string)
- research_complexity (1-4)
- report_dir (path)
- topic_path (path)
- context (optional)

**Two implementation options**:

**Option A: Extend research-coordinator to accept topics array** (RECOMMENDED)
- Modify research-coordinator.md Input Format section to accept optional topics/report_paths arrays
- If topics array provided: Skip STEP 1 (topic decomposition), use provided topics
- If topics array empty: Execute STEP 1 as normal (decompose research_request)
- This enables both automated (coordinator decomposes) and manual (command decomposes) workflows

**Option B: Keep coordinator as-is, always let it decompose**
- Don't pass topics array to coordinator
- Let coordinator perform its own decomposition
- Block 1d-topics becomes optional enhancement for Phase 2 (topic-detection-agent)
- Simpler integration but less control over topic decomposition

**Recommendation**: Choose Option A for maximum flexibility and alignment with plan specifications.

#### 3. Modified Block 1f: Multi-Report Validation

**Location**: Replace existing Block 1f validation logic

**Current Pattern** (single report):
```bash
# Validate REPORT_PATH is set (from Block 1e)
if [ -z "${REPORT_PATH:-}" ]; then
  log_command_error ... "REPORT_PATH not restored from Block 1e state"
  exit 1
fi

# HARD BARRIER: Validate agent artifact
if ! validate_agent_artifact "$REPORT_PATH" 100 "research report"; then
  echo "ERROR: HARD BARRIER FAILED - Research specialist validation failed" >&2
  exit 1
fi

# Content validation: Check for ## Findings section
if ! grep -q "^## Findings" "$REPORT_PATH"; then
  log_command_error ... "Research report missing required ## Findings section"
  exit 1
fi
```

**New Pattern** (multi-report):
```bash
# Validate REPORT_PATHS_ARRAY is set (from Block 1e)
if [ -z "${REPORT_PATHS_ARRAY:-}" ] || [ ${#REPORT_PATHS_ARRAY[@]} -eq 0 ]; then
  log_command_error ... "REPORT_PATHS_ARRAY not restored from Block 1e state"
  exit 1
fi

echo "Expected ${#REPORT_PATHS_ARRAY[@]} research reports"

# HARD BARRIER: Validate all reports (fail-fast)
VALIDATION_FAILED=0
for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "Validating: $REPORT_PATH"

  if ! validate_agent_artifact "$REPORT_PATH" 100 "research report"; then
    echo "ERROR: Report missing or invalid: $REPORT_PATH" >&2
    VALIDATION_FAILED=1
  fi

  # Content validation: Check for ## Findings section
  if ! grep -q "^## Findings" "$REPORT_PATH"; then
    log_command_error ... "Research report missing required ## Findings section" \
      ... "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
    VALIDATION_FAILED=1
  fi
done

if [ $VALIDATION_FAILED -eq 1 ]; then
  echo "ERROR: HARD BARRIER FAILED - One or more research reports invalid" >&2
  echo "" >&2
  echo "Recovery steps:" >&2
  echo "1. Check research-coordinator agent log for errors" >&2
  echo "2. Verify all research-specialist invocations completed" >&2
  echo "3. Re-run: /create-plan \"${FEATURE_DESCRIPTION}\"" >&2
  exit 1
fi

# Extract metadata from each report
METADATA_SUMMARY=""
for i in "${!REPORT_PATHS_ARRAY[@]}"; do
  REPORT_PATH="${REPORT_PATHS_ARRAY[$i]}"

  # Extract title (first # heading)
  REPORT_TITLE=$(grep -m 1 "^# " "$REPORT_PATH" | sed 's/^# //')

  # Count findings (## Findings section bullets)
  FINDINGS_COUNT=$(sed -n '/^## Findings/,/^## /p' "$REPORT_PATH" | grep -c "^- " || echo 0)

  # Count recommendations (## Recommendations section bullets)
  RECOMMENDATIONS_COUNT=$(sed -n '/^## Recommendations/,/^## /p' "$REPORT_PATH" | grep -c "^- " || echo 0)

  # Build metadata entry
  METADATA_ENTRY="Report $((i+1)): $REPORT_TITLE ($FINDINGS_COUNT findings, $RECOMMENDATIONS_COUNT recommendations)"
  METADATA_SUMMARY="${METADATA_SUMMARY}${METADATA_ENTRY}\n"
done

# Persist aggregated metadata to state file
append_workflow_state "METADATA_SUMMARY" "$METADATA_SUMMARY"

echo ""
echo "✓ All ${#REPORT_PATHS_ARRAY[@]} research reports validated"
echo ""
echo "Metadata Summary:"
echo -e "$METADATA_SUMMARY"
```

**Key Changes**:
- Loop through REPORT_PATHS_ARRAY (not single REPORT_PATH)
- Validate each report with validate_agent_artifact
- Fail-fast if any report missing (maintain hard barrier pattern)
- Extract metadata from each report (title, findings count, recommendations count)
- Aggregate metadata into single METADATA_SUMMARY string
- Persist METADATA_SUMMARY to state file for Block 2

#### 4. Modified Block 2: Planning Phase Integration

**Location**: Modify plan-architect invocation to pass report paths instead of inline content

**Current Pattern** (content passing):
```markdown
Task {
  prompt: |
    ...
    Research Report Content:
    ${FULL_REPORT_CONTENT}
    ...
}
```

**New Pattern** (metadata + paths):
```markdown
Task {
  prompt: |
    ...
    Research Reports: ${#REPORT_PATHS_ARRAY[@]} reports created
    ${METADATA_SUMMARY}

    Report Paths (read as needed):
    ${REPORT_PATHS_ARRAY[@]}
    ...
}
```

**Key Changes**:
- Pass report count and aggregated metadata (110 tokens per report)
- Pass report paths array for plan-architect to read selectively
- Remove inline full report content passing (2,500 tokens per report)
- Context reduction: 95% (110 tokens vs 2,500 tokens per report)

#### 5. Modified Frontmatter: dependent-agents Field

**Current dependent-agents**:
```yaml
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
```

**New dependent-agents**:
```yaml
dependent-agents:
  - research-coordinator
  - plan-architect
```

**Key Changes**:
- Add research-coordinator (directly invoked in Block 1e-exec)
- Remove research-specialist (transitive dependency, invoked by coordinator)
- Remove research-sub-supervisor (transitive dependency, invoked by coordinator when topic count ≥4)
- Keep plan-architect (directly invoked in Block 2)

### Implementation Strategy

#### Phase 1 Task Breakdown

1. **Task 1**: Add Block 1d-topics bash block (topic decomposition with heuristics)
   - Duration: 2-3 hours
   - Complexity: Medium (bash array manipulation, state persistence)
   - Testing: Verify topics array populated correctly for various FEATURE_DESCRIPTION patterns

2. **Task 2**: Extend research-coordinator.md to accept topics/report_paths arrays (Option A)
   - Duration: 1-2 hours
   - Complexity: Low (documentation update, contract extension)
   - Testing: Verify coordinator accepts and uses pre-computed topics

3. **Task 3**: Replace Block 1e-exec with research-coordinator invocation
   - Duration: 1 hour
   - Complexity: Low (Task tool invocation pattern change)
   - Testing: Verify coordinator receives correct contract parameters

4. **Task 4**: Update Block 1f to validate multiple reports with metadata extraction
   - Duration: 2-3 hours
   - Complexity: Medium (multi-report validation loop, metadata parsing)
   - Testing: Verify all reports validated, metadata extracted correctly

5. **Task 5**: Update Block 2 and frontmatter
   - Duration: 1 hour
   - Complexity: Low (contract update, frontmatter change)
   - Testing: Verify plan-architect receives metadata and paths, not full content

**Total Estimated Duration**: 7-10 hours (within Phase 1 estimate of 8-10 hours)

### Risks and Mitigations

#### Risk 1: Topic Decomposition Inaccuracy
**Impact**: research-coordinator receives poorly scoped topics, research quality degrades
**Mitigation**:
- Implement conservative heuristics (prefer single topic over bad decomposition)
- Fall back to single-topic mode if decomposition unclear
- Phase 2 will add topic-detection-agent for automated improvement

#### Risk 2: Research-Coordinator Breaking Changes
**Impact**: Extending coordinator contract breaks existing usage
**Mitigation**:
- Make topics/report_paths arrays optional (backward compatible)
- If arrays empty, coordinator performs its own decomposition (existing behavior)
- Test both pre-computed and auto-decompose workflows

#### Risk 3: Multi-Report Validation Complexity
**Impact**: Validation logic becomes fragile, false negatives/positives
**Mitigation**:
- Use same validate_agent_artifact function as single-report case
- Fail-fast on first validation failure (clear error messages)
- Log all validation errors with error-handling library

#### Risk 4: Metadata Extraction Parsing Errors
**Impact**: Malformed reports cause metadata extraction to fail
**Mitigation**:
- Use graceful fallback (use filename if title parsing fails)
- Default to 0 if count parsing fails (better than exit)
- Log parsing errors for debugging

#### Risk 5: Plan Quality Regression
**Impact**: plan-architect receives less context, produces lower-quality plans
**Mitigation**:
- plan-architect can still read full reports (receives paths)
- Metadata provides sufficient context for most planning scenarios
- Measure plan quality in Phase 8 integration testing
- Rollback if quality degrades significantly

### Testing Strategy

#### Unit Testing (Task-Level)

1. **Block 1d-topics Heuristics**:
   - Test conjunction detection: "implement OAuth2 and session management" → 2 topics
   - Test domain keywords: "authentication database API" → 3 topics
   - Test single-topic fallback: "fix bug" → 1 topic
   - Test complexity mapping: complexity 1 → 1 topic, complexity 4 → 4-5 topics

2. **Multi-Report Validation**:
   - Test all reports valid → validation passes
   - Test one missing report → validation fails with clear error
   - Test malformed report (no ## Findings) → validation fails
   - Test metadata extraction with valid reports → correct title/counts

3. **State Persistence**:
   - Test TOPICS_ARRAY persisted correctly → restored in next block
   - Test REPORT_PATHS_ARRAY persisted correctly → restored in Block 1f
   - Test METADATA_SUMMARY persisted correctly → available for Block 2

#### Integration Testing (Phase-Level)

1. **Single-Topic Scenario** (complexity 1-2):
   - Run: `/create-plan "simple feature" --complexity 1`
   - Verify: 1 topic generated (fallback behavior)
   - Verify: Single research report created
   - Verify: plan-architect receives report path and metadata

2. **Multi-Topic Scenario** (complexity 3):
   - Run: `/create-plan "implement OAuth2 authentication with session management and password security" --complexity 3`
   - Verify: 3 topics generated (authentication, sessions, passwords)
   - Verify: 3 research reports created in parallel (check timestamps)
   - Verify: All reports validated (Block 1f passes)
   - Verify: Metadata extracted from all 3 reports
   - Verify: plan-architect receives 3 report paths + aggregated metadata

3. **Hard Barrier Failure** (missing report):
   - Simulate: Delete one report file before Block 1f validation
   - Verify: Block 1f detects missing report
   - Verify: Error message lists which report missing
   - Verify: Workflow halts with clear recovery steps

4. **Context Reduction Measurement**:
   - Baseline: Count tokens if full reports passed to plan-architect (hypothetical)
   - Actual: Count tokens with metadata-only passing
   - Calculate reduction: (baseline - actual) / baseline × 100
   - Target: ≥40% reduction

#### Regression Testing

1. **Backward Compatibility** (single-topic workflows):
   - Run: `/create-plan "simple feature" --complexity 1`
   - Verify: Existing behavior maintained (1 report, no multi-topic overhead)

2. **plan-architect Behavior**:
   - Verify: plan-architect still receives report paths (can read as needed)
   - Verify: Plan quality maintained (compare to baseline plans)

3. **Hard Barrier Pattern**:
   - Verify: Path pre-calculation still occurs (reports directory created)
   - Verify: Fail-fast on missing reports (workflow halts)
   - Verify: Error logging works (errors.jsonl populated)

### Success Criteria

Phase 1 is successful if:
- ✓ Block 1d-topics generates 1-4 topics based on FEATURE_DESCRIPTION and RESEARCH_COMPLEXITY
- ✓ Block 1e-exec invokes research-coordinator (not research-specialist directly)
- ✓ research-coordinator creates 2-4 reports in parallel (measured via timestamps)
- ✓ Block 1f validates all reports (multi-report hard barrier works)
- ✓ Metadata extracted from all reports (title, findings count, recommendations count)
- ✓ plan-architect receives report paths + metadata (not full content)
- ✓ Context reduction ≥40% measured (baseline vs actual token counts)
- ✓ Single-topic scenarios still work (backward compatibility)
- ✓ Integration tests pass (3-topic scenario creates valid plan)

### Next Steps

1. **Immediate**: Implement Task 1 (Block 1d-topics) with heuristic decomposition
2. **Then**: Implement Task 2 (extend research-coordinator contract)
3. **Then**: Implement Tasks 3-5 (replace invocation, update validation, update frontmatter)
4. **Finally**: Run integration tests and measure context reduction

### Context Management

**Current Context Usage**: ~30% (60k tokens of 200k window)
**Estimated Context for Implementation**: +40% (80k tokens for file modifications, testing)
**Total Estimated**: 70% (within safe limits)
**Continuation Required**: No (Phase 1 should complete in single iteration)

### Artifacts to Create

1. Modified file: `/home/benjamin/.config/.claude/commands/create-plan.md` (Block 1d-topics, 1e-exec, 1f, 2, frontmatter)
2. Modified file: `/home/benjamin/.config/.claude/agents/research-coordinator.md` (Input Format section)
3. Test summary: `/home/benjamin/.config/.claude/specs/013_research_coordinator_gaps_uniformity/outputs/phase1_integration_test_results.txt`

### Notes

- This analysis assumes the implementer-coordinator agent has sufficient context to complete Phase 1
- If context exhaustion detected, create checkpoint and return with requires_continuation: true
- Phase 2 (topic-detection-agent integration) will replace heuristic decomposition with LLM-based automated detection
- Phase 8 will measure actual performance metrics (context reduction, time savings)

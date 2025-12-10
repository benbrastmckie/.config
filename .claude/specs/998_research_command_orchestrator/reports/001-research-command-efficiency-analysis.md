# Research Command Efficiency Analysis

**Date**: 2025-12-09
**Scope**: /research command architecture analysis
**Purpose**: Identify inefficiencies and bottlenecks preventing scalable research orchestration

## Executive Summary

The /research command demonstrates significant architectural inefficiency by requiring the primary agent to perform excessive work during research execution. Analysis of the command reveals a critical bottleneck: the orchestrating agent was designed to delegate research work to the research-coordinator, but the command flow forces the primary agent into direct research execution mode. This creates a 95% context consumption inefficiency where the primary agent loads full report content (2,500 tokens per report) instead of receiving metadata-only summaries (110 tokens per report).

The command architecture has been recently updated (as of 2025-12-08) to integrate research-coordinator for multi-topic research orchestration, achieving 95-96% context reduction when properly delegated. However, the implementation reveals coordination complexity and potential failure modes that need systematic optimization.

## Findings

### 1. Multi-Block State Restoration Overhead

**Issue**: The /research command uses 9 distinct bash blocks (Block 1a, 1b, 1b-exec, 1c, 1d-topics, 1d, 1d-exec, 1e, Block 2) to orchestrate workflow state transitions, each requiring full state restoration with project directory detection, library sourcing, and error trap setup.

**Evidence**: Block 1a through Block 2 each contain identical state restoration patterns:
- Project directory detection (15 lines)
- State file path calculation and restoration (10 lines)
- Library sourcing with three-tier pattern (15 lines)
- Error trap setup (5 lines)
- Variable defensive initialization (10 lines)

**Impact**:
- ~55 lines of repeated boilerplate per block = 495 lines total overhead
- 9 separate bash command invocations required for single workflow
- State persistence file I/O occurs 9 times per workflow
- Error surface area increases with each block transition

**Root Cause**: Command architecture predates the state-based orchestration optimizations introduced in the lean-coordinator and implementer-coordinator patterns.

### 2. Hard Barrier Pattern Complexity

**Issue**: The hard barrier pattern (pre-calculate paths → invoke agent → validate artifacts) requires 3 separate blocks per delegation point, creating a 3:1 overhead ratio.

**Evidence**:
- Block 1b: Topic name path pre-calculation
- Block 1b-exec: Topic naming agent invocation
- Block 1c: Hard barrier validation
- Block 1d: Report path pre-calculation
- Block 1d-exec: Research coordinator invocation
- Block 1e: Agent output validation

**Impact**:
- 6 blocks required for 2 agent delegations (3:1 ratio)
- Each barrier creates checkpoint friction where the workflow must pause
- State must be persisted/restored across each barrier
- Validation failures require manual re-execution from specific blocks

**Design Tradeoff**: The hard barrier pattern provides critical safety guarantees (prevents path mismatch issues, ensures artifact creation) but creates significant orchestration overhead.

### 3. Redundant Topic Decomposition

**Issue**: The command performs topic decomposition in Block 1d-topics using heuristic-based parsing (splitting on "and", "or", commas), but this duplicates logic that research-coordinator already implements in STEP 1 (automated decomposition mode).

**Evidence**:
```bash
# From Block 1d-topics (lines 849-883)
IFS=',' read -ra PARTS <<< "$WORKFLOW_DESCRIPTION"
for part in "${PARTS[@]}"; do
  IFS=' and ' read -ra SUB_PARTS <<< "$part"
  # Further decomposition...
done
```

Research-coordinator STEP 1 implements identical decomposition:
```yaml
# From research-coordinator.md (lines 166-171)
Parse Research Request: Analyze the research_request string to identify distinct research topics
- Look for conjunctions ("and", "or"), commas, topic keywords
- Identify major themes
- Target 2-5 topics based on research_complexity
```

**Impact**:
- Duplicate logic maintained in two locations (command + agent)
- Decomposition runs twice (primary agent + coordinator)
- Mode 2 (Pre-Decomposed) exists to bypass primary agent decomposition, but adds complexity
- If decomposition logic changes, both files must be updated

**Alternative**: Use Mode 1 (Automated Decomposition) exclusively, allowing research-coordinator to handle all topic parsing.

### 4. Context Consumption During Validation

**Issue**: Block 1e validates all research reports were created, but uses inline validation logic instead of delegating to a validation utility. This forces validation code to live in the command file, increasing command complexity.

**Evidence**: Block 1e contains 70+ lines of validation logic (lines 1152-1319):
- Report file existence checks
- Size threshold validation (100 bytes minimum)
- Required sections validation ("## Findings")
- Error logging for missing/invalid reports

**Impact**:
- Validation logic tightly coupled to command
- Cannot reuse validation logic across commands
- Hard to test validation independently
- Increases command file size (currently 1,564 lines)

**Improvement Opportunity**: Extract validation logic into `lib/workflow/validation-utils.sh` with a `validate_research_artifacts()` function that accepts report paths array and returns validation results.

### 5. Invocation Plan File Pattern Creates Checkpoint Overhead

**Issue**: Research-coordinator STEP 2.5 requires creation of an invocation plan file (`$REPORT_DIR/.invocation-plan.txt`) as a "pre-execution barrier" to prove STEP 2.5 executed before STEP 3. This pattern adds artifact management overhead.

**Evidence**: STEP 2.5 creates invocation plan file (lines 282-303), STEP 4 validates it exists (lines 518-537), STEP 6 deletes it on success (lines 786-792).

**Impact**:
- 3 file I/O operations per workflow (create, validate, delete)
- Trace file + plan file = 2 artifacts for single delegation
- Plan file validation in STEP 4 is redundant with trace file validation
- Cleanup logic required to remove temporary artifacts

**Design Question**: Does the invocation plan file provide value beyond the invocation trace file? Both serve as "proof of execution" for earlier steps.

### 6. Missing Intermediate Summary Parsing

**Issue**: Research-coordinator returns verbose completion signals with full metadata JSON (lines 761-777), but the /research command doesn't parse this metadata in Block 1e. The hard barrier validation re-implements all validation checks instead of trusting coordinator's success signal.

**Evidence**: Block 1e performs independent validation without consuming coordinator's `RESEARCH_COORDINATOR_COMPLETE: SUCCESS` signal:
```bash
# Block 1e validation (re-implements what coordinator already verified)
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "agent_error" "research-coordinator failed to create report file"
  # ...
fi
```

Research-coordinator STEP 6 already validated all reports in STEP 4:
```bash
# research-coordinator.md STEP 4 (lines 599-631)
if [ ! -f "$REPORT_PATH" ]; then
  MISSING_REPORTS+=("$REPORT_PATH")
  echo "ERROR: Report not found: $REPORT_PATH" >&2
fi
# Fail-fast if any reports missing
```

**Impact**:
- Duplicate validation logic (coordinator validates, command re-validates)
- Coordinator's success signal is ignored (wasted work)
- If coordinator passes STEP 4 but command Block 1e fails, indicates architectural inconsistency
- Coordinator's metadata extraction (STEP 5) is unused by /research command

**Improvement Opportunity**: Implement brief summary parsing pattern (similar to implementer-coordinator) where Block 1e parses `RESEARCH_COORDINATOR_COMPLETE` signal and trusts coordinator validation instead of re-validating.

### 7. No Wave-Based Orchestration

**Issue**: Research-coordinator invokes all research-specialist agents in parallel (STEP 3), but the /research command doesn't leverage wave-based orchestration to handle phase dependencies or partial success modes.

**Evidence**: STEP 3 generates all Task invocations in a single bash loop without wave grouping:
```bash
for i in "${!TOPICS[@]}"; do
  # Generate Task invocation for topic $i
done
```

Partial success mode exists (lines 820-826 in research-coordinator.md):
```
If ≥50% reports created: Return partial metadata with warning
If <50% reports created: Return TASK_ERROR
```

**Impact**:
- Cannot handle dependent research topics (e.g., "Research A must complete before Research B")
- No progress tracking for multi-topic research (can't resume from Wave 2 if Wave 1 succeeded)
- Partial success mode is binary (50% threshold) without granular wave-level success tracking
- All topics must retry from beginning if any topic fails

**Comparison**: The implementer-coordinator uses wave-based orchestration with phase dependencies:
```yaml
phases:
  - name: "Wave 1: Core Setup"
    dependencies: []
  - name: "Wave 2: Integration Tests"
    dependencies: ["Wave 1"]
```

**Improvement Opportunity**: Extend research-coordinator to support wave-based topic groups with dependencies, enabling progressive research workflows.

### 8. STEP 3 Task Invocation Pattern Complexity

**Issue**: Research-coordinator STEP 3 uses a bash-loop-generates-Task-invocations pattern that creates execution ambiguity. The agent must:
1. Execute bash script to generate Task invocation text
2. Recognize generated text contains `**EXECUTE NOW**` directives
3. Parse generated text and execute each Task invocation separately

**Evidence**: STEP 3 instructions contain 3 nested execution layers:
```
1. Execute bash script (lines 342-422)
2. Bash script outputs Task invocation patterns with **EXECUTE NOW** markers
3. Agent must parse output and execute each Task invocation
```

STEP 3.5 exists solely to verify agent completed step 3 correctly (lines 460-508).

**Impact**:
- High cognitive load for agent (must understand "generate then execute" pattern)
- STEP 3.5 self-validation checkpoint required to prevent agent from skipping Task invocations
- If agent misinterprets pattern as documentation, returns "Reports directory is empty" error (line 579-586)
- Common failure mode: Agent generates Task patterns but doesn't execute them

**Root Cause**: Task tool cannot be invoked from bash loops (architectural limitation). The current pattern works around this by generating text that the agent must re-interpret.

**Alternative Pattern**: Explicit Task invocation list with hardcoded topic indices:
```
**EXECUTE NOW**: Task { topic: TOPICS[0], path: REPORT_PATHS[0] }
**EXECUTE NOW**: Task { topic: TOPICS[1], path: REPORT_PATHS[1] }
**EXECUTE NOW**: Task { topic: TOPICS[2], path: REPORT_PATHS[2] }
```

This removes the "generate then execute" indirection but requires coordinator to know exact topic count at author time (not runtime).

### 9. Error Logging Integration Gaps

**Issue**: While the /research command uses centralized error logging (`log_command_error`), the research-coordinator agent uses a custom error handler (`handle_coordinator_error`) that outputs ERROR_CONTEXT in a different format.

**Evidence**:
- Command uses `log_command_error()` from error-handling.sh with 7 parameters
- Coordinator uses custom handler (lines 111-136) that outputs ERROR_CONTEXT JSON to stderr
- Parent command doesn't parse ERROR_CONTEXT from coordinator stderr

**Impact**:
- Coordinator errors not logged to centralized errors.jsonl
- `/errors --command /research` won't show coordinator-level failures
- Diagnostic information from coordinator lost unless stderr is manually inspected
- Inconsistent error reporting between command and agent layers

**Expected Integration**: Parent command should parse coordinator's ERROR_CONTEXT and call `log_command_error()` with coordinator's error details.

### 10. Trace File Lifecycle Ambiguity

**Issue**: Research-coordinator creates `.invocation-trace.log` file in STEP 3, validates it in STEP 4, but deletes it in STEP 6 only on success (line 786-792). On failure, trace file persists but command doesn't document this.

**Evidence**:
```bash
# STEP 6 cleanup (lines 786-792)
if [ -f "$REPORT_DIR/.invocation-trace.log" ]; then
  rm "$REPORT_DIR/.invocation-trace.log"
fi
# Note: If STEP 4 validation fails, trace file is preserved for debugging
```

**Impact**:
- Trace file accumulation in reports directories after failures
- No documented retention policy (when to delete old trace files?)
- Trace file format not documented (is it parseable for debugging?)
- If coordinator retries, old trace file might conflict with new invocation

**Improvement Opportunity**:
1. Move trace files to `.claude/tmp/` instead of reports directory
2. Document trace file retention policy
3. Add trace file timestamp to prevent conflicts on retry

## Recommendations

### High Priority (Architectural Improvements)

1. **Consolidate Bash Blocks**: Reduce from 9 blocks to 3 blocks by combining state restoration:
   - Block 1: Setup + topic naming + topic decomposition + report path calculation
   - Block 2: Research coordinator invocation + validation
   - Block 3: Completion and summary

   Expected savings: ~350 lines of boilerplate, 6 fewer block transitions

2. **Implement Brief Summary Parsing**: Add coordinator metadata parsing in Block 1e to avoid re-validation:
   ```bash
   # Parse coordinator completion signal
   COORDINATOR_OUTPUT=$(parse_coordinator_metadata "$task_output")
   REPORTS_CREATED=$(echo "$COORDINATOR_OUTPUT" | jq -r '.reports_created')
   # Trust coordinator validation instead of re-checking files
   ```

   Expected savings: 95% context reduction maintained, ~70 lines of validation code removed

3. **Delegate Topic Decomposition**: Remove Block 1d-topics, use research-coordinator Mode 1 (Automated Decomposition) exclusively:
   ```diff
   - Block 1d-topics: Parse topics from WORKFLOW_DESCRIPTION
   - Block 1d-exec: Pass topics array to coordinator (Mode 2)
   + Block 1d-exec: Pass research_request to coordinator (Mode 1, coordinator decomposes)
   ```

   Expected savings: ~100 lines, removes duplicate decomposition logic

4. **Extract Validation Utilities**: Move report validation logic to `lib/workflow/validation-utils.sh`:
   ```bash
   # New function in validation-utils.sh
   validate_research_artifacts() {
     local report_paths_array=("$@")
     # Validation logic from Block 1e
   }
   ```

   Benefits: Reusable across commands, testable in isolation, reduces command complexity

### Medium Priority (Coordinator Optimizations)

5. **Simplify Barrier Pattern**: Merge STEP 2.5 invocation plan file into trace file (single artifact):
   ```bash
   # STEP 3: Create trace file with expected invocation count header
   echo "Expected Invocations: ${#TOPICS[@]}" > "$TRACE_FILE"
   # STEP 4: Validate trace file header instead of separate plan file
   ```

   Expected savings: 1 file I/O per workflow, 30 lines of plan file management code

6. **Add Wave-Based Orchestration**: Extend research-coordinator to support topic dependency groups:
   ```yaml
   # Example: Dependent research topics
   waves:
     - name: "Wave 1: Foundation Research"
       topics: ["Mathlib theorems", "Lean 4 basics"]
       dependencies: []
     - name: "Wave 2: Advanced Patterns"
       topics: ["Proof automation", "Tactic development"]
       dependencies: ["Wave 1"]
   ```

   Benefits: Enables progressive research, better failure recovery, supports complex research workflows

7. **Standardize Error Handling**: Integrate coordinator ERROR_CONTEXT parsing in command:
   ```bash
   # After coordinator returns
   parse_coordinator_errors "$task_output" "$WORKFLOW_ID"
   ```

   Benefits: Centralized error logging, queryable coordinator errors via `/errors`

### Low Priority (Incremental Improvements)

8. **Document Trace File Format**: Add trace file schema documentation to research-coordinator.md:
   ```markdown
   ## Trace File Format
   ```
   [TIMESTAMP] Topic[INDEX]: TOPIC_NAME | Path: REPORT_PATH | Status: PENDING|INVOKED|COMPLETE
   ```

9. **Move Trace Files to .claude/tmp/**: Change trace file location to prevent reports directory pollution:
   ```diff
   - TRACE_FILE="$REPORT_DIR/.invocation-trace.log"
   + TRACE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_trace_${WORKFLOW_ID}.log"
   ```

10. **Add Progress Tracking**: Emit progress signals during multi-topic research:
    ```bash
    # After each topic completes
    echo "PROGRESS: Topic $((i+1))/${#TOPICS[@]} complete" >&2
    ```

## References

### Files Examined

1. `/home/benjamin/.config/.claude/commands/research.md` (1,564 lines)
   - Block structure analysis (lines 23-1562)
   - State restoration patterns (repeated across blocks)
   - Hard barrier pattern implementation (Blocks 1b-1e)
   - Validation logic (Block 1e, lines 1152-1319)

2. `/home/benjamin/.config/.claude/agents/research-coordinator.md` (963 lines)
   - STEP 1-6 workflow analysis (lines 147-794)
   - STEP 3 Task invocation pattern (lines 333-457)
   - STEP 4 validation logic (lines 511-656)
   - Error handling protocol (lines 799-900)

3. `/home/benjamin/.config/.claude/output/research-output.md` (255 lines)
   - Example /research execution trace
   - Demonstrates single-topic research flow
   - Shows console summary format

### Related Documentation

- **Hierarchical Agent Architecture**: `.claude/docs/concepts/hierarchical-agents-overview.md`
  - Example 7: Research Coordinator Pattern (metadata-only passing, 95% context reduction)
  - Example 8: Lean Command Coordinator Optimization (brief summary parsing pattern)

- **Hard Barrier Pattern**: `.claude/docs/concepts/hierarchical-agents-patterns.md`
  - Pre-calculate paths → invoke agent → validate artifacts
  - Prevents path mismatch issues, ensures mandatory delegation

- **State-Based Orchestration**: `.claude/docs/architecture/state-based-orchestration-overview.md`
  - Wave-based phase execution with dependencies
  - Partial success mode handling (≥50% threshold)

- **Error Handling Pattern**: `.claude/docs/concepts/patterns/error-handling.md`
  - Centralized error logging integration
  - Agent error return protocol (TASK_ERROR signals)

### Comparison Points

- **Implementer-Coordinator**: Uses wave-based orchestration with brief summary parsing (80 tokens vs 2,000 tokens per phase = 96% reduction)
- **Lean-Plan-Architect**: Integrates research-coordinator in plan-driven mode with metadata-only consumption
- **Create-Plan Command**: Similar multi-block structure (10 blocks), candidate for same consolidation optimizations

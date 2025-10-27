---
command-type: primary
dependent-commands: list-reports, report
description: Investigate issues and create diagnostic report without code changes
argument-hint: <issue-description> [report-path1] [report-path2] ...
allowed-tools: Read, Bash, Grep, Glob, WebSearch, WebFetch, TodoWrite, Task
---

# /debug Command

**YOU MUST orchestrate a diagnostic investigation by delegating to specialized debug agents.**

**YOUR ROLE**: You are the INVESTIGATION ORCHESTRATOR, not the investigator.
- **DO NOT** analyze code/logs/errors yourself using Read/Grep/Bash tools
- **ONLY** use Task tool to invoke debug-specialist or debug-analyst agents
- **YOUR RESPONSIBILITY**: Coordinate investigation, aggregate findings, verify report creation

**EXECUTION MODES**:
- **Simple Mode** (single root cause): Invoke debug-specialist for direct analysis
- **Complex Mode** (2+ potential causes): Invoke multiple debug-analyst agents in parallel for hypothesis testing

**CRITICAL INSTRUCTIONS**:
- Execute all investigation steps in EXACT sequential order (Steps 1-5)
- DO NOT skip Step 3.5 (parallel investigation) for complex issues
- DO NOT skip report file creation and verification
- DO NOT skip spec-updater invocation for plan linking
- DO NOT make code changes (diagnostic only - agents document findings)
- Fallback mechanisms ensure 100% report creation

## Usage

```
/debug <issue-description> [report-path1] [report-path2] ...
```

### Arguments

- `<issue-description>` (required): Description of the bad behavior or issue to investigate
- `[report-path1] [report-path2] ...` (optional): Related reports or plan paths that might provide context
  - Can be report paths: `specs/reports/001_*.md`
  - Can be plan paths: `specs/plans/002_*.md` (will annotate plan with debug notes)

## Examples

### Basic Debugging
```
/debug "Terminal commands appearing mixed with startup messages"
```

### With Context Reports
```
/debug "Module caching preventing updates" specs/reports/001_architecture.md
```

### Multiple Reports
```
/debug "Performance degradation after refactor" reports/002_perf.md reports/003_profiling.md
```

## Process

**STEP 1 (REQUIRED BEFORE STEP 2) - Issue Analysis**

**EXECUTE NOW - Parse and Analyze Issue**:

- Parse and understand the reported behavior
- Identify affected components and systems
- Review any provided context reports
- Determine investigation scope

**MANDATORY VERIFICATION - Issue Scope Determined**:

```bash
if [ -z "$issue_description" ]; then
  echo "❌ ERROR: No issue description provided"
  exit 1
fi

if [ -z "$affected_components" ]; then
  echo "❌ ERROR: Affected components not identified"
  exit 1
fi

echo "✓ VERIFIED: Issue analyzed, scope determined"
echo "  - Components: $affected_components"
echo "  - Scope: $investigation_scope"
```

---

**STEP 2 (REQUIRED BEFORE STEP 3) - Evidence Gathering**

**EXECUTE NOW - Collect Diagnostic Evidence**:

- **Code Inspection**: Examine relevant source files
- **Environment Analysis**: Check configuration and environment variables
- **Log Analysis**: Review error logs and debug output (if available)
- **Dependency Review**: Verify module dependencies and versions
- **State Examination**: Check caches, session data, and persistent state

**MANDATORY VERIFICATION - Evidence Collected**:

```bash
if [ ${#evidence_items[@]} -eq 0 ]; then
  echo "❌ ERROR: No evidence collected"
  exit 1
fi

echo "✓ VERIFIED: Evidence gathered (${#evidence_items[@]} items)"
for item in "${evidence_items[@]}"; do
  echo "  - $item"
done
```

---

**STEP 3 (REQUIRED BEFORE STEP 3.5 OR STEP 4) - Root Cause Investigation**

**EXECUTE NOW - Analyze Root Causes**:

- **Trace Execution Paths**: Follow code flow from symptoms to source
- **Identify Patterns**: Look for common failure modes
- **Test Hypotheses**: Validate potential causes through inspection
- **Check Recent Changes**: Review git history if relevant
- **Environmental Factors**: Consider system-specific issues

**MANDATORY VERIFICATION - Root Cause Analysis Complete**:

```bash
if [ -z "$root_cause_analysis" ]; then
  echo "❌ ERROR: Root cause analysis not performed"
  exit 1
fi

echo "✓ VERIFIED: Root cause analysis complete"
echo "  - Hypotheses generated: $hypothesis_count"
```

---

### 3.5. Parallel Hypothesis Investigation (for Complex Issues)

**YOU MUST invoke debug-analyst agents in parallel for complex issues. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Parallel investigation is MANDATORY for complex issues
- DO NOT investigate hypotheses sequentially
- DO NOT skip metadata extraction
- DO NOT skip synthesis of findings
- Fallback mechanism ensures complete investigation

For complex issues with multiple potential root causes, use parallel debug-analyst agents to investigate hypotheses simultaneously.

**When to Use**:
- **Multiple potential causes**: Issue could stem from 2-4 different root causes
- **Complex systems**: Integration failures, race conditions, state management issues
- **Unknown root cause**: Initial investigation doesn't reveal obvious culprit
- **Performance degradation**: Multiple bottlenecks or optimization opportunities

**Workflow Overview**:
1. Generate 2-4 prioritized hypotheses based on initial analysis
2. Invoke debug-analyst agent for each hypothesis in parallel
3. Use forward_message to extract metadata from each investigation
4. Synthesize findings to identify confirmed hypothesis
5. Create consolidated debug report with all investigation results

---

**Key Execution Requirements**:

1. **Generate hypotheses** (from initial investigation):
   ```bash
   # Priority levels: high (most likely), medium (alternative), low (edge case)
   HYPOTHESES='[
     {"hypothesis": "Missing import statement", "priority": "high"},
     {"hypothesis": "Incorrect function signature", "priority": "medium"},
     {"hypothesis": "Race condition in async code", "priority": "low"}
   ]'

   # Extract count for parallel invocation
   HYPOTHESIS_COUNT=$(echo "$HYPOTHESES" | jq '. | length')
   echo "PROGRESS: Investigating $HYPOTHESIS_COUNT hypotheses in parallel"
   ```

**STEP A (REQUIRED FOR COMPLEX ISSUES) - Invoke Debug-Analyst Agents in Parallel**

**EXECUTE NOW - Parallel Hypothesis Investigation**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke debug-analyst agents in parallel (single message). This is NOT optional.

**WHY THIS MATTERS**: Parallel investigation reduces debugging time by 60-80% compared to sequential hypothesis testing.

2. **Invoke debug-analyst agents in parallel** (single message, multiple Task tool calls):

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE for each hypothesis (No modifications, no paraphrasing):

**CRITICAL**: All Task tool calls MUST be in a SINGLE message for true parallel execution.

```bash
# Source context preservation utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"

# Track context before parallel investigation
CONTEXT_BEFORE=$(track_context_usage "before" "debug_parallel_investigation" "")

# Build agent prompts for each hypothesis
for i in $(seq 0 $((HYPOTHESIS_COUNT - 1))); do
  HYPOTHESIS=$(echo "$HYPOTHESES" | jq -r ".[$i].hypothesis")
  PRIORITY=$(echo "$HYPOTHESES" | jq -r ".[$i].priority")

  # Invoke Task tool for this hypothesis (all in ONE message)
  Task {
    subagent_type: "general-purpose"
    description: "Investigate hypothesis: ${HYPOTHESIS}"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

      You are acting as a Debug Analyst Agent.

      Investigation Context:
      - Issue: "${ISSUE_DESCRIPTION}"
      - Failed test: ${TEST_COMMAND}
      - Modified files: ${FILE_LIST}
      - Hypothesis: ${HYPOTHESIS}
      - Priority: ${PRIORITY}

      Investigate this hypothesis and create artifact at:
      specs/${TOPIC_DIR}/debug/$(printf "%03d" $((i+1)))_investigation_${HYPOTHESIS// /_}.md

      Return metadata only (path + 50-word summary + confirmation JSON).
  }
done
```

**Parallel Invocation Requirements**:
- MUST invoke ALL debug-analyst agents in ONE message (not sequential)
- Maximum 4 hypotheses per parallel batch
- MUST use exact template for each hypothesis
- MUST NOT modify agent behavioral guidelines path

**Template Variables** (ONLY allowed modifications):
- `${ISSUE_DESCRIPTION}`: Issue description from user input
- `${TEST_COMMAND}`: Failed test command (if applicable)
- `${FILE_LIST}`: Modified files related to issue
- `${HYPOTHESIS}`: Specific hypothesis to investigate
- `${PRIORITY}`: Hypothesis priority (high/medium/low)
- `${TOPIC_DIR}`: Topic directory for debug artifacts

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Return format requirement (metadata only)

Expected response format:
{
  "artifact_path": "specs/${TOPIC_DIR}/debug/NNN_investigation.md",
  "metadata": {
    "title": "Debug Investigation: ${ISSUE_DESCRIPTION}",
    "summary": "[50-word summary of findings]",
    "root_cause": "[concise root cause]",
    "proposed_fix": "[brief fix description]",
    "hypothesis_confirmed": true|false
  }
}
EOF
)

     # Note: Actual Task tool invocation happens in AI execution layer
     # Multiple Task calls in single message for parallel execution
   done
   ```

3. **Collect and synthesize results using forward_message**:
   ```bash
   # Parse all subagent responses
   INVESTIGATION_RESULTS=""
   for i in $(seq 1 $HYPOTHESIS_COUNT); do
     SUBAGENT_OUTPUT="$( # output from Task tool call $i )"

     # Extract metadata using forward_message
     INVESTIGATION_RESULT=$(forward_message "$SUBAGENT_OUTPUT" "debug_investigation_$i")

     # Accumulate results
     INVESTIGATION_RESULTS=$(echo "$INVESTIGATION_RESULTS" | jq ". += [$INVESTIGATION_RESULT]")
   done

   # Identify confirmed hypothesis
   CONFIRMED_INVESTIGATION=$(echo "$INVESTIGATION_RESULTS" | jq -r '.[] | select(.metadata.hypothesis_confirmed == true) | .artifact_path' | head -1)

   # Track context after (metadata only, not full investigations)
   SUMMARIES=$(echo "$INVESTIGATION_RESULTS" | jq -r '.[].metadata.summary' | tr '\n' ' ')
   CONTEXT_AFTER=$(track_context_usage "after" "debug_parallel_investigation" "$SUMMARIES")

   # Calculate reduction
   CONTEXT_REDUCTION=$(calculate_context_reduction "$CONTEXT_BEFORE" "$CONTEXT_AFTER")
   echo "PROGRESS: Parallel investigation complete - context reduction: ${CONTEXT_REDUCTION}%"
   ```

4. **Load confirmed investigation and create consolidated report**:
   ```bash
   if [ -n "$CONFIRMED_INVESTIGATION" ]; then
     # Load full investigation artifact for confirmed hypothesis
     FULL_INVESTIGATION=$(load_metadata_on_demand "$CONFIRMED_INVESTIGATION")

     # Extract root cause and proposed fix
     ROOT_CAUSE=$(echo "$FULL_INVESTIGATION" | jq -r '.root_cause')
     PROPOSED_FIX=$(echo "$FULL_INVESTIGATION" | jq -r '.proposed_fix')

     echo "PROGRESS: Root cause confirmed: $ROOT_CAUSE"
   else
     # No hypothesis confirmed - require manual investigation
     echo "WARNING: No hypothesis confirmed. Manual investigation required."
     ROOT_CAUSE="Investigation inconclusive - see individual investigation reports"
   fi

   # Create consolidated debug report with all investigation paths
   # Include metadata summaries from all hypotheses
   # Reference confirmed investigation for detailed findings
   ```

**Quick Example**:
```bash
# Generate hypotheses
HYPOTHESES='[
  {"hypothesis": "Missing import of refreshToken()", "priority": "high"},
  {"hypothesis": "Incorrect token expiry calculation", "priority": "medium"},
  {"hypothesis": "Session storage race condition", "priority": "low"}
]'

# Invoke 3 debug-analyst agents in parallel (single message, 3 Task tool calls)
# Each creates investigation artifact: specs/042_auth/debug/001_investigation_*.md

# Collect results using forward_message
RESULTS=$(collect_parallel_investigations "$SUBAGENT_OUTPUTS")

# Metadata returned (3 × 50 words = 150 words):
# - Investigation 1: "Hypothesis CONFIRMED: Missing import..."
# - Investigation 2: "Hypothesis REJECTED: Token calculation correct..."
# - Investigation 3: "Hypothesis REJECTED: No race condition detected..."

# Load confirmed investigation only
CONFIRMED_PATH=$(echo "$RESULTS" | jq -r '.[] | select(.metadata.hypothesis_confirmed == true) | .artifact_path')
FULL_INVESTIGATION=$(load_metadata_on_demand "$CONFIRMED_PATH")

# Create consolidated debug report referencing confirmed investigation
# Prune alternative investigations (unconfirmed hypotheses)
```

**Expected Impact**:
- 90% context reduction vs. sequential full investigations (150 words metadata vs. 3 × full reports)
- 60% faster investigation time (parallel vs. sequential)
- Systematic hypothesis validation (no missed alternatives)
- Clear audit trail (all hypotheses documented)

**Integration Points**:
- **Agent template**: `.claude/agents/debug-analyst.md`
- **Utilities**: `artifact-operations.sh` (forward_message, load_metadata_on_demand), `context-metrics.sh` (tracking)
- **Output artifacts**: `specs/{topic}/debug/NNN_investigation_*.md` (one per hypothesis)
- **Consolidated report**: `specs/{topic}/debug/NNN_debug_[issue_name].md` (synthesized findings)

**Error Handling**:
- Agent timeout/failure → Skip hypothesis, log warning, continue with remaining
- All hypotheses rejected → Manual investigation flag in consolidated report
- Multiple hypotheses confirmed → Escalate to user for disambiguation

**Benefits**:
- Parallel investigation eliminates sequential time overhead
- Metadata-based passing preserves context
- All hypotheses explored systematically
- Failed hypotheses documented for future reference
- Clear path from investigation to fix

**STEP 4 (REQUIRED BEFORE STEP 5) - Debug Report Creation Using Uniform Structure**

**EXECUTE NOW - Source Required Utilities**:
```bash
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
```

**Step 2: Determine Topic Directory**
- If plan path provided as context: Extract topic from plan path
- If report path provided: Extract topic from report path
- If no context: Create new topic for debug issue using `get_or_create_topic_dir()`

**Step 3: Create Debug Report**
```bash
# Extract or create topic directory
if [ -n "$PLAN_PATH" ]; then
  # Extract from plan: specs/042_auth/plans/001_plan.md → specs/042_auth
  TOPIC_DIR=$(dirname "$(dirname "$PLAN_PATH")")
elif [ -n "$REPORT_PATH" ]; then
  # Extract from report: specs/042_auth/reports/001_report.md → specs/042_auth
  TOPIC_DIR=$(dirname "$(dirname "$REPORT_PATH")")
else
  # Create new topic for standalone debug
  TOPIC_DIR=$(get_or_create_topic_dir "$ISSUE_DESCRIPTION" "specs")
fi

**STEP B (REQUIRED) - Create Debug Report File with Verification**

**EXECUTE NOW - Create Debug Report File**

**ABSOLUTE REQUIREMENT**: YOU MUST create debug report file and verify creation. This is NOT optional.

**WHY THIS MATTERS**: Debug report is the primary deliverable documenting investigation findings and root cause analysis.

# Create debug report in topic's debug/ subdirectory
DEBUG_PATH=$(create_topic_artifact "$TOPIC_DIR" "debug" "$DEBUG_NAME" "$DEBUG_CONTENT")
# Creates: ${TOPIC_DIR}/debug/NNN_debug_issue.md

# MANDATORY: Verify file exists
if [ ! -f "$DEBUG_PATH" ]; then
  echo "⚠️  DEBUG REPORT NOT FOUND - Triggering fallback mechanism"

  # Fallback: Create file directly with Write tool
  FALLBACK_PATH="${TOPIC_DIR}/debug/${DEBUG_NAME}.md"
  mkdir -p "$(dirname "$FALLBACK_PATH")"

  # Use Write tool to create debug report
  cat > "$FALLBACK_PATH" <<EOF
$DEBUG_CONTENT
EOF

  DEBUG_PATH="$FALLBACK_PATH"
  echo "✓ Fallback debug report created: $DEBUG_PATH"

  # Manual registration in artifact registry
  echo "$DEBUG_PATH" >> "${TOPIC_DIR}/.artifact-registry"
fi

# Verify file is readable and non-empty
if [ ! -s "$DEBUG_PATH" ]; then
  echo "❌ CRITICAL: Debug report empty or unreadable: $DEBUG_PATH"
  exit 1
fi

echo "✓ Debug report created successfully: $DEBUG_PATH"
```

**Fallback Mechanism** (Guarantees 100% Report Creation):
- If `create_topic_artifact` fails → Create file directly with Write tool
- Manual directory creation if needed
- Manual artifact registry update
- File size verification ensures non-empty file

**Benefits**:
- Debug reports in same topic as related plans/reports
- Easy cross-referencing within topic
- Debug reports are committed to git (unlike other artifact types)
- Single utility manages creation

**STEP 5 (REQUIRED) - Spec-Updater Agent Invocation**

**YOU MUST invoke spec-updater agent after debug report creation. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Spec-updater invocation is MANDATORY after debug report file creation
- DO NOT skip cross-reference linking
- DO NOT skip plan annotation
- Fallback mechanism ensures debug report is linked

**IMPORTANT**: After the debug report file is created and written, invoke the spec-updater agent to link the debug report to the related plan and update cross-references.

This step ensures the debug report is properly integrated into the topic structure and the plan is annotated with debugging information.

---

**STEP C (REQUIRED AFTER STEP B) - Invoke Spec-Updater Agent**

**EXECUTE NOW - Link Debug Report via Spec-Updater**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke spec-updater agent to link debug report. This is NOT optional.

**WHY THIS MATTERS**: Cross-reference linking enables navigation between debug reports and plans, essential for tracking debugging history.

#### Step 5.1: Invoke Spec-Updater Agent

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

```
Task {
  subagent_type: "general-purpose"
  description: "Link debug report to plan"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Context:
    - Debug report created at: {debug_report_path}
    - Topic directory: {topic_dir}
    - Related plan: {plan_path}
    - Failed phase: {phase_number} (if applicable)
    - Operation: debug_report_creation

    Tasks:
    1. Add debug report reference to plan metadata:
       - Update plan's "Debug Reports" section (create if missing)
       - Use relative path (e.g., ../debug/NNN_debug_issue.md)

    2. If phase specified, add debugging note to phase section:
       - Add "#### Debugging Notes" subsection after phase tasks
       - Include: Date, Issue, Debug Report link, Root Cause
       - Format for tracking resolution status

    3. Verify debug/ subdirectory is NOT gitignored:
       - Debug reports must be committed to git
       - Check git status to confirm tracking
}
```

**Template Variables** (ONLY allowed modifications):
- `{debug_report_path}`: Absolute debug report file path (from STEP B)
- `{topic_dir}`: Topic directory path
- `{plan_path}`: Related plan file path (if applicable)
- `{phase_number}`: Failed phase number (if applicable)

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Task list (1-3)
- Return format requirements

---

**STEP D (REQUIRED AFTER STEP C) - Mandatory Verification with Fallback**

**MANDATORY VERIFICATION - Confirm Debug Report Linked**

**ABSOLUTE REQUIREMENT**: YOU MUST verify debug report was linked to plan. This is NOT optional.

  4. Update cross-references:
     - Debug report links to plan
     - Plan links to debug report
     - Bidirectional references validated

  Return:
  - Link status (successful/failed)
  - Plan modifications made
  - Gitignore validation result (debug/ should NOT be ignored)
  - Confirmation message for user
```

#### Step 5.2: Handle Spec-Updater Response

After spec-updater completes:
- Display link status to user
- Show which plan file was modified (if any)
- Confirm gitignore compliance (debug/ not ignored)
- If warnings/issues: Show them and suggest fixes

**Example Output**:
```
Debug report linked to plan:
✓ Plan annotated: specs/042_auth/plans/001_implementation.md
✓ Debug report reference added to Phase 3
✓ Gitignore compliance verified (debug/ is committed)
✓ All cross-references validated
```

or if no plan provided:

```
Standalone debug report created:
✓ Report available for future plan linkage
✓ Gitignore compliance verified (debug/ is committed)
✓ Topic structure validated
```

## Report Structure

Debug reports follow the standard structure defined in `.claude/docs/reference/debug-structure.md`.

Key sections include:
- **Problem Statement**: Detailed description of reported vs expected behavior
- **Investigation Process**: Methodology, hypotheses tested, diagnostic tools used
- **Findings**: Root cause analysis with code evidence
- **Proposed Solutions**: Multiple options with pros/cons and effort/risk assessment
- **Recommendations**: Prioritized actions including preventive measures
- **Testing Strategy**: How to validate fixes and prevent regressions
- **Resolution Status**: Tracking for when the issue is fixed

For complete debug report structure and investigation guidelines, see `.claude/docs/reference/debug-structure.md`

## Investigation Techniques

### Code Analysis
- Search for error messages and their sources
- Trace function calls and data flow
- Identify state mutations and side effects
- Review error handling and edge cases

### Pattern Detection
- Look for similar issues in codebase
- Check for known anti-patterns
- Identify missing validation or guards
- Review synchronization and timing issues

### Environmental Checks
- Verify configuration files
- Check environment variables
- Review system dependencies
- Validate file permissions

### Cache and State
- Identify caching mechanisms
- Check for stale data
- Review session persistence
- Examine module loading

## Output

Creates a debug report in the topic-based structure:
```
specs/{NNN_topic}/debug/NNN_debug_[issue_name].md
```

Where:
- `{NNN_topic}` = Three-digit numbered topic directory (e.g., `042_authentication`)
- `NNN` = Next sequential number within topic's debug/ subdirectory

**Important**: Debug reports are **committed to git** (unlike other artifact types which are gitignored). This ensures debugging history is preserved in the repository.

## Best Practices

### DO
- **Be Systematic**: Follow a methodical investigation process
- **Document Everything**: Record all findings, even dead ends
- **Preserve Evidence**: Include relevant code snippets and logs
- **Consider Context**: Review related reports for background
- **Think Broadly**: Consider environmental and timing issues
- **Propose Multiple Solutions**: Offer alternatives when possible

### DON'T
- **Don't Modify Code**: This is investigation only
- **Don't Assume**: Validate hypotheses with evidence
- **Don't Skip Steps**: Thorough investigation prevents recurrence
- **Don't Ignore Warnings**: Small issues can indicate larger problems

## Integration with Other Commands

### Before Debugging
- Use `/list-reports` to find related documentation
- Check existing debug reports for similar issues

### After Debugging
- Use `/plan` to create implementation plan from findings
- Use `/implement` to execute the solution
- Consider `/test` to verify the fix

## Plan Annotation

**When a plan path is provided as an argument:**

After creating the debug report, automatically annotate the plan with debugging history.

### Step 1: Identify Plan and Failed Phase
- Check if any argument is a plan path (e.g., `specs/{NNN_topic}/plans/*.md`)
- If yes: Determine which phase failed (from issue description or plan analysis)
- Extract phase number from user's description or by analyzing plan

### Step 2: Extract Root Cause
- From the debug report just created
- Summarize root cause in one line
- Extract debug report path

### Step 3: Annotate Plan with Debugging Notes
- Use Edit tool to add "#### Debugging Notes" subsection after the failed phase
- Use relative path for debug report link (e.g., `../debug/NNN_debug_*.md`)
- Format:
  ```markdown
  #### Debugging Notes
  - **Date**: [YYYY-MM-DD]
  - **Issue**: [Brief description from issue-description argument]
  - **Debug Report**: [../debug/NNN_debug_issue.md](../debug/NNN_debug_issue.md)
  - **Root Cause**: [One-line summary from debug report]
  - **Resolution**: Pending
  ```

### Step 4: Handle Multiple Debugging Iterations
- Before adding notes: Check if phase already has "#### Debugging Notes"
- If exists: Append new iteration using Edit tool
  ```markdown
  **Iteration 2** (2025-10-03)
  - **Issue**: [New issue description]
  - **Debug Report**: [link to new debug report]
  - **Root Cause**: [New root cause]
  - **Resolution**: Pending
  ```
- If 3+ iterations: Add note `**Status**: Escalated to manual intervention`

### Step 5: Update Resolution When Fixed
**Note for `/implement` command:**
- After a phase with debugging notes passes tests
- Check for "Resolution: Pending" in debugging notes
- Update to "Resolution: Applied"
- Add git commit hash: `Fix Applied In: [commit-hash]`

### Example Annotation

```markdown
### Phase 3: Core Implementation

Tasks:
- [x] Implement main feature
- [x] Add error handling
- [x] Write tests

#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase 3 tests failing with null pointer exception
- **Debug Report**: [../debug/001_debug_phase3.md](../debug/001_debug_phase3.md)
- **Root Cause**: Missing null check in error handler
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

## Common Investigation Areas

### Performance Issues
- Profiling bottlenecks
- Memory leaks
- Inefficient algorithms
- Database query optimization

### Integration Problems
- API compatibility
- Module conflicts
- Version mismatches
- Configuration errors

### State Management
- Race conditions
- Cache invalidation
- Session corruption
- Data synchronization

### User Experience
- Unexpected behavior
- Error message clarity
- Workflow disruptions
- Feature failures

## Checkpoint Reporting

**YOU MUST report debug investigation checkpoint. This is NOT optional.**

**CHECKPOINT REQUIREMENT - Report Debug Investigation Complete**

**ABSOLUTE REQUIREMENT**: After debug report creation and linking, YOU MUST report this checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Checkpoint reporting confirms successful investigation completion with debug report created and cross-referenced.

**Report Format**:

```
CHECKPOINT: Debug Investigation Complete
- Issue: ${ISSUE_DESCRIPTION}
- Debug Report: ${DEBUG_PATH}
- Topic: ${TOPIC_DIR}
- Hypotheses Investigated: ${HYPOTHESIS_COUNT}
- Root Cause: ${ROOT_CAUSE_SUMMARY}
- Plan Annotated: ${PLAN_PATH} (if applicable)
- Status: INVESTIGATION COMPLETE
```

**Required Information**:
- Issue description (from user input)
- Debug report file path (from STEP B)
- Topic directory
- Number of hypotheses investigated (if parallel investigation used)
- Root cause summary (one-line)
- Related plan path (if applicable)
- Investigation complete confirmation

---

## Agent Usage

For agent invocation patterns and error recovery, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns) and [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns).

**Debug-specific agent:**

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| debug-specialist | Root cause analysis and diagnostic reporting | Evidence gathering, structured reporting, multiple solutions |

**Delegation Benefits:**
- Specialized investigation methodology
- Consistent debug report format
- Multiple solution proposals with tradeoffs
- Read-only access (no unintended modifications)
- Reusable diagnostics for future issues

## Notes

- Debug reports are permanent documentation of issues and investigations
- Reports help prevent similar issues in the future
- Clear documentation speeds up resolution when issues recur
- Investigation without implementation allows for careful planning
- The `debug-specialist` agent ensures thorough, structured investigations
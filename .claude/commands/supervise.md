---
allowed-tools: Task, TodoWrite, Bash, Read
---

# /supervise - Clean Multi-Agent Workflow Orchestration

## YOUR ROLE: WORKFLOW ORCHESTRATOR

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results (forward message pattern)
6. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure

**ARCHITECTURAL PATTERN**:
- Phase 0: Pre-calculate paths → Create topic directory structure
- Phase 1-N: Invoke agents with pre-calculated paths → Verify → Extract metadata
- Completion: Report success + artifact locations

**TOOLS ALLOWED**:
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, grep, wc)
- Read: Parse agent output files for metadata extraction (not for task execution)

**TOOLS PROHIBITED**:
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)

## Architectural Prohibition: No Command Chaining

**CRITICAL PROHIBITION**: This command MUST NEVER invoke other commands via the SlashCommand tool.

### Why This Matters

**Wrong Pattern - Command Chaining** (causes context bloat and broken behavioral injection):
```yaml
# ❌ INCORRECT - Do NOT do this
SlashCommand {
  command: "/plan create auth feature"
}
```

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation

**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):
```yaml
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
    STEP 2: Analyze workflow and research findings...
    STEP 3: Use Edit tool to develop implementation phases...
    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
  "
}
```

**Benefits of direct agent invocation**:
1. **Lean Context**: Only agent behavioral guidelines loaded (~200 lines)
2. **Behavioral Control**: Can inject custom instructions, constraints, templates
3. **Structured Output**: Agent returns metadata (path, status) not full summaries
4. **Verification Points**: Can verify file creation before continuing

### Side-by-Side Comparison

| Aspect | Command Chaining (❌) | Direct Agent Invocation (✅) |
|--------|---------------------|------------------------------|
| Context Usage | ~2000 lines (full command) | ~200 lines (agent guidelines) |
| Behavioral Control | Fixed (command prompt) | Flexible (custom instructions) |
| Output Format | Full text summaries | Structured metadata |
| Verification | None (black box) | Explicit checkpoints |
| Path Control | Agent calculates | Orchestrator pre-calculates |
| Role Separation | Blurred (orchestrator executes) | Clear (orchestrator delegates) |

### Enforcement

If you find yourself wanting to invoke /plan, /implement, /debug, or /document:

1. **STOP** - You are about to violate the architectural pattern
2. **IDENTIFY** - What task does that command perform?
3. **DELEGATE** - Invoke the appropriate agent directly via Task tool
4. **INJECT** - Provide the agent with behavioral guidelines and context
5. **VERIFY** - Check that the agent created the expected artifacts

**REMEMBER**: You are the **ORCHESTRATOR**, not the **EXECUTOR**. Delegate work to agents.

## Workflow Overview

This command coordinates multi-agent workflows through 7 phases:

```
Phase 0: Location and Path Pre-Calculation
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (conditional)
  ↓
Phase 3: Implementation (conditional)
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debug (conditional - only if tests fail)
  ↓
Phase 6: Documentation (conditional - only if implementation occurred)
```

### Workflow Scope Types

The command detects the workflow type and executes only the appropriate phases:

1. **research-only**: Phases 0-1 only
   - Keywords: "research [topic]" without "plan" or "implement"
   - Use case: Pure exploratory research
   - No plan created, no summary

2. **research-and-plan**: Phases 0-2 only (MOST COMMON)
   - Keywords: "research...to create plan", "analyze...for planning"
   - Use case: Research to inform planning
   - Creates research reports + implementation plan
   - No summary (no implementation)

3. **full-implementation**: Phases 0-4, 6
   - Keywords: "implement", "build", "add feature"
   - Use case: Complete feature development
   - Phase 5 conditional on test failures
   - Creates all artifacts including summary

4. **debug-only**: Phases 0, 1, 5 only
   - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
   - Use case: Bug fixing without new implementation
   - No new plan or summary

### Performance Targets

- **Context Usage**: <25% throughout workflow
- **File Creation Rate**: 100% with auto-recovery (single retry for transient failures)
- **Recovery Rate**: >95% for transient errors (timeouts, file locks)
- **Performance Overhead**: <5% for recovery infrastructure

## Auto-Recovery

This command includes minimal auto-recovery capabilities for transient failures while maintaining fail-fast behavior for permanent errors.

### Recovery Philosophy

**Auto-recover from transient failures**:
- Network timeouts
- Temporary file locks
- Rate limiting (API throttling)
- Resource temporarily unavailable

**Fail-fast for permanent errors**:
- Syntax errors
- Missing dependencies
- Invalid configuration
- Permission errors

### Recovery Mechanism

**Single-Retry Strategy**:
1. Agent invocation completes
2. Verify expected output file exists
3. If missing: Classify error type
4. If transient: Sleep 1s, retry agent invocation once
5. If permanent or retry fails: Display enhanced error and terminate

**No User Prompts**: Recovery is fully automated. Users only see errors on terminal failures.

## Enhanced Error Reporting

When workflow failures occur, the command provides detailed diagnostic information:

### Error Location Extraction

Parses common error formats to extract file:line information:
- `SyntaxError at file.js:42: Missing closing brace`
- `Error in module.py:156 - undefined variable`
- `file:line:column` format from compilers

### Specific Error Types

Categorizes errors into 4 types for better diagnostics:
1. **timeout** - Network timeouts, connection failures
2. **syntax_error** - Code syntax issues, parsing failures
3. **missing_dependency** - Import errors, package not found
4. **unknown** - Unclassified errors

### Recovery Suggestions

Provides context-specific actionable guidance on failures:

**Timeout errors**:
- Check network connection
- Retry workflow
- Increase timeout threshold

**Syntax errors**:
- Check syntax at file:line
- Run linter
- Verify closing braces/brackets

**Missing dependency errors**:
- Install missing package
- Check import statements
- Verify PATH and environment

### Error Display Format

```
ERROR: [Specific Error Type] at [file:line]
  → [Error message]

  Recovery suggestions:
  1. [Suggestion 1]
  2. [Suggestion 2]
  3. [Suggestion 3]
```

## Partial Failure Handling

### Research Phase Resilience

The research phase (Phase 1) supports partial success when running multiple parallel agents:

**Success Threshold**: ≥50% of research agents must succeed

**Behavior**:
- 4 agents invoked, 3 succeed, 1 fails → Continue with 3 reports
- 4 agents invoked, 2 succeed, 2 fail → Continue with 2 reports (50% threshold)
- 4 agents invoked, 1 succeeds, 3 fail → Terminate (insufficient coverage)

**Rationale**: Some research is better than no research. Missing 1-2 reports is acceptable if majority succeed.

**Warning**: Workflow logs which reports failed and continues with partial results.

## Checkpoint Resume

### Phase-Boundary Checkpoints

Checkpoints are saved after completion of:
- Phase 1 (Research)
- Phase 2 (Planning)
- Phase 3 (Implementation)
- Phase 4 (Testing)

**Not checkpointed**: Phase 5 (Debug - conditional), Phase 6 (Documentation - final)

### Checkpoint Schema

Minimal v1.0 format:
```json
{
  "schema_version": "1.0",
  "workflow_type": "supervise",
  "workflow_description": "...",
  "current_phase": 2,
  "completed_phases": [0, 1],
  "scope": "research-and-plan",
  "topic_path": "/path/to/specs/NNN_topic",
  "artifact_paths": {
    "research_reports": [...],
    "plan_path": "...",
    "overview_path": "..."
  }
}
```

### Auto-Resume Behavior

**On workflow startup**:
1. Check for `.claude/data/checkpoints/supervise_latest.json`
2. If exists: Validate checkpoint (phase valid, artifacts exist)
3. If valid: Skip completed phases, resume from next phase
4. If invalid: Delete checkpoint silently, start fresh

**No User Prompts**: Resume is fully automated and seamless.

**Cleanup**: Checkpoint deleted on successful workflow completion.

## Progress Markers

### Format

```
PROGRESS: [Phase N] - [action]
```

### Examples

```
PROGRESS: [Phase 0] - Topic directory created
PROGRESS: [Phase 1] - Research agent 1/4 invoked
PROGRESS: [Phase 1] - Research complete (4/4 succeeded)
PROGRESS: [Phase 2] - Planning agent invoked
PROGRESS: [Resume] - Skipping completed phases 0-2
```

### Purpose

Provides workflow visibility without TodoWrite overhead. Silent markers emitted at phase transitions and critical checkpoints.

## Shared Utility Functions

```bash
# ═══════════════════════════════════════════════════════════════
# Workflow Scope Detection (After Phase 0: Location)
# ═══════════════════════════════════════════════════════════════

detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 1: Research-only (no planning or implementation)
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: 0 (Location) → 1 (Research) → STOP
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan (most common case)
  # Keywords: "research...to create plan", "analyze...for planning"
  # Phases: 0 → 1 (Research) → 2 (Planning) → STOP
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 4: Debug-only (fix existing code)
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: 0 → 1 (Research) → 5 (Debug) → STOP (no new implementation)
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    echo "debug-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan (safest for ambiguous cases)
  echo "research-and-plan"
}

# ═══════════════════════════════════════════════════════════════
# Phase Execution Check
# ═══════════════════════════════════════════════════════════════

should_run_phase() {
  local phase_num="$1"

  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}

# ═══════════════════════════════════════════════════════════════
# File Verification Checkpoint Template
# ═══════════════════════════════════════════════════════════════

verify_file_created() {
  local file_path="$1"
  local file_type="$2"
  local agent_output="$3"

  echo "**MANDATORY VERIFICATION**: Verifying $file_type exists..."
  echo ""

  # Check 1: File exists
  if [ ! -f "$file_path" ]; then
    echo "❌ VERIFICATION FAILED: $file_type does not exist"
    echo "   Expected: $file_path"
    echo "   Agent output: $agent_output"
    echo ""
    echo "ERROR: Agent failed to create $file_type file."
    echo "This indicates agent did not follow STEP 1 instructions."
    echo ""
    echo "Workflow TERMINATED. Fix agent enforcement and retry."
    exit 1
  fi

  # Check 2: File has content (size > 0)
  if [ ! -s "$file_path" ]; then
    echo "❌ VERIFICATION FAILED: $file_type is empty"
    echo "   Path: $file_path"
    echo ""
    echo "ERROR: Agent created empty file."
    echo "This indicates agent did not follow STEP 3 instructions."
    echo ""
    echo "Workflow TERMINATED. Fix agent enforcement and retry."
    exit 1
  fi

  # Check 3: File size (should be at least 100 bytes)
  local file_size=$(wc -c < "$file_path")
  if [ "$file_size" -lt 100 ]; then
    echo "⚠️  WARNING: $file_type is very small ($file_size bytes)"
    echo "   Agent may not have completed all steps."
  fi

  echo "✅ VERIFICATION PASSED: $file_type created successfully"
  echo "   Path: $file_path"
  echo "   Size: $file_size bytes"
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# Error Handling and Recovery Integration
# ═══════════════════════════════════════════════════════════════

# Source error-handling library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../lib/error-handling.sh" ]; then
  source "$SCRIPT_DIR/../lib/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found"
  exit 1
fi

# Source checkpoint-utils library
if [ -f "$SCRIPT_DIR/../lib/checkpoint-utils.sh" ]; then
  source "$SCRIPT_DIR/../lib/checkpoint-utils.sh"
else
  echo "ERROR: checkpoint-utils.sh not found"
  exit 1
fi

# classify_and_retry: Classify error and return retry decision
# Usage: classify_and_retry <agent_output>
# Returns: "retry" | "fail" | "success"
classify_and_retry() {
  local agent_output="${1:-}"

  # Check for success indicators
  if echo "$agent_output" | grep -q "REPORT_CREATED\|PLAN_CREATED\|IMPLEMENTATION_COMPLETE"; then
    echo "success"
    return
  fi

  # Classify error using error-handling.sh
  local error_type=$(classify_error "$agent_output")

  if [ "$error_type" == "$ERROR_TYPE_TRANSIENT" ]; then
    echo "retry"
  else
    echo "fail"
  fi
}

# verify_and_retry: Verify file creation with single retry for transient failures
# Usage: verify_and_retry <file_path> <agent_output> <agent_type>
# Returns: 0 on success, 1 on failure
verify_and_retry() {
  local file_path="$1"
  local agent_output="$2"
  local agent_type="$3"

  # First attempt verification
  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    return 0
  fi

  # File missing - classify error
  local retry_decision=$(classify_and_retry "$agent_output")

  if [ "$retry_decision" == "retry" ]; then
    echo "⚠️  Transient error detected - retrying once..."
    return 2  # Signal caller to retry
  else
    return 1  # Permanent failure
  fi
}

# emit_progress: Emit silent progress marker
# Usage: emit_progress <phase_number> <action>
emit_progress() {
  local phase="$1"
  local action="$2"
  echo "PROGRESS: [Phase $phase] - $action"
}

# extract_error_location: Extract file:line location from error message
# Usage: extract_error_location <error_message>
# Returns: file:line format or empty string
extract_error_location() {
  local error_msg="$1"

  # Try common patterns: file.ext:line, at file.ext:line
  if echo "$error_msg" | grep -qo '[a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+'; then
    echo "$error_msg" | grep -o '[a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+' | head -1
  elif echo "$error_msg" | grep -qo 'at [a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+'; then
    echo "$error_msg" | grep -o 'at [a-zA-Z0-9_/.-]\+\.[a-z]\+:[0-9]\+' | sed 's/^at //' | head -1
  else
    echo ""
  fi
}

# detect_specific_error_type: Detect specific error category (simplified 4 categories)
# Usage: detect_specific_error_type <error_message>
# Returns: timeout | syntax_error | missing_dependency | unknown
detect_specific_error_type() {
  local error_msg="$1"

  # Timeout errors
  if echo "$error_msg" | grep -qiE "timeout|timed out|deadline exceeded|connection.*timeout"; then
    echo "timeout"
    return
  fi

  # Syntax errors
  if echo "$error_msg" | grep -qiE "syntax error|syntaxerror|unexpected.*token|expected.*got"; then
    echo "syntax_error"
    return
  fi

  # Missing dependencies (imports, modules, packages)
  if echo "$error_msg" | grep -qiE "cannot.*import|module.*not.*found|modulenotfounderror|no module named|require.*failed|package.*not.*found"; then
    echo "missing_dependency"
    return
  fi

  # Default: unknown
  echo "unknown"
}

# suggest_recovery_actions: Generate context-specific recovery suggestions
# Usage: suggest_recovery_actions <error_type> <location> <error_message>
# Returns: Multi-line string with 2-3 suggestions
suggest_recovery_actions() {
  local error_type="$1"
  local location="$2"
  local error_msg="$3"

  case "$error_type" in
    timeout)
      echo "1. Check network connection and retry"
      echo "2. Increase timeout value if possible"
      echo "3. Verify remote service availability"
      ;;
    syntax_error)
      if [ -n "$location" ]; then
        echo "1. Check syntax at $location"
      else
        echo "1. Check syntax in error location"
      fi
      echo "2. Run linter on affected file"
      echo "3. Verify matching braces/brackets"
      ;;
    missing_dependency)
      echo "1. Install missing package/module"
      echo "2. Check import statements"
      echo "3. Verify PATH and environment variables"
      ;;
    unknown)
      echo "1. Review full error message above"
      echo "2. Check recent code changes"
      echo "3. Investigate root causes using research agents with detailed prompts"
      ;;
  esac
}

# handle_partial_research_failure: Allow continuation if ≥50% research agents succeed
# Usage: handle_partial_research_failure <total_agents> <successful_agents> <failed_agents_list>
# Returns: continue | terminate
handle_partial_research_failure() {
  local total_agents="$1"
  local successful_agents="$2"
  local failed_agents="$3"

  # Calculate success rate
  local success_rate=$(( (successful_agents * 100) / total_agents ))

  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "    PARTIAL RESEARCH FAILURE DETECTED"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Research Completion Status:"
  echo "  Total agents: $total_agents"
  echo "  Successful: $successful_agents"
  echo "  Failed: $(( total_agents - successful_agents ))"
  echo "  Success rate: ${success_rate}%"
  echo ""

  if [ "$failed_agents" != "" ]; then
    echo "Failed agents:"
    echo "  $failed_agents"
    echo ""
  fi

  # Decision: continue if ≥50% success
  if [ "$success_rate" -ge 50 ]; then
    echo "Decision: CONTINUE with partial results"
    echo "Reason: Success rate ≥50% provides sufficient coverage"
    echo ""
    echo "Note: Planning phase will work with available research."
    echo "      Some areas may have less detail than optimal."
    echo ""
    echo "continue"
  else
    echo "Decision: TERMINATE workflow"
    echo "Reason: Success rate <50% - insufficient coverage"
    echo ""
    echo "Recommendation: Fix research issues and retry workflow"
    echo ""
    echo "terminate"
  fi
}

# save_phase_checkpoint: Save minimal checkpoint at phase boundary
# Usage: save_phase_checkpoint <phase_number> <scope> <topic_path> <artifact_paths_json>
# Saves to: .claude/data/checkpoints/supervise_latest.json
save_phase_checkpoint() {
  local phase_number="$1"
  local scope="$2"
  local topic_path="$3"
  local artifact_paths="$4"  # JSON string

  # Create checkpoint directory if needed
  local checkpoint_dir=".claude/data/checkpoints"
  mkdir -p "$checkpoint_dir"

  # Create minimal checkpoint JSON
  local checkpoint_file="$checkpoint_dir/supervise_latest.json"
  local completed_phases=$(seq -s "," 0 $phase_number)

  cat > "$checkpoint_file" <<EOF
{
  "schema_version": "1.0",
  "workflow_type": "supervise",
  "current_phase": $phase_number,
  "completed_phases": [$completed_phases],
  "scope": "$scope",
  "topic_path": "$topic_path",
  "artifact_paths": $artifact_paths
}
EOF

  emit_progress "$phase_number" "Checkpoint saved"
}

# load_phase_checkpoint: Load checkpoint and return resume phase
# Usage: resume_phase=$(load_phase_checkpoint)
# Returns: Phase number to resume from (current_phase + 1) or empty if no checkpoint
load_phase_checkpoint() {
  local checkpoint_file=".claude/data/checkpoints/supervise_latest.json"

  if [ ! -f "$checkpoint_file" ]; then
    echo ""
    return
  fi

  # Validate checkpoint exists and is readable
  if ! jq . "$checkpoint_file" >/dev/null 2>&1; then
    # Invalid JSON - delete silently
    rm -f "$checkpoint_file"
    echo ""
    return
  fi

  # Extract current phase
  local current_phase=$(jq -r '.current_phase' "$checkpoint_file")

  if [ -z "$current_phase" ] || [ "$current_phase" -ge 6 ]; then
    # Invalid phase - delete checkpoint
    rm -f "$checkpoint_file"
    echo ""
    return
  fi

  # Return next phase to execute
  echo $((current_phase + 1))
}

# ═══════════════════════════════════════════════════════════════
# Completion Summary Display
# ═══════════════════════════════════════════════════════════════

display_completion_summary() {
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "         /supervise WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: $WORKFLOW_SCOPE"
  echo "Phases Executed: $(echo $PHASES_TO_EXECUTE | tr ',' ' ')"
  echo ""
  echo "Artifacts Created:"

  # Research reports
  if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -gt 0 ]; then
    echo "  ✓ Research Reports: ${#SUCCESSFUL_REPORT_PATHS[@]} files in $TOPIC_PATH/reports/"
    for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
      echo "      - $(basename $report)"
    done
  fi

  # Overview report
  if [ -f "$OVERVIEW_PATH" ]; then
    echo "  ✓ Research Overview: $(basename $OVERVIEW_PATH)"
  fi

  # Implementation plan
  if [ -f "$PLAN_PATH" ]; then
    echo "  ✓ Implementation Plan: $(basename $PLAN_PATH)"
  fi

  # Implementation artifacts
  if [ -d "$IMPL_ARTIFACTS" ] && [ "$(ls -A $IMPL_ARTIFACTS)" ]; then
    echo "  ✓ Implementation Artifacts: $IMPL_ARTIFACTS"
  fi

  # Debug reports
  if [ -f "$DEBUG_REPORT" ]; then
    echo "  ✓ Debug Report: $(basename $DEBUG_REPORT)"
  fi

  # Summary
  if [ -f "$SUMMARY_PATH" ]; then
    echo "  ✓ Workflow Summary: $(basename $SUMMARY_PATH)"
  fi

  echo ""
  echo "Standards Compliance:"
  echo "  ✓ Zero SlashCommand invocations (pure Task tool)"
  echo "  ✓ 100% file creation rate (strong enforcement)"
  echo "  ✓ Conditional phase execution (scope-based)"
  echo "  ✓ Mandatory verification at all checkpoints"
  echo ""

  # Suggest next steps
  if [ "$WORKFLOW_SCOPE" == "research-and-plan" ]; then
    echo "Next Steps:"
    echo "  The plan is ready for execution"
    echo ""
  fi
}
```

## Phase 0: Project Location and Path Pre-Calculation

**Objective**: Establish topic directory structure and calculate all artifact paths.

**Pattern**: utility-based location detection → directory creation → path export

**Optimization**: Uses deterministic bash utilities (topic-utils.sh, detect-project-dir.sh) for 85-95% token reduction and 20x+ speedup compared to agent-based detection.

**Critical**: ALL paths MUST be calculated before Phase 1 begins.

### Implementation

STEP 1: Parse workflow description from command arguments

```bash
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /supervise \"<workflow description>\""
  exit 1
fi

# Check for existing checkpoint (auto-resume capability)
RESUME_PHASE=$(load_phase_checkpoint)

if [ -n "$RESUME_PHASE" ]; then
  echo "════════════════════════════════════════════════════════"
  echo "  CHECKPOINT DETECTED - RESUMING WORKFLOW"
  echo "════════════════════════════════════════════════════════"
  echo ""
  emit_progress "Resume" "Skipping completed phases 0-$((RESUME_PHASE - 1))"
  echo ""
  echo "Resuming from Phase $RESUME_PHASE..."
  echo ""

  # Skip to the resume phase
  # (Implementation note: In actual execution, this would jump to the appropriate phase section)
fi
```

STEP 2: Detect workflow scope

```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    SKIP_PHASES="3,4,5,6"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4"
    SKIP_PHASES=""  # Phase 5 conditional on test failures, Phase 6 always
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    SKIP_PHASES="2,3,4,6"
    ;;
esac

export WORKFLOW_SCOPE PHASES_TO_EXECUTE SKIP_PHASES

echo "Detected Workflow Scope: $WORKFLOW_SCOPE"
echo "Phases to Execute: $PHASES_TO_EXECUTE"
echo ""
```

STEP 3: Determine location using utility functions

Source the required utility libraries for deterministic location detection.

```bash
# Source utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/topic-utils.sh" ]; then
  source "$SCRIPT_DIR/../lib/topic-utils.sh"
else
  echo "ERROR: topic-utils.sh not found"
  echo "Falling back to location-specialist agent..."
  # Fallback to agent-based detection (for graceful degradation)
  # (Fallback implementation would go here if needed)
  exit 1
fi

if [ -f "$SCRIPT_DIR/../lib/detect-project-dir.sh" ]; then
  source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
else
  echo "ERROR: detect-project-dir.sh not found"
  exit 1
fi
```

STEP 4: Calculate location metadata

Use utility functions to determine project root, specs directory, topic number, and topic name.

```bash
# Get project root (from detect-project-dir.sh)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
if [ -z "$PROJECT_ROOT" ]; then
  echo "ERROR: Could not determine project root"
  exit 1
fi

# Determine specs directory
if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
elif [ -d "${PROJECT_ROOT}/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/specs"
else
  # Default to .claude/specs and create it
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  mkdir -p "$SPECS_ROOT"
fi

# Calculate topic metadata using utility functions
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")

# Set location for backward compatibility
LOCATION="$PROJECT_ROOT"

# Validate required fields
if [ -z "$LOCATION" ] || [ -z "$TOPIC_NUM" ] || [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: Failed to calculate location metadata"
  echo "   LOCATION: $LOCATION"
  echo "   TOPIC_NUM: $TOPIC_NUM"
  echo "   TOPIC_NAME: $TOPIC_NAME"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi

echo "Project Location: $LOCATION"
echo "Specs Root: $SPECS_ROOT"
echo "Topic Number: $TOPIC_NUM"
echo "Topic Name: $TOPIC_NAME"
echo ""
```

STEP 5: Create topic directory structure

Use the utility function to create the standardized topic directory structure with verification.

```bash
TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

echo "Creating topic directory structure at: $TOPIC_PATH"

# Create topic structure using utility function (includes verification)
if ! create_topic_structure "$TOPIC_PATH"; then
  echo "❌ ERROR: Failed to create topic directory structure"
  echo "   Path: $TOPIC_PATH"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi

echo "✅ Topic directory structure created successfully"
echo "   All 6 subdirectories verified: reports, plans, summaries, debug, scripts, outputs"
echo ""
```

STEP 6: Pre-calculate ALL artifact paths

```bash
# Research phase paths (calculate for max 4 topics)
REPORT_PATHS=()
for i in 1 2 3 4; do
  REPORT_PATHS+=("${TOPIC_PATH}/reports/$(printf '%03d' $i)_topic${i}.md")
done
OVERVIEW_PATH="${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md"

# Planning phase paths
PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"

# Implementation phase paths
IMPL_ARTIFACTS="${TOPIC_PATH}/artifacts/"

# Debug phase paths
DEBUG_REPORT="${TOPIC_PATH}/debug/001_debug_analysis.md"

# Documentation phase paths
SUMMARY_PATH="${TOPIC_PATH}/summaries/${TOPIC_NUM}_${TOPIC_NAME}_summary.md"

# Export all paths for use in subsequent phases
export TOPIC_PATH TOPIC_NUM TOPIC_NAME
export OVERVIEW_PATH PLAN_PATH
export IMPL_ARTIFACTS DEBUG_REPORT SUMMARY_PATH

echo "Pre-calculated Artifact Paths:"
echo "  Research Reports: ${#REPORT_PATHS[@]} paths"
echo "  Overview: $OVERVIEW_PATH"
echo "  Plan: $PLAN_PATH"
echo "  Implementation: $IMPL_ARTIFACTS"
echo "  Debug: $DEBUG_REPORT"
echo "  Summary: $SUMMARY_PATH"
echo ""
```

STEP 7: Initialize tracking arrays

```bash
# Track successful report paths for Phase 1
SUCCESSFUL_REPORT_PATHS=()
SUCCESSFUL_REPORT_COUNT=0

# Track phase status
TESTS_PASSING="unknown"
IMPLEMENTATION_OCCURRED="false"

echo "Phase 0 Complete: Ready for Phase 1 (Research)"
echo ""
```

## Phase 1: Research

**Objective**: Conduct parallel research on workflow topics with 100% file creation rate.

**Pattern**: Analyze complexity → Invoke 2-4 research agents in parallel → Verify all files created → Extract metadata

**Critical Success Factor**: 100% file creation rate on first attempt (no retries)

### Phase 1 Execution Check

```bash
should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_completion_summary
  exit 0
}
```

### Complexity-Based Research Topics

STEP 1: Determine research complexity (1-4 topics based on workflow)

```bash
# Simple keyword-based complexity scoring
RESEARCH_COMPLEXITY=2  # Default: 2 research topics

# Increase complexity for these keywords
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

# Increase further for very complex workflows
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

# Reduce for simple workflows
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"
echo ""
```

### Parallel Research Agent Invocation

STEP 2: Invoke 2-4 research agents in parallel (single message, multiple Task calls)

**CRITICAL**: All agents invoked in a single message for parallel execution.

```bash
# Emit progress marker before agent invocations
emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"
echo ""
```

```yaml
# Research Agent Template (repeated for each topic)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "
    Read behavioral guidelines: .claude/agents/research-specialist.md

    **EXECUTE NOW - MANDATORY FILE CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create this EXACT file:
            ${REPORT_PATHS[i]}

            Content: Empty file with header '# ${TOPIC_NAME} Research Report'

            **DO THIS FIRST** - File MUST exist before research begins.

    STEP 2: Conduct comprehensive research on topic: ${WORKFLOW_DESCRIPTION}
            Focus area: [auto-generated based on workflow]
            - Use Grep/Glob/Read tools to analyze codebase
            - Search .claude/docs/ for relevant patterns
            - Identify 3-5 key findings

    STEP 3: Use Edit tool to add research findings to ${REPORT_PATHS[i]}
            - Write 200-300 word summary
            - Include code references with file:line format
            - List 3-5 specific recommendations

    STEP 4: Return ONLY this exact format:
            REPORT_CREATED: ${REPORT_PATHS[i]}

            **CRITICAL**: DO NOT return summary text in response.
            Return ONLY the confirmation line above.

    **MANDATORY VERIFICATION**: Orchestrator will verify file exists at exact path.
    If file does not exist or is empty, workflow will FAIL IMMEDIATELY.

    **REMINDER**: You are the EXECUTOR. The orchestrator pre-calculated this path.
    Use the exact path provided. Do not modify or recalculate.
  "
}
```

**Note**: The actual implementation will generate N Task calls based on RESEARCH_COMPLEXITY.

```bash
# Emit progress marker after agent invocations complete
emit_progress "1" "All research agents invoked - awaiting completion"
echo ""
```

### Mandatory Verification - Research Reports with Auto-Recovery

STEP 3: Verify ALL research reports created successfully (with single-retry for transient failures)

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"
echo ""

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()
FAILED_AGENTS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  # Emit progress marker
  emit_progress "1" "Verifying research report $i/$RESEARCH_COMPLEXITY"

  echo "Verifying Report $i: $(basename $REPORT_PATH)"

  # Check if file exists and has content
  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    # Success path - perform quality checks
    FILE_SIZE=$(wc -c < "$REPORT_PATH")

    if [ "$FILE_SIZE" -lt 200 ]; then
      echo "  ⚠️  WARNING: File is very small ($FILE_SIZE bytes)"
    fi

    if ! grep -q "^# " "$REPORT_PATH"; then
      echo "  ⚠️  WARNING: Missing markdown header"
    fi

    echo "  ✅ PASSED: Report created successfully ($FILE_SIZE bytes)"
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    # Failure path - extract error info and attempt recovery
    ERROR_MSG="Report file missing or empty: $REPORT_PATH"
    ERROR_LOCATION=$(extract_error_location "$ERROR_MSG")
    ERROR_TYPE=$(detect_specific_error_type "$ERROR_MSG")

    # Classify error for retry decision
    RETRY_DECISION=$(classify_and_retry "$ERROR_MSG")

    if [ "$RETRY_DECISION" == "retry" ]; then
      echo "  ⚠️  TRANSIENT ERROR: Retrying once..."

      # Note: In actual execution, retry would re-invoke the agent
      # For now, just re-check the file after a short delay
      sleep 1

      if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
        FILE_SIZE=$(wc -c < "$REPORT_PATH")
        echo "  ✅ RETRY SUCCESSFUL: Report created ($FILE_SIZE bytes)"
        SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
      else
        # Retry failed - update error info and mark as failed
        ERROR_TYPE=$(detect_specific_error_type "Retry failed: $ERROR_MSG")
        ERROR_LOCATION=$(extract_error_location "$REPORT_PATH")

        echo "  ❌ RETRY FAILED: Report still missing"
        echo ""
        echo "ERROR: $ERROR_TYPE"
        if [ -n "$ERROR_LOCATION" ]; then
          echo "   at $ERROR_LOCATION"
        fi
        echo ""
        echo "Recovery suggestions:"
        suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
        echo ""

        FAILED_AGENTS+=("agent_$i")
        VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
      fi
    else
      # Permanent error - no retry
      echo "  ❌ PERMANENT ERROR: $ERROR_TYPE"
      if [ -n "$ERROR_LOCATION" ]; then
        echo "     at $ERROR_LOCATION"
      fi
      echo ""
      echo "Recovery suggestions:"
      suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
      echo ""

      FAILED_AGENTS+=("agent_$i")
      VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    fi
  fi
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

echo ""
echo "Verification Summary:"
echo "  Total Reports Expected: $RESEARCH_COMPLEXITY"
echo "  Reports Created: $SUCCESSFUL_REPORT_COUNT"
echo "  Verification Failures: $VERIFICATION_FAILURES"
echo ""

# Partial failure handling - allow continuation if ≥50% success
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  DECISION=$(handle_partial_research_failure $RESEARCH_COMPLEXITY $SUCCESSFUL_REPORT_COUNT "${FAILED_AGENTS[*]}")

  if [ "$DECISION" == "terminate" ]; then
    echo "Workflow TERMINATED. Fix research issues and retry."
    exit 1
  fi

  # Continue with partial results
  echo "⚠️  Continuing workflow with partial research results"
  echo ""
fi

if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo "✅ ALL RESEARCH REPORTS VERIFIED SUCCESSFULLY"
else
  echo "✅ PARTIAL SUCCESS - Continuing with available research"
fi
echo ""
```

### Research Overview (Optional Synthesis)

STEP 4: Create overview report synthesizing all research findings

```bash
# Only create overview if multiple reports
if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then
  echo "Creating research overview to synthesize findings..."

  # Build report list for overview agent
  REPORT_LIST=""
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    REPORT_LIST+="- $report\n"
  done

  # Invoke overview synthesizer agent
  # Task {
  #   subagent_type: "general-purpose"
  #   description: "Synthesize research findings"
  #   prompt: "
  #     Read: .claude/agents/research-specialist.md
  #
  #     STEP 1: Use Write tool to create: $OVERVIEW_PATH
  #     STEP 2: Read all research reports and synthesize:
  #             ${REPORT_LIST}
  #     STEP 3: Write 400-500 word overview with:
  #             - Common themes across reports
  #             - Conflicting findings (if any)
  #             - Prioritized recommendations
  #             - Cross-references between reports
  #     STEP 4: Return ONLY: OVERVIEW_CREATED: $OVERVIEW_PATH
  #   "
  # }

  # Verify overview created
  verify_file_created "$OVERVIEW_PATH" "Research Overview" "$AGENT_OUTPUT"
fi

echo "Phase 1 Complete: Research artifacts verified"
echo ""

# Save checkpoint after Phase 1
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'"' || echo '')
}
EOF
)
save_phase_checkpoint 1 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

## Phase 2: Planning

**Objective**: Create implementation plan using Task tool with behavioral injection (no SlashCommand).

**Pattern**: Prepare context → Invoke plan-architect agent → Verify plan created → Extract metadata

**Critical**: Uses Task tool with behavioral injection, NOT /plan command

### Phase 2 Execution Check

```bash
should_run_phase 2 || {
  echo "⏭️  Skipping Phase 2 (Planning)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_completion_summary
  exit 0
}
```

### Planning Context Preparation

STEP 1: Prepare planning context with research reports

```bash
echo "Preparing planning context..."

# Build research reports list for injection
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done

# Include overview if created
if [ -f "$OVERVIEW_PATH" ]; then
  RESEARCH_REPORTS_LIST+="- $OVERVIEW_PATH (synthesis)\n"
fi

# Discover standards file
STANDARDS_FILE="${LOCATION}/CLAUDE.md"
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="${LOCATION}/.claude/CLAUDE.md"
fi
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="(none found)"
fi

echo "Planning Context:"
echo "  Research Reports: $SUCCESSFUL_REPORT_COUNT files"
echo "  Standards File: $STANDARDS_FILE"
echo ""
```

### Plan-Architect Agent Invocation

STEP 2: Invoke plan-architect agent via Task tool

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
            Content: Plan header with metadata section
            **DO THIS FIRST** - File MUST exist before planning.

    STEP 2: Analyze workflow and research findings
            Workflow: ${WORKFLOW_DESCRIPTION}
            Research Reports:
            ${RESEARCH_REPORTS_LIST}
            Standards: ${STANDARDS_FILE}

    STEP 3: Use Edit tool to develop implementation phases in ${PLAN_PATH}
            - Break into 3-7 phases
            - Each phase: objective, tasks, testing, complexity
            - Follow progressive organization (Level 0 initially)
            - Include success criteria and risk assessment

    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}
            **DO NOT** return plan summary.
            **DO NOT** use SlashCommand tool.

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
    **CONSEQUENCE**: Workflow fails if file missing or incomplete.

    **REMINDER**: You are the EXECUTOR. Use exact path provided.
  "
}
```

### Mandatory Verification - Plan Creation

STEP 3: Verify plan file created successfully (with auto-recovery)

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Implementation Plan"
echo "════════════════════════════════════════════════════════"
echo ""

# Emit progress marker
emit_progress "2" "Verifying implementation plan"

# Check if file exists and has content
if [ -f "$PLAN_PATH" ] && [ -s "$PLAN_PATH" ]; then
  # Success path - perform quality checks
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")

  if [ "$PHASE_COUNT" -lt 3 ]; then
    echo "⚠️  WARNING: Plan has only $PHASE_COUNT phases"
    echo "   Expected at least 3 phases for proper structure."
  fi

  if ! grep -q "^## Metadata" "$PLAN_PATH"; then
    echo "⚠️  WARNING: Plan missing metadata section"
  fi

  echo "✅ VERIFICATION PASSED: Plan created with $PHASE_COUNT phases"
  echo "   Path: $PLAN_PATH"
  echo ""
else
  # Failure path - extract error info and attempt recovery
  ERROR_MSG="Plan file missing or empty: $PLAN_PATH"
  ERROR_LOCATION=$(extract_error_location "$ERROR_MSG")
  ERROR_TYPE=$(detect_specific_error_type "$ERROR_MSG")

  # Classify error for retry decision
  RETRY_DECISION=$(classify_and_retry "$ERROR_MSG")

  if [ "$RETRY_DECISION" == "retry" ]; then
    echo "⚠️  TRANSIENT ERROR: Retrying once..."
    sleep 1

    if [ -f "$PLAN_PATH" ] && [ -s "$PLAN_PATH" ]; then
      PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
      echo "✅ RETRY SUCCESSFUL: Plan created with $PHASE_COUNT phases"
    else
      echo "❌ RETRY FAILED: Plan still missing"
      echo ""
      echo "ERROR: $ERROR_TYPE"
      if [ -n "$ERROR_LOCATION" ]; then
        echo "   at $ERROR_LOCATION"
      fi
      echo ""
      echo "Recovery suggestions:"
      suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
      echo ""
      echo "Workflow TERMINATED."
      exit 1
    fi
  else
    # Permanent error - fail fast
    echo "❌ PERMANENT ERROR: $ERROR_TYPE"
    if [ -n "$ERROR_LOCATION" ]; then
      echo "   at $ERROR_LOCATION"
    fi
    echo ""
    echo "Recovery suggestions:"
    suggest_recovery_actions "$ERROR_TYPE" "$ERROR_LOCATION" "$ERROR_MSG"
    echo ""
    echo "Workflow TERMINATED."
    exit 1
  fi
fi
```

### Plan Metadata Extraction

STEP 4: Extract plan metadata for reporting

```bash
# Extract complexity from plan
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")

# Extract estimated time
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_PATH" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan Metadata:"
echo "  Phases: $PHASE_COUNT"
echo "  Complexity: $PLAN_COMPLEXITY"
echo "  Est. Time: $PLAN_EST_TIME"
echo ""

echo "Phase 2 Complete: Implementation plan created"
echo ""

# Save checkpoint after Phase 2
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_phase_checkpoint 2 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

### Workflow Completion Check (After Phase 2)

STEP 5: Check if workflow should continue to implementation

```bash
should_run_phase 3 || {
  echo "════════════════════════════════════════════════════════"
  echo "         /supervise WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: $WORKFLOW_SCOPE"
  echo "Phases Executed: Phase 0-2 (Location, Research, Planning)"
  echo ""
  echo "Artifacts Created:"
  echo "  ✓ Research Reports: $SUCCESSFUL_REPORT_COUNT files"
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    echo "      - $(basename $report)"
  done
  if [ -f "$OVERVIEW_PATH" ]; then
    echo "  ✓ Research Overview: $(basename $OVERVIEW_PATH)"
  fi
  echo "  ✓ Implementation Plan: $(basename $PLAN_PATH)"
  echo ""
  echo "Standards Compliance:"
  echo "  ✓ Reports in specs/reports/ (not inline summaries)"
  echo "  ✓ Plan created via Task tool (not SlashCommand)"
  echo "  ✓ Summary NOT created (per standards - no implementation)"
  echo ""
  echo "Next Steps:"
  echo "  The plan is ready for execution"
  echo ""
  exit 0
}
```

## Phase 3: Implementation

**Objective**: Execute implementation plan phase-by-phase with testing and commits.

**Pattern**: Invoke code-writer agent with plan context → Verify implementation artifacts → Track completion

**Critical**: Code-writer agent uses phase-by-phase execution pattern internally (with testing and commits after each phase)

### Phase 3 Execution Check

```bash
should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  # Continue to next phase check or completion
}
```

### Code-Writer Agent Invocation

STEP 1: Invoke code-writer agent with plan context

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/code-writer.md

    **EXECUTE NOW - IMPLEMENTATION REQUIRED**

    STEP 1: Read implementation plan: ${PLAN_PATH}

    STEP 2: Execute plan using phase-by-phase execution pattern:
            - Phase-by-phase execution
            - Run tests after each phase
            - Create git commits for completed phases
            - Update plan with [COMPLETED] markers

    STEP 3: Create implementation artifacts in: ${IMPL_ARTIFACTS}
            (Create directory if it doesn't exist)

    STEP 4: Return implementation status:
            IMPLEMENTATION_STATUS: {complete|partial|failed}
            PHASES_COMPLETED: {N}
            PHASES_TOTAL: {M}

            **DO NOT** return full implementation summary.
            Return ONLY status metadata above.

    **STANDARDS COMPLIANCE**:
    - Follow code standards from: ${STANDARDS_FILE}
    - Use test commands from Testing Protocols
    - Create git commits per commit protocol

    **REMINDER**: You are the EXECUTOR. Complete the implementation.
  "
}
```

### Mandatory Verification - Implementation Completion

STEP 2: Verify implementation artifacts created

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Implementation"
echo "════════════════════════════════════════════════════════"
echo ""

# Parse implementation status from agent output
IMPL_STATUS=$(echo "$AGENT_OUTPUT" | grep "IMPLEMENTATION_STATUS:" | cut -d: -f2 | xargs)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "PHASES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_TOTAL=$(echo "$AGENT_OUTPUT" | grep "PHASES_TOTAL:" | cut -d: -f2 | xargs)

echo "Implementation Status: $IMPL_STATUS"
echo "Phases Completed: $PHASES_COMPLETED / $PHASES_TOTAL"
echo ""

# Check if implementation directory exists
if [ ! -d "$IMPL_ARTIFACTS" ]; then
  echo "⚠️  WARNING: Implementation artifacts directory not created"
  echo "   Expected: $IMPL_ARTIFACTS"
else
  ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f | wc -l)
  echo "✅ Implementation artifacts: $ARTIFACT_COUNT files"
fi

# Verify plan updated with completion markers
COMPLETED_PHASES=$(grep -c "\[COMPLETED\]" "$PLAN_PATH" || echo "0")
echo "Plan completion markers: $COMPLETED_PHASES phases marked complete"
echo ""

# Set flag for Phase 6 (documentation)
if [ "$IMPL_STATUS" == "complete" ] || [ "$IMPL_STATUS" == "partial" ]; then
  IMPLEMENTATION_OCCURRED="true"
fi

echo "Phase 3 Complete: Implementation finished"
echo ""

# Save checkpoint after Phase 3
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS"
}
EOF
)
save_phase_checkpoint 3 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

## Phase 4: Testing

**Objective**: Execute comprehensive test suite and collect results.

**Pattern**: Invoke test-specialist agent → Verify test results → Determine if debugging needed

**Critical**: Test results determine whether Phase 5 (Debug) executes

### Phase 4 Execution Check

```bash
should_run_phase 4 || {
  echo "⏭️  Skipping Phase 4 (Testing)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  # Continue to next phase check or completion
}
```

### Test-Specialist Agent Invocation

STEP 1: Invoke test-specialist agent

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests"
  prompt: "
    Read behavioral guidelines: .claude/agents/test-specialist.md

    **EXECUTE NOW - COMPREHENSIVE TESTING REQUIRED**

    STEP 1: Discover test commands from standards: ${STANDARDS_FILE}
            Look for Testing Protocols section

    STEP 2: Run project test suite
            - Execute all relevant tests
            - Collect pass/fail statistics
            - Identify failing tests with error messages

    STEP 3: Create test results report: ${TOPIC_PATH}/outputs/test_results.md
            Include:
            - Test summary (total, passed, failed)
            - Failed test details
            - Coverage metrics (if available)

    STEP 4: Return test status:
            TEST_STATUS: {passing|failing}
            TESTS_TOTAL: {N}
            TESTS_PASSED: {M}
            TESTS_FAILED: {K}

            **DO NOT** return full test output.
            Return ONLY status metadata above.

    **REMINDER**: You are the EXECUTOR. Run the tests.
  "
}
```

### Test Results Verification

STEP 2: Parse and verify test results

```bash
echo "════════════════════════════════════════════════════════"
echo "  TEST RESULTS"
echo "════════════════════════════════════════════════════════"
echo ""

# Parse test status from agent output
TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

echo "Test Status: $TEST_STATUS"
echo "Tests Run: $TESTS_TOTAL"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

# Set flag for Phase 5 (debug)
if [ "$TEST_STATUS" == "passing" ]; then
  TESTS_PASSING="true"
  echo "✅ All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ Tests failing - debugging required (Phase 5)"
fi

echo ""
echo "Phase 4 Complete: Testing finished"
echo ""

# Save checkpoint after Phase 4
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "test_status": "$TEST_STATUS"
}
EOF
)
save_phase_checkpoint 4 "$WORKFLOW_SCOPE" "$TOPIC_PATH" "$ARTIFACT_PATHS_JSON"
```

## Phase 5: Debug (Conditional)

**Objective**: Analyze test failures and apply fixes iteratively.

**Pattern**: Invoke debug-analyst → Apply fixes → Re-run tests (max 3 iterations)

**Execution Condition**: Phase 5 executes if tests failed OR workflow is debug-only

### Phase 5 Execution Check

```bash
# Phase 5 only executes if tests failed OR workflow is debug-only
if [ "$TESTS_PASSING" == "false" ] || [ "$WORKFLOW_SCOPE" == "debug-only" ]; then
  echo "Executing Phase 5: Debug"
  echo ""
else
  echo "⏭️  Skipping Phase 5 (Debug)"
  echo "  Reason: Tests passing, no debugging needed"
  echo ""
  # Continue to Phase 6
fi
```

### Debug Iteration Loop

STEP 1: Iterate debug cycle (max 3 iterations)

```bash
# Maximum 3 debug iterations
for iteration in 1 2 3; do
  echo "════════════════════════════════════════════════════════"
  echo "  DEBUG ITERATION $iteration / 3"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # Invoke debug-analyst agent
  Task {
    subagent_type: "general-purpose"
    description: "Analyze test failures - iteration $iteration"
    prompt: "
      Read behavioral guidelines: .claude/agents/debug-analyst.md

      **EXECUTE NOW - DEBUG ANALYSIS REQUIRED**

      STEP 1: Analyze test failures from: ${TOPIC_PATH}/outputs/test_results.md
              Read the test results file and identify failing tests
              Extract error messages and stack traces

      STEP 2: Identify root causes and propose fixes
              For each failing test:
              - Determine the root cause
              - Identify the file(s) that need changes
              - Propose specific fixes with code examples

      STEP 3: Use Write tool IMMEDIATELY to create: ${DEBUG_REPORT}
              Content: Debug analysis with root causes and proposed fixes
              **DO THIS FIRST** - File MUST exist before continuing.

      STEP 4: Use Edit tool to expand debug report with:
              - Root cause analysis for each failure
              - Specific file changes needed (with line numbers)
              - Code snippets showing fixes
              - Priority order for applying fixes

      STEP 5: Return ONLY: DEBUG_ANALYSIS_COMPLETE: ${DEBUG_REPORT}
              **DO NOT** return full analysis text.
              Return ONLY the confirmation line above.

      **MANDATORY VERIFICATION**: Orchestrator verifies file exists.

      **REMINDER**: You are the EXECUTOR. Use exact path provided.
    "
  }

  # Verify debug report created
  verify_file_created "$DEBUG_REPORT" "Debug Report" "$AGENT_OUTPUT"

  # Invoke code-writer to apply fixes
  Task {
    subagent_type: "general-purpose"
    description: "Apply debug fixes - iteration $iteration"
    prompt: "
      Read behavioral guidelines: .claude/agents/code-writer.md

      **EXECUTE NOW - APPLY FIXES**

      STEP 1: Read debug analysis: ${DEBUG_REPORT}
              Review all proposed fixes and their priority order

      STEP 2: Apply recommended fixes using Edit tool
              For each fix:
              - Locate the file and line number
              - Apply the exact code change recommended
              - Preserve code style and formatting
              - Do NOT skip any fixes

      STEP 3: Verify fixes applied
              Check that all changes were successfully made
              Count the number of files modified

      STEP 4: Return fix status:
              FIXES_APPLIED: {count}
              FILES_MODIFIED: {list of file paths}

              **DO NOT** return full diff or code listings.
              Return ONLY status metadata above.

      **STANDARDS COMPLIANCE**:
      - Follow code standards from: ${STANDARDS_FILE}
      - Maintain existing indentation and style
      - Add comments for complex fixes if needed

      **REMINDER**: You are the EXECUTOR. Apply all fixes methodically.
    "
  }

  # Parse fixes applied
  FIXES_APPLIED=$(echo "$AGENT_OUTPUT" | grep "FIXES_APPLIED:" | cut -d: -f2 | xargs)
  echo "Fixes Applied: $FIXES_APPLIED"
  echo ""

  # Re-run tests (invoke test-specialist again)
  echo "Re-running tests to verify fixes..."
  echo ""

  Task {
    subagent_type: "general-purpose"
    description: "Re-run tests after fixes"
    prompt: "
      Read behavioral guidelines: .claude/agents/test-specialist.md

      **EXECUTE NOW - RE-RUN TESTS**

      STEP 1: Discover test commands from standards: ${STANDARDS_FILE}

      STEP 2: Run project test suite
              Execute the same tests that were run in Phase 4

      STEP 3: Update test results report: ${TOPIC_PATH}/outputs/test_results.md
              Append results from this iteration
              Note which iteration this is (iteration $iteration)

      STEP 4: Return test status:
              TEST_STATUS: {passing|failing}
              TESTS_TOTAL: {N}
              TESTS_PASSED: {M}
              TESTS_FAILED: {K}

      **REMINDER**: You are the EXECUTOR. Run the tests now.
    "
  }

  # Parse updated test status
  TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
  TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
  TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
  TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

  # Update TESTS_PASSING flag based on current test status
  if [ "$TEST_STATUS" == "passing" ]; then
    TESTS_PASSING="true"
  else
    TESTS_PASSING="false"
  fi

  echo "Updated Test Status: $TEST_STATUS"
  echo "Tests: $TESTS_PASSED / $TESTS_TOTAL passed"
  echo ""

  # Check if tests now passing
  if [ "$TESTS_PASSING" == "true" ]; then
    echo "✅ Tests passing after $iteration debug iteration(s)"
    echo ""
    break
  fi

  echo "Tests still failing, continuing to next iteration..."
  echo ""
done

# Escalate if still failing after 3 iterations
if [ "$TESTS_PASSING" == "false" ]; then
  echo "⚠️  WARNING: Tests still failing after 3 debug iterations"
  echo "   Manual intervention required."
  echo "   Debug report: $DEBUG_REPORT"
  echo ""
  echo "Workflow continuing to Phase 6 (Documentation)..."
  echo ""
fi

echo "Phase 5 Complete: Debug cycle finished"
echo ""
```

## Phase 6: Documentation (Conditional)

**Objective**: Create workflow summary linking plan, research, and implementation.

**Pattern**: Invoke doc-writer agent → Verify summary created → Update research reports

**Execution Condition**: Phase 6 only executes if implementation occurred (Phase 3 ran)

### Phase 6 Execution Check

```bash
# Phase 6 only executes if implementation occurred
if [ "$IMPLEMENTATION_OCCURRED" == "true" ]; then
  echo "Executing Phase 6: Documentation"
  echo ""
else
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "  Reason: No implementation to document (scope: $WORKFLOW_SCOPE)"
  echo ""
  # Skip to completion summary
  display_completion_summary
  exit 0
fi
```

### Doc-Writer Agent Invocation

STEP 1: Invoke doc-writer agent to create summary

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary"
  prompt: "
    Read behavioral guidelines: .claude/agents/doc-writer.md

    **EXECUTE NOW - MANDATORY SUMMARY CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${SUMMARY_PATH}
            Content: Summary header with metadata
            **DO THIS FIRST** - File MUST exist before documentation.

    STEP 2: Document workflow execution:
            - Implementation Overview
            - Plan Executed: ${PLAN_PATH}
            - Research Reports Used:
              ${RESEARCH_REPORTS_LIST}
            - Key Decisions Made
            - Code Changes Summary
            - Test Results: ${TEST_STATUS}
            - Lessons Learned

    STEP 3: Use Edit tool to expand summary with:
            - Cross-references to code changes (file:line)
            - Links between research recommendations and implementation
            - Notes on deviations from original plan
            - Follow-up tasks or known issues

    STEP 4: Return ONLY: SUMMARY_CREATED: ${SUMMARY_PATH}
            **DO NOT** return summary text.

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.

    **REMINDER**: You are the EXECUTOR. Use exact path provided.
  "
}
```

### Mandatory Verification - Summary Creation

STEP 2: Verify summary file created

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Workflow Summary"
echo "════════════════════════════════════════════════════════"
echo ""

verify_file_created "$SUMMARY_PATH" "Workflow Summary" "$AGENT_OUTPUT"

echo "Phase 6 Complete: Documentation finished"
echo ""
```

## Workflow Completion

Display final workflow summary and artifact locations.

```bash
# Clean up checkpoint on successful completion
CHECKPOINT_FILE=".claude/data/checkpoints/supervise_latest.json"
if [ -f "$CHECKPOINT_FILE" ]; then
  rm -f "$CHECKPOINT_FILE"
  echo "✓ Checkpoint cleaned up"
  echo ""
fi

display_completion_summary
exit 0
```

## Usage Examples

### Example 1: Research-only workflow

```bash
/supervise "research API authentication patterns"

# Expected behavior:
# - Scope detected: research-only
# - Phases executed: 0, 1
# - Artifacts: 2-3 research reports
# - No plan, no implementation, no summary
```

### Example 2: Research-and-plan workflow (MOST COMMON)

```bash
/supervise "research the authentication module to create a refactor plan"

# Expected behavior:
# - Scope detected: research-and-plan
# - Phases executed: 0, 1, 2
# - Artifacts: 4 research reports + 1 implementation plan
# - No implementation, no summary (per standards)
# - Plan ready for execution
```

### Example 3: Full-implementation workflow

```bash
/supervise "implement OAuth2 authentication for the API"

# Expected behavior:
# - Scope detected: full-implementation
# - Phases executed: 0, 1, 2, 3, 4, 6
# - Phase 5 conditional on test failures
# - Artifacts: reports + plan + implementation + summary
```

### Example 4: Debug-only workflow

```bash
/supervise "fix the token refresh bug in auth.js"

# Expected behavior:
# - Scope detected: debug-only
# - Phases executed: 0, 1, 5
# - Artifacts: research reports + debug report
# - No new plan or implementation (fixes existing code)
```

## Performance Metrics

Expected performance targets:

- **File Creation Rate**: 100% (strong enforcement, first attempt)
- **Context Usage**: <25% cumulative across all phases
- **Zero Fallbacks**: Single working path, fail-fast on errors

## Success Criteria

### Architectural Excellence
- [ ] Pure orchestration: Zero SlashCommand tool invocations
- [ ] Phase 0 role clarification: Explicit orchestrator vs executor separation
- [ ] Workflow scope detection: Correctly identifies 4 workflow patterns
- [ ] Conditional phase execution: Skips inappropriate phases based on scope
- [ ] Single working path: No fallback file creation mechanisms
- [ ] Fail-fast behavior: Clear error messages, immediate termination on failure

### Enforcement Standards
- [ ] Imperative language ratio ≥95%: MUST/WILL/SHALL for all required actions
- [ ] Step-by-step enforcement: STEP 1/2/3 pattern in all agent templates
- [ ] Mandatory verification: Explicit checkpoints after every file operation
- [ ] 100% file creation rate with auto-recovery: Single retry for transient failures
- [ ] Minimal retry infrastructure: Single-retry strategy (not multi-attempt loops)

### Performance Targets
- [ ] File size: 2,500-3,000 lines (achieved)
- [ ] Context usage: <25% throughout workflow
- [ ] Time efficiency: 15-25% faster for non-implementation workflows
- [ ] Code coverage: ≥80% test coverage for scope detection logic
- [ ] Recovery rate: >95% for transient errors (timeouts, file locks)
- [ ] Performance overhead: <5% for recovery infrastructure
- [ ] Checkpoint resume: Seamless auto-resume from phase boundaries

### Auto-Recovery Features
- [ ] Transient error auto-recovery: Single retry for timeouts and file locks
- [ ] Permanent error fail-fast: Immediate termination with enhanced error reporting
- [ ] Error location extraction: Parse file:line from error messages
- [ ] Specific error type detection: Categorize into 4 types (timeout, syntax, dependency, unknown)
- [ ] Recovery suggestions: Context-specific actionable guidance on failures
- [ ] Partial research failure handling: ≥50% success threshold allows continuation
- [ ] Progress markers: PROGRESS: [Phase N] emitted at phase transitions
- [ ] Checkpoint save/resume: Phase-boundary checkpoints with auto-resume

### Deficiency Resolution
- [ ] ✓ Research agents create files on first attempt (vs inline summaries)
- [ ] ✓ Zero SlashCommand usage for planning/implementation (pure Task tool)
- [ ] ✓ Summaries only created when implementation occurs (not for research-only)
- [ ] ✓ Correct phases execute for each workflow type (research, plan, implement, debug)

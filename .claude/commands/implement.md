---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan] [--create-pr] [--dashboard] [--dry-run]
description: Execute implementation plan with automated testing, adaptive replanning, and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list, update, revise, debug, document, expand, github-specialist
---

# Execute Implementation Plan

I'll help you systematically implement the plan file with automated testing and commits at each phase.

## Plan Information
- **Plan file**: $1 (or I'll find the most recent incomplete plan)
- **Starting phase**: $2 (default: resume from last incomplete phase or 1)

## Adaptive Planning Features

This command includes intelligent plan revision capabilities that detect when replanning is needed during implementation:

**Automatic Triggers:**
1. **Complexity Detection**: Phases with complexity score >8 or >10 tasks trigger phase expansion
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase suggests missing prerequisites
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` for discovered out-of-scope work

**Behavior:**
- Automatically invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases, or updates tasks)
- Continues implementation with revised plan
- Maximum 2 replans per phase prevents infinite loops

**Shared Utilities Integration:**
- **Checkpoint Management**: Uses `.claude/lib/checkpoint-utils.sh` for workflow state persistence
- **Complexity Analysis**: Uses `.claude/lib/complexity-utils.sh` for phase complexity scoring
- **Adaptive Logging**: Uses `.claude/lib/adaptive-planning-logger.sh` for trigger evaluation logging
- **Error Handling**: Uses `.claude/lib/error-handling.sh` for error classification and recovery

These shared utilities provide consistent, tested implementations across all commands.

**Safety:**
- Loop prevention with replan counters tracked in checkpoints
- Replan history logged for audit trail
- User escalation when limits exceeded
- Manual override via `--force-replan` flag

**Example Usage:**
```bash
# Normal implementation (automatic detection enabled)
/implement specs/plans/025_plan.md

# Manual scope drift reporting
/implement specs/plans/025_plan.md 3 --report-scope-drift "Database migration needed before schema changes"

# Force replan despite limit (requires manual approval)
/implement specs/plans/025_plan.md 4 --force-replan
```

## Auto-Resume Feature
If no plan file is provided, I will:
1. Search for the most recently modified implementation plan
2. Check if it has incomplete phases or tasks
3. Resume from the first incomplete phase
4. If all recent plans are complete, show a list to choose from

## Progress Dashboard (Optional)

Enable real-time visual progress tracking with the `--dashboard` flag:

```bash
/implement specs/plans/025_plan.md --dashboard
```

**Features**:
- **Real-time ANSI rendering**: Visual dashboard with Unicode box-drawing
- **Phase progress**: See all phases with status icons (✓ Complete, → In Progress, ⬚ Pending)
- **Progress bar**: Visual representation of completion percentage
- **Time tracking**: Elapsed time and estimated remaining duration
- **Test results**: Last test status with pass/fail indicator
- **Wave information**: Shows parallel execution waves when using dependency-based execution

**Terminal Requirements**:
- **Supported**: xterm, xterm-256color, screen, tmux, kitty, alacritty, most modern terminals
- **Unsupported**: dumb terminals, non-interactive shells, terminals without ANSI support

**Graceful Fallback**:
When terminal doesn't support ANSI codes, automatically falls back to traditional `PROGRESS:` markers without requiring any action.

**Dashboard Layout Example**:
```
┌─────────────────────────────────────────────────────────────┐
│ Implementation Progress: User Authentication Feature         │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Foundation ............................ ✓ Complete  │
│ Phase 2: Core Implementation ................... ✓ Complete  │
│ Phase 3: Testing & Validation .................. → In Progress│
│ Phase 4: Documentation ......................... ⬚ Pending    │
│ Phase 5: Cleanup ............................... ⬚ Pending    │
├─────────────────────────────────────────────────────────────┤
│ Progress: [████████████████░░░░░░░░░░░░] 60% (3/5 phases)   │
│ Elapsed: 14m 32s  |  Estimated Remaining: ~10m              │
├─────────────────────────────────────────────────────────────┤
│ Current Task: Running integration tests                     │
│ Last Test: test_auth_flow.lua ..................... ✓ PASS   │
└─────────────────────────────────────────────────────────────┘
```

**Implementation Details**:
The dashboard uses `.claude/lib/progress-dashboard.sh` utility which provides:
- Multi-layer terminal capability detection (TERM env, tput, interactive check)
- In-place ANSI updates without scrolling
- Performance-optimized rendering (minimal redraws)
- Support for both sequential and parallel (wave-based) execution

## Dry-Run Mode (Preview and Validation)

Preview execution plan without making changes using the `--dry-run` flag.

**Usage**: `/implement specs/plans/025_plan.md --dry-run` or combine with `--dashboard` for visual preview

**Analysis Performed**:
1. Plan parsing (structure, phases, tasks, dependencies)
2. Complexity evaluation (hybrid complexity scores per phase)
3. Agent assignments (which agents invoked for each phase)
4. Duration estimation (agent-registry metrics)
5. File/test analysis (affected files and tests)
6. Execution preview (wave-based order with parallelism)
7. Confirmation prompt (proceed or exit)

**Output Preview** (displays Unicode box-drawing with plan structure, waves, phase details, complexity scores, agent types, files, tests, duration estimates, execution summary)

**Use Cases**: Validation, time estimation, resource planning, dependency verification, file impact assessment, team coordination

**Scope**:
- Analyzes: Plan structure, complexity scores, agent assignments, duration, affected files/tests, execution waves
- Does NOT: Create/modify files, run tests, create git commits, invoke agents

**Duration Estimation**: Uses `.claude/lib/agent-registry-utils.sh` for historical performance data (agent execution time per complexity point, success rates, retry probabilities, parallel execution efficiency, test execution estimates)

## Standards Discovery and Application

For standards discovery patterns, see:
- [Upward CLAUDE.md Search](../docs/command-patterns.md#pattern-upward-claudemd-search)
- [Standards Section Extraction](../docs/command-patterns.md#pattern-standards-section-extraction)
- [Standards Application During Code Generation](../docs/command-patterns.md#pattern-standards-application-during-code-generation)
- [Fallback Behavior](../docs/command-patterns.md#pattern-fallback-behavior)

**Implement-specific application**:
- Apply Code Standards during code generation (indentation, naming, error handling)
- Use Testing Protocols for test execution and validation
- Follow Documentation Policy for new modules
- Verify compliance before marking each phase complete
- Document applied standards in commit messages

## Process

### Utility Initialization

Initialize required utilities for consistent error handling, state management, and logging before beginning implementation.

**When to Initialize**:
- **Before implementation**: Run once at command start
- **Required utilities**: 5 core utilities (error, checkpoint, complexity, logger, agent-registry)
- **Optional**: Progress dashboard if `--dashboard` flag present

**Initialization Overview**:
1. Detect project directory (sets CLAUDE_PROJECT_DIR)
2. Source and verify 5 core utilities
3. Initialize adaptive planning logger
4. Initialize progress dashboard if enabled (terminal capability detection)

**Pattern Details**: See [Standard Logger Setup](../docs/command-patterns.md#pattern-standard-logger-setup) for logger initialization patterns.

**Key Execution Requirements**:

1. **Detect project directory**:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/../lib/detect-project-dir.sh"  # Sets CLAUDE_PROJECT_DIR
   ```

2. **Verify core utilities**:
   ```bash
   UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
   [ -f "$UTILS_DIR/error-handling.sh" ] || { echo "ERROR: error-handling.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/complexity-utils.sh" ] || { echo "ERROR: complexity-utils.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/adaptive-planning-logger.sh" ] || { echo "ERROR: adaptive-planning-logger.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/agent-registry-utils.sh" ] || { echo "ERROR: agent-registry-utils.sh not found"; exit 1; }
   ```

3. **Initialize logger** (`.claude/logs/adaptive-planning.log`, 10MB max, 5 files retained):
   ```bash
   source "$UTILS_DIR/adaptive-planning-logger.sh"
   ```

4. **Initialize dashboard** (optional, with terminal capability detection):
   ```bash
   if [ "$DASHBOARD_FLAG" = "true" ] && [ -f "$UTILS_DIR/progress-dashboard.sh" ]; then
     source "$UTILS_DIR/progress-dashboard.sh"
     TERMINAL_CAPABILITIES=$(detect_terminal_capabilities)
     [ "$(echo "$TERMINAL_CAPABILITIES" | jq -r '.ansi_supported')" = "true" ] && DASHBOARD_ENABLED=true
   fi
   ```

**Quick Example**:
```bash
# Step 1: Detect project
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Step 2 & 3: Source utilities and logger
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
for util in error-handling.sh checkpoint-utils.sh complexity-utils.sh adaptive-planning-logger.sh agent-registry-utils.sh; do
  [ -f "$UTILS_DIR/$util" ] || { echo "ERROR: $util not found"; exit 1; }
done
source "$UTILS_DIR/adaptive-planning-logger.sh"

# Step 4: Dashboard (optional)
[ "$DASHBOARD_FLAG" = "true" ] && source "$UTILS_DIR/progress-dashboard.sh" && initialize_dashboard "$PLAN_NAME" "$TOTAL_PHASES"
```

**Logging Events**: log_complexity_check, log_test_failure_pattern, log_scope_drift, log_replan_invocation, log_loop_prevention, log_collapse_check

**Dashboard Lifecycle**: initialize_dashboard → update_dashboard_phase (after each phase) → clear_dashboard (on completion)

### Progressive Plan Support

This command supports all three progressive structure levels:

**Step 0: Detect Plan Structure Level**
```bash
# Use adaptive plan parser to detect structure
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
# Returns: 0 (single-file), 1 (phase-expanded), or 2 (stage-expanded)
```

**Level-Aware Processing**:
- **Level 0**: Single-file processing (all phases inline)
- **Level 1**: Process main plan and expanded phase files
- **Level 2**: Navigate hierarchy (main plan → phase directories → stage files)

**Unified Interface**:
All level-specific differences are abstracted by progressive utilities:
- `is_plan_expanded`: Check if plan has directory structure
- `is_phase_expanded`: Check if specific phase is in separate file
- `is_stage_expanded`: Check if specific stage is in separate file
- `list_expanded_phases`: Get numbers of expanded phases
- `list_expanded_stages`: Get numbers of expanded stages

### Implementation Flow

Let me first locate the implementation plan:

1. **Detect and parse the plan** to identify:
   - Plan structure level (0, 1, or 2) using parse-adaptive-plan.sh
   - Expanded phases and stages (via progressive parsing utilities)
   - Referenced research reports (if any)
   - Standards file path (if captured in plan metadata)
2. **Discover and load standards**:
   - Find CLAUDE.md files (working directory and subdirectories)
   - Extract Code Standards, Testing Protocols, Documentation Policy
   - Note standards for application during implementation
3. **Check for research reports**:
   - Extract report paths from plan metadata
   - Note reports for summary generation
4. **For each phase**:
   - Display the phase name and tasks
   - Implement changes following discovered standards
   - Run tests using standards-defined test commands
   - Verify compliance with standards before completing
   - Update the plan file with completion markers
   - Create a git commit with a structured message
   - Move to the next phase
5. **After all phases complete**:
   - Generate implementation summary
   - Update referenced reports if needed
   - Link plan and reports in summary

### Step 0.5: Dry-Run Mode Execution (if --dry-run flag present)

Execute preview mode instead of actual implementation when `--dry-run` flag detected. See [Dry-Run Mode](#dry-run-mode-preview-and-validation) for feature details and output examples.

**Execution Workflow**:
1. Parse flag and plan metadata
2. Analyze phases (complexity, agent assignment, duration via hybrid_complexity_evaluation)
3. Generate execution waves (parse-phase-dependencies.sh)
4. Display formatted preview (Unicode box-drawing with waves, phases, agents, files, tests, estimates)
5. Prompt and either exit or continue to normal flow

**Implementation**: Phase analysis uses hybrid_complexity_evaluation(); agent assignment maps complexity to types; duration from agent-registry-utils.sh; wave display shows sequential/parallel patterns; file/test extraction via regex

## Parallel Execution with Dependencies

Analyze phase dependencies to enable parallel execution in waves.

**Dependency Analysis Workflow**:
1. **Parse dependencies**: Use `parse-phase-dependencies.sh` to generate execution waves (format: `WAVE_1:1`, `WAVE_2:2 3`, etc.)
2. **Group phases**: Each wave contains parallelizable phases, waves execute sequentially
3. **Execute waves**: Single-phase waves run normally, multi-phase waves invoke multiple agents simultaneously (multiple Task calls in one message)
4. **Error handling**: Fail-fast on phase failure, preserve checkpoint, report successes/failures, allow resume from failed wave

**Parallel Execution Safety**: Max 3 concurrent phases per wave, fail-fast behavior, checkpoint after each wave, aggregate test results

**Dependency Format**: Phases declare dependencies in header (`dependencies: [1, 2]`). Empty array or omitted = no dependencies (wave 1). Circular dependencies detected and rejected.

## Phase Execution Protocol

Execute phases either sequentially (traditional) or in parallel waves (with dependencies).

**Execution Modes**:
- **Sequential**: Execute phases in order (Phase 1, 2, 3, ...) when no dependencies declared
- **Parallel**: Parse dependencies into waves, execute waves sequentially, parallelize phases within waves (>1 phase per wave)

**Wave Execution Flow**:
1. **Wave Initialization**: Identify phases in current wave, log wave execution start
2. **Phase Preparation**: Display phase number, name, tasks for each phase in wave
3. **Complexity Analysis**: Run analyzer, calculate hybrid complexity score (see Step 1.5)
4. **Agent Selection** (using $COMPLEXITY_SCORE from Step 1.5):
   - Direct execution (0-2), code-writer (3-5), code-writer + think (6-7), code-writer + think hard (8-9), code-writer + think harder (10+)
   - Special case overrides: doc-writer (documentation), test-specialist (testing), debug-specialist (debug)
5. **Delegation**: Invoke agent via Task tool with behavioral injection, monitor PROGRESS markers
6. **Testing and Commit**: Execute for all phases in wave (see subsequent sections)

**Pattern Details**: See [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection) for delegation patterns.
### Plan Hierarchy Update After Phase Completion

After successfully completing a phase (tests passing and git commit created), update the plan hierarchy to ensure all parent/grandparent plan files reflect completion status.

**When to Update**:
- After git commit succeeds for the phase
- Before saving the checkpoint
- For all hierarchy levels (Level 0, Level 1, Level 2)

**Update Workflow**:

1. **Invoke Spec-Updater Agent**:
   ```
   Task {
     subagent_type: "general-purpose"
     description: "Update plan hierarchy after Phase N completion"
     prompt: |
       Read and follow the behavioral guidelines from:
       /home/benjamin/.config/.claude/agents/spec-updater.md

       You are acting as a Spec Updater Agent.

       Update plan hierarchy checkboxes after Phase ${PHASE_NUM} completion.

       Plan: ${PLAN_PATH}
       Phase: ${PHASE_NUM}
       All tasks in this phase have been completed.

       Steps:
       1. Source checkbox utilities: source .claude/lib/checkbox-utils.sh
       2. Mark phase complete: mark_phase_complete "${PLAN_PATH}" ${PHASE_NUM}
       3. Verify consistency: verify_checkbox_consistency "${PLAN_PATH}" ${PHASE_NUM}
       4. Report: List all files updated (stage → phase → main plan)

       Expected output:
       - Confirmation of hierarchy update
       - List of updated files
       - Verification status
   }
   ```

2. **Validate Update Success**:
   - Check agent response for successful completion
   - Verify all hierarchy levels updated
   - Confirm no consistency errors

3. **Handle Update Failures**:
   - If hierarchy update fails: Log error and escalate to user
   - Do NOT proceed to checkpoint save if update fails
   - Preserve phase completion in working directory
   - User can manually fix hierarchy and resume

4. **Update Checkpoint State**:
   Add `hierarchy_updated` field to checkpoint data:
   ```bash
   CHECKPOINT_DATA='{
     "workflow_description":"implement",
     "plan_path":"'$PLAN_PATH'",
     "current_phase":'$NEXT_PHASE',
     "total_phases":'$TOTAL_PHASES',
     "status":"in_progress",
     "tests_passing":true,
     "hierarchy_updated":true,
     "replan_count":'$REPLAN_COUNT'
   }'
   save_checkpoint "implement" "$CHECKPOINT_DATA"
   ```

**Hierarchy Levels**:
- **Level 0** (single file): Update checkboxes in main plan only
- **Level 1** (expanded phases): Update phase file + main plan
- **Level 2** (stage expansion): Update stage file + phase file + main plan

**Error Handling**:
- Hierarchy update failures are non-fatal but logged
- User notified if parent plans couldn't be updated
- Phase still marked complete in deepest level file
- Can be manually synced later using checkbox-utils.sh

**Graceful Degradation**:
If spec-updater agent is unavailable, fall back to direct checkbox-utils.sh calls:
```bash
source .claude/lib/checkbox-utils.sh
mark_phase_complete "$PLAN_PATH" "$PHASE_NUM"
verify_checkbox_consistency "$PLAN_PATH" "$PHASE_NUM"
```

### 1.4. Check Expansion Status

Before implementing the phase, check if it's already expanded and display current structure:

```bash
# Detect plan structure level
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Check if current phase is expanded
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
```

**Display Structure Information:**
- **Level 0**: "Plan Structure: Level 0 (all phases inline)"
- **Level 1**: "Plan Structure: Level 1 (Phase X expanded, other phases inline)"
- **Level 2**: "Plan Structure: Level 2 (Phase X with stage expansion)"

This is informational only and helps understand the current plan organization.

### 1.5. Hybrid Complexity Evaluation

Evaluate phase complexity using hybrid approach: threshold-based scoring with agent evaluation for borderline cases (score ≥7 or ≥8 tasks).

**When to Use**:
- **Every phase**: Always evaluate complexity before implementation
- **Borderline cases**: Automatic agent invocation for context-aware analysis
- **Agent triggers**: Threshold score ≥7 OR task count ≥8

**Workflow Overview**:
1. Calculate threshold-based score (complexity-utils.sh)
2. Determine if agent evaluation needed (borderline thresholds)
3. Run hybrid_complexity_evaluation function (may invoke agent)
4. Parse result (final_score, evaluation_method, agent_reasoning)
5. Log evaluation for analytics (adaptive-planning-logger.sh)
6. Export COMPLEXITY_SCORE for downstream decisions (expansion, agent selection)

**Key Execution Requirements**:

1. **Threshold calculation** (uses complexity-utils.sh):
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"
   THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
   TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")
   ```

2. **Hybrid evaluation with agent fallback**:
   ```bash
   # Determine if agent needed (score ≥7 OR tasks ≥8)
   AGENT_NEEDED="false"
   [ "$THRESHOLD_SCORE" -ge 7 ] || [ "$TASK_COUNT" -ge 8 ] && AGENT_NEEDED="true"

   # Run hybrid evaluation (may invoke complexity_estimator agent)
   EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
   COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
   EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')  # "threshold", "agent", or "reconciled"
   ```

3. **Logging and analytics**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/adaptive-planning-logger.sh"
   log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$COMPLEXITY_THRESHOLD_HIGH" "$AGENT_NEEDED"

   # Log discrepancy if agent evaluation differed from threshold
   [ "$EVALUATION_METHOD" != "threshold" ] && log_complexity_discrepancy "$PHASE_NAME" "$THRESHOLD_SCORE" "$AGENT_SCORE" "$SCORE_DIFF" "$AGENT_REASONING" "$EVALUATION_METHOD"
   ```

4. **Export for downstream use**:
   ```bash
   export COMPLEXITY_SCORE      # Used by Steps 1.55 (Proactive Expansion) and 1.6 (Agent Selection)
   export EVALUATION_METHOD
   ```

**Quick Example**:
```bash
# Calculate threshold score
source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"
THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]")

# Run hybrid evaluation (auto-invokes agent if borderline)
EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')

echo "Complexity Score: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"

# Log and export
log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$COMPLEXITY_THRESHOLD_HIGH" "$([ $THRESHOLD_SCORE -ge 7 ] && echo 'true' || echo 'false')"
export COMPLEXITY_SCORE EVALUATION_METHOD
```

**Expected Impact**: 30% reduction in expansion errors via context-aware evaluation

**Error Handling**: Agent timeout/failure/invalid response → Fallback to threshold score (all fallbacks logged)

### 1.55. Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Note**: This step uses the hybrid complexity score ($COMPLEXITY_SCORE) from Step 1.5.

**Evaluation criteria**: Task complexity, scope breadth, interrelationships, parallel work potential, clarity vs detail tradeoff

**If expansion recommended**: Display formatted recommendation with rationale and `/expand phase` command

**If not needed**: Continue silently to implementation

**Relationship to reactive expansion** (Step 3.4):
- **Proactive** (1.55): Before implementation, recommendation only
- **Reactive** (3.4): After implementation, auto-revision via `/revise --auto-mode`

### 1.57. Implementation Research Agent Invocation

Invoke implementation-researcher agent for complex phases to gather codebase context before implementation.

**When to Invoke**:
- **Complexity trigger**: $COMPLEXITY_SCORE ≥ 8 (from Step 1.5)
- **Task trigger**: $TASK_COUNT > 10 (from Step 1.5)
- **Purpose**: Search existing implementations, identify patterns, detect integration challenges

**Workflow Overview**:
1. Check complexity/task thresholds
2. Invoke implementation-researcher agent via Task tool
3. Use forward_message pattern to extract artifact metadata
4. Store metadata in context (minimal footprint)
5. Load full artifact on-demand during implementation

**Key Execution Requirements**:

1. **Check thresholds** (uses variables from Step 1.5):
   ```bash
   # Thresholds from complexity evaluation
   RESEARCH_NEEDED="false"
   [ "$COMPLEXITY_SCORE" -ge 8 ] || [ "$TASK_COUNT" -gt 10 ] && RESEARCH_NEEDED="true"

   if [ "$RESEARCH_NEEDED" = "true" ]; then
     echo "PROGRESS: Complex phase detected (score: $COMPLEXITY_SCORE, tasks: $TASK_COUNT) - invoking implementation researcher"
   fi
   ```

2. **Invoke implementation-researcher agent**:
   ```bash
   # Source context preservation utilities
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"

   # Track context before research
   CONTEXT_BEFORE=$(track_context_usage "before" "phase_${CURRENT_PHASE}_research" "")

   # Build task list for agent
   FILE_LIST=$(echo "$PHASE_CONTENT" | grep -oE '[a-zA-Z0-9_/.-]+\.(js|py|lua|sh|md|yaml)' | sort -u | head -20 | tr '\n' ', ')

   # Invoke agent
   RESEARCH_AGENT_PROMPT=$(cat <<'EOF'
Read and follow behavioral guidelines from:
${CLAUDE_PROJECT_DIR}/.claude/agents/implementation-researcher.md

You are acting as an Implementation Researcher Agent.

Research Context:
- Phase: ${CURRENT_PHASE}
- Description: ${PHASE_NAME}
- Files to modify: ${FILE_LIST}
- Task count: ${TASK_COUNT}
- Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

Research existing implementations, patterns, and utilities for this phase.
Create artifact at: specs/${TOPIC_DIR}/artifacts/phase_${CURRENT_PHASE}_exploration.md
Return metadata only (path + 50-word summary + key findings JSON).
EOF
)

   # Replace variables in prompt
   RESEARCH_AGENT_PROMPT=$(echo "$RESEARCH_AGENT_PROMPT" | \
     sed "s|\${CLAUDE_PROJECT_DIR}|${CLAUDE_PROJECT_DIR}|g" | \
     sed "s|\${CURRENT_PHASE}|${CURRENT_PHASE}|g" | \
     sed "s|\${PHASE_NAME}|${PHASE_NAME}|g" | \
     sed "s|\${FILE_LIST}|${FILE_LIST}|g" | \
     sed "s|\${TASK_COUNT}|${TASK_COUNT}|g" | \
     sed "s|\${TOPIC_DIR}|${TOPIC_DIR}|g")

   # Note: Actual Task tool invocation happens in AI execution layer
   # This is the prompt content that should be used
   ```

3. **Extract metadata using forward_message**:
   ```bash
   # Parse subagent response for artifact paths and metadata
   RESEARCH_RESULT=$(forward_message "$SUBAGENT_OUTPUT" "phase_${CURRENT_PHASE}_research")

   # Extract artifact path and metadata
   ARTIFACT_PATH=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].path')
   ARTIFACT_METADATA=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].metadata')
   RESEARCH_SUMMARY=$(echo "$ARTIFACT_METADATA" | jq -r '.summary')

   # Track context after research (metadata only, not full artifact)
   CONTEXT_AFTER=$(track_context_usage "after" "phase_${CURRENT_PHASE}_research" "$RESEARCH_SUMMARY")

   # Calculate and log reduction
   CONTEXT_REDUCTION=$(calculate_context_reduction "$CONTEXT_BEFORE" "$CONTEXT_AFTER")
   echo "PROGRESS: Research complete - context reduction: ${CONTEXT_REDUCTION}%"
   ```

4. **Store metadata for on-demand loading**:
   ```bash
   # Cache metadata in memory
   cache_metadata "$ARTIFACT_PATH" "$ARTIFACT_METADATA"

   # Store path in phase context
   PHASE_RESEARCH_ARTIFACT="$ARTIFACT_PATH"

   # During implementation: Load full artifact only when needed
   # FULL_RESEARCH=$(load_metadata_on_demand "$PHASE_RESEARCH_ARTIFACT")
   ```

**Quick Example**:
```bash
# Check if research needed
RESEARCH_NEEDED="false"
[ "$COMPLEXITY_SCORE" -ge 8 ] || [ "$TASK_COUNT" -gt 10 ] && RESEARCH_NEEDED="true"

if [ "$RESEARCH_NEEDED" = "true" ]; then
  # Track context before
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"
  CONTEXT_BEFORE=$(track_context_usage "before" "phase_3_research" "")

  # Invoke implementation-researcher agent (Task tool in AI layer)
  # Returns: {"artifact_path": "specs/042_auth/artifacts/phase_3_exploration.md", "metadata": {...}}

  # Extract metadata using forward_message
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
  RESEARCH_RESULT=$(forward_message "$SUBAGENT_OUTPUT" "phase_3_research")
  ARTIFACT_PATH=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].path')
  RESEARCH_SUMMARY=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].metadata.summary')

  # Track context after (metadata only)
  CONTEXT_AFTER=$(track_context_usage "after" "phase_3_research" "$RESEARCH_SUMMARY")

  # Cache for on-demand loading
  cache_metadata "$ARTIFACT_PATH" "$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].metadata')"

  # Reduction: 95% (full artifact ~2000 tokens → metadata ~100 tokens)
  REDUCTION=$(calculate_context_reduction "$CONTEXT_BEFORE" "$CONTEXT_AFTER")
  echo "Context reduction: ${REDUCTION}%"
fi
```

**Expected Impact**:
- 95% context reduction vs. loading full research (2000 tokens → 100 tokens)
- Research loaded on-demand only when implementing complex phases
- Metadata provides sufficient context for most implementation decisions

**Integration Points**:
- **Agent template**: `.claude/agents/implementation-researcher.md`
- **Utilities**: `artifact-operations.sh` (forward_message, cache_metadata), `context-metrics.sh` (tracking)
- **Output artifact**: `specs/{topic}/artifacts/phase_{N}_exploration.md`

**Error Handling**:
- Agent timeout/failure → Skip research, log warning, continue with implementation
- Invalid metadata → Fallback to minimal context, log error
- Artifact creation failure → Non-blocking, implementation proceeds

**Benefits**:
- Identifies reusable utilities before implementation (reduces duplication)
- Discovers patterns and conventions (increases consistency)
- Detects integration challenges early (reduces rework)
- Minimal context footprint (enables scaling to larger plans)

### 1.6. Parallel Wave Execution

For parallel agent invocation patterns, see [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation).

**Single Phase Wave**: Execute normally (agent delegation or direct), wait, proceed to testing

**Multi-Phase Wave**:
1. Invoke all phases in parallel using multiple Task tool calls in one message
2. Wait for wave completion, collect results, aggregate progress markers
3. Check for failures: If any failed, stop execution and save checkpoint
4. Proceed to wave testing and commit all changes together

**Parallelism limits**: Max 3 concurrent phases per wave, split into sub-waves if needed

### 2. Implementation
Create or modify the necessary files according to the plan specifications.

**If Agent Delegated**: Use agent's output
**If Direct Execution**: Implement manually following standards

### 3. Testing
Run tests by:
- Looking for test commands in the phase tasks
- Checking for common test patterns (npm test, pytest, make test)
- Running language-specific test commands based on project type

### 3.3. Automatic Debug Integration (if tests fail)

**When to Use Automatic Debug Integration**:
- **Test failures** in any phase during implementation
- **Automatic triggers**: No manual invocation needed
- **Tiered recovery**: 4 escalating levels of error handling

**Quick Overview**:
1. Classify error type and display suggestions (error-handling.sh)
2. Retry transient errors (timeout, busy, locked) with extended timeout
3. Retry tool access errors with reduced toolset fallback
4. Auto-invoke /debug agent for root cause analysis
5. Present user choices: (r)evise, (c)ontinue, (s)kip, (a)bort
6. Execute chosen action and update plan with debugging notes

**Pattern Details**: See [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns) for complete tiered recovery workflow.

**Key Execution Requirements**:

1. **Error classification** (uses error-handling.sh):
   ```bash
   source "$CLAUDE_PROJECT_DIR/.claude/lib/error-handling.sh"
   ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")  # → syntax, test_failure, timeout, etc.
   SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT" "$ERROR_LOCATION")
   ```

2. **Automatic /debug invocation** (Level 4):
   ```bash
   DEBUG_RESULT=$(invoke_slash_command "/debug \"Phase $CURRENT_PHASE failure\" \"$PLAN_PATH\"")
   DEBUG_REPORT_PATH=$(extract_report_path "$DEBUG_RESULT")
   # Fallback: .claude/lib/analyze-error.sh if /debug fails
   ```

3. **User choice actions**:
   - **(r)evise**: Invoke `/revise --auto-mode` with debug findings, retry phase
   - **(c)ontinue**: Mark `[INCOMPLETE]`, add debugging notes, proceed to next phase
   - **(s)kip**: Mark `[SKIPPED]`, add debugging notes, proceed to next phase
   - **(a)bort**: Save checkpoint with debug info, exit for manual intervention

**Quick Example - Tiered Recovery**:
```bash
# Level 1: Classify and suggest
source "$UTILS_DIR/error-handling.sh"
ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")  # → "syntax"
echo "Error Type: $ERROR_TYPE"
echo "$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT")"

# Level 2: Transient retry (if timeout/busy)
if [ "$ERROR_TYPE" = "timeout" ]; then
  RETRY_META=$(retry_with_timeout "Phase 3 tests" "$ATTEMPT_NUMBER")
  # Retry with extended timeout if SHOULD_RETRY=true
fi

# Level 3: Tool fallback (if tool access error)
if echo "$TEST_OUTPUT" | grep -qi "tool.*failed"; then
  FALLBACK_META=$(retry_with_fallback "Phase 3" "$ATTEMPT_NUMBER")
  # Retry with REDUCED_TOOLSET
fi

# Level 4: Auto-invoke /debug
DEBUG_RESULT=$(invoke_slash_command "/debug \"Phase 3 test failure\" \"plan.md\"")
DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -o 'specs/reports/.*\.md')

# Present choices
echo "Choose: (r)evise, (c)ontinue, (s)kip, (a)bort"
read -p "Action: " USER_CHOICE

case "$USER_CHOICE" in
  r) invoke_slash_command "/revise --auto-mode --context '$REVISION_CONTEXT' '$PLAN_PATH'" ;;
  c) add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "Incomplete" ;;
  s) add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "Skipped" ;;
  a) save_checkpoint "paused" "$CURRENT_PHASE" "$CURRENT_PHASE"; exit 0 ;;
esac
```

**Error Categories**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown

**Helper Function**: `add_debugging_notes(plan_path, phase_num, debug_report_path, root_cause, resolution_status)`
- Creates "#### Debugging Notes" section with date, issue, report link, root cause, resolution
- Appends iterations for repeat failures, escalates after 3+ attempts

**Benefits**: 50% faster debug workflow, 4-level tiered recovery, graceful degradation, clear user choices

### 3.4. Adaptive Planning Detection

**Overview**: See [Adaptive Planning Features](#adaptive-planning-features) section for full details.

**Workflow**:
1. Load checkpoint and check replan limits (max 2 per phase)
2. Detect triggers: Complexity (score >8 or >10 tasks), Test failure pattern (2+ consecutive), Scope drift (manual flag)
3. Build revision context JSON and invoke `/revise --auto-mode`
4. Parse response: Update checkpoint, increment counters, log replan history
5. Loop prevention: Escalate to user if limit reached

**Trigger types**:
- **expand_phase**: Complexity threshold exceeded
- **add_phase**: Test failure pattern detected
- **update_tasks**: Scope drift flagged

### 3.5. Update Debug Resolution (if tests pass for previously-failed phase)
**Check if this phase was previously debugged:**

**Step 1: Check for Debugging Notes**
- Read current phase section in plan
- Look for "#### Debugging Notes" subsection
- Check if it contains "Resolution: Pending"

**Step 2: Update Resolution**
- If debugging notes exist and tests now pass:
  - Use Edit tool to update: `Resolution: Pending` → `Resolution: Applied`
  - Add git commit hash line (will be added after commit)
  - This marks that the debugging led to a successful fix

**Step 3: Add Fix Commit Hash (after git commit)**
- After git commit succeeds
- If resolution was updated: Add commit hash to debugging notes
- Format: `Fix Applied In: [commit-hash]`

**Example:**
```markdown
#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase failed with null pointer
- **Debug Report**: [../reports/026_debug.md](../reports/026_debug.md)
- **Root Cause**: Missing null check
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

### 4. Git Commit
Create a structured commit:
```
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 5. Plan Update (After Git Commit Succeeds)

Update plan files incrementally after each successful phase completion.

**Update Steps**:
1. **Mark tasks complete**: Use Edit tool to change `- [ ]` → `- [x]` in appropriate file based on expansion status
2. **Add completion marker**: Change `### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`
3. **Verify updates**: Read updated file and verify all phase tasks show `[x]`
4. **Update progress section**: Add/update "## Implementation Progress" with last phase, date, commit, status, resume command

**Level-Aware Updates**: Use progressive utilities (is_phase_expanded, is_stage_expanded) to determine correct file location (Level 0: main plan only, Level 1: phase file or main plan, Level 2: stage file, phase file, or main plan)

**Progress Section Content**: Last completed phase, completion date, git commit hash, status "In Progress (M/N phases complete)", resume instructions `/implement <plan-file> <next-phase-number>`

### 5.5. Automatic Collapse Detection

Automatically evaluate if an expanded phase should be collapsed back to the main plan file after completion.

**Trigger Conditions**: Phase is expanded (separate file) AND phase is completed (all tasks marked [x])

**Collapse Thresholds**: Tasks ≤ 5 AND Complexity < 6.0 (both required, conservative approach)

**Workflow**:
1. Check phase expansion and completion status (parse-adaptive-plan.sh)
2. Extract metrics: task count, complexity score (complexity-utils.sh)
3. Log evaluation (log_collapse_check for observability)
4. If thresholds met: Build collapse context JSON, invoke `/revise --auto-mode collapse_phase`
5. Update plan path if structure level changed (Level 1 → Level 0)
6. Log collapse invocation (log_collapse_invocation for audit trail)

**Pattern Details**: See [Adaptive Planning Features](#adaptive-planning-features) for collapse workflow integration.

**Logging**: All evaluations logged to `.claude/logs/adaptive-planning.log`

**Non-Blocking**: Collapse failures logged but don't stop implementation

**Edge Cases**: Phase with stages (collapse stages first), incomplete phase (skipped), complex phase (not triggered), structure level change (plan path updated)

### 6. Incremental Summary Generation

Create or update partial summary after each phase completion to track implementation progress.

**Workflow**:
1. Extract specs directory and determine summary path: `[specs-dir]/summaries/NNN_partial.md`
2. Create (first phase) or update (subsequent phases) partial summary using Write/Edit tools
3. Update with status "in_progress", phases completed "M/N", last phase details, commit hash, resume instructions

**Required Content**:
- Metadata: Date started, specs directory, plan link, status, phases completed count
- Progress: Last completed phase (name, date, commit), phases checklist with completion dates
- Resume: Instructions for `/implement [plan-path] M+1` (auto-resume enabled by default)
- Notes: Brief implementation observations

**Template Reference**: See finalized summaries in `specs/summaries/` for structure examples

### 7. Before Starting Next Phase
**Defensive check before proceeding:**

**Step 1: Read Current Plan State**
- Use Read tool to read plan file
- Find previous phase heading

**Step 2: Verify Previous Phase Complete**
- Check that previous phase has `[COMPLETED]` marker
- Check that previous phase tasks are `[x]`

**Step 3: Mark Complete if Missing (Defensive)**
- If previous phase not marked but commit exists: Mark it now
- Log warning about inconsistency
- This ensures plan stays consistent even if previous update failed

## Test Detection Patterns

I'll look for and run:
- Commands containing `:lua.*test`
- Commands with `:Test`
- Standard test commands: `npm test`, `pytest`, `make test`
- Project-specific test commands based on configuration files

## Resuming Implementation

If we need to stop and resume later, you can use:
```
/implement <plan-file> <phase-number>
```

This will start from the specified phase number.

## Error Handling and Rollback

### Test Failures

When tests fail, use error-handling.sh for systematic error analysis and recovery:

**Step 1: Capture Error Output**
```bash
# Capture test failure output
TEST_ERROR_OUTPUT=$(run_tests 2>&1)
TEST_EXIT_CODE=$?
```

**Step 2: Classify Error Type**
```bash
# Use error-handling.sh to classify the error
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-handling.sh"

ERROR_TYPE=$(classify_error "$TEST_ERROR_OUTPUT")
# Returns: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown
```

**Step 3: Generate Recovery Suggestions**
```bash
# Get actionable recovery suggestions based on error type
SUGGESTIONS=$(suggest_recovery "$ERROR_TYPE" "$TEST_ERROR_OUTPUT")
```

**Step 4: Format Error Report**
```bash
# Use error-handling.sh to format a structured error report
ERROR_REPORT=$(format_error_report "$ERROR_TYPE" "$TEST_ERROR_OUTPUT" "$CURRENT_PHASE")
echo "$ERROR_REPORT"
```

**Step 5: Decide Next Action**
- Display formatted error report with suggestions
- Attempt automated fixes for common issues (if applicable)
- Re-run tests after fixes
- Only move forward when tests pass
- If unresolvable: Save checkpoint and escalate to user

### Phase Failure Handling
**What happens when a phase fails:**

**Don't Mark Phase Complete:**
- If phase tests fail: Do NOT mark tasks as `[x]`
- Do NOT add `[COMPLETED]` marker to phase heading
- Do NOT update partial summary with this phase
- Do NOT create git commit

**Preserve Partial Work:**
- Keep code changes in working directory
- Previous phases remain marked complete
- Partial summary reflects only successful phases
- User can debug, fix, and retry the phase

**Retry Failed Phase:**
```
# After fixing issues
/implement <plan-file> <failed-phase-number>
```

**Partial Summary Always Accurate:**
- Partial summary only includes successfully completed phases
- "Phases Completed: M/N" reflects actual progress
- Resume instructions point to first incomplete phase
- Status remains "in_progress" until all phases complete

### Git Commit Failure Handling
If git commit fails after marking phase complete:
- Log error with details
- Preserve partial work (don't rollback code changes)
- Partial summary already reflects completed phase
- Manual intervention required to resolve git issues

## Summary Generation

After completing all phases:

### 1-3. Finalize Summary File

**Workflow**:
- Check for partial summary: `[specs-dir]/summaries/NNN_partial.md`
- If exists: Rename to `NNN_implementation_summary.md` and finalize
- If not: Create new summary from scratch
- Location: Extract specs-dir from plan metadata
- Number: Match plan number (NNN)

**Finalization updates**:
- Remove "(PARTIAL)" from title
- Change status: `in_progress` → `complete`
- Update phases: `M/N` → `N/N`
- Add completion date and lessons learned
- Remove resume instructions

### 4-5. Registry and Cross-References

**Update SPECS.md Registry**:
- Increment "Summaries" count
- Update "Last Updated" date

**Bidirectional links**:
- Add "## Implementation Summary" section to plan file
- Add "## Implementation Status" section to each research report
- Verify all links created (non-blocking if fails)

### 6. Create Pull Request (Optional)

For PR creation workflow, see [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection).

**Implement-specific PR workflow**:
- Trigger: `--create-pr` flag or CLAUDE.md auto-PR config
- Prerequisites: Check gh CLI installed and authenticated
- Agent: Invoke github-specialist with behavioral injection
- Content: Implementation overview, phases, test results, reports, file changes
- Update: Add PR link to summary and plan files
- Graceful degradation: Provide manual gh command if fails

## Finding the Implementation Plan

### Auto-Detection Logic (when no arguments provided):
```bash
# 1. Find all plans (both files and directories), sorted by modification time
# - Level 0 plans: specs/plans/NNN_*.md
# - Level 1/2 plans: specs/plans/NNN_*/NNN_*.md
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" -exec ls -t {} + 2>/dev/null

# 2. For each plan, use progressive parser to check status:
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# 3. Select the first incomplete plan
```

### If no plan file provided:
I'll search for the most recent incomplete implementation plan by:
1. Looking in all `specs/plans/` directories for both files and directories
2. Sorting by modification time (most recent first)
3. Detecting structure level using `parse-adaptive-plan.sh detect_structure_level`
4. Checking plan status by reading phase completion markers
5. Selecting the first incomplete plan found
6. Determining the first incomplete phase to resume from

### If a plan file or directory is provided:
I'll use the specified plan directly and:
1. Detect structure level (0, 1, or 2) using parsing utility
2. Read appropriate plan file based on expansion status
3. Check completion status using `[COMPLETED]` markers
4. Find first incomplete phase (if any)
5. Resume from that phase or start from phase 1

### Plan Status Detection:
Check for completion markers in appropriate files:

- **Complete Plan**: All phases have `[COMPLETED]` marker
- **Incomplete Phase**: Phase lacks `[COMPLETED]` marker or has unchecked tasks
- **Level 0**: Check phase headings and task checkboxes in main plan file
- **Level 1**: Check completion markers in expanded phase files and main plan
- **Level 2**: Check completion across stage files, phase files, and main plan

## Integration with Other Commands

### Standards Flow
This command is part of the standards enforcement pipeline:

1. `/report` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan metadata
3. `/implement` - **Applies standards during code generation** (← YOU ARE HERE)
4. `/test` - Verifies implementation using standards-defined test commands
5. `/document` - Creates documentation following standards format
6. `/refactor` - Validates code against standards

### How /implement Uses Standards

#### From /plan
- Reads captured standards file path from plan metadata
- Uses plan's documented test commands and coding style

#### Applied During Implementation
- **Code generation**: Follows Code Standards (indentation, naming, error handling)
- **Test execution**: Uses Testing Protocols (test commands, patterns)
- **Documentation**: Creates docs per Documentation Policy

#### Verified Before Commit
- Standards compliance checked before marking phase complete
- Commit message notes which standards were applied

### Example Flow
```
User runs: /plan "Add authentication"
  ↓
/plan discovers CLAUDE.md:
  - Code Standards: snake_case, 2 spaces, pcall
  - Testing: :TestSuite
  ↓
Plan metadata captures: Standards File: CLAUDE.md
  ↓
User runs: /implement auth_plan.md
  ↓
/implement discovers CLAUDE.md + reads plan:
  - Confirms standards
  - Applies during generation
  - Tests with :TestSuite
  - Verifies compliance
  ↓
Generated code follows standards automatically
```

## Agent Usage

This command executes implementation directly using its own tools (Read, Edit, Write, Bash, TodoWrite) for performance, context preservation, and predictable behavior. For complex implementations requiring specialized agents, use `/orchestrate` instead.

## Checkpoint Detection and Resume

For checkpoint management patterns, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns).

**When to Use Checkpoints**:
- **Automatic saves**: After each phase completion with git commit
- **Auto-resume**: 90% of resumes happen automatically without prompts
- **Safety checks**: 5 conditions verified before auto-resume

**Workflow Overview**:
1. Check for existing checkpoint (load_checkpoint)
2. Evaluate auto-resume safety conditions (5 checks)
3. Auto-resume if safe, otherwise show interactive prompt with reason
4. Save checkpoint after each phase (atomic save operations)
5. Cleanup on completion or archive on failure

**Pattern Details**: See [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns) for complete workflow including safety checks, schema migration, and error handling.

**Key Execution Requirements**:

1. **Load checkpoint** (uses checkpoint-utils.sh):
   ```bash
   source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"
   CHECKPOINT_DATA=$(load_checkpoint "implement")
   CHECKPOINT_EXISTS=$?

   [ $CHECKPOINT_EXISTS -eq 0 ] && PLAN_PATH=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
   ```

2. **Smart auto-resume with safety checks**:
   ```bash
   if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
     # Auto-resume silently (90% of cases)
     log_checkpoint_auto_resume "$CURRENT_PHASE" "implement"
   else
     # Show interactive prompt with reason
     SKIP_REASON=$(get_skip_reason "$CHECKPOINT_FILE")
     echo "⚠ Cannot auto-resume: $SKIP_REASON"
     # Offer: (r)esume, (s)tart fresh, (v)iew, (d)elete
   fi
   ```

3. **Save checkpoint after phase**:
   ```bash
   CHECKPOINT_DATA='{"workflow_description":"implement", "plan_path":"'$PLAN_PATH'", "current_phase":'$NEXT_PHASE', "total_phases":'$TOTAL_PHASES', "status":"in_progress", "tests_passing":true, "replan_count":'$REPLAN_COUNT'}'
   save_checkpoint "implement" "$CHECKPOINT_DATA"
   ```

**Quick Example - Auto-Resume Flow**:
```bash
# Check for checkpoint
CHECKPOINT_DATA=$(load_checkpoint "implement")

if [ $? -eq 0 ]; then
  # Evaluate 5 safety conditions
  if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
    # All safety conditions met → Auto-resume (no prompt)
    CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
    echo "✓ Auto-resuming from Phase $CURRENT_PHASE"
  else
    # Safety condition failed → Interactive prompt with specific reason
    echo "⚠ Cannot auto-resume: $(get_skip_reason "$CHECKPOINT_FILE")"
    # Prompt user for manual decision
  fi
fi

# After each phase completes
save_checkpoint "implement" "$CHECKPOINT_DATA"  # Atomic save

# On completion
delete_checkpoint "implement"  # Cleanup
```

**Auto-Resume Safety Conditions**:
1. Tests passing in last run (tests_passing = true)
2. No recent errors (last_error = null)
3. Checkpoint age < 7 days
4. Plan file not modified since checkpoint
5. Status = "in_progress"

**Checkpoint State Fields**: workflow_description, plan_path, current_phase, total_phases, completed_phases, status, tests_passing, replan_count, phase_replan_count, replan_history

**Benefits**: Smart auto-resume (90% automatic), 5-condition safety checks, clear feedback on skip reason, schema migration, atomic saves, consistent naming, built-in validation

Let me start by finding your implementation plan.

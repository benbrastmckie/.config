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
- **Error Handling**: Uses `.claude/lib/error-utils.sh` for error classification and recovery

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

Preview execution plan without making changes using the `--dry-run` flag:

```bash
/implement specs/plans/025_plan.md --dry-run
```

**Dry-Run Analysis**:
1. **Plan parsing**: Parse plan structure, phases, tasks, and dependencies
2. **Complexity evaluation**: Calculate hybrid complexity scores for each phase
3. **Agent assignments**: Show which agents would be invoked for each phase
4. **Duration estimation**: Estimate time based on agent-registry metrics
5. **File analysis**: List files and tests that would be affected
6. **Execution preview**: Display wave-based execution order with parallelism
7. **Confirmation prompt**: Option to proceed with actual implementation

**Preview Output Example**:
```
┌─────────────────────────────────────────────────────────────┐
│ Implementation Plan: User Authentication Feature (Dry-Run)  │
├─────────────────────────────────────────────────────────────┤
│ Plan Structure: Level 1 (Phase 2 expanded)                  │
│ Total Phases: 5  |  Estimated Duration: ~42 minutes         │
├─────────────────────────────────────────────────────────────┤
│ Wave 1 (Sequential):                                         │
│   Phase 1: Foundation                       [Direct] 8min   │
│     Complexity: 2.4  |  Tasks: 4  |  Agent: None            │
│     Files: auth/base.lua, auth/types.lua                    │
│     Tests: test_auth_foundation.lua                         │
│                                                              │
│ Wave 2 (Parallel - 2 phases):                               │
│   Phase 2: Core Auth Logic                [Writer] 15min   │
│     Complexity: 6.8  |  Tasks: 8  |  Agent: code-writer     │
│     Files: auth/login.lua, auth/session.lua                 │
│     Tests: test_login.lua, test_session.lua                 │
│   Phase 3: Token Management               [Writer] 12min   │
│     Complexity: 5.2  |  Tasks: 6  |  Agent: code-writer     │
│     Files: auth/token.lua, auth/refresh.lua                 │
│     Tests: test_token_validation.lua                        │
│                                                              │
│ Wave 3 (Sequential):                                         │
│   Phase 4: Integration Tests           [Test-Spec] 5min    │
│     Complexity: 3.1  |  Tasks: 3  |  Agent: test-specialist │
│     Tests: test_auth_integration.lua                        │
│   Phase 5: Documentation                  [Doc-Write] 2min  │
│     Complexity: 1.8  |  Tasks: 2  |  Agent: doc-writer      │
│     Files: auth/README.md, CHANGELOG.md                     │
├─────────────────────────────────────────────────────────────┤
│ Execution Summary:                                           │
│   Total Waves: 3  |  Parallel Phases: 2  |  Max Concurrent: 2│
│   Files Modified: 9  |  Tests Created: 5                    │
│   Estimated Time: 42 minutes (30min with parallelism)       │
└─────────────────────────────────────────────────────────────┘

Proceed with implementation? (y/n):
```

**Dry-Run with Dashboard**:
Combine flags for visual preview:
```bash
/implement specs/plans/025_plan.md --dry-run --dashboard
```

Shows dashboard preview with simulated execution without making changes.

**Use Cases**:
- **Validation**: Verify plan structure before execution
- **Time estimation**: Understand time commitment
- **Resource planning**: See which agents will be invoked
- **Dependency verification**: Confirm wave-based execution order is correct
- **File impact assessment**: Review which files will be modified
- **Team coordination**: Share execution plan with team before starting

**Dry-Run Scope**:
- ✓ Parses plan and analyzes structure
- ✓ Calculates complexity scores
- ✓ Determines agent assignments
- ✓ Estimates duration from agent registry
- ✓ Lists affected files and tests
- ✓ Shows execution waves and parallelism
- ✗ Does not create/modify files
- ✗ Does not run tests
- ✗ Does not create git commits
- ✗ Does not invoke agents

**Implementation Details**:
Duration estimation uses `.claude/lib/agent-registry-utils.sh` to retrieve historical performance data:
- Average agent execution time per complexity point
- Success rates and retry probabilities
- Parallel execution efficiency factors
- Test execution time estimates

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

Before beginning implementation, initialize all required utilities for consistent error handling, state management, and logging.

**Step 1: Detect Project Directory**
```bash
# Detect project root dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
# Sets: CLAUDE_PROJECT_DIR
```

**Step 2: Source Shared Utilities**

Use Bash tool to verify utilities are available:
```bash
# Verify and prepare utilities
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"

# Core utilities (required)
[ -f "$UTILS_DIR/error-utils.sh" ] || { echo "ERROR: error-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/complexity-utils.sh" ] || { echo "ERROR: complexity-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/adaptive-planning-logger.sh" ] || { echo "ERROR: adaptive-planning-logger.sh not found"; exit 1; }
[ -f "$UTILS_DIR/agent-registry-utils.sh" ] || { echo "ERROR: agent-registry-utils.sh not found"; exit 1; }

echo "✓ All required utilities available"
```

**Step 3: Initialize Logger**

For logger setup pattern, see [Standard Logger Setup](../docs/command-patterns.md#pattern-standard-logger-setup).

```bash
# Initialize adaptive planning logger
source "$UTILS_DIR/adaptive-planning-logger.sh"

# Logger is now available for all subsequent operations
```

**Implement-specific logging events**:
- Complexity threshold evaluations (log_complexity_check)
- Test failure pattern detection (log_test_failure_pattern)
- Scope drift detections (log_scope_drift)
- Replan invocations (log_replan_invocation)
- Loop prevention enforcement (log_loop_prevention)
- Collapse opportunity evaluations (log_collapse_check)

**Log file**: `.claude/logs/adaptive-planning.log` (10MB max, 5 files retained)

**Step 4: Initialize Progress Dashboard (Optional)**

If the `--dashboard` flag is present, source and initialize the progress dashboard utility:

```bash
# Parse --dashboard flag from arguments
DASHBOARD_ENABLED=false
for arg in "$@"; do
  if [ "$arg" = "--dashboard" ]; then
    DASHBOARD_ENABLED=true
    break
  fi
done

# Source dashboard utility if enabled
if [ "$DASHBOARD_ENABLED" = "true" ]; then
  if [ -f "$UTILS_DIR/progress-dashboard.sh" ]; then
    source "$UTILS_DIR/progress-dashboard.sh"

    # Detect terminal capabilities
    TERMINAL_CAPABILITIES=$(detect_terminal_capabilities)
    ANSI_SUPPORTED=$(echo "$TERMINAL_CAPABILITIES" | jq -r '.ansi_supported')

    if [ "$ANSI_SUPPORTED" != "true" ]; then
      echo "⚠ Dashboard requested but terminal doesn't support ANSI"
      echo "  Reason: $(echo "$TERMINAL_CAPABILITIES" | jq -r '.reason')"
      echo "  Falling back to traditional progress markers"
      DASHBOARD_ENABLED=false
    else
      echo "✓ Progress dashboard enabled (ANSI terminal detected)"
    fi
  else
    echo "⚠ progress-dashboard.sh not found, disabling dashboard"
    DASHBOARD_ENABLED=false
  fi
fi
```

**Dashboard lifecycle during implementation**:

1. **Before phase loop begins**: Call `initialize_dashboard "$PLAN_NAME" "$TOTAL_PHASES"`
2. **After each phase completes**: Call `update_dashboard_phase "$PHASE_NUM" "$PHASE_STATUS" "$CURRENT_TASK"`
3. **During phase execution**: Update dashboard with test results and current task
4. **On completion or error**: Call `clear_dashboard` before displaying final messages

**Integration Complete**: All shared utilities are now available for use throughout implementation

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

If the `--dry-run` flag is detected, execute preview mode instead of actual implementation:

**Step 1: Parse Flag and Plan**
```bash
# Check for --dry-run flag
DRY_RUN=false
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN=true
    break
  fi
done

if [ "$DRY_RUN" = "true" ]; then
  # Parse plan structure
  PLAN_PATH="$1"  # First argument is plan path
  STRUCTURE_LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

  # Extract plan metadata
  PLAN_NAME=$(grep "^# " "$PLAN_PATH" | head -1 | sed 's/^# //')
  TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_PATH")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Dry-Run Mode: $PLAN_NAME"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi
```

**Step 2: Analyze Each Phase**
```bash
# For each phase, gather analysis data
declare -a PHASE_ANALYSIS

for phase_num in $(seq 1 $TOTAL_PHASES); do
  # Extract phase details
  PHASE_SECTION=$(sed -n "/^### Phase $phase_num:/,/^### Phase $((phase_num + 1)):/p" "$PLAN_PATH")
  PHASE_NAME=$(echo "$PHASE_SECTION" | grep "^### Phase $phase_num:" | sed "s/^### Phase $phase_num: //")
  TASK_LIST=$(echo "$PHASE_SECTION" | grep "^- \[ \]" || echo "")
  TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")

  # Run hybrid complexity evaluation
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"
  COMPLEXITY_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_PATH")
  COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | jq -r '.final_score')

  # Determine agent assignment
  AGENT_TYPE="None"
  if echo "$PHASE_NAME" | grep -qi "document\|readme\|doc"; then
    AGENT_TYPE="doc-writer"
  elif echo "$PHASE_NAME" | grep -qi "test"; then
    AGENT_TYPE="test-specialist"
  elif echo "$PHASE_NAME" | grep -qi "debug"; then
    AGENT_TYPE="debug-specialist"
  elif (( $(echo "$COMPLEXITY_SCORE >= 10" | bc -l) )); then
    AGENT_TYPE="code-writer (think harder)"
  elif (( $(echo "$COMPLEXITY_SCORE >= 8" | bc -l) )); then
    AGENT_TYPE="code-writer (think hard)"
  elif (( $(echo "$COMPLEXITY_SCORE >= 6" | bc -l) )); then
    AGENT_TYPE="code-writer (think)"
  elif (( $(echo "$COMPLEXITY_SCORE >= 3" | bc -l) )); then
    AGENT_TYPE="code-writer"
  fi

  # Extract file references from tasks
  FILES_MENTIONED=$(echo "$TASK_LIST" | grep -o '[a-zA-Z0-9_/-]*\.\(lua\|js\|py\|sh\|md\)' | sort -u | tr '\n' ', ' | sed 's/,$//')

  # Extract test references
  TESTS_MENTIONED=$(echo "$TASK_LIST" | grep -o 'test[a-zA-Z0-9_/-]*\.\(lua\|js\|py\|sh\)' | sort -u | tr '\n' ', ' | sed 's/,$//')

  # Estimate duration based on complexity and agent type
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-registry-utils.sh"
  if [ "$AGENT_TYPE" != "None" ]; then
    AGENT_METRICS=$(get_agent_metrics "$(echo $AGENT_TYPE | cut -d' ' -f1)")
    AVG_DURATION=$(echo "$AGENT_METRICS" | jq -r '.average_duration_seconds // 600')
    ESTIMATED_MINUTES=$(echo "scale=0; ($AVG_DURATION + ($COMPLEXITY_SCORE * 60)) / 60" | bc)
  else
    ESTIMATED_MINUTES=$(echo "scale=0; $COMPLEXITY_SCORE * 2" | bc)
  fi

  # Store phase analysis
  PHASE_ANALYSIS[$phase_num]=$(cat <<EOF
{
  "phase_num": $phase_num,
  "phase_name": "$PHASE_NAME",
  "complexity": $COMPLEXITY_SCORE,
  "tasks": $TASK_COUNT,
  "agent": "$AGENT_TYPE",
  "files": "$FILES_MENTIONED",
  "tests": "$TESTS_MENTIONED",
  "duration_minutes": $ESTIMATED_MINUTES
}
EOF
)
done
```

**Step 3: Parse Dependencies and Generate Waves**
```bash
# Use dependency parser to generate execution waves
WAVES=$(.claude/lib/parse-phase-dependencies.sh "$PLAN_PATH")

# Parse wave information
declare -A WAVE_PHASES
WAVE_COUNT=0

while IFS=: read -r wave_label phase_list; do
  WAVE_NUM=$(echo "$wave_label" | grep -o '[0-9]*')
  WAVE_PHASES[$WAVE_NUM]="$phase_list"
  WAVE_COUNT=$WAVE_NUM
done <<< "$WAVES"
```

**Step 4: Display Dry-Run Preview**
```bash
# Display formatted preview
echo "┌─────────────────────────────────────────────────────────────┐"
printf "│ Implementation Plan: %-38s │\n" "$PLAN_NAME (Dry-Run)"
echo "├─────────────────────────────────────────────────────────────┤"
printf "│ Plan Structure: Level %-1s %-33s │\n" "$STRUCTURE_LEVEL" "(expanded phases: ...)"
TOTAL_DURATION=0
for i in $(seq 1 $TOTAL_PHASES); do
  PHASE_DATA="${PHASE_ANALYSIS[$i]}"
  DURATION=$(echo "$PHASE_DATA" | jq -r '.duration_minutes')
  TOTAL_DURATION=$((TOTAL_DURATION + DURATION))
done
printf "│ Total Phases: %-2s  |  Estimated Duration: ~%-2s minutes   │\n" "$TOTAL_PHASES" "$TOTAL_DURATION"
echo "├─────────────────────────────────────────────────────────────┤"

# Display each wave
for wave_num in $(seq 1 $WAVE_COUNT); do
  PHASES_IN_WAVE="${WAVE_PHASES[$wave_num]}"
  PHASE_ARRAY=($PHASES_IN_WAVE)
  PHASE_COUNT=${#PHASE_ARRAY[@]}

  if [ $PHASE_COUNT -eq 1 ]; then
    echo "│ Wave $wave_num (Sequential):                                       │"
  else
    printf "│ Wave %d (Parallel - %d phases):                              │\n" "$wave_num" "$PHASE_COUNT"
  fi

  for phase_num in "${PHASE_ARRAY[@]}"; do
    PHASE_DATA="${PHASE_ANALYSIS[$phase_num]}"
    PHASE_NAME=$(echo "$PHASE_DATA" | jq -r '.phase_name' | cut -c 1-30)
    COMPLEXITY=$(echo "$PHASE_DATA" | jq -r '.complexity')
    TASKS=$(echo "$PHASE_DATA" | jq -r '.tasks')
    AGENT=$(echo "$PHASE_DATA" | jq -r '.agent' | cut -c 1-12)
    FILES=$(echo "$PHASE_DATA" | jq -r '.files' | cut -c 1-50)
    TESTS=$(echo "$PHASE_DATA" | jq -r '.tests' | cut -c 1-50)
    DURATION=$(echo "$PHASE_DATA" | jq -r '.duration_minutes')

    printf "│   Phase %d: %-30s [%-10s] %2dmin │\n" "$phase_num" "$PHASE_NAME" "$AGENT" "$DURATION"
    printf "│     Complexity: %-4s  |  Tasks: %-2s  |  Agent: %-12s │\n" "$COMPLEXITY" "$TASKS" "$AGENT"

    if [ -n "$FILES" ] && [ "$FILES" != "null" ]; then
      printf "│     Files: %-50s │\n" "$FILES"
    fi
    if [ -n "$TESTS" ] && [ "$TESTS" != "null" ]; then
      printf "│     Tests: %-50s │\n" "$TESTS"
    fi
    echo "│                                                              │"
  done
done

echo "├─────────────────────────────────────────────────────────────┤"
printf "│ Execution Summary:                                           │\n"
PARALLEL_PHASES=$((TOTAL_PHASES - WAVE_COUNT))
printf "│   Total Waves: %-2s  |  Parallel Phases: %-2s  |  Max Concurrent: 3│\n" "$WAVE_COUNT" "$PARALLEL_PHASES"

# Count unique files and tests
UNIQUE_FILES=$(for i in $(seq 1 $TOTAL_PHASES); do echo "${PHASE_ANALYSIS[$i]}" | jq -r '.files'; done | tr ',' '\n' | sort -u | wc -l)
UNIQUE_TESTS=$(for i in $(seq 1 $TOTAL_PHASES); do echo "${PHASE_ANALYSIS[$i]}" | jq -r '.tests'; done | tr ',' '\n' | sort -u | wc -l)

printf "│   Files Modified: %-2s  |  Tests Created: %-2s                    │\n" "$UNIQUE_FILES" "$UNIQUE_TESTS"

# Calculate parallel time savings
PARALLEL_DURATION=$(echo "scale=0; $TOTAL_DURATION * 0.7" | bc)
printf "│   Estimated Time: %d minutes (%dmin with parallelism)       │\n" "$TOTAL_DURATION" "$PARALLEL_DURATION"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
```

**Step 5: Prompt for Confirmation**
```bash
# Ask user if they want to proceed
read -p "Proceed with implementation? (y/n): " PROCEED

if [ "$PROCEED" != "y" ] && [ "$PROCEED" != "Y" ]; then
  echo "Dry-run complete. Exiting without changes."
  exit 0
fi

# If user confirms, continue with normal implementation
echo "Proceeding with implementation..."
echo ""
```

**Dry-Run Exit**: If user declines, exit immediately without making changes. If user confirms, continue with normal implementation flow.

## Parallel Execution with Dependencies

Before executing phases, I will analyze phase dependencies to enable parallel execution:

### Dependency Analysis

**Step 1: Parse Dependencies**
```bash
# Use dependency parser to generate execution waves
WAVES=$(.claude/lib/parse-phase-dependencies.sh "$PLAN_FILE")
```

**Step 2: Group Phases into Waves**
- Parse wave output: `WAVE_1:1`, `WAVE_2:2 3`, `WAVE_3:4`
- Each wave contains phases that can execute in parallel
- Waves execute sequentially (wait for wave completion before next)

**Step 3: Execute Waves**

For each wave:
1. **Single Phase**: Execute normally (sequential)
2. **Multiple Phases**: Execute in parallel
   - Invoke multiple agents simultaneously using multiple Task tool calls in one message
   - Each phase gets its own agent based on complexity analysis
   - Wait for all phases in wave to complete
   - Collect results from all parallel executions

**Step 4: Error Handling**
- If any phase in a wave fails, stop execution
- Preserve checkpoint with partial completion
- Report which phases succeeded and which failed
- User can resume from failed wave

### Parallel Execution Safety

- **Max Parallelism**: Limit to 3 concurrent phases per wave
- **Fail-Fast**: Stop wave execution if any phase fails
- **Checkpoint Preservation**: Save state after each wave
- **Result Collection**: Aggregate test results and file changes from parallel phases

### Dependency Format

Phases declare dependencies in their header:
```markdown
### Phase N: Phase Name
dependencies: [1, 2]  # Depends on phases 1 and 2
```

- Empty array `[]` or omitted = no dependencies (can run in wave 1)
- Multiple dependencies = wait for all to complete
- Circular dependencies are detected and rejected

## Phase Execution Protocol

### Execution Flow

**Sequential Execution** (no dependencies or dependencies: [] omitted):
- Execute phases one by one in order (Phase 1, 2, 3, ...)
- Traditional workflow, fully backward compatible

**Parallel Execution** (with dependency declarations):
- Parse dependencies into execution waves
- Execute each wave sequentially
- Within each wave, execute phases in parallel if wave contains >1 phase
- Wait for wave completion before next wave

For each wave, I will:

### 0. Wave Initialization
- Identify phases in current wave from dependency analysis
- Log: "Executing Wave N with M phase(s): [phase numbers]"

For each phase in the wave, I will prepare:

### 1. Display Phase Information
Show the phase number, name, and all tasks that need to be completed.

### 1.5. Phase Complexity Analysis and Agent Selection

For agent delegation patterns, see [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection).

**Note**: This step uses the hybrid complexity score ($COMPLEXITY_SCORE) from Step 1.5 (Hybrid Complexity Evaluation) for agent selection thresholds.

**Implement-specific complexity scoring**:

1. **Run complexity analyzer**:
   ```bash
   .claude/lib/analyze-phase-complexity.sh "<phase-name>" "<task-list>"
   ```

2. **Agent selection thresholds** (using hybrid complexity score from Step 1.5):
   - **Direct execution** (score 0-2): Simple phases
   - **code-writer** (score 3-5): Medium complexity
   - **code-writer + think** (score 6-7): Medium-high complexity
   - **code-writer + think hard** (score 8-9): High complexity
   - **code-writer + think harder** (score 10+): Critical complexity

3. **Special case overrides**:
   - **doc-writer**: Documentation/README phases
   - **test-specialist**: Testing phases
   - **debug-specialist**: Debug/investigation phases

**Delegation workflow**:
- Announce delegation with complexity score
- Invoke agent via Task tool with behavioral injection
- Monitor PROGRESS markers for visibility
- Collect results for testing and commit steps

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

Evaluate phase complexity using hybrid approach (threshold + agent for borderline cases).

**Workflow**:

1. **Calculate threshold-based score**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"

   THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
   TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")
   ```

2. **Determine if agent evaluation needed**:
   ```bash
   AGENT_NEEDED="false"
   if [ "$THRESHOLD_SCORE" -ge 7 ] || [ "$TASK_COUNT" -ge 8 ]; then
     AGENT_NEEDED="true"
     echo "Borderline complexity detected (score: $THRESHOLD_SCORE, tasks: $TASK_COUNT)"
     echo "Invoking complexity_estimator agent for context-aware analysis..."
   fi
   ```

3. **Run hybrid evaluation**:
   ```bash
   EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")

   COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
   EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')

   echo "Complexity Score: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"

   # If agent was used, display reasoning
   if [ "$AGENT_NEEDED" = "true" ]; then
     AGENT_REASONING=$(echo "$EVALUATION_RESULT" | jq -r '.agent_reasoning // "N/A"')
     if [ "$AGENT_REASONING" != "N/A" ]; then
       echo "Agent Reasoning: $AGENT_REASONING"
     fi

     # Check for agent errors
     AGENT_ERROR=$(echo "$EVALUATION_RESULT" | jq -r '.agent_error // "null"')
     if [ "$AGENT_ERROR" != "null" ]; then
       echo "⚠ Agent evaluation failed: $AGENT_ERROR"
       echo "  Falling back to threshold score: $COMPLEXITY_SCORE"
     fi
   fi
   ```

4. **Log evaluation for analytics**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/adaptive-planning-logger.sh"

   log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" \
     "$COMPLEXITY_THRESHOLD_HIGH" "$([ $AGENT_NEEDED = 'true' ] && echo 'true' || echo 'false')"

   # If score reconciliation occurred, log discrepancy details
   if [ "$EVALUATION_METHOD" != "threshold" ]; then
     THRESHOLD_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.reconciliation_details.threshold_score // 0')
     AGENT_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.reconciliation_details.agent_score // 0')
     SCORE_DIFF=$(echo "$EVALUATION_RESULT" | jq -r '.reconciliation_details.score_difference // 0')

     log_complexity_discrepancy "$PHASE_NAME" "$THRESHOLD_SCORE" "$AGENT_SCORE" \
       "$SCORE_DIFF" "$AGENT_REASONING" "$EVALUATION_METHOD"
   fi
   ```

5. **Use score for downstream decisions**:
   - Export COMPLEXITY_SCORE for Steps 1.55 (Proactive Expansion) and 1.6 (Agent Selection)
   ```bash
   export COMPLEXITY_SCORE
   export EVALUATION_METHOD
   ```

**Expected Impact**: 30% reduction in expansion errors via context-aware evaluation

**Error Handling**:
- Agent timeout (60s): Fallback to threshold score
- Agent invocation failure: Fallback to threshold score
- Invalid agent response: Fallback to threshold score
- All fallbacks logged for improvement tracking

### 1.55. Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Note**: This step uses the hybrid complexity score ($COMPLEXITY_SCORE) from Step 1.5.

**Evaluation criteria**: Task complexity, scope breadth, interrelationships, parallel work potential, clarity vs detail tradeoff

**If expansion recommended**: Display formatted recommendation with rationale and `/expand phase` command

**If not needed**: Continue silently to implementation

**Relationship to reactive expansion** (Step 3.4):
- **Proactive** (1.55): Before implementation, recommendation only
- **Reactive** (3.4): After implementation, auto-revision via `/revise --auto-mode`

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

**Workflow**: Tiered error recovery with automatic /debug invocation and user choice prompts

This section implements a 4-level error recovery strategy that automatically handles test failures:
- Level 1: Immediate error classification and suggestions
- Level 2: Retry with timeout for transient errors
- Level 3: Retry with fallback for tool access errors
- Level 4: Automatic /debug invocation with user choices (r/c/s/a)

**Level 1: Immediate Classification & Suggestions**

```bash
# Classify error type using error-utils.sh
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"
ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")
ERROR_LOCATION=$(extract_location "$TEST_OUTPUT")
SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT" "$ERROR_LOCATION")

# Display immediate suggestions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Failure Detected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Error Type: $ERROR_TYPE"
echo "Location: $ERROR_LOCATION"
echo ""
echo "$SUGGESTIONS"
echo ""
```

**Level 2: Transient Error Retry**

```bash
# Check for transient errors (timeout, busy, locked)
if [ "$ERROR_TYPE" = "timeout" ] || echo "$TEST_OUTPUT" | grep -qi "busy\|locked"; then
  RETRY_META=$(retry_with_timeout "Phase $CURRENT_PHASE tests" "$ATTEMPT_NUMBER")
  SHOULD_RETRY=$(echo "$RETRY_META" | jq -r '.should_retry')
  NEW_TIMEOUT=$(echo "$RETRY_META" | jq -r '.new_timeout')

  if [ "$SHOULD_RETRY" = "true" ]; then
    echo "Retrying with extended timeout: ${NEW_TIMEOUT}ms"
    # Re-run tests with new timeout
    # If successful: Skip to next phase
    # If failed: Continue to Level 3
  fi
fi
```

**Level 3: Fallback with Reduced Toolset**

```bash
# Check for tool access errors
if echo "$TEST_OUTPUT" | grep -qi "tool.*failed\|access.*denied"; then
  FALLBACK_META=$(retry_with_fallback "Phase $CURRENT_PHASE" "$ATTEMPT_NUMBER")
  REDUCED_TOOLSET=$(echo "$FALLBACK_META" | jq -r '.reduced_toolset')

  echo "Retrying with reduced toolset: $REDUCED_TOOLSET"
  # Re-invoke agent with reduced tools
  # If successful: Skip to next phase
  # If failed: Continue to Level 4
fi
```

**Level 4: Automatic Debug Invocation**

No user prompt - automatically invoke /debug for root cause analysis:

```bash
echo "Invoking debug agent for root cause analysis..."

# Build debug command
ERROR_MESSAGE=$(echo "$TEST_OUTPUT" | head -c 100)
DEBUG_COMMAND="/debug \"Phase $CURRENT_PHASE test failure: $ERROR_MESSAGE\" \"$PLAN_PATH\""

# Invoke /debug via SlashCommand tool
DEBUG_RESULT=$(invoke_slash_command "$DEBUG_COMMAND")

# Parse debug report path from response
DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -o 'specs/reports/[0-9]*_debug_.*\.md' | head -1)

# Fallback to analyze-error.sh if /debug fails
if [ -z "$DEBUG_REPORT_PATH" ]; then
  echo "⚠ Debug agent failed, using analyze-error.sh fallback"
  ANALYSIS_RESULT=$(.claude/lib/analyze-error.sh "$TEST_OUTPUT")
  ROOT_CAUSE=$(echo "$ANALYSIS_RESULT" | grep "^Error Type:" | cut -d: -f2-)
  SUGGESTIONS=$(echo "$ANALYSIS_RESULT" | sed -n '/^Suggestions:/,/^$/p')
else
  # Extract root cause from debug report
  ROOT_CAUSE=$(sed -n '/^## Root Cause Analysis/,/^##/p' "$DEBUG_REPORT_PATH" |
               grep -v '^##' | head -5 | tr '\n' ' ' | cut -c 1-80)
fi
```

**Display Debug Summary**

```bash
if [ -n "$DEBUG_REPORT_PATH" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────────────────┐"
  printf "│ %-63s │\n" "Phase $CURRENT_PHASE Test Failure"
  echo "├─────────────────────────────────────────────────────────────────┤"
  printf "│ Root Cause: %-51s │\n" "${ROOT_CAUSE:0:51}"
  printf "│ Debug Report: %-49s │\n" "$(basename "$DEBUG_REPORT_PATH")"
  echo "└─────────────────────────────────────────────────────────────────┘"
  echo ""
fi
```

**User Choice Prompt**

Present clear choices with explanations:

```bash
echo "Choose action:"
echo ""
echo "  (r) Revise plan with debug findings"
echo "      → Automatically update plan structure or tasks based on analysis"
echo "      → Retry phase after revision"
echo ""
echo "  (c) Continue to next phase"
echo "      → Mark this phase [INCOMPLETE] with debugging notes"
echo "      → Proceed to Phase $((CURRENT_PHASE + 1))"
echo ""
echo "  (s) Skip current phase"
echo "      → Mark this phase [SKIPPED]"
echo "      → Proceed to Phase $((CURRENT_PHASE + 1))"
echo ""
echo "  (a) Abort implementation"
echo "      → Save checkpoint for later resumption"
echo "      → Resume with: /implement $PLAN_PATH $CURRENT_PHASE"
echo ""

# Read and validate choice
while true; do
  read -p "Choose action (r/c/s/a): " USER_CHOICE
  case "$USER_CHOICE" in
    r|c|s|a) break ;;
    *) echo "Invalid choice. Please enter r, c, s, or a." ;;
  esac
done

# Log choice
log_user_choice "$CURRENT_PHASE" "$USER_CHOICE" "$DEBUG_REPORT_PATH"
```

**Execute Action**

```bash
case "$USER_CHOICE" in
  r)
    # Build revision context JSON
    REVISION_CONTEXT=$(cat <<EOF
{
  "revision_type": "add_phase",
  "current_phase": $CURRENT_PHASE,
  "reason": "Test failure: $ROOT_CAUSE",
  "debug_report": "$DEBUG_REPORT_PATH",
  "suggested_action": "Add prerequisites or update tasks based on debug findings"
}
EOF
)

    # Invoke /revise --auto-mode
    echo "Invoking /revise --auto-mode to update plan..."
    REVISE_RESULT=$(invoke_slash_command "/revise --auto-mode --context '$REVISION_CONTEXT' '$PLAN_PATH'")

    # Parse response
    REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

    if [ "$REVISE_STATUS" = "success" ]; then
      echo "✓ Plan revised successfully"
      echo "  Retrying Phase $CURRENT_PHASE..."
      # Retry phase (loop back to Step 2: Implementation)
    else
      echo "✗ Plan revision failed"
      echo "  Falling back to (c) Continue action"
      USER_CHOICE="c"  # Fallback
    fi
    ;;

  c)
    # Mark phase [INCOMPLETE] and add debugging notes
    add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "$ROOT_CAUSE" "Incomplete"

    # Update phase heading
    sed -i "s/^### Phase $CURRENT_PHASE: \(.*\)$/### Phase $CURRENT_PHASE: \1 [INCOMPLETE]/" "$PLAN_PATH"

    # Save checkpoint
    save_checkpoint "in_progress" "$CURRENT_PHASE" "$((CURRENT_PHASE + 1))"

    # Proceed to next phase
    CURRENT_PHASE=$((CURRENT_PHASE + 1))
    ;;

  s)
    # Mark phase [SKIPPED]
    add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "$ROOT_CAUSE" "Skipped"

    sed -i "s/^### Phase $CURRENT_PHASE: \(.*\)$/### Phase $CURRENT_PHASE: \1 [SKIPPED]/" "$PLAN_PATH"

    # Save checkpoint
    save_checkpoint "in_progress" "$CURRENT_PHASE" "$((CURRENT_PHASE + 1))"

    # Proceed to next phase
    CURRENT_PHASE=$((CURRENT_PHASE + 1))
    ;;

  a)
    # Save checkpoint with debug info
    save_checkpoint "paused" "$CURRENT_PHASE" "$CURRENT_PHASE" "$ROOT_CAUSE" "$DEBUG_REPORT_PATH"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Implementation Aborted"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Checkpoint saved with debug information"
    echo "Resume with: /implement $PLAN_PATH $CURRENT_PHASE"
    echo ""

    # Exit workflow
    exit 0
    ;;
esac
```

**Helper Function: add_debugging_notes**

```bash
add_debugging_notes() {
  local plan_path="$1"
  local phase_num="$2"
  local debug_report_path="$3"
  local root_cause="$4"
  local resolution_status="$5"  # Pending, Applied, Incomplete, Skipped

  # Check if debugging notes already exist
  local has_debug_notes
  has_debug_notes=$(grep -q "#### Debugging Notes" "$plan_path" && echo "true" || echo "false")

  if [ "$has_debug_notes" = "false" ]; then
    # Create new debugging notes section
    local debug_notes=$(cat <<EOF

#### Debugging Notes
- **Date**: $(date +%Y-%m-%d)
- **Issue**: Phase $phase_num test failure
- **Debug Report**: [$debug_report_path]($debug_report_path)
- **Root Cause**: $root_cause
- **Resolution**: $resolution_status
EOF
)
    # Insert after phase tasks using Edit tool
  else
    # Append new iteration
    local iteration_count
    iteration_count=$(grep -c "^**Iteration" "$plan_path" || echo "0")
    iteration_count=$((iteration_count + 1))

    local new_iteration=$(cat <<EOF

**Iteration $iteration_count** ($(date +%Y-%m-%d))
- **Issue**: Phase $phase_num test failure
- **Debug Report**: [$debug_report_path]($debug_report_path)
- **Root Cause**: $root_cause
- **Resolution**: $resolution_status
EOF
)
    # Append using Edit tool

    # Check for escalation
    if [ $iteration_count -ge 3 ]; then
      echo "**Status**: Escalated to manual intervention (3+ debugging attempts)" >> "$plan_path"
    fi
  fi

  echo "✓ Debugging notes added to plan (Status: $resolution_status)"
}
```

**Error categories**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown

**Benefits**:
- **50% faster debug workflow**: Auto-invocation eliminates prompt delays
- **Clear user choices**: No "should I debug?" questions, just actionable options
- **Tiered recovery**: 4 levels of increasingly sophisticated error handling
- **Graceful degradation**: Fallback to analyze-error.sh if /debug fails

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
**Incremental plan updates after each phase:**

**Step 1: Mark Phase Tasks Complete**

Use the Edit tool to mark tasks as complete in the appropriate file:
- **Level 0**: Update tasks in main plan file
- **Level 1**: If phase is expanded, update tasks in phase file; otherwise update in main plan
- **Level 2**: If stage is expanded, update tasks in stage file; otherwise in phase file

**Approach**:
- Use Edit tool to change completed tasks: `- [ ]` → `- [x]`
- Check if phase/stage is expanded using progressive utilities
- Update in appropriate location based on expansion status

**Step 2: Add Phase Completion Marker**

Add completion marker to phase heading:
- **Level 0**: Add `[COMPLETED]` to phase heading in main plan
- **Level 1**: If phase is expanded, add marker to phase file; otherwise to main plan
- **Level 2**: Mark appropriate stage files and phase overview as complete

Use Edit tool to change:
`### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`

**Step 3: Verify Plan Updated**

Check that tasks are properly marked by reading the updated file and verifying all phase tasks show `[x]`.

**Step 4: Add/Update Implementation Progress Section**
- Use Edit tool to add or update "## Implementation Progress" section
- Place after metadata, before overview
- Include:
  - Last completed phase number and name
  - Completion date
  - Git commit hash
  - Resume instructions: `/implement <plan-file> <next-phase-number>`

**Example Implementation Progress Section:**
```markdown
## Implementation Progress

- **Last Completed Phase**: Phase 2: Core Implementation
- **Date**: 2025-10-03
- **Commit**: abc1234
- **Status**: In Progress (2/5 phases complete)
- **Resume**: `/implement specs/plans/018.md 3`
```

### 5.5. Automatic Collapse Detection

After completing a phase and committing changes, automatically evaluate if an expanded phase should be collapsed back to the main plan file based on complexity heuristics.

**Trigger Conditions:**

Only check phases that meet BOTH criteria:
1. **Phase is expanded** (in a separate file, not inline)
2. **Phase is completed** (all tasks marked [x])

**Detection Logic:**

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source structure evaluation utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/structure-eval-utils.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh"

# Check if phase is expanded and completed
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
IS_PHASE_COMPLETED=$(grep -q "\[COMPLETED\]" "$PHASE_FILE" && echo "true" || echo "false")

if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then
  # Get phase details for complexity calculation
  PHASE_FILE=$(get_phase_file "$PLAN_PATH" "$CURRENT_PHASE")

  if [ -f "$PHASE_FILE" ]; then
    # Extract phase metrics
    PHASE_CONTENT=$(cat "$PHASE_FILE")
    PHASE_NAME=$(grep "^### Phase $CURRENT_PHASE" "$PHASE_FILE" | head -1 | sed "s/^### Phase $CURRENT_PHASE:* //" | sed 's/ \[.*\]$//')
    TASK_COUNT=$(grep -c "^- \[x\]" "$PHASE_FILE" || echo "0")

    # Calculate complexity score
    COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")

    # Log collapse check (always, for observability)
    TRIGGERED="false"
    if [ "$TASK_COUNT" -le 5 ] && awk -v s="$COMPLEXITY_SCORE" 'BEGIN {exit !(s < 6.0)}'; then
      TRIGGERED="true"
    fi
    log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "6.0" "$TRIGGERED"

    # Check collapse thresholds: tasks ≤ 5 AND complexity < 6.0
    if [ "$TASK_COUNT" -le 5 ]; then
      if awk -v score="$COMPLEXITY_SCORE" 'BEGIN {exit !(score < 6.0)}'; then

        # Build collapse context JSON
        COLLAPSE_CONTEXT=$(cat <<EOF
{
  "revision_type": "collapse_phase",
  "current_phase": $CURRENT_PHASE,
  "reason": "Phase $CURRENT_PHASE completed and now simple ($TASK_COUNT tasks, complexity $COMPLEXITY_SCORE)",
  "suggested_action": "Collapse Phase $CURRENT_PHASE back into main plan",
  "simplicity_metrics": {
    "tasks": $TASK_COUNT,
    "complexity_score": $COMPLEXITY_SCORE,
    "completion": true
  }
}
EOF
)

        # Invoke /revise --auto-mode for automatic collapse
        echo "Triggering auto-collapse for Phase $CURRENT_PHASE (simple after completion)..."
        REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$COLLAPSE_CONTEXT'")

        # Parse revision result
        REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

        if [ "$REVISE_STATUS" = "success" ]; then
          # Collapse succeeded
          NEW_LEVEL=$(echo "$REVISE_RESULT" | jq -r '.new_structure_level')

          # Log successful collapse invocation
          log_collapse_invocation "$CURRENT_PHASE" "auto" "Phase simple after completion"

          echo "✓ Auto-collapsed Phase $CURRENT_PHASE (structure level now: $NEW_LEVEL)"

          # Update plan path if it changed (Level 1 → Level 0)
          UPDATED_FILE=$(echo "$REVISE_RESULT" | jq -r '.updated_file')
          if [ "$UPDATED_FILE" != "$PLAN_PATH" ]; then
            PLAN_PATH="$UPDATED_FILE"
            echo "  Plan file updated: $PLAN_PATH"
          fi
        else
          # Collapse failed - log but continue
          ERROR_MSG=$(echo "$REVISE_RESULT" | jq -r '.error_message')
          echo "⚠ Auto-collapse failed: $ERROR_MSG"
          echo "  Continuing with expanded structure"
        fi
      fi
    fi
  fi
fi
```

**Collapse Thresholds:**
- **Tasks**: ≤ 5 completed tasks
- **Complexity**: < 6.0 (medium-low complexity)
- **Both Required**: Both thresholds must be met (conservative approach)

**Automatic Actions:**
1. Calculate phase complexity using `calculate_phase_complexity()` from complexity-utils.sh
2. Check if thresholds met (tasks ≤ 5 AND complexity < 6.0)
3. Log collapse check for observability
4. If triggered: Build collapse context JSON and invoke `/revise --auto-mode collapse_phase`
5. Parse response and update plan path if structure level changed
6. Log collapse invocation (auto trigger) for audit trail

**Logging:**
- **collapse_check**: Logs every evaluation (triggered or not)
- **collapse_invocation**: Logs only when collapse executes (trigger=auto)
- **Log file**: `.claude/logs/adaptive-planning.log`

**Non-Blocking:**
- Collapse failures are logged but don't stop implementation
- Phase remains expanded if collapse fails
- Implementation continues to next phase regardless

**Edge Cases:**
- **Phase with stages**: Collapse will fail (must collapse stages first)
- **Incomplete phase**: Skipped silently (not eligible)
- **Complex phase**: Not triggered (stays expanded)
- **Structure level change**: Plan path updated if last expanded phase (Level 1 → Level 0)

### 6. Incremental Summary Generation
**Create or update partial summary after each phase:**

**Step 1: Determine Summary Path**
- Extract specs directory from plan metadata
- Summary path: `[specs-dir]/summaries/NNN_partial.md`
- Number matches plan number

**Step 2: Create or Update Partial Summary**
- If first phase: Use Write tool to create new partial summary
- If subsequent phase: Use Edit tool to update existing partial summary
- Include:
  - Status: "in_progress"
  - Phases completed: "M/N"
  - Last completed phase name and date
  - Last git commit hash
  - Resume instructions

**Partial Summary Template:**
```markdown
# Implementation Summary: [Feature Name] (PARTIAL)

## Metadata
- **Date Started**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Summary Number**: [NNN]
- **Plan**: [Link to plan file]
- **Status**: in_progress
- **Phases Completed**: M/N

## Progress

### Last Completed Phase
- **Phase**: Phase M: [Phase Name]
- **Completed**: [YYYY-MM-DD]
- **Commit**: [hash]

### Phases Summary
- [x] Phase 1: [Name] - Completed [date]
- [x] Phase 2: [Name] - Completed [date]
- [ ] Phase 3: [Name] - Pending
- [ ] Phase 4: [Name] - Pending

## Resume Instructions
To continue this implementation:
```
/implement [plan-path] M+1
```

Auto-resume is enabled by default when calling /implement without arguments.

## Implementation Notes
[Brief notes about progress, challenges, or decisions made]
```

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

When tests fail, use error-utils.sh for systematic error analysis and recovery:

**Step 1: Capture Error Output**
```bash
# Capture test failure output
TEST_ERROR_OUTPUT=$(run_tests 2>&1)
TEST_EXIT_CODE=$?
```

**Step 2: Classify Error Type**
```bash
# Use error-utils.sh to classify the error
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"

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
# Use error-utils.sh to format a structured error report
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

This command does not directly invoke specialized agents. Instead, it executes implementation directly using its own tools (Read, Edit, Write, Bash, TodoWrite).

### Potential Agent Integration (Future Enhancement)
While `/implement` currently works autonomously, it could potentially delegate to specialized agents:

- **code-writer**: For complex code generation tasks
  - Would receive plan context and phase requirements
  - Could apply standards more intelligently
  - Would use TodoWrite for task tracking

- **test-specialist**: For test execution and analysis
  - Could provide more detailed test failure diagnostics
  - Would categorize errors more effectively
  - Could suggest fixes for common test failures

- **code-reviewer**: For standards compliance checking
  - Optional pre-commit validation
  - Could run after each phase before marking complete
  - Would provide structured feedback on standards violations

### Current Design Rationale
`/implement` executes directly without agent delegation because:
1. **Performance**: Avoids agent invocation overhead for simple implementations
2. **Context**: Maintains full implementation context across all phases
3. **Control**: Direct execution provides more predictable behavior
4. **Simplicity**: Easier to debug and reason about

For complex, multi-phase implementations requiring specialized expertise, use `/orchestrate` instead, which fully leverages the agent system.

## Checkpoint Detection and Resume

For checkpoint management patterns, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns).

**Implement-specific checkpoint workflow using checkpoint-utils.sh**:

**Step 1: Check for Existing Checkpoint**
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Load most recent implement checkpoint
CHECKPOINT_DATA=$(load_checkpoint "implement")
CHECKPOINT_EXISTS=$?

if [ $CHECKPOINT_EXISTS -eq 0 ]; then
  # Checkpoint found - parse state
  PLAN_PATH=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
  CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
  TOTAL_PHASES=$(echo "$CHECKPOINT_DATA" | jq -r '.total_phases')
fi
```

**Step 2: Smart Auto-Resume or Interactive Prompt**
```bash
if [ $CHECKPOINT_EXISTS -eq 0 ]; then
  # First check if checkpoint can be auto-resumed safely
  if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
    # All safety conditions met - auto-resume silently
    echo "✓ Auto-resuming from Phase $CURRENT_PHASE/$TOTAL_PHASES (all safety conditions met)"

    # Extract plan path and proceed with implementation
    PLAN_PATH=$(echo "$CHECKPOINT_DATA" | jq -r '.workflow_state.plan_path')
    CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')

    # Log auto-resume for audit trail
    source "$UTILS_DIR/adaptive-planning-logger.sh"
    log_checkpoint_auto_resume "$CURRENT_PHASE" "implement"
  else
    # Safety conditions not met - show interactive prompt with reason
    SKIP_REASON=$(get_skip_reason "$CHECKPOINT_FILE")

    echo "Found checkpoint: Phase $CURRENT_PHASE/$TOTAL_PHASES"
    echo "⚠ Cannot auto-resume: $SKIP_REASON"
    echo ""
    echo "Options: (r)esume, (s)tart fresh, (v)iew, (d)elete"
    read -r CHOICE

    case "$CHOICE" in
      r) # Resume from checkpoint (manual override)
         echo "Resuming from Phase $CURRENT_PHASE"
         ;;
      s) # Start fresh
         checkpoint_delete "implement" "$PROJECT_NAME"
         ;;
      v) # View checkpoint details
         cat "$CHECKPOINT_FILE" | jq .
         echo ""
         echo "Press Enter to continue..."
         read
         ;;
      d) # Delete and start fresh
         checkpoint_delete "implement" "$PROJECT_NAME"
         ;;
    esac
  fi
fi
```

**Step 3: Save Checkpoint After Each Phase**
```bash
# After successful git commit
save_checkpoint "implement" "$CHECKPOINT_DATA"

# Checkpoint data structure
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_description": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $NEXT_PHASE,
  "total_phases": $TOTAL_PHASES,
  "completed_phases": [$COMPLETED_PHASES_ARRAY],
  "status": "in_progress",
  "tests_passing": true,
  "replan_count": $REPLAN_COUNT,
  "phase_replan_count": {$PHASE_REPLAN_COUNTS},
  "replan_history": [$REPLAN_HISTORY_ARRAY]
}
EOF
)
```

**Step 4: Cleanup on Completion**
```bash
# On successful completion
delete_checkpoint "implement"

# On failure
archive_checkpoint "implement" "failed"
```

**Checkpoint state fields**:
- workflow_description, plan_path, current_phase, total_phases
- completed_phases, status, tests_passing
- replan_count, phase_replan_count, replan_history (for adaptive planning)

**Benefits of checkpoint-utils.sh**:
- **Smart auto-resume**: 90% of resumes happen automatically without user prompts
- **Safety checks**: 5 conditions verified before auto-resume (tests passing, no errors, age <7 days, plan not modified, status in_progress)
- **Clear feedback**: When auto-resume skipped, user sees exact reason why
- Automatic schema migration for checkpoint format changes
- Atomic save operations prevent corrupted checkpoints
- Consistent checkpoint naming and location
- Built-in validation before loading

**Auto-Resume Safety Conditions**:
1. ✓ Tests passing in last run (tests_passing = true)
2. ✓ No recent errors (last_error = null)
3. ✓ Checkpoint age < 7 days
4. ✓ Plan file not modified since checkpoint
5. ✓ Status = "in_progress"

**When to Expect Interactive Prompts**:
- Tests failed in last run → Manual review needed
- Errors in last run → Manual review needed
- Checkpoint > 7 days old → Confirm still relevant
- Plan file modified → Review changes before resuming
- Checkpoint status not "in_progress" → Verify state

Let me start by finding your implementation plan.

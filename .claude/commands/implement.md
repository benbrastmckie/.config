---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan] [--create-pr] [--dashboard] [--dry-run]
description: Execute implementation plan with automated testing, adaptive replanning, and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list, update, revise, debug, document, expand, github-specialist
---

# Execute Implementation Plan

**YOU MUST orchestrate or execute implementation following this exact process:**

**YOUR ROLE - ADAPTIVE BASED ON PHASE COMPLEXITY**:

You are the implementation manager with THREE distinct roles that activate conditionally:

1. **Phase Coordinator** (ALWAYS ACTIVE):
   - **DO**: Manage workflow state, checkpoints, progress tracking
   - **DO**: Update plan files and hierarchy after each phase
   - **DO**: Run tests and create git commits
   - **DO NOT**: Skip testing, commits, or plan updates
   - **Tools**: checkpoint-utils.sh, checkbox-utils.sh, progress-dashboard.sh

2. **Direct Executor** (FOR SIMPLE PHASES - Complexity Score <3):
   - **WHEN**: Phase complexity score <3 (from Step 1.5 hybrid evaluation)
   - **DO**: Execute implementation yourself using Read/Edit/Write tools
   - **DO**: Apply coding standards from CLAUDE.md
   - **DO NOT**: Invoke agents for simple tasks
   - **Tools**: Read, Edit, Write, Bash

3. **Agent Orchestrator** (FOR COMPLEX PHASES - Complexity Score ≥3):
   - **WHEN**: Phase complexity score ≥3 (from Step 1.5 hybrid evaluation)
   - **DO**: Delegate implementation to specialized agents
   - **DO**: Invoke implementation-researcher for exploration (score ≥8)
   - **DO**: Invoke code-writer for implementation (score 3-10)
   - **DO**: Invoke debug-specialist for test failures
   - **DO**: Invoke doc-writer for documentation phases
   - **DO NOT**: Execute complex implementation yourself
   - **DO NOT**: Use Read/Grep/Write for tasks requiring agent expertise
   - **Tools**: Task tool with behavioral injection

**CRITICAL ROLE SWITCHING**:
- Role switches automatically based on $COMPLEXITY_SCORE from Step 1.5
- YOU WILL NOT see implementation details when orchestrating (agents work independently)
- YOUR JOB when orchestrating: Invoke agents → Verify outputs → Update plan
- YOUR JOB when executing: Read files → Make changes → Test changes

**EXECUTION FLOW**:
1. STEP 1: Evaluate phase complexity (hybrid_complexity_evaluation)
2. STEP 2: Switch to appropriate role based on complexity score
3. STEP 3: Execute or orchestrate implementation
4. STEP 4: Run tests and verify success
5. STEP 5: Update plan hierarchy and create git commit

**CRITICAL INSTRUCTIONS**:
- Execute phases in EXACT sequential order
- DO NOT skip testing after each phase
- DO NOT skip git commits
- DO NOT proceed if tests fail (unless debugging mode)
- MANDATORY: Update plan file after each phase

## Adaptive Role Clarification

**BEFORE EACH PHASE, YOU MUST:**

1. **Read complexity score** from Step 1.5 hybrid evaluation ($COMPLEXITY_SCORE)
2. **Identify active role** based on score and phase type
3. **Switch execution mode** to match role

**Role Decision Tree**:

```
┌─────────────────────────────────────────────────────────┐
│ Phase Complexity Evaluation (Step 1.5)                  │
│ → $COMPLEXITY_SCORE exported                            │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ $COMPLEXITY_SCORE ?  │
              └──────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
     Score 0-2      Score 3-7      Score 8-10
  ┌─────────────┐ ┌────────────┐ ┌─────────────┐
  │   Direct    │ │ Orchestrate│ │ Orchestrate │
  │  Execution  │ │ code-writer│ │ code-writer │
  │             │ │            │ │ + researcher│
  └─────────────┘ └────────────┘ └─────────────┘
       │              │              │
       └──────────────┼──────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
  Special Overrides        Tests Fail?
  ┌──────────────┐         ┌──────────┐
  │ Doc phase?   │─Yes─→   │ Invoke   │
  │ → doc-writer │         │  debug   │
  └──────────────┘         └──────────┘
```

**Special Case Overrides** (TAKE PRECEDENCE over complexity score):
- Documentation phase → Use doc-writer agent (any complexity)
- Testing phase → Use test-specialist agent (any complexity)
- Debug phase → Use debug-specialist agent (any complexity)
- Test failure → Auto-invoke debug-specialist (Step 3.3)
- After phase complete → Invoke spec-updater (Plan Hierarchy Update)

**Example Phase Execution**:

**Simple Phase** (complexity 2):
```
Phase 4: Add utility function
→ Complexity: 2/10 (threshold calculation)
→ Role: Direct Executor
→ Action: Read utils.sh → Add function → Test → Commit
→ Tools: Read, Edit, Write, Bash
```

**Complex Phase** (complexity 8):
```
Phase 3: Database integration
→ Complexity: 8/10 (hybrid: threshold=7, agent=9, reconciled=8)
→ Role: Agent Orchestrator
→ Action: Invoke implementation-researcher → Invoke code-writer → Verify outputs
→ Tools: Task (with behavioral injection)
```

**Documentation Phase** (complexity 5, but special override):
```
Phase 6: Update documentation
→ Complexity: 5/10
→ Role: Agent Orchestrator (override)
→ Action: Invoke doc-writer agent
→ Reason: Documentation phases always use doc-writer (special case override)
```

**PHASE 0 ROLE CLARIFICATION - Documentation Phases**

**YOUR ROLE (when phase type = documentation)**:

You are the DOCUMENTATION ORCHESTRATOR, not the documentation writer.

**CRITICAL INSTRUCTIONS FOR DOCUMENTATION PHASES**:

1. **DO NOT write documentation yourself** regardless of complexity score
   - DO NOT use Write tool to create .md files
   - DO NOT update README files directly
   - DO NOT generate documentation content yourself

2. **ONLY use Task tool** to delegate to doc-writer agent
   - Agent will create/update documentation files
   - Agent will follow Documentation Policy from CLAUDE.md
   - You will verify documentation created

3. **YOUR JOB**:
   - Detect documentation phase (phase name contains "document", "docs", "README")
   - Invoke doc-writer agent via Task tool with phase context
   - Verify documentation files created (fallback if needed)
   - Update plan hierarchy after completion

**SPECIAL CASE OVERRIDE**:
- Documentation phases ALWAYS use doc-writer agent
- Complexity score IGNORED for this phase type
- Even simple documentation (complexity 2) uses agent
- Reason: Consistency in documentation format and standards compliance

**WHEN THIS APPLIES**:
- Phase name/description contains: "document", "docs", "README", "documentation"
- Phase tasks include creating/updating .md files
- Regardless of complexity score

**Agent Invocation Template** (use THIS EXACT TEMPLATE):
```
Task {
  subagent_type: "general-purpose"
  description: "Create/update documentation for Phase ${PHASE_NUM}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent.

    Create/update documentation for Phase ${PHASE_NUM}: ${PHASE_NAME}

    Plan: ${PLAN_PATH}
    Phase Tasks: ${TASK_LIST}
    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Follow Documentation Policy from standards.
    Return: List of files created/updated
}
```

## Plan Information

**INPUTS REQUIRED**:
- **Plan file**: $1 (absolute path, or auto-detected most recent incomplete plan)
- **Starting phase**: $2 (default: auto-resume from last incomplete phase or 1)

**MANDATORY INPUT VALIDATION**:
Before proceeding, verify plan file exists and is readable.

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

**YOU MUST execute these steps in EXACT sequential order:**

---

### STEP 1 (REQUIRED BEFORE STEP 2) - Utility Initialization

**EXECUTE NOW - Initialize Required Utilities**

**ABSOLUTE REQUIREMENT**: YOU MUST initialize all required utilities before beginning implementation. This is NOT optional.

**WHY THIS MATTERS**: Utilities provide error handling, state management, and logging that are critical for reliable implementation. Skipping initialization will cause failures.

**Utilities REQUIRED**:
1. error-handling.sh (error classification and recovery)
2. checkpoint-utils.sh (workflow state persistence)
3. complexity-utils.sh (phase complexity scoring)
4. adaptive-planning-logger.sh (trigger evaluation logging)
5. agent-registry-utils.sh (agent invocation management)

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

**YOU MUST follow the wave execution flow for each phase. This is NOT optional.**

Execute phases either sequentially (traditional) or in parallel waves (with dependencies).

**Execution Modes**:
- **Sequential**: Execute phases in order (Phase 1, 2, 3, ...) when no dependencies declared
- **Parallel**: Parse dependencies into waves, execute waves sequentially, parallelize phases within waves (>1 phase per wave)

**CRITICAL INSTRUCTIONS**:
- Wave execution flow is MANDATORY
- DO NOT skip complexity analysis
- DO NOT skip agent selection based on complexity
- Agent delegation is REQUIRED for complex phases (score ≥3)

**Wave Execution Flow**:
1. **Wave Initialization**: Identify phases in current wave, log wave execution start
2. **Phase Preparation**: Display phase number, name, tasks for each phase in wave
3. **Complexity Analysis**: Run analyzer, calculate hybrid complexity score (see Step 1.5)
4. **Agent Selection** (using $COMPLEXITY_SCORE from Step 1.5):

**MANDATORY AGENT DELEGATION** (based on complexity score):

- **Score 0-2**: Direct execution (use Read, Edit, Write tools directly)
- **Score 3-5**: **code-writer agent** (standard delegation)
- **Score 6-7**: **code-writer agent** + extended thinking time
- **Score 8-9**: **code-writer agent** + deep analysis mode
- **Score 10+**: **code-writer agent** + maximum reasoning depth

**Special Case Overrides** (TAKE PRECEDENCE over score):
- **Documentation phases**: Use **doc-writer agent** (regardless of score)
- **Testing phases**: Use **test-specialist agent** (regardless of score)
- **Debug phases**: Use **debug-specialist agent** (regardless of score)

**Agent Invocation Template** (code-writer):

YOU MUST use THIS EXACT TEMPLATE for code-writer delegation:

```
Task {
  subagent_type: "general-purpose"
  description: "Implement Phase ${PHASE_NUM} - ${PHASE_NAME}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer Agent.

    Implement Phase ${PHASE_NUM}: ${PHASE_NAME}

    Plan: ${PLAN_PATH}
    Phase Tasks:
    ${TASK_LIST}

    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
    Complexity: ${COMPLEXITY_SCORE}

    Follow plan tasks exactly, apply coding standards, run tests after implementation.

    Return: Summary of changes made + test results
}
```

**Template Variables** (ONLY allowed modifications):
- `${PHASE_NUM}`: Phase number
- `${PHASE_NAME}`: Phase description
- `${PLAN_PATH}`: Absolute plan path
- `${TASK_LIST}`: Phase task list
- `${COMPLEXITY_SCORE}`: Complexity score from Step 1.5

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Standards reference
- Return format requirement

5. **Delegation**: Invoke agent via Task tool with behavioral injection, monitor PROGRESS markers
6. **Testing and Commit**: Execute for all phases in wave (see subsequent sections)

**Pattern Details**: See [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection) for delegation patterns.
### Plan Hierarchy Update After Phase Completion

**YOU MUST update plan hierarchy after each phase completion. This is NOT optional.**

After successfully completing a phase (tests passing and git commit created), update the plan hierarchy to ensure all parent/grandparent plan files reflect completion status.

**When to Update**:
- After git commit succeeds for the phase
- Before saving the checkpoint
- For all hierarchy levels (Level 0, Level 1, Level 2)

**CRITICAL INSTRUCTIONS**:
- Plan hierarchy updates are MANDATORY
- DO NOT skip verification steps
- DO NOT proceed to next phase if hierarchy update fails
- Fallback mechanism ensures 100% update success

---

**STEP A (REQUIRED BEFORE STEP B) - Invoke Spec-Updater Agent**

**EXECUTE NOW - Update Plan Hierarchy via Spec-Updater Agent**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke the spec-updater agent to update plan checkboxes. This is NOT optional.

**WHY THIS MATTERS**: Parent plan files must reflect phase completion for accurate progress tracking. Skipping this step creates inconsistency across plan hierarchy.

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

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

**Template Variables** (ONLY allowed modifications):
- `${PHASE_NUM}`: Replace with current phase number
- `${PLAN_PATH}`: Replace with absolute plan file path

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Step sequence or numbering
- Expected output format

---

**STEP B (REQUIRED AFTER STEP A) - Mandatory Verification with Fallback**

**MANDATORY VERIFICATION - Confirm Hierarchy Updated**

**ABSOLUTE REQUIREMENT**: YOU MUST verify hierarchy update succeeded. This is NOT optional.

**Verification Steps**:

1. **Check agent response for successful completion**:
   - Look for confirmation message
   - Verify all hierarchy levels updated
   - Confirm no consistency errors

2. **If agent succeeds**: Extract updated file list and log success

3. **If agent fails**: EXECUTE FALLBACK MECHANISM

**Fallback Mechanism** (Guarantees 100% Success):

```bash
# Direct utility invocation if agent fails
source .claude/lib/checkbox-utils.sh
mark_phase_complete "$PLAN_PATH" "$PHASE_NUM"
verify_checkbox_consistency "$PLAN_PATH" "$PHASE_NUM"
echo "✓ Fallback hierarchy update complete"
```

**Handle Update Failures**:
- If hierarchy update fails (both agent AND fallback): Log error and escalate to user
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

### STEP 1.4 (REQUIRED BEFORE STEP 1.5) - Check Expansion Status

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

**YOU MUST evaluate phase complexity before implementation. This is NOT optional.**

Evaluate phase complexity using hybrid approach: threshold-based scoring with agent evaluation for borderline cases (score ≥7 or ≥8 tasks).

**When to Use**:
- **Every phase**: Always evaluate complexity before implementation
- **Borderline cases**: Automatic agent invocation for context-aware analysis
- **Agent triggers**: Threshold score ≥7 OR task count ≥8

**CRITICAL INSTRUCTIONS**:
- Complexity evaluation is MANDATORY for every phase
- DO NOT skip threshold calculation
- DO NOT skip agent invocation when thresholds met
- Agent evaluation provides context-aware accuracy

**Workflow Overview**:
1. Calculate threshold-based score (complexity-utils.sh)
2. Determine if agent evaluation needed (borderline thresholds)
3. Run hybrid_complexity_evaluation function (may invoke agent)
4. Parse result (final_score, evaluation_method, agent_reasoning)
5. Log evaluation for analytics (adaptive-planning-logger.sh)
6. Export COMPLEXITY_SCORE for downstream decisions (expansion, agent selection)

---

**Key Execution Requirements**:

1. **Threshold calculation** (uses complexity-utils.sh):
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"
   THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
   TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")
   ```

2. **Hybrid evaluation with agent fallback**:

**AGENT INVOCATION NOTE**: The `hybrid_complexity_evaluation` function automatically invokes the **complexity-estimator agent** when borderline thresholds are met. This agent invocation is handled by the utility function and is NOT optional.

   ```bash
   # Determine if agent needed (score ≥7 OR tasks ≥8)
   AGENT_NEEDED="false"
   [ "$THRESHOLD_SCORE" -ge 7 ] || [ "$TASK_COUNT" -ge 8 ] && AGENT_NEEDED="true"

   # Run hybrid evaluation
   # IMPORTANT: This function invokes complexity-estimator agent when AGENT_NEEDED="true"
   # Agent provides context-aware evaluation for borderline phases
   EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
   COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
   EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')  # "threshold", "agent", or "reconciled"
   ```

**Complexity-Estimator Agent Behavior** (invoked automatically by utility):
- Agent reads phase context from plan file
- Evaluates task complexity, scope breadth, integration challenges
- Returns numerical score with reasoning
- Utility reconciles agent score with threshold score
- Fallback to threshold score if agent fails

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

### STEP 1.55 (REQUIRED BEFORE STEP 1.6) - Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Note**: This step uses the hybrid complexity score ($COMPLEXITY_SCORE) from Step 1.5.

**Evaluation criteria**: Task complexity, scope breadth, interrelationships, parallel work potential, clarity vs detail tradeoff

**If expansion recommended**: Display formatted recommendation with rationale and `/expand phase` command

**If not needed**: Continue silently to implementation

**Relationship to reactive expansion** (Step 3.4):
- **Proactive** (1.55): Before implementation, recommendation only
- **Reactive** (3.4): After implementation, auto-revision via `/revise --auto-mode`

---

**PHASE 0 ROLE CLARIFICATION - Implementation Research**

**YOUR ROLE (for complex phases requiring research)**:

You are the RESEARCH ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS FOR STEP 1.57**:

1. **DO NOT execute research yourself** when complexity ≥8 OR tasks >10
   - DO NOT use Read/Grep tools to explore codebase
   - DO NOT analyze existing implementations directly
   - DO NOT identify patterns yourself

2. **ONLY use Task tool** to delegate to implementation-researcher agent
   - Agent will explore codebase and identify patterns
   - Agent will create artifact with findings
   - You will receive metadata only (path + summary)

3. **YOUR JOB**:
   - Calculate complexity threshold (Step 1.5 result)
   - Check if RESEARCH_NEEDED = true
   - Invoke implementation-researcher via Task tool
   - Extract artifact metadata via forward_message pattern
   - Store metadata for on-demand loading during implementation

**YOU WILL NOT see full research findings**:
- Agent returns metadata only (artifact path + 50-word summary)
- Full artifact loaded on-demand during implementation (if needed)
- Context reduction: 95% (2000 tokens → 100 tokens)

**WHEN THIS SECTION APPLIES**:
- Complexity score ≥8 (from Step 1.5)
- OR task count >10
- Purpose: Gather codebase context before implementation

**WHEN TO SKIP THIS SECTION**:
- Complexity score <8 AND task count ≤10
- Simple phases don't need research
- Continue to Step 1.6 (agent selection for implementation)

---

### STEP 1.57 (REQUIRED BEFORE STEP 1.6) - Implementation Research Agent Invocation

**YOU MUST invoke implementation-researcher for complex phases. This is NOT optional.**

Invoke implementation-researcher agent for complex phases to gather codebase context before implementation.

**When to Invoke**:
- **Complexity trigger**: $COMPLEXITY_SCORE ≥ 8 (from Step 1.5)
- **Task trigger**: $TASK_COUNT > 10 (from Step 1.5)
- **Purpose**: Search existing implementations, identify patterns, detect integration challenges

**CRITICAL INSTRUCTIONS**:
- Research invocation is MANDATORY for complex phases
- DO NOT skip threshold checks
- DO NOT skip metadata extraction
- Fallback mechanism ensures research completion

**Workflow Overview**:
1. Check complexity/task thresholds
2. Invoke implementation-researcher agent via Task tool
3. Use forward_message pattern to extract artifact metadata
4. Store metadata in context (minimal footprint)
5. Load full artifact on-demand during implementation

---

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

**STEP C (REQUIRED BEFORE STEP D) - Invoke Implementation-Researcher Agent**

**EXECUTE NOW - Invoke Research Agent for Complex Phase**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke implementation-researcher agent when complexity thresholds met. This is NOT optional.

**WHY THIS MATTERS**: Complex phases benefit from codebase exploration before implementation. Research identifies reusable patterns and integration challenges, reducing rework.

2. **Invoke implementation-researcher agent**:

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

```bash
# Source context preservation utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"

# Track context before research
CONTEXT_BEFORE=$(track_context_usage "before" "phase_${CURRENT_PHASE}_research" "")

# Build task list for agent
FILE_LIST=$(echo "$PHASE_CONTENT" | grep -oE '[a-zA-Z0-9_/.-]+\.(js|py|lua|sh|md|yaml)' | sort -u | head -20 | tr '\n' ', ')

# Invoke agent with THIS EXACT PROMPT
Task {
  subagent_type: "general-purpose"
  description: "Research phase ${CURRENT_PHASE} implementation context"
  prompt: |
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
}
```

**Template Variables** (ONLY allowed modifications):
- `${CLAUDE_PROJECT_DIR}`: Project directory path
- `${CURRENT_PHASE}`: Current phase number
- `${PHASE_NAME}`: Phase description
- `${FILE_LIST}`: Files to modify
- `${TASK_COUNT}`: Task count
- `${TOPIC_DIR}`: Topic directory name

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Research context structure
- Return format requirement (metadata only)

---

**STEP D (REQUIRED AFTER STEP C) - Mandatory Verification with Fallback**

**MANDATORY VERIFICATION - Confirm Research Artifact Created**

**ABSOLUTE REQUIREMENT**: YOU MUST verify research artifact was created. This is NOT optional.

3. **Extract metadata using forward_message**:

**Verification Steps**:

```bash
# Parse subagent response for artifact paths and metadata
RESEARCH_RESULT=$(forward_message "$SUBAGENT_OUTPUT" "phase_${CURRENT_PHASE}_research")

# Extract artifact path and metadata
ARTIFACT_PATH=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].path')
ARTIFACT_METADATA=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].metadata')
RESEARCH_SUMMARY=$(echo "$ARTIFACT_METADATA" | jq -r '.summary')

# MANDATORY: Verify artifact file exists
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "⚠️  ARTIFACT NOT FOUND - Triggering fallback mechanism"

  # Fallback: Create minimal research artifact from agent output
  FALLBACK_PATH="specs/${TOPIC_DIR}/artifacts/phase_${CURRENT_PHASE}_exploration.md"
  mkdir -p "$(dirname "$FALLBACK_PATH")"

  cat > "$FALLBACK_PATH" <<EOF
# Phase ${CURRENT_PHASE} Implementation Research

## Agent Output
$SUBAGENT_OUTPUT

## Metadata
- Generated: Fallback mechanism
- Reason: Primary artifact creation failed
- Phase: ${CURRENT_PHASE}
- Complexity: ${COMPLEXITY_SCORE}
EOF

  ARTIFACT_PATH="$FALLBACK_PATH"
  RESEARCH_SUMMARY="Fallback research artifact created"
  echo "✓ Fallback artifact created: $ARTIFACT_PATH"
fi

# Track context after research (metadata only, not full artifact)
CONTEXT_AFTER=$(track_context_usage "after" "phase_${CURRENT_PHASE}_research" "$RESEARCH_SUMMARY")

# Calculate and log reduction
CONTEXT_REDUCTION=$(calculate_context_reduction "$CONTEXT_BEFORE" "$CONTEXT_AFTER")
echo "PROGRESS: Research complete - context reduction: ${CONTEXT_REDUCTION}%"
```

**Fallback Mechanism** (Guarantees 100% Success):
- If agent fails to create artifact → Create from agent output
- Minimal structure with agent findings preserved
- Non-blocking (implementation continues)

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
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"
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
- **Utilities**: `artifact-creation.sh` and `artifact-registry.sh` (forward_message, cache_metadata), `context-metrics.sh` (tracking)
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

**STEP 2 (REQUIRED BEFORE STEP 3) - Implementation**

**EXECUTE NOW - Implement Phase Tasks**:

Create or modify the necessary files according to the plan specifications.

**If Agent Delegated**: Use agent's output
**If Direct Execution**: Implement manually following standards

---

**STEP 3 (REQUIRED BEFORE STEP 4) - Testing**

**EXECUTE NOW - Run Phase Tests**:

Run tests by:
- Looking for test commands in the phase tasks
- Checking for common test patterns (npm test, pytest, make test)
- Running language-specific test commands based on project type

---

**PHASE 0 ROLE CLARIFICATION - Debug Integration**

**YOUR ROLE (when test failures occur)**:

You are the DEBUG ORCHESTRATOR, not the debugger.

**CRITICAL INSTRUCTIONS FOR STEP 3.3**:

1. **DO NOT debug failures yourself** when Level 4 triggered
   - DO NOT analyze error messages directly
   - DO NOT investigate root causes manually
   - DO NOT propose fixes yourself

2. **ONLY use SlashCommand tool** to invoke /debug command
   - /debug will coordinate debug-analyst agents
   - /debug will create structured debug report
   - You will receive report path for user choices

3. **YOUR JOB**:
   - Classify error type (error-handling.sh)
   - Execute tiered recovery (Levels 1-3)
   - Invoke /debug for Level 4 (complex failures)
   - Present user choices: (r)evise, (c)ontinue, (s)kip, (a)bort
   - Execute chosen action

**TIERED RECOVERY LEVELS**:
- **Level 1**: Error classification + suggestions (no retry)
- **Level 2**: Transient retry (timeout, busy, locked errors)
- **Level 3**: Tool fallback (reduced toolset retry)
- **Level 4**: Auto-invoke /debug (orchestration mode) ← THIS IS WHERE YOU ORCHESTRATE

**YOU WILL NOT see debug analysis directly**:
- /debug command creates report artifact
- You receive report path only
- User chooses action based on report
- If (r)evise chosen: Invoke /revise --auto-mode with debug findings

**WHEN THIS SECTION APPLIES**:
- Test failures in any phase
- Automatic trigger (no manual invocation needed)
- Applies after Levels 1-3 if still failing

**FALLBACK MECHANISM**:
- If /debug fails: Use analyze-error.sh utility (guaranteed report creation)
- Non-blocking: User choices presented regardless

---

### 3.3. Automatic Debug Integration (if tests fail)

**YOU MUST invoke debug-analyst for test failures. This is NOT optional.**

**When to Use Automatic Debug Integration**:
- **Test failures** in any phase during implementation
- **Automatic triggers**: No manual invocation needed
- **Tiered recovery**: 4 escalating levels of error handling

**CRITICAL INSTRUCTIONS**:
- Debug invocation is MANDATORY for test failures
- DO NOT skip error classification
- DO NOT skip /debug agent invocation (Level 4)
- User choice execution is MANDATORY

**Quick Overview**:
1. Classify error type and display suggestions (error-handling.sh)
2. Retry transient errors (timeout, busy, locked) with extended timeout
3. Retry tool access errors with reduced toolset fallback
4. Auto-invoke /debug agent for root cause analysis
5. Present user choices: (r)evise, (c)ontinue, (s)kip, (a)bort
6. Execute chosen action and update plan with debugging notes

**Pattern Details**: See [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns) for complete tiered recovery workflow.

---

**Key Execution Requirements**:

1. **Error classification** (uses error-handling.sh):
   ```bash
   source "$CLAUDE_PROJECT_DIR/.claude/lib/error-handling.sh"
   ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")  # → syntax, test_failure, timeout, etc.
   SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT" "$ERROR_LOCATION")
   ```

**STEP E (REQUIRED FOR TEST FAILURES) - Automatic /debug Invocation**

**EXECUTE NOW - Invoke /debug for Root Cause Analysis**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke /debug command when Level 4 triggered. This is NOT optional.

**WHY THIS MATTERS**: Automated root cause analysis identifies underlying issues systematically, reducing debugging time by 50%.

2. **Automatic /debug invocation** (Level 4):

**Debug Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

```bash
# Invoke /debug command with exact parameters
SlashCommand {
  command: "/debug \"Phase $CURRENT_PHASE failure: $ERROR_TYPE\" \"$PLAN_PATH\""
}

# Extract debug report path from response
DEBUG_REPORT_PATH=$(extract_report_path "$DEBUG_RESULT")

# MANDATORY: Verify debug report created
if [ -z "$DEBUG_REPORT_PATH" ] || [ ! -f "$DEBUG_REPORT_PATH" ]; then
  echo "⚠️  DEBUG REPORT NOT FOUND - Triggering fallback mechanism"

  # Fallback: Use analyze-error.sh utility
  source .claude/lib/analyze-error.sh
  DEBUG_ANALYSIS=$(analyze_error "$ERROR_TYPE" "$TEST_OUTPUT" "$CURRENT_PHASE")

  # Create fallback debug report
  FALLBACK_REPORT="specs/${TOPIC_DIR}/debug/phase_${CURRENT_PHASE}_failure.md"
  mkdir -p "$(dirname "$FALLBACK_REPORT")"

  cat > "$FALLBACK_REPORT" <<EOF
# Phase ${CURRENT_PHASE} Debug Report (Fallback)

## Error Analysis
$DEBUG_ANALYSIS

## Context
- Phase: ${CURRENT_PHASE}
- Error Type: ${ERROR_TYPE}
- Test Output: ${TEST_OUTPUT}
EOF

  DEBUG_REPORT_PATH="$FALLBACK_REPORT"
  echo "✓ Fallback debug report created: $DEBUG_REPORT_PATH"
fi
```

**Fallback Mechanism** (Guarantees 100% Debug Report):
- If /debug fails → Use analyze-error.sh utility
- Create minimal debug report with error analysis
- Non-blocking (user choices still presented)

---

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

### STEP 3.4 (CONDITIONAL - IF TRIGGERS DETECTED) - Adaptive Planning Detection

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

### STEP 3.5 (CONDITIONAL - IF PREVIOUSLY DEBUGGED) - Update Debug Resolution
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

**STEP 4 (REQUIRED BEFORE STEP 5) - Git Commit**

**YOU MUST create git commit after each phase. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Git commits are MANDATORY after successful phase completion
- DO NOT skip commit creation
- DO NOT proceed to next phase without commit
- Structured commit message format is REQUIRED

**EXECUTE NOW - Create Structured Git Commit**

**ABSOLUTE REQUIREMENT**: YOU MUST create a git commit using the exact format below. This is NOT optional.

**WHY THIS MATTERS**: Git commits preserve implementation progress incrementally. Each commit represents a checkpoint for rollback and debugging.

**Commit Message Template**:

Create a structured commit using THIS EXACT FORMAT:

```bash
git add <modified-files>

git commit -m "$(cat <<'EOF'
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Template Variables** (ONLY allowed modifications):
- `<modified-files>`: Files changed in this phase
- `Phase N`: Replace with actual phase number
- `Phase Name`: Replace with actual phase name

**DO NOT modify**:
- Commit type prefix (`feat:`)
- Commit structure (title, blank line, body)
- Co-Authored-By footer

---

**CHECKPOINT REQUIREMENT - Report Phase Completion**

**ABSOLUTE REQUIREMENT**: After git commit succeeds, YOU MUST report this checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Checkpoint reporting provides progress visibility and enables workflow monitoring.

**RETURN_FORMAT_SPECIFIED**: YOU MUST return ONLY this exact format (no modifications):

**Report Format**:

```
CHECKPOINT: Phase ${PHASE_NUM} Complete
- Phase: ${PHASE_NAME}
- Tests: ✓ PASSED
- Commit: ${COMMIT_HASH}
- Files Modified: ${FILE_COUNT}
- Next Phase: ${NEXT_PHASE}
```

**Required Information**:
- Phase number and name
- Test status (PASSED)
- Git commit hash (from git log -1)
- Count of modified files
- Next phase number (or "Summary Generation" if last phase)

**STEP 5 (REQUIRED) - Plan Update (After Git Commit Succeeds)**

**EXECUTE NOW - Update Plan Files**:

Update plan files incrementally after each successful phase completion.

**Update Steps**:
1. **Mark tasks complete**: Use Edit tool to change `- [ ]` → `- [x]` in appropriate file based on expansion status
2. **Add completion marker**: Change `### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`
3. **Verify updates**: Read updated file and verify all phase tasks show `[x]`
4. **Update progress section**: Add/update "## Implementation Progress" with last phase, date, commit, status, resume command

**Level-Aware Updates**: Use progressive utilities (is_phase_expanded, is_stage_expanded) to determine correct file location (Level 0: main plan only, Level 1: phase file or main plan, Level 2: stage file, phase file, or main plan)

**Progress Section Content**: Last completed phase, completion date, git commit hash, status "In Progress (M/N phases complete)", resume instructions `/implement <plan-file> <next-phase-number>`

### STEP 5.5 (CONDITIONAL - IF PHASE EXPANDED) - Automatic Collapse Detection

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

**YOU MUST finalize summary after all phases complete. This is NOT optional.**

After completing all phases:

**CRITICAL INSTRUCTIONS**:
- Summary finalization is MANDATORY
- DO NOT skip registry updates
- DO NOT skip cross-reference links
- Final checkpoint reporting is REQUIRED

### 1-3. Finalize Summary File

**EXECUTE NOW - Finalize Implementation Summary**

**ABSOLUTE REQUIREMENT**: YOU MUST finalize the implementation summary. This is NOT optional.

**WHY THIS MATTERS**: Summary provides complete implementation record for future reference and tracks artifacts used during implementation.

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

---

**CHECKPOINT REQUIREMENT - Report Implementation Complete**

**ABSOLUTE REQUIREMENT**: After summary finalization, YOU MUST report this final checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Final checkpoint confirms all phases complete, provides implementation metrics, and marks workflow conclusion.

**RETURN_FORMAT_SPECIFIED**: YOU MUST return ONLY this exact format (no modifications):

**Report Format**:

```
CHECKPOINT: Implementation Complete
- Plan: ${PLAN_NAME}
- Phases: ${TOTAL_PHASES}/${TOTAL_PHASES} (100%)
- Summary: ${SUMMARY_PATH}
- Duration: ${IMPLEMENTATION_TIME}
- Commits: ${COMMIT_COUNT}
- Tests: ✓ ALL PASSED
- Status: COMPLETE
```

**Required Information**:
- Plan name (from plan metadata)
- Total phases completed
- Summary file path
- Implementation duration (first commit to last commit)
- Total commit count
- Final test status
- Completion status

### 4-5. Registry and Cross-References

**Update SPECS.md Registry**:
- Increment "Summaries" count
- Update "Last Updated" date

**Bidirectional links**:
- Add "## Implementation Summary" section to plan file
- Add "## Implementation Status" section to each research report
- Verify all links created (non-blocking if fails)

### 6. Create Pull Request (Optional)

**IF --create-pr flag present, YOU MUST invoke github-specialist. This is NOT optional.**

For PR creation workflow, see [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection).

**Implement-specific PR workflow**:
- Trigger: `--create-pr` flag or CLAUDE.md auto-PR config
- Prerequisites: Check gh CLI installed and authenticated
- Agent: Invoke github-specialist with behavioral injection
- Content: Implementation overview, phases, test results, reports, file changes
- Update: Add PR link to summary and plan files
- Graceful degradation: Provide manual gh command if fails

**CRITICAL INSTRUCTIONS** (when --create-pr flag present):
- Github-specialist invocation is MANDATORY
- DO NOT skip gh CLI verification
- DO NOT skip PR link updates
- Fallback mechanism ensures PR creation or manual instructions

---

**STEP F (REQUIRED IF --create-pr FLAG) - Invoke Github-Specialist Agent**

**EXECUTE NOW - Create Pull Request via Github-Specialist**

**ABSOLUTE REQUIREMENT**: IF --create-pr flag present, YOU MUST invoke github-specialist agent. This is NOT optional.

**WHY THIS MATTERS**: Automated PR creation streamlines the review workflow and provides structured implementation summary in PR description.

**Prerequisite Check**:

```bash
# Verify gh CLI available
if ! command -v gh &> /dev/null; then
  echo "⚠️  gh CLI not found - Providing manual instructions"
  echo "Install: https://cli.github.com/"
  echo "Manual PR creation: gh pr create --title '...' --body '...'"
  exit 0
fi

# Verify gh authentication
if ! gh auth status &> /dev/null; then
  echo "⚠️  gh CLI not authenticated - Providing manual instructions"
  echo "Authenticate: gh auth login"
  exit 0
fi
```

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

```
Task {
  subagent_type: "general-purpose"
  description: "Create pull request for implementation"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/github-specialist.md

    You are acting as a Github Specialist Agent.

    Create pull request for completed implementation.

    Plan: ${PLAN_PATH}
    Summary: ${SUMMARY_PATH}
    Branch: ${CURRENT_BRANCH}
    Base: ${BASE_BRANCH}

    Steps:
    1. Generate PR title from plan name
    2. Create PR body with implementation overview, phases, test results, file changes
    3. Execute: gh pr create --title "..." --body "..."
    4. Extract PR URL from output
    5. Return PR URL

    Expected output:
    - PR URL (https://github.com/...)
    - PR number
}
```

**Template Variables** (ONLY allowed modifications):
- `${PLAN_PATH}`: Absolute plan file path
- `${SUMMARY_PATH}`: Implementation summary path
- `${CURRENT_BRANCH}`: Current git branch
- `${BASE_BRANCH}`: Target branch for PR (usually main/master)

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Step sequence
- Expected output format

---

**STEP G (REQUIRED AFTER STEP F) - Mandatory PR Verification with Fallback**

**MANDATORY VERIFICATION - Confirm PR Created**

**ABSOLUTE REQUIREMENT**: YOU MUST verify PR was created. This is NOT optional.

**Verification Steps**:

```bash
# Extract PR URL from agent response
PR_URL=$(echo "$AGENT_OUTPUT" | grep -oE 'https://github.com/[^[:space:]]+/pull/[0-9]+')
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')

# MANDATORY: Verify PR exists
if [ -z "$PR_URL" ]; then
  echo "⚠️  PR URL NOT FOUND - Triggering fallback mechanism"

  # Fallback: Provide manual gh command
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Manual PR Creation Required"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Run this command:"
  echo ""
  echo "gh pr create \\"
  echo "  --title \"${PR_TITLE}\" \\"
  echo "  --body \"${PR_BODY}\""
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Non-blocking: Continue without PR URL
  PR_URL="(manual creation required)"
  PR_NUMBER="N/A"
fi

# Update summary and plan with PR link
if [ "$PR_URL" != "(manual creation required)" ]; then
  echo "## Pull Request" >> "$SUMMARY_PATH"
  echo "" >> "$SUMMARY_PATH"
  echo "- **PR**: [$PR_NUMBER]($PR_URL)" >> "$SUMMARY_PATH"

  echo "" >> "$PLAN_PATH"
  echo "## Pull Request" >> "$PLAN_PATH"
  echo "" >> "$PLAN_PATH"
  echo "- **PR**: [$PR_NUMBER]($PR_URL)" >> "$PLAN_PATH"

  echo "✓ PR links added to summary and plan"
fi
```

**Fallback Mechanism** (Graceful Degradation):
- If agent fails → Provide manual gh command with pre-filled title/body
- If gh CLI unavailable → Provide installation instructions
- If gh not authenticated → Provide authentication instructions
- Non-blocking (summary finalization continues)

---

**CHECKPOINT REQUIREMENT - Report PR Creation**

**IF PR created successfully**, YOU MUST report this checkpoint:

**RETURN_FORMAT_SPECIFIED**: YOU MUST return ONLY this exact format (no modifications):

```
CHECKPOINT: Pull Request Created
- PR: #${PR_NUMBER}
- URL: ${PR_URL}
- Branch: ${CURRENT_BRANCH} → ${BASE_BRANCH}
- Summary: Updated with PR link
```

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

1. `/research` - Researches topic (no standards needed)
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

# Implementation Workflow

This document describes the complete workflow for implementing plans using the /implement command.

**Referenced by**: [implement.md](../implement.md)

**Contents**:
- Plan Discovery and Validation
- Progressive Structure Navigation
- Phase-by-Phase Execution
- Checkpoint Management
- Completion and Summary

---

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
   [ -f "$UTILS_DIR/unified-logger.sh" ] || { echo "ERROR: unified-logger.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/agent-registry-utils.sh" ] || { echo "ERROR: agent-registry-utils.sh not found"; exit 1; }
   ```

3. **Initialize logger** (`.claude/logs/adaptive-planning.log`, 10MB max, 5 files retained):
   ```bash
   source "$UTILS_DIR/unified-logger.sh"
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
for util in error-handling.sh checkpoint-utils.sh complexity-utils.sh unified-logger.sh agent-registry-utils.sh; do
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


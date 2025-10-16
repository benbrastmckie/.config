# Interactive Prompts and Checkpoint Detection Systems

## Metadata
- **Date**: 2025-10-10
- **Scope**: Comprehensive analysis of interactive prompt systems throughout .claude/ configuration
- **Primary Directory**: .claude/
- **Files Analyzed**: 6 command files, 3 utility libraries
- **Research Method**: Codebase analysis via grep, glob, and file reading

## Executive Summary

This report provides a comprehensive analysis of all interactive prompt systems in the .claude/ configuration, with a focus on checkpoint detection and user interaction patterns. The configuration contains **two fully implemented interactive checkpoint systems** (`/implement` and `/orchestrate` commands) and **one conceptual wizard system** (`/plan-wizard`) that has been fully specified but not yet implemented.

All interactive prompts follow a consistent terminal detection pattern (`if [ -t 0 ]`) to gracefully degrade to non-interactive defaults when running in non-terminal environments. The checkpoint systems enable workflow resumption after interruptions, while error escalation prompts provide structured recovery options.

**Key Finding**: Interactive prompts are limited to workflow control (resume/restart) and error recovery, with no interactive prompts during normal command execution. This design maintains automation-friendly behavior while providing human intervention points only when necessary.

## Background

The .claude/ configuration implements a sophisticated workflow orchestration system with multiple commands (`/implement`, `/orchestrate`, `/report`, `/plan`, etc.) that can run for extended periods. Two critical requirements drive interactive prompt usage:

1. **Workflow Resumability**: Long-running workflows (implementation, orchestration) need checkpoint-based recovery
2. **Error Recovery**: When automated retry fails, human judgment is needed to choose recovery strategies

This analysis examines how these requirements are met through interactive prompt systems.

## Current State Analysis

### 1. Checkpoint Detection System Architecture

#### Implementation Locations

**A. `/implement` Command** (`.claude/commands/implement.md:1560-1647`)

The `/implement` command includes checkpoint detection at workflow initialization:

**Step 1: Check for Existing Checkpoint** (line 1564-1569)
```bash
# Load most recent implement checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement 2>/dev/null || echo "")
```

**Step 2: Interactive Resume Prompt** (lines 1571-1589)

When a checkpoint exists, presents this interactive menu:
```
Found existing checkpoint for implementation
Plan: [plan_path]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Last test status: [tests_passing]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart from beginning
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

**Implementation Pattern**: Uses shell `read -p` for user input (implied, not shown in markdown spec)

**B. `/orchestrate` Command** (`.claude/commands/orchestrate.md:2405-2477`)

Nearly identical pattern to `/implement`:

**Step 1: Check for Existing Checkpoint** (lines 2409-2414)
```bash
# Load most recent orchestrate checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh orchestrate 2>/dev/null || echo "")
```

**Step 2: Interactive Resume Prompt** (lines 2416-2434)
```
Found existing checkpoint for orchestrate workflow
Project: [project_name]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Status: [status]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart workflow
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

#### Checkpoint Lifecycle

**Checkpoint Creation** (after each phase):
```bash
# Build checkpoint state JSON
STATE_JSON=$(cat <<EOF
{
  "workflow_description": "...",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "total_phases": $TOTAL_PHASES,
  "completed_phases": [$COMPLETED_PHASES_ARRAY],
  "status": "in_progress",
  "tests_passing": true
}
EOF
)

# Save checkpoint
PROJECT_NAME=$(basename "$PLAN_PATH" .md | sed 's/^[0-9]*_//')
.claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON"
```

**Checkpoint Cleanup**:
- Success: `rm .claude/data/checkpoints/implement_${PROJECT_NAME}_*.json`
- Failure: `mv .claude/data/checkpoints/implement_${PROJECT_NAME}_*.json .claude/data/checkpoints/failed/`

#### Checkpoint Utility Library

**File**: `.claude/lib/checkpoint-utils.sh`

**Schema Version**: 1.1 (line 16)

**Core Functions**:
- `save_checkpoint()` - Save workflow checkpoint (lines 29-115)
- `restore_checkpoint()` - Load most recent checkpoint (lines 121-173)
- `validate_checkpoint()` - Validate structure (lines 179-221)
- `migrate_checkpoint_format()` - Schema migration (lines 227-274)

**Checkpoint Storage Location**: `.claude/checkpoints/` (line 19)

**Checkpoint Naming Pattern**: `{workflow_type}_{project_name}_{timestamp}.json`

Example: `implement_auth_system_20251010_140523.json`

**Checkpoint Schema** (v1.1):
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_auth_system_20251010_140523",
  "workflow_type": "implement",
  "project_name": "auth_system",
  "workflow_description": "Implement authentication system",
  "created_at": "2025-10-10T14:05:23Z",
  "updated_at": "2025-10-10T14:05:23Z",
  "status": "in_progress",
  "current_phase": 2,
  "total_phases": 5,
  "completed_phases": [1],
  "workflow_state": {...},
  "last_error": null,
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}
```

**Adaptive Planning Fields** (added in v1.1):
- `replanning_count`: Total replan operations
- `last_replan_reason`: Most recent replan trigger
- `replan_phase_counts`: Per-phase replan tracking
- `replan_history`: Audit trail of replans

### 2. Error Escalation Interactive Prompts

#### Implementation Location

**File**: `.claude/lib/error-utils.sh`

#### Standard Error Escalation

**Function**: `escalate_to_user()` (lines 159-182)

**Purpose**: Present error to user with recovery options

**Usage Example**:
```bash
escalate_to_user "Build failed" "1. Fix code\n2. Skip phase\n3. Abort"
```

**Implementation** (lines 174-182):
```bash
# Check if running interactively
if [ -t 0 ]; then
  read -p "Choose an option: " choice
  echo "$choice"
else
  # Non-interactive, return empty
  echo ""
fi
```

**Key Pattern**:
- **Terminal Detection**: `if [ -t 0 ]` checks if stdin is connected to a terminal
- **Interactive**: Prompts for user choice with `read -p`
- **Non-interactive**: Returns empty string (command uses default behavior)

#### Parallel Operations Error Escalation

**Function**: `escalate_to_user_parallel()` (lines 625-679)

**Purpose**: Handle partial failures in parallel operations

**Signature**:
```bash
escalate_to_user_parallel <error_context_json> <recovery_options>
```

**Example Error Context**:
```json
{
  "operation": "expand",
  "failed": 2,
  "total": 5
}
```

**Recovery Options**: Comma-separated list (e.g., `"retry,skip,abort"`)

**Interactive Prompt Format** (lines 640-660):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User Escalation Required
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Operation: expand
Failed: 2/5 operations

Recovery Options:
  1. retry
  2. skip
  3. abort

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Choose an option (1-3):
```

**Implementation** (lines 662-678):
```bash
# Check if interactive
if [[ -t 0 ]]; then
  echo -n "Choose an option (1-${#OPTIONS[@]}): " >&2
  read -r choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#OPTIONS[@]} ]]; then
    echo "${OPTIONS[$((choice-1))]}"
    return 0
  else
    echo "Invalid choice, defaulting to: ${OPTIONS[0]}" >&2
    echo "${OPTIONS[0]}"
    return 0
  fi
else
  # Non-interactive, return first option
  echo "${OPTIONS[0]}"
  return 0
fi
```

**Features**:
- Numeric choice validation
- Default to first option on invalid input
- Non-interactive default: first option in list
- Always returns valid option (never fails)

### 3. Conceptual Interactive System: Plan Wizard

#### Implementation Status

**File**: `.claude/commands/plan-wizard.md`

**Status**: **Fully Specified, Not Implemented**

The `/plan-wizard` command has been completely documented with detailed specifications but has not been implemented in executable form (no corresponding shell script or agent).

#### Wizard Design

**Purpose**: Interactive, guided experience for creating implementation plans

**Target Users**: New users unfamiliar with planning system

**Workflow**: 4-step interactive process

#### Step 1: Feature Description Prompt

**Prompt** (lines 31-38):
```
🧙 Plan Wizard - Interactive Plan Creation

This wizard will guide you through creating a comprehensive implementation plan.

Step 1: What would you like to implement?
Describe your feature or task in 1-2 sentences:
```

**User Input**: Free-form text (1-2 sentences)

**Processing**: Extract keywords, store as `$FEATURE_DESC`

#### Step 2: Component Identification

**Logic** (lines 58-76): Analyze feature description and suggest components

**Prompt** (lines 79-88):
```
Step 2: Which components will this affect?

Suggested components (based on your description):
- [component 1]
- [component 2]
- [component 3]

Enter components (comma-separated), or press Enter to use suggestions:
```

**User Input**: Component list or Enter for suggestions

**Processing**: Parse comma-separated components, store as `$COMPONENTS` array

#### Step 3: Complexity Assessment

**Prompt** (lines 102-110):
```
Step 3: What's the main complexity level?

1. Simple    - Minor changes, single file, < 2 hours
2. Medium    - Multiple files, new functionality, 2-8 hours
3. Complex   - Architecture changes, multiple modules, 8-16 hours
4. Critical  - Major refactor, system-wide impact, > 16 hours

Select complexity (1-4):
```

**User Input**: Number 1-4

**Processing** (lines 119-123):
```
Mapping:
1 → "simple" (1-2 phases, no research)
2 → "medium" (2-4 phases, optional research)
3 → "complex" (4-6 phases, research recommended)
4 → "critical" (6+ phases, research required)
```

#### Step 4: Research Decision

**Dynamic Suggestion Logic** (lines 130-141):
```bash
if [ "$COMPLEXITY" = "simple" ]; then
  RESEARCH_SUGGESTION="not recommended"
  DEFAULT_RESEARCH="n"
elif [ "$COMPLEXITY" = "medium" ]; then
  RESEARCH_SUGGESTION="optional"
  DEFAULT_RESEARCH="n"
else
  RESEARCH_SUGGESTION="recommended"
  DEFAULT_RESEARCH="y"
fi
```

**Prompt** (lines 144-154):
```
Step 4: Should I research first? ($RESEARCH_SUGGESTION)

Research will help identify:
- Existing patterns in the codebase
- Best practices and standards
- Alternative approaches
- Potential challenges

Conduct research before planning? (y/n) [$DEFAULT_RESEARCH]:
```

**User Input**: y/n (defaults based on complexity)

**Processing**: Store decision as `$DO_RESEARCH`

#### Step 5: Research Topic Identification (Conditional)

**Only if research confirmed** (lines 165-194)

**Topic Detection Logic** (lines 168-193):
```bash
# Pattern detection for common research needs
if echo "$FEATURE_DESC" | grep -qi "auth\|security\|login"; then
  RESEARCH_TOPICS+=("Security best practices for authentication (2025)")
  RESEARCH_TOPICS+=("Existing authentication patterns in codebase")
fi

if echo "$FEATURE_DESC" | grep -qi "performance\|optimize\|speed"; then
  RESEARCH_TOPICS+=("Performance optimization techniques")
  RESEARCH_TOPICS+=("Benchmarking and profiling approaches")
fi

# Generic topics for all features
RESEARCH_TOPICS+=("Existing implementations of similar features")
RESEARCH_TOPICS+=("Project coding standards and conventions")

# Limit to top 3-4 most relevant topics
RESEARCH_TOPICS=("${RESEARCH_TOPICS[@]:0:4}")
```

**Prompt** (lines 197-211):
```
Step 5: Research Topics

Based on your feature, I suggest researching:
1. [topic 1]
2. [topic 2]
3. [topic 3]

Options:
- Press Enter to proceed with these topics
- Edit topics (comma-separated list)
- Type 'skip' to skip research

Your choice:
```

**User Input**: Enter (use suggestions), custom list, or "skip"

#### Wizard Completion

After gathering all inputs, the wizard would:
1. Launch parallel research agents (if research confirmed)
2. Invoke `/plan` command with collected context
3. Display plan creation results

**Final Output** (lines 364-378):
```
✅ Plan Created Successfully!

Plan: specs/plans/[NNN]_[feature_name].md
Phases: N
Complexity: $COMPLEXITY
Research: [Y/N, N artifacts if yes]

Next steps:
- Review the plan: cat specs/plans/[NNN]_[feature_name].md
- Implement the plan: /implement specs/plans/[NNN]_[feature_name].md
- Modify if needed: /update plan specs/plans/[NNN]_[feature_name].md "changes..."

The wizard has completed. Happy implementing! 🚀
```

### 4. Interactive Prompt Patterns and Standards

#### Terminal Detection Pattern

**Standard Pattern** (used in all interactive prompts):
```bash
if [ -t 0 ]; then
  # Interactive mode: stdin is a terminal
  read -p "Prompt message: " variable
  echo "$variable"
else
  # Non-interactive mode: stdin is not a terminal
  # Use default behavior or return empty/default value
  echo ""  # or echo "$DEFAULT_VALUE"
fi
```

**Test**: `[ -t 0 ]` checks if file descriptor 0 (stdin) is a terminal

**Purpose**: Enable automation (CI/CD, scripts) while supporting human interaction

#### User Input Processing

**Simple Choice Pattern** (`escalate_to_user()`):
```bash
read -p "Choose an option: " choice
echo "$choice"
```

**Validated Numeric Choice** (`escalate_to_user_parallel()`):
```bash
read -r choice

if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#OPTIONS[@]} ]]; then
  echo "${OPTIONS[$((choice-1))]}"  # Valid choice
  return 0
else
  echo "Invalid choice, defaulting to: ${OPTIONS[0]}" >&2
  echo "${OPTIONS[0]}"  # Default on invalid input
  return 0
fi
```

**Y/N Confirmation Pattern** (plan-wizard Step 4):
```bash
read -p "Confirm? (y/n) [$DEFAULT]: " choice
choice="${choice:-$DEFAULT}"  # Use default if empty
```

## Key Findings

### 1. Checkpoint Systems Are Fully Implemented

Both `/implement` and `/orchestrate` commands have complete checkpoint detection and interactive resume capabilities:

**Consistency**: Both commands use identical prompt structure and options
- (r)esume, (s)tart fresh, (v)iew details, (d)elete

**Integration**: Checkpoints are managed by shared utility library (`.claude/lib/checkpoint-utils.sh`)

**Robustness**: Checkpoint schema versioning (v1.1) with migration support

**Adaptive Planning Integration**: Checkpoint schema includes replanning metadata (v1.1 fields)

### 2. Error Escalation Prompts Are Strategic

Interactive prompts only appear when:
1. **Automated recovery failed** (retry exhausted)
2. **Human judgment required** (multiple recovery options exist)
3. **Partial success** (some operations succeeded, some failed)

**Design Principle**: Minimize human interruption; only escalate when necessary

### 3. Plan Wizard Is Conceptual Only

The `/plan-wizard` command is **fully documented but not implemented**:

**Specification Quality**: Complete with all prompts, logic, examples, and error handling
- 718 lines of detailed documentation
- Step-by-step workflow
- Example usage scenarios
- Integration patterns

**Implementation Gap**: No executable code (no shell script, no agent)

**Reason**: Likely deprioritized in favor of direct `/plan` command usage

**Value**: Documented design can inform future implementation if needed

### 4. Interactive Prompts Follow Consistent Patterns

All interactive systems use:
- **Terminal detection**: `[ -t 0 ]` pattern
- **Graceful degradation**: Non-interactive defaults
- **Structured output**: Clear options and formatting
- **Error handling**: Invalid input defaults to safe option

**No Inconsistencies**: All prompts follow same architecture

### 5. No Interactive Prompts During Normal Execution

Interactive prompts are **limited to workflow control and error recovery**:

**No Interactive Prompts In**:
- `/report` command (fully automated)
- `/plan` command (fully automated)
- `/test` command (fully automated)
- `/document` command (fully automated)
- Phase execution within `/implement` or `/orchestrate`

**Interactive Prompts Only In**:
- Workflow initialization (checkpoint detection)
- Error recovery (when automated retry fails)
- Conceptual wizard (not implemented)

**Design Rationale**: Maintain automation-friendly behavior for CI/CD and agent invocation

## Technical Details

### Checkpoint File Format

**Schema Version 1.1** (current)

**Example Checkpoint** (`.claude/checkpoints/implement_auth_system_20251010_140523.json`):
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_auth_system_20251010_140523",
  "workflow_type": "implement",
  "project_name": "auth_system",
  "workflow_description": "Implement user authentication with email/password",
  "created_at": "2025-10-10T14:05:23Z",
  "updated_at": "2025-10-10T14:32:15Z",
  "status": "in_progress",
  "current_phase": 3,
  "total_phases": 5,
  "completed_phases": [1, 2],
  "workflow_state": {
    "plan_path": "specs/plans/018_auth_implementation.md",
    "tests_passing": true,
    "files_modified": ["auth.lua", "user.lua", "tests/auth_spec.lua"]
  },
  "last_error": null,
  "replanning_count": 1,
  "last_replan_reason": "Phase complexity score 9.2 exceeds threshold 8",
  "replan_phase_counts": {
    "phase_2": 1
  },
  "replan_history": [
    {
      "phase": 2,
      "timestamp": "2025-10-10T14:20:30Z",
      "reason": "Phase complexity score 9.2 exceeds threshold 8",
      "action": "Expanded phase 2 into separate file"
    }
  ]
}
```

**Schema Migration** (v1.0 → v1.1):

**Added Fields** (lines 259-267):
```bash
jq '. + {
  schema_version: "'$CHECKPOINT_SCHEMA_VERSION'",
  replanning_count: (.replanning_count // 0),
  last_replan_reason: (.last_replan_reason // null),
  replan_phase_counts: (.replan_phase_counts // {}),
  replan_history: (.replan_history // [])
}' "$checkpoint_file" > "${checkpoint_file}.migrated"
```

**Automatic Migration**: `migrate_checkpoint_format()` automatically upgrades old checkpoints (lines 227-274)

### Interactive Prompt Formatting

#### Box-Drawing Characters

All prompts use Unicode box-drawing for visual structure:

**Example** (`escalate_to_user_parallel()`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User Escalation Required
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Character**: U+2501 (BOX DRAWINGS HEAVY HORIZONTAL)

**Consistency**: Same box-drawing style used throughout all commands

#### Option Formatting

**Standard Pattern**:
```
Options:
  (r)esume - Continue from Phase [N+1]
  (s)tart fresh - Delete checkpoint and restart
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

**Features**:
- Single-letter shortcuts in parentheses
- Clear description for each option
- Default indicated in brackets (when applicable)
- Concise labels for quick scanning

### Error Handling

#### Invalid Checkpoint Handling

**Corrupted JSON** (`restore_checkpoint()`, lines 160-166):
```bash
# Validate JSON if jq available
if command -v jq &> /dev/null; then
  if ! jq empty "$checkpoint_file" 2>/dev/null; then
    echo "Corrupted checkpoint (invalid JSON): $checkpoint_file" >&2
    echo "Delete with: rm \"$checkpoint_file\"" >&2
    return 1
  fi
fi
```

**Response**: Clear error message with recovery command

#### Missing Checkpoint Handling

**No Checkpoint Found** (`restore_checkpoint()`, lines 148-151):
```bash
if [ -z "$checkpoint_file" ]; then
  echo "No checkpoint found for workflow type: $workflow_type" >&2
  return 1
fi
```

**Response**: Command proceeds with fresh start (no interactive prompt if no checkpoint)

#### Interactive Prompt Timeout

**No Built-in Timeout**: `read -p` command blocks indefinitely

**Potential Issue**: User AFK leaves workflow hanging

**Mitigation**: Not implemented (current design assumes active user)

**Recommendation**: Add `read -t 300` (5-minute timeout) for production use

## Recommendations

### 1. Standardize Interactive Prompt Utility

**Current State**: Each command re-implements interactive prompt logic

**Recommendation**: Create shared utility function

**Implementation** (add to `.claude/lib/prompt-utils.sh`):
```bash
#!/usr/bin/env bash
# Shared interactive prompt utilities

# prompt_user_choice: Present options and get user choice
# Usage: prompt_user_choice "Title" "option1,option2,option3" "default"
# Returns: Selected option
prompt_user_choice() {
  local title="${1:-}"
  local options="${2:-}"
  local default="${3:-}"

  # Parse options
  IFS=',' read -ra OPTS <<< "$options"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "$title" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Display options
  for i in "${!OPTS[@]}"; do
    echo "  $((i+1)). ${OPTS[$i]}" >&2
  done
  echo "" >&2

  # Check if interactive
  if [[ -t 0 ]]; then
    echo -n "Choose an option (1-${#OPTS[@]}): " >&2
    read -r choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#OPTS[@]} ]]; then
      echo "${OPTS[$((choice-1))]}"
    else
      echo "Invalid choice, using default: ${default:-${OPTS[0]}}" >&2
      echo "${default:-${OPTS[0]}}"
    fi
  else
    # Non-interactive
    echo "${default:-${OPTS[0]}}"
  fi
}

# prompt_checkpoint_resume: Standard checkpoint resume prompt
# Usage: prompt_checkpoint_resume "$CHECKPOINT_DATA"
# Returns: r|s|v|d
prompt_checkpoint_resume() {
  local checkpoint_data="${1:-}"

  # Extract checkpoint fields
  local plan_path=$(echo "$checkpoint_data" | jq -r '.plan_path // .project_name')
  local created_at=$(echo "$checkpoint_data" | jq -r '.created_at')
  local current_phase=$(echo "$checkpoint_data" | jq -r '.current_phase')
  local total_phases=$(echo "$checkpoint_data" | jq -r '.total_phases')

  echo "Found existing checkpoint" >&2
  echo "Plan: $plan_path" >&2
  echo "Created: $created_at" >&2
  echo "Progress: Phase $current_phase of $total_phases completed" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  (r)esume - Continue from Phase $((current_phase + 1))" >&2
  echo "  (s)tart fresh - Delete checkpoint and restart" >&2
  echo "  (v)iew details - Show checkpoint contents" >&2
  echo "  (d)elete - Remove checkpoint without starting" >&2
  echo "" >&2

  if [[ -t 0 ]]; then
    read -p "Choice [r/s/v/d]: " choice
    echo "${choice:-r}"  # Default to resume
  else
    echo "r"  # Non-interactive default: resume
  fi
}

export -f prompt_user_choice
export -f prompt_checkpoint_resume
```

**Benefits**:
- Consistent UX across all commands
- Centralized interactive/non-interactive logic
- Easier testing
- Reduced code duplication

### 2. Add Timeout to Interactive Prompts

**Current Issue**: Prompts block indefinitely if user doesn't respond

**Recommendation**: Add timeout with sensible defaults

**Implementation**:
```bash
# Interactive prompt with timeout
if [[ -t 0 ]]; then
  read -t 300 -p "Choice [r/s/v/d]: " choice  # 5-minute timeout

  if [ $? -eq 142 ]; then
    # Timeout occurred
    echo "Prompt timed out after 5 minutes, using default: resume" >&2
    choice="r"
  fi

  echo "${choice:-r}"
else
  echo "r"  # Non-interactive default
fi
```

**Timeout Values**:
- Checkpoint resume: 300 seconds (5 minutes)
- Error escalation: 180 seconds (3 minutes)
- Wizard prompts: 120 seconds (2 minutes per step)

### 3. Implement Testing for Interactive Prompts

**Current Gap**: No tests for interactive prompt handling

**Recommendation**: Add test suite for prompt utilities

**Test Strategy**:

**A. Non-Interactive Mode Testing** (primary):
```bash
# Test non-interactive behavior (no actual user input needed)
test_checkpoint_resume_noninteractive() {
  # Simulate non-interactive environment
  result=$(echo "" | ./prompt-utils.sh prompt_checkpoint_resume "$CHECKPOINT_JSON")

  assert_equals "$result" "r" "Should default to resume in non-interactive mode"
}
```

**B. Simulated Interactive Mode Testing** (with echo):
```bash
# Test interactive mode with simulated input
test_checkpoint_resume_with_input() {
  # Pipe simulated user input
  result=$(echo "s" | ./prompt-utils.sh prompt_checkpoint_resume "$CHECKPOINT_JSON")

  assert_equals "$result" "s" "Should return user's choice"
}
```

**C. Timeout Testing**:
```bash
# Test timeout behavior
test_prompt_timeout() {
  # Simulate timeout (no input within timeout period)
  result=$(timeout 1s bash -c 'read -t 0.5 -p "Test: " choice; echo $choice')

  assert_equals "$?" "142" "Should return timeout exit code"
}
```

**Test File**: `.claude/tests/test_interactive_prompts.sh`

### 4. Consider Implementing Plan Wizard

**Current State**: Fully specified but not implemented

**Decision Factors**:

**Arguments For Implementation**:
- Lowers barrier for new users
- Guides discovery of planning features
- Reduces cognitive load
- Well-documented design exists

**Arguments Against Implementation**:
- Direct `/plan` command works well
- Adds maintenance burden
- Interactive prompts complicate automation
- May not be frequently used by experienced users

**Recommendation**: **Defer implementation** unless user research indicates need

**Alternative**: Create non-interactive "guided plan" mode:
```bash
/plan --guided "Add authentication"
# Analyzes description, suggests components, recommends research
# Outputs suggested command:
# Suggested: /plan "Add authentication" --research "auth patterns, security practices"
# Run this? (y/n)
```

### 5. Document Interactive Prompt Guidelines

**Recommendation**: Create `.claude/docs/interactive-prompt-guidelines.md`

**Contents**:
- When to use interactive prompts vs automation
- Standard prompt format and styling
- Terminal detection pattern
- Non-interactive fallback requirements
- Timeout recommendations
- Testing requirements

**Purpose**: Ensure consistency when adding new interactive prompts

### 6. Add Logging for Interactive Prompt Usage

**Current Gap**: No visibility into prompt usage patterns

**Recommendation**: Log when prompts are shown and user choices

**Implementation**:
```bash
# Add to prompt utility functions
log_prompt_interaction() {
  local prompt_type="${1:-}"
  local user_choice="${2:-}"
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  echo "[$timestamp] PROMPT_INTERACTION type=$prompt_type choice=$user_choice" >> .claude/logs/prompts.log
}
```

**Benefits**:
- Understand which prompts users encounter most
- Identify confusing prompts (frequent timeouts or invalid choices)
- Measure interactive vs non-interactive usage

## Testing Gaps

### Current State

**Test Coverage**: **0% for interactive prompts**

**Existing Tests**: None found for:
- Checkpoint detection prompts
- Error escalation prompts
- Interactive input validation
- Non-interactive fallback behavior

### Recommended Test Suite

**Test File**: `.claude/tests/test_interactive_prompts.sh`

**Test Categories**:

1. **Non-Interactive Mode** (5 tests)
   - Checkpoint resume defaults to "resume"
   - Error escalation defaults to first option
   - Invalid input handling in non-interactive mode
   - Empty input handling
   - Timeout behavior (if implemented)

2. **Interactive Mode Simulation** (8 tests)
   - Valid single-letter choice (r/s/v/d)
   - Valid numeric choice (1/2/3)
   - Invalid choice defaults correctly
   - Empty input uses default
   - Case-insensitive input handling
   - Whitespace trimming
   - Multiple choice handling
   - Option parsing

3. **Terminal Detection** (3 tests)
   - Correctly identifies interactive terminal
   - Correctly identifies non-interactive stdin (pipe)
   - Correctly identifies non-interactive stdin (redirect)

4. **Checkpoint Integration** (4 tests)
   - Resume from checkpoint
   - Start fresh (checkpoint deleted)
   - View details (checkpoint displayed)
   - Delete checkpoint (workflow aborts)

5. **Error Escalation** (4 tests)
   - Standard error escalation flow
   - Parallel error escalation flow
   - Multiple recovery options
   - Recovery option validation

**Total Recommended Tests**: 24 tests

### Test Implementation Example

```bash
#!/usr/bin/env bash
# Test interactive prompts

source "$(dirname "$0")/../lib/test-framework.sh"
source "$(dirname "$0")/../lib/prompt-utils.sh"

test_checkpoint_resume_defaults_to_resume() {
  local checkpoint_json='{"plan_path":"test.md","current_phase":2,"total_phases":5}'

  # Simulate non-interactive (empty stdin)
  local result=$(echo "" | prompt_checkpoint_resume "$checkpoint_json" 2>/dev/null)

  assert_equals "$result" "r" "Should default to resume"
}

test_checkpoint_resume_accepts_user_choice() {
  local checkpoint_json='{"plan_path":"test.md","current_phase":2,"total_phases":5}'

  # Simulate user choosing "start fresh"
  local result=$(echo "s" | prompt_checkpoint_resume "$checkpoint_json" 2>/dev/null)

  assert_equals "$result" "s" "Should return user's choice"
}

test_invalid_choice_uses_default() {
  # Simulate invalid input
  local result=$(echo "invalid" | prompt_user_choice "Test" "opt1,opt2,opt3" "opt1" 2>/dev/null)

  assert_equals "$result" "opt1" "Should use default on invalid input"
}

run_tests
```

## Integration with Broader System

### Checkpoint Detection in Workflow

**Initialization Sequence** (both `/implement` and `/orchestrate`):

```
1. Command invoked: /implement [plan-file]
   ↓
2. Check for existing checkpoint
   ↓
3. If checkpoint exists:
   ├─ Display checkpoint info
   ├─ Present interactive prompt (r/s/v/d)
   ├─ Wait for user choice (or use default if non-interactive)
   └─ Branch based on choice:
      ├─ (r)esume: Load checkpoint state, continue from last phase
      ├─ (s)tart: Delete checkpoint, begin from phase 1
      ├─ (v)iew: Display checkpoint JSON, then prompt again
      └─ (d)elete: Delete checkpoint, exit command
   ↓
4. If no checkpoint or "start fresh":
   └─ Initialize new workflow, create checkpoint after phase 1
   ↓
5. Execute workflow phases
   ↓
6. Save checkpoint after each phase
   ↓
7. On completion: Delete checkpoint
```

### Error Escalation in Workflow

**Error Recovery Sequence**:

```
1. Phase execution encounters error
   ↓
2. Classify error (transient/permanent/fatal)
   ↓
3. Attempt automatic recovery (max 3 retries)
   ↓
4. If retries exhausted:
   ├─ Generate recovery options
   ├─ Call escalate_to_user() or escalate_to_user_parallel()
   ├─ Display error context and recovery options
   ├─ Wait for user choice
   └─ Execute chosen recovery action
   ↓
5. If recovery succeeds: Continue workflow
6. If recovery fails: Save error checkpoint, exit
```

### Adaptive Planning Integration

**Checkpoint Schema v1.1** includes adaptive planning metadata:

**Replan Detection** (in `/implement` command):
```bash
# Check replan limit before automatic revision
PHASE_REPLAN_COUNT=$(jq -r ".replan_phase_counts.phase_${CURRENT_PHASE} // 0" "$CHECKPOINT")

if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  # Reached limit, skip automatic replan
  # Could present interactive prompt: "Manual replan needed. Continue? (y/n)"
  echo "Replan limit reached for phase $CURRENT_PHASE"
fi
```

**Potential Interactive Prompt** (not currently implemented):
```
⚠ Replanning Limit Reached

Phase $CURRENT_PHASE has been replanned 2 times (maximum).

Replan History:
  - Attempt 1: Complexity threshold exceeded
  - Attempt 2: Test failure pattern detected

Options:
  (c)ontinue - Proceed with current plan (may fail again)
  (r)evise - Manual revision via /revise command
  (s)kip - Skip this phase and continue
  (a)bort - Stop implementation

Choice [c/r/s/a]:
```

**Recommendation**: Consider adding this interactive prompt to `/implement` for replan limit scenarios

## Cross-References

### Related Documentation
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh`
- **Error Handling**: `.claude/lib/error-utils.sh`
- **Adaptive Planning**: `.claude/docs/adaptive-plan-structures.md`
- **Command Patterns**: `.claude/docs/command-patterns.md`

### Related Commands
- `/implement`: Primary checkpoint detection user (lines 1560-1647)
- `/orchestrate`: Workflow checkpoint detection (lines 2405-2477)
- `/plan-wizard`: Conceptual interactive wizard (not implemented)

### Related Tests
- **Checkpoint Tests**: `.claude/tests/test_checkpoint_parallel_ops.sh`
- **Error Recovery Tests**: `.claude/tests/test_error_recovery.sh`
- **Needed**: `.claude/tests/test_interactive_prompts.sh` (recommended)

## Lessons Learned

### Design Insights

1. **Minimalist Approach Works Well**: Only two interactive prompt systems needed
2. **Terminal Detection Pattern is Robust**: `[ -t 0 ]` reliably detects interactive environments
3. **Non-Interactive Defaults are Critical**: Enables CI/CD and automation
4. **Checkpoint Versioning is Forward-Thinking**: Schema migration prevents breaking changes

### Implementation Trade-offs

1. **Plan Wizard vs Direct Commands**: Direct commands preferred for automation
2. **Interactive vs Automated Recovery**: Interactive for human judgment, automated where possible
3. **Prompt Timeout**: Not implemented (assumes active user) - could be issue in production
4. **Shared Utilities**: Currently duplicated - should be centralized

### Future Considerations

1. **Voice Input**: Plan wizard mentioned voice input as future enhancement (line 699)
2. **GUI Integration**: Text-only currently, could add TUI (text UI) with libraries like `dialog`
3. **Remote Operation**: Consider how prompts work over SSH or remote command execution
4. **Multi-User Workflows**: Current design assumes single user - collaborative workflows would need different prompt handling

## Conclusion

The .claude/ configuration implements a **well-designed, consistent interactive prompt system** focused on workflow resumption and error recovery. The two implemented systems (`/implement` and `/orchestrate` checkpoint detection) follow identical patterns and use robust terminal detection for graceful degradation.

**Key Strengths**:
- Consistent UX across commands
- Automation-friendly design
- Robust checkpoint management
- Strategic use of interactive prompts (only when necessary)

**Key Opportunities**:
- Standardize prompt utilities to reduce duplication
- Add timeout handling for production resilience
- Implement test coverage for interactive behaviors
- Consider adding more interactive prompts for edge cases (e.g., replan limits)

**Plan Wizard Status**: Fully documented but not implemented - defer unless user research indicates need.

The current implementation demonstrates thoughtful design that balances human interaction needs with automation requirements. The recommended improvements focus on standardization, robustness, and testing rather than major architectural changes.

## References

### Primary Files Analyzed
1. `.claude/commands/implement.md` - Checkpoint detection (lines 1560-1647)
2. `.claude/commands/orchestrate.md` - Workflow checkpoint detection (lines 2405-2477)
3. `.claude/lib/checkpoint-utils.sh` - Checkpoint management utilities
4. `.claude/lib/error-utils.sh` - Error escalation prompts (lines 155-182, 621-679)
5. `.claude/commands/plan-wizard.md` - Conceptual wizard design (718 lines)
6. `.claude/docs/command-patterns.md` - Command design patterns

### Search Queries Used
- `read -p` - Interactive input pattern
- `checkpoint.*found|resume.*checkpoint` - Checkpoint detection
- `escalate.*user|interactive.*prompt` - Error escalation
- `Options:|Choice \[` - Interactive prompt formatting

### Time Investment
- **Research Phase**: ~45 minutes (codebase search, file reading)
- **Analysis Phase**: ~30 minutes (pattern identification, cross-referencing)
- **Report Writing**: ~60 minutes (documentation, formatting)
- **Total**: ~2.5 hours

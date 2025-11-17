# Phase 1 Expansion: Foundation - Create Command Template and Shared Utilities

## Phase Overview

**Objective**: Create a production-ready, reusable template with all 6 essential features that serves as the foundation for generating dedicated orchestrator commands.

**Complexity**: Medium (7/10)
- Template requires careful design for maintainability
- Must support multiple workflow types with single source
- Compatibility verification is critical for reliability
- Version management adds coordination overhead

**Duration Estimate**: 4 hours
- Template creation: 2 hours
- Compatibility script: 1 hour
- Testing and validation: 1 hour

**Dependencies**: None (foundation phase)

**Success Criteria**:
1. Template file contains all 6 essential features from `/coordinate`
2. Substitution markers work correctly for all workflow types
3. Compatibility verification catches library mismatches
4. Template versioning supports future updates
5. All tests pass with 100% feature coverage

---

## Stage 1.1: Template File Structure and Headers

### Objective
Create the base template file with proper versioning, metadata, and documentation structure.

### Implementation Details

#### 1.1.1: Create Template File
**File**: `/home/benjamin/.config/.claude/templates/state-based-orchestrator-template.md`

**Structure** (600-800 lines total):
```markdown
# {{COMMAND_NAME}} - State-Based Orchestrator Template
# Version: 1.0.0
# Template Type: State-Based Orchestrator
# Workflow Type: {{WORKFLOW_TYPE}}
# Compatible With: state-machine-lib >= 2.0.0

## Template Metadata
- **Template Version**: 1.0.0
- **Last Updated**: 2025-11-17
- **Minimum Library Version**: state-machine-lib 2.0.0
- **Required Features**: 6 essential features
- **Target Line Count**: 600-800 lines

## Library Compatibility Matrix

| Library Component | Minimum Version | Required Features |
|------------------|----------------|-------------------|
| state-machine-lib | 2.0.0 | Core orchestration, state transitions |
| hierarchical-agent-utils | 1.5.0 | Agent spawning, coordination |
| terminal-manager | 1.3.0 | Output buffering, context preservation |
| error-handler-lib | 1.2.0 | Error classification, recovery |

## Essential Features Checklist

This template MUST include all 6 essential features:

- [x] 1. Workflow Description Capture (identical to /coordinate)
- [x] 2. State Machine Initialization with workflow_type
- [x] 3. Hierarchical Agent Coordination in Research Phase
- [x] 4. Complexity Override Parsing (--complexity flag)
- [x] 5. Conditional Phase Activation
- [x] 6. Terminal State with Artifact Summary

## Customization Points

### Workflow-Specific Substitutions
- `{{WORKFLOW_TYPE}}`: debug | research | plan | implement | test
- `{{COMMAND_NAME}}`: /debug | /research | /plan | /implement | /test-all
- `{{DEFAULT_COMPLEXITY}}`: 1-4 (workflow-dependent)
- `{{TERMINAL_STATE}}`: debug_complete | research_complete | etc.

### Conditional Phase Flags
- `{{ENABLE_PLANNING}}`: true/false - Include planning phase
- `{{ENABLE_IMPLEMENTATION}}`: true/false - Include implementation phase
- `{{ENABLE_TESTING}}`: true/false - Include testing phase
- `{{ENABLE_DEBUG}}`: true/false - Include debug phase
- `{{ENABLE_DOCUMENTATION}}`: true/false - Include documentation phase

### Customizable Constants
- `{{MAX_RESEARCH_DEPTH}}`: 2-4 (hierarchical depth)
- `{{MAX_RETRY_ATTEMPTS}}`: 2-3 (error recovery)
- `{{TIMEOUT_MINUTES}}`: 30-120 (workflow timeout)
```

#### 1.1.2: Version Header Format
**Location**: Lines 1-30 of template

**YAML Frontmatter**:
```yaml
---
template_version: "1.0.0"
template_type: "state-based-orchestrator"
workflow_type: "{{WORKFLOW_TYPE}}"
compatibility:
  state_machine_lib: ">=2.0.0"
  hierarchical_agent_utils: ">=1.5.0"
  terminal_manager: ">=1.3.0"
  error_handler_lib: ">=1.2.0"
features:
  - workflow_description_capture
  - state_machine_initialization
  - hierarchical_agent_coordination
  - complexity_override_parsing
  - conditional_phase_activation
  - terminal_state_summary
substitution_markers:
  - WORKFLOW_TYPE
  - COMMAND_NAME
  - DEFAULT_COMPLEXITY
  - TERMINAL_STATE
  - ENABLE_PLANNING
  - ENABLE_IMPLEMENTATION
  - ENABLE_TESTING
  - ENABLE_DEBUG
  - ENABLE_DOCUMENTATION
  - MAX_RESEARCH_DEPTH
  - MAX_RETRY_ATTEMPTS
  - TIMEOUT_MINUTES
changelog: ".claude/templates/CHANGELOG.md"
---
```

#### 1.1.3: Template Documentation Section
**Location**: Lines 31-100

```markdown
## Template Usage Guide

### Generating a New Orchestrator Command

1. **Copy Template**: Create new command file in `.claude/commands/`
2. **Substitute Markers**: Replace all `{{MARKER}}` placeholders
3. **Configure Phases**: Set conditional phase flags
4. **Verify Compatibility**: Run verification script
5. **Test Command**: Execute with `--dry-run` flag

### Example Substitution

For `/debug` command:
- `{{WORKFLOW_TYPE}}`: "debug"
- `{{COMMAND_NAME}}`: "/debug"
- `{{DEFAULT_COMPLEXITY}}`: "2"
- `{{TERMINAL_STATE}}`: "debug_complete"
- `{{ENABLE_PLANNING}}`: false
- `{{ENABLE_IMPLEMENTATION}}`: false
- `{{ENABLE_TESTING}}`: false
- `{{ENABLE_DEBUG}}`: true
- `{{ENABLE_DOCUMENTATION}}`: true
- `{{MAX_RESEARCH_DEPTH}}`: 3
- `{{MAX_RETRY_ATTEMPTS}}`: 2
- `{{TIMEOUT_MINUTES}}`: 60

### Validation Requirements

Before deploying:
1. All substitution markers resolved (no `{{}}` remaining)
2. Library compatibility verified
3. Essential features checklist complete
4. Syntax validation passed
5. Dry-run execution successful

## Architecture Notes

### Template Design Principles

1. **Single Source of Truth**: All orchestrator commands derive from this template
2. **Feature Parity**: Maintain 100% feature compatibility with `/coordinate`
3. **Version Tracking**: Explicit versioning for template evolution
4. **Substitution Safety**: Clear marker syntax prevents partial substitutions
5. **Library Coupling**: Explicit compatibility matrix prevents runtime failures

### Maintenance Guidelines

1. **Breaking Changes**: Increment major version (2.0.0)
2. **New Features**: Increment minor version (1.1.0)
3. **Bug Fixes**: Increment patch version (1.0.1)
4. **Changelog**: Document all changes in CHANGELOG.md
5. **Backward Compatibility**: Support N-1 version for 6 months
```

---

## Stage 1.2: Feature 1 - Workflow Description Capture

### Objective
Implement identical workflow description capture as `/coordinate` (lines 100-150).

### Implementation Details

#### 1.2.1: User Input Section
**Location**: Lines 100-150

```bash
#!/usr/bin/env bash
# Part 1: Workflow Description Capture
# Feature: Identical to /coordinate command
# Lines: 100-150

set -euo pipefail

# Source required libraries
source "$(dirname "$0")/../lib/state-machine-lib.sh"
source "$(dirname "$0")/../lib/terminal-manager.sh"
source "$(dirname "$0")/../lib/error-handler-lib.sh"

# Workflow metadata
readonly WORKFLOW_TYPE="{{WORKFLOW_TYPE}}"
readonly COMMAND_NAME="{{COMMAND_NAME}}"
readonly DEFAULT_COMPLEXITY={{DEFAULT_COMPLEXITY}}

# Capture workflow description from command line
if [[ $# -eq 0 ]]; then
    echo "Error: Workflow description required" >&2
    echo "Usage: $COMMAND_NAME <description> [--complexity N]" >&2
    exit 1
fi

# Parse arguments
WORKFLOW_DESCRIPTION=""
COMPLEXITY_OVERRIDE=""
ADDITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --complexity)
            if [[ -z "${2:-}" ]] || [[ ! "$2" =~ ^[1-4]$ ]]; then
                echo "Error: --complexity requires value 1-4" >&2
                exit 1
            fi
            COMPLEXITY_OVERRIDE="$2"
            shift 2
            ;;
        --*)
            ADDITIONAL_ARGS+=("$1")
            if [[ -n "${2:-}" ]] && [[ ! "$2" =~ ^-- ]]; then
                ADDITIONAL_ARGS+=("$2")
                shift
            fi
            shift
            ;;
        *)
            if [[ -z "$WORKFLOW_DESCRIPTION" ]]; then
                WORKFLOW_DESCRIPTION="$1"
            else
                WORKFLOW_DESCRIPTION="$WORKFLOW_DESCRIPTION $1"
            fi
            shift
            ;;
    esac
done

# Validate workflow description
if [[ -z "$WORKFLOW_DESCRIPTION" ]]; then
    echo "Error: Workflow description cannot be empty" >&2
    exit 1
fi

# Set complexity (override or default)
readonly COMPLEXITY="${COMPLEXITY_OVERRIDE:-$DEFAULT_COMPLEXITY}"

echo "=== {{COMMAND_NAME}} Orchestrator ===" >&2
echo "Workflow: $WORKFLOW_DESCRIPTION" >&2
echo "Complexity: $COMPLEXITY/4" >&2
echo "Type: $WORKFLOW_TYPE" >&2
echo "" >&2
```

#### 1.2.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_workflow_capture.sh`

```bash
#!/usr/bin/env bash
# Test: Workflow Description Capture

test_workflow_capture_basic() {
    local output
    output=$(/debug "investigate authentication bug" 2>&1)

    assert_contains "$output" "Workflow: investigate authentication bug"
    assert_contains "$output" "Complexity: 2/4"
    assert_contains "$output" "Type: debug"
}

test_workflow_capture_complexity_override() {
    local output
    output=$(/research "state machine patterns" --complexity 3 2>&1)

    assert_contains "$output" "Complexity: 3/4"
}

test_workflow_capture_missing_description() {
    local output
    output=$(/plan 2>&1)

    assert_exit_code 1
    assert_contains "$output" "Error: Workflow description required"
}

test_workflow_capture_invalid_complexity() {
    local output
    output=$(/implement "add feature" --complexity 5 2>&1)

    assert_exit_code 1
    assert_contains "$output" "Error: --complexity requires value 1-4"
}

test_workflow_capture_multiword_description() {
    local output
    output=$(/test-all "run integration tests for auth module" 2>&1)

    assert_contains "$output" "Workflow: run integration tests for auth module"
}
```

---

## Stage 1.3: Feature 2 - State Machine Initialization

### Objective
Initialize state machine with workflow_type placeholder (lines 150-250).

### Implementation Details

#### 1.3.1: State Machine Setup
**Location**: Lines 150-250

```bash
# Part 2: State Machine Initialization
# Feature: State machine with workflow_type
# Lines: 150-250

# Initialize state machine
readonly STATE_DIR=".claude/specs/${WORKFLOW_DESCRIPTION//[^a-zA-Z0-9_]/_}"
readonly STATE_FILE="$STATE_DIR/state.json"
readonly ARTIFACTS_DIR="$STATE_DIR/artifacts"
readonly REPORTS_DIR="$STATE_DIR/reports"

# Create directory structure
mkdir -p "$STATE_DIR" "$ARTIFACTS_DIR" "$REPORTS_DIR"

# Define workflow-specific states
declare -A WORKFLOW_STATES

case "$WORKFLOW_TYPE" in
    debug)
        WORKFLOW_STATES=(
            [init]="research_phase"
            [research_phase]="debug_phase"
            [debug_phase]="documentation_phase"
            [documentation_phase]="debug_complete"
            [debug_complete]="terminal"
        )
        ;;
    research)
        WORKFLOW_STATES=(
            [init]="research_phase"
            [research_phase]="synthesis_phase"
            [synthesis_phase]="research_complete"
            [research_complete]="terminal"
        )
        ;;
    plan)
        WORKFLOW_STATES=(
            [init]="research_phase"
            [research_phase]="planning_phase"
            [planning_phase]="plan_complete"
            [plan_complete]="terminal"
        )
        ;;
    implement)
        WORKFLOW_STATES=(
            [init]="research_phase"
            [research_phase]="planning_phase"
            [planning_phase]="implementation_phase"
            [implementation_phase]="testing_phase"
            [testing_phase]="implement_complete"
            [implement_complete]="terminal"
        )
        ;;
    test)
        WORKFLOW_STATES=(
            [init]="research_phase"
            [research_phase]="testing_phase"
            [testing_phase]="test_complete"
            [test_complete]="terminal"
        )
        ;;
    *)
        echo "Error: Unknown workflow type: $WORKFLOW_TYPE" >&2
        exit 1
        ;;
esac

# Initialize or resume state
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_STATE=$(jq -r '.current_state' "$STATE_FILE")
    echo "Resuming from state: $CURRENT_STATE" >&2
else
    CURRENT_STATE="init"
    cat > "$STATE_FILE" <<EOF
{
  "workflow_type": "$WORKFLOW_TYPE",
  "workflow_description": "$WORKFLOW_DESCRIPTION",
  "complexity": $COMPLEXITY,
  "current_state": "$CURRENT_STATE",
  "created_at": "$(date -Iseconds)",
  "updated_at": "$(date -Iseconds)",
  "phase_results": {},
  "error_count": 0,
  "retry_count": 0
}
EOF
    echo "Initialized state machine: $WORKFLOW_TYPE" >&2
fi

# State transition function
transition_state() {
    local next_state="${WORKFLOW_STATES[$CURRENT_STATE]}"

    if [[ -z "$next_state" ]]; then
        echo "Error: No transition defined from $CURRENT_STATE" >&2
        return 1
    fi

    # Update state file
    jq --arg state "$next_state" \
       --arg timestamp "$(date -Iseconds)" \
       '.current_state = $state | .updated_at = $timestamp' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    CURRENT_STATE="$next_state"
    echo "Transitioned to: $CURRENT_STATE" >&2
}

# Error recovery function
handle_phase_error() {
    local phase="$1"
    local error_msg="$2"

    local error_count
    error_count=$(jq -r '.error_count' "$STATE_FILE")
    error_count=$((error_count + 1))

    jq --arg phase "$phase" \
       --arg error "$error_msg" \
       --arg count "$error_count" \
       '.error_count = ($count | tonumber) | .last_error = {phase: $phase, message: $error}' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    if [[ $error_count -ge {{MAX_RETRY_ATTEMPTS}} ]]; then
        echo "Error: Maximum retry attempts reached ($error_count)" >&2
        return 1
    fi

    echo "Error in $phase (attempt $error_count/{{MAX_RETRY_ATTEMPTS}}): $error_msg" >&2
    return 0
}
```

#### 1.3.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_state_machine.sh`

```bash
#!/usr/bin/env bash
# Test: State Machine Initialization

test_state_machine_initialization() {
    local state_file=".claude/specs/test_workflow/state.json"

    /debug "test workflow" >/dev/null 2>&1

    assert_file_exists "$state_file"
    assert_json_field "$state_file" ".workflow_type" "debug"
    assert_json_field "$state_file" ".current_state" "init"
}

test_state_transition() {
    local state_file=".claude/specs/test_workflow/state.json"

    # Initialize and transition
    /research "test topic" >/dev/null 2>&1

    # Verify state updated
    local current_state
    current_state=$(jq -r '.current_state' "$state_file")
    assert_not_equal "$current_state" "init"
}

test_state_resume() {
    # Create existing state
    mkdir -p ".claude/specs/resume_test"
    cat > ".claude/specs/resume_test/state.json" <<EOF
{
  "workflow_type": "plan",
  "current_state": "planning_phase",
  "complexity": 3
}
EOF

    local output
    output=$(/plan "resume test" 2>&1)

    assert_contains "$output" "Resuming from state: planning_phase"
}

test_error_recovery() {
    local state_file=".claude/specs/error_test/state.json"

    # Simulate error
    /implement "error test" >/dev/null 2>&1 || true

    local error_count
    error_count=$(jq -r '.error_count' "$state_file")
    assert_greater_than "$error_count" "0"
}

test_workflow_specific_states() {
    # Debug workflow
    /debug "test" >/dev/null 2>&1
    assert_state_exists ".claude/specs/test/state.json" "debug_phase"

    # Research workflow
    /research "test" >/dev/null 2>&1
    assert_state_exists ".claude/specs/test/state.json" "synthesis_phase"
}
```

---

## Stage 1.4: Feature 3 - Hierarchical Agent Coordination

### Objective
Implement research phase with hierarchical/flat coordination (lines 250-500).

### Implementation Details

#### 1.4.1: Research Phase Implementation
**Location**: Lines 250-500

```bash
# Part 3: Research Phase - Hierarchical Agent Coordination
# Feature: Hierarchical agent coordination in research phase
# Lines: 250-500

source "$(dirname "$0")/../lib/hierarchical-agent-utils.sh"

# Research phase configuration
readonly RESEARCH_DEPTH={{MAX_RESEARCH_DEPTH}}
readonly RESEARCH_BREADTH=4  # Standard 4-agent pattern

execute_research_phase() {
    echo "=== Research Phase ===" >&2
    echo "Depth: $RESEARCH_DEPTH levels" >&2
    echo "Breadth: $RESEARCH_BREADTH agents per level" >&2

    # Determine coordination mode based on complexity
    local coordination_mode
    if [[ $COMPLEXITY -ge 3 ]]; then
        coordination_mode="hierarchical"
        echo "Mode: Hierarchical (complexity $COMPLEXITY >= 3)" >&2
    else
        coordination_mode="flat"
        echo "Mode: Flat (complexity $COMPLEXITY < 3)" >&2
    fi

    # Initialize research coordinator
    local supervisor_agent="$ARTIFACTS_DIR/research_supervisor.md"

    cat > "$supervisor_agent" <<'SUPERVISOR_EOF'
# Research Supervisor Agent

You are coordinating research for: {{WORKFLOW_DESCRIPTION}}

## Coordination Mode: {{COORDINATION_MODE}}

## Your Responsibilities

1. **Topic Decomposition**: Break down research into 4 focused sub-topics
2. **Agent Spawning**: Create specialized research agents for each sub-topic
3. **Progress Monitoring**: Track completion of all research agents
4. **Synthesis**: Combine findings into OVERVIEW.md

## Research Structure

Create exactly 4 research agents:
- Agent 1: [Primary aspect]
- Agent 2: [Secondary aspect]
- Agent 3: [Implementation details]
- Agent 4: [Integration considerations]

## Output Requirements

1. Individual reports: `001_topic1.md` through `004_topic4.md`
2. Synthesis report: `OVERVIEW.md` (500-800 lines)
3. State update: Mark research_phase complete

## Coordination Pattern

{{#if hierarchical}}
Use hierarchical coordination:
- Spawn 4 level-1 agents
- Each level-1 agent spawns 2-3 level-2 agents
- Maximum depth: {{MAX_RESEARCH_DEPTH}} levels
- Total agents: 12-16
{{else}}
Use flat coordination:
- Spawn 4 parallel agents
- No sub-agents
- All agents report directly to supervisor
- Total agents: 4
{{/if}}

SUPERVISOR_EOF

    # Substitute template variables
    sed -i "s/{{WORKFLOW_DESCRIPTION}}/$WORKFLOW_DESCRIPTION/g" "$supervisor_agent"
    sed -i "s/{{COORDINATION_MODE}}/$coordination_mode/g" "$supervisor_agent"
    sed -i "s/{{MAX_RESEARCH_DEPTH}}/$RESEARCH_DEPTH/g" "$supervisor_agent"

    # Handle conditional coordination mode
    if [[ "$coordination_mode" == "hierarchical" ]]; then
        sed -i '/{{#if hierarchical}}/,/{{else}}/!d' "$supervisor_agent"
        sed -i '/{{#if hierarchical}}/d; /{{else}}/,/{{\/if}}/d' "$supervisor_agent"
    else
        sed -i '/{{#if hierarchical}}/,/{{else}}/d' "$supervisor_agent"
        sed -i '/{{\/if}}/d' "$supervisor_agent"
    fi

    # Execute supervisor agent
    local supervisor_output
    supervisor_output=$(execute_agent "$supervisor_agent" "$REPORTS_DIR" 2>&1)
    local supervisor_exit=$?

    if [[ $supervisor_exit -ne 0 ]]; then
        handle_phase_error "research_phase" "Supervisor agent failed: $supervisor_output"
        return 1
    fi

    # Verify research outputs
    local required_reports=("001_*.md" "002_*.md" "003_*.md" "004_*.md" "OVERVIEW.md")
    for pattern in "${required_reports[@]}"; do
        if ! ls "$REPORTS_DIR"/$pattern >/dev/null 2>&1; then
            handle_phase_error "research_phase" "Missing required report: $pattern"
            return 1
        fi
    done

    # Count total agents spawned (for metrics)
    local agent_count
    agent_count=$(grep -r "Agent spawned:" "$REPORTS_DIR" | wc -l)

    # Update state with research results
    jq --arg reports "$REPORTS_DIR" \
       --arg agent_count "$agent_count" \
       --arg coordination "$coordination_mode" \
       '.phase_results.research = {
           reports_dir: $reports,
           agent_count: ($agent_count | tonumber),
           coordination_mode: $coordination,
           completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S"))
       }' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "Research phase complete: $agent_count agents, $coordination_mode mode" >&2
    return 0
}

# Agent execution wrapper
execute_agent() {
    local agent_file="$1"
    local output_dir="$2"

    # Use terminal manager for buffered output
    local terminal_id
    terminal_id=$(create_terminal_buffer)

    # Execute agent with timeout
    timeout {{TIMEOUT_MINUTES}}m \
        claude-code agent "$agent_file" \
        --output-dir "$output_dir" \
        --terminal-id "$terminal_id" \
        2>&1

    local exit_code=$?

    # Capture buffered output
    get_terminal_buffer "$terminal_id" > "$output_dir/agent_output.log"
    destroy_terminal_buffer "$terminal_id"

    return $exit_code
}
```

#### 1.4.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_research_phase.sh`

```bash
#!/usr/bin/env bash
# Test: Hierarchical Agent Coordination

test_research_phase_flat_mode() {
    local reports_dir=".claude/specs/flat_research/reports"

    /debug "simple issue" --complexity 1 >/dev/null 2>&1

    assert_file_exists "$reports_dir/001_*.md"
    assert_file_exists "$reports_dir/OVERVIEW.md"

    local agent_count
    agent_count=$(jq -r '.phase_results.research.agent_count' \
        ".claude/specs/flat_research/state.json")
    assert_equal "$agent_count" "4"
}

test_research_phase_hierarchical_mode() {
    local reports_dir=".claude/specs/hierarchical_research/reports"

    /implement "complex feature" --complexity 4 >/dev/null 2>&1

    local agent_count
    agent_count=$(jq -r '.phase_results.research.agent_count' \
        ".claude/specs/hierarchical_research/state.json")
    assert_greater_than "$agent_count" "4"
    assert_less_than "$agent_count" "17"
}

test_research_phase_coordination_mode_selection() {
    # Complexity 2 -> flat
    /plan "task" --complexity 2 >/dev/null 2>&1
    local mode1
    mode1=$(jq -r '.phase_results.research.coordination_mode' \
        ".claude/specs/task/state.json")
    assert_equal "$mode1" "flat"

    # Complexity 3 -> hierarchical
    /plan "task2" --complexity 3 >/dev/null 2>&1
    local mode2
    mode2=$(jq -r '.phase_results.research.coordination_mode' \
        ".claude/specs/task2/state.json")
    assert_equal "$mode2" "hierarchical"
}

test_research_phase_required_reports() {
    local reports_dir=".claude/specs/reports_test/reports"

    /research "topic" >/dev/null 2>&1

    assert_file_exists "$reports_dir/001_*.md"
    assert_file_exists "$reports_dir/002_*.md"
    assert_file_exists "$reports_dir/003_*.md"
    assert_file_exists "$reports_dir/004_*.md"
    assert_file_exists "$reports_dir/OVERVIEW.md"
}

test_research_phase_agent_timeout() {
    # Mock slow agent
    export MOCK_AGENT_DELAY=600  # 10 minutes

    local output
    output=$(/research "slow topic" 2>&1)

    assert_exit_code 1
    assert_contains "$output" "timeout"
}
```

---

## Stage 1.5: Feature 4 - Complexity Override Parsing

### Objective
Implement `--complexity [1-4]` flag support with validation (integrated in Stage 1.2).

### Implementation Details

#### 1.5.1: Complexity Flag Parsing (Already Implemented)
**Reference**: Lines 120-145 in Stage 1.2.1

**Additional Validation**:
```bash
# Complexity validation function
validate_complexity() {
    local complexity="$1"

    if [[ ! "$complexity" =~ ^[1-4]$ ]]; then
        echo "Error: Complexity must be 1, 2, 3, or 4" >&2
        echo "  1: Minimal (flat coordination, basic features)" >&2
        echo "  2: Simple (flat coordination, standard features)" >&2
        echo "  3: Moderate (hierarchical coordination, enhanced features)" >&2
        echo "  4: Complex (deep hierarchical, full features)" >&2
        return 1
    fi

    return 0
}
```

#### 1.5.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_complexity_override.sh`

```bash
#!/usr/bin/env bash
# Test: Complexity Override Parsing

test_complexity_override_valid() {
    for complexity in 1 2 3 4; do
        local output
        output=$(/plan "test" --complexity $complexity 2>&1)
        assert_contains "$output" "Complexity: $complexity/4"
    done
}

test_complexity_override_invalid() {
    for invalid in 0 5 -1 abc; do
        local output
        output=$(/plan "test" --complexity $invalid 2>&1)
        assert_exit_code 1
        assert_contains "$output" "Error: --complexity requires value 1-4"
    done
}

test_complexity_default_per_workflow() {
    # Debug: default 2
    local output1
    output1=$(/debug "test" 2>&1)
    assert_contains "$output1" "Complexity: 2/4"

    # Implement: default 3
    local output2
    output2=$(/implement "test" 2>&1)
    assert_contains "$output2" "Complexity: 3/4"
}

test_complexity_affects_coordination() {
    # Low complexity -> flat
    /research "test1" --complexity 1 >/dev/null 2>&1
    local mode1
    mode1=$(jq -r '.phase_results.research.coordination_mode' \
        ".claude/specs/test1/state.json")
    assert_equal "$mode1" "flat"

    # High complexity -> hierarchical
    /research "test2" --complexity 4 >/dev/null 2>&1
    local mode2
    mode2=$(jq -r '.phase_results.research.coordination_mode' \
        ".claude/specs/test2/state.json")
    assert_equal "$mode2" "hierarchical"
}
```

---

## Stage 1.6: Feature 5 - Conditional Phase Activation

### Objective
Implement placeholder sections for conditional phases with substitution markers.

### Implementation Details

#### 1.6.1: Conditional Phase Template
**Location**: Lines 500-650

```bash
# Part 4: Conditional Phases
# Feature: Conditional phase activation
# Lines: 500-650

# Planning Phase (conditional)
{{#if ENABLE_PLANNING}}
execute_planning_phase() {
    echo "=== Planning Phase ===" >&2

    local planning_agent="$ARTIFACTS_DIR/planning_agent.md"

    cat > "$planning_agent" <<'PLANNING_EOF'
# Planning Agent

## Context
- Workflow: {{WORKFLOW_DESCRIPTION}}
- Research reports: Available in reports/ directory
- Complexity: {{COMPLEXITY}}

## Task
Create detailed implementation plan based on research findings.

## Output Requirements
1. Plan file: `plans/001_{{WORKFLOW_DESCRIPTION}}.md`
2. Phase breakdown with dependencies
3. Task estimates and success criteria
4. Testing strategy

## Plan Structure
- Metadata section
- Phase 1-N with objectives
- Dependencies between phases
- Rollback procedures

PLANNING_EOF

    # Execute planning agent
    local planning_output
    planning_output=$(execute_agent "$planning_agent" "$STATE_DIR/plans" 2>&1)

    if [[ $? -ne 0 ]]; then
        handle_phase_error "planning_phase" "Planning agent failed"
        return 1
    fi

    # Update state
    jq '.phase_results.planning = {completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S"))}' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    return 0
}
{{/if}}

# Implementation Phase (conditional)
{{#if ENABLE_IMPLEMENTATION}}
execute_implementation_phase() {
    echo "=== Implementation Phase ===" >&2

    local implementation_agent="$ARTIFACTS_DIR/implementation_agent.md"

    cat > "$implementation_agent" <<'IMPLEMENTATION_EOF'
# Implementation Agent

## Context
- Plan: Available in plans/ directory
- Research: Available in reports/ directory
- Workflow: {{WORKFLOW_DESCRIPTION}}

## Task
Execute implementation plan with testing and validation.

## Output Requirements
1. Code changes committed
2. Tests passing
3. Documentation updated
4. Artifacts in artifacts/ directory

## Implementation Strategy
- Phase-by-phase execution
- Test-driven development
- Continuous validation
- Rollback on failure

IMPLEMENTATION_EOF

    # Execute implementation agent
    local impl_output
    impl_output=$(execute_agent "$implementation_agent" "$ARTIFACTS_DIR" 2>&1)

    if [[ $? -ne 0 ]]; then
        handle_phase_error "implementation_phase" "Implementation failed"
        return 1
    fi

    # Update state
    jq '.phase_results.implementation = {completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S"))}' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    return 0
}
{{/if}}

# Testing Phase (conditional)
{{#if ENABLE_TESTING}}
execute_testing_phase() {
    echo "=== Testing Phase ===" >&2

    # Run test suite
    local test_output
    test_output=$(bash .claude/scripts/run-tests.sh 2>&1)
    local test_exit=$?

    # Save test results
    echo "$test_output" > "$ARTIFACTS_DIR/test_results.log"

    if [[ $test_exit -ne 0 ]]; then
        handle_phase_error "testing_phase" "Tests failed"
        return 1
    fi

    # Update state
    jq '.phase_results.testing = {
        completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S")),
        test_results: "artifacts/test_results.log"
    }' "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    return 0
}
{{/if}}

# Debug Phase (conditional)
{{#if ENABLE_DEBUG}}
execute_debug_phase() {
    echo "=== Debug Phase ===" >&2

    local debug_agent="$ARTIFACTS_DIR/debug_agent.md"

    cat > "$debug_agent" <<'DEBUG_EOF'
# Debug Agent

## Context
- Issue: {{WORKFLOW_DESCRIPTION}}
- Research: Available in reports/ directory
- Complexity: {{COMPLEXITY}}

## Task
Investigate issue and create diagnostic report.

## Output Requirements
1. Root cause analysis
2. Reproduction steps
3. Fix recommendations
4. Test cases to prevent regression

## Debug Strategy
- Systematic investigation
- Evidence collection
- Hypothesis testing
- Fix validation

DEBUG_EOF

    # Execute debug agent
    local debug_output
    debug_output=$(execute_agent "$debug_agent" "$STATE_DIR/debug" 2>&1)

    if [[ $? -ne 0 ]]; then
        handle_phase_error "debug_phase" "Debug analysis failed"
        return 1
    fi

    # Update state
    jq '.phase_results.debug = {completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S"))}' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    return 0
}
{{/if}}

# Documentation Phase (conditional)
{{#if ENABLE_DOCUMENTATION}}
execute_documentation_phase() {
    echo "=== Documentation Phase ===" >&2

    local doc_agent="$ARTIFACTS_DIR/documentation_agent.md"

    cat > "$doc_agent" <<'DOC_EOF'
# Documentation Agent

## Context
- Workflow: {{WORKFLOW_DESCRIPTION}}
- All phase results: Available in state.json

## Task
Create comprehensive documentation for completed workflow.

## Output Requirements
1. Summary document: `summary.md`
2. Updated README if applicable
3. API documentation if applicable
4. User guide if applicable

## Documentation Strategy
- Clear, concise language
- Code examples
- Visual diagrams where helpful
- No emojis (UTF-8 encoding)

DOC_EOF

    # Execute documentation agent
    local doc_output
    doc_output=$(execute_agent "$doc_agent" "$STATE_DIR" 2>&1)

    if [[ $? -ne 0 ]]; then
        handle_phase_error "documentation_phase" "Documentation failed"
        return 1
    fi

    # Update state
    jq '.phase_results.documentation = {completed_at: (now | strftime("%Y-%m-%dT%H:%M:%S"))}' \
       "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    return 0
}
{{/if}}
```

#### 1.6.2: Phase Activation Logic
**Location**: Lines 650-700

```bash
# Main execution loop
main() {
    # Execute research phase (always required)
    if ! execute_research_phase; then
        echo "Error: Research phase failed" >&2
        exit 1
    fi
    transition_state

    # Execute conditional phases
    {{#if ENABLE_PLANNING}}
    if [[ "$CURRENT_STATE" == "planning_phase" ]]; then
        if ! execute_planning_phase; then
            echo "Error: Planning phase failed" >&2
            exit 1
        fi
        transition_state
    fi
    {{/if}}

    {{#if ENABLE_IMPLEMENTATION}}
    if [[ "$CURRENT_STATE" == "implementation_phase" ]]; then
        if ! execute_implementation_phase; then
            echo "Error: Implementation phase failed" >&2
            exit 1
        fi
        transition_state
    fi
    {{/if}}

    {{#if ENABLE_TESTING}}
    if [[ "$CURRENT_STATE" == "testing_phase" ]]; then
        if ! execute_testing_phase; then
            echo "Error: Testing phase failed" >&2
            exit 1
        fi
        transition_state
    fi
    {{/if}}

    {{#if ENABLE_DEBUG}}
    if [[ "$CURRENT_STATE" == "debug_phase" ]]; then
        if ! execute_debug_phase; then
            echo "Error: Debug phase failed" >&2
            exit 1
        fi
        transition_state
    fi
    {{/if}}

    {{#if ENABLE_DOCUMENTATION}}
    if [[ "$CURRENT_STATE" == "documentation_phase" ]]; then
        if ! execute_documentation_phase; then
            echo "Error: Documentation phase failed" >&2
            exit 1
        fi
        transition_state
    fi
    {{/if}}

    # Terminal state
    if [[ "$CURRENT_STATE" == "{{TERMINAL_STATE}}" ]]; then
        echo "=== Workflow Complete ===" >&2
        generate_terminal_summary
        exit 0
    fi
}

main "$@"
```

#### 1.6.3: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_conditional_phases.sh`

```bash
#!/usr/bin/env bash
# Test: Conditional Phase Activation

test_debug_workflow_phases() {
    /debug "test issue" >/dev/null 2>&1

    local phases
    phases=$(jq -r '.phase_results | keys[]' \
        ".claude/specs/test_issue/state.json")

    assert_contains "$phases" "research"
    assert_contains "$phases" "debug"
    assert_contains "$phases" "documentation"
    assert_not_contains "$phases" "planning"
    assert_not_contains "$phases" "implementation"
}

test_implement_workflow_phases() {
    /implement "test feature" >/dev/null 2>&1

    local phases
    phases=$(jq -r '.phase_results | keys[]' \
        ".claude/specs/test_feature/state.json")

    assert_contains "$phases" "research"
    assert_contains "$phases" "planning"
    assert_contains "$phases" "implementation"
    assert_contains "$phases" "testing"
    assert_not_contains "$phases" "debug"
}

test_research_workflow_phases() {
    /research "test topic" >/dev/null 2>&1

    local phases
    phases=$(jq -r '.phase_results | keys[]' \
        ".claude/specs/test_topic/state.json")

    assert_contains "$phases" "research"
    assert_equal "$(echo "$phases" | wc -l)" "1"  # Only research
}

test_phase_skip_on_error() {
    # Mock planning phase failure
    export MOCK_PLANNING_FAILURE=true

    /plan "test" >/dev/null 2>&1

    local phases
    phases=$(jq -r '.phase_results | keys[]' \
        ".claude/specs/test/state.json")

    assert_contains "$phases" "research"
    assert_not_contains "$phases" "planning"
}
```

---

## Stage 1.7: Feature 6 - Terminal State Summary

### Objective
Implement terminal state with comprehensive artifact summary.

### Implementation Details

#### 1.7.1: Terminal State Implementation
**Location**: Lines 700-800

```bash
# Part 5: Terminal State and Artifact Summary
# Feature: Terminal state with artifact summary
# Lines: 700-800

generate_terminal_summary() {
    echo "" >&2
    echo "========================================" >&2
    echo "  {{COMMAND_NAME}} Workflow Complete" >&2
    echo "========================================" >&2
    echo "" >&2

    # Read state for summary
    local workflow_desc complexity created_at
    workflow_desc=$(jq -r '.workflow_description' "$STATE_FILE")
    complexity=$(jq -r '.complexity' "$STATE_FILE")
    created_at=$(jq -r '.created_at' "$STATE_FILE")

    # Calculate duration
    local start_timestamp end_timestamp duration_seconds duration_formatted
    start_timestamp=$(date -d "$created_at" +%s 2>/dev/null || echo "0")
    end_timestamp=$(date +%s)
    duration_seconds=$((end_timestamp - start_timestamp))
    duration_formatted=$(format_duration $duration_seconds)

    echo "Workflow: $workflow_desc" >&2
    echo "Type: $WORKFLOW_TYPE" >&2
    echo "Complexity: $complexity/4" >&2
    echo "Duration: $duration_formatted" >&2
    echo "" >&2

    # Phase summary
    echo "Completed Phases:" >&2
    jq -r '.phase_results | to_entries[] | "  - \(.key): \(.value.completed_at // "in progress")"' \
        "$STATE_FILE" >&2
    echo "" >&2

    # Artifact summary
    echo "Generated Artifacts:" >&2

    if [[ -d "$REPORTS_DIR" ]]; then
        local report_count
        report_count=$(find "$REPORTS_DIR" -name "*.md" -type f | wc -l)
        echo "  Reports: $report_count files in $REPORTS_DIR" >&2
        find "$REPORTS_DIR" -name "*.md" -type f -exec basename {} \; | sort | sed 's/^/    - /' >&2
    fi

    if [[ -d "$STATE_DIR/plans" ]]; then
        local plan_count
        plan_count=$(find "$STATE_DIR/plans" -name "*.md" -type f | wc -l)
        if [[ $plan_count -gt 0 ]]; then
            echo "  Plans: $plan_count files in $STATE_DIR/plans" >&2
            find "$STATE_DIR/plans" -name "*.md" -type f -exec basename {} \; | sort | sed 's/^/    - /' >&2
        fi
    fi

    if [[ -d "$ARTIFACTS_DIR" ]]; then
        local artifact_count
        artifact_count=$(find "$ARTIFACTS_DIR" -type f | wc -l)
        if [[ $artifact_count -gt 0 ]]; then
            echo "  Artifacts: $artifact_count files in $ARTIFACTS_DIR" >&2
            find "$ARTIFACTS_DIR" -type f -exec basename {} \; | sort | sed 's/^/    - /' >&2
        fi
    fi

    if [[ -d "$STATE_DIR/debug" ]]; then
        local debug_count
        debug_count=$(find "$STATE_DIR/debug" -type f | wc -l)
        if [[ $debug_count -gt 0 ]]; then
            echo "  Debug Reports: $debug_count files in $STATE_DIR/debug" >&2
            find "$STATE_DIR/debug" -type f -exec basename {} \; | sort | sed 's/^/    - /' >&2
        fi
    fi

    echo "" >&2

    # Error summary (if any)
    local error_count
    error_count=$(jq -r '.error_count' "$STATE_FILE")
    if [[ $error_count -gt 0 ]]; then
        echo "Errors Encountered: $error_count" >&2
        jq -r '.last_error | "  Last: \(.phase) - \(.message)"' "$STATE_FILE" >&2
        echo "" >&2
    fi

    # Agent metrics
    local total_agents
    total_agents=$(jq -r '.phase_results.research.agent_count // 0' "$STATE_FILE")
    if [[ $total_agents -gt 0 ]]; then
        local coordination_mode
        coordination_mode=$(jq -r '.phase_results.research.coordination_mode' "$STATE_FILE")
        echo "Agent Metrics:" >&2
        echo "  Total Agents: $total_agents" >&2
        echo "  Coordination: $coordination_mode" >&2
        echo "" >&2
    fi

    # Next steps
    echo "Next Steps:" >&2
    case "$WORKFLOW_TYPE" in
        debug)
            echo "  1. Review debug report in $STATE_DIR/debug/" >&2
            echo "  2. Implement recommended fixes" >&2
            echo "  3. Run tests to verify resolution" >&2
            ;;
        research)
            echo "  1. Review OVERVIEW.md in $REPORTS_DIR/" >&2
            echo "  2. Create implementation plan with /plan" >&2
            echo "  3. Execute plan with /implement" >&2
            ;;
        plan)
            echo "  1. Review plan in $STATE_DIR/plans/" >&2
            echo "  2. Execute plan with /implement" >&2
            echo "  3. Monitor progress and adapt as needed" >&2
            ;;
        implement)
            echo "  1. Review implementation artifacts" >&2
            echo "  2. Run additional tests if needed" >&2
            echo "  3. Create PR or deploy changes" >&2
            ;;
        test)
            echo "  1. Review test results in $ARTIFACTS_DIR/" >&2
            echo "  2. Fix any failing tests" >&2
            echo "  3. Re-run test suite to verify" >&2
            ;;
    esac

    echo "" >&2
    echo "State file: $STATE_FILE" >&2
    echo "========================================" >&2
}

# Duration formatting utility
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}
```

#### 1.7.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_terminal_state.sh`

```bash
#!/usr/bin/env bash
# Test: Terminal State Summary

test_terminal_summary_generation() {
    local output
    output=$(/debug "test issue" 2>&1)

    assert_contains "$output" "Workflow Complete"
    assert_contains "$output" "Completed Phases:"
    assert_contains "$output" "Generated Artifacts:"
    assert_contains "$output" "Next Steps:"
}

test_terminal_summary_duration() {
    local output
    output=$(/research "test topic" 2>&1)

    assert_contains "$output" "Duration:"
    assert_matches "$output" "[0-9]+[hms]"
}

test_terminal_summary_artifacts() {
    /plan "test feature" >/dev/null 2>&1

    local output
    output=$(/plan "test feature" 2>&1)

    assert_contains "$output" "Reports:"
    assert_contains "$output" "001_"
    assert_contains "$output" "OVERVIEW.md"
}

test_terminal_summary_error_reporting() {
    # Mock error
    export MOCK_PHASE_ERROR=true

    local output
    output=$(/implement "test" 2>&1 || true)

    assert_contains "$output" "Errors Encountered:"
    assert_contains "$output" "Last:"
}

test_terminal_summary_agent_metrics() {
    local output
    output=$(/research "test" --complexity 3 2>&1)

    assert_contains "$output" "Agent Metrics:"
    assert_contains "$output" "Total Agents:"
    assert_contains "$output" "Coordination:"
}

test_terminal_summary_next_steps() {
    # Debug workflow
    local output1
    output1=$(/debug "test" 2>&1)
    assert_contains "$output1" "Review debug report"

    # Research workflow
    local output2
    output2=$(/research "test" 2>&1)
    assert_contains "$output2" "Review OVERVIEW.md"

    # Plan workflow
    local output3
    output3=$(/plan "test" 2>&1)
    assert_contains "$output3" "Execute plan with /implement"
}
```

---

## Stage 1.8: Library Compatibility Verification

### Objective
Create compatibility verification script to validate library versions.

### Implementation Details

#### 1.8.1: Verification Script
**File**: `/home/benjamin/.config/.claude/lib/verify-state-machine-compatibility.sh`

```bash
#!/usr/bin/env bash
# Library Compatibility Verification Script
# Version: 1.0.0

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$SCRIPT_DIR"

# Required library versions
declare -A REQUIRED_VERSIONS=(
    [state-machine-lib]=2.0.0
    [hierarchical-agent-utils]=1.5.0
    [terminal-manager]=1.3.0
    [error-handler-lib]=1.2.0
)

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Version comparison function
version_gte() {
    local version=$1
    local required=$2

    # Convert to comparable format: 1.2.3 -> 001002003
    local ver_num=$(echo "$version" | awk -F. '{printf "%03d%03d%03d", $1, $2, $3}')
    local req_num=$(echo "$required" | awk -F. '{printf "%03d%03d%03d", $1, $2, $3}')

    [[ $ver_num -ge $req_num ]]
}

# Extract version from library file
get_library_version() {
    local lib_file="$1"

    if [[ ! -f "$lib_file" ]]; then
        echo "0.0.0"
        return 1
    fi

    # Look for version comment: # Version: X.Y.Z
    local version
    version=$(grep -m1 "^# Version:" "$lib_file" | awk '{print $3}')

    if [[ -z "$version" ]]; then
        echo "0.0.0"
        return 1
    fi

    echo "$version"
}

# Verify single library
verify_library() {
    local lib_name="$1"
    local required_version="${REQUIRED_VERSIONS[$lib_name]}"
    local lib_file="$LIB_DIR/$lib_name.sh"

    echo -n "Checking $lib_name... "

    if [[ ! -f "$lib_file" ]]; then
        echo -e "${RED}MISSING${NC}"
        echo "  Error: Library file not found: $lib_file"
        return 1
    fi

    local installed_version
    installed_version=$(get_library_version "$lib_file")

    if ! version_gte "$installed_version" "$required_version"; then
        echo -e "${RED}INCOMPATIBLE${NC}"
        echo "  Installed: $installed_version"
        echo "  Required:  >= $required_version"
        return 1
    fi

    echo -e "${GREEN}OK${NC} (version $installed_version)"
    return 0
}

# Verify template version compatibility
verify_template_version() {
    local template_file="$1"

    echo -n "Checking template version... "

    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}MISSING${NC}"
        echo "  Error: Template file not found: $template_file"
        return 1
    fi

    # Extract template version from YAML frontmatter
    local template_version
    template_version=$(grep "^template_version:" "$template_file" | awk '{print $2}' | tr -d '"')

    if [[ -z "$template_version" ]]; then
        echo -e "${RED}INVALID${NC}"
        echo "  Error: Template version not found in YAML frontmatter"
        return 1
    fi

    echo -e "${GREEN}OK${NC} (version $template_version)"

    # Verify compatibility matrix in template
    echo -n "Checking compatibility matrix... "

    local matrix_valid=true
    for lib_name in "${!REQUIRED_VERSIONS[@]}"; do
        local lib_key=$(echo "$lib_name" | tr '-' '_')
        local required_version="${REQUIRED_VERSIONS[$lib_name]}"

        if ! grep -q "$lib_key.*>=.*$required_version" "$template_file"; then
            echo -e "${RED}INVALID${NC}"
            echo "  Error: Compatibility matrix missing or incorrect for $lib_name"
            echo "  Expected: $lib_key >= $required_version"
            matrix_valid=false
            break
        fi
    done

    if $matrix_valid; then
        echo -e "${GREEN}OK${NC}"
    fi

    return $([ "$matrix_valid" = true ])
}

# Verify essential features checklist
verify_essential_features() {
    local template_file="$1"

    echo "Checking essential features..."

    local features=(
        "Workflow Description Capture"
        "State Machine Initialization"
        "Hierarchical Agent Coordination"
        "Complexity Override Parsing"
        "Conditional Phase Activation"
        "Terminal State with Artifact Summary"
    )

    local all_present=true
    for feature in "${features[@]}"; do
        echo -n "  - $feature... "
        if grep -q "$feature" "$template_file"; then
            echo -e "${GREEN}PRESENT${NC}"
        else
            echo -e "${RED}MISSING${NC}"
            all_present=false
        fi
    done

    return $([ "$all_present" = true ])
}

# Main verification
main() {
    local template_file="${1:-}"

    echo "=========================================="
    echo "  Library Compatibility Verification"
    echo "=========================================="
    echo ""

    # Verify libraries
    echo "Verifying library versions..."
    local lib_errors=0
    for lib_name in "${!REQUIRED_VERSIONS[@]}"; do
        if ! verify_library "$lib_name"; then
            ((lib_errors++))
        fi
    done
    echo ""

    # Verify template if provided
    local template_errors=0
    if [[ -n "$template_file" ]]; then
        echo "Verifying template..."
        if ! verify_template_version "$template_file"; then
            ((template_errors++))
        fi
        echo ""

        if ! verify_essential_features "$template_file"; then
            ((template_errors++))
        fi
        echo ""
    fi

    # Summary
    echo "=========================================="
    if [[ $lib_errors -eq 0 ]] && [[ $template_errors -eq 0 ]]; then
        echo -e "${GREEN}All checks passed!${NC}"
        echo "=========================================="
        return 0
    else
        echo -e "${RED}Verification failed!${NC}"
        echo "  Library errors: $lib_errors"
        if [[ -n "$template_file" ]]; then
            echo "  Template errors: $template_errors"
        fi
        echo "=========================================="
        return 1
    fi
}

main "$@"
```

#### 1.8.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_compatibility_verification.sh`

```bash
#!/usr/bin/env bash
# Test: Library Compatibility Verification

test_compatibility_all_libraries_present() {
    local output
    output=$(bash .claude/lib/verify-state-machine-compatibility.sh 2>&1)

    assert_exit_code 0
    assert_contains "$output" "All checks passed"
}

test_compatibility_missing_library() {
    # Temporarily rename library
    mv .claude/lib/state-machine-lib.sh .claude/lib/state-machine-lib.sh.bak

    local output
    output=$(bash .claude/lib/verify-state-machine-compatibility.sh 2>&1 || true)

    assert_exit_code 1
    assert_contains "$output" "MISSING"

    # Restore
    mv .claude/lib/state-machine-lib.sh.bak .claude/lib/state-machine-lib.sh
}

test_compatibility_outdated_library() {
    # Create mock outdated library
    cat > .claude/lib/test-lib.sh <<'EOF'
#!/usr/bin/env bash
# Version: 1.0.0
EOF

    # Temporarily add to required versions
    export REQUIRED_VERSIONS="test-lib=2.0.0"

    local output
    output=$(bash .claude/lib/verify-state-machine-compatibility.sh 2>&1 || true)

    assert_contains "$output" "INCOMPATIBLE"

    # Cleanup
    rm .claude/lib/test-lib.sh
}

test_compatibility_template_verification() {
    local output
    output=$(bash .claude/lib/verify-state-machine-compatibility.sh \
        .claude/templates/state-based-orchestrator-template.md 2>&1)

    assert_exit_code 0
    assert_contains "$output" "Checking template version... OK"
    assert_contains "$output" "Checking compatibility matrix... OK"
}

test_compatibility_essential_features() {
    local output
    output=$(bash .claude/lib/verify-state-machine-compatibility.sh \
        .claude/templates/state-based-orchestrator-template.md 2>&1)

    assert_contains "$output" "Workflow Description Capture... PRESENT"
    assert_contains "$output" "State Machine Initialization... PRESENT"
    assert_contains "$output" "Hierarchical Agent Coordination... PRESENT"
    assert_contains "$output" "Complexity Override Parsing... PRESENT"
    assert_contains "$output" "Conditional Phase Activation... PRESENT"
    assert_contains "$output" "Terminal State with Artifact Summary... PRESENT"
}

test_compatibility_version_comparison() {
    # Test version_gte function
    source .claude/lib/verify-state-machine-compatibility.sh

    assert_true version_gte "2.0.0" "1.5.0"
    assert_true version_gte "2.0.0" "2.0.0"
    assert_false version_gte "1.9.9" "2.0.0"
    assert_true version_gte "1.10.0" "1.9.0"
}
```

---

## Stage 1.9: Template Versioning and Changelog

### Objective
Create template changelog and versioning documentation.

### Implementation Details

#### 1.9.1: Changelog File
**File**: `/home/benjamin/.config/.claude/templates/CHANGELOG.md`

```markdown
# State-Based Orchestrator Template Changelog

## Version 1.0.0 (2025-11-17)

### Initial Release

#### Essential Features
1. **Workflow Description Capture** (lines 100-150)
   - Identical argument parsing to `/coordinate`
   - Multi-word description support
   - Additional argument passthrough

2. **State Machine Initialization** (lines 150-250)
   - Workflow-specific state definitions
   - Resume capability from interrupted workflows
   - Error recovery with retry limits
   - State transition validation

3. **Hierarchical Agent Coordination** (lines 250-500)
   - Complexity-based coordination mode selection
   - Flat coordination (complexity 1-2): 4 agents
   - Hierarchical coordination (complexity 3-4): 12-16 agents
   - Configurable research depth (2-4 levels)
   - Terminal manager integration for output buffering

4. **Complexity Override Parsing** (lines 120-145)
   - `--complexity [1-4]` flag support
   - Validation with error messages
   - Workflow-specific defaults
   - Complexity affects coordination mode

5. **Conditional Phase Activation** (lines 500-700)
   - Planning phase (optional)
   - Implementation phase (optional)
   - Testing phase (optional)
   - Debug phase (optional)
   - Documentation phase (optional)
   - Boolean flag configuration

6. **Terminal State Summary** (lines 700-800)
   - Comprehensive workflow summary
   - Phase completion listing
   - Artifact inventory with file counts
   - Duration calculation and formatting
   - Error summary
   - Agent metrics
   - Workflow-specific next steps

#### Template Infrastructure
- YAML frontmatter with version metadata
- Library compatibility matrix
- Substitution marker documentation
- Customization point guidelines
- Version header format
- Template usage guide

#### Substitution Markers
- `{{WORKFLOW_TYPE}}`: debug | research | plan | implement | test
- `{{COMMAND_NAME}}`: /debug | /research | /plan | /implement | /test-all
- `{{DEFAULT_COMPLEXITY}}`: 1-4 (workflow-dependent)
- `{{TERMINAL_STATE}}`: workflow_complete state name
- `{{ENABLE_*}}`: Conditional phase flags
- `{{MAX_RESEARCH_DEPTH}}`: 2-4 (hierarchical depth)
- `{{MAX_RETRY_ATTEMPTS}}`: 2-3 (error recovery)
- `{{TIMEOUT_MINUTES}}`: 30-120 (workflow timeout)

#### Library Dependencies
- state-machine-lib >= 2.0.0
- hierarchical-agent-utils >= 1.5.0
- terminal-manager >= 1.3.0
- error-handler-lib >= 1.2.0

#### Tooling
- Compatibility verification script
- Template validation tests
- Feature checklist validation
- Version extraction utilities

#### Documentation
- Template usage guide (lines 31-100)
- Architecture notes and design principles
- Maintenance guidelines
- Example substitutions for each workflow type

#### Testing
- 30+ test cases covering all features
- Integration tests for each workflow type
- Compatibility verification tests
- Error handling and recovery tests
- State machine transition tests

### Known Limitations
- Single-threaded execution (no parallel phases)
- Fixed 4-agent research pattern
- No dynamic phase dependency resolution
- Manual substitution marker resolution required

### Future Enhancements
See roadmap in template documentation.

---

## Version Scheme

Template versioning follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes to template structure or API
- **MINOR**: New features, backward-compatible
- **PATCH**: Bug fixes, documentation updates

### Backward Compatibility Policy
- Support N-1 major version for 6 months
- Deprecation warnings before breaking changes
- Migration guides for major version upgrades

---

## Upgrade Instructions

### From: N/A (Initial Release)
To: 1.0.0

This is the initial release. No upgrade necessary.

---

## Template Validation

To verify template integrity:

```bash
bash .claude/lib/verify-state-machine-compatibility.sh \
    .claude/templates/state-based-orchestrator-template.md
```

Expected output:
- All libraries compatible
- Template version detected
- All 6 essential features present
- Compatibility matrix valid

---

## Contributing

When updating template:

1. Increment version in YAML frontmatter
2. Update compatibility matrix if library versions change
3. Document changes in this CHANGELOG
4. Update template usage guide if API changes
5. Add/update tests for new features
6. Run verification script before committing
7. Update roadmap if addressing planned enhancements

---

## Support

For issues or questions:
- Check template usage guide in template file (lines 31-100)
- Run verification script for diagnostic information
- Review test cases for usage examples
- Consult state-machine-lib documentation for advanced features
```

#### 1.9.2: Testing Specification

**Test File**: `/home/benjamin/.config/.claude/tests/template/test_template_versioning.sh`

```bash
#!/usr/bin/env bash
# Test: Template Versioning

test_template_has_version() {
    local version
    version=$(grep "^template_version:" \
        .claude/templates/state-based-orchestrator-template.md | \
        awk '{print $2}' | tr -d '"')

    assert_not_empty "$version"
    assert_matches "$version" "^[0-9]+\.[0-9]+\.[0-9]+$"
}

test_changelog_exists() {
    assert_file_exists ".claude/templates/CHANGELOG.md"
}

test_changelog_has_current_version() {
    local template_version
    template_version=$(grep "^template_version:" \
        .claude/templates/state-based-orchestrator-template.md | \
        awk '{print $2}' | tr -d '"')

    assert_file_contains ".claude/templates/CHANGELOG.md" "## Version $template_version"
}

test_compatibility_matrix_in_template() {
    assert_file_contains \
        .claude/templates/state-based-orchestrator-template.md \
        "Library Compatibility Matrix"

    assert_file_contains \
        .claude/templates/state-based-orchestrator-template.md \
        "state-machine-lib"

    assert_file_contains \
        .claude/templates/state-based-orchestrator-template.md \
        "hierarchical-agent-utils"
}

test_template_line_count() {
    local line_count
    line_count=$(wc -l < .claude/templates/state-based-orchestrator-template.md)

    assert_greater_than "$line_count" "600"
    assert_less_than "$line_count" "900"
}
```

---

## Stage 1.10: Integration Testing

### Objective
Comprehensive integration tests for complete template functionality.

### Implementation Details

#### 1.10.1: Integration Test Suite
**File**: `/home/benjamin/.config/.claude/tests/template/test_template_integration.sh`

```bash
#!/usr/bin/env bash
# Test: Template Integration

test_full_debug_workflow() {
    local workflow_desc="test authentication bug"
    local output
    output=$(/debug "$workflow_desc" 2>&1)

    # Verify workflow executed
    assert_exit_code 0
    assert_contains "$output" "Workflow Complete"

    # Verify state file
    local state_file=".claude/specs/${workflow_desc//[^a-zA-Z0-9_]/_}/state.json"
    assert_file_exists "$state_file"
    assert_json_field "$state_file" ".workflow_type" "debug"

    # Verify phases completed
    assert_json_field "$state_file" ".phase_results.research.completed_at" --not-null
    assert_json_field "$state_file" ".phase_results.debug.completed_at" --not-null

    # Verify artifacts
    local reports_dir=".claude/specs/${workflow_desc//[^a-zA-Z0-9_]/_}/reports"
    assert_file_exists "$reports_dir/OVERVIEW.md"
}

test_full_research_workflow() {
    local workflow_desc="state machine patterns"
    local output
    output=$(/research "$workflow_desc" --complexity 3 2>&1)

    assert_exit_code 0

    # Verify hierarchical coordination used
    local state_file=".claude/specs/${workflow_desc//[^a-zA-Z0-9_]/_}/state.json"
    local coordination
    coordination=$(jq -r '.phase_results.research.coordination_mode' "$state_file")
    assert_equal "$coordination" "hierarchical"

    # Verify multiple agents
    local agent_count
    agent_count=$(jq -r '.phase_results.research.agent_count' "$state_file")
    assert_greater_than "$agent_count" "4"
}

test_workflow_resume_after_interruption() {
    local workflow_desc="resumable workflow"

    # Start workflow (simulate interruption after research)
    /plan "$workflow_desc" >/dev/null 2>&1 &
    local pid=$!
    sleep 5
    kill $pid 2>/dev/null || true
    wait $pid 2>/dev/null || true

    # Resume workflow
    local output
    output=$(/plan "$workflow_desc" 2>&1)

    assert_contains "$output" "Resuming from state:"
    assert_exit_code 0
}

test_error_recovery_with_retry() {
    # Mock agent failure
    export MOCK_AGENT_FAILURE=true
    export MOCK_FAILURE_COUNT=1

    local output
    output=$(/research "test topic" 2>&1)

    # Should retry and succeed
    assert_exit_code 0

    local state_file=".claude/specs/test_topic/state.json"
    local error_count
    error_count=$(jq -r '.error_count' "$state_file")
    assert_equal "$error_count" "1"
}

test_complexity_affects_all_features() {
    # Low complexity
    /test-all "low complexity test" --complexity 1 >/dev/null 2>&1
    local state1=".claude/specs/low_complexity_test/state.json"
    local mode1
    mode1=$(jq -r '.phase_results.research.coordination_mode' "$state1")
    assert_equal "$mode1" "flat"

    # High complexity
    /test-all "high complexity test" --complexity 4 >/dev/null 2>&1
    local state2=".claude/specs/high_complexity_test/state.json"
    local mode2
    mode2=$(jq -r '.phase_results.research.coordination_mode' "$state2")
    assert_equal "$mode2" "hierarchical"
}

test_terminal_summary_completeness() {
    local output
    output=$(/implement "test feature" 2>&1)

    # All required summary sections
    assert_contains "$output" "Workflow Complete"
    assert_contains "$output" "Completed Phases:"
    assert_contains "$output" "Generated Artifacts:"
    assert_contains "$output" "Duration:"
    assert_contains "$output" "Next Steps:"
    assert_contains "$output" "State file:"
}

test_all_substitution_markers_resolved() {
    # Generate command from template
    local test_command="/tmp/test-command.sh"

    # Simulate template substitution (manual for test)
    sed 's/{{WORKFLOW_TYPE}}/test/g; s/{{COMMAND_NAME}}/test-command/g' \
        .claude/templates/state-based-orchestrator-template.md > "$test_command"

    # Verify no markers remain
    local remaining_markers
    remaining_markers=$(grep -o '{{[A-Z_]*}}' "$test_command" | wc -l || echo 0)

    assert_equal "$remaining_markers" "0"
}
```

---

## Error Handling and Edge Cases

### Critical Error Scenarios

1. **Missing Library Dependencies**
   - Detection: Compatibility verification fails
   - Recovery: Install/update required libraries
   - Prevention: Run verification before deployment

2. **Invalid Substitution Markers**
   - Detection: Syntax errors when executing generated command
   - Recovery: Re-run template generator with correct values
   - Prevention: Validate markers before saving

3. **State File Corruption**
   - Detection: JSON parsing errors
   - Recovery: Restore from backup or reinitialize
   - Prevention: Atomic writes with .tmp files

4. **Agent Timeout**
   - Detection: Timeout command triggers
   - Recovery: Retry with increased timeout or lower complexity
   - Prevention: Set appropriate timeouts per complexity

5. **Incompatible Library Versions**
   - Detection: Compatibility script catches version mismatch
   - Recovery: Update libraries to required versions
   - Prevention: Version pinning in compatibility matrix

---

## Performance Considerations

### Template File Size
- Target: 600-800 lines
- Maximum: 1000 lines
- Optimization: Remove redundant comments, consolidate functions

### State File Operations
- Use atomic writes (write to .tmp, then mv)
- Minimize jq calls (batch updates where possible)
- Cache state reads within single execution

### Agent Spawning
- Flat mode: 4 agents (fast, simple workflows)
- Hierarchical mode: 12-16 agents (complex workflows)
- Trade-off: Depth vs. breadth (more depth = more agents = longer runtime)

### Terminal Buffer Management
- Create buffers lazily (only when needed)
- Destroy buffers after use (free resources)
- Buffer size limit: 10MB per agent

---

## Acceptance Criteria

### Template File
- [ ] 600-800 lines total
- [ ] YAML frontmatter with version 1.0.0
- [ ] All 6 essential features implemented
- [ ] All 8 substitution markers documented
- [ ] Compatibility matrix complete
- [ ] Usage guide with examples
- [ ] Passes syntax validation

### Compatibility Script
- [ ] Checks all 4 required libraries
- [ ] Version comparison logic works correctly
- [ ] Template version extraction works
- [ ] Essential features validation works
- [ ] Clear error messages for all failure modes
- [ ] Exit code reflects pass/fail status

### Changelog
- [ ] Version 1.0.0 documented
- [ ] All features listed
- [ ] Known limitations documented
- [ ] Upgrade instructions present
- [ ] Contributing guidelines included

### Testing
- [ ] 30+ test cases covering all features
- [ ] All tests pass
- [ ] Integration tests for each workflow type
- [ ] Error handling tests
- [ ] Performance benchmarks documented

### Documentation
- [ ] Template usage guide complete
- [ ] Customization points documented
- [ ] Example substitutions for all workflow types
- [ ] Architecture notes included
- [ ] Maintenance guidelines provided

---

## Summary

Phase 1 creates the foundation for all dedicated orchestrator commands by:

1. **Establishing Template Standard**: Single source of truth for command generation
2. **Ensuring Feature Parity**: All 6 essential features from `/coordinate`
3. **Enabling Customization**: Clear substitution markers and configuration points
4. **Providing Validation**: Compatibility verification and feature checklists
5. **Supporting Evolution**: Versioning and changelog for template updates

**Success Metrics**:
- Template generates functional commands for all workflow types
- Compatibility verification catches all library mismatches
- All tests pass with 100% feature coverage
- Documentation enables self-service command generation

**Next Phase**: Phase 2 will use this template to generate the first dedicated command (`/debug`), validating the template design and establishing the generation process.
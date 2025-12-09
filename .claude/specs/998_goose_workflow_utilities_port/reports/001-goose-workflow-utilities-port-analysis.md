# Goose Workflow Utilities Port - Analysis Report

## Metadata
- **Date**: 2025-12-05
- **Agent**: research-specialist
- **Topic**: Porting Claude Code's /research, /create-plan, /revise, /implement workflows to Goose ecosystem
- **Report Type**: Architecture analysis and migration strategy
- **Parent Research**: /home/benjamin/.config/.claude/specs/996_goose_claude_code_port/reports/001-goose-claude-code-port-research.md

## Executive Summary

This analysis examines porting Claude Code's core workflow commands (/research, /create-plan, /revise, /implement) and their dependencies to the Goose ecosystem. The analysis reveals that while both systems orchestrate AI agent workflows, their architectural paradigms differ significantly: Claude Code uses **bash-orchestrated markdown commands** with hierarchical agent delegation, while Goose uses **YAML recipe templates** with MCP-based tool extensions. A successful port requires transforming bash state machines into recipe retry configurations, converting agent delegation patterns to subrecipes, and reimagining bash libraries as either embedded instructions or custom MCP servers.

**Key Findings**:
1. **Command Structure**: Markdown commands with embedded bash → YAML recipes with instructions
2. **Agent Delegation**: Task tool invocation → Subrecipe calls with parameter passing
3. **State Management**: Bash state files + state machine → Recipe parameters + checkpoints
4. **Hard Barrier Pattern**: Bash verification blocks → Recipe retry with shell validation checks
5. **Library Functions**: 52 bash libraries → Embedded instructions or MCP servers

**Estimated Migration Effort**: 60-80 hours for core workflow utilities (research, planning, implementation)

## Findings

### 1. Command Architecture Comparison

#### Claude Code Command Pattern
```markdown
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description> [--file <path>] [--complexity 1-4]
description: Research and create new implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
---

# /create-plan - Research-and-Plan Workflow Command

## Block 1a: Initial Setup and State Initialization
```bash
# Capture arguments
# Initialize state machine
# Source bash libraries (three-tier pattern)
```

## Block 1b: Research Phase
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent
Task { ... }

## Block 1c: Verification
```bash
# Validate agent output (hard barrier)
```
```

**Key Characteristics**:
- Multi-block bash orchestration with state persistence between blocks
- Hierarchical agent delegation via Task tool
- Explicit hard barriers (pre-calculate path → invoke agent → validate artifact)
- Library sourcing with three-tier pattern (core → workflow → helpers)
- Checkpoint reporting for user feedback

#### Goose Recipe Equivalent

```yaml
version: "2.1"
title: "Create Implementation Plan"
description: "Research and create new implementation plan workflow"

instructions: |
  You are executing a research-and-plan workflow.

  ## Phase 1: Research
  1. Analyze feature requirements: {{ feature_description }}
  2. Search codebase for relevant patterns
  3. Create research report at: {{ research_dir }}/001-{{ topic_slug }}.md

  ## Phase 2: Planning
  1. Read research report from Phase 1
  2. Create implementation plan at: {{ plans_dir }}/001-{{ topic_slug }}-plan.md
  3. Include metadata with research report references

  ## Phase 3: Validation
  Verify both artifacts created and contain required sections.
  Return: PLAN_CREATED: {{ plan_path }}

parameters:
  - key: feature_description
    input_type: string
    requirement: required
  - key: complexity
    input_type: number
    requirement: optional
    default: 3
  - key: topic_slug
    input_type: string
    requirement: optional

extensions:
  - type: stdio
    name: developer
    cmd: goose-developer
    bundled: true
  - type: stdio
    name: filesystem
    cmd: goose-fs
    bundled: true

sub_recipes:
  - name: research-specialist
    path: ./research-specialist.yaml
    parameters:
      report_path: "{{ research_dir }}/001-{{ topic_slug }}.md"
      topic: "{{ feature_description }}"
  - name: plan-architect
    path: ./plan-architect.yaml
    parameters:
      plan_path: "{{ plans_dir }}/001-{{ topic_slug }}-plan.md"
      research_reports: "{{ research_dir }}/*.md"

settings:
  goose_provider: anthropic
  goose_model: claude-sonnet-4-20250514

retry:
  max_retries: 2
  timeout_seconds: 600
  checks:
    - type: shell
      command: "test -f {{ plan_path }} && test $(wc -c < {{ plan_path }}) -gt 500"
  on_failure: "rm -f {{ plan_path }}"

response:
  json_schema:
    type: object
    properties:
      plan_path:
        type: string
      research_reports:
        type: array
        items:
          type: string
    required: [plan_path]
```

**Translation Mapping**:
| Claude Code Element | Goose Equivalent | Complexity |
|---------------------|------------------|------------|
| Frontmatter metadata | YAML recipe fields | Low |
| Bash Block 1 (setup) | `parameters` section | Medium |
| Task tool invocation | `sub_recipes` calls | Medium |
| Bash Block N (verify) | `retry.checks` | Medium |
| State persistence | File-based state + parameters | High |
| Library sourcing | Embedded instructions or MCP | High |

### 2. Agent Delegation Architecture

#### Claude Code Agent Pattern

**Agent Behavioral File** (/home/benjamin/.config/.claude/agents/research-specialist.md):
```markdown
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
description: Specialized in codebase research and report creation
model: sonnet-4.5
---

# Research Specialist Agent

**STEP 1**: Receive and verify report path
**STEP 2**: Create report file FIRST
**STEP 3**: Conduct research and update report
**STEP 4**: Verify and return confirmation

Return: REPORT_CREATED: [path]
```

**Command Invocation Pattern** (/research Block 1d-exec):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Complexity: ${RESEARCH_COMPLEXITY}

    Execute research and return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

#### Goose Subrecipe Equivalent

**Subrecipe File** (.goose/recipes/research-specialist.yaml):
```yaml
version: "2.1"
title: "Research Specialist"
description: "Codebase research and report creation"

instructions: |
  You are a research specialist conducting codebase analysis.

  STEP 1: Verify report path
  - Report Path: {{ report_path }}
  - Verify absolute path format

  STEP 2: Create report file FIRST
  - Use Write tool to create file at {{ report_path }}
  - Include initial structure with metadata

  STEP 3: Conduct research
  - Search codebase for patterns related to: {{ topic }}
  - Use Glob/Grep for file discovery
  - Analyze implementations

  STEP 4: Update report with findings
  - Use Edit tool to populate sections
  - Include file references with line numbers

  STEP 5: Verify completion
  - Check file exists and size >500 bytes
  - Return: REPORT_CREATED: {{ report_path }}

parameters:
  - key: report_path
    input_type: string
    requirement: required
  - key: topic
    input_type: string
    requirement: required
  - key: complexity
    input_type: number
    requirement: optional
    default: 2

extensions:
  - type: stdio
    name: developer
    cmd: goose-developer
    bundled: true
  - type: stdio
    name: filesystem
    cmd: goose-fs
    bundled: true

settings:
  goose_provider: anthropic
  goose_model: claude-sonnet-4-20250514
  temperature: 0.3

retry:
  max_retries: 2
  timeout_seconds: 300
  checks:
    - type: shell
      command: "test -f {{ report_path }} && test $(wc -c < {{ report_path }}) -gt 500"
```

**Parent Recipe Invocation**:
```yaml
sub_recipes:
  - name: research-specialist
    path: ./research-specialist.yaml
    parameters:
      report_path: "{{ research_dir }}/001-analysis.md"
      topic: "{{ feature_description }}"
      complexity: "{{ complexity }}"
```

**Key Differences**:
1. **Behavioral Instructions**: Markdown with imperative language → YAML instructions field
2. **Tool Permissions**: `allowed-tools` frontmatter → `extensions` configuration
3. **Model Selection**: `model` frontmatter → `settings.goose_model`
4. **Invocation**: Task tool prompt → Subrecipe parameter passing
5. **Return Signal**: Text parsing → Response JSON schema (optional)

### 3. State Management Architecture

#### Claude Code State Persistence

**Library**: /home/benjamin/.config/.claude/lib/core/state-persistence.sh
```bash
# Initialize workflow state file
init_workflow_state() {
  local workflow_id="$1"
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"
  cat > "$STATE_FILE" <<EOF
WORKFLOW_ID="$workflow_id"
TIMESTAMP="$(date +%s)"
EOF
  echo "$STATE_FILE"
}

# Append variable to state file
append_workflow_state() {
  local var_name="$1"
  local var_value="$2"
  echo "export ${var_name}=\"${var_value}\"" >> "$STATE_FILE"
}

# Load workflow state
load_workflow_state() {
  local workflow_id="$1"
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"
  source "$STATE_FILE"
}
```

**Usage Pattern** (/create-plan Block 1a):
```bash
WORKFLOW_ID="plan_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Persist variables across blocks
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
```

**Cross-Block Restoration** (/create-plan Block 2):
```bash
# Load state from previous block
load_workflow_state "$WORKFLOW_ID"

# Variables now available
echo "Plan: $PLAN_FILE"
echo "Topic: $TOPIC_PATH"
```

#### Goose State Equivalent

**Approach 1: File-Based State** (closest to Claude Code)
```yaml
instructions: |
  ## State Initialization
  Execute: mkdir -p .goose/tmp/workflow_{{ workflow_id }}

  ## Save State Variables
  Execute: |
    cat > .goose/tmp/workflow_{{ workflow_id }}/state.json <<EOF
    {
      "plan_file": "{{ plan_file }}",
      "topic_path": "{{ topic_path }}",
      "research_dir": "{{ research_dir }}"
    }
    EOF

  ## Load State in Next Phase
  Execute: |
    STATE=$(cat .goose/tmp/workflow_{{ workflow_id }}/state.json)
    PLAN_FILE=$(echo "$STATE" | jq -r '.plan_file')
```

**Approach 2: Recipe Parameters** (recommended)
```yaml
# Parent recipe passes state via parameters
sub_recipes:
  - name: phase-2-planning
    path: ./planning-phase.yaml
    parameters:
      plan_file: "{{ plan_file }}"  # From phase 1
      topic_path: "{{ topic_path }}"
      research_dir: "{{ research_dir }}"
      research_reports: "{{ research_reports }}"  # JSON array
```

**Approach 3: Checkpoint Files** (for workflow resumption)
```yaml
retry:
  checkpoint_file: ".goose/checkpoints/workflow_{{ workflow_id }}.json"
  on_checkpoint:
    - "Save current state: plan_file, completed_phases, next_phase"
  on_resume:
    - "Load checkpoint and continue from next_phase"
```

**State Management Comparison**:
| Aspect | Claude Code | Goose Equivalent |
|--------|-------------|------------------|
| State Storage | Bash source files (.sh) | JSON files or parameters |
| State Scope | Workflow-level (single file) | Recipe-level (parameter passing) |
| Cross-Block Access | `source $STATE_FILE` | Read JSON or parameter inheritance |
| Persistence | Temp directory (.claude/tmp/) | Checkpoints (.goose/checkpoints/) |
| Restoration | Automatic via sourcing | Manual JSON parsing or recipe params |

### 4. Hard Barrier Pattern Implementation

#### Claude Code Hard Barrier Architecture

The hard barrier pattern enforces subagent artifact creation through three sequential blocks:

**Block 1d: Pre-Calculate Path** (/research command):
```bash
# BEFORE agent invocation - calculate exact output path
REPORT_NUMBER="001"
REPORT_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Validate path is absolute
if [[ "$REPORT_PATH" =~ ^/ ]]; then
  : # OK
else
  echo "ERROR: Path not absolute"
  exit 1
fi

# Persist for next blocks
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
```

**Block 1d-exec: Agent Invocation with Contract**:
```markdown
Task {
  prompt: "
    **CRITICAL**: You MUST create report at EXACT path: ${REPORT_PATH}
    The orchestrator has pre-calculated this path and will validate after you return.
    Do NOT derive your own path.
  "
}
```

**Block 1e: Validation (Hard Barrier)**:
```bash
# AFTER agent returns - verify artifact exists
if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: HARD BARRIER FAILED - Report not found at: $REPORT_PATH"
  echo "Agent did not create expected artifact"
  exit 1
fi

# Validate size
if [ "$(wc -c < "$REPORT_PATH")" -lt 100 ]; then
  echo "ERROR: Report too small"
  exit 1
fi

echo "✓ Hard barrier passed - report validated"
```

#### Goose Hard Barrier Equivalent

**Recipe Retry with Shell Validation**:
```yaml
instructions: |
  ## Phase 1: Pre-Calculate Path
  Calculate report path:
  - Directory: {{ research_dir }}
  - Number: 001
  - Slug: {{ topic | slugify }}
  - Full path: {{ research_dir }}/001-{{ topic | slugify }}.md

  ## Phase 2: Create Report
  Use Write tool to create report at calculated path.
  Include metadata, executive summary, findings sections.

  ## Phase 3: Verification
  The retry configuration will validate the file was created.

retry:
  max_retries: 2
  timeout_seconds: 300
  checks:
    - type: shell
      command: |
        test -f {{ research_dir }}/001-{{ topic | slugify }}.md && \
        test $(wc -c < {{ research_dir }}/001-{{ topic | slugify }}.md) -gt 100
      error_message: "Hard barrier failed: Report not created or too small"
  on_failure: |
    echo "Cleaning up incomplete artifact..."
    rm -f {{ research_dir }}/001-{{ topic | slugify }}.md
```

**Key Mapping**:
| Claude Code Block | Goose Equivalent | Notes |
|-------------------|------------------|-------|
| Block N-1 (pre-calc) | `instructions` path calculation | Use template vars |
| Block N (invoke) | `instructions` or `sub_recipes` | Natural language or subrecipe |
| Block N+1 (validate) | `retry.checks` shell commands | Automatic validation |

**Advantages of Goose Approach**:
1. **Declarative validation**: Shell checks in YAML vs bash blocks
2. **Automatic retry**: Built-in retry logic vs manual error handling
3. **Cleaner separation**: Validation config separate from instructions
4. **Cleanup automation**: `on_failure` hooks for cleanup

**Limitations**:
1. **Less granular error messages**: Shell check output vs custom bash diagnostics
2. **Limited error context**: Cannot log to custom error file as easily
3. **No intermediate checkpoints**: Claude Code has explicit checkpoint reporting

### 5. Bash Library Dependencies

Claude Code relies on 52 bash libraries across 4 tiers. Analysis of critical dependencies:

#### Tier 1: Critical Foundation (Fail-Fast Required)

**error-handling.sh** (Lines: 450):
- `setup_bash_error_trap()`: ERR trap with logging
- `log_command_error()`: JSONL error logging
- `ensure_error_log_exists()`: Log file initialization
- `_source_with_diagnostics()`: Library loading wrapper

**Goose Migration**: Embed error handling in instructions
```yaml
instructions: |
  ## Error Handling
  If any step fails:
  1. Log error to: .goose/tmp/errors.jsonl
     Format: {"timestamp":"","command":"","error":"","details":{}}
  2. Clean up partial artifacts
  3. Return error signal: ERROR: [type] - [message]
```

**state-persistence.sh** (Lines: 380):
- `init_workflow_state()`: Create state file
- `append_workflow_state()`: Add variable to state
- `load_workflow_state()`: Restore state from file
- `save_completed_states_to_state()`: Persist state transitions

**Goose Migration**: Use JSON state files
```yaml
instructions: |
  ## State Management
  Save state: echo '{"plan_file":"{{ plan_file }}"}' > .goose/tmp/state.json
  Load state: STATE=$(cat .goose/tmp/state.json)
  Extract: PLAN_FILE=$(echo "$STATE" | jq -r '.plan_file')
```

**workflow-state-machine.sh** (Lines: 620):
- `sm_init()`: Initialize state machine
- `sm_transition()`: Validate and transition states
- `sm_current_state()`: Get current state
- Enforces valid state transitions (research → plan → implement → test → complete)

**Goose Migration**: Embed state validation in instructions
```yaml
instructions: |
  ## State Machine Validation
  Current state: {{ current_state }}
  Valid transitions: {{ valid_next_states }}

  Before transitioning to {{ next_state }}:
  1. Validate transition is allowed from {{ current_state }}
  2. Update state file: echo "{{ next_state }}" > .goose/tmp/current_state.txt
  3. Proceed to next phase
```

#### Tier 2: Workflow Support

**workflow-initialization.sh** (Lines: 280):
- `initialize_workflow_paths()`: Create topic directories
- `create_topic_artifact()`: Generate artifact paths
- Topic-based directory structure (specs/{NNN_topic}/)

**Goose Migration**: Shell commands in instructions
```yaml
instructions: |
  ## Initialize Workflow Paths
  Execute:
    TOPIC_NUM=$(find .claude/specs -name '[0-9]*_*' | wc -l | xargs -I{} expr {} + 1)
    TOPIC_NUM_PADDED=$(printf "%03d" $TOPIC_NUM)
    TOPIC_SLUG=$(echo "{{ topic }}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
    TOPIC_PATH=".claude/specs/${TOPIC_NUM_PADDED}_${TOPIC_SLUG}"
    mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug}
```

**checkpoint-utils.sh** (Lines: 195):
- `save_checkpoint()`: Save workflow checkpoint
- `load_checkpoint()`: Resume from checkpoint
- `delete_checkpoint()`: Clean up checkpoint

**Goose Migration**: Built-in retry checkpoint
```yaml
retry:
  checkpoint_file: ".goose/checkpoints/{{ workflow_id }}.json"
  checkpoint_interval: 300  # Save every 5 minutes
```

**validation-utils.sh** (Lines: 340):
- `validate_agent_artifact()`: Check file exists, minimum size
- `validate_state_restoration()`: Verify variables restored
- `validate_directory_var()`: Check directory exists

**Goose Migration**: Shell validation in retry checks
```yaml
retry:
  checks:
    - type: shell
      command: |
        test -f {{ artifact_path }} && \
        test $(wc -c < {{ artifact_path }}) -gt {{ min_size }} && \
        test -d {{ directory_path }}
```

#### Tier 3: Command-Specific Utilities

**checkbox-utils.sh** (Lines: 485):
- `mark_phase_complete()`: Mark checkboxes in plan
- `verify_phase_complete()`: Check all tasks done
- `add_complete_marker()`: Add [COMPLETE] to phase heading
- `check_all_phases_complete()`: Validate entire plan

**Goose Migration**: External script or MCP server
```yaml
extensions:
  - type: stdio
    name: plan-manager
    cmd: node
    args: ["./mcp-servers/plan-manager/index.js"]
    timeout: 30

instructions: |
  ## Mark Phase Complete
  Use plan-manager extension:
  - mark_phase_complete: {{ plan_file }}, phase: {{ phase_num }}
  - verify_all_complete: {{ plan_file }}
```

**standards-extraction.sh** (Lines: 290):
- `format_standards_for_prompt()`: Extract CLAUDE.md sections
- Parses markdown sections, formats for agent prompts

**Goose Migration**: .goosehints files
```yaml
# .goosehints in project root (equivalent to CLAUDE.md)
# Automatically loaded by Goose
# No extraction needed - entire file available to recipes
```

**complexity-utils.sh** (Lines: 175):
- `calculate_complexity()`: Estimate project complexity
- Used by plan-architect for tier selection

**Goose Migration**: Embed calculation in recipe
```yaml
instructions: |
  ## Complexity Calculation
  Calculate score:
  - Base: {{ feature_type }} (new=10, enhance=7, refactor=5, fix=3)
  - Tasks: {{ estimated_tasks }} / 2
  - Files: {{ estimated_files }} * 3
  - Integrations: {{ integrations }} * 5
  - Total: {{ score }}

  Select tier:
  - <50: Tier 1 (single file)
  - 50-200: Tier 2 (phase directory)
  - ≥200: Tier 3 (hierarchical)
```

### 6. Workflow-Specific Migration Analysis

#### /research Command Port

**Claude Code Structure** (Lines: 1289):
- 7 sequential bash blocks with state persistence
- Hard barrier pattern (pre-calc → invoke → validate)
- Topic naming via LLM agent
- Research specialist delegation
- Artifact validation

**Goose Recipe Structure**:
```yaml
version: "2.1"
title: "Research Workflow"
description: "Research a topic and create comprehensive analysis report"

instructions: |
  ## Phase 1: Topic Naming
  Generate topic slug from: {{ topic }}
  - Lowercase, underscores, 5-40 chars
  - Example: "authentication patterns" → "authentication_patterns"

  ## Phase 2: Path Setup
  Create directory structure:
  - Topic dir: .claude/specs/{{ topic_num }}_{{ topic_slug }}
  - Reports dir: .claude/specs/{{ topic_num }}_{{ topic_slug }}/reports
  - Report path: .claude/specs/{{ topic_num }}_{{ topic_slug }}/reports/001-analysis.md

  ## Phase 3: Research
  Invoke research-specialist subrecipe with:
  - report_path: {{ report_path }}
  - topic: {{ topic }}
  - complexity: {{ complexity }}

  ## Phase 4: Validation
  Retry configuration will validate report created.

parameters:
  - key: topic
    input_type: string
    requirement: required
  - key: complexity
    input_type: number
    default: 2

sub_recipes:
  - name: topic-naming-agent
    path: ./topic-naming.yaml
    parameters:
      description: "{{ topic }}"
  - name: research-specialist
    path: ./research-specialist.yaml
    parameters:
      report_path: "{{ report_path }}"
      topic: "{{ topic }}"

retry:
  max_retries: 2
  checks:
    - type: shell
      command: "test -f {{ report_path }} && test $(wc -c < {{ report_path }}) -gt 500"
```

**Migration Complexity**: Medium (16-24 hours)
- Topic naming: Convert LLM agent to subrecipe
- Directory setup: Embed shell commands in instructions
- Research delegation: Direct subrecipe mapping
- Validation: Use retry.checks

#### /create-plan Command Port

**Claude Code Structure** (Lines: 1970):
- 11 sequential bash blocks
- Research phase → Planning phase → Verification
- Two agent invocations (research-specialist, plan-architect)
- Standards extraction and injection
- Phase 0 divergence detection

**Goose Recipe Structure**:
```yaml
version: "2.1"
title: "Create Implementation Plan"
description: "Research and plan workflow"

instructions: |
  ## Phase 1: Research
  Invoke research-specialist to create:
  - Research report at {{ research_dir }}/001-analysis.md

  ## Phase 2: Extract Standards
  Read .goosehints file (auto-loaded by Goose)
  Extract planning-relevant sections:
  - Code Standards
  - Testing Protocols
  - Documentation Policy

  ## Phase 3: Planning
  Invoke plan-architect with:
  - Research reports from Phase 1
  - Standards from .goosehints
  - Create plan at {{ plans_dir }}/001-plan.md

  ## Phase 4: Divergence Detection
  Check if plan includes Phase 0 (Standards Revision)
  If yes: Display warning about standards changes

sub_recipes:
  - name: research-specialist
    path: ./research-specialist.yaml
  - name: plan-architect
    path: ./plan-architect.yaml
    parameters:
      research_reports: "{{ research_reports }}"
      standards_content: "{{ standards }}"

retry:
  checks:
    - type: shell
      command: "test -f {{ plan_path }}"
```

**Migration Complexity**: Medium-High (24-32 hours)
- Two-phase orchestration: Sequential subrecipes
- Standards injection: .goosehints auto-loading
- Phase 0 detection: Post-processing in instructions
- Metadata validation: Shell commands or MCP server

#### /revise Command Port

**Claude Code Structure** (Lines: 1400):
- Plan revision via Edit tool (not Write)
- Backup creation before modification
- Research phase for new insights
- Plan-architect in revision mode
- Diff validation (plan must differ from backup)

**Goose Recipe Structure**:
```yaml
version: "2.1"
title: "Revise Plan Workflow"
description: "Research and revise existing implementation plan"

instructions: |
  ## Phase 1: Backup
  Create backup of existing plan:
  - Source: {{ existing_plan_path }}
  - Backup: {{ plans_dir }}/backups/{{ timestamp }}_backup.md

  ## Phase 2: Research Revision Insights
  Invoke research-specialist for new insights:
  - Topic: {{ revision_details }}
  - Report: {{ research_dir }}/revision_{{ num }}.md

  ## Phase 3: Plan Revision
  Invoke plan-architect in revision mode:
  - Operation: "revision"
  - Existing plan: {{ existing_plan_path }}
  - Research: {{ research_reports }}
  - Use Edit tool (not Write)

  ## Phase 4: Validation
  Verify plan was modified:
  - Compare with backup using: cmp -s {{ backup }} {{ plan }}
  - If identical: ERROR
  - If different: SUCCESS

parameters:
  - key: existing_plan_path
    input_type: string
    requirement: required
  - key: revision_details
    input_type: string
    requirement: required

sub_recipes:
  - name: research-specialist
    path: ./research-specialist.yaml
  - name: plan-architect
    path: ./plan-architect.yaml
    parameters:
      operation_mode: "revision"
      existing_plan: "{{ existing_plan_path }}"
      backup_path: "{{ backup_path }}"

retry:
  checks:
    - type: shell
      command: |
        ! cmp -s {{ backup_path }} {{ existing_plan_path }} && \
        test -f {{ existing_plan_path }}
      error_message: "Plan not modified or missing"
```

**Migration Complexity**: Medium (20-28 hours)
- Backup logic: Shell commands in instructions
- Revision mode detection: Recipe parameters
- Edit tool enforcement: Agent instructions
- Diff validation: Shell validation check

#### /implement Command Port

**Claude Code Structure** (Lines: 1566):
- Wave-based parallel execution (via implementer-coordinator)
- Iteration loop for large plans (max_iterations, continuation_context)
- Checkpoint creation and resumption
- Phase marker management ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])
- Hard barrier with summary validation

**Goose Recipe Structure**:
```yaml
version: "2.1"
title: "Implementation Workflow"
description: "Execute implementation plan with iteration support"

instructions: |
  ## Iteration Loop Management
  Current iteration: {{ iteration }} / {{ max_iterations }}

  ## Phase Execution
  For each phase in plan (starting at {{ starting_phase }}):
  1. Mark phase [IN PROGRESS]
  2. Execute phase tasks
  3. Mark phase [COMPLETE] when all tasks done

  ## Context Management
  If context usage > {{ context_threshold }}%:
  - Create checkpoint at .goose/checkpoints/implement_{{ workflow_id }}.json
  - Save: plan_path, completed_phases, next_phase, iteration
  - Return: requires_continuation=true

  ## Summary Creation
  After completing phases or context exhaustion:
  - Create summary at {{ summaries_dir }}/implementation_summary.md
  - Include: work status, completed phases, testing strategy
  - Return: IMPLEMENTATION_COMPLETE

parameters:
  - key: plan_file
    input_type: string
    requirement: required
  - key: starting_phase
    input_type: number
    default: 1
  - key: max_iterations
    input_type: number
    default: 5
  - key: context_threshold
    input_type: number
    default: 90

sub_recipes:
  - name: implementer-coordinator
    path: ./implementer-coordinator.yaml
    parameters:
      plan_path: "{{ plan_file }}"
      starting_phase: "{{ starting_phase }}"
      iteration: "{{ iteration }}"
      continuation_context: "{{ continuation_context }}"

retry:
  checkpoint_file: ".goose/checkpoints/implement_{{ workflow_id }}.json"
  max_retries: 2
  checks:
    - type: shell
      command: |
        test -f {{ summaries_dir }}/implementation_summary.md && \
        test $(wc -c < {{ summaries_dir }}/implementation_summary.md) -gt 500
```

**Iteration Loop Implementation**:
```yaml
# Goose doesn't have built-in iteration loops
# Workaround: External script or manual re-invocation

# Option 1: Shell script wrapper
#!/bin/bash
ITERATION=1
MAX_ITERATIONS=5
while [ $ITERATION -le $MAX_ITERATIONS ]; do
  goose run --recipe implement.yaml \
    --params iteration=$ITERATION \
    --params continuation_context=.goose/tmp/iter_$((ITERATION-1)).md

  # Check if continuation needed
  REQUIRES_CONT=$(jq -r '.requires_continuation' .goose/tmp/response.json)
  [ "$REQUIRES_CONT" = "false" ] && break

  ITERATION=$((ITERATION + 1))
done

# Option 2: MCP server for orchestration
# Custom MCP server that manages iteration loop
```

**Migration Complexity**: High (32-40 hours)
- Iteration loop: External orchestration wrapper
- Phase markers: MCP server or embedded shell commands
- Checkpoint/resume: Use Goose built-in checkpoints
- Context estimation: Recipe instructions + shell monitoring

### 7. Library Migration Strategy

**52 Bash Libraries** categorized by migration approach:

#### Category A: Embed in Recipe Instructions (22 libraries)
Simple utilities that can be expressed as inline shell commands or natural language instructions.

Examples:
- `timestamp-utils.sh`: Date formatting → `Execute: date +%Y-%m-%d`
- `detect-project-dir.sh`: Find .claude/ directory → Template variable `{{ project_dir }}`
- `argument-capture.sh`: Parse CLI args → Recipe `parameters` section
- `summary-formatting.sh`: Format output → Instructions text formatting

**Migration**: Copy logic into `instructions` field as shell commands or natural language.

#### Category B: Convert to MCP Servers (15 libraries)
Complex stateful utilities that benefit from dedicated tool interfaces.

Examples:
- `checkbox-utils.sh`: Plan phase management → MCP server with tools:
  - `mark_phase_complete(plan_path, phase_num)`
  - `verify_phase_complete(plan_path, phase_num)`
  - `check_all_phases_complete(plan_path)`
- `workflow-state-machine.sh`: State validation → MCP server with tools:
  - `sm_init(description, workflow_type)`
  - `sm_transition(target_state)`
  - `sm_current_state()`
- `standards-extraction.sh`: CLAUDE.md parsing → Not needed (use .goosehints)

**Migration**: Build Node.js or Python MCP servers, add to recipe `extensions`.

**Example MCP Server** (plan-manager):
```javascript
// mcp-servers/plan-manager/index.js
import { MCPServer, Tool } from '@anthropic-ai/mcp';

const server = new MCPServer({
  name: 'plan-manager',
  version: '1.0.0',
  tools: [
    new Tool({
      name: 'mark_phase_complete',
      description: 'Mark all tasks in a phase as complete',
      inputSchema: {
        type: 'object',
        properties: {
          plan_path: { type: 'string' },
          phase_num: { type: 'number' }
        }
      },
      handler: async ({ plan_path, phase_num }) => {
        // Read plan file
        const plan = await fs.readFile(plan_path, 'utf8');
        // Find phase section, mark checkboxes
        const updated = plan.replace(...);
        await fs.writeFile(plan_path, updated);
        return { success: true };
      }
    }),
    // Additional tools...
  ]
});

server.listen();
```

**Recipe Integration**:
```yaml
extensions:
  - type: stdio
    name: plan-manager
    cmd: node
    args: ["./mcp-servers/plan-manager/index.js"]

instructions: |
  Use plan-manager extension to update phase status:
  - mark_phase_complete: {{ plan_file }}, phase: 3
```

#### Category C: Deprecate/Replace with Goose Built-ins (8 libraries)
Functionality provided natively by Goose.

Examples:
- `error-handling.sh`: Bash error traps → Goose built-in error handling
- `checkpoint-utils.sh`: Checkpoint save/load → `retry.checkpoint_file`
- `unified-logger.sh`: Logging → Goose native logging (`goose logs`)

**Migration**: Remove, use Goose equivalents.

#### Category D: Requires Architectural Redesign (7 libraries)
Core orchestration logic tightly coupled to Claude Code's architecture.

Examples:
- `workflow-initialization.sh`: Multi-block state setup → Recipe parameter initialization
- `barrier-utils.sh`: Hard barrier verification → `retry.checks`
- `validation-utils.sh`: Agent artifact validation → Shell validation checks

**Migration**: Redesign using recipe-native patterns (parameters, checks, subrecipes).

**Summary Table**:
| Category | Count | Migration Approach | Effort |
|----------|-------|-------------------|--------|
| A: Embed in instructions | 22 | Copy as shell/text | Low |
| B: Convert to MCP servers | 15 | Build Node/Python MCP | High |
| C: Use Goose built-ins | 8 | Remove, use native | Low |
| D: Architectural redesign | 7 | Redesign with recipes | Medium |

### 8. Hard Barrier Pattern Migration

The hard barrier pattern is central to Claude Code's agent delegation architecture. It enforces artifact creation through three components:

**Claude Code Pattern**:
1. **Pre-calculation**: Calculate exact output path before agent invocation
2. **Contract**: Pass path to agent as explicit requirement
3. **Validation**: Verify artifact exists after agent returns

**Example** (/research Block 1d-1e):
```bash
# Block 1d: Pre-calculate
REPORT_PATH="${RESEARCH_DIR}/001-${TOPIC_SLUG}.md"
append_workflow_state "REPORT_PATH" "$REPORT_PATH"

# Block 1d-exec: Contract
Task {
  prompt: "**CRITICAL**: Create report at EXACT path: ${REPORT_PATH}"
}

# Block 1e: Validate
if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: HARD BARRIER FAILED"
  exit 1
fi
```

**Goose Equivalent**:
```yaml
instructions: |
  ## Pre-Calculate Path
  Report path: {{ research_dir }}/001-{{ topic_slug }}.md

  ## Create Report
  Use Write tool to create report at calculated path.

  ## Validation
  The retry configuration will verify file creation.

retry:
  max_retries: 2
  checks:
    - type: shell
      command: "test -f {{ research_dir }}/001-{{ topic_slug }}.md"
      error_message: "Hard barrier failed: Report not created"
  on_failure: "rm -f {{ research_dir }}/001-{{ topic_slug }}.md"
```

**Key Differences**:
1. **Pre-calculation**: Bash variable → Template variable
2. **Contract**: Task prompt → Recipe instructions
3. **Validation**: Bash block with exit → `retry.checks` with automatic retry

**Benefits of Goose Approach**:
- Declarative validation (YAML vs bash)
- Automatic retry logic
- Cleaner separation of concerns
- Built-in cleanup hooks

**Limitations**:
- Less granular error diagnostics
- Cannot customize per-failure behavior as easily
- No intermediate checkpoint reporting

### 9. Recommended Migration Roadmap

#### Phase 1: Foundation Setup (8-12 hours)
**Goal**: Establish Goose project structure and core utilities

**Tasks**:
1. Create `.goose/` directory structure
   ```
   .goose/
     recipes/
       research-specialist.yaml
       plan-architect.yaml
       implementer-coordinator.yaml
     mcp-servers/
       plan-manager/
       state-machine/
   ```

2. Create `.goosehints` from CLAUDE.md
   - Convert CLAUDE.md sections to .goosehints format
   - Test auto-loading in recipes

3. Build foundational MCP servers
   - `plan-manager`: Phase marker management (checkbox-utils.sh)
   - `state-machine`: State validation (workflow-state-machine.sh subset)

4. Test recipe parameter passing
   - Create minimal recipe
   - Pass parameters between parent and subrecipe
   - Verify parameter inheritance

**Deliverables**:
- `.goose/` structure created
- `.goosehints` file with standards
- 2 MCP servers (plan-manager, state-machine)
- Parameter passing test recipe

#### Phase 2: Research Workflow (12-16 hours)
**Goal**: Port /research command as Goose recipe

**Tasks**:
1. Create `research.yaml` parent recipe
   - Parameter definitions (topic, complexity)
   - Topic slug generation in instructions
   - Directory initialization (specs/NNN_topic/)

2. Create `research-specialist.yaml` subrecipe
   - Port research-specialist.md behavioral guidelines
   - Implement hard barrier (retry.checks)
   - Test report creation

3. Create `topic-naming.yaml` subrecipe
   - Port topic-naming-agent.md logic
   - Generate semantic directory names
   - Validate naming format

4. Integration testing
   - Test full research workflow
   - Verify artifact creation
   - Validate hard barrier enforcement

**Deliverables**:
- `research.yaml` recipe
- `research-specialist.yaml` subrecipe
- `topic-naming.yaml` subrecipe
- Integration tests passing

#### Phase 3: Planning Workflow (16-24 hours)
**Goal**: Port /create-plan command with two-phase orchestration

**Tasks**:
1. Create `create-plan.yaml` parent recipe
   - Research phase invocation (use research-specialist subrecipe)
   - Planning phase invocation (plan-architect)
   - Standards injection from .goosehints

2. Create `plan-architect.yaml` subrecipe
   - Port plan-architect.md behavioral guidelines
   - Complexity calculation in instructions
   - Tier selection logic
   - Metadata generation
   - Phase 0 divergence detection

3. Build plan metadata validation
   - MCP server or shell validation
   - Check required fields (Date, Feature, Status, etc.)
   - Validate research report references

4. Test two-phase orchestration
   - Research → Planning flow
   - State passing between phases
   - Artifact validation

**Deliverables**:
- `create-plan.yaml` recipe
- `plan-architect.yaml` subrecipe
- Plan metadata validation tool
- Two-phase orchestration tests

#### Phase 4: Revision Workflow (12-16 hours)
**Goal**: Port /revise command with backup and Edit tool usage

**Tasks**:
1. Create `revise.yaml` recipe
   - Backup creation logic
   - Research phase for revision insights
   - Plan revision phase

2. Extend `plan-architect.yaml` for revision mode
   - Add `operation_mode` parameter
   - Enforce Edit tool (not Write)
   - Preserve [COMPLETE] phases

3. Implement diff validation
   - Shell check: plan differs from backup
   - Error if plan unchanged

4. Test revision workflow
   - Create plan
   - Revise plan
   - Verify backup created
   - Validate plan modified

**Deliverables**:
- `revise.yaml` recipe
- Plan-architect revision mode
- Diff validation tests

#### Phase 5: Implementation Workflow (24-32 hours)
**Goal**: Port /implement command with iteration support

**Tasks**:
1. Create `implement.yaml` recipe
   - Phase marker management integration
   - Checkpoint creation
   - Summary validation

2. Create `implementer-coordinator.yaml` subrecipe
   - Port implementer-coordinator.md logic
   - Wave-based parallelization (if feasible in Goose)
   - Iteration management

3. Build iteration orchestration wrapper
   - External shell script for iteration loop
   - Or custom MCP server for orchestration
   - Checkpoint save/resume

4. Integrate plan-manager MCP server
   - Phase marker updates
   - Progress tracking
   - Completion verification

5. Test large plan implementation
   - Multi-iteration workflow
   - Checkpoint/resume
   - Phase marker updates

**Deliverables**:
- `implement.yaml` recipe
- `implementer-coordinator.yaml` subrecipe
- Iteration orchestration wrapper
- Large plan tests

#### Phase 6: Integration & Testing (16-24 hours)
**Goal**: End-to-end testing and documentation

**Tasks**:
1. Integration test suite
   - Full workflow: research → plan → implement
   - Revision workflow: plan → revise → implement
   - Edge cases: errors, retries, checkpoints

2. Documentation
   - Recipe usage guides
   - MCP server API docs
   - Migration notes from Claude Code

3. Performance optimization
   - Reduce MCP server latency
   - Optimize shell command execution
   - Minimize recipe invocation overhead

4. User experience improvements
   - Better error messages
   - Progress indicators
   - Completion signals

**Deliverables**:
- Integration test suite
- User documentation
- Performance benchmarks
- Migration guide

**Total Estimated Effort**: 88-124 hours (11-15.5 days at 8 hours/day)

### 10. Key Challenges and Mitigation Strategies

#### Challenge 1: Iteration Loop Architecture

**Problem**: Goose recipes don't have built-in iteration loops. Claude Code's /implement uses a while loop to handle large plans across multiple iterations.

**Claude Code Pattern**:
```bash
ITERATION=1
while [ $ITERATION -le $MAX_ITERATIONS ]; do
  # Invoke implementer-coordinator
  # Check requires_continuation signal
  # Break if work complete
  ITERATION=$((ITERATION + 1))
done
```

**Mitigation Options**:

**Option A: External Orchestration Script** (Recommended)
```bash
#!/bin/bash
# goose-implement-orchestrator.sh
ITERATION=1
MAX_ITERATIONS=${MAX_ITERATIONS:-5}
PLAN_FILE=$1

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "Iteration $ITERATION/$MAX_ITERATIONS"

  goose run --recipe .goose/recipes/implement.yaml \
    --params plan_file="$PLAN_FILE" \
    --params iteration=$ITERATION \
    --params continuation_context=".goose/tmp/iter_$((ITERATION-1)).json"

  # Parse response
  REQUIRES_CONT=$(jq -r '.requires_continuation' .goose/tmp/response.json)
  [ "$REQUIRES_CONT" = "false" ] && break

  ITERATION=$((ITERATION + 1))
done
```

**Option B: Recursive Subrecipe**
```yaml
# implement.yaml
sub_recipes:
  - name: implementer-coordinator
    path: ./implementer-coordinator.yaml
  - name: implement-next-iteration
    path: ./implement.yaml  # Self-reference
    condition: "{{ requires_continuation }} == true"
    parameters:
      iteration: "{{ iteration + 1 }}"
```

**Option C: Custom MCP Server**
```javascript
// Orchestration MCP server
new Tool({
  name: 'implement_with_iterations',
  handler: async ({ plan_file, max_iterations }) => {
    for (let i = 1; i <= max_iterations; i++) {
      const result = await invokeGooseRecipe('implement.yaml', {
        iteration: i,
        continuation_context: await loadContext(i - 1)
      });
      if (!result.requires_continuation) break;
    }
  }
})
```

**Recommendation**: Use Option A (external script) for simplicity and transparency.

#### Challenge 2: Bash Library Migration Effort

**Problem**: 52 bash libraries represent significant porting effort. Not all can be directly translated to Goose patterns.

**Mitigation Strategy**:

**Prioritization Matrix**:
| Library | Usage Frequency | Complexity | Migration Priority |
|---------|----------------|------------|-------------------|
| state-persistence.sh | High | Medium | Critical |
| workflow-state-machine.sh | High | High | Critical |
| checkbox-utils.sh | High | Medium | High |
| error-handling.sh | High | Low | Medium (use Goose native) |
| validation-utils.sh | Medium | Low | Medium |
| timestamp-utils.sh | Low | Low | Low (inline) |

**Phased Approach**:
1. **Phase 1**: Migrate critical libraries (state-persistence, workflow-state-machine) as MCP servers
2. **Phase 2**: Embed medium-priority libraries as inline instructions
3. **Phase 3**: Deprecate low-priority libraries, use Goose built-ins
4. **Phase 4**: Optimize MCP servers for performance

**Library Consolidation**:
- Combine related utilities into single MCP servers
  - Example: `plan-manager` MCP combines checkbox-utils.sh + complexity-utils.sh + plan validation
- Reduce total MCP server count from potential 15 to 5-6 core servers

#### Challenge 3: Hard Barrier Enforcement Without Bash Blocks

**Problem**: Claude Code's hard barrier uses sequential bash blocks (pre-calc → invoke → validate). Goose recipes execute as single instructions block.

**Mitigation**:

**Approach 1: Retry Configuration** (Recommended)
```yaml
retry:
  checks:
    - type: shell
      command: "test -f {{ artifact_path }} && test $(wc -c < {{ artifact_path }}) -gt {{ min_size }}"
      error_message: "Hard barrier failed: {{ artifact_type }} not created"
  on_failure: "rm -f {{ artifact_path }}"
```

**Approach 2: MCP Server Validation**
```yaml
extensions:
  - type: stdio
    name: artifact-validator
    cmd: node
    args: ["./mcp-servers/artifact-validator/index.js"]

instructions: |
  After creating artifact:
  Use artifact-validator extension:
  - validate_artifact: {{ artifact_path }}, min_size: 500
  - If validation fails: Return ERROR
```

**Approach 3: Subrecipe Chaining**
```yaml
sub_recipes:
  - name: pre-calculate-path
    path: ./path-calculator.yaml
    output: artifact_path
  - name: create-artifact
    path: ./artifact-creator.yaml
    parameters:
      artifact_path: "{{ pre_calculate_path.artifact_path }}"
  - name: validate-artifact
    path: ./artifact-validator.yaml
    parameters:
      artifact_path: "{{ pre_calculate_path.artifact_path }}"
```

**Recommendation**: Use Approach 1 (retry configuration) for simplicity. Add Approach 2 (MCP validation) for complex artifacts.

#### Challenge 4: State Persistence Between Recipe Invocations

**Problem**: Claude Code persists state via bash files sourced in each block. Goose recipes are stateless templates.

**Mitigation**:

**Approach 1: JSON State Files**
```yaml
instructions: |
  ## Save State
  Execute: |
    cat > .goose/tmp/state_{{ workflow_id }}.json <<EOF
    {
      "plan_file": "{{ plan_file }}",
      "topic_path": "{{ topic_path }}",
      "completed_phases": [1, 2, 3]
    }
    EOF

  ## Load State (in next recipe invocation)
  Execute: |
    STATE=$(cat .goose/tmp/state_{{ workflow_id }}.json)
    PLAN_FILE=$(echo "$STATE" | jq -r '.plan_file')
```

**Approach 2: Recipe Parameter Passing**
```yaml
# Parent recipe
sub_recipes:
  - name: phase-1
    path: ./phase-1.yaml
  - name: phase-2
    path: ./phase-2.yaml
    parameters:
      plan_file: "{{ phase_1.plan_file }}"  # Pass output from phase 1
      topic_path: "{{ phase_1.topic_path }}"
```

**Approach 3: Checkpoint Files**
```yaml
retry:
  checkpoint_file: ".goose/checkpoints/{{ workflow_id }}.json"
  on_checkpoint:
    - "Save: plan_file, topic_path, completed_phases"
```

**Recommendation**: Use Approach 2 (parameter passing) for simple workflows, Approach 1 (JSON files) for complex state, Approach 3 (checkpoints) for resumability.

#### Challenge 5: Agent Behavioral Guidelines Translation

**Problem**: Claude Code uses markdown behavioral files (.claude/agents/*.md) with imperative instructions. Goose uses YAML `instructions` field with natural language.

**Mitigation**:

**Translation Pattern**:

**Claude Code** (research-specialist.md):
```markdown
# Research Specialist Agent

**STEP 1**: Receive and verify report path
**STEP 2**: Create report file FIRST
**STEP 3**: Conduct research and update report
**STEP 4**: Verify and return confirmation

Return: REPORT_CREATED: [path]
```

**Goose Equivalent** (research-specialist.yaml):
```yaml
instructions: |
  You are a research specialist conducting codebase analysis.

  STEP 1: Verify Report Path
  - Received path: {{ report_path }}
  - Validate path is absolute (starts with /)

  STEP 2: Create Report File FIRST
  - Use Write tool to create file at {{ report_path }}
  - Include metadata section with date, agent, topic
  - Add placeholder sections: Executive Summary, Findings, Recommendations

  STEP 3: Conduct Research
  - Search codebase using Glob/Grep for patterns
  - Analyze relevant files
  - Use Edit tool to populate report sections

  STEP 4: Verify Completion
  - Check file exists: test -f {{ report_path }}
  - Verify size >500 bytes
  - Return completion signal: REPORT_CREATED: {{ report_path }}

  If any step fails, return: ERROR: [type] - [message]
```

**Key Differences**:
- **Imperative language preserved**: "STEP 1", "Use Write tool"
- **Template variables**: Replace bash `$REPORT_PATH` with `{{ report_path }}`
- **Tool references explicit**: "Use Write tool", "Use Edit tool"
- **Return signals defined**: "REPORT_CREATED: {{ report_path }}"

**Conversion Checklist**:
- [ ] Convert ALL CAPS sections to readable headings
- [ ] Replace bash variables with template variables
- [ ] Preserve step-by-step structure
- [ ] Keep imperative tone ("YOU MUST", "DO NOT")
- [ ] Define tool usage explicitly
- [ ] Specify return signals

## Recommendations

### Short-Term (Immediate - 2 weeks)

**1. Prototype Single Workflow** (Priority: Critical)
- Port `/research` command as proof-of-concept
- Validate recipe pattern works for Claude Code workflows
- Test hard barrier enforcement with retry.checks
- Measure performance vs Claude Code bash implementation
- **Deliverable**: Working research.yaml recipe + research-specialist.yaml subrecipe

**2. Build Core MCP Servers** (Priority: High)
- `plan-manager`: Phase marker management (checkbox-utils.sh equivalent)
- `state-machine`: State validation and transitions
- Test MCP server performance and reliability
- **Deliverable**: 2 MCP servers with API documentation

**3. Create .goosehints Migration Script** (Priority: Medium)
- Automated conversion from CLAUDE.md to .goosehints
- Preserve section structure and content
- Test auto-loading in Goose recipes
- **Deliverable**: Conversion script + .goosehints file

### Medium-Term (1-2 months)

**4. Complete Core Workflow Migration** (Priority: Critical)
- Port `/create-plan` with two-phase orchestration
- Port `/revise` with backup and Edit tool enforcement
- Port `/implement` with iteration support
- Integration testing across all three workflows
- **Deliverable**: 3 core workflows as Goose recipes + test suite

**5. Develop Iteration Orchestration** (Priority: High)
- Build external orchestration script for iteration loops
- Or implement custom MCP server for iteration management
- Test with large plans requiring multiple iterations
- **Deliverable**: Iteration orchestration tool + documentation

**6. Library Consolidation** (Priority: Medium)
- Identify libraries that can be combined into single MCP servers
- Deprecate libraries replaced by Goose built-ins
- Embed simple utilities as inline instructions
- **Deliverable**: Consolidated MCP server suite (5-6 servers)

### Long-Term (3-6 months)

**7. Performance Optimization** (Priority: Medium)
- Profile MCP server latency
- Optimize recipe invocation overhead
- Benchmark vs Claude Code bash implementation
- Target: <10% performance penalty vs bash
- **Deliverable**: Performance report + optimizations

**8. User Experience Enhancements** (Priority: Medium)
- Better error messages (map shell errors to user-friendly descriptions)
- Progress indicators (equivalent to checkpoint reporting)
- Completion signals for tool integration
- **Deliverable**: Enhanced UX features + user testing

**9. Documentation and Migration Guide** (Priority: High)
- Comprehensive recipe usage documentation
- MCP server API reference
- Migration guide from Claude Code to Goose
- Troubleshooting guide for common issues
- **Deliverable**: Complete documentation suite

**10. Community Contribution** (Priority: Low)
- Open-source Goose recipe templates for workflow orchestration
- Contribute MCP servers to Goose ecosystem
- Share migration learnings with Goose community
- **Deliverable**: Public GitHub repository

### Critical Success Factors

**1. Maintain Hard Barrier Pattern Integrity**
- Ensure artifact creation is enforced in Goose recipes
- Use retry.checks for validation
- Preserve pre-calculation → contract → validation flow
- **Risk**: Without hard barriers, agents may skip artifact creation

**2. Preserve State Machine Semantics**
- State transitions must be validated (research → plan → implement)
- Invalid transitions should error
- Completed states should persist across recipe invocations
- **Risk**: Invalid state transitions lead to workflow corruption

**3. Agent Behavioral Fidelity**
- Subrecipe instructions must match agent behavioral guidelines
- Preserve imperative language and step structure
- Maintain tool usage patterns (Write FIRST, then research)
- **Risk**: Deviations from guidelines cause agent failures

**4. Performance Parity**
- Goose workflows should perform within 10% of Claude Code bash
- MCP server latency must be <100ms per call
- Recipe invocation overhead acceptable (<500ms)
- **Risk**: Poor performance discourages adoption

**5. Testability and Debuggability**
- Comprehensive integration tests for all workflows
- Clear error messages for debugging
- Logging equivalent to Claude Code error.jsonl
- **Risk**: Hard to debug failures without good diagnostics

## References

### Source Files Analyzed

**Claude Code Commands**:
- /home/benjamin/.config/.claude/commands/research.md (Lines: 1289)
- /home/benjamin/.config/.claude/commands/create-plan.md (Lines: 1970)
- /home/benjamin/.config/.claude/commands/revise.md (Lines: 1400)
- /home/benjamin/.config/.claude/commands/implement.md (Lines: 1566)

**Agent Behavioral Files**:
- /home/benjamin/.config/.claude/agents/research-specialist.md (Lines: 450+)
- /home/benjamin/.config/.claude/agents/plan-architect.md (Lines: 380+)

**Bash Libraries** (52 total):
- /home/benjamin/.config/.claude/lib/core/error-handling.sh (Lines: 450)
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh (Lines: 380)
- /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh (Lines: 620)
- /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh (Lines: 280)
- /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh (Lines: 485)
- /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh (Lines: 290)
- /home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh (Lines: 195)
- /home/benjamin/.config/.claude/lib/workflow/validation-utils.sh (Lines: 340)
- ... (44 additional libraries)

**Parent Research**:
- /home/benjamin/.config/.claude/specs/996_goose_claude_code_port/reports/001-goose-claude-code-port-research.md (Lines: 486)

**Goose Documentation** (referenced):
- Goose Recipe Specification (version 2.1)
- MCP Server Protocol Specification
- Goose CLI Documentation

### External Resources

- Block's Goose GitHub Repository: https://github.com/block/goose
- MCP (Model Context Protocol) Specification: https://github.com/anthropic-ai/mcp
- Claude Code Documentation: .claude/docs/ directory
- Goose Recipe Examples: Goose repository examples/

## Conclusion

Porting Claude Code's core workflow utilities (/research, /create-plan, /revise, /implement) to the Goose ecosystem is **feasible but requires substantial architectural transformation**. The migration cannot be a simple copy-paste; it requires reimagining bash-orchestrated workflows as declarative YAML recipes, converting hierarchical agent delegation to subrecipe patterns, and replacing bash state machines with recipe-native state management.

**Key Insights**:
1. **Recipe Pattern Works**: Goose's YAML recipe structure can express Claude Code's multi-phase workflows through subrecipe composition and parameter passing
2. **Hard Barriers Translate**: The hard barrier pattern (pre-calc → invoke → validate) maps cleanly to recipe retry.checks with shell validation
3. **MCP Servers Essential**: Complex utilities (checkbox-utils, state-machine) require dedicated MCP servers; simple utilities can be embedded in instructions
4. **Iteration Needs Wrapper**: Goose lacks built-in iteration loops; external orchestration script or custom MCP server required
5. **State Management Different**: Bash state files must be replaced with JSON state files or recipe parameter passing

**Estimated Effort**: 88-124 hours (11-15.5 days) for complete migration of all four workflows plus supporting infrastructure.

**Recommendation**: Proceed with phased migration, starting with /research prototype to validate approach, then progressively port /create-plan, /revise, and /implement. Prioritize MCP server development for plan-manager and state-machine to enable complex workflows. The investment is justified by gaining access to Goose's MCP ecosystem and multi-model support while preserving Claude Code's proven workflow patterns.

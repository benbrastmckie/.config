# Workflow Libraries

Workflow orchestration and state machine libraries used by `/build`, `/plan`, `/debug`, `/research`, `/revise`.

## Libraries

### argument-capture.sh
Argument parsing and capture utilities.

**Key Functions:**
- `capture_arguments()` - Capture command arguments
- `parse_arguments()` - Parse argument array

### checkpoint-utils.sh
Checkpoint management for workflow resume capability with schema migration.

**Key Functions:**
- `save_checkpoint()` - Save workflow state for resume
- `restore_checkpoint()` - Load most recent checkpoint
- `validate_checkpoint()` - Validate checkpoint structure
- `checkpoint_get_field()` - Extract field value from checkpoint
- `checkpoint_set_field()` - Update field value in checkpoint

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh"
CHECKPOINT=$(save_checkpoint "implement" "project" "$STATE")
PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')
```

### metadata-extraction.sh
Metadata extraction from artifacts without reading full files.

**Key Functions:**
- `extract_report_metadata()` - Extract metadata from report
- `extract_plan_metadata()` - Extract metadata from plan

### workflow-detection.sh
Workflow scope detection and phase execution logic.

**Key Functions:**
- `detect_workflow_scope()` - Detect workflow type
- `should_run_phase()` - Check if phase should execute for current scope

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-detection.sh"
SCOPE=$(detect_workflow_scope "research auth to create plan")
```

### workflow-init.sh
Basic workflow initialization.

**Key Functions:**
- `init_workflow()` - Initialize workflow environment

### workflow-initialization.sh
Extended workflow setup with full configuration.

**Key Functions:**
- `initialize_workflow()` - Full workflow initialization
- `setup_workflow_paths()` - Configure workflow paths

### workflow-llm-classifier.sh
LLM-based workflow classification for complex descriptions.

**Key Functions:**
- `classify_workflow_llm()` - Use LLM to classify workflow type

### workflow-scope-detection.sh
Workflow scope detection using pattern matching.

**Key Functions:**
- `detect_scope()` - Detect workflow scope from description

### workflow-state-machine.sh
State machine orchestration for workflow execution.

**Key Functions:**
- `init_state_machine()` - Initialize state machine
- `transition_state()` - Transition to next state
- `get_current_state()` - Get current state
- `execute_state()` - Execute current state

## Dependencies

- Most libraries depend on `core/` libraries
- `workflow-scope-detection.sh` sources `workflow-llm-classifier.sh`
- `workflow-detection.sh` sources `workflow-scope-detection.sh`
- `metadata-extraction.sh` depends on `core/base-utils.sh` and `core/unified-logger.sh`

## Navigation

- [Parent Directory (lib/)](../README.md)

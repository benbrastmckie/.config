# Numbered Directory Infrastructure Research Report

## Metadata
- **Date**: 2025-11-23
- **Agent**: research-specialist
- **Topic**: Numbered specs directory creation infrastructure for /plan and /research commands
- **Report Type**: codebase analysis

## Executive Summary

The numbered project directory infrastructure (e.g., `933_error_numbering_increment_fix/`) is implemented through a well-established two-library system: `topic-utils.sh` provides basic numbering and validation functions, while `unified-location-detection.sh` provides atomic topic allocation with concurrency guarantees. Commands use `initialize_workflow_paths()` from `workflow-initialization.sh` which orchestrates these libraries and integrates with the Haiku LLM-based topic-naming-agent for semantic directory name generation.

## Findings

### 1. Core Library Architecture

The numbered directory creation system consists of three key library files:

#### 1.1 topic-utils.sh (Basic Numbering Functions)
**Location**: `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh`

This library provides fundamental topic directory utilities:

- **`get_next_topic_number(specs_root)`** (lines 25-41): Finds the maximum existing topic number and returns the next sequential three-digit number. Starts at "001" for empty directories.
  ```bash
  max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)
  ```

- **`get_or_create_topic_number(specs_root, topic_name)`** (lines 50-65): Idempotent function that checks for existing topic with exact name match before allocating new number. This prevents topic number incrementing on each bash block invocation.

- **`validate_topic_name_format(topic_name)`** (lines 91-115): Validates that topic names meet format requirements: `^[a-z0-9_]{5,40}$`, no consecutive underscores, no leading/trailing underscores.

- **`create_topic_structure(topic_path)`** (lines 126-139): Creates only the topic root directory (lazy subdirectory creation).

#### 1.2 unified-location-detection.sh (Atomic Allocation)
**Location**: `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh`

This library provides atomic topic allocation with concurrency guarantees:

- **`allocate_and_create_topic(specs_root, topic_name)`** (lines 247-305): **This is the primary function for numbered directory creation.** It holds an exclusive file lock through BOTH number calculation AND directory creation, eliminating race conditions.

  **Key Features**:
  - Uses `flock` for exclusive locking via `.topic_number.lock` file
  - First topic starts at 000 (not 001)
  - Rollover at 999 -> 000 (modulo 1000)
  - Collision detection and automatic next-number finding after rollover
  - Returns pipe-delimited string: `"topic_number|topic_path"`

  ```bash
  RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_NAME")
  TOPIC_NUM="${RESULT%|*}"      # Extract number
  TOPIC_PATH="${RESULT#*|}"     # Extract path
  ```

- **`get_next_topic_number(specs_root)`** (lines 186-215): Similar to topic-utils.sh version but with lock file support. Note: This standalone function does NOT provide atomic creation - use `allocate_and_create_topic()` instead.

- **`sanitize_topic_name(raw_name)`** (lines 364-377): Fallback sanitization when LLM naming fails. Converts to lowercase, replaces spaces with underscores, removes non-alphanumerics, truncates to 50 chars.

- **`ensure_artifact_directory(file_path)`** (lines 400-411): Creates parent directory for artifact files (lazy creation pattern). Used by agents before writing report/plan files.

#### 1.3 workflow-initialization.sh (Orchestration Layer)
**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh`

This library provides the high-level `initialize_workflow_paths()` function used by commands:

- **`initialize_workflow_paths(workflow_description, workflow_scope, research_complexity, classification_result)`** (lines 379-810): Main entry point for Phase 0 initialization in workflow commands.

  **Integration with Topic Naming**:
  - Lines 469-475: If `classification_result` JSON is provided (contains LLM-generated `topic_directory_slug`), uses `validate_topic_directory_slug()` for two-tier validation
  - Otherwise falls back to basic sanitization
  - Calls `get_or_create_topic_number()` (not `allocate_and_create_topic()`!) for idempotent topic number assignment

- **`validate_topic_directory_slug(classification_result, workflow_description)`** (lines 287-333): Two-tier validation for LLM-generated topic slugs:
  - Tier 1: Use valid LLM slug if format matches `^[a-z0-9_]{1,40}$` and no path separators
  - Tier 2: Static fallback to `"no_name_error"` (clear failure signal)

### 2. Topic Naming Agent Integration

**Location**: `/home/benjamin/.config/.claude/agents/topic-naming-agent.md`

Commands use a Haiku LLM agent (topic-naming-agent) for semantic directory name generation:

**Agent Invocation Pattern** (from plan.md Block 1b, lines 261-284):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /plan command

    **Input**:
    - User Prompt: ${FEATURE_DESCRIPTION}
    - Command Name: /plan
    - OUTPUT_FILE_PATH: ${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to OUTPUT_FILE_PATH using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>
  "
}
```

**Agent Output Validation** (plan.md Block 1c, lines 453-514):
1. Read topic name from output file
2. Validate format using regex `^[a-z0-9_]{5,40}$`
3. On failure: log error and fallback to `"no_name_error"`
4. Create classification JSON for `initialize_workflow_paths()`

### 3. Command Integration Pattern

Both `/plan` and `/research` commands follow identical topic creation patterns:

**Block 1a** - Setup and state initialization
**Block 1b** - Topic naming agent invocation via Task tool
**Block 1c** - Topic path initialization using `initialize_workflow_paths()`

Key code from plan.md Block 1c (lines 516-520):
```bash
# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with LLM-generated name (or fallback)
initialize_workflow_paths "$FEATURE_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
```

### 4. Numbering Behavior

**Starting Number**:
- `allocate_and_create_topic()`: Starts at 000
- `get_next_topic_number()` in topic-utils.sh: Starts at 001

**Rollover**:
- After 999, numbers wrap to 000
- Collision detection finds next available if rolled-over number exists
- All 1000 numbers exhausted returns error (rare edge case)

**Lock File**: `${specs_root}/.topic_number.lock`
- Created automatically on first allocation
- Empty file (<1KB, gitignored)
- Lock released automatically when process exits

### 5. Documentation Reference

**Primary Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Complete topic structure and atomic allocation documentation
- `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` - LLM naming system guide

## Recommendations

### 1. Use allocate_and_create_topic() for Atomic Operations
When creating new topic directories, always use `allocate_and_create_topic()` from `unified-location-detection.sh` rather than the separate `get_next_topic_number()` + `mkdir` pattern. This provides atomic guarantees and eliminates race conditions.

**Correct Pattern**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_NAME")
TOPIC_NUM="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"
```

### 2. Use initialize_workflow_paths() for Full Workflow Setup
For workflow commands that need complete path setup (TOPIC_PATH, RESEARCH_DIR, PLANS_DIR, etc.), use `initialize_workflow_paths()` from `workflow-initialization.sh`. This handles:
- LLM slug validation
- Idempotent topic number assignment
- Path variable exports
- State file integration

### 3. Integrate with Topic Naming Agent
For semantic directory naming, invoke the topic-naming-agent via Task tool:
1. Agent writes topic name to output file
2. Validate format with `validate_topic_name_format()`
3. Create JSON with `topic_directory_slug` key
4. Pass to `initialize_workflow_paths()`

### 4. Handle Fallback Cases
Always implement fallback to `"no_name_error"` when:
- Agent times out (>5 seconds)
- Agent returns empty output
- Validation fails
- Output file not created

This provides clear visibility into naming failures for post-hoc investigation.

### 5. Avoid Redundant Implementation
The existing infrastructure in `topic-utils.sh`, `unified-location-detection.sh`, and `workflow-initialization.sh` is comprehensive. New commands should reuse these functions rather than implementing custom numbering logic.

## References

| File | Lines | Description |
|------|-------|-------------|
| /home/benjamin/.config/.claude/lib/plan/topic-utils.sh | 25-41 | `get_next_topic_number()` basic implementation |
| /home/benjamin/.config/.claude/lib/plan/topic-utils.sh | 50-65 | `get_or_create_topic_number()` idempotent allocation |
| /home/benjamin/.config/.claude/lib/plan/topic-utils.sh | 91-115 | `validate_topic_name_format()` format validation |
| /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh | 186-215 | `get_next_topic_number()` with lock support |
| /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh | 247-305 | `allocate_and_create_topic()` atomic allocation |
| /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh | 364-377 | `sanitize_topic_name()` fallback sanitization |
| /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh | 400-411 | `ensure_artifact_directory()` lazy creation |
| /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh | 287-333 | `validate_topic_directory_slug()` LLM slug validation |
| /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh | 379-810 | `initialize_workflow_paths()` main orchestration |
| /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh | 469-477 | LLM slug integration with get_or_create_topic_number() |
| /home/benjamin/.config/.claude/commands/plan.md | 261-284 | Topic naming agent Task invocation |
| /home/benjamin/.config/.claude/commands/plan.md | 453-514 | Agent output validation and fallback |
| /home/benjamin/.config/.claude/commands/research.md | 229-256 | Topic naming agent Task invocation (research) |
| /home/benjamin/.config/.claude/agents/topic-naming-agent.md | 1-500 | Complete agent behavioral guidelines |
| /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md | 119-196 | Atomic topic allocation documentation |
| /home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md | 1-620 | LLM naming system guide |

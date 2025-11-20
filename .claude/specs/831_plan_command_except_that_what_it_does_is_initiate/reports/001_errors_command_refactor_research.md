# /errors Command Refactor Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Refactoring /errors command to use research-and-plan workflow pattern
- **Report Type**: codebase analysis and architecture design

## Executive Summary

The current `/errors` command is a simple query utility (160 lines) that displays error logs from `.claude/data/logs/errors.jsonl`. To transform it into a research-and-plan workflow similar to `/plan` and `/debug`, it must adopt a multi-phase state machine architecture with specialized agents for error analysis, root cause investigation, and fix planning. This refactor requires creating a new `error-analyst` agent, integrating the state machine workflow pattern, and following established command authoring standards from `.claude/docs/reference/standards/command-authoring.md`.

## Findings

### 1. Current /errors Command Analysis

**File**: `/home/benjamin/.config/.claude/commands/errors.md` (lines 1-230)

The current command is a simple query interface:
- **Allowed tools**: Bash, Read (minimal toolset)
- **Functionality**: Query and display error logs with filtering
- **No state machine**: Simple procedural execution
- **No agent invocation**: Direct bash execution only
- **Options**: `--command`, `--since`, `--type`, `--limit`, `--workflow-id`, `--summary`, `--raw`

**Key functions used from error-handling.sh**:
- `query_errors()` (lines 579-644)
- `recent_errors()` (lines 650-695)
- `error_summary()` (lines 700-743)

**Error log format** (`.claude/data/logs/errors.jsonl`):
```json
{
  "timestamp": "2025-11-19T14:30:00Z",
  "command": "/build",
  "workflow_id": "build_1732023400",
  "user_args": "plan.md 3",
  "error_type": "state_error",
  "error_message": "State file not found",
  "source": "bash_block",
  "stack": ["..."],
  "context": {}
}
```

### 2. /plan Command Architecture (Template Pattern)

**File**: `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-427)

The `/plan` command demonstrates the research-and-plan workflow pattern to emulate:

**Frontmatter requirements**:
- `allowed-tools`: Task, TodoWrite, Bash, Read, Grep, Glob, Write
- `command-type`: primary
- `dependent-agents`: research-specialist, research-sub-supervisor, plan-architect
- `library-requirements`: workflow-state-machine.sh >=2.0.0, state-persistence.sh >=1.5.0

**Workflow phases**:
1. **Block 1: Consolidated Setup** (lines 23-204)
   - Capture feature description
   - Parse `--complexity` and `--file` flags
   - Detect project directory
   - Source libraries in dependency order
   - Initialize state machine with `sm_init()`
   - Transition to `STATE_RESEARCH`
   - Initialize workflow paths
   - Archive prompt file if `--file` used
   - Persist state variables

2. **Task: Research-specialist agent** (lines 206-231)
   - Invoked with `Task {}` pseudo-syntax
   - Passes research topic, complexity, output directory
   - Returns `REPORT_CREATED: [path]`

3. **Block 2: Research Verification and Planning Setup** (lines 232-316)
   - Load workflow state
   - Verify research artifacts (directory exists, files exist, size check)
   - Transition to `STATE_PLAN`
   - Prepare plan path
   - Collect research report paths

4. **Task: Plan-architect agent** (lines 318-343)
   - Creates implementation plan
   - Returns `PLAN_CREATED: [path]`

5. **Block 3: Plan Verification and Completion** (lines 345-415)
   - Verify plan artifacts
   - Transition to `STATE_COMPLETE`
   - Output summary and next steps

### 3. /debug Command Architecture (Similar Pattern)

**File**: `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-743)

The `/debug` command provides another reference pattern with debug-specific phases:

**Workflow type**: debug-only
**Terminal state**: debug
**Dependent agents**: research-specialist, plan-architect, debug-analyst

**Phases**:
1. **Part 1**: Capture issue description
2. **Part 2**: State machine initialization
3. **Part 2a**: Workflow classification (semantic slug generation)
4. **Part 3**: Research phase (issue investigation)
5. **Part 4**: Planning phase (debug strategy)
6. **Part 5**: Debug phase (root cause analysis) - invokes `debug-analyst` agent
7. **Part 6**: Completion and cleanup

### 4. Error Handling Library Analysis

**File**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 1-1239)

**Error classification functions** (critical for error analysis):
- `classify_error()` (lines 29-55): Classifies as transient/permanent/fatal
- `detect_error_type()` (lines 90-141): Detects specific types (syntax, test_failure, file_not_found, etc.)
- `extract_location()` (lines 143-158): Extracts file:line from error message
- `generate_suggestions()` (lines 160-237): Creates error-specific fix suggestions

**Error types defined** (lines 17-27, 361-370):
- `ERROR_TYPE_TRANSIENT`, `ERROR_TYPE_PERMANENT`, `ERROR_TYPE_FATAL`
- `ERROR_TYPE_STATE`, `ERROR_TYPE_VALIDATION`, `ERROR_TYPE_AGENT`
- `ERROR_TYPE_PARSE`, `ERROR_TYPE_FILE`, `ERROR_TYPE_TIMEOUT_ERR`, `ERROR_TYPE_EXECUTION`

**Log functions**:
- `log_command_error()` (lines 407-487): Logs to centralized JSONL
- `parse_subagent_error()` (lines 489-529): Parses TASK_ERROR signals

### 5. Agent Patterns and Requirements

**Agent reference file**: `/home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md`

**Existing debug-related agents**:
- `debug-specialist` (lines 72-85): Root cause analysis with WebSearch access
- `debug-analyst` (lines 87-103): Parallel root cause analysis for complex bugs

**Agent requirements for new error-analyst**:
1. **Allowed tools**: Read, Grep, Glob, Bash (for log analysis)
2. **Capabilities**:
   - Error log pattern detection
   - Stack trace analysis
   - Context aggregation
   - Root cause grouping
   - Fix proposal generation
3. **Model selection**: sonnet-4.5 (complex analysis justifies capable model)

### 6. Workflow Initialization Patterns

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 1-935)

**Key function**: `initialize_workflow_paths()` (lines 364-793)
- Validates inputs
- Scope detection
- Path pre-calculation
- Directory structure creation (lazy creation pattern)
- Exports: TOPIC_PATH, TOPIC_NAME, TOPIC_NUM, RESEARCH_DIR, PLAN_PATH, etc.

**Valid workflow scopes** (line 393):
- `research-only`
- `research-and-plan`
- `research-and-revise`
- `full-implementation`
- `debug-only`

For /errors refactor, a new scope `error-analysis` or reuse of `debug-only` would be appropriate.

### 7. Command Authoring Standards

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (lines 1-575)

**Critical requirements**:

1. **Execution directives** (lines 16-87):
   - Every bash block must have `**EXECUTE NOW**:` directive
   - Prevents silent failures where code is read but not executed

2. **Task tool invocation** (lines 89-162):
   - NO code block wrapper around Task {}
   - Must include imperative instruction
   - Must require completion signals

3. **Subprocess isolation** (lines 164-227):
   - `set +H` at start of every block
   - Re-source libraries in every block
   - Return code verification for critical functions

4. **State persistence** (lines 229-268):
   - Use `append_workflow_state()` for cross-block variables
   - Save workflow ID to fixed location

5. **Output suppression** (lines 479-560):
   - Library sourcing with `2>/dev/null`
   - Single summary line per block
   - 2-3 bash blocks target

### 8. Proposed Workflow for Refactored /errors Command

**Workflow type**: `error-analysis` (new) or reuse `debug-only`
**Terminal state**: `plan` (after planning phase complete)
**Output**: Error analysis reports + fix implementation plan

**Proposed phases**:

1. **Phase 0: Setup** (single bash block)
   - Parse arguments (`--since`, `--type`, `--command`, `--severity`, `--complexity`)
   - Source libraries
   - Initialize state machine
   - Transition to research state
   - Initialize workflow paths

2. **Phase 1: Error Research** (Task: error-analyst agent)
   - Read error logs from `.claude/data/logs/errors.jsonl`
   - Group errors by type, command, and root cause
   - Identify error patterns and frequencies
   - Analyze stack traces and context
   - Create error analysis reports in `{topic}/reports/`

3. **Phase 2: Verification** (bash block)
   - Verify research artifacts
   - Transition to plan state

4. **Phase 3: Fix Planning** (Task: plan-architect agent)
   - Read error analysis reports
   - Create implementation plan for fixing errors
   - Include standards updates if needed
   - Return `PLAN_CREATED: [path]`

5. **Phase 4: Completion** (bash block)
   - Verify plan artifacts
   - Transition to complete state
   - Output summary

### 9. Error-Analyst Agent Design

**Proposed file**: `/home/benjamin/.config/.claude/agents/error-analyst.md`

**Frontmatter**:
```yaml
---
allowed-tools: Read, Write, Grep, Glob, Bash
description: Specialized in error log analysis and root cause pattern detection
model: sonnet-4.5
model-justification: Complex log analysis, pattern detection, root cause grouping with 25+ completion criteria
fallback-model: sonnet-4.5
---
```

**Capabilities**:
1. Read and parse JSONL error logs
2. Group errors by:
   - Error type (state_error, validation_error, etc.)
   - Command that produced error
   - Root cause patterns
   - Frequency/recurrence
3. Identify common root causes using pattern detection
4. Generate structured analysis reports
5. Propose fixes with confidence levels

**Report structure**:
```markdown
# Error Analysis Report

## Metadata
- Date: YYYY-MM-DD
- Agent: error-analyst
- Error Count: N errors analyzed
- Time Range: [start] to [end]

## Executive Summary
[2-3 sentences summarizing key findings]

## Error Patterns

### Pattern 1: [Error Type]
- **Frequency**: N occurrences
- **Commands affected**: /build, /plan
- **Root cause**: [analysis]
- **Example errors**: [samples]
- **Proposed fix**: [specific fix with confidence level]

### Pattern 2: [Error Type]
...

## Root Cause Analysis
[Deep analysis of underlying issues]

## Recommendations
1. [Specific fix recommendation]
2. [Standards update if needed]
3. [Prevention measures]

## References
- Log file: .claude/data/logs/errors.jsonl
- Affected files: [with line numbers]
```

### 10. Standards Compliance Analysis

The refactored /errors command must follow these standards:

1. **Directory protocols** (`.claude/docs/concepts/directory-protocols.md`):
   - Create topic directory: `specs/{NNN_error_analysis}/`
   - Research reports in: `reports/`
   - Plans in: `plans/`

2. **Command authoring** (lines 1-575 of command-authoring.md):
   - All execution directive requirements
   - Task invocation patterns
   - Subprocess isolation
   - Output suppression

3. **Agent development**:
   - Follow research-specialist pattern for completion criteria
   - Include verification checkpoints
   - Return completion signals

**Potential standards updates needed**:
- Add `error-analysis` workflow scope to valid scopes in workflow-initialization.sh
- Document new error-analyst agent in agent-reference.md

## Recommendations

### 1. Create error-analyst agent first

Create `/home/benjamin/.config/.claude/agents/error-analyst.md` following the pattern of `research-specialist.md` with:
- Same step structure (verify path, create file first, research, verify completion)
- Progress markers
- Completion criteria checklist
- 28+ verification requirements

**Rationale**: The agent is the core component that performs error analysis and must be robust.

### 2. Refactor /errors command to multi-phase workflow

Transform from 160-line query utility to ~450-line workflow command following `/plan` and `/debug` patterns:
- Add frontmatter with proper dependencies and library requirements
- Implement 5-phase workflow (setup, research, verification, planning, completion)
- Use state machine for phase transitions
- Persist state across bash blocks

### 3. Reuse existing workflow scope

Use `debug-only` workflow scope rather than creating new `error-analysis` scope:
- `debug-only` already supports research -> plan -> debug flow
- Terminal state would be `plan` (after planning phase)
- Avoids modifying workflow-initialization.sh

### 4. Extend error-handling.sh with analysis functions

Add helper functions to `/home/benjamin/.config/.claude/lib/core/error-handling.sh`:
- `analyze_error_patterns()`: Group and analyze errors
- `get_error_statistics()`: Calculate frequencies and distributions
- `extract_root_causes()`: Identify common root causes

### 5. Follow output suppression standards

Keep command output minimal:
- Single summary line per bash block
- Suppress library sourcing output
- Use progress markers for visibility
- Target 3-4 bash blocks total

### 6. Document standards change prominently

If any standards need updating (unlikely with debug-only reuse), prominently document in the plan:
- Mark section as `## STANDARDS UPDATE REQUIRED`
- Explain what needs to change
- Justify why change is necessary
- Show before/after

### 7. Maintain backward compatibility

Preserve existing /errors query functionality as a mode:
- `/errors` (default): New error analysis workflow
- `/errors --query`: Legacy query mode
- `/errors --summary`: Existing summary view

This allows gradual adoption and preserves familiar functionality.

## References

### Core Files Analyzed

1. `/home/benjamin/.config/.claude/commands/errors.md` (lines 1-230)
   - Current /errors command implementation

2. `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-427)
   - Template workflow pattern for research-and-plan

3. `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-743)
   - Alternative workflow pattern with debug phase

4. `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 1-1239)
   - Error classification, logging, and analysis utilities

5. `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-873)
   - Agent pattern with completion criteria and verification

6. `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-670)
   - Agent pattern to follow for error-analyst

7. `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 1-935)
   - Workflow path initialization and scope validation

8. `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (lines 1-575)
   - Command development requirements

9. `/home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md` (lines 1-393)
   - Agent catalog and tool access matrix

10. `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 1-1149)
    - Topic-based artifact organization

### Related Specifications

- State machine workflow: `workflow-state-machine.sh`
- State persistence: `state-persistence.sh`
- Error types: `error-handling.sh` (lines 17-27, 361-370)
- Valid workflow scopes: `workflow-initialization.sh` (line 393)

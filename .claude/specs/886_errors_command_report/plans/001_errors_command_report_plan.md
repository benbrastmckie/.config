# /errors Command Report Artifact Implementation Plan

## Metadata

- **Date**: 2025-11-20
- **Feature**: Create basic report artifacts for /errors command via haiku subagent
- **Scope**: Refactor /errors command to delegate error analysis to specialized agent, creating markdown report artifacts in topic-based structure
- **Estimated Phases**: 4
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0 (Single File)
- **Complexity Score**: 68.0
- **Status**: [IN PROGRESS]
- **Research Reports**:
  - [/errors Command Report Artifact Architecture Research](/home/benjamin/.config/.claude/specs/886_errors_command_report/reports/001_errors_command_report_artifact_research.md)

## Overview

The `/errors` command is currently a read-only query utility (233 lines) that displays error logs from `.claude/data/logs/errors.jsonl`. To enhance this command with report artifact generation while conserving context, we will:

1. Create a specialized `errors-analyst` haiku subagent that generates structured error analysis reports
2. Refactor `/errors` command to orchestrate error analysis via Task invocation
3. Produce markdown reports following topic-based directory structure
4. Return report paths to users for reference and downstream workflow integration (e.g., `/repair`)

This implementation follows established patterns from `/plan`, `/repair`, and `/debug` commands, using haiku model for context efficiency and maintaining backward compatibility with existing query functionality.

## Research Summary

Key findings from architecture research:

- **Current State**: /errors command is read-only with no artifact generation or orchestration capability (research finding from section 1)
- **Pattern Foundation**: /repair and /plan commands demonstrate successful agent delegation using Task invocation with completion signals (section 3)
- **Report Structure**: Error analysis reports follow `.claude/specs/{NNN_topic}/reports/{NNN_filename}.md` with markdown metadata, findings, and recommendations (section 2)
- **Model Selection**: Haiku model appropriate for error log analysis (token budget ~1000-2200 per report) while conserving context (section 4)
- **Agent Architecture**: errors-analyst agent must follow 4-step process: receive path, ensure directory, create file, verify completion with 28 criteria checklist (section 5)
- **Integration Pattern**: Main command invokes agent via Task, receives `REPORT_CREATED: [path]` signal, verifies artifact, and displays summary (section 7)
- **Context Benefits**: Haiku delegation reduces main command token load by ~75% while maintaining analysis quality (section 8)

Recommended approach: Create errors-analyst haiku agent following research-specialist pattern, refactor /errors to use Task invocation with state machine for orchestration, create topic-based report artifacts with structured sections.

## Success Criteria

- [x] errors-analyst haiku agent created with 4-step process and 28 completion criteria
- [x] /errors command refactored to invoke agent via Task and handle report path
- [x] Error report artifacts created in topic-based directory structure (specs/{NNN_topic}/reports/)
- [x] Report format includes metadata, executive summary, error overview, patterns, and recommendations
- [x] /errors preserves backward compatibility with --query flag for legacy query mode
- [x] Integration tested with /repair command (downstream workflow)
- [x] Documentation updated with new /errors functionality and agent reference

## Technical Design

### Architecture Overview

```
User Input (/errors)
    ↓
/errors Command (233 → ~350 lines)
    ├─ Parse arguments (filters, flags)
    ├─ Determine operation mode
    │  ├─ Mode 1: --query (existing functionality preserved)
    │  └─ Mode 2: Default (new artifact generation)
    ├─ Mode 2 Flow:
    │  ├─ Initialize workflow state machine
    │  ├─ Create topic-based path (specs/{NNN_error_analysis}/)
    │  ├─ Invoke Task: errors-analyst agent
    │  ├─ Wait for REPORT_CREATED signal
    │  ├─ Verify artifact existence
    │  └─ Display summary + path
    └─ Mode 1 Flow: Execute existing query logic

errors-analyst Agent (~650 lines)
    ├─ STEP 1: Receive absolute path and verify
    ├─ STEP 2: Create report file structure
    ├─ STEP 3: Analyze error logs and populate sections
    │  ├─ Parse .claude/data/logs/errors.jsonl
    │  ├─ Group by error_type, command, time patterns
    │  ├─ Identify top N errors by frequency
    │  └─ Generate recommendations
    ├─ STEP 4: Verify completion and return signal
    └─ Return: REPORT_CREATED: [absolute_path]

Report Artifact (.claude/specs/{NNN_topic}/reports/001_error_report.md)
    ├─ ## Metadata (date, agent, filters, time range)
    ├─ ## Executive Summary (2-3 sentences)
    ├─ ## Error Overview (counts, types, commands)
    ├─ ## Top Errors by Frequency (patterns, occurrences, examples)
    ├─ ## Error Distribution (by type, by command)
    ├─ ## Recommendations (actionable fixes)
    └─ ## References (log path, agent, analysis date)
```

### Component Details

**1. errors-analyst Agent** (`/home/benjamin/.config/.claude/agents/errors-analyst.md`)
- Model: claude-3-5-haiku-20241022
- Tools: Read, Write, Grep, Glob, Bash
- Process: 4-step (path verification, directory creation, file creation/analysis, verification)
- Completion: 28 criteria checklist
- Output Signal: `REPORT_CREATED: [absolute_path]`

**2. /errors Command Refactoring** (`/home/benjamin/.config/.claude/commands/errors.md`)
- Add frontmatter fields:
  - `dependent-agents: errors-analyst`
  - `library-requirements: workflow-state-machine.sh >=2.0.0`
  - Update `allowed-tools: Task, Write, Glob, Bash, Read`
- Block 1: Setup and Agent Invocation
  - Parse error filters (--command, --since, --type, --limit, --workflow-id)
  - Add --query flag for legacy query mode
  - Create error analysis description for topic naming
  - Initialize workflow state machine
  - Invoke errors-analyst via Task
- Block 2: Verification and Summary
  - Verify report file exists
  - Extract summary statistics from report
  - Display brief summary to console
  - Output path to generated report

**3. Report Artifact Structure**
- Location: `.claude/specs/{NNN_error_analysis}/reports/001_error_report.md`
- Topic naming via haiku LLM agent (automatic generation based on filter context)
- Metadata: date, agent, errors analyzed, time range, filters applied
- Sections: executive summary, error overview, top patterns, distribution, recommendations, references

### State Management

Use `workflow-state-machine.sh` for cross-block variable persistence:
- STATE_KEY: "errors_analysis_{timestamp}"
- Variables to persist:
  - REPORT_PATH (received from agent)
  - ANALYSIS_FILTERS (user-provided arguments)
  - TOPIC_DIR (determined during setup)

### Error Handling

- Task invocation timeout: 120 seconds
- File existence verification after agent completion
- Fallback message if agent fails to return REPORT_CREATED signal
- Logging: All errors to `.claude/data/logs/errors.jsonl` via error-handling.sh

## Implementation Phases

### Phase 1: Agent Development [COMPLETE]
dependencies: []

**Objective**: Create errors-analyst haiku subagent following research-specialist pattern with 4-step process and 28 completion criteria.

**Complexity**: High

Tasks:
- [x] Create `/home/benjamin/.config/.claude/agents/errors-analyst.md` skeleton (frontmatter, metadata, process steps)
- [x] Implement STEP 1: Absolute path verification and directory existence check
- [x] Implement STEP 2: Create initial report file with metadata template
- [x] Implement STEP 3: Read error logs from `.claude/data/logs/errors.jsonl`
- [x] Implement STEP 3a: Parse JSONL format and validate error entries
- [x] Implement STEP 3b: Group errors by type, command, and time patterns
- [x] Implement STEP 3c: Calculate frequency counts and identify top N error patterns
- [x] Implement STEP 3d: Generate structured markdown sections with findings
- [x] Implement STEP 4: Verify file creation and emit completion signal
- [x] Add progress markers at each STEP milestone
- [x] Add 28-item completion criteria checklist
- [x] Test agent with sample error logs (create fixture if needed)

Testing:
```bash
# Unit test: agent receives path correctly
# Unit test: report file created at exact path
# Unit test: metadata section populated
# Unit test: error analysis logic (grouping, frequency, patterns)
# Unit test: completion signal format (REPORT_CREATED: path)
```

**Expected Duration**: 4-5 hours

### Phase 2: /errors Command Refactoring [COMPLETE]
dependencies: [1]

**Objective**: Refactor /errors command to invoke errors-analyst agent and handle report artifacts while preserving backward compatibility.

**Complexity**: Medium

Tasks:
- [x] Update `/home/benjamin/.config/.claude/commands/errors.md` frontmatter (dependent-agents, library-requirements, allowed-tools)
- [x] Implement Block 1: Setup - Parse command-line arguments with new --query flag
- [x] Implement Block 1: Create error analysis description for topic naming
- [x] Implement Block 1: Initialize workflow state machine for cross-block persistence
- [x] Implement Block 1: Calculate topic-based directory path (specs/{NNN_error_analysis}/)
- [x] Implement Block 1: Invoke Task for errors-analyst agent with proper parameters
- [x] Implement Block 1: Handle timeout and error responses from agent
- [x] Implement Block 2: Verify report file exists at returned path
- [x] Implement Block 2: Extract summary statistics from report (total errors, top types)
- [x] Implement Block 2: Format and display summary output to user
- [x] Implement Block 2: Output full path to generated report
- [x] Add --query flag handling to preserve existing query functionality
- [x] Add error logging via error-handling.sh library
- [x] Test refactored command with --query flag (legacy mode)
- [x] Test refactored command with various filter combinations (new mode)

Testing:
```bash
# Integration test: /errors --query returns existing behavior
# Integration test: /errors (no flags) generates report
# Integration test: /errors --command /build --type agent_error generates filtered report
# Integration test: Report path returned correctly
# Integration test: /errors output includes summary and path
```

**Expected Duration**: 3-4 hours

### Phase 3: Documentation and Integration [COMPLETE]
dependencies: [2]

**Objective**: Update documentation and verify integration with downstream workflows (/repair).

**Complexity**: Low

Tasks:
- [x] Create agent reference entry for errors-analyst in `.claude/docs/reference/standards/agent-reference.md`
- [x] Update `/errors` command reference in `.claude/docs/reference/standards/command-reference.md`
- [x] Update errors-command-guide.md to document new artifact generation functionality
- [x] Add /errors to command index in `.claude/docs/guides/commands/README.md`
- [x] Document backward compatibility with --query flag
- [x] Add cross-reference between /errors and /repair command documentation
- [x] Verify integration: /errors report artifact feeds into /repair workflow
- [x] Update CLAUDE.md error logging standards section (if applicable)

Testing:
```bash
# Verify: All documentation links are correct
# Verify: Command reference entries are accurate
# Verify: Agent reference lists errors-analyst correctly
# Manual test: Follow /errors → /repair workflow (full integration)
```

**Expected Duration**: 2-3 hours

### Phase 4: Testing and Validation [COMPLETE]
dependencies: [3]

**Objective**: Run comprehensive tests to validate artifact generation, compatibility, and integration.

**Complexity**: Medium

Tasks:
- [x] Create test suite: `tests/features/commands/test_errors_report_generation.sh`
- [x] Test case: Agent creates report with valid metadata
- [x] Test case: /errors command returns correct report path
- [x] Test case: Report file size and content validation (>300 bytes, required sections)
- [x] Test case: Error log parsing handles edge cases (empty log, malformed entries, special characters)
- [x] Test case: Topic naming generates valid directory structure
- [x] Test case: /errors --query preserves backward compatibility
- [x] Test case: /errors with filter combinations (--command, --since, --type)
- [x] Test case: Integration with /repair (report artifact used by repair workflow)
- [x] Test case: Error handling (timeouts, missing files, invalid permissions)
- [x] Run existing error-related tests to ensure no regression
- [x] Create integration test: Full workflow /errors → /repair → /build

Testing:
```bash
# Run: bash tests/features/commands/test_errors_report_generation.sh
# Run: bash tests/integration/test_error_workflow.sh (new)
# Coverage: All error handling paths tested
# Manual: /errors without arguments generates report
# Manual: /errors --query returns legacy behavior
# Manual: Generated report feeds into /repair successfully
```

**Expected Duration**: 3-4 hours

## Testing Strategy

### Unit Testing

1. **Agent Logic Tests**: Test errors-analyst agent components
   - Path verification and directory creation
   - JSONL parsing and error entry validation
   - Grouping and frequency calculation algorithms
   - Markdown report generation
   - Completion signal format validation

2. **Command Tests**: Test /errors command refactoring
   - Argument parsing (all filter combinations)
   - State machine initialization and persistence
   - Task invocation and signal handling
   - Report verification logic
   - Output formatting

### Integration Testing

1. **Agent-Command Interaction**: Test full /errors → report flow
   - Command invokes agent successfully
   - Agent returns correct signal format
   - Report file created at expected location
   - Command displays summary correctly

2. **Downstream Workflow**: Test /errors → /repair integration
   - /errors generates report artifact
   - /repair command can read and parse report
   - /repair uses error patterns from report
   - Full workflow completes without errors

### Test Coverage Requirements

- Agent completion criteria: ALL 28 criteria must pass
- Command backward compatibility: --query flag behavior identical to original
- Report format: All required sections present with substantial content (>300 bytes)
- Error handling: All error paths tested (timeouts, missing files, invalid input)
- Integration: Full /errors → /repair workflow functional

### Validation Commands

```bash
# Verify agent created
test -f .claude/agents/errors-analyst.md && echo "Agent created"

# Verify command updated
grep "dependent-agents: errors-analyst" .claude/commands/errors.md

# Verify report structure
ls .claude/specs/*/reports/*error_report.md 2>/dev/null | head -1

# Test agent execution
source .claude/agents/errors-analyst.md 2>/dev/null

# Test command refactoring
./.claude/commands/errors.md --help

# Test integration
/errors | grep "Report:"
```

## Documentation Requirements

### Agent Documentation
- Create agent reference entry: `.claude/docs/reference/standards/agent-reference.md`
- Document model selection: Why haiku model for context conservation
- Document tool access: Which tools agent uses (Read, Write, Grep, Glob, Bash)
- Document process: 4-step execution with progress markers
- Document completion criteria: All 28 required items

### Command Documentation
- Update command reference: `.claude/docs/reference/standards/command-reference.md`
- Expand errors-command-guide.md with new functionality
- Document new flags: --query for backward compatibility
- Document report artifact: Location, format, structure
- Document integration: How /errors feeds into /repair

### Integration Documentation
- Update `/repair` command guide to reference error reports from /errors
- Add workflow diagram: /errors → /repair → /build
- Document cross-command artifact usage
- Add examples: Common /errors usage patterns

### Standards Documentation
- Update error logging standards in CLAUDE.md (if applicable)
- Reference topic-based directory protocols for report location
- Document report numbering scheme (001, 002, 003...)
- Reference agent development patterns

## Dependencies

### External Dependencies
- `workflow-state-machine.sh` library (v2.0.0 or higher)
- `error-handling.sh` library (for error logging)
- `.claude/data/logs/errors.jsonl` (error log file)

### Internal Dependencies
- research-specialist.md (pattern reference for agent development)
- repair.md command (pattern reference for agent invocation)
- directory-protocols.md (topic-based structure specification)
- agent-reference.md (documentation template)

### File Dependencies
- Create: `/home/benjamin/.config/.claude/agents/errors-analyst.md` (new agent, ~650 lines)
- Modify: `/home/benjamin/.config/.claude/commands/errors.md` (refactor, +120 lines)
- Modify: Documentation files (command reference, agent reference, guides)
- Create: Test suite `tests/features/commands/test_errors_report_generation.sh` (~200 lines)

### Prerequisites
- Understanding of error log format (JSONL with structured fields)
- Understanding of topic-based directory protocols
- Understanding of Task invocation pattern (from /plan, /repair examples)
- Understanding of haiku model capabilities and token budget constraints
- Working knowledge of bash state machine pattern

## Estimated Effort Breakdown

| Phase | Tasks | Complexity | Hours |
|-------|-------|-----------|-------|
| Phase 1: Agent Development | 12 | High | 4-5 |
| Phase 2: Command Refactoring | 14 | Medium | 3-4 |
| Phase 3: Documentation | 8 | Low | 2-3 |
| Phase 4: Testing & Validation | 13 | Medium | 3-4 |
| **Total** | **47** | **Medium-High** | **12-16** |

## Notes

- This plan follows the successful pattern of `/repair` and `/plan` commands for agent delegation
- Haiku model selection aligns with error analysis workload (1000-2200 tokens per report)
- Topic-based directory structure automatically organizes reports by error analysis session
- Backward compatibility preserved via --query flag (no breaking changes to existing functionality)
- Integration with /repair workflow enables automated error fix planning from /errors reports
- All agent completion criteria (28 items) must be verified before marking phase complete
- Phase dependencies enable parallel execution (Phase 1 and 2 could potentially run concurrently if agent scaffolding pre-exists)

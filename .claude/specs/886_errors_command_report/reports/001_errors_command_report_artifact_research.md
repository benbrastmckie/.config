# /errors Command Report Artifact Architecture Research

## Metadata

- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: /errors command should create a basic report artifact and be run by a haiku subagent to conserve context, returning the path to the report with a brief summary back to the main agent
- **Report Type**: codebase analysis and architecture design
- **Workflow Type**: research-and-plan
- **Research Complexity**: 3

## Executive Summary

The `/errors` command is currently a simple query utility (233 lines) that filters and displays error logs from `.claude/data/logs/errors.jsonl`. To fulfill the requirement of creating "a basic report artifact" while being "run by a haiku subagent to conserve context," the command must be refactored into a workflow that delegates error log analysis to a specialized haiku subagent, which creates a structured markdown report file and returns the path to that report back to the orchestrating command.

**Key Findings**:
- Current `/errors` command is read-only query utility with no report generation
- Similar commands (`/plan`, `/repair`, `/debug`) delegate analysis to dedicated agents (research-specialist, repair-analyst) using Task invocation pattern
- Report artifacts follow `.claude/specs/{NNN_topic}/reports/NNN_filename.md` structure with markdown frontmatter and structured sections
- Haiku model should be used for agents that conserve context (appropriate for analysis tasks ~500-2000 tokens)
- Report creation pattern requires: STEP 2 creates file first, STEP 3 conducts analysis, STEP 4 verifies completion

**Recommended Approach**:
1. Create a `errors-analyst` haiku subagent that creates structured error analysis reports
2. Refactor `/errors` command to invoke the agent via Task invocation, receiving report path back
3. Agent creates report file at `{topic}/reports/NNN_error_report.md` with basic structure: metadata, error summary, patterns identified, top errors, next steps
4. Main command verifies artifact and outputs brief summary with path confirmation

## Findings

### 1. Current /errors Command Architecture

**File**: `/home/benjamin/.config/.claude/commands/errors.md` (233 lines)

**Current Design**:
- Frontmatter specifies: allowed-tools: `Bash, Read`
- Description: "Query and display error logs from commands and subagents"
- Implementation: Direct bash execution with no agent involvement
- Functions used: `query_errors()`, `recent_errors()`, `error_summary()` from error-handling.sh

**Current Capabilities**:
- Query error logs with filters: `--command`, `--since`, `--type`, `--limit`, `--workflow-id`
- Display modes: recent errors, summary statistics, raw JSONL, formatted query results
- No artifact generation - output is displayed to console only
- No state persistence or workflow orchestration

**Limitation Identified**: Command does not generate structured report files (artifacts). It only queries and displays existing error logs.

### 2. Report Artifact Pattern Analysis

**Pattern Source**: Analysis of `/repair` and `/plan` commands which demonstrate report generation.

**Existing Report Structure** (from spec directory 835):
- Location: `.claude/specs/{NNN_topic}/reports/{NNN_filename}.md`
- Format: Markdown with YAML-like metadata section
- Sections: Metadata, Executive Summary, Findings, Recommendations, References
- Example file: `/home/benjamin/.config/.claude/specs/835_standards_and_adequately_documented_in_claude/reports/001_errors_command_standards_compliance_report.md` (600+ lines)

**Report Numbering Logic**:
```
Find existing reports: specs/{topic}/reports/[0-9][0-9][0-9]_*.md
Increment highest number
Format as 3-digit: 001, 002, 003...
```

**Basic Report Metadata Section**:
```markdown
## Metadata

- **Date**: YYYY-MM-DD
- **Agent**: agent-name
- **Topic**: descriptive topic
- **Report Type**: [type of analysis]
- **Time Range**: [start] to [end] (for error analysis)
```

### 3. Similar Commands with Report Generation

#### 3.1 /repair Command (Primary Pattern)

**File**: `/home/benjamin/.config/.claude/commands/repair.md`

**Architecture**:
- Frontmatter declares: `command-type: utility`, `dependent-agents: repair-analyst, plan-architect`
- Block 1: Setup (parse arguments, initialize state machine, transition to RESEARCH state)
- Task: Invokes `repair-analyst` agent with error filters
- repair-analyst creates: `.claude/specs/{NNN_error_repair}/reports/{NNN}_repair_analysis.md`
- Agent returns: `REPORT_CREATED: [path]` signal
- Block 2: Verification (verify report exists, transition to PLAN state)
- Task: Invokes `plan-architect` agent with analysis report
- Plan-architect creates: `.claude/specs/{NNN_error_repair}/plans/{NNN}_fix_plan.md`

**Key Observation**: repair-analyst is NOT a haiku model (it's sonnet-4.5 for complex analysis). However, for the `/errors` command requirement of "conserving context," a haiku agent is appropriate for basic error report generation.

#### 3.2 /plan Command (Orchestration Pattern)

**File**: `/home/benjamin/.config/.claude/commands/plan.md` (427 lines)

**Agent Invocation Pattern**:
```markdown
## TASK: Request Research Report

YOU MUST invoke the research-specialist agent to analyze the feature description and produce a research report.

RESEARCH_TOPIC="{feature description}"
REPORT_OUTPUT_DIR="{specs_dir}/reports"
RESEARCH_COMPLEXITY="{complexity level}"

[Task details with specific parameters]

Complete signal expected: `REPORT_CREATED: [path]`
```

### 4. Haiku Model Usage Pattern

**Context**: Haiku models appropriate for agents that conserve token usage

**Guideline from research-specialist.md**:
- sonnet-4.5 specified for comprehensive 28-criteria completion
- Haiku appropriate for: pattern detection, basic analysis, filtering, summary generation
- Token budget considerations: Haiku ~4x cheaper than Sonnet, 100K context window

**Recommendation for errors-analyst**:
- **Model**: Claude Haiku (claude-3-5-haiku-20241022 or current variant)
- **Justification**: Error log analysis, pattern detection, basic report generation (~500-1500 tokens per report)
- **Fallback**: sonnet-4.5 if analysis becomes complex

### 5. Agent File Structure Pattern

**Reference File**: `/home/benjamin/.config/.claude/agents/research-specialist.md` (686 lines)

**Required Sections for new errors-analyst agent**:

1. **Frontmatter** (lines 1-7):
   ```yaml
   ---
   allowed-tools: Read, Write, Grep, Glob, Bash
   description: Analyze error logs and create basic report artifacts
   model: haiku
   model-justification: Error log analysis with pattern detection for basic reports, conserving context
   fallback-model: sonnet-4.5
   ---
   ```

2. **Research Execution Process** (lines 11+):
   - STEP 1: Receive and verify report path (absolute paths only)
   - STEP 1.5: Ensure parent directory exists (lazy creation pattern)
   - STEP 2: Create report file FIRST with initial structure
   - STEP 3: Conduct research and update report incrementally
   - STEP 4: Verify file exists and completion

3. **Progress Markers**:
   - `PROGRESS: Creating report file at [path]`
   - `PROGRESS: Starting research on [topic]`
   - `PROGRESS: Analyzing N files found`
   - `PROGRESS: Updating report with findings`
   - `PROGRESS: Research complete, report verified`

4. **Completion Criteria** (28 required):
   - File creation (absolute paths, Write tool used)
   - Content completeness (metadata, findings, recommendations)
   - Research quality (multiple sources, specific evidence)
   - Process compliance (all 4 steps completed)
   - Return format (REPORT_CREATED: path only)

### 6. Basic Error Report Structure for /errors Command

**Proposed Report Format** for errors-analyst agent output:

```markdown
# Error Analysis Report

## Metadata

- **Date**: YYYY-MM-DD
- **Agent**: errors-analyst
- **Errors Analyzed**: N errors
- **Time Range**: [start_time] to [end_time]
- **Filters Applied**: [command/type/since/severity if any]

## Executive Summary

[2-3 sentences summarizing key findings: total errors, most common type, most affected command]

## Error Overview

- **Total Errors**: N
- **Error Types Found**: [list]
- **Commands Affected**: [list]
- **Date Range**: [start] to [end]

## Top Errors by Frequency

### Error Pattern 1: [error type - count]
- **Occurrences**: N
- **Affected Commands**: [list]
- **Examples**: [sample error messages or error_ids]

### Error Pattern 2: [error type - count]
- **Occurrences**: N
- **Affected Commands**: [list]
- **Examples**: [sample error messages]

## Error Distribution

### By Type
- state_error: N
- validation_error: N
- agent_error: N
- [other types]: N

### By Command
- /build: N
- /plan: N
- [other commands]: N

## Recommendations

1. [Specific action for most common error type]
2. [Pattern-based fix recommendation]
3. [Prevention/monitoring recommendation]

## References

- Error Log: .claude/data/logs/errors.jsonl
- Analysis Date: [date]
- Report Created By: errors-analyst (haiku subagent)
```

### 7. /errors Command Refactor Requirements

**Refactoring Approach** (minimal changes to preserve existing functionality):

1. **Add Task invocation for analysis**:
   - Parse error filters from arguments
   - Create description for topic naming
   - Invoke errors-analyst agent via Task
   - Receive REPORT_CREATED signal with path

2. **Preserve existing query functionality**:
   - Keep `--query` or `--raw` mode for direct log queries (backward compatibility)
   - Default behavior: generate report via agent

3. **Output format**:
   - Display brief summary (total errors, top types)
   - Provide path to generated report
   - Example: "Error analysis complete. Report: specs/886_error_analysis/reports/001_error_report.md"

4. **Frontmatter updates**:
   - Add: `dependent-agents: errors-analyst`
   - Add: `library-requirements: workflow-state-machine.sh >=2.0.0`
   - Modify allowed-tools to include: Task, Write, Glob

### 8. Context Conservation Benefits

**Why Haiku Model for errors-analyst**:

1. **Token Budget**: Haiku ~4x cheaper, sufficient for log analysis
2. **Speed**: Faster response times for straightforward analysis
3. **Context Efficiency**: Allows main command to remain light weight
4. **Isolation**: Agent handles error parsing/analysis independently
5. **Modularity**: Can be reused by other error analysis workflows

**Example Token Usage**:
- Reading error log: 500-1000 tokens
- Analysis and pattern detection: 300-800 tokens
- Report generation: 200-400 tokens
- Total per report: ~1000-2200 tokens (well within haiku capability)

### 9. Integration with Error Management Workflow

**Complete Error Management Workflow** (from CLAUDE.md):

1. **Error Production** (automatic): Commands log to `.claude/data/logs/errors.jsonl`
2. **Error Querying** (`/errors`): View logs with filters
3. **Error Analysis** (`/repair` or new `/errors --analyze`): Group errors, identify patterns
4. **Fix Implementation** (`/build`): Execute repair plans

**Proposed Enhancement**:
- `/errors` (default): Generate analysis report via haiku agent (NEW)
- `/errors --query`: Legacy query mode (existing functionality preserved)
- Output flows to `/repair` for fix planning if needed

### 10. Standards Compliance Checklist

**Applicable Standards**:

1. **Directory Protocols** (directory-protocols.md):
   - Topic-based structure: `specs/{NNN_topic}/`
   - Report numbering: 001, 002, 003...
   - Artifact directories: `reports/`, `plans/`
   - ✓ Applicable: errors-analyst will follow this pattern

2. **Command Authoring** (command-authoring.md):
   - Execution directives: `**EXECUTE NOW**:` for each bash block
   - Task invocation: No code wrapper around Task {}
   - Subprocess isolation: `set +H` in each block
   - State persistence: Use state machine for cross-block variables
   - ✓ Applicable: /errors refactor must follow these patterns

3. **Agent Development** (research-specialist.md):
   - 4-step process: Receive path, ensure directory, create file, verify
   - Progress markers: Required at each milestone
   - 28 completion criteria: All must be met
   - Return format: `REPORT_CREATED: [path]` only
   - ✓ Applicable: errors-analyst must follow these patterns

4. **Error Handling** (error-handling.md in CLAUDE.md):
   - All commands log errors via error-handling.sh
   - Error types: state_error, validation_error, agent_error, parse_error, file_error, timeout_error, execution_error
   - ✓ Applicable: errors-analyst will read from centralized error log

## Recommendations

### 1. Create errors-analyst Haiku Agent (Priority: High)

**File**: Create `/home/benjamin/.config/.claude/agents/errors-analyst.md`

**Structure**:
- Follow research-specialist.md pattern exactly
- Use Haiku model for context conservation
- Implement 4-step process (receive path, ensure directory, create file, verify)
- Emit progress markers at each step
- Include 28 completion criteria checklist

**Implementation Notes**:
- Read error logs: `.claude/data/logs/errors.jsonl`
- Parse JSONL format for error entries
- Group by error_type, command, timestamp patterns
- Identify top N errors by frequency
- Generate markdown report with structured sections
- Return: `REPORT_CREATED: [absolute_path]`

### 2. Refactor /errors Command to Use Agent (Priority: Medium)

**Changes to `/home/benjamin/.config/.claude/commands/errors.md`**:

1. Update frontmatter:
   - Add: `dependent-agents: errors-analyst`
   - Add: `library-requirements: workflow-state-machine.sh >=2.0.0`
   - Update allowed-tools to include: Task, Write, Glob

2. Add Block 1: Setup and Agent Invocation
   - Parse optional filter arguments
   - Create error analysis description
   - Initialize workflow paths
   - Invoke errors-analyst via Task
   - Verify REPORT_CREATED signal

3. Add Block 2: Verification and Summary
   - Verify report file exists
   - Read report for summary statistics
   - Display brief summary to user
   - Provide path to full report

4. Preserve legacy query functionality:
   - Add `--query` flag for direct error log queries (existing behavior)
   - Default (no flags): Generate and display report

### 3. Document in Command Reference (Priority: Medium)

**Updates Needed**:
1. Update `.claude/docs/reference/standards/command-reference.md` to document /errors command
2. Add /errors to guides/commands/README.md index
3. Cross-reference /errors ↔ /repair in both command guides

### 4. Agent Completion Criteria Template

Create as template section in errors-analyst.md:

```
## COMPLETION CRITERIA - ALL REQUIRED

Before completing your task, YOU MUST verify ALL of these criteria:

### File Creation (ABSOLUTE REQUIREMENTS)
- [ ] Report file exists at exact path specified in Step 1
- [ ] File path is absolute (not relative)
- [ ] File was created using Write tool (not accumulated in memory)
- [ ] File size is >300 bytes (indicates substantial content)

### Content Completeness (MANDATORY SECTIONS)
- [ ] Metadata section complete (date, agent, report type, filters)
- [ ] Executive Summary is 2-3 sentences (not placeholder)
- [ ] Error Overview has total count and affected commands
- [ ] Top Errors section lists at least 3 error patterns
- [ ] References section includes error log path

### Research Quality (NON-NEGOTIABLE)
- [ ] At least 10 error entries analyzed from log
- [ ] All error types found documented
- [ ] Frequency counts provided for each pattern
- [ ] All conclusions supported by specific error entries
- [ ] Recommendations are actionable (specific next steps)

### Process Compliance (CRITICAL)
- [ ] STEP 1 completed: Absolute path received and verified
- [ ] STEP 2 completed: Report file created FIRST
- [ ] STEP 3 completed: Research conducted and file updated
- [ ] STEP 4 completed: File verified and completion signal returned
- [ ] All progress markers emitted at required milestones

### Return Format (STRICT REQUIREMENT)
- [ ] Return format is EXACTLY: `REPORT_CREATED: [absolute-path]`
- [ ] No summary text returned (orchestrator reads file)
- [ ] Path matches exactly from Step 1
```

## References

### Analyzed Files

1. `/home/benjamin/.config/.claude/commands/errors.md` (233 lines)
   - Current /errors command implementation
   - Lines 1-12: Frontmatter (minimal tool set)
   - Lines 14-179: Bash execution block

2. `/home/benjamin/.config/.claude/commands/repair.md` (403 lines)
   - Example of command with agent delegation
   - Lines 6-8: dependent-agents declaration
   - Task invocation for repair-analyst agent

3. `/home/benjamin/.config/.claude/commands/plan.md` (427 lines)
   - Multi-phase workflow with research-specialist
   - Task invocation pattern for agent collaboration

4. `/home/benjamin/.config/.claude/agents/research-specialist.md` (686 lines)
   - Template for agent implementation
   - 4-step process pattern
   - Completion criteria template (28 items)

5. `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` (367 lines)
   - Comprehensive documentation of current /errors functionality
   - Usage patterns and examples

6. `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` (504 lines)
   - Documentation of /repair workflow with agent delegation
   - Error analysis and planning patterns

7. `/home/benjamin/.config/.claude/specs/835_standards_and_adequately_documented_in_claude/reports/001_errors_command_standards_compliance_report.md` (606 lines)
   - Compliance analysis of existing /errors command
   - Documentation standards evaluation

8. `/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/reports/001_errors_command_refactor_research.md` (420 lines)
   - Previous research on /errors refactoring to use workflows
   - Architecture design recommendations

### Key Documentation Sections

- CLAUDE.md: Error Logging Standards section (line 88-114)
- command-authoring.md: Task tool invocation, execution directives, state persistence
- directory-protocols.md: Topic-based structure, report numbering
- agent-reference.md: Agent tool access matrix

## Conclusion

The `/errors` command can be efficiently refactored to create basic report artifacts by delegating analysis to a specialized `errors-analyst` haiku subagent. This approach:

1. **Conserves context**: Haiku model reduces token usage by ~75% vs. Sonnet
2. **Follows patterns**: Mirrors successful `/repair` and `/plan` implementations
3. **Maintains functionality**: Preserves existing query capabilities via `--query` flag
4. **Enables discoverability**: Creates permanent artifact files for reference and automation
5. **Integrates seamlessly**: Report output feeds into `/repair` workflow for fix planning

**Implementation Roadmap**:
- Phase 1: Create errors-analyst haiku agent (650 lines, ~2-3 hours)
- Phase 2: Refactor /errors command (400 lines, ~2-3 hours)
- Phase 3: Update documentation and cross-references (1-2 hours)
- Phase 4: Testing and verification (1-2 hours)

**Estimated Total Effort**: 6-10 hours for complete implementation

---

**Report Generated**: 2025-11-20
**Complexity Level**: 3
**Research Status**: Complete
**Confidence Level**: High (comprehensive pattern analysis of existing implementations)

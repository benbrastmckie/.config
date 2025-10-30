# Debugging Strategies for Orchestration Commands

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: 543_coordinate_command_branch_failure_analysis
- **Report Type**: codebase analysis
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

Orchestration commands in this project employ sophisticated debugging infrastructure including checkpoint-based recovery, unified logging, and hierarchical agent coordination. Effective debugging requires understanding the log analysis techniques for tracing execution flow across multiple bash functions, verification checkpoints that enable fail-fast error handling, and comparative analysis patterns between working and broken command versions.

## Findings

### Log Analysis Techniques

The project implements a unified logging system that captures detailed execution traces across all orchestration workflows. The logging infrastructure is located in `.claude/lib/unified-logger.sh` (lines 1-95) and provides structured logging with timestamps, context, and severity levels.

**Checkpoint Logging** (.claude/lib/checkpoint-utils.sh, lines 1-60):
- Saves command state at predefined checkpoints to `.claude/data/checkpoints/`
- Checkpoint schema version 1.3 includes: workflow_id, plan_path, current_phase, completed_phases, phase_metadata, replan_history, replan_count
- Each checkpoint stores: phase status, artifacts created, duration, execution timestamps
- Replan history tracked to prevent infinite loops (max 2 replans per phase enforced)
- Log rotation configured in unified-logger.sh (lines 59-95): 10MB max per file, 5 files retained

**Structured Logging Components**:
- Adaptive planning logs at `.claude/data/logs/adaptive-planning.log` capturing complexity decisions
- Conversion logs for doc processing workflows (configurable via CONVERSION_LOG_FILE)
- All logs include full execution context: timestamp, level, category, message (format: YYYY-MM-DD HH:MM:SS)

**Log Structure**:
- Phase-level logs in unified-logger.sh containing task execution details
- Error classification (transient, permanent, fatal) in error-handling.sh (lines 12-42)
- Variable snapshots in checkpoint files capturing state at decision points
- Timestamps enable performance analysis: phase duration in minutes, actual vs estimated time

### Execution Flow Tracing in Complex Bash Commands

The orchestration commands use multiple structural patterns to make tracing easier:

**Wave-Based Execution Pattern** (/coordinate command, lines 1-100):
- Executes independent tasks in parallel waves within workflow phases
- Each wave completes before next wave begins (Phase 0 → Phase 1 → Phase 2...)
- Enables clear division of execution flow into observable stages
- Agent invocations tracked in task results with PROGRESS: markers
- Wave structure captured in checkpoint files: `{"1": [1], "2": [2, 3], "3": [4]}` (wave → phase mapping)

**Phase Dependencies** (directory-protocols.md):
- Plans support explicit phase dependencies using `phase_depends_on` syntax in phase headers
- Dependency graph allows /implement to schedule phases in correct order (topological sort)
- Failed prerequisites prevent dependent phase execution (fail-fast)
- Dependency violations detected immediately with error message showing blocker
- Reduces cascading failures by stopping at first blocker

**Agent Tracking** (behavioral-injection.md):
- Each agent invocation tracked with unique ID in Task tool
- Agent behavioral files determine execution context (.claude/agents/*.md)
- Agent output returned with explicit completion signals (e.g., `REPORT_CREATED: path`)
- Subagent delegation creates clear parent-child traces via agent context injection
- /coordinate prohibits command chaining to maintain observable control flow (lines 70-100)

**Error Propagation** (error-handling.sh, lines 1-42):
- Bash set -euo pipefail prevents silent failures in all shell functions
- Each function returns explicit exit codes (0 for success, non-zero for failure)
- Error classification in error-handling.sh: transient (retry), permanent (analyze), fatal (escalate)
- Errors logged with full context: function name, line number, error message, recovery suggestion
- Errors bubble up to top level where centralized error handler applies recovery policy

### Verification Checkpoints and Error Handling

The project implements mandatory verification checkpoints to ensure reliability:

**File Creation Verification** (verified in research-specialist.md STEP 2 and STEP 4):
- All artifact-creating agents use MANDATORY VERIFICATION before proceeding
- Checkpoint pattern: Write tool creates file → bash verification confirms existence → continue
- File verification checks: path exists, size >500 bytes, content not placeholder
- If creation fails, immediate error with diagnostic location and recovery procedure
- Prevents cascading failures where missing artifacts cause downstream errors

**Adaptive Planning Safeguards** (.claude/lib/checkpoint-utils.sh, lines 30-48):
- Replan limit: maximum 2 replans per phase prevents infinite loops (enforced by checkpoint counters)
- Complexity thresholds configured in CLAUDE.md adaptive_planning_config (expansion: 8.0, tasks: 10, files: 10)
- Replan counter stored in checkpoint JSON: `"replan_count": {"3": 1}` (phase 3 has been replanned once)
- Replan history tracked with timestamps: phase number, reason (complexity_exceeded, test_failures), date
- Exceeding limit triggers user escalation (logged warning, no automatic retry)

**Fail-Fast Strategy** (CLAUDE.md development_philosophy):
- Missing files produce immediate, obvious bash errors (no silent fallbacks or graceful degradation)
- Test failures stop implementation immediately via `set -e` (no retry masking in /implement)
- Breaking changes fail loudly: command exits with non-zero code, displays error message, provides recovery steps
- No silent failures: library sourcing errors, function not found, permission denied all visible

**Error Handling Utilities** (.claude/lib/error-handling.sh, lines 1-60):
- Error classification function (lines 16-42): examines error message keywords to classify as transient/permanent/fatal
- Recovery suggestion function (lines 44-60): generates recovery text based on error type
- Centralized formatting with context: error type, affected component, suggested recovery action
- User-friendly error messages distinguish between: code-level issues vs. transient resource issues

### Tools and Techniques for Comparing Versions

Effective debugging often requires comparing working vs. broken implementations:

**Git-Based Comparison**:
- Use `git diff <working-branch> <broken-branch> -- .claude/commands/coordinate.md` to compare command files
- Check commit history with `git log --oneline --decorate` for contextual changes with branch information
- Use `git show <commit> | head -100` to examine specific implementation changes with context
- Branch comparison: `git diff main...feature-branch .claude/lib/` shows library changes only
- Use `git log -p` to view full diffs with commit messages for context

**Log Comparison Techniques**:
- Save logs from working version: `cp .claude/data/logs/ /tmp/working-logs/ 2>/dev/null || mkdir -p /tmp/working-logs/`
- Run failing version, save new logs: `cp .claude/data/logs/ /tmp/broken-logs/`
- Compare timestamps to identify execution divergence: `diff <(grep "^20" /tmp/working-logs/adaptive-planning.log | cut -d' ' -f1-2) <(grep "^20" /tmp/broken-logs/adaptive-planning.log | cut -d' ' -f1-2)`
- Diff log sections to spot missing operations: `diff /tmp/working-logs/adaptive-planning.log /tmp/broken-logs/adaptive-planning.log`

**Phase-Level Analysis** (from checkpoint-recovery.md):
- Extract phase metadata from checkpoints: Each checkpoint contains phase_metadata with status, artifacts, duration
- Compare phase execution times: `jq '.phase_metadata."3".duration_minutes' checkpoint_working.json` vs `checkpoint_broken.json`
- Identify missing phases: Count phases in working vs. broken: `jq '.completed_phases | length' checkpoint.json`
- Check if dependent phases blocked: Review replan_history to see if dependency violations triggered replans

**Agent Output Inspection** (orchestration-troubleshooting.md section 2):
- Agent outputs returned as Task result values (not written to separate files in standard flow)
- For /coordinate: agent outputs captured as PROGRESS: markers and completion signals (REPORT_CREATED:, PLAN_CREATED:)
- Compare agent return values between runs to identify delegation behavior changes
- Check if agents invoked correct number of times: Count PROGRESS: markers in log

**Checkpoint Comparison**:
- Load checkpoint files: `.claude/data/checkpoints/implement_*.json` (JSON format for parsing)
- Compare state at each phase: `jq '.phase_metadata."2"' checkpoint_working.json` shows phase 2 state
- Verify variable state at decision points captured in replan_history
- Identify where state divergence begins by comparing replan_count at each phase

### Troubleshooting Guide Resources

The project includes comprehensive troubleshooting documentation:

**Orchestration Troubleshooting Guide** (.claude/docs/guides/orchestration-troubleshooting.md, lines 1-250):
- Section 1: Bootstrap Failures - Library sourcing errors, function not found, SCRIPT_DIR validation (lines 43-145)
- Section 2: Agent Delegation Issues - 0% delegation rate, template variables not substituted, anti-pattern detection (lines 147-249)
- Quick diagnostic checklist (lines 17-41): 5-step verification to identify failure category
- Validation script: `./.claude/lib/validate-agent-invocation-pattern.sh` detects YAML block anti-patterns
- Recovery procedures for each failure type with example commands

**Diagnostic Checklist** (orchestration-troubleshooting.md lines 17-41):
```bash
# 1. Bootstrap check: /command-name "test" 2>&1 | head -20
# 2. Agent delegation: /command-name "test" 2>&1 | grep "PROGRESS:"
# 3. File creation: find .claude/specs -name "*.md" -mmin -5
# 4. Fallback detection: ls .claude/TODO*.md 2>/dev/null
# 5. Pattern validation: ./.claude/lib/validate-agent-invocation-pattern.sh
```

**Command-Specific Guides**:
- /coordinate: Wave-based execution (lines 1-100 of coordinate.md shows phase 0 architecture)
- /orchestrate: Full-featured orchestration with PR automation
- /supervise: Sequential orchestration with proven compliance

**Verification Patterns** (.claude/docs/concepts/patterns/verification-fallback.md):
- Mandatory verification checkpoint framework: create → verify → proceed
- File creation reliability patterns: Write tool + bash stat for atomic operations
- Fail-fast approach: errors surface immediately, no silent failures
- State persistence via checkpoints for recovery

## Recommendations

### 1. Systematic Log Analysis Workflow

Implement a structured approach to debugging using logs:
- Start with latest log file at `.claude/data/logs/coordinate.log` or equivalent
- Extract phase-level information to identify where failure occurred
- Use grep to filter error patterns: `grep -i "error\|failed\|exception" logs/`
- Compare timestamps to identify performance anomalies
- For async failures, check agent output files for subagent-specific errors
- Document findings in debug reports for pattern recognition

**Evidence**: Log structure documented in CLAUDE.md adaptive_planning section; checkpoint utilities expose full query interface for forensic access

### 2. Execution Flow Tracing with Phase Dependencies

When debugging complex orchestration failures:
- Map phase dependencies using plan structure (available in specification files)
- Trace which phases actually executed vs. which were expected
- Use checkpoint data to verify state at each phase boundary
- Identify if failure is in phase logic or in phase ordering
- Check if dependent phases were correctly blocked by prerequisites
- Verify wave boundaries in parallel execution (for /coordinate)

**Evidence**: Phase dependency syntax and wave-based execution documented in .claude/docs/concepts/directory-protocols.md; /coordinate implements explicit wave stages

### 3. Comparative Analysis Between Versions

For regression debugging:
- Create git branches to isolate versions before comparison
- Use `git diff` at both command and function level
- Compare checkpoint files from both versions (timestamps, state variables)
- Log comparison: save both runs, use diff tool to find divergence points
- Test with minimal reproduction case (single phase if possible)
- Document all differences found to build hypothesis about root cause

**Evidence**: Verify strategy available via git workflow in project standards; checkpoint utilities provide structured state for comparison

### 4. Mandatory Verification Checkpoints

When implementing fixes or debugging:
- Insert verification checkpoints after each file creation (recommended: immediately after Write operations)
- Use explicit file existence checks: `[ -f "$path" ] || exit 1`
- Capture artifact paths to verify they match expectations
- Log checkpoint results to aid forensic analysis
- Prevent cascading failures by stopping at first missing artifact
- Document verification procedures in plan implementation sections

**Evidence**: Verification and fallback pattern documented in .claude/docs/concepts/patterns/verification-fallback.md; all commands enforce MANDATORY VERIFICATION checkpoints

### 5. Agent Delegation Debugging

For failures in hierarchical agent architectures:
- Enable detailed agent logging in each subagent invocation
- Capture subagent output to separate files for isolated analysis
- Verify agent return values match expected format (metadata extraction for reporting agents)
- Check parent-child communication: verify context passing between levels
- Use metadata extraction pattern to identify if reports created correctly
- Compare agent outputs to identify where delegation broke

**Evidence**: Hierarchical agent architecture documented in CLAUDE.md; behavioral injection pattern and agent reference available at .claude/docs/reference/agent-reference.md

## References

### Logging and Checkpoint Utilities
- /home/benjamin/.config/.claude/lib/unified-logger.sh - Structured logging implementation
- /home/benjamin/.config/.claude/lib/checkpoint-utils.sh - Checkpoint management (lines 1-50: checkpoint save/load, lines 51-100: state recovery)
- /home/benjamin/.config/.claude/lib/adaptive-planning.sh - Adaptive planning with replan limits
- /home/benjamin/.config/.claude/data/logs/ - Runtime log storage directory

### Error Handling and Verification
- /home/benjamin/.config/.claude/lib/error-handling.sh - Error formatting and diagnostics
- /home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md - Verification checkpoint patterns
- /home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md - Checkpoint recovery framework

### Execution Flow and Phase Management
- /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md - Phase dependency syntax and organization
- /home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md - Wave-based execution patterns
- /home/benjamin/.config/.claude/commands/coordinate.md - Wave-based orchestration implementation

### Troubleshooting Documentation
- /home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md - Complete troubleshooting procedures
- /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md - Best practices including debugging procedures
- /home/benjamin/.config/.claude/docs/reference/command-reference.md - Command capabilities and limitations

### Agent Architecture
- /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md - Agent invocation patterns and debugging
- /home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md - Report structure verification
- /home/benjamin/.config/.claude/docs/reference/agent-reference.md - Agent specifications and output formats


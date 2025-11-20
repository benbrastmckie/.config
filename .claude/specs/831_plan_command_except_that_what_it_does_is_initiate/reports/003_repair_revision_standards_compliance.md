# /repair Command Revision Research - Standards Compliance and Infrastructure Integration

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Plan revision insights for standards compliance and infrastructure integration
- **Report Type**: codebase analysis

## Executive Summary

The /repair command plan shows solid understanding of the research-and-plan workflow pattern but has several compliance gaps requiring revision. Key issues include: (1) missing Phase 1 task for repair-analyst agent which plans to add "analyze_error_patterns()", "get_error_statistics()", and "extract_root_causes()" functions that don't exist - Phase 5 should be merged or ordered before Phase 1; (2) potential naming confusion with existing debug-analyst agent which also performs root cause analysis; (3) missing --severity flag in error-handling.sh query_errors function; (4) agent-registry.json needs updating with repair-analyst entry; (5) documentation location should follow established command guide pattern.

## Findings

### 1. Standards Compliance Analysis

#### Command Authoring Standards Compliance

**Compliant Patterns Identified**:
- Plan correctly uses `dependent-agents` and `library-requirements` frontmatter (command-authoring.md lines 1-14)
- Plan correctly identifies 3-block structure: Setup, Research Verification, Completion
- Plan correctly identifies Task invocation pattern with completion signals (REPORT_CREATED, PLAN_CREATED)
- Plan specifies `set +H` requirement for bash blocks
- Plan references `--complexity` flag support

**Non-Compliant Patterns**:

1. **Missing Execution Directives**: The plan shows bash blocks but doesn't explicitly mention "EXECUTE NOW" directive requirement from command-authoring.md lines 16-48. The plan's bash examples need these directives.

2. **Missing State Persistence Pattern**: Plan Phase 2 shows "Persist state variables with append_workflow_state()" but doesn't show the STATE_FILE initialization pattern from command-authoring.md lines 229-267.

3. **Agent Tool Mismatch**: Plan Phase 1 specifies repair-analyst should have "allowed-tools: Read, Write, Grep, Glob, Bash" but the corresponding functions (`analyze_error_patterns()`, `get_error_statistics()`, `extract_root_causes()`) are planned for Phase 5 - this creates a circular dependency.

#### Agent Reference Standards Compliance

**Compliant**:
- Plan uses research-specialist pattern with 28+ completion criteria
- Plan specifies model selection (sonnet-4.5) with justification
- Plan includes progress streaming markers requirement

**Non-Compliant**:

1. **Agent Naming Convention Issue**: The plan proposes `repair-analyst` but there's already a `debug-analyst` agent (agent-registry.json lines 108-125) that "investigates potential root causes in parallel". This creates semantic overlap:
   - debug-analyst: "Investigate potential root cause for test failure or bug"
   - repair-analyst (proposed): "Error log analysis and root cause detection"

   Both perform root cause analysis. Consider naming alternatives:
   - `error-analyst` - focuses on JSONL error log analysis specifically
   - `log-analyst` - emphasizes log processing
   - `error-pattern-analyst` - emphasizes pattern detection

2. **Missing Agent Registry Entry**: The plan doesn't mention updating agent-registry.json which is required for agent metrics tracking.

3. **Missing Tool Access Matrix Update**: agent-reference.md lines 298-314 has a Tool Access Matrix that needs repair-analyst entry.

#### Testing Protocols Compliance

**Compliant**:
- Plan includes test file creation: test_repair_workflow.sh
- Plan references test isolation standards

**Non-Compliant**:

1. **Missing Agent Behavioral Compliance Tests**: Plan Phase 6 shows generic tests but doesn't include the specific behavioral compliance tests from testing-protocols.md lines 39-186:
   - File Creation Compliance test
   - Completion Signal Format test
   - STEP Structure Validation test
   - Imperative Language Validation test
   - Verification Checkpoints test
   - File Size Limits test

### 2. Infrastructure Integration Analysis

#### error-handling.sh Integration (lines 1-1239)

**Existing Functions Available**:
- `query_errors()` (lines 578-644) - Already supports --command, --since, --type, --limit, --workflow-id filters
- `recent_errors()` (lines 646-695) - Human-readable recent errors
- `error_summary()` (lines 697-743) - Summary with counts by command and type
- `classify_error()` (lines 29-55) - Error classification
- `detect_error_type()` (lines 90-141) - Detailed error type detection

**Missing Functions Required by Plan**:
- `analyze_error_patterns()` - Not present
- `get_error_statistics()` - Not present
- `extract_root_causes()` - Not present

**Critical Issue**: Phase 5 of the plan adds these functions to error-handling.sh, but Phase 1 creates the repair-analyst agent that depends on them. This is a **dependency violation** - Phase 5 must be completed before Phase 1.

**Severity Filter Missing**: The plan mentions `--severity` flag (Phase 2) but `query_errors()` in error-handling.sh doesn't support severity filtering. This requires adding to both:
1. The JSONL log schema (adding severity field to `log_command_error()`)
2. The `query_errors()` function (adding severity filter)

#### Workflow State Machine Integration

**Pattern Match**: The plan correctly follows /plan command pattern (plan.md lines 1-427):
- 3-block structure
- sm_init() and sm_transition() calls
- STATE_RESEARCH, STATE_PLAN, STATE_COMPLETE transitions
- append_workflow_state() for cross-block persistence

**Issue**: Plan references `research-and-plan` workflow scope which is correct for the pattern but should document this maps to terminal state "plan" (not "complete").

#### Agent Invocation Pattern

**Correct Pattern Used** (from plan.md lines 206-230):
```
Task {
  subagent_type: "general-purpose"
  description: "..."
  prompt: "Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent].md
    ...
    Return: SIGNAL_NAME: ${PATH}"
}
```

### 3. Redundancy/Inconsistency Analysis

#### Functional Overlap with Existing Components

1. **debug-analyst vs repair-analyst Overlap**:
   - debug-analyst.md lines 1-463: Root cause analysis for bugs/test failures
   - repair-analyst (proposed): Root cause analysis for error logs

   Key difference: debug-analyst investigates live bugs with hypothesis testing; repair-analyst analyzes historical error logs for patterns.

   **Recommendation**: The distinction is valid but naming should clarify:
   - `error-log-analyst` or `error-pattern-analyst` would be clearer

2. **/errors vs /repair Overlap**:
   - /errors: Query utility (160 lines, simple)
   - /repair: Analysis + planning workflow (complex)

   This is appropriate - /errors queries, /repair analyzes and plans fixes.

3. **error_summary() vs proposed statistics functions**:
   - `error_summary()` exists and provides counts by command/type
   - Plan proposes `get_error_statistics()` with similar function

   **Recommendation**: Extend `error_summary()` rather than create new function, or clearly differentiate (e.g., `get_error_statistics()` returns JSON, `error_summary()` prints human-readable).

#### Naming Conventions

**Established Patterns**:
- Commands: `/verb` or `/verb-noun` (plan, build, debug, errors, convert-docs)
- Agents: `role-type` (research-specialist, debug-analyst, plan-architect)

**Analysis**:
- `/repair` follows `/verb` pattern - **compliant**
- `repair-analyst` follows `role-type` pattern - **compliant** but semantic overlap concern

### 4. Documentation Integration Analysis

#### Guide File Location

**Pattern**: All commands with guides use `.claude/docs/guides/commands/{command}-command-guide.md`

Examples found:
- debug-command-guide.md
- plan-command-guide.md
- build-command-guide.md
- research-command-guide.md

**Requirement**: Create `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md`

Plan Phase 6 only mentions:
- "Create command documentation for new /repair command"

**Issue**: Plan doesn't specify guide file path following the established naming pattern.

#### Agent Reference Updates

**Required Updates**:
1. Add repair-analyst to agent-reference.md:
   - Agent Directory section (alphabetical)
   - Tool Access Matrix (line 298-314)
   - Agent Selection Guidelines section

2. Update agents/README.md:
   - Command-to-Agent Mapping section
   - Available Agents section

### 5. Clean-Break Requirements Analysis

#### Dependencies Needing Updates

1. **agent-registry.json** - Add repair-analyst entry with:
   - type: "specialized"
   - category: "analysis" or "debugging"
   - tools: ["Read", "Write", "Grep", "Glob", "Bash"]
   - behavioral_file: ".claude/agents/repair-analyst.md"

2. **error-handling.sh** - Extend with:
   - severity field in log schema
   - severity filter in query_errors()
   - New analysis functions (or extend existing)

3. **CLAUDE.md** - Add to project commands section:
   - /repair command with usage

#### Infrastructure Improvements Needed

1. **Severity Logging**: Add severity field to `log_command_error()` (line 407-487):
   ```bash
   # Add severity parameter
   log_command_error() {
     local command="${1:-unknown}"
     ...
     local severity="${8:-medium}"  # NEW
     ...
   }
   ```

2. **Pattern Detection Functions**: Either:
   - Add to error-handling.sh as planned
   - Or have repair-analyst compute these inline (simpler, no library changes)

   **Recommendation**: Have repair-analyst compute patterns inline using jq queries on the JSONL log, avoiding library changes that other commands don't need.

## Recommendations

### Critical Revisions Required

1. **Reorder Phase Dependencies**: Move Phase 5 (helper functions) before Phase 1 (agent creation), or merge Phase 5 into Phase 1. Current order creates circular dependency.

2. **Rename Agent**: Consider `error-pattern-analyst` or `error-log-analyst` to differentiate from debug-analyst which also does root cause analysis.

3. **Add Severity Support**: Include subtasks for:
   - Adding severity field to log_command_error()
   - Adding severity filter to query_errors()
   - Document severity levels (low, medium, high, critical)

4. **Update Documentation Paths**: Specify exact paths:
   - Guide: `.claude/docs/guides/commands/repair-command-guide.md`
   - Agent docs: Update agent-reference.md and agents/README.md

5. **Add Agent Registry Update**: Phase 6 must include updating agent-registry.json.

### Important Additions

6. **Add Behavioral Compliance Tests**: Phase 6 should include all 6 behavioral test types from testing-protocols.md.

7. **Simplify Infrastructure**: Consider having repair-analyst compute patterns inline with jq rather than adding new library functions. This follows clean-break principle - new command, minimal coupling.

8. **Add Command Reference Update**: Phase 6 should update CLAUDE.md command reference section.

### Optional Improvements

9. **Consider Metadata Extraction**: Follow research-specialist pattern of metadata-only passing to parent for context efficiency.

10. **Add Resume Support**: Consider checkpoint support for long-running error analysis (not in current plan).

## References

### Standards Documents
- /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md (lines 1-575) - Execution directives, Task patterns, subprocess isolation
- /home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md (lines 1-393) - Agent catalog, tool matrix, invocation patterns
- /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md (lines 1-262) - Test patterns, behavioral compliance, isolation
- /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md (lines 1-118) - Naming conventions, output suppression

### Infrastructure Files
- /home/benjamin/.config/.claude/lib/core/error-handling.sh (lines 1-1239) - Error logging, query functions, state error handler
- /home/benjamin/.config/.claude/commands/plan.md (lines 1-427) - Reference research-and-plan workflow pattern
- /home/benjamin/.config/.claude/commands/errors.md (lines 1-230) - Existing error query command

### Agent Files
- /home/benjamin/.config/.claude/agents/debug-analyst.md (lines 1-463) - Existing root cause analysis agent
- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 1-671) - Pattern for new agent creation
- /home/benjamin/.config/.claude/agents/agent-registry.json (lines 1-288) - Agent registry requiring update

### Documentation Locations
- /home/benjamin/.config/.claude/docs/guides/commands/ - Command guide directory
- /home/benjamin/.config/.claude/agents/README.md (lines 1-150) - Agent documentation index

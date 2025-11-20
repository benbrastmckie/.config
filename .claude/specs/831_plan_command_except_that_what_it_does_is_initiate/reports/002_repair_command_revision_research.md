# Plan Revision Research: Create /repair Command Instead of Modifying /errors

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Plan revision to create /repair command instead of modifying /errors
- **Report Type**: codebase analysis and plan revision guidance
- **Related Plan**: /home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/plans/001_plan_command_except_that_what_it_does_is_plan.md

## Executive Summary

The existing plan refactors `/errors` to add orchestrator workflow capabilities, but the user wants to preserve `/errors` as-is and create a NEW command `/repair`. This revision requires significant restructuring: changing all references from `/errors` to `/repair`, renaming the `error-analyst` agent to `repair-analyst`, updating file paths, adjusting success criteria, and simplifying the design by removing backward compatibility concerns (since `/errors` stays unchanged). The `/repair` command will follow the same `/plan` orchestrator pattern with research-and-plan workflow type.

## Findings

### 1. Current Plan Structure Analysis

**File**: `/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/plans/001_plan_command_except_that_what_it_does_is_plan.md` (lines 1-381)

The existing plan has 6 phases totaling 18 estimated hours:

| Phase | Description | Hours | Impact on Revision |
|-------|-------------|-------|-------------------|
| 1 | Create error-analyst Agent | 4 | Rename to repair-analyst |
| 2 | Refactor /errors Command Structure | 3 | **Replace entirely** - create new /repair command |
| 3 | Integrate error-analyst Agent Invocation | 2 | Update agent name references |
| 4 | Add Research Verification and Planning Phase | 3 | Minor path updates |
| 5 | Add Helper Functions to error-handling.sh | 3 | Keep as-is (useful for /repair) |
| 6 | Documentation and Testing | 3 | Update file names and references |

**Key sections requiring revision**:
- Metadata: Feature description, scope
- Overview: Remove "Maintains backward compatibility"
- Success Criteria: Remove legacy mode criteria
- Technical Design: Update all file paths and command name
- All 6 Phases: Update references and file paths
- Testing Strategy: Remove regression tests for legacy mode

### 2. Orchestrator Pattern Reference

**Files analyzed**:
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-427)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-743)

The `/repair` command should follow the established pattern:

**Frontmatter requirements**:
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: [--since TIME] [--type TYPE] [--command CMD] [--complexity 1-4]
description: Research error patterns and create implementation plan to fix them
command-type: primary
dependent-agents:
  - research-specialist
  - repair-analyst
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
---
```

**Workflow structure** (3 bash blocks + 2 Task invocations):
1. Block 1: Setup, initialize state machine, transition to research
2. Task: repair-analyst agent (error log analysis)
3. Block 2: Verify research, transition to plan
4. Task: plan-architect agent (create fix plan)
5. Block 3: Verify plan, complete workflow

### 3. Workflow Scope Options

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (line 393)

Valid workflow scopes:
- `research-only`
- `research-and-plan`
- `research-and-revise`
- `full-implementation`
- `debug-only`

**Recommendation**: Use `research-and-plan` scope (not `debug-only` as originally proposed)

**Rationale**:
- `/repair` researches errors then creates a plan to fix them
- This matches the research-and-plan pattern exactly
- Terminal state is `plan` (matches original plan)
- No need to modify workflow-initialization.sh

### 4. Existing /errors Command (Preserved)

**File**: `/home/benjamin/.config/.claude/commands/errors.md` (lines 1-230)

The current `/errors` command will remain unchanged:
- Simple query utility with Bash and Read tools
- Options: `--command`, `--since`, `--type`, `--limit`, `--workflow-id`, `--summary`, `--raw`
- Uses `query_errors()`, `recent_errors()`, `error_summary()` functions
- No state machine, no agent invocation

**Key insight**: Since `/errors` stays unchanged, the revised plan:
- Does NOT need backward compatibility mode
- Does NOT need `--query`, `--summary`, `--raw` preservation
- CAN have simpler argument structure focused only on error filtering

### 5. Agent Naming Convention

**Directory**: `/home/benjamin/.config/.claude/agents/`

Existing agent names follow pattern: `{purpose}-{role}.md`
- `debug-analyst.md` - for /debug command
- `research-specialist.md` - for research tasks
- `plan-architect.md` - for plan creation

**Proposed agent name**: `repair-analyst.md`
- Follows existing naming convention
- Clear association with /repair command
- Distinct from `error-analyst` (avoids confusion with error-handling concepts)

### 6. File Path Changes Required

All paths in the plan need updating:

| Original | Revised |
|----------|---------|
| `/errors` command | `/repair` command |
| `errors.md` | `repair.md` |
| `error-analyst.md` | `repair-analyst.md` |
| `test_errors_workflow.sh` | `test_repair_workflow.sh` |
| `debug_state_id.txt` | `repair_state_id.txt` |
| `debug_state_$$.txt` | `repair_state_$$.txt` |

### 7. Success Criteria Simplification

**Original criteria** (7 items):
1. /errors command invokes error-analyst agent
2. Error analysis reports created
3. Plan-architect generates fix plans
4. **Legacy query functionality preserved** (REMOVE)
5. Command authoring standards followed
6. Tests pass
7. Documentation updated

**Revised criteria** (6 items):
1. /repair command invokes repair-analyst agent
2. Error analysis reports created in `specs/{NNN_topic}/reports/`
3. Plan-architect generates fix implementation plans
4. Command authoring standards followed
5. Tests pass for new workflow phases
6. Documentation updated for new command

### 8. Argument Structure for /repair

Since `/errors` handles queries, `/repair` focuses on analysis workflow:

**Proposed arguments**:
- `--since TIME` - Analyze errors since timestamp
- `--type TYPE` - Focus on specific error types
- `--command CMD` - Analyze errors from specific command
- `--severity LEVEL` - Filter by severity (optional)
- `--complexity 1-4` - Research complexity (default: 2)
- `--file PATH` - Read issue description from file

**Not needed** (handled by /errors):
- `--limit` - not relevant for analysis
- `--summary` - /errors provides this
- `--raw` - /errors provides this
- `--query` - /errors is the query interface
- `--workflow-id` - /errors provides this

### 9. Phase-by-Phase Revision Summary

**Phase 1**: Create repair-analyst Agent
- Rename from error-analyst to repair-analyst
- Update file path: `.claude/agents/repair-analyst.md`
- Same capabilities (error log analysis, pattern detection)
- Update testing commands

**Phase 2**: Create /repair Command Structure
- **Complete rewrite** - not refactoring existing
- Create new `.claude/commands/repair.md`
- Use research-and-plan workflow type
- State ID file: `repair_state_id.txt`
- Simpler argument parsing (no legacy modes)

**Phase 3**: Integrate repair-analyst Agent Invocation
- Update Task invocation to reference repair-analyst
- Pass error filters from arguments
- Same completion signal: `REPORT_CREATED: [path]`

**Phase 4**: Add Research Verification and Planning Phase
- Update variable names (REPAIR_DIR instead of DEBUG_DIR)
- Same verification logic
- Same plan-architect invocation

**Phase 5**: Add Helper Functions to error-handling.sh
- Keep as-is - functions are useful regardless
- `analyze_error_patterns()`, `get_error_statistics()`, `extract_root_causes()`
- These functions serve both /errors and /repair

**Phase 6**: Documentation and Testing
- Create test file: `test_repair_workflow.sh`
- Update agent-reference.md with repair-analyst
- Create command documentation for /repair
- **Remove** regression tests for legacy mode

### 10. Phase Dependencies Update

Original dependencies enable parallel execution:
- Phase 5 runs parallel with Phases 2-4

Updated dependencies remain the same pattern but with corrected phase content.

## Recommendations

### 1. Rename agent from error-analyst to repair-analyst

**Impact**: Phase 1, Phase 3, Phase 6
**Files affected**:
- Agent file path
- Task invocations
- Documentation references

This improves naming clarity and distinguishes from error-handling concepts.

### 2. Change workflow type from debug-only to research-and-plan

**Impact**: Phase 2 (Block 1 setup)
**Rationale**:
- research-and-plan matches the actual workflow (research errors → plan fixes)
- Terminal state is `plan` which is correct
- No standards update needed

### 3. Remove all backward compatibility concerns

**Impact**: Overview, Success Criteria, Phase 2, Testing Strategy
**Changes**:
- Remove `--query`, `--summary`, `--raw` flags
- Remove legacy mode detection
- Remove regression testing for legacy mode
- Simplify Technical Design section

### 4. Update all file paths and command references

**Impact**: All phases
**Systematic changes**:
- `/errors` → `/repair`
- `error-analyst` → `repair-analyst`
- `errors.md` → `repair.md`
- Test files and state files

### 5. Simplify argument structure

**Impact**: Phase 2, Technical Design
**Arguments**: `--since`, `--type`, `--command`, `--severity`, `--complexity`, `--file`
**Remove**: `--query`, `--summary`, `--raw`, `--limit`

### 6. Update estimated hours

**Original**: 18 hours
**Revised**: ~16 hours (Phase 2 simplification from refactor to new file creation)

### 7. Preserve helper function phase (Phase 5)

The helper functions in error-handling.sh are valuable for /repair's analysis capabilities and don't need modification based on the command name change.

## References

### Files Analyzed

1. `/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/plans/001_plan_command_except_that_what_it_does_is_plan.md` (lines 1-381)
   - Current plan requiring revision

2. `/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/reports/001_errors_command_refactor_research.md` (lines 1-420)
   - Original research report with pattern analysis

3. `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-427)
   - Reference pattern for research-and-plan workflow

4. `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-743)
   - Reference pattern for multi-phase workflows

5. `/home/benjamin/.config/.claude/commands/errors.md` (lines 1-230)
   - Existing /errors command (to remain unchanged)

6. `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (line 393)
   - Valid workflow scope definitions

7. `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 578-743)
   - Error query and analysis functions

8. `/home/benjamin/.config/.claude/agents/` (directory)
   - Agent naming conventions and existing patterns

### Key Code Locations

- Workflow scopes: `workflow-initialization.sh:393`
- State machine initialization: `plan.md:156-159`
- Task invocation pattern: `plan.md:206-231`
- Research verification: `plan.md:264-283`
- Error log queries: `error-handling.sh:578-744`

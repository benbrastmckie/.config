# Command Protocols File Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: command-protocols.md file origin, dependencies, and relocation analysis
- **Report Type**: codebase analysis

## Executive Summary

The file `/home/benjamin/.config/.claude/specs/standards/command-protocols.md` is **aspirational documentation that was never implemented**. It was created on 2025-10-16 as part of commit `1746b887` ("feat: Implement Phase 5 - Plan Hierarchy Updates") but the protocols it defines (coordination-hub, resource-manager, event message schemas, etc.) are not used anywhere in the codebase. The file can be safely deleted, or if the protocols are desired for future implementation, it should be moved to `.claude/docs/reference/standards/command-coordination-protocols.md`.

## Findings

### 1. File Origin and Creation Context

**Created**: 2025-10-16 in commit `1746b887`
- **Commit message**: "feat: Implement Phase 5 - Plan Hierarchy Updates"
- **Author**: benbrastmckie@gmail.com (Claude-assisted)
- **Path**: `/home/benjamin/.config/.claude/specs/standards/command-protocols.md`
- **File size**: 18,464 bytes (583 lines)

The file was created alongside many other files in that commit, but the commit message focuses on "checkbox utilities for updating plan hierarchies" - there's no mention of command coordination protocols. This suggests the file may have been created speculatively or as part of a larger design document that was never fully implemented.

### 2. File Content Analysis

The file defines comprehensive protocols that are NOT implemented:

**Defined but not used**:
- Event message schema: `EVENT_TYPE:workflow_id:phase:data` (line 13-18)
- Event types: `WORKFLOW_CREATED`, `AGENT_ALLOCATED`, `RESOURCE_THRESHOLD`, `TASK_ASSIGNED` (lines 258-318)
- Resource allocation schema with request/response formats (lines 42-121)
- State synchronization protocols (lines 123-195)
- Communication patterns: Request-Response, Publish-Subscribe (lines 319-346)
- Component registration (lines 404-438)
- Health monitoring (lines 440-470)

**Evidence of non-implementation**:
- Search for `AGENT_ALLOCATED`, `RESOURCE_THRESHOLD`, `TASK_ASSIGNED` found ONLY in command-protocols.md
- Search for `coordination-hub`, `resource-manager` in shell scripts found NO matches
- No shell scripts implement the event message schema format
- The state-based orchestration architecture uses a completely different approach (workflow-state-machine.sh)

### 3. Current References to This File

Only TWO references exist:

1. **TODO.md (line 14)**: `/home/benjamin/.config/.claude/TODO.md`
   - Listed under "research other elements" - suggests this file was flagged for research/evaluation
   - Context: Part of cleanup/refactoring tasks

2. **This research report** (self-reference)

### 4. Comparison with Actual Implementation

The actual orchestration system uses:

**workflow-state-machine.sh** (`.claude/lib/workflow/workflow-state-machine.sh`):
- 8 explicit states: initialize, research, plan, implement, test, debug, document, complete
- Transition table validation
- Checkpoint-based state persistence

**state-persistence.sh** (`.claude/lib/core/state-persistence.sh`):
- GitHub Actions-style workflow state files
- Selective file-based persistence

The command-protocols.md defines a much more complex coordination system with:
- Multiple specialized components (coordination-hub, resource-manager, performance-monitor)
- JSON-based message schemas
- Request-response patterns with correlation IDs
- Health monitoring endpoints

This is a fundamentally different architecture that was never built.

### 5. Specs Directory Purpose

Per the project's directory protocols (`.claude/docs/concepts/directory-protocols.md`), the `specs/` directory is for:
- Temporary artifacts: plans, reports, summaries, debug reports
- Topic-based organization: `specs/{NNN_topic}/`
- Gitignored artifacts (except debug reports)

The `specs/standards/` subdirectory is an anomaly - there's no documentation defining this location, and it contains only this one file. Standards documentation belongs in `.claude/docs/reference/standards/`.

### 6. Similar Documentation in .claude/docs/

Existing standards in `.claude/docs/reference/standards/`:
- `command-authoring.md` - Command development standards
- `command-reference.md` - Complete command catalog
- `testing-protocols.md` - Test protocols
- `code-standards.md` - Coding conventions
- `output-formatting.md` - Output standards
- `agent-reference.md` - Agent catalog

If the command coordination protocols were essential, they would fit alongside these existing standards.

## Recommendations

### 1. Delete the File (Recommended)

**Rationale**: The protocols are not implemented and the actual orchestration system uses a completely different architecture.

**Actions**:
- Delete `/home/benjamin/.config/.claude/specs/standards/command-protocols.md`
- Remove the `specs/standards/` directory (will be empty)
- Remove the reference from `/home/benjamin/.config/.claude/TODO.md` (line 14)

### 2. Alternative: Move to Archive

If you want to preserve the documentation for future reference:
- Move to `.claude/docs/archive/specs/command-coordination-protocols.md`
- Add a header noting it's aspirational/unimplemented

### 3. Alternative: Move to docs/reference/standards (if planning to implement)

If these protocols should be implemented in the future:
- Move to `.claude/docs/reference/standards/command-coordination-protocols.md`
- Update `.claude/docs/reference/standards/README.md` to add entry
- Create implementation tasks to build the described components

### 4. Update TODO.md

Regardless of choice, update TODO.md (line 14) to either:
- Remove the reference (if deleting)
- Update path (if moving)

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/specs/standards/command-protocols.md` (lines 1-583) - The file under investigation
- `/home/benjamin/.config/.claude/TODO.md` (line 14) - Only active reference
- `/home/benjamin/.config/.claude/docs/reference/standards/README.md` (lines 1-26) - Existing standards structure
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` (lines 1-100) - Actual orchestration architecture
- `/home/benjamin/.config/.claude/docs/reference/workflows/orchestration-reference.md` (lines 1-100) - Current orchestration reference
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - Actual state implementation
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - Actual persistence implementation

### Git History

- Commit `1746b887` (2025-10-16): "feat: Implement Phase 5 - Plan Hierarchy Updates" - Created the file

### Search Commands Used

- `grep -r "specs/standards/command-protocols"` - Found 1 reference (TODO.md)
- `grep -r "command-protocols"` - Found 3 files (including this report)
- `grep -r "AGENT_ALLOCATED|RESOURCE_THRESHOLD|TASK_ASSIGNED"` - Found ONLY in command-protocols.md
- `grep -r "coordination-hub|resource-manager" *.sh` - No matches in shell scripts
- `glob "**/*protocol*.md"` - Found 8 protocol-related files

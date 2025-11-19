# Coordinate Command References Cleanup Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Coordinate command references cleanup
- **Report Type**: codebase analysis

## Executive Summary

The `/coordinate` command was properly archived to `.claude/archive/coordinate/` but extensive documentation references remain active across the codebase. Analysis identified **200+ references** to `/coordinate` across 100+ files in active documentation, commands, agents, tests, and library files. The primary cleanup targets are: `/home/benjamin/.config/.claude/commands/README.md` (11 references presenting coordinate as active), `/home/benjamin/.config/CLAUDE.md` (4 references in section metadata), and approximately 90 references in `.claude/docs/` referencing coordinate as if it were still active.

## Findings

### Category 1: Commands README (Critical Priority)

**File**: `/home/benjamin/.config/.claude/commands/README.md`

This file presents `/coordinate` as if it were an active production command:

- **Lines 9-16**: Command Highlights section promotes coordinate as "Production Orchestrator"
- **Lines 34, 88-105**: Full command entry with usage, type, agents, features
- **Line 437**: Listed in Primary Commands section
- **Lines 682, 696**: Referenced in command architecture and navigation
- **Lines 761-764**: Example usage section "Full Workflow with Coordinate"

**Issue**: Contradicts the archive status - commands README shows coordinate as active while command-reference.md correctly marks it as ARCHIVED.

### Category 2: Main CLAUDE.md (High Priority)

**File**: `/home/benjamin/.config/CLAUDE.md`

Section metadata references need updating:

- **Line 75**: `[Used by: /implement, /build, /coordinate, all commands and agents]`
- **Line 118**: `[Used by: /implement, /plan, /coordinate]`
- **Line 125**: `[Used by: /coordinate, /implement, /plan, /debug]`
- **Line 132**: `[Used by: /coordinate, custom orchestrators]`

### Category 3: Agent Documentation (Medium Priority)

**File**: `/home/benjamin/.config/.claude/agents/README.md`

Agent entries still list coordinate as a consumer:

- **Line 179**: plan-architect "Used By Commands: /plan, /revise, /coordinate, /debug"
- **Line 205**: research-specialist "Used By Commands: /plan, /research, /revise, /coordinate, /debug"
- **Line 282**: implementer-coordinator "Used By Commands: /build, /coordinate"
- **Line 795**: research-sub-supervisor coordination reference

### Category 4: Reference Documentation (Medium Priority)

**Directory**: `/home/benjamin/.config/.claude/docs/reference/`

Major files with coordinate references:

- `command-reference.md` - Correctly marks as ARCHIVED (no change needed)
- `orchestration-reference.md` - 20+ references recommending /coordinate for production
- `command_architecture_standards.md` - Historical examples using /coordinate
- `library-api-utilities.md` - Commands list including /coordinate
- `backup-retention-policy.md` - Examples using coordinate

### Category 5: Guide Documentation (Medium Priority)

**Directory**: `/home/benjamin/.config/.claude/docs/guides/`

Key files:

- `README.md:218-228` - Full guide entry for coordinate-command-guide.md (file no longer exists)
- `orchestration-troubleshooting.md` - References /coordinate throughout
- `hierarchical-supervisor-guide.md` - Examples using /coordinate
- `command-development-standards-integration.md` - Case studies with /coordinate

### Category 6: Architecture Documentation (Low Priority)

**Directory**: `/home/benjamin/.config/.claude/docs/architecture/`

Files with references:

- `state-based-orchestration-overview.md` - Migration metrics for /coordinate
- `workflow-state-machine.md` - Lists /coordinate as user
- `README.md` - References coordinate-state-management.md (archived)

### Category 7: Library Files (Low Priority)

**File**: `/home/benjamin/.config/.claude/lib/unified-logger.sh`

- **Lines 716-746**: Functions for coordinate workflow display and temp file cleanup

**File**: `/home/benjamin/.config/.claude/lib/auto-analysis-utils.sh`

- **Lines 226-251**: `coordinate_metadata_updates()` function
- **Lines 517-545**: `coordinate_collapse_metadata_updates()` function

### Category 8: Test Files (Low Priority)

**Directory**: `/home/benjamin/.config/.claude/tests/`

18 test files reference coordinate:

- `test_scope_detection.sh` - Integration tests for /coordinate
- `test_orchestration_commands.sh` - Tests orchestration commands
- `test_coordinate_synchronization.sh.bak` - Backup test file
- `manual_e2e_hybrid_classification.sh` - Manual E2E tests

### Category 9: Backup Files (No Action Needed)

**Directory**: `/home/benjamin/.config/.claude/backups/`

These are historical backups and should not be modified.

## Recommendations

### Recommendation 1: Update Commands README (Critical)

**File**: `/home/benjamin/.config/.claude/commands/README.md`

Actions required:
1. Remove coordinate from "Command Highlights" section (lines 9-16)
2. Add archived section or mark coordinate entry as archived (lines 88-105)
3. Remove from Primary Commands list (line 437)
4. Update navigation to note archive status (line 696)
5. Update or remove "Full Workflow with Coordinate" example (lines 761-764)

### Recommendation 2: Update Main CLAUDE.md Section Metadata

**File**: `/home/benjamin/.config/CLAUDE.md`

Update "Used by" metadata in 4 sections:
- Line 75: Remove `/coordinate` from output formatting
- Line 118: Remove `/coordinate` from development workflow
- Line 125: Remove `/coordinate` from hierarchical agent architecture
- Line 132: Replace `/coordinate` with `/build` for state-based orchestration

### Recommendation 3: Update Agent Documentation

**File**: `/home/benjamin/.config/.claude/agents/README.md`

Update "Used By Commands" for affected agents:
- plan-architect: Remove /coordinate
- research-specialist: Remove /coordinate
- implementer-coordinator: Remove /coordinate

### Recommendation 4: Update Orchestration Reference Guide

**File**: `/home/benjamin/.config/.claude/docs/reference/orchestration-reference.md`

This file heavily recommends /coordinate for production use. Options:
- Option A: Remove /coordinate entries entirely
- Option B: Mark as archived with migration notes (recommended)
- Update command comparison tables
- Update "Quick Recommendation" section

### Recommendation 5: Update Guides README

**File**: `/home/benjamin/.config/.claude/docs/guides/README.md`

Remove entry for coordinate-command-guide.md (lines 218-228) as the file no longer exists in active docs (was moved to archive).

### Recommendation 6: Clean Up Library Functions (Optional)

**Files**: `unified-logger.sh`, `auto-analysis-utils.sh`

Consider:
- Keeping functions for backward compatibility (if other code depends on them)
- Marking functions as deprecated with comments
- Removing if confirmed no longer needed

### Recommendation 7: Archive or Update Test Files (Low Priority)

Test files referencing /coordinate may need:
- Updating to use replacement commands (/build, /plan, /research)
- Archiving alongside the command
- Removing if tests are no longer relevant

## References

### Primary Files Requiring Changes

- `/home/benjamin/.config/.claude/commands/README.md:9-16,34,88-105,437,682,696,761-764`
- `/home/benjamin/.config/CLAUDE.md:75,118,125,132`
- `/home/benjamin/.config/.claude/agents/README.md:179,205,282,795`
- `/home/benjamin/.config/.claude/docs/reference/orchestration-reference.md:21,39,52,58,224,230,259,278,286-287,301-303,309,718,749,813`
- `/home/benjamin/.config/.claude/docs/guides/README.md:218-228`

### Secondary Documentation Files

- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:1323,1331-1336,1353,1593,1642,1672,1706,2418,2580`
- `/home/benjamin/.config/.claude/docs/reference/library-api-utilities.md:194-196`
- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md:3,9,406,753`
- `/home/benjamin/.config/.claude/docs/guides/hierarchical-supervisor-guide.md:55,177,269`
- `/home/benjamin/.config/.claude/docs/guides/command-development-standards-integration.md:317,390,556,696,699,704,754-755`
- `/home/benjamin/.config/.claude/docs/reference/test-isolation-standards.md:46,359,377,585,712`

### Library Files

- `/home/benjamin/.config/.claude/lib/unified-logger.sh:716,744-746`
- `/home/benjamin/.config/.claude/lib/auto-analysis-utils.sh:226-251,517-545`

### Archive Location (For Reference)

- `/home/benjamin/.config/.claude/archive/coordinate/` - Properly archived command, agents, docs, scripts, tests, and libs

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_claude_commands_readmemd_and_likely_else_plan.md](../plans/001_claude_commands_readmemd_and_likely_else_plan.md)
- **Implementation**: [Will be updated by /build]
- **Date**: 2025-11-18

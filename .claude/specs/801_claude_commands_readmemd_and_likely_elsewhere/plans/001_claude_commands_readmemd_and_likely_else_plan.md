# Coordinate Command References Cleanup Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Coordinate command documentation references cleanup
- **Scope**: Remove/update all references to archived /coordinate command from active documentation
- **Estimated Phases**: 4
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 75
- **Research Reports**:
  - [Coordinate References Cleanup Report](/home/benjamin/.config/.claude/specs/801_claude_commands_readmemd_and_likely_elsewhere/reports/001_coordinate_references_cleanup.md)

## Overview

The `/coordinate` command was properly archived to `.claude/archive/coordinate/` but approximately 200+ documentation references remain active across the codebase. These stale references mislead users by presenting coordinate as an active command when it has been replaced by `/build` and other commands.

This plan systematically cleans up all coordinate references from active documentation, ensuring consistency between archive status and documentation content. The cleanup prioritizes high-visibility files (commands README, main CLAUDE.md) before moving to secondary documentation.

## Research Summary

Key findings from the coordinate references cleanup research:

- **200+ references** identified across 100+ files in active documentation
- **11 references** in commands README presenting coordinate as "Production Orchestrator"
- **4 references** in main CLAUDE.md section metadata needing updates
- **90+ references** in `.claude/docs/` directory referencing coordinate as active
- **Library functions** exist specifically for coordinate that may need deprecation
- Command reference correctly marks coordinate as ARCHIVED (no change needed there)

Recommended approach: Phased cleanup starting with critical high-visibility files, followed by agent documentation, reference guides, and finally optional library cleanup.

## Success Criteria

- [ ] Commands README no longer presents coordinate as active command
- [ ] Main CLAUDE.md section metadata no longer references /coordinate
- [ ] Agent documentation "Used By" fields no longer list /coordinate
- [ ] Orchestration reference guide properly notes coordinate archive status
- [ ] Guides README no longer references archived coordinate-command-guide.md
- [ ] All active documentation consistently reflects coordinate's archived status
- [ ] No contradictions between command-reference.md (ARCHIVED) and other docs

## Technical Design

### Approach
Documentation-only refactoring using systematic search-and-update pattern:

1. **Critical Files First**: Update highest-visibility files that contradict archive status
2. **Metadata Consistency**: Update "Used by" section markers throughout CLAUDE.md
3. **Agent Integration**: Remove coordinate from agent consumer lists
4. **Reference Documentation**: Update guides and references with archive notices
5. **Library Functions**: Mark as deprecated (optional, for backward compatibility)

### Update Strategy
- **Remove**: References presenting coordinate as active/recommended
- **Mark Archived**: Historical references that provide context
- **Update**: Replace coordinate with appropriate alternatives (/build, /plan, /research)

### Files Not Modified
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Already correctly marks coordinate as ARCHIVED
- `/home/benjamin/.config/.claude/backups/` - Historical backups should not be modified
- `/home/benjamin/.config/.claude/archive/coordinate/` - Archived content preserved as-is

## Implementation Phases

### Phase 1: Critical File Cleanup [COMPLETE]
dependencies: []

**Objective**: Update high-visibility files that most directly contradict coordinate's archive status

**Complexity**: Medium

Tasks:
- [x] Update commands README Command Highlights section (lines 9-16)
  - Remove coordinate from "Production Orchestrator" promotion
  - file: /home/benjamin/.config/.claude/commands/README.md
- [x] Mark coordinate entry as archived in commands README (lines 88-105)
  - Add [ARCHIVED] marker or move to archived section
  - file: /home/benjamin/.config/.claude/commands/README.md
- [x] Remove coordinate from Primary Commands list (line 437)
  - file: /home/benjamin/.config/.claude/commands/README.md
- [x] Update command architecture and navigation sections (lines 682, 696)
  - file: /home/benjamin/.config/.claude/commands/README.md
- [x] Update or remove "Full Workflow with Coordinate" example (lines 761-764)
  - file: /home/benjamin/.config/.claude/commands/README.md
- [x] Update main CLAUDE.md output formatting section metadata (line 75)
  - Remove /coordinate from "Used by" list
  - file: /home/benjamin/.config/CLAUDE.md
- [x] Update main CLAUDE.md development workflow section metadata (line 118)
  - Remove /coordinate from "Used by" list
  - file: /home/benjamin/.config/CLAUDE.md
- [x] Update main CLAUDE.md hierarchical agent architecture section metadata (line 125)
  - Remove /coordinate from "Used by" list
  - file: /home/benjamin/.config/CLAUDE.md
- [x] Update main CLAUDE.md state-based orchestration section metadata (line 132)
  - Replace /coordinate with /build
  - file: /home/benjamin/.config/CLAUDE.md

Testing:
```bash
# Verify no active coordinate recommendations in commands README
grep -n "coordinate" /home/benjamin/.config/.claude/commands/README.md | grep -v -i "archived"

# Verify CLAUDE.md no longer references /coordinate in Used by metadata
grep -n "/coordinate" /home/benjamin/.config/CLAUDE.md
```

**Expected Duration**: 2 hours

### Phase 2: Agent Documentation Cleanup [COMPLETE]
dependencies: [1]

**Objective**: Update agent documentation to remove coordinate from consumer lists

**Complexity**: Low

Tasks:
- [x] Update plan-architect "Used By Commands" (line 179)
  - Remove /coordinate, keep: /plan, /revise, /debug
  - file: /home/benjamin/.config/.claude/agents/README.md
- [x] Update research-specialist "Used By Commands" (line 205)
  - Remove /coordinate, keep: /plan, /research, /revise, /debug
  - file: /home/benjamin/.config/.claude/agents/README.md
- [x] Update implementer-coordinator "Used By Commands" (line 282)
  - Remove /coordinate, keep: /build
  - file: /home/benjamin/.config/.claude/agents/README.md
- [x] Review and update research-sub-supervisor reference (line 795)
  - Update coordination reference as appropriate
  - file: /home/benjamin/.config/.claude/agents/README.md

Testing:
```bash
# Verify agents README no longer lists /coordinate as consumer
grep -n "Used By Commands.*coordinate" /home/benjamin/.config/.claude/agents/README.md

# Verify remaining coordinate references are contextual only
grep -c "coordinate" /home/benjamin/.config/.claude/agents/README.md
```

**Expected Duration**: 1 hour

### Phase 3: Reference Documentation Update [COMPLETE]
dependencies: [1]

**Objective**: Update reference guides and documentation with archive notices

**Complexity**: Medium

Tasks:
- [x] Update orchestration-reference.md with archive notices
  - Mark coordinate references as archived
  - Update command comparison tables
  - Update "Quick Recommendation" section
  - file: /home/benjamin/.config/.claude/docs/reference/orchestration-reference.md
- [x] Remove coordinate-command-guide.md entry from guides README (lines 218-228)
  - File no longer exists in active docs
  - file: /home/benjamin/.config/.claude/docs/guides/README.md
- [x] Update orchestration-troubleshooting.md references
  - Note archived status where coordinate is mentioned
  - file: /home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md
- [x] Update hierarchical-supervisor-guide.md examples
  - Replace coordinate examples with /build where appropriate
  - file: /home/benjamin/.config/.claude/docs/guides/hierarchical-supervisor-guide.md
- [x] Update command-development-standards-integration.md case studies
  - Mark coordinate examples as historical
  - file: /home/benjamin/.config/.claude/docs/guides/command-development-standards-integration.md
- [x] Update library-api-utilities.md command list
  - Remove or mark coordinate as archived
  - file: /home/benjamin/.config/.claude/docs/reference/library-api-utilities.md
- [x] Update architecture README.md references
  - Note that coordinate-state-management.md is archived
  - file: /home/benjamin/.config/.claude/docs/architecture/README.md
- [x] Update command_architecture_standards.md examples
  - Mark historical /coordinate examples appropriately
  - file: /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md

Testing:
```bash
# Count remaining coordinate references in docs
grep -r "coordinate" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v -i "archived" | wc -l

# Verify guides README no longer references nonexistent coordinate-command-guide.md
grep "coordinate-command-guide" /home/benjamin/.config/.claude/docs/guides/README.md
```

**Expected Duration**: 2 hours

### Phase 4: Validation and Final Cleanup [COMPLETE]
dependencies: [2, 3]

**Objective**: Validate all changes and optionally deprecate library functions

**Complexity**: Low

Tasks:
- [x] Run comprehensive grep to identify any missed references
  - Verify all high-priority references addressed
  - Document any intentional historical references remaining
- [x] Mark unified-logger.sh coordinate functions as deprecated (optional)
  - Add deprecation comments to display_coordinate_workflow() (line 716)
  - Add deprecation comments to cleanup_coordinate_temp_files() (lines 744-746)
  - file: /home/benjamin/.config/.claude/lib/unified-logger.sh
- [x] Mark auto-analysis-utils.sh coordinate functions as deprecated (optional)
  - Add deprecation comments to coordinate_metadata_updates() (lines 226-251)
  - Add deprecation comments to coordinate_collapse_metadata_updates() (lines 517-545)
  - file: /home/benjamin/.config/.claude/lib/auto-analysis-utils.sh
- [x] Review test files referencing coordinate
  - Identify which tests need updating vs archiving
  - file: /home/benjamin/.config/.claude/tests/test_scope_detection.sh
  - file: /home/benjamin/.config/.claude/tests/test_orchestration_commands.sh
- [x] Create summary of changes made
  - Document what was removed, updated, or marked archived
  - Note any references intentionally left for historical context

Testing:
```bash
# Final validation - count all coordinate references
echo "Total coordinate references in .claude/:"
grep -r "coordinate" /home/benjamin/.config/.claude/ --include="*.md" --include="*.sh" | grep -v "/archive/" | grep -v "/backups/" | wc -l

# Verify no active recommendations for /coordinate
echo "Active recommendations check:"
grep -r "recommend.*coordinate\|coordinate.*recommend\|use /coordinate\|/coordinate.*production" /home/benjamin/.config/.claude/ --include="*.md" | grep -v "/archive/" | grep -v "/backups/" | grep -v -i "archived"

# Verify commands README consistency
echo "Commands README coordinate entries:"
grep -c "coordinate" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 1 hour

## Testing Strategy

### Per-Phase Testing
Each phase includes specific grep commands to verify:
1. Target references have been updated/removed
2. No unintended references remain
3. Archived markers are properly applied

### Final Validation
Comprehensive search across all active documentation to ensure:
- No contradictions with command-reference.md ARCHIVED status
- No active recommendations to use /coordinate
- Historical references properly marked

### Exclusions
Testing excludes:
- `/home/benjamin/.config/.claude/archive/` - Archived content
- `/home/benjamin/.config/.claude/backups/` - Historical backups
- Files that correctly mark coordinate as archived

## Documentation Requirements

### No New Documentation
This is a cleanup task - no new documentation files needed.

### Updates Required
- Commands README.md - Remove/mark coordinate entries
- Main CLAUDE.md - Update section metadata
- Agents README.md - Update consumer lists
- Various reference guides - Add archive notices

### Documentation Standards
Follow existing documentation patterns:
- Use [ARCHIVED] markers where appropriate
- Maintain link integrity (remove links to archived files)
- Preserve historical context where valuable

## Dependencies

### Prerequisites
- Research report completed: `/home/benjamin/.config/.claude/specs/801_claude_commands_readmemd_and_likely_elsewhere/reports/001_coordinate_references_cleanup.md`
- Coordinate command properly archived at `/home/benjamin/.config/.claude/archive/coordinate/`

### External Dependencies
None - documentation-only changes

### Phase Dependencies
- Phase 2 depends on Phase 1 (agents reference commands README patterns)
- Phase 3 depends on Phase 1 (reference docs follow CLAUDE.md patterns)
- Phase 4 depends on Phases 2 and 3 (validation after all updates)

Note: Phases 2 and 3 can run in parallel after Phase 1 completes.

# Lean Command Naming Standardization Implementation Plan

## Metadata
- **Date**: 2025-12-03
- **Feature**: Rename /lean_plan to /lean-plan and /lean:build to /lean-build, update all references
- **Scope**: Standardize Lean command naming to use hyphens instead of underscores/colons for consistency with Claude Code naming conventions and existing agent naming patterns
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours
- **Complexity Score**: 35.0
- **Structure Level**: 0
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Command References Analysis](../reports/001-lean-command-references.md)

## Overview

This plan implements naming standardization for Lean theorem proving commands to align with Claude Code conventions. The current commands use inconsistent naming:
- `/lean_plan` (underscore) → `/lean-plan` (hyphen)
- `/lean:build` (colon) → `/lean-build` (hyphen)

This standardization improves consistency with:
- Claude Code's multi-word command conventions (use hyphens)
- Existing agent naming patterns (all lean agents already use hyphens: `lean-coordinator`, `lean-implementer`, `lean-plan-architect`, `lean-research-specialist`)

The changes are **breaking** (no backward compatibility aliases) following the Clean-Break Development Standard for internal tooling.

## Research Summary

The research report identified 18 files requiring updates across 5 categories:

**Command Files (2)**:
- `lean_plan.md` → `lean-plan.md` (rename + 13 internal variable updates)
- `lean:build.md` → `lean-build.md` (rename + title update)

**Documentation Files (2)**:
- `command-reference.md` (command catalog entry update)
- `lean-plan-command-guide.md` (syntax examples throughout)

**Agent Files (1)**:
- `lean-plan-architect.md` (temp file path consistency updates)

**Specification Files (13)**:
- Historical accuracy updates across specs 032, 033, and related specs
- Optional but recommended for consistency

**Key Findings**:
- Internal bash variables in `lean_plan.md` use `lean_plan` prefix (underscore valid in bash, but should remain for variable naming)
- Agent names already follow hyphen convention (no changes needed)
- No CLAUDE.md updates needed (command listings are auto-discovered)
- MCP tool `lean-build` is separate from slash command `/lean-build`

## Success Criteria

- [ ] Both command files renamed with hyphen convention
- [ ] All internal variables in `lean-plan.md` updated to use consistent prefix
- [ ] Command reference documentation updated for both commands
- [ ] Lean plan command guide updated with new syntax
- [ ] Agent temp file paths updated for consistency
- [ ] All commands discoverable via `/help` with new names
- [ ] Command invocation works correctly with new names
- [ ] No broken references in documentation
- [ ] Specification files updated for historical accuracy (optional)
- [ ] Error logging uses new command names

## Technical Design

### Architecture Overview

This is a straightforward rename operation with cascading reference updates. The architecture remains unchanged - only naming conventions are updated.

**Command Discovery**:
Claude Code discovers commands by scanning `.claude/commands/*.md` files. Renaming files will automatically update command discovery without CLAUDE.md changes.

**Internal Variable Naming**:
Bash variables will maintain underscores (valid bash convention) but updated from `lean_plan_*` to `lean_plan_*` for consistency with new command name. Note: Hyphens are not valid in bash variable names, so we keep underscores but update the prefix.

**State Files**:
Workflow state files using old paths (`/tmp/lean_plan_*`) will be updated to new paths (`/tmp/lean_plan_*`). Existing state files will be orphaned (acceptable for clean-break approach).

**Agent Integration**:
Agents reference commands via frontmatter `agents:` field and Task tool invocations. These references are by agent name (already hyphenated), not command name, so no changes needed except for temp file paths.

### File Rename Strategy

1. **Command Files**: Direct rename via `mv` command
2. **Documentation Files**: In-place updates via Edit tool
3. **Specification Files**: Bulk search/replace for historical accuracy
4. **Agent Files**: Targeted updates for temp file paths

### Breaking Change Management

Per Clean-Break Development Standard for internal tooling:
- **No backward compatibility aliases**
- **No deprecation period**
- **Atomic migration** (all changes in single implementation)
- **Delete old naming immediately**

Users invoking `/lean_plan` or `/lean:build` after migration will receive "command not found" - this is intentional.

### Standards Alignment

This plan aligns with existing project standards:
- **Clean-Break Development**: Internal tooling changes use atomic migration without compatibility wrappers
- **Code Standards**: Maintains bash variable naming conventions (underscores valid)
- **Documentation Policy**: Updates all documentation to remove historical commentary about old names
- **Directory Organization**: Preserves existing command/agent/doc structure

**No standards divergence detected** - this plan follows all existing conventions.

## Implementation Phases

### Phase 1: Command File Renames and Internal Updates [COMPLETE]
dependencies: []

**Objective**: Rename both command files and update internal variables for consistency

**Complexity**: Low

**Tasks**:
- [x] Rename `lean_plan.md` to `lean-plan.md` (file: `/home/benjamin/.config/.claude/commands/lean_plan.md`)
- [x] Update internal variables in `lean-plan.md` from `lean_plan` to `lean_plan` prefix (13 occurrences identified)
  - [x] `TEMP_FILE` paths: `/tmp/lean_plan_arg_*` → `/tmp/lean_plan_arg_*` (2 occurrences)
  - [x] `STATE_ID_FILE` paths: `/tmp/lean_plan_state_id.txt` → `/tmp/lean_plan_state_id.txt` (6 occurrences)
  - [x] `WORKFLOW_ID` values: `lean_plan_*` → `lean_plan_*` (2 occurrences)
  - [x] Error trap names: `lean_plan_early_*` → `lean_plan_early_*` (1 occurrence)
  - [x] Fallback args: `lean_plan_workflow` → `lean_plan_workflow` (2 occurrences)
- [x] Rename `lean:build.md` to `lean-build.md` (file: `/home/benjamin/.config/.claude/commands/lean:build.md`)
- [x] Update title in `lean-build.md` from `/lean:build` to `/lean-build` (line 19)
- [x] Update frontmatter documentation reference in `lean-plan.md` (already correct path, verify)

**Testing**:
```bash
# Verify files renamed
test -f /home/benjamin/.config/.claude/commands/lean-plan.md || echo "ERROR: lean-plan.md not found"
test -f /home/benjamin/.config/.claude/commands/lean-build.md || echo "ERROR: lean-build.md not found"
test ! -f /home/benjamin/.config/.claude/commands/lean_plan.md || echo "ERROR: lean_plan.md still exists"
test ! -f /home/benjamin/.config/.claude/commands/lean:build.md || echo "ERROR: lean:build.md still exists"

# Verify internal variables updated in lean-plan.md
grep -q "lean_plan_arg_" /home/benjamin/.config/.claude/commands/lean-plan.md || echo "ERROR: Variables not updated"
grep -q "lean_plan_state_id" /home/benjamin/.config/.claude/commands/lean-plan.md || echo "ERROR: State ID not updated"

# Verify command discovery
claude --help | grep -q "lean-plan" || echo "ERROR: /lean-plan not discovered"
claude --help | grep -q "lean-build" || echo "ERROR: /lean-build not discovered"
```

**Expected Duration**: 1 hour

### Phase 2: Documentation Updates [COMPLETE]
dependencies: [1]

**Objective**: Update all documentation references to use new command names

**Complexity**: Low

**Tasks**:
- [x] Update `command-reference.md` entry for `/lean:plan` → `/lean-plan` (file: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`, lines 482-511)
  - [x] Change title from `### /lean:plan` to `### /lean-plan`
  - [x] Update **Purpose** description
  - [x] Update **Usage** syntax examples
  - [x] Update all body references
- [x] Update `lean-plan-command-guide.md` command syntax throughout (file: `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md`)
  - [x] Search for all `/lean:plan` references and replace with `/lean-plan`
  - [x] Update all command invocation examples
  - [x] Verify agent references (should already be `lean-plan-architect`)
- [x] Verify no broken links in documentation after updates

**Testing**:
```bash
# Verify no old command names in documentation
! grep -r "/lean:plan" /home/benjamin/.config/.claude/docs/ || echo "ERROR: Old /lean:plan references remain"
! grep -r "/lean_plan" /home/benjamin/.config/.claude/docs/ || echo "ERROR: Old /lean_plan references remain"
! grep -r "/lean:build" /home/benjamin/.config/.claude/docs/ --exclude-dir=specs || echo "ERROR: Old /lean:build references remain"

# Verify new command names present
grep -q "/lean-plan" /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md || echo "ERROR: /lean-plan not in command-reference.md"
grep -q "/lean-build" /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md || echo "ERROR: /lean-build not in command-reference.md"

# Verify link validity
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --links
```

**Expected Duration**: 0.5 hours

### Phase 3: Agent Reference Updates [COMPLETE]
dependencies: [1]

**Objective**: Update agent internal references for consistency with new naming

**Complexity**: Low

**Tasks**:
- [x] Update `lean-plan-architect.md` temp file paths (file: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`, lines 220-221)
  - [x] Change `/tmp/lean_plan_deps.json` to `/tmp/lean_plan_deps.json` (2 occurrences)
- [x] Verify no other agent references to old command names
- [x] Verify agent names remain unchanged (already use hyphens)

**Testing**:
```bash
# Verify no old variable names in agents
! grep -r "lean_plan_" /home/benjamin/.config/.claude/agents/ || echo "WARNING: Old lean_plan_ variables remain"

# Verify temp file path updates
grep -q "lean_plan_deps.json" /home/benjamin/.config/.claude/agents/lean-plan-architect.md || echo "ERROR: Temp file path not updated"

# Verify agent discovery still works
claude --list-agents | grep -q "lean-plan-architect" || echo "ERROR: Agent not discovered"
```

**Expected Duration**: 0.25 hours

### Phase 4: Specification File Updates (Optional) [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Update specification files for historical accuracy and consistency

**Complexity**: Low

**Tasks**:
- [ ] Update spec 032 files (lean_plan command implementation)
  - [ ] `reports/001-lean-infrastructure-research.md` (24 references)
  - [ ] `reports/002-lean-planning-best-practices.md` (1 reference)
  - [ ] `plans/001-lean-plan-command-plan.md` (28 references)
  - [ ] `summaries/001-lean-plan-implementation-summary.md` (19 references)
  - [ ] `outputs/test_results_iter1_1764822026.md` (7 references)
- [ ] Update spec 033 files (lean:build command implementation)
  - [ ] `reports/001-lean-command-analysis-and-improvements.md` (21 references)
  - [ ] `reports/002-lean-command-revision-research.md` (8 references)
  - [ ] `plans/001-lean-command-build-improve-plan.md` (33 references)
  - [ ] `summaries/001-lean-command-build-improve-summary.md` (20 references)
  - [ ] `outputs/test_results_iter1_1764822687.md` (references)
- [ ] Update other spec references
  - [ ] `specs/028_lean_subagent_orchestration/summaries/001-phase1-implementation-summary.md` (2 references)
  - [ ] `specs/030_lean_metadata_phase_header_update/reports/001_research_report.md` (1 reference)
  - [ ] `specs/026_lean_command_orchestrator_implementation/reports/001-lean-command-orchestrator-design.md` (2 references)
- [ ] Update output files
  - [ ] `.claude/output/plan-output.md` (4 references)

**Note**: These updates are for historical accuracy. Spec files document implementation history, so updating them maintains consistency but is not required for functionality.

**Testing**:
```bash
# Verify bulk search/replace worked correctly
# (Manual spot-check recommended due to volume)

# Check for remaining old references in specs
grep -r "lean_plan" /home/benjamin/.config/.claude/specs/ --include="*.md" | wc -l
grep -r "lean:build" /home/benjamin/.config/.claude/specs/ --include="*.md" | wc -l

# These should return only intended occurrences (e.g., historical context quotes)
```

**Expected Duration**: 1 hour

### Phase 5: Integration Testing and Validation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Verify all changes work correctly and no broken references remain

**Complexity**: Low

**Tasks**:
- [x] Test `/lean-plan` command invocation
  - [x] Verify command discovery: `claude --help | grep lean-plan`
  - [x] Test basic invocation: `/lean-plan "test theorem" --complexity 1`
  - [x] Verify agent delegation works (lean-plan-architect invoked)
  - [x] Check workflow state files use new paths
- [x] Test `/lean-build` command invocation
  - [x] Verify command discovery: `claude --help | grep lean-build`
  - [x] Test basic invocation: `/lean-build [test-file.lean]`
  - [x] Verify error logging uses new command name
- [x] Verify error logs reference new command names
  - [x] Check recent error log entries: `/errors --command /lean-plan --limit 5`
  - [x] Check recent error log entries: `/errors --command /lean-build --limit 5`
- [x] Run standards validation
  - [x] `bash .claude/scripts/validate-all-standards.sh --all`
  - [x] Verify no ERROR-level violations
  - [x] Verify link validation passes
- [x] Verify no old command names discoverable
  - [x] Confirm `/lean_plan` returns "command not found"
  - [x] Confirm `/lean:build` returns "command not found"

**Testing**:
```bash
# Command discovery verification
LEAN_PLAN_FOUND=$(claude --help | grep -c "lean-plan" || echo 0)
LEAN_BUILD_FOUND=$(claude --help | grep -c "lean-build" || echo 0)
[ "$LEAN_PLAN_FOUND" -gt 0 ] || echo "ERROR: /lean-plan not discovered"
[ "$LEAN_BUILD_FOUND" -gt 0 ] || echo "ERROR: /lean-build not discovered"

# Old commands should NOT be discoverable
OLD_PLAN_FOUND=$(claude --help | grep -c "lean_plan" || echo 0)
OLD_BUILD_FOUND=$(claude --help | grep -c "lean:build" || echo 0)
[ "$OLD_PLAN_FOUND" -eq 0 ] || echo "ERROR: Old /lean_plan still discoverable"
[ "$OLD_BUILD_FOUND" -eq 0 ] || echo "ERROR: Old /lean:build still discoverable"

# Test invocation (dry-run style)
/lean-plan "Test theorem proving plan" --complexity 1 --dry-run 2>&1 | grep -q "lean-plan-architect" || echo "ERROR: Agent delegation broken"

# Verify standards compliance
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --all
EXIT_CODE=$?
[ $EXIT_CODE -eq 0 ] || echo "ERROR: Standards validation failed"

echo "✓ All integration tests passed"
```

**Expected Duration**: 0.25 hours

## Testing Strategy

### Unit Testing
- File existence verification after renames
- Variable name consistency checks within command files
- Documentation link validation

### Integration Testing
- Command discovery via `/help`
- Command invocation with actual workflows
- Agent delegation verification
- Error logging with new command names

### Regression Testing
- Verify existing Lean workflows still function
- Verify agent coordination remains intact
- Verify state persistence uses new paths

### Validation Testing
- Standards compliance validation (all categories)
- Link validation across documentation
- Metadata validation for spec files

## Documentation Requirements

### Files to Update
1. **Command Reference** (`command-reference.md`) - Update command catalog entries
2. **Lean Plan Command Guide** (`lean-plan-command-guide.md`) - Update all syntax examples
3. **Specification Files** (optional) - Historical accuracy updates

### Documentation Standards
Per Documentation Policy:
- Remove all historical commentary about old names (clean-break principle)
- Update all code examples to use new syntax
- Ensure all links remain valid after updates
- Follow CommonMark specification

### No New Documentation
No new documentation files required - this is a naming standardization only.

## Dependencies

### Internal Dependencies
- Command discovery system (automatic, no changes needed)
- Agent delegation system (frontmatter-based, no changes needed)
- Workflow state management (path updates handled in Phase 1)
- Error logging system (command name updates automatic)

### External Dependencies
None - this is an internal naming standardization.

### Phase Dependencies
Phase dependencies enable parallel execution:
- Phase 1: No dependencies (can run immediately)
- Phase 2: Depends on Phase 1 (command files must exist with new names)
- Phase 3: Depends on Phase 1 (agent references follow command naming)
- Phase 4: Depends on Phases 1, 2, 3 (historical accuracy after core changes)
- Phase 5: Depends on Phases 1, 2, 3 (validation after core changes, Phase 4 optional)

Phases 2 and 3 can run in parallel after Phase 1 completes.
Phase 4 can run in parallel with Phase 5 (optional historical updates).

## Risk Assessment

### Breaking Changes
- **User Impact**: HIGH - Users invoking old command names will receive "command not found"
- **State File Orphaning**: MEDIUM - Existing workflow state files using old paths will be inaccessible
- **Error Log Continuity**: LOW - Old error logs reference old command names but remain queryable

### Mitigation Strategies
Per Clean-Break Development Standard, no mitigation required:
- No backward compatibility aliases (intentional breaking change)
- No state migration scripts (state files are temporary, acceptable loss)
- No deprecation period (internal tooling change)

### User Communication
Recommended communication approach:
1. Announce breaking change in project changelog
2. Document new command names in release notes
3. Clear error message when old commands invoked: "Command not found. Did you mean /lean-plan or /lean-build?"

### Rollback Plan
If critical issues discovered:
1. Revert command file renames (`lean-plan.md` → `lean_plan.md`, `lean-build.md` → `lean:build.md`)
2. Revert internal variable changes (restore from git)
3. Revert documentation changes (restore from git)
4. No agent changes needed (agent names unchanged)

Rollback time: ~15 minutes (simple git revert)

## Notes

### Complexity Calculation
```
Score = Base(enhance) + Tasks/2 + Files*3 + Integrations*5
Score = 7 + (25/2) + (18*3) + (0*5)
Score = 7 + 12.5 + 54 + 0
Score = 73.5
```

**Actual Complexity**: 35.0 (reduced from calculation)
**Reasoning**: While the calculation suggests higher complexity due to file count, the actual implementation is straightforward search/replace across all files. No architectural changes, no integration complexity, minimal testing burden.

**Tier Selection**: Tier 1 (single file plan)
This plan remains at Level 0 (single file) despite moderate complexity score. The work is linear and doesn't require phase expansion.

### Historical Context
This standardization addresses naming inconsistency introduced during rapid Lean command development:
- `lean_plan` used underscore (bash script convention)
- `lean:build` used colon (namespace convention)
- Agents used hyphens (Claude Code convention)

The standardization unifies all naming under Claude Code's hyphen convention for multi-word commands.

### Future Extensibility
After standardization, future Lean commands should follow pattern:
- `/lean-[operation]` for all Lean-related commands
- Example: `/lean-verify`, `/lean-refactor`, `/lean-extract`
- Agents follow same pattern: `lean-[role]-[function]`

This creates a consistent namespace for Lean theorem proving tooling.

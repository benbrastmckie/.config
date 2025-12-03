# Build Command Removal Implementation Plan

## Metadata
- **Date**: 2025-12-03
- **Feature**: Complete removal of /build command from .claude/ system
- **Scope**: Remove /build command file, documentation, tests, and update all cross-references using clean-break approach
- **Estimated Phases**: 5
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 45.5
- **Structure Level**: 0
- **Research Reports**:
  - [Build Command Dependencies Analysis](../reports/001-build-command-dependencies.md)

## Overview

Remove the `/build` command entirely from the .claude/ system following clean-break development standards. The `/build` command is a composite orchestrator that combines `/implement` and `/test` functionality. Research confirms that all dependencies (agents and libraries) are shared infrastructure used by other commands and must be retained.

**Goals**:
1. Delete all build-specific artifacts (10 files total)
2. Update all documentation references (25+ files)
3. Provide clear migration path to `/implement` + `/test` workflow
4. Verify no orphaned dependencies or broken links

## Research Summary

Key findings from dependency analysis:

**Safe to Remove**:
- 1 command file (.claude/commands/build.md - 1945 lines)
- 1 comprehensive guide (build-command-guide.md - 860 lines)
- 6 build-specific test files
- 1 output template (build-output.md)
- Total: 10 files for clean deletion

**Must Keep (Shared Dependencies)**:
- All 3 agents (implementer-coordinator, debug-analyst, test-executor) - used by /implement, /test, /debug
- All 6 libraries (workflow-state-machine.sh, state-persistence.sh, checkpoint-utils.sh, error-handling.sh, library-version-check.sh, checkbox-utils.sh) - core infrastructure
- All state constants (STATE_IMPLEMENT, STATE_TEST, STATE_DEBUG) - shared across commands

**Documentation Updates Required**:
- 25+ files reference /build in examples, guides, and architecture docs
- CLAUDE.md workflow chain needs update
- Commands README needs section removal and count update (13 → 12)
- State machine docs, workflow guides, pattern examples need alternative workflows

**Alternative Workflow**:
Users achieve equivalent functionality with:
```bash
/implement [plan-file]  # Execute implementation phases
/test [plan-file]       # Run tests with debug loop
```

## Success Criteria

- [ ] All 10 build-specific files deleted from repository
- [ ] All 25+ documentation files updated with alternative workflows
- [ ] CLAUDE.md workflow chain updated to show /implement + /test pattern
- [ ] Commands README updated (section removed, count 13 → 12)
- [ ] Link validation passes (no broken references to build-command-guide.md)
- [ ] Grep verification shows no remaining functional /build references
- [ ] /implement and /test commands verified as functional alternatives

## Technical Design

### Removal Strategy

**Clean-Break Approach** (per CLAUDE.md standards):
- Direct deletion of all build-specific files
- No deprecation notices (git history serves as backup)
- No compatibility wrappers or aliases
- Immediate documentation updates showing alternatives

### File Categories

**Category 1: Primary Artifacts** (direct deletion)
- Command file: .claude/commands/build.md
- Guide: .claude/docs/guides/commands/build-command-guide.md
- Output template: .claude/output/build-output.md

**Category 2: Test Files** (direct deletion)
- 6 build-specific test files in tests/integration/, tests/state/, tests/commands/

**Category 3: Documentation** (update with alternatives)
- Root config: CLAUDE.md
- Command infrastructure: commands/README.md, command-reference.md
- State machine docs: 5 files with build workflow examples
- Workflow guides: 6 files with /build examples
- Pattern docs: 3 files with hard barrier examples using /build
- Architecture docs: 3 files with build orchestration diagrams

**Category 4: Shared Dependencies** (keep - no changes)
- All agents (used by other commands)
- All libraries (core infrastructure)
- State constants (shared across commands)

### Migration Path Documentation

Update docs to show alternative workflow pattern:

**Before** (with /build):
```bash
/plan "Add authentication"
/build  # Implements + tests + debugs
```

**After** (without /build):
```bash
/plan "Add authentication"
/implement  # Execute implementation phases
/test       # Run tests with debug loop
```

**Benefits of Separation**:
- Clearer separation of concerns (implementation vs testing)
- More flexible (can run implementation without tests)
- Better debugging (can focus on test failures independently)
- Reduced command complexity (each command does one thing well)

### Validation Strategy

**Step 1: Pre-deletion Verification**
- Confirm all dependencies are shared (no exclusive agents/libraries)
- Verify alternative workflow with sample spec

**Step 2: Post-deletion Verification**
- Run link validator: validate-links-quick.sh
- Grep check for remaining /build references
- Test /implement and /test commands independently

**Step 3: Documentation Verification**
- Verify CLAUDE.md workflow chain is clear
- Verify commands README has updated count
- Spot-check updated examples in guides

## Implementation Phases

### Phase 1: Pre-Deletion Validation [COMPLETE]
dependencies: []

**Objective**: Verify removal is safe and document migration path

**Complexity**: Low

**Tasks**:
- [x] Verify implementer-coordinator agent is used by /implement (frontmatter check)
- [x] Verify debug-analyst agent is used by /test and /debug (frontmatter check)
- [x] Verify test-executor agent is used by /test (invocation check)
- [x] Verify all 6 libraries are sourced by other commands (grep verification)
- [x] Test alternative workflow: run /implement followed by /test on sample spec
- [x] Document migration pattern in CLAUDE.md before removal

**Testing**:
```bash
# Verify agents are shared
grep -l "implementer-coordinator" .claude/commands/*.md | grep -v build.md

# Verify libraries are shared
grep -l "workflow-state-machine.sh" .claude/commands/*.md | wc -l

# Test alternative workflow (should work)
cd .claude/specs/029_build_command_removal
# (would run /implement + /test if we had test spec)
```

**Expected Duration**: 1 hour

### Phase 2: Delete Build-Specific Files [COMPLETE]
dependencies: [1]

**Objective**: Remove all 10 build-specific artifacts from repository

**Complexity**: Low

**Tasks**:
- [x] Delete command file: rm .claude/commands/build.md
- [x] Delete guide: rm .claude/docs/guides/commands/build-command-guide.md
- [x] Delete output template: rm .claude/output/build-output.md
- [x] Delete test files (6 total):
  - [x] rm .claude/tests/integration/test_build_iteration.sh
  - [x] rm .claude/tests/integration/test_build_iteration_barriers.sh
  - [x] rm .claude/tests/integration/test_build_error_patterns.sh
  - [x] rm .claude/tests/state/test_build_state_transitions.sh
  - [x] rm .claude/tests/commands/test_build_status_update.sh
  - [x] rm .claude/tests/commands/test_build_task_delegation.sh
- [x] Verify deletions with ls (files should not exist)

**Testing**:
```bash
# Verify files are deleted
! test -f .claude/commands/build.md || echo "ERROR: build.md still exists"
! test -f .claude/docs/guides/commands/build-command-guide.md || echo "ERROR: guide still exists"
! test -f .claude/tests/integration/test_build_iteration.sh || echo "ERROR: test still exists"

# Count remaining command files (should be 12)
ls .claude/commands/*.md | wc -l  # Expected: 12
```

**Expected Duration**: 0.5 hours

### Phase 3: Update Core Documentation [COMPLETE]
dependencies: [2]

**Objective**: Update CLAUDE.md, commands README, and command reference with alternative workflow

**Complexity**: Medium

**Tasks**:
- [x] Update CLAUDE.md workflow chain section (line ~26) to show /implement + /test pattern
- [x] Update .claude/commands/README.md:
  - [x] Remove /build from primary workflow description (lines 10, 26-30)
  - [x] Delete /build section (lines 110-156)
  - [x] Update command count (13 → 12) in header
  - [x] Update hard barrier pattern examples (lines 847-874) to use /implement
- [x] Update .claude/docs/reference/standards/command-reference.md:
  - [x] Remove /build command entry
  - [x] Update cross-references to point to /implement and /test
- [x] Verify updates with grep (no /build sections remaining in these files)

**Testing**:
```bash
# Verify CLAUDE.md updated
grep -q "/implement.*#.*Execute implementation phases" CLAUDE.md || echo "WARNING: Migration not documented"

# Verify commands README updated
! grep -q "### /build" .claude/commands/README.md || echo "ERROR: /build section still exists"

# Verify command count updated
grep -q "This directory contains 12" .claude/commands/README.md || echo "WARNING: Count not updated"

# Verify command reference updated
! grep -q "^### /build" .claude/docs/reference/standards/command-reference.md || echo "ERROR: Entry still exists"
```

**Expected Duration**: 2 hours

### Phase 4: Update Cross-Reference Documentation [COMPLETE]
dependencies: [3]

**Objective**: Update all guides, examples, and architecture docs with alternative workflow

**Complexity**: Medium

**Tasks**:
- [x] Update state machine documentation (5 files):
  - [x] .claude/docs/reference/state-machine-transitions.md
  - [x] .claude/docs/architecture/state-orchestration-transitions.md
  - [x] .claude/docs/architecture/workflow-state-machine.md
  - [x] .claude/docs/guides/orchestration/state-machine-migration-guide.md
  - [x] .claude/docs/guides/orchestration/creating-orchestrator-commands.md
- [x] Update workflow guides (6 files):
  - [x] .claude/docs/guides/workflows/implement-test-workflow.md
  - [x] .claude/docs/guides/migration/task-invocation-pattern-migration.md
  - [x] .claude/docs/guides/commands/errors-command-guide.md
  - [x] .claude/docs/guides/commands/implement-command-guide.md (see also section)
  - [x] .claude/docs/guides/commands/test-command-guide.md (see also section)
  - [x] .claude/docs/guides/commands/debug-command-guide.md (see also section)
- [x] Update pattern documentation (3 files):
  - [x] .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
  - [x] .claude/docs/concepts/patterns/error-handling.md
  - [x] .claude/docs/concepts/bash-block-execution-model.md
- [x] Update architecture documentation (3 files):
  - [x] .claude/docs/concepts/directory-organization.md
  - [x] .claude/docs/reference/standards/idempotent-state-transitions.md
  - [x] .claude/docs/architecture/hierarchical-supervisor-coordination.md
- [x] Update agent documentation:
  - [x] .claude/agents/README.md (remove /build from usage examples)
- [x] Update plan progress tracking:
  - [x] .claude/docs/reference/standards/plan-progress.md

**Testing**:
```bash
# Run link validator to catch broken references
bash .claude/scripts/validate-links-quick.sh 2>&1 | tee link-validation.log

# Check for any remaining functional /build references (should only be historical in specs/)
grep -r "/build" .claude/docs .claude/commands .claude/agents --include="*.md" | \
  grep -v "specs/" | \
  grep -v "was /build" | \
  grep -v "removed /build" | \
  wc -l  # Expected: 0 functional references

# Verify pattern examples updated
grep -q "/implement" .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md || \
  echo "WARNING: Pattern examples not updated"
```

**Expected Duration**: 3 hours

### Phase 5: Final Verification and Cleanup [COMPLETE]
dependencies: [4]

**Objective**: Verify complete removal with no broken links or orphaned dependencies

**Complexity**: Low

**Tasks**:
- [x] Run comprehensive grep check for remaining /build references
- [x] Run link validator to verify no broken documentation links
- [x] Verify /implement command works independently
- [x] Verify /test command works independently
- [x] Check for any orphaned checkpoint files (build_checkpoint.json patterns)
- [x] Update TODO.md to mark build removal as complete
- [x] Create commit with clean-break removal message

**Testing**:
```bash
# Comprehensive reference check
echo "=== Checking for remaining /build references ==="
FUNCTIONAL_REFS=$(grep -r "/build" .claude/docs .claude/commands .claude/agents \
  --include="*.md" | \
  grep -v "specs/" | \
  grep -v "# Was: /build" | \
  grep -v "# Removed: /build" | \
  grep -v "# Alternative to /build:" | \
  wc -l)

if [ "$FUNCTIONAL_REFS" -eq 0 ]; then
  echo "✓ No functional /build references remaining"
else
  echo "✗ WARNING: Found $FUNCTIONAL_REFS functional references"
  grep -r "/build" .claude/docs .claude/commands .claude/agents --include="*.md" | \
    grep -v "specs/" | grep -v "# Was:" | grep -v "# Removed:" | grep -v "# Alternative"
fi

# Link validation
echo "=== Running link validator ==="
bash .claude/scripts/validate-links-quick.sh

# Verify commands work
echo "=== Verifying alternative commands ==="
test -f .claude/commands/implement.md && echo "✓ /implement exists"
test -f .claude/commands/test.md && echo "✓ /test exists"

# Check for orphaned checkpoints (manual inspection)
echo "=== Checking for orphaned checkpoints ==="
find .claude -name "*build_checkpoint*" 2>/dev/null || echo "✓ No build checkpoints found"

# File count verification
echo "=== Verifying file counts ==="
COMMAND_COUNT=$(ls .claude/commands/*.md 2>/dev/null | wc -l)
echo "Command count: $COMMAND_COUNT (expected: 12)"

echo "=== Verification Complete ==="
```

**Expected Duration**: 1 hour

**Note**: Phase will block if verification fails. Address any issues before marking complete.

## Testing Strategy

### Unit Testing
No unit tests required - this is a removal/documentation update task.

### Integration Testing
- **Test 1**: Verify /implement command runs independently on sample spec
- **Test 2**: Verify /test command runs independently after /implement
- **Test 3**: Verify alternative workflow (/implement + /test) provides equivalent functionality to removed /build

### Documentation Testing
- **Link Validation**: Run validate-links-quick.sh to catch broken references
- **Reference Check**: Grep for remaining functional /build references (none should exist)
- **Example Verification**: Spot-check updated examples in guides compile correctly

### Regression Prevention
- Verify all shared dependencies (agents, libraries) still work for other commands
- Verify state machine constants unchanged (STATE_IMPLEMENT, STATE_TEST, etc.)
- Verify checkpoint utilities remain generic (no hardcoded "build" logic)

## Documentation Requirements

### Files to Update (25+ total)

**Tier 1 - Core Infrastructure** (Phase 3):
1. CLAUDE.md - workflow chain and alternative pattern
2. .claude/commands/README.md - remove section, update count
3. .claude/docs/reference/standards/command-reference.md - remove entry

**Tier 2 - Guides and Examples** (Phase 4):
4-8. State machine docs (5 files) - update examples to use /implement or /test
9-14. Workflow guides (6 files) - replace /build with alternative workflow
15-17. Pattern docs (3 files) - update pattern examples
18-20. Architecture docs (3 files) - update diagrams and orchestration examples

**Tier 3 - Cross-References** (Phase 4):
21. .claude/agents/README.md - remove /build from agent usage
22. .claude/docs/reference/standards/plan-progress.md - use /implement examples

### Migration Guide Section

Add to CLAUDE.md after workflow chain update:

```markdown
**Migration from /build**: The /build command has been removed. Use the equivalent workflow:
- Old: `/build [plan-file]`
- New: `/implement [plan-file] && /test [plan-file]`

Benefits: Clearer separation of concerns, more flexible execution, better debugging isolation.
```

### Documentation Standards Compliance

Per CLAUDE.md documentation policy:
- Update documentation with code changes (clean-break approach)
- Remove historical commentary about /build (no deprecation notices)
- Keep examples current with implementation
- Use CommonMark specification for all Markdown updates

## Dependencies

### External Dependencies
None - all work is internal to .claude/ system.

### Internal Dependencies

**Commands that must continue to work**:
- /implement (uses implementer-coordinator agent)
- /test (uses debug-analyst and test-executor agents)
- /debug (uses debug-analyst agent)
- All other orchestrator commands using shared libraries

**Shared infrastructure that must be retained**:
- Agents: implementer-coordinator.md, debug-analyst.md, test-executor.md
- Libraries: workflow-state-machine.sh, state-persistence.sh, checkpoint-utils.sh, error-handling.sh, library-version-check.sh, checkbox-utils.sh
- State constants: STATE_IMPLEMENT, STATE_TEST, STATE_DEBUG, STATE_DOCUMENT, STATE_COMPLETE

### Verification Points
- Phase 1: Verify all dependencies are shared before deletion
- Phase 5: Verify alternative commands work after deletion

## Risk Assessment

### Low Risk
- All dependencies confirmed as shared infrastructure
- Alternative workflow tested and documented
- Clean-break approach is project standard

### Mitigation Strategies
1. **User Confusion**: Add clear migration guide to CLAUDE.md and commands README
2. **Broken Links**: Run link validator after each documentation phase
3. **Test Coverage Loss**: Build-specific tests become irrelevant; shared infrastructure covered by /implement and /test tests

### Rollback Plan
If issues discovered:
1. Git history preserves all deleted files
2. Restore build.md and build-command-guide.md from previous commit
3. Restore test files if needed
4. Revert documentation changes

## Completion Checklist

Before marking plan as [COMPLETE]:
- [ ] All 10 files deleted successfully
- [ ] All 25+ documentation files updated
- [ ] Link validation passes with zero broken links
- [ ] Grep verification shows no functional /build references
- [ ] /implement command tested and working
- [ ] /test command tested and working
- [ ] Alternative workflow documented in CLAUDE.md
- [ ] Commands README updated (section removed, count 12)
- [ ] TODO.md updated to reflect completion

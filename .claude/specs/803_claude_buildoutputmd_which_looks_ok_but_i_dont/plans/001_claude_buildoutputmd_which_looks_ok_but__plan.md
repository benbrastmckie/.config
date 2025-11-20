# Remove "Next Steps" Section from /build Command Final Output

## Metadata
- **Date**: 2025-11-19
- **Feature**: Remove redundant "Next Steps" section from build command completion output
- **Scope**: Build command Block 4 output and related documentation
- **Estimated Phases**: 3
- **Estimated Hours**: 1.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 12
- **Research Reports**:
  - [Build Final Summary Next Steps Removal](../reports/001_build_final_summary_next_steps_removal.md)

## Overview

The `/build` command currently displays a "Next Steps" section in its final output suggesting manual git operations (commit, review). This is redundant because the implementation-executor agent already creates git commits automatically after each phase completion. The "Next Steps" section misleads users into thinking they need to manually commit changes that have already been committed.

This plan removes the "Next Steps" section from the success path while maintaining a simplified re-run hint for the failure path.

## Research Summary

Key findings from the research report:
- **Location identified**: "Next Steps" generated in `/home/benjamin/.config/.claude/commands/build.md` lines 885-894
- **Redundancy confirmed**: Implementation-executor agent automatically commits after each phase (documented in lines 134-145 of implementation-executor.md)
- **Misleading guidance**: The current "git add -A && git commit" suggestion would cause empty commits or errors
- **Two paths**: Success path (tests passed) and failure path (tests failed) have different "Next Steps" content
- **Documentation impact**: Build command guide at `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` needs updating

Recommended approach: Remove "Next Steps" entirely for success path, simplify failure path to single re-run command hint.

## Success Criteria
- [ ] Success path displays no "Next Steps" section
- [ ] Failure path shows simplified single-line re-run hint
- [ ] Build command guide documentation updated to match new behavior
- [ ] Existing checkpoint deletion logic preserved
- [ ] Summary file path reference preserved in output

## Technical Design

### Architecture Overview

The change modifies the Block 4 completion output in build.md:

**Current Flow**:
```
Phase completion → Summary output → "Next Steps" section → Summary file path
```

**New Flow**:
```
Phase completion → Summary output → (failure hint if applicable) → Summary file path
```

### Component Changes

1. **build.md Block 4**: Remove "Next Steps" section, keep checkpoint deletion, add condensed failure hint
2. **build-command-guide.md**: Update examples to reflect new output format

### Design Decisions

- **Remove success path guidance entirely**: The build is complete; commits are done; no action needed
- **Condense failure hint**: "Re-run after applying fixes: /build $PLAN_FILE" is sufficient
- **Preserve summary file reference**: Users need to know where to find the summary artifact

## Implementation Phases

### Phase 1: Update Build Command [COMPLETE]
dependencies: []

**Objective**: Modify Block 4 completion output to remove "Next Steps" section

**Complexity**: Low

Tasks:
- [x] Read build.md to locate exact "Next Steps" code block (lines 885-894)
- [x] Modify success path to remove "Next Steps" echo statements while preserving delete_checkpoint call
- [x] Modify failure path to use simplified single-line re-run hint
- [x] Verify summary file path reference is preserved (appears after the Next Steps block)

Testing:
```bash
# Verify the changes compile correctly (no bash syntax errors)
bash -n /home/benjamin/.config/.claude/commands/build.md

# Visual inspection of changes
grep -A5 "TESTS_PASSED" /home/benjamin/.config/.claude/commands/build.md | grep -E "(Next Steps|echo)"
```

**Expected Duration**: 0.5 hours

### Phase 2: Update Documentation [COMPLETE]
dependencies: [1]

**Objective**: Update build command guide to reflect new output format

**Complexity**: Low

Tasks:
- [x] Read build-command-guide.md to locate "Next Steps" documentation (lines 323-326)
- [x] Update success examples to remove "Next Steps" section
- [x] Update failure examples to show simplified re-run guidance
- [x] Verify consistency between code and documentation

Testing:
```bash
# Check that documentation no longer references "Next Steps" in success examples
grep -n "Next Steps" /home/benjamin/.config/.claude/docs/guides/build-command-guide.md
```

**Expected Duration**: 0.5 hours

### Phase 3: Validation [COMPLETE]
dependencies: [1, 2]

**Objective**: Verify changes work correctly and maintain expected behavior

**Complexity**: Low

Tasks:
- [x] Review changed files for consistency
- [x] Verify checkpoint deletion still occurs on success path
- [x] Confirm summary file path reference is preserved
- [x] Verify no orphaned "Next Steps" references remain in modified files

Testing:
```bash
# Search for any remaining "Next Steps" references in modified files
grep -l "Next Steps" /home/benjamin/.config/.claude/commands/build.md /home/benjamin/.config/.claude/docs/guides/build-command-guide.md || echo "No 'Next Steps' found - expected for success path"

# Verify delete_checkpoint call preserved
grep "delete_checkpoint" /home/benjamin/.config/.claude/commands/build.md

# Check for balanced if/else/fi structure
grep -c "^  if \|^  else\|^  fi" /home/benjamin/.config/.claude/commands/build.md
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
- Bash syntax validation with `bash -n`
- Grep-based verification of expected patterns

### Integration Testing
- Visual inspection of modified sections
- Confirmation that checkpoint deletion logic remains intact

### Acceptance Testing
- Modified output matches expected format (no "Next Steps" on success, condensed hint on failure)
- Documentation accurately reflects code behavior

## Documentation Requirements

- Update `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` to remove "Next Steps" from success examples
- Ensure failure examples show simplified re-run command

## Dependencies

### Prerequisites
- None - standalone change to existing command

### Related Files
- `/home/benjamin/.config/.claude/commands/build.md` - Primary modification target
- `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` - Documentation update
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Reference only (no changes)

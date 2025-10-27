# Historical Comments Cleanup Implementation Plan

## Metadata
- **Date**: 2025-10-26
- **Feature**: Remove historical comments and temporal markers from .claude/docs/
- **Scope**: Clean up 44 files containing 226+ historical markers to align with timeless writing standards
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 58.0
- **Research Reports**:
  - [Historical Comments Analysis](../reports/001_historical_comments_analysis.md)

## Overview

This plan addresses the cleanup of extensive historical commentary in the `.claude/docs/` directory that violates the project's [Writing Standards](../../../.claude/docs/concepts/writing-standards.md) principle of "timeless writing". The research report identified 44 files with 226+ instances of temporal language, historical context sections, and version-specific notes that need to be removed or rewritten to focus on current system behavior.

The cleanup will be performed in severity-based phases, starting with critical violations (date stamps, "Previously/Now" comparisons) and progressing to moderate violations (migration notes, spec references). The goal is to transform documentation from describing "how the system evolved" to describing "what the system does".

## Research Summary

The research report identified five categories of historical markers requiring cleanup:

1. **Temporal Language** (~120 instances): Phrases like "previously", "now", "was", "were" that compare past and present states
2. **Historical Context Sections** (~15 sections): Dedicated sections explaining "Background", "Impact of Fix", "Solution Process"
3. **Version-Specific Notes** (~25 instances): Date stamps ("As of 2025-10-24"), version markers ("v1.X+"), deprecation notices
4. **Consolidation/Migration Notes** (~40 instances): References to past refactoring, file movements, guide mergers
5. **Spec Reference Patterns** (~18 instances): References to specific implementation plans (e.g., "spec 438")

**Severity Distribution**:
- 18% Critical (40 instances): Must remove immediately
- 64% Moderate (145 instances): Should clean up for consistency
- 18% Harmless (41 instances): Legitimate context to preserve

**Top Priority Files** (8 critical files):
1. `concepts/directory-protocols.md` - Date stamp removal
2. `reference/library-api.md` - Behavior change note rewrite
3. `guides/command-development-guide.md` - Historical context sections
4. `troubleshooting/inline-template-duplication.md` - Case study conversion
5. `workflows/checkpoint_template_guide.md` - Schema versioning simplification
6. `guides/README.md` - Consolidation note removal
7. `workflows/tts-integration-guide.md` - Removed features rewrite
8. `guides/performance-measurement.md` - Background comparison removal

## Success Criteria

- [ ] All critical violations removed (40 instances across 8 files)
- [ ] All moderate violations cleaned up (145 instances across 32 files)
- [ ] Legitimate historical context preserved (debug state, troubleshooting symptoms)
- [ ] Automated grep validation passes (0 matches for critical patterns)
- [ ] Documentation remains clear and actionable after cleanup
- [ ] No information loss from removed historical context
- [ ] All files follow timeless writing standards from CLAUDE.md

## Technical Design

### Cleanup Strategy

**Severity-Based Phased Approach**:
1. **Phase 1**: Critical files (8 files) - Manual review and rewrite required
2. **Phase 2**: Moderate files (32 files) - Batch processing with pattern replacement
3. **Phase 3**: Validation and verification using automated grep patterns
4. **Phase 4**: Spot-check and quality assurance
5. **Phase 5**: Documentation updates and completion

**Rewrite Patterns**:

| Before (Historical) | After (Timeless) |
|---------------------|------------------|
| "Previously created all subdirectories eagerly. Now creates only the topic root..." | "Creates the topic root directory. Subdirectories are created on-demand when files are written." |
| "As of 2025-10-24: Subdirectories are created on-demand..." | "Subdirectories are created on-demand when files are written to them." |
| "#### Historical Context\n\nThis anti-pattern was discovered in spec 438..." | "#### Code-Fenced Task Invocations Prevent Execution\n\nYAML blocks wrapped in code fences cause 0% delegation rate..." |
| "Current schema version: 1.3 (as of 2025-10-17)" | "Current schema version: 1.3" |

**Preservation Rules**:
- Keep debug/state context ("previously-failed tests", "most recently discussed plan")
- Keep troubleshooting symptoms ("Previously working command now fails")
- Keep scenario examples ("Legacy Documentation Migration" use case)
- Keep CHANGELOG/audit trail references

### Validation Approach

Use automated grep patterns from research report to verify cleanup:

```bash
# Critical temporal markers (target: 0 matches)
grep -r -E "\b(As of [0-9]{4}-[0-9]{2}-[0-9]{2}|previously created|now creates|was removed|were removed)\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md"

# Version markers (target: 0 matches)
grep -r -E "\((New|Updated|Current)\)|\b(v[0-9]+\.[0-9]+\+)\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md"

# Historical context sections (target: 0 matches)
grep -r -E "^###? (Historical Context|Background|Impact of Fix|Solution Process)" \
  .claude/docs/ --exclude-dir=archive --include="*.md"

# Spec references (target: <5 occurrences)
grep -r -E "\b(spec [0-9]{3,4}|Spec [0-9]{3,4})\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md" | wc -l
```

## Implementation Phases

### Phase 1: Critical Files Cleanup [COMPLETED]
dependencies: []

**Objective**: Remove critical violations from 8 high-priority files

**Complexity**: High

**Tasks**:
- [x] Clean up `concepts/directory-protocols.md` (line 69) - Remove "As of 2025-10-24" date stamp
- [x] Clean up `reference/library-api.md` (line 226) - Rewrite "Behavior Change: Previously... Now..." to present-only
- [x] Clean up `guides/command-development-guide.md` (lines 675-683, 765-772) - Remove "Historical Context" sections, preserve anti-pattern info
- [x] Clean up `troubleshooting/inline-template-duplication.md` (lines 470-499) - Convert case study narrative to timeless troubleshooting pattern
- [x] Clean up `workflows/checkpoint_template_guide.md` (lines 60-108, 184-197) - Remove version markers, simplify "Migration Path" to "Current Schema"

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] Clean up `guides/README.md` (lines 260-264) - Remove consolidation note about merged guides
- [x] Clean up `workflows/tts-integration-guide.md` (lines 108, 180) - Rewrite "were removed" to "are not supported"
- [x] Clean up `guides/performance-measurement.md` (line 522) - Remove "Background: previously used" comparison
- [x] Run initial validation grep patterns on cleaned files
- [x] Review each cleaned file to ensure clarity preserved

**Testing**:
```bash
# Verify critical patterns removed from Phase 1 files
for file in concepts/directory-protocols.md reference/library-api.md guides/command-development-guide.md \
            troubleshooting/inline-template-duplication.md workflows/checkpoint_template_guide.md \
            guides/README.md workflows/tts-integration-guide.md guides/performance-measurement.md; do
  echo "Checking $file..."
  grep -E "\b(As of [0-9]{4}|previously|now creates|Historical Context)\b" ".claude/docs/$file" && echo "FAIL: Still has violations" || echo "PASS"
done
```

**Expected Duration**: 3-4 hours

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(482): complete Phase 1 - Critical Files Cleanup`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Moderate Files - Temporal Language Cleanup
dependencies: [1]

**Objective**: Clean up temporal language patterns across remaining files

**Complexity**: Medium

**Tasks**:
- [ ] Identify all remaining files with temporal markers using grep pattern
- [ ] Batch 1: Search/replace "previously" patterns (review each match for context)
- [ ] Batch 2: Search/replace "was removed" / "were removed" patterns
- [ ] Batch 3: Search/replace "now supports" / "now creates" patterns
- [ ] Batch 4: Review and rewrite remaining temporal comparisons
- [ ] Run validation grep on all modified files
- [ ] Spot-check 5 files to ensure context preserved

**Testing**:
```bash
# Verify temporal language cleaned up
grep -r -E "\b(previously|was removed|were removed|now creates|now supports)\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md" \
  | grep -v "previously-failed" \
  | grep -v "Previously working command" \
  | wc -l  # Target: <10 occurrences (only legitimate context)
```

**Expected Duration**: 2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(482): complete Phase 2 - Temporal Language Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Moderate Files - Version/Migration Cleanup
dependencies: [1]

**Objective**: Simplify version markers, migration notes, and spec references

**Complexity**: Medium

**Tasks**:
- [ ] Clean up remaining version markers: "(New)", "(Updated)", "(v1.X+)"
- [ ] Simplify deprecated command warnings in `reference/command-reference.md`
- [ ] Review and clean up "Legacy Compatibility" sections (remove if functions gone, simplify if remain)
- [ ] Depersonalize spec number references (remove from narrative, optionally move to footnotes)
- [ ] Remove consolidation/migration announcements from guides
- [ ] Clean up remaining files from moderate priority list (files 9-44 from research report)
- [ ] Run validation grep on all modified files

**Testing**:
```bash
# Verify version markers removed
grep -r -E "\((New|Updated|Current)\)|\b(v[0-9]+\.[0-9]+\+)\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md" | wc -l  # Target: 0

# Verify spec references depersonalized
grep -r -E "\b(spec [0-9]{3,4}|Spec [0-9]{3,4})\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md" | wc -l  # Target: <5
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(482): complete Phase 3 - Version/Migration Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Validation and Quality Assurance
dependencies: [1, 2, 3]

**Objective**: Verify cleanup completeness and ensure no information loss

**Complexity**: Low

**Tasks**:
- [ ] Run all validation grep patterns from research report
- [ ] Generate summary report of remaining violations (if any)
- [ ] Manual spot-check 15 files across all categories (critical, moderate, harmless)
- [ ] Verify troubleshooting guides still provide actionable information
- [ ] Verify debug/state context preserved where needed
- [ ] Check for false positives (legitimate uses of temporal language)
- [ ] Review `writing-standards.md` to ensure example violations clearly marked
- [ ] Create list of any remaining violations that need manual review
- [ ] Verify all automated grep checks pass

**Testing**:
```bash
# Full validation suite
cd /home/benjamin/.config

# 1. Critical temporal markers (expect: 0 matches)
echo "=== Critical Temporal Markers ==="
grep -r -E "\b(As of [0-9]{4}-[0-9]{2}-[0-9]{2}|previously created|now creates|was removed|were removed)\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md" \
  | grep -v "previously-failed" \
  | grep -v "Previously working command"

# 2. Version markers (expect: 0 matches)
echo "=== Version Markers ==="
grep -r -E "\((New|Updated|Current)\)|\b(v[0-9]+\.[0-9]+\+)\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md"

# 3. Historical context sections (expect: 0 matches)
echo "=== Historical Context Sections ==="
grep -r -E "^###? (Historical Context|Background|Impact of Fix|Solution Process)" \
  .claude/docs/ --exclude-dir=archive --include="*.md"

# 4. Spec references (expect: <5 occurrences)
echo "=== Spec References (target <5) ==="
grep -r -E "\b(spec [0-9]{3,4}|Spec [0-9]{3,4})\b" \
  .claude/docs/ --exclude-dir=archive --include="*.md" | wc -l
```

**Expected Duration**: 1-2 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(482): complete Phase 4 - Validation and QA`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Documentation and Completion
dependencies: [4]

**Objective**: Update documentation and finalize cleanup

**Complexity**: Low

**Tasks**:
- [ ] Update research report with implementation results (total violations removed, files modified)
- [ ] Document any remaining edge cases or exceptions in writing-standards.md
- [ ] Create summary of cleanup results (violations removed, effort spent, lessons learned)
- [ ] Update this implementation plan with completion status
- [ ] Verify all commits follow project commit message standards
- [ ] Final review of git diff to ensure only historical markers removed
- [ ] Mark all success criteria as complete

**Testing**:
```bash
# Verify no unintended changes
git diff --stat | grep -E "(\.md|\.sh|\.lua)" | wc -l  # Should show only docs/ files modified

# Verify commit messages follow standards
git log --oneline -5 | grep "feat(482):" | wc -l  # Should show 5 commits
```

**Expected Duration**: 1 hour

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(482): complete Phase 5 - Documentation and Completion`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Automated Validation

Use grep patterns throughout implementation to verify cleanup:

1. **After each file cleanup**: Run targeted grep on specific file
2. **After each phase**: Run category-specific grep (temporal, version, context sections)
3. **Phase 4**: Run full validation suite on entire `.claude/docs/` directory

### Manual Validation

1. **Spot-checks**: Review 15 files manually to ensure:
   - Historical markers removed
   - Present-tense descriptions remain clear
   - No information loss from removals
   - Legitimate context preserved

2. **Troubleshooting verification**: Verify guides still provide:
   - Clear problem descriptions
   - Actionable detection steps
   - Working solutions

3. **Context preservation**: Verify legitimate historical references retained:
   - Debug state ("previously-failed tests")
   - Troubleshooting symptoms ("Previously working command now fails")
   - Scenario examples ("Legacy Documentation Migration")

### Coverage Requirements

- 100% of critical violations removed (40 instances)
- 100% of moderate violations cleaned up (145 instances)
- 100% of harmless violations preserved (41 instances)
- All automated grep checks pass (0 matches for critical patterns)

## Documentation Requirements

### Files to Update

1. **Research Report** (`../reports/001_historical_comments_analysis.md`):
   - Add "Implementation Status" section
   - Link to this plan
   - Update with final cleanup results

2. **Writing Standards** (`concepts/writing-standards.md`):
   - Document any new edge cases discovered during cleanup
   - Add examples of good rewrites if needed
   - Verify example violations are clearly marked

3. **This Implementation Plan**:
   - Update task checkboxes as work progresses
   - Mark phases complete
   - Add final summary section with results

### Documentation Standards

- Follow timeless writing principles (the goal of this cleanup!)
- Use present tense for all descriptions
- Focus on "what the system does" not "how it evolved"
- Preserve actionable information while removing historical context
- Follow CLAUDE.md documentation policy

## Dependencies

### External Dependencies
- None (internal documentation cleanup only)

### Prerequisites
- Read access to all `.claude/docs/` files
- Write access to modify documentation
- Git access for commits
- Research report completed (already done)

### Blocked Tasks
- None (all phases can proceed sequentially after Phase 1)

### Integration Points
- Research report (bidirectional link)
- Writing standards documentation
- Git commit history

## Risk Management

### Identified Risks

1. **Information Loss**: Risk that removing historical context also removes important context
   - **Mitigation**: Manual review of each critical file, preserve debug/troubleshooting context
   - **Severity**: Medium

2. **Clarity Reduction**: Risk that timeless rewrites are less clear than historical comparisons
   - **Mitigation**: Spot-check rewritten sections, ask "does this explain current behavior clearly?"
   - **Severity**: Medium

3. **False Positives**: Risk that automated grep patterns flag legitimate uses
   - **Mitigation**: Manual review of grep results, context-aware replacement
   - **Severity**: Low

4. **Scope Creep**: Risk of over-cleaning and removing legitimate historical records
   - **Mitigation**: Preserve CHANGELOG references, debug context, troubleshooting symptoms
   - **Severity**: Low

### Rollback Strategy

If cleanup introduces errors:
1. Use git to identify problematic changes: `git diff <commit>`
2. Revert specific file: `git checkout HEAD~1 -- <file>`
3. Re-apply cleanup with more careful rewrite
4. All commits are atomic by phase for easy rollback

## Notes

**High Complexity Justification**: Complexity score of 58.0 indicates this may benefit from phase expansion during implementation. Consider using `/expand` if any phase becomes too complex.

**Batch Processing**: Phase 2 and 3 involve batch processing of 32 files. Consider creating helper scripts for common patterns if manual replacement becomes tedious.

**Writing Standards Reference**: This cleanup directly implements the timeless writing standards documented in `concepts/writing-standards.md` (lines 1-102). The cleaned files will serve as examples of best practices.

**Archive Directory**: The 7 files in `.claude/docs/archive/` are intentionally excluded from cleanup as they are historical records by definition.

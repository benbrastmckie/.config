# Remove All Mentions of Archived Content Implementation Plan

## Metadata
- **Date**: 2025-10-26
- **Feature**: Remove all references to archived content from .claude/ directory
- **Scope**: CLAUDE.md, command files, and documentation files
- **Estimated Phases**: 5
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 32.5
- **Research Reports**:
  - [CLAUDE.md archive mentions](/home/benjamin/.config/.claude/specs/483_remove_all_mentions_of_archived_content_in_claude_/reports/001_topic1.md)
  - [Command file archive mentions](/home/benjamin/.config/.claude/specs/483_remove_all_mentions_of_archived_content_in_claude_/reports/002_topic2.md)
  - [Documentation archive mentions](/home/benjamin/.config/.claude/specs/483_remove_all_mentions_of_archived_content_in_claude_/reports/003_topic3.md)

## Overview

This plan removes all mentions of archived content from the .claude/ directory while preserving legitimate operational uses of the term "archive" (checkpoint archival, data retention policies). The goal is to eliminate historical commentary and dead code references while maintaining clean, present-focused documentation per the project's development philosophy.

## Research Summary

Based on research findings across three reports:

**CLAUDE.md Analysis (Report 1)**:
- 3 mentions in "Recent Cleanup (2025-10-26)" section (lines 328, 430, 434)
- References archived /report command, legacy libraries, and archive directory location
- Recommendation: Replace detailed cleanup notes with condensed reference

**Command Files Analysis (Report 2)**:
- 35 total mentions across 8 files, but only 5 require action
- 3 dead code fallbacks referencing archived location-specialist agent
- 1 broken reference to non-existent "Plan 034"
- 30 mentions are legitimate (historical docs, checkpoint management, writing standards)

**Documentation Analysis (Report 3)**:
- 12 files with broken references to removed utils/ and examples/ directories
- archive/ subdirectory documentation is legitimate and should be preserved
- Library API reference mentions 2 archived library files

**Recommended Approach**:
- Phase-by-phase cleanup starting with dead code (highest impact)
- Preserve operational archive usage (checkpoints, data retention)
- Update broken directory references (utils/ → lib/, examples/ removed)
- Condense historical commentary in CLAUDE.md per writing standards

## Success Criteria
- [ ] All dead code fallbacks to archived agents removed
- [ ] All references to non-existent directories (utils/, examples/) updated or removed
- [ ] CLAUDE.md "Recent Cleanup" section condensed to single-line reference
- [ ] All references to non-existent plans removed or updated
- [ ] Operational "archive" usage preserved (checkpoint archival, data retention)
- [ ] No broken links remain in documentation
- [ ] Writing standards compliance verified (no historical markers)

## Technical Design

### Categorization of Archive Mentions

**Category 1: Dead Code (REMOVE)**
- orchestrate.md lines 467-469: Fallback to archived location-specialist agent (no implementation)
- supervise.md line 688: Error fallback to archived agent (unreachable code)

**Category 2: Broken References (UPDATE)**
- analyze.md line 295: Reference to non-existent "Plan 034"
- 12 documentation files: References to removed utils/ directory (→ lib/)
- 3 documentation files: References to removed examples/ directory (→ remove/redirect)
- library-api.md lines 787-789: Archived library files (mark as archived or remove)

**Category 3: Historical Commentary (CONDENSE)**
- CLAUDE.md lines 425-434: "Recent Cleanup" section (10 lines → 1 line)
- README.md (commands): Historical cleanup notes (keep for migration guidance)

**Category 4: Legitimate Usage (PRESERVE)**
- Checkpoint archival to .claude/data/checkpoints/failed/
- Data retention policies (logs, metrics)
- Writing standards enforcement (temporal marker checks)
- archive/ subdirectory documentation in docs/README.md

### Update Strategy

1. **Dead Code Removal**: Direct deletion via Edit tool
2. **Broken Directory References**: Regex-based replacement (utils/ → lib/)
3. **Historical Commentary**: Condensation following writing standards
4. **Verification**: Grep searches to confirm no unintended removals

## Implementation Phases

### Phase 1: Remove Dead Code Fallbacks [COMPLETED]
dependencies: []

**Objective**: Eliminate dead code that references archived agents with no implementation

**Complexity**: Low

**Tasks**:
- [x] Remove fallback code in orchestrate.md (lines 467-469) - legacy location-specialist agent reference
- [x] Replace error fallback in supervise.md (line 688) with proper error handling
- [x] Verify no other commands have similar dead code patterns via grep search

**Testing**:
```bash
# Verify removed code doesn't break command execution
cd /home/benjamin/.config
grep -n "location-specialist" .claude/commands/*.md
grep -n "fallback.*agent" .claude/commands/*.md
```

**Expected Duration**: 30 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(483): complete Phase 1 - Remove Dead Code Fallbacks`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Fix Broken Plan and Library References [COMPLETED]
dependencies: [1]

**Objective**: Update or remove references to non-existent plans and archived library files

**Complexity**: Low

**Tasks**:
- [x] Update analyze.md line 295 - remove "(see Plan 034)" or replace with accurate context
- [x] Update library-api.md lines 787-789 - mark artifact-operations-legacy.sh and migrate-specs-utils.sh as archived
- [x] Verify no other broken plan references exist via grep pattern search

**Testing**:
```bash
# Verify no broken plan references remain
cd /home/benjamin/.config
grep -E "Plan [0-9]{3}|plan [0-9]{3}|spec [0-9]{3}" .claude/commands/*.md .claude/docs/**/*.md
grep "artifact-operations-legacy\|migrate-specs-utils" .claude/docs/**/*.md
```

**Expected Duration**: 30 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(483): complete Phase 2 - Fix Broken Plan and Library References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Update Broken Directory References [COMPLETED]
dependencies: [1]

**Objective**: Replace references to removed utils/ and examples/ directories with current equivalents

**Complexity**: Medium

**Tasks**:
- [x] Update adaptive-planning-guide.md - replace .claude/utils/ references with lib/ equivalents (10 occurrences)
- [x] Update efficiency-guide.md - replace .claude/utils/ references with lib/ equivalents (8 occurrences)
- [x] Update data-management.md - replace .claude/utils/ references with lib/ equivalents (1 occurrence)
- [x] Update error-enhancement-guide.md - replace .claude/utils/ references with lib/ equivalents (6 occurrences)
- [x] Update migration-guide-adaptive-plans.md - SKIPPED (file is in archive, preserve as-is)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [x] Update agent-delegation-issues.md - remove or redirect examples/ references (8 occurrences)
- [x] Update setup-command-guide.md - remove or redirect examples/ references (1 occurrence)
- [x] Update command-development-guide.md - remove or redirect examples/ references (1 occurrence)
- [x] Update docs/README.md line 136 - change /report to /research or add "(archived)" note
- [x] Verify all utils/ and examples/ references updated via grep search

**Testing**:
```bash
# Verify no broken directory references remain
cd /home/benjamin/.config
grep -n "\.claude/utils/" .claude/docs/**/*.md
grep -n "\.claude/examples/" .claude/docs/**/*.md .claude/commands/*.md
grep -n "examples/correct-agent-invocation\|examples/behavioral-injection\|examples/reference-implementations" .claude/docs/**/*.md
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(483): complete Phase 3 - Update Broken Directory References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Condense Historical Commentary in CLAUDE.md
dependencies: [2]

**Objective**: Replace detailed cleanup section with condensed reference per writing standards

**Complexity**: Low

**Tasks**:
- [ ] Read current CLAUDE.md "Recent Cleanup" section (lines 425-434)
- [ ] Replace 10-line section with single-line reference to archive documentation
- [ ] Preserve /report → /research migration note in commands section (line 328)
- [ ] Verify writing standards compliance (no temporal markers like "Recent", dated references)

**Testing**:
```bash
# Verify historical markers removed
cd /home/benjamin/.config
grep -i "recent\|2025-10-26\|cleanup" CLAUDE.md
grep -i "previously\|formerly\|legacy.*archive" CLAUDE.md
```

**Expected Duration**: 30 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(483): complete Phase 4 - Condense Historical Commentary in CLAUDE.md`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Verification and Final Cleanup
dependencies: [3, 4]

**Objective**: Comprehensive verification that all archive mentions are appropriate and no broken references remain

**Complexity**: Low

**Tasks**:
- [ ] Run comprehensive grep search for all "archive" mentions across .claude/ directory
- [ ] Manually verify each remaining mention is legitimate (checkpoint archival, data retention, archive/ subdirectory docs)
- [ ] Check for any unintended removals via git diff review
- [ ] Verify no broken links exist in documentation
- [ ] Run documentation link checker if available
- [ ] Update this plan file status to "Complete"

**Testing**:
```bash
# Comprehensive archive mention verification
cd /home/benjamin/.config
echo "=== All remaining 'archive' mentions ==="
grep -rn "archive" .claude/ --include="*.md" | grep -v ".claude/archive/" | grep -v "checkpoint.*archive" | grep -v "data.*archive"

echo "=== Verify no dead code remains ==="
grep -rn "location-specialist" .claude/commands/

echo "=== Verify no broken directory references ==="
grep -rn "\.claude/utils/" .claude/docs/
grep -rn "\.claude/examples/" .claude/docs/

echo "=== Verify no broken plan references ==="
grep -rEn "Plan [0-9]{3}" .claude/commands/ .claude/docs/
```

**Expected Duration**: 30 minutes

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(483): complete Phase 5 - Verification and Final Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Per-Phase Testing
- Use grep searches to verify specific removals/updates
- Check for unintended side effects via git diff
- Verify no broken links remain after each phase

### Final Verification
- Comprehensive grep search for all "archive" mentions
- Manual review of each remaining mention to ensure legitimacy
- Documentation link validation
- Review git diff for entire changeset

### Test Commands
All testing uses bash grep commands as shown in phase testing sections.

## Documentation Requirements

### Files to Update
- CLAUDE.md (condense cleanup section)
- orchestrate.md (remove dead code)
- supervise.md (update error handling)
- analyze.md (fix plan reference)
- library-api.md (mark archived files)
- 5 documentation files (utils/ references)
- 3 documentation files (examples/ references)
- docs/README.md (/report reference)

### Documentation Standards
- Follow writing standards: no temporal markers, no historical commentary
- Preserve operational documentation (checkpoint archival, data retention)
- Ensure all links are valid and point to existing files
- Maintain present-focused, timeless documentation per development philosophy

## Dependencies

### External Dependencies
None - all changes are internal to .claude/ directory

### Internal Dependencies
- Phase dependencies ensure logical order (dead code first, verification last)
- Git available for commits and diff reviews
- Grep available for search verification

### File Dependencies
- All target files exist and are writable
- No concurrent modifications expected during implementation

## Risk Management

### Low Risk Areas
- Dead code removal (lines 467-469 in orchestrate.md, line 688 in supervise.md)
- Plan reference updates (analyze.md line 295)
- Historical commentary condensation (CLAUDE.md)

### Medium Risk Areas
- Directory reference updates (utils/ → lib/) - must ensure correct lib/ equivalents
- Examples directory removal - must provide appropriate redirects

### Mitigation Strategies
- Git commits per phase enable easy rollback
- Comprehensive grep verification after each phase
- Manual review of git diff before final commit
- Preserve operational archive usage (checkpoints, data retention)

### Rollback Plan
- All phases create individual git commits
- Can cherry-pick revert if specific phase causes issues
- Research reports preserved for reference if rework needed

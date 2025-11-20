# Documentation Cleanup for Deleted Library Files

## Metadata
- **Date**: 2025-11-19
- **Feature**: Documentation cleanup for deleted lib files
- **Scope**: Remove/update stale references to 15 deleted library files across documentation
- **Estimated Phases**: 6
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 56
- **Research Reports**:
  - [Deleted Lib Files Analysis](/home/benjamin/.config/.claude/specs/44_deleted_lib_docs_cleanup/reports/001_deleted_lib_files_analysis.md)

## Overview

This plan addresses documentation cleanup following the lib directory refactoring (commit fb8680db). 15 library files were deleted but documentation references remain, creating broken links and confusion about available utilities.

**Key Goals:**
1. Update references to consolidated libraries (parse-adaptive-plan.sh -> plan-core-bundle.sh, complexity-thresholds.sh -> complexity-utils.sh)
2. Remove references to archived/never-implemented utilities (13 files)
3. Ensure documentation accurately reflects available library infrastructure

## Research Summary

Analysis of 15 deleted library files found:
- **2 files need UPDATE_REFS**: parse-adaptive-plan.sh (21 refs) consolidated to plan-core-bundle.sh, complexity-thresholds.sh (6 refs) consolidated to complexity-utils.sh
- **13 files need REMOVE_REFS**: Archived utilities that were never implemented or deemed unnecessary
- **Zero files need restoration** - all deletions were intentional

Recommended approach: Use bulk sed commands for efficiency, organize by documentation location type.

## Success Criteria

- [ ] All references to parse-adaptive-plan.sh updated to reference plan-core-bundle.sh
- [ ] All references to complexity-thresholds.sh updated to reference complexity-utils.sh
- [ ] All references to 13 removed utilities completely eliminated from documentation
- [ ] No grep matches found for any of the 15 deleted file names
- [ ] Documentation remains internally consistent after changes
- [ ] UTILS_README.md accurately reflects only existing utilities

## Technical Design

### Approach
Use sed commands with in-place editing for efficient bulk changes. Organize by documentation category:
1. **API documentation** (.claude/docs/reference/library-api/) - heaviest concentration
2. **Guide documentation** (.claude/docs/guides/) - scattered references
3. **Workflow/concept documentation** - isolated references
4. **Core infrastructure** (UTILS_README.md, README.md, commands/)

### Consolidation Mappings
- `parse-adaptive-plan.sh` -> `lib/plan/plan-core-bundle.sh`
- `complexity-thresholds.sh` -> `lib/plan/complexity-utils.sh`

### Files to Remove References To
1. generate-readme.sh
2. agent-registry-utils.sh
3. monitor-model-usage.sh
4. validate-context-reduction.sh
5. list-checkpoints.sh
6. json-utils.sh
7. cleanup-checkpoints.sh
8. dependency-analysis.sh
9. agent-discovery.sh
10. context-metrics.sh
11. agent-schema-validator.sh
12. deps-utils.sh
13. git-utils.sh

## Implementation Phases

### Phase 1: Update Consolidated Library References [COMPLETE]
dependencies: []

**Objective**: Update documentation references for the 2 consolidated libraries
**Complexity**: Low

Tasks:
- [x] Update parse-adaptive-plan.sh -> plan-core-bundle.sh in .claude/README.md
- [x] Update parse-adaptive-plan.sh references in .claude/docs/workflows/adaptive-planning-guide.md
- [x] Update parse-adaptive-plan.sh references in .claude/commands/README.md
- [x] Update parse-adaptive-plan.sh references in .claude/commands/expand.md
- [x] Update parse-adaptive-plan.sh references in .claude/docs/reference/architecture/documentation.md
- [x] Update parse-adaptive-plan.sh references in .claude/docs/reference/architecture/error-handling.md
- [x] Update complexity-thresholds.sh -> complexity-utils.sh in .claude/docs/guides/patterns/refactoring-methodology.md
- [x] Update complexity-thresholds.sh references in .claude/docs/reference/library-api/utilities.md
- [x] Update complexity-thresholds.sh references in .claude/docs/reference/library-api/overview.md

Testing:
```bash
# Verify all references updated correctly
grep -r "parse-adaptive-plan\.sh" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v "consolidated\|archived" | wc -l
grep -r "complexity-thresholds\.sh" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v "consolidated\|archived" | wc -l
# Expected: 0 matches for each (or only archival notes)
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Remove API Documentation References [COMPLETE]
dependencies: [1]

**Objective**: Clean up library-api documentation for removed utilities
**Complexity**: Medium

Tasks:
- [x] Remove agent-registry-utils.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove agent-discovery.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove agent-schema-validator.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove context-metrics.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove deps-utils.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove git-utils.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove json-utils.sh section from .claude/docs/reference/library-api/utilities.md
- [x] Remove agent-registry-utils.sh reference from .claude/docs/reference/library-api/overview.md

Testing:
```bash
# Verify API docs clean
for file in agent-registry-utils agent-discovery agent-schema-validator context-metrics deps-utils git-utils json-utils; do
  count=$(grep -c "${file}\.sh" /home/benjamin/.config/.claude/docs/reference/library-api/*.md 2>/dev/null || echo 0)
  echo "${file}.sh: $count references"
done
# Expected: 0 references for each
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Remove Guide Documentation References [COMPLETE]
dependencies: [1]

**Objective**: Clean up guide documentation for removed utilities
**Complexity**: Medium

Tasks:
- [x] Remove "README Scaffolding" section from .claude/docs/guides/commands/setup-command-guide.md (generate-readme.sh refs)
- [x] Remove "Monitoring" section from .claude/docs/guides/development/model-selection-guide.md (monitor-model-usage.sh refs)
- [x] Remove agent-registry-utils.sh examples from .claude/docs/guides/patterns/implementation-guide.md
- [x] Remove json-utils.sh reference from .claude/docs/guides/development/using-utility-libraries.md
- [x] Remove agent-registry-utils.sh reference from .claude/docs/guides/development/command-development/command-development-standards-integration.md

Testing:
```bash
# Verify guide docs clean
grep -r "generate-readme\.sh\|monitor-model-usage\.sh\|agent-registry-utils\.sh\|json-utils\.sh" /home/benjamin/.config/.claude/docs/guides/ --include="*.md" | wc -l
# Expected: 0 references
```

**Expected Duration**: 0.75 hours

---

### Phase 4: Remove Workflow and Concept Documentation References [COMPLETE]
dependencies: [1]

**Objective**: Clean up workflow and concept documentation for removed utilities
**Complexity**: Low

Tasks:
- [x] Remove list-checkpoints.sh references from .claude/docs/workflows/adaptive-planning-guide.md
- [x] Remove cleanup-checkpoints.sh references from .claude/docs/workflows/adaptive-planning-guide.md
- [x] Remove validate-context-reduction.sh reference from .claude/docs/troubleshooting/agent-delegation-troubleshooting.md
- [x] Remove validate-context-reduction.sh reference from .claude/docs/concepts/hierarchical-agents.md
- [x] Remove dependency-analysis.sh reference from .claude/docs/reference/workflows/phase-dependencies.md

Testing:
```bash
# Verify workflow/concept docs clean
grep -r "list-checkpoints\.sh\|cleanup-checkpoints\.sh\|validate-context-reduction\.sh\|dependency-analysis\.sh" /home/benjamin/.config/.claude/docs/ --include="*.md" | wc -l
# Expected: 0 references
```

**Expected Duration**: 0.5 hours

---

### Phase 5: Clean Up Core Library References [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Update UTILS_README.md and core library documentation
**Complexity**: Medium

Tasks:
- [x] Remove parse-adaptive-plan.sh from .claude/lib/UTILS_README.md (update to plan-core-bundle.sh)
- [x] Remove complexity-thresholds.sh from .claude/lib/UTILS_README.md (update to complexity-utils.sh)
- [x] Remove validate-context-reduction.sh references from .claude/lib/UTILS_README.md
- [x] Remove list-checkpoints.sh references from .claude/lib/UTILS_README.md
- [x] Remove cleanup-checkpoints.sh references from .claude/lib/UTILS_README.md
- [x] Remove agent-registry-utils.sh reference from .claude/lib/core/error-handling.sh (line ~1026)
- [x] Update .claude/CHANGELOG.md parse-adaptive-plan.sh references if needed

Testing:
```bash
# Verify UTILS_README.md only documents existing files
grep -E "parse-adaptive-plan|complexity-thresholds|validate-context-reduction|list-checkpoints|cleanup-checkpoints" /home/benjamin/.config/.claude/lib/UTILS_README.md | wc -l
# Expected: 0 or only consolidated notes
```

**Expected Duration**: 0.5 hours

---

### Phase 6: Validation and Verification [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Verify all references removed and documentation consistency
**Complexity**: Low

Tasks:
- [x] Run comprehensive grep for all 15 deleted file names
- [x] Verify no broken internal links in documentation
- [x] Ensure consolidation notes are present where appropriate
- [x] Confirm UTILS_README.md table of contents matches actual files
- [x] Create summary report of changes made

Testing:
```bash
# Comprehensive verification for all 15 files
DELETED_FILES="parse-adaptive-plan complexity-thresholds generate-readme agent-registry-utils monitor-model-usage validate-context-reduction list-checkpoints json-utils cleanup-checkpoints dependency-analysis agent-discovery context-metrics agent-schema-validator deps-utils git-utils"

echo "=== Final Verification ==="
for file in $DELETED_FILES; do
  count=$(grep -r "${file}\.sh" /home/benjamin/.config/.claude/ --include="*.md" --include="*.sh" 2>/dev/null | grep -v "specs/\|backup\|archived\|consolidated" | wc -l)
  if [ "$count" -gt 0 ]; then
    echo "WARNING: ${file}.sh still has $count active references"
  else
    echo "OK: ${file}.sh - all references cleaned"
  fi
done

# Link validation
echo ""
echo "=== Link Validation ==="
find /home/benjamin/.config/.claude/docs -name "*.md" -exec grep -l "lib/.*\.sh" {} \; | while read doc; do
  grep -o "lib/[^)]*\.sh" "$doc" | sort -u | while read lib; do
    if [ ! -f "/home/benjamin/.config/.claude/$lib" ]; then
      echo "BROKEN: $doc references non-existent $lib"
    fi
  done
done
```

**Expected Duration**: 0.25 hours

## Testing Strategy

### Unit Testing
Each phase includes targeted grep commands to verify specific file references are removed/updated.

### Integration Testing
Phase 6 provides comprehensive validation across all documentation to ensure:
1. No stale references remain (grep all 15 filenames)
2. No broken links exist (verify lib paths point to existing files)
3. Consolidation mappings are complete and accurate

### Success Validation
Final validation command:
```bash
# Should return 0 for all deleted files
for f in parse-adaptive-plan complexity-thresholds generate-readme agent-registry-utils monitor-model-usage validate-context-reduction list-checkpoints json-utils cleanup-checkpoints dependency-analysis agent-discovery context-metrics agent-schema-validator deps-utils git-utils; do
  grep -r "${f}\.sh" /home/benjamin/.config/.claude/{docs,lib,commands} --include="*.md" --include="*.sh" 2>/dev/null | grep -v "archived\|consolidated\|specs/" || true
done | wc -l
```

## Documentation Requirements

- No new documentation needed - this is cleanup of existing docs
- UTILS_README.md must be updated to reflect current utility library state
- Consolidation notes should be preserved in appropriate locations (e.g., expand.md:862)

## Dependencies

### Prerequisites
- Research report analysis complete (done - see report 001)
- Git history verification of consolidation targets complete

### External Dependencies
- None - documentation-only changes

### Tools Required
- sed (for bulk in-place edits)
- grep (for verification)
- Standard bash utilities

## Risk Assessment

### Low Risk
- All changes are documentation-only (no code functionality impact)
- Consolidation targets verified to exist (plan-core-bundle.sh, complexity-utils.sh)
- Can be incrementally validated per phase

### Mitigation
- Verify each file edit before proceeding to next
- Maintain backup awareness (git provides version control)
- Test commands provided for each phase

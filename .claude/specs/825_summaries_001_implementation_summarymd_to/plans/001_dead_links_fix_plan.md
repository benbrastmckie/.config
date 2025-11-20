# Dead Links Fix Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix Dead Links in .claude/docs/
- **Scope**: Fix all broken links resulting from lib/ directory reorganization
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 62.5
- **Research Reports**:
  - [Broken Links Research](/home/benjamin/.config/.claude/specs/825_summaries_001_implementation_summarymd_to/reports/001_broken_links_research.md)

## Overview

Fix 80+ broken documentation links across 15+ files in .claude/docs/ resulting from lib/ directory reorganization. The lib/ directory was restructured from a flat organization into subdirectories (core/, workflow/, artifact/, plan/, util/, convert/), breaking all existing `lib/filename.sh` references. Additionally, 8 missing files are referenced in documentation, and several test file paths have incorrect depth.

## Research Summary

Key findings from research report:
- **80+ broken lib links** across 15+ files using old flat `lib/filename.sh` paths
- **8 missing files** referenced in documentation (context-pruning.sh most critical with 24+ refs)
- **7+ test path issues** in docs/concepts/patterns/ and docs/guides/ directories
- **Path mapping documented** - complete old-to-new path mappings provided for bulk sed replacement
- **Risk level**: Low (documentation-only changes)

Recommended approach: Use systematic sed-based bulk replacements with validation after each phase.

## Success Criteria
- [ ] All 80+ lib reorganization links fixed to new subdirectory paths
- [ ] All 8 missing file references resolved (removed or documented)
- [ ] All test file path depths corrected in pattern documentation
- [ ] Link validation script runs without errors
- [ ] No regression in existing documentation functionality

## Technical Design

### Fix Strategy

The fix uses bulk sed replacements organized by target subdirectory for maintainability:

1. **Workflow subdirectory files**: workflow-*.sh, checkpoint-utils.sh, metadata-extraction.sh, argument-capture.sh
2. **Core subdirectory files**: unified-*.sh, detect-project-dir.sh, error-handling.sh, state-persistence.sh, library-sourcing.sh
3. **Artifact subdirectory files**: artifact-*.sh, template-integration.sh
4. **Plan subdirectory files**: topic-*.sh, complexity-utils.sh, plan-core-bundle.sh, auto-analysis-utils.sh
5. **Util subdirectory files**: backup-command-file.sh, rollback-command-file.sh, validate-agent-invocation-pattern.sh
6. **Convert subdirectory files**: convert-*.sh

### Missing File Resolution

For the 8 missing files:
- **context-pruning.sh** (24+ refs): Document as planned but not implemented, remove references
- **parse-adaptive-plan.sh**, **list-checkpoints.sh**, **cleanup-checkpoints.sh**: Part of adaptive planning not yet implemented
- **dependency-analysis.sh**, **conversion-logger.sh**, **utils.sh**, **validate-context-reduction.sh**: Remove references

### File Path Resolution

Test paths in docs/concepts/patterns/ need depth adjustment from `../../tests/` to `../../../tests/`.

## Implementation Phases

### Phase 1: Fix Lib Reorganization Links [COMPLETE]
dependencies: []

**Objective**: Fix all 80+ broken lib links to use new subdirectory structure
**Complexity**: Medium

Tasks:
- [x] Fix workflow subdirectory links (workflow-*.sh, checkpoint-utils.sh, metadata-extraction.sh, argument-capture.sh)
  ```bash
  find .claude/docs -name "*.md" -exec sed -i \
    -e 's|lib/workflow-llm-classifier\.sh|lib/workflow/workflow-llm-classifier.sh|g' \
    -e 's|lib/workflow-scope-detection\.sh|lib/workflow/workflow-scope-detection.sh|g' \
    -e 's|lib/workflow-detection\.sh|lib/workflow/workflow-detection.sh|g' \
    -e 's|lib/workflow-initialization\.sh|lib/workflow/workflow-initialization.sh|g' \
    -e 's|lib/workflow-init\.sh|lib/workflow/workflow-init.sh|g' \
    -e 's|lib/workflow-state-machine\.sh|lib/workflow/workflow-state-machine.sh|g' \
    -e 's|lib/checkpoint-utils\.sh|lib/workflow/checkpoint-utils.sh|g' \
    -e 's|lib/metadata-extraction\.sh|lib/workflow/metadata-extraction.sh|g' \
    -e 's|lib/argument-capture\.sh|lib/workflow/argument-capture.sh|g' \
    {} \;
  ```

- [x] Fix core subdirectory links (unified-*.sh, detect-project-dir.sh, error-handling.sh, state-persistence.sh, library-sourcing.sh)
  ```bash
  find .claude/docs -name "*.md" -exec sed -i \
    -e 's|lib/unified-location-detection\.sh|lib/core/unified-location-detection.sh|g' \
    -e 's|lib/unified-logger\.sh|lib/core/unified-logger.sh|g' \
    -e 's|lib/detect-project-dir\.sh|lib/core/detect-project-dir.sh|g' \
    -e 's|lib/error-handling\.sh|lib/core/error-handling.sh|g' \
    -e 's|lib/state-persistence\.sh|lib/core/state-persistence.sh|g' \
    -e 's|lib/library-sourcing\.sh|lib/core/library-sourcing.sh|g' \
    -e 's|lib/base-utils\.sh|lib/core/base-utils.sh|g' \
    -e 's|lib/timestamp-utils\.sh|lib/core/timestamp-utils.sh|g' \
    -e 's|lib/library-version-check\.sh|lib/core/library-version-check.sh|g' \
    {} \;
  ```

- [x] Fix artifact subdirectory links (artifact-*.sh, template-integration.sh, overview-synthesis.sh, substitute-variables.sh)
  ```bash
  find .claude/docs -name "*.md" -exec sed -i \
    -e 's|lib/artifact-creation\.sh|lib/artifact/artifact-creation.sh|g' \
    -e 's|lib/artifact-registry\.sh|lib/artifact/artifact-registry.sh|g' \
    -e 's|lib/template-integration\.sh|lib/artifact/template-integration.sh|g' \
    -e 's|lib/overview-synthesis\.sh|lib/artifact/overview-synthesis.sh|g' \
    -e 's|lib/substitute-variables\.sh|lib/artifact/substitute-variables.sh|g' \
    {} \;
  ```

- [x] Fix plan subdirectory links (topic-*.sh, complexity-utils.sh, plan-core-bundle.sh, auto-analysis-utils.sh, checkbox-utils.sh, parse-template.sh)
  ```bash
  find .claude/docs -name "*.md" -exec sed -i \
    -e 's|lib/topic-decomposition\.sh|lib/plan/topic-decomposition.sh|g' \
    -e 's|lib/topic-utils\.sh|lib/plan/topic-utils.sh|g' \
    -e 's|lib/complexity-utils\.sh|lib/plan/complexity-utils.sh|g' \
    -e 's|lib/plan-core-bundle\.sh|lib/plan/plan-core-bundle.sh|g' \
    -e 's|lib/auto-analysis-utils\.sh|lib/plan/auto-analysis-utils.sh|g' \
    -e 's|lib/checkbox-utils\.sh|lib/plan/checkbox-utils.sh|g' \
    -e 's|lib/parse-template\.sh|lib/plan/parse-template.sh|g' \
    {} \;
  ```

- [x] Fix util subdirectory links (backup-command-file.sh, rollback-command-file.sh, validate-agent-invocation-pattern.sh, git-commit-utils.sh, etc.)
  ```bash
  find .claude/docs -name "*.md" -exec sed -i \
    -e 's|lib/backup-command-file\.sh|lib/util/backup-command-file.sh|g' \
    -e 's|lib/rollback-command-file\.sh|lib/util/rollback-command-file.sh|g' \
    -e 's|lib/validate-agent-invocation-pattern\.sh|lib/util/validate-agent-invocation-pattern.sh|g' \
    -e 's|lib/git-commit-utils\.sh|lib/util/git-commit-utils.sh|g' \
    -e 's|lib/progress-dashboard\.sh|lib/util/progress-dashboard.sh|g' \
    -e 's|lib/optimize-claude-md\.sh|lib/util/optimize-claude-md.sh|g' \
    -e 's|lib/generate-testing-protocols\.sh|lib/util/generate-testing-protocols.sh|g' \
    -e 's|lib/detect-testing\.sh|lib/util/detect-testing.sh|g' \
    -e 's|lib/dependency-analyzer\.sh|lib/util/dependency-analyzer.sh|g' \
    {} \;
  ```

- [x] Fix convert subdirectory links (convert-*.sh)
  ```bash
  find .claude/docs -name "*.md" -exec sed -i \
    -e 's|lib/convert-core\.sh|lib/convert/convert-core.sh|g' \
    -e 's|lib/convert-docx\.sh|lib/convert/convert-docx.sh|g' \
    -e 's|lib/convert-markdown\.sh|lib/convert/convert-markdown.sh|g' \
    -e 's|lib/convert-pdf\.sh|lib/convert/convert-pdf.sh|g' \
    {} \;
  ```

Testing:
```bash
# Verify no remaining old-style lib links (except for missing files)
grep -r "lib/[a-z-]*\.sh" .claude/docs --include="*.md" | grep -v "lib/core\|lib/workflow\|lib/artifact\|lib/plan\|lib/util\|lib/convert" | head -20
```

**Expected Duration**: 1 hour

### Phase 2: Resolve Missing File References [COMPLETE]
dependencies: [1]

**Objective**: Remove or document references to 8 missing files
**Complexity**: Medium

Tasks:
- [x] Identify all context-pruning.sh references (24+ occurrences)
  ```bash
  grep -rn "context-pruning\.sh" .claude/docs --include="*.md"
  ```

- [x] Remove context-pruning.sh references from documentation files
  - File: .claude/docs/concepts/hierarchical-agents.md
  - File: .claude/docs/workflows/orchestration-guide.md
  - File: .claude/docs/concepts/patterns/context-management.md
  - File: .claude/docs/troubleshooting/agent-delegation-troubleshooting.md
  - Action: Remove or replace with alternative context management approach

- [x] Remove parse-adaptive-plan.sh references (6 occurrences)
  ```bash
  grep -rn "parse-adaptive-plan\.sh" .claude/docs --include="*.md"
  ```
  - File: .claude/docs/workflows/adaptive-planning-guide.md
  - Action: Remove references to unimplemented adaptive plan parsing

- [x] Remove list-checkpoints.sh and cleanup-checkpoints.sh references
  ```bash
  grep -rn "list-checkpoints\.sh\|cleanup-checkpoints\.sh" .claude/docs --include="*.md"
  ```
  - File: .claude/docs/workflows/adaptive-planning-guide.md
  - Action: Remove references to unimplemented checkpoint management

- [x] Remove dependency-analysis.sh references
  ```bash
  grep -rn "dependency-analysis\.sh" .claude/docs --include="*.md"
  ```
  - File: .claude/docs/reference/workflows/phase-dependencies.md
  - Action: Remove or update to alternative approach

- [x] Remove conversion-logger.sh, utils.sh, and validate-context-reduction.sh references
  ```bash
  grep -rn "conversion-logger\.sh\|utils\.sh\|validate-context-reduction\.sh" .claude/docs --include="*.md"
  ```
  - Action: Remove references to these non-existent files

Testing:
```bash
# Verify all missing file references removed
for file in context-pruning parse-adaptive-plan list-checkpoints cleanup-checkpoints dependency-analysis conversion-logger utils validate-context-reduction; do
  count=$(grep -r "${file}\.sh" .claude/docs --include="*.md" | wc -l)
  echo "${file}.sh: ${count} references"
done
```

**Expected Duration**: 1 hour

### Phase 3: Fix Test File Path Depth [COMPLETE]
dependencies: [1]

**Objective**: Correct test file relative path depth in pattern documentation
**Complexity**: Low

Tasks:
- [x] Fix test paths in docs/concepts/patterns/ files
  ```bash
  find .claude/docs/concepts/patterns -name "*.md" -exec sed -i \
    's|\.\./\.\./tests/|\.\./\.\./\.\./tests/|g' {} \;
  ```

- [x] Fix test paths in docs/guides/orchestration/ files
  ```bash
  find .claude/docs/guides/orchestration -name "*.md" -exec sed -i \
    's|\.\./\.\./tests/|\.\./\.\./\.\./tests/|g' {} \;
  ```

- [x] Fix test paths in docs/guides/patterns/ files
  ```bash
  find .claude/docs/guides/patterns -name "*.md" -exec sed -i \
    's|\.\./\.\./tests/|\.\./\.\./\.\./tests/|g' {} \;
  ```

Testing:
```bash
# Verify corrected paths exist
grep -rn "\.\./\.\./\.\./tests/" .claude/docs --include="*.md" | while read line; do
  file=$(echo "$line" | cut -d: -f1)
  path=$(echo "$line" | grep -oP '\.\./\.\./\.\./tests/[^)"\s]+')
  dir=$(dirname "$file")
  if [ -n "$path" ]; then
    resolved=$(cd "$dir" && realpath "$path" 2>/dev/null || echo "BROKEN")
    [ "$resolved" = "BROKEN" ] && echo "BROKEN: $file -> $path"
  fi
done | head -20
```

**Expected Duration**: 30 minutes

### Phase 4: Validation and Documentation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Validate all fixes and update documentation
**Complexity**: Low

Tasks:
- [x] Run link validation script
  ```bash
  .claude/scripts/validate-links-quick.sh
  ```

- [x] Verify no remaining broken lib links
  ```bash
  # Check for any remaining old-style lib/ references
  grep -r "lib/[a-z-]*\.sh" .claude/docs --include="*.md" | grep -v "lib/core\|lib/workflow\|lib/artifact\|lib/plan\|lib/util\|lib/convert" || echo "No broken lib links found"
  ```

- [x] Spot-check key documentation files
  - Check: .claude/docs/concepts/hierarchical-agents.md (was 18 broken links)
  - Check: .claude/docs/troubleshooting/agent-delegation-troubleshooting.md (was 12+ broken links)
  - Check: .claude/docs/workflows/adaptive-planning-guide.md (was 11 broken links)
  - Check: .claude/docs/concepts/patterns/llm-classification-pattern.md (was 9 broken links)

- [x] Document lib directory structure in README
  - File: .claude/lib/README.md
  - Action: Add section documenting new subdirectory organization

Testing:
```bash
# Final comprehensive validation
echo "=== Final Validation ==="
echo "Broken lib links:"
grep -r "lib/[a-z-]*\.sh" .claude/docs --include="*.md" | grep -v "lib/core\|lib/workflow\|lib/artifact\|lib/plan\|lib/util\|lib/convert" | wc -l

echo "Missing file references:"
for file in context-pruning parse-adaptive-plan list-checkpoints cleanup-checkpoints dependency-analysis conversion-logger utils validate-context-reduction; do
  grep -r "${file}\.sh" .claude/docs --include="*.md" | wc -l
done | awk '{sum+=$1} END {print sum}'

echo "=== Validation Complete ==="
```

**Expected Duration**: 30 minutes

## Testing Strategy

### Phase-Level Testing
Each phase includes inline testing commands to validate fixes immediately after application.

### Integration Testing
- Run `validate-links-quick.sh` after all phases complete
- Spot-check files with highest broken link counts
- Verify documentation still renders correctly

### Regression Prevention
- No changes to lib/ directory itself (already reorganized)
- All changes are documentation-only
- Git diff review before commit

## Documentation Requirements

### Files to Update
- `.claude/lib/README.md` - Document new subdirectory structure

### No New Documentation
- This is a fix for existing documentation
- No new guides or references needed

## Dependencies

### Prerequisites
- None - all required lib files already exist in new locations

### External Dependencies
- None - all tools are standard Unix utilities (sed, grep, find)

### Risk Factors
- **Low Risk**: Documentation-only changes
- **Mitigation**: Git provides easy rollback if needed

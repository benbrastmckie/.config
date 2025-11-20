# Failing Tests Research Report - Library Refactoring

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Failing tests after .claude/lib/ refactoring
- **Report Type**: codebase analysis

## Executive Summary

The refactoring in commit `fb8680db` reorganized `.claude/lib/` from a flat structure into subdirectories (core/, workflow/, plan/, artifact/, convert/, util/), causing 29 of 81 test suites to fail. The primary root cause is that test files still reference libraries at their old flat paths (e.g., `$LIB_DIR/workflow-scope-detection.sh`) instead of new subdirectory paths (e.g., `$LIB_DIR/workflow/workflow-scope-detection.sh`). Secondary failures relate to documentation reorganization (guides moved to subdirectories) and stale test assertions checking for patterns that were modified or removed.

## Findings

### Test Failures Summary

**Total Test Suites**: 81
**Passing**: 52
**Failing**: 29
**Failure Rate**: 35.8%

### Category 1: Incorrect Library Source Paths (Critical - 15 tests)

The most common failure pattern is tests attempting to source libraries at old flat paths.

**Affected Tests**:

| Test File | Incorrect Path | Correct Path |
|-----------|----------------|--------------|
| test_workflow_scope_detection.sh:47 | `$LIB_DIR/workflow-scope-detection.sh` | `$LIB_DIR/workflow/workflow-scope-detection.sh` |
| test_scope_detection.sh:47 | `$LIB_DIR/workflow-scope-detection.sh` | `$LIB_DIR/workflow/workflow-scope-detection.sh` |
| test_scope_detection.sh:379 | `$LIB_DIR/workflow-detection.sh` | `$LIB_DIR/workflow/workflow-detection.sh` |
| test_llm_classifier.sh:47 | `$LIB_DIR/workflow-llm-classifier.sh` | `$LIB_DIR/workflow/workflow-llm-classifier.sh` |
| test_topic_filename_generation.sh:47 | `$LIB_DIR/workflow-llm-classifier.sh` | `$LIB_DIR/workflow/workflow-llm-classifier.sh` |
| test_topic_filename_generation.sh:48 | `$LIB_DIR/workflow-initialization.sh` | `$LIB_DIR/workflow/workflow-initialization.sh` |
| test_topic_slug_validation.sh:47 | `$LIB_DIR/topic-utils.sh` | `$LIB_DIR/plan/topic-utils.sh` |
| test_topic_slug_validation.sh:48 | `$LIB_DIR/workflow-initialization.sh` | `$LIB_DIR/workflow/workflow-initialization.sh` |
| test_offline_classification.sh:* | `$LIB_DIR/workflow-llm-classifier.sh` | `$LIB_DIR/workflow/workflow-llm-classifier.sh` |
| test_offline_classification.sh:* | `$LIB_DIR/workflow-scope-detection.sh` | `$LIB_DIR/workflow/workflow-scope-detection.sh` |
| test_progressive_collapse.sh:12 | `$LIB_DIR/plan-core-bundle.sh` | `$LIB_DIR/plan/plan-core-bundle.sh` |
| test_progressive_expansion.sh:12 | `$LIB_DIR/plan-core-bundle.sh` | `$LIB_DIR/plan/plan-core-bundle.sh` |
| test_parsing_utilities.sh:12 | `$LIB_DIR/plan-core-bundle.sh` | `$LIB_DIR/plan/plan-core-bundle.sh` |
| test_overview_synthesis.sh:11 | `$LIB_DIR/overview-synthesis.sh` | `$LIB_DIR/artifact/overview-synthesis.sh` |
| test_cross_block_function_availability.sh | `$LIB_DIR/workflow-state-machine.sh` | `$LIB_DIR/workflow/workflow-state-machine.sh` |

**Library Path Mapping**:

| Old Path | New Path (Subdirectory) |
|----------|------------------------|
| workflow-*.sh | workflow/ |
| plan-core-bundle.sh, topic-*.sh, checkbox-utils.sh, complexity-utils.sh, auto-analysis-utils.sh, parse-template.sh | plan/ |
| overview-synthesis.sh, artifact-*.sh, substitute-variables.sh, template-integration.sh | artifact/ |
| unified-*.sh, base-utils.sh, detect-project-dir.sh, error-handling.sh, library-*.sh, state-persistence.sh, timestamp-utils.sh | core/ |
| convert-*.sh | convert/ |
| git-commit-utils.sh, backup-command-file.sh, progress-dashboard.sh, detect-testing.sh, etc. | util/ |

### Category 2: Documentation Path Changes (Medium - 6 tests)

The validate_executable_doc_separation.sh test expects guide files at old locations.

**Error Pattern**:
```
FAIL: .claude/commands/build.md references missing guide .claude/docs/guides/build-command-guide.md
```

**Root Cause**: Guides were moved from `.claude/docs/guides/*.md` to `.claude/docs/guides/commands/*.md`

**Affected Commands**:
- build.md (line references: .claude/docs/guides/build-command-guide.md)
- debug.md
- plan.md
- research.md
- revise.md
- setup.md

**Actual New Locations**: `.claude/docs/guides/commands/{name}-command-guide.md`

### Category 3: Stale Test Assertions (Medium - 10 tests)

Tests checking for patterns that were modified during the refactoring.

**test_command_topic_allocation.sh** (10 failures):
- Checks for error handling pattern `-ne 0` after `allocate_and_create_topic`
- Checks for result parsing patterns
- Commands may have different error handling or parsing approaches now

**test_compliance_remediation_phase7.sh** (15 failures):
- Expects specific enforcement markers like `MANDATORY VERIFICATION`, `CHECKPOINT reporting`
- Expects diagnostic sections like `POSSIBLE CAUSES`, `TROUBLESHOOTING`
- Commands were likely simplified or restructured without these specific patterns

### Category 4: Test Environment Issues (Low - 5 tests)

**test_workflow_initialization.sh** (21 failures):
- Path construction issue: `/home/benjamin/.config/.claude/.claude/lib/workflow/workflow-initialization.sh`
- Double `.claude` in path suggests incorrect `CLAUDE_ROOT` calculation
- Test line 72: `source "${CLAUDE_ROOT}/.claude/lib/workflow/workflow-initialization.sh"`
- If `CLAUDE_ROOT` is already `.claude`, this creates duplicated path

**test_workflow_init.sh** (10 failures):
- Uses `$PROJECT_ROOT/lib/workflow/workflow-init.sh` (missing `.claude` segment)
- Correct path should be `$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh`

**test_template_system.sh**:
- Uses `$LIB_DIR/parse-template.sh`
- Should be `$LIB_DIR/plan/parse-template.sh`

### Category 5: Migration-Related Assertions (Low - 3 tests)

**test_command_topic_allocation.sh**:
- Fails on "Migration guide exists" - the atomic-allocation-migration.md was archived/removed

### Root Cause Analysis

The refactoring commit `fb8680db` made the following structural changes:

1. **Library Reorganization**: 40+ library files moved from flat `.claude/lib/` into subdirectories
2. **Guide Reorganization**: Command guides moved from `.claude/docs/guides/` to `.claude/docs/guides/commands/`
3. **Archive/Removal**: Several deprecated files removed including migration guides
4. **Internal Path Updates**: Some libraries updated to use new subdirectory paths

The commit message indicates "test path updates" were included, but the updates were incomplete - only some tests were updated while others still contain old paths.

### Severity Assessment

| Category | Severity | Count | Effort to Fix |
|----------|----------|-------|---------------|
| Incorrect Library Source Paths | Critical | 15 | Low (find & replace) |
| Documentation Path Changes | Medium | 6 | Low (update path or test logic) |
| Stale Test Assertions | Medium | 10 | Medium (review & update assertions) |
| Test Environment Issues | Low | 5 | Low (fix path construction) |
| Migration-Related | Low | 3 | Low (remove or update checks) |

## Recommendations

### Recommendation 1: Batch Update Library Paths in Tests

Create a systematic update for all test files with incorrect library source paths:

```bash
# Example fix pattern for workflow libraries
sed -i 's|\$LIB_DIR/workflow-|\$LIB_DIR/workflow/workflow-|g' .claude/tests/*.sh
sed -i 's|\$LIB_DIR/plan-core-bundle|\$LIB_DIR/plan/plan-core-bundle|g' .claude/tests/*.sh
sed -i 's|\$LIB_DIR/topic-utils|\$LIB_DIR/plan/topic-utils|g' .claude/tests/*.sh
sed -i 's|\$LIB_DIR/overview-synthesis|\$LIB_DIR/artifact/overview-synthesis|g' .claude/tests/*.sh
```

Priority: HIGH - This fixes 15 failing test suites with minimal risk.

### Recommendation 2: Fix Documentation Path Validation

Update validate_executable_doc_separation.sh to check the new guide location:

```bash
# Change from:
guide=".claude/docs/guides/${basename}-command-guide.md"

# To:
guide=".claude/docs/guides/commands/${basename}-command-guide.md"
```

Alternatively, update the command files to reference the new guide paths if they haven't been updated.

Priority: MEDIUM - This fixes 6 validation failures.

### Recommendation 3: Update or Remove Stale Compliance Assertions

For test_compliance_remediation_phase7.sh and test_command_topic_allocation.sh:
- Review if the expected patterns still apply after refactoring
- Update assertions to match current command implementations
- Consider removing checks for patterns that are no longer part of the design

Priority: MEDIUM - These tests may need individual review.

### Recommendation 4: Fix Path Construction in Test Setup

For test_workflow_initialization.sh:
- Line 72 uses `${CLAUDE_ROOT}/.claude/lib/...` but CLAUDE_ROOT is already set to include `.claude`
- Change to: `source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"`

For test_workflow_init.sh:
- Line 83 uses `$PROJECT_ROOT/lib/workflow/workflow-init.sh`
- Change to: `source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"`

Priority: LOW - These are test environment issues affecting fewer tests.

### Recommendation 5: Create Library Path Mapping Documentation

Add a migration reference in `.claude/lib/README.md` documenting:
- Old path -> New path mappings
- Rationale for subdirectory organization
- Instructions for updating dependent code

This will help prevent similar issues in the future and assist with any remaining migrations.

Priority: LOW - Documentation improvement for maintainability.

### Implementation Order

1. **Phase 1** (Quick Wins): Batch update library source paths using sed replacements
2. **Phase 2** (Validation): Fix documentation path validation test
3. **Phase 3** (Review): Update stale compliance/allocation test assertions
4. **Phase 4** (Cleanup): Fix path construction issues in test setup functions
5. **Phase 5** (Documentation): Add migration mapping documentation

### Estimated Effort

- Total estimated time: 2-3 hours
- Critical fixes (Phase 1-2): 30 minutes
- Review-required fixes (Phase 3): 1 hour
- Cleanup (Phase 4-5): 1 hour

## References

### Source Files Analyzed

- `/home/benjamin/.config/.claude/tests/run_all_tests.sh` - Test runner showing 29 failures
- `/home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh:47` - Example incorrect path
- `/home/benjamin/.config/.claude/tests/test_scope_detection.sh:47,379` - Multiple incorrect paths
- `/home/benjamin/.config/.claude/tests/test_llm_classifier.sh:47` - workflow-llm-classifier.sh path issue
- `/home/benjamin/.config/.claude/tests/test_topic_filename_generation.sh:47-48` - Two path issues
- `/home/benjamin/.config/.claude/tests/test_topic_slug_validation.sh:47-48` - topic-utils and workflow-initialization paths
- `/home/benjamin/.config/.claude/tests/test_progressive_collapse.sh:12` - plan-core-bundle.sh path
- `/home/benjamin/.config/.claude/tests/test_progressive_expansion.sh:12` - plan-core-bundle.sh path
- `/home/benjamin/.config/.claude/tests/test_parsing_utilities.sh:12` - plan-core-bundle.sh path
- `/home/benjamin/.config/.claude/tests/test_overview_synthesis.sh:11` - overview-synthesis.sh path
- `/home/benjamin/.config/.claude/tests/test_workflow_initialization.sh:72` - Double .claude path issue
- `/home/benjamin/.config/.claude/tests/test_workflow_init.sh:83-100` - Missing .claude in path
- `/home/benjamin/.config/.claude/tests/validate_executable_doc_separation.sh:33` - Guide path check
- `/home/benjamin/.config/.claude/tests/test_command_topic_allocation.sh:119-150` - Stale assertions
- `/home/benjamin/.config/.claude/tests/test_compliance_remediation_phase7.sh:1-150` - Compliance checks
- `/home/benjamin/.config/.claude/tests/test_template_system.sh:84` - parse-template.sh path

### Git Commit Analyzed

- `fb8680db` - "refactor: reorganize .claude/lib/ into subdirectories with test path updates"

### Library Directory Structure (Post-Refactoring)

```
.claude/lib/
  artifact/    - artifact-creation.sh, artifact-registry.sh, overview-synthesis.sh, etc.
  convert/     - convert-core.sh, convert-docx.sh, convert-markdown.sh, convert-pdf.sh
  core/        - base-utils.sh, unified-location-detection.sh, unified-logger.sh, etc.
  plan/        - plan-core-bundle.sh, topic-utils.sh, topic-decomposition.sh, etc.
  util/        - git-commit-utils.sh, progress-dashboard.sh, detect-testing.sh, etc.
  workflow/    - workflow-*.sh (all workflow-related libraries)
```

### Current Library Files

```
/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh
/home/benjamin/.config/.claude/lib/core/unified-logger.sh
/home/benjamin/.config/.claude/lib/core/library-sourcing.sh
/home/benjamin/.config/.claude/lib/core/base-utils.sh
/home/benjamin/.config/.claude/lib/core/detect-project-dir.sh
/home/benjamin/.config/.claude/lib/core/error-handling.sh
/home/benjamin/.config/.claude/lib/core/state-persistence.sh
/home/benjamin/.config/.claude/lib/core/timestamp-utils.sh
/home/benjamin/.config/.claude/lib/core/library-version-check.sh
/home/benjamin/.config/.claude/lib/workflow/workflow-scope-detection.sh
/home/benjamin/.config/.claude/lib/workflow/workflow-detection.sh
/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh
/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh
/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh
/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh
/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh
/home/benjamin/.config/.claude/lib/workflow/metadata-extraction.sh
/home/benjamin/.config/.claude/lib/workflow/argument-capture.sh
/home/benjamin/.config/.claude/lib/plan/plan-core-bundle.sh
/home/benjamin/.config/.claude/lib/plan/topic-utils.sh
/home/benjamin/.config/.claude/lib/plan/topic-decomposition.sh
/home/benjamin/.config/.claude/lib/plan/parse-template.sh
/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh
/home/benjamin/.config/.claude/lib/plan/complexity-utils.sh
/home/benjamin/.config/.claude/lib/plan/auto-analysis-utils.sh
/home/benjamin/.config/.claude/lib/artifact/overview-synthesis.sh
/home/benjamin/.config/.claude/lib/artifact/artifact-creation.sh
/home/benjamin/.config/.claude/lib/artifact/artifact-registry.sh
/home/benjamin/.config/.claude/lib/artifact/substitute-variables.sh
/home/benjamin/.config/.claude/lib/artifact/template-integration.sh
```

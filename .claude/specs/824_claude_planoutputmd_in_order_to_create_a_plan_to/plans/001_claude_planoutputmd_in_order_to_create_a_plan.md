# Library Path Fixes Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix broken library source references after .claude/lib refactoring
- **Scope**: Comprehensive fix of all incorrect library paths in code, tests, commands, and documentation
- **Estimated Phases**: 5
- **Estimated Hours**: 4.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 56.5
- **Research Reports**:
  - [Plan Command Errors Analysis](/home/benjamin/.config/.claude/specs/824_claude_planoutputmd_in_order_to_create_a_plan_to/reports/001_plan_command_errors_analysis.md)
  - [Comprehensive Library Path Audit](/home/benjamin/.config/.claude/specs/824_claude_planoutputmd_in_order_to_create_a_plan_to/reports/002_comprehensive_library_path_audit.md)

## Overview

The /plan command and other workflow commands are failing due to broken library source references after a refactoring of the .claude/lib/ directory from a flat structure to hierarchical subdirectories (core/, workflow/, plan/, util/, artifact/, convert/). The comprehensive audit identified **131+ issues** across:
- 10 critical code issues (HIGH priority - breaks functionality)
- 3 test/command issues (MEDIUM priority)
- 100+ documentation examples with flat paths (LOW priority)
- 2 archived/missing libraries still referenced

## Research Summary

Key findings from the research reports:

### From Report 001 (Initial Analysis):
- **Primary Issue**: workflow-llm-classifier.sh (line 19) sources detect-project-dir.sh with incorrect path
- **Secondary Issue**: workflow-init.sh _source_lib() function constructs paths without subdirectory prefixes
- **Pattern to Follow**: Files like workflow-state-machine.sh correctly use `$SCRIPT_DIR/../core/detect-project-dir.sh`

### From Report 002 (Comprehensive Audit):
- **Additional Critical Issue**: unified-location-detection.sh (lines 83-84) looks for topic-utils.sh in core/ instead of plan/
- **Test File Issue**: test_phase3_verification.sh references non-existent verification-helpers.sh
- **Command Issues**: expand.md references non-existent parse-adaptive-plan.sh; crud-feature.yaml uses flat path
- **Documentation**: 100+ files have examples with flat paths instead of hierarchical
- **Archived Libraries**: context-pruning.sh archived but still referenced in 10+ docs

Note: workflow-scope-detection.sh was initially suspected but already has correct path (line 22: `/../core/detect-project-dir.sh`)

## Success Criteria

- [ ] All workflow commands (/plan, /research, /build, /debug, /revise) execute without library sourcing errors
- [ ] No "No such file or directory" errors for detect-project-dir.sh
- [ ] No "Required library not found" errors from _source_lib function
- [ ] unified-location-detection.sh correctly sources topic-utils.sh from plan/ subdirectory
- [ ] Test file test_phase3_verification.sh either fixed or removed
- [ ] expand.md and crud-feature.yaml commands have correct library paths
- [ ] All documentation examples use hierarchical paths (lib/subdirectory/file.sh)
- [ ] No references to archived context-pruning.sh library
- [ ] Pattern consistency: all files use SCRIPT_DIR + relative path pattern

## Technical Design

### Architecture Overview

The fix follows the existing pattern established in correctly-updated files:

```bash
# Pattern: SCRIPT_DIR + relative path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/detect-project-dir.sh"
```

### Library Subdirectory Mapping

Libraries are organized in these subdirectories:
- **core/**: state-persistence.sh, error-handling.sh, library-version-check.sh, unified-location-detection.sh, detect-project-dir.sh, base-utils.sh, timestamp-utils.sh, unified-logger.sh, library-sourcing.sh
- **workflow/**: workflow-state-machine.sh, workflow-initialization.sh, workflow-init.sh, workflow-llm-classifier.sh, workflow-detection.sh, checkpoint-utils.sh, metadata-extraction.sh, argument-capture.sh
- **plan/**: topic-utils.sh, checkbox-utils.sh, plan-core-bundle.sh, complexity-utils.sh, auto-analysis-utils.sh, parse-template.sh, topic-decomposition.sh
- **artifact/**: artifact-creation.sh, artifact-registry.sh, template-integration.sh, substitute-variables.sh, overview-synthesis.sh
- **util/**: dependency-analyzer.sh, git-commit-utils.sh, progress-dashboard.sh, optimize-claude-md.sh, detect-testing.sh
- **convert/**: convert-core.sh, convert-docx.sh, convert-pdf.sh, convert-markdown.sh

### _source_lib Update Strategy

Update calls to include subdirectory prefixes (Option A from research - explicit paths are clearer):

```bash
# Before
_source_lib "state-persistence.sh" "required"

# After
_source_lib "core/state-persistence.sh" "required"
```

## Implementation Phases

### Phase 1: Fix Critical Code - Direct Source Paths [NOT STARTED]
dependencies: []

**Objective**: Fix incorrect relative paths in workflow library files that cause immediate failures

**Complexity**: Low

Tasks:
- [ ] Read workflow-llm-classifier.sh to confirm current path (file: /home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh)
- [ ] Update line 19 to use correct relative path: `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/detect-project-dir.sh"`
- [ ] Optionally refactor to use SCRIPT_DIR pattern for consistency with other files
- [ ] Read unified-location-detection.sh to confirm topic-utils.sh path (file: /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh)
- [ ] Update lines 83-84 to use correct path: `$SCRIPT_DIR_ULD/../plan/topic-utils.sh` instead of `$SCRIPT_DIR_ULD/topic-utils.sh`
- [ ] Verify both files source correctly by running basic source tests

Testing:
```bash
# Test workflow-llm-classifier.sh sources without error
bash -c 'source /home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh 2>&1'
echo "workflow-llm-classifier.sh exit code: $?"

# Test unified-location-detection.sh sources without error
bash -c 'source /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh 2>&1'
echo "unified-location-detection.sh exit code: $?"
```

**Expected Duration**: 0.5 hours

### Phase 2: Fix Critical Code - workflow-init.sh _source_lib Calls [NOT STARTED]
dependencies: [1]

**Objective**: Update all _source_lib calls to include subdirectory prefixes

**Complexity**: Low

Tasks:
- [ ] Read workflow-init.sh to identify all _source_lib calls (file: /home/benjamin/.config/.claude/lib/workflow/workflow-init.sh)
- [ ] Update line 167: `_source_lib "core/state-persistence.sh" "required"`
- [ ] Update line 168: `_source_lib "workflow/workflow-state-machine.sh" "required"`
- [ ] Update line 171: `_source_lib "core/library-version-check.sh" "optional"`
- [ ] Update line 172: `_source_lib "core/error-handling.sh" "optional"`
- [ ] Update line 173: `_source_lib "core/unified-location-detection.sh" "optional"`
- [ ] Update line 174: `_source_lib "workflow/workflow-initialization.sh" "optional"`
- [ ] Update line 300: `_source_lib "core/state-persistence.sh" "required"`
- [ ] Update line 301: `_source_lib "workflow/workflow-state-machine.sh" "required"`
- [ ] Verify all updated paths resolve to existing files

Testing:
```bash
# Verify each library path exists
for lib in core/state-persistence.sh workflow/workflow-state-machine.sh core/library-version-check.sh core/error-handling.sh core/unified-location-detection.sh workflow/workflow-initialization.sh; do
  test -f "/home/benjamin/.config/.claude/lib/$lib" && echo "OK: $lib" || echo "MISSING: $lib"
done

# Test workflow-init.sh can be sourced
bash -c '
  export CLAUDE_PROJECT_DIR=/home/benjamin/.config
  source /home/benjamin/.config/.claude/lib/workflow/workflow-init.sh
  echo "workflow-init.sh sourced successfully"
'
```

**Expected Duration**: 0.5 hours

### Phase 3: Fix Test Files and Commands [NOT STARTED]
dependencies: [1, 2]

**Objective**: Fix or remove test files and commands with incorrect library paths

**Complexity**: Medium

Tasks:
- [ ] Investigate test_phase3_verification.sh - determine if verification-helpers.sh was archived (file: /home/benjamin/.config/.claude/tests/.claude/tests/test_phase3_verification.sh)
- [ ] Either remove test_phase3_verification.sh if functionality was archived, OR create verification-helpers.sh stub
- [ ] Read expand.md to find parse-adaptive-plan.sh reference (file: /home/benjamin/.config/.claude/commands/expand.md)
- [ ] Remove or comment out parse-adaptive-plan.sh reference at line 862 if library was consolidated
- [ ] Read crud-feature.yaml template (file: /home/benjamin/.config/.claude/commands/templates/crud-feature.yaml)
- [ ] Update line 78 from `source .claude/lib/checkbox-utils.sh` to `source .claude/lib/plan/checkbox-utils.sh`
- [ ] Verify all fixed commands/tests work correctly

Testing:
```bash
# Check if test file exists and can be parsed
test -f "/home/benjamin/.config/.claude/tests/.claude/tests/test_phase3_verification.sh" && bash -n "/home/benjamin/.config/.claude/tests/.claude/tests/test_phase3_verification.sh"

# Verify checkbox-utils.sh exists at correct path
test -f "/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh" && echo "checkbox-utils.sh exists" || echo "MISSING"

# Syntax check expand.md bash blocks (verify no obvious errors)
grep -A5 'source.*adaptive-plan' /home/benjamin/.config/.claude/commands/expand.md || echo "Reference removed or not found"
```

**Expected Duration**: 1.0 hour

### Phase 4: Update Documentation Paths [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Bulk update all documentation files with flat paths to hierarchical paths

**Complexity**: Medium

Tasks:
- [ ] Create sed script to update common library paths (state-persistence.sh, workflow-state-machine.sh, etc.)
- [ ] Update state-persistence.sh references: `.claude/lib/state-persistence.sh` -> `.claude/lib/core/state-persistence.sh`
- [ ] Update workflow-state-machine.sh references: `.claude/lib/workflow-state-machine.sh` -> `.claude/lib/workflow/workflow-state-machine.sh`
- [ ] Update metadata-extraction.sh references: `.claude/lib/metadata-extraction.sh` -> `.claude/lib/workflow/metadata-extraction.sh`
- [ ] Update artifact-creation.sh references: `.claude/lib/artifact-creation.sh` -> `.claude/lib/artifact/artifact-creation.sh`
- [ ] Update error-handling.sh references: `.claude/lib/error-handling.sh` -> `.claude/lib/core/error-handling.sh`
- [ ] Update unified-location-detection.sh references: `.claude/lib/unified-location-detection.sh` -> `.claude/lib/core/unified-location-detection.sh`
- [ ] Update topic-utils.sh references: `.claude/lib/topic-utils.sh` -> `.claude/lib/plan/topic-utils.sh`
- [ ] Update checkbox-utils.sh references: `.claude/lib/checkbox-utils.sh` -> `.claude/lib/plan/checkbox-utils.sh`
- [ ] Update complexity-utils.sh references: `.claude/lib/complexity-utils.sh` -> `.claude/lib/plan/complexity-utils.sh`
- [ ] Update dependency-analyzer.sh references: `.claude/lib/dependency-analyzer.sh` -> `.claude/lib/util/dependency-analyzer.sh`
- [ ] Update checkpoint-utils.sh references: `.claude/lib/checkpoint-utils.sh` -> `.claude/lib/workflow/checkpoint-utils.sh`
- [ ] Update workflow-detection.sh references: `.claude/lib/workflow-detection.sh` -> `.claude/lib/workflow/workflow-detection.sh`
- [ ] Update library-version-check.sh references: `.claude/lib/library-version-check.sh` -> `.claude/lib/core/library-version-check.sh`
- [ ] Remove all references to archived context-pruning.sh or mark as deprecated

Testing:
```bash
# Verify no flat paths remain for critical libraries
grep -r "lib/state-persistence\.sh" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v "lib/core/state-persistence" && echo "FLAT PATHS REMAIN" || echo "All paths updated"

# Check for context-pruning.sh references
grep -r "context-pruning" /home/benjamin/.config/.claude/docs/ --include="*.md" | wc -l
```

**Expected Duration**: 1.5 hours

### Phase 5: Integration Testing and Validation [NOT STARTED]
dependencies: [1, 2, 3, 4]

**Objective**: Validate that all workflow commands work correctly after fixes

**Complexity**: Low

Tasks:
- [ ] Test /plan command with a simple workflow description
- [ ] Test /research command with a simple topic
- [ ] Test /build command basic invocation
- [ ] Create validation script to check all source statements in .claude/lib/*.sh files
- [ ] Run validation script to confirm no broken references remain
- [ ] Test source chain: workflow-init.sh -> workflow-state-machine.sh -> detect-project-dir.sh
- [ ] Verify error messages are clear when libraries are missing (not misleading paths)
- [ ] Run existing test suite to check for regressions

Testing:
```bash
# Comprehensive source validation
find /home/benjamin/.config/.claude/lib -name "*.sh" -exec grep -l "source.*\.sh" {} \; | while read file; do
  echo "Checking: $file"
  bash -n "$file" 2>&1 || echo "  SYNTAX ERROR"
done

# Count any remaining flat-path issues in all shell scripts
echo "Checking for remaining flat paths in lib/*.sh..."
grep -rn "lib/[a-z-]*\.sh" /home/benjamin/.config/.claude/lib/ --include="*.sh" | grep -v "lib/[a-z]*/[a-z-]*\.sh" | wc -l

# Test a complete workflow command
echo "Testing /plan command readiness..."
bash -c '
  export CLAUDE_PROJECT_DIR=/home/benjamin/.config
  source /home/benjamin/.config/.claude/lib/workflow/workflow-init.sh
  echo "Full workflow chain sources successfully"
'
```

**Expected Duration**: 1.0 hour

## Testing Strategy

### Unit Testing
- Each modified file tested in isolation with bash source command
- Verify exit code 0 and no error output to stderr

### Integration Testing
- Test full command invocation: `/plan "test feature"`
- Verify state machine initializes correctly
- Confirm library sourcing output is suppressed (no verbose messages)

### Validation Script
Create/update validation script to check all source statements:
```bash
#!/usr/bin/env bash
# validate-library-sources.sh
# Validates all source statements in .claude/lib/ resolve to existing files

errors=0
find /home/benjamin/.config/.claude/lib -name "*.sh" -print0 | while IFS= read -r -d '' file; do
  # Extract source statements and verify targets exist
  grep -n 'source.*\.sh' "$file" | while read line; do
    # Parse and validate each source path
    # Increment errors if file not found
    :
  done
done
exit $errors
```

### Documentation Verification
- Grep for any remaining flat paths in documentation
- Ensure all examples use hierarchical structure

## Documentation Requirements

- No new documentation needed - this is a bug fix
- Update .claude/lib/README.md if it contains outdated flat structure references
- Consider adding a "Library Directory Structure" section to document subdirectory organization
- Remove or update references to archived context-pruning.sh library

## Dependencies

### Prerequisites
- Access to all files in /home/benjamin/.config/.claude/lib/
- Access to all files in /home/benjamin/.config/.claude/docs/
- Access to all files in /home/benjamin/.config/.claude/commands/
- Access to all files in /home/benjamin/.config/.claude/tests/
- Bash shell for testing

### External Dependencies
- None - all changes are internal to .claude/

### Risk Factors
- Low to Medium risk: mostly path string changes
- Documentation updates are bulk operations - verify sed patterns before applying
- Mitigation: each phase tested before moving to next phase
- Git provides rollback capability if issues arise

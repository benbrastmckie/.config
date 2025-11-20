# Test Path Update Requirements

## Summary

The library refactor moved 42 libraries from `.claude/lib/*.sh` to organized subdirectories. The test suite needs corresponding updates to reference the new paths.

## Root Cause

Tests source libraries using relative paths like:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
```

After refactor, libraries are at:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
```

## Library Location Mapping

### Core Libraries (lib/core/)
- state-persistence.sh
- unified-logger.sh
- timestamp-utils.sh
- library-version-check.sh
- error-handling.sh
- library-sourcing.sh
- detect-project-dir.sh
- argument-capture.sh

### Workflow Libraries (lib/workflow/)
- workflow-state-machine.sh
- workflow-initialization.sh
- workflow-scope-detection.sh
- workflow-llm-classifier.sh
- workflow-detection.sh
- hierarchical-supervisor.sh
- wave-executor.sh
- parallel-subagent-executor.sh
- adaptive-planning.sh

### Plan Libraries (lib/plan/)
- checkbox-utils.sh
- plan-expansion-core.sh
- plan-collapse-core.sh
- plan-core-bundle.sh
- plan-dependency-parser.sh
- plan-structure-manager.sh
- progressive-disclosure.sh

### Artifact Libraries (lib/artifact/)
- checkpoint-utils.sh
- artifact-creation.sh
- topic-utils.sh
- topic-decomposition.sh
- unified-location-detection.sh

### Convert Libraries (lib/convert/)
- convert-core.sh
- convert-docx.sh
- convert-pdf.sh
- convert-parallel.sh

### Utility Libraries (lib/util/)
- verification-helpers.sh
- git-commit-utils.sh
- template-integration.sh
- parse-template.sh
- overview-synthesis.sh
- progress-dashboard.sh
- research-topic-generator.sh
- tts-utils.sh
- unified-slug-generator.sh

## Required Updates

1. **Test files**: Update all source statements to use new subdirectory paths
2. **Internal dependencies**: Some libraries source other libraries - these were updated in the refactor but may need verification
3. **Path patterns**: Tests using `../lib/` patterns need to use `../lib/subdirectory/`

## Recommended Approach

1. Create a sed script to update all test files systematically
2. Test each library category independently
3. Verify internal library dependencies work correctly

## Files Requiring Updates

Run this to find all affected test files:
```bash
grep -l 'source.*\.claude/lib/[^/]*\.sh' .claude/tests/*.sh
```

## Estimated Effort

- 50+ test files need path updates
- Each update is mechanical (find/replace)
- Estimated time: 30-60 minutes for systematic update

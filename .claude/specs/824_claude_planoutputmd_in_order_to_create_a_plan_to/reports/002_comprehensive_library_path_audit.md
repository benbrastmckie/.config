# Comprehensive Library Path Audit Report

## Executive Summary

This report identifies **ALL instances** of incorrect library paths across the codebase following the refactoring of `.claude/lib/` from a flat structure to a hierarchical structure with subdirectories (core/, workflow/, plan/, util/, artifact/, convert/).

**Total Issues Found**: 131 issues across multiple categories

### Issue Categories
1. **Critical Code Issues** (breaks functionality): 3 files, 11 issues
2. **Documentation with Incorrect Examples** (misleading but non-breaking): 40+ files, 100+ issues
3. **Missing/Archived Libraries Referenced**: 2 libraries

---

## Category 1: Critical Code Issues (High Priority)

These files contain actual executable code with incorrect library paths that will cause runtime failures.

### 1.1 workflow-llm-classifier.sh - INCORRECT detect-project-dir.sh PATH

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh`  
**Line**: 19  
**Current (Wrong)**:
```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect-project-dir.sh"
```
**Correct Path**:
```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/detect-project-dir.sh"
```
**Impact**: HIGH - Causes immediate failure when workflow-llm-classifier.sh is sourced

---

### 1.2 workflow-init.sh - Missing Subdirectory Prefixes in _source_lib Calls

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh`  

| Line | Current (Wrong) | Correct Path |
|------|-----------------|--------------|
| 167 | `_source_lib "state-persistence.sh" "required"` | `_source_lib "core/state-persistence.sh" "required"` |
| 168 | `_source_lib "workflow-state-machine.sh" "required"` | `_source_lib "workflow/workflow-state-machine.sh" "required"` |
| 171 | `_source_lib "library-version-check.sh" "optional"` | `_source_lib "core/library-version-check.sh" "optional"` |
| 172 | `_source_lib "error-handling.sh" "optional"` | `_source_lib "core/error-handling.sh" "optional"` |
| 173 | `_source_lib "unified-location-detection.sh" "optional"` | `_source_lib "core/unified-location-detection.sh" "optional"` |
| 174 | `_source_lib "workflow-initialization.sh" "optional"` | `_source_lib "workflow/workflow-initialization.sh" "optional"` |
| 300 | `_source_lib "state-persistence.sh" "required"` | `_source_lib "core/state-persistence.sh" "required"` |
| 301 | `_source_lib "workflow-state-machine.sh" "required"` | `_source_lib "workflow/workflow-state-machine.sh" "required"` |

**Impact**: HIGH - Causes "Required library not found" errors for all workflow commands

---

### 1.3 unified-location-detection.sh - INCORRECT topic-utils.sh PATH

**File**: `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh`  
**Lines**: 83-84  
**Current (Wrong)**:
```bash
SCRIPT_DIR_ULD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR_ULD/topic-utils.sh" ]; then
  source "$SCRIPT_DIR_ULD/topic-utils.sh"
fi
```
**Correct Path**:
```bash
SCRIPT_DIR_ULD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR_ULD/../plan/topic-utils.sh" ]; then
  source "$SCRIPT_DIR_ULD/../plan/topic-utils.sh"
fi
```
**Impact**: MEDIUM - extract_significant_words function unavailable, causes fallback behavior

---

## Category 2: Test Files with Incorrect Paths

### 2.1 test_phase3_verification.sh - References Non-Existent Library

**File**: `/home/benjamin/.config/.claude/tests/.claude/tests/test_phase3_verification.sh`  
**Line**: 7  
**Current (Wrong)**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
```
**Issue**: `verification-helpers.sh` does not exist (was archived/removed)

**Resolution Options**:
- Delete test if functionality was archived
- Or create `verification-helpers.sh` in appropriate subdirectory

---

## Category 3: Commands with Incorrect Paths

### 3.1 expand.md - References Non-Existent Library

**File**: `/home/benjamin/.config/.claude/commands/expand.md`  
**Line**: 862  
**Current (Wrong)**:
```bash
source .claude/lib/parse-adaptive-plan.sh
```
**Issue**: `parse-adaptive-plan.sh` does not exist in any location

**Resolution Options**:
- Remove reference if functionality was consolidated
- Or create library in plan/ subdirectory

---

### 3.2 templates/crud-feature.yaml - Uses Flat Path

**File**: `/home/benjamin/.config/.claude/commands/templates/crud-feature.yaml`  
**Line**: 78  
**Current (Wrong)**:
```bash
source .claude/lib/checkbox-utils.sh
```
**Correct Path**:
```bash
source .claude/lib/plan/checkbox-utils.sh
```

---

## Category 4: Documentation with Incorrect Library Paths

These are documentation examples that need updating to reflect the new hierarchical structure. While non-breaking, they provide misleading guidance.

### 4.1 Libraries with Flat Paths That Should Be Hierarchical

#### state-persistence.sh references (should be core/)
- `.claude/docs/reference/library-api/persistence.md` - Lines 113, 141, 266, 273, 282
- `.claude/docs/concepts/bash-block-execution-model.md` - Lines 106, 415, 988, 1007
- `.claude/docs/reference/standards/command-authoring.md` - Lines 194, 237, 241
- `.claude/docs/guides/orchestration/creating-orchestrator-commands.md` - Line 106
- `.claude/docs/guides/orchestration/state-machine-orchestrator-development.md` - Lines 71, 106, 129, 148
- `.claude/docs/architecture/state-based-orchestration-overview.md` - Lines 506, 513, 701, 1260

**Correct path**: `.claude/lib/core/state-persistence.sh`

#### workflow-state-machine.sh references (should be workflow/)
- `.claude/docs/reference/standards/command-authoring.md` - Lines 45, 57, 193
- `.claude/docs/guides/orchestration/creating-orchestrator-commands.md` - Line 107
- `.claude/docs/guides/orchestration/state-machine-orchestrator-development.md` - Line 71
- `.claude/docs/architecture/state-based-orchestration-overview.md` - Lines 1259, 1331
- `.claude/docs/concepts/bash-block-execution-model.md` - Lines 536, 542

**Correct path**: `.claude/lib/workflow/workflow-state-machine.sh`

#### metadata-extraction.sh references (should be workflow/)
- `.claude/docs/workflows/orchestration-guide-examples.md` - Line 258
- `.claude/docs/workflows/orchestration-guide.md` - Line 1188
- `.claude/docs/workflows/context-budget-management.md` - Line 568
- `.claude/docs/architecture/hierarchical-supervisor-coordination.md` - Line 533
- `.claude/docs/troubleshooting/agent-delegation-troubleshooting.md` - Line 610
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Lines 361, 1290
- `.claude/docs/concepts/directory-protocols.md` - Line 648
- `.claude/docs/concepts/directory-protocols-examples.md` - Line 20

**Correct path**: `.claude/lib/workflow/metadata-extraction.sh`

#### artifact-creation.sh references (should be artifact/)
- `.claude/docs/workflows/orchestration-guide-examples.md` - Line 159
- `.claude/docs/workflows/orchestration-guide.md` - Line 1089
- `.claude/docs/troubleshooting/agent-delegation-troubleshooting.md` - Lines 228, 868
- `.claude/docs/concepts/hierarchical-agents.md` - Line 1594
- `.claude/docs/reference/architecture/validation.md` - Line 50
- `.claude/docs/reference/decision-trees/template-usage-decision-tree.md` - Line 111

**Correct path**: `.claude/lib/artifact/artifact-creation.sh`

#### error-handling.sh references (should be core/)
- `.claude/docs/reference/standards/command-authoring.md` - Line 195
- `.claude/docs/guides/orchestration/creating-orchestrator-commands.md` - Line 109
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Line 1303

**Correct path**: `.claude/lib/core/error-handling.sh`

#### unified-location-detection.sh references (should be core/)
- `.claude/docs/concepts/directory-protocols.md` - Line 93
- `.claude/docs/concepts/directory-protocols-overview.md` - Line 89
- `.claude/docs/reference/library-api/overview.md` - Line 101
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Lines 207, 1187, 1287
- `.claude/docs/guides/orchestration/orchestration-troubleshooting.md` - Lines 438, 543, 764

**Correct path**: `.claude/lib/core/unified-location-detection.sh`

#### topic-utils.sh references (should be plan/)
- `.claude/docs/concepts/directory-protocols.md` - Line 94
- `.claude/docs/concepts/directory-protocols-overview.md` - Line 90
- `.claude/docs/reference/standards/command-authoring.md` - Line 83

**Correct path**: `.claude/lib/plan/topic-utils.sh`

#### unified-logger.sh references (should be core/)
- `.claude/docs/reference/standards/command-authoring.md` - Line 196

**Correct path**: `.claude/lib/core/unified-logger.sh`

#### library-version-check.sh references (should be core/)
- `.claude/docs/guides/orchestration/creating-orchestrator-commands.md` - Line 108

**Correct path**: `.claude/lib/core/library-version-check.sh`

#### complexity-utils.sh references (should be plan/)
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Lines 467, 1293

**Correct path**: `.claude/lib/plan/complexity-utils.sh`

#### dependency-analyzer.sh references (should be util/)
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Lines 536, 1296

**Correct path**: `.claude/lib/util/dependency-analyzer.sh`

#### checkpoint-utils.sh references (should be workflow/)
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Line 1306
- `.claude/docs/guides/orchestration/orchestration-troubleshooting.md` - Line 701

**Correct path**: `.claude/lib/workflow/checkpoint-utils.sh`

#### workflow-detection.sh references (should be workflow/)
- `.claude/docs/guides/orchestration/orchestration-best-practices.md` - Lines 651, 1300

**Correct path**: `.claude/lib/workflow/workflow-detection.sh`

#### checkbox-utils.sh references (should be plan/)
- `.claude/docs/reference/standards/plan-progress.md` - Lines 188, 206, 219

**Correct path**: `.claude/lib/plan/checkbox-utils.sh`

#### workflow-initialization.sh references (should be workflow/)
- `.claude/docs/guides/orchestration/state-machine-migration-guide.md` - Line 220

**Correct path**: `.claude/lib/workflow/workflow-initialization.sh`

---

## Category 5: Archived/Missing Libraries Still Referenced

### 5.1 context-pruning.sh - Archived but Still Referenced

**Status**: Library was archived/deleted but numerous documentation files still reference it

**Files Still Referencing**:
- `.claude/docs/workflows/context-budget-management.md`
- `.claude/docs/workflows/hierarchical-agent-workflow.md`
- `.claude/docs/troubleshooting/agent-delegation-troubleshooting.md`
- `.claude/docs/guides/orchestration/orchestration-best-practices.md`
- `.claude/docs/concepts/hierarchical-agents.md`
- `.claude/docs/concepts/patterns/context-management.md`
- `.claude/docs/reference/library-api/overview.md`
- `.claude/docs/reference/library-api/utilities.md`
- `.claude/docs/reference/standards/agent-reference.md`

**Resolution**: Either remove all references or re-implement functionality

### 5.2 verification-helpers.sh - Missing

**Status**: Referenced in test file but does not exist

**File Referencing**: `.claude/tests/.claude/tests/test_phase3_verification.sh`

---

## Summary Statistics

| Category | Count | Priority |
|----------|-------|----------|
| Critical code issues (workflow-llm-classifier.sh) | 1 | HIGH |
| Critical code issues (workflow-init.sh) | 8 | HIGH |
| Critical code issues (unified-location-detection.sh) | 1 | MEDIUM |
| Test files with missing libraries | 1 | MEDIUM |
| Commands with incorrect paths | 2 | MEDIUM |
| Documentation files with flat paths | 100+ | LOW |
| Archived libraries still referenced | 2 | LOW |

**Total Critical Issues**: 10  
**Total All Issues**: 131+

---

## Recommended Fix Order

### Phase 1: Fix Critical Code (Immediate)
1. Fix `workflow-llm-classifier.sh` line 19 path
2. Update all 8 `_source_lib` calls in `workflow-init.sh`
3. Fix `unified-location-detection.sh` topic-utils.sh path

### Phase 2: Fix Tests and Commands (Short-term)
1. Remove or fix `test_phase3_verification.sh`
2. Fix `expand.md` parse-adaptive-plan.sh reference
3. Fix `templates/crud-feature.yaml` checkbox-utils.sh path

### Phase 3: Update Documentation (Medium-term)
1. Create a sed script to bulk-update documentation paths
2. Consider removing all context-pruning.sh references

---

## Library Path Mapping Reference

| Old Flat Path | New Hierarchical Path |
|---------------|----------------------|
| `lib/state-persistence.sh` | `lib/core/state-persistence.sh` |
| `lib/workflow-state-machine.sh` | `lib/workflow/workflow-state-machine.sh` |
| `lib/detect-project-dir.sh` | `lib/core/detect-project-dir.sh` |
| `lib/error-handling.sh` | `lib/core/error-handling.sh` |
| `lib/library-version-check.sh` | `lib/core/library-version-check.sh` |
| `lib/unified-location-detection.sh` | `lib/core/unified-location-detection.sh` |
| `lib/unified-logger.sh` | `lib/core/unified-logger.sh` |
| `lib/base-utils.sh` | `lib/core/base-utils.sh` |
| `lib/timestamp-utils.sh` | `lib/core/timestamp-utils.sh` |
| `lib/library-sourcing.sh` | `lib/core/library-sourcing.sh` |
| `lib/workflow-initialization.sh` | `lib/workflow/workflow-initialization.sh` |
| `lib/workflow-init.sh` | `lib/workflow/workflow-init.sh` |
| `lib/workflow-llm-classifier.sh` | `lib/workflow/workflow-llm-classifier.sh` |
| `lib/workflow-scope-detection.sh` | `lib/workflow/workflow-scope-detection.sh` |
| `lib/workflow-detection.sh` | `lib/workflow/workflow-detection.sh` |
| `lib/checkpoint-utils.sh` | `lib/workflow/checkpoint-utils.sh` |
| `lib/metadata-extraction.sh` | `lib/workflow/metadata-extraction.sh` |
| `lib/argument-capture.sh` | `lib/workflow/argument-capture.sh` |
| `lib/topic-utils.sh` | `lib/plan/topic-utils.sh` |
| `lib/checkbox-utils.sh` | `lib/plan/checkbox-utils.sh` |
| `lib/plan-core-bundle.sh` | `lib/plan/plan-core-bundle.sh` |
| `lib/complexity-utils.sh` | `lib/plan/complexity-utils.sh` |
| `lib/auto-analysis-utils.sh` | `lib/plan/auto-analysis-utils.sh` |
| `lib/parse-template.sh` | `lib/plan/parse-template.sh` |
| `lib/topic-decomposition.sh` | `lib/plan/topic-decomposition.sh` |
| `lib/artifact-creation.sh` | `lib/artifact/artifact-creation.sh` |
| `lib/artifact-registry.sh` | `lib/artifact/artifact-registry.sh` |
| `lib/template-integration.sh` | `lib/artifact/template-integration.sh` |
| `lib/substitute-variables.sh` | `lib/artifact/substitute-variables.sh` |
| `lib/overview-synthesis.sh` | `lib/artifact/overview-synthesis.sh` |
| `lib/dependency-analyzer.sh` | `lib/util/dependency-analyzer.sh` |
| `lib/git-commit-utils.sh` | `lib/util/git-commit-utils.sh` |
| `lib/progress-dashboard.sh` | `lib/util/progress-dashboard.sh` |
| `lib/optimize-claude-md.sh` | `lib/util/optimize-claude-md.sh` |
| `lib/detect-testing.sh` | `lib/util/detect-testing.sh` |
| `lib/backup-command-file.sh` | `lib/util/backup-command-file.sh` |
| `lib/rollback-command-file.sh` | `lib/util/rollback-command-file.sh` |
| `lib/validate-agent-invocation-pattern.sh` | `lib/util/validate-agent-invocation-pattern.sh` |
| `lib/generate-testing-protocols.sh` | `lib/util/generate-testing-protocols.sh` |
| `lib/convert-core.sh` | `lib/convert/convert-core.sh` |
| `lib/convert-docx.sh` | `lib/convert/convert-docx.sh` |
| `lib/convert-pdf.sh` | `lib/convert/convert-pdf.sh` |
| `lib/convert-markdown.sh` | `lib/convert/convert-markdown.sh` |

---

## Files Examined
- All `.sh` files in `/home/benjamin/.config/.claude/lib/`
- All `.md` files in `/home/benjamin/.config/.claude/commands/`
- All `.md` files in `/home/benjamin/.config/.claude/agents/`
- All `.sh` files in `/home/benjamin/.config/.claude/tests/`
- All `.md` documentation files in `/home/benjamin/.config/.claude/docs/`
- Spec files in `/home/benjamin/.config/.claude/specs/`

**Report Generated**: 2025-11-19

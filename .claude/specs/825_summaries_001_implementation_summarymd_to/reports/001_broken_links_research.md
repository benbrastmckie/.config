# Broken Links Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Dead Links in .claude/docs/ Documentation
- **Report Type**: codebase analysis

## Executive Summary

Research discovered extensive broken links across .claude/docs/ resulting from a lib/ directory reorganization that moved all shell scripts into subdirectories (core/, workflow/, artifact/, plan/, util/, convert/). Found 15+ documentation files with 80+ broken lib links, plus 8 completely missing files referenced in documentation. Additionally found incorrect test file path depth in several documents.

## Findings

### Category 1: Lib Directory Reorganization Broken Links

The lib/ directory was reorganized from a flat structure into subdirectories. All existing references using `lib/filename.sh` are now broken.

#### New Lib Directory Structure

```
.claude/lib/
├── core/           # Core utilities
│   ├── base-utils.sh
│   ├── detect-project-dir.sh
│   ├── error-handling.sh
│   ├── library-sourcing.sh
│   ├── library-version-check.sh
│   ├── state-persistence.sh
│   ├── timestamp-utils.sh
│   ├── unified-location-detection.sh
│   └── unified-logger.sh
├── workflow/       # Workflow utilities
│   ├── argument-capture.sh
│   ├── checkpoint-utils.sh
│   ├── metadata-extraction.sh
│   ├── workflow-detection.sh
│   ├── workflow-initialization.sh
│   ├── workflow-init.sh
│   ├── workflow-llm-classifier.sh
│   ├── workflow-scope-detection.sh
│   └── workflow-state-machine.sh
├── artifact/       # Artifact management
│   ├── artifact-creation.sh
│   ├── artifact-registry.sh
│   ├── overview-synthesis.sh
│   ├── substitute-variables.sh
│   └── template-integration.sh
├── plan/           # Plan utilities
│   ├── auto-analysis-utils.sh
│   ├── checkbox-utils.sh
│   ├── complexity-utils.sh
│   ├── parse-template.sh
│   ├── plan-core-bundle.sh
│   ├── topic-decomposition.sh
│   └── topic-utils.sh
├── util/           # General utilities
│   ├── backup-command-file.sh
│   ├── dependency-analyzer.sh
│   ├── detect-testing.sh
│   ├── generate-testing-protocols.sh
│   ├── git-commit-utils.sh
│   ├── optimize-claude-md.sh
│   ├── progress-dashboard.sh
│   ├── rollback-command-file.sh
│   └── validate-agent-invocation-pattern.sh
└── convert/        # Conversion utilities
    ├── convert-core.sh
    ├── convert-docx.sh
    ├── convert-markdown.sh
    └── convert-pdf.sh
```

#### Files with Broken Lib Links (15 files identified)

1. **llm-classification-pattern.md** (lines 73, 109, 232, 476-478)
   - `.claude/docs/concepts/patterns/llm-classification-pattern.md`
   - 6 broken links to workflow files

2. **workflow-classification-guide.md** (lines 630-632)
   - `.claude/docs/guides/orchestration/workflow-classification-guide.md`
   - 3 broken links

3. **enhanced-topic-generation-guide.md** (lines 674-676)
   - `.claude/docs/guides/patterns/enhanced-topic-generation-guide.md`
   - 3 broken links

4. **agent-delegation-troubleshooting.md** (lines 72, 228, 376, 469-470, 476-477, 593, 610, 618, 634, 657, 868, 956)
   - `.claude/docs/troubleshooting/agent-delegation-troubleshooting.md`
   - 12+ broken links

5. **conversion-guide.md** (lines 611, 632-634, 869)
   - `.claude/docs/workflows/conversion-guide.md`
   - 5 broken links

6. **orchestration-guide.md** (lines 69, 77, 86, 94, 410, 1089, 1188)
   - `.claude/docs/workflows/orchestration-guide.md`
   - 7 broken links

7. **hierarchical-agents.md** (lines 155, 161, 178, 197, 218, 243, 282, 301, 391, 414, 448, 485, 726, 741, 762-763, 1162, 1345)
   - `.claude/docs/concepts/hierarchical-agents.md`
   - 18 broken links

8. **orchestration-reference.md** (lines 99, 165, 199, 215, 915, 953, 993)
   - `.claude/docs/reference/workflows/orchestration-reference.md`
   - 7 broken links

9. **bash-block-execution-model.md** (line 933)
   - `.claude/docs/concepts/bash-block-execution-model.md`
   - 1 broken link

10. **implementation-guide.md** (lines 439, 469)
    - `.claude/docs/guides/patterns/implementation-guide.md`
    - 2 broken links

11. **build-command-guide.md** (line 629)
    - `.claude/docs/guides/commands/build-command-guide.md`
    - 1 broken link

12. **utilities.md** (lines 145, 344, 402, 405)
    - `.claude/docs/reference/library-api/utilities.md`
    - 4 broken links

13. **adaptive-planning-guide.md** (lines 260-261, 273, 352-356, 404, 410, 417, 423)
    - `.claude/docs/workflows/adaptive-planning-guide.md`
    - 11 broken links

14. **state-machine-orchestrator-development.md** (line 972)
    - `.claude/docs/guides/orchestration/state-machine-orchestrator-development.md`
    - 1 broken link

15. **command-development-standards-integration.md** (lines 284, 299, 330-331)
    - `.claude/docs/guides/development/command-development/command-development-standards-integration.md`
    - 4 broken links

#### Path Mapping (Old to New)

| Old Path | New Path |
|----------|----------|
| `lib/workflow-llm-classifier.sh` | `lib/workflow/workflow-llm-classifier.sh` |
| `lib/workflow-scope-detection.sh` | `lib/workflow/workflow-scope-detection.sh` |
| `lib/workflow-detection.sh` | `lib/workflow/workflow-detection.sh` |
| `lib/workflow-initialization.sh` | `lib/workflow/workflow-initialization.sh` |
| `lib/workflow-init.sh` | `lib/workflow/workflow-init.sh` |
| `lib/workflow-state-machine.sh` | `lib/workflow/workflow-state-machine.sh` |
| `lib/checkpoint-utils.sh` | `lib/workflow/checkpoint-utils.sh` |
| `lib/metadata-extraction.sh` | `lib/workflow/metadata-extraction.sh` |
| `lib/argument-capture.sh` | `lib/workflow/argument-capture.sh` |
| `lib/unified-location-detection.sh` | `lib/core/unified-location-detection.sh` |
| `lib/unified-logger.sh` | `lib/core/unified-logger.sh` |
| `lib/detect-project-dir.sh` | `lib/core/detect-project-dir.sh` |
| `lib/error-handling.sh` | `lib/core/error-handling.sh` |
| `lib/state-persistence.sh` | `lib/core/state-persistence.sh` |
| `lib/library-sourcing.sh` | `lib/core/library-sourcing.sh` |
| `lib/artifact-creation.sh` | `lib/artifact/artifact-creation.sh` |
| `lib/artifact-registry.sh` | `lib/artifact/artifact-registry.sh` |
| `lib/template-integration.sh` | `lib/artifact/template-integration.sh` |
| `lib/topic-decomposition.sh` | `lib/plan/topic-decomposition.sh` |
| `lib/topic-utils.sh` | `lib/plan/topic-utils.sh` |
| `lib/complexity-utils.sh` | `lib/plan/complexity-utils.sh` |
| `lib/plan-core-bundle.sh` | `lib/plan/plan-core-bundle.sh` |
| `lib/auto-analysis-utils.sh` | `lib/plan/auto-analysis-utils.sh` |
| `lib/convert-core.sh` | `lib/convert/convert-core.sh` |
| `lib/backup-command-file.sh` | `lib/util/backup-command-file.sh` |
| `lib/rollback-command-file.sh` | `lib/util/rollback-command-file.sh` |
| `lib/validate-agent-invocation-pattern.sh` | `lib/util/validate-agent-invocation-pattern.sh` |

### Category 2: Missing Files (Files That Don't Exist)

8 files are referenced in documentation but don't exist in any lib subdirectory:

1. **context-pruning.sh** - Referenced 24+ times across 15+ files
   - Most heavily referenced missing file
   - Used in: hierarchical-agents.md, orchestration-guide.md, context-management.md, etc.

2. **parse-adaptive-plan.sh** - Referenced 6 times
   - Used in: adaptive-planning-guide.md

3. **list-checkpoints.sh** - Referenced 3 times
   - Used in: adaptive-planning-guide.md

4. **cleanup-checkpoints.sh** - Referenced 2 times
   - Used in: adaptive-planning-guide.md

5. **dependency-analysis.sh** - Referenced 2 times
   - Used in: phase-dependencies.md

6. **conversion-logger.sh** - Referenced 1 time
   - Used in: command-development-standards-integration.md

7. **utils.sh** - Referenced 1 time
   - Used in: defensive-programming.md

8. **validate-context-reduction.sh** - Referenced 1 time
   - Used in: agent-delegation-troubleshooting.md

### Category 3: Incorrect Test File Path Depth

Files in `docs/concepts/patterns/` use `../../tests/` but should use `../../../tests/`:

- `llm-classification-pattern.md` (lines 482-484)
  - `../../tests/test_llm_classifier.sh` → `../../../tests/test_llm_classifier.sh`
  - `../../tests/test_scope_detection.sh` → `../../../tests/test_scope_detection.sh`
  - `../../tests/test_scope_detection_ab.sh` → `../../../tests/test_scope_detection_ab.sh`

Files in `docs/guides/orchestration/` use `../../tests/` but should also use `../../../tests/`:

- `workflow-classification-guide.md` (lines 635-636)

Files in `docs/guides/patterns/` need similar fix:

- `enhanced-topic-generation-guide.md` (line 679)

### Category 4: Additional Patterns Found

Other broken link patterns that may need attention:

1. **Relative link depth issues** with `../lib/` vs `../../lib/` vs `../../../lib/`
2. **Scripts directory references** that may need updating

## Recommendations

### 1. Fix Lib Reorganization Links (High Priority)

Create a systematic fix for all 80+ broken lib links using the path mapping above:

```bash
# Example sed commands for bulk replacement
sed -i 's|lib/workflow-scope-detection\.sh|lib/workflow/workflow-scope-detection.sh|g' file.md
sed -i 's|lib/metadata-extraction\.sh|lib/workflow/metadata-extraction.sh|g' file.md
sed -i 's|lib/unified-location-detection\.sh|lib/core/unified-location-detection.sh|g' file.md
```

### 2. Remove or Create Missing File References (High Priority)

For the 8 missing files, either:
- **Create the files** if functionality was planned but not implemented
- **Remove references** if functionality was deprecated
- **Update to alternative** if functionality moved to different files

Specifically:
- `context-pruning.sh` - Most critical, 24+ references need resolution
- `parse-adaptive-plan.sh`, `list-checkpoints.sh`, `cleanup-checkpoints.sh` - May be part of adaptive planning that was never implemented

### 3. Fix Test File Path Depth (Medium Priority)

Update relative paths in `docs/concepts/patterns/` from `../../tests/` to `../../../tests/`:

```bash
sed -i 's|\.\./\.\./tests/|\.\./\.\./\.\./tests/|g' .claude/docs/concepts/patterns/*.md
```

### 4. Add Link Validation to CI (Low Priority)

Consider implementing a simple link checker that doesn't require npx:

```bash
#!/bin/bash
# Simple internal link validator
find .claude/docs -name "*.md" -exec grep -l '\[.*\](.*\.sh)' {} \; | while read file; do
    grep -oP '\[.*?\]\(\K[^)]+\.sh' "$file" | while read link; do
        # Resolve relative path and check existence
        target=$(cd "$(dirname "$file")" && realpath "$link" 2>/dev/null)
        [ ! -f "$target" ] && echo "BROKEN: $file -> $link"
    done
done
```

### 5. Update CLAUDE.md Documentation Policy (Low Priority)

Add guidance about lib directory structure and link conventions to prevent future issues.

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/specs/823_broken_links_after_quick_reference_integration/summaries/001_implementation_summary.md` (lines 1-128)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md` (lines 1-555)
- `/home/benjamin/.config/.claude/lib/` - All subdirectories
- `/home/benjamin/.config/.claude/docs/` - Multiple files via grep search
- `/home/benjamin/.config/.claude/scripts/validate-links.sh` (lines 1-87)

### Broken Links by File (Summary)

| File Path | Broken Links | Category |
|-----------|--------------|----------|
| docs/concepts/patterns/llm-classification-pattern.md | 9 | Lib reorg + Test paths |
| docs/troubleshooting/agent-delegation-troubleshooting.md | 12+ | Lib reorg + Missing |
| docs/concepts/hierarchical-agents.md | 18 | Lib reorg + Missing |
| docs/workflows/orchestration-guide.md | 7 | Lib reorg + Missing |
| docs/workflows/adaptive-planning-guide.md | 11 | Missing files |
| docs/reference/workflows/orchestration-reference.md | 7 | Lib reorg |
| docs/workflows/conversion-guide.md | 5 | Lib reorg |
| docs/reference/library-api/utilities.md | 4 | Lib reorg + Missing |
| docs/guides/orchestration/workflow-classification-guide.md | 5 | Lib reorg + Test paths |
| docs/guides/patterns/enhanced-topic-generation-guide.md | 4 | Lib reorg + Test paths |

### Total Scope

- **Files requiring updates**: 15+ documentation files
- **Total broken links**: 80+ lib links + 24+ missing file references + 7 test path fixes
- **Estimated fix time**: 2-3 hours for systematic sed-based replacement
- **Risk level**: Low (documentation-only changes)

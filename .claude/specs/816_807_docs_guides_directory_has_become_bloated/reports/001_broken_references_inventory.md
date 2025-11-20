# Broken References Inventory - Guides Refactor

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Broken cross-references from guides directory refactor
- **Report Type**: codebase analysis

## Executive Summary

The guides refactor moved 61+ files from `.claude/docs/guides/` root to subdirectories (commands/, development/, orchestration/, patterns/, templates/). This created **150+ broken references** across the codebase. The most affected files are docs/README.md (45+ references), docs/reference/*.md files (30+ references), and docs/workflows/*.md files (25+ references). Additionally, several guide files were archived or split, requiring references to be updated to new consolidated locations.

## Findings

### Category 1: Major Reference Hub Files (HIGH PRIORITY)

These files contain the most broken references and should be fixed first:

#### 1.1 `/home/benjamin/.config/.claude/docs/README.md`
**Impact**: 45+ broken references to guides at root level
**Lines affected**: 248, 370-379, 413-426, 567-575, 601-622, 668-742, 756-757

Key broken patterns:
- `guides/agent-development-guide.md` - appears 12+ times
- `guides/command-development-guide.md` - appears 10+ times
- `guides/command-patterns.md` - appears 5+ times
- `guides/standards-integration.md` - appears 4+ times
- `guides/performance-optimization.md` - appears 4+ times
- `guides/logging-patterns.md` - appears 2 times
- `guides/error-enhancement-guide.md` - appears 2 times

#### 1.2 `/home/benjamin/.config/.claude/docs/reference/README.md`
**Impact**: 12 broken references
**Lines affected**: 25, 38, 51, 64, 90, 103, 142

Broken patterns:
- `../guides/command-development-guide.md`
- `../guides/agent-development-guide.md`
- `../guides/command-patterns.md`
- `../guides/standards-integration.md`
- `../guides/test-command-guide.md`
- `../guides/using-utility-libraries.md`

#### 1.3 `/home/benjamin/.config/.claude/docs/reference/code-standards.md`
**Impact**: 7 broken references
**Lines affected**: 8, 74, 75, 79, 85, 86, 87

Broken patterns:
- `.claude/docs/guides/error-enhancement-guide.md`
- `.claude/docs/guides/_template-executable-command.md`
- `.claude/docs/guides/_template-command-guide.md`
- `.claude/docs/guides/command-development-guide.md` (2x)
- `.claude/docs/guides/agent-development-guide.md`
- `.claude/docs/guides/model-selection-guide.md`

### Category 2: Reference Files in docs/reference/

#### 2.1 `/home/benjamin/.config/.claude/docs/reference/command-reference.md`
**Lines**: 3, 173, 477, 511, 591-594
- `../guides/command-development-guide.md` (3x)
- `../guides/document-command-guide.md`
- `../guides/test-command-guide.md`
- `../guides/command-patterns.md`

#### 2.2 `/home/benjamin/.config/.claude/docs/reference/agent-reference.md`
**Lines**: 330, 389-391
- `../guides/agent-development-guide.md` (3x)
- `../guides/command-patterns.md`

#### 2.3 `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md`
**Lines**: 268, 288-290, 293
- `../guides/error-enhancement-guide.md` (2x)
- `../guides/logging-patterns.md`
- `../guides/command-development-guide.md`
- `../guides/_template-bash-block.md`

#### 2.4 `/home/benjamin/.config/.claude/docs/reference/library-api-overview.md`
**Lines**: 22, 434, 435
- `../guides/using-utility-libraries.md` (2x)
- `../guides/command-development-guide.md`

#### 2.5 `/home/benjamin/.config/.claude/docs/reference/library-api.md`
**Lines**: 12, 1374-1377
- `../guides/using-utility-libraries.md` (2x)
- `../guides/command-development-guide.md`
- `../guides/agent-development-guide.md`
- `../guides/performance-optimization.md`

#### 2.6 `/home/benjamin/.config/.claude/docs/reference/library-api-utilities.md`
**Lines**: 458-461
- `../guides/using-utility-libraries.md`
- `../guides/command-development-guide.md`
- `../guides/agent-development-guide.md`
- `../guides/performance-optimization.md`

#### 2.7 `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
**Lines**: 1367, 1368, 2480
- `../guides/command-development-guide.md`
- `../guides/orchestration-troubleshooting.md`
- `../guides/command-patterns.md`

#### 2.8 `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md`
**Lines**: 226, 227
- `../guides/command-development-guide.md`
- `../guides/orchestration-troubleshooting.md`

#### 2.9 `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md`
**Line**: 196
- `../guides/agent-development-guide.md`

#### 2.10 `/home/benjamin/.config/.claude/docs/reference/architecture-standards-integration.md`
**Lines**: 173, 188
- `../guides/command-patterns.md`
- `../guides/command-development-guide.md`

#### 2.11 `/home/benjamin/.config/.claude/docs/reference/claude-md-section-schema.md`
**Lines**: 425, 426
- `../guides/standards-integration.md` (2x)

#### 2.12 `/home/benjamin/.config/.claude/docs/reference/plan-progress-tracking.md`
**Line**: 225
- `../guides/build-command-guide.md`

#### 2.13 `/home/benjamin/.config/.claude/docs/reference/test-isolation-standards.md`
**Lines**: 766, 767
- `../guides/command-development-guide.md`
- `../guides/agent-development-guide.md`

#### 2.14 `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md`
**Line**: 567
- `../guides/command-development-fundamentals.md`

#### 2.15 `/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md`
**Lines**: 10, 461
- `../guides/agent-development-guide.md` (2x)

#### 2.16 `/home/benjamin/.config/.claude/docs/reference/orchestration-reference.md`
**Line**: 978
- `../guides/command-development-guide.md`

### Category 3: Workflow Files in docs/workflows/

#### 3.1 `/home/benjamin/.config/.claude/docs/workflows/README.md`
**Lines**: 38, 64, 90, 103
- `../guides/agent-development-guide.md` (2x)
- `../guides/data-management.md`
- `../guides/performance-optimization.md`
- `../guides/command-development-guide.md`

#### 3.2 `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md`
**Lines**: 1302, 1303, 1370
- `../guides/agent-development-guide.md` (2x)
- `../guides/command-development-guide.md`

#### 3.3 `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-examples.md`
**Lines**: 435, 436
- `../guides/agent-development-guide.md`
- `../guides/command-development-guide.md`

#### 3.4 `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-troubleshooting.md`
**Line**: 250
- `../guides/agent-development-guide.md`

#### 3.5 `/home/benjamin/.config/.claude/docs/workflows/context-budget-management.md`
**Lines**: 662, 663
- `../guides/orchestration-best-practices.md`
- `../guides/phase-0-optimization.md`

#### 3.6 `/home/benjamin/.config/.claude/docs/workflows/hierarchical-agent-workflow.md`
**Lines**: 202, 247
- `../guides/phase-0-optimization.md`
- `../guides/orchestration-best-practices.md`

#### 3.7 `/home/benjamin/.config/.claude/docs/workflows/tts-integration-guide.md`
**Line**: 632
- `../guides/performance-optimization.md`

### Category 4: Concept Files in docs/concepts/

#### 4.1 `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`
**Lines**: 38, 1466, 1467
- `../guides/agent-development-guide.md` (2x)
- `../guides/command-development-guide.md`

#### 4.2 `/home/benjamin/.config/.claude/docs/concepts/README.md`
**Lines**: 26, 65
- `../guides/agent-development-guide.md`
- `../guides/command-development-guide.md`

#### 4.3 `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md`
**Lines**: 87, 193, 300-303
- `../guides/library-api.md`
- `../guides/error-enhancement-guide.md` (2x)
- `../guides/command-development-guide.md`
- `../guides/agent-development-guide.md`

### Category 5: Agent and Command Files

#### 5.1 `/home/benjamin/.config/.claude/agents/README.md`
**Line**: 825
- `../docs/guides/agent-development-guide.md`

#### 5.2 `/home/benjamin/.config/.claude/agents/templates/README.md`
**Line**: 60
- `../../docs/guides/agent-development-guide.md`

#### 5.3 `/home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md`
**Line**: 11
- `../docs/guides/docs-accuracy-analyzer-agent-guide.md`

#### 5.4 `/home/benjamin/.config/.claude/commands/templates/README.md`
**Line**: 71
- `../../docs/guides/command-development-guide.md`

### Category 6: Architecture Files

#### 6.1 `/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md`
**Line**: 980
- `.claude/docs/guides/orchestration-best-practices.md`

### Category 7: Internal Guide Cross-References

These are broken references within the guides directory itself (files referencing sibling files at old paths):

#### 7.1 `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md`
**Line**: 554
- `.claude/docs/guides/agent-development-guide.md`

#### 7.2 `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-troubleshooting.md`
**Lines**: 212, 313, 887, 888
- `./command-development-guide.md`
- `./imperative-language-guide.md` (2x)

#### 7.3 `/home/benjamin/.config/.claude/docs/guides/patterns/migration-testing.md`
**Lines**: 7, 490
- `./execution-enforcement-guide.md` (2x)

#### 7.4 `/home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md`
**Lines**: 35, 38, 39, 173, 788, 791, 792
- `execution-enforcement-guide.md` (3x)
- `command-development-guide.md` (2x)
- `agent-development-guide.md` (2x)

#### 7.5 `/home/benjamin/.config/.claude/docs/guides/patterns/performance-optimization.md`
**Lines**: 1318, 1319
- `./command-development-guide.md`
- `./agent-development-guide.md`

#### 7.6 `/home/benjamin/.config/.claude/docs/guides/patterns/standards-integration.md`
**Line**: 733
- `command-development-guide.md`

#### 7.7 `/home/benjamin/.config/.claude/docs/guides/patterns/error-enhancement-guide.md`
**Lines**: 437, 438
- Links to workflows (correct path but needs verification)

#### 7.8 `/home/benjamin/.config/.claude/docs/guides/patterns/logging-patterns.md`
**Line**: 719
- `error-enhancement-guide.md` (correct - same directory)

#### 7.9 `/home/benjamin/.config/.claude/docs/guides/patterns/revision-specialist-agent-guide.md`
**Line**: 395
- `./coordinate-command-guide.md`

#### 7.10 `/home/benjamin/.config/.claude/docs/guides/patterns/enhanced-topic-generation-guide.md`
**Line**: 683
- `workflow-classification-guide.md` (needs path update)

#### 7.11 `/home/benjamin/.config/.claude/docs/guides/development/using-utility-libraries.md`
**Line**: 758
- `command-development-guide.md` (needs path update)

#### 7.12 `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md`
**Lines**: 472, 473
- `model-rollback-guide.md` (correct - same directory)
- `agent-development-guide.md` (needs path update)

#### 7.13 `/home/benjamin/.config/.claude/docs/guides/development/model-rollback-guide.md`
**Lines**: 386, 387
- `model-selection-guide.md` (correct - same directory)
- `agent-development-guide.md` (needs path update)

#### 7.14 `/home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md`
**Lines**: 161, 169
- `./command-development-guide.md`
- `./related-guide.md`

#### 7.15 `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md`
**Lines**: 530, 769, 772
- `imperative-language-guide.md`
- `agent-development-guide.md`
- `execution-enforcement-guide.md`

### Category 8: CHANGELOG and Other Root Files

#### 8.1 `/home/benjamin/.config/.claude/CHANGELOG.md`
**Lines**: 225, 233
- `.claude/docs/guides/command-authoring-guide.md`
- `.claude/docs/guides/agent-authoring-guide.md`

### Category 9: Spec Files (Lower Priority - Historical)

These references in spec files are historical records and may not need updating:
- `/home/benjamin/.config/.claude/specs/807_*/reports/*.md` - Various historical references
- `/home/benjamin/.config/.claude/specs/800_*/reports/*.md` - Analysis reports
- `/home/benjamin/.config/.claude/specs/794_*/plans/*.md` - Implementation plans
- `/home/benjamin/.config/.claude/specs/788_*/reports/*.md` - Documentation conventions
- `/home/benjamin/.config/.claude/specs/789_*/summaries/*.md` - Implementation summaries

### Category 10: Backup Files (No Fix Needed)

These are backup copies and should not be modified:
- `/home/benjamin/.config/.claude/backups/guides-refactor-20251119/guides/*.md`
- `/home/benjamin/.config/.claude/backups/docs-optimization-20251117/*.md`

### Category 11: Archive Files (Lower Priority)

Files in archive may have broken internal references but are not actively used:
- `/home/benjamin/.config/.claude/docs/archive/guides/link-conventions-guide.md` - Lines 17, 20, 26, 29, 145
- `/home/benjamin/.config/.claude/archive/coordinate/docs/architecture/*.md` - Various lines

## Summary Statistics

| Category | File Count | Reference Count | Priority |
|----------|------------|-----------------|----------|
| docs/README.md | 1 | 45+ | HIGH |
| docs/reference/*.md | 16 | 50+ | HIGH |
| docs/workflows/*.md | 7 | 20+ | MEDIUM |
| docs/concepts/*.md | 3 | 10+ | MEDIUM |
| agents/*.md | 3 | 5 | MEDIUM |
| commands/*.md | 1 | 1 | MEDIUM |
| docs/guides/**/*.md (internal) | 15+ | 30+ | HIGH |
| specs/*.md | 10+ | 20+ | LOW |
| backups/*.md | 5+ | 15+ | NONE |
| archive/*.md | 5+ | 10+ | LOW |

**Total Broken References**: ~150+
**Files Requiring Updates**: ~50
**High Priority Files**: ~20

## Recommendations

1. **Fix in Priority Order**:
   - Start with `docs/README.md` - highest impact, most references
   - Then `docs/reference/*.md` files - critical for developers
   - Then internal guide cross-references - ensures guide integrity
   - Then `docs/workflows/*.md` and `docs/concepts/*.md`

2. **Use Batch Replace Strategy**:
   - Group fixes by old path -> new path
   - Use sed or similar for bulk updates
   - Test each file after modification

3. **Create Path Mapping Script**:
   - Automate the old-to-new path transformation
   - Apply consistently across all files

4. **Skip Low Priority Files**:
   - Backup files should not be modified
   - Spec files are historical records
   - Archive files can be fixed later if needed

5. **Verify After Fixes**:
   - Run broken link checker
   - Test navigation from key entry points
   - Validate all markdown links resolve

## References

Files analyzed:
- `/home/benjamin/.config/.claude/docs/README.md`
- `/home/benjamin/.config/.claude/docs/reference/*.md` (16 files)
- `/home/benjamin/.config/.claude/docs/workflows/*.md` (7 files)
- `/home/benjamin/.config/.claude/docs/concepts/*.md` (3 files)
- `/home/benjamin/.config/.claude/docs/guides/**/*.md` (67 files)
- `/home/benjamin/.config/.claude/agents/*.md` (20+ files)
- `/home/benjamin/.config/.claude/commands/templates/*.md` (3 files)
- `/home/benjamin/.config/.claude/CHANGELOG.md`
- Various spec and archive files

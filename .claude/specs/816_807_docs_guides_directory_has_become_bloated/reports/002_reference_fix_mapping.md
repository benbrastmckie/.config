# Reference Fix Mapping - Old Paths to New Paths

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Mapping old guide paths to new locations
- **Report Type**: codebase analysis

## Executive Summary

This report provides a complete mapping of old guide file paths to their new locations after the guides directory refactor. Files were reorganized into 5 subdirectories: commands/, development/, orchestration/, patterns/, and templates/. Some files were split into multiple parts, and others were archived. The mapping includes 44 moved files and 8 archived files, with specific guidance on which new file to use as the primary reference for split content.

## Findings

### Path Mapping Groups

The following sections group old paths with the files that reference them, organized by the new location pattern for efficient batch replacement.

---

### Group 1: Development Guides (9 files)

#### 1.1 agent-development-guide.md
**Old Path**: `guides/agent-development-guide.md`
**New Path**: `guides/development/agent-development/agent-development-fundamentals.md`
**Note**: File was split into 6 parts. Use fundamentals.md as primary entry point.

**Files referencing this path** (30+ occurrences):
- `/home/benjamin/.config/.claude/docs/README.md` - Lines 248, 376, 416, 419, 420, 567, 568, 569, 614, 615, 684, 716, 733, 734
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Lines 38
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Line 86
- `/home/benjamin/.config/.claude/docs/reference/agent-reference.md` - Lines 330, 389, 390
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Line 1376
- `/home/benjamin/.config/.claude/docs/reference/library-api-utilities.md` - Line 460
- `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` - Line 196
- `/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md` - Lines 10, 461
- `/home/benjamin/.config/.claude/docs/reference/test-isolation-standards.md` - Line 767
- `/home/benjamin/.config/.claude/docs/workflows/README.md` - Lines 38
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md` - Lines 1302, 1370
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-examples.md` - Line 435
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-troubleshooting.md` - Line 250
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` - Lines 38, 1466
- `/home/benjamin/.config/.claude/docs/concepts/README.md` - Line 26
- `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md` - Line 301
- `/home/benjamin/.config/.claude/agents/README.md` - Line 825
- `/home/benjamin/.config/.claude/agents/templates/README.md` - Line 60
- `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` - Line 554
- `/home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md` - Lines 39, 792
- `/home/benjamin/.config/.claude/docs/guides/patterns/performance-optimization.md` - Line 1319
- `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md` - Line 473
- `/home/benjamin/.config/.claude/docs/guides/development/model-rollback-guide.md` - Line 387
- `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md` - Line 769

#### 1.2 command-development-guide.md
**Old Path**: `guides/command-development-guide.md`
**New Path**: `guides/development/command-development/command-development-fundamentals.md`
**Note**: File was split into 5 parts. Use fundamentals.md as primary entry point.

**Files referencing this path** (25+ occurrences):
- `/home/benjamin/.config/.claude/docs/README.md` - Lines 374, 413, 567, 601, 610, 620, 668, 722, 729, 740
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Lines 25, 64, 103, 142
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Lines 79, 85
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Lines 3, 511, 591, 594
- `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md` - Line 290
- `/home/benjamin/.config/.claude/docs/reference/library-api-overview.md` - Line 435
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Line 1375
- `/home/benjamin/.config/.claude/docs/reference/library-api-utilities.md` - Line 459
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Line 1367
- `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md` - Line 226
- `/home/benjamin/.config/.claude/docs/reference/architecture-standards-integration.md` - Line 188
- `/home/benjamin/.config/.claude/docs/reference/orchestration-reference.md` - Line 978
- `/home/benjamin/.config/.claude/docs/reference/test-isolation-standards.md` - Line 766
- `/home/benjamin/.config/.claude/docs/workflows/README.md` - Line 103
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md` - Line 1303
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-examples.md` - Line 436
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` - Line 1467
- `/home/benjamin/.config/.claude/docs/concepts/README.md` - Line 65
- `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md` - Line 300
- `/home/benjamin/.config/.claude/commands/templates/README.md` - Line 71
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-troubleshooting.md` - Line 212
- `/home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md` - Lines 38, 791
- `/home/benjamin/.config/.claude/docs/guides/patterns/performance-optimization.md` - Line 1318
- `/home/benjamin/.config/.claude/docs/guides/patterns/standards-integration.md` - Line 733
- `/home/benjamin/.config/.claude/docs/guides/development/using-utility-libraries.md` - Line 758
- `/home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md` - Line 161

#### 1.3 model-selection-guide.md
**Old Path**: `guides/model-selection-guide.md`
**New Path**: `guides/development/model-selection-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Line 87

#### 1.4 using-utility-libraries.md
**Old Path**: `guides/using-utility-libraries.md`
**New Path**: `guides/development/using-utility-libraries.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Line 142
- `/home/benjamin/.config/.claude/docs/reference/library-api-overview.md` - Lines 22, 434
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Line 1374
- `/home/benjamin/.config/.claude/docs/reference/library-api-utilities.md` - Line 458

#### 1.5 command-development-fundamentals.md
**Old Path**: `guides/command-development-fundamentals.md`
**New Path**: `guides/development/command-development/command-development-fundamentals.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md` - Line 567

---

### Group 2: Pattern Guides (15 files)

#### 2.1 error-enhancement-guide.md
**Old Path**: `guides/error-enhancement-guide.md`
**New Path**: `guides/patterns/error-enhancement-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Line 8
- `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md` - Lines 268, 289
- `/home/benjamin/.config/.claude/docs/README.md` - Line 575
- `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md` - Lines 193, 302

#### 2.2 data-management.md
**Old Path**: `guides/data-management.md`
**New Path**: `guides/patterns/data-management.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/workflows/README.md` - Line 64

#### 2.3 performance-optimization.md
**Old Path**: `guides/performance-optimization.md`
**New Path**: `guides/patterns/performance-optimization.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/README.md` - Lines 574, 756
- `/home/benjamin/.config/.claude/docs/workflows/README.md` - Line 90
- `/home/benjamin/.config/.claude/docs/workflows/tts-integration-guide.md` - Line 632
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Line 1377
- `/home/benjamin/.config/.claude/docs/reference/library-api-utilities.md` - Line 461

#### 2.4 logging-patterns.md
**Old Path**: `guides/logging-patterns.md`
**New Path**: `guides/patterns/logging-patterns.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/README.md` - Line 573
- `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md` - Line 288

#### 2.5 standards-integration.md
**Old Path**: `guides/standards-integration.md`
**New Path**: `guides/patterns/standards-integration.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/README.md` - Lines 377, 414, 425, 570, 604, 700, 726
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Line 51
- `/home/benjamin/.config/.claude/docs/reference/claude-md-section-schema.md` - Lines 425, 426

#### 2.6 phase-0-optimization.md
**Old Path**: `guides/phase-0-optimization.md`
**New Path**: `guides/patterns/phase-0-optimization.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/workflows/context-budget-management.md` - Line 663
- `/home/benjamin/.config/.claude/docs/workflows/hierarchical-agent-workflow.md` - Line 202

#### 2.7 docs-accuracy-analyzer-agent-guide.md
**Old Path**: `guides/docs-accuracy-analyzer-agent-guide.md`
**New Path**: `guides/patterns/docs-accuracy-analyzer-agent-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md` - Line 11

#### 2.8 enhanced-topic-generation-guide.md
**Old Path**: `guides/enhanced-topic-generation-guide.md`
**New Path**: `guides/patterns/enhanced-topic-generation-guide.md`
**Note**: Internal reference needs update to orchestration/ subdirectory

---

### Group 3: Orchestration Guides (8 files)

#### 3.1 orchestration-best-practices.md
**Old Path**: `guides/orchestration-best-practices.md`
**New Path**: `guides/orchestration/orchestration-best-practices.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md` - Line 980
- `/home/benjamin/.config/.claude/docs/workflows/context-budget-management.md` - Line 662
- `/home/benjamin/.config/.claude/docs/workflows/hierarchical-agent-workflow.md` - Line 247

#### 3.2 orchestration-troubleshooting.md
**Old Path**: `guides/orchestration-troubleshooting.md`
**New Path**: `guides/orchestration/orchestration-troubleshooting.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Line 1368
- `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md` - Line 227

---

### Group 4: Command Guides (12 files)

#### 4.1 build-command-guide.md
**Old Path**: `guides/build-command-guide.md`
**New Path**: `guides/commands/build-command-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/plan-progress-tracking.md` - Line 225

#### 4.2 test-command-guide.md
**Old Path**: `guides/test-command-guide.md`
**New Path**: `guides/commands/test-command-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Line 90
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Line 477

#### 4.3 document-command-guide.md
**Old Path**: `guides/document-command-guide.md`
**New Path**: `guides/commands/document-command-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Line 173

---

### Group 5: Template Files (3 files)

#### 5.1 _template-executable-command.md
**Old Path**: `guides/_template-executable-command.md`
**New Path**: `guides/templates/_template-executable-command.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Line 74

#### 5.2 _template-command-guide.md
**Old Path**: `guides/_template-command-guide.md`
**New Path**: `guides/templates/_template-command-guide.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Line 75

#### 5.3 _template-bash-block.md
**Old Path**: `guides/_template-bash-block.md`
**New Path**: `guides/templates/_template-bash-block.md`

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md` - Line 293

---

### Group 6: Archived Files (No New Location)

These files were archived and should be referenced differently:

#### 6.1 command-patterns.md
**Old Path**: `guides/command-patterns.md`
**Archive Location**: `docs/archive/guides/command-patterns.md`
**Replacement**: `guides/patterns/command-patterns/command-patterns-overview.md`
**Note**: Content was split into 4 files in command-patterns/ subdirectory

**Files referencing this path** (9 occurrences):
- `/home/benjamin/.config/.claude/docs/README.md` - Lines 378, 415, 571, 622, 730, 742
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Lines 25, 64
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Line 592
- `/home/benjamin/.config/.claude/docs/reference/agent-reference.md` - Line 391
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Line 2480
- `/home/benjamin/.config/.claude/docs/reference/architecture-standards-integration.md` - Line 173

#### 6.2 execution-enforcement-guide.md
**Old Path**: `guides/execution-enforcement-guide.md`
**Archive Location**: `docs/archive/guides/execution-enforcement-guide.md`
**Replacement**: `guides/patterns/execution-enforcement/execution-enforcement-overview.md`
**Note**: Content was split into 4 files in execution-enforcement/ subdirectory

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/guides/patterns/migration-testing.md` - Lines 7, 490
- `/home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md` - Lines 35, 173, 788
- `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md` - Line 772

#### 6.3 imperative-language-guide.md
**Old Path**: `guides/imperative-language-guide.md`
**Archive Location**: `docs/archive/guides/imperative-language-guide.md`
**Replacement**: Reference execution-enforcement patterns instead
**Note**: Content merged into execution-enforcement guides

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-troubleshooting.md` - Lines 313, 888
- `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md` - Line 530

#### 6.4 workflow-type-selection-guide.md
**Old Path**: `guides/workflow-type-selection-guide.md`
**Archive Location**: `docs/archive/guides/workflow-type-selection-guide.md`
**Replacement**: `guides/orchestration/workflow-classification-guide.md`

#### 6.5 command-authoring-guide.md / agent-authoring-guide.md
**Old Paths**: `guides/command-authoring-guide.md`, `guides/agent-authoring-guide.md`
**Archive Location**: N/A (renamed)
**Replacement**: command-development-guide and agent-development-guide respectively
**Note**: These were old names, replaced by development guides

**Files referencing these paths**:
- `/home/benjamin/.config/.claude/CHANGELOG.md` - Lines 225, 233

#### 6.6 library-api.md
**Old Path**: `guides/library-api.md`
**New Path**: Should reference `docs/reference/library-api.md`
**Note**: This was likely always in reference/, not guides/

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md` - Lines 87, 303

#### 6.7 coordinate-command-guide.md
**Old Path**: `guides/coordinate-command-guide.md`
**Status**: Removed/Deprecated
**Note**: Coordinate command was deprecated in favor of build command

**Files referencing this path**:
- `/home/benjamin/.config/.claude/docs/guides/patterns/revision-specialist-agent-guide.md` - Line 395
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestrate-phases-implementation.md` - Line 754

---

## Sed Replacement Commands

These sed commands can be used for batch replacement. Apply in order of specificity:

### Phase 1: Development Guides
```bash
# agent-development-guide.md -> development/agent-development/agent-development-fundamentals.md
sed -i 's|guides/agent-development-guide\.md|guides/development/agent-development/agent-development-fundamentals.md|g'

# command-development-guide.md -> development/command-development/command-development-fundamentals.md
sed -i 's|guides/command-development-guide\.md|guides/development/command-development/command-development-fundamentals.md|g'

# model-selection-guide.md
sed -i 's|guides/model-selection-guide\.md|guides/development/model-selection-guide.md|g'

# using-utility-libraries.md
sed -i 's|guides/using-utility-libraries\.md|guides/development/using-utility-libraries.md|g'
```

### Phase 2: Pattern Guides
```bash
# error-enhancement-guide.md
sed -i 's|guides/error-enhancement-guide\.md|guides/patterns/error-enhancement-guide.md|g'

# data-management.md
sed -i 's|guides/data-management\.md|guides/patterns/data-management.md|g'

# performance-optimization.md
sed -i 's|guides/performance-optimization\.md|guides/patterns/performance-optimization.md|g'

# logging-patterns.md
sed -i 's|guides/logging-patterns\.md|guides/patterns/logging-patterns.md|g'

# standards-integration.md
sed -i 's|guides/standards-integration\.md|guides/patterns/standards-integration.md|g'

# phase-0-optimization.md
sed -i 's|guides/phase-0-optimization\.md|guides/patterns/phase-0-optimization.md|g'

# docs-accuracy-analyzer-agent-guide.md
sed -i 's|guides/docs-accuracy-analyzer-agent-guide\.md|guides/patterns/docs-accuracy-analyzer-agent-guide.md|g'
```

### Phase 3: Orchestration Guides
```bash
# orchestration-best-practices.md
sed -i 's|guides/orchestration-best-practices\.md|guides/orchestration/orchestration-best-practices.md|g'

# orchestration-troubleshooting.md
sed -i 's|guides/orchestration-troubleshooting\.md|guides/orchestration/orchestration-troubleshooting.md|g'
```

### Phase 4: Command Guides
```bash
# build-command-guide.md
sed -i 's|guides/build-command-guide\.md|guides/commands/build-command-guide.md|g'

# test-command-guide.md
sed -i 's|guides/test-command-guide\.md|guides/commands/test-command-guide.md|g'

# document-command-guide.md
sed -i 's|guides/document-command-guide\.md|guides/commands/document-command-guide.md|g'
```

### Phase 5: Template Files
```bash
# Templates
sed -i 's|guides/_template-executable-command\.md|guides/templates/_template-executable-command.md|g'
sed -i 's|guides/_template-command-guide\.md|guides/templates/_template-command-guide.md|g'
sed -i 's|guides/_template-bash-block\.md|guides/templates/_template-bash-block.md|g'
```

### Phase 6: Archived File Replacements
```bash
# command-patterns.md -> command-patterns-overview.md
sed -i 's|guides/command-patterns\.md|guides/patterns/command-patterns/command-patterns-overview.md|g'

# execution-enforcement-guide.md -> execution-enforcement-overview.md
sed -i 's|guides/execution-enforcement-guide\.md|guides/patterns/execution-enforcement/execution-enforcement-overview.md|g'

# workflow-type-selection-guide.md -> workflow-classification-guide.md
sed -i 's|guides/workflow-type-selection-guide\.md|guides/orchestration/workflow-classification-guide.md|g'
```

## Recommendations

1. **Execute sed commands in separate phases** to avoid partial replacements
2. **Test on a single file first** before batch application
3. **Commit after each phase** for easy rollback
4. **Verify links after replacement** using a markdown link checker
5. **Handle special cases manually**:
   - CHANGELOG references to old authoring guides
   - Deprecated coordinate-command-guide references
   - library-api.md (in reference/, not guides/)
6. **Update internal guide references** separately with relative paths
7. **Skip backup and archive directories** when running sed

## References

Files analyzed for path mapping:
- `/home/benjamin/.config/.claude/docs/guides/**/README.md` - New structure documentation
- `/home/benjamin/.config/.claude/docs/archive/guides/` - Archived file locations
- `/home/benjamin/.config/.claude/specs/807_*/summaries/001_guides_refactor_summary.md` - Original refactor summary
- All files identified in 001_broken_references_inventory.md

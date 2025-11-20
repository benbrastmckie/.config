# Broken Link Analysis Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Analysis of broken links and their categorization
- **Report Type**: codebase analysis

## Executive Summary

The broken link analysis reveals three distinct categories of issues following the reference directory restructuring. The most severe category involves 80+ references to `command_architecture_standards.md`, a file that appears to have been deleted rather than moved. The other two categories (`library-api-overview.md` and `phase_dependencies.md`) are straightforward path updates. The remediation strategy requires different approaches: bulk sed replacement for categories B and C, but careful investigation for category A to determine if the file should be restored or references redirected to new locations.

## Findings

### 1. Link Categorization Overview

| Category | File Pattern | Count | Severity | Fix Strategy |
|----------|-------------|-------|----------|--------------|
| A | `command_architecture_standards.md` | ~80 | Critical | Investigate/Restore |
| B | `library-api-overview.md` | ~10 | Medium | Sed replacement |
| C | `phase_dependencies.md` | ~12 | Medium | Sed replacement |
| D | Internal anchors (quick-reference) | 3 | None | Already valid |

**Total Broken References**: 102+ (across ~50 unique files)

### 2. Category A: command_architecture_standards.md - CRITICAL

**Status**: File appears to be DELETED, not moved

**Verification**:
```bash
ls -la /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md
# Result: No such file or directory

# Searched in potential new locations:
ls -la /home/benjamin/.config/.claude/docs/reference/architecture/
# Contains: dependencies.md, documentation.md, error-handling.md, integration.md,
#           overview.md, template-vs-behavioral.md, testing.md, validation.md
# Note: No command_architecture_standards.md or similar

ls -la /home/benjamin/.config/.claude/docs/reference/standards/
# Would need to check for equivalent content
```

**Impact Assessment**:

This file was a foundational reference for 14+ formal standards:
- Standard 0: Execution Enforcement
- Standard 1: Inline Execution
- Standards 6-8: Context Preservation
- Standard 11: Imperative Agent Invocation
- Standard 12: Structural vs Behavioral Content Separation
- Standard 13: Project Directory Detection
- Standard 14: Executable/Documentation Separation

**Affected Files** (80+ references in 40+ unique files):

Critical documentation files affected:
- `/home/benjamin/.config/.claude/docs/README.md` - Main documentation index (7 references)
- `/home/benjamin/.config/.claude/docs/concepts/README.md` - Concepts index (2 references)
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` - Writing standards (2 references)
- `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md` - Framework guide (2 references)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` - Agent architecture (1 reference)
- `/home/benjamin/.config/.claude/docs/concepts/architectural-decision-framework.md` - Decision framework (1 reference)

Workflow documentation affected:
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md` - Main orchestration guide (2 references)
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-overview.md` - Overview (1 reference)
- `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide-patterns.md` - Patterns (1 reference)
- `/home/benjamin/.config/.claude/docs/workflows/spec_updater_guide.md` - Spec updater (2 references)
- `/home/benjamin/.config/.claude/docs/workflows/checkpoint_template_guide.md` - Checkpoints (1 reference)

Troubleshooting documentation affected:
- `/home/benjamin/.config/.claude/docs/troubleshooting/README.md` - Index (1 reference)
- `/home/benjamin/.config/.claude/docs/troubleshooting/agent-delegation-troubleshooting.md` - Agent delegation (3 references)
- `/home/benjamin/.config/.claude/docs/troubleshooting/inline-template-duplication.md` - Templates (1 reference)
- `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` - Bash limitations (1 reference)

Pattern documentation affected:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/README.md` - Patterns index (1 reference)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` - Separation (4 references)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Injection (2 references)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - Verification (1 reference)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/defensive-programming.md` - Defensive (1 reference)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md` - LLM patterns (2 references)

Guide documentation affected:
- `/home/benjamin/.config/.claude/docs/guides/README.md` - Guides index (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/templates/README.md` - Templates (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md` - Refactoring (2 references)
- `/home/benjamin/.config/.claude/docs/guides/patterns/migration-testing.md` - Migration (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/patterns/standards-integration.md` - Integration (5 references)
- `/home/benjamin/.config/.claude/docs/guides/patterns/logging-patterns.md` - Logging (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/commands/setup-command-guide.md` - Setup (2 references)
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-best-practices.md` - Best practices (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-troubleshooting.md` - Troubleshooting (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/development/README.md` - Development (1 reference)
- `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-examples-case-studies.md` - Examples (1 reference)

Reference documentation affected:
- `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md` - Testing (1 reference)
- `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md` - Commands (1 reference)
- `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` - Formatting (1 reference)
- `/home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md` - Agents (2 references)
- `/home/benjamin/.config/.claude/docs/reference/architecture/template-vs-behavioral.md` - Templates (2 references)
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/step-pattern-classification-flowchart.md` - Flowcharts (1 reference)
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/template-usage-decision-tree.md` - Decision tree (1 reference)
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/error-handling-flowchart.md` - Error handling (2 references)
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/executable-vs-guide-content.md` - Guide content (4 references)

Architecture documentation affected:
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` - State orchestration (1 reference)

### 3. Category B: library-api-overview.md - MEDIUM

**Status**: File MOVED to subdirectory

**Path Change**:
- Old: `reference/library-api-overview.md`
- New: `reference/library-api/overview.md`

**Affected Files** (10 references in 4 unique files):

1. `/home/benjamin/.config/.claude/docs/concepts/directory-protocols-overview.md`
   - Line 158: `../reference/library-api-overview.md#allocate_and_create_topic`
   - Line 189: `../reference/library-api-overview.md#ensure_artifact_directory`

2. `/home/benjamin/.config/.claude/docs/reference/library-api/state-machine.md`
   - Line 8: `library-api-overview.md`
   - Line 177: `library-api-overview.md`

3. `/home/benjamin/.config/.claude/docs/reference/library-api/utilities.md`
   - Line 8: `library-api-overview.md`
   - Line 455: `library-api-overview.md`

4. `/home/benjamin/.config/.claude/docs/reference/library-api/persistence.md`
   - Line 8: `library-api-overview.md`
   - Line 336: `library-api-overview.md`

**Note**: The files within `library-api/` directory use relative links that should point to `overview.md` (not `library-api-overview.md`).

### 4. Category C: phase_dependencies.md - MEDIUM

**Status**: File MOVED and RENAMED

**Path Change**:
- Old: `reference/phase_dependencies.md`
- New: `reference/workflows/phase-dependencies.md`

**Note**: Filename changed from underscore to hyphen (`phase_dependencies` -> `phase-dependencies`)

**Affected Files** (12 references in 6 unique files):

1. `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md`
   - Line 476: `../reference/phase_dependencies.md`

2. `/home/benjamin/.config/.claude/docs/workflows/README.md`
   - Line 51: `../reference/phase_dependencies.md`
   - Line 248: `../reference/phase_dependencies.md`

3. `/home/benjamin/.config/.claude/docs/concepts/directory-protocols-overview.md`
   - Line 358: `../reference/phase_dependencies.md`
   - Line 369: plain text mention (not a link)

4. `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`
   - Line 984: `../reference/phase_dependencies.md`
   - Line 1143: plain text mention (not a link)

5. `/home/benjamin/.config/.claude/docs/concepts/directory-protocols-examples.md`
   - Line 431: plain text mention (not a link)

6. `/home/benjamin/.config/.claude/docs/README.md`
   - Line 50: `reference/phase_dependencies.md`
   - Line 122: plain text in tree structure
   - Line 362: `reference/phase_dependencies.md`
   - Line 558: `reference/phase_dependencies.md`

### 5. Category D: Quick-Reference Internal Anchors - NO ACTION NEEDED

These are NOT broken links - they are internal page anchors:

1. `/home/benjamin/.config/.claude/docs/reference/workflows/orchestration-reference.md:6`
   - Link: `#section-1-command-quick-reference`
   - Type: Internal anchor within same file - VALID

2. `/home/benjamin/.config/.claude/docs/guides/commands/setup-command-guide.md:968`
   - Text: "quick-reference info" (descriptive text, not a link) - N/A

3. `/home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md:19`
   - Link: `#quick-reference`
   - Type: Internal anchor within same file - VALID

## Recommendations

### 1. Priority 1: Investigate command_architecture_standards.md Deletion

**Action**: Check git history for the file

```bash
cd /home/benjamin/.config
git log --all --full-history --follow --oneline -- ".claude/docs/reference/command_architecture_standards.md"
git show HEAD:.claude/docs/reference/command_architecture_standards.md 2>/dev/null || echo "Not in HEAD"
```

**Decision Tree**:
- If file was intentionally split → Map standards to new locations, create redirect document
- If file was accidentally deleted → Restore from git history
- If file content was merged → Update all 80+ references to new consolidated location

### 2. Priority 2: Bulk Fix library-api-overview.md References

**Execution Commands**:

For files in `library-api/` directory (relative path fix):
```bash
# These need: library-api-overview.md -> overview.md
sed -i 's|library-api-overview\.md|overview.md|g' \
  /home/benjamin/.config/.claude/docs/reference/library-api/state-machine.md \
  /home/benjamin/.config/.claude/docs/reference/library-api/utilities.md \
  /home/benjamin/.config/.claude/docs/reference/library-api/persistence.md
```

For files outside `library-api/` directory (full path fix):
```bash
# These need: reference/library-api-overview.md -> reference/library-api/overview.md
find /home/benjamin/.config/.claude/docs -name "*.md" -not -path "*/library-api/*" \
  -exec sed -i 's|reference/library-api-overview\.md|reference/library-api/overview.md|g' {} \;
```

### 3. Priority 3: Bulk Fix phase_dependencies.md References

**Execution Commands**:
```bash
# Fix both the path and the filename (underscore to hyphen)
find /home/benjamin/.config/.claude/docs -name "*.md" \
  -exec sed -i 's|reference/phase_dependencies\.md|reference/workflows/phase-dependencies.md|g' {} \;
```

### 4. Validation After Fixes

Run validation scripts in sequence:
```bash
cd /home/benjamin/.config

# Quick validation (recent files only)
bash .claude/scripts/validate-links-quick.sh

# Full validation (all files)
bash .claude/scripts/validate-links.sh
```

### 5. Documentation Update

After all fixes are applied, update these index files:
- `/home/benjamin/.config/.claude/docs/README.md` - Update file tree to reflect new structure
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Update navigation guide

## References

- `/home/benjamin/.config/.claude/docs/reference/` - Reference directory structure
- `/home/benjamin/.config/.claude/docs/reference/library-api/overview.md` - New library API overview location
- `/home/benjamin/.config/.claude/docs/reference/workflows/phase-dependencies.md` - New phase dependencies location
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols-overview.md` (lines 158, 189, 246, 358, 368-369)
- `/home/benjamin/.config/.claude/docs/README.md` (lines 22, 50, 96, 121, 122, 361, 362, 557, 558, 600, 719)
- `/home/benjamin/.config/.claude/docs/workflows/README.md` (lines 51, 248)
- `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh` - Quick validation script
- Git status showing file renames with R flag for reference/ restructuring

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_broken_links_fix_plan.md](../plans/001_broken_links_fix_plan.md)
- **Implementation**: Pending
- **Date**: 2025-11-19

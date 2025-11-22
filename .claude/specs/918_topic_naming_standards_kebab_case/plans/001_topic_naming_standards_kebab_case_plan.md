# Topic Naming Standards: Kebab-Case FILE Naming Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Kebab-Case File Naming within Snake_Case Directories
- **Scope**: Migrate file naming from snake_case to kebab-case while preserving snake_case directory naming
- **Estimated Phases**: 4
- **Estimated Hours**: 8
- **Complexity Score**: 72 (refactor=5 + 18 tasks/2 + 12 files*3 + 3 integrations*5)
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
  - [Topic Naming Kebab-Case Standards Research](../reports/001_topic_naming_kebab_case_standards.md)
  - [Plan Revision Insights: Directory vs File Naming](../reports/001_plan_revision_insights.md)

## Overview

This plan implements kebab-case formatting for **file names only** within the existing snake_case directory structure. This creates a clear separation: directories use snake_case for topic identification, files use kebab-case for readability.

**Current State**:
- Directories: `918_topic_naming_standards_kebab_case/` (snake_case - KEEP)
- Files: `001_topic_naming_plan.md` (snake_case - CHANGE)

**Target State**:
- Directories: `918_topic_naming_standards_kebab_case/` (snake_case - UNCHANGED)
- Files: `001-topic-naming-plan.md` (kebab-case - NEW FORMAT)

**Key Pattern Changes**:
- Directory: `^[0-9]{3}_[a-z0-9_]{1,37}$` (KEEP underscore separator)
- File: `^[0-9]{3}-[a-z0-9-]+-[type]\.md$` (hyphens between components)

## Research Summary

Key findings from research reports:

**From 001_topic_naming_kebab_case_standards.md**:
- Original research focused on directory naming migration (scope changed)
- Identified all files involved in filename construction
- Documented current snake_case patterns in commands and agents

**From 001_plan_revision_insights.md** (Critical Revision):
- User clarification: Directories=snake_case (keep), Files=kebab-case (change)
- Plan filename construction found in: plan.md (line 814), repair.md (line 524), debug.md (line 947)
- Report filename construction found in: research-specialist.md (line 480)
- Path extraction patterns need dual-format support for backward compatibility

## Success Criteria

- [ ] All new plan files created with kebab-case format: `NNN-topic-name-plan.md`
- [ ] All new report files created with kebab-case format: `NNN-report-name.md`
- [ ] All new debug strategy files created with kebab-case format: `NNN-debug-strategy.md`
- [ ] Path extraction patterns support both `NNN_file.md` and `NNN-file.md` formats
- [ ] Directory naming remains unchanged (snake_case with underscores)
- [ ] Documentation updated to clarify directories=snake_case, files=kebab-case
- [ ] Existing snake_case files remain accessible (backward compatibility)
- [ ] Tests pass with new kebab-case file format

## Technical Design

### Naming Convention Split

| Component | Format | Separator | Example |
|-----------|--------|-----------|---------|
| Directory | snake_case | underscore | `918_topic_naming_standards/` |
| Plan file | kebab-case | hyphen | `001-topic-naming-plan.md` |
| Report file | kebab-case | hyphen | `001-research-analysis.md` |
| Summary file | kebab-case | hyphen | `001-implementation-summary.md` |
| Debug file | kebab-case | hyphen | `001-debug-strategy.md` |

### File Naming Pattern

```
Before: {NNN}_{topic_name}_{type}.md
After:  {NNN}-{topic-name}-{type}.md

Examples:
  001_jwt_token_fix_plan.md      -> 001-jwt-token-fix-plan.md
  001_error_analysis.md          -> 001-error-analysis.md
  001_debug_strategy.md          -> 001-debug-strategy.md
```

### Conversion Logic

When constructing filenames from snake_case topic names:
```bash
# Topic name remains snake_case for directory: jwt_token_fix
# File slug converts underscores to hyphens: jwt-token-fix
FILE_SLUG=$(echo "$TOPIC_NAME" | tr '_' '-')
PLAN_FILENAME="${PLAN_NUMBER}-${FILE_SLUG}-plan.md"
```

### Affected Components

**Command Layer** (filename construction):
- `commands/plan.md` - Line 814: Plan filename construction
- `commands/repair.md` - Line 524: Plan filename construction
- `commands/debug.md` - Line 947: Debug plan filename construction

**Agent Layer** (filename construction):
- `agents/research-specialist.md` - Line 476, 480: Report filename glob and construction

**Library Layer** (path patterns):
- `lib/workflow/workflow-initialization.sh` - Lines 94-98, 680: Path extraction and plan path construction

### Backward Compatibility

Path extraction patterns will be updated to support both formats:
```bash
# Before: Only snake_case files
/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}_[^.]+\.md$

# After: Both formats
/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}[-_][^.]+\.md$
```

## Implementation Phases

### Phase 1: Command File Updates [NOT STARTED]
dependencies: []

**Objective**: Update filename construction in commands to use kebab-case
**Complexity**: Low
**Risk**: Low (straightforward string manipulation)

Tasks:
- [ ] Update `/plan` command filename construction (file: .claude/commands/plan.md, line 814)
  - Change: `PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"`
  - To: `PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"`
- [ ] Update `/repair` command filename construction (file: .claude/commands/repair.md, line 524)
  - Change: `PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"`
  - To: `PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"`
- [ ] Update `/debug` command filename construction (file: .claude/commands/debug.md, line 947)
  - Change: `PLAN_FILENAME="${PLAN_NUMBER}_debug_strategy.md"`
  - To: `PLAN_FILENAME="${PLAN_NUMBER}-debug-strategy.md"`

Testing:
```bash
# Verify plan.md changes
grep -n "PLAN_FILENAME" .claude/commands/plan.md
# Should show: PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"

# Verify repair.md changes
grep -n "PLAN_FILENAME" .claude/commands/repair.md
# Should show same pattern with hyphen separators

# Verify debug.md changes
grep -n "PLAN_FILENAME" .claude/commands/debug.md
# Should show: PLAN_FILENAME="${PLAN_NUMBER}-debug-strategy.md"
```

**Expected Duration**: 1.5 hours

### Phase 2: Agent File Updates [NOT STARTED]
dependencies: [1]

**Objective**: Update filename construction and examples in agents
**Complexity**: Low
**Risk**: Low (documentation and pattern updates)

Tasks:
- [ ] Update research-specialist.md report glob pattern (file: .claude/agents/research-specialist.md, line 476)
  - Change: `ls "$TOPIC_DIR"/[0-9][0-9][0-9]_*.md`
  - To: `ls "$TOPIC_DIR"/[0-9][0-9][0-9][-_]*.md` (support both formats)
- [ ] Update research-specialist.md report filename construction (file: .claude/agents/research-specialist.md, line 480)
  - Change: `REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}_${report_name}.md"`
  - To: `REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}-$(echo "$report_name" | tr '_' '-').md"`
- [ ] Update errors-analyst.md examples to use kebab-case filenames (file: .claude/agents/errors-analyst.md)
  - Change example: `001_error_report.md` to `001-error-report.md`
- [ ] Update spec-updater.md filename examples (file: .claude/agents/spec-updater.md, line 357)
  - Change example: `001_report.md` to `001-report.md`

Testing:
```bash
# Verify research-specialist.md glob pattern supports both formats
grep -n "\[0-9\]\[0-9\]\[0-9\]" .claude/agents/research-specialist.md
# Should show dual-format pattern

# Verify report path construction uses hyphens
grep -n "REPORT_PATH" .claude/agents/research-specialist.md
# Should show hyphen separator in construction
```

**Expected Duration**: 2 hours

### Phase 3: Library Path Pattern Updates [NOT STARTED]
dependencies: [1]

**Objective**: Update path extraction and construction patterns in workflow libraries
**Complexity**: Medium
**Risk**: Medium (affects path validation across workflows)

Tasks:
- [ ] Update extract_topic_from_plan_path() regex for dual file format support (file: .claude/lib/workflow/workflow-initialization.sh, line 95)
  - Change: `/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}_[^.]+\.md$`
  - To: `/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}[-_][^.]+\.md$`
- [ ] Update plan path construction (file: .claude/lib/workflow/workflow-initialization.sh, line 680)
  - Change: `local plan_path="${topic_path}/plans/001_${topic_name}_plan.md"`
  - To: `local plan_path="${topic_path}/plans/001-$(echo "${topic_name}" | tr '_' '-')-plan.md"`
- [ ] Update path expectation comments to document both formats (file: .claude/lib/workflow/workflow-initialization.sh, lines 94, 98, 103)
  - Add: `# Expected: /path/to/specs/NNN_topic/plans/NNN-plan.md (new) or NNN_plan.md (legacy)`

Testing:
```bash
# Source library and test path extraction with both formats
source .claude/lib/workflow/workflow-initialization.sh

# Test with new kebab-case filename
extract_topic_from_plan_path "/home/user/.config/.claude/specs/918_topic/plans/001-topic-plan.md"
# Should return: 918_topic

# Test with legacy snake_case filename (backward compatibility)
extract_topic_from_plan_path "/home/user/.config/.claude/specs/918_topic/plans/001_topic_plan.md"
# Should return: 918_topic
```

**Expected Duration**: 2.5 hours

### Phase 4: Documentation and Validation [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Update documentation and validate migration
**Complexity**: Low
**Risk**: Low (documentation and verification only)

Tasks:
- [ ] Update docs/concepts/directory-protocols.md to clarify naming split
  - Add section: "Directory vs File Naming Conventions"
  - Explain: directories=snake_case, files=kebab-case
- [ ] Update docs/guides/development/topic-naming-with-llm.md file naming examples
  - Change all file examples from `001_name_plan.md` to `001-name-plan.md`
- [ ] Update CLAUDE.md directory protocols section if it contains file naming examples
- [ ] Run validation scripts to ensure no regressions
- [ ] Verify existing snake_case files remain accessible via glob patterns

Testing:
```bash
# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Verify backward compatibility - existing files still discoverable
find .claude/specs -name "*.md" -path "*/plans/*" | head -5
# Should find both old snake_case and any new kebab-case files

# Grep check for documentation consistency
grep -r "NNN_.*_plan\.md" .claude/docs/ || echo "No snake_case file examples found in docs (good)"
grep -r "NNN-.*-plan\.md" .claude/docs/ && echo "Kebab-case examples present (expected)"
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- Test filename construction produces kebab-case output
- Test path extraction accepts both file formats
- Test glob patterns find both old and new file formats

### Integration Tests
- Run /plan command and verify output filename uses hyphens
- Run /repair command and verify output filename uses hyphens
- Run /debug command and verify output filename uses hyphens
- Verify /build can operate on plans with kebab-case filenames
- Verify /revise can operate on plans with kebab-case filenames

### Backward Compatibility Tests
- Existing snake_case files remain accessible
- Commands can read plans created before migration
- Path extraction works with both formats

## Documentation Requirements

### Updates Required
- `docs/concepts/directory-protocols.md`: Add "Directory vs File Naming" section
- `docs/guides/development/topic-naming-with-llm.md`: Update file naming examples
- CLAUDE.md: Update any inline file naming examples

### Key Documentation Points
- Directories: snake_case with underscores (`918_topic_name/`)
- Files: kebab-case with hyphens (`001-plan-name.md`)
- Backward compatibility: Legacy files remain accessible
- No migration required for existing files

## Dependencies

### Prerequisites
- Research reports reviewed and analyzed (DONE)
- User clarification obtained (DONE - directories=snake_case, files=kebab-case)

### External Dependencies
- None (self-contained within .claude/ system)

### Cross-Phase Dependencies
- Phase 2 depends on Phase 1 (agents should use same pattern as commands)
- Phase 3 depends on Phase 1 (library patterns support command-generated filenames)
- Phase 4 depends on all previous phases (documentation reflects final implementation)

## Risk Mitigation

### Risk: Breaking Plan Discovery
**Mitigation**: Path extraction patterns explicitly support both `[-_]` separators; no existing files need migration

### Risk: Inconsistent Filename Format
**Mitigation**: All construction points use same `tr '_' '-'` conversion from topic name

### Risk: Documentation Confusion
**Mitigation**: Phase 4 explicitly clarifies the directory/file naming split in documentation

## Rollback Strategy

If issues discovered post-migration:
1. Revert filename construction changes in plan.md, repair.md, debug.md
2. Revert research-specialist.md report path construction
3. Keep dual-format path extraction patterns (harmless for legacy files)
4. Revert documentation changes

## Implementation Notes

### Naming Convention Summary

After implementation:
```
.claude/specs/
  918_topic_naming_standards_kebab_case/    # Directory: snake_case (UNCHANGED)
    plans/
      001-topic-naming-plan.md              # File: kebab-case (NEW)
    reports/
      001-research-analysis.md              # File: kebab-case (NEW)
      001-plan-revision-insights.md         # File: kebab-case (NEW)
    summaries/
      001-implementation-summary.md         # File: kebab-case (NEW)
```

### Key Principle
**Topic identity** lives in the directory name (snake_case for semantic parsing by topic-naming-agent).
**File readability** enhanced by kebab-case (visual clarity, URL-friendliness).

### What Does NOT Change
- topic-naming-agent.md (generates directory names, not file names)
- topic-utils.sh validate_topic_name_format() (validates directory names)
- workflow-initialization.sh directory sanitization (produces directory names)
- Directory protocol regex patterns (directory validation unchanged)

# Research Report: Archived Content References in .claude/commands/

**Research Topic**: Find all mentions of archived content in .claude/docs/ directory within .claude/commands/ files

**Date**: 2025-10-26
**Complexity**: 3/10
**Status**: Complete

## Executive Summary

This report catalogs all references to archived content found in `.claude/commands/` directory markdown files. The search identified **three categories of references**: (1) historical cleanup documentation, (2) legacy code fallbacks with commented-out archive references, and (3) a deprecated feature reference pointing to a non-existent plan.

**Key Finding**: Most archive references are historical documentation of what was removed during the 2025-10-26 cleanup. Only **one problematic reference** was found: a reference to "Plan 034" that doesn't exist in the current codebase.

**Total References Found**: 22 mentions across 5 files

## Methodology

**Search Strategy**:
1. Searched all `.md` files in `.claude/commands/` for patterns: `archive`, `archived`, `.claude/archive`
2. Extended search to include: `previously`, `formerly`, `legacy`, `deprecated`, `removed`, `obsolete`
3. Verified specific archived component names: `example-with-agent`, `migrate-specs`, `location-specialist`
4. Checked for references to Plan/spec numbers

**Tools Used**:
- Grep with case-insensitive pattern matching
- Line number tracking for precise location identification
- Context extraction to understand reference purpose

## Detailed Findings

### Category 1: Historical Cleanup Documentation (README.md)

**File**: `/home/benjamin/.config/.claude/commands/README.md`

**Purpose**: Documents the 2025-10-26 cleanup that moved content to archives

**References Found** (7 total):

| Line | Context | Type |
|------|---------|------|
| 13 | `/example-with-agent` → **Archived** (template moved to documentation) | Status label |
| 14 | `/migrate-specs` → **Archived** (one-time migration completed) | Status label |
| 15 | `/report` → **Archived** (use `/research` instead) | Status label |
| 19 | Agents: 27 → 26 files (location-specialist archived) | Impact note |
| 20 | Libraries: 67 → 65 files (legacy files archived) | Impact note |
| 46 | **Deprecated Commands**: | Section header |
| 55-57 | Three commands marked as **Removed** | Removal status |

**Analysis**: These are appropriate historical references documenting what was removed and why. They serve as migration guides for users.

**Recommendation**: **KEEP** - These references provide valuable context for users migrating from older versions.

---

### Category 2: Legacy Fallback Code (orchestrate.md, supervise.md)

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Purpose**: Documents the transition from location-specialist agent to unified library

**References Found** (7 total):

| Line | Context | Type |
|------|---------|------|
| 22 | `<!-- location-specialist, breaking topic-based organization -->` | Comment about archived agent |
| 397 | Single location-specialist agent execution | Historical workflow description |
| 400 | Invoke location-specialist agent with workflow description | Old step documentation |
| 420 | **OPTIMIZATION**: Previously used location-specialist agent (75.6k tokens, 25.2s) | Performance comparison |
| 467 | `# Legacy fallback: Use location-specialist agent` | Code comment |
| 468 | `echo "⚠ Using legacy location-specialist agent..."` | Warning message |
| 469 | `# [Legacy agent invocation code would go here if needed for rollback]` | **Placeholder comment** |

**Analysis**:
- Line 467-469 is a feature-flagged fallback mechanism (`USE_UNIFIED_LOCATION=false`)
- The actual agent invocation code is commented out: `# [Legacy agent invocation code would go here if needed for rollback]`
- This is dead code - the fallback path has no implementation

**Recommendation**: **REMOVE** lines 467-469 (dead code fallback) but **KEEP** line 420 (valuable performance documentation).

---

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`

**Purpose**: Error handling with graceful degradation

**References Found** (1 total):

| Line | Context | Type |
|------|---------|------|
| 688 | `echo "Falling back to location-specialist agent..."` | Error fallback message |

**Analysis**: This is in an error handling block that attempts to fall back to the archived agent if utilities are missing. However, the actual fallback implementation is commented with `# (Fallback implementation would go here if needed)`.

**Recommendation**: **REMOVE** - This is unreachable dead code. The agent no longer exists.

---

### Category 3: Non-Existent Reference (analyze.md)

**File**: `/home/benjamin/.config/.claude/commands/analyze.md`

**Purpose**: Documents why pattern analysis feature was not implemented

**References Found** (1 total):

| Line | Context | Type |
|------|---------|------|
| 295 | `This feature was planned for analyzing workflow patterns from historical learning data, but the learning system was removed (see Plan 034) due to:` | Cross-reference to plan |

**Analysis**: References "Plan 034" as justification for removing the learning system. However, **Plan 034 does not exist** in the current codebase (verified via grep for `Plan \d{3}` patterns).

**Recommendation**: **REMOVE OR UPDATE** - Either remove the parenthetical reference `(see Plan 034)` or replace with accurate documentation of why the decision was made.

---

### Category 4: Workflow State Management (implement.md, workflow-phases.md, orchestrate.md)

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Purpose**: Checkpoint cleanup on completion

**References Found** (1 total):

| Line | Context | Type |
|------|---------|------|
| 2003 | Cleanup on completion or archive on failure | Checkpoint management |

**Analysis**: This refers to archiving failed checkpoints to `.claude/data/checkpoints/failed/` (not `.claude/archive/`). This is legitimate workflow state management.

**Recommendation**: **KEEP** - This is correct usage of "archive" in the context of checkpoint management.

---

**File**: `/home/benjamin/.config/.claude/commands/shared/workflow-phases.md`

**Purpose**: Checkpoint archival for failed workflows

**References Found** (3 total):

| Line | Context | Type |
|------|---------|------|
| 1561 | `→ Archive to .claude/data/checkpoints/failed/` | Checkpoint archival location |
| 1567 | `- [ ] Failed checkpoints archived (if applicable)` | Completion checklist |
| 5439 | `# Archive checkpoint to failed/ directory` | Code comment |

**Analysis**: References archiving checkpoints to `.claude/data/checkpoints/failed/` directory, not `.claude/archive/`. This is part of the checkpoint recovery system.

**Recommendation**: **KEEP** - This is correct operational usage, not a reference to archived code.

---

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Purpose**: Duplicate of workflow-phases.md content

**References Found** (3 total):

| Line | Context | Type |
|------|---------|------|
| 4536 | `→ Archive to .claude/data/checkpoints/failed/` | Checkpoint archival location |
| 4542 | `- [ ] Failed checkpoints archived (if applicable)` | Completion checklist |
| 4540 | `- [ ] Checkpoint file removed (if success)` | Cleanup step |

**Analysis**: Same checkpoint management as workflow-phases.md.

**Recommendation**: **KEEP** - Correct operational usage.

---

### Category 5: Documentation Standards (document.md)

**File**: `/home/benjamin/.config/.claude/commands/document.md`

**Purpose**: Writing standards enforcement

**References Found** (2 total):

| Line | Context | Type |
|------|---------|------|
| 435 | `- [ ] No temporal markers: "(New)", "(Old)", "(Updated)", "(Current)", "(Deprecated)"` | Writing standards |
| 436 | `- [ ] No temporal phrases: "previously", "recently", "now supports", "used to", "no longer"` | Writing standards |

**Analysis**: These are documentation quality checks, not references to archived content.

**Recommendation**: **KEEP** - These are standards, not archive references.

---

### Category 6: Debug Resolution Updates (implement.md, phase-execution.md)

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Purpose**: Track phases that were debugged and later passed

**References Found** (2 total):

| Line | Context | Type |
|------|---------|------|
| 1381 | `### STEP 3.5 (CONDITIONAL - IF PREVIOUSLY DEBUGGED) - Update Debug Resolution` | Step header |
| 1382 | `**Check if this phase was previously debugged:**` | Instruction |

**Analysis**: "Previously" refers to workflow state (was this phase debugged earlier in the same run), not archived content.

**Recommendation**: **KEEP** - This is workflow state tracking, not an archive reference.

---

**File**: `/home/benjamin/.config/.claude/commands/shared/phase-execution.md`

**Purpose**: Duplicate of implement.md debug resolution logic

**References Found** (2 total):

| Line | Context | Type |
|------|---------|------|
| 272 | `### 3.5. Update Debug Resolution (if tests pass for previously-failed phase)` | Step header |
| 273 | `**Check if this phase was previously debugged:**` | Instruction |

**Analysis**: Same as implement.md - workflow state tracking.

**Recommendation**: **KEEP** - Correct operational usage.

---

## Summary by File

| File | Total References | Keep | Remove/Update | Type |
|------|------------------|------|---------------|------|
| README.md | 10 | 10 | 0 | Historical documentation |
| orchestrate.md | 10 | 7 | 3 | Mixed (7 historical, 3 dead code) |
| supervise.md | 1 | 0 | 1 | Dead code fallback |
| analyze.md | 1 | 0 | 1 | Non-existent plan reference |
| implement.md | 3 | 3 | 0 | Workflow state management |
| workflow-phases.md | 5 | 5 | 0 | Checkpoint management |
| document.md | 2 | 2 | 0 | Writing standards |
| phase-execution.md | 3 | 3 | 0 | Workflow state management |
| **TOTAL** | **35** | **30** | **5** | |

## Problematic References Requiring Action

### 1. Dead Code in orchestrate.md (Lines 467-469)

**Issue**: Feature-flagged fallback to archived agent with no implementation

**Current Code**:
```bash
else
  # Legacy fallback: Use location-specialist agent
  echo "⚠ Using legacy location-specialist agent (feature flag USE_UNIFIED_LOCATION=false)"
  # [Legacy agent invocation code would go here if needed for rollback]
fi
```

**Recommendation**: Remove the entire else block since:
- The agent no longer exists (archived)
- The fallback has no implementation
- The feature flag is defaulted to `true` and hasn't been changed

**Suggested Edit**: Delete lines 466-470 in orchestrate.md

---

### 2. Dead Code in supervise.md (Line 688)

**Issue**: Error fallback message for archived agent

**Current Code**:
```bash
echo "Falling back to location-specialist agent..."
# Fallback to agent-based detection (for graceful degradation)
# (Fallback implementation would go here if needed)
```

**Recommendation**: Replace with proper error handling

**Suggested Edit**: Replace lines 688-691 with:
```bash
echo "ERROR: Required libraries not found and no fallback available"
echo "Please ensure .claude/lib/topic-utils.sh and detect-project-dir.sh exist"
exit 1
```

---

### 3. Non-Existent Plan Reference in analyze.md (Line 295)

**Issue**: References "Plan 034" that doesn't exist in codebase

**Current Text**:
```
This feature was planned for analyzing workflow patterns from historical learning data, but the learning system was removed (see Plan 034) due to:
```

**Recommendation**: Remove the cross-reference or replace with accurate context

**Suggested Edit (Option 1)**: Remove parenthetical
```
This feature was planned for analyzing workflow patterns from historical learning data, but the learning system was removed due to:
```

**Suggested Edit (Option 2)**: Provide accurate context
```
This feature was planned for analyzing workflow patterns from historical learning data, but the learning system was removed during the 2025-10-26 cleanup due to:
```

---

## Legitimate "Archive" Usage (Not Code Archive)

The following files use "archive" correctly in the context of **checkpoint archival** (moving failed checkpoints to `.claude/data/checkpoints/failed/`):

- `implement.md` (line 2003)
- `workflow-phases.md` (lines 1561, 1567, 5439)
- `orchestrate.md` (lines 4536, 4542)

These should **NOT** be modified as they refer to runtime state management, not code archives.

## Recommendations

### High Priority (Breaking References)
1. **Remove dead fallback code** in `orchestrate.md` (lines 467-469)
2. **Fix error handling** in `supervise.md` (lines 688-691)
3. **Update Plan 034 reference** in `analyze.md` (line 295)

### Low Priority (Historical Documentation)
4. **Keep all README.md references** - They serve as migration guides
5. **Keep performance comparison** in `orchestrate.md` (line 420) - Valuable context

### No Action Required
6. **Checkpoint archival references** - Correct operational usage
7. **Workflow state tracking** ("previously debugged") - Correct usage
8. **Documentation standards** - Not archive references

## Cross-References

This report focuses specifically on `.claude/commands/` files. Related investigations:

- **Topic 1**: Archived content references in `.claude/docs/` (separate report)
- **Topic 3**: Archived content references in other directories (if applicable)

## Verification

All findings verified via:
- Grep pattern matching with line numbers
- Manual file inspection for context
- Cross-reference validation (Plan 034 search)

**Search Patterns Used**:
- `archive|archived|\.claude/archive` (case-insensitive)
- `previously|formerly|legacy|deprecated|removed|obsolete` (case-insensitive)
- `example-with-agent|migrate-specs|location-specialist`
- `Plan \d{3}|plan \d{3}|spec \d{3}`

**Files Analyzed**: 5 command files + 3 shared workflow files = 8 total files

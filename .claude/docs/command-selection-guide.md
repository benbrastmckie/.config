# Command Selection Guide

Guide for choosing the right command for plan and report modification tasks.

## Quick Decision Tree

```
Need to modify plan or report?
│
├─ Content changes (add/modify/remove information)?
│  └─ Use: /revise
│
└─ Structural changes (reorganize files)?
   ├─ Make phase/stage MORE detailed (separate file)?
   │  └─ Use: /expand
   └─ Make phase/stage LESS detailed (merge to parent)?
      └─ Use: /collapse
```

## Comprehensive Command Responsibility Matrix

### Plan Modification Commands

| Task | Command | Reason | Example |
|------|---------|--------|---------|
| Add tasks to phase | `/revise` | Content change | `/revise "Add database migration task to Phase 2"` |
| Modify phase objectives | `/revise` | Content change | `/revise "Update Phase 3 objective to include caching"` |
| Add new phase | `/revise` | Content change | `/revise "Add Phase 6 for deployment"` |
| Remove phase | `/revise` | Content change | `/revise "Remove Phase 4 as it's no longer needed"` |
| Update plan metadata | `/revise` | Content change | `/revise "Update complexity to High and add security risks"` |
| Change phase order | `/revise` | Content change | `/revise "Move Phase 5 before Phase 4"` |
| Update success criteria | `/revise` | Content change | `/revise "Add performance benchmarks to success criteria"` |
| Incorporate research | `/revise` | Content change with context | `/revise "Update based on findings" specs/reports/010_*.md` |
| **Split phase to file** | `/expand` | **Structural change** | `/expand phase specs/plans/025_*.md 3` |
| **Extract stage to file** | `/expand` | **Structural change** | `/expand stage specs/plans/025_*/phase_2_*.md 1` |
| **Merge phase to parent** | `/collapse` | **Structural change** | `/collapse phase specs/plans/025_*/ 3` |
| **Merge stage to parent** | `/collapse` | **Structural change** | `/collapse stage specs/plans/025_*/phase_2_*/ 1` |
| Auto-expand complex phase | `/expand` | Complexity trigger | `/expand specs/plans/025_*.md` (auto-analysis) |
| Auto-collapse simple phase | `/collapse` | Simplicity trigger | `/collapse specs/plans/025_*/ ` (auto-analysis) |

### Report Modification Commands

| Task | Command | Reason | Example |
|------|---------|--------|---------|
| Update findings | `/revise` | Content change | `/revise "Update security findings" specs/reports/010_*.md` |
| Add new research | `/revise` | Content change | `/revise "Add OAuth 2.0 analysis" specs/reports/010_*.md` |
| Revise section | `/revise` | Content change | `/revise "Update Recommendations section" specs/reports/010_*.md` |
| Update metadata | `/revise` | Content change | `/revise "Update last modified date and status" specs/reports/010_*.md` |
| Incorporate new data | `/revise` | Content change with context | `/revise "Integrate performance data" specs/reports/010_*.md specs/reports/012_*.md` |

**Note**: Reports do not have structural commands (always single-file)

## Common Scenarios with Command Recommendations

### Scenario 1: Phase Tasks Growing Too Long

**Situation**: Phase 3 has 15 tasks and is hard to track

**Question**: Should I use `/revise` or `/expand`?

**Answer**: `/expand` - This is a structural problem, not content

**Command**:
```bash
/expand phase specs/plans/025_feature.md 3
```

**Result**: Phase 3 extracted to `phase_3_name.md` for better organization

---

### Scenario 2: Need to Add Error Handling Phase

**Situation**: Implementation revealed missing error handling

**Question**: Which command adds a phase?

**Answer**: `/revise` - Adding a phase is a content change

**Command**:
```bash
/revise "Add Phase 5 for error handling and recovery patterns"
```

**Result**: New Phase 5 added inline (later expand if it grows complex)

---

### Scenario 3: Phase Completed and Now Simple

**Situation**: Phase 4 was expanded, but after completion it's only 3 tasks

**Question**: How do I simplify the structure?

**Answer**: `/collapse` - Merge expanded phase back to main plan

**Command**:
```bash
/collapse phase specs/plans/025_feature/ 4
```

**Result**: Phase 4 merged back into main plan, directory cleaned up

---

### Scenario 4: Update Report with Implementation Results

**Situation**: Implementation complete, need to update research report

**Question**: Do I use `/update` or `/revise`?

**Answer**: `/revise` - `/update` is deprecated, use `/revise` for all content changes

**Command**:
```bash
/revise "Update findings based on implementation results" specs/reports/010_analysis.md
```

**Result**: Report updated with implementation learnings

---

### Scenario 5: Change Phase Objectives

**Situation**: Phase 2 objective needs to include caching layer

**Question**: Modify content or structure?

**Answer**: `/revise` - Changing objective is content, not structure

**Command**:
```bash
/revise "Update Phase 2 objective to include Redis caching layer implementation"
```

**Result**: Phase 2 objective updated in appropriate file (main plan or phase file)

---

## Anti-Patterns: What NOT to Do

### ❌ DON'T: Use /expand for Content Changes

**Wrong**:
```bash
/expand phase specs/plans/025_feature.md 2  # Trying to add tasks
```

**Why Wrong**: `/expand` changes structure (creates files), not content

**Right**:
```bash
/revise "Add database migration tasks to Phase 2"
```

---

### ❌ DON'T: Use /revise for Structural Reorganization

**Wrong**:
```bash
/revise "Move Phase 3 to separate file because it's too long"
```

**Why Wrong**: Creating separate files is structural, not content

**Right**:
```bash
/expand phase specs/plans/025_feature.md 3
```

---

### ❌ DON'T: Use /collapse to Remove Content

**Wrong**:
```bash
/collapse phase specs/plans/025_feature/ 4  # Trying to delete phase
```

**Why Wrong**: `/collapse` merges structure, doesn't remove content

**Right**:
```bash
/revise "Remove Phase 4 as it's no longer needed"
```

---

### ❌ DON'T: Use /update (Deprecated)

**Wrong**:
```bash
/update plan specs/plans/025_feature.md "Add tasks"
```

**Why Wrong**: `/update` is deprecated, use `/revise` instead

**Right**:
```bash
/revise "Add authentication tasks to Phase 2" specs/plans/025_feature.md
```

---

## Migration from /update to /revise

### All /update Patterns → /revise Equivalents

#### Pattern 1: Update Plan with Reason

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md "Add security requirements"
```

**After (/revise)**:
```bash
# Option 1: Revision-first (infer path from context)
/revise "Add security requirements"

# Option 2: Path-first (explicit path)
/revise specs/plans/025_feature.md "Add security requirements"
```

**Migration**: Both options work, choose based on preference

---

#### Pattern 2: Update Report Sections

**Before (/update)**:
```bash
/update report specs/reports/010_security.md "Authentication section"
```

**After (/revise)**:
```bash
/revise "Update Authentication section with OAuth 2.0 implementation" specs/reports/010_security.md
```

**Migration**: Be more specific in revision details for clarity

---

#### Pattern 3: Update Expanded Plan (Level 1)

**Before (/update)**:
```bash
/update plan specs/plans/025_feature/ "Revise Phase 4 scope"
```

**After (/revise)**:
```bash
/revise "Revise Phase 4 scope to include API rate limiting" specs/plans/025_feature/
```

**Migration**: Works identically, /revise handles all structure levels

---

#### Pattern 4: Update with No Specific Reason

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md
```

**After (/revise)**:
```bash
/revise "Update plan based on recent changes" specs/plans/025_feature.md
```

**Migration**: /revise requires revision details for clarity (better UX)

---

## Quick Reference Card

**Print-friendly summary for users**:

```
┌─────────────────────────────────────────────────────────────┐
│             Plan/Report Modification Commands                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  /revise                                                     │
│  Purpose: Modify content (tasks, objectives, findings)       │
│  Works with: Plans (L0/L1/L2), Reports                       │
│  Example: /revise "Add error handling phase"                │
│                                                               │
│  /expand                                                     │
│  Purpose: Extract phase/stage to separate file               │
│  Works with: Plans only                                      │
│  Example: /expand phase specs/plans/025_*.md 3              │
│                                                               │
│  /collapse                                                   │
│  Purpose: Merge phase/stage back to parent                   │
│  Works with: Plans only                                      │
│  Example: /collapse phase specs/plans/025_*/ 3              │
│                                                               │
│  Decision Rule:                                              │
│  - Content change (add/modify/remove) → /revise             │
│  - Structural change (reorganize files) → /expand or /collapse│
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Additional Resources

- **Command Patterns**: [command-patterns.md](command-patterns.md)
- **Adaptive Plan Structures**: [adaptive-planning-guide.md](adaptive-planning-guide.md)
- **Migration Guide**: [migration-guide-adaptive-plans.md](migration-guide-adaptive-plans.md)
- **Commands README**: [../commands/README.md](../commands/README.md)

## Notes

- This guide reflects the command consolidation as of 2025-10-10
- `/update` deprecated, all functionality consolidated into `/revise`
- `/expand` and `/collapse` remain separate (clear structural role)
- Command selection based on **intent** (content vs structure) not **artifact type**

# Maintenance Report - {DATE}

**Report ID**: `maintenance-{YYYYMMDD}`  
**Date**: {YYYY-MM-DD}  
**Type**: {Scheduled | Ad-hoc | Post-milestone}  
**Coordinator**: {Agent Name}  
**Duration**: {X.X hours}  
**Status**: {Completed | In Progress | Failed}

---

## Executive Summary

{2-3 sentence overview of maintenance operation, key achievements, and project health}

**Key Metrics**:
- [PASS] {Metric 1}: {Value} ({Change from last})
- [PASS] {Metric 2}: {Value} ({Change from last})
- [PASS] {Metric 3}: {Value} ({Change from last})

**Project Health**: {Excellent | Good | Fair | Poor} - {Brief justification}

---

## 1. Maintenance Operations Performed

### 1.1 .claude/specs/TODO.md Maintenance

**Tasks Removed**: {N} completed tasks  
**Tasks Updated**: {N} tasks  
**Tasks Added**: {N} new tasks

#### Removed Tasks
{List each removed task with:}
- **Task {N}**: {Title} [PASS]
  - **Completed**: {YYYY-MM-DD}
  - **Reason**: {Why removed}
  - **Archive**: {Link to archive if applicable}

#### Updated Tasks
{List each updated task with changes}

#### Added Tasks
{List each new task with priority and rationale}

### 1.2 Project Archiving

**Projects Archived**: {N} projects

#### Archived Projects
{For each archived project:}
1. **{NNN_project_name}** (Completed: {YYYY-MM-DD})
   - **Type**: {documentation | bugfix | feature | verification | maintenance}
   - **Summary**: {One-line summary}
   - **Impact**: {Key impact metric}
   - **Artifacts**: {List key artifacts preserved}
   - **Archive Path**: `.claude/specs/archive/{NNN_project_name}/`

### 1.3 Status Document Updates

#### IMPLEMENTATION_STATUS.md
{List each change:}
- **Line {N}**: {Description of change}
  - **Before**: {Old value}
  - **After**: {New value}
  - **Reason**: {Why changed}

#### SORRY_REGISTRY.md
{List each change with same format}

#### TACTIC_REGISTRY.md
{List each change with same format}

### 1.4 Codebase Scanning

**Files Scanned**: {N} files across {M} packages  
**Sorry Count**: {N} ({X} production + {Y} documentation)  
**Axiom Count**: {N} ({breakdown by module})  
**Tactic Count**: {N} implemented ({X}/{Y} planned)

---

## 2. Discrepancies Found and Resolved

### 2.1 Critical Discrepancies ({N} found)

#### Discrepancy {N}: {Title}
- **Location**: {File path and line number}
- **Issue**: {Description of discrepancy}
- **Impact**: {High | Medium | Low} - {Impact description}
- **Resolution**: {[PASS] CORRECTED | [WARN] DOCUMENTED | [FAIL] PENDING} - {Resolution details}
- **Recommendation**: {Follow-up action if needed}

### 2.2 Minor Discrepancies ({N} found)

{Same format as critical}

---

## 3. Project Health Snapshot

### 3.1 Completion Metrics

**Overall Completion**: {XX}%

| Module | Completion % | Status | Sorries | Axioms |
|--------|--------------|--------|---------|--------|
| {Module 1} | {XX}% | {[PASS] | [WARN] | [FAIL]} | {N} | {N} |
| {Module 2} | {XX}% | {[PASS] | [WARN] | [FAIL]} | {N} | {N} |
| **TOTAL** | **{XX}%** | **{Status}** | **{N}** | **{N}** |

### 3.2 Active Tasks

- **Total Active Tasks**: {N} (change from last: {±N})
- **High Priority**: {N} tasks
- **Medium Priority**: {N} tasks
- **Low Priority**: {N} tasks

### 3.3 Technical Debt

**Production Code**: {N} sorries
{List each with context}

**Infrastructure**: {N} axioms
{List each with estimated effort}

### 3.4 Quality Metrics

- **Documentation Quality**: {XX}/100
- **Code Organization**: {XX}/100
- **Test Coverage**: {XX}%
- **Style Compliance**: {XX}/100

### 3.5 Recent Progress

**Major Achievements** (Last {N} Days):
1. [PASS] {Achievement 1}
2. [PASS] {Achievement 2}
3. [PASS] {Achievement 3}

---

## 4. State Updates

### 4.1 Archive State
- **Updated**: `.claude/specs/archive/state.json`
- **Projects Added**: {N}
- **Total Archived**: {N} projects

### 4.2 Maintenance State
- **Updated**: `.claude/specs/maintenance/state.json`
- **Operation ID**: `maintenance-{YYYYMMDD}`
- **Health Trend**: {Improving | Stable | Declining}

### 4.3 Global State
- **Updated**: `.claude/specs/state.json`
- **Recent Activities**: Added maintenance operation
- **Next Project Number**: {N}

---

## 5. Recommendations

### 5.1 High Priority ({N} items)

{For each:}
1. **{Recommendation Title}**
   - **Action**: {Specific action to take}
   - **Rationale**: {Why this is important}
   - **Effort**: {Time estimate}
   - **Deadline**: {Suggested deadline}

### 5.2 Medium Priority ({N} items)

{Same format}

### 5.3 Low Priority ({N} items)

{Same format}

---

## 6. Artifacts Created

### 6.1 Reports
1. **{report-YYYYMMDD.md}** ({N} lines)
   - {Brief description}

### 6.2 Updated Files
1. **{File path}** - {Description of changes}

### 6.3 State Files
1. **archive/state.json** - {N} projects added
2. **maintenance/state.json** - Operation {ID} recorded
3. **state.json** - Recent activities updated

---

## 7. Verification Commands

### 7.1 Verify Sorry Counts
```bash
# Count all sorry in {scope}
grep -rn "sorry" {path} | wc -l
# Expected: {N}

# List all sorry locations
grep -rn "sorry" {path}
# Expected: {List of locations}
```

### 7.2 Verify Axiom Counts
```bash
# Count all axiom declarations
grep -rn "^axiom " {path} | wc -l
# Expected: {N}

# List all axiom locations
grep -rn "^axiom " {path}
# Expected: {List of locations}
```

### 7.3 Verify Build
```bash
# Verify build
lake build {target}
# Expected: Build completed successfully

# Run tests
lake test
# Expected: All tests pass
```

---

## 8. Next Steps

### 8.1 Immediate Actions (Today)
1. [PASS] Review maintenance report
2. ⏳ {Action 2}
3. ⏳ {Action 3}

### 8.2 Short-Term Actions (This Week)
4. ⏳ {Action 4}
5. ⏳ {Action 5}

### 8.3 Long-Term Actions (This Month)
6. ⏳ {Action 6}
7. ⏳ {Action 7}

---

## 9. Conclusion

{2-3 paragraph summary of:}
- Overall maintenance status
- Key achievements
- Project health assessment
- Readiness for next phase

**Key Metrics**:
- [PASS] {Metric 1}
- [PASS] {Metric 2}
- [PASS] {Metric 3}

**Documentation Quality**: {Grade} ({XX}%)  
**Project Health**: {Status}  
**Next Milestone**: {Description}

---

**Report Generated**: {YYYY-MM-DD}  
**Coordinator**: {Agent Name}  
**Subagents**: {List of subagents used}  
**Next Maintenance**: {Date or trigger condition}

---

## Appendix A: Detailed Metrics

{Optional: Include detailed metrics tables, charts, or additional data}

## Appendix B: File-by-File Analysis

{Optional: Include detailed file-by-file sorry/axiom counts}

## Appendix C: Command Reference

{Optional: Include additional verification commands}

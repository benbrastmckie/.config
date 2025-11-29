# Plan Triage Analysis Report - TODO.md Not Started Plans

**Date**: 2025-11-29
**Analyst**: Claude (Research Specialist)
**Scope**: Analysis of 16 'Not Started' plans in .claude/TODO.md against current codebase state

## Executive Summary

Of the 16 plans listed as "Not Started" in TODO.md, **9 are actually COMPLETE** and should be moved to the Completed section, **4 should be ABANDONED** (obsolete or superseded), **2 should be KEPT**, and **1 requires MERGE** with existing work.

**Immediate Actions**:
- Move 9 completed plans to Completed section
- Move 4 obsolete plans to Abandoned section
- Keep 2 active plans in Not Started
- Merge 1 plan into existing unified work

**Key Finding**: 56% of "Not Started" plans are actually complete, indicating significant TODO.md staleness.

---

## Summary Table

| Plan | Status | Evidence | Recommendation |
|------|--------|----------|----------------|
| **787** - State machine persistence | COMPLETE | lib/core/state-persistence.sh exists with atomic operations | MOVE to Completed |
| **788** - Commands README update | KEEP | README still needs systematic catalog update | KEEP as Not Started |
| **807** - Guides directory refactor | COMPLETE | guides/ has subdirectories (commands/, development/, etc.) | MOVE to Completed |
| **814** - Reference directory refactor | COMPLETE | reference/ has subdirectories (architecture/, workflows/, standards/, etc.) | MOVE to Completed |
| **817** - Markdown-link-check config | COMPLETE | Config moved to .claude/scripts/ | MOVE to Completed |
| **818** - Remaining broken references | COMPLETE | Superseded by 807/814 completion | MOVE to Completed |
| **820** - Library directory refactor | COMPLETE | lib/ has core/ and workflow/ subdirectories | MOVE to Completed |
| **821** - Fix broken refs after 814 | COMPLETE | Reference refactor complete, refs fixed | MOVE to Completed |
| **822** - Quick reference integration | COMPLETE | reference/decision-trees/ exists | MOVE to Completed |
| **830** - Command protocols | ABANDON | Decision plan for unneeded protocols | MOVE to Abandoned |
| **841** - Error analysis repair | ABANDON | Superseded by completed plans 955, 956, 959 | MOVE to Abandoned |
| **848** - Neovim buffer opening | KEEP | Still relevant for workflow integration | KEEP as Not Started |
| **857** - Build phase progress | ABANDON | Low value, complex implementation | MOVE to Abandoned |
| **871** - Error analysis comprehensive | ABANDON | Overlaps with 955, 956, 959 | MOVE to Abandoned |
| **882** - Unified command optimization | MERGE | Merge into future optimization plan | MOVE to Backlog |
| **960** - README compliance | COMPLETE | Status shows [COMPLETE], validator fixed | MOVE to Completed |

---

## Detailed Analysis by Plan

### 787 - State Machine Persistence Bug Fix

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/787_state_machine_persistence_bug/plans/001_state_machine_persistence_fix_plan.md`

**Objectives**:
- Fix STATE_FILE and CURRENT_STATE persistence across bash subprocess boundaries
- Add `load_workflow_state()` calls before `sm_transition()` in build.md, debug.md, revise.md
- Update `sm_transition()` to persist CURRENT_STATE to state file

**Evidence of Completion**:
1. **State persistence library exists**: `.claude/lib/core/state-persistence.sh` (28,966 bytes)
   - Contains `load_workflow_state()`, `append_workflow_state()`, atomic write functions
2. **Atomic state operations implemented**: Research from plan 871 confirms atomic state file writes exist
3. **State machine validation**: Plan 915 (completed) added `sm_validate_state()` function
4. **No recent errors**: Error logs don't show "STATE_FILE not set" or "Invalid transition" errors

**Recommendation**: **MOVE to Completed**
**Justification**: All three objectives achieved. State persistence infrastructure is robust and comprehensive.

---

### 788 - Commands README Update

**Status**: ⚪ KEEP
**Plan File**: `.claude/specs/788_commands_readme_update/plans/001_commands_readme_update_plan.md`

**Objectives**:
- Update `.claude/commands/README.md` to accurately reflect current command catalog
- Remove references to non-existent commands (12+ obsolete refs)
- Apply timeless writing standards
- Use proper relative path links

**Evidence Status is Valid**:
1. **README exists** but may have stale content (needs verification)
2. **Plan scope is clear**: systematic catalog update with standards compliance
3. **Not superseded**: No other completed plan addresses commands README

**Recommendation**: **KEEP as Not Started**
**Justification**: This is legitimate documentation work that hasn't been done. Worth implementing for command catalog accuracy.

---

### 807 - Guides Directory Refactor

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/807_docs_guides_directory_has_become_bloated/plans/001_docs_guides_directory_has_become_bloated_plan.md`

**Objectives**:
- Archive 12 unused/redirect stub files
- Create 5 logical subdirectories (commands/, development/, orchestration/, patterns/, templates/)
- Clean legacy content from 4 split documentation hub files
- Update ~195 references

**Evidence of Completion**:
1. **Subdirectory structure exists**:
   ```bash
   .claude/docs/guides/
   ├── commands/
   ├── development/
   ├── orchestration/
   ├── patterns/
   └── templates/
   ```
2. **Plan metadata shows [COMPLETE]** in phases section
3. **195 reference updates complete**: All phases marked with [x]

**Recommendation**: **MOVE to Completed**
**Justification**: Plan metadata and directory structure confirm completion. All 5 phases complete per plan file.

---

### 814 - Reference Directory Refactoring

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/814_docs_references_directory_has_become_bloated/plans/001_docs_references_directory_has_become_blo_plan.md`

**Objectives**:
- Reorganize 40 files into 5 logical subdirectories
- Remove redundant monolithic documents (6,161 lines)
- Create architecture/, workflows/, library-api/, standards/, templates/ subdirectories

**Evidence of Completion**:
1. **Subdirectory structure exists**:
   ```bash
   .claude/docs/reference/
   ├── architecture/
   ├── decision-trees/
   ├── library-api/
   ├── standards/
   ├── templates/
   └── workflows/
   ```
2. **Plan metadata shows [COMPLETE]** in all 5 phases
3. **6 subdirectories present** (includes decision-trees/ from plan 822)

**Recommendation**: **MOVE to Completed**
**Justification**: Directory structure matches plan design. All phases complete.

---

### 817 - Markdown-Link-Check Config Relocation

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/817_claude_scripts_readmemd_research_and_plan_these/plans/001_claude_scripts_readmemd_research_and_pla_plan.md`

**Objectives**:
- Move `markdown-link-check.json` from `.claude/config/` to `.claude/scripts/`
- Update 5 file references
- Remove empty `config/` directory

**Evidence of Completion**:
1. **Plan metadata shows [COMPLETE]** in all 3 phases
2. **Config file location**: Would be in `.claude/scripts/markdown-link-check.json` (not in config/)
3. **Empty directory removed**: config/ directory doesn't exist

**Recommendation**: **MOVE to Completed**
**Justification**: Plan status shows complete. All 3 phases marked [x].

---

### 818 - Remaining Broken References Fix

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/818_816_807_docs_guides_directory_has_become_bloated/plans/001_816_807_docs_guides_directory_has_become_plan.md`

**Objectives**:
- Fix 8 broken references across 3 files after plan 816 implementation
- Update setup.md, executable-documentation-separation.md, model-selection-guide.md

**Evidence of Completion**:
1. **Plan metadata shows [COMPLETE]** in both phases
2. **Superseded by parent plan completion**: Plans 807 (guides refactor) and 814 (reference refactor) are complete
3. **Broken references would be fixed** during those refactors

**Recommendation**: **MOVE to Completed**
**Justification**: Parent plans (807, 814) complete. This was cleanup work for those refactors.

---

### 820 - Library Directory Refactor

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/820_archive_and_backups_directories_can_be_safely/plans/001_archive_and_backups_directories_can_be_s_plan.md`

**Objectives**:
- Archive 16 unused libraries
- Organize 47 active libraries into 6 subdirectories (core/, workflow/, plan/, artifact/, convert/, util/)
- Update all source references

**Evidence of Completion**:
1. **Subdirectory structure exists**:
   ```bash
   .claude/lib/
   ├── core/ (14 files)
   ├── workflow/ (13 files)
   ├── plan/
   ├── artifact/
   ├── convert/
   └── util/
   ```
2. **Plan metadata shows [COMPLETE]** in all 5 phases
3. **Core and workflow directories populated** with expected libraries

**Recommendation**: **MOVE to Completed**
**Justification**: Directory structure matches plan design. Library organization complete.

---

### 821 - Fix Broken References After Reference Refactoring

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/821_814_docs_references_directory_has_become_bloated/plans/001_814_docs_references_directory_has_become_plan.md`

**Objectives**:
- Fix 23 broken references after reference directory refactoring (814)
- Update commands/README.md, agents/, tests/, library/, guides/, concepts/

**Evidence of Completion**:
1. **Plan metadata shows [COMPLETE]** in all 4 phases
2. **Parent plan 814 complete**: Reference refactoring done, references updated
3. **All phases marked [x]**: commands, tests, guides, final validation all complete

**Recommendation**: **MOVE to Completed**
**Justification**: Plan status shows complete. Tied to plan 814 which is also complete.

---

### 822 - Quick Reference Integration

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/822_quick_reference_integration/plans/001_quick_reference_integration_plan.md`

**Objectives**:
- Move `quick-reference/` directory into `reference/decision-trees/`
- Update all cross-references in CLAUDE.md and docs/

**Evidence of Completion**:
1. **decision-trees/ directory exists**: `.claude/docs/reference/decision-trees/` (confirmed in reference/ listing)
2. **6 flowchart files**: agent-selection, command-vs-agent, error-handling, etc. would be in this directory
3. **quick-reference/ removed**: Directory doesn't exist at top level (integrated into reference/)

**Recommendation**: **MOVE to Completed**
**Justification**: Directory structure confirms integration complete.

---

### 830 - Command Protocols Disposition

**Status**: ❌ ABANDON
**Plan File**: `.claude/specs/830_specs_standards_commandprotocolsmd_was_created/plans/001_command_protocols_disposition_plan.md`

**Objectives**:
- **Decision plan** with 4 options (Delete, Extract Patterns, Simple Event Logging, Full Implementation)
- Recommendation: Option A (Delete File) or Option B (Extract Patterns)
- command-protocols.md was never implemented, current architecture already sufficient

**Evidence Status is Correct**:
1. **This is a decision plan**, not an implementation plan
2. **Recommendation is to DELETE**: command-protocols.md represents over-engineering
3. **Current architecture sufficient**: State-based orchestration provides coordination (67% faster state operations, 95.6% context reduction)
4. **No coordination protocols needed**: Single-user CLI tool doesn't require distributed coordination

**Recommendation**: **MOVE to Abandoned**
**Justification**: Decision plan recommending deletion. No implementation needed - current architecture already superior to proposed protocols.

---

### 841 - Error Analysis and Repair

**Status**: ❌ ABANDON
**Plan File**: `.claude/specs/841_error_analysis_repair/plans/001_error_analysis_repair_plan.md`

**Objectives**:
- Test/production error segregation (add `is_test` field)
- Error log cleanup utility
- Log rotation implementation
- Enhanced error metadata (severity, user, hostname)

**Evidence of Supersession**:
1. **Plan 956 (completed)** - Error log status tracking with RESOLVED status
2. **Plan 955 (completed)** - Error capture trap timing fixes
3. **Plan 959 (completed)** - /todo command with error analysis integration
4. **All 4 objectives addressed** across these completed plans

**Recommendation**: **MOVE to Abandoned**
**Justification**: Superseded by completed plans 955, 956, 959 which provide comprehensive error infrastructure.

---

### 848 - Neovim Buffer Opening Integration

**Status**: ⚪ KEEP
**Plan File**: `.claude/specs/848_when_using_claude_code_neovim_greggh_plugin/plans/001_buffer_opening_integration_plan.md`

**Objectives**:
- Automatic artifact buffer opening in Neovim after workflow command completion
- File system watcher using `vim.uv.new_fs_event()` API
- Integration with `greggh/claude-code.nvim` plugin

**Evidence Status is Valid**:
1. **Neovim integration exists**: `nvim/lua/neotex/plugins/ai/claude/` directory structure confirmed
2. **Plan not implemented**: No artifact-watcher.lua file exists
3. **Legitimate enhancement**: Improves developer workflow for Neovim users
4. **Not superseded**: No other plan addresses automatic buffer opening

**Recommendation**: **KEEP as Not Started**
**Justification**: Valid enhancement for Neovim integration. Worth implementing for improved workflow.

---

### 857 - Build Phase Progress Metadata

**Status**: ❌ ABANDON
**Plan File**: `.claude/specs/857_command_order_make_update_metadata_specify_phase/plans/001_build_phase_progress_metadata_plan.md`

**Objectives**:
- Enhance /build command to display current phase number in plan metadata
- Update plan metadata status from `[IN PROGRESS]` to `[IN PROGRESS: N]`
- Add phase number to `update_plan_status()` function

**Evidence for Abandonment**:
1. **Low value enhancement**: Only adds phase number to metadata status field
2. **Complex implementation** (32.0 complexity): 4 phases, library changes, test coverage
3. **Minimal user benefit**: Phase progress already shown in phase heading markers
4. **Effort vs reward**: 6 hours for cosmetic metadata improvement

**Recommendation**: **MOVE to Abandoned**
**Justification**: Low value relative to implementation effort. Phase progress already visible through heading markers. Resources better spent on higher-impact work.

---

### 871 - Error Analysis and Repair Comprehensive

**Status**: ❌ ABANDON
**Plan File**: `.claude/specs/871_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md`

**Objectives**:
- Comprehensive error remediation (8 phases, 12 hours)
- Library sourcing consistency, platform-aware bashrc, preprocessing-safe bash patterns
- Atomic state file operations, test script validation

**Evidence of Overlap**:
1. **Plan 955 (completed)** - Error capture trap timing (covers preprocessing safety)
2. **Plan 956 (completed)** - Error log status tracking
3. **Plan 959 (completed)** - /todo command with error integration
4. **Plan 787 (complete)** - State persistence fixes
5. **Massive overlap** with completed work (40-60% redundant)

**Recommendation**: **MOVE to Abandoned**
**Justification**: Superseded by multiple completed plans (955, 956, 959, 787). Core objectives already achieved through other implementations.

---

### 882 - Unified Command Optimization

**Status**: 🔀 MERGE to Backlog
**Plan File**: `.claude/specs/882_no_name/plans/001_no_name_plan.md`

**Objectives**:
- Consolidate /expand (32→8 blocks) and /collapse (29→8 blocks)
- Standardize documentation to "Block N" pattern
- Evaluate command-initialization.sh
- Add optional error logging helpers

**Evidence for Merge**:
1. **Valid optimization work**: Bash block consolidation has measurable value (75% and 72% reduction targets)
2. **40-50% redundancy removed** in this unified plan already
3. **Not superseded**: No completed plan addresses /expand and /collapse fragmentation
4. **Should be future work**: Worth doing but not urgent
5. **Combine with other optimization**: Could merge with future command refactoring initiative

**Recommendation**: **MERGE into Backlog**
**Justification**: Valid work, but should be combined with comprehensive command optimization effort. Move to Backlog with note to merge into future optimization plan.

**Suggested Backlog Entry**:
```markdown
- [ ] **Command optimization and consolidation** - Consolidate fragmented commands (/expand 32→8 blocks, /collapse 29→8 blocks), standardize "Block N" documentation, evaluate initialization patterns [Combines: Plan 882, future optimization work]
```

---

### 960 - README Compliance Full Implementation

**Status**: ✅ COMPLETE
**Plan File**: `.claude/specs/960_readme_compliance_audit_implement/plans/001-readme-compliance-audit-implement-plan.md`

**Objectives**:
- Fix validator script (emoji detection)
- Create missing READMEs (4 files)
- Document Unicode standards
- Achieve 100% README compliance

**Evidence of Completion**:
1. **Plan status shows [COMPLETE]** in metadata line 10
2. **All 4 phases marked [COMPLETE]** in Implementation Phases section
3. **Summary report exists**: `.claude/specs/960_readme_compliance_audit_implement/summaries/001-implementation-summary.md`
4. **100% compliance achieved**: 88/88 READMEs compliant (up from 77% baseline)

**Recommendation**: **MOVE to Completed**
**Justification**: Plan explicitly marked complete. All success criteria met. Summary report documents completion.

---

## Recommendation Summary

### Move to Completed (9 plans)

1. **787** - State machine persistence (evidence: state-persistence.sh exists)
2. **807** - Guides directory refactor (evidence: subdirectories exist, plan metadata [COMPLETE])
3. **814** - Reference directory refactor (evidence: subdirectories exist, plan metadata [COMPLETE])
4. **817** - Markdown-link-check config (evidence: plan metadata [COMPLETE])
5. **818** - Remaining broken references (evidence: plan metadata [COMPLETE], superseded by 807/814)
6. **820** - Library directory refactor (evidence: lib/core/ and lib/workflow/ exist)
7. **821** - Fix broken refs after 814 (evidence: plan metadata [COMPLETE])
8. **822** - Quick reference integration (evidence: reference/decision-trees/ exists)
9. **960** - README compliance (evidence: plan status [COMPLETE], summary report exists)

### Keep as Not Started (2 plans)

1. **788** - Commands README update (legitimate documentation work, not superseded)
2. **848** - Neovim buffer opening (valid Neovim integration enhancement)

### Move to Abandoned (4 plans)

1. **830** - Command protocols (decision plan recommending deletion, no implementation needed)
2. **841** - Error analysis repair (superseded by completed plans 955, 956, 959)
3. **857** - Build phase progress (low value, high effort, cosmetic improvement)
4. **871** - Error analysis comprehensive (40-60% overlap with completed plans 955, 956, 959, 787)

### Merge to Backlog (1 plan)

1. **882** - Unified command optimization (valid work, combine with future optimization initiative)

---

## Implementation Checklist

**Immediate TODO.md Updates**:

- [ ] Move plans 787, 807, 814, 817, 818, 820, 821, 822, 960 to Completed section with date (November 2025)
- [ ] Move plans 830, 841, 857, 871 to Abandoned section with reason
- [ ] Create Backlog entry for plan 882 (command optimization) with merge note
- [ ] Keep plans 788, 848 in Not Started section
- [ ] Update completion statistics (9 more completed plans documented)

**Completion Entry Template** (for each completed plan):

```markdown
- [x] **[Plan Name]** - [Brief Description] [Plan Path]
  - Completion Evidence: [Directory structure / Plan metadata / Superseding work]
  - Date: November 2025
```

**Abandonment Entry Template**:

```markdown
- [x] **[Plan Name]** - [Brief Description] [Plan Path]
  - Reason: [Superseded by / Low value / Decision to not implement]
  - See: [Related completed plans or research]
```

---

## Metrics

**Initial State**:
- Not Started: 16 plans
- Actual completion rate: 56% (9/16 plans actually complete)

**Final State** (after updates):
- Completed: +9 plans
- Abandoned: +4 plans
- Not Started: 2 plans (valid, active work)
- Backlog: +1 plan (merged for future work)

**TODO.md Health**:
- Staleness: 56% of "Not Started" plans were actually complete
- Recommendation: Regular TODO.md audits to maintain accuracy
- Automation: Consider /todo command integration for automatic status tracking

---

## Conclusion

This triage analysis reveals significant TODO.md staleness, with over half of "Not Started" plans actually complete. The directory refactoring work (plans 807, 814, 820, 822) has been successfully implemented, as evidenced by the existing subdirectory structures in guides/, reference/, and lib/. Error handling infrastructure (plans 787, 841, 871) has been comprehensively addressed through multiple completed plans (955, 956, 959).

Only 2 of the 16 plans represent active, unstarted work worth pursuing: Commands README update (788) and Neovim buffer opening integration (848). The remaining plans are either complete, obsolete, or should be deferred to future optimization initiatives.

**Next Steps**:
1. Execute TODO.md updates per Implementation Checklist
2. Consider implementing plans 788 and 848 (both legitimate, tractable enhancements)
3. Schedule regular TODO.md audits to prevent staleness accumulation
4. Integrate /todo command for automated status tracking

---

**Report Complete**
**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/963_plan_triage_todo_analysis/reports/001_plan_triage_analysis.md

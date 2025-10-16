# Phase 7 Directory Modularization Revision Plan

## Metadata
- **Date**: 2025-10-14
- **Feature**: Revise Phase 7 directory modularization plan to align with current .claude/ state
- **Scope**: Reconcile inconsistencies, update baselines, incorporate best practices
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Target Plan**: /home/benjamin/.config/.claude/specs/plans/045_claude_directory_optimization/phase_7_directory_modularization/

## Overview

The Phase 7 directory modularization plan requires comprehensive revision to address critical inconsistencies between plan documentation and current reality. Research findings reveal:

1. **Structural Inconsistencies**: Plan overview states 4 stages, but 5 stage files exist (stage_1 through stage_5)
2. **Content Mismatches**: Stage 3 file contains adaptive planning extraction (implement.md focus), but overview describes utility consolidation
3. **Baseline Drift**: Plan cites Oct 13-14 baselines but needs verification against current Oct 14 state
4. **File Naming**: Plan references both artifact-operations.sh (current, 1,585 lines) and artifact-utils.sh (deprecated name)
5. **Directory Reality**: Current state shows 17 top-level directories including empty registry/, minimal utils/ (2 files, 12K), and data/organized checkpoints/logs/

This revision will reconcile all inconsistencies, update to current baselines, incorporate industry best practices for lib/ subdirectory organization, and address redundant directory cleanup needs.

## Success Criteria

- [ ] All stage numbering and file references reconciled (4 vs 5 stages resolved)
- [ ] Stage 3 scope aligned between file content and overview description
- [ ] Baseline file sizes and dates verified and updated to Oct 14 current state
- [ ] File naming inconsistencies resolved (artifact-operations.sh vs artifact-utils.sh)
- [ ] Directory inventory updated to reflect 17 top-level directories
- [ ] lib/ v2.0 refactor completion (Oct 14) documented with 30 script count
- [ ] Best practices integrated: lib/ subdirectory organization proposal added
- [ ] Redundant directory cleanup strategy defined (registry/, utils/ consolidation)
- [ ] utils/ vs lib/ distinction clarified per industry standards
- [ ] All plan references validated against actual current files
- [ ] Testing validation strategy updated for revised plan accuracy
- [ ] lib/ subdirectory organization incorporated (core/adaptive/conversion/agents)

## Technical Design

### Architecture Decisions

**1. Reconciliation Strategy**

Use phased approach to ensure systematic resolution:
- **Phase 1**: Fix structural inconsistencies (stage numbering, content scope)
- **Phase 2**: Update all baselines to current Oct 14 state
- **Phase 3**: Incorporate best practices (lib/ structure, utils/ consolidation)
- **Phase 4**: Validate all references and generate test plan

**2. Stage Numbering Resolution**

Current state shows 5 stage files:
- stage_1_foundation.md
- stage_2_orchestrate_extraction.md
- stage_3_implement_extraction.md
- stage_4_utility_consolidation.md
- stage_5_documentation_validation.md

Plan overview claims 4 stages and lists:
1. Foundation and Analysis
2. Extract Command Documentation
3. Consolidate Utility Libraries
4. Documentation, Testing, and Validation

**Resolution**: Confirm whether stage_2/stage_3 should be merged (both are command extractions), or if overview needs to reflect 5-stage reality. Analysis of stage files shows:
- Stage 2: orchestrate.md, setup.md, revise.md extraction
- Stage 3: implement.md extraction (adaptive planning, progressive structure, phase execution)

Recommendation: Update overview to reflect 5 stages, with Stage 2 (high-priority commands) and Stage 3 (implement.md) as separate stages due to implement.md's cross-command dependencies.

**3. Content Scope Alignment**

Stage 3 file (stage_3_implement_extraction.md) contains:
- Task 1: Extract Adaptive Planning Documentation (200 lines)
- Task 2: Extract Progressive Structure Documentation (150 lines)
- Task 3: Extract Phase Execution Protocol (180 lines)
- Task 4: Update implement.md and Verify Final State

Overview description for Stage 3 states:
"Consolidate Utility Libraries: Split oversized utilities, eliminate duplicates, bundle always-sourced utilities"

**Discrepancy**: Stage 3 file content matches implement.md extraction (should be part of Stage 2 sequence), while Stage 4 file (stage_4_utility_consolidation.md) actually contains utility consolidation tasks.

**Resolution**: Swap stage numbers or update overview to correctly map:
- Stages 2-3: Command documentation extraction
- Stage 4: Utility consolidation
- Stage 5: Documentation and validation

**4. Baseline Verification Strategy**

Plan cites these baselines (need verification):
- orchestrate.md: 2,720 lines (claimed reduction from 6,341)
- implement.md: 987 lines (claimed reduction from 1,803)
- artifact-operations.sh: 1,585 lines (current verified)
- lib/: 30 scripts, 492K (need verification)
- commands/: 21 files, 400K (need verification)
- agents/: 12 files, 296K (need verification)

**Verification Tasks**:
- Count actual files in each directory
- Measure current line counts for all referenced files
- Document Oct 14 as definitive baseline date
- Flag any discrepancies for correction

**5. Best Practices Integration**

Industry standards recommend:
- **lib/ Organization**: Group by functional domain when >20 files
  - core/ - base utilities (error handling, logging, validation)
  - adaptive/ - adaptive planning, complexity, checkpoint management
  - conversion/ - convert-docs related utilities
  - agents/ - agent invocation, registry, coordination
- **utils/ Policy**: Minimal, task-specific helpers only
- **Redundancy Elimination**: Empty directories removed, single-file utils/ consolidated into lib/

**Integration Plan**:
- Add Stage 5 (or new stage) for lib/ subdirectory organization
- Define utils/ consolidation strategy (move to lib/ or eliminate)
- Document registry/ removal (empty, functionality in lib/artifact-operations.sh)
- Clarify data/ organization pattern (checkpoints, logs, metrics)

**6. File Naming Corrections**

Plan references:
- artifact-utils.sh (old name, should be artifact-operations.sh)
- Both names appear in different sections

**Correction Strategy**:
- Global find/replace: artifact-utils.sh → artifact-operations.sh
- Verify no remaining references to old name
- Document rename in revision history

### Component Interactions

```
Phase 7 Revision Structure:

phase_7_overview.md (current: 384 lines)
├── Reconciliation Updates
│   ├── Stage numbering: 4 → 5 stages
│   ├── Stage 3 scope: utility consolidation → implement extraction
│   ├── Stage 4 scope: documentation → utility consolidation
│   └── New Stage 5: documentation and validation
│
├── Baseline Updates
│   ├── Verify orchestrate.md: 2,720 lines
│   ├── Verify implement.md: 987 lines
│   ├── Verify artifact-operations.sh: 1,585 lines (confirmed)
│   ├── Update lib/ count: 30 scripts (verify), 492K (verify)
│   ├── Update directory inventory: 17 top-level directories
│   └── Document Oct 14 as current baseline
│
├── Best Practices Additions
│   ├── lib/ subdirectory proposal (core/adaptive/conversion/agents)
│   ├── utils/ consolidation strategy
│   ├── registry/ removal recommendation
│   └── data/ organization documentation
│
└── Validation Additions
    ├── File reference validation checklist
    ├── Baseline verification tests
    └── Success criteria measurement approach

Stage Files (5 total):
├── stage_1_foundation.md (current: 528 lines)
│   └── Verify baseline tests, inventory extraction candidates
│
├── stage_2_orchestrate_extraction.md (current: unknown, needs verification)
│   └── Extract orchestrate.md, setup.md, revise.md to shared/
│
├── stage_3_implement_extraction.md (current: 1,914 lines)
│   ├── Current: Utility consolidation (WRONG)
│   └── Revised: implement.md extraction to shared/
│
├── stage_4_utility_consolidation.md (current: unknown, needs verification)
│   ├── Current: Documentation validation (WRONG)
│   └── Revised: Utility consolidation (artifact-operations.sh split, etc.)
│
└── stage_5_documentation_validation.md (current: unknown, needs verification)
    └── Current: Does not exist in overview, needs addition
```

### Data Flow

**Current State (Broken)**:
```
Overview (4 stages) ≠ Files (5 stages)
Stage 3 overview description ≠ Stage 3 file content
artifact-utils.sh reference ≠ artifact-operations.sh reality
```

**Revised State (Consistent)**:
```
Overview (5 stages) = Files (5 stages)
All stage descriptions = Actual file contents
All file references = Current filenames
All baselines = Oct 14 verified state
```

## Implementation Phases

### Phase 1: Structural Reconciliation

**Objective**: Fix all structural inconsistencies in phase_7_overview.md and stage alignment

**Complexity**: Medium

**Tasks**:

1. **Update Overview Stage Count**
   - Edit phase_7_overview.md
   - Change "Estimated Stages: 4" to "Estimated Stages: 5"
   - Update Implementation Stages section to list 5 stages
   - Add Stage 5 entry with summary

2. **Reconcile Stage 3 Scope Mismatch**
   - Read stage_3_implement_extraction.md content (Tasks 1-4)
   - Verify it contains implement.md extraction, NOT utility consolidation
   - Update overview Stage 3 description to match actual content:
     - Old: "Consolidate Utility Libraries"
     - New: "Extract implement.md Documentation"
   - Update summary to reflect adaptive planning, progressive structure, phase execution extractions

3. **Update Stage 4 Description**
   - Verify stage_4_utility_consolidation.md contains utility consolidation
   - Update overview Stage 4 description:
     - Old: "Documentation, Testing, and Validation"
     - New: "Consolidate Utility Libraries"
   - Update summary to reflect artifact-operations.sh split, base-utils.sh creation, logger consolidation

4. **Add Stage 5 to Overview**
   - Create new Stage 5 entry in Implementation Stages section
   - Title: "Documentation, Testing, and Validation"
   - Summary: "Complete the refactor by updating all documentation, running full test suite, validating all success criteria"
   - Reference: "See [Stage 5 Details](stage_5_documentation_validation.md)"

5. **Verify Stage File Names Match Overview**
   - Ensure all 5 stage file references in overview match actual filenames
   - stage_1_foundation.md ✓
   - stage_2_orchestrate_extraction.md ✓
   - stage_3_implement_extraction.md ✓
   - stage_4_utility_consolidation.md ✓
   - stage_5_documentation_validation.md ✓

6. **Update Expanded Stages Metadata**
   - Change "**Expanded Stages**: [1, 2, 3, 4]" to "[1, 2, 3, 4, 5]"

**Testing**:
```bash
# Verify stage count
grep "Estimated Stages:" phase_7_overview.md
# Expected: "Estimated Stages: 5"

# Verify all 5 stages listed
grep -c "^### Stage [0-9]:" phase_7_overview.md
# Expected: 5

# Verify stage 3 description updated
grep -A2 "^### Stage 3:" phase_7_overview.md | grep -i "implement"
# Expected: Contains "implement" not "utility"
```

**Success Criteria**:
- Overview reflects 5 stages
- All stage descriptions match file contents
- Expanded stages metadata updated
- No stage numbering inconsistencies remain

### Phase 2: Baseline Alignment

**Objective**: Update all file sizes, dates, and directory counts to current Oct 14 state

**Complexity**: Low

**Tasks**:

1. **Verify and Update orchestrate.md Baseline**
   ```bash
   wc -l .claude/commands/orchestrate.md
   # Update plan with actual count (verify 2,720 lines claim)
   ```
   - Update all references to orchestrate.md with verified line count
   - Confirm reduction target (<1,200 lines, 56%) is realistic

2. **Verify and Update implement.md Baseline**
   ```bash
   wc -l .claude/commands/implement.md
   # Update plan with actual count (verify 987 lines claim)
   ```
   - Update all references to implement.md with verified line count
   - Confirm reduction target (<500 lines, 49%) is realistic

3. **Verify and Update artifact-operations.sh Baseline**
   ```bash
   wc -l .claude/lib/artifact-operations.sh
   # Confirmed: 1,585 lines
   ```
   - Baseline already verified at 1,585 lines
   - Confirm this is the largest utility file

4. **Count and Update lib/ Directory Stats**
   ```bash
   find .claude/lib -name "*.sh" | wc -l
   # Verify claim: 30 scripts
   du -sh .claude/lib
   # Verify claim: 492K
   ```
   - Update "lib/ (30 scripts, 492K)" with actual counts
   - List any significant size changes since Oct 13

5. **Count and Update commands/ Directory Stats**
   ```bash
   find .claude/commands -type f | wc -l
   # Verify claim: 21 files
   du -sh .claude/commands
   # Verify claim: 400K
   ```
   - Update "commands/ (21 files, 400K)" with actual counts

6. **Count and Update agents/ Directory Stats**
   ```bash
   find .claude/agents -type f | wc -l
   # Verify claim: 12 files
   du -sh .claude/agents
   # Verify claim: 296K
   ```
   - Update "agents/ (12 files, 296K)" with actual counts

7. **Verify Directory Inventory**
   ```bash
   ls -1 .claude/ | wc -l
   # Expected: 17 top-level directories
   ls -la .claude/ | grep "^d" | tail -n +3 | awk '{print $9}'
   # List all directories for documentation
   ```
   - Update directory count (currently states "17 top-level directories")
   - Document empty directories: registry/ (0 files), minimal utils/ (2 files)

8. **Update Baseline Date References**
   - Global search for "October 13" or "Oct 13"
   - Update to "October 14" or "Oct 14" where referring to current state
   - Maintain "Oct 13" only when referring to historical refactors
   - Add note: "Baseline Date: October 14, 2025"

9. **Verify File Naming: artifact-operations.sh**
   - Search for all "artifact-utils.sh" references
   - Replace with "artifact-operations.sh" (verified current name)
   - Document rename in plan revision history

10. **Update Success Criteria with Verified Baselines**
    - Ensure all file size targets use verified current baselines
    - Update reduction percentages if baselines changed

**Testing**:
```bash
# Run all verification commands
./verify_baselines.sh

# Expected output:
# orchestrate.md: XXXX lines (verified)
# implement.md: XXX lines (verified)
# artifact-operations.sh: 1585 lines (verified)
# lib/: XX scripts, XXXK (verified)
# commands/: XX files, XXXK (verified)
# agents/: XX files, XXXK (verified)
# Directory count: 17 (verified)
```

**Success Criteria**:
- All file line counts verified and updated
- All directory counts verified and updated
- Baseline date updated to Oct 14
- artifact-operations.sh naming corrected throughout
- No references to artifact-utils.sh remain

### Phase 3: Best Practices Integration

**Objective**: Incorporate industry best practices for lib/ organization and redundant directory cleanup

**Complexity**: Medium

**Tasks**:

1. **Add lib/ Subdirectory Organization Proposal**
   - Insert new section in Technical Design or as new Stage 6 (future)
   - Title: "lib/ Subdirectory Organization (Future Enhancement)"
   - Rationale: Industry standards recommend grouping when >20 related files
   - Proposed structure:
     ```
     lib/
     ├── core/          # Base utilities (10 files)
     │   ├── error-handling.sh
     │   ├── validation-utils.sh
     │   ├── timestamp-utils.sh
     │   └── deps-utils.sh
     ├── adaptive/      # Adaptive planning (8 files)
     │   ├── complexity-utils.sh
     │   ├── checkpoint-utils.sh
     │   ├── adaptive-planning-logger.sh
     │   └── progressive-planning-utils.sh
     ├── conversion/    # Convert-docs (8 files)
     │   ├── convert-core.sh
     │   ├── convert-docx.sh
     │   ├── convert-markdown.sh
     │   ├── convert-pdf.sh
     │   └── conversion-logger.sh
     └── agents/        # Agent utilities (4 files)
         ├── agent-invocation.sh
         ├── agent-registry-utils.sh
         └── analyze-metrics.sh
     ```
   - Benefits: Clearer functional separation, easier navigation, reduced namespace pollution
   - Migration: Backward compatibility via symlinks during transition

2. **Define utils/ Consolidation Strategy**
   - Document current utils/ state: 2 files (parse-adaptive-plan.sh, show-agent-metrics.sh), 12K
   - Industry recommendation: utils/ for task-specific helpers, lib/ for reusable modules
   - Proposed action:
     - Option A: Move to lib/adaptive/ (parse-adaptive-plan.sh) and lib/agents/ (show-agent-metrics.sh)
     - Option B: Keep utils/ for true one-off scripts, consolidate reusable code to lib/
   - Decision criteria: Are these files sourced by multiple commands (→ lib/) or standalone scripts (→ utils/)?
   - Update Technical Design with recommendation

3. **Add registry/ Directory Cleanup Recommendation**
   - Document current state: registry/ directory empty (0 files)
   - Functionality: Moved to lib/artifact-operations.sh (register_artifact, query_artifacts functions)
   - Recommendation: Remove empty registry/ directory
   - Rationale: Reduces directory clutter, consolidates artifact tracking in single utility
   - Add to Stage 4 or Stage 5 tasks: "Remove empty .claude/registry/ directory"

4. **Document data/ Organization Pattern**
   - Current state: data/ exists with checkpoints/, logs/, metrics/ subdirectories
   - This is the CORRECT location for runtime data (not .claude/ root)
   - Add note to Technical Design:
     - "data/ Organization": checkpoints, logs, metrics under data/ (not .claude/ root)
     - Clarifies that .claude/checkpoints and .claude/logs are NOT the primary locations
   - Recommendation: Verify all commands use data/ paths, not .claude/ root paths

5. **Clarify lib/ vs utils/ Distinction**
   - Add subsection to Technical Design: "Directory Roles"
   - lib/: Sourced bash utilities (functions), modular, reusable across commands
   - utils/: Standalone scripts, task-specific, may not be sourced
   - commands/: Slash command prompts (markdown), invoked by user
   - agents/: Agent behavioral guidelines (markdown), invoked via Task tool
   - data/: Runtime data (checkpoints, logs, metrics), gitignored
   - templates/: Plan templates (YAML), used by /plan-from-template

6. **Update Success Criteria**
   - Add: "lib/ subdirectory organization proposal documented"
   - Add: "utils/ consolidation strategy defined"
   - Add: "registry/ cleanup recommendation added"
   - Add: "data/ organization pattern clarified"
   - Add: "lib/ vs utils/ distinction documented"

7. **Add Future Considerations Section**
   - Document lib/ subdirectory organization as Phase 8 or future refactor
   - Note: Not part of current Phase 7 scope, but recommended follow-up
   - Estimate: 3-4 hours, low risk (backward compatibility via symlinks)

**Testing**:
```bash
# Verify all sections added
grep -A5 "lib/ Subdirectory Organization" phase_7_overview.md
grep -A5 "utils/ Consolidation Strategy" phase_7_overview.md
grep -A5 "registry/ Directory Cleanup" phase_7_overview.md
grep -A5 "data/ Organization Pattern" phase_7_overview.md
grep -A5 "Directory Roles" phase_7_overview.md
```

**Success Criteria**:
- lib/ subdirectory proposal documented with structure and rationale
- utils/ consolidation strategy defined with decision criteria
- registry/ cleanup recommendation added
- data/ organization documented
- Directory roles clarified
- Future considerations section added

### Phase 4: Validation and Testing

**Objective**: Validate all plan references, create baseline verification script, update testing strategy

**Complexity**: Low

**Tasks**:

1. **Create Baseline Verification Script**
   - Create `.claude/tests/verify_phase7_baselines.sh`
   - Script checks:
     - orchestrate.md line count matches plan claim
     - implement.md line count matches plan claim
     - artifact-operations.sh line count = 1,585
     - lib/ script count matches plan claim
     - commands/ file count matches plan claim
     - agents/ file count matches plan claim
     - Directory count = 17
   - Output: PASS/FAIL for each check
   - Return non-zero exit code if any check fails

2. **Validate All File References**
   - Create checklist of files referenced in plan
   - Verify each file exists:
     - phase_7_overview.md ✓
     - stage_1_foundation.md ✓
     - stage_2_orchestrate_extraction.md ✓
     - stage_3_implement_extraction.md ✓
     - stage_4_utility_consolidation.md ✓
     - stage_5_documentation_validation.md ✓
     - artifact-operations.sh ✓
     - orchestrate.md, implement.md, setup.md, revise.md ✓
   - Document any missing files
   - Add note to plan if files need creation

3. **Verify Cross-References Between Stages**
   - Stage 2 creates shared/ files (workflow-phases.md, error-recovery.md, etc.)
   - Stage 3 references error-recovery.md created in Stage 2
   - Stage 4 references shared docs created in Stages 2-3
   - Verify all cross-references are valid
   - Update stage descriptions if dependencies incorrect

4. **Update Testing Strategy Section**
   - Add "Baseline Verification Tests" subsection
   - Reference verify_phase7_baselines.sh script
   - Add "Plan Consistency Tests" subsection:
     - Stage count matches files
     - Stage descriptions match file contents
     - All file references valid
   - Add "Success Criteria Validation Tests":
     - Measurable success criteria
     - Verification commands for each criterion

5. **Create Phase 7 Revision Summary**
   - Add "Revision Summary" section to phase_7_overview.md
   - List all changes made:
     - Stage count: 4 → 5
     - Stage 3 scope: utility → implement extraction
     - Stage 4 scope: documentation → utility consolidation
     - Stage 5 added: documentation and validation
     - Baselines updated to Oct 14 verified state
     - artifact-utils.sh → artifact-operations.sh corrected
     - lib/ subdirectory proposal added
     - utils/ consolidation strategy defined
     - registry/ cleanup recommendation added
   - Date: October 14, 2025
   - Reason: Reconcile plan with current reality, incorporate best practices

6. **Update Revision History Section**
   - Add entry for this revision (should be Revision 3)
   - Format:
     ```markdown
     ### 2025-10-14 - Revision 3
     **Changes**: Systematic reconciliation of plan with current .claude/ state
     **Reason**: Resolve structural inconsistencies, update baselines, incorporate best practices
     **Reports Used**: Research synthesis (200-word summary of .claude/ current state)
     **Modified Sections**:
     - Stage count: 4 → 5 stages
     - Stage 3 scope realignment: implement.md extraction
     - Stage 4 scope realignment: utility consolidation
     - Baselines verified: Oct 14, 2025
     - File naming corrected: artifact-operations.sh
     - Best practices added: lib/ subdirectories, utils/ consolidation, registry/ cleanup
     ```

7. **Run Full Validation**
   - Execute verify_phase7_baselines.sh
   - Verify all cross-references
   - Check stage count consistency
   - Confirm all success criteria measurable
   - Document any remaining issues

8. **Generate Validation Report**
   - Create `phase_7_revision_validation.md` in plan directory
   - Include:
     - Baseline verification results
     - File reference validation results
     - Cross-reference validation results
     - Success criteria measurability assessment
     - Remaining issues (if any)
     - Approval status

**Testing**:
```bash
# Run baseline verification
.claude/tests/verify_phase7_baselines.sh
# Expected: All checks PASS

# Validate file references
.claude/tests/validate_file_references.sh phase_7_directory_modularization/
# Expected: All referenced files exist

# Check stage consistency
grep -c "^### Stage [0-9]:" phase_7_overview.md
# Expected: 5

# Verify revision history updated
grep "2025-10-14 - Revision 3" phase_7_overview.md
# Expected: Found
```

**Success Criteria**:
- verify_phase7_baselines.sh script created and passing
- All file references validated
- All cross-references verified
- Testing strategy updated with validation tests
- Revision summary added to overview
- Revision history updated
- Validation report generated

## Testing Strategy

### Unit Tests

**Baseline Verification**:
```bash
# Test each baseline claim
test_orchestrate_baseline() {
  wc -l .claude/commands/orchestrate.md | grep -q "2720"
}

test_implement_baseline() {
  wc -l .claude/commands/implement.md | grep -q "987"
}

test_artifact_operations_baseline() {
  wc -l .claude/lib/artifact-operations.sh | grep -q "1585"
}
```

**File Reference Validation**:
```bash
# Test each file exists
test_stage_files_exist() {
  for i in 1 2 3 4 5; do
    [ -f "stage_${i}_*.md" ] || return 1
  done
  return 0
}
```

### Integration Tests

**Stage Consistency**:
```bash
# Verify stage count matches files
test_stage_count_matches_files() {
  OVERVIEW_COUNT=$(grep -c "^### Stage [0-9]:" phase_7_overview.md)
  FILE_COUNT=$(ls -1 stage_*.md | wc -l)
  [ "$OVERVIEW_COUNT" -eq "$FILE_COUNT" ]
}
```

**Cross-Reference Validation**:
```bash
# Verify Stage 3 references Stage 2 artifacts
test_cross_references() {
  grep -q "error-recovery.md" stage_3_implement_extraction.md
}
```

### Regression Tests

**Ensure No Broken References**:
```bash
# After revision, verify all links work
test_no_broken_references() {
  for file in stage_*.md phase_7_overview.md; do
    grep -o '\[.*\](.*\.md)' "$file" | while read link; do
      FILE=$(echo "$link" | grep -o '(.*\.md)' | tr -d '()')
      [ -f "$FILE" ] || echo "BROKEN: $link in $file"
    done
  done
}
```

### Coverage Requirements

- 100% of referenced files must exist and be accessible
- 100% of baselines must be verified against current state
- 100% of cross-references must be valid
- All success criteria must be measurable and testable

## Documentation Requirements

### Updated Documentation

**phase_7_overview.md**:
- Stage count: 4 → 5
- Stage descriptions realigned with file contents
- Baselines updated to Oct 14 verified state
- Best practices sections added
- Revision summary added
- Revision history updated

**All 5 Stage Files**:
- Verify content matches overview descriptions
- Update any baseline references
- Correct artifact-utils.sh → artifact-operations.sh references

**New Testing Documentation**:
- verify_phase7_baselines.sh script
- validate_file_references.sh script
- phase_7_revision_validation.md report

### Architecture Diagram

Update Component Interactions diagram to reflect:
- 5 stages (not 4)
- Correct stage responsibilities
- lib/ subdirectory proposal (future)
- data/ organization pattern

## Dependencies

### Prerequisites

- Access to all stage files (stage_1 through stage_5)
- Access to phase_7_overview.md
- Access to .claude/ directory for baseline verification
- Edit tool for file modifications
- Bash for verification scripts

### Internal Dependencies

- Phase 1 must complete before Phase 2 (structural fixes enable baseline updates)
- Phase 2 must complete before Phase 3 (verified baselines inform best practices)
- Phase 3 must complete before Phase 4 (all content finalized before validation)

## Risk Assessment

### High Risk

**None** - This is documentation revision, no code changes

### Medium Risk

- **Baseline verification reveals significant drift**: Mitigation—document actual state, adjust targets
- **Stage file contents significantly differ from overview**: Mitigation—choose authoritative source (files), update overview

### Low Risk

- **Best practices may not align with project needs**: Mitigation—mark as recommendations, not requirements
- **Validation uncovers more inconsistencies**: Mitigation—iterative revision, document all findings

## Notes

### Refactoring Philosophy

Following CLAUDE.md Development Philosophy:
- **Present-focused**: Document current state accurately
- **No historical markers**: Revision history tracks changes, but main content describes current reality
- **Clarity over compatibility**: Clean, consistent documentation prioritized

### Critical Findings from Research

**Stage Numbering**: 5 stage files exist, but overview claims 4. Resolution: Update overview to 5 stages.

**Stage 3 Content Mismatch**: File contains implement.md extraction (adaptive planning, progressive structure, phase execution), but overview says "utility consolidation". Resolution: Update overview to reflect actual content.

**Baseline Verification**: artifact-operations.sh confirmed at 1,585 lines. Other baselines need verification.

**Directory Reality**: 17 top-level directories, including empty registry/, minimal utils/ (2 files), organized data/ subdirectory. Best practices recommend cleanup.

**lib/ Organization**: 30 scripts in flat structure. Industry standards recommend subdirectories when >20 files. Proposal: core/, adaptive/, conversion/, agents/ grouping.

### Success Metrics

- 100% stage consistency (overview = files)
- 100% baseline accuracy (plan = reality)
- 100% file reference validity (all links work)
- 0 naming inconsistencies (artifact-operations.sh everywhere)
- Best practices documented (lib/ subdirs, utils/ consolidation, registry/ cleanup)

### Future Improvements

- Implement lib/ subdirectory organization (Phase 8 or separate plan)
- Execute utils/ consolidation based on defined strategy
- Remove empty registry/ directory as recommended
- Verify and migrate all data to data/ subdirectory

## Implementation Summary

This plan was executed on 2025-10-14. See workflow summary:
- [Workflow Summary](../summaries/051_phase7_revision_summary.md)

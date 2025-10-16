# Spec File Update Mechanisms Implementation Plan

## Metadata

- **Date**: 2025-10-03
- **Specs Directory**: /home/benjamin/.config/.claude/specs/
- **Plan Number**: 018
- **Feature**: Implement comprehensive spec file update mechanisms
- **Scope**: Update `/report`, `/refactor`, `/plan`, `/implement`, `/orchestrate`, `/debug` commands to maintain spec file consistency
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [../reports/022_spec_file_update_requirements.md](../reports/022_spec_file_update_requirements.md)
  - [../reports/018_flexible_specs_location_strategies.md](../reports/018_flexible_specs_location_strategies.md)

## Overview

This plan implements the 5 critical spec file management improvements identified in Report 022:

0. **Specs Directory Location Tracking** - Document specs/ directory in metadata so related specs stay co-located (affects `/report`, `/refactor`, `/plan`, `/implement`, `/orchestrate`)
1. **`/implement` Incremental Updates** - Update plans and generate summaries incrementally during execution
2. **`/orchestrate` Bidirectional Links** - Create two-way cross-references between summaries, plans, and reports (including refactoring reports)
3. **`/debug` Plan Annotations** - Annotate plans with debugging history
4. **`/report` Implementation Tracking** - Track which report recommendations were implemented (applies to both `/report` and `/refactor` since both create reports)

**Priority Focus**: Phases 1-2 (specs directory tracking and `/implement` updates) are critical for user workflows. Phases 3-5 improve quality-of-life but are lower priority.

## Success Criteria

- [ ] All new spec files include "Specs Directory" metadata
- [ ] `/plan` uses same specs/ directory as referenced reports
- [ ] `/implement` updates plan files incrementally after each phase
- [ ] `/implement` creates partial summaries for interrupted implementations
- [ ] `/orchestrate` creates bidirectional links (summary ↔ plan ↔ reports)
- [ ] `/debug` annotates plans with debugging history
- [ ] Reports track implementation status of recommendations
- [ ] All changes maintain backward compatibility with existing specs

## Technical Design

### Architecture Decisions

**1. SPECS.md Registry File**

```markdown
A centralized `.claude/SPECS.md` file acts as a registry for all projects:

# Specs Directory Registry

## Projects

### /path/to/project/module
- **Specs Directory**: project/module/specs/
- **Last Updated**: 2025-10-03
- **Reports**: 3
- **Plans**: 2
- **Summaries**: 1
```

**Workflow**:
1. Command detects relevant project directory (based on files being worked on)
2. Checks `.claude/SPECS.md` for registered specs directory for that project
3. If not found: Auto-detects best location and registers it
4. Uses that specs directory for creating specs
5. Includes path in spec file metadata for consistency

**2. Metadata-Driven Specs Location**

```markdown
All spec files include metadata documenting their specs/ directory:

## Metadata
- **Specs Directory**: path/to/specs/
- **[Type] Number**: NNN
```

Commands use both SPECS.md registry AND metadata:
- `/report` → checks registry → detects if needed → documents in metadata
- `/plan` → reads from report metadata OR registry → uses same location → documents in metadata
- `/implement` → reads from plan metadata → uses same location → documents in metadata
```

**3. Incremental Plan Updates**

```markdown
/implement updates plan file after each phase completion:

1. Execute phase tasks
2. Run phase tests
3. If tests pass:
   a. Mark tasks complete: - [x]
   b. Add phase marker: ### Phase N [COMPLETED]
   c. Update plan file atomically
   d. Verify write succeeded
   e. Create git commit
4. Generate/update partial summary
5. Move to next phase
```

**4. Bidirectional Cross-References**

```markdown
/orchestrate documentation phase:

1. Create workflow summary linking to plan and reports
2. Update plan with "Implementation Summary" section linking to summary
3. Update each report with "Implementation Status" section linking to summary and plan
4. Verify all cross-references are bidirectional
```

### Component Interactions

```
Workflow: /report → /plan → /implement → summary

Phase 1 (Specs Directory Tracking with SPECS.md):
  /report detects project: nvim/lua/neotex/auth/
    ↓ checks .claude/SPECS.md
    ↓ if not found: auto-detects → registers in SPECS.md
    ↓ creates: nvim/lua/neotex/auth/specs/reports/001.md
    ↓ metadata: "Specs Directory: nvim/lua/neotex/auth/specs/"

  /plan reads report metadata → uses same specs directory
    ↓ creates: nvim/lua/neotex/auth/specs/plans/001.md
    ↓ metadata: "Specs Directory: nvim/lua/neotex/auth/specs/"

  /implement reads plan metadata → uses same specs directory
    ↓ creates: nvim/lua/neotex/auth/specs/summaries/001.md
    ↓ metadata: "Specs Directory: nvim/lua/neotex/auth/specs/"
    ✓ All co-located in nvim/lua/neotex/auth/specs/

Phase 2 (/implement Updates):
  /implement Phase 1:
    → update plan: Phase 1 [COMPLETED]
    → create: specs/summaries/001_partial.md
    → commit: "Phase 1 complete"
  /implement Phase 2:
    → update plan: Phase 2 [COMPLETED]
    → update: specs/summaries/001_partial.md
    → commit: "Phase 2 complete"
  [interrupt]
    ✓ Plan shows Phases 1-2 complete
    ✓ Partial summary exists for resume context

Phase 3 (Bidirectional Links):
  /orchestrate completion:
    → create: specs/summaries/002_workflow.md
      ↳ links to: plans/002.md, reports/003.md
    → update: plans/002.md
      ↳ adds link to: summaries/002_workflow.md
    → update: reports/003.md
      ↳ adds link to: summaries/002_workflow.md, plans/002.md
    ✓ All files cross-reference each other
```

### Data Flow

```
Specs Directory Resolution:
  1. Check .claude/SPECS.md for project
  2. If not found → auto-detect best location
  3. Register in SPECS.md
  4. Use for specs creation
  5. Document in spec metadata

Specs Directory Propagation:
  SPECS.md registry → report.metadata.specs_dir → plan.metadata.specs_dir → summary.metadata.specs_dir

Plan Update Flow:
  implement_phase() → tests_pass? → update_plan_atomically() → verify() → commit()

Cross-Reference Flow:
  create_summary() → extract_linked_files() → update_each_file() → verify_bidirectional()
```

## Implementation Phases

### Phase 1: Specs Directory Metadata Tracking [COMPLETED]

**Objective**: Add "Specs Directory" metadata to all spec files, create SPECS.md registry, and update commands to respect it
**Complexity**: Low-Medium
**Priority**: CRITICAL (enables modular/monorepo organization)

Tasks:
- [x] Create `.claude/SPECS.md` registry file if it doesn't exist
  - Format: Markdown with project sections
  - Each project section includes: Specs Directory path, Last Updated, counts (Reports, Plans, Summaries)
  - Gitignored or committed based on user preference
- [x] Update `/report` command template (`.claude/commands/report.md`)
  - On execution: Detect relevant project directory (based on topic and file analysis)
  - Check `.claude/SPECS.md` for registered specs directory for that project
  - If not found: Auto-detect best location (deepest directory containing relevant files)
  - Register project and specs directory in SPECS.md (create entry with counts)
  - Create report in registered specs directory
  - Add "Specs Directory: [path]" to report metadata
  - Update SPECS.md report count
- [x] Update `/refactor` command template (`.claude/commands/refactor.md`)
  - Same logic as `/report` (refactoring reports are just specialized reports)
  - Detect project, check/register in SPECS.md, document in metadata
  - Update SPECS.md report count
- [x] Update `/plan` command logic (`.claude/commands/plan.md`)
  - If report paths provided: Extract specs_dir from first report's metadata
  - Else: Check SPECS.md for current project, or auto-detect and register
  - Create plan in same specs/ directory as reports
  - Add "Specs Directory: [path]" to plan metadata
  - Update SPECS.md plan count
- [x] Update `/implement` command logic (`.claude/commands/implement.md`)
  - Extract specs_dir from plan metadata
  - Create summary in same specs/ directory as plan
  - Add "Specs Directory: [path]" to summary metadata
  - Update SPECS.md summary count
- [x] Update `/orchestrate` command logic (`.claude/commands/orchestrate.md`)
  - Update research-specialist agent prompt to check SPECS.md and document specs directory in reports
  - Update plan-architect agent prompt to read specs directory from reports metadata
  - Update code-writer agent prompt to read specs directory from plan metadata
  - Update doc-writer agent prompt to use same specs directory for summary
  - Update SPECS.md counts after workflow completion
- [x] Update spec file templates in all commands
  - Add "Specs Directory: [path]" to metadata sections
  - Add "[Type] Number: NNN" to clarify number is within that directory
- [x] Add backward compatibility handling
  - If existing spec file lacks "Specs Directory" metadata, infer from file path
  - Existing specs without metadata continue working
  - Commands can work without SPECS.md (auto-detect and create as needed)

Testing:
```bash
# Test specs directory consistency with /report
cd /tmp/test-project/module/
/report "test feature"
# Verify: creates module/specs/reports/001_test_feature.md
# Verify: metadata includes "Specs Directory: module/specs/"

# Test specs directory consistency with /refactor
cd /tmp/test-project/module/
/refactor module/ "code quality issues"
# Verify: creates module/specs/reports/002_refactoring_module.md
# Verify: metadata includes "Specs Directory: module/specs/"

cd /tmp/test-project/  # Different directory
/plan "implement test feature" module/specs/reports/001_test_feature.md
# Verify: creates module/specs/plans/001_implement_test_feature.md (not specs/plans/)
# Verify: metadata includes "Specs Directory: module/specs/"

# Test that /plan can reference refactoring reports too
/plan "apply refactoring" module/specs/reports/002_refactoring_module.md
# Verify: creates module/specs/plans/002_apply_refactoring.md
# Verify: uses same module/specs/ directory

/implement module/specs/plans/001_implement_test_feature.md
# Verify: creates module/specs/summaries/001_implement_test_feature.md
# Verify: metadata includes "Specs Directory: module/specs/"

ls module/specs/
# Verify: all spec types in same directory (reports, plans, summaries)
# Verify: both regular reports and refactoring reports in reports/
```

**Success Criteria**:
- All new reports, plans, summaries include "Specs Directory" metadata
- `/plan` uses same specs/ directory as referenced reports
- `/implement` uses same specs/ directory as plan
- Related specs stay co-located

### Phase 2: Incremental Plan and Summary Updates in `/implement` [COMPLETED]

**Objective**: Update plan files after each phase and maintain partial summaries for interrupted implementations
**Complexity**: Medium
**Priority**: CRITICAL (enables resumable implementations)

Tasks:
- [ ] Update `/implement` command phase execution logic
  - After each phase's git commit succeeds:
    - Use Edit tool to mark all phase tasks as complete: `- [ ]` → `- [x]`
    - Add `[COMPLETED]` marker to phase heading: `### Phase N` → `### Phase N [COMPLETED]`
    - Read back plan file to verify markers were added
    - If verification fails: Log warning, continue (don't block)
  - Before starting next phase:
    - Read plan file
    - Verify previous phase marked `[COMPLETED]`
    - If not marked: Mark it now (defensive programming)
- [ ] Add incremental summary generation to `/implement`
  - After each phase completion: Create or update `specs/summaries/NNN_partial.md`
  - Partial summary includes:
    - Status: "in_progress"
    - Phases completed: "M/N"
    - Last completed phase name and date
    - Last git commit hash
    - Resume instructions: `/implement plan_NNN.md M+1`
  - Use Write tool to create, Edit tool to update
- [ ] Add checkpoint system to track implementation progress
  - After each phase: Update plan with "## Implementation Progress" section (using Edit tool)
  - Include: Last completed phase, date, git commit, resume instructions
  - Format: `Resume with: /implement plan_NNN.md <next-phase-number>`
  - Section added after metadata, before overview
- [ ] Finalize summary on workflow completion
  - If all phases complete: Rename partial summary to final: `NNN_partial.md` → `NNN_summary.md`
  - Update status from "in_progress" to "complete"
  - Add completion date and final metrics
  - If interrupted: Partial summary remains for resume context
- [ ] Add rollback handling for phase failures
  - If phase tests fail: Don't mark phase complete
  - If git commit fails after marking complete: Log error, preserve partial work
  - Partial summary always reflects actual completed phases, not attempted phases
- [ ] Update `/resume-implement` command logic
  - Read plan file to find last `[COMPLETED]` phase
  - Check for partial summary file to get additional context
  - Resume from first incomplete phase
  - Continue updating same partial summary

Testing:
```bash
# Test incremental updates
/plan "feature with 4 phases"
# Creates: specs/plans/019_feature_with_4_phases.md

/implement specs/plans/019_feature_with_4_phases.md
# Let run through Phase 1 and Phase 2, then Ctrl+C

# Verify plan updated
cat specs/plans/019_feature_with_4_phases.md | grep "Phase 1.*COMPLETED"
cat specs/plans/019_feature_with_4_phases.md | grep "Phase 2.*COMPLETED"
cat specs/plans/019_feature_with_4_phases.md | grep "Phase 3" | grep -v "COMPLETED"

# Verify partial summary exists
ls specs/summaries/019_feature_with_4_phases_partial.md
cat specs/summaries/019_feature_with_4_phases_partial.md | grep "Status: in_progress"
cat specs/summaries/019_feature_with_4_phases_partial.md | grep "Phases completed: 2/4"

# Test resume
/resume-implement
# Verify: auto-detects plan_019.md, resumes from Phase 3

# Let complete all phases
# Verify final summary
ls specs/summaries/019_feature_with_4_phases.md
cat specs/summaries/019_feature_with_4_phases.md | grep "Status: complete"
```

**Success Criteria**:
- Plan files updated after each phase completion
- Tasks marked `[x]` and phases marked `[COMPLETED]` incrementally
- Partial summaries created during implementation
- Interrupted implementations can resume cleanly
- `/resume-implement` works reliably

### Phase 3: Bidirectional Cross-References in `/orchestrate` [COMPLETED]

**Objective**: Update plans and reports to link back to summaries, creating bidirectional navigation
**Complexity**: Medium
**Priority**: HIGH (improves spec navigation and traceability)

Tasks:
- [ ] Update `/orchestrate` documentation phase (doc-writer agent prompt)
  - After creating workflow summary:
    - Extract plan path from summary metadata
    - Extract report paths from summary cross-references
    - Use Edit tool to append "## Implementation Summary" section to plan:
      ```markdown
      ## Implementation Summary
      - **Status**: Complete
      - **Date**: [YYYY-MM-DD]
      - **Summary**: [link to specs/summaries/NNN.md]
      ```
    - For each report: Use Edit tool to append "## Implementation Status" section:
      ```markdown
      ## Implementation Status
      - **Status**: Implemented
      - **Date**: [YYYY-MM-DD]
      - **Plan**: [link to specs/plans/NNN.md]
      - **Summary**: [link to specs/summaries/NNN.md]
      ```
  - Before marking workflow complete:
    - Verify all cross-references exist (Read tool to check)
    - If verification fails: Report warnings but continue
- [ ] Update `/implement` summary generation (if not orchestrated)
  - When generating final summary:
    - Extract plan path from plan metadata
    - Extract report paths from plan metadata (if any)
    - Use Edit tool to update plan with implementation summary link
    - Use Edit tool to update reports with implementation status
- [ ] Add cross-reference sections to spec file templates
  - Plan template: Optional "## Implementation Summary" section (added post-implementation)
  - Report template: Optional "## Implementation Status" section (added post-implementation)
  - Summary template: "## Cross-References" section (always included)
- [ ] Handle edge cases
  - If plan/report file not writable: Log warning, continue
  - If file already has implementation section: Update existing section with Edit tool, don't duplicate
  - If multiple summaries reference same plan: Append to list, don't replace

Testing:
```bash
# Test bidirectional linking
/report "test best practices"
# Creates: specs/reports/023_test_best_practices.md

/orchestrate "implement test framework using report 023"
# Should create: plan_024.md, execute it, create summary_024.md

# Verify summary links
cat specs/summaries/024_workflow.md | grep "reports/023"
cat specs/summaries/024_workflow.md | grep "plans/024"

# Verify plan links back
cat specs/plans/024_test_framework.md | grep "Implementation Summary"
cat specs/plans/024_test_framework.md | grep "summaries/024"

# Verify report links back
cat specs/reports/023_test_best_practices.md | grep "Implementation Status"
cat specs/reports/023_test_best_practices.md | grep "plans/024"
cat specs/reports/023_test_best_practices.md | grep "summaries/024"

# Verify navigation works both ways
# Summary → Plan → Summary ✓
# Summary → Report → Summary ✓
```

**Success Criteria**:
- Workflow summaries link to plans and reports
- Plans link back to summaries
- Reports link back to summaries and plans
- All cross-references are bidirectional
- Navigation works in both directions

### Phase 4: Debug Report Plan Annotations [COMPLETED]

**Objective**: Annotate plans with debugging history when `/debug` creates debug reports
**Complexity**: Low-Medium
**Priority**: MEDIUM (improves debugging context)

Tasks:
- [ ] Update `/debug` command completion logic
  - After creating debug report:
    - If plan_path provided in arguments:
      - Extract failed phase number from context (from plan or user input)
      - Extract root cause summary from debug report
      - Use Edit tool to add "#### Debugging Notes" subsection after the failed phase:
        ```markdown
        #### Debugging Notes
        - **Date**: [YYYY-MM-DD]
        - **Issue**: [Brief description]
        - **Debug Report**: [link to specs/reports/NNN_debug.md]
        - **Root Cause**: [One-line summary]
        - **Resolution**: Pending
        ```
  - If plan not provided: Log suggestion to manually link debug report to plan
- [ ] Track multiple debugging iterations
  - Before adding notes: Check if phase already has "#### Debugging Notes"
  - If exists: Append new iteration, don't replace
  - Number iterations: "Iteration 1", "Iteration 2", etc.
  - If 3+ iterations: Add note "Escalated to manual intervention"
- [ ] Update debug resolution when fixes applied in `/implement`
  - After phase tests pass (previously failed phase):
    - Check if phase has "#### Debugging Notes" with "Resolution: Pending"
    - Use Edit tool to update resolution: `Resolution: Pending` → `Resolution: Applied`
    - Add fix commit hash: `Fix Applied In: [commit-hash]`

Testing:
```bash
# Test debug annotations
/plan "complex feature with tricky logic"
# Creates: specs/plans/025_complex_feature.md

/implement specs/plans/025_complex_feature.md
# Let Phase 3 fail with test errors

/debug "Phase 3 test failures" specs/plans/025_complex_feature.md
# Creates: specs/reports/026_debug_phase3.md

# Verify plan annotated
cat specs/plans/025_complex_feature.md | grep "Phase 3" -A 20 | grep "Debugging Notes"
cat specs/plans/025_complex_feature.md | grep "reports/026"
cat specs/plans/025_complex_feature.md | grep "Resolution: Pending"

# Apply fixes and re-run
/implement specs/plans/025_complex_feature.md 3

# Verify resolution updated
cat specs/plans/025_complex_feature.md | grep "Resolution: Applied"
cat specs/plans/025_complex_feature.md | grep "Fix Applied In:"
```

**Success Criteria**:
- Debug reports annotate original plans
- Debugging history visible in plan files
- Multiple iterations tracked
- Resolution status updated when fixes applied

### Phase 5: Report Implementation Tracking [COMPLETED]

**Objective**: Track which report recommendations were implemented and their outcomes
**Complexity**: Medium
**Priority**: LOW-MEDIUM (nice-to-have quality improvement)
**Note**: Applies to both `/report` and `/refactor` since both create reports with recommendations

Tasks:
- [ ] Add implementation status section to report templates
  - Update both `.claude/commands/report.md` and `.claude/commands/refactor.md`
  - All new reports include "## Implementation Status" section:
    ```markdown
    ## Implementation Status
    - **Status**: Research Complete
    - **Plan**: None yet
    - **Implementation**: Not started
    - **Date**: [YYYY-MM-DD]
    ```
- [ ] Update `/plan` command to mark reports as "planning"
  - If report paths provided:
    - For each report: Use Edit tool to update status:
      `Status: Research Complete` → `Status: Planning In Progress`
    - Add plan link: `Plan: None yet` → `Plan: [link to specs/plans/NNN.md]`
    - Update date
- [ ] Update `/implement` or `/orchestrate` to mark reports as "implemented"
  - On implementation completion:
    - Extract report paths from plan metadata
    - For each report: Use Edit tool to update status:
      `Status: Planning In Progress` → `Status: Implemented`
      `Implementation: Not started` → `Implementation: [link to specs/summaries/NNN.md]`
    - Update date
- [ ] Handle reports without implementation status section (backward compatibility)
  - Check if report has "## Implementation Status" section
  - If missing: Use Edit tool to append section before updating
  - If report is pre-this-feature and can't be updated: Log warning, skip update

Testing:
```bash
# Test report tracking
/report "caching strategies"
# Creates: specs/reports/027_caching_strategies.md
# Verify: includes "Implementation Status: Research Complete"

/plan "add caching layer" specs/reports/027_caching_strategies.md
# Creates: specs/plans/026_add_caching_layer.md

# Verify report updated
cat specs/reports/027_caching_strategies.md | grep "Planning In Progress"
cat specs/reports/027_caching_strategies.md | grep "plans/026"

/implement specs/plans/026_add_caching_layer.md
# All phases complete

# Verify report marked implemented
cat specs/reports/027_caching_strategies.md | grep "Status: Implemented"
cat specs/reports/027_caching_strategies.md | grep "summaries/026"
cat specs/reports/027_caching_strategies.md | grep "Recommendation Tracking"
```

**Success Criteria**:
- New reports include implementation status section
- Reports updated when referenced by plans
- Reports show which recommendations were implemented
- Lifecycle tracking (research → planning → implemented)

## Testing Strategy

### Unit Testing

Test SPECS.md registry functionality:

```bash
# Test SPECS.md creation and registration
rm -f .claude/SPECS.md
/report "test feature"
# Verify: .claude/SPECS.md exists
# Verify: Contains project entry with specs directory path

# Test SPECS.md registry lookup
cat .claude/SPECS.md  # Should show registered project
/plan "implement test" specs/reports/001.md
# Verify: Plan uses same specs directory as report (from SPECS.md or metadata)

# Test metadata extraction from spec files
echo "## Metadata\n- **Specs Directory**: test/specs/" > /tmp/test.md
/plan "test with report" /tmp/test.md
# Verify: Plan created in test/specs/plans/
```

### Integration Testing

Test commands with new functionality:

```bash
# Test Phase 1: Specs directory consistency
cd /tmp/modular-project/auth/
/report "auth test" && /plan "implement auth" specs/reports/001.md
ls specs/plans/001_implement_auth.md && echo "PASS: Co-located" || echo "FAIL"

# Test Phase 2: Incremental updates
/implement specs/plans/001.md  # Interrupt after Phase 1
grep "Phase 1.*COMPLETED" specs/plans/001.md && echo "PASS: Plan updated" || echo "FAIL"
ls specs/summaries/001_*_partial.md && echo "PASS: Partial summary" || echo "FAIL"

# Test Phase 3: Bidirectional links
/orchestrate "test feature"
grep "Implementation Summary" specs/plans/*.md && echo "PASS: Plan links" || echo "FAIL"
```

### End-to-End Testing

Test complete workflows:

```bash
# Scenario: Research → Plan → Implement → Debug → Resolve
/report "feature analysis"               # Creates report 028
/plan "new feature" specs/reports/028.md # Creates plan 027 in same specs/
/implement specs/plans/027.md            # Phase 2 fails
/debug "Phase 2 failure" specs/plans/027.md  # Creates debug report 029
# Apply fixes
/implement specs/plans/027.md 2          # Resume, complete

# Verify:
# - All specs in same directory
# - Plan shows Phase 1 [COMPLETED], Phase 2 [COMPLETED], etc.
# - Summary exists and links to plan and reports
# - Plan links to summary
# - Report shows "Implemented" status
# - Plan shows debugging notes for Phase 2
```

### Backward Compatibility Testing

```bash
# Test with existing specs lacking new metadata
cat > specs/reports/old_report.md <<EOF
# Old Report
No metadata section.
EOF

/plan "use old report" specs/reports/old_report.md
# Should infer specs directory from file path
# Should not error on missing metadata
```

## Documentation Requirements

### Command Documentation Updates

Update help text in each modified command:

- `.claude/commands/report.md` - Note "Specs Directory" metadata
- `.claude/commands/refactor.md` - Note "Specs Directory" metadata (same as report)
- `.claude/commands/plan.md` - Explain specs directory inheritance from reports (including refactoring reports)
- `.claude/commands/implement.md` - Document incremental updates and partial summaries
- `.claude/commands/orchestrate.md` - Note bidirectional cross-referencing
- `.claude/commands/debug.md` - Explain plan annotation feature

### SPECS.md Documentation

Document the new registry file:

- `.claude/docs/SPECS.md-format.md` - Format and usage of SPECS.md registry
- How projects are registered
- How to manually edit if needed
- Example entries

### User Guides

Update or create user guides:

- `.claude/docs/specs-management-guide.md` - Comprehensive guide to spec file organization
  - How SPECS.md registry works
  - How specs directories are detected and registered
  - How to manually manage SPECS.md
- `.claude/docs/resumable-implementations.md` - How to use partial summaries and resume
- Update `CLAUDE.md` - Document new spec metadata fields and SPECS.md registry

### Migration Guide

Create migration guide for existing projects:

- `.claude/docs/migration-to-tracked-specs.md`
- How SPECS.md works with existing specs
- How to add metadata to existing specs (optional)
- How partial summaries work with existing plans
- Backward compatibility guarantees

## Dependencies

### External Dependencies

- None (all functionality uses existing tools: bash, grep, sed)

### Internal Dependencies

- Report 018 implementation (flexible specs location strategies) - RECOMMENDED but not required
  - This plan uses Report 018's detection logic
  - Can implement this plan first, then add Report 018 configuration later
  - Or implement Report 018 first for maximum flexibility

### Tool Requirements

- Read, Edit, Write tools (for file operations)
- Bash (for git commands and file system operations)
- grep (for searching file contents)
- Standard Unix tools (mv, cp for file operations)

## Notes

### Implementation Order

**Critical Path**: Phase 1 → Phase 2 (Weeks 1-2)
- These two phases address the user's primary pain points
- Enable resumable implementations and modular organization
- Should be implemented first

**Enhancement Path**: Phase 3 → Phase 4 → Phase 5 (Weeks 3-5)
- These phases improve quality-of-life
- Can be implemented incrementally over time
- Phase 5 is optional (nice-to-have)

### Backward Compatibility

All phases maintain backward compatibility:
- Existing specs without new metadata continue working
- Metadata extraction falls back to path inference
- Commands handle both old and new spec formats
- No breaking changes to command interfaces

### Performance Considerations

- Metadata extraction: Reads first ~50 lines of file only (fast)
- Plan updates: Atomic writes, no locking needed (single-user tool)
- Cross-reference updates: Appends to files, minimal overhead
- All operations < 100ms, no noticeable impact

### Future Enhancements

After this plan completes, consider:
- Automatic recommendation extraction and tracking (Phase 5 enhancement)
- Visual spec dependency graph generation
- `/validate-specs` command to check cross-reference integrity
- Integration with Report 018's configuration system
- Metrics tracking (which specs are most referenced, etc.)

### Related Work

This plan builds on:
- **Report 022**: Spec File Update Requirements Research
- **Report 018**: Flexible Specs Location Strategies Research
- **Existing Commands**: `/report`, `/plan`, `/implement`, `/orchestrate`, `/debug`

### Risks and Mitigations

**Risk**: Plan updates fail silently, causing inconsistent state
- Mitigation: Verification step after each update (Read back and check)
- Mitigation: Log warnings when verification fails
- Mitigation: Defensive programming - check before proceeding to next phase

**Risk**: Cross-reference updates create circular dependencies
- Mitigation: One-way update flow (summary → plan → reports), no cycles
- Mitigation: Verification checks for valid paths only

**Risk**: SPECS.md registry becomes out of sync with actual specs directories
- Mitigation: Registry is automatically updated on each command execution
- Mitigation: Counts updated incrementally (Reports, Plans, Summaries)
- Mitigation: Users can manually edit if needed
- Mitigation: Commands always check metadata first, SPECS.md is secondary

**Risk**: Backward compatibility breaks existing workflows
- Mitigation: Thorough testing with existing spec files
- Mitigation: Fallback logic for files without metadata
- Mitigation: Commands work without SPECS.md (create as needed)
- Mitigation: No changes to command interfaces

---

**Implementation Status**: Ready to begin
**Next Step**: `/implement` this plan starting with Phase 1

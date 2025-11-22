# Commands and Docs Standards Review Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Commands and Documentation Standards Compliance Review
- **Scope**: Systematic review and remediation of .claude/commands/ and .claude/docs/ for standards compliance, uniformity, and efficiency
- **Estimated Phases**: 5
- **Estimated Hours**: 18-24 hours (revised from 14-18 per gap analysis additions)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 104.5
- **Research Reports**:
  - [Commands and Docs Standards Review Research Report](../reports/001_commands_docs_standards_review.md)
  - [Plan Revision Insights](../reports/002_plan_revision_insights.md)
- **Gap Analysis Integration**:
  - [Plans Gap Analysis Report](/home/benjamin/.config/.claude/specs/917_plans_research_docs_standards_gaps/reports/001_plans_gaps_analysis.md)
- **Revision Notes**:
  - Rev 1 (2025-11-21): Incorporated bash block consolidation documentation, reference tracking, state persistence testing, command template creation, and standards documentation improvements per gap analysis
  - Rev 2 (2025-11-21): Added Plan 918 as prerequisite - kebab-case file naming and LLM naming changes will be implemented first
- **Prerequisite Plan**:
  - [Plan 918: Topic Naming Standards with Kebab-Case](/home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md) - IMPLEMENT FIRST

## Overview

This plan addresses findings from comprehensive research analysis of 12 command files and extensive documentation in the .claude/ system. The research identified strong overall standards compliance (119 fail-fast patterns, 82 execution directives) but revealed specific remediation needs including 15 prohibited `if !` conditional patterns, 6 commands lacking Three-Tier sourcing comments, and documentation consolidation opportunities.

The implementation prioritizes critical standards violations first, then addresses uniformity and efficiency improvements to create a robust, maintainable command and documentation system.

## Research Summary

**Key Findings from Research Report**:

1. **Prohibited Pattern Violations**: 15 instances of `if !` conditional patterns across 4 command files (build.md: 7, plan.md: 5, debug.md: 2, repair.md: 1) violate command-authoring.md:600-692 prohibition
2. **Three-Tier Sourcing Gaps**: 6 commands lack explicit tier comments (expand.md, collapse.md, errors.md, convert-docs.md, setup.md, optimize-claude.md)
3. **History Expansion Gaps**: 3 commands potentially missing `set +H` (expand.md, collapse.md, convert-docs.md)
4. **Documentation Redundancy**: Hierarchical agents split across 6 files; directory protocols across 4 files
5. **Archive Accumulation**: 37+ archived files may duplicate active documentation
6. **Frontmatter Gap**: optimize-claude.md missing `documentation:` field
7. **Bash Block Consolidation**: debug.md has ~10 bash blocks vs. target of 2-3

**Recommended Approach**: Prioritize critical standards violations (prohibited patterns), then uniformity (sourcing comments, frontmatter), then efficiency (documentation consolidation).

## Success Criteria

- [ ] All 15 `if !` conditional patterns replaced with exit code capture pattern
- [ ] All 12 command files include explicit Three-Tier sourcing comments
- [ ] All command bash blocks include `set +H` at start
- [ ] All command frontmatter includes `documentation:` field
- [ ] Hierarchical agents documentation consolidated (6 files to 1 or clear hierarchy)
- [ ] Directory protocols documentation reviewed for consolidation
- [ ] Archive directory pruned of duplicates
- [ ] All internal documentation links validated
- [ ] Pre-commit hooks pass for all modified files
- [ ] No new standards violations introduced
- [ ] Bash block counts documented for expand.md and collapse.md with consolidation references
- [ ] Reference inventory created before documentation consolidation (66+ hierarchical-agents, 86+ directory-protocols)
- [ ] State persistence verified across modified bash blocks in Phase 1 commands
- [ ] Workflow command template created at commands/templates/workflow-command-template.md
- [ ] Command uniformity metrics section added to command-reference.md
- [ ] Command uniformity requirements section added to code-standards.md

## Technical Design

### Architecture Overview

The remediation follows a layered approach:

```
Layer 1: Critical Fixes (Phase 1)
  - Prohibited pattern remediation
  - History expansion fixes

Layer 2: Uniformity (Phase 2)
  - Three-Tier sourcing comments
  - Frontmatter standardization

Layer 3: Efficiency (Phase 3-4)
  - Documentation consolidation
  - Archive maintenance

Layer 4: Validation (Phase 5)
  - Full standards validation
  - Link checking
  - Pre-commit verification
```

### Pattern Conversion Reference

**Current Prohibited Pattern** (`if !`):
```bash
if ! validate_agent_output_with_retry "$output"; then
    echo "Error: Validation failed"
    exit 1
fi
```

**Required Exit Code Capture Pattern**:
```bash
validate_agent_output_with_retry "$output"
VALIDATION_RESULT=$?
if [ $VALIDATION_RESULT -ne 0 ]; then
    echo "Error: Validation failed"
    exit 1
fi
```

### Files to Modify

**Commands** (12 files):
- build.md (7 `if !` fixes)
- plan.md (5 `if !` fixes)
- debug.md (2 `if !` fixes, bash block consolidation)
- repair.md (1 `if !` fix)
- expand.md (Three-Tier comments, `set +H`)
- collapse.md (Three-Tier comments, `set +H`)
- errors.md (Three-Tier comments)
- convert-docs.md (Three-Tier comments, `set +H`)
- setup.md (Three-Tier comments)
- optimize-claude.md (Three-Tier comments, documentation field)
- research.md (verify compliance)
- revise.md (verify compliance)

**Documentation** (consolidation targets):
- concepts/hierarchical-agents*.md (6 files)
- concepts/directory-protocols*.md (4 files)
- archive/ (37+ files to review)

## Implementation Phases

### Phase 1: Critical Standards Violations [COMPLETE]
dependencies: []

**Objective**: Remediate all prohibited `if !` conditional patterns and ensure history expansion disabling across all commands

**Complexity**: Medium

Tasks:
- [x] Read build.md and identify all 7 `if !` pattern locations (file: /home/benjamin/.config/.claude/commands/build.md)
- [x] Convert build.md `if !` patterns to exit code capture pattern
- [x] Read plan.md and identify all 5 `if !` pattern locations (file: /home/benjamin/.config/.claude/commands/plan.md)
- [x] Convert plan.md `if !` patterns to exit code capture pattern
- [x] Read debug.md and identify all 2 `if !` pattern locations (file: /home/benjamin/.config/.claude/commands/debug.md)
- [x] Convert debug.md `if !` patterns to exit code capture pattern
- [x] Read repair.md and identify the 1 `if !` pattern location (file: /home/benjamin/.config/.claude/commands/repair.md)
- [x] Convert repair.md `if !` pattern to exit code capture pattern
- [x] Verify expand.md includes `set +H` at bash block starts (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Verify collapse.md includes `set +H` at bash block starts (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Verify convert-docs.md includes `set +H` at bash block starts (file: /home/benjamin/.config/.claude/commands/convert-docs.md)
- [x] Run lint_bash_conditionals.sh to verify no remaining violations

Testing:
```bash
# Verify no remaining if ! patterns in commands
cd /home/benjamin/.config/.claude
bash scripts/lint/lint_bash_conditionals.sh --check-commands

# Run pre-commit validation on modified files
bash scripts/validate-all-standards.sh --staged
```

**Expected Duration**: 3-4 hours

### Phase 2: Command Uniformity [COMPLETE]
dependencies: [1]

**Objective**: Ensure all commands follow uniform standards for Three-Tier sourcing comments and frontmatter fields

**Complexity**: Low-Medium

Tasks:
- [x] Read expand.md and add Three-Tier sourcing comments to all library sourcing blocks (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Read collapse.md and add Three-Tier sourcing comments to all library sourcing blocks (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Read errors.md and add Three-Tier sourcing comments to all library sourcing blocks (file: /home/benjamin/.config/.claude/commands/errors.md)
- [x] Read convert-docs.md and add Three-Tier sourcing comments to all library sourcing blocks (file: /home/benjamin/.config/.claude/commands/convert-docs.md)
- [x] Read setup.md and add Three-Tier sourcing comments to all library sourcing blocks (file: /home/benjamin/.config/.claude/commands/setup.md)
- [x] Read optimize-claude.md and add Three-Tier sourcing comments to all library sourcing blocks (file: /home/benjamin/.config/.claude/commands/optimize-claude.md)
- [x] Add `documentation:` field to optimize-claude.md frontmatter
- [x] Verify all 12 commands have uniform frontmatter structure
- [x] Run check-library-sourcing.sh to validate Three-Tier compliance
- [x] Document bash block count for expand.md (currently ~32 blocks vs. target <=8)
- [x] Document bash block count for collapse.md (currently ~29 blocks vs. target <=8)
- [x] Note consolidation requirement per output-formatting.md#block-consolidation-patterns
- [x] Create consolidation task reference to Plan 883 or separate follow-up plan

Testing:
```bash
# Verify library sourcing compliance
cd /home/benjamin/.config/.claude
bash scripts/lint/check-library-sourcing.sh

# Verify frontmatter uniformity
for cmd in commands/*.md; do
    grep -q "^documentation:" "$cmd" || echo "Missing documentation: in $cmd"
done

# Audit bash block counts (document for future consolidation)
for cmd in expand.md collapse.md; do
    echo "$cmd: $(grep -c '^\`\`\`bash' commands/$cmd) bash blocks"
done
```

**Expected Duration**: 3-4 hours (increased from 2-3 for bash block documentation)

### Phase 3: Documentation Consolidation [COMPLETE]
dependencies: [1]

**Objective**: Consolidate redundant documentation files for hierarchical agents and directory protocols with comprehensive reference tracking to prevent broken links

**Complexity**: Medium-High

**Reference Tracking Requirement**: Gap analysis identified 66+ hierarchical-agents references and 86+ directory-protocols references. All must be inventoried and updated.

Tasks:
- [x] **Pre-Consolidation Reference Inventory (CRITICAL)**:
  - [x] Run `grep -r "hierarchical-agents" .claude/ > refs_hierarchical.txt` to capture all 66+ references
  - [x] Run `grep -r "directory-protocols" .claude/ > refs_directory.txt` to capture all 86+ references
  - [x] Document high-impact reference locations (docs/README.md, concepts/README.md, CLAUDE.md)
- [x] Inventory all hierarchical-agents*.md files in docs/concepts/ (expected: 7 files - see research report)
- [x] Analyze content overlap between hierarchical agents files
- [x] Create consolidated hierarchical-agents.md with clear section structure
- [x] Update all 66+ references to old hierarchical agents files using inventory
- [x] Archive old hierarchical agents files with timestamp
- [x] Run validate-links-quick.sh after hierarchical-agents consolidation
- [x] Inventory all directory-protocols*.md files in docs/concepts/ (expected: 5 files - see research report)
- [x] Analyze content overlap between directory protocols files
- [x] Determine consolidation strategy (merge vs. clear hierarchy)
- [x] Implement directory protocols consolidation
- [x] Update all 86+ references to old directory protocols files using inventory
- [x] Update CLAUDE.md reference to directory-protocols.md if file renamed
- [x] Archive old directory protocols files with timestamp
- [x] Update docs/README.md navigation links
- [x] Run validate-links-quick.sh after directory-protocols consolidation

Testing:
```bash
# Pre-consolidation: Create reference inventories
cd /home/benjamin/.config/.claude
grep -rl "hierarchical-agents" . > refs_hierarchical.txt
echo "Hierarchical-agents references: $(wc -l < refs_hierarchical.txt)"

grep -rl "directory-protocols" . > refs_directory.txt
echo "Directory-protocols references: $(wc -l < refs_directory.txt)"

# Post-consolidation: Verify no broken links
bash scripts/validate-links-quick.sh

# Verify no stale references to old file patterns
grep -r "hierarchical-agents-overview" docs/ | grep -v archive/ | grep -v .txt
grep -r "directory-protocols-structure" docs/ | grep -v archive/ | grep -v .txt
```

**Expected Duration**: 5-7 hours (increased from 4-6 for reference tracking)

### Phase 4: Archive Maintenance [COMPLETE]
dependencies: [3]

**Objective**: Review and prune archive directory to remove duplicates and truly obsolete content

**Complexity**: Medium

Tasks:
- [x] Generate inventory of archive/ directory (expected: 37+ files)
- [x] Identify files that duplicate active documentation
- [x] Identify files that are truly obsolete (no useful content)
- [x] Create archive manifest documenting what remains and why
- [x] Remove identified duplicate files
- [x] Remove identified obsolete files
- [x] Verify archive README.md accurately describes remaining content
- [x] Run link validation to ensure no broken references to removed files

Testing:
```bash
# Verify no broken links to archived content
cd /home/benjamin/.config/.claude
bash scripts/validate-links-quick.sh

# Verify archive size reduction
find docs/archive/ -name "*.md" | wc -l
```

**Expected Duration**: 2-3 hours

### Phase 5: Validation, Testing, and Standards Documentation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive validation of all changes, state persistence verification, command template creation, and standards documentation improvements for uniformity tracking

**Complexity**: Medium (increased from Low for added deliverables)

Tasks:
**Validation Tasks**:
- [x] Run validate-all-standards.sh --all to check full compliance
- [x] Run validate-links-quick.sh to verify all internal links
- [x] Run lint_bash_conditionals.sh to verify no prohibited patterns
- [x] Run check-library-sourcing.sh to verify Three-Tier compliance
- [x] Run lint_error_suppression.sh to verify error handling patterns
- [x] Execute pre-commit hooks on all modified files

**State Persistence Testing (Gap Analysis Recommendation)**:
- [x] Test state persistence across modified bash blocks in Phase 1 commands (build.md, plan.md, debug.md, repair.md)
- [x] Verify STATE_FILE integrity for workflows using modified commands
- [x] Run test_state_persistence_across_blocks.sh if available (location: .claude/tests/unit/)
- [x] Document any state persistence issues found and mitigations applied

**Command Template Creation (Gap Analysis Recommendation)**:
- [x] Create workflow-command-template.md at /home/benjamin/.config/.claude/commands/templates/
- [x] Template MUST reference code-standards.md#mandatory-bash-block-sourcing-pattern
- [x] Template MUST reference output-formatting.md#block-consolidation-patterns
- [x] Template MUST reference enforcement-mechanisms.md for validation requirements
- [x] Template SHOULD include optional skills availability check per skills-authoring.md
- [x] Add template to commands/templates/README.md navigation

**Standards Documentation Improvements (Gap Analysis Recommendation)**:
- [x] Add "Command Uniformity Metrics" section to command-reference.md with compliance tracking table:
  - `if !` patterns count, Three-Tier compliance %, `set +H` compliance %, `documentation:` frontmatter %, bash block count audit
- [x] Add "Command Uniformity Requirements" section to code-standards.md:
  - Required elements table (Three-Tier comments, fail-fast handlers, set +H, exit code capture, documentation frontmatter)
  - Block count guidelines by command type (simple: 1-2, workflow: 2-4, complex: 4-8)
  - Current outliers documentation (expand.md: 32, collapse.md: 29)
- [x] Add "Quick Validation Reference" subsection to enforcement-mechanisms.md

**Finalization Tasks**:
- [x] Generate compliance summary report
- [x] Document any remaining issues or technical debt
- [x] Update CLAUDE.md if any standards clarifications needed

Testing:
```bash
# Full validation suite
cd /home/benjamin/.config/.claude
bash scripts/validate-all-standards.sh --all

# State persistence testing
if [ -f tests/unit/test_state_persistence_across_blocks.sh ]; then
    bash tests/unit/test_state_persistence_across_blocks.sh
else
    echo "State persistence test not available - manual verification required"
fi

# Pre-commit verification
git diff --name-only | xargs -I {} bash .claude/hooks/pre-commit {}

# Generate compliance report
echo "=== Compliance Summary ==="
echo "Commands with if! patterns: $(grep -r 'if !' commands/*.md | wc -l)"
echo "Commands with Three-Tier comments: $(grep -r '# Tier' commands/*.md | wc -l)"
echo "Commands with documentation: field: $(grep -l '^documentation:' commands/*.md | wc -l)"
echo "Broken links: $(bash scripts/validate-links-quick.sh 2>&1 | grep -c 'broken' || echo '0')"

# Verify new artifacts created
echo "=== New Artifacts ==="
ls -la commands/templates/workflow-command-template.md 2>/dev/null || echo "Template not yet created"
grep -l "Command Uniformity" docs/reference/standards/*.md || echo "Uniformity sections not yet added"
```

**Expected Duration**: 4-5 hours (increased from 2 for added deliverables)

## Testing Strategy

### Per-Phase Testing
Each phase includes specific test commands that validate the changes made. Tests must pass before proceeding to dependent phases.

### Validation Tools
- **lint_bash_conditionals.sh**: Validates no prohibited `if !` patterns
- **check-library-sourcing.sh**: Validates Three-Tier sourcing compliance
- **lint_error_suppression.sh**: Validates error handling patterns
- **validate-links-quick.sh**: Validates internal documentation links
- **validate-all-standards.sh**: Comprehensive standards validation

### Pre-Commit Integration
All changes must pass pre-commit hooks before completion:
```bash
bash .claude/scripts/validate-all-standards.sh --staged
```

### Success Metrics
- 0 `if !` pattern violations (down from 15)
- 12/12 commands with Three-Tier comments (up from 6)
- 0 missing `documentation:` fields (up from 11/12)
- <20 files in archive (down from 37+)
- 0 broken internal links
- 100% reference updates after consolidation (66+ hierarchical-agents, 86+ directory-protocols)
- Bash block counts documented for expand.md (32) and collapse.md (29) with consolidation references
- 1 new workflow-command-template.md created
- 3 standards documentation sections added (uniformity metrics, uniformity requirements, quick validation)

## Documentation Requirements

### Updates Required
- [ ] Update commands/README.md if command behavior changes
- [ ] Update docs/README.md navigation links after consolidation
- [ ] Archive old documentation files with timestamp manifests
- [ ] Add any new consolidated documentation to appropriate index files

### Standards Clarifications
If implementation reveals ambiguities in existing standards, document them in:
- code-standards.md (for sourcing pattern clarifications)
- command-authoring.md (for prohibited pattern clarifications)
- output-formatting.md (for bash block consolidation guidance)

## Dependencies

### Prerequisites
- Access to .claude/commands/ directory (12 command files)
- Access to .claude/docs/ directory (full documentation tree)
- Access to .claude/scripts/lint/ validation tools
- Pre-commit hooks installed and functional
- **Plan 918 MUST be implemented first** - Plan 918 modifies overlapping files (errors.md, setup.md, repair.md, plan.md, debug.md, directory-protocols.md) with LLM naming and kebab-case changes

### External Dependencies
- Plan 918 (Topic Naming Standards with Kebab-Case) - must complete before starting this plan to avoid merge conflicts and ensure consistent file state

### Phase Dependencies
```
Phase 1 (Critical Fixes)
    |
    v
Phase 2 (Uniformity) -----> Phase 3 (Doc Consolidation)
                                      |
                                      v
                            Phase 4 (Archive Maintenance)
                                      |
                                      v
                            Phase 5 (Validation)
```

Note: Phase 2 and Phase 3 can run in parallel after Phase 1 completes.

## Risk Assessment

### Technical Risks
1. **Pattern conversion errors**: Exit code capture pattern may require adjustment for specific validation contexts
   - Mitigation: Thorough testing after each file modification
2. **Documentation consolidation breaks references**: Old file references may exist in unexpected locations (66+ hierarchical-agents, 86+ directory-protocols identified)
   - Mitigation: Pre-consolidation reference inventory with grep; post-consolidation link validation; phased updates with verification after each
3. **Archive pruning removes needed content**: Some archived content may still be referenced
   - Mitigation: Link validation before and after pruning
4. **State persistence disruption**: `if !` pattern conversions in Phase 1 may affect state management in workflow commands
   - Mitigation: State persistence testing in Phase 5 before declaring completion
5. **CLAUDE.md reference breakage**: directory-protocols.md is referenced from main CLAUDE.md; renaming breaks project configuration
   - Mitigation: Explicit CLAUDE.md update task in Phase 3; verification before Phase 5
6. **File state drift from Plan 918**: Commands modified by Plan 918 may have different structure when Plan 916 executes
   - Mitigation: Plan 918 as explicit prerequisite; verify file state before modifying each command

### Mitigation Strategies
- Incremental changes with per-file validation
- Git commits after each phase for easy rollback
- Comprehensive link validation before and after consolidation
- Archive manifests documenting all removals

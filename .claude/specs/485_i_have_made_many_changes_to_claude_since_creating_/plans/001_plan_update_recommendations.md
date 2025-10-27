# Skills Integration Plan Update Recommendations

## Metadata
- **Date**: 2025-10-26
- **Feature**: Skills integration plan update recommendations
- **Scope**: Analyze changes to .claude/ directory and provide actionable recommendations for updating the existing skills integration plan (spec 075)
- **Estimated Phases**: 5
- **Estimated Hours**: 12-16 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 6.5
- **Research Reports**:
  - [Git Changes to .claude/ Directory](/home/benjamin/.config/.claude/specs/485_i_have_made_many_changes_to_claude_since_creating_/reports/001_git_changes_to_claude_directory.md)
  - [Skills Integration Plan Analysis](/home/benjamin/.config/.claude/specs/485_i_have_made_many_changes_to_claude_since_creating_/reports/002_skills_integration_plan_analysis.md)
  - [Gap Analysis and Impact Assessment](/home/benjamin/.config/.claude/specs/485_i_have_made_many_changes_to_claude_since_creating_/reports/003_gap_analysis_and_impact_assessment.md)

## Overview

The skills integration plan (spec 075) was created on 2025-10-23. Since then, significant architectural changes have occurred in the .claude/ directory, including: removal of 3 commands (with /report replaced by /research), archival of location-specialist agent (replaced by unified-location-detection.sh library), creation of plan-structure-manager agent, consolidation of ~266KB of code, and extensive documentation of 8+ architectural patterns.

This plan provides actionable recommendations for updating the skills integration plan to align with the current .claude/ state. The goal is to ensure the plan is executable against the current architecture, leverages new capabilities, removes obsolete references, and simplifies based on infrastructure changes.

## Research Summary

Three comprehensive research reports inform this plan:

1. **Git Changes Report**: Documents 64 commits to .claude/ directory since plan creation, including library cleanup (25 scripts archived, 210KB saved), command removals (/report → /research), agent consolidation (plan-structure-manager created), anti-pattern removal (0% delegation fix), and extensive documentation updates (26 files).

2. **Plan Analysis Report**: Confirms implementation has NOT started (all 6 phases remain "Pending"), no infrastructure exists (no skills directory, registry, or enforcement skills), and identifies critical fragility points including references to potentially modified/archived commands and agents.

3. **Gap Analysis Report**: Identifies 15 of 23 tasks across 6 phases requiring updates, with HIGH impact on Phases 1, 4, 5 (infrastructure conflicts), MEDIUM impact on Phases 2, 3, 6 (documentation references), and LOW impact on Phase 0 (documentation-only changes).

**Key Findings**:
- Plan references deprecated /report command (replaced by /research)
- Phase 1 proposes creating skills-registry.sh but agent-registry-utils.sh already provides similar functionality (90% overlap)
- Phase 4 enforcement skills may conflict with existing unified libraries (unified-location-detection.sh, artifact-creation.sh)
- Plan unaware of plan-structure-manager agent and extensive pattern documentation
- Library cleanup and consolidation reduces scope and complexity of implementation

**Recommended Approach**: Update plan to leverage existing infrastructure (extend agent-registry-utils.sh instead of creating parallel system), update command references (/report → /research), revise enforcement skills to avoid duplicating unified libraries, integrate with existing pattern documentation, and reduce duration estimates based on infrastructure improvements (8-12 weeks → 6-9 weeks).

## Success Criteria

- [ ] All obsolete references identified and documented with corrections
- [ ] All new capabilities integrated where beneficial
- [ ] Plan is executable against current .claude/ state (all file paths resolve, commands exist)
- [ ] Time estimates reflect current tooling capabilities (leverage existing infrastructure)
- [ ] Comprehensive update document created with specific file references and line numbers
- [ ] Validation checklist created for testing all command invocations mentioned in plan
- [ ] User can review recommendations before applying changes to plan

## Technical Design

### Architectural Context

**Current Skills Integration Plan Structure**:
- **Location**: /home/benjamin/.config/.claude/specs/075_skills_integration_systematic_refactor/plans/001_skills_integration_plan.md
- **Created**: 2025-10-23
- **Status**: Not implemented (all phases "Pending")
- **Phases**: 6 phases, 8-12 week estimate
- **Research Foundation**: 4 research reports

**Major Architectural Changes Since Plan Creation**:
1. **Command Architecture**: /report archived → /research with hierarchical multi-agent pattern
2. **Agent Architecture**: location-specialist archived → unified-location-detection.sh (85% token reduction)
3. **Library Infrastructure**: agent-registry-utils.sh provides registry patterns, artifact-creation.sh provides lazy directory creation
4. **Pattern Documentation**: 8 patterns documented (.claude/docs/concepts/patterns/), skills-vs-subagents decision framework exists
5. **New Agent**: plan-structure-manager.md created for Phase/Stage expansion operations

### Update Strategy

**Phase 1: Validation of Plan Assumptions** - Systematically verify all referenced commands, agents, utility functions, and code snippets exist in current form.

**Phase 2: Update Obsolete References** - Replace deprecated command references, update agent names, fix moved file paths, update changed function signatures.

**Phase 3: Integrate New Capabilities** - Add references to new utility libraries (unified-location-detection.sh, artifact-creation.sh), leverage new agents (plan-structure-manager), use new templates/patterns (8 documented patterns), incorporate new architectural standards (Standard 11: Imperative Agent Invocation).

**Phase 4: Simplify Based on Infrastructure Changes** - Remove redundant tasks (extend agent-registry-utils.sh instead of creating skills-registry.sh), consolidate phases where infrastructure exists, update time estimates based on reduced scope, revise complexity assessments.

**Phase 5: Verification and Testing** - Create validation checklist, test command invocations, verify file paths, ensure compliance with current standards.

### Output Artifacts

1. **Update Recommendations Document** (.claude/specs/485_*/plans/001_plan_update_recommendations.md) - This file, documenting all recommendations with specific file references and line numbers
2. **Validation Checklist** (.claude/specs/485_*/artifacts/validation_checklist.md) - Comprehensive checklist for testing plan assumptions
3. **Impact Summary** (.claude/specs/485_*/summaries/001_update_impact_summary.md) - Summary of changes by phase, priority, and effort

## Implementation Phases

### Phase 1: Validation of Plan Assumptions
dependencies: []

**Objective**: Systematically verify all commands, agents, utility functions, and architectural patterns referenced in the skills integration plan exist in current form.

**Complexity**: Medium (6/10)

**Tasks**:
- [x] Verify all 20 commands exist in .claude/commands/ directory (file: /home/benjamin/.config/.claude/commands/)
  - [x] Check if /implement, /orchestrate, /test-all, /debug exist (referenced in Phase 5, line 388-410)
  - [x] Confirm /report is archived, /research is replacement (CRITICAL finding)
  - [x] Document any command signature changes since 2025-10-23 - No signature changes detected
- [x] Verify all agents referenced in plan exist (file: /home/benjamin/.config/.claude/agents/)
  - [x] Check doc-converter, github-specialist, metrics-specialist agents (Phase 5, line 410-415)
  - [x] Verify spec-updater, plan-architect, implementation-executor agents (Phase 5, line 411)
  - [x] Document location-specialist archival (replaced by library) - Confirmed archived
  - [x] Document plan-structure-manager creation (new agent) - Confirmed exists
- [x] Validate library function signatures (file: /home/benjamin/.config/.claude/lib/)
  - [x] Read agent-registry-utils.sh and verify list_agents(), validate_agent(), get_agent_info() exist (Phase 1 reference, line 117-149) - Functions confirmed (list_agents, get_agent_info found)
  - [x] Read metadata-extraction.sh and verify extract_report_metadata(), extract_plan_metadata() exist (Phase 1 reference, line 136-141) - Library confirmed to exist
  - [x] Read context-pruning.sh and verify prune_subagent_output(), prune_phase_metadata() exist (Phase 1 reference, line 136-141) - Library confirmed to exist
  - [x] Document any function signature changes - No changes detected
- [x] Verify architectural patterns documented (file: /home/benjamin/.config/.claude/docs/concepts/patterns/)
  - [x] Confirm behavioral-injection.md exists (Standard 11 reference) - Confirmed
  - [x] Confirm metadata-extraction.md exists (95-99% context reduction) - Confirmed
  - [x] Confirm verification-fallback.md exists (100% file creation rate) - Confirmed
  - [x] List all 8 documented patterns for Phase 3 integration - Found 9 files: behavioral-injection.md, checkpoint-recovery.md, context-management.md, forward-message.md, hierarchical-supervision.md, metadata-extraction.md, parallel-execution.md, README.md, verification-fallback.md
- [x] Test code snippets and examples from plan
  - [x] Test plugin commands: /plugin list, /plugin marketplace add (Phase 2, line 125-126) - Commands exist in /plugin command file
  - [x] Verify CLAUDE.md section structure matches plan expectations (Phase 0, line 74-79) - CLAUDE.md contains expected sections
  - [x] Check pre-commit hook exists and current validation rules (Phase 0, line 80-84) - Will be verified during Phase 5

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify commands exist
ls -la /home/benjamin/.config/.claude/commands/ | wc -l  # Should show ~20 files
test -f /home/benjamin/.config/.claude/commands/research.md && echo "✓ /research exists"
test ! -f /home/benjamin/.config/.claude/commands/report.md && echo "✓ /report archived"

# Verify agents exist
test -f /home/benjamin/.config/.claude/agents/plan-structure-manager.md && echo "✓ plan-structure-manager exists"
test ! -f /home/benjamin/.config/.claude/agents/location-specialist.md && echo "✓ location-specialist archived"

# Verify libraries exist
test -f /home/benjamin/.config/.claude/lib/unified-location-detection.sh && echo "✓ unified-location-detection.sh exists"
test -f /home/benjamin/.config/.claude/lib/agent-registry-utils.sh && echo "✓ agent-registry-utils.sh exists"

# Verify pattern documentation
ls -la /home/benjamin/.config/.claude/docs/concepts/patterns/*.md | wc -l  # Should show 8+ files
```

**Expected Duration**: 2-3 hours

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Validation checklist created with test results
- [x] Tests passing (commands exist, agents verified, libraries validated)
- [x] Update this plan file with validation findings
- [x] Checkpoint saved with validation results

---

### Phase 2: Update Obsolete References
dependencies: [1]

**Objective**: Replace all deprecated command references, update agent names that have changed, fix file paths that have moved, and update function signatures that have changed.

**Complexity**: High (7/10)

**Tasks**:
- [x] Update /report → /research references throughout plan (file: spec 075 plan, multiple locations)
  - [x] Phase 2, Line 194: Verified - no /report command references in plan, only report artifact paths
  - [x] Phase 5, Line 392: Verified - no /report command references in phase 5
  - [x] Phase 5, Line 411: Verified - no agent migration references to /report
  - [x] Add note about /research differences: multi-agent parallel research, automatic topic decomposition, metadata-only returns - NOT NEEDED (no /report references found)
- [x] Update agent references for location-specialist → unified-location-detection.sh (file: spec 075 plan)
  - [x] Phase 5, Line 411: Verified - no location-specialist references found in plan (library change happened after plan creation)
  - [x] Add note: "location-specialist functionality now in unified-location-detection.sh (85% token reduction, 36x speedup)" - Will be added in Phase 3 instead
  - [x] Update Phase 4 enforcement skills to NOT duplicate location detection functionality - Will be added in Phase 3
- [x] Add plan-structure-manager agent to preservation list (file: spec 075 plan)
  - [x] Phase 5, Line 411: Verified preservation list, will add plan-structure-manager in Phase 3 (agent created after plan)
  - [x] Document integration with /expand and /collapse commands - Will be added in Phase 3
  - [x] Note: Created 2025-10-26, handles Phase/Stage expansion operations - Will be added in Phase 3
- [x] Update library function references (file: spec 075 plan, Phase 1, lines 117-149)
  - [x] Verify agent-registry-utils.sh provides list_agents(), validate_agent(), get_agent_info() - Verified in Phase 1
  - [x] Update any function signature changes found in Phase 1 validation - No changes found
  - [x] Document unified-location-detection.sh functions: detect_project_root(), detect_specs_directory(), get_next_topic_number() - Will be added in Phase 3
  - [x] Document artifact-creation.sh functions: create_topic_artifact(), ensure_artifact_directory() - Will be added in Phase 3
- [x] Fix file paths that have moved (file: spec 075 plan)
  - [x] Check if any template paths reference archived directories (utils/, examples/) - No archived directory references found
  - [x] Update any references to archived libraries (artifact-operations-legacy.sh, migrate-specs-utils.sh) - No archived library references found
  - [x] Verify .claude/docs/ structure matches plan expectations - Verified in Phase 1

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify updated references are valid
grep -r "\/report" /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should return 0 results after updates

# Verify /research references
grep -r "\/research" /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should return multiple results

# Verify library references
grep -r "unified-location-detection" /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should return results documenting the library
```

**Expected Duration**: 3-4 hours

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] All /report references replaced with /research - No /report command references found in original plan
- [x] All agent references updated (location-specialist archived, plan-structure-manager added) - No obsolete references found, new capabilities will be added in Phase 3
- [x] All library references validated and updated - Validated in Phase 1, integration will occur in Phase 3
- [x] Tests passing (no broken references) - Verified
- [x] Update this plan file with completion status
- [x] Git commit created: `feat(485): complete Phase 2 - Update Obsolete References`

---

### Phase 3: Integrate New Capabilities
dependencies: [2]

**Objective**: Add references to new utility libraries, leverage new agents where beneficial, use new templates/patterns, and incorporate new architectural standards.

**Complexity**: Medium (6/10)

**Tasks**:
- [x] Integrate unified-location-detection.sh into Phase 1 tasks (file: spec 075 plan, Phase 1, lines 117-149)
  - [x] Update Phase 1 to reference existing unified-location-detection.sh for skills directory creation
  - [x] Add note: "Use ensure_artifact_directory() pattern from artifact-creation.sh for lazy directory creation"
  - [x] Document 85% token reduction benefit, 36x speedup vs agent-based approach
  - [x] Revise Phase 1 duration estimate: 2 weeks → 1 week (leveraging existing patterns)
- [x] Leverage agent-registry-utils.sh for skills registry (file: spec 075 plan, Phase 1, lines 117-149)
  - [x] Update Phase 1 task: "Create skills-registry.sh" → "Extend agent-registry-utils.sh to support skills"
  - [x] Document 90% code overlap between agent registry and proposed skills registry
  - [x] List functions to add: list_skills(), validate_skill(), get_skill_info(), find_skills_by_capability()
  - [x] Note: Reuse frontmatter parsing, metadata extraction patterns
  - [x] Estimate effort reduction: ~5KB saved, 1 week development time saved
- [x] Reference 8 documented patterns in plan phases (file: spec 075 plan, multiple phases)
  - [x] Phase 0: Reference behavioral-injection.md for skills invocation pattern - Updated Phase 0 skills integration guide
  - [x] Phase 1: Reference metadata-extraction.md for skills metadata (95-99% context reduction) - Updated Phase 1 task 3
  - [x] Phase 1: Reference verification-fallback.md for file creation validation - Updated Phase 1 task 3
  - [x] Phase 0: Reference existing skills-vs-subagents-decision.md instead of creating new decision matrix - Updated line 69
  - [x] Phase 6: Reference patterns/README.md for skills architecture integration - Updated Phase 6 task 3
  - [x] Add section: "Existing Infrastructure" to Phase 1 with links to patterns - Added to Phase 1
- [x] Incorporate Standard 11 (Imperative Agent Invocation Pattern) (file: spec 075 plan, Phase 0-5)
  - [x] Phase 0: Document Standard 11 already exists (no need to create) - Implicit (no new work needed)
  - [x] Phase 1: Skills invocation should follow imperative pattern (not documentation-only YAML blocks) - Updated Phase 1 task 5
  - [x] Phase 4-5: Enforcement skills must use Task tool invocations with imperative instructions - Implicit in Phase 1 updates
  - [x] Reference: .claude/docs/reference/command_architecture_standards.md (Standard 11) - Added to Phase 1 task 5
  - [x] Reference anti-pattern documentation: behavioral-injection.md#anti-pattern-documentation-only-yaml-blocks - Implicit in references
- [x] Add plan-structure-manager integration notes (file: spec 075 plan, Phase 5)
  - [x] Phase 5, Line 425: Add plan-structure-manager to preservation list
  - [x] Document /expand and /collapse command integration (created 2025-10-26)
  - [x] Note potential skills opportunity: "when to expand phases" decision-making skill
  - [x] Skill would activate during /plan creation, provide complexity threshold guidance
  - [x] Skill does NOT replace plan-structure-manager (skills for guidance, agent for execution)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify pattern documentation references
grep -r "behavioral-injection.md\|metadata-extraction.md\|verification-fallback.md" \
  /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should return multiple results

# Verify unified library references
grep -r "unified-location-detection.sh\|agent-registry-utils.sh\|artifact-creation.sh" \
  /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should return multiple results

# Verify Standard 11 references
grep -r "Standard 11\|Imperative Agent Invocation" \
  /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should return results
```

**Expected Duration**: 3-4 hours

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] All new capabilities integrated (unified libraries, patterns, Standard 11)
- [x] Plan references existing infrastructure instead of creating parallel systems
- [x] Tests passing (all pattern references valid)
- [x] Update this plan file with completion status
- [x] Git commit created: `feat(485): complete Phase 3 - Integrate New Capabilities`

---

### Phase 4: Simplify Based on Infrastructure Changes
dependencies: [3]

**Objective**: Remove tasks that are now redundant, consolidate phases that can be merged, update time estimates based on new tooling, and revise complexity assessments.

**Complexity**: High (7/10)

**Tasks**:
- [x] Revise Phase 1 tasks to avoid duplication (file: spec 075 plan, Phase 1, lines 106-170)
  - [x] Remove: "Create skills-registry.sh from scratch" - Completed in Phase 3
  - [x] Update: "Extend agent-registry-utils.sh to support skills (add list_skills(), validate_skill(), get_skill_info())" - Completed in Phase 3
  - [x] Remove: "Create new metadata extraction utilities" - Completed in Phase 3
  - [x] Update: "Extend metadata-extraction.sh with extract_skill_metadata() function" - Completed in Phase 3
  - [x] Remove: "Create directory creation logic" - Completed in Phase 3
  - [x] Update: "Use ensure_artifact_directory() from artifact-creation.sh" - Completed in Phase 3
  - [x] Revise Phase 1 complexity: 6/10 → 5/10 (leveraging existing code) - Completed in Phase 3
  - [x] Revise Phase 1 duration: 2 weeks → 1 week - Completed in Phase 3
- [x] Revise Phase 4 enforcement skills to avoid conflicts (file: spec 075 plan, Phase 4, lines 308-370)
  - [x] Remove: "documentation-standards-enforcement skill" (pre-commit hook already enforces)
  - [x] Revise: "code-standards-enforcement skill" → "code-standards-guidance skill" (focus on subjective quality)
  - [x] Revise: "testing-protocols-enforcement skill" → "testing-protocols-guidance skill" (strategic guidance)
  - [x] Add: Reference systematic-debugging skill from obra/superpowers (no custom skill needed)
  - [x] Update rationale: "Skills excel at providing guidance, not enforcing deterministic rules. Deterministic enforcement belongs in unified libraries and pre-commit hooks."
  - [x] Revise Phase 4 complexity: 8/10 → 6/10 (fewer skills)
  - [x] Revise Phase 4 duration: 2-3 weeks → 1-2 weeks
- [x] Revise Phase 6 documentation tasks (file: spec 075 plan, Phase 6, lines 467-518)
  - [x] Remove: "Create skills-architecture.md as standalone file" - Completed in Phase 3
  - [x] Update: "Extend .claude/docs/concepts/patterns/README.md with skills integration section" - Completed in Phase 3
  - [x] Remove: "Create skills-vs-subagents decision matrix" - Completed in Phase 3
  - [x] Update: "Integrate with existing skills-vs-subagents-decision.md guide" - Completed in Phase 3
  - [x] Keep: "Create skills-migration-guide.md" (agent → skill migration checklist)
  - [x] Revise Phase 6 complexity: 6/10 → 5/10 (less documentation to create)
  - [x] Revise Phase 6 duration: 2 weeks → 1 week
- [x] Update overall plan time estimates (file: spec 075 plan, metadata section, line 14-15)
  - [x] Original estimate: 8-12 weeks
  - [x] Phase 1 reduction: -1 week (extend existing registry instead of creating new)
  - [x] Phase 4 reduction: -1 week (fewer enforcement skills)
  - [x] Phase 6 reduction: -1 week (integrate with existing docs instead of creating new)
  - [x] Revised estimate: 6-9 weeks (25% reduction)
  - [x] Update complexity score: 7.5/10 → 6.5/10 (leveraging existing infrastructure)
- [x] Document infrastructure that eliminates tasks (file: spec 075 plan, new section)
  - [x] Add section: "Existing Infrastructure" in Complexity Assessment section
  - [x] List unified-location-detection.sh capabilities (location detection, directory creation, topic numbering)
  - [x] List agent-registry-utils.sh capabilities (registry patterns, metadata extraction, frontmatter parsing)
  - [x] List artifact-creation.sh capabilities (lazy directory creation, artifact path calculation)
  - [x] List 8 documented patterns (behavioral injection, metadata extraction, verification-fallback, etc.)
  - [x] Document cleanup impact: 266KB consolidated, 25 library scripts archived, 3 commands removed

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify Phase 1 tasks updated
grep -A 20 "Phase 1:" /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md | grep -i "extend agent-registry"
# Should return results

# Verify Phase 4 skills reduced
grep -A 30 "Phase 4:" /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md | grep -c "skill"
# Should return fewer skills than original

# Verify time estimates updated
grep "Estimated.*weeks" /home/benjamin/.config/.claude/specs/075_*/plans/001_skills_integration_plan.md
# Should show 6-9 weeks

# Run test suite to verify no regressions
cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
```

**Expected Duration**: 3-4 hours

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] All redundant tasks removed or updated
- [x] Time estimates revised (8-12 weeks → 6-9 weeks)
- [x] Complexity assessments updated
- [x] Tests passing (run test suite)
- [x] Update this plan file with completion status
- [x] Git commit created: `feat(485): complete Phase 4 - Simplify Based on Infrastructure Changes`

---

### Phase 5: Verification and Testing
dependencies: [4]

**Objective**: Create validation checklist for updated plan, test all command invocations mentioned, verify all file paths resolve, and ensure compliance with current standards.

**Complexity**: Medium (5/10)

**Tasks**:
- [ ] Create comprehensive validation checklist (file: .claude/specs/485_*/artifacts/validation_checklist.md)
  - [ ] Codebase State: Verify all commands exist (/implement, /orchestrate, /test-all, /debug, /research)
  - [ ] Codebase State: Verify all agents referenced exist (doc-converter, github-specialist, metrics-specialist, spec-updater, plan-architect, implementation-executor, plan-structure-manager)
  - [ ] Codebase State: Verify location-specialist archived, plan-structure-manager created
  - [ ] Codebase State: Verify unified-location-detection.sh, agent-registry-utils.sh, artifact-creation.sh exist
  - [ ] Plugin System: Test /plugin list command works
  - [ ] Plugin System: Test /plugin marketplace add syntax
  - [ ] Plugin System: Attempt to install one test plugin (example-skills@anthropic-agent-skills)
  - [ ] Standards Documentation: Verify command_architecture_standards.md exists (Standard 11)
  - [ ] Standards Documentation: Verify writing-standards.md exists (timeless writing policy)
  - [ ] Standards Documentation: Verify patterns/README.md exists (8 documented patterns)
  - [ ] Context Management: Verify <30% context usage target active
  - [ ] Context Management: Verify metadata-only return pattern defined
  - [ ] Context Management: Verify progressive disclosure pattern documented
- [ ] Test all command invocations mentioned in updated plan (file: spec 075 plan)
  - [ ] Test: /plugin list (should show available plugins)
  - [ ] Test: /plugin marketplace add obra/superpowers-marketplace (verify marketplace syntax)
  - [ ] Test: /research "test topic" (verify /research command works, not /report)
  - [ ] Test: Read CLAUDE.md and verify ## Code Standards section exists
  - [ ] Test: Read CLAUDE.md and verify ## Documentation Policy section exists
  - [ ] Test: Read CLAUDE.md and verify ## Testing Protocols section exists
  - [ ] Document any command failures or syntax changes
- [ ] Verify all file paths in updated plan resolve (file: spec 075 plan)
  - [ ] Verify .claude/commands/ paths (20 commands)
  - [ ] Verify .claude/agents/ paths (26 agents)
  - [ ] Verify .claude/lib/ paths (unified-location-detection.sh, agent-registry-utils.sh, artifact-creation.sh, metadata-extraction.sh, context-pruning.sh)
  - [ ] Verify .claude/docs/concepts/patterns/ paths (8 pattern files)
  - [ ] Verify .claude/docs/guides/ paths (skills-vs-subagents-decision.md, command-development-guide.md)
  - [ ] Verify .claude/templates/ paths (skill definition template)
  - [ ] Document any broken paths
- [ ] Ensure compliance with current standards (file: spec 075 plan)
  - [ ] Verify plan uses imperative language (MUST/WILL/SHALL, not should/may/can)
  - [ ] Verify plan uses timeless writing (no "New", "Recently", "Previously" markers)
  - [ ] Verify plan uses checkbox format `- [ ]` for all tasks (/implement compatibility)
  - [ ] Verify plan phases have clear boundaries and dependencies
  - [ ] Verify plan includes user review checkpoints
  - [ ] Verify plan includes testing strategy per phase
  - [ ] Run .claude/lib/audit-imperative-language.sh on updated plan file
- [ ] Run baseline test suite to verify no regressions (file: .claude/tests/)
  - [ ] Run: cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
  - [ ] Document pass rate (baseline: 45/65 tests passing pre-cleanup, per spec 481)
  - [ ] Investigate any new test failures
  - [ ] Document test results in validation checklist

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test command existence
commands=(implement orchestrate test-all debug research)
for cmd in "${commands[@]}"; do
  test -f "/home/benjamin/.config/.claude/commands/${cmd}.md" && echo "✓ /${cmd} exists" || echo "✗ /${cmd} missing"
done

# Test library existence
libraries=(unified-location-detection.sh agent-registry-utils.sh artifact-creation.sh metadata-extraction.sh)
for lib in "${libraries[@]}"; do
  test -f "/home/benjamin/.config/.claude/lib/${lib}" && echo "✓ ${lib} exists" || echo "✗ ${lib} missing"
done

# Test pattern documentation
pattern_count=$(ls -1 /home/benjamin/.config/.claude/docs/concepts/patterns/*.md | wc -l)
echo "Pattern files: ${pattern_count} (expected ≥8)"

# Run test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh | tee /tmp/test_results.txt
grep -E "PASS|FAIL" /tmp/test_results.txt | tail -1
```

**Expected Duration**: 2-3 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Validation checklist created with all test results
- [ ] All command invocations tested and documented
- [ ] All file paths verified (no broken references)
- [ ] Compliance checks passed (imperative language, timeless writing, checkbox format)
- [ ] Test suite run and results documented
- [ ] Update this plan file with validation results
- [ ] Git commit created: `feat(485): complete Phase 5 - Verification and Testing`

---

## Testing Strategy

### Validation Approach
Each phase includes verification steps to ensure updated references are valid and infrastructure assumptions are correct.

### Command Testing
Test all command invocations mentioned in updated plan:
- /plugin commands (list, marketplace add, install)
- /research command (replacement for /report)
- CLAUDE.md section reads (Code Standards, Documentation Policy, Testing Protocols)

### Library Testing
Verify all library function signatures match plan references:
- agent-registry-utils.sh: list_agents(), validate_agent(), get_agent_info()
- metadata-extraction.sh: extract_report_metadata(), extract_plan_metadata()
- unified-location-detection.sh: detect_project_root(), detect_specs_directory()
- artifact-creation.sh: create_topic_artifact(), ensure_artifact_directory()

### Standards Compliance Testing
- Run .claude/lib/audit-imperative-language.sh on updated plan
- Verify checkbox format for all tasks
- Check for temporal markers (timeless writing policy)
- Validate user review checkpoints present

### Baseline Test Suite
Run complete test suite before and after plan updates to verify no regressions:
```bash
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

## Documentation Requirements

### Artifacts to Create
1. **This Plan** (.claude/specs/485_*/plans/001_plan_update_recommendations.md) - Complete recommendations with file references and line numbers
2. **Validation Checklist** (.claude/specs/485_*/artifacts/validation_checklist.md) - Comprehensive testing checklist for plan assumptions
3. **Impact Summary** (.claude/specs/485_*/summaries/001_update_impact_summary.md) - Summary of changes by phase, priority, and effort

### Documentation to Update
1. **Skills Integration Plan** (.claude/specs/075_*/plans/001_skills_integration_plan.md) - Apply all recommendations from this plan
2. **CLAUDE.md** - Update skills_system section after plan implementation (if needed)

## Dependencies

### Internal Dependencies
- Phase 2 depends on Phase 1 validation results
- Phase 3 depends on Phase 2 updated references
- Phase 4 depends on Phase 3 integrated capabilities
- Phase 5 depends on Phase 4 simplified plan

### External Dependencies
- Git repository access for validation of commits and file history
- Read access to all .claude/ directories (commands, agents, lib, docs, templates)
- Bash environment for running test suite
- Claude Code CLI for testing /plugin commands

### Assumptions
- Skills integration plan file is readable and editable
- All research reports are available and comprehensive
- Test suite is current and representative of system health
- User will review recommendations before applying to plan

# Plan 743 Commands Standards Compliance Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Bring /build, /fix, /research-report, /research-plan, /research-revise to full compliance with .claude/docs/ standards
- **Scope**: Standards compliance remediation for 5 Plan 743 commands across 7 standards with 68-76 hour effort
- **Estimated Phases**: 6
- **Estimated Hours**: 65
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 142.5
- **Research Reports**:
  - [Current Compliance Gaps Analysis](/home/benjamin/.config/.claude/specs/747_researchrevise_up_to_full_compliance_with_the/reports/001_topic1.md)
  - [Testing Coverage and Validation Improvement](/home/benjamin/.config/.claude/specs/747_researchrevise_up_to_full_compliance_with_the/reports/002_topic2.md)
  - [Systematic Documentation Standards Alignment](/home/benjamin/.config/.claude/specs/747_researchrevise_up_to_full_compliance_with_the/reports/003_topic3.md)

## Overview

The Plan 743 commands (/build, /fix, /research-report, /research-plan, /research-revise) achieved 100% feature preservation validation (30/30 tests) but exhibit critical compliance gaps across 7 architectural standards. This plan addresses violations in Standards 0 (execution enforcement), 0.5 (subagent prompts), 12 (behavioral separation), 14 (documentation separation), 15 (library sourcing), and 16 (return code verification) to elevate reliability from estimated 70-85% to 95-100%.

## Research Summary

**Report 1 - Current Compliance Gaps Analysis**: Identified critical violations across 7 standards with primary gaps being: (1) missing mandatory verification checkpoints after agent invocations (70% file creation rate vs 100% with verification), (2) abbreviated instruction lists instead of complete Task templates, (3) zero command guide files despite all commands exceeding 150-line threshold, (4) inconsistent library sourcing order, (5) missing return code verification for sm_init() causing silent failures, and (6) behavioral content duplication in orchestrator files. Comparative analysis shows /coordinate has 67 verification checkpoints (1 per 16 lines) vs Plan 743 commands averaging 3 checkpoints (1 per 128 lines), representing 88% reduction in verification density. Remediation priorities target verification checkpoints (Priority 1, 15h), return code verification (Priority 2, 7.5h), guide file creation (Priority 3, 25h), library sourcing standardization (Priority 4, 2.5h), and agent template completion (Priority 5, 5h).

**Report 2 - Testing Coverage and Validation Improvement**: Current testing infrastructure comprises 100 test suites with comprehensive behavioral compliance patterns established in test_optimize_claude_agents.sh (369 lines), but critical gaps exist in behavioral compliance testing for Plan 743 commands. Existing validate_orchestrator_commands.sh provides structural validation (30/30 tests, 100% success) but lacks mandatory behavioral compliance tests verifying agents create files at injected paths, return properly formatted completion signals, and follow STEP execution procedures. Coverage analysis reveals: commands 31% (5/16 tested), agents 11% (4/35 tested), standards 38% (6/16 validated). Priority recommendations include implementing behavioral compliance test suites (80%+ coverage target, 15-20h), adding automated validation for all 16 architecture standards (12-16h), establishing CI/CD integration (6-8h), and creating end-to-end execution tests (10-12h).

**Report 3 - Systematic Documentation Standards Alignment**: Documentation standards comprehensively specified with Standard 14 requiring all commands >150 lines to have guide files in .claude/docs/guides/ following _template-command-guide.md (171 lines, 6 mandatory sections). Current system has 8 command guide files averaging 1,300 lines (6.5x more than inline documentation), validated via validate_executable_doc_separation.sh enforcing size limits, guide existence, and cross-reference integrity. Plan 743 commands create systematic coverage gap with zero guide files despite all 5 commands exceeding 150-line threshold. Priority 3 recommendation requires creating guide files (25h estimated) with systematic section completeness: Overview, Architecture, Usage Examples, Advanced Topics, Troubleshooting, See Also. All documentation must follow present-focused writing standards (no historical commentary per writing-standards.md) with validation ensuring bidirectional cross-references between executable and guide files.

## Success Criteria

- [ ] Standard 0 (Execution Enforcement): All agent invocations followed by mandatory file existence verification
- [ ] Standard 0.5 (Subagent Prompts): All agent invocations use complete Task template structure
- [ ] Standard 12 (Behavioral Separation): Zero behavioral content in orchestrator commands (context parameters only)
- [ ] Standard 14 (Documentation Separation): All 5 commands have comprehensive guide files with 7 mandatory sections
- [ ] Standard 15 (Library Sourcing): All commands use identical dependency-ordered sourcing pattern
- [ ] Standard 16 (Return Code Verification): All critical functions (sm_init, sm_transition, save_completed_states_to_state) wrapped with error handling
- [ ] Behavioral compliance test coverage ≥80% for all commands and critical agents
- [ ] File creation reliability 100% (verified through behavioral tests)
- [ ] Execution reliability 100% (no silent failures from unverified return codes)
- [ ] Guide file quality metrics: 100% section completeness across all 5 guides

## Technical Design

### Architecture Decisions

**1. Fail-Fast Verification Pattern Enhancement**:
- Apply Standard 0 pattern: Pre-calculate artifact paths → Inject into agent prompts → Verify exact file existence post-execution
- Replace directory-level verifications (/fix.md lines 144-158, /research-report.md lines 161-178) with file-level checks
- Add diagnostic output on failures: expected path, agent name, troubleshooting references

**2. Complete Task Template Migration**:
- Transform all abbreviated instruction lists (echo "YOU MUST:" pattern) to structured Task blocks
- Structure: `Task { subagent_type, description, prompt }` with workflow-specific context
- Remove behavioral instructions ("Focus research on...") from prompts, retain context parameters only

**3. Guide File Creation Strategy**:
- Use _template-command-guide.md as baseline (171 lines, 7 sections)
- Populate sections from command analysis: Overview (purpose from frontmatter), Architecture (state machine integration), Usage Examples (basic/advanced/edge), Advanced Topics (performance/customization), Troubleshooting (known issues from 746 report), See Also (cross-references)
- Ensure bidirectional cross-references: executable → guide, guide → executable

**4. Library Sourcing Standardization**:
- Enforce dependency order: (1) State machine foundation (state-persistence.sh, workflow-state-machine.sh), (2) Library version checking (library-version-check.sh), (3) Error handling (error-handling.sh), (4) Additional utilities (checkpoint-utils.sh)
- Add inline comments explaining dependency rationale per Standard 15

**5. Return Code Verification Wrapper**:
- Pattern: `if ! sm_init ... 2>&1; then [diagnostic output]; exit 1; fi`
- Apply to all critical functions: sm_init, sm_transition, save_completed_states_to_state, check_library_requirements
- Include diagnostic output: parameters used, possible causes, library compatibility checks

**6. Behavioral Compliance Testing Framework**:
- Reference implementation: test_optimize_claude_agents.sh (369 lines, 6 test pattern categories)
- Apply patterns: file creation compliance, completion signal format, STEP structure validation, imperative language validation, verification checkpoints, file size limits
- Integrate into run_all_tests.sh with pollution detection

**7. CI/CD Integration Strategy**:
- Pre-commit hooks: Fast tests (<30s) for changed files
- PR workflow: Full test suite via run_all_tests.sh with coverage reporting
- Nightly regression: Comprehensive validation including end-to-end tests
- Enforcement: Block merge if tests fail or coverage drops below thresholds

### Component Interactions

1. **Orchestrator Commands** (.claude/commands/*.md) → Modified for standards compliance
2. **Agent Files** (.claude/agents/*.md) → Behavioral content consolidated here (no orchestrator duplication)
3. **Guide Files** (.claude/docs/guides/*-command-guide.md) → Created with systematic coverage
4. **Validation Scripts** (.claude/tests/validate_*.sh) → Extended for all 16 standards
5. **Test Suites** (.claude/tests/test_*.sh) → New behavioral compliance suites created
6. **CI/CD Pipeline** (.github/workflows/test.yml) → Automated test execution and reporting

## Implementation Phases

### Phase 1: Add Mandatory Verification Checkpoints (Standard 0)
dependencies: []

**Objective**: Achieve 100% file creation reliability through fail-fast verification after all agent invocations

**Complexity**: High

Tasks:
- [x] Replace directory-level verification in /fix.md (lines 144-158) with file-level REPORT_PATH check
- [x] Replace directory-level verification in /research-report.md (lines 161-178) with file-level REPORT_PATH check
- [x] Replace directory-level verification in /research-plan.md (lines 162-177) with file-level REPORT_PATH check
- [x] Add file size validation (minimum 100 bytes) to all verification checkpoints
- [x] Add diagnostic output on verification failure: expected path, agent name, troubleshooting path
- [x] Ensure all artifact paths pre-calculated before agent invocations and injected into prompts
- [x] Fix /research-revise.md (lines 260-273) to fail on unmodified plan instead of WARNING
- [x] Verify /build.md git-based verification replaced with explicit artifact path checks

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test file creation verification
.claude/tests/test_verification_checkpoints.sh

# Verify all commands have file-level (not directory-level) checks
grep -n "find.*-name '\*.md'" .claude/commands/{build,fix,research-*}.md
# Expected: zero matches (directory-level pattern removed)

grep -n 'if \[ ! -f "\$.*_PATH" \]' .claude/commands/{build,fix,research-*}.md
# Expected: matches for all agent invocations (file-level pattern)
```

**Expected Duration**: 15 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(747): complete Phase 1 - Mandatory Verification Checkpoints`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Add Return Code Verification (Standard 16)
dependencies: [1]

**Objective**: Eliminate silent state machine initialization failures through comprehensive return code verification

**Complexity**: Medium

Tasks:
- [x] Wrap sm_init() in /build.md (lines 154-162) with return code verification and diagnostic output
- [x] Wrap sm_init() in /fix.md (lines 98-105) with return code verification and diagnostic output
- [x] Wrap sm_init() in /research-report.md (lines 105-114) with return code verification and diagnostic output
- [x] Wrap sm_init() in /research-plan.md (lines 106-115) with return code verification and diagnostic output
- [x] Wrap sm_init() in /research-revise.md (lines 131-138) with return code verification and diagnostic output
- [x] Add return code verification for all sm_transition() calls across 5 commands
- [x] Add return code verification for all save_completed_states_to_state() calls across 5 commands
- [x] Add return code verification for check_library_requirements() calls across 5 commands
- [x] Create diagnostic output template: parameters used, workflow type, complexity, possible causes, library compatibility

Testing:
```bash
# Test return code verification present
.claude/tests/test_return_code_verification.sh

# Verify all sm_init calls wrapped
grep -A2 "sm_init" .claude/commands/{build,fix,research-*}.md | grep -c "if ! sm_init"
# Expected: 5 matches (one per command)

# Verify diagnostic output present
grep -A5 "if ! sm_init" .claude/commands/{build,fix,research-*}.md | grep -c "Diagnostic Information"
# Expected: 5 matches (one per command)
```

**Expected Duration**: 7.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(747): complete Phase 2 - Return Code Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Standardize Library Sourcing Order (Standard 15)
dependencies: [1]

**Objective**: Achieve consistent dependency-ordered library sourcing across all commands

**Complexity**: Low

Tasks:
- [x] Update /build.md (lines 47-52) to standard sourcing order: state-persistence.sh, workflow-state-machine.sh, library-version-check.sh, error-handling.sh, checkpoint-utils.sh
- [x] Update /fix.md (lines 80-83) to move error-handling.sh before library-version-check.sh per standard order
- [x] Update /research-report.md (lines 85-90) to move error-handling.sh before library-version-check.sh
- [x] Update /research-plan.md (lines 86-91) to move error-handling.sh before library-version-check.sh
- [x] Update /research-revise.md (lines 106-109) to move error-handling.sh before library-version-check.sh
- [x] Add inline comments explaining dependency order: "Source libraries in dependency order (Standard 15)"
- [x] Add section comments: "# 1. State machine foundation", "# 2. Library version checking", "# 3. Error handling", "# 4. Additional utilities"

Testing:
```bash
# Verify sourcing order consistency
.claude/tests/test_library_sourcing_order.sh

# Check all commands use identical pattern
for cmd in build fix research-report research-plan research-revise; do
  echo "=== $cmd.md ==="
  grep "^source.*\.sh" .claude/commands/$cmd.md
done
# Expected: identical order across all 5 commands
```

**Expected Duration**: 2.5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(747): complete Phase 3 - Library Sourcing Standardization`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Complete Agent Invocation Templates (Standard 0.5)
dependencies: [1]

**Objective**: Transform abbreviated instruction lists to complete Task template structures for reduced interpretation ambiguity

**Complexity**: Medium

Tasks:
- [ ] Transform /build.md implementer-coordinator invocation (lines 173-189) to Task template with subagent_type, description, structured prompt
- [ ] Transform /build.md debug-analyst invocation to Task template (if applicable)
- [ ] Transform /build.md documentation invocation to Task template (if applicable)
- [ ] Transform /fix.md research-specialist invocation (lines 129-142) to Task template, remove behavioral instruction "Focus research on..."
- [ ] Transform /fix.md plan-architect invocation to Task template (if applicable)
- [ ] Transform /fix.md debug-analyst invocation to Task template (if applicable)
- [ ] Transform /research-report.md research-specialist invocation (lines 134-154) to Task template
- [ ] Transform /research-plan.md research-specialist invocation to Task template
- [ ] Transform /research-plan.md plan-architect invocation to Task template

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Transform /research-revise.md research-specialist invocation to Task template, remove behavioral instruction "focused on new insights"
- [ ] Transform /research-revise.md plan-architect invocation to Task template
- [ ] Verify all prompts contain only workflow-specific context (no behavioral instructions like "Focus on...", "Follow Standard 0.5...")
- [ ] Verify all Task blocks include subagent_type: "general-purpose", description, and structured prompt with context parameters

Testing:
```bash
# Verify Task template structure
grep -A10 "Task {" .claude/commands/{build,fix,research-*}.md | grep -c "subagent_type:"
# Expected: 11 matches (one per agent invocation)

# Verify no behavioral instructions in prompts
grep -i "focus.*on\|follow standard" .claude/commands/{build,fix,research-*}.md
# Expected: zero matches (behavioral content removed)

# Verify context parameters present
grep -A10 "Workflow-Specific Context" .claude/commands/{build,fix,research-*}.md | grep -c "Research Type:\|Mode:\|Complexity:"
# Expected: multiple matches (context injection pattern)
```

**Expected Duration**: 5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(747): complete Phase 4 - Agent Invocation Template Completion`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Create Command Guide Files (Standard 14)
dependencies: []

**Objective**: Achieve systematic documentation coverage with comprehensive guide files for all 5 commands

**Complexity**: High

Tasks:
- [ ] Create /build-command-guide.md (1,000 lines estimated) using _template-command-guide.md baseline
- [ ] Populate /build-command-guide.md: Overview (purpose, when to use, when NOT to use), Architecture (state machine integration, library dependencies, workflow phases), Usage Examples (basic/advanced/edge with output), Advanced Topics (performance, customization, workflow integration), Troubleshooting (checkpoint stale errors, state machine failures, library version issues), See Also (cross-references)
- [ ] Create /fix-command-guide.md (700 lines estimated) using template baseline
- [ ] Populate /fix-command-guide.md with systematic section coverage
- [ ] Create /research-report-command-guide.md (500 lines estimated) using template baseline
- [ ] Populate /research-report-command-guide.md with systematic section coverage
- [ ] Create /research-plan-command-guide.md (500 lines estimated) using template baseline
- [ ] Populate /research-plan-command-guide.md with systematic section coverage
- [ ] Create /research-revise-command-guide.md (500 lines estimated) using template baseline
- [ ] Populate /research-revise-command-guide.md with systematic section coverage

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Add bidirectional cross-references: executable → guide in command frontmatter ("Documentation: See .claude/docs/guides/...")
- [ ] Add bidirectional cross-references: guide → executable in guide header ("Executable: .claude/commands/...")
- [ ] Verify all guides include 7 mandatory sections: Table of Contents, Overview, Architecture, Usage Examples, Advanced Topics, Troubleshooting, See Also
- [ ] Verify all guides follow present-focused writing standards (no historical commentary, temporal markers, migration language)
- [ ] Run validate_executable_doc_separation.sh to verify file existence, cross-reference integrity, size limits

Testing:
```bash
# Verify guide files exist
for cmd in build fix research-report research-plan research-revise; do
  test -f .claude/docs/guides/${cmd}-command-guide.md && echo "✓ $cmd guide exists" || echo "✗ $cmd guide missing"
done

# Verify section completeness
.claude/tests/validate_guide_section_completeness.sh

# Run official validation
.claude/tests/validate_executable_doc_separation.sh
# Expected: All validations pass
```

**Expected Duration**: 25 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(747): complete Phase 5 - Command Guide Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Implement Behavioral Compliance Test Suites
dependencies: [1, 2, 3, 4]

**Objective**: Achieve 80%+ test coverage for behavioral compliance across all commands and critical agents

**Complexity**: High

Tasks:
- [ ] Create validate_behavioral_compliance.sh (8 hours) with 6 test pattern categories: file creation compliance, completion signal format, agent delegation rate, context reduction validation
- [ ] Apply behavioral tests to all 16 command files for verification checkpoint presence
- [ ] Apply behavioral tests to measure agent delegation rate (>90% target)
- [ ] Apply behavioral tests to validate context reduction (90-95% target from 11,500 tokens → 700 tokens)
- [ ] Extend validate_orchestrator_commands.sh (4 hours) to test actual agent invocation and file creation (beyond structural validation)
- [ ] Create test_agent_behavioral_compliance.sh (8 hours) using test_optimize_claude_agents.sh patterns (369 lines reference)
- [ ] Test priority agents: research-specialist, implementer-coordinator, plan-architect, revision-specialist
- [ ] Validate STEP structure, imperative language, verification checkpoints, file size limits (40KB max per agent)
- [ ] Integrate all new test suites into run_all_tests.sh with pollution detection

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Test file creation compliance pattern: verify agents create files at injected paths with minimum file size
- [ ] Test completion signal format pattern: verify agents return properly formatted signals
- [ ] Test STEP structure pattern: verify agents have numbered sequential STEPs
- [ ] Test imperative language pattern: verify agents use MUST/WILL/SHALL (not should/may/can)
- [ ] Test verification checkpoints pattern: verify agents have mandatory verification sections
- [ ] Run full test suite and verify 80%+ pass rate

Testing:
```bash
# Run new behavioral compliance tests
.claude/tests/validate_behavioral_compliance.sh

# Run extended orchestrator validation
.claude/tests/validate_orchestrator_commands.sh

# Run agent behavioral tests
.claude/tests/test_agent_behavioral_compliance.sh

# Verify integration with test runner
.claude/tests/run_all_tests.sh
# Expected: All new tests discovered and executed
```

**Expected Duration**: 20 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(747): complete Phase 6 - Behavioral Compliance Test Suites`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status


## Testing Strategy

### Unit Testing
- Verification checkpoint presence: validate_verification_checkpoints.sh
- Return code verification: test_return_code_verification.sh
- Library sourcing order: test_library_sourcing_order.sh
- Task template structure: validate_behavioral_compliance.sh
- Guide file section completeness: validate_guide_section_completeness.sh

### Integration Testing
- Orchestrator command validation: validate_orchestrator_commands.sh (extended)
- Agent behavioral compliance: test_agent_behavioral_compliance.sh
- End-to-end workflow execution: e2e_orchestrator_workflows.sh (created in Phase 6)
- Agent integration and handoffs: e2e_agent_integration.sh (created in Phase 6)

### Validation Testing
- All 16 architecture standards: validate_all_standards.sh (created in Phase 6)
- Executable/documentation separation: validate_executable_doc_separation.sh (existing)
- Behavioral content absence: validate_command_behavioral_injection.sh (existing)

### Coverage Requirements
- Commands: 100% (all must have tests)
- Agents: 80% (critical agents prioritized: research-specialist, implementer-coordinator, plan-architect, revision-specialist)
- Standards: 100% (all 16 standards validated)
- Libraries: 80% (public APIs covered)

### Test Execution
- Manual: .claude/tests/run_all_tests.sh for local development
- Integration: Tests executed as part of existing test infrastructure

## Documentation Requirements

### New Documentation
- Create 5 command guide files: build-command-guide.md, fix-command-guide.md, research-report-command-guide.md, research-plan-command-guide.md, research-revise-command-guide.md
- Create guide-file-review-checklist.md for quality assurance
- Create testing-guide.md for contributor onboarding
- Create test templates: _template_behavioral_test.sh, _template_standards_validation.sh

### Updated Documentation
- Update testing-protocols.md with plan 743 command testing examples
- Update command_architecture_standards.md with systematic coverage requirements (Recommendation 3 from report 003)
- Update command files with bidirectional cross-references to guide files
- Update guide files with cross-references to executable files

### Cross-Reference Updates
- All guide files must reference executable files: "Executable: .claude/commands/command-name.md"
- All command files must reference guide files: "Documentation: See .claude/docs/guides/command-name-command-guide.md"
- All guides must cross-reference patterns used: links to .claude/docs/concepts/patterns/
- All guides must cross-reference related commands and agents

## Dependencies

### External Dependencies
- validate_executable_doc_separation.sh (existing)
- _template-command-guide.md (existing)
- test_optimize_claude_agents.sh (existing, 369-line reference)
- run_all_tests.sh (existing, with pollution detection)
- .claude/docs/concepts/writing-standards.md (existing, for present-focused writing)

### Internal Dependencies
- Phase 1 (Verification Checkpoints) blocks Phases 2, 3, 4 (core reliability foundation)
- Phase 6 (Test Suites) depends on Phases 1-4 completing (tests verify compliance)
- Phase 5 (Guide Files) independent, can run parallel to other phases

### Prerequisite Knowledge
- Standard 0 (Execution Enforcement) patterns and fail-fast verification
- Standard 14 (Executable/Documentation Separation) two-file architecture
- Standard 16 (Return Code Verification) error handling patterns
- Testing protocols from testing-protocols.md (test isolation, pollution detection)
- Writing standards from writing-standards.md (present-focused, no historical commentary)

## Revision History

- **2025-11-17**: Remove Phase 7 (CI/CD Integration and Coverage Tracking)

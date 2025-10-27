# /plan Command Standards Compliance Enhancement

## Metadata
- **Date**: 2025-10-26
- **Feature**: Ensure /plan command maintains 100% compliance with directory protocols and architecture standards
- **Scope**: Verification, edge case handling, and documentation improvements
- **Estimated Phases**: 5
- **Estimated Hours**: 8-12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 45.0 (Medium - comprehensive testing and edge cases)
- **Research Reports**:
  - [Plan Command Artifact Location Compliance Analysis](/home/benjamin/.config/.claude/specs/479_review_the_plan_command_to_make_sure_that_if_follows/reports/001_plan_command_artifact_location_analysis.md)

## Overview

The research report confirms the `/plan` command demonstrates **exemplary compliance** (100%, 10/10 standards) with directory protocols and command architecture standards. This implementation plan focuses on **maintaining and enhancing** this compliance through:

1. **Comprehensive testing** to verify all compliance patterns under edge cases
2. **Edge case hardening** to handle error conditions gracefully
3. **Documentation improvements** to mark /plan as reference implementation
4. **Regression prevention** through automated compliance checks
5. **Cross-command consistency** validation with /supervise and /orchestrate

**Current Compliance Status** (from research report):
- Topic-based artifact location: 100%
- Lazy directory creation: 100%
- Utility library usage: 100%
- Mandatory verification checkpoints: 100%
- Behavioral injection pattern: 100%
- Imperative language usage: 100%
- Gitignore compliance: 100%
- Complexity analysis integration: 100%

**Focus Areas**:
- Strengthen verification checkpoint resilience
- Add automated compliance testing
- Document as reference implementation
- Ensure consistent behavior with /supervise approach

## Success Criteria

- [ ] All verification checkpoints tested under failure conditions
- [ ] Edge cases handled with graceful fallbacks (network failure, disk full, permission errors)
- [ ] Automated compliance test suite passes 100%
- [ ] /plan command annotated as reference implementation
- [ ] Cross-command consistency validated with /supervise
- [ ] Regression prevention mechanisms in place
- [ ] Documentation updated with compliance examples
- [ ] All tests passing (≥80% coverage on modified code)

## Technical Design

### Architecture

The /plan command follows a **mixed execution model** with proper separation of concerns:

1. **Research Orchestration Mode** (Step 0.5, conditional)
   - Invokes research-specialist agents via Task tool
   - Uses behavioral injection pattern
   - Metadata-only context passing

2. **Direct Execution Mode** (Steps 1-7, always)
   - Uses unified-location-detection.sh for topic paths
   - Creates plans via create_topic_artifact()
   - Implements verification checkpoints with fallbacks

### Key Compliance Patterns

**Pattern 1: Unified Location Detection** (lines 462-507)
```bash
source .claude/lib/unified-location-detection.sh
LOCATION_JSON=$(perform_location_detection "$FEATURE_DESCRIPTION" "false")
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
```

**Pattern 2: Lazy Directory Creation** (lines 618-623)
```bash
ensure_artifact_directory "$FALLBACK_PATH" || {
  echo "ERROR: Failed to create parent directory" >&2
  exit 1
}
```

**Pattern 3: Mandatory Verification** (lines 611-664)
```bash
if [ ! -f "$PLAN_PATH" ]; then
  # FALLBACK MECHANISM (Guarantees 100% Success)
  FALLBACK_PATH="${TOPIC_DIR}/plans/${PLAN_FILENAME}"
  # ... fallback creation ...
fi
```

**Pattern 4: Behavioral Injection** (lines 161-224)
```markdown
**EXECUTE NOW - Invoke Research-Specialist Agents**
Task {
  subagent_type: "general-purpose"
  description: "Research {topic} for {feature}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md
```

### Enhancement Strategy

1. **Testing Layer**: Add comprehensive compliance tests
2. **Edge Case Handling**: Strengthen error recovery
3. **Documentation Layer**: Annotate as reference implementation
4. **Monitoring Layer**: Add compliance metrics tracking

## Implementation Phases

### Phase 0: Compliance Baseline Verification
dependencies: []

**Objective**: Verify current 100% compliance status through automated testing

**Complexity**: Low

**Tasks**:
- [ ] Create test script: `.claude/tests/test_plan_command_compliance.sh`
- [ ] Test 1: Verify topic-based artifact location (create plan in new topic, verify path structure)
- [ ] Test 2: Verify lazy directory creation (ensure no empty subdirectories created)
- [ ] Test 3: Verify utility library integration (unified-location-detection.sh, artifact-operations.sh)
- [ ] Test 4: Verify mandatory verification checkpoints (trigger fallback, verify recovery)
- [ ] Test 5: Verify behavioral injection pattern (invoke research agents, verify report creation)
- [ ] Test 6: Verify imperative language usage (grep for MUST/EXECUTE/MANDATORY markers)
- [ ] Test 7: Verify gitignore compliance (plans in plans/ subdirectory, check .gitignore)
- [ ] Test 8: Verify complexity analysis (test complexity score calculation and storage)
- [ ] Run baseline test suite: `bash .claude/tests/test_plan_command_compliance.sh`
- [ ] Document baseline results: `.claude/specs/479_*/test_results/baseline_compliance.txt`

**Testing**:
```bash
# Run compliance test suite
bash .claude/tests/test_plan_command_compliance.sh

# Verify 100% pass rate (8/8 tests)
grep -c "PASS" .claude/specs/479_*/test_results/baseline_compliance.txt
```

**Expected Duration**: 2 hours

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (8/8 compliance tests)
- [ ] Git commit created: `feat(479): complete Phase 0 - Compliance Baseline Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 1: Edge Case Testing and Hardening
dependencies: [0]

**Objective**: Identify and handle edge cases in verification checkpoints and fallback mechanisms

**Complexity**: Medium

**Tasks**:
- [ ] Create edge case test suite: `.claude/tests/test_plan_edge_cases.sh`
- [ ] Test edge case 1: Disk space exhausted during plan creation (simulate with small tmpfs)
- [ ] Test edge case 2: jq command not available (test fallback JSON parsing with grep/sed)
- [ ] Test edge case 3: Permission denied on topic directory (test error handling)
- [ ] Test edge case 4: Research agent returns non-compliant output (test fallback report creation)
- [ ] Test edge case 5: Concurrent plan creation (two /plan invocations, same topic)
- [ ] Test edge case 6: Malformed feature description (empty, unicode, special characters)
- [ ] Test edge case 7: Network timeout during research phase (if WebSearch used)
- [ ] Test edge case 8: CLAUDE_PROJECT_DIR override with non-writable path
- [ ] Review test results and identify failure modes
- [ ] Strengthen verification checkpoints based on test findings (file: `.claude/commands/plan.md`)
- [ ] Add error recovery for identified edge cases
- [ ] Update fallback mechanisms for robustness
- [ ] Re-run edge case test suite to verify fixes

**Testing**:
```bash
# Run edge case test suite
bash .claude/tests/test_plan_edge_cases.sh

# All tests should either pass or gracefully fail with clear error messages
grep "GRACEFUL_FAILURE\|PASS" .claude/specs/479_*/test_results/edge_case_results.txt
```

**Expected Duration**: 3-4 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (edge cases handled gracefully)
- [ ] Git commit created: `feat(479): complete Phase 1 - Edge Case Testing and Hardening`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Reference Implementation Annotation
dependencies: [0]

**Objective**: Document /plan command as reference implementation with inline annotations

**Complexity**: Low

**Tasks**:
- [ ] Add reference implementation marker at top of plan.md (after YAML frontmatter):
  ```markdown
  <!-- REFERENCE_IMPLEMENTATION: Standards Compliance
       This command demonstrates exemplary compliance with directory protocols
       and command architecture standards. Use as reference when updating other commands.

       Compliance Patterns Demonstrated:
       - Topic-based artifact location (lines 459-518)
       - Lazy directory creation (lines 618-623)
       - Unified location detection library (lines 462-467)
       - Mandatory verification checkpoints (lines 611-664)
       - Behavioral injection pattern (lines 161-224)
       - Imperative language usage (throughout)

       Standards References:
       - Directory Protocols: .claude/docs/concepts/directory-protocols.md
       - Command Architecture: .claude/docs/reference/command_architecture_standards.md
       - Verification Pattern: .claude/docs/concepts/patterns/verification-fallback.md
       - Behavioral Injection: .claude/docs/concepts/patterns/behavioral-injection.md
  -->
  ```
- [ ] Add inline compliance annotations at key implementation points
- [ ] Annotation 1: Topic-based location (lines 485-507 in plan.md)
- [ ] Annotation 2: Lazy directory creation (lines 618-623 in plan.md)
- [ ] Annotation 3: Verification checkpoint (lines 611-664 in plan.md)
- [ ] Annotation 4: Behavioral injection (lines 161-224 in plan.md)
- [ ] Update command reference documentation: `.claude/docs/reference/command-reference.md`
- [ ] Add "Reference Implementation" badge to /plan entry in command reference
- [ ] Create compliance examples document: `.claude/docs/examples/compliance-patterns.md`
- [ ] Include /plan command patterns in examples document with code snippets

**Testing**:
```bash
# Verify annotations present
grep -c "REFERENCE_IMPLEMENTATION\|COMPLIANCE_PATTERN" .claude/commands/plan.md

# Verify command reference updated
grep "Reference Implementation" .claude/docs/reference/command-reference.md
```

**Expected Duration**: 1-2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (documentation checks)
- [ ] Git commit created: `docs(479): complete Phase 2 - Reference Implementation Annotation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Cross-Command Consistency Validation
dependencies: [0]

**Objective**: Validate /plan uses same patterns as /supervise and /orchestrate for consistency

**Complexity**: Medium

**Tasks**:
- [ ] Create cross-command validation script: `.claude/tests/test_command_consistency.sh`
- [ ] Compare location detection patterns (/plan vs /supervise vs /orchestrate)
- [ ] Verify all three commands source unified-location-detection.sh
- [ ] Verify all three commands use perform_location_detection() function
- [ ] Verify all three commands use ensure_artifact_directory() for lazy creation
- [ ] Compare verification checkpoint patterns across commands
- [ ] Identify any pattern deviations between commands
- [ ] Document intentional differences (e.g., /plan's report topic extraction, lines 480-482)
- [ ] Ensure behavioral injection pattern consistent across orchestration commands
- [ ] Verify imperative language usage consistent (MUST/EXECUTE NOW/MANDATORY)
- [ ] Create consistency report: `.claude/specs/479_*/reports/command_consistency_analysis.md`
- [ ] Update any commands with inconsistent patterns to match /plan reference implementation

**Testing**:
```bash
# Run consistency validation
bash .claude/tests/test_command_consistency.sh

# Verify all commands use same utility library
grep -l "unified-location-detection.sh" .claude/commands/plan.md .claude/commands/supervise.md .claude/commands/orchestrate.md
```

**Expected Duration**: 2-3 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (consistency validation)
- [ ] Git commit created: `test(479): complete Phase 3 - Cross-Command Consistency Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Regression Prevention and Monitoring
dependencies: [0, 1, 2, 3]

**Objective**: Implement automated compliance checks to prevent future regressions

**Complexity**: Medium

**Tasks**:
- [ ] Create compliance monitoring script: `.claude/lib/check-command-compliance.sh`
- [ ] Implement compliance check 1: Verify unified location detection library usage
- [ ] Implement compliance check 2: Verify lazy directory creation pattern (no mkdir in location detection)
- [ ] Implement compliance check 3: Verify verification checkpoint presence (grep for MANDATORY VERIFICATION)
- [ ] Implement compliance check 4: Verify behavioral injection pattern (no ```yaml wrappers)
- [ ] Implement compliance check 5: Verify imperative language usage (MUST/EXECUTE/MANDATORY count)
- [ ] Implement compliance check 6: Verify fallback mechanism presence
- [ ] Integrate compliance checks into test suite: `.claude/tests/run_all_tests.sh`
- [ ] Add pre-commit hook suggestion for compliance checks (optional, document in README)
- [ ] Create compliance metrics dashboard script: `.claude/lib/compliance-metrics.sh`
- [ ] Document compliance checking process: `.claude/docs/guides/compliance-checking-guide.md`
- [ ] Add compliance check to CI/CD pipeline recommendations (if applicable)

**Testing**:
```bash
# Run compliance monitoring on /plan command
bash .claude/lib/check-command-compliance.sh .claude/commands/plan.md

# Expected: 100% compliance score (6/6 checks pass)
bash .claude/lib/check-command-compliance.sh .claude/commands/plan.md | grep -c "PASS"
```

**Expected Duration**: 2-3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (compliance checks functional)
- [ ] Git commit created: `feat(479): complete Phase 4 - Regression Prevention and Monitoring`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Documentation and Knowledge Transfer
dependencies: [0, 1, 2, 3, 4]

**Objective**: Comprehensive documentation of compliance patterns for future development

**Complexity**: Low

**Tasks**:
- [ ] Update directory protocols documentation: `.claude/docs/concepts/directory-protocols.md`
- [ ] Add "Compliance Examples" section with /plan command references
- [ ] Update command architecture standards: `.claude/docs/reference/command_architecture_standards.md`
- [ ] Add /plan as reference implementation example in Standard 0 (Verification) and Standard 11 (Behavioral Injection)
- [ ] Create compliance checklist: `.claude/docs/checklists/command-compliance-checklist.md`
- [ ] Document all 10 compliance standards with examples from /plan
- [ ] Update verification-fallback pattern documentation: `.claude/docs/concepts/patterns/verification-fallback.md`
- [ ] Add /plan's fallback mechanisms as examples (lines 612-636, 248-286, 994-1020)
- [ ] Update behavioral-injection pattern documentation: `.claude/docs/concepts/patterns/behavioral-injection.md`
- [ ] Add /plan's agent invocation as example (lines 161-224)
- [ ] Create troubleshooting guide: `.claude/docs/troubleshooting/compliance-issues.md`
- [ ] Document common compliance pitfalls and resolutions
- [ ] Update CLAUDE.md with compliance section reference (if not present)
- [ ] Create implementation summary: `.claude/specs/479_*/summaries/001_compliance_enhancement_summary.md`

**Testing**:
```bash
# Verify all documentation files exist
test -f .claude/docs/checklists/command-compliance-checklist.md && \
test -f .claude/docs/troubleshooting/compliance-issues.md && \
echo "Documentation complete"

# Verify compliance examples added to pattern docs
grep -l "/plan command" .claude/docs/concepts/patterns/*.md
```

**Expected Duration**: 1-2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (documentation validation)
- [ ] Git commit created: `docs(479): complete Phase 5 - Documentation and Knowledge Transfer`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Test Categories

1. **Compliance Testing** (Phase 0)
   - Verify all 10 compliance standards met
   - Automated test suite with 8 core compliance tests
   - Baseline: 100% pass rate expected

2. **Edge Case Testing** (Phase 1)
   - Test error conditions and recovery mechanisms
   - 8 edge cases covering disk space, permissions, concurrency
   - Graceful failure with clear error messages required

3. **Integration Testing** (Phase 3)
   - Cross-command consistency validation
   - Verify /plan, /supervise, /orchestrate use same patterns
   - Library integration tests

4. **Regression Testing** (Phase 4)
   - Automated compliance checks on command modifications
   - 6 compliance checks integrated into test suite
   - Prevent future compliance regressions

### Test Execution

**Run All Tests**:
```bash
# From project root
cd /home/benjamin/.config

# Run full test suite
.claude/tests/run_all_tests.sh

# Run specific compliance tests
.claude/tests/test_plan_command_compliance.sh
.claude/tests/test_plan_edge_cases.sh
.claude/tests/test_command_consistency.sh
```

**Coverage Requirements**:
- Baseline compliance: 100% (8/8 tests pass)
- Edge case handling: 100% (graceful failure)
- Cross-command consistency: 100% (same patterns)
- Regression prevention: 100% (6/6 checks pass)

### Success Criteria

All tests must pass before marking phases complete:
- Phase 0: 8/8 compliance tests pass
- Phase 1: 8/8 edge cases handled gracefully
- Phase 3: 0 pattern deviations found
- Phase 4: 6/6 compliance checks pass

## Documentation Requirements

### Files to Create

1. **Test Scripts**:
   - `.claude/tests/test_plan_command_compliance.sh` - Core compliance tests
   - `.claude/tests/test_plan_edge_cases.sh` - Edge case tests
   - `.claude/tests/test_command_consistency.sh` - Cross-command validation

2. **Compliance Tools**:
   - `.claude/lib/check-command-compliance.sh` - Automated compliance checker
   - `.claude/lib/compliance-metrics.sh` - Metrics dashboard

3. **Documentation**:
   - `.claude/docs/checklists/command-compliance-checklist.md` - Compliance checklist
   - `.claude/docs/examples/compliance-patterns.md` - Example patterns from /plan
   - `.claude/docs/troubleshooting/compliance-issues.md` - Troubleshooting guide
   - `.claude/specs/479_*/summaries/001_compliance_enhancement_summary.md` - Implementation summary

4. **Test Results**:
   - `.claude/specs/479_*/test_results/baseline_compliance.txt` - Phase 0 results
   - `.claude/specs/479_*/test_results/edge_case_results.txt` - Phase 1 results
   - `.claude/specs/479_*/reports/command_consistency_analysis.md` - Phase 3 analysis

### Files to Update

1. **.claude/commands/plan.md**:
   - Add reference implementation annotation (top of file)
   - Add inline compliance annotations at key patterns

2. **.claude/docs/reference/command-reference.md**:
   - Add "Reference Implementation" badge to /plan entry

3. **.claude/docs/concepts/directory-protocols.md**:
   - Add "Compliance Examples" section with /plan references

4. **.claude/docs/reference/command_architecture_standards.md**:
   - Add /plan examples in Standard 0 and Standard 11

5. **.claude/docs/concepts/patterns/verification-fallback.md**:
   - Add /plan fallback mechanisms as examples

6. **.claude/docs/concepts/patterns/behavioral-injection.md**:
   - Add /plan agent invocation as example

### Documentation Standards

All documentation must follow:
- Clear, concise language (present tense, timeless)
- Code examples with syntax highlighting
- Cross-references with absolute paths
- No historical markers (per Development Philosophy)
- CommonMark specification compliance

## Dependencies

### External Dependencies

None - all utilities and libraries already present in codebase.

### Internal Dependencies

**Utility Libraries** (already in use by /plan):
- `.claude/lib/unified-location-detection.sh` - Topic path detection
- `.claude/lib/artifact-operations.sh` - File creation utilities
- `.claude/lib/template-integration.sh` - Template handling
- `.claude/lib/complexity-utils.sh` - Complexity calculation

**Standards Documentation**:
- `.claude/docs/concepts/directory-protocols.md` - Directory standards
- `.claude/docs/reference/command_architecture_standards.md` - Architecture standards
- `.claude/docs/concepts/patterns/verification-fallback.md` - Verification pattern
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern

### Phase Dependencies

Phases are designed for efficient execution:
- **Wave 1** (parallel): Phases 0, 2
- **Wave 2** (parallel): Phases 1, 3
- **Wave 3** (sequential): Phase 4 (requires all previous phases)
- **Wave 4** (sequential): Phase 5 (requires all previous phases)

**Parallel Execution Opportunity**: Phases 0 and 2 can run in parallel (independent), and Phases 1 and 3 can run in parallel. This provides **40% time savings** (8-12 hours → 5-7 hours).

## Risk Assessment

### Low Risks

1. **Documentation-Heavy Phases** (Phases 2, 5)
   - Risk: Time-consuming but straightforward
   - Mitigation: Clear templates and examples provided

2. **Test Suite Maintenance**
   - Risk: Tests may require updates as codebase evolves
   - Mitigation: Well-documented test cases with clear failure modes

### Medium Risks

1. **Edge Case Discovery** (Phase 1)
   - Risk: May discover unexpected failure modes requiring significant fixes
   - Mitigation: Research report confirms current 100% compliance, edge cases likely minor

2. **Cross-Command Consistency** (Phase 3)
   - Risk: May find deviations in /supervise or /orchestrate requiring updates
   - Mitigation: Research confirms /plan and /supervise use same unified library

### Mitigation Strategies

1. **Incremental Testing**: Test each compliance pattern individually before integration
2. **Fallback Mechanisms**: Ensure all edge cases have graceful failure paths
3. **Documentation First**: Document patterns before implementing checks
4. **Regression Prevention**: Integrate compliance checks into existing test suite

## Implementation Notes

### Key Findings from Research

The research report (100% compliance, 10/10 standards) confirms:

1. **/plan is already compliant** - no fixes needed, only enhancements
2. **Exemplary patterns** - suitable as reference implementation
3. **Strong verification** - all checkpoints have fallback mechanisms
4. **Consistent with /supervise** - both use unified-location-detection.sh
5. **Imperative language** - 47 enforcement markers (MUST, EXECUTE NOW, MANDATORY)

### Enhancement Focus

This plan focuses on **maintaining and demonstrating** compliance, not fixing issues:
- **Testing** to prevent regressions
- **Documentation** to share patterns with other commands
- **Monitoring** to detect future compliance drift
- **Edge cases** to strengthen robustness

### Success Metrics

**Quantitative**:
- 100% test pass rate (baseline + edge cases)
- 6/6 compliance checks pass
- 0 pattern deviations found in cross-command analysis
- 10/10 compliance standards validated

**Qualitative**:
- /plan documented as reference implementation
- Clear compliance examples for other commands
- Automated compliance checking integrated
- Developer knowledge of compliance patterns improved

## Completion Checklist

Before marking this plan complete:

- [ ] All 5 phases completed with checkboxes marked
- [ ] All test suites passing (compliance, edge cases, consistency)
- [ ] Git commits created for each phase
- [ ] Documentation updated and reviewed
- [ ] Compliance monitoring integrated into test suite
- [ ] Implementation summary created
- [ ] No regressions introduced (original 100% compliance maintained)
- [ ] All success criteria met

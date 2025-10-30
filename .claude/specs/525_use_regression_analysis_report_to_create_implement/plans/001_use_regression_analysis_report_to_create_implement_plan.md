# /coordinate Command Clarification and Library Sourcing Fix - Implementation Plan

## Metadata
- **Date**: 2025-10-29
- **Feature**: Clarify /coordinate "regression" context and fix library sourcing API confusion
- **Scope**: Address spec 522 findings by documenting that current state is intentional, clarify library-sourcing.sh API behavior, and prevent future baseline copy timing issues
- **Estimated Phases**: 4
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 42.5
- **Research Reports**:
  - [Existing .claude/ Infrastructure Patterns](/home/benjamin/.config/.claude/specs/525_use_regression_analysis_report_to_create_implement/reports/001_claude_infrastructure_patterns.md)
  - [/coordinate Command Regression Analysis - Key Findings](/home/benjamin/.config/.claude/specs/525_use_regression_analysis_report_to_create_implement/reports/002_regression_findings_analysis.md)
  - [Referenced Implementation Plans - Pattern Analysis](/home/benjamin/.config/.claude/specs/525_use_regression_analysis_report_to_create_implement/reports/003_referenced_plan_patterns.md)

## Overview

Analysis of the spec 522 "regression" reveals this was NOT a regression from working functionality, but rather:
1. A same-day bug fix (October 27, 2025) - /coordinate was created with broken YAML-style agent invocations (0% delegation) and fixed within 4 hours 52 minutes using imperative pattern (>90% delegation)
2. An intentional architectural pattern - orchestrators delegate to specialized agents and never execute tasks directly
3. A library refactoring issue - incomplete library sourcing was corrected by explicitly passing all required libraries

The current implementation is superior to all previous versions in every measurable way. However, library-sourcing.sh has API design confusion that needs clarification, and baseline copy timing issues should be prevented.

## Research Summary

Key findings from research reports:

**From Infrastructure Patterns Report**:
- .claude/ follows four-pillar structure: commands/, lib/, agents/, docs/
- Library organization uses consolidated sourcing (library-sourcing.sh), functional deduplication shims (artifact-operations.sh), and consolidation bundles
- Agent behavioral files in .claude/agents/ with registry-based architecture
- Templates stored in commands/templates/ (NOT .claude/templates/)

**From Regression Findings Report**:
- /coordinate created October 27 at 10:01 AM with broken YAML pattern, fixed same day at 2:53 PM
- Delegation architecture was intentional from inception (68 lines of prohibition documentation)
- Library refactoring created secondary issue: incomplete sourcing resolved by explicit passing
- Final state: 0% → >90% delegation, 0% → 100% file creation reliability, 109/109 tests passing

**From Plan Patterns Report**:
- Risk-prioritized phasing: zero/low-risk quick wins first, high-risk migrations last
- Test baseline establishment with phase boundary validation (≥80% coverage for new code)
- Backward-compatible shims for large migrations (>50 references)
- Multi-level progress checkpoints (phase-level + intra-phase)
- Comprehensive documentation as first-class deliverable

## Success Criteria
- [ ] Regression context documented in Architecture Decision Record (ADR)
- [ ] Library sourcing API behavior clarified through testing and documentation
- [ ] Baseline copy timing issue prevention mechanism implemented
- [ ] All existing tests passing (109/109 coordinate tests, 57/76 overall baseline)
- [ ] Documentation updated with clarified patterns and standards

## Technical Design

### Problem Analysis

**Problem 1: Misunderstood "Regression"**
- User believed /coordinate had regressed from working functionality
- Reality: Same-day bug fix (4 hours 52 minutes from creation to fix)
- Root cause: Baseline copy timing - /coordinate copied from /supervise before spec 438 fixes applied

**Problem 2: Library Sourcing API Confusion**
- Documentation suggests `source_required_libraries()` automatically sources 7 core libraries
- Current /coordinate usage explicitly passes all 7 core libraries plus optional dependency-analyzer.sh
- Unclear if explicit passing is required or defensive programming

**Problem 3: No Prevention for Baseline Copy Timing Issues**
- Commands copied as baselines may inherit unfixed bugs
- No validation mechanism during command creation
- No clear marker for "validated baseline" commits

### Solution Architecture

**Solution 1: Document Architectural Intent via ADR**
- Create `.claude/docs/decisions/001_orchestrator_delegation_pattern.md`
- Document when SlashCommand eliminated, problems solved, metrics
- Explain same-day bug fix context for spec 522
- Prevent future misunderstanding of intentional architectural patterns

**Solution 2: Clarify Library Sourcing API**
- Test if `source_required_libraries "dependency-analyzer.sh"` works correctly (auto-sourcing core libraries)
- If yes: Revert /coordinate to simpler call, document auto-sourcing behavior
- If no: Keep explicit passing, update documentation to require all libraries
- Document final decision in library-sourcing.sh header and lib/README.md

**Solution 3: Prevent Baseline Copy Timing Issues**
- Create baseline validation checklist for command creation
- Document in command-development-guide.md
- Add git tag convention for validated baselines
- Create template in .claude/templates/orchestration-command-template.md

### Alternative Approaches Considered

**Alternative 1: Roll Back to "Previous" Implementation**
- Rejected: No previous working implementation exists (same-day bug fix)
- Downside: Would degrade 0% → >90% delegation rate back to 0%

**Alternative 2: Keep Ambiguous Library Sourcing**
- Rejected: Causes confusion, incorrect usage, defensive over-specification
- Downside: Future commands may incorrectly assume auto-sourcing or over-specify

**Alternative 3: No Baseline Copy Prevention**
- Rejected: Same timing issue could recur with future command creation
- Downside: Wastes effort debugging "regressions" that are actually creation bugs

### Trade-offs and Limitations

**Acknowledged Limitations**:
- ADR documents past decisions but doesn't prevent future misunderstandings (requires reading)
- Library sourcing test may expose bugs in library-sourcing.sh requiring fixes
- Baseline validation checklist adds overhead to command creation (worthwhile for quality)

**Performance Characteristics**:
- Library sourcing test: ~5-10 seconds per test scenario
- ADR documentation: No runtime impact
- Baseline validation: 2-5 minutes per command creation (manual checklist)

## Implementation Phases

### Phase 1: Library Sourcing API Testing and Clarification
dependencies: []

**Objective**: Test library-sourcing.sh behavior with minimal arguments and document correct usage pattern

**Complexity**: LOW

**Tasks**:
- [ ] Create test script `.claude/tests/test_library_sourcing_api.sh` to verify auto-sourcing behavior
  - [ ] Test scenario 1: Call `source_required_libraries` with no arguments (should source 7 core libraries)
  - [ ] Test scenario 2: Call with only optional library `source_required_libraries "dependency-analyzer.sh"` (should source 7 core + dependency-analyzer)
  - [ ] Test scenario 3: Call with explicit core libraries (current /coordinate pattern)
  - [ ] Verify function availability after each scenario using `type -t function_name`
- [ ] Run test suite and document results in `.claude/specs/525_*/artifacts/library_sourcing_test_results.md`
- [ ] Based on results, determine correct API usage:
  - [ ] If scenario 2 works: Simplify /coordinate call to `source_required_libraries "dependency-analyzer.sh"`
  - [ ] If scenario 2 fails: Update library-sourcing.sh documentation to require explicit passing of all libraries
- [ ] Update `.claude/lib/library-sourcing.sh` header with clarified usage examples
- [ ] Update `.claude/lib/README.md` Library Classification section with API behavior documentation

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Run library sourcing API tests
cd /home/benjamin/.config/.claude/tests
bash test_library_sourcing_api.sh

# Expected: All 3 scenarios tested, clear pass/fail results
# Success criteria: Determine correct usage pattern with evidence
```

**Expected Duration**: 1.5-2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (library sourcing API tests created and executed)
- [ ] Git commit created: `feat(525): complete Phase 1 - Library sourcing API testing and clarification`
- [ ] Update this plan file with phase completion status

---

### Phase 2: Update /coordinate Based on API Clarification
dependencies: [1]

**Objective**: Apply correct library sourcing pattern to /coordinate.md based on Phase 1 findings

**Complexity**: LOW

**Tasks**:
- [ ] Read Phase 1 test results artifact to determine correct pattern
- [ ] If auto-sourcing works:
  - [ ] Update `.claude/commands/coordinate.md` to use simplified call: `source_required_libraries "dependency-analyzer.sh"`
  - [ ] Remove explicit passing of 7 core libraries (lines ~150-160 of coordinate.md)
- [ ] If explicit passing required:
  - [ ] Keep current /coordinate.md implementation unchanged
  - [ ] Document rationale in commit message
- [ ] Run full /coordinate test suite to verify no regression:
  - [ ] `cd /home/benjamin/.config/.claude/tests && bash test_coordinate_delegation.sh`
  - [ ] `cd /home/benjamin/.config/.claude/tests && bash test_coordinate_basic.sh`
  - [ ] Verify 109/109 tests still passing
- [ ] Update `.claude/docs/reference/library-api.md` with correct usage pattern and examples

**Testing**:
```bash
# Run full coordinate test suite
cd /home/benjamin/.config/.claude/tests
bash test_coordinate_delegation.sh
bash test_coordinate_basic.sh

# Run overall test suite baseline check
./run_all_tests.sh

# Expected: 109/109 coordinate tests passing, ≥57/76 overall baseline maintained
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (109/109 coordinate tests, ≥57/76 overall baseline)
- [ ] Git commit created: `feat(525): complete Phase 2 - Apply correct library sourcing pattern to /coordinate`
- [ ] Update this plan file with phase completion status

---

### Phase 3: Document Architectural Intent via ADR
dependencies: [1, 2]

**Objective**: Create Architecture Decision Record documenting orchestrator delegation pattern and clarifying spec 522 "regression" context

**Complexity**: MEDIUM

**Tasks**:
- [ ] Create `.claude/docs/decisions/` directory if not exists
- [ ] Create `.claude/docs/decisions/001_orchestrator_delegation_pattern.md` with sections:
  - [ ] **Title and Metadata**: ADR number, date, status (Accepted), decision owner
  - [ ] **Context**: Problem space requiring decision (command chaining vs agent delegation)
  - [ ] **Decision**: Orchestrators delegate via Task tool, never use SlashCommand/Read/Write/Edit directly
  - [ ] **Rationale**: Context bloat (5000+ tokens per command), broken behavioral injection, lost control
  - [ ] **Consequences**: Positive (context reduction, behavioral injection works, consistent patterns) and negative (requires agent creation for new capabilities)
  - [ ] **Timeline**: When SlashCommand eliminated from orchestration commands (spec 438, October 24, 2025)
  - [ ] **Performance Metrics**: Context usage before/after (5000 tokens → 250 tokens per delegation), delegation rate improvement (0% → >90%)
  - [ ] **Migration Path**: 3 orchestration commands (/coordinate, /orchestrate, /supervise) fully migrated
  - [ ] **Spec 522 Clarification**: Document same-day bug fix timeline (October 27, 2025: 10:01 AM creation → 2:53 PM fix)
  - [ ] **References**: Link to spec 522 reports, commit hashes (1179e2e1, a79d0e87, 42cf20cb), Standard 11 in command_architecture_standards.md
- [ ] Create `.claude/docs/decisions/002_library_sourcing_api_design.md` with sections:
  - [ ] **Title and Metadata**: Document library-sourcing.sh API behavior decision from Phase 1
  - [ ] **Context**: Confusion between auto-sourcing vs explicit passing of core libraries
  - [ ] **Decision**: [Document Phase 1 decision: auto-sourcing or explicit passing]
  - [ ] **Rationale**: [Document test results justifying decision]
  - [ ] **Consequences**: Commands use consistent library sourcing pattern, reduced boilerplate (if auto-sourcing) or explicit clarity (if explicit passing)
  - [ ] **References**: Link to Phase 1 test results artifact, library-sourcing.sh, lib/README.md
- [ ] Update `.claude/docs/README.md` to add "Architecture Decision Records" section linking to decisions/
- [ ] Update `CLAUDE.md` quick reference section to include ADR location (if not already present)

**Testing**:
```bash
# Verify ADR files created with required sections
test -f /home/benjamin/.config/.claude/docs/decisions/001_orchestrator_delegation_pattern.md || echo "ERROR: ADR 001 not found"
test -f /home/benjamin/.config/.claude/docs/decisions/002_library_sourcing_api_design.md || echo "ERROR: ADR 002 not found"

# Check required sections present in ADR 001
grep -q "## Context" /home/benjamin/.config/.claude/docs/decisions/001_orchestrator_delegation_pattern.md
grep -q "## Decision" /home/benjamin/.config/.claude/docs/decisions/001_orchestrator_delegation_pattern.md
grep -q "## Rationale" /home/benjamin/.config/.claude/docs/decisions/001_orchestrator_delegation_pattern.md
grep -q "## Consequences" /home/benjamin/.config/.claude/docs/decisions/001_orchestrator_delegation_pattern.md
grep -q "Spec 522 Clarification" /home/benjamin/.config/.claude/docs/decisions/001_orchestrator_delegation_pattern.md

# Check required sections present in ADR 002
grep -q "## Context" /home/benjamin/.config/.claude/docs/decisions/002_library_sourcing_api_design.md
grep -q "## Decision" /home/benjamin/.config/.claude/docs/decisions/002_library_sourcing_api_design.md

echo "✓ ADR validation complete"
```

**Expected Duration**: 2-2.5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (ADR validation commands pass)
- [ ] Git commit created: `docs(525): complete Phase 3 - Document architectural intent via ADRs`
- [ ] Update this plan file with phase completion status

---

### Phase 4: Prevent Baseline Copy Timing Issues
dependencies: [1, 2, 3]

**Objective**: Create validation mechanisms and documentation to prevent future commands from inheriting unfixed bugs through baseline copy timing issues

**Complexity**: MEDIUM

**Tasks**:
- [ ] Create `.claude/docs/guides/command-creation-checklist.md` with sections:
  - [ ] **Pre-Creation Validation**: Verify source command has all architectural fixes applied
    - [ ] Check delegation rate >90% using `.claude/lib/validate-agent-invocation-pattern.sh`
    - [ ] Verify no YAML-style Task blocks (pattern: `Task {`)
    - [ ] Confirm all agent invocations use imperative pattern (pattern: `**EXECUTE NOW**`)
    - [ ] Run test suite on source command (all tests passing)
  - [ ] **Baseline Tagging Convention**: Use git tags like `baseline-orchestration-v1.0` after full validation
  - [ ] **Post-Copy Validation**: After copying baseline, re-verify all patterns in new command
  - [ ] **Testing Requirements**: Create command-specific test suite before first use
  - [ ] **Documentation Requirements**: Update command README with command-specific behavior
  - [ ] **Review Checklist**: 10-item checklist for command creation review
- [ ] Update `.claude/docs/guides/command-development-guide.md` to reference command-creation-checklist.md
  - [ ] Add "Creating New Orchestration Commands" section linking to checklist
  - [ ] Document baseline tagging convention with examples
  - [ ] Explain timing issue risks (spec 522 case study)
- [ ] Create `.claude/templates/orchestration-command-template.md` as validated baseline template:
  - [ ] Copy current /coordinate.md as baseline (includes all spec 438/497 fixes)
  - [ ] Add placeholder sections: `{{COMMAND_NAME}}`, `{{WORKFLOW_DESCRIPTION}}`, `{{AGENT_TYPES}}`
  - [ ] Include all architectural patterns: imperative agent invocation, no command chaining, Phase 0-7 structure
  - [ ] Document template maintenance: update after major architectural changes, re-tag baselines
- [ ] Add baseline validation to `.claude/lib/validate-agent-invocation-pattern.sh`:
  - [ ] Add `--baseline-check` flag for comprehensive validation
  - [ ] Check for YAML-style Task blocks and report line numbers
  - [ ] Verify imperative language patterns present
  - [ ] Output validation score (0-100) for baseline suitability

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify checklist and template created
test -f /home/benjamin/.config/.claude/docs/guides/command-creation-checklist.md || echo "ERROR: Checklist not found"
test -f /home/benjamin/.config/.claude/templates/orchestration-command-template.md || echo "ERROR: Template not found"

# Test baseline validation enhancement
cd /home/benjamin/.config/.claude/lib
bash validate-agent-invocation-pattern.sh --baseline-check ../commands/coordinate.md

# Expected: Validation score ≥90 for /coordinate.md (fully compliant)

# Test detection of broken patterns (use archived spec 491 version if available)
# Expected: Validation score <50 for pre-fix version (detects YAML blocks)

echo "✓ Baseline prevention mechanism validation complete"
```

**Expected Duration**: 2.5-3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (baseline validation tests pass)
- [ ] Git commit created: `feat(525): complete Phase 4 - Prevent baseline copy timing issues`
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Test Baseline Establishment
- **Current Baseline**: 109/109 coordinate tests passing, 57/76 overall tests passing (75% overall baseline rate)
- **Success Criteria**: Maintain or improve baseline throughout implementation
- **Regression Detection**: Any drop below 109/109 coordinate or 57/76 overall triggers investigation

### Phase-Level Testing
- **Phase 1**: Library sourcing API tests (new test suite, 3 scenarios)
- **Phase 2**: Full /coordinate test suite (109 tests), overall baseline check (57/76)
- **Phase 3**: ADR validation (grep checks for required sections)
- **Phase 4**: Baseline validation enhancement tests (validate-agent-invocation-pattern.sh)

### Coverage Requirements
- **Target**: ≥80% coverage for new code (test_library_sourcing_api.sh, command-creation-checklist.md validation)
- **Baseline**: Maintain 75% overall passing rate (57/76 tests)
- **New Tests**: 1 new test suite (library sourcing API), ~10 test scenarios

### Integration Testing
- Run full test suite after each phase to detect cross-phase issues
- Test /coordinate end-to-end after Phase 2 changes
- Validate baseline validation tool against multiple command versions (Phase 4)

## Documentation Requirements

### Files Requiring Updates

**Primary Documentation**:
- `.claude/docs/decisions/001_orchestrator_delegation_pattern.md` (NEW - Phase 3)
- `.claude/docs/decisions/002_library_sourcing_api_design.md` (NEW - Phase 3)
- `.claude/docs/guides/command-creation-checklist.md` (NEW - Phase 4)
- `.claude/templates/orchestration-command-template.md` (NEW - Phase 4)

**Reference Documentation**:
- `.claude/lib/library-sourcing.sh` header (Phase 1 - clarified usage examples)
- `.claude/lib/README.md` Library Classification section (Phase 1 - API behavior)
- `.claude/docs/reference/library-api.md` (Phase 2 - correct usage pattern)
- `.claude/docs/guides/command-development-guide.md` (Phase 4 - baseline tagging, timing risks)
- `.claude/docs/README.md` (Phase 3 - ADR section)
- `CLAUDE.md` quick reference (Phase 3 - ADR location, if not present)

**Test Documentation**:
- `.claude/specs/525_*/artifacts/library_sourcing_test_results.md` (NEW - Phase 1)

### Documentation Standards
- Follow timeless documentation approach (no historical markers like "New" or "Previously")
- Use imperative language for required actions (MUST/WILL/SHALL)
- Include concrete examples with absolute file paths
- Document decision rationale (not just outcomes)
- Cross-reference related documentation (ADRs, guides, standards)

## Dependencies

### External Dependencies
- None (all work internal to .claude/)

### Internal Dependencies
- **Phase Dependencies**:
  - Phase 2 depends on Phase 1 (API clarification needed before /coordinate update)
  - Phase 3 depends on Phases 1-2 (ADR documents decisions from earlier phases)
  - Phase 4 depends on Phases 1-3 (checklist references ADRs and validated patterns)
- **Library Dependencies**:
  - library-sourcing.sh (Phase 1 testing target)
  - validate-agent-invocation-pattern.sh (Phase 4 enhancement target)
- **Command Dependencies**:
  - /coordinate.md (Phase 2 update target)

### Rollback Dependencies
- **Primary**: Git history (revert commits per phase)
- **Secondary**: Plan file checkpoints (restore incomplete phases)
- **Validation**: Test suite (verify successful rollback)

### Prerequisite Knowledge
- Bash sourcing patterns and function visibility
- Git tagging conventions for baseline markers
- ADR format and purpose (documenting architectural decisions)
- /coordinate command structure (Phase 0-7 orchestration pattern)

## Rollback Procedures

### Immediate Rollback (Phase-Level)
```bash
# Rollback most recent phase
git log --oneline -5  # Identify commit to revert
git revert <commit-hash>
git commit -m "rollback(525): Revert Phase N - [reason for rollback]"

# Verify rollback
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Expected: 57/76 tests passing (baseline maintained)
```

### Phase-Specific Rollback Procedures

**Phase 1 Rollback**:
- Remove test_library_sourcing_api.sh if causing issues
- Restore original library-sourcing.sh header
- No impact on /coordinate (Phase 2 not yet executed)

**Phase 2 Rollback**:
- Restore /coordinate.md to explicit library passing pattern
- Re-run coordinate test suite to verify 109/109 passing
- Keep Phase 1 test results for future reference

**Phase 3 Rollback**:
- Remove ADR files if misleading
- Restore docs/README.md and CLAUDE.md references
- No code impact (documentation-only phase)

**Phase 4 Rollback**:
- Remove command-creation-checklist.md and template if not useful
- Restore original command-development-guide.md
- Restore original validate-agent-invocation-pattern.sh

### Emergency Rollback (Full Implementation)
```bash
# Revert all phases in reverse order
git log --oneline --grep="feat(525)" | tac | while read commit msg; do
  git revert --no-commit $commit
done
git commit -m "rollback(525): Emergency rollback - full implementation reverted"

# Verify system state
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

### Rollback Decision Criteria
- **Trigger Rollback If**:
  - Test passing rate drops below 57/76 overall baseline
  - /coordinate test passing rate drops below 109/109
  - Library sourcing changes break other commands (detected in overall test suite)
  - ADR documentation is factually incorrect or misleading
  - Baseline validation enhancement breaks existing workflows

- **Monitor For**:
  - Test failure patterns after each phase
  - /coordinate command functionality (manual smoke test)
  - Library sourcing behavior in other commands
  - False positives from enhanced validate-agent-invocation-pattern.sh

## Risk Assessment

### Risk 1: Library Sourcing Test Reveals Bug in library-sourcing.sh
- **Severity**: MEDIUM
- **Likelihood**: MEDIUM (API confusion suggests possible implementation mismatch)
- **Impact**: May require fixing library-sourcing.sh instead of just documenting behavior
- **Mitigation**: If bug found, defer fix to separate spec (document as "Known Issue" in Phase 1 artifact)

### Risk 2: /coordinate Changes Break Other Commands Using Same Pattern
- **Severity**: HIGH
- **Likelihood**: LOW (changes isolated to /coordinate, other commands tested in overall suite)
- **Impact**: Multiple commands may need updates if pattern incorrect
- **Mitigation**: Run full test suite after Phase 2, check for cascading failures

### Risk 3: Baseline Validation Enhancement Too Strict
- **Severity**: MEDIUM
- **Likelihood**: MEDIUM (defining "valid baseline" is subjective)
- **Impact**: False positives may block valid command creation
- **Mitigation**: Use scoring system (0-100) instead of pass/fail, document score interpretation

### Risk 4: ADR Documentation Misinterprets Spec 522 Findings
- **Severity**: HIGH
- **Likelihood**: LOW (research reports thoroughly analyzed)
- **Impact**: Future developers misunderstand architectural intent
- **Mitigation**: Cross-reference commit hashes, include quotes from research reports, peer review ADR

## Future Improvements

### Stretch Goals (Out of Scope for This Plan)
- Automated baseline validation in pre-commit hooks
- ADR template generator tool
- Comprehensive test suite for all library-sourcing.sh functions
- Migration of other commands to simplified library sourcing (if Phase 1 proves auto-sourcing works)

### Follow-Up Specs
- If Phase 1 reveals library-sourcing.sh bug: Create spec to fix implementation
- If baseline validation useful: Extend to all command types (not just orchestration)
- If ADR pattern successful: Create ADRs for other major architectural decisions

## Revision History

### 2025-10-29 - Initial Plan Creation

**Context**: Created based on spec 522 regression analysis findings, incorporating patterns from spec 523 (shim research) and spec 519 (library loading).

**Research Integration**: 3 research reports analyzed and referenced in metadata.

**Complexity Calculation**:
- Base (enhance existing feature): 7
- Tasks (29 tasks): 14.5
- Files (14 files to create/modify): 42
- Integrations (0 external): 0
- **Total**: 7 + 14.5 + 42 + 0 = 63.5 (adjusted to 42.5 based on low risk)

**Key Decisions**:
- Prioritized library sourcing clarification (Phase 1-2) before documentation (Phase 3-4)
- Included ADR creation to prevent future misunderstandings of architectural intent
- Added baseline validation mechanism to prevent recurrence of timing issues

**Phase Structure**: 4 phases with explicit dependencies (Phase 1 independent, Phase 2 depends on 1, Phase 3 depends on 1-2, Phase 4 depends on 1-3)

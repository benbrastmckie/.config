# Research Standards Conformance Fix Implementation Plan

## Metadata
- **Date**: 2025-12-10
- **Feature**: Fix /research command preprocessing errors and resolve standards conformance violations across command files
- **Status**: [COMPLETE]
- **Estimated Hours**: 12-18 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Research Report: Error Analysis in Research Output](../reports/001-error-analysis-research-output.md)
  - [Research Report: Standards Conformance Assessment](../reports/002-standards-conformance-assessment.md)
  - [Research Report: Standards Revision Strategy](../reports/003-standards-revision-strategy.md)
- **Scope**: Fix critical preprocessing bug in /research command, resolve defensive variable expansion violations across 15 commands, fix linter bugs, investigate hard barrier pattern requirements, and document array iteration anti-patterns
- **Complexity Score**: 158 (Medium-High)
- **Structure Level**: 0

## Overview

The `/research` command is completely non-functional due to bash preprocessing corruption of indirect array expansion syntax `${!ARRAY[@]}` at three locations. This causes "bad substitution" errors that prevent research execution. Additionally, comprehensive standards validation revealed 5 error categories affecting 15+ command files:

1. **Critical Bug**: Preprocessing-unsafe array iteration pattern (blocks /research execution)
2. **Widespread Issue**: Unbound variable expansions with `set -u` enabled (15 files)
3. **Standards Quality**: Hard barrier pattern requirements unclear/overly prescriptive (10 files)
4. **Tooling Issue**: Error suppression linter has bugs causing false positives
5. **Minor Issues**: Missing library sourcing, error logging coverage gaps

Research shows the fix is straightforward: replace `${!TOPICS_ARRAY[@]}` with seq-based iteration pattern `seq 0 $((${#TOPICS_ARRAY[@]} - 1))` that other commands (/create-plan, /lean-plan, /implement) already use successfully.

## Research Summary

**Error Analysis (Report 1)**: The /research command encountered bash array handling errors during execution, with output truncated at 78 lines. Three critical error patterns identified:
- Bad substitution error from `${\!TOPICS_ARRAY[@]}` (preprocessing corruption)
- Unbound variable error from REPORT_PATHS_ARRAY[0] (cascading failure)
- Incomplete execution with zero research artifacts created
- Root cause: Bash preprocessing transformation bugs triggered by indirect array expansion syntax

**Standards Conformance (Report 2)**: Root cause is preprocessing-unsafe `${!ARRAY[@]}` syntax at lines 487, 508, and 916 in /research.md. This is a documented anti-pattern in bash-tool-limitations.md but lacks explicit "NEVER use" prohibition. Solution: Replace with seq-based iteration pattern already validated in /create-plan, /lean-plan, and /implement commands. This is an implementation fix, not a standards revision issue.

**Standards Revision Strategy (Report 3)**: Comprehensive validation identified 5 error categories:
- Category 1 (Unbound Variables): 15 files with defensive expansion violations - FIX CODE
- Category 2 (Missing Libraries): 1 file missing state-persistence.sh sourcing - FIX CODE
- Category 3 (Error Suppression): 1 file with || true anti-pattern - FIX CODE
- Category 4 (Hard Barrier): 10 files missing pattern compliance - INVESTIGATE STANDARD
- Category 5 (Linter Bugs): Integer expression error and false positives - FIX LINTER
- Category 6 (Error Logging): 1 file below 80% coverage - FIX CODE

Recommended approach: Fix legitimate code issues (80% of errors) while investigating hard barrier pattern requirements (20% standards quality issue).

## Success Criteria
- [ ] /research command executes successfully without preprocessing errors
- [ ] All three array iteration anti-patterns replaced with seq-based pattern
- [ ] 15 commands updated with defensive variable expansion syntax
- [ ] Error suppression linter bugs resolved (integer expression, false positives)
- [ ] Hard barrier pattern investigation completed with decision documented
- [ ] Array iteration documentation added to bash-tool-limitations.md
- [ ] New linter created to detect ${!ARRAY[@]} anti-pattern
- [ ] /research command validation passes with test invocations
- [ ] All validation scripts return exit code 0 for affected commands
- [ ] Pre-commit hooks updated if needed for new linter integration

## Technical Design

### Architecture Overview

**Component 1: Array Iteration Pattern Fix**
- Target: /research.md lines 487, 508, 916
- Change: Replace `for i in "${!TOPICS_ARRAY[@]}"` with `for i in $(seq 0 $((${#TOPICS_ARRAY[@]} - 1)))`
- Rationale: Seq-based iteration avoids preprocessing corruption that affects indirect expansion
- Precedent: /create-plan (line 1309), /lean-plan (line 919), /implement (lines 1295, 1624)

**Component 2: Defensive Variable Expansion**
- Target: 15 command files using unbound variables with `set -u` enabled
- Pattern: Replace `$VAR` with `${VAR:-}` or `${VAR:-default}` in all bash blocks
- Focus Areas: log_command_error calls, state persistence functions, conditional expressions
- Standard: .claude/docs/concepts/patterns/error-handling.md#defensive-variable-expansion

**Component 3: Linter Quality Improvements**
- Fix: lint_error_suppression.sh line 110 integer expression bug (variable contains "0\n0")
- Enhancement: Relax verification pattern matching to reduce false positives
- New Linter: lint-array-iteration.sh to detect ${!ARRAY[@]} patterns
- Integration: Add --array-iteration category to validate-all-standards.sh

**Component 4: Standards Documentation Enhancements**
- Add: Array Iteration Patterns section to bash-tool-limitations.md
- Content: Explicit anti-pattern prohibition with "NEVER use" language
- Include: Code examples showing broken vs correct patterns
- Cross-Reference: Link from command-authoring.md code standards

**Component 5: Hard Barrier Pattern Investigation**
- Research: Origin, purpose, and scope of hard barrier pattern requirements
- Analysis: Review validator logic and compliant vs non-compliant commands
- Decision: Update standard, update commands, or update validator
- Documentation: Record decision rationale in investigation report

### Integration Points
- Pre-commit hooks: May need update if new linter added
- validate-all-standards.sh: Add --array-iteration category
- Research command: Critical path for ProofChecker project usage
- Command discovery hierarchy: Ensure ProofChecker syncs updated /research

### Standards Alignment
- Code Standards: Three-tier sourcing pattern maintained, defensive expansion enforced
- Output Formatting: Suppression patterns with 2>/dev/null retained where appropriate
- Error Logging: Explicit error handling replaces || true anti-patterns
- Testing Protocols: Validation tests for each fix category
- Documentation Standards: New sections follow existing format conventions

## Implementation Phases

### Phase 1: Critical /research Command Fix [COMPLETE]
dependencies: []

**Objective**: Fix preprocessing-unsafe array iteration in /research command to restore functionality

**Complexity**: Low

**Tasks**:
- [x] Read /research.md to identify exact line numbers for all three ${!TOPICS_ARRAY[@]} occurrences
- [x] Replace line 487 display loop: `for i in "${!TOPICS_ARRAY[@]}"` → `for i in $(seq 0 $((${#TOPICS_ARRAY[@]} - 1)))`
- [x] Replace line 508 report path generation loop with seq-based iteration
- [x] Replace line 916 validation loop with seq-based iteration
- [x] Verify no other indirect expansion patterns exist in /research.md
- [x] Test /research with single-topic mode: `/research "test single topic research"`
- [x] Test /research with multi-topic mode: `/research "test multi-topic research" --complexity 3`
- [x] Verify no "bad substitution" errors in output
- [x] Verify REPORT_PATHS_ARRAY populated correctly (no unbound variable errors)
- [x] Confirm research reports created in expected directory

**Testing**:
```bash
# Test single-topic mode (complexity < 3)
/research "test authentication patterns analysis"
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test multi-topic mode (complexity >= 3, triggers coordinator)
/research "comprehensive async implementation research" --complexity 3
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Verify no preprocessing errors in output
! grep -q "bad substitution" /home/benjamin/.config/.claude/output/research-output.md || exit 1
! grep -q "unbound variable" /home/benjamin/.config/.claude/output/research-output.md || exit 1

# Verify artifacts created
test -d /home/benjamin/.config/.claude/specs/*/reports/ || exit 1
```

**Expected Duration**: 2 hours

### Phase 2: Documentation and Linter for Array Iteration Anti-Pattern [COMPLETE]
dependencies: [1]

**Objective**: Document array iteration anti-pattern and create automated detection

**Complexity**: Medium

**Tasks**:
- [x] Add "Array Iteration Patterns" section to bash-tool-limitations.md after line 462
- [x] Document ${!ARRAY[@]} as "NEVER use" anti-pattern with error symptom examples
- [x] Provide seq-based correct pattern with explanation of why it works
- [x] List validated commands using this pattern (/create-plan, /lean-plan, /implement)
- [x] Create new linter: .claude/scripts/lint/lint-array-iteration.sh
- [x] Implement grep-based detection for ${!.*[@]} regex pattern
- [x] Return ERROR severity for command files, WARNING for agent files
- [x] Add --array-iteration category to validate-all-standards.sh
- [x] Test linter against /research.md (should fail before Phase 1, pass after)
- [x] Test linter against /create-plan.md (should pass, uses seq pattern)
- [x] Update CLAUDE.md code_standards section to reference new documentation
- [x] Run full validation suite to ensure no regressions

**Testing**:
```bash
# Verify documentation added correctly
grep -q "Array Iteration Patterns" /home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Verify linter exists and is executable
test -f /home/benjamin/.config/.claude/scripts/lint/lint-array-iteration.sh || exit 1
test -x /home/benjamin/.config/.claude/scripts/lint/lint-array-iteration.sh || exit 1

# Test linter on compliant command (should pass)
bash /home/benjamin/.config/.claude/scripts/lint/lint-array-iteration.sh /home/benjamin/.config/.claude/commands/create-plan.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test linter on non-compliant command (should fail before fix)
bash /home/benjamin/.config/.claude/scripts/lint/lint-array-iteration.sh /home/benjamin/.config/.claude/commands/research.md.backup
EXIT_CODE=$?
test $EXIT_CODE -ne 0 || exit 1

# Verify integration with unified validator
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --array-iteration 2>&1 | grep -q "array-iteration"
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1
```

**Expected Duration**: 3 hours

### Phase 3: Defensive Variable Expansion Fixes (15 Commands) [COMPLETE]
dependencies: []

**Objective**: Fix unbound variable expansion violations across all affected commands

**Complexity**: Medium

**Tasks**:
- [x] Create list of 15 affected commands from Report 3 findings
- [x] For each command, identify unbound variable usages with grep: `grep -n '\$[A-Z_]*[^{]' command.md`
- [x] Replace append_workflow_state calls: Add ${VAR:-} for TOPIC_NAME_FILE, STATE_DIR, etc
- [x] Replace log_command_error calls: Add ${USER_ARGS:-} fallback for all invocations
- [x] Fix integer comparisons: Quote variables in conditionals `[ -z "${VAR:-}" ]`
- [x] Fix state persistence calls: Add defensive expansion for all state variables
- [x] Test each command after fixes with validation: `bash .claude/scripts/validate-all-standards.sh --unbound-variables`
- [x] Verify no "unbound variable" errors with `set -u` enabled
- [x] Document pattern in error-handling.md if not already present
- [x] Update 3 commands per batch, validate, commit, then next batch

**Affected Commands** (from Report 3):
1. /collapse.md
2. /create-plan.md
3. /debug.md
4. /expand.md
5. /implement.md
6. /lean-build.md
7. /lean-implement.md
8. /lean-plan.md
9. /optimize-claude.md
10. /repair.md
11. /research.md (if not covered in Phase 1)
12. /revise.md
13. /setup.md
14. /test.md
15. /todo.md

**Testing**:
```bash
# Run unbound variable validation on all commands
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --unbound-variables
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test sample command with set -u enabled
(
  set -u
  source /home/benjamin/.config/.claude/commands/create-plan.md
  # Should not error on unbound variables
)
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Verify defensive expansion pattern used
grep -q '${.*:-}' /home/benjamin/.config/.claude/commands/create-plan.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1
```

**Expected Duration**: 5 hours

### Phase 4: Fix Minor Code Issues (3 Files) [COMPLETE]
dependencies: []

**Objective**: Resolve missing library sourcing, error suppression anti-patterns, and error logging coverage

**Complexity**: Low

**Tasks**:
- [x] Fix /errors.md: Add state-persistence.sh sourcing to block 3 before save_completed_states_to_state call
- [x] Verify sourcing pattern: Include fail-fast handler after source statement
- [x] Fix /lean-implement.md line 1445: Replace `save_completed_states_to_state 2>/dev/null || true` with explicit error handling
- [x] Add log_command_error call with proper error context for state save failures
- [x] Fix /collapse.md: Add explicit error logging to 5 remaining exit points (73% → 80%+ coverage)
- [x] Identify exit points: Search for `exit 1` without preceding log_command_error
- [x] Test /errors.md: Verify command executes without "command not found" errors
- [x] Test /lean-implement.md: Verify error suppression linter passes
- [x] Test /collapse.md: Verify error logging coverage validator returns >= 80%

**Testing**:
```bash
# Test state persistence sourcing in /errors.md
bash /home/benjamin/.config/.claude/scripts/lint/check-library-sourcing.sh /home/benjamin/.config/.claude/commands/errors.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test error suppression anti-pattern fix
bash /home/benjamin/.config/.claude/scripts/lint/lint_error_suppression.sh /home/benjamin/.config/.claude/commands/lean-implement.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test error logging coverage
COVERAGE=$(bash /home/benjamin/.config/.claude/scripts/lint/check-error-logging-coverage.sh /home/benjamin/.config/.claude/commands/collapse.md 2>&1 | grep -oP '\d+(?=%)')
awk -v cov="$COVERAGE" 'BEGIN { exit (cov < 80) ? 1 : 0 }' || exit 1
```

**Expected Duration**: 1 hour

### Phase 5: Hard Barrier Pattern Investigation and Resolution [COMPLETE]
dependencies: []

**Objective**: Investigate hard barrier pattern requirements and determine resolution approach

**Complexity**: Medium

**Tasks**:
- [x] Search for hard barrier pattern documentation in .claude/docs/
- [x] Read validate-hard-barrier.sh validator to understand enforcement logic
- [x] Review git history for pattern introduction: `git log --grep="hard barrier" --all`
- [x] Analyze compliant commands: What patterns do they use that pass validation?
- [x] Analyze non-compliant commands: What specific checks are failing?
- [x] Answer: Does pattern apply to all commands or specific types (multi-agent orchestrators)?
- [x] Answer: Is Na/Nb/Nc naming required or just semantic structure?
- [x] Answer: Should "CANNOT be bypassed" be exact text or semantic enforcement?
- [x] Document decision in investigation report: .claude/specs/024_research_standards_conformance_fix/reports/004-hard-barrier-pattern-investigation.md
- [x] Choose resolution path: (A) Update 10 commands with pattern, (B) Revise standard to be less prescriptive, or (C) Update validator for false positives
- [x] If path A: Create checklist for adding pattern to 10 commands
- [x] If path B: Revise .claude/docs/reference/standards/command-authoring.md with relaxed requirements
- [x] If path C: Update validate-hard-barrier.sh with improved detection logic

**Affected Commands** (10 files from Report 3):
1. /implement.md
2. /collapse.md
3. /debug.md
4. /errors.md
5. /expand.md
6. /lean-build.md
7. /lean-implement.md
8. /lean-plan.md
9. /optimize-claude.md
10. /repair.md

**Testing**:
```bash
# Run hard barrier validation on all commands
bash /home/benjamin/.config/.claude/tests/utilities/validate-hard-barrier.sh /home/benjamin/.config/.claude/commands/*.md
EXIT_CODE=$?
# Exit code depends on resolution path chosen

# If path A or C: Should return 0 (all pass)
test $EXIT_CODE -eq 0 || exit 1

# Verify investigation report created
test -f /home/benjamin/.config/.claude/specs/024_research_standards_conformance_fix/reports/004-hard-barrier-pattern-investigation.md || exit 1

# Verify decision documented in report
grep -q "Resolution Path:" /home/benjamin/.config/.claude/specs/024_research_standards_conformance_fix/reports/004-hard-barrier-pattern-investigation.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1
```

**Expected Duration**: 3 hours

### Phase 6: Fix Error Suppression Linter Bugs [COMPLETE]
dependencies: []

**Objective**: Resolve linter bugs causing integer expression errors and false positives

**Complexity**: Low

**Tasks**:
- [x] Read lint_error_suppression.sh line 110 to understand integer expression bug
- [x] Debug: Run linter with `set -x` to see variable values before comparison
- [x] Fix: Likely grep -c returning "0\n0" instead of "0" for multiple files
- [x] Solution: Use `grep -c ... | head -1` or sum counts properly with awk
- [x] Test fix with sample commands to verify integer expression error gone
- [x] Review false positive warnings for verification pattern matching
- [x] Identify: What verification patterns are commands using that linter doesn't recognize?
- [x] Enhance regex: Expand verification pattern detection to include alternative patterns
- [x] Test enhanced linter against /create-plan.md, /implement.md, /lean-plan.md
- [x] Verify no false positives for commands with proper verification
- [x] Add test cases to prevent regression: .claude/tests/utilities/test_lint_error_suppression.sh

**Testing**:
```bash
# Test linter integer expression fix
bash /home/benjamin/.config/.claude/tests/utilities/lint_error_suppression.sh /home/benjamin/.config/.claude/commands/*.md 2>&1 | grep -q "integer expression expected"
EXIT_CODE=$?
test $EXIT_CODE -ne 0 || exit 1  # Should NOT find integer expression error

# Test false positive reduction
bash /home/benjamin/.config/.claude/tests/utilities/lint_error_suppression.sh /home/benjamin/.config/.claude/commands/create-plan.md 2>&1 | grep -q "WARNING.*verification"
EXIT_CODE=$?
test $EXIT_CODE -ne 0 || exit 1  # Should NOT warn on properly verified command

# Run full error suppression validation
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --error-suppression
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1
```

**Expected Duration**: 1 hour

### Phase 7: Integration Testing and Cross-Project Sync [COMPLETE]
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Validate all fixes work together and sync /research command to ProofChecker project

**Complexity**: Low

**Tasks**:
- [x] Run full validation suite: `bash .claude/scripts/validate-all-standards.sh --all`
- [x] Verify exit code 0 (all validators pass)
- [x] Test /research command with realistic multi-topic scenario
- [x] Verify research-coordinator integration still works after array iteration fix
- [x] Check ProofChecker project for local .claude/commands/research.md override
- [x] If override exists: Copy updated /research.md from .config to ProofChecker
- [x] Test /research in ProofChecker context with Lean-specific query
- [x] Verify no "bad substitution" or "unbound variable" errors in ProofChecker
- [x] Update ProofChecker CLAUDE.md if needed to document command sync
- [x] Run pre-commit hooks on all modified files to ensure compliance
- [x] Create validation checklist document for future reference

**Testing**:
```bash
# Full validation suite (all categories)
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --all
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test /research in .config project
cd /home/benjamin/.config
/research "comprehensive testing of array iteration fix" --complexity 3
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Test /research in ProofChecker project
cd /home/benjamin/Documents/Philosophy/Projects/ProofChecker
/research "Lean proof automation temporal deduction" --complexity 2
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Verify no preprocessing errors in either output
! grep -q "bad substitution" /home/benjamin/.config/.claude/output/research-output.md || exit 1
! grep -q "bad substitution" /home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/output/research-output.md || exit 1

# Run pre-commit validation on modified files
git diff --name-only --cached | xargs bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --staged
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
Each phase includes targeted validation tests for specific fixes:
- Phase 1: /research command execution tests (single/multi-topic modes)
- Phase 2: Linter tests (detection accuracy, integration validation)
- Phase 3: Defensive expansion validation (unbound variable detection)
- Phase 4: Library sourcing, error suppression, error logging validators
- Phase 5: Hard barrier pattern validation (decision-dependent)
- Phase 6: Linter regression tests (integer expression, false positives)

### Integration Testing
Phase 7 provides comprehensive cross-cutting validation:
- Full validation suite execution (all categories combined)
- Real-world /research scenarios (realistic queries, complexity levels)
- Cross-project testing (ProofChecker sync validation)
- Pre-commit hook integration (ensure no regressions)

### Validation Commands
Primary validation scripts used throughout implementation:
```bash
# Unified validator (all categories)
bash .claude/scripts/validate-all-standards.sh --all

# Specific category validators
bash .claude/scripts/validate-all-standards.sh --array-iteration
bash .claude/scripts/validate-all-standards.sh --unbound-variables
bash .claude/scripts/validate-all-standards.sh --error-suppression
bash .claude/scripts/validate-all-standards.sh --state-persistence-sourcing
bash .claude/scripts/validate-all-standards.sh --error-logging-coverage

# Hard barrier (decision-dependent)
bash .claude/tests/utilities/validate-hard-barrier.sh .claude/commands/*.md

# Individual linters
bash .claude/scripts/lint/lint-array-iteration.sh <command-file>
bash .claude/scripts/lint/check-library-sourcing.sh <command-file>
bash .claude/tests/utilities/lint_error_suppression.sh <command-file>
```

### Success Metrics
- /research command: 100% success rate on test invocations (no preprocessing errors)
- Validation suite: Exit code 0 for all categories (100% compliance)
- Error logging: >= 80% coverage for all commands
- Linter accuracy: Zero false positives on known-good commands
- Cross-project: ProofChecker /research executes successfully

### Non-Interactive Automation
All testing is automated with exit code validation:
- No manual inspection required
- No visual verification steps
- Programmatic assertions for all success criteria
- Test artifacts: validation logs, command output captures

## Documentation Requirements

### New Documentation Files
1. **Array Iteration Patterns Section** (bash-tool-limitations.md)
   - Add after line 462 in troubleshooting documentation
   - Content: Anti-pattern prohibition, correct pattern, validated examples
   - Cross-reference from command-authoring.md code standards section

2. **Hard Barrier Pattern Investigation Report** (new file)
   - Path: .claude/specs/024_research_standards_conformance_fix/reports/004-hard-barrier-pattern-investigation.md
   - Content: Research findings, decision rationale, resolution path chosen
   - Format: Standard research report structure with findings/recommendations

3. **Linter Script** (new file)
   - Path: .claude/scripts/lint/lint-array-iteration.sh
   - Content: Grep-based detection for ${!.*[@]} pattern
   - Integration: --array-iteration category in validate-all-standards.sh

### Updated Documentation Files
1. **CLAUDE.md code_standards Section**
   - Add reference to array iteration anti-pattern documentation
   - Link to bash-tool-limitations.md#array-iteration-patterns

2. **command-authoring.md**
   - Add note about defensive variable expansion requirement
   - Reference error-handling.md patterns for unbound variable handling
   - Link to array iteration documentation if not present

3. **Research Command Guide** (if needed)
   - Document array iteration fix in troubleshooting section
   - Update Issue 6 to reference seq-based solution explicitly

### Documentation Standards Compliance
- Follow CommonMark specification for all markdown files
- Use UTF-8 encoding without emojis (per documentation policy)
- Include code examples with syntax highlighting (```bash blocks)
- Cross-reference related documentation with relative paths
- Update existing docs rather than creating new unless necessary
- Remove historical commentary (clean-break development standard)

## Dependencies

### External Dependencies
None - all fixes use existing bash utilities and validation scripts

### Internal Dependencies
- state-persistence.sh library (sourcing fix in Phase 4)
- validation-utils.sh library (validation functions throughout)
- error-handling.sh library (log_command_error integration)
- validate-all-standards.sh (integration point for new linter)
- All bash linters in .claude/tests/utilities/ and .claude/scripts/lint/

### Prerequisite Conditions
- Git working directory clean (or changes committed) before starting fixes
- .config project is current working directory for command modifications
- ProofChecker project accessible for cross-project sync testing
- All existing validation scripts functional and executable

### Phase Dependencies
- Phase 2 depends on Phase 1: Documentation/linter reference Phase 1 fix
- Phase 7 depends on Phases 1-6: Integration testing validates all fixes
- Phases 3, 4, 5, 6 are independent: Can be executed in parallel if desired

**Note**: Phase dependencies enable wave-based parallel execution:
- Wave 1: Phases 1, 3, 4, 5, 6 (independent, can run in parallel)
- Wave 2: Phase 2 (depends on Phase 1)
- Wave 3: Phase 7 (depends on all prior phases)

See [Concurrent Execution Safety Standard](.claude/docs/reference/standards/concurrent-execution-safety.md) for parallel execution patterns.

# Systematic Infrastructure Fix: Bash Library Sourcing Standards Enforcement

## Plan Metadata
- **Plan Type**: Infrastructure Improvement
- **Scope**: All .claude/commands/ with multi-layer enforcement system
- **Root Cause**: 60-70% compliance gap with library re-sourcing standards
- **Error Rate**: 57% in /build, systematic violations across 7 commands
- **Severity**: CRITICAL - Affects all workflow commands
- **Research Reports**:
  - [Root Cause Analysis](../reports/001_root_cause_analysis.md)
  - [Systematic Bash Sourcing Analysis](../reports/002_bash_sourcing_systematic_analysis.md)

## Problem Statement

Research reveals the /build errors are symptoms of a systemic infrastructure problem: documented bash sourcing standards exist but lack enforcement mechanisms. Analysis shows:

**Compliance Gap**:
- 60-70% of command blocks properly re-source libraries
- 86+ instances of bare `2>/dev/null` without fail-fast handlers
- High-complexity commands (debug.md: 29 sourcing statements, build.md: 22) most affected
- Inconsistent patterns even within same command file

**Root Cause** (from research):
1. **Primary**: No automated enforcement of documented standards
2. **Secondary**: Subprocess isolation violations (libraries not re-sourced per block)
3. **Tertiary**: library-sourcing.sh utility missing critical libraries (workflow-state-machine.sh, state-persistence.sh)

**Specific /build Failure** (Lines 377-380, Block 2):
- Missing workflow-state-machine.sh sourcing
- Bare error suppression without fail-fast
- Function save_completed_states_to_state called at line 543 without availability check
- Results in 57% error rate (4 of 7 errors)

## Success Criteria

### Immediate (Phase 1)
- [ ] /build command completes without exit code 127 errors
- [ ] State persistence succeeds in all /build workflow phases
- [ ] Error messages visible when state operations fail

### Systematic (Phases 2-4)
- [ ] All commands conform to three-tier sourcing pattern
- [ ] Zero bare error suppression on critical libraries
- [ ] 100% compliance with fail-fast pattern
- [ ] Defensive checks before all critical function calls

### Preventive (Phases 5-6)
- [ ] Automated linter detects sourcing violations
- [ ] Pre-commit hooks prevent new violations
- [ ] Documentation updated with anti-patterns
- [ ] Template infrastructure supports copy-paste compliance

## Research Summary

Based on systematic analysis (002_bash_sourcing_systematic_analysis.md):

**Standards Documentation**: Excellent
- bash-block-execution-model.md is comprehensive (1194 lines)
- Subprocess isolation well-documented with validated patterns
- Templates exist (_template-bash-block.md) with correct patterns

**Implementation Reality**: Inconsistent
- 60-70% compliance with re-sourcing standards
- 40% bare error suppression (violates output-formatting.md)
- 86+ instances across 7 commands need remediation
- build.md Block 2 missing workflow-state-machine.sh (immediate failure cause)

**Enforcement Mechanisms**: Missing
- No automated validation
- No pre-commit checks
- Code review blind to runtime subprocess isolation issues
- Template adoption not enforced for existing commands

**Recommended Approach**: Multi-layer enforcement
1. Fix immediate /build failure (Phase 1)
2. Standardize sourcing pattern (three-tier bootstrap → state → libraries)
3. Create automated linting for violations
4. Implement pre-commit hooks
5. Add defensive validation in libraries
6. Update documentation with troubleshooting

## Implementation Phases

### Phase 1: Fix Immediate /build Failures [COMPLETE]
dependencies: []

**Objective**: Eliminate 57% error rate by fixing Block 2 sourcing violations
**Complexity**: Low
**Estimated Effort**: 1.5 hours

#### Tasks:

- [x] **Task 1.1: Add Missing Library to Block 2**
  - File: `.claude/commands/build.md`
  - Location: Lines 377-380 (before save_completed_states_to_state calls at line 543)
  - Change: Add workflow-state-machine.sh with fail-fast pattern
  ```bash
  # Current (VIOLATION - missing workflow-state-machine.sh)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null

  # Fixed (THREE-TIER PATTERN)
  # Tier 1: Critical Foundation (fail-fast required)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
    echo "ERROR: Failed to source state-persistence.sh" >&2
    exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-state-machine.sh" >&2
    exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to source error-handling.sh" >&2
    exit 1
  }

  # Tier 3: Command-Specific (graceful degradation)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
  ```
  - Rationale: Makes save_completed_states_to_state() available, follows three-tier pattern
  - Verification: `type save_completed_states_to_state` after sourcing

- [x] **Task 1.2: Apply Same Pattern to Test Phase Block**
  - File: `.claude/commands/build.md`
  - Location: After line ~850 (test phase block start)
  - Change: Same three-tier sourcing pattern
  - Fixes: Line 956 save_completed_states_to_state call

- [x] **Task 1.3: Apply Same Pattern to Documentation Phase Block**
  - File: `.claude/commands/build.md`
  - Location: After line ~1050 (documentation phase block start)
  - Change: Same three-tier sourcing pattern
  - Fixes: Line 1170 save_completed_states_to_state call

- [x] **Task 1.4: Remove Error Suppression from State Function Calls**
  - File: `.claude/commands/build.md`
  - Locations: Lines 543, 956, 1170
  - Change: Remove `2>&1` redirection, preserve stderr visibility
  ```bash
  # Current (ANTI-PATTERN - hides errors)
  save_completed_states_to_state 2>&1
  SAVE_EXIT=$?

  # Fixed (allows error messages to stderr)
  save_completed_states_to_state
  SAVE_EXIT=$?
  ```
  - Standards: Output Formatting Standards - Error suppression anti-pattern (lines 56-95)

- [x] **Task 1.5: Add Defensive Checks Before Critical Calls**
  - File: `.claude/commands/build.md`
  - Locations: Before lines 543, 956, 1170
  - Add function availability check:
  ```bash
  if ! type save_completed_states_to_state &>/dev/null; then
    echo "ERROR: save_completed_states_to_state function not found" >&2
    echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced" >&2
    exit 1
  fi
  ```
  - Rationale: Fail-fast at point of issue with clear diagnostic

**Testing**:
```bash
# Test original failing scenario
/build .claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md

# Verify no exit code 127 errors
/errors --command /build --since 10m

# Verify state persistence
ls -lt .claude/tmp/workflow_build_*.sh | head -1 | xargs grep COMPLETED_STATES
```

**Expected Outcome**: /build error rate 57% → <5%

### Phase 2: Create Three-Tier Sourcing Standard [COMPLETE]
dependencies: [1]

**Objective**: Establish standardized sourcing pattern for all commands
**Complexity**: Medium
**Estimated Effort**: 2 hours

#### Tasks:

- [x] **Task 2.1: Create Sourcing Pattern Library**
  - File: `.claude/lib/core/source-libraries-inline.sh` (new)
  - Purpose: Centralized three-tier sourcing without BASH_SOURCE dependency
  - Implementation (from research Part 7.5, Option B):
  ```bash
  #!/usr/bin/env bash
  # Three-tier library sourcing for Claude Code context

  source_critical_libraries() {
    # Detect project directory (git-based or directory walk)
    if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    else
      current_dir="$(pwd)"
      while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.claude" ]; then
          CLAUDE_PROJECT_DIR="$current_dir"
          break
        fi
        current_dir="$(dirname "$current_dir")"
      done
    fi

    export CLAUDE_PROJECT_DIR
    export CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

    # Tier 1: Critical Foundation (fail-fast)
    source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || {
      echo "ERROR: Failed to source state-persistence.sh" >&2
      return 1
    }
    source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
      echo "ERROR: Failed to source workflow-state-machine.sh" >&2
      return 1
    }
    source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
      echo "ERROR: Failed to source error-handling.sh" >&2
      return 1
    }

    # Verify critical functions available
    if ! type append_workflow_state &>/dev/null; then
      echo "ERROR: State persistence functions not available" >&2
      return 1
    fi

    return 0
  }

  source_workflow_libraries() {
    # Tier 2: Workflow Support (graceful degradation)
    source "${CLAUDE_LIB}/workflow/workflow-initialization.sh" 2>/dev/null || true
    source "${CLAUDE_LIB}/workflow/checkpoint-utils.sh" 2>/dev/null || true
    source "${CLAUDE_LIB}/core/unified-location-detection.sh" 2>/dev/null || true
    source "${CLAUDE_LIB}/core/unified-logger.sh" 2>/dev/null || true
  }
  ```
  - Rationale: Works in Claude Code context, provides fail-fast for critical libraries

- [x] **Task 2.2: Update _template-bash-block.md**
  - File: `.claude/docs/guides/templates/_template-bash-block.md`
  - Change: Replace inline sourcing with three-tier pattern utility
  ```bash
  # Block 1: Bootstrap
  CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  export CLAUDE_PROJECT_DIR

  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" || exit 1
  source_critical_libraries || exit 1
  source_workflow_libraries

  # Block 2+: Re-source
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" || exit 1
  source_critical_libraries || exit 1
  source_workflow_libraries

  # Load state (AFTER libraries)
  load_workflow_state "$WORKFLOW_ID"
  ```

- [x] **Task 2.3: Document Three-Tier Pattern**
  - File: `.claude/docs/reference/standards/code-standards.md`
  - Section: Add "Three-Tier Library Sourcing Pattern" after line 66
  - Content: Document Tier 1 (fail-fast), Tier 2 (graceful), Tier 3 (command-specific)
  - Link: Reference bash-block-execution-model.md

**Deliverables**:
- Centralized sourcing utility
- Updated template with three-tier pattern
- Documentation of sourcing tiers

**Testing**:
```bash
# Test utility in isolation
source .claude/lib/core/source-libraries-inline.sh
source_critical_libraries
echo $?  # Should be 0

# Verify functions available
type append_workflow_state save_completed_states_to_state
```

### Phase 3: Create Automated Linter [COMPLETE]
dependencies: [2]

**Objective**: Detect sourcing violations automatically
**Complexity**: Medium
**Estimated Effort**: 3 hours

#### Tasks:

- [x] **Task 3.1: Implement Library Sourcing Linter**
  - File: `.claude/scripts/lint/check-library-sourcing.sh` (new)
  - Checks to implement (from research Part 4.4):
    1. Library re-sourcing check (function calls without library in same block)
    2. Bare error suppression check (`2>/dev/null` without fail-fast)
    3. Sourcing order check (state-persistence before workflow-initialization)
    4. Function availability check (defensive `type` checks before critical calls)
  - Implementation:
  ```bash
  #!/usr/bin/env bash
  # Linter: Check bash library sourcing patterns

  REQUIRED_FUNCTIONS=(
    "save_completed_states_to_state:workflow/workflow-state-machine.sh"
    "append_workflow_state:workflow/workflow-state-machine.sh"
    "log_command_error:core/error-handling.sh"
    "ensure_error_log_exists:core/error-handling.sh"
  )

  CRITICAL_LIBRARIES=(
    "state-persistence.sh"
    "workflow-state-machine.sh"
    "error-handling.sh"
  )

  check_bare_suppression() {
    local file=$1
    # Find: source.*2>/dev/null$ (no fail-fast)
    # Exclude: source.*2>/dev/null || { ... }
    grep -n "source.*2>/dev/null\s*$" "$file" | \
    while IFS=: read -r line_num line_content; do
      # Check if library is critical
      for lib in "${CRITICAL_LIBRARIES[@]}"; do
        if echo "$line_content" | grep -q "$lib"; then
          echo "ERROR: $file:$line_num"
          echo "  Bare error suppression on critical library: $lib"
          echo "  Fix: Add fail-fast handler"
        fi
      done
    done
  }

  check_function_availability() {
    local file=$1
    # Find function calls, check if defensive check exists
    for func_lib in "${REQUIRED_FUNCTIONS[@]}"; do
      IFS=: read -r func lib <<< "$func_lib"
      grep -n "$func" "$file" | \
      while IFS=: read -r line_num _; do
        # Check 10 lines before for defensive check
        start=$((line_num - 10))
        [ $start -lt 1 ] && start=1
        if ! sed -n "${start},${line_num}p" "$file" | grep -q "type $func"; then
          echo "WARNING: $file:$line_num"
          echo "  Missing defensive check before $func"
          echo "  Fix: Add 'if ! type $func &>/dev/null; then exit 1; fi'"
        fi
      done
    done
  }

  # Main execution
  ERROR_COUNT=0
  WARNING_COUNT=0

  for cmd_file in .claude/commands/*.md; do
    echo "Checking $cmd_file..."
    check_bare_suppression "$cmd_file"
    check_function_availability "$cmd_file"
  done

  echo ""
  echo "SUMMARY: $ERROR_COUNT errors, $WARNING_COUNT warnings"
  [ $ERROR_COUNT -eq 0 ]
  ```

- [x] **Task 3.2: Add Linter to CI/Validation**
  - File: `.claude/scripts/validate-all.sh` (existing)
  - Add: Call check-library-sourcing.sh before test execution
  - Exit on linter errors

- [x] **Task 3.3: Document Linter Usage**
  - File: `.claude/docs/guides/development/linting-bash-sourcing.md` (new)
  - Content: How to run linter, interpret output, fix violations
  - Examples: Common violations and fixes

**Testing**:
```bash
# Test linter on current codebase (expect violations)
bash .claude/scripts/lint/check-library-sourcing.sh

# Verify detection of known violations
# Should find: 86+ bare suppression instances
# Should find: Missing defensive checks in build.md
```

### Phase 4: Remediate All Commands [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Apply three-tier pattern to all workflow commands
**Complexity**: High
**Estimated Effort**: 4 hours

#### Tasks:

- [x] **Task 4.1: Remediate /plan Command**
  - File: `.claude/commands/plan.md`
  - Violations: 16 sourcing statements, bare suppression patterns
  - Apply: Three-tier sourcing pattern to all bash blocks
  - Test: `/plan "test feature" --complexity 2`

- [x] **Task 4.2: Remediate /debug Command**
  - File: `.claude/commands/debug.md`
  - Violations: 29 sourcing statements (highest complexity), 25 bare suppressions
  - Apply: Three-tier pattern, defensive checks before critical calls
  - Test: `/debug "test issue" --complexity 2`

- [x] **Task 4.3: Remediate /research Command**
  - File: `.claude/commands/research.md`
  - Violations: 11 sourcing statements, 9 bare suppressions
  - Apply: Three-tier pattern
  - Test: `/research "test topic" --complexity 2`

- [x] **Task 4.4: Remediate /repair Command**
  - File: `.claude/commands/repair.md`
  - Violations: 12 sourcing statements, 10 bare suppressions
  - Apply: Three-tier pattern
  - Test: `/repair --since 1h --complexity 2`

- [x] **Task 4.5: Remediate /revise Command**
  - File: `.claude/commands/revise.md`
  - Violations: 16 sourcing statements, 7 bare suppressions
  - Apply: Three-tier pattern
  - Test: `/revise existing-plan.md "test revision"`

- [x] **Task 4.6: Verify All Commands Pass Linter**
  - Run: `bash .claude/scripts/lint/check-library-sourcing.sh`
  - Expected: 0 errors, 0 warnings
  - Document: Any remaining acceptable warnings with rationale

**Testing Strategy** (per command):
```bash
# 1. Run linter before remediation (document baseline)
# 2. Apply three-tier pattern
# 3. Run linter after remediation (verify 0 errors)
# 4. Test command with real workflow
# 5. Check error logs for subprocess isolation issues
/errors --command /COMMAND --since 10m --type dependency_error
```

**Deliverables**:
- All 7 commands conform to three-tier pattern
- Zero bare error suppression on critical libraries
- 100% linter compliance
- Comprehensive test coverage

### Phase 5: Implement Pre-Commit Enforcement [COMPLETE]
dependencies: [3, 4]

**Objective**: Prevent new violations from entering codebase
**Complexity**: Low
**Estimated Effort**: 1.5 hours

#### Tasks:

- [x] **Task 5.1: Create Pre-Commit Hook**
  - File: `.git/hooks/pre-commit` (or .husky/pre-commit)
  - Implementation (from research Part 4.5):
  ```bash
  #!/usr/bin/env bash
  # Pre-commit hook: Validate library sourcing patterns

  echo "Running library sourcing linter..."

  # Run linter on staged command files
  STAGED_COMMANDS=$(git diff --cached --name-only --diff-filter=ACM | grep '^.claude/commands/.*\.md$')

  if [ -n "$STAGED_COMMANDS" ]; then
    LINTER_OUTPUT=$(bash .claude/scripts/lint/check-library-sourcing.sh $STAGED_COMMANDS 2>&1)
    LINTER_EXIT=$?

    if [ $LINTER_EXIT -ne 0 ]; then
      echo "$LINTER_OUTPUT"
      echo ""
      echo "ERROR: Library sourcing violations detected"
      echo "Fix violations before committing, or use --no-verify to bypass"
      exit 1
    fi

    echo "✓ Library sourcing checks passed"
  fi
  ```

- [x] **Task 5.2: Document Pre-Commit Hook Usage**
  - File: `.claude/docs/guides/development/pre-commit-hooks.md` (update existing or create)
  - Content: Installation, bypass procedure, troubleshooting
  - Link: From CLAUDE.md development workflow section

- [x] **Task 5.3: Add Hook Installation to /setup**
  - File: `.claude/commands/setup.md`
  - Add: Automatic pre-commit hook installation during setup
  - Check: If .git/hooks/pre-commit exists, merge or warn

**Testing**:
```bash
# Test hook blocks violations
# 1. Introduce bare suppression violation in build.md
# 2. Stage and attempt commit
# 3. Verify hook blocks commit with clear error

# Test hook allows compliant commits
# 1. Fix violation
# 2. Stage and commit
# 3. Verify hook allows commit
```

### Phase 6: Update Documentation and Standards [COMPLETE]
dependencies: [4]

**Objective**: Prevent future violations through improved documentation
**Complexity**: Medium
**Estimated Effort**: 2.5 hours

#### Tasks:

- [x] **Task 6.1: Create Exit Code 127 Troubleshooting Guide**
  - File: `.claude/docs/troubleshooting/exit-code-127-command-not-found.md` (new)
  - Content: Diagnostic flowchart for "command not found" errors
    1. Check if function defined in library
    2. Check if library sourced in current bash block (subprocess isolation)
    3. Check if CLAUDE_PROJECT_DIR set
    4. Check if library file exists at path
    5. Check for defensive availability check
  - Examples: Real violations from build.md, debug.md

- [x] **Task 6.2: Update Bash Block Execution Model with Anti-Patterns**
  - File: `.claude/docs/concepts/bash-block-execution-model.md`
  - Section: Add "Anti-Pattern: Missing Library Re-Sourcing" after line 973
  - Content (from research Part 5.3):
  ```markdown
  ### Anti-Pattern: Missing Library Re-Sourcing

  **Problem**: Calling library function without re-sourcing in current block

  **Example** (from build.md Block 2 violation):
  ```bash
  # Block 1
  source workflow-state-machine.sh
  save_completed_states_to_state  # ✓ Works

  # Block 2 (NEW SUBPROCESS)
  # Library NOT re-sourced
  save_completed_states_to_state  # ✗ Exit code 127: command not found
  ```

  **Fix**: Re-source library in Block 2
  ```bash
  # Block 2 (NEW SUBPROCESS)
  source workflow-state-machine.sh  # ← Add this
  save_completed_states_to_state    # ✓ Now works
  ```

  **Detection**: "bash: save_completed_states_to_state: command not found"
  **Linter**: check-library-sourcing.sh detects this pattern
  ```

- [x] **Task 6.3: Update Output Formatting Standards**
  - File: `.claude/docs/reference/standards/output-formatting.md`
  - Section: Add "Bare Error Suppression Statistics" after line 95
  - Content: Reference research findings (86+ instances remediated)
  - Add: Link to linter for automated detection

- [x] **Task 6.4: Update /build Command Guide**
  - File: `.claude/docs/guides/commands/build-command-guide.md`
  - Section: Add "Subprocess Isolation Architecture"
  - Content: Explain three-tier sourcing pattern, why libraries re-sourced per block
  - Diagram: Show state flow across bash blocks

- [x] **Task 6.5: Create Migration Guide for Existing Commands**
  - File: `.claude/docs/guides/development/migrating-to-three-tier-sourcing.md` (new)
  - Content: Step-by-step process for updating old commands
    1. Audit current sourcing patterns
    2. Identify critical vs optional libraries
    3. Replace inline sourcing with source_critical_libraries()
    4. Add defensive checks before critical calls
    5. Test with linter
    6. Verify with real workflow

**Deliverables**:
- Troubleshooting guide for exit code 127
- Anti-patterns documented in bash-block-execution-model.md
- Updated standards with enforcement references
- Migration guide for future updates

## Dependencies

### Phase Dependencies
- Phase 1: Independent (immediate fix)
- Phase 2: Depends on Phase 1 (validated pattern from /build fix)
- Phase 3: Depends on Phase 2 (linter checks for three-tier pattern)
- Phase 4: Depends on Phases 1-3 (apply proven pattern with linter validation)
- Phase 5: Depends on Phases 3-4 (hook runs linter on compliant codebase)
- Phase 6: Depends on Phase 4 (document implemented patterns)

### Parallel Execution
- Phase 5 can run parallel with Phase 6 (independent activities)
- Phase 2 and Phase 3 can overlap (template + linter development)

### External Dependencies
- No external dependencies
- All changes internal to .claude/ infrastructure

## Testing Strategy

### Unit Tests
```bash
# Test: Three-tier sourcing utility
test_source_critical_libraries() {
  source .claude/lib/core/source-libraries-inline.sh
  source_critical_libraries
  [[ $? -eq 0 ]]

  # Verify functions available
  type append_workflow_state
  type save_completed_states_to_state
  type log_command_error
}

# Test: Linter detects violations
test_linter_detection() {
  # Create test file with violation
  echo 'source lib.sh 2>/dev/null' > test.md

  bash .claude/scripts/lint/check-library-sourcing.sh test.md
  [[ $? -ne 0 ]]  # Should fail

  rm test.md
}
```

### Integration Tests
```bash
# Test: All commands complete without subprocess isolation errors
test_all_commands_state_management() {
  /plan "test" --complexity 1
  /debug "test" --complexity 1
  /research "test" --complexity 1
  /repair --since 1h --complexity 1
  /build test-plan.md

  # Verify no dependency_error or state_error in logs
  /errors --since 30m --type dependency_error | grep -q "error"
  [[ $? -ne 0 ]]  # Should NOT find errors
}

# Test: Linter passes on all commands
test_linter_full_compliance() {
  bash .claude/scripts/lint/check-library-sourcing.sh
  [[ $? -eq 0 ]]
}
```

### Regression Tests
```bash
# Test: Original /build failures resolved
test_build_regression() {
  /build .claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md
  [[ $? -eq 0 ]]

  /build .claude/specs/886_errors_command_report/plans/001_errors_command_report_plan.md
  [[ $? -eq 0 ]]
}

# Test: No exit code 127 errors across all commands
test_no_command_not_found() {
  # Run multiple workflows
  /plan "test1" --complexity 2
  /build test1-plan.md
  /debug "test2" --complexity 2

  # Check error logs
  /errors --since 1h --query | \
  jq -r '.[] | select(.context.exit_code == 127)' | wc -l | \
  grep -q '^0$'
}
```

## Success Metrics

### Quantitative Metrics
- [ ] /build error rate: 57% → <5%
- [ ] Bare error suppression instances: 86 → 0
- [ ] Commands passing linter: 0/7 → 7/7
- [ ] Exit code 127 errors (24 hour window): Current → 0
- [ ] State persistence success rate: 100%

### Qualitative Metrics
- [ ] Error messages are actionable and diagnostic
- [ ] Code conforms to documented three-tier pattern
- [ ] Developers understand subprocess isolation model
- [ ] Linter prevents new violations (pre-commit enforcement)
- [ ] Documentation includes troubleshooting for common issues

### Performance Metrics
- [ ] Library sourcing overhead: <10ms per block (negligible)
- [ ] Linter execution time: <5s for all commands
- [ ] Pre-commit hook adds: <3s to commit process

## Timeline

### Week 1
- **Phase 1**: Days 1-2 (1.5 hours) - Fix immediate /build failures
- **Phase 2**: Days 2-3 (2 hours) - Create three-tier sourcing standard
- **Phase 3**: Days 3-4 (3 hours) - Create automated linter

### Week 2
- **Phase 4**: Days 5-8 (4 hours) - Remediate all commands systematically
- **Phase 5**: Day 9 (1.5 hours) - Implement pre-commit enforcement
- **Phase 6**: Days 9-10 (2.5 hours) - Update documentation

**Total Estimated Effort**: 14.5 hours over 10 days

**Critical Path**: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
**Parallel Work**: Phase 5 || Phase 6 (save 1 day)

## Risk Assessment

### High Risk
- **Phase 4**: Changes to 7 commands could introduce new failures
  - **Mitigation**: Test each command individually before moving to next
  - **Mitigation**: Use linter to verify compliance before testing
  - **Rollback**: Git revert per-file with granular commits

### Medium Risk
- **Phase 3**: Linter false positives could block valid patterns
  - **Mitigation**: Test linter on known-good and known-bad patterns
  - **Mitigation**: Allow warnings (non-blocking) vs errors (blocking)

### Low Risk
- **Phase 1**: Library re-sourcing performance impact
  - **Expected**: <10ms overhead (negligible for workflow commands)
  - **Measurement**: Time execution before/after with `time` command
- **Phase 5-6**: Documentation and tooling don't affect runtime

## Rollback Plan

### If Phase 1 Breaks /build
1. Revert `.claude/commands/build.md` to backup
2. Analyze new errors via `/errors --command /build --since 10m`
3. Adjust sourcing pattern based on findings
4. Retry with corrected pattern

### If Phase 4 Breaks Multiple Commands
1. Identify which command introduced failure
2. Revert affected command file to pre-remediation commit
3. Test other commands to verify isolation
4. Apply more targeted fix to failed command
5. Re-run linter to verify fix

### If Linter Has False Positives
1. Document false positive pattern
2. Update linter exclusion rules
3. Re-run validation
4. Add test case for false positive pattern

## Related Documentation

### Research Reports
- Root Cause Analysis: `.claude/specs/105_build_state_management_bash_errors_fix/reports/001_root_cause_analysis.md`
- Systematic Bash Sourcing Analysis: `.claude/specs/105_build_state_management_bash_errors_fix/reports/002_bash_sourcing_systematic_analysis.md`

### Standards and Patterns
- Bash Block Execution Model: `.claude/docs/concepts/bash-block-execution-model.md`
- Output Formatting Standards: `.claude/docs/reference/standards/output-formatting.md`
- Code Standards: `.claude/docs/reference/standards/code-standards.md`
- Bash Block Template: `.claude/docs/guides/templates/_template-bash-block.md`

### Original Error Reports
- Build Error Analysis: `.claude/specs/20251120_build_error_analysis/reports/001_error_report.md`

## Appendix: Research Findings Summary

### Compliance Gap Analysis
From research report 002_bash_sourcing_systematic_analysis.md:

**Command Sourcing Patterns** (Table from Part 2.2):
| Command | Sourcing Statements | Bash Blocks | Ratio | Bare Suppressions |
|---------|--------------------:|------------:|------:|------------------:|
| debug.md | 29 | ~7 | 4.1 | 25 |
| build.md | 22 | ~7 | 3.1 | 20 |
| revise.md | 16 | ~5 | 3.2 | 7 |
| plan.md | 16 | ~5 | 3.2 | 13 |
| repair.md | 12 | ~4 | 3.0 | 10 |
| research.md | 11 | ~3 | 3.7 | 9 |
| optimize-claude.md | 4 | ~2 | 2.0 | 2 |

**Total**: 86+ instances of bare error suppression across 7 commands

### Three-Tier Sourcing Pattern
From research report Part 4.2:

**Tier 1: Critical Foundation** (fail-fast required)
- state-persistence.sh
- workflow-state-machine.sh
- error-handling.sh

**Tier 2: Workflow Support** (graceful degradation)
- workflow-initialization.sh
- checkpoint-utils.sh
- unified-location-detection.sh
- unified-logger.sh

**Tier 3: Command-Specific** (optional)
- plan/checkbox-utils.sh
- core/summary-formatting.sh
- etc.

### Linter Requirements
From research report Part 4.4:

**Detection Capabilities**:
1. Bare error suppression on critical libraries
2. Function calls without library re-sourcing
3. Sourcing order violations
4. Missing defensive function availability checks

**Output Format**: ERROR (blocking) vs WARNING (informational)

---

### Phase 7: Update Standards Documentation for Enforcement [COMPLETE]
dependencies: [4, 6]

**Objective**: Update .claude/docs/ standards to enforce uniform sourcing approach, preventing future issues
**Complexity**: Medium
**Estimated Effort**: 2 hours

**Prerequisite**: Phase 4 (remediation) must be tested and verified successful before updating standards

#### Tasks:

- [x] **Task 7.1: Update Code Standards with Mandatory Sourcing Rules**
  - File: `.claude/docs/reference/standards/code-standards.md`
  - Section: Add new section "Mandatory Bash Block Sourcing Pattern"
  - Content:
  ```markdown
  ## Mandatory Bash Block Sourcing Pattern

  All bash blocks in `.claude/commands/` MUST follow the three-tier sourcing pattern.
  This is NOT optional - violations will be caught by pre-commit hooks.

  ### Required Pattern (Every Bash Block)

  ```bash
  # 1. Bootstrap: Detect project directory
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
      current_dir="$(dirname "$current_dir")"
    done
  fi
  export CLAUDE_PROJECT_DIR

  # 2. Source Critical Libraries (Tier 1 - FAIL-FAST REQUIRED)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
    echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-state-machine.sh" >&2; exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to source error-handling.sh" >&2; exit 1
  }

  # 3. Optional Libraries (Tier 2/3 - graceful degradation allowed)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || true
  ```

  ### Enforcement

  - **Linter**: `.claude/scripts/lint/check-library-sourcing.sh` validates all commands
  - **Pre-commit**: Violations block commits (use `--no-verify` only with documented justification)
  - **CI**: Linter runs in validation pipeline before tests

  ### Why This Pattern is Mandatory

  Each bash block in Claude Code runs in a **new subprocess**. Variables and functions
  from previous blocks are NOT available. This is documented in:
  - `.claude/docs/concepts/bash-block-execution-model.md` (Section 3: Subprocess Isolation)

  Without re-sourcing libraries, function calls fail with exit code 127 ("command not found").
  ```
  - Link from: CLAUDE.md error_logging section

- [x] **Task 7.2: Update Output Formatting Standards with Suppression Policy**
  - File: `.claude/docs/reference/standards/output-formatting.md`
  - Section: Update "Output Suppression Patterns" to include enforcement
  - Add after existing suppression guidance:
  ```markdown
  ### MANDATORY: Error Suppression on Critical Libraries

  The following libraries MUST use fail-fast pattern (bare `2>/dev/null` is PROHIBITED):
  - `state-persistence.sh`
  - `workflow-state-machine.sh`
  - `error-handling.sh`
  - `library-version-check.sh`

  **Prohibited** (will fail linter):
  ```bash
  source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null
  ```

  **Required** (linter-compliant):
  ```bash
  source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-state-machine.sh" >&2
    exit 1
  }
  ```

  **Rationale**: Bare suppression hides critical failures, causing exit code 127 errors
  much later in execution with no diagnostic information.
  ```

- [x] **Task 7.3: Update Bash Block Execution Model with Mandatory Section**
  - File: `.claude/docs/concepts/bash-block-execution-model.md`
  - Add: New section "Mandatory Re-Sourcing Requirements" after subprocess isolation section
  - Content:
  ```markdown
  ## Mandatory Re-Sourcing Requirements

  **REQUIREMENT**: Every bash block MUST re-source all required libraries.

  This requirement is enforced by:
  1. **Linter**: `check-library-sourcing.sh` detects violations
  2. **Pre-commit hooks**: Block commits with violations
  3. **Code review**: Automated comments on PRs with violations

  ### Function Availability Check

  Before calling any library function, add a defensive check:
  ```bash
  if ! type save_completed_states_to_state &>/dev/null; then
    echo "ERROR: save_completed_states_to_state not found" >&2
    echo "DIAGNOSTIC: workflow-state-machine.sh not sourced in this block" >&2
    exit 1
  fi
  ```

  This check should appear within 10 lines before any critical function call.
  ```

- [x] **Task 7.4: Add Sourcing Pattern to CLAUDE.md Index**
  - File: `CLAUDE.md`
  - Section: Update `code_standards` section to reference mandatory sourcing
  - Add bullet point:
  ```markdown
  - **Bash Sourcing**: All bash blocks must follow three-tier sourcing pattern (enforced by linter and pre-commit hooks). See [Code Standards - Mandatory Bash Block Sourcing Pattern](.claude/docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern).
  ```

- [x] **Task 7.5: Create Standards Compliance Checklist**
  - File: `.claude/docs/reference/checklists/bash-command-compliance.md` (new)
  - Content: Checklist for command authors to verify compliance before commit
  ```markdown
  # Bash Command Compliance Checklist

  Use this checklist before submitting any new or modified command in `.claude/commands/`.

  ## Pre-Submission Verification

  - [x] Every bash block has project directory detection (git or directory walk)
  - [x] Every bash block sources Tier 1 libraries with fail-fast handlers
  - [x] No bare `2>/dev/null` on critical libraries (state-persistence, workflow-state-machine, error-handling)
  - [x] Defensive `type` checks before critical function calls
  - [x] Linter passes: `bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/YOUR_COMMAND.md`
  - [x] Manual test: Run command through at least one complete workflow

  ## Common Violations

  | Violation | Detection | Fix |
  |-----------|-----------|-----|
  | Missing library re-source | Exit 127 on function call | Add source statement in block |
  | Bare error suppression | Linter ERROR | Add `|| { echo "ERROR"; exit 1; }` |
  | Missing defensive check | Linter WARNING | Add `type FUNC &>/dev/null` check |
  | Wrong sourcing order | State errors | Source state-persistence before workflow-state-machine |

  ## Automated Enforcement

  Pre-commit hook validates these requirements automatically. Bypass with `git commit --no-verify`
  only if you have documented justification in commit message.
  ```

- [x] **Task 7.6: Verify Standards Documentation Complete**
  - Run: Audit all referenced documentation files exist
  - Check: Cross-references between documents are valid
  - Verify: Examples in documentation match implemented patterns
  - Test: New command author can follow documentation to create compliant command

**Testing**:
```bash
# Verify standards documentation is consistent
grep -r "three-tier" .claude/docs/ | wc -l  # Should find multiple references

# Verify CLAUDE.md references updated
grep -q "mandatory-bash-block-sourcing" CLAUDE.md

# Verify checklist is actionable
# Manual test: Follow checklist for a command, verify all steps work

# Integration test: Create new command following documentation
# Verify it passes linter without referencing implementation
```

**Deliverables**:
- Code standards updated with mandatory sourcing pattern
- Output formatting standards updated with suppression policy
- Bash block execution model updated with mandatory section
- CLAUDE.md index references enforcement
- Compliance checklist for command authors

**Success Criteria**:
- [x] New command authors can create compliant commands using only documentation
- [x] All enforcement mechanisms documented and cross-referenced
- [x] No undocumented enforcement requirements
- [x] Pattern deviations require documented justification

---

## Updated Dependencies

### Phase Dependencies (Updated)
- Phase 1: Independent (immediate fix)
- Phase 2: Depends on Phase 1 (validated pattern from /build fix)
- Phase 3: Depends on Phase 2 (linter checks for three-tier pattern)
- Phase 4: Depends on Phases 1-3 (apply proven pattern with linter validation)
- Phase 5: Depends on Phases 3-4 (hook runs linter on compliant codebase)
- Phase 6: Depends on Phase 4 (document implemented patterns)
- **Phase 7**: Depends on Phases 4, 6 (enforce patterns after implementation verified)

### Parallel Execution (Updated)
- Phase 5 can run parallel with Phase 6 (independent activities)
- Phase 7 runs AFTER Phase 4 testing completes (enforcement requires verified implementation)

---

## Updated Timeline

### Week 1
- **Phase 1**: Days 1-2 (1.5 hours) - Fix immediate /build failures
- **Phase 2**: Days 2-3 (2 hours) - Create three-tier sourcing standard
- **Phase 3**: Days 3-4 (3 hours) - Create automated linter

### Week 2
- **Phase 4**: Days 5-8 (4 hours) - Remediate all commands systematically
- **Phase 5**: Day 9 (1.5 hours) - Implement pre-commit enforcement
- **Phase 6**: Days 9-10 (2.5 hours) - Update documentation
- **Phase 7**: Day 10 (2 hours) - Update standards documentation for enforcement

**Total Estimated Effort**: 16.5 hours over 10 days (increased from 14.5 hours)

**Critical Path**: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 7
**Parallel Work**: Phase 5 || Phase 6 || Phase 7 (after Phase 4 testing)

---

**Plan Created**: 2025-11-21
**Plan Revised**: 2025-11-21 (systematic infrastructure approach)
**Plan Revised**: 2025-11-21 (added Phase 7 for standards enforcement documentation)
**Plan Type**: Infrastructure Improvement (multi-layer enforcement)
**Implementation Method**: Sequential phases with wave-based parallel execution
**Expected Outcome**: Zero subprocess isolation errors, systematic prevention of future violations, enforced standards documentation

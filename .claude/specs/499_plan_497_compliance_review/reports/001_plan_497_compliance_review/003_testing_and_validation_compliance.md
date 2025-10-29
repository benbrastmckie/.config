# Testing and Validation Compliance Analysis - Plan 497

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Testing and Validation Compliance
- **Report Type**: compliance analysis
- **Overview Report**: [./OVERVIEW.md](./OVERVIEW.md)
- **Plan**: [../../../497_unified_plan_coordinate_supervise_improvements/plans/001_unified_implementation_plan.md](../../../497_unified_plan_coordinate_supervise_improvements/plans/001_unified_implementation_plan.md)
- **Standards Reference**: CLAUDE.md Testing Protocols section, .claude/tests/ infrastructure

## Executive Summary

Plan 497 demonstrates **STRONG COMPLIANCE** (85/100) with testing protocols but has **CRITICAL GAPS** in mandatory verification checkpoint implementation. The plan creates comprehensive validation infrastructure (Phase 0) and extensive integration testing (Phase 4) with delegation rate analysis and regression tests. However, it fundamentally lacks the MANDATORY VERIFICATION checkpoint pattern required by the Verification and Fallback Pattern (Standard 0 in Command Architecture Standards). The plan validates agent invocation patterns but does not enforce file creation verification, creating a 0% file creation verification rate despite the project's 100% verification requirement.

## Findings

### 1. Test Infrastructure Compliance - STRONG (95/100)

**Phase 0 Test Infrastructure Creation**:

Plan creates comprehensive testing infrastructure meeting all project requirements:

1. **Validation Script** (`.claude/lib/validate-agent-invocation-pattern.sh`):
   - Lines 247-252: Complete anti-pattern detection specification
   - Detects YAML-style Task blocks in command files
   - Detects markdown code fences around Task invocations
   - Detects template variables in agent prompts
   - Reports violations with line numbers and context
   - Exit code 0 for pass, 1 for violations (standard bash convention)

2. **Unified Test Suite** (`.claude/tests/test_orchestration_commands.sh`):
   - Lines 253-257: Test helper function specification
   - Functions: `test_agent_invocation_pattern()`, `test_bootstrap_sequence()`, `test_delegation_rate()`
   - Shared test fixtures for orchestration commands
   - Integration with existing test infrastructure

3. **Backup Utility** (`.claude/lib/backup-command-file.sh`):
   - Lines 258-262: Backup automation with integrity verification
   - Timestamped backups before edits
   - Rollback function provided
   - All operations logged

4. **Integration with CI/CD**:
   - Lines 266-269: Integration with `.claude/tests/run_all_tests.sh`
   - Pre-commit hook support (optional)
   - Documented validation workflow

**Compliance Evidence**:
- Testing Protocols section requires test location `.claude/tests/` (COMPLIANT - line 184)
- Test runner `run_all_tests.sh` integration required (COMPLIANT - lines 266-269, 889)
- Test pattern `test_*.sh` required (COMPLIANT - line 253)
- Coverage target ≥80% for modified code (ADDRESSED - delegation rate analysis line 600)

**Strengths**:
- Creates reusable infrastructure shared across all phases
- Automated validation reduces human error
- Safe rollback capabilities via backup utility
- Follows project test naming conventions

### 2. Test Coverage Requirements - STRONG (90/100)

**Phase-by-Phase Test Coverage**:

1. **Phase 0 Testing** (lines 277-296):
   - Validation script tested on known anti-patterns
   - Backup utility creation and integrity verification tested
   - Test suite structure validation
   - Baseline metrics established before fixes

2. **Phase 1 Testing** (lines 360-373):
   - Validation check after each agent invocation transformation
   - Pattern consistency verified against /supervise reference
   - Template variables checked
   - YAML blocks removal confirmed
   - Quick functionality test with `--dry-run`
   - Visual diff check

3. **Phase 2 Testing** (lines 438-452):
   - Library sourcing error simulation
   - Function verification diagnostics testing
   - Directory creation validation (expect agent to create)
   - Error message clarity verification

4. **Phase 3 Testing** (lines 525-539):
   - Validation checks on all 3 agent invocations
   - Bash code block conversion verification
   - Pattern consistency checks
   - Quick functionality test

5. **Phase 4 Integration Testing** (lines 549-644):
   - **Comprehensive end-to-end workflows** (lines 561-595):
     - /coordinate: research-only, research-and-plan workflows
     - /research: hierarchical research with 2-4 subtopics
     - /supervise: all 4 workflow types
   - **Delegation Rate Analysis** (lines 596-602):
     - Target >90% for all commands
     - Before/after metrics comparison
   - **File Creation Verification** (lines 603-606):
     - Artifacts in correct locations
     - No TODO*.md output files
     - Topic-based directory structure
   - **Regression Testing** (lines 607-609):
     - /orchestrate compatibility
     - 4 /supervise workflow types
     - No breaking changes

**Test Command Documentation** (lines 813-838):
```bash
# Validation
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md

# Unit tests (run unified test suite)
./.claude/tests/test_orchestration_commands.sh

# Integration tests
/coordinate "research authentication patterns for REST APIs"
/coordinate "research authentication to create implementation plan"
/research "API authentication patterns and best practices"
/supervise "research async programming patterns"

# Delegation analysis
/analyze agents  # If available

# File verification
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/
ls -la .claude/TODO*.md  # Should fail (no such file)

# Full test suite
./.claude/tests/run_all_tests.sh
```

**Coverage Requirements (CLAUDE.md lines 91-95)**:
- ✅ Aim for >80% coverage on new code (delegation rate >90% target exceeds this)
- ✅ All public APIs must have tests (all 3 commands tested in Phase 4)
- ✅ Critical paths require integration tests (end-to-end workflows in Phase 4)
- ✅ Regression tests for all bug fixes (Phase 4 task 4.6)

**Strengths**:
- Multi-level testing: unit, integration, performance, regression (line 1049)
- Quantitative metrics: delegation rate 0% → >90% (lines 1130-1133)
- Test-after-each-phase strategy prevents accumulation of broken code
- Comprehensive workflow coverage (4 types for /supervise)

**Minor Gap**:
- No explicit coverage measurement tool integration (e.g., coverage percentage calculation)
- Delegation rate used as proxy for test coverage

### 3. Mandatory Verification Checkpoints - CRITICAL GAP (15/100)

**Verification and Fallback Pattern Requirements** (from `.claude/docs/concepts/patterns/verification-fallback.md`):

The project standard requires THREE components for all file creation operations:
1. **Path Pre-Calculation**: Calculate all file paths before execution
2. **MANDATORY VERIFICATION**: Verify file existence after each creation
3. **Fallback Mechanisms**: Create missing files if verification fails

**Plan 497 Implementation Analysis**:

**Path Pre-Calculation: PRESENT** (lines 213-217):
```markdown
**EXECUTE NOW**: USE the Bash tool to calculate paths:

```bash
topic_dir=$(create_topic_structure "research_topic_name")
report_path="$topic_dir/reports/001_subtopic_name.md"
echo "REPORT_PATH: $report_path"
```
```

**MANDATORY VERIFICATION: ABSENT**:
- 0 occurrences of "MANDATORY VERIFICATION" pattern in plan
- 0 occurrences of file existence checks after agent invocations
- 0 occurrences of fallback creation mechanisms
- 54 total occurrences of verification-related terms (grep count), but ALL are:
  - Validation script verification (pattern checking, not file creation)
  - Function verification (library function existence)
  - Test verification (test results validation)
  - General verification references

**Comparison to Standard**:

From `verification-fallback.md` (lines 61-106):
```markdown
**Step 2: MANDATORY VERIFICATION Checkpoints**

After each file creation, verify file exists:

## MANDATORY VERIFICATION - Report Creation

EXECUTE NOW (REQUIRED BEFORE NEXT STEP):

1. Verify report file exists:
   ls -la specs/027_authentication/reports/001_oauth_patterns.md

2. Expected output:
   -rw-r--r-- 1 user group 15420 Oct 21 10:30 001_oauth_patterns.md

3. Verify file size > 0:
   [ -s specs/027_authentication/reports/001_oauth_patterns.md ] && echo "✓ File created"

4. If verification fails, proceed to FALLBACK MECHANISM.
5. If verification succeeds, proceed to next agent invocation.

**Step 3: Fallback File Creation**

If verification fails, create file directly:

## FALLBACK MECHANISM - Manual File Creation

TRIGGER: File verification failed for 001_oauth_patterns.md

EXECUTE IMMEDIATELY:

1. Create file directly using Write tool:
   Write tool invocation:
   {
     "file_path": "specs/027_authentication/reports/001_oauth_patterns.md",
     "content": "<agent's report content from previous response>"
   }

2. MANDATORY VERIFICATION (repeat):
   ls -la specs/027_authentication/reports/001_oauth_patterns.md

3. If still fails, escalate to user with error details.
4. If succeeds, log fallback usage and continue workflow.
```

**Plan 497 Gaps**:

1. **No File Existence Verification**:
   - Phase 1 (/coordinate fixes): No verification checkpoints for agent-created files
   - Phase 3 (/research fixes): No verification checkpoints for agent-created files
   - Phase 4 (integration testing): File verification only in TESTING phase, not RUNTIME enforcement

2. **No Fallback Creation**:
   - Zero fallback mechanisms specified
   - Agent failures would cascade to dependent phases (same problem pattern fixes)
   - Phase 2 explicitly REMOVES fallbacks (lines 413-433) but doesn't replace with verification checkpoints

3. **Inconsistent with Project Standard**:
   - Command Architecture Standards (Standard 0) requires Pattern 2: Mandatory Verification Checkpoints (lines 103-133)
   - Verification-Fallback pattern is marked [Used by: /implement, /orchestrate, /plan, /report, all file creation commands and agents] (line 3)
   - Plan 497 fixes orchestration commands (/coordinate, /supervise, /research) but doesn't implement file verification

**Impact on File Creation Rate**:

From `verification-fallback.md` Performance Impact (lines 343-351):

| Command | Before Pattern | After Pattern | Improvement |
|---------|---------------|---------------|-------------|
| /report | 7/10 (70%) | 10/10 (100%) | +43% |
| /plan | 6/10 (60%) | 10/10 (100%) | +67% |
| /implement | 8/10 (80%) | 10/10 (100%) | +25% |
| **Average** | **7/10 (70%)** | **10/10 (100%)** | **+43%** |

**Plan 497 without verification checkpoints will likely achieve:**
- File creation rate: ~70% (7/10) - same as "before pattern"
- Downstream reliability: 30% workflow failures due to missing files
- No improvement in file creation reliability despite fixing agent invocation patterns

**Critical Issue**:
Plan fixes agent INVOCATION pattern (0% → >90% delegation rate) but doesn't fix FILE CREATION verification (expected 70% → 70%, not 70% → 100%). The plan addresses one failure mode (agents not being invoked) but ignores a second failure mode (agents invoked but files not created).

### 4. Fallback Removal Philosophy - PARTIAL COMPLIANCE (60/100)

**Phase 2 Fallback Removal** (lines 384-461):

Plan explicitly removes fallback mechanisms from /supervise:

**Task 2.2: Remove Fallback Functions** (lines 413-419):
- Remove workflow-detection.sh fallback functions
- Remove inline function definitions
- Force explicit error if library sourcing fails
- Update error message to suggest installing missing library

**Task 2.4: Remove Directory Creation Fallbacks** (lines 428-433):
- Remove topic directory creation fallback
- Remove implementation artifacts directory fallback
- Keep agent invocation `mkdir -p` instructions (agents responsible)
- Add validation that agents created expected directories
- Fail-fast if directories missing after agent execution

**Design Rationale** (lines 395-401):
> Remove fallback mechanisms to enable effective debugging when commands don't work consistently:
> - Clear, explicit error messages when library sourcing fails
> - Better diagnostics for missing functions
> - Remove fallback functions (force explicit library dependencies)
> - Remove directory creation fallbacks (agents must create directories)
> - NO startup marker (uncertain value for orchestrator mode detection)
> - Fail-fast approach: explicit errors are easier to debug than silent fallbacks

**Compliance Analysis**:

**ALIGNED with fail-fast philosophy**:
- Removing silent fallbacks that hide errors (GOOD)
- Forcing explicit errors for missing dependencies (GOOD)
- Better diagnostics when failures occur (GOOD)

**MISALIGNED with Verification-Fallback pattern**:
- Verification-Fallback pattern requires BOTH verification AND fallback
- Fallback removal applies to BOOTSTRAP/INFRASTRUCTURE failures (correct)
- Fallback removal should NOT apply to FILE CREATION operations (incorrect omission)

**Distinction Not Made in Plan**:

The plan conflates two types of fallbacks:

1. **Bad Fallbacks** (correctly removed):
   - Silent fallback function definitions when library missing
   - Automatic directory creation when agent should create
   - Hiding configuration/dependency errors

2. **Good Fallbacks** (incorrectly omitted):
   - File creation verification checkpoints
   - Fallback file creation when agent succeeds but file missing
   - Detection and correction of tool failures

**From verification-fallback.md** (lines 85-106):
> **Step 3: Fallback File Creation**
>
> If verification fails, create file directly:
>
> ## FALLBACK MECHANISM - Manual File Creation
>
> TRIGGER: File verification failed for 001_oauth_patterns.md
>
> [Creates file directly using Write tool]

This is a CORRECTIVE fallback (detects and fixes agent tool failures), not a HIDING fallback (masks dependency issues). Plan 497 removes ALL fallbacks without distinguishing between these categories.

**Result**:
- Bootstrap failures: Explicit errors (GOOD - achieves fail-fast goal)
- File creation failures: Silent propagation to dependent phases (BAD - violates fail-fast goal AND verification pattern)

### 5. Progress Checkpoint Pattern - PRESENT (90/100)

**Progress Checkpoints in Plan** (example from lines 337-342):

```markdown
<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->
```

**Occurrence Analysis**:
- Phase 0: 1 progress checkpoint (line 271)
- Phase 1: 1 progress checkpoint (line 337)
- Phase 2: 1 progress checkpoint (line 416)
- Phase 3: 1 progress checkpoint (line 492)
- Phase 4: 1 progress checkpoint (line 579)
- Phase 5: 1 progress checkpoint (line 677)

Total: 6 progress checkpoints (1 per phase)

**Compliance with Checkpoint Recovery Pattern**:

From CLAUDE.md (lines 908-909):
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore (API: save_checkpoint, restore_checkpoint)

**Phase Completion Requirements** (consistent pattern across all phases):
```markdown
**Phase N Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(497): complete Phase N - [Description]`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status
```

**Strengths**:
- Consistent checkpoint placement (every phase)
- Clear checkpoint format (markdown checklist)
- Git commit integration (enables rollback to any phase)
- Plan file self-updating (maintains state)

**Minor Gaps**:
- No explicit `save_checkpoint()` function calls (lines 335, 908 mention checkpoint functions)
- "if complex phase" qualifier unclear (all phases meet complexity criteria)
- No checkpoint restoration instructions in Phase 1 Task 1.3 despite mention (line 335)

**Distinction from MANDATORY VERIFICATION**:
- Progress checkpoints: Track TASK COMPLETION (plan state)
- Mandatory verification: Verify FILE CREATION (artifact state)
- These are complementary, not equivalent

Current plan has 6 progress checkpoints but 0 mandatory verification checkpoints.

### 6. Test-Before-Commit Enforcement - STRONG (95/100)

**Phase Completion Requirements** (consistent across all 6 phases):

Every phase requires:
```markdown
**Phase N Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(497): complete Phase N - [Description]`
```

**Enforcement Locations**:
- Phase 0: lines 300-305
- Phase 1: lines 377-382
- Phase 2: lines 456-461
- Phase 3: lines 542-547
- Phase 4: lines 639-644
- Phase 5: lines 734-739

**Test-Before-Commit Pattern**:
1. Complete all tasks (checkbox verification)
2. Run test suite (explicit test execution)
3. Verify tests pass (gate before commit)
4. Create git commit (only after tests pass)

**Compliance with Testing Protocols** (CLAUDE.md lines 91-95):
- ✅ "run test suite per Testing Protocols in CLAUDE.md" explicit reference
- ✅ Test execution required before commit
- ✅ Consistent enforcement across all phases

**Git Commit Convention**:
Pattern: `feat(497): complete Phase N - [Description]`

Examples from plan:
- `feat(497): complete Phase 0 - Shared Infrastructure and Validation Utilities`
- `feat(497): complete Phase 1 - Fix /coordinate Command Agent Invocations`
- `feat(497): complete Phase 2 - Improve /supervise Command Robustness`

**Strengths**:
- Atomic commits per phase (enables rollback)
- Conventional commit format (feat(spec): description)
- Test requirement explicit and consistent
- Clear commit message pattern

**Minor Enhancement Opportunity**:
- Could add explicit test failure handling: "If tests fail, DO NOT commit. Fix issues and re-test."
- Could reference specific test suites to run (e.g., "run test_orchestration_commands.sh")

### 7. Validation Script Testing - STRONG (100/100)

**Validation Script Specification** (Phase 0, lines 247-252):

```markdown
- [ ] Create validation script: `.claude/lib/validate-agent-invocation-pattern.sh`
  - Detect YAML-style Task blocks in command files
  - Detect markdown code fences (` ```yaml `, ` ```bash `) around Task invocations
  - Detect template variables in agent prompts (`${VAR}`)
  - Report violations with line numbers and context
  - Exit code 0 for pass, 1 for violations found
```

**Testing Plan** (lines 277-296):

```bash
# Test validation script
./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
# Expected: Violations detected (9 locations)

./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
# Expected: Violations detected (3 locations + bash code blocks)

./.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: Violations detected (0 violations - already fixed in spec 438)
```

**Validation Integration** (lines 266-269):

```markdown
- [ ] Integrate validation into CI/CD
  - Add validation script to `.claude/tests/run_all_tests.sh`
  - Set up pre-commit hook (optional)
  - Document validation workflow
```

**Usage Throughout Plan**:
- Phase 1: Validation check after /coordinate fixes (line 363)
- Phase 3: Validation check after /research fixes (line 528)
- Phase 4: Validation of all commands (lines 717-720)
- Phase 5: Validation in test suite (lines 718-721)

**Complete Validation Coverage**:
All 3 orchestration commands validated:
1. /coordinate (9 invocations)
2. /research (3 invocations + bash blocks)
3. /supervise (reference pattern, 0 violations expected)

**Strengths**:
- Automated anti-pattern detection
- Expected results documented (enables test validation)
- Integration with test runner
- Baseline established before fixes (line 265)

**Excellence Indicators**:
- Exit code convention (0/1) follows Unix standards
- Line number reporting (debugging efficiency)
- Context display (understanding violations)
- Both positive and negative test cases (supervise passes, others fail initially)

## Recommendations

### CRITICAL Priority - Add Mandatory Verification Checkpoints

**Problem**: Plan achieves 95% delegation rate but will likely maintain 70% file creation rate due to missing verification checkpoints.

**Solution**: Add MANDATORY VERIFICATION sections after each agent invocation in all 3 commands:

**For /coordinate command** (Phase 1):

After each agent invocation (Tasks 1.1-1.6), add:

```markdown
## MANDATORY VERIFICATION - [Agent Name] File Creation

EXECUTE NOW (REQUIRED BEFORE NEXT STEP):

1. Verify [artifact type] file exists:
   ```bash
   ls -la "$EXPECTED_PATH"
   [ -f "$EXPECTED_PATH" ] || echo "ERROR: File missing"
   ```

2. Verify file size > 500 bytes:
   ```bash
   FILE_SIZE=$(wc -c < "$EXPECTED_PATH")
   [ "$FILE_SIZE" -ge 500 ] || echo "WARNING: File too small (${FILE_SIZE} bytes)"
   ```

3. Results:
   IF VERIFICATION PASSES: ✓ Proceed to next step
   IF VERIFICATION FAILS: ⚡ Execute FALLBACK MECHANISM

## FALLBACK MECHANISM - Create [Artifact] File

TRIGGER: Verification failed for $EXPECTED_PATH

EXECUTE IMMEDIATELY:

1. Extract content from agent response
2. Create file using Write tool:
   ```
   Write tool invocation with file_path and content
   ```

3. MANDATORY RE-VERIFICATION:
   ```bash
   ls -la "$EXPECTED_PATH"
   ```

4. If re-verification succeeds: ✓ Continue
   If re-verification fails: ❌ Escalate to user
```

**Impact**:
- File creation rate: 70% → 100% (+43% based on verification-fallback.md metrics)
- Workflow failure rate: 30% → 0%
- Diagnostic time: 10-20 minutes → immediate (verification checkpoint identifies exact failure)

**Implementation Estimate**: +2-3 hours (0.5 hours per command × 3 commands + testing)

### HIGH Priority - Distinguish Fallback Types

**Problem**: Phase 2 removes ALL fallbacks without distinguishing bootstrap fallbacks (correct) from file creation fallbacks (incorrect).

**Solution**: Update Phase 2 rationale and scope:

**Phase 2 Task 2.2 - Revised** (lines 413-419):

```markdown
- [ ] **Task 2.2**: Remove BOOTSTRAP Fallback Functions (Not File Creation Fallbacks)
  - Remove workflow-detection.sh fallback functions (library dependency fallbacks)
  - Remove inline function definitions (bootstrap fallbacks)
  - Force explicit error if library sourcing fails
  - PRESERVE file creation verification checkpoints (these are CORRECTIVE fallbacks, not HIDING fallbacks)
  - Update error message to suggest installing missing library
```

**Add Clarification Section**:

```markdown
### Fallback Types (Critical Distinction)

**REMOVE: Bootstrap/Infrastructure Fallbacks** (hide dependency errors):
- Silent function definitions when library missing
- Automatic directory creation masking agent failures
- Fallback workflow detection when library unavailable

**PRESERVE: File Creation Fallbacks** (detect and correct tool failures):
- Verification checkpoints after agent file creation
- Fallback file creation when agent succeeds but file missing
- Detection of Write tool failures or path issues

Rationale: Bootstrap fallbacks hide configuration errors (bad), but file creation
fallbacks detect transient tool failures (good). Fail-fast means "fail immediately
on configuration errors" not "fail silently on transient tool errors."
```

**Impact**:
- Clarifies fail-fast philosophy application
- Prevents misinterpretation leading to omission of verification checkpoints
- Aligns with Verification-Fallback pattern requirements

### MEDIUM Priority - Add Test Coverage Metrics

**Problem**: Delegation rate used as proxy for test coverage, but no explicit coverage measurement.

**Solution**: Add coverage measurement to Phase 4:

**Phase 4 Task 4.7 - New**:

```markdown
- [ ] **Task 4.7**: Measure Test Coverage
  - Identify testable operations in all 3 commands:
    - Agent invocations (9 in /coordinate, 3 in /research, 7 in /supervise)
    - Library sourcing operations (7 libraries)
    - Verification checkpoints (post-fix: should be 1 per agent invocation)
  - Calculate coverage percentage:
    - Operations tested / Total operations × 100
    - Target: ≥80% per Testing Protocols
  - Document coverage metrics in test output
```

**Example Coverage Calculation**:

```bash
# /coordinate command
Total agent invocations: 9
Invocations with tests: 9 (Phase 4 Task 4.1)
Coverage: 100%

Total verification checkpoints: 9 (post-fix)
Checkpoints tested: 9 (Phase 4 Task 4.5)
Coverage: 100%

Overall /coordinate coverage: 100%
```

**Impact**:
- Quantifiable coverage metrics (vs proxy metrics)
- Compliance verification with CLAUDE.md ≥80% requirement
- Identifies coverage gaps before completion

### LOW Priority - Explicit Checkpoint Function Calls

**Problem**: Progress checkpoints mention "Checkpoint saved (if complex phase)" but don't show explicit function calls.

**Solution**: Add checkpoint save/restore examples to Phase 1:

**Phase 1 Task 1.3 Enhancement** (line 335):

```markdown
- [ ] **Task 1.3**: Fix Implementation Phase Agent Invocation (implementer-coordinator)
  - Apply same transformation pattern
  - Ensure plan path passed from planning phase
  - Add checkpoint restoration instructions:
    ```bash
    source .claude/lib/checkpoint-utils.sh
    restore_checkpoint "coordinate_planning_phase" || echo "No checkpoint, starting fresh"
    ```
  - Add checkpoint save after implementation:
    ```bash
    save_checkpoint "coordinate_implementation_phase" "$IMPLEMENTATION_ARTIFACTS"
    ```
```

**Impact**:
- Clear checkpoint function usage examples
- Removes "if complex phase" ambiguity
- Demonstrates checkpoint-utils.sh API

### LOW Priority - Pre-commit Hook Template

**Problem**: Pre-commit hook mentioned as optional (line 267) but no implementation guide.

**Solution**: Add pre-commit hook template to Phase 0:

**Phase 0 Task Enhancement**:

```markdown
- [ ] Integrate validation into CI/CD
  - Add validation script to `.claude/tests/run_all_tests.sh` ✓
  - Set up pre-commit hook (optional):
    ```bash
    # .git/hooks/pre-commit
    #!/bin/bash
    changed_commands=$(git diff --cached --name-only | grep "^.claude/commands/.*\.md$")

    for cmd in $changed_commands; do
      ./.claude/lib/validate-agent-invocation-pattern.sh "$cmd" || {
        echo "ERROR: Anti-pattern detected in $cmd"
        echo "Fix violations before committing"
        exit 1
      }
    done
    ```
  - Document validation workflow ✓
```

**Impact**:
- Prevents anti-pattern commits
- Continuous validation enforcement
- Template reduces implementation friction

## References

### Plan Files
- /home/benjamin/.config/.claude/specs/497_unified_plan_coordinate_supervise_improvements/plans/001_unified_implementation_plan.md (primary analysis target)

### Standards Documentation
- /home/benjamin/.config/CLAUDE.md (lines 60-95: Testing Protocols section)
- /home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md (complete Verification and Fallback Pattern specification)
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (lines 1-150: Standard 0 - Execution Enforcement, Pattern 2 - Mandatory Verification Checkpoints)

### Test Infrastructure
- /home/benjamin/.config/.claude/tests/run_all_tests.sh (test runner with 66 existing test suites)
- /home/benjamin/.config/.claude/tests/test_*.sh (66 test files discovered via Glob)

### Library Files Referenced in Plan
- .claude/lib/checkpoint-utils.sh (checkpoint save/restore API)
- .claude/lib/workflow-detection.sh (workflow type detection)
- .claude/lib/unified-location-detection.sh (location detection library)
- .claude/lib/validate-agent-invocation-pattern.sh (to be created in Phase 0)

### Cross-References
- Spec 495: /coordinate and /research command failures (agent invocation anti-patterns)
- Spec 057: /supervise command robustness (bootstrap failures, fallback removal)
- Spec 438: /supervise agent delegation fix (reference pattern, 6/6 regression tests passing)
- Plan 077: /implement command migration (verification-fallback pattern case study, 70% → 100% file creation rate)

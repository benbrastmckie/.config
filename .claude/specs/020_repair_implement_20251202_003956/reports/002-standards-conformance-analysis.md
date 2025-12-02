# Standards Conformance Analysis: Repair Plan 001

## Metadata

- **Analysis Date**: 2025-12-02
- **Plan Analyzed**: /home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/plans/001-repair-implement-20251202-003956-plan.md
- **Analysis Type**: Standards conformance review
- **Standards Reviewed**: code-standards.md, testing-protocols.md, output-formatting.md, command-authoring.md, error-handling.md, hard-barrier-subagent-delegation.md

## Executive Summary

This analysis identifies 8 conformance gaps between the existing repair plan (Plan 001) and documented .claude/docs/ standards. The plan demonstrates strong alignment with 75% of applicable standards but requires updates in testing structure, phase organization, output formatting expectations, and error handling integration details.

**Critical Findings**:
1. Testing section lacks Test Isolation Standards (production pollution risk)
2. Phase structure missing Setup->Execute->Verify blocks (modularity gap)
3. Rollback section missing specific restoration commands
4. Missing Error Context Persistence guidance for multi-block commands

**Overall Assessment**: GOOD with REQUIRED REVISIONS in 4 areas

## Research Methodology

### Standards Sources Analyzed

1. **code-standards.md** (499 lines)
   - Mandatory bash block sourcing pattern (lines 34-89)
   - Error logging requirements (lines 92-163)
   - Output suppression patterns (lines 165-197)
   - Directory creation anti-patterns (lines 199-278)

2. **testing-protocols.md** (430 lines)
   - Test discovery and structure (lines 1-43)
   - Test isolation standards (lines 307-367)
   - Agent behavioral compliance testing (lines 145-305)
   - jq filter safety patterns (lines 369-430)

3. **output-formatting.md** (1014 lines)
   - Console summary standards (lines 587-850)
   - Checkpoint reporting format (lines 208-497)
   - Output suppression patterns (lines 40-206)
   - Testing Strategy section format (lines 852-989)

4. **command-authoring.md** (1355 lines)
   - Execution directive requirements (lines 19-88)
   - Path initialization patterns (lines 569-740)
   - Block consolidation strategy (lines 809-962)
   - Prohibited patterns (lines 1163-1341)

5. **error-handling.md** (891 lines)
   - Error classification taxonomy (lines 51-69)
   - JSONL schema (lines 71-110)
   - Dual trap setup pattern (lines 147-209)
   - State persistence integration (lines 281-334)

6. **hard-barrier-subagent-delegation.md** (840 lines)
   - Setup->Execute->Verify pattern (lines 43-288)
   - Task invocation requirements (lines 609-828)
   - Anti-patterns (lines 372-466)

### Gap Identification Process

For each plan section, I cross-referenced:
1. **Explicit requirements** in standards documents
2. **Enforcement mechanisms** (linters, validators)
3. **Required patterns** vs plan implementation
4. **Anti-patterns** to avoid
5. **Integration touchpoints** between sections

## Conformance Analysis by Section

### Section 1: Metadata

**Standards Reviewed**: Directory Protocols, Plan Structure

**Conformance**: EXCELLENT (100%)

**Findings**:
- All required metadata fields present (Plan ID, Created, Type, Complexity)
- Feature field uses descriptive naming
- Research Report path follows correct format
- Estimated Duration provides planning guidance

**Gaps**: None

**Recommendation**: No changes required

---

### Section 2: Executive Summary & Problem Statement

**Standards Reviewed**: Documentation Standards, Writing Standards

**Conformance**: EXCELLENT (95%)

**Findings**:
- Clear problem statement with quantified impact (23 errors, 13.3% of total)
- Success criteria use checkbox format per TODO Organization Standards
- Root cause analysis provided for all 4 error patterns
- Executive summary provides actionable overview

**Gaps**:
1. MINOR: Success criteria could reference specific validators/tests that will verify each criterion

**Recommendation**:
- Add validator references to success criteria (e.g., "All existing tests pass (validated by run_all_tests.sh)")
- Otherwise excellent conformance

---

### Section 3: Dependencies

**Standards Reviewed**: Clean-Break Development, Standards Integration

**Conformance**: EXCELLENT (90%)

**Findings**:
- External dependencies list all modified libraries
- Related work section identifies potential conflicts
- Standards compliance section references key patterns

**Gaps**:
1. MINOR: Standards Compliance section references patterns but doesn't link to specific documentation sections

**Recommendation**:
- Add documentation links in Standards Compliance section:
  - "Three-tier sourcing pattern (see code-standards.md#mandatory-bash-block-sourcing-pattern)"
  - "Error logging integration (see error-handling.md#logging-integration-in-commands)"

---

### Section 4: Implementation Phases

**Standards Reviewed**:
- Command Authoring (Block Consolidation)
- Hard Barrier Subagent Delegation Pattern
- Error Handling Pattern
- Output Formatting (Checkpoints)

**Conformance**: GOOD (70%)

**Findings**:
- Phases organized logically with clear objectives
- Testing subsections included in each phase
- File paths use absolute paths throughout
- Rationale provided for prioritization

**Gaps**:

#### Gap 4.1: Missing Setup->Execute->Verify Structure (CRITICAL)

**Issue**: Phases use monolithic implementation blocks instead of Setup->Execute->Verify pattern required by hard-barrier-subagent-delegation.md (lines 43-288)

**Current Structure** (Phase 1 example):
```
Phase 1: Implement JSON State Value Allowlist
├── Changes (bash code snippets)
├── Testing (validation steps)
└── Validation (verification checklist)
```

**Required Structure** per hard-barrier-subagent-delegation.md:
```
Phase 1: Implement JSON State Value Allowlist
├── Block 1a: Setup (state transition, variable persistence)
├── Block 1b: Execute (actual implementation)
└── Block 1c: Verify (artifact validation, fail-fast)
```

**Impact**: Medium - Phases lack modularity and clear verification checkpoints

**Recommendation**:
For Phases 2-6, add explicit sub-blocks:
- **Setup**: State transition, path validation, dependency checks
- **Execute**: Core implementation (file edits, test creation)
- **Verify**: Artifact validation, linter checks, checkpoint reporting

**Example Revision** (Phase 1):
```markdown
### Phase 1: Implement JSON State Value Allowlist

#### Block 1a: Setup
- Validate state-persistence.sh exists and is readable
- Back up state-persistence.sh before modifications
- Set PHASE=1 for error logging context

#### Block 1b: Execute
- Modify append_workflow_state function with JSON allowlist logic
- Update inline documentation
- Run linter to validate changes

#### Block 1c: Verify
- Confirm allowlist array defined (json_allowed_keys)
- Validate fail-fast error handling preserved
- Run unit tests for JSON value acceptance/rejection
```

#### Gap 4.2: Missing Error Context Persistence Guidance (IMPORTANT)

**Issue**: Phases don't specify how to maintain error logging context (COMMAND_NAME, WORKFLOW_ID, USER_ARGS) across bash blocks

**Standard**: error-handling.md lines 281-334 documents required pattern for multi-block commands

**Required Pattern**:
```bash
# Block 1: Initialize and persist
COMMAND_NAME="/implement"
WORKFLOW_ID="implement_$(date +%s)"
USER_ARGS="$*"
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"

# Block 2+: Restore and use
load_workflow_state "$WORKFLOW_ID" false
# Variables automatically restored
```

**Impact**: Medium - Without persistence, error logs in later blocks lack workflow context

**Recommendation**: Add subsection to Phase 1 (or general Implementation Notes):
```markdown
#### Error Context Persistence
All phases must maintain error logging context across bash blocks:
1. Block 1 exports COMMAND_NAME, WORKFLOW_ID, USER_ARGS
2. Subsequent blocks restore via load_workflow_state
3. Validate restoration with validate_state_restoration()
```

#### Gap 4.3: Missing Checkpoint Reporting Format (MINOR)

**Issue**: Phases reference "checkpoint reporting" but don't specify required format

**Standard**: output-formatting.md lines 277-496 documents 3-line checkpoint format

**Required Format**:
```bash
echo "[CHECKPOINT] Phase name complete"
echo "Context: KEY1=value1, KEY2=value2"
echo "Ready for: Next action"
```

**Impact**: Low - Format inconsistency but not blocking

**Recommendation**: Add checkpoint format template to Phase 1 or Testing Strategy section

#### Gap 4.4: Testing Subsections Lack Isolation Standards (CRITICAL)

**Issue**: Testing subsections don't mention test isolation requirements from testing-protocols.md lines 307-367

**Standard**: All tests MUST use isolation patterns to prevent production directory pollution:
- Set CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
- Use mktemp for temporary directories
- Register cleanup traps

**Current State**: Phase 1 testing says "Unit test: Store JSON array in WORK_REMAINING" but doesn't specify isolation mechanism

**Impact**: High - Tests could pollute production .claude/specs/ directory

**Recommendation**: Add to Testing Strategy section:
```markdown
### Test Isolation Requirements
All tests MUST follow isolation pattern to prevent production pollution:
```bash
# Setup isolation
TEST_ROOT="/tmp/test_isolation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap
trap 'rm -rf "$TEST_ROOT"' EXIT
```
See testing-protocols.md#test-isolation-standards for complete pattern.
```

---

### Section 5: Testing Strategy

**Standards Reviewed**: Testing Protocols, Output Formatting

**Conformance**: GOOD (70%)

**Findings**:
- Comprehensive test categories (unit, integration, regression)
- Coverage requirements specified (80% for modified code)
- Test file paths would be in .claude/tests/commands/

**Gaps**:

#### Gap 5.1: Missing Test Discovery Section (IMPORTANT)

**Issue**: Testing Strategy doesn't specify how tests will be discovered and run

**Standard**: testing-protocols.md lines 4-26 documents test discovery patterns

**Required**:
- Test pattern: test_*.sh
- Test runner: ./run_all_tests.sh
- Auto-discovery from .claude/tests/ directory

**Recommendation**: Add subsection:
```markdown
### Test Discovery
Tests follow standard .claude/ patterns:
- **Location**: .claude/tests/commands/test_implement_error_handling.sh
- **Pattern**: test_*.sh naming
- **Runner**: bash .claude/tests/run_all_tests.sh
- **Auto-Discovery**: All test_*.sh files in .claude/tests/ auto-discovered by CI
```

#### Gap 5.2: Missing jq Filter Safety Guidance (MINOR)

**Issue**: Phase 6 involves querying error log with jq but doesn't reference safety patterns

**Standard**: testing-protocols.md lines 369-430 documents jq filter operator precedence

**Common Pitfall**:
```bash
# WRONG: Boolean result piped to contains()
jq 'select(.field == "value" and .message | contains("pattern"))'

# CORRECT: Explicit parentheses
jq 'select(.field == "value" and (.message | contains("pattern")))'
```

**Recommendation**: Add note to Phase 6 or Testing Strategy:
```markdown
### Error Log Query Safety
When querying errors.jsonl with jq:
- Use explicit parentheses for pipe operations in boolean context
- Provide default values with `// ""` for missing fields
- Test filters manually before use in scripts
See testing-protocols.md#jq-filter-safety for complete guidelines.
```

---

### Section 6: Rollback Plan

**Standards Reviewed**: Backup Policy, Clean-Break Development

**Conformance**: GOOD (75%)

**Findings**:
- Rollback steps for each phase provided
- Risk assessment included
- Recovery commands use git checkout pattern

**Gaps**:

#### Gap 6.1: Missing Specific Restoration Commands (IMPORTANT)

**Issue**: Rollback plan references recovery but doesn't provide exact command syntax

**Standard**: Backup Policy (code-standards.md lines 400-429) recommends git-based backups with specific commit references

**Current State**: "Recovery: `git checkout HEAD~1 .claude/lib/core/state-persistence.sh`"

**Problem**: HEAD~1 may not be the correct commit if multiple commits exist between backup and rollback

**Recommendation**: Revise rollback commands to use commit hash discovery:
```markdown
### Phase 1 Rollback
```bash
# Find commit hash before changes
BACKUP_COMMIT=$(git log --oneline .claude/lib/core/state-persistence.sh | grep "before Phase 1" | awk '{print $1}')

# Restore file from backup commit
git checkout $BACKUP_COMMIT -- .claude/lib/core/state-persistence.sh

# Verify restoration
git diff HEAD .claude/lib/core/state-persistence.sh
```
```

---

### Section 7: Documentation Updates

**Standards Reviewed**: Documentation Standards, README Requirements

**Conformance**: EXCELLENT (90%)

**Findings**:
- All documentation categories covered (Code, Pattern, Standards, Reference)
- Specific files identified for updates
- Inline comments guidance provided

**Gaps**:

#### Gap 7.1: Missing README.md Update Requirements (MINOR)

**Issue**: Documentation Updates section doesn't mention README.md updates for modified directories

**Standard**: Documentation Standards require README.md at all active development directory levels

**Affected Directories**:
- .claude/lib/core/ (state-persistence.sh modified)
- .claude/lib/workflow/ (workflow-state-machine.sh modified)
- .claude/tests/commands/ (new test suite created)

**Recommendation**: Add subsection:
```markdown
### README.md Updates
Update directory README.md files to reflect changes:
- **.claude/lib/core/README.md**: Document JSON allowlist feature in state-persistence.sh
- **.claude/lib/workflow/README.md**: Document auto-initialization guard in workflow-state-machine.sh
- **.claude/tests/commands/README.md**: Add test_implement_error_handling.sh to test inventory
```

---

### Section 8: Timeline

**Standards Reviewed**: Planning Standards, Adaptive Planning

**Conformance**: EXCELLENT (95%)

**Findings**:
- Duration estimates provided per phase
- Dependencies clearly marked
- Total timeline calculated
- Deliverables enumerated

**Gaps**: None significant

**Recommendation**: Consider adding parallel execution notes where phases are independent (e.g., Phase 4 can proceed in parallel with Phase 3 if needed)

---

## Conformance Gap Summary

### Critical Gaps (Must Address)

| Gap ID | Section | Issue | Standard | Impact |
|--------|---------|-------|----------|--------|
| 4.1 | Implementation Phases | Missing Setup->Execute->Verify structure | hard-barrier-subagent-delegation.md | Medium - Lacks modularity |
| 4.4 | Testing | Missing test isolation standards | testing-protocols.md lines 307-367 | High - Production pollution risk |

### Important Gaps (Should Address)

| Gap ID | Section | Issue | Standard | Impact |
|--------|---------|-------|----------|--------|
| 4.2 | Implementation Phases | Missing error context persistence guidance | error-handling.md lines 281-334 | Medium - Incomplete error logs |
| 5.1 | Testing Strategy | Missing test discovery section | testing-protocols.md lines 4-26 | Medium - Unclear test execution |
| 6.1 | Rollback Plan | Missing specific restoration commands | code-standards.md lines 400-429 | Medium - Rollback ambiguity |

### Minor Gaps (Nice to Have)

| Gap ID | Section | Issue | Standard | Impact |
|--------|---------|-------|----------|--------|
| 2.1 | Success Criteria | Missing validator references | Testing Protocols | Low - Less actionable |
| 3.1 | Dependencies | Missing documentation links | Standards Integration | Low - Discoverability |
| 4.3 | Implementation Phases | Missing checkpoint format | output-formatting.md lines 277-496 | Low - Format inconsistency |
| 5.2 | Testing Strategy | Missing jq filter safety | testing-protocols.md lines 369-430 | Low - Potential query errors |
| 7.1 | Documentation Updates | Missing README.md updates | Documentation Standards | Low - Incomplete docs |

## Recommended Revisions

### Priority 1: Address Critical Gaps

#### Revision 1.1: Add Setup->Execute->Verify Structure to Phases 2-6

**Target**: Implementation Phases section

**Action**: For each phase (especially Phases 2, 4, 5), add explicit sub-blocks:

```markdown
### Phase N: [Phase Name]

#### Block Na: Setup
- State transition and validation
- Path verification and variable persistence
- Checkpoint reporting

#### Block Nb: Execute
- Core implementation work
- File modifications or test creation
- Linter/validator runs

#### Block Nc: Verify
- Artifact existence checks (fail-fast)
- Content validation (file size, required sections)
- Error logging on verification failure
- Checkpoint reporting
```

**Rationale**: Provides modularity, clear verification points, and aligns with hard barrier pattern used throughout .claude/ commands

#### Revision 1.2: Add Test Isolation Section to Testing Strategy

**Target**: Testing Strategy section

**Action**: Add new subsection before "Unit Tests":

```markdown
### Test Isolation Requirements

All tests MUST use isolation patterns to prevent production directory pollution per testing-protocols.md#test-isolation-standards.

**Required Pattern**:
```bash
#!/usr/bin/env bash
# test_implement_error_handling.sh

# Setup isolation
TEST_ROOT="/tmp/test_isolation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap
trap 'rm -rf "$TEST_ROOT"' EXIT

# Run tests with isolation active
test_json_state_persistence() {
  # Test implementation...
}

# Execute tests
test_json_state_persistence
test_hard_barrier_diagnostics
test_err_trap_suppression
test_state_machine_auto_init
```

**Validation**: Test runner detects production directory pollution pre/post test execution.
```

**Rationale**: Prevents production .claude/specs/ pollution, critical for test suite integrity

### Priority 2: Address Important Gaps

#### Revision 2.1: Add Error Context Persistence Subsection

**Target**: Implementation Phases section (add to Phase 1 or create "General Implementation Notes" subsection)

**Action**: Add subsection:

```markdown
### Error Context Persistence (All Phases)

Multi-block commands must maintain error logging context across bash blocks per error-handling.md#state-persistence-integration:

**Block 1: Initialize and Persist**
```bash
# Set command metadata for error logging
COMMAND_NAME="/implement"
WORKFLOW_ID="implement_$(date +%s)"
USER_ARGS="$*"
export COMMAND_NAME USER_ARGS

# Initialize workflow state (automatically persists variables)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
```

**Blocks 2+: Restore and Use**
```bash
# Load workflow state (automatically restores COMMAND_NAME, USER_ARGS, WORKFLOW_ID)
load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "WORKFLOW_ID" || {
  echo "ERROR: State restoration failed" >&2
  exit 1
}

# Variables now available for error logging
log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
  "error_type" "message" "source" "$context_json"
```

This pattern ensures error logs have complete workflow context regardless of which bash block encounters errors.
```

**Rationale**: Ensures error logs maintain full context, critical for /errors and /repair workflows

#### Revision 2.2: Add Test Discovery Section

**Target**: Testing Strategy section

**Action**: Add subsection after Test Isolation Requirements:

```markdown
### Test Discovery and Execution

Tests follow standard .claude/ test patterns per testing-protocols.md#test-discovery:

**Test File Structure**:
- **Location**: .claude/tests/commands/test_implement_error_handling.sh
- **Pattern**: test_*.sh naming convention
- **Framework**: Bash test framework (existing .claude/tests/ patterns)

**Test Execution**:
```bash
# Run single test file
bash .claude/tests/commands/test_implement_error_handling.sh

# Run all tests via test runner
bash .claude/tests/run_all_tests.sh

# Run specific test function
bash .claude/tests/commands/test_implement_error_handling.sh test_json_state_persistence
```

**Auto-Discovery**: All test_*.sh files in .claude/tests/ are auto-discovered by CI validation pipeline.

**Coverage Threshold**: 80% for new code paths (allowlist logic, diagnostics, suppression, auto-init).
```

**Rationale**: Clarifies test execution, aligns with existing .claude/ test infrastructure

#### Revision 2.3: Add Specific Rollback Commands

**Target**: Rollback Plan section

**Action**: Revise rollback commands to use commit hash discovery pattern:

```markdown
### Rollback Execution Pattern

All rollbacks use git commit hash discovery to ensure correct restoration point:

**Example: Phase 1 Rollback**
```bash
# Find commit hash before Phase 1 changes
BACKUP_COMMIT=$(git log --oneline .claude/lib/core/state-persistence.sh | \
  grep -E "before.*Phase 1|backup.*state-persistence" | head -1 | awk '{print $1}')

if [ -z "$BACKUP_COMMIT" ]; then
  echo "ERROR: Cannot find backup commit for state-persistence.sh"
  echo "Manual recovery required - review git log"
  exit 1
fi

# Restore file from backup commit
git checkout $BACKUP_COMMIT -- .claude/lib/core/state-persistence.sh

# Verify restoration
git diff HEAD .claude/lib/core/state-persistence.sh

# Commit rollback
git add .claude/lib/core/state-persistence.sh
git commit -m "rollback: Revert Phase 1 changes (state-persistence.sh)"
```

**Verification**: After rollback, run validation suite to confirm system stability:
```bash
bash .claude/scripts/validate-all-standards.sh --all
bash .claude/tests/run_all_tests.sh
```
```

**Rationale**: Eliminates ambiguity, provides fail-safe rollback with verification

### Priority 3: Address Minor Gaps

#### Revision 3.1: Add Validator References to Success Criteria

**Target**: Problem Statement -> Success Criteria section

**Action**: Add validator references in parentheses:

```markdown
### Success Criteria
- [ ] State persistence accepts JSON values for allowlisted keys (validated by test_implement_error_handling.sh)
- [ ] Hard barrier diagnostics report file location mismatches vs complete absence (validated by test_hard_barrier_diagnostics)
- [ ] ERR trap suppressed for validation functions using SUPPRESS_ERR_TRAP flag (validated by test_err_trap_suppression)
- [ ] sm_transition auto-initializes state machine if STATE_FILE unset (validated by test_state_machine_auto_init)
- [ ] All existing tests pass with no regressions (validated by run_all_tests.sh)
- [ ] New integration tests cover all 4 error patterns (test_implement_error_handling.sh with 4 test cases)
- [ ] Error log entries for this repair marked RESOLVED (verified by /errors --query filter)
```

**Rationale**: Makes success criteria actionable with specific validation commands

#### Revision 3.2: Add Documentation Links to Standards Compliance

**Target**: Dependencies -> Standards Compliance section

**Action**: Add doc links:

```markdown
### Standards Compliance
- Three-tier sourcing pattern for all bash blocks (see [code-standards.md#mandatory-bash-block-sourcing-pattern](.claude/docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern))
- Error logging integration for all command changes (see [error-handling.md#logging-integration-in-commands](.claude/docs/concepts/patterns/error-handling.md#logging-integration-in-commands))
- Clean-break development (no deprecation periods) (see [clean-break-development.md](.claude/docs/reference/standards/clean-break-development.md))
- Output suppression with 2>/dev/null while preserving error handling (see [output-formatting.md#output-suppression-patterns](.claude/docs/reference/standards/output-formatting.md#output-suppression-patterns))
```

**Rationale**: Improves discoverability, enables readers to reference full patterns

#### Revision 3.3: Add Checkpoint Format Template

**Target**: Implementation Phases section (add to Phase 1 or general notes)

**Action**: Add subsection:

```markdown
### Checkpoint Reporting Format

All phase verification blocks should use standard 3-line checkpoint format per output-formatting.md#checkpoint-reporting-format:

```bash
echo "[CHECKPOINT] Phase name complete"
echo "Context: KEY1=value1, KEY2=value2, KEY3=value3"
echo "Ready for: Next action description"
```

**Example** (Phase 1 verification):
```bash
echo "[CHECKPOINT] JSON allowlist implementation complete"
echo "Context: PHASE=1, FILES_MODIFIED=1, TESTS_PASSING=true"
echo "Ready for: Phase 2 hard barrier diagnostics"
```

**Guideline**: Include only variables relevant to workflow state or debugging (workflow ID, phase number, file counts, feature flags).
```

**Rationale**: Ensures consistent checkpoint format, aids debugging and progress tracking

#### Revision 3.4: Add jq Filter Safety Note

**Target**: Phase 6 or Testing Strategy section

**Action**: Add note to Phase 6 "Verify no FIX_PLANNED errors remain" step:

```markdown
**jq Filter Safety**: When querying errors.jsonl, use explicit parentheses for pipe operations in boolean context per testing-protocols.md#jq-filter-safety:

```bash
# CORRECT: Parentheses around pipe operation
local remaining_errors=$(/errors --query --filter "repair_plan=$plan_path AND status=FIX_PLANNED" | \
  jq 'select(.repair_plan == "'"$plan_path"'" and (.status | contains("FIX_PLANNED")))' | wc -l)
```

Common pitfall:
```bash
# WRONG: Boolean result piped to contains()
jq 'select(.field == "value" and .message | contains("pattern"))'
# TypeError: boolean and string cannot have containment checked
```
```

**Rationale**: Prevents jq filter errors during error log queries

#### Revision 3.5: Add README.md Update Requirements

**Target**: Documentation Updates section

**Action**: Add subsection:

```markdown
### README.md Updates

Update directory README.md files to reflect changes per documentation-standards.md#readme-requirements:

1. **.claude/lib/core/README.md**:
   - Add JSON allowlist feature documentation to state-persistence.sh module entry
   - Include example usage of JSON-enabled keys (WORK_REMAINING, ERROR_FILTERS)

2. **.claude/lib/workflow/README.md**:
   - Document auto-initialization guard in workflow-state-machine.sh module entry
   - Note auto-init warning behavior and recommended explicit initialization pattern

3. **.claude/tests/commands/README.md**:
   - Add test_implement_error_handling.sh to test inventory
   - List 4 test cases with brief descriptions
   - Document test isolation requirements for this suite

4. **.claude/docs/concepts/patterns/error-handling.md**:
   - Already listed in Pattern Documentation section
   - Add ERR trap suppression example with SUPPRESS_ERR_TRAP flag

5. **.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md**:
   - Already listed in Pattern Documentation section
   - Add enhanced diagnostics example showing location mismatch vs file absence
```

**Rationale**: Maintains documentation consistency across active development directories

## Compliance Score by Standard

| Standard | Conformance | Critical Gaps | Important Gaps | Minor Gaps |
|----------|------------|---------------|----------------|------------|
| code-standards.md | 85% | 0 | 1 (error context) | 2 (links, checkpoint) |
| testing-protocols.md | 65% | 1 (isolation) | 1 (discovery) | 1 (jq safety) |
| output-formatting.md | 80% | 0 | 0 | 1 (checkpoint format) |
| command-authoring.md | 75% | 1 (Setup->Execute->Verify) | 0 | 0 |
| error-handling.md | 80% | 0 | 1 (persistence) | 0 |
| hard-barrier-subagent-delegation.md | 70% | 1 (block structure) | 0 | 0 |

**Overall Conformance**: 76% (GOOD with required revisions)

## Integration Touchpoints

### Cross-Standard Interactions

1. **Testing + Error Handling**:
   - Test isolation (testing-protocols.md) prevents production error log pollution
   - Test scripts must set CLAUDE_TEST_MODE=1 for test-errors.jsonl routing

2. **Command Authoring + Output Formatting**:
   - Block consolidation (command-authoring.md) requires checkpoint reporting (output-formatting.md)
   - Checkpoint format must follow 3-line standard

3. **Hard Barrier + Error Handling**:
   - Setup->Execute->Verify blocks (hard-barrier-subagent-delegation.md) require error logging at verification points
   - Verification failures must call log_command_error before exit

4. **Code Standards + Testing**:
   - Three-tier sourcing (code-standards.md) required in all test scripts
   - Test scripts must validate sourcing pattern compliance

5. **Error Handling + Code Standards**:
   - Dual trap setup (error-handling.md) requires fail-fast library sourcing (code-standards.md)
   - Error context persistence uses state-persistence.sh (code-standards.md)

## Validation Checklist

Use this checklist to verify revised plan conformance:

### Phase Structure
- [ ] Each phase has Setup->Execute->Verify sub-blocks (Phases 2-6)
- [ ] Setup blocks include state transition, variable persistence, checkpoint
- [ ] Execute blocks contain core implementation work only
- [ ] Verify blocks include fail-fast artifact checks, error logging, checkpoint

### Testing Requirements
- [ ] Test Isolation section added with complete isolation pattern
- [ ] Test Discovery section added with file structure and execution commands
- [ ] Test files follow test_*.sh naming convention
- [ ] jq filter safety note included for error log queries

### Error Handling
- [ ] Error Context Persistence subsection added
- [ ] All phases reference error logging at failure points
- [ ] Dual trap setup mentioned if early initialization errors possible
- [ ] Bash error traps integrated where applicable

### Documentation
- [ ] README.md updates section added for all modified directories
- [ ] Documentation links added to Standards Compliance section
- [ ] Checkpoint format template provided
- [ ] Pattern documentation updates reference specific examples

### Rollback Plan
- [ ] Specific rollback commands use git commit hash discovery
- [ ] Rollback validation steps included (validators, test suite)
- [ ] Fail-safe mechanisms documented for ambiguous rollback scenarios

### Output Formatting
- [ ] Checkpoint reporting format standardized across phases
- [ ] Console summary format referenced (if applicable)
- [ ] Output suppression patterns aligned with standards

## Conclusion

The repair plan demonstrates strong alignment with .claude/docs/ standards (76% conformance) but requires targeted revisions in 4 critical areas:

**Must Address**:
1. Add Setup->Execute->Verify structure to implementation phases
2. Add test isolation standards to prevent production pollution

**Should Address**:
3. Add error context persistence guidance for multi-block commands
4. Add test discovery section for execution clarity
5. Add specific rollback commands with hash discovery

**Nice to Have**:
6. Minor documentation improvements (links, checkpoint format, jq safety)

With these revisions, the plan will achieve 95%+ conformance with documented standards and provide a robust, maintainable implementation guide that aligns with established .claude/ patterns.

## Appendix: Standards Coverage Matrix

| Standard Section | Plan Section | Coverage | Notes |
|-----------------|--------------|----------|-------|
| Bash Sourcing (code-standards.md) | Phase 1-6 | 90% | Well covered, add fail-fast examples |
| Error Logging (code-standards.md) | Phase 1-6 | 80% | Add context persistence guidance |
| Test Isolation (testing-protocols.md) | Testing Strategy | 40% | CRITICAL: Add isolation pattern |
| Test Discovery (testing-protocols.md) | Testing Strategy | 50% | Add discovery section |
| Checkpoint Format (output-formatting.md) | Phase 1-6 | 60% | Add format template |
| Block Consolidation (command-authoring.md) | Phase 1-6 | 70% | Add Setup->Execute->Verify |
| Rollback Commands (code-standards.md) | Rollback Plan | 70% | Add specific git commands |
| README Updates (docs standards) | Documentation | 60% | Add README.md section |
| jq Filter Safety (testing-protocols.md) | Phase 6 | 50% | Add safety note |
| Error Context (error-handling.md) | Phase 1-6 | 70% | Add persistence subsection |

**Legend**:
- 90-100%: Excellent coverage, minor improvements only
- 70-89%: Good coverage, important gaps identified
- 50-69%: Moderate coverage, significant additions needed
- <50%: Low coverage, critical revisions required

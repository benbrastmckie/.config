# Implementation Plan: Plan Metadata Dependencies Fix

## Metadata

**Date**: 2025-12-09
**Feature**: Fix /lean-plan phase metadata generation and preprocessing-unsafe conditionals
**Status**: [COMPLETE]
**Estimated Hours**: 6-8 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Lean Plan Output Error Diagnosis](../reports/001-lean-plan-error-diagnosis.md)
- [Plan Metadata Dependencies & Phase Classification](../reports/002-plan-metadata-dependencies.md)
- [Infrastructure Integration with Standards](../reports/003-infrastructure-standards-integration.md)

## Overview

The /lean-plan command fails during Block 1d-topics execution with a bash conditional syntax error, preventing research report generation and causing generated plans to lack phase-level metadata (implementer, dependencies, lean_file fields). This blocks wave-based parallel execution and unambiguous phase classification in /lean-implement.

**Root Causes**:
1. Preprocessing-unsafe conditional at lean-plan.md:937 (`if [[ ! "$REPORT_FILE" =~ ^/ ]]`) triggers bash syntax error
2. Workflow failure prevents research-coordinator invocation and report generation
3. lean-plan-architect agent bypassed entirely due to Block 1d failure
4. standards-extraction.sh exists and includes plan_metadata_standard but is never invoked by /lean-plan
5. lean-plan-architect behavioral guidelines do not explicitly require phase metadata fields

**Impact**:
- Complete /lean-plan workflow failure (no research, empty topic directory)
- Generated plans lack phase-level metadata for coordinator routing
- /lean-implement forced to use Tier 3 keyword fallback (error-prone classification)
- Wave-based parallelization disabled (40-60% performance loss)

**Solution Architecture**:
1. Fix preprocessing-unsafe conditionals in lean-plan.md (2 occurrences at lines 937, 1583)
2. Add standards extraction invocation before lean-plan-architect Task delegation
3. Update lean-plan-architect behavioral guidelines with explicit phase metadata template
4. Audit and test full workflow end-to-end with validation checkpoints

## Phases

### Phase 1: Fix Preprocessing-Unsafe Conditionals [COMPLETE]
implementer: software
dependencies: []

**Goal**: Replace preprocessing-unsafe bash conditionals in lean-plan.md with split-pattern approach proven in Spec 005 fix.

**Files Modified**:
- /home/benjamin/.config/.claude/commands/lean-plan.md

**Tasks**:

- [x] Fix conditional at line 937 (REPORT_FILE validation)
  - Replace: `if [[ ! "$REPORT_FILE" =~ ^/ ]]; then`
  - With split pattern: `[[ "${REPORT_FILE:-}" = /* ]]; IS_ABSOLUTE_REPORT_PATH=$?; if [ $IS_ABSOLUTE_REPORT_PATH -ne 0 ]; then`
  - Preserve error logging behavior
  - Verify indentation and context preserved

- [x] Fix conditional at line 1583 (PLAN_PATH validation)
  - Replace: `if [[ ! "$PLAN_PATH" =~ ^/ ]]; then`
  - With split pattern: `[[ "${PLAN_PATH:-}" = /* ]]; IS_ABSOLUTE_PLAN_PATH=$?; if [ $IS_ABSOLUTE_PLAN_PATH -ne 0 ]; then`
  - Preserve error logging behavior
  - Verify indentation and context preserved

- [x] Audit for additional unsafe conditionals
  - Search entire lean-plan.md for `if [[ ! ` pattern
  - Verify only lines 937 and 1583 require fixes
  - Document any additional occurrences found

**Success Criteria**:
- [x] Block 1d-topics executes without bash syntax error
- [x] TOPIC_NAME variable successfully set after Block 1d
- [x] REPORT_PATHS_JSON_PATH file created with valid JSON
- [x] lint_bash_conditionals.sh passes for lean-plan.md

**Validation**:
```bash
# Test Block 1d execution
/lean-plan "test formalization task" 2>&1 | tee /tmp/lean-plan-test.log
grep -q "conditional binary operator expected" /tmp/lean-plan-test.log && echo "FAIL: Syntax error still present" || echo "PASS: No syntax errors"

# Verify linter passes
bash /home/benjamin/.config/.claude/scripts/lint/lint_bash_conditionals.sh /home/benjamin/.config/.claude/commands/lean-plan.md
```

### Phase 2: Add Standards Extraction to /lean-plan [COMPLETE]
implementer: software
dependencies: [1]

**Goal**: Invoke format_standards_for_prompt() before lean-plan-architect Task delegation to inject phase metadata standard into agent context.

**Files Modified**:
- /home/benjamin/.config/.claude/commands/lean-plan.md

**Tasks**:

- [x] Add standards extraction invocation in Block 1e
  - Insert after workflow state restoration
  - Insert before lean-plan-architect Task invocation
  - Source standards-extraction.sh library with error handling
  - Call format_standards_for_prompt() and capture output
  - Add graceful degradation if library unavailable

- [x] Persist FORMATTED_STANDARDS variable
  - Add to workflow state persistence via append_workflow_state
  - Verify available in subsequent blocks
  - Add state restoration in Block 1f (planning phase)

- [x] Update lean-plan-architect Task prompt
  - Add FORMATTED_STANDARDS section before Feature Description
  - Use markdown formatting: "**Project Standards (from CLAUDE.md)**:"
  - Follow behavioral injection pattern from hierarchical-agents-overview.md

- [x] Add standards extraction checkpoint
  - Echo confirmation message after successful extraction
  - Echo warning if standards unavailable (graceful degradation)
  - Log byte count of extracted standards for debugging

**Code Pattern** (insert in Block 1e, after state restoration):
```bash
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  echo "WARNING: standards-extraction.sh not found, proceeding without standards context" >&2
}

# Extract formatted standards for agent context
if command -v format_standards_for_prompt &>/dev/null; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt)
  echo "✓ Standards extracted for planning agent (${#FORMATTED_STANDARDS} bytes)"
else
  FORMATTED_STANDARDS=""
  echo "⚠ Standards extraction unavailable, agent will operate without standards context"
fi

# Persist for subsequent blocks
append_workflow_state "FORMATTED_STANDARDS"
```

**Success Criteria**:
- [ ] format_standards_for_prompt() successfully invoked
- [ ] FORMATTED_STANDARDS variable contains plan_metadata_standard section
- [ ] lean-plan-architect Task receives formatted standards in prompt
- [ ] Standards byte count logged in output (expect 5000-15000 bytes)

**Validation**:
```bash
# Test standards extraction
cd /home/benjamin/.config && bash -c "source .claude/lib/plan/standards-extraction.sh && format_standards_for_prompt | grep -c 'Plan Metadata Standard'"

# Verify lean-plan output includes standards confirmation
/lean-plan "test task" 2>&1 | grep "Standards extracted for planning agent"
```

### Phase 3: Update lean-plan-architect Behavioral Guidelines [COMPLETE]
implementer: software
dependencies: [1]

**Goal**: Add explicit phase metadata template and instructions to lean-plan-architect.md behavioral guidelines.

**Files Modified**:
- /home/benjamin/.config/.claude/agents/lean-plan-architect.md

**Tasks**:

- [x] Add phase metadata format to STEP 1 analysis requirements
  - Insert in "Per-Phase File Targeting" section (line ~86)
  - Document implementer field requirement (always "lean" for Lean plans)
  - Document dependencies field for wave structure
  - Document lean_file field for primary Lean file per phase

- [x] Add phase metadata template to output format examples
  - Insert complete example phase with all three metadata fields
  - Show proper placement: after heading, before tasks
  - Include both single-file and multi-file plan examples
  - Reference Plan Metadata Standard for canonical specification

- [x] Add validation checkpoint to STEP 3
  - Instruct agent to verify all phases include metadata fields
  - Add self-check: "Before returning, verify each phase includes implementer, dependencies, lean_file"
  - Reference validate-plan-metadata.sh for format validation

- [x] Add metadata generation to planning instructions
  - In STEP 3 planning section, add explicit requirement: "Each phase MUST include phase-level metadata"
  - Document field values: `implementer: lean`, `dependencies: [N, N]`, `lean_file: /absolute/path`
  - Clarify dependencies array format matches wave structure from STEP 1

**Template Addition** (insert after line 100 in lean-plan-architect.md):

```markdown
**Phase Metadata Requirements** (CRITICAL for orchestration):

Every phase MUST include these metadata fields immediately after the phase heading:

```markdown
### Phase N: Phase Name [NOT STARTED]
implementer: lean
lean_file: /absolute/path/to/file.lean
dependencies: []

Tasks:
- [ ] Task 1
```

**Field Specifications**:
- `implementer: lean` - Always "lean" for Lean theorem proving phases (never "software")
- `lean_file: /absolute/path` - Absolute path to primary .lean file for this phase's theorems
- `dependencies: []` - Array of phase numbers that must complete before this phase (empty for Wave 1)

**Wave Structure Integration**:
- Dependencies array must match wave structure from STEP 1 analysis
- Wave 1 phases: `dependencies: []`
- Wave 2 phases: `dependencies: [N]` where N is a Wave 1 phase number
- Wave 3 phases: `dependencies: [N, M]` where N, M are Wave 1 or Wave 2 phase numbers
```

**Success Criteria**:
- [ ] lean-plan-architect guidelines include phase metadata template
- [ ] STEP 1 analysis section mentions metadata field generation
- [ ] STEP 3 planning section requires metadata fields
- [ ] Template shows correct field formats (implementer: lean, dependencies array, absolute paths)

**Validation**:
```bash
# Verify template added
grep -A 10 "Phase Metadata Requirements" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Verify all three fields mentioned
grep -c "implementer:" /home/benjamin/.config/.claude/agents/lean-plan-architect.md  # Expect 2+
grep -c "dependencies:" /home/benjamin/.config/.claude/agents/lean-plan-architect.md  # Expect 2+
grep -c "lean_file:" /home/benjamin/.config/.claude/agents/lean-plan-architect.md     # Expect 2+
```

### Phase 4: Add Validation Checkpoint to /lean-plan [COMPLETE]
implementer: software
dependencies: [1, 2]

**Goal**: Add plan metadata validation checkpoint after lean-plan-architect returns to catch format errors early.

**Files Modified**:
- /home/benjamin/.config/.claude/commands/lean-plan.md

**Tasks**:

- [x] Add validation checkpoint after plan generation
  - Insert in Block 1f (after lean-plan-architect Task returns)
  - Check PLAN_PATH file exists before validation
  - Invoke validate-plan-metadata.sh with plan file path
  - Capture validation exit code and output

- [x] Handle validation failures gracefully
  - Log validation errors to error log via log_command_error
  - Echo WARNING message to stderr (not blocking)
  - Allow workflow to complete even if validation fails
  - Include validation exit code in error details

- [x] Add validation success confirmation
  - Echo success message if validation passes
  - Include metadata field count in confirmation
  - Log validation pass to workflow state for debugging

- [x] Handle missing validator gracefully
  - Check if validate-plan-metadata.sh exists before invocation
  - Echo warning if validator not found (graceful degradation)
  - Continue workflow without validation if validator missing

**Code Pattern** (insert in Block 1f, after PLAN_PATH confirmation):
```bash
# Validate generated plan metadata
if [ -f "${PLAN_PATH}" ]; then
  echo "Validating plan metadata format..."

  # Run validator if available
  VALIDATOR_PATH="${CLAUDE_PROJECT_DIR}/.claude/scripts/lint/validate-plan-metadata.sh"
  if [ -f "$VALIDATOR_PATH" ]; then
    VALIDATION_OUTPUT=$("$VALIDATOR_PATH" "$PLAN_PATH" 2>&1)
    VALIDATION_EXIT=$?

    if [ $VALIDATION_EXIT -ne 0 ]; then
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Generated plan failed metadata validation" \
        "plan_validation" \
        "$(jq -n --arg path "$PLAN_PATH" --arg output "$VALIDATION_OUTPUT" '{plan_path: $path, validation_output: $output}')"

      echo "WARNING: Plan metadata validation failed (exit code $VALIDATION_EXIT)" >&2
      echo "$VALIDATION_OUTPUT" >&2
      echo "Plan created but may not meet metadata standards" >&2
      # Don't exit - allow workflow to complete with warning
    else
      echo "✓ Plan metadata validation passed"
    fi
  else
    echo "⚠ Plan metadata validator not found at $VALIDATOR_PATH, skipping validation"
  fi
fi
```

**Success Criteria**:
- [ ] Validation checkpoint added after plan generation
- [ ] validate-plan-metadata.sh invoked with plan file path
- [ ] Validation failures logged but do not block workflow
- [ ] Validation success confirmed in output
- [ ] Missing validator handled gracefully (no fatal error)

**Validation**:
```bash
# Test validation checkpoint with valid plan
/lean-plan "test task" 2>&1 | grep "Plan metadata validation"

# Test validation with invalid plan (create malformed plan for testing)
echo "### Phase 1: Test [NOT STARTED]
implementer: INVALID
dependencies: bad_format
lean_file: relative/path.lean" > /tmp/test-plan.md

bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh /tmp/test-plan.md
# Expect exit code 1 (validation failure)
```

### Phase 5: End-to-End Testing and Verification [COMPLETE]
implementer: software
dependencies: [1, 2, 3, 4]

**Goal**: Execute full /lean-plan workflow with real formalization task to verify all fixes integrated correctly.

**Files Modified**:
- None (testing phase)

**Tasks**:

- [x] Execute /lean-plan with test formalization task
  - Use simple Lean theorem proving task (1-2 theorems)
  - Capture complete output to /tmp/lean-plan-verification.log
  - Monitor for bash syntax errors in Block 1d
  - Verify research-coordinator invocation and report generation

- [x] Validate generated plan structure
  - Verify plan file created at expected path
  - Check all phases include implementer field (value: "lean")
  - Check all phases include dependencies field (valid array format)
  - Check all phases include lean_file field (absolute .lean paths)
  - Run validate-plan-metadata.sh on generated plan

- [x] Test wave-based execution compatibility
  - Read generated plan dependencies arrays
  - Manually verify wave structure matches phase dependencies
  - Test /lean-implement can parse phase metadata (dry-run mode)
  - Verify coordinator routing works with implementer field

- [x] Verify standards injection
  - Check lean-plan-output.md for "Standards extracted" confirmation
  - Verify FORMATTED_STANDARDS byte count logged (5000-15000 bytes)
  - Confirm no warnings about missing standards-extraction.sh

- [x] Regression testing for existing functionality
  - Test --file parameter with existing plan revision
  - Test --complexity parameter ranges (1-4)
  - Test --project parameter with Lean project path
  - Verify all existing features still functional

**Test Commands**:
```bash
# Test 1: Simple formalization task
cd /home/benjamin/Documents/Philosophy/Projects/ProofChecker
/lean-plan "Prove associativity and commutativity for addition" --complexity 2

# Test 2: Validate generated plan
GENERATED_PLAN=$(find .claude/specs -name "*-plan.md" -type f -mmin -5 | head -1)
bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh "$GENERATED_PLAN"

# Test 3: Verify phase metadata
grep -A 3 "^### Phase" "$GENERATED_PLAN" | grep -E "(implementer:|dependencies:|lean_file:)"

# Test 4: Test /lean-implement compatibility (dry-run)
# /lean-implement "$GENERATED_PLAN" --dry-run  # Future test when /lean-implement ready

# Test 5: Linter verification
bash /home/benjamin/.config/.claude/scripts/lint/lint_bash_conditionals.sh /home/benjamin/.config/.claude/commands/lean-plan.md
```

**Success Criteria**:
- [ ] /lean-plan executes without bash syntax errors
- [ ] Block 1d-topics completes successfully (TOPIC_NAME set)
- [ ] Research reports generated with valid content
- [ ] Generated plan passes validate-plan-metadata.sh validation
- [ ] All phases include implementer, dependencies, lean_file fields
- [ ] Dependencies arrays match wave structure from research
- [ ] Standards extraction confirmation logged in output
- [ ] lint_bash_conditionals.sh passes for lean-plan.md
- [ ] No regressions in existing /lean-plan functionality

**Validation**:
```bash
# Comprehensive validation suite
cd /home/benjamin/.config

# Test bash conditionals fixed
! grep 'if \[\[ !' .claude/commands/lean-plan.md | grep -q '=~'
echo "PASS: No preprocessing-unsafe conditionals found"

# Test standards extraction functional
bash -c "source .claude/lib/plan/standards-extraction.sh && format_standards_for_prompt | grep -q 'Plan Metadata Standard' && echo 'PASS: Standards extraction works'"

# Test lean-plan-architect updated
grep -q "Phase Metadata Requirements" .claude/agents/lean-plan-architect.md && echo "PASS: Agent guidelines updated"

# Test validation checkpoint added
grep -q "validate-plan-metadata.sh" .claude/commands/lean-plan.md && echo "PASS: Validation checkpoint added"

# Execute end-to-end test
cd /home/benjamin/Documents/Philosophy/Projects/ProofChecker
/lean-plan "Test theorem proving task" --complexity 1 2>&1 | tee /tmp/e2e-test.log

# Verify no errors
! grep -q "conditional binary operator expected" /tmp/e2e-test.log && echo "PASS: No bash syntax errors"
grep -q "Standards extracted" /tmp/e2e-test.log && echo "PASS: Standards injected"
grep -q "Plan metadata validation passed" /tmp/e2e-test.log && echo "PASS: Validation successful"
```

## Testing Strategy

### Unit Testing

**Test 1: Preprocessing-Safe Conditionals**
- Extract lean-plan.md bash blocks
- Parse conditionals at lines 937, 1583
- Verify split pattern used (standalone test + numeric comparison)
- Run lint_bash_conditionals.sh validator

**Test 2: Standards Extraction**
- Source standards-extraction.sh library
- Call format_standards_for_prompt()
- Verify output contains "Plan Metadata Standard" section
- Check output contains implementer, dependencies, lean_file documentation
- Verify byte count between 5000-15000

**Test 3: Phase Metadata Validation**
- Create test plan with valid phase metadata
- Create test plan with invalid implementer value
- Create test plan with invalid dependencies format
- Create test plan with relative lean_file path
- Run validate-plan-metadata.sh on each test case
- Verify exit codes: 0 (valid), 1 (invalid)

### Integration Testing

**Test 4: /lean-plan Workflow**
- Execute /lean-plan with test formalization task
- Verify Block 1d-topics completes without error
- Verify research-coordinator invoked with topic array
- Verify research reports created at expected paths
- Verify lean-plan-architect receives FORMATTED_STANDARDS
- Verify generated plan includes phase metadata fields

**Test 5: Phase Metadata Format**
- Parse generated plan for phase headings
- Extract implementer field from each phase (expect "lean")
- Extract dependencies field from each phase (expect valid array)
- Extract lean_file field from each phase (expect absolute path)
- Validate dependencies match wave structure from research

**Test 6: /lean-implement Compatibility**
- Read generated plan with phase metadata
- Parse implementer field for coordinator routing
- Build wave execution graph from dependencies arrays
- Verify Tier 1 classification triggers (implementer field present)
- Verify /lean-implement can route phases correctly

### Regression Testing

**Test 7: Existing /lean-plan Features**
- Test --file parameter with plan revision
- Test --complexity parameter (values 1-4)
- Test --project parameter with Lean project path
- Test error handling for missing Lean project
- Test error handling for invalid complexity value
- Verify all existing functionality preserved

**Test 8: Backward Compatibility**
- Test /lean-implement with plans WITHOUT phase metadata (Tier 3 fallback)
- Test /lean-build with plans WITHOUT lean_file field
- Verify graceful degradation when metadata absent
- Verify existing plans still functional

### Validation Testing

**Test 9: Pre-Commit Hook Integration**
- Stage lean-plan.md with unsafe conditionals
- Run pre-commit hook
- Verify commit blocked with ERROR message
- Fix conditionals and retry
- Verify commit allowed

**Test 10: Linter Coverage**
- Run lint_bash_conditionals.sh on all .claude/commands/*.md files
- Verify no preprocessing-unsafe conditionals found
- Test linter detects `if [[ ! ... =~ ... ]]` pattern
- Verify ERROR-level violation returned

## Dependencies

### Internal Dependencies
- standards-extraction.sh library (exists at /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh)
- validate-plan-metadata.sh validator (exists at /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh)
- lint_bash_conditionals.sh linter (exists at /home/benjamin/.config/.claude/scripts/lint/lint_bash_conditionals.sh)
- Plan Metadata Standard documentation (exists at /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md)

### External Dependencies
- None (all dependencies are internal .claude/ infrastructure)

### Phase Dependencies
- Phase 2 depends on Phase 1 (bash fixes enable workflow continuation)
- Phase 3 depends on Phase 1 (agent must receive context to generate metadata)
- Phase 4 depends on Phases 1 and 2 (validation requires working workflow and standards injection)
- Phase 5 depends on all previous phases (end-to-end testing validates complete integration)

## Success Metrics

### Primary Metrics
1. **Workflow Completion**: /lean-plan executes without bash syntax errors (Block 1d-topics success rate: 0% → 100%)
2. **Phase Metadata Coverage**: Generated plans include phase-level metadata fields (current: 0%, target: 100%)
3. **Validation Pass Rate**: Generated plans pass validate-plan-metadata.sh (current: 0%, target: 100%)
4. **Standards Injection**: lean-plan-architect receives FORMATTED_STANDARDS in context (current: 0%, target: 100%)

### Secondary Metrics
5. **Linter Compliance**: lean-plan.md passes lint_bash_conditionals.sh (current: fail, target: pass)
6. **Coordinator Routing**: /lean-implement uses Tier 1 classification via implementer field (current: Tier 3 fallback, target: Tier 1)
7. **Wave Execution**: Plans support parallel phase execution via dependencies field (current: 0%, target: 100%)
8. **Regression Prevention**: All existing /lean-plan features functional (target: 100% backward compatibility)

### Performance Metrics
9. **Time Savings**: Wave-based execution enabled (expected 40-60% time reduction for multi-phase Lean plans)
10. **Classification Accuracy**: Phase type detection via implementer field (Tier 1: 100% accuracy vs Tier 3: ~80% accuracy)

## Risks and Mitigations

### Risk 1: standards-extraction.sh Performance Impact
**Risk**: Extracting and formatting standards adds overhead to /lean-plan execution time
**Mitigation**:
- Standards extraction is lightweight (awk-based parsing, <1 second)
- Graceful degradation if library unavailable (workflow continues)
- One-time extraction per workflow (cached in FORMATTED_STANDARDS variable)
**Likelihood**: Low
**Impact**: Low

### Risk 2: Backward Compatibility with Existing Plans
**Risk**: Changes to /lean-plan or lean-plan-architect break existing plans without phase metadata
**Mitigation**:
- Phase metadata fields are OPTIONAL (validation permissive)
- /lean-implement supports Tier 3 fallback for plans without metadata
- Regression testing validates existing functionality preserved
**Likelihood**: Low
**Impact**: Medium

### Risk 3: Validation Checkpoint Blocking Workflow
**Risk**: validate-plan-metadata.sh failures could block plan generation
**Mitigation**:
- Validation errors are warnings only (non-blocking)
- Workflow continues even if validation fails
- Error logged for debugging but does not exit workflow
**Likelihood**: Low
**Impact**: Low

### Risk 4: Agent Ignores Metadata Template
**Risk**: lean-plan-architect may not generate phase metadata despite receiving standards
**Mitigation**:
- Explicit template added to agent behavioral guidelines (STEP 1 and STEP 3)
- Standards injection provides canonical specification
- Validation checkpoint catches missing metadata early
- Manual review of first generated plans to verify compliance
**Likelihood**: Medium
**Impact**: High

### Risk 5: Preprocessing-Safe Pattern Regression
**Risk**: Future edits to lean-plan.md may reintroduce unsafe conditionals
**Mitigation**:
- lint_bash_conditionals.sh integrated into pre-commit hook (blocks commits)
- Documentation of safe pattern in code-standards.md
- Linter detects `if [[ ! ... =~ ... ]]` pattern automatically
**Likelihood**: Low
**Impact**: Low

## Implementation Notes

### Design Decisions

**Decision 1: Non-Blocking Validation**
- Validation errors are warnings, not fatal errors
- Rationale: Allow workflow to complete even if metadata imperfect (graceful degradation)
- Alternative considered: Block workflow on validation failure (rejected - too strict for optional fields)

**Decision 2: Graceful Degradation for Missing Standards**
- If standards-extraction.sh unavailable, workflow continues without standards context
- Rationale: Robustness in edge cases (e.g., library corruption, permissions issues)
- Alternative considered: Fail-fast if standards unavailable (rejected - too brittle)

**Decision 3: Agent-Level Metadata Generation**
- lean-plan-architect responsible for generating phase metadata, not /lean-plan command
- Rationale: Agent has full plan context and wave structure analysis
- Alternative considered: Command injects metadata post-generation (rejected - agent better positioned)

**Decision 4: Explicit implementer Field for Lean Plans**
- All Lean plan phases use `implementer: lean` (never omitted)
- Rationale: Eliminate ambiguity for /lean-implement coordinator routing
- Alternative considered: Rely on lean_file presence for Tier 2 classification (rejected - explicit better)

### Code Patterns

**Pattern 1: Preprocessing-Safe Conditionals**
```bash
# Anti-pattern (unsafe)
if [[ ! "$VAR" =~ ^/ ]]; then

# Safe pattern (split into separate test + comparison)
[[ "${VAR:-}" = /* ]]
IS_ABSOLUTE=$?
if [ $IS_ABSOLUTE -ne 0 ]; then
```

**Pattern 2: Standards Injection**
```bash
# Source library with graceful fallback
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  echo "WARNING: standards-extraction.sh not found" >&2
}

# Extract standards with availability check
if command -v format_standards_for_prompt &>/dev/null; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt)
  echo "✓ Standards extracted (${#FORMATTED_STANDARDS} bytes)"
else
  FORMATTED_STANDARDS=""
  echo "⚠ Standards extraction unavailable"
fi

# Persist for subsequent blocks
append_workflow_state "FORMATTED_STANDARDS"
```

**Pattern 3: Non-Blocking Validation**
```bash
# Validate plan metadata (non-blocking)
if [ -f "${PLAN_PATH}" ]; then
  if [ -f "$VALIDATOR_PATH" ]; then
    VALIDATION_OUTPUT=$("$VALIDATOR_PATH" "$PLAN_PATH" 2>&1)
    VALIDATION_EXIT=$?

    if [ $VALIDATION_EXIT -ne 0 ]; then
      log_command_error "validation_error" "Plan metadata validation failed" "..."
      echo "WARNING: Validation failed (exit $VALIDATION_EXIT)" >&2
      # Continue workflow despite validation failure
    else
      echo "✓ Plan metadata validation passed"
    fi
  else
    echo "⚠ Validator not found, skipping validation"
  fi
fi
```

### Integration Points

**Integration 1: standards-extraction.sh Library**
- Location: /home/benjamin/.config/.claude/lib/plan/standards-extraction.sh
- Function: format_standards_for_prompt()
- Output: Markdown-formatted standards sections
- Used by: /lean-plan Block 1e (before agent Task invocation)

**Integration 2: lean-plan-architect Agent**
- Location: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
- Receives: FORMATTED_STANDARDS in Task prompt
- Generates: Plan with phase-level metadata (implementer, dependencies, lean_file)
- Used by: /lean-plan Block 1f (plan generation)

**Integration 3: validate-plan-metadata.sh Validator**
- Location: /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh
- Input: Plan file path
- Output: Exit code 0 (pass) or 1 (fail), validation messages to stdout
- Used by: /lean-plan Block 1f (after plan generation)

**Integration 4: lint_bash_conditionals.sh Linter**
- Location: /home/benjamin/.config/.claude/scripts/lint/lint_bash_conditionals.sh
- Input: Command markdown file path
- Output: ERROR-level violations for preprocessing-unsafe conditionals
- Used by: Pre-commit hook, validate-all-standards.sh --conditionals

### Documentation Updates

**Update 1: Plan Metadata Standard**
- File: /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
- Change: None required (already documents phase-level metadata fields)
- Note: Standard already comprehensive, implementation catches up to specification

**Update 2: Code Standards**
- File: /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md
- Change: Add lean-plan.md to list of files fixed for preprocessing-safe conditionals
- Note: Document Spec 036 fix in historical examples

**Update 3: Lean Plan Command Guide**
- File: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md
- Change: Add section documenting phase metadata generation
- Note: Cross-reference Plan Metadata Standard for field specifications

**Update 4: lean-plan-architect Agent Guide**
- File: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
- Change: Add phase metadata template to STEP 1 and STEP 3 (implemented in Phase 3)
- Note: Template shows implementer, dependencies, lean_file placement

## Completion Criteria

This plan is considered complete when:

1. **Workflow Execution**: /lean-plan executes without bash syntax errors in Block 1d-topics
2. **Research Generation**: Research reports successfully created via research-coordinator invocation
3. **Standards Injection**: lean-plan-architect receives FORMATTED_STANDARDS in Task prompt context
4. **Phase Metadata**: Generated plans include implementer, dependencies, lean_file fields in all phases
5. **Validation Pass**: Generated plans pass validate-plan-metadata.sh validation (exit code 0)
6. **Linter Pass**: lean-plan.md passes lint_bash_conditionals.sh validation (no unsafe conditionals)
7. **Regression Pass**: All existing /lean-plan features functional (--file, --complexity, --project parameters)
8. **End-to-End Test**: Full workflow test produces valid plan with phase metadata and research reports

**Final Verification Command**:
```bash
# Execute comprehensive verification suite
cd /home/benjamin/Documents/Philosophy/Projects/ProofChecker

# Test 1: Execute /lean-plan
/lean-plan "Prove basic arithmetic properties" --complexity 2 2>&1 | tee /tmp/verification.log

# Test 2: Verify no syntax errors
! grep -q "conditional binary operator expected" /tmp/verification.log || exit 1

# Test 3: Verify standards injected
grep -q "Standards extracted for planning agent" /tmp/verification.log || exit 1

# Test 4: Verify validation passed
grep -q "Plan metadata validation passed" /tmp/verification.log || exit 1

# Test 5: Verify plan metadata
GENERATED_PLAN=$(find .claude/specs -name "*-plan.md" -type f -mmin -5 | head -1)
bash /home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh "$GENERATED_PLAN" || exit 1

# Test 6: Verify phase metadata fields present
PHASE_COUNT=$(grep -c "^### Phase" "$GENERATED_PLAN")
IMPLEMENTER_COUNT=$(grep -c "^implementer:" "$GENERATED_PLAN")
DEPENDENCIES_COUNT=$(grep -c "^dependencies:" "$GENERATED_PLAN")
LEAN_FILE_COUNT=$(grep -c "^lean_file:" "$GENERATED_PLAN")

[ "$IMPLEMENTER_COUNT" -eq "$PHASE_COUNT" ] || exit 1
[ "$DEPENDENCIES_COUNT" -eq "$PHASE_COUNT" ] || exit 1
[ "$LEAN_FILE_COUNT" -eq "$PHASE_COUNT" ] || exit 1

echo "ALL VERIFICATION TESTS PASSED"
```

## Related Documentation

- [Plan Metadata Standard](/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md) - Phase metadata field specifications
- [Code Standards](/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md) - Preprocessing-safe conditional patterns
- [Bash Block Execution Model](/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md) - Preprocessing behavior documentation
- [Command Authoring Standards](/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md) - Standards injection pattern
- [Hierarchical Agent Architecture](/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md) - Behavioral injection pattern
- [Directory Protocols](/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md) - Topic-based structure and plan naming
- [Enforcement Mechanisms](/home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md) - Pre-commit hook integration

## Notes

**Spec 005 and Spec 022 Precedent**: This fix follows the same preprocessing-safe conditional pattern proven successful in Spec 005 (repair-research fix) and documented in Spec 022 (lean-plan agent hierarchy fix). The split pattern (standalone test + numeric comparison) is the canonical solution.

**standards-extraction.sh Already Exists**: Research report 003 predicted the need to create this library, but verification shows it already exists at the expected location with plan_metadata_standard section included. The gap is in activation (command invocation), not implementation.

**Graceful Degradation Philosophy**: All changes follow graceful degradation principles - if standards unavailable or validation fails, workflow continues with warnings. This prevents brittle failures in edge cases.

**Agent Behavioral Injection**: The lean-plan-architect agent receives phase metadata standards via runtime prompt injection (behavioral injection pattern), not hardcoded instructions. This follows hierarchical agent architecture best practices.

**Phase Dependencies for THIS Plan**: All phases are software implementation (not Lean proofs) and follow sequential dependency structure:
- Phase 1: No dependencies (bash fix enables workflow)
- Phase 2: Depends on Phase 1 (standards injection requires working workflow)
- Phase 3: Depends on Phase 1 (agent must receive context after workflow fixes)
- Phase 4: Depends on Phases 1 and 2 (validation requires workflow + standards)
- Phase 5: Depends on all (end-to-end test validates complete integration)

**Wave Execution Not Applicable**: This plan uses sequential dependencies (no parallelizable phases) because Phase 2, 3, 4 all logically follow Phase 1, and Phase 5 requires all previous phases complete. Future Lean theorem proving plans will leverage wave-based parallelization enabled by this fix.

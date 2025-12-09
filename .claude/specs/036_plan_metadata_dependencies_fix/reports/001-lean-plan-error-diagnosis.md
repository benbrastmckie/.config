# Lean Plan Output Error Diagnosis

## Research Overview

**Topic**: Investigate root causes of errors in /lean-plan output generation
**Date**: 2025-12-09
**Context**: Analysis of lean-plan-output.md errors and impact on plan generation workflow

## Executive Summary

The /lean-plan command fails during Block 1d-topics execution with bash conditional syntax error `conditional binary operator expected` at line 247 (line 937 in lean-plan.md source). The error occurs during report path validation where the condition `if [[ ! "$REPORT_FILE" =~ ^/ ]]; then` is being malformed during execution.

**Root Cause**: Bash preprocessing issue with double-bracket conditional containing regex operator within markdown bash blocks. The preprocessor appears to transform the negation operator, causing bash to see malformed syntax.

**Impact**: Complete workflow failure - no research reports generated, no plan created, topic directory created but empty.

## Findings

### Finding 1: Bash Conditional Syntax Error Location

**Observation**: lean-plan-output.md (line 44-50) shows:

```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 2
     /run/current-system/sw/bin/bash: eval: line 247:
     conditional binary operator expected
     /run/current-system/sw/bin/bash: eval: line 247: syntax
     error near `"$REPORT_FILE"'
     /run/current-system/sw/bin/bash: eval: line 247: `  if
     [[ \! "$REPORT_FILE" =~ ^/ ]]; then'
```

**Analysis**: The error message shows `\!` (escaped exclamation) in the conditional, but lean-plan.md:937 contains `if [[ ! "$REPORT_FILE" =~ ^/ ]]; then` (unescaped). This indicates transformation during preprocessing/execution.

**Source Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md:937`

```markdown
  # Validate path is absolute
  if [[ ! "$REPORT_FILE" =~ ^/ ]]; then
    log_command_error \
```

**Evidence**:
- Error occurs at `eval: line 247` during bash block execution
- Command source line 937 maps to execution line 247 after extraction
- Escaped `\!` seen in error but not in source suggests preprocessing issue

### Finding 2: Preprocessing-Unsafe Conditional Pattern

**Pattern Analysis**: The `.claude/docs/reference/standards/code-standards.md` and `.claude/docs/concepts/bash-block-execution-model.md` document "preprocessing-unsafe conditionals" as a known anti-pattern.

**Relevant Standards**:

From `bash-block-execution-model.md`:

> Bash blocks in command markdown files are extracted and evaluated by Claude Code's execution engine. During this extraction, certain bash syntax patterns can be transformed, causing syntax errors.

**Grep Results**: Found 89 instances of similar errors across output files and documentation:

- `.claude/output/research-output.md:24`: `conditional binary operator expected`
- `.claude/specs/022_lean_plan_agent_hierarchy_fix/reports/001-hierarchical-agent-architecture-analysis.md`: Documents identical syntax error in /lean-plan
- `.claude/specs/005_repair_research_20251201_212513/reports/001-research-errors-repair.md:29-30`: Documents same pattern

**Prior Incidents**: Spec 005 and Spec 022 both addressed this exact error in other commands with the solution of splitting conditionals into preprocessing-safe patterns.

### Finding 3: Workflow Execution Blockage

**Impact Cascade**:

1. **Block 1d-topics** fails with syntax error (line 937)
2. **TOPIC_NAME** variable never set
3. **REPORT_PATHS_JSON_PATH** never created
4. **Research phase skipped** (hard barrier validation fails)
5. **Plan generation continues** with incomplete context
6. **Output plan lacks metadata** because no research occurred

**Evidence from lean-plan-output.md**:

- Lines 44-50: Bash error terminates Block 1d-topics
- Lines 54-58: Block 1e continues with "Research Topics Classification" but no actual research invocation
- Lines 60-201: Agent directly creates research report and plan (bypassing research-coordinator)
- Result: Plan at `.claude/specs/053_p6_perpetuity_theorem_derive/plans/001-p6-perpetuity-theorem-derive-plan.md` has NO phase-level metadata

**Verification**: Reading the generated plan confirms missing fields:
- No `implementer:` field in any phase
- No `dependencies:` field in any phase
- No `lean_file:` field in any phase
- Status markers present but metadata absent

### Finding 4: Phase Classification Lost

**Problem**: Without phase-level metadata, the `/lean-implement` command cannot:

1. **Route phases correctly** - No `implementer:` field means Tier 3 keyword fallback (error-prone)
2. **Enable parallelization** - No `dependencies:` field means sequential execution only (40-60% slower)
3. **Associate Lean files** - No `lean_file:` field means manual file detection required

**Example from Generated Plan** (`001-p6-perpetuity-theorem-derive-plan.md:26-59`):

```markdown
### Phase 1: Add Duality Bridge Lemmas [IN PROGRESS]

**Goal**: Add lemmas connecting operator duality transformations needed for P6 derivation.

**Files Modified**:
- Logos/Core/Theorems/Perpetuity.lean

**Tasks**:

- [ ] `theorem_box_sometimes_to_sometimes_box`
  - Goal: `⊢ ¬φ.neg.sometimes.diamond ↔ φ.always.box.neg` (equivalence via duality)
  - Strategy: Use existing duality lemmas + DNE/DNI to transform operators
  - Complexity: Complex
  - Dependencies: []
```

**Missing**:
- `implementer: lean` (phase type)
- `dependencies: []` (wave execution)
- `lean_file: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/Logos/Core/Theorems/Perpetuity.lean` (file association)

**Note**: Task-level `Dependencies: []` exists but phase-level `dependencies:` absent, preventing wave-based orchestration.

### Finding 5: Preprocessing-Safe Conditional Pattern (Solution)

**From Spec 005 Fix** (`.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md:73-79`):

The repair plan for identical errors in /research and /plan commands used this pattern:

```bash
# Anti-pattern (preprocessing-unsafe):
if [[ ! "$TOPIC_NAME_FILE" =~ ^/ ]]; then

# Fixed pattern (preprocessing-safe):
[[ "${TOPIC_NAME_FILE:-}" = /* ]]
IS_ABSOLUTE_PATH=$?
if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
```

**Rationale**:
- Split regex match into standalone test command
- Capture exit code in intermediate variable
- Use simple numeric comparison in conditional

**Verification**: grep shows this pattern used successfully in lean-plan.md at lines 91-95 and 117-120 for --file and --project path validation.

## Recommendations

### Recommendation 1: Fix Bash Conditional at Line 937

**Action**: Replace preprocessing-unsafe conditional with split-pattern approach

**Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md:937`

**Change**:

```bash
# Current (line 937):
if [[ ! "$REPORT_FILE" =~ ^/ ]]; then

# Fixed:
[[ "${REPORT_FILE:-}" = /* ]]
IS_ABSOLUTE_REPORT_PATH=$?
if [ $IS_ABSOLUTE_REPORT_PATH -ne 0 ]; then
```

**Testing**: After fix, verify Block 1d-topics executes without syntax error.

### Recommendation 2: Audit All Double-Bracket Conditionals in lean-plan.md

**Scope**: Search entire lean-plan.md for `if [[ ! ` pattern

**Method**:

```bash
grep -n 'if \[\[ !' /home/benjamin/.config/.claude/commands/lean-plan.md
```

**Action**: Convert all instances to preprocessing-safe split pattern

**Expected Findings**: 1-3 additional instances requiring conversion

### Recommendation 3: Enable Phase Metadata Generation in lean-plan-architect

**Problem**: The lean-plan-architect agent generates plans without phase-level metadata fields

**Root Cause**: Agent behavioral guidelines or prompt injection may not include phase metadata requirements

**Solution Path**:
1. Review `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`
2. Verify Plan Metadata Standard integration (via `format_standards_for_prompt()`)
3. Add explicit phase metadata template to agent guidelines
4. Include example phase with all three fields (implementer, dependencies, lean_file)

**Validation**: After fix, generated plans should include phase metadata automatically

### Recommendation 4: Add Linter Rule for Preprocessing-Unsafe Conditionals

**Tool**: `.claude/scripts/lint/lint_bash_conditionals.sh` (already exists per grep results)

**Enhancement**: Ensure linter catches `if [[ ! ... =~ ... ]]` pattern specifically

**Integration**: Verify pre-commit hook runs this linter on `.claude/commands/*.md` files

**Enforcement**: ERROR-level violation blocks commits

### Recommendation 5: Test Full Workflow After Fix

**Test Plan**:

1. Apply Recommendation 1 fix to lean-plan.md:937
2. Run `/lean-plan "test formalization task"`
3. Verify:
   - Block 1d-topics completes without error
   - TOPIC_NAME variable set correctly
   - Research-coordinator invoked with topic array
   - Research reports created with valid content
   - Plan includes phase-level metadata (implementer, dependencies, lean_file)
   - Plan file passes `validate-plan-metadata.sh` validation

**Success Criteria**:
- Zero bash syntax errors in lean-plan-output.md
- Research reports created at expected paths
- Plan metadata includes all phase-level fields
- /lean-implement can parse phase metadata correctly

## Related Issues

### Issue 1: Spec 022 Documented Same Error

**Reference**: `.claude/specs/022_lean_plan_agent_hierarchy_fix/reports/001-hierarchical-agent-architecture-analysis.md:130-131`

**Context**: Previous fix attempt for /lean-plan but error persists, indicating incomplete fix or regression

**Investigation Needed**: Compare Spec 022 fix with current lean-plan.md to determine if:
- Fix was never applied
- Fix was reverted inadvertently
- Fix was incomplete (only some conditionals fixed)

### Issue 2: Multiple Commands Affected

**Pattern**: Same preprocessing-unsafe conditional appears across multiple commands:

- `/research` - Fixed in Spec 005
- `/plan` - Fixed in Spec 005
- `/lean-plan` - NOT YET FIXED (this analysis)
- `/repair` - May have same issue (grep found error in output)

**Systematic Fix**: Create unified linter rule and audit all commands

## Validation Checklist

After implementing recommendations:

- [ ] lean-plan.md:937 uses preprocessing-safe conditional pattern
- [ ] Block 1d-topics executes without bash syntax errors
- [ ] TOPIC_NAME variable set correctly after Block 1d
- [ ] research-coordinator invoked with topic array (not skipped)
- [ ] Research reports created at pre-calculated paths
- [ ] Generated plan includes phase-level metadata fields
- [ ] Linter detects preprocessing-unsafe conditionals in commands
- [ ] Pre-commit hook blocks commits with unsafe conditionals

## Conclusion

The /lean-plan command failure is caused by a preprocessing-unsafe bash conditional at line 937 using `if [[ ! "$VAR" =~ ^/ ]]` syntax. This pattern has been identified and fixed in other commands (Spec 005) but not yet applied to /lean-plan. The fix is straightforward (split into separate test + numeric comparison) and has proven successful in prior implementations. Additionally, the generated plan lacks phase-level metadata because the workflow terminates before reaching the planning phase properly, causing downstream integration issues with /lean-implement's wave-based orchestration.

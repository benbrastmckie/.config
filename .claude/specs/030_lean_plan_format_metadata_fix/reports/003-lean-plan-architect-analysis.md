# Lean Plan Architect Behavioral File Analysis

## Research Topic
Analyze /home/benjamin/.config/.claude/agents/lean-plan-architect.md to identify instructions producing incorrect format and determine modifications needed to match plan-architect.md output.

## Date
2025-12-08

## Summary
Analysis of lean-plan-architect.md behavioral file reveals critical format discrepancies compared to plan-architect.md standard. The primary issues are incorrect phase heading level (### vs ##), missing implementer field placement, and incomplete metadata validation instructions.

---

## Key Findings

### 1. Phase Heading Format Discrepancy

**Issue**: lean-plan-architect.md specifies **### Phase N:** (level 3 heading) while the actual output shows **## Phase N:** (level 2 heading).

**Evidence from lean-plan-architect.md**:
- **Line 203**: `### Phase 1: [Theorem Category Name] [NOT STARTED]`
- **Line 256**: "ALL phase headings MUST use `### Phase N:` format (level 3, matching /create-plan standard)"
- **Line 391**: `### Phase N: [Category Name] [NOT STARTED]` (in template)
- **Line 423**: `### Phase 1: Basic Commutativity Properties [NOT STARTED]` (in example)

**Comparison with plan-architect.md**:
- **Line 545-560**: Shows correct format `### Phase N: Name [NOT STARTED]` (level 3)
- plan-architect.md correctly specifies level 3 headings throughout

**Root Cause**: The instructions at line 256 explicitly state "matching /create-plan standard" and consistently use level 3 headings in templates, but the actual implementation is producing level 2 headings. This suggests either:
1. The agent is not following the template format exactly
2. There's a conflicting instruction elsewhere overriding the template
3. The agent is misinterpreting the heading level syntax

**Recommended Fix**:
```markdown
# At line 256, strengthen the directive:
- OLD: "ALL phase headings MUST use `### Phase N:` format (level 3, matching /create-plan standard)"
- NEW: "CRITICAL: ALL phase headings MUST use exactly three hash marks: `### Phase N:` (level 3 heading, NOT ## which is level 2). This matches /create-plan standard and ensures parse compatibility with /lean-implement."
```

---

### 2. Implementer Field Format Issue

**Issue**: The `implementer:` field placement and format instructions are unclear compared to plan-architect.md.

**Evidence from lean-plan-architect.md**:
- **Line 204**: Shows `implementer: lean` AFTER the phase heading, but placement relative to other fields is ambiguous
- **Line 242**: "The `implementer:` field appears immediately after the phase heading, before `lean_file:` and `dependencies:`"
- **Line 258**: Lists `implementer:` field as required but doesn't emphasize strict ordering

**Comparison with plan-architect.md**:
- plan-architect.md doesn't have an `implementer:` field concept (it's Lean-specific)
- However, plan-architect.md has clear field ordering for other metadata (line 545-560)

**Root Cause**: The instructions specify the field order but don't make it a CRITICAL requirement with validation checks. The actual output may vary field order.

**Recommended Fix**:
```markdown
# At line 242, add validation emphasis:
- OLD: "The `implementer:` field appears immediately after the phase heading, before `lean_file:` and `dependencies:`"
- NEW: "CRITICAL FIELD ORDER: Each phase MUST have fields in this EXACT order:
  1. Phase heading (### Phase N: Name [NOT STARTED])
  2. implementer: [lean|software]
  3. lean_file: /absolute/path (for lean phases)
  4. dependencies: [...]

  VIOLATION of this order will cause /lean-implement parser failures."
```

---

### 3. Metadata Validation Missing

**Issue**: lean-plan-architect.md lacks the comprehensive metadata validation that plan-architect.md includes.

**Evidence from plan-architect.md**:
- **Lines 208-223**: Includes bash validation script for metadata compliance
- **Lines 224-241**: Detailed required metadata fields with format specifications
- **Lines 1178-1204**: Verification commands that MUST EXECUTE before returning

**Evidence from lean-plan-architect.md**:
- **Lines 276-345**: Has verification section but NO automated validation script
- **Line 290-331**: Has manual verification checklist but no enforced script execution

**Root Cause**: lean-plan-architect.md relies on manual verification instead of automated validation, making it easy to skip metadata compliance checks.

**Recommended Fix**:
```markdown
# At line 290 (in STEP 3 verification), add before "Lean-Specific Verification":

**Metadata Validation** (MANDATORY):
After creating the plan, validate metadata compliance using the validation script:

```bash
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_PATH" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Plan metadata validation failed"
  echo "See validation output above for specific issues"
  exit 1
fi

echo "✓ Metadata validation passed"
```

**Required Metadata Fields** (see [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md)):
- **Date**: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)`
- **Feature**: One-line description (50-100 chars)
- **Status**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, or `[BLOCKED]`
- **Estimated Hours**: `{low}-{high} hours` (numeric range with "hours" suffix)
- **Standards File**: Absolute path (provided in prompt)
- **Research Reports**: Markdown links with relative paths or `none`
- **Lean File**: Absolute path to .lean file (Lean-specific)
- **Lean Project**: Absolute path to lakefile.toml location (Lean-specific)
```

---

### 4. Phase Routing Summary Table

**Issue**: The Phase Routing Summary table format is specified but not validated.

**Evidence from lean-plan-architect.md**:
- **Lines 178-196**: Specifies Phase Routing Summary table format
- **Line 195**: "This summary enables /lean-implement to route phases to appropriate implementer agents upfront."

**Analysis**: This section is correct and unique to lean-plan-architect.md. No changes needed, but validation should confirm table presence.

**Recommended Enhancement**:
```markdown
# At line 318 (in verification section), add:

**Phase Routing Summary Validation**:
```bash
# Check for Phase Routing Summary table
grep -q "### Phase Routing Summary" "$PLAN_PATH" || echo "WARNING: Missing Phase Routing Summary table"

# Validate table format (must have header and at least one phase row)
TABLE_ROWS=$(sed -n '/### Phase Routing Summary/,/^$/p' "$PLAN_PATH" | grep -c "^|" || echo 0)
[ "$TABLE_ROWS" -ge 2 ] || echo "WARNING: Phase Routing Summary table incomplete ($TABLE_ROWS rows)"
```
```

---

### 5. Dependency Syntax Format

**Issue**: The dependency syntax is correct but not strongly enforced.

**Evidence from lean-plan-architect.md**:
- **Line 249**: "Dependencies MUST use `dependencies: [...]` format for wave execution"
- **Line 264**: Shows `dependencies: [list of prerequisite phase numbers, or empty list]`

**Comparison with plan-architect.md**:
- plan-architect.md has similar wording at line 989-994 but includes cross-reference to parallel execution documentation

**Root Cause**: Both files correctly specify dependency syntax, no issue found here.

**No fix needed** - format is correct.

---

## Specific Line Numbers and Text Changes Required

### Change 1: Phase Heading Format Clarification
**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
**Line**: 256
**Old Text**:
```markdown
- ALL phase headings MUST use `### Phase N:` format (level 3, matching /create-plan standard)
```
**New Text**:
```markdown
- CRITICAL: ALL phase headings MUST use exactly three hash marks: `### Phase N:` (level 3 heading, NOT ## which is level 2). This matches /create-plan standard and ensures parse compatibility with /lean-implement. Example: `### Phase 1: Foundation [NOT STARTED]` (correct) vs `## Phase 1: ...` (WRONG)
```

---

### Change 2: Implementer Field Order Enforcement
**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
**Line**: 242
**Old Text**:
```markdown
**Implementer Field Values**:
- Use `implementer: lean` for theorem-proving phases (phases with `lean_file:` field and theorem lists)
- Use `implementer: software` for infrastructure phases (tooling setup, test harness, documentation)
- The `implementer:` field appears immediately after the phase heading, before `lean_file:` and `dependencies:`
```
**New Text**:
```markdown
**Implementer Field Values and CRITICAL Field Order**:
- Use `implementer: lean` for theorem-proving phases (phases with `lean_file:` field and theorem lists)
- Use `implementer: software` for infrastructure phases (tooling setup, test harness, documentation)

**MANDATORY FIELD ORDER** (parser enforced):
Each phase MUST have fields in this EXACT sequence:
1. Phase heading: `### Phase N: Name [NOT STARTED]` (level 3, three hashes)
2. `implementer: lean` OR `implementer: software` (no other values allowed)
3. `lean_file: /absolute/path` (for lean phases only, software phases omit this)
4. `dependencies: [...]` (always present, use `[]` for no dependencies)

**WRONG ORDER EXAMPLE** (will cause parser failure):
```markdown
### Phase 1: Basics [NOT STARTED]
dependencies: []
implementer: lean  # WRONG: implementer must come before dependencies
lean_file: /path/file.lean
```

**CORRECT ORDER EXAMPLE**:
```markdown
### Phase 1: Basics [NOT STARTED]
implementer: lean  # Correct: first field after heading
lean_file: /path/file.lean  # Second field (for lean phases)
dependencies: []  # Third field (always last)
```
```

---

### Change 3: Add Metadata Validation Script
**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
**Line**: Insert at line 290 (before "**Lean-Specific Verification**:")
**New Section**:
```markdown
**Metadata Validation** (MANDATORY - Execute Before Lean-Specific Checks):
After creating the plan, validate metadata compliance using the validation script:

```bash
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_PATH" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Plan metadata validation failed"
  echo "See validation output above for specific issues"
  exit 1
fi

echo "✓ Metadata validation passed"
```

**Required Metadata Fields** (see [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md)):
- **Date**: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)`
- **Feature**: One-line description (50-100 chars)
- **Status**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, or `[BLOCKED]`
- **Estimated Hours**: `{low}-{high} hours` (numeric range with "hours" suffix)
- **Standards File**: Absolute path (provided in prompt)
- **Research Reports**: Markdown links with relative paths or `none`
- **Lean File**: Absolute path to .lean file (Lean-specific required)
- **Lean Project**: Absolute path to lakefile.toml location (Lean-specific required)

**Lean-Specific Verification**:
```

---

### Change 4: Add Phase Routing Summary Validation
**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
**Line**: Insert at line 318 (in theorem count validation section)
**New Section**:
```markdown

**Phase Routing Summary Validation**:
```bash
# Check for Phase Routing Summary table (required after "## Implementation Phases" heading)
grep -q "### Phase Routing Summary" "$PLAN_PATH" || {
  echo "ERROR: Missing Phase Routing Summary table"
  echo "This table is required for /lean-implement to route phases correctly"
  exit 1
}

# Validate table format (must have header row and at least one data row)
TABLE_ROWS=$(sed -n '/### Phase Routing Summary/,/^$/p' "$PLAN_PATH" | grep -c "^|" || echo 0)
if [ "$TABLE_ROWS" -lt 2 ]; then
  echo "ERROR: Phase Routing Summary table incomplete ($TABLE_ROWS rows, need ≥2)"
  exit 1
fi

echo "✓ Phase Routing Summary table valid"
```
```

---

### Change 5: Strengthen Heading Level in Template
**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
**Line**: 391 (Theorem Phase Format Template heading)
**Old Text**:
```markdown
## Theorem Phase Format Template

Use this template for each phase:

```markdown
### Phase N: [Category Name] [NOT STARTED]
```
**New Text**:
```markdown
## Theorem Phase Format Template

Use this template for each phase (NOTE: heading is level 3 - three hashes ###):

```markdown
### Phase N: [Category Name] [NOT STARTED]
```

**CRITICAL**: The phase heading above uses THREE hash marks (###) for level 3 heading.
- CORRECT: `### Phase 1: ...` (level 3)
- WRONG: `## Phase 1: ...` (level 2 - DO NOT USE)

The level 3 format is required for /lean-implement parser compatibility.
```

---

### Change 6: Update Self-Verification Checklist
**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
**Line**: 334-343 (Self-Verification Checklist section)
**Old Text**:
```markdown
**Self-Verification Checklist**:
- [ ] Plan file created at exact PLAN_PATH provided in prompt
- [ ] File contains all required sections
- [ ] Research reports listed in metadata
- [ ] **Lean File** metadata field present (absolute path)
- [ ] **Lean Project** metadata field present (absolute path)
- [ ] All theorems have Goal specifications (Lean 4 types)
- [ ] All theorems have Strategy specifications
- [ ] All theorems have Complexity assessments
- [ ] Dependency graph is acyclic (no circular dependencies)
- [ ] Phase dependencies use `dependencies: [...]` format
```
**New Text**:
```markdown
**Self-Verification Checklist**:
- [ ] Plan file created at exact PLAN_PATH provided in prompt
- [ ] File contains all required sections
- [ ] Metadata validation script executed and passed (EXIT_CODE=0)
- [ ] Research reports listed in metadata
- [ ] **Lean File** metadata field present (absolute path)
- [ ] **Lean Project** metadata field present (absolute path)
- [ ] Phase Routing Summary table present and valid (≥2 rows)
- [ ] ALL phase headings use level 3 format: `### Phase N:` (three hashes, not two)
- [ ] ALL phases have `implementer:` field immediately after heading
- [ ] ALL phases have correct field order: heading → implementer → lean_file → dependencies
- [ ] All theorems have Goal specifications (Lean 4 types)
- [ ] All theorems have Strategy specifications
- [ ] All theorems have Complexity assessments
- [ ] Dependency graph is acyclic (no circular dependencies)
- [ ] Phase dependencies use `dependencies: [...]` format
```

---

## Root Cause Analysis

### Primary Issue: Ambiguous Format Specification
The lean-plan-architect.md file correctly specifies level 3 headings (`### Phase N:`) in templates and examples, but the instructions are not emphatic enough to prevent level 2 heading usage. The phrase "matching /create-plan standard" at line 256 assumes the agent knows the standard, rather than being explicit.

### Secondary Issue: Missing Enforcement
Unlike plan-architect.md (which has validation commands at lines 1178-1204), lean-plan-architect.md lacks automated validation scripts that would catch format violations before the plan is finalized.

### Tertiary Issue: Field Order Not Parser-Critical
The implementer/lean_file/dependencies field order is specified but not marked as "PARSER-CRITICAL", making it seem optional rather than mandatory for /lean-implement compatibility.

---

## Recommended Action Plan

### Immediate Fixes (High Priority)
1. **Change 1**: Clarify phase heading format with explicit "three hashes" instruction
2. **Change 2**: Make field order enforcement explicit with "parser enforced" warning
3. **Change 3**: Add metadata validation script execution requirement

### Secondary Fixes (Medium Priority)
4. **Change 4**: Add Phase Routing Summary validation script
5. **Change 5**: Strengthen template heading format with visual comparison
6. **Change 6**: Update self-verification checklist with format checks

### Validation Enhancements (Low Priority)
7. Add verification command to count phase heading levels and error if any use level 2
8. Add verification to check implementer field is always on line 2 after phase heading

---

## Testing Recommendations

After implementing fixes, test with:

1. **Format Compliance Test**: Create a lean plan and verify:
   - All phase headings use `### Phase N:` (level 3)
   - All phases have implementer field on line 2
   - Field order is heading → implementer → lean_file → dependencies
   - Metadata validation script passes

2. **Parser Compatibility Test**:
   - Feed generated plan to /lean-implement parser
   - Verify phase extraction works correctly
   - Verify implementer routing works as expected

3. **Negative Test**:
   - Manually create plan with level 2 headings (`## Phase N:`)
   - Verify validation catches the error
   - Manually create plan with wrong field order
   - Verify validation catches the error

---

## Conclusion

The lean-plan-architect.md behavioral file has correct format specifications in templates and examples, but lacks enforcement mechanisms and explicit warnings that would prevent format violations. The recommended fixes add:

1. **Explicit clarity**: "three hashes" instead of "level 3"
2. **Parser enforcement warnings**: Make it clear violations break /lean-implement
3. **Automated validation**: Add script execution requirements like plan-architect.md
4. **Enhanced checklists**: Include format checks in verification

These changes will align lean-plan-architect.md with plan-architect.md's validation rigor while maintaining Lean-specific requirements.

---

## Implementation Status
- **Status**: Research Complete
- **Plan**: [Will be updated by plan-architect]
- **Date**: 2025-12-08

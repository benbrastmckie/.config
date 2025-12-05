# Lean Plan Output Formatting Standardization Research

## Research Metadata
- **Date**: 2025-12-04
- **Researcher**: research-specialist agent
- **Research Type**: comparative-analysis
- **Complexity**: 3
- **Topic**: Standardize /lean-plan output formatting to match /create-plan standards

## Executive Summary

The /lean-plan command currently produces plans with inconsistent heading levels (using `##` for phases instead of `###`) and includes Lean-specific metadata fields (`**Lean File**`, `**Lean Project**`) that are not part of the standard plan metadata schema. This research analyzes the formatting differences between /lean-plan and /create-plan outputs and identifies the standardization requirements.

**Key Findings**:
1. Phase heading level mismatch: /lean-plan uses `##` while /create-plan uses `###`
2. Lean-specific metadata fields are valid workflow extensions (not violations)
3. Both commands properly include `[NOT STARTED]` status markers
4. /create-plan metadata order is standardized (plan-architect.md compliance)
5. /lean-plan must align phase heading format to enable /implement parsing compatibility

**Recommendation**: Update lean-plan-architect.md STEP 2 to mandate `### Phase N:` format (level 3) matching create-plan standard, while preserving valid Lean-specific metadata fields.

## 1. Current /lean-plan Output Format

### Phase Heading Format (ISSUE)

**Current format** (from lean-plan-architect.md lines 325-351):
```markdown
### Phase N: [Category Name] [NOT STARTED]
lean_file: /absolute/path/to/file.lean
dependencies: [list of prerequisite phase numbers, or empty list]
```

**Status**: CORRECT - Uses `### Phase N:` (level 3 heading)

### Metadata Format

**Current format** (from lean-plan-architect.md lines 126-140):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Status**: [NOT STARTED]
- **Estimated Hours**: [low]-[high] hours
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**:
  - [Link to Mathlib research report](../reports/001-name.md)
  - [Link to proof patterns report](../reports/002-name.md)
- **Lean File**: [Absolute path to .lean file for Tier 1 discovery]
- **Lean Project**: [Absolute path to lakefile.toml location]
```

**Analysis**:
- Includes standard metadata fields (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- Adds Lean-specific fields (**Lean File**, **Lean Project**) - valid per Plan Metadata Standard
- Follows Plan Metadata Standard for required fields (lines 224-230 from plan-architect.md)
- Uses proper field format with bold labels and colons

### Theorem Specification Format (Lean-Specific)

**Current format** (from lean-plan-architect.md lines 154-168):
```markdown
**Theorems**:
- [ ] `theorem_name_1`: [Brief description]
  - Goal: `∀ a b : Type, property a b`  # Lean 4 type signature
  - Strategy: Use `Mathlib.Theorem.Name` via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours
```

**Analysis**:
- Lean-specific extension to standard task format
- Uses standard checkbox format `- [ ]` (required by /implement)
- Adds nested metadata for theorem proving (Goal, Strategy, Complexity)
- Proper indentation for nested fields

## 2. Reference /create-plan Output Format

### Phase Heading Format (REFERENCE STANDARD)

**Reference format** (from plan-architect.md lines 959-990):
```markdown
### Phase 1: Foundation [NOT STARTED]
dependencies: []

**Objective**: [Goal]
**Complexity**: Low

Tasks:
- [ ] Task 1 (file: path/to/file.ext)
- [ ] Task 2

Testing:
```bash
# Test command
:TestFile
```

**Expected Duration**: X hours
```

**Status**: STANDARD - Uses `### Phase N:` (level 3 heading)

### Metadata Format (REFERENCE STANDARD)

**Reference format** (from plan-architect.md lines 923-936 and create-plan.md lines 1228-1243):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [Name]
- **Scope**: [Brief description]
- **Estimated Phases**: [N]
- **Estimated Hours**: [H]
- **Standards File**: /path/to/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
  - [Report 1 Title](../reports/001_report_name.md)
  - [Report 2 Title](../reports/002_report_name.md)
```

**Key Differences from /lean-plan**:
1. Includes optional **Scope** field (recommended for complex plans)
2. Includes **Estimated Phases** field (informational)
3. Lists **Status** AFTER **Standards File** (field order difference)
4. Does NOT include workflow-specific fields like **Lean File**

### Metadata Field Order

**From create-plan.md Task prompt** (lines 1228-1243):
```markdown
1. Metadata Status Field:
   - MUST be exactly: **Status**: [NOT STARTED]
   - Do NOT use [IN PROGRESS], [COMPLETE], or [BLOCKED]

...

5. Metadata Field Restriction:
   - Only use standard metadata fields from plan-architect.md template
   - Do NOT add workflow-specific fields (e.g., **Lean File**)
   - Required fields: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
```

**Analysis**: create-plan.md explicitly prohibits workflow-specific fields, BUT Plan Metadata Standard (plan-metadata-standard.md) allows workflow-specific extensions.

## 3. Plan Metadata Standard Analysis

### Required Metadata Fields

**From Plan Metadata Standard** (.claude/docs/reference/standards/plan-metadata-standard.md):

**Required Fields** (ERROR if missing):
1. **Date**: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)`
2. **Feature**: One-line description (50-100 chars)
3. **Status**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]`
4. **Estimated Hours**: `{low}-{high} hours` (numeric range)
5. **Standards File**: Absolute path to CLAUDE.md
6. **Research Reports**: Markdown links with relative paths or `none`

**Optional Recommended Fields**:
- **Scope**: Multi-line description (recommended for complex plans)
- **Complexity Score**: Numeric value from complexity calculation
- **Structure Level**: `0`, `1`, or `2`
- **Estimated Phases**: Phase count from initial analysis

**Workflow-Specific Fields** (explicitly allowed):
- /repair plans: **Error Log Query**, **Errors Addressed**
- /revise plans: **Original Plan**, **Revision Reason**
- **Lean-specific plans**: **Lean File**, **Lean Project** (valid extensions)

**Analysis**: The Plan Metadata Standard explicitly permits workflow-specific metadata fields. The create-plan.md restriction is specific to that command's agent prompt, NOT a global prohibition.

### Field Order Standards

**No mandated order** - Plan Metadata Standard does not specify required field ordering. Recommended order:
1. Date
2. Feature
3. Scope (optional)
4. Status
5. Estimated Hours
6. Standards File
7. Research Reports
8. Workflow-specific fields (Lean File, Lean Project, etc.)

## 4. Formatting Differences Summary

### Phase Heading Format

| Command | Current Format | Standard Format | Status |
|---------|----------------|-----------------|--------|
| /lean-plan | `### Phase N:` (level 3) | `### Phase N:` (level 3) | ✅ CORRECT |
| /create-plan | `### Phase N:` (level 3) | `### Phase N:` (level 3) | ✅ CORRECT |

**Conclusion**: NO ISSUE - Both commands use `### Phase N:` format correctly.

**NOTE**: Original issue description claimed /lean-plan uses `##` (level 2), but lean-plan-architect.md template shows `###` (level 3) at lines 325, 357. The architectural documentation is CORRECT. If actual output uses `##`, it's an agent compliance issue, not a template issue.

### Metadata Fields Comparison

| Field | /lean-plan | /create-plan | Required? | Notes |
|-------|------------|--------------|-----------|-------|
| Date | ✅ | ✅ | Yes | Standard format |
| Feature | ✅ | ✅ | Yes | One-line description |
| Status | ✅ | ✅ | Yes | [NOT STARTED] for new plans |
| Estimated Hours | ✅ | ✅ | Yes | Numeric range with "hours" |
| Standards File | ✅ | ✅ | Yes | Absolute path |
| Research Reports | ✅ | ✅ | Yes | Relative paths or "none" |
| Scope | ❌ | ✅ (optional) | No | Recommended for complex plans |
| Estimated Phases | ❌ | ✅ (optional) | No | Informational |
| Complexity Score | ❌ | ✅ (optional) | No | From complexity calculation |
| Structure Level | ❌ | ✅ (optional) | No | 0, 1, or 2 |
| **Lean File** | ✅ | ❌ | No (Lean-specific) | Valid workflow extension |
| **Lean Project** | ✅ | ❌ | No (Lean-specific) | Valid workflow extension |

**Conclusion**:
- All REQUIRED fields present in both commands
- /create-plan includes more OPTIONAL fields (good practice but not mandatory)
- /lean-plan Lean-specific fields are VALID per Plan Metadata Standard
- No violations detected

### Field Order Comparison

**Current /lean-plan order** (from lean-plan-architect.md lines 126-140):
1. Date
2. Feature
3. Status
4. Estimated Hours
5. Standards File
6. Research Reports
7. **Lean File**
8. **Lean Project**

**Reference /create-plan order** (from plan-architect.md lines 923-936):
1. Date
2. Feature
3. Scope (optional)
4. Estimated Phases (optional)
5. Estimated Hours
6. Standards File
7. Status
8. Research Reports

**Difference**: /create-plan lists Status AFTER Standards File, /lean-plan lists Status BEFORE Estimated Hours.

**Recommendation**: Adopt /create-plan field order for consistency:
1. Date
2. Feature
3. Scope (optional - add for Lean plans)
4. Status
5. Estimated Hours
6. Standards File
7. Research Reports
8. Lean-specific fields (Lean File, Lean Project)

## 5. Agent Behavioral File Analysis

### lean-plan-architect.md Compliance

**Phase Heading Format** (lines 189-195):
```markdown
**CRITICAL FORMAT REQUIREMENTS FOR NEW PLANS**:
- Metadata **Status** MUST be `[NOT STARTED]` (not [IN PROGRESS] or [COMPLETE])
- ALL phase headings MUST use `### Phase N:` format (level 3, matching /create-plan standard)
- ALL phases MUST have `lean_file:` field immediately after heading (Tier 1 format)
- ALL phase headings MUST include `[NOT STARTED]` marker
```

**Analysis**: lean-plan-architect.md ALREADY mandates `### Phase N:` format (level 3) matching /create-plan standard (line 191). The documentation is CORRECT.

**Metadata Format** (lines 126-140):
```markdown
3. **Include Lean-Specific Metadata**:
   ## Metadata
   - **Date**: YYYY-MM-DD
   - **Feature**: [One-line formalization description]
   - **Status**: [NOT STARTED]
   - **Estimated Hours**: [low]-[high] hours
   - **Standards File**: [Absolute path to CLAUDE.md]
   - **Research Reports**: ...
   - **Lean File**: [Absolute path to .lean file for Tier 1 discovery]
   - **Lean Project**: [Absolute path to lakefile.toml location]
```

**Issues Identified**:
1. Field order differs from /create-plan reference (Status before Estimated Hours)
2. Missing optional recommended fields (Scope, Estimated Phases, Complexity Score)

### plan-architect.md Reference Template

**Standard Template** (lines 923-936):
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [Name]
- **Scope**: [Brief description]
- **Estimated Phases**: [N]
- **Estimated Hours**: [H]
- **Standards File**: /path/to/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
  - [Report 1 Title](../reports/001_report_name.md)
```

**Analysis**: Standard template includes Scope, Estimated Phases, and Status AFTER Standards File.

## 6. Recommended Formatting Changes

### Change 1: Standardize Metadata Field Order

**Current** (lean-plan-architect.md lines 126-140):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Status**: [NOT STARTED]
- **Estimated Hours**: [low]-[high] hours
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**: ...
- **Lean File**: [Absolute path]
- **Lean Project**: [Absolute path]
```

**Recommended** (align with /create-plan order):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Scope**: [Brief description of formalization goal and mathematical context]
- **Status**: [NOT STARTED]
- **Estimated Hours**: [low]-[high] hours
- **Complexity Score**: [Numeric complexity from calculation]
- **Structure Level**: 0
- **Estimated Phases**: [N]
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**: ...
- **Lean File**: [Absolute path to .lean file for Tier 1 discovery]
- **Lean Project**: [Absolute path to lakefile.toml location]
```

**Changes**:
1. Add **Scope** field after Feature (recommended for Lean plans explaining mathematical context)
2. Move **Status** after Scope (align with /create-plan order)
3. Add **Complexity Score** field (from complexity calculation, informational)
4. Add **Structure Level** field (always 0 for Lean plans, progressive expansion not used)
5. Add **Estimated Phases** field (from STEP 1 analysis, informational)
6. Move **Standards File** BEFORE Research Reports (align with /create-plan order)
7. Keep Lean-specific fields at end (workflow extension convention)

### Change 2: Enhance Scope Field Documentation

**Add to lean-plan-architect.md STEP 2**:

```markdown
**Scope Field for Lean Plans**:
The Scope field should provide mathematical context for formalization:
- Mathematical area (algebra, topology, category theory, etc.)
- Theorem category (group theory, ring theory, etc.)
- Formalization approach (blueprint-based, interactive, etc.)
- Expected output (proven theorems count, library modules)

Example:
- **Scope**: Formalize group homomorphism preservation properties in abstract algebra. Blueprint-based approach proving 12 theorems about identity preservation, inverse preservation, and composition. Output: ProofChecker/GroupHom.lean module with complete proofs.
```

### Change 3: Update Phase Heading Validation

**No change needed** - lean-plan-architect.md already mandates `### Phase N:` format at line 191.

**Verification needed**: Check actual /lean-plan output to confirm agents are following template. If agents output `##` instead of `###`, it's an agent compliance issue requiring agent behavioral file enforcement update.

## 7. Impact Analysis

### Breaking Changes

**None** - All changes are additive:
- Adding optional metadata fields (Scope, Complexity Score, etc.)
- Reordering metadata fields (non-breaking for parsers)
- Phase heading format already correct in template

### Compatibility Impact

**Plan Parsing** (/implement, /lean-build):
- Field order changes are safe (parsers use field labels, not order)
- Adding optional fields is safe (parsers ignore unknown fields)
- Phase heading format unchanged (already correct)

**Agent Behavioral Files**:
- lean-plan-architect.md: Update STEP 2 metadata template (lines 126-140)
- plan-architect.md: No changes needed (reference template)
- lean-research-specialist.md: No changes needed (research phase)

### Performance Impact

**None** - Formatting changes have no runtime impact.

## 8. Implementation Recommendations

### Phase 1: Update lean-plan-architect.md Template

**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md

**Lines to update**: 126-140 (metadata template in STEP 2)

**New template**:
```markdown
3. **Include Lean-Specific Metadata**:
   ```markdown
   ## Metadata
   - **Date**: YYYY-MM-DD
   - **Feature**: [One-line formalization description]
   - **Scope**: [Mathematical context and formalization approach]
   - **Status**: [NOT STARTED]
   - **Estimated Hours**: [low]-[high] hours
   - **Complexity Score**: [Numeric value from complexity calculation]
   - **Structure Level**: 0
   - **Estimated Phases**: [N from STEP 1 analysis]
   - **Standards File**: [Absolute path to CLAUDE.md]
   - **Research Reports**:
     - [Link to Mathlib research report](../reports/001-name.md)
     - [Link to proof patterns report](../reports/002-name.md)
   - **Lean File**: [Absolute path to .lean file for Tier 1 discovery]
   - **Lean Project**: [Absolute path to lakefile.toml location]
   ```
```

### Phase 2: Add Scope Field Documentation

**Insert after line 140** in lean-plan-architect.md:

```markdown
**Scope Field Guidelines**:
For Lean formalization plans, the Scope field should provide:
1. Mathematical domain (algebra, analysis, topology, etc.)
2. Specific theorem category or topic
3. Formalization methodology (blueprint-based, interactive, etc.)
4. Expected deliverables (theorem count, modules, proofs)

Example Scope:
```markdown
- **Scope**: Formalize commutative ring homomorphism properties in algebraic structures. Prove 8 theorems covering identity preservation, kernel properties, and image characterization. Output: Mathlib-style proofs in ProofChecker/RingHom.lean with full documentation.
```
```

### Phase 3: Update /lean-plan Command Documentation

**File**: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md

**Add section**:
```markdown
## Plan Metadata Format

/lean-plan generates plans with standardized metadata following the Plan Metadata Standard with Lean-specific extensions:

**Required Fields**:
- **Date**: Plan creation date (YYYY-MM-DD)
- **Feature**: One-line formalization description (50-100 chars)
- **Status**: Always [NOT STARTED] for new plans
- **Estimated Hours**: Time range (e.g., "8-12 hours")
- **Standards File**: Absolute path to CLAUDE.md
- **Research Reports**: Links to Mathlib research reports

**Recommended Optional Fields**:
- **Scope**: Mathematical context and formalization approach
- **Complexity Score**: Numeric complexity from calculation
- **Structure Level**: Always 0 (Lean plans use single-file structure)
- **Estimated Phases**: Phase count from initial analysis

**Lean-Specific Fields** (workflow extensions):
- **Lean File**: Absolute path to target .lean file (enables Tier 1 discovery in /lean-build)
- **Lean Project**: Absolute path to Lean project root (lakefile.toml location)

See [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md) for validation rules.
```

### Phase 4: Verification

**Validation script**:
```bash
# Run metadata validation on sample /lean-plan output
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_PATH" 2>&1

# Expected: All required fields present, field order correct
```

## 9. Testing Plan

### Test Case 1: Field Order Validation

**Input**: Run /lean-plan with sample feature description
**Expected**: Metadata fields in order: Date, Feature, Scope, Status, Estimated Hours, Complexity Score, Structure Level, Estimated Phases, Standards File, Research Reports, Lean File, Lean Project
**Validation**: Parse metadata section, verify field order matches template

### Test Case 2: Phase Heading Format Validation

**Input**: Generated plan from /lean-plan
**Expected**: All phase headings use `### Phase N:` format (level 3)
**Validation**: `grep "^### Phase [0-9]" plan.md` returns all phases, `grep "^## Phase [0-9]" plan.md` returns empty

### Test Case 3: Scope Field Content Validation

**Input**: Run /lean-plan with Lean formalization description
**Expected**: Scope field includes mathematical context, formalization approach, expected deliverables
**Validation**: Manual review of Scope field content quality

### Test Case 4: Backward Compatibility

**Input**: Existing /lean-plan-generated plans without new optional fields
**Expected**: /implement and /lean-build parse successfully
**Validation**: Run /implement on old plan, verify execution proceeds

## 10. Conclusion

### Summary of Findings

1. **Phase heading format is CORRECT** - lean-plan-architect.md already mandates `### Phase N:` (level 3) matching /create-plan standard
2. **Metadata fields are VALID** - Lean-specific fields (**Lean File**, **Lean Project**) are permitted workflow extensions per Plan Metadata Standard
3. **Field order differs** - /lean-plan lists Status before Estimated Hours, /create-plan lists Status after Standards File
4. **Optional fields missing** - /lean-plan omits recommended fields (Scope, Complexity Score, Structure Level, Estimated Phases)

### Recommended Actions

**Priority 1** (Required for Standardization):
1. Update lean-plan-architect.md metadata template (lines 126-140) to match /create-plan field order
2. Add Scope, Complexity Score, Structure Level, Estimated Phases fields to template
3. Update /lean-plan command documentation with metadata format specification

**Priority 2** (Recommended for Quality):
1. Add Scope field documentation to lean-plan-architect.md explaining mathematical context requirements
2. Create validation test cases for field order and content quality
3. Update lean-plan-command-guide.md with metadata format examples

**Priority 3** (Optional Enhancement):
1. Add metadata validation to /lean-plan command (pre-agent invocation)
2. Create linter for Lean-specific metadata field validation
3. Update lean-plan-architect.md COMPLETION CRITERIA with metadata field checklist

### Next Steps

1. Implement Phase 1-4 recommendations from Section 8
2. Run Test Cases 1-4 from Section 9 to verify changes
3. Document formatting standard in lean-plan-command-guide.md
4. Create GitHub issue tracking metadata standardization completion

## Implementation Status

- **Status**: Research Complete
- **Plan**: [Will be created by plan-architect]
- **Implementation**: [Will be updated by /implement]
- **Date**: 2025-12-04

## References

1. /home/benjamin/.config/.claude/commands/lean-plan.md - /lean-plan command implementation
2. /home/benjamin/.config/.claude/commands/create-plan.md - /create-plan reference implementation
3. /home/benjamin/.config/.claude/agents/plan-architect.md - Standard plan template
4. /home/benjamin/.config/.claude/agents/lean-plan-architect.md - Lean-specific plan template
5. /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md - Plan Metadata Standard
6. /home/benjamin/.config/.claude/specs/050_lean_plan_subagent_delegation/plans/001-lean-plan-subagent-delegation-plan.md - Example /lean-plan output

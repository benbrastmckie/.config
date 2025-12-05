# Lean Plan Formatting Standardization Implementation Plan

## Metadata
- **Date**: 2025-12-04 (Revised)
- **Feature**: Standardize /lean-plan output formatting to match /create-plan metadata field order and add phase routing indicators
- **Scope**: Update lean-plan-architect.md agent behavioral file to: (1) standardize metadata field order (matching plan-architect.md), (2) add optional recommended fields (Scope, Complexity Score, Structure Level, Estimated Phases), (3) add phase routing summary section showing implementer types upfront, (4) add per-phase `implementer:` metadata field indicating "lean" or "software" agent, and (5) maintain Lean-specific fields (**Lean File**, **Lean Project**) as valid workflow extensions. Phase heading format is already correct (### Phase N:).
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-4 hours
- **Complexity Score**: 18.0
- **Structure Level**: 0
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Plan Formatting Research](../reports/001-lean-plan-formatting-research.md)

## Overview

The /lean-plan command currently produces plans with metadata field order that differs from the /create-plan standard. Research shows that phase heading format is already correct (using `### Phase N:` level 3 headings), and Lean-specific metadata fields (**Lean File**, **Lean Project**) are valid per Plan Metadata Standard.

This plan updates lean-plan-architect.md to:
1. Standardize metadata field order to match plan-architect.md reference
2. Add optional recommended fields (Scope, Complexity Score, Structure Level, Estimated Phases)
3. Add Phase Routing Summary section showing phase types upfront for /lean-implement
4. Add per-phase `implementer:` metadata field indicating "lean" or "software" agent
5. Document Scope field guidelines for Lean formalization plans
6. Maintain Lean-specific fields as valid workflow extensions

**Key Benefits**:
- **Consistency**: Metadata ordering matches /create-plan standard
- **Clarity**: Scope field provides mathematical context for formalizations
- **Routing Efficiency**: /lean-implement can identify phase types upfront without parsing entire plan
- **Traceability**: Complexity Score and Structure Level aid in plan assessment
- **Standards Compliance**: Aligns with Plan Metadata Standard recommendations

## Research Summary

Research findings from comprehensive formatting analysis:

**Current State**:
- Phase heading format is CORRECT - already uses `### Phase N:` (level 3)
- Metadata includes all required fields (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- Lean-specific fields (**Lean File**, **Lean Project**) are valid per Plan Metadata Standard
- Field order differs from /create-plan: Status appears before Estimated Hours

**Reference Standard** (/create-plan):
- Metadata field order: Date, Feature, Scope, Status, Estimated Hours, Standards File, Research Reports
- Includes optional fields: Scope, Complexity Score, Structure Level, Estimated Phases
- Status field appears AFTER Scope field (if present)

**Required Changes**:
- Update metadata template in lean-plan-architect.md STEP 2 (lines 126-140)
- Add Scope field documentation for Lean formalization plans
- Add optional recommended fields (Complexity Score, Structure Level, Estimated Phases)
- Add Phase Routing Summary section template showing upfront phase type indicators
- Add `implementer:` field template for per-phase routing metadata
- NO changes needed to phase heading format (already correct)
- Updates to agent behavioral logic needed for Phase Routing Summary generation

## Success Criteria

- [ ] lean-plan-architect.md metadata template updated with standardized field order
- [ ] Scope field added after Feature field in metadata template
- [ ] Complexity Score field added to metadata template
- [ ] Structure Level field added to metadata template (always 0 for Lean plans)
- [ ] Estimated Phases field added to metadata template
- [ ] Phase Routing Summary section template added to lean-plan-architect.md
- [ ] Per-phase `implementer:` field template added to lean-plan-architect.md
- [ ] Instructions added for generating Phase Routing Summary based on phase analysis
- [ ] Logic documented for determining `implementer:` field value ("lean" vs "software")
- [ ] Lean-specific fields (**Lean File**, **Lean Project**) remain at end of metadata
- [ ] Scope field documentation added explaining mathematical context requirements
- [ ] lean-plan-command-guide.md updated with metadata format specification
- [ ] lean-plan-command-guide.md documents Phase Routing Summary format
- [ ] lean-plan-command-guide.md documents per-phase `implementer:` field
- [ ] Test /lean-plan command generates plans with new metadata format
- [ ] Test /lean-plan output includes Phase Routing Summary table
- [ ] Test /lean-plan output includes `implementer:` field on each phase
- [ ] Metadata validation passes for sample /lean-plan output
- [ ] Backward compatibility verified: existing plans still parseable by /implement and /lean-build

## Technical Design

### Architecture Overview

**Current Architecture** (lean-plan-architect.md STEP 2):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Status**: [IN PROGRESS]
- **Estimated Hours**: [low]-[high] hours
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**: ...
- **Lean File**: [Absolute path]
- **Lean Project**: [Absolute path]
```

**New Architecture** (aligned with plan-architect.md):
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Scope**: [Mathematical context and formalization approach]
- **Status**: [IN PROGRESS]
- **Estimated Hours**: [low]-[high] hours
- **Complexity Score**: [Numeric value from complexity calculation]
- **Structure Level**: 0
- **Estimated Phases**: [N from STEP 1 analysis]
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**: ...
- **Lean File**: [Absolute path to .lean file for Tier 1 discovery]
- **Lean Project**: [Absolute path to lakefile.toml location]
```

### Component Integration

**Metadata Field Order** (standardized):
1. Date
2. Feature
3. Scope (optional recommended)
4. Status
5. Estimated Hours
6. Complexity Score (optional recommended)
7. Structure Level (optional recommended)
8. Estimated Phases (optional recommended)
9. Standards File
10. Research Reports
11. Lean File (Lean-specific workflow extension)
12. Lean Project (Lean-specific workflow extension)

**Scope Field Guidelines** (for Lean plans):
- Mathematical domain (algebra, analysis, topology, etc.)
- Specific theorem category or topic
- Formalization methodology (blueprint-based, interactive, etc.)
- Expected deliverables (theorem count, modules, proofs)

**Example Scope**:
```markdown
- **Scope**: Formalize group homomorphism preservation properties in abstract algebra. Prove 8 theorems covering identity preservation, inverse preservation, and composition. Output: ProofChecker/GroupHom.lean module with complete proofs.
```

**Phase Routing Summary Format** (new addition):
```markdown
## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | software | implementer-coordinator |
| 2 | lean | lean-implementer |
| 3 | software | implementer-coordinator |
```

**Per-Phase Implementer Field** (new addition):
```markdown
### Phase N: [Phase Name] [NOT STARTED]
implementer: software  # or "lean" for theorem-proving phases
lean_file: /path/to/file.lean  # only for lean phases
dependencies: []
```

### Divergence from Standards

**No divergence** - this plan aligns existing /lean-plan implementation with Plan Metadata Standard recommendations. All changes are additive (adding optional fields) or organizational (field reordering). Plan Metadata Standard explicitly permits workflow-specific fields like **Lean File** and **Lean Project**.

## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | software | implementer-coordinator |
| 2 | software | implementer-coordinator |
| 3 | software | implementer-coordinator |

### Phase 1: Update Metadata Template in lean-plan-architect.md [COMPLETE]
implementer: software
dependencies: []

**Objective**: Update metadata template in STEP 2 (lines 126-140) to match /create-plan field order and add optional recommended fields.

**Complexity**: Low

**Tasks**:
- [x] Read lean-plan-architect.md to confirm current template location (file: /home/benjamin/.config/.claude/agents/lean-plan-architect.md, lines 126-140)
- [x] Update metadata template to new field order using Edit tool
- [x] Add **Scope** field after **Feature** field with placeholder text
- [x] Move **Status** field to appear after **Scope** field
- [x] Add **Complexity Score** field after **Estimated Hours** with placeholder
- [x] Add **Structure Level** field with value 0 (Lean plans always use single-file structure)
- [x] Add **Estimated Phases** field with placeholder from STEP 1 analysis
- [x] Move **Standards File** field to appear before **Research Reports**
- [x] Keep **Lean File** and **Lean Project** fields at end (workflow extensions)
- [x] Add Phase Routing Summary template after "## Implementation Phases" heading
- [x] Add instructions for generating Phase Routing Summary table based on phase analysis
- [x] Add `implementer:` field template to per-phase format (appears after phase heading)
- [x] Document `implementer:` field values: "lean" for theorem-proving phases, "software" for infrastructure/tooling phases
- [x] Add logic for determining implementer type: check for lean_file metadata (indicates "lean"), otherwise "software"
- [x] Verify template uses markdown code block syntax correctly
- [x] Verify all required fields present (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)

**Testing**:
```bash
# Verify updated template structure
grep -A 15 "Include Lean-Specific Metadata" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Expected output should show new field order with Scope, Complexity Score, Structure Level, Estimated Phases
```

**Expected Duration**: 0.5 hours

### Phase 2: Add Scope Field Documentation [COMPLETE]
implementer: software
dependencies: [1]

**Objective**: Add documentation section after metadata template explaining Scope field requirements for Lean formalization plans.

**Complexity**: Low

**Tasks**:
- [x] Insert new section after line 140 in lean-plan-architect.md (file: /home/benjamin/.config/.claude/agents/lean-plan-architect.md)
- [x] Add heading: "**Scope Field Guidelines**:"
- [x] Document Scope field should provide mathematical context
- [x] List required Scope components: mathematical domain, theorem category, formalization approach, expected deliverables
- [x] Add example Scope field content for group homomorphism formalization
- [x] Add guidance on scope length (2-3 sentences recommended)
- [x] Reference Scope field in STEP 2 instructions for agent awareness
- [x] Add note that Scope is optional but recommended for Lean plans
- [x] Verify documentation follows writing standards (clear, concise, no historical commentary)

**Testing**:
```bash
# Verify Scope field documentation exists
grep -A 10 "Scope Field Guidelines" /home/benjamin/.config/.claude/agents/lean-plan-architect.md

# Expected: Section with mathematical context requirements and example
```

**Expected Duration**: 0.5 hours

### Phase 3: Update lean-plan-command-guide.md and Validate [COMPLETE]
implementer: software
dependencies: [1, 2]

**Objective**: Update command guide documentation with metadata format specification and validate with test /lean-plan execution.

**Complexity**: Medium

**Tasks**:
- [x] Read lean-plan-command-guide.md to locate metadata documentation section (file: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md)
- [x] Add or update "Plan Metadata Format" section documenting field order
- [x] List required fields with descriptions (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- [x] List recommended optional fields with descriptions (Scope, Complexity Score, Structure Level, Estimated Phases)
- [x] List Lean-specific fields with descriptions (**Lean File**, **Lean Project**)
- [x] Document Phase Routing Summary section format with table structure
- [x] Document per-phase `implementer:` field with "lean" and "software" values
- [x] Add example metadata block showing complete field set
- [x] Add example Phase Routing Summary table
- [x] Add example phase with `implementer:` field
- [x] Reference Plan Metadata Standard documentation link
- [x] Create test Lean project with sample theorem file for validation
- [x] Run /lean-plan with test feature description
- [x] Verify output plan has new metadata field order
- [x] Verify Scope field is present and populated
- [x] Verify Complexity Score, Structure Level, Estimated Phases fields present
- [x] Verify Phase Routing Summary table exists and shows phase types
- [x] Verify each phase has `implementer:` field with correct value
- [x] Run metadata validation: `bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_PATH"`
- [x] Verify backward compatibility: existing plans parse correctly with /implement
- [x] Document metadata format in lean-plan-output.md (if exists)

**Testing**:
```bash
# Create test Lean project
mkdir -p /tmp/test_lean_format
cat > /tmp/test_lean_format/Main.lean <<'EOF'
import Mathlib.Algebra.Group.Hom.Defs

theorem group_hom_preserves_identity {G H : Type*} [Group G] [Group H]
  (f : G →* H) : f 1 = 1 := by
  sorry
EOF

# Run /lean-plan with test feature
cd /home/benjamin/.config
/lean-plan "formalize group homomorphism identity preservation" --lean-project /tmp/test_lean_format

# Verify metadata format in generated plan
TOPIC_DIR=$(ls -td .claude/specs/*_group_hom* | head -1)
PLAN_FILE=$(ls "$TOPIC_DIR/plans/"*.md | head -1)

# Check field order
grep -A 15 "## Metadata" "$PLAN_FILE"

# Expected output should show:
# - Date
# - Feature
# - Scope
# - Status
# - Estimated Hours
# - Complexity Score
# - Structure Level
# - Estimated Phases
# - Standards File
# - Research Reports
# - Lean File
# - Lean Project

# Validate metadata compliance
bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_FILE" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Metadata validation failed"
  exit 1
fi
echo "✓ Metadata validation passed"

# Test backward compatibility with existing plan
EXISTING_PLAN="/home/benjamin/.config/.claude/specs/050_lean_plan_subagent_delegation/plans/001-lean-plan-subagent-delegation-plan.md"
if [ -f "$EXISTING_PLAN" ]; then
  bash .claude/scripts/lint/validate-plan-metadata.sh "$EXISTING_PLAN" 2>&1
  echo "✓ Backward compatibility verified"
fi
```

**Expected Duration**: 1-1.5 hours

## Testing Strategy

### Unit Testing

**Metadata Template Validation**:
- Test metadata template in lean-plan-architect.md contains all required fields
- Test field order matches /create-plan reference standard
- Test optional fields (Scope, Complexity Score, Structure Level, Estimated Phases) present
- Test Lean-specific fields (**Lean File**, **Lean Project**) at end

**Documentation Validation**:
- Test Scope field documentation exists and explains mathematical context requirements
- Test lean-plan-command-guide.md has "Plan Metadata Format" section
- Test metadata format documentation includes all field categories (required, optional, Lean-specific)

### Integration Testing

**End-to-End Workflow**:
- Test /lean-plan command generates plan with new metadata format
- Test generated plan has all required fields in correct order
- Test generated plan has optional fields populated (Scope, Complexity Score, etc.)
- Test metadata validation script passes for new format

**Backward Compatibility Testing**:
- Test existing /lean-plan-generated plans still parseable by /implement
- Test existing plans pass metadata validation (required fields only)
- Test /lean-build command works with both old and new plan formats

### Standards Compliance Testing

**Plan Metadata Standard Compliance**:
- Verify required fields match Plan Metadata Standard specification
- Verify optional fields are recognized by validation script
- Verify Lean-specific fields permitted as workflow extensions
- Verify field order follows recommended pattern (if specified)

**Documentation Standards Compliance**:
- Verify documentation follows writing standards (clear, concise, no emojis)
- Verify examples are accurate and helpful
- Verify links to Plan Metadata Standard documentation valid

## Documentation Requirements

### Agent Behavioral File Documentation

**Update lean-plan-architect.md**:
- Updated metadata template in STEP 2 (lines 126-140)
- Added Scope field documentation section (after line 140)
- Added references to optional recommended fields in STEP 1 analysis requirements
- Maintained existing Lean-specific documentation (**Lean File**, **Lean Project** explanations)

### Command Guide Documentation

**Update lean-plan-command-guide.md** (file: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md):
- Add "Plan Metadata Format" section documenting standardized field order
- Document required fields with descriptions
- Document recommended optional fields with descriptions
- Document Lean-specific workflow extension fields
- Add example metadata block showing complete field set
- Add reference link to Plan Metadata Standard documentation

### Output Documentation

**Update lean-plan-output.md** (if exists):
- Document metadata format changes in output examples
- Show before/after comparison of metadata sections
- Add notes about backward compatibility with existing plans

## Dependencies

### External Dependencies

**None** - All required infrastructure exists:
- lean-plan-architect.md agent (to be updated)
- plan-architect.md reference template (no changes needed)
- Plan Metadata Standard documentation (already permits workflow extensions)
- Metadata validation script (already supports optional fields)

### Internal Prerequisites

**Completed Phases**:
- Phase 1 must complete before Phase 2 (metadata template must exist for documentation)
- Phase 2 must complete before Phase 3 (Scope documentation needed for validation)
- Phase 1 and 2 must complete before Phase 3 (guide updates reference both template and docs)

**Validation Dependencies**:
- Phase 3 depends on metadata validation script (already exists)
- Phase 3 depends on test Lean project creation (created in phase)

## Rollback Plan

**If implementation fails**:
1. Revert lean-plan-architect.md to git HEAD: `git checkout HEAD -- .claude/agents/lean-plan-architect.md`
2. Revert lean-plan-command-guide.md if updated: `git checkout HEAD -- .claude/docs/guides/commands/lean-plan-command-guide.md`
3. Clean up test artifacts: `rm -rf /tmp/test_lean_format .claude/specs/*_group_hom*`
4. No state file changes (no rollback needed)

**Safe rollback guaranteed** because:
- Only documentation files modified (lean-plan-architect.md, lean-plan-command-guide.md)
- No command logic changes (no /lean-plan.md modifications)
- No library changes (no rollback needed)
- Changes are additive (field additions, not removals)

## Risk Analysis

### Implementation Risks

**Risk**: Metadata field order changes break parsers
- **Mitigation**: Parsers use field labels, not order (verified in research)
- **Severity**: Very Low - field order is informational, not structural

**Risk**: Optional fields cause validation failures
- **Mitigation**: Plan Metadata Standard explicitly allows optional fields
- **Severity**: Very Low - validation script designed for optional fields

**Risk**: Scope field documentation too prescriptive
- **Mitigation**: Mark Scope as optional recommended, provide guidelines not rules
- **Severity**: Low - agents can adapt to flexible guidelines

### Compatibility Risks

**Risk**: Existing /lean-plan workflows break
- **Mitigation**: All changes are additive (adding fields, not removing)
- **User impact**: None - existing plans remain valid
- **Severity**: None - backward compatible by design

**Risk**: /lean-build command doesn't recognize new fields
- **Mitigation**: /lean-build parses **Lean File** metadata (unchanged)
- **Severity**: None - Lean-specific fields unchanged

### Documentation Risks

**Risk**: Documentation updates incomplete or inaccurate
- **Mitigation**: Follow documentation standards checklist, verify examples
- **Severity**: Low - documentation can be corrected post-implementation

## Success Metrics

**Metadata Standardization**:
- **Target**: 100% field order compliance with /create-plan standard
- **Measurement**: Compare lean-plan-architect.md template to plan-architect.md reference
- **Validation**: All required fields in correct order

**Optional Field Adoption**:
- **Target**: 100% of /lean-plan outputs include Scope, Complexity Score, Structure Level, Estimated Phases
- **Measurement**: Run 5 test cases, verify all optional fields populated
- **Validation**: No missing optional fields in generated plans

**Backward Compatibility**:
- **Target**: 100% of existing plans remain valid
- **Measurement**: Run metadata validation on 10 existing plans
- **Validation**: All existing plans pass validation (required fields only)

**Documentation Completeness**:
- **Target**: 100% documentation coverage for metadata format
- **Measurement**: Check lean-plan-command-guide.md has "Plan Metadata Format" section
- **Validation**: Section documents all field categories with examples

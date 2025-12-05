# Phase Heading Format Analysis for Lean Plan Architect

**Date**: 2025-12-04
**Research Topic**: Verify lean-plan-architect uses '###' level headings for phases, matching /create-plan standard
**Complexity Level**: 2
**Status**: Complete

## Executive Summary

The lean-plan-architect agent already uses the correct phase heading format: `### Phase N: [Name] [NOT STARTED]` (3 hash symbols = level 3 markdown heading). This matches the standard used by plan-architect and other agents in the project. No changes are needed to lean-plan-architect's phase heading format - it is already compliant with the standard.

## Research Questions

1. What phase heading format does lean-plan-architect currently generate?
2. What phase heading format does plan-architect use as the standard?
3. Do the two agents use matching formats?
4. Are there any inconsistencies or issues with the lean-plan-architect format?

## Findings

### Finding 1: Lean Plan Architect Phase Heading Format

**Evidence**: Lines 128, 304, and 335 in `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`

The lean-plan-architect agent defines phase format using **3 hash symbols** (level 3 markdown heading):

```markdown
### Phase 1: [Theorem Category Name] [NOT STARTED]
dependencies: []

**Objective**: [High-level goal for this phase]

**Complexity**: [Low|Medium|High]

**Theorems**:
- [ ] `theorem_name_1`: [Brief description]
  - Goal: `∀ a b : Type, property a b`  # Lean 4 type signature
  - Strategy: Use `Mathlib.Theorem.Name` via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours
```

This format is used consistently in all phase format documentation within the agent (lines 128, 304, 335).

### Finding 2: Plan Architect Phase Heading Format

**Evidence**: Line 547 in `/home/benjamin/.config/.claude/agents/plan-architect.md`

The plan-architect agent defines the required phase heading format as:

```
**Required Format**: `### Phase N: Name [NOT STARTED]`
```

This explicitly requires **3 hash symbols** (level 3 heading). Examples from lines 557-559:

```markdown
### Phase 1: Foundation [NOT STARTED]
### Phase 2: Core Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

### Finding 3: Real-World Verification

**Evidence**: Actual plan file at `/home/benjamin/.config/.claude/specs/037_lean_metadata_phase_refactor/plans/001-lean-metadata-phase-refactor-plan.md`

Verified actual output from a plan (line 95):

```markdown
### Phase 1: Update lean-plan-architect Phase Template [NOT STARTED]
dependencies: []
```

This confirms that plans created by plan-architect (and by extension, would be created by lean-plan-architect) use the `###` level 3 heading format.

### Finding 4: Consistency Across Agents

**Evidence**: Grep search across all agent files

Cross-checking phase heading formats in other agents:
- `plan-architect.md`: `### Phase N: ...` (3 symbols)
- `lean-plan-architect.md`: `### Phase N: ...` (3 symbols)
- `cleanup-plan-architect.md`: `### Phase 1: ...` (3 symbols)
- `implementation-executor.md`: `### Phase N: ...` (3 symbols)

All specialized plan architect agents use the same **3-hash symbol** format.

### Finding 5: Documentation of Standards

**Evidence**: Lines 170-172 in `lean-plan-architect.md`

The lean-plan-architect includes explicit standards:

```markdown
**CRITICAL REQUIREMENTS FOR NEW PLANS**:
- Metadata **Status** MUST be `[NOT STARTED]` (not [IN PROGRESS] or [COMPLETE])
- ALL phase headings MUST include `[NOT STARTED]` marker
- ALL theorem checkboxes MUST use `- [ ]` (unchecked)
```

While this doesn't explicitly state the heading level, the format template on line 128 clearly shows `###`.

## Comparison Matrix

| Aspect | Plan Architect | Lean Plan Architect | Status |
|--------|---|---|---|
| Phase Heading Level | 3 (`###`) | 3 (`###`) | ✓ Match |
| Format Pattern | `### Phase N: Name [Status]` | `### Phase N: Name [Status]` | ✓ Match |
| Status Marker | `[NOT STARTED]` required | `[NOT STARTED]` required | ✓ Match |
| Example Line | Line 557 | Line 128 | ✓ Consistent |
| Actual Output | Real plans use `###` | Would generate `###` | ✓ Verified |

## Detailed Analysis

### Phase Heading Format Standards

The project uses a consistent phase heading format across all agents:

**Standard Format**: `### Phase N: Descriptive Name [Status Marker]`

**Components**:
1. **Heading Level**: 3 (three hash symbols = `###`)
2. **Phase Number**: Sequential integer (1, 2, 3, etc.)
3. **Descriptive Name**: Clear description of phase objective
4. **Status Marker**: One of `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]`

**Implementation in Agents**:
- **plan-architect.md** (lines 543-567): Documents required format and provides examples
- **lean-plan-architect.md** (lines 128-163, 304-330, 335-364): Uses exact same format in templates and examples

### Why 3-Hash Markdown Headings?

The use of `###` (level 3 headings) is intentional:
- Level 1 (`#`): Reserved for plan/document title
- Level 2 (`##`): Reserved for major sections (Metadata, Overview, Implementation Phases, etc.)
- Level 3 (`###`): Used for phases within the Implementation Phases section
- Level 4+ (`####`): Used for tasks and detailed subsections within phases

This hierarchy ensures proper markdown document structure and enables:
- Clear visual hierarchy in rendered markdown
- Proper table of contents generation
- Consistent navigation in markdown viewers
- Compatibility with /implement command parsing

### Verification Against Standards

**Document**: `/home/benjamin/.config/CLAUDE.md` (Plan Metadata Standard section)

The project standards document references phase heading format requirements, and both agents adhere to this standard:
- Phase headings include status markers for progress tracking
- Format is `### Phase N: Name [Status]`
- Status markers transition through lifecycle: `[NOT STARTED]` → `[IN PROGRESS]` → `[COMPLETE]`

## Implications for Existing Plans

### Current Lean Plans

Examined existing Lean plans in `/home/benjamin/.config/.claude/specs/`:
- `032_lean_plan_command/plans/001-lean-plan-command-plan.md`
- `033_lean_command_build_improve/plans/001-lean-command-build-improve-plan.md`
- `036_lean_build_error_improvement/plans/001-lean-build-error-improvement-plan.md`

**Result**: All verified plans use `### Phase N: ...` format (3-hash headings).

### Integration with /lean-build Command

The `/lean-build` command expects phase headings to follow the standard format:
- Lines 221-242 in `/lean-build` search for `lean_file:` metadata after phase headings
- Phase heading parsing depends on consistent heading level (level 3)
- Tier 1 discovery mechanism (phase-specific file discovery) assumes standard format

**Impact**: The current lean-plan-architect format is fully compatible with /lean-build parsing and metadata extraction.

## Quality Standards Check

### Heading Format Compliance

| Criterion | Status | Evidence |
|---|---|---|
| Uses `###` (level 3) heading | ✓ Compliant | Lines 128, 304, 335 in lean-plan-architect.md |
| Includes phase number | ✓ Compliant | `### Phase 1:` format |
| Includes descriptive name | ✓ Compliant | Template shows `[Theorem Category Name]` |
| Includes status marker | ✓ Compliant | `[NOT STARTED]` in all examples |
| Matches plan-architect standard | ✓ Compliant | Identical format to plan-architect.md |
| Matches actual plan output | ✓ Compliant | Real plans use same format |

## Conclusion

### Primary Finding

**The lean-plan-architect agent already uses the correct phase heading format (`### Phase N: [Name] [NOT STARTED]`) that matches the /create-plan and plan-architect standards. No changes are needed.**

### Supporting Evidence

1. **Explicit Format Definition**: lean-plan-architect documents phase format on lines 127-163 using `###` headings
2. **Template Consistency**: All phase templates (examples at lines 128, 304, 335) use the same format
3. **Standards Alignment**: Plan-architect explicitly requires `### Phase N: Name [NOT STARTED]` (line 547)
4. **Verified Output**: Actual plans generated use matching `###` format
5. **Integration Compatibility**: /lean-build command correctly parses phase metadata with this format

### Recommendations

1. **No Refactoring Needed**: The lean-plan-architect agent's phase heading format is already correct and compliant
2. **Focus Area**: If the revised plan at `/home/benjamin/.config/.claude/specs/037_lean_metadata_phase_refactor/plans/001-lean-metadata-phase-refactor-plan.md` requires changes, those changes should focus on the `lean_file:` metadata specification (per-phase file targeting), not the heading level or format
3. **Documentation**: The current documentation in lean-plan-architect is clear and accurate - no updates needed for phase heading format documentation

## Appendix: Format Specifications by Source

### From lean-plan-architect.md

**Primary Definition** (lines 127-163):
```markdown
### Phase 1: [Theorem Category Name] [NOT STARTED]
dependencies: []

**Objective**: [High-level goal for this phase]

**Complexity**: [Low|Medium|High]

**Theorems**:
- [ ] `theorem_name_1`: [Brief description]
  - Goal: `∀ a b : Type, property a b`
  - Strategy: Use `Mathlib.Theorem.Name` via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours
```

**Template Definition** (lines 304-330):
```markdown
### Phase N: [Category Name] [NOT STARTED]
dependencies: [list of prerequisite phase numbers, or empty list]

**Objective**: [What this phase accomplishes]

**Complexity**: [Low|Medium|High based on theorem complexity]

**Theorems**: [List as in primary definition]
```

**Concrete Example** (lines 335-364):
```markdown
### Phase 1: Basic Commutativity Properties [NOT STARTED]
dependencies: []

**Objective**: Prove commutativity for addition and multiplication

**Complexity**: Low

**Theorems**:
- [ ] `theorem_add_comm`: Prove addition commutativity
  - Goal: `∀ a b : Nat, a + b = b + a`
  - Strategy: Use `Nat.add_comm` from Mathlib via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours
```

### From plan-architect.md

**Documented Standard** (line 547):
```
**Required Format**: `### Phase N: Name [NOT STARTED]`
```

**Status Lifecycle** (lines 549-553):
```
1. **[NOT STARTED]**: Applied during plan creation (your responsibility)
2. **[IN PROGRESS]**: Applied by /implement when phase execution begins
3. **[COMPLETE]**: Applied by /implement when phase execution ends
4. **[BLOCKED]**: Applied when phase cannot proceed due to failures
```

**Examples** (lines 555-560):
```markdown
### Phase 1: Foundation [NOT STARTED]
### Phase 2: Core Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

---

**Report Completion Status**: ✓ Complete
**Recommendation**: No changes required - lean-plan-architect already uses standard '###' phase heading format

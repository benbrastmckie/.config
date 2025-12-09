# Research Report: Lean Plan Format Issues

**Research Topic**: Current lean-plan output format issues in /home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/048_minimal_axiom_review_proofs/plans/001-minimal-axiom-review-proofs-plan.md

**Date**: 2025-12-08
**Complexity**: 3

---

## Executive Summary

Analysis of the reference Lean plan reveals **four critical format issues** that need to be standardized in `/lean-plan` command output:

1. **Phase heading format**: Uses `## Phase N:` (should be `### Phase N:`)
2. **Missing dependencies**: No `dependencies: []` declarations in phases
3. **Missing implementation type indicators**: No explicit Lean vs software markers
4. **Status metadata format**: Uses `[IN PROGRESS]` with brackets (inconsistent with other metadata formats)

---

## Issue 1: Phase Heading Format

### Current Format (Incorrect)
Lines 26, 68, 116, 178, 210, 246, 273 use **level-2 headings** for phases:

```markdown
## Phase 1: Critical Documentation Fixes [COMPLETE]
## Phase 2: Derive necessitation from MK [COMPLETE]
## Phase 3: Prove the Deduction Theorem [NOT STARTED]
## Phase 4: Update MK/TK Documentation [NOT STARTED]
## Phase 5: Derive pairing Axiom [NOT STARTED]
## Phase 6: Derive dni Axiom [NOT STARTED]
## Phase 7: Verification and Cleanup [NOT STARTED]
```

### Expected Format (Correct)
Should use **level-3 headings**:

```markdown
### Phase 1: Critical Documentation Fixes [COMPLETE]
### Phase 2: Derive necessitation from MK [COMPLETE]
### Phase 3: Prove the Deduction Theorem [NOT STARTED]
```

### Rationale
- Level-2 headings (`##`) are reserved for top-level plan sections (Context, Metadata, Risk Assessment, Dependencies Graph, Summary)
- Phase headings should be subordinate to these top-level sections using level-3 (`###`)
- Maintains consistent heading hierarchy with standard plan format

---

## Issue 2: Missing Dependencies Declarations

### Current Format (Missing)
None of the phases have explicit dependency declarations. For example, Phase 3 (lines 116-175) has no `dependencies:` field.

### Expected Format (Correct)
Each phase should declare dependencies explicitly:

```markdown
### Phase 3: Prove the Deduction Theorem [NOT STARTED]

**Dependencies**: []

**Goal**: Prove the deduction theorem: `(φ :: Γ) ⊢ ψ → Γ ⊢ φ → ψ`
```

Or for dependent phases:

```markdown
### Phase 4: Update MK/TK Documentation [NOT STARTED]

**Dependencies**: [3]

**Goal**: Document that MK and TK are the primitive inference rules...
```

### Evidence
- Line 22 shows `- **Dependencies**: []` in metadata section, but this is for the ENTIRE plan, not per-phase
- The Dependencies Graph section (lines 336-353) manually describes phase dependencies in text/diagram form
- However, phases themselves lack the `**Dependencies**: [...]` field needed for automated parsing

### Impact
Without explicit per-phase dependency declarations:
- Automated phase dependency parsing fails
- Wave-based parallel execution cannot be determined programmatically
- Must rely on manual interpretation of the Dependencies Graph section

---

## Issue 3: Missing Implementation Type Indicators

### Current Format (Missing)
No explicit indicators of whether phases involve Lean proofs vs software implementation. For example:

- Phase 1 (lines 26-65): Documentation updates (software)
- Phase 2 (lines 68-113): Lean theorem proving
- Phase 3 (lines 116-175): Lean theorem proving
- Phase 5 (lines 210-242): Lean derivation

### Expected Format (Correct)
Should include implementation type metadata:

```markdown
### Phase 2: Derive necessitation from MK [COMPLETE]

**Implementation Type**: Lean
**Dependencies**: []

**Goal**: Prove that the necessitation rule is a special case of modal_k with empty context.
```

Or:

```markdown
### Phase 1: Critical Documentation Fixes [COMPLETE]

**Implementation Type**: Software
**Dependencies**: []

**Goal**: Fix inaccurate claims about soundness proof status in documentation.
```

### Rationale
- Lean plans involve both Lean proof work and supporting software/documentation work
- Implementation type affects:
  - Verification commands (`lake build` vs `grep` checks)
  - Success criteria (compile with zero sorry vs file content matches)
  - Task complexity estimation
- Explicit markers enable better tooling support and automated validation

---

## Issue 4: Status Metadata Format

### Current Format (Inconsistent)
Line 4 uses bracketed format:

```markdown
- **Status**: [IN PROGRESS]
```

### Alternative Formats Observed
Other plan metadata fields use unbracketed format:

```markdown
- **Feature**: Complete tasks from axiom system systematic review
- **Created**: 2025-12-08
- **Plan Type**: research-and-plan (Lean specialization)
```

### Expected Format (Correct)
Should use unbracketed format for consistency:

```markdown
- **Status**: IN PROGRESS
```

Or if brackets are kept, should be consistent across all enum-like fields:

```markdown
- **Status**: [IN PROGRESS]
- **Plan Type**: [research-and-plan (Lean specialization)]
```

### Rationale
- Metadata section (lines 3-22) should have consistent formatting
- Current format mixes bracketed (`[IN PROGRESS]`) and unbracketed (`2025-12-08`) styles
- Plan Metadata Standard (referenced in CLAUDE.md) should clarify which style is canonical

---

## Issue 5: Phase Status in Headings

### Current Format (Inline Status)
Phases include status in the heading itself (lines 26, 68, 116, etc.):

```markdown
## Phase 1: Critical Documentation Fixes [COMPLETE]
## Phase 2: Derive necessitation from MK [COMPLETE]
## Phase 3: Prove the Deduction Theorem [NOT STARTED]
```

### Expected Format (Ambiguous)
Two possible interpretations:

**Option A: Keep status in heading**
```markdown
### Phase 1: Critical Documentation Fixes [COMPLETE]
```

**Option B: Move status to metadata field**
```markdown
### Phase 1: Critical Documentation Fixes

**Status**: COMPLETE
**Dependencies**: []
```

### Recommendation
- If status remains in headings, should use unbracketed format for consistency with metadata section recommendation: `### Phase 1: Critical Documentation Fixes - COMPLETE`
- If brackets are preferred, maintain consistency: both heading status and metadata Status field should use brackets

---

## Recommendations for /lean-plan Command

### High Priority Fixes

1. **Change phase headings from `## Phase N:` to `### Phase N:`**
   - Affects: All phase heading generation logic
   - Impact: Restores correct heading hierarchy
   - Difficulty: Low (simple string replacement)

2. **Add `**Dependencies**: [...]` field to each phase**
   - Affects: Phase metadata generation
   - Format: `**Dependencies**: []` for independent phases, `**Dependencies**: [1, 2]` for dependent phases
   - Placement: Immediately after phase heading, before `**Goal**:`
   - Difficulty: Medium (requires dependency graph analysis)

3. **Add `**Implementation Type**: Lean|Software` field to each phase**
   - Affects: Phase metadata generation
   - Values: `Lean` (for proof work), `Software` (for documentation/infrastructure)
   - Placement: After `**Dependencies**:`, before `**Goal**:`
   - Difficulty: Medium (requires heuristic or LLM classification)

### Medium Priority Fixes

4. **Standardize Status metadata format**
   - Decide: Bracketed (`[IN PROGRESS]`) vs unbracketed (`IN PROGRESS`)
   - Apply consistently to both:
     - Metadata section `**Status**:` field
     - Phase heading status suffixes
   - Difficulty: Low (style decision + string formatting)

---

## Format Specification Summary

### Correct Phase Format Template

```markdown
### Phase N: Phase Title

**Implementation Type**: Lean|Software
**Dependencies**: [list of phase numbers] or []

**Goal**: Brief description of phase objective.

**Rationale**: Explanation of why this phase is needed.

### Tasks

- [ ] `task_id`: Task description
  - Goal: What the task achieves
  - Strategy: How to accomplish it
  - Complexity: Simple|Medium|Complex
  - Dependencies: [list of task IDs] or []

### Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2

### Verification Commands

```bash
# Commands to verify success
```
```

### Metadata Section Format

```markdown
- **Feature**: One-line feature description
- **Status**: NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED
- **Created**: YYYY-MM-DD
- **Plan Type**: research-and-plan (Lean specialization)
- **Lean Project**: /absolute/path/to/project
- **Lean File**: Relative/Path/To/File.lean
- **Dependencies**: []
- **Estimated Hours**: X-Y
```

---

## Verification Checklist

For `/lean-plan` output validation, check:

- [ ] All phase headings use `### Phase N:` (level-3)
- [ ] Each phase has `**Dependencies**: [...]` field
- [ ] Each phase has `**Implementation Type**: Lean|Software` field
- [ ] Status metadata format is consistent (bracketed or unbracketed)
- [ ] Phase heading status suffixes match metadata style
- [ ] Metadata section includes all required fields
- [ ] Dependencies Graph section reflects per-phase dependency declarations

---

## Additional Observations

### Strengths of Current Format

1. **Rich task metadata**: Each task has Goal, Strategy, Complexity, Dependencies (lines 34-48, 76-85, etc.)
2. **Verification commands**: Concrete bash commands for validation (lines 56-64, 161-168, etc.)
3. **Dependencies Graph**: Visual representation of phase relationships (lines 336-353)
4. **Risk Assessment**: Explicit risk categorization (lines 318-330)
5. **Summary table**: Quick overview of all phases with complexity and hours (lines 359-368)

### Recommended Additions (Not Format Issues)

While analyzing, I noticed the plan is well-structured but could benefit from:

1. **Lean-specific verification commands**: The plan includes `lake build`, `lake test`, `lake lint` (lines 308-312), which is excellent
2. **Sorry tracking**: References to `grep -c "sorry"` for tracking incomplete proofs (lines 59, 164, 312)
3. **Lean file paths**: Explicit specification of which Lean files are affected (lines 19-20, 93-112)

These are strengths, not issues - they should be retained in `/lean-plan` output.

---

## Conclusion

The analyzed plan demonstrates **good structure and content** but has **four systematic format issues**:

1. Phase headings use wrong heading level (`##` instead of `###`)
2. Missing per-phase dependency declarations
3. Missing implementation type indicators
4. Inconsistent status metadata formatting

These issues are **easily fixable** through `/lean-plan` command template updates and will enable:
- Automated phase dependency parsing
- Better tooling support for Lean vs software phases
- Consistent metadata formatting across plans
- Improved heading hierarchy for documentation navigation

**Next Steps**: Update `/lean-plan` command to emit the corrected format specified in the "Format Specification Summary" section above.

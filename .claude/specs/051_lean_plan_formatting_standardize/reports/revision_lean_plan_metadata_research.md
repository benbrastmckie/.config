# Research Report: Lean Plan Metadata and Phase-Specific Implementer Routing

## Metadata
- **Date**: 2025-12-04
- **Research Topic**: Plan revision insights for Lean plan metadata and phase-specific implementer routing
- **Research Complexity**: 2
- **Workflow Type**: research-and-revise
- **Related Plan**: /home/benjamin/.config/.claude/specs/051_lean_plan_formatting_standardize/plans/001-lean-plan-formatting-standardize-plan.md

## Executive Summary

This research analyzes the current /lean-plan command structure, /lean-implement routing mechanism, and Lean-specific agent architecture to inform plan revision for metadata standardization and phase-type identification. The investigation reveals that /lean-implement already has a robust 2-tier phase classification system (Tier 1: `lean_file:` metadata, Tier 2: keyword/extension analysis), but the /lean-plan command's metadata template doesn't explicitly generate phase-type markers that would optimize this routing.

**Key Findings**:
1. /lean-plan metadata template already includes **Lean File** and **Lean Project** fields (valid workflow extensions)
2. Phase-level `lean_file:` metadata is the PRIMARY signal for /lean-implement routing (Tier 1 detection)
3. Current template generates `lean_file:` per-phase metadata correctly
4. Plan Metadata Standard permits workflow-specific fields, no standards divergence needed
5. Metadata field order differs from /create-plan reference (Status before Estimated Hours)
6. Optional recommended fields (Scope, Complexity Score, Structure Level, Estimated Phases) missing

**Recommendation**: Update lean-plan-architect.md metadata template to match /create-plan field order and add optional recommended fields while maintaining existing Lean-specific phase metadata format.

## Research Questions and Answers

### Question 1: What metadata fields does the standard plan format require?

**Answer**: Per Plan Metadata Standard documentation:

**Required Fields** (6 total):
1. **Date**: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)` - Plan creation/revision date
2. **Feature**: Single-line description (50-100 chars) - What is being implemented
3. **Status**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, or `[BLOCKED]` - Current plan status
4. **Estimated Hours**: `{low}-{high} hours` - Time estimate as numeric range
5. **Standards File**: `/absolute/path/to/CLAUDE.md` - Standards traceability
6. **Research Reports**: Markdown links with relative paths or `none` if no research phase

**Optional Recommended Fields** (4 total):
1. **Scope**: Multi-line description (recommended for complexity > 60)
2. **Complexity Score**: Numeric value (0-100)
3. **Structure Level**: `0`, `1`, or `2` (plan organization tier)
4. **Estimated Phases**: Numeric value (phase count estimate)

**Workflow-Specific Extensions** (permitted by standard):
- /repair: Error Log Query, Errors Addressed
- /revise: Original Plan, Revision Reason
- **/lean-plan**: **Lean File**, **Lean Project** (Lean-specific fields)

**Field Order** (recommended pattern):
1. Date
2. Feature
3. Scope (optional)
4. Status
5. Estimated Hours
6. Complexity Score (optional)
7. Structure Level (optional)
8. Estimated Phases (optional)
9. Standards File
10. Research Reports
11. [Workflow-specific fields]

**Validation Enforcement**:
- **ERROR-level**: Missing required fields, invalid formats
- **WARNING-level**: Unusual ranges, non-existent paths
- **INFO-level**: Missing recommended optional fields

### Question 2: How does /lean-implement currently determine which phases are Lean vs non-Lean?

**Answer**: /lean-implement uses a **2-tier classification algorithm** in Block 1a-classify:

**Tier 1: Phase-Specific Metadata (Strongest Signal)**
- **Detection**: Checks if phase contains `lean_file:` metadata field
- **Format**: `lean_file: /absolute/path/to/file.lean` (immediately after phase heading)
- **Example**:
  ```markdown
  ### Phase 1: Prove Modal Axioms [NOT STARTED]
  lean_file: /path/to/Modal.lean
  dependencies: []

  Tasks:
  - [ ] Prove theorem_K
  ```
- **Classification**: If `lean_file:` present → phase is "lean"
- **Priority**: **Highest** - overrides all other signals

**Tier 2: Keyword and Extension Analysis**
- **Lean indicators**: `.lean`, `theorem`, `lemma`, `sorry`, `tactic`, `mathlib`, `lean_`
- **Software indicators**: `.ts`, `.js`, `.py`, `.sh`, `.md`, `implement`, `create`, `write tests`
- **Default**: If ambiguous → "software" (conservative approach)

**Classification Function** (from /lean-implement.md, lines 430-461):
```bash
detect_phase_type() {
  local phase_content="$1"
  local phase_num="$2"

  # Tier 1: Check for lean_file metadata (strongest signal)
  if echo "$phase_content" | grep -qE "^lean_file:"; then
    echo "lean"
    return 0
  fi

  # Tier 2: Keyword and extension analysis
  # Lean indicators
  if echo "$phase_content" | grep -qiE '\.(lean)\b|theorem\b|lemma\b|sorry\b|tactic\b|mathlib\b|lean_(goal|build|leansearch)'; then
    echo "lean"
    return 0
  fi

  # Software indicators
  if echo "$phase_content" | grep -qE '\.(ts|js|py|sh|md|json|yaml|toml)\b'; then
    echo "software"
    return 0
  fi

  # Default: software (conservative)
  echo "software"
}
```

**Routing Decision Process** (Block 1b):
1. Read routing map from Block 1a-classify
2. Extract current phase entry: `phase_num:type:lean_file_path`
3. If `type` is "lean" → Invoke lean-coordinator
4. If `type` is "software" → Invoke implementer-coordinator

**Key Insight**: The `lean_file:` field is the **primary discriminator** for phase routing. Without it, /lean-implement falls back to keyword analysis, which may misclassify phases with ambiguous naming.

### Question 3: What phase-specific metadata format would best support implementer routing?

**Answer**: The optimal format already exists in lean-plan-architect.md STEP 2 (lines 141-182). Analysis shows:

**Current Lean Plan Phase Format** (lean-plan-architect.md):
```markdown
### Phase N: [Category Name] [NOT STARTED]
lean_file: /absolute/path/to/file.lean
dependencies: [list of prerequisite phase numbers, or empty list]

**Objective**: [What this phase accomplishes]

**Complexity**: [Low|Medium|High based on theorem complexity]

**Theorems**:
- [ ] `theorem_name`: [One-line description]
  - Goal: `[Lean 4 type signature]`
  - Strategy: [Proof approach: tactics to use, Mathlib theorems to apply]
  - Complexity: Simple|Medium|Complex
  - Prerequisites: [Other theorems needed, if any]
  - Estimated: [hours] hours
```

**Why This Format is Optimal**:

1. **Tier 1 Routing Signal**: `lean_file:` field immediately after heading enables deterministic classification
2. **Multi-File Support**: Each phase can specify different .lean file (e.g., Phase 1 → Truth.lean, Phase 2 → Modal.lean)
3. **Absolute Paths**: Full file paths enable /lean-build Tier 1 discovery (faster than global metadata fallback)
4. **Dependency Tracking**: `dependencies: []` format enables wave-based parallel execution
5. **Theorem-Level Granularity**: Individual theorem tasks with Goals and Strategies for lean-implementer

**Best Practices for Phase Metadata**:
- **Always include `lean_file:`** for Lean theorem-proving phases (even if same file across all phases)
- **Use absolute paths**: `/home/user/project/ProofChecker/Module.lean` (not relative paths)
- **Place immediately after heading**: Before `dependencies:` field
- **One primary file per phase**: For multi-file plans, assign each phase to its dominant file

**Example Multi-File Plan Structure**:
```markdown
### Phase 1: Basic Truth Definitions [NOT STARTED]
lean_file: /home/user/lean-project/ProofChecker/Truth.lean
dependencies: []

### Phase 2: Modal Logic Operators [NOT STARTED]
lean_file: /home/user/lean-project/ProofChecker/Modal.lean
dependencies: [1]

### Phase 3: World History Axioms [NOT STARTED]
lean_file: /home/user/lean-project/ProofChecker/WorldHistory.lean
dependencies: [1]
```

**Routing Map Generation** (from multi-file plan):
```
1:lean:/home/user/lean-project/ProofChecker/Truth.lean
2:lean:/home/user/lean-project/ProofChecker/Modal.lean
3:lean:/home/user/lean-project/ProofChecker/WorldHistory.lean
```

**Comparison with Software Phases** (no lean_file):
```markdown
### Phase 4: Setup Test Infrastructure [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Create test framework for Lean proofs

**Tasks**:
- [ ] Install Lean test runner
- [ ] Configure CI pipeline
- [ ] Write test harness scripts
```
Classification: "software" (no `lean_file:` field, has `.sh` extension keywords)

### Question 4: How should the ## Implementation Phases section indicate phase types upfront?

**Answer**: Based on analysis of lean-plan-architect.md and /lean-implement.md, phase types are **NOT** indicated upfront in a summary section. Instead, they are determined **dynamically** during /lean-implement execution through the 2-tier classification algorithm.

**Current Architecture** (No Upfront Declaration):
- /lean-plan creates phases with `lean_file:` metadata
- /lean-implement Block 1a-classify scans all phases and builds routing map at runtime
- No "## Phase Type Summary" or "Phase Classification" section in plan metadata

**Why Dynamic Classification is Preferred**:

1. **Single Source of Truth**: Phase metadata (`lean_file:` field) serves both as Lean file specification AND type indicator
2. **Flexibility**: Supports mixed Lean/software plans without manual type tagging
3. **Maintainability**: Type changes (e.g., converting software phase to Lean) only require metadata edit, not dual updates
4. **Automatic Detection**: /lean-implement auto-detects changes without plan regeneration

**Alternative Considered: Upfront Phase Type Summary**

Example (NOT recommended):
```markdown
## Phase Type Classification
- Lean Phases: 1, 2, 3 (theorem proving)
- Software Phases: 4, 5 (infrastructure)
```

**Drawbacks**:
- **Redundancy**: Duplicates information already in `lean_file:` metadata
- **Maintenance Burden**: Requires updating two locations on phase type changes
- **Inconsistency Risk**: Summary and metadata can drift out of sync
- **No Additional Value**: /lean-implement ignores summary, parses metadata directly

**Recommended Approach**: Maintain status quo (no upfront declaration). Phase types are inferred from per-phase `lean_file:` metadata.

**Documentation Enhancement** (optional):
Add usage note in lean-plan-command-guide.md explaining how /lean-implement determines phase types:

```markdown
## Phase Type Classification

/lean-implement automatically classifies phases as "lean" (theorem proving) or "software" (implementation) using a 2-tier detection algorithm:

1. **Tier 1 (Strongest Signal)**: Presence of `lean_file:` metadata
   - If phase has `lean_file: /path/to/file.lean` → classified as "lean"

2. **Tier 2 (Keyword Analysis)**: File extensions and keywords in phase content
   - Lean indicators: `.lean`, `theorem`, `lemma`, `sorry`, `tactic`, `mathlib`
   - Software indicators: `.ts`, `.js`, `.py`, `.sh`, `implement`, `create`

No manual phase type annotation required. Routing is automatic based on metadata.
```

## Current /lean-plan Command Structure

### Metadata Section Format (lean-plan-architect.md, lines 126-140)

**Current Template**:
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

**Observations**:
1. **Status before Estimated Hours**: Differs from /create-plan reference (Status should come after Scope)
2. **Missing optional fields**: Scope, Complexity Score, Structure Level, Estimated Phases
3. **Lean-specific fields present**: **Lean File** and **Lean Project** (valid per Plan Metadata Standard)
4. **Field order inconsistency**: Not aligned with recommended pattern

### Phase Heading Format (lean-plan-architect.md, lines 141-182)

**Current Format**:
```markdown
### Phase N: [Category Name] [NOT STARTED]
lean_file: /absolute/path/to/file.lean
dependencies: []
```

**Analysis**:
- **Heading Level**: `###` (level 3) - **CORRECT** per Plan Metadata Standard
- **Status Marker**: `[NOT STARTED]` - **CORRECT** for new plans
- **lean_file Field**: Immediately after heading - **OPTIMAL** for Tier 1 routing
- **dependencies Field**: Follows lean_file - **CORRECT** for wave execution

**Conclusion**: Phase heading format is already compliant with standards. No changes needed.

## /lean-implement Command Structure

### Routing Mechanism (Block 1a-classify and Block 1b)

**Block 1a-classify** (lean-implement.md, lines 383-573):
- Extracts all phases from plan file
- Classifies each phase using 2-tier algorithm
- Builds routing map: `phase_num:type:lean_file_path`
- Stores routing map in workspace file: `${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt`

**Routing Map Format**:
```
1:lean:/home/user/lean-project/ProofChecker/Truth.lean
2:lean:/home/user/lean-project/ProofChecker/Modal.lean
3:software:none
4:lean:/home/user/lean-project/ProofChecker/Basics.lean
```

**Block 1b** (lean-implement.md, lines 575-673):
- Reads routing map from workspace file
- Determines current phase number (from STARTING_PHASE or continuation)
- Parses phase entry to extract type and lean_file_path
- Routes to appropriate coordinator via Task tool

**Coordinator Invocation Decision**:
```bash
if [ "$PHASE_TYPE" = "lean" ]; then
  # Invoke lean-coordinator with lean_file_path
  Task { ... lean-coordinator.md ... }
else
  # Invoke implementer-coordinator
  Task { ... implementer-coordinator.md ... }
fi
```

**Metadata Needed for Routing**:
1. `lean_file:` per-phase metadata (Tier 1 signal)
2. Phase content keywords (Tier 2 fallback)
3. Phase number (for routing map lookup)

## Lean-Specific Agent Files

### lean-plan-architect.md Agent

**Role**: Create Lean implementation plans with theorem-level granularity

**Key Responsibilities** (STEP 2, lines 108-207):
1. Create plan file at exact PLAN_PATH provided by orchestrator
2. Include Lean-specific metadata (**Lean File**, **Lean Project**)
3. Create theorem-level phases with per-phase `lean_file:` metadata
4. Generate Goal, Strategy, Complexity for each theorem
5. Build dependency graph for wave-based execution

**Per-Phase File Targeting** (lines 88-103):
```markdown
**Per-Phase File Targeting** (CRITICAL for Tier 1 Discovery):

For each phase, you MUST specify the primary Lean file where theorems will be proven:

1. Review Formalization Goal: Identify which modules/files are affected
2. Identify Primary File: Select one Lean file per phase
3. Use Absolute Paths: Generate absolute path to .lean file
4. Add lean_file Field: Include `lean_file: /absolute/path` immediately after phase heading
5. Multi-File Plans: Assign each phase to its primary file
```

**Example Phase Generation** (lines 324-387):
```markdown
### Phase 1: Basic Commutativity Properties [NOT STARTED]
lean_file: /home/user/lean-project/ProofChecker/Basics.lean
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

**Self-Validation Checklist** (lines 268-279):
```markdown
Self-Verification Checklist:
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

### lean-implementer.md Agent

**Role**: Prove theorems using Lean 4 LSP integration and Mathlib search

**Input Contract** (lines 96-112):
```yaml
lean_file_path: /absolute/path/to/file.lean
topic_path: /absolute/path/to/topic/
artifact_paths:
  summaries: /topic/summaries/
  debug: /topic/debug/
max_attempts: 3
plan_path: ""  # Optional: Path to plan file for progress tracking
execution_mode: "file-based"  # "file-based" or "plan-based"
theorem_tasks: []  # Optional: Array of theorem objects (empty = all sorry markers)
rate_limit_budget: 3  # Number of external search requests allowed
wave_number: 1
phase_number: 0  # Phase number for progress tracking (0 if file-based)
continuation_context: null
```

**Mode Detection** (lines 164-207):
- **Batch mode**: `theorem_tasks` array is non-empty → process only specified theorems
- **File-based mode**: `theorem_tasks` is empty array → process ALL sorry markers in file

**Progress Tracking** (lines 139-159):
```bash
# Source checkbox-utils.sh for progress tracking (non-fatal)
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "Warning: Progress tracking unavailable"
}

# Mark phase IN PROGRESS if plan-based mode and library available
if [ -n "$PLAN_PATH" ] && [ "$PHASE_NUMBER" -gt 0 ]; then
  add_in_progress_marker "$PLAN_PATH" "$PHASE_NUMBER" 2>/dev/null
  echo "Progress tracking enabled for phase $PHASE_NUMBER"
fi
```

**Output Signal** (lines 646-688):
- File-based mode: `IMPLEMENTATION_COMPLETE` with full session summary
- Batch mode: `THEOREM_BATCH_COMPLETE` with wave-specific results
- Both modes include: theorems_proven, theorems_partial, tactics_used, work_remaining

## Plan Metadata Standard Reference

### Required Fields Summary (plan-metadata-standard.md, lines 23-84)

| Field | Format | Validation | Purpose |
|-------|--------|------------|---------|
| Date | `YYYY-MM-DD` or `YYYY-MM-DD (Revised)` | ISO 8601 + optional suffix | Creation/revision date |
| Feature | Single line, 50-100 chars | Non-empty, single line | What is being implemented |
| Status | `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, `[BLOCKED]` | Exact bracket notation | Current plan status |
| Estimated Hours | `{low}-{high} hours` | Numeric range with "hours" | Time estimate |
| Standards File | `/absolute/path/to/CLAUDE.md` | Absolute path starting with `/` | Standards traceability |
| Research Reports | Markdown links (relative paths) or `none` | Relative paths or literal "none" | Links to research |

### Recommended Optional Fields (lines 86-124)

| Field | Format | When to Include |
|-------|--------|-----------------|
| Scope | Multi-line description | Complexity > 60, multi-phase plans |
| Complexity Score | Numeric (0-100) | When plan-architect calculates it |
| Structure Level | `0`, `1`, or `2` | Always (tracks plan organization) |
| Estimated Phases | Numeric value | When known from initial assessment |

### Workflow-Specific Extensions (lines 126-156)

**Plan Metadata Standard Explicitly Permits**:
- /repair: Error Log Query, Errors Addressed
- /revise: Original Plan, Revision Reason
- **/lean-plan: Lean File, Lean Project** (acknowledged as valid extensions)

**Extension Mechanism** (lines 280-306):
```markdown
Adding Workflow-Specific Fields:
1. Define Field in Plan-Generating Command
2. Document Field in This Standard
3. Update Validator (Optional)
4. No Breaking Changes: Base required fields remain unchanged
```

## Existing Plan Analysis

### Current Metadata Format (001-lean-plan-formatting-standardize-plan.md, lines 3-14)

**Observed Format**:
```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Standardize /lean-plan output formatting...
- **Scope**: Update lean-plan-architect.md agent behavioral file...
- **Status**: [NOT STARTED]
- **Estimated Hours**: 2-3 hours
- **Complexity Score**: 18.0
- **Structure Level**: 0
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Plan Formatting Research](../reports/001-lean-plan-formatting-research.md)
```

**Observations**:
1. **Scope field present**: Multi-line description of updates
2. **Complexity Score present**: Numeric value from calculation
3. **Structure Level present**: Value 0 (single-file plan)
4. **Estimated Phases present**: Value 3 (matches phase count)
5. **Field order**: Date → Feature → Scope → Status → Estimated Hours → Complexity → Structure → Estimated Phases → Standards → Reports
6. **Missing Lean-specific fields**: No **Lean File** or **Lean Project** (NOT a Lean formalization plan)

**Conclusion**: This plan already follows the recommended /create-plan metadata format with all optional fields included.

### Phase Format Analysis (001-lean-plan-formatting-standardize-plan.md, lines 135-163)

**Phase 1 Example**:
```markdown
### Phase 1: Update Metadata Template in lean-plan-architect.md [NOT STARTED]
dependencies: []

**Objective**: Update metadata template in STEP 2 (lines 126-140)...

**Complexity**: Low

**Tasks**:
- [ ] Read lean-plan-architect.md to confirm current template location
- [ ] Update metadata template to new field order using Edit tool
- [ ] Add **Scope** field after **Feature** field with placeholder text
...
```

**Observations**:
1. **Heading format**: `### Phase 1:` (level 3) - **CORRECT**
2. **Status marker**: `[NOT STARTED]` - **CORRECT**
3. **dependencies field**: Empty array `[]` - **CORRECT**
4. **No lean_file field**: This is a software implementation plan (editing markdown files), NOT a Lean theorem-proving plan
5. **Task checkboxes**: Use `- [ ]` (unchecked) - **CORRECT**

**Conclusion**: Phase format follows Plan Metadata Standard correctly for software implementation plans.

## Gaps in Phase-Type Identification

### Current State

**What Works**:
1. /lean-plan generates `lean_file:` per-phase metadata for Lean theorem-proving phases
2. /lean-implement Tier 1 detection recognizes `lean_file:` as strongest classification signal
3. Routing map correctly identifies Lean vs software phases at runtime
4. lean-implementer receives correct lean_file_path for theorem proving

**What's Missing** (from perspective of metadata standardization):
1. **Metadata field order inconsistency**: /lean-plan template doesn't match /create-plan reference order
2. **Missing optional recommended fields**: Scope, Complexity Score, Structure Level, Estimated Phases not in template
3. **No upfront phase type summary**: But this is INTENTIONAL (dynamic classification preferred)

### Identified Gaps

**Gap 1: Metadata Template Field Order**
- **Issue**: lean-plan-architect.md template has Status before Estimated Hours
- **Expected**: Date → Feature → Scope (optional) → Status → Estimated Hours → ...
- **Impact**: Informational only - parsers use field labels, not order
- **Severity**: Low (cosmetic inconsistency)

**Gap 2: Missing Optional Recommended Fields**
- **Issue**: Template doesn't include Scope, Complexity Score, Structure Level, Estimated Phases
- **Expected**: Optional fields present for consistency with /create-plan
- **Impact**: Less metadata available for plan assessment and tooling
- **Severity**: Medium (functional gap in plan quality)

**Gap 3: No Scope Field Documentation**
- **Issue**: No guidance on what Scope should contain for Lean formalization plans
- **Expected**: Documentation of Scope field requirements (mathematical context, theorem category, formalization approach)
- **Impact**: Agents may not populate Scope field consistently
- **Severity**: Medium (documentation gap)

**No Gap Identified**: Phase-type identification
- **Reason**: `lean_file:` per-phase metadata already provides optimal routing signal
- **Status**: Working as designed, no changes needed

## Recommendations for Plan Revision

### Priority 1: Update Metadata Template Field Order (Phase 1)

**Action**: Modify lean-plan-architect.md STEP 2 metadata template (lines 126-140)

**Current Order**:
```markdown
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Status**: [NOT STARTED]
- **Estimated Hours**: [low]-[high] hours
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**: ...
- **Lean File**: [Absolute path]
- **Lean Project**: [Absolute path]
```

**Revised Order**:
```markdown
- **Date**: YYYY-MM-DD
- **Feature**: [One-line formalization description]
- **Scope**: [Mathematical context and formalization approach]
- **Status**: [NOT STARTED]
- **Estimated Hours**: [low]-[high] hours
- **Complexity Score**: [Numeric value from complexity calculation]
- **Structure Level**: 0
- **Estimated Phases**: [N from STEP 1 analysis]
- **Standards File**: [Absolute path to CLAUDE.md]
- **Research Reports**: ...
- **Lean File**: [Absolute path to .lean file for Tier 1 discovery]
- **Lean Project**: [Absolute path to lakefile.toml location]
```

**Rationale**:
- Aligns with /create-plan reference standard
- Adds optional recommended fields for plan quality
- Maintains Lean-specific fields at end (workflow extensions)
- No breaking changes (all additions, no removals)

### Priority 2: Add Scope Field Documentation (Phase 2)

**Action**: Add documentation section after metadata template in lean-plan-architect.md

**Content** (to be inserted after line 140):
```markdown
**Scope Field Guidelines**:

For Lean formalization plans, the Scope field should provide mathematical context and formalization approach:

1. **Mathematical Domain**: Area of mathematics (algebra, analysis, topology, logic, etc.)
2. **Theorem Category**: Specific topic or property being formalized
3. **Formalization Methodology**: Approach (blueprint-based, interactive, direct proof, etc.)
4. **Expected Deliverables**: Theorem count, modules, proof structure

**Length**: 2-3 sentences recommended

**Example**:
- **Scope**: Formalize group homomorphism preservation properties in abstract algebra. Prove 8 theorems covering identity preservation, inverse preservation, and composition. Output: ProofChecker/GroupHom.lean module with complete proofs.
```

**Rationale**:
- Provides clear guidance for agents on Scope field content
- Ensures mathematical context is captured for Lean formalization plans
- Follows documentation standards (clear, concise, example-driven)

### Priority 3: Update lean-plan-command-guide.md (Phase 3)

**Action**: Add "Plan Metadata Format" section documenting standardized field order

**Section Content**:
```markdown
## Plan Metadata Format

/lean-plan generates implementation plans with standardized metadata following the Plan Metadata Standard:

### Required Fields (6)
- **Date**: Plan creation date (YYYY-MM-DD format)
- **Feature**: One-line formalization description (50-100 characters)
- **Status**: Current plan status ([NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED])
- **Estimated Hours**: Time estimate as numeric range (e.g., "8-12 hours")
- **Standards File**: Absolute path to CLAUDE.md for standards traceability
- **Research Reports**: Markdown links to research reports or `none` if no research phase

### Recommended Optional Fields (4)
- **Scope**: Mathematical context and formalization approach (2-3 sentences)
- **Complexity Score**: Numeric complexity score (0-100) from plan-architect calculation
- **Structure Level**: Plan organization tier (always 0 for Lean plans - single-file structure)
- **Estimated Phases**: Phase count estimate from initial analysis

### Lean-Specific Workflow Extension Fields (2)
- **Lean File**: Absolute path to target .lean file for Tier 1 discovery
- **Lean Project**: Absolute path to Lean project root (lakefile.toml location)

### Field Order
Metadata fields appear in this order:
1. Date
2. Feature
3. Scope (if present)
4. Status
5. Estimated Hours
6. Complexity Score (if present)
7. Structure Level (if present)
8. Estimated Phases (if present)
9. Standards File
10. Research Reports
11. Lean File
12. Lean Project

### Example Metadata Block
[Include complete example showing all fields]

For complete metadata standard documentation, see [Plan Metadata Standard](../../reference/standards/plan-metadata-standard.md).
```

**Rationale**:
- Documents metadata format for user and agent reference
- Clarifies required vs optional vs Lean-specific fields
- Provides complete example for consistency
- Links to authoritative standard documentation

### Priority 4: No Changes to Phase Metadata Format

**Recommendation**: **Do NOT modify** the phase-level metadata format in lean-plan-architect.md

**Rationale**:
1. Current format already optimal for /lean-implement routing
2. `lean_file:` per-phase metadata is PRIMARY Tier 1 signal
3. Phase heading format (`### Phase N:`) already correct per standard
4. Dependencies format (`dependencies: []`) already correct for wave execution
5. No gaps identified in phase-type identification mechanism

**Existing Format to Preserve**:
```markdown
### Phase N: [Category Name] [NOT STARTED]
lean_file: /absolute/path/to/file.lean
dependencies: []

**Objective**: ...
**Complexity**: ...
**Theorems**: ...
```

## References

1. **Plan Metadata Standard**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md`
2. **lean-plan Command**: `/home/benjamin/.config/.claude/commands/lean-plan.md`
3. **lean-implement Command**: `/home/benjamin/.config/.claude/commands/lean-implement.md`
4. **lean-plan-architect Agent**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`
5. **lean-implementer Agent**: `/home/benjamin/.config/.claude/agents/lean-implementer.md`
6. **Existing Plan**: `/home/benjamin/.config/.claude/specs/051_lean_plan_formatting_standardize/plans/001-lean-plan-formatting-standardize-plan.md`

REPORT_CREATED: /home/benjamin/.config/.claude/specs/051_lean_plan_formatting_standardize/reports/revision_lean_plan_metadata_research.md

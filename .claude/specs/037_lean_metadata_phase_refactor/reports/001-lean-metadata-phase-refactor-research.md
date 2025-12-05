# Lean Metadata Phase Refactor Research Report

## Metadata
- **Date**: 2025-12-04
- **Agent**: research-specialist
- **Topic**: Refactor Lean plan metadata to specify target Lean files per-phase instead of globally
- **Research Complexity**: 3
- **Report Type**: Lean command infrastructure research

---

## Executive Summary

This report analyzes the current Lean plan metadata structure and command infrastructure to design a phase-level Lean file specification system. Currently, /lean-plan and /lean-build use a **global "Lean File:" metadata field** (Tier 2 discovery) that applies to all phases. The goal is to refactor to **per-phase "lean_file:" specifications** (Tier 1 discovery) enabling different phases to target different Lean files.

**Key Findings**:
1. **/lean-build uses 2-tier discovery**: Tier 1 (phase-specific `lean_file:`) preferred, Tier 2 (global `**Lean File**:`) fallback
2. **lean-coordinator delegates to lean-implementer** with phase-specific file information via `theorem_tasks` array
3. **Current plans use global metadata only** - no existing phase-level examples
4. **Backward compatibility needed** - Tier 2 fallback ensures existing plans work

**Recommended Approach**:
- Add `lean_file:` field immediately after phase heading (Tier 1 format)
- Keep Tier 2 global metadata as fallback for single-file plans
- Update lean-plan-architect to include phase-level `lean_file:` specifications
- lean-coordinator already supports per-phase file extraction via theorem_tasks

---

## Current Metadata Structure Analysis

### Global Metadata Format (Tier 2 - Current Standard)

**Location**: /lean-build command (lines 46-73)

The current standard uses markdown list format in the plan metadata section:

```markdown
## Metadata
- **Date**: 2025-12-03
- **Feature**: Modal Logic Proofs
- **Lean File**: /absolute/path/to/file.lean
```

**Format Requirements**:
- Must use markdown list format: `- **Lean File**: /path`
- Must include hyphen prefix and space
- Asterisks mark bold text in markdown

**Discovery Priority** (from /lean-build lines 61-73):
1. Tier 1 attempted first: `lean_file:` after phase heading
2. Tier 2 fallback: `- **Lean File**:` in metadata section
3. Error if both fail

**Example from Reference Plan** (/home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/035_semantics_temporal_order_generalization/plans/001-semantics-temporal-order-generalization-plan.md, line 11):

```markdown
- **Lean File**: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/ProofChecker/Semantics/TaskFrame.lean
```

**Limitation**: Single file applies to ALL phases - cannot target different files per phase.

---

## Tier 1 Discovery Format (Desired State)

### Phase-Specific Metadata Format

**Location**: /lean-build command documentation (lines 30-42)

The Tier 1 format (preferred but not yet used in practice) specifies files per-phase:

```markdown
### Phase 1: Prove Theorems [NOT STARTED]
lean_file: /absolute/path/to/file.lean

**Tasks**:
- [ ] Prove theorem_add
```

**Format Requirements**:
- Must appear immediately after phase heading (no blank lines)
- Format: `lean_file: /absolute/path` (no markdown bold/list syntax)
- Lowercase `lean_file:` keyword
- Absolute paths required

**Discovery Implementation** (/lean-build lines 206-242):

```bash
# Tier 1: Extract phase-specific lean_file metadata
LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
  BEGIN { in_phase=0 }
  /^### Phase / {
    if (index($0, "Phase " target ":") > 0) {
      in_phase = 1
    } else {
      in_phase = 0
    }
    next
  }
  in_phase && /^lean_file:/ {
    sub(/^lean_file:[[:space:]]*/, "")
    print
    exit
  }
' "$PLAN_FILE")
```

**Multi-File Support** (lines 269-286):
- Tier 1 can specify comma-separated files: `lean_file: file1.lean, file2.lean`
- Parsed into array for sequential processing
- Each file validated before processing

**Benefits**:
- Faster than Tier 2 (no full-file grep)
- Phase-specific targeting enables multi-file workflows
- Consistent with other metadata conventions (lowercase, colon-separated)

---

## Command Infrastructure Analysis

### /lean-plan Command Workflow

**Location**: /home/benjamin/.config/.claude/commands/lean-plan.md

**Metadata Generation** (Block 2, lines 1115-1129):

```markdown
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_LIST=$(echo "$REPORT_PATHS" | tr '\n' ' ')

# === PERSIST FOR BLOCK 3 (BULK OPERATION) ===
append_workflow_state_bulk <<EOF
PLAN_PATH=$PLAN_PATH
REPORT_PATHS_LIST=$REPORT_PATHS_LIST
EOF
```

**Agent Invocation** (Block 2, lines 1194-1260):

The lean-plan-architect agent receives:
- `PLAN_PATH`: Output file location
- `LEAN_PROJECT_PATH`: Lean project root
- `FEATURE_DESCRIPTION`: User prompt
- `REPORT_PATHS_LIST`: Research reports
- `FORMATTED_STANDARDS`: Project standards

**Critical Format Requirements** (lines 1226-1250):

```markdown
**CRITICAL FORMAT REQUIREMENTS FOR NEW PLANS**:
- Metadata **Status** MUST be `[NOT STARTED]`
- ALL phase headings MUST include `[NOT STARTED]` marker
- ALL theorem checkboxes MUST use `- [ ]` (unchecked)
- ALL theorems MUST have Goal specification
- ALL theorems MUST have Strategy (proof approach)
- ALL theorems MUST have Complexity (Simple/Medium/Complex)
- Dependencies MUST use `dependencies: [...]` format

Include Lean-specific metadata:
- Include **Lean File** field (absolute path for Tier 1 discovery)
- Include **Lean Project** field (lakefile.toml location)
```

**Current Implementation**: lean-plan-architect generates global `**Lean File**` metadata only (Tier 2 format).

---

### /lean-build Command Workflow

**Location**: /home/benjamin/.config/.claude/commands/lean-build.md

**Discovery Mechanism** (Block 1a, lines 206-278):

1. **Starting Phase Detection** (line 215):
   ```bash
   STARTING_PHASE=1
   ```

2. **Tier 1 Phase-Specific Search** (lines 221-242):
   - Searches for `lean_file:` after phase heading
   - Uses awk to find phase by number
   - Extracts file path or comma-separated list

3. **Tier 2 Global Fallback** (lines 244-256):
   - Searches for `- **Lean File**:` in metadata section
   - Uses grep with markdown list format

4. **Error on Failure** (lines 259-277):
   - Provides clear instructions for both Tier 1 and Tier 2 formats
   - Exits with validation_error

**Multi-File Processing** (lines 280-308):
- Parses comma-separated files into LEAN_FILES array
- Validates each file exists
- Stores first file as primary, rest in JSON array
- Passes to coordinator for sequential processing

**Backward Compatibility**: Tier 2 fallback ensures existing plans with global metadata continue working.

---

### lean-coordinator Agent Workflow

**Location**: /home/benjamin/.config/.claude/agents/lean-coordinator.md

**Input Contract** (lines 28-58):

```yaml
plan_path: /path/to/specs/028_lean/plans/001-lean-plan.md
lean_file_path: /path/to/project/Theorems.lean
topic_path: /path/to/specs/028_lean
artifact_paths:
  summaries: /path/to/specs/028_lean/summaries/
  outputs: /path/to/specs/028_lean/outputs/
  checkpoints: /home/user/.claude/data/checkpoints/
continuation_context: null
iteration: 1
max_iterations: 5
context_threshold: 85
```

**Phase Processing** (lines 296-309):

The coordinator extracts `phase_number` from theorem metadata:

```bash
# Each theorem in theorem_tasks includes phase_number
# Example: {"name": "theorem_add_comm", "line": 42, "phase_number": 1}

# Extract phase_number for current theorem
phase_num=$(echo "$theorem_obj" | jq -r '.phase_number // 0')

# Pass to lean-implementer for progress marker updates
# - If phase_num > 0: Enable progress tracking
# - If phase_num = 0: File-based mode, skip progress tracking
```

**Implementer Invocation** (lines 344-436):

For each theorem in wave, coordinator invokes lean-implementer with:

```yaml
Input:
- lean_file_path: /path/to/Theorems.lean
- theorem_tasks: [{"name": "theorem_add_comm", "line": 42, "phase_number": 1}]
- plan_path: /path/to/plan.md
- rate_limit_budget: 1
- execution_mode: "plan-based"
- wave_number: 1
- phase_number: 1
```

**Key Insight**: The coordinator **already supports per-phase file specification** through the `theorem_tasks` array - each theorem can have a different source file. The missing piece is the plan format to specify per-phase files.

---

### lean-implementer Agent Workflow

**Location**: /home/benjamin/.config/.claude/agents/lean-implementer.md

**Input Contract** (lines 93-111):

```yaml
lean_file_path: /absolute/path/to/file.lean
topic_path: /absolute/path/to/topic/
artifact_paths:
  summaries: /topic/summaries/
  debug: /topic/debug/
max_attempts: 3
plan_path: ""  # Empty for file-based mode
execution_mode: "file-based"  # or "plan-based"
theorem_tasks: []  # Empty = all sorry markers, non-empty = specific theorems
rate_limit_budget: 3
wave_number: 1
phase_number: 0  # 0 for file-based, >0 for plan-based
```

**Theorem Processing** (lines 163-206):

```bash
# Check execution mode based on theorem_tasks
LEAN_FILE="$1"  # From input contract
THEOREM_TASKS="$2"  # From input contract (JSON array or empty array)

if echo "$THEOREM_TASKS" | jq -e 'length > 0' >/dev/null 2>&1; then
  # Batch mode: Process only specified theorems
  theorem_lines=$(echo "$THEOREM_TASKS" | jq -r '.[] | "\(.line):\(.name)"')
else
  # File-based mode: Process ALL sorry markers
  sorry_lines=$(grep -n "sorry" "$LEAN_FILE" || echo "")
fi
```

**Key Insight**: lean-implementer receives a **single lean_file_path** per invocation. For multi-file workflows, coordinator must invoke implementer multiple times with different files.

**Multi-File Processing** (lines 51-91):

The agent documentation describes multi-file processing:

```markdown
### 7. Multi-File Processing
When the input contract includes multiple lean files (LEAN_FILES array):

1. Iterate through each file sequentially
2. Aggregate results across all files
3. Per-file progress tracking
4. Continuation context preservation
```

However, the implementer processes ONE file at a time - the coordinator handles multi-file orchestration.

---

## lean-plan-architect Agent Analysis

**Location**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md

**Plan Creation Pattern** (lines 90-163):

Currently generates **global metadata only**:

```markdown
## Metadata
- **Lean File**: [Absolute path for Tier 1 discovery]
- **Lean Project**: [Absolute path to lakefile.toml location]
```

**Phase Format Template** (lines 124-162):

```markdown
### Phase N: [Category Name] [NOT STARTED]
dependencies: [list of prerequisite phase numbers, or empty list]

**Objective**: [What this phase accomplishes]

**Theorems**:
- [ ] `theorem_name`: [One-line description]
  - Goal: `[Lean 4 type signature]`
  - Strategy: [Proof approach]
  - Complexity: Simple|Medium|Complex
  - Prerequisites: [Other theorems needed]
  - Estimated: [hours] hours
```

**Missing**: No `lean_file:` field in phase template.

**Required Change**: Update phase template to include:

```markdown
### Phase N: [Category Name] [NOT STARTED]
lean_file: /absolute/path/to/file.lean
dependencies: []
```

---

## Reference Plan Structure Example

**Source**: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/035_semantics_temporal_order_generalization/plans/001-semantics-temporal-order-generalization-plan.md

**Global Metadata** (lines 3-14):

```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Generalize temporal domain from Int to LinearOrderedAddCommGroup
- **Status**: [NOT STARTED]
- **Estimated Hours**: 30-47 hours
- **Standards File**: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/CLAUDE.md
- **Research Reports**:
  - [Semantics Temporal Order Generalization Research](../reports/001-semantics-temporal-order-generalization-research.md)
- **Lean File**: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/ProofChecker/Semantics/TaskFrame.lean
- **Lean Project**: /home/benjamin/Documents/Philosophy/Projects/ProofChecker
```

**Phase Structure** (lines 42-86):

```markdown
## Phase 0: Standards Validation and Type Alias Preparation [IN PROGRESS]
dependencies: []

**Objective**: Validate generalization against CLAUDE.md standards

**Complexity**: Low

**Tasks**:
- [ ] Review LEAN Style Guide for typeclass parameter conventions
  - Goal: Confirm `(T : Type*)` vs `{T : Type*}` convention
  - Strategy: Check CLAUDE.md and LEAN_STYLE_GUIDE.md
  - Complexity: Simple
  - Estimated: 0.5 hours
```

**Observation**: No phase-level `lean_file:` specification - all phases implicitly target the same file from global metadata.

**Limitation for Multi-File Plans**:
- Phase 0 might work on CLAUDE.md (documentation)
- Phase 1 might work on TaskFrame.lean
- Phase 2 might work on WorldHistory.lean
- Current format cannot distinguish these targets

---

## Proposed Refactoring Design

### Per-Phase Lean File Specification

**Format**:

```markdown
### Phase 1: TaskFrame Generalization [NOT STARTED]
lean_file: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/ProofChecker/Semantics/TaskFrame.lean
dependencies: []

**Objective**: Parameterize TaskFrame structure by temporal group type

**File**: ProofChecker/Semantics/TaskFrame.lean

**Theorems/Changes**:
- [ ] Generalize `TaskFrame` structure definition
  - Goal: `structure TaskFrame (T : Type*) [LinearOrderedAddCommGroup T] where`
  - Strategy: Add type parameter and typeclass constraint
  - Complexity: Medium
  - Estimated: 2 hours
```

**Key Elements**:
1. `lean_file:` immediately after phase heading (Tier 1 format)
2. Absolute path to target Lean file
3. Optional `**File**:` field in phase body for human readability (relative path)
4. `dependencies: []` for phase dependency tracking

### Multi-File Plan Example

**Scenario**: Generalization touches multiple Lean modules

```markdown
## Metadata
- **Lean File**: /path/to/primary/file.lean  # Fallback for Tier 2
- **Lean Project**: /path/to/project

---

### Phase 1: TaskFrame Generalization [NOT STARTED]
lean_file: /home/benjamin/ProofChecker/ProofChecker/Semantics/TaskFrame.lean
dependencies: []

**Objective**: Parameterize TaskFrame structure
**File**: ProofChecker/Semantics/TaskFrame.lean
**Theorems**: [...]

---

### Phase 2: WorldHistory Generalization [NOT STARTED]
lean_file: /home/benjamin/ProofChecker/ProofChecker/Semantics/WorldHistory.lean
dependencies: [1]

**Objective**: Generalize WorldHistory and add convexity
**File**: ProofChecker/Semantics/WorldHistory.lean
**Theorems**: [...]

---

### Phase 3: Truth Evaluation Generalization [NOT STARTED]
lean_file: /home/benjamin/ProofChecker/ProofChecker/Semantics/Truth.lean
dependencies: [2]

**Objective**: Update truth evaluation to use polymorphic temporal type
**File**: ProofChecker/Semantics/Truth.lean
**Theorems**: [...]
```

**Discovery Behavior**:
- /lean-build extracts `lean_file:` from each phase (Tier 1)
- lean-coordinator groups theorems by phase and file
- lean-implementer invoked once per file with relevant theorems
- Progress tracking updates correct phase markers

**Backward Compatibility**:
- If `lean_file:` missing from phase, fall back to global `**Lean File**:`
- Single-file plans work unchanged
- Multi-file plans gain explicit per-phase targeting

---

## Implementation Requirements

### 1. lean-plan-architect Agent Changes

**File**: /home/benjamin/.config/.claude/agents/lean-plan-architect.md

**Change 1: Update Phase Template** (lines 300-330):

Add `lean_file:` to phase format template:

```markdown
### Phase N: [Category Name] [NOT STARTED]
lean_file: /absolute/path/to/file.lean
dependencies: [list of prerequisite phase numbers]

**Objective**: [What this phase accomplishes]
**File**: [Relative path for human readability]
**Complexity**: [Low|Medium|High]

**Theorems**:
- [ ] `theorem_name`: [Description]
  - Goal: `[Lean 4 type]`
  - Strategy: [Proof approach]
  - Complexity: Simple|Medium|Complex
```

**Change 2: Update Creation Instructions** (lines 124-179):

```markdown
4. **Create Theorem-Level Phases**:

Each phase should include:
- Phase heading with status marker
- **lean_file:** Absolute path to target Lean file (NEW)
- **dependencies:** Array of prerequisite phase numbers
- Objective, Complexity, and Theorems sections
```

**Change 3: Add File Selection Guidance** (lines 60-85):

```markdown
**Per-Phase File Targeting**:
For each phase, determine the primary Lean file:
1. Review formalization goal and identify affected modules
2. Assign one primary file per phase based on theorem locations
3. If multiple files needed in one phase, list primary first
4. Use absolute paths for lean_file: specification
5. Include relative path in **File:** field for readability
```

### 2. /lean-build Command Changes

**File**: /home/benjamin/.config/.claude/commands/lean-build.md

**No changes needed** - Tier 1 discovery already implemented (lines 206-242).

**Validation**: Verify multi-file support works correctly (lines 280-308).

### 3. lean-coordinator Agent Changes

**File**: /home/benjamin/.config/.claude/agents/lean-coordinator.md

**Enhancement: Per-Phase File Grouping** (new section after line 162):

```markdown
### Phase-File Association

When building theorem_tasks for implementer invocation:

1. **Extract lean_file from Phase Metadata**:
   ```bash
   PHASE_LEAN_FILE=$(awk -v target="$phase_num" '
     /^### Phase / && index($0, "Phase " target ":") {
       getline
       if (/^lean_file:/) {
         sub(/^lean_file:[[:space:]]*/, "")
         print
         exit
       }
     }
   ' "$plan_path")
   ```

2. **Fallback to Global Metadata** if phase-specific not found
3. **Group Theorems by File**: If multiple phases target same file, batch theorems
4. **Invoke Implementer Per File**: One invocation per distinct file in wave
```

**No breaking changes** - coordinator already receives `lean_file_path` and passes to implementer.

### 4. Documentation Updates

**Files to Update**:
- /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md
- /home/benjamin/.config/.claude/docs/guides/commands/lean-build-command-guide.md (if exists)

**Content**:
- Explain Tier 1 vs Tier 2 discovery
- Provide multi-file plan examples
- Document phase-level lean_file: syntax
- Show backward compatibility with global metadata

---

## Migration Strategy

### For Existing Plans

**No Breaking Changes**:
- Existing plans with global `**Lean File**:` continue working (Tier 2)
- /lean-build falls back to global metadata if phase-specific missing
- No immediate action required

**Optional Migration**:
1. Identify phases targeting different files
2. Add `lean_file:` after each phase heading
3. Keep global `**Lean File**:` for backward compatibility
4. Test with /lean-build to verify Tier 1 discovery

**Example Migration**:

**Before** (global only):
```markdown
## Metadata
- **Lean File**: /path/to/TaskFrame.lean

### Phase 1: TaskFrame [NOT STARTED]
### Phase 2: WorldHistory [NOT STARTED]
```

**After** (per-phase with fallback):
```markdown
## Metadata
- **Lean File**: /path/to/TaskFrame.lean  # Fallback

### Phase 1: TaskFrame [NOT STARTED]
lean_file: /path/to/TaskFrame.lean
### Phase 2: WorldHistory [NOT STARTED]
lean_file: /path/to/WorldHistory.lean
```

### For New Plans

**lean-plan-architect Generates**:
1. Analyze feature description and identify affected files
2. Assign lean_file: per phase based on theorem locations
3. Include global **Lean File**: for backward compatibility
4. Add relative **File**: field in phase body for readability

**Validation**:
- /lean-build Tier 1 discovery extracts phase-specific files
- lean-coordinator groups theorems by file
- Progress tracking updates correct phase markers

---

## Risks and Mitigations

### Risk 1: Existing Plans Break

**Likelihood**: Low
**Impact**: High

**Mitigation**:
- Tier 2 fallback maintains backward compatibility
- Existing plans work unchanged
- Only new multi-file plans use Tier 1

### Risk 2: Coordinator File Grouping Complexity

**Likelihood**: Medium
**Impact**: Medium

**Mitigation**:
- Coordinator already handles theorem_tasks with file info
- File grouping is algorithmic (group by lean_file_path)
- Test with multi-file plan before production

### Risk 3: Phase-File Mismatch

**Likelihood**: Low
**Impact**: Medium

**Mitigation**:
- Validate lean_file: paths exist during plan creation
- lean-build validates file existence before coordinator invocation
- Clear error messages for missing files

### Risk 4: Documentation Lag

**Likelihood**: High
**Impact**: Low

**Mitigation**:
- Update command guides immediately after implementation
- Provide migration examples in documentation
- Add troubleshooting section for Tier 1/Tier 2 discovery

---

## Testing Strategy

### Unit Tests

1. **Tier 1 Discovery Test**:
   ```bash
   # Create test plan with phase-level lean_file:
   cat > test_plan.md <<EOF
   ### Phase 1: Test [NOT STARTED]
   lean_file: /path/to/file1.lean
   EOF

   # Verify /lean-build extracts correct file
   /lean-build test_plan.md
   ```

2. **Tier 2 Fallback Test**:
   ```bash
   # Create plan with global metadata only
   cat > test_plan.md <<EOF
   ## Metadata
   - **Lean File**: /path/to/file.lean

   ### Phase 1: Test [NOT STARTED]
   EOF

   # Verify fallback works
   /lean-build test_plan.md
   ```

3. **Multi-File Test**:
   ```bash
   # Create plan with different files per phase
   cat > test_plan.md <<EOF
   ### Phase 1: Test1 [NOT STARTED]
   lean_file: /path/to/file1.lean
   ### Phase 2: Test2 [NOT STARTED]
   lean_file: /path/to/file2.lean
   EOF

   # Verify coordinator groups correctly
   /lean-build test_plan.md --prove-all
   ```

### Integration Tests

1. **Full Workflow Test**:
   - /lean-plan generates multi-file plan
   - /lean-build discovers per-phase files
   - lean-coordinator groups theorems by file
   - lean-implementer processes each file
   - Progress tracking updates correct phases

2. **Backward Compatibility Test**:
   - Use existing plan with global metadata only
   - Verify Tier 2 fallback works
   - Verify no regressions in single-file workflow

---

## References

### Commands
- `/lean-plan`: /home/benjamin/.config/.claude/commands/lean-plan.md
- `/lean-build`: /home/benjamin/.config/.claude/commands/lean-build.md

### Agents
- `lean-plan-architect`: /home/benjamin/.config/.claude/agents/lean-plan-architect.md
- `lean-coordinator`: /home/benjamin/.config/.claude/agents/lean-coordinator.md
- `lean-implementer`: /home/benjamin/.config/.claude/agents/lean-implementer.md
- `lean-research-specialist`: /home/benjamin/.config/.claude/agents/lean-research-specialist.md

### Example Plan
- Reference: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/035_semantics_temporal_order_generalization/plans/001-semantics-temporal-order-generalization-plan.md

### Documentation
- Lean Build Command Guide: /home/benjamin/.config/.claude/docs/guides/commands/lean-build-command-guide.md (check if exists)
- Lean Plan Command Guide: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md

---

## Conclusion

The refactoring to per-phase Lean file specification is **well-supported by existing infrastructure**:

1. **/lean-build already implements Tier 1 discovery** - no command changes needed
2. **lean-coordinator supports per-phase file handling** - minor enhancement for file grouping
3. **lean-implementer processes one file at a time** - no changes needed
4. **lean-plan-architect needs phase template update** - add lean_file: field

**Backward compatibility preserved** through Tier 2 fallback to global metadata.

**Primary Implementation Task**: Update lean-plan-architect agent's phase template to include `lean_file:` specification immediately after phase heading.

**Secondary Enhancement**: Add file-grouping logic to lean-coordinator for efficient multi-file wave execution (optional optimization).

**No Breaking Changes**: Existing plans continue working via Tier 2 discovery mechanism.

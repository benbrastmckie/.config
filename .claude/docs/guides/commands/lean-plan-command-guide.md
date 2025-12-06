# Lean Plan Command Guide

## Overview

The `/lean-plan` command creates Lean-specific implementation plans for theorem proving projects with theorem-level granularity, Mathlib research, proof strategies, and dependency tracking.

**When to Use**:
- Planning Lean 4 formalization projects
- Designing theorem proving workflows
- Structuring large proof developments
- Preparing for wave-based parallel proving with `/lean`

**When NOT to Use**:
- General software implementation (use `/plan` instead)
- Single theorem proving (use `/lean` directly)
- Non-Lean programming tasks

---

## Syntax

```bash
/lean-plan "<feature-description>" [--file <path>] [--complexity 1-4] [--project <path>]
```

### Arguments

- **`<feature-description>`** (required): Natural language description of formalization goal
  - Example: `"formalize group homomorphism properties"`
  - Example: `"prove basic arithmetic commutativity theorems"`

- **`--file <path>`** (optional): Path to file with detailed formalization prompt
  - Use when formalization description is too long for command line
  - File content replaces `<feature-description>`
  - Path can be absolute or relative to current directory

- **`--complexity 1-4`** (optional, default: 3): Research depth level
  - **1** (Quick): Minimal Mathlib search, 2-3 namespaces
  - **2** (Standard): 5-7 namespaces, basic WebSearch
  - **3** (Deep): 10+ namespaces, comprehensive documentation search
  - **4** (Exhaustive): Full Mathlib survey, advanced pattern analysis

- **`--project <path>`** (optional): Explicit Lean project path
  - Auto-detected if omitted (searches for `lakefile.toml` upward from cwd)
  - Use when working outside project directory
  - Path can be absolute or relative

---

## Lean File Metadata Formats

The `/lean-plan` command generates plans with 2-tier Lean file discovery to support both single-file and multi-file theorem proving workflows.

### Tier 1: Phase-Specific File Metadata (Preferred)

**Format**: `lean_file: /absolute/path` immediately after phase heading

**Location**: After `### Phase N:` heading, before `dependencies:` field

**Example**:
```markdown
### Phase 1: Basic Commutativity Properties [NOT STARTED]
lean_file: /home/user/ProofChecker/ProofChecker/Basics.lean
dependencies: []

**Objective**: Prove commutativity for addition and multiplication
```

**Discovery Priority**: Tier 1 is checked FIRST by `/lean-build` command

**Use Case**: Multi-file plans where different phases target different .lean files

**Advantages**:
- Enables precise file targeting per phase
- Supports complex multi-module formalizations
- Faster discovery (no metadata section parsing)
- Enables parallel proving across different files

### Tier 2: Global File Metadata (Fallback)

**Format**: `- **Lean File**: /absolute/path` in metadata section

**Location**: Metadata section at top of plan file

**Example**:
```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Formalize group properties
- **Scope**: Formalize basic group theory properties including associativity and identity. Output: Groups.lean with 5 theorems.
- **Status**: [NOT STARTED]
- **Estimated Hours**: 4-6 hours
- **Complexity Score**: 30.0
- **Structure Level**: 0
- **Estimated Phases**: 2
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**: [Link to research](../reports/001-research.md)
- **Lean File**: /home/user/ProofChecker/ProofChecker/Groups.lean
- **Lean Project**: /home/user/ProofChecker/
```

**Discovery Priority**: Tier 2 is checked ONLY if Tier 1 discovery returns empty

**Use Case**: Single-file plans where all phases target the same .lean file

**Advantages**:
- Simple format for single-file workflows
- Backward compatible with existing plans
- Single source of truth for project-wide file path

### Discovery Mechanism

The `/lean-build` command uses this 2-tier discovery algorithm:

```
For each phase:
  1. Search for `lean_file:` after phase heading (Tier 1)
  2. If found: Use phase-specific file
  3. If empty: Fall back to global **Lean File** in metadata (Tier 2)
  4. If both empty: Error with format examples
```

**Key Points**:
- Tier 1 has precedence over Tier 2
- No blank lines allowed between phase heading and `lean_file:`
- Absolute paths required (relative paths not supported)
- Both tiers can coexist (Tier 1 overrides Tier 2 per phase)

### When to Use Each Tier

**Use Tier 1** (phase-specific):
- Multi-file formalizations (different phases target different files)
- Large projects with modular structure
- When phases have distinct file boundaries
- When evolving from single-file to multi-file structure

**Use Tier 2** (global):
- Single-file formalizations (all theorems in one file)
- Simple projects with one primary module
- When all phases target the same file
- For backward compatibility with existing plans

**Use Both**:
- Tier 2 as fallback for phases without explicit `lean_file:`
- Tier 1 overrides for phases targeting different files
- Gradual migration from single-file to multi-file structure

---

## Usage Examples

### Example 1: Basic Usage

```bash
cd ~/ProofChecker
/lean-plan "formalize basic arithmetic commutativity theorems"
```

**Result**:
- Auto-detects Lean project in current directory
- Creates research reports with Mathlib theorem discoveries
- Creates implementation plan with theorem specifications
- Default complexity level 3 (deep research)

### Example 2: Using `--file` Flag (Long Prompt)

```bash
# Create detailed prompt file
cat > formalization-spec.md <<EOF
# Group Homomorphism Formalization

Formalize the following theorems about group homomorphisms:

1. Identity preservation: f(0) = 0
2. Operation preservation: f(a + b) = f(a) + f(b)
3. Inverse preservation: f(-a) = -f(a)
4. Kernel properties

Include proofs that compose and relate these properties.
EOF

/lean-plan --file formalization-spec.md --complexity 3
```

**Result**:
- Reads detailed prompt from file
- Archives prompt file in `specs/NNN_topic/prompts/`
- Creates comprehensive research reports
- Creates plan with dependency tracking for related theorems

### Example 3: Using `--project` Flag (Explicit Project)

```bash
# Working from different directory
cd ~/Documents
/lean-plan "prove list reversal properties" --project ~/ProofChecker
```

**Result**:
- Uses Lean project at `~/ProofChecker` (not current directory)
- Searches for existing proofs in that project
- Creates specs in `.claude/specs/` within ProofChecker project

### Example 4: Using `--complexity` Flag

```bash
# Quick plan for simple theorems (complexity 2)
/lean-plan "prove Nat.add_comm using Mathlib" --complexity 2

# Exhaustive research for complex formalization (complexity 4)
/lean-plan "formalize category theory functors" --complexity 4
```

**Result (complexity 2)**:
- Quick Mathlib search (5-7 namespaces)
- Faster planning (2-3 minutes)

**Result (complexity 4)**:
- Comprehensive Mathlib survey
- Deep pattern analysis
- Longer planning (10-15 minutes)

### Example 5: Complete Workflow (Plan → Execute)

```bash
# Step 1: Create plan
/lean-plan "formalize ring homomorphism theorems" --complexity 3

# Step 2: Review plan
cat .claude/specs/*/plans/*.md

# Step 3: Execute plan with /lean
/lean .claude/specs/*/plans/*.md --prove-all

# Step 4: Iterate if needed
/lean .claude/specs/*/plans/*.md --max-iterations=5
```

### Example 6: Multi-File Plan

For formalizations spanning multiple Lean files, `/lean-plan` generates phase-specific `lean_file:` specifications:

```bash
# Create multi-module formalization plan
/lean-plan "formalize task execution framework with TaskFrame, WorldHistory, and Truth modules" --complexity 3
```

**Generated Plan Structure** (with phase-specific files):

```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Formalize task execution framework
- **Scope**: Formalize task execution framework with state transitions and task composition. Output: 3 modules (TaskFrame.lean, WorldHistory.lean, Truth.lean) with 15 theorems.
- **Status**: [NOT STARTED]
- **Estimated Hours**: 12-18 hours
- **Complexity Score**: 75.0
- **Structure Level**: 0
- **Estimated Phases**: 3
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**: [Mathlib Research](../reports/001-mathlib-research.md)
- **Lean File**: /home/user/ProofChecker/ProofChecker/TaskFrame.lean  # Tier 2 fallback
- **Lean Project**: /home/user/ProofChecker/

## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | lean | lean-implementer |
| 2 | lean | lean-implementer |
| 3 | lean | lean-implementer |

### Phase 1: Task Frame Theorems [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/TaskFrame.lean
dependencies: []

**Objective**: Prove basic task execution properties

**Theorems**:
- [ ] `task_execute_deterministic`: Task execution is deterministic
  - Goal: `∀ (t : Task) (w : World), execute t w = execute t w`
  - Strategy: Use functional determinism, apply `rfl` tactic
  - Complexity: Simple
  - Estimated: 1 hour

---

### Phase 2: World History Theorems [NOT STARTED]
lean_file: /home/user/ProofChecker/ProofChecker/WorldHistory.lean
dependencies: [1]

**Objective**: Prove world state evolution properties

**Theorems**:
- [ ] `world_history_consistent`: World history maintains consistency
  - Goal: `∀ (h : History), consistent h → consistent (h.append event)`
  - Strategy: Induction on history structure, use consistency lemmas
  - Complexity: Medium
  - Estimated: 3 hours

---

### Phase 3: Truth Preservation [NOT STARTED]
lean_file: /home/user/ProofChecker/ProofChecker/Truth.lean
dependencies: [1, 2]

**Objective**: Prove truth preservation across task execution

**Theorems**:
- [ ] `truth_preserved_under_execution`: Execution preserves truth
  - Goal: `∀ (t : Task) (w : World), truth w → truth (execute t w)`
  - Strategy: Apply TaskFrame.task_execute_deterministic, use WorldHistory consistency
  - Complexity: Complex
  - Prerequisites: `task_execute_deterministic`, `world_history_consistent`
  - Estimated: 5 hours
```

**Execution with `/lean-build`**:

```bash
# /lean-build discovers phase-specific files via Tier 1 mechanism
/lean .claude/specs/*/plans/*.md --prove-all

# Phase 1 executes on TaskFrame.lean (Tier 1: lean_file specified)
# Phase 2 executes on WorldHistory.lean (Tier 1: lean_file specified)
# Phase 3 executes on Truth.lean (Tier 1: lean_file specified)

# Wave-based execution enables parallel proving when phases are independent
```

**Key Features**:
- Each phase specifies its target file via `lean_file:` (Tier 1)
- `/lean-build` uses Tier 1 discovery to route theorems to correct files
- lean-coordinator groups theorems by file for efficient batch processing
- Tier 2 global `**Lean File**` provides fallback if phase missing `lean_file:`

---

## Integration with /lean Workflow

The `/lean-plan` command is designed to integrate seamlessly with the `/lean` execution command:

### Planning Phase: `/lean-plan`

**Responsibilities**:
1. Mathlib theorem discovery (via lean-research-specialist)
2. Proof pattern analysis
3. Theorem dependency graph generation
4. Proof strategy formulation
5. Wave structure creation for parallel proving

**Outputs**:
- Research reports in `specs/NNN_topic/reports/`
- Implementation plan in `specs/NNN_topic/plans/`
- Theorem specifications with Goals, Strategies, Complexity

### Execution Phase: `/lean`

**Responsibilities**:
1. Tier 1 discovery: Read **Lean File** metadata from plan
2. Wave-based orchestration: Parse phase dependencies
3. Parallel proving: Execute independent theorems concurrently (40-60% time savings)
4. Progress tracking: Update `[NOT STARTED]` → `[IN PROGRESS]` → `[COMPLETE]`

**Input**: Plan file created by `/lean-plan`

**Execution**:
```bash
# Prove all theorems in plan
/lean path/to/plan.md --prove-all

# Verify only (no new proofs)
/lean path/to/plan.md --verify

# Iterate with retries
/lean path/to/plan.md --max-attempts=3 --max-iterations=5
```

---

## Plan Format Explanation

### Metadata Section

Plans created by `/lean-plan` include standard metadata plus Lean-specific fields.

**Field Order** (following [Plan Metadata Standard](../../reference/standards/plan-metadata-standard.md)):

1. **Required Fields**:
   - **Date**: Plan creation date (YYYY-MM-DD format)
   - **Feature**: One-line formalization description (50-100 chars)
   - **Status**: Current plan status ([NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED])
   - **Estimated Hours**: Time estimate as numeric range (e.g., "8-12 hours")
   - **Standards File**: Absolute path to CLAUDE.md
   - **Research Reports**: Links to Mathlib and proof pattern research reports

2. **Recommended Optional Fields**:
   - **Scope**: Mathematical domain and formalization approach (detailed context)
   - **Complexity Score**: Numeric complexity value from formalization analysis
   - **Structure Level**: Always 0 for Lean plans (single-file structure)
   - **Estimated Phases**: Phase count from initial analysis

3. **Lean-Specific Workflow Extensions**:
   - **Lean File**: Absolute path to target .lean file (Tier 2 discovery fallback)
   - **Lean Project**: Absolute path to Lean project root (lakefile.toml location)

**Example Metadata Block**:

```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Formalize group homomorphism preservation properties
- **Scope**: Formalize group homomorphism preservation in abstract algebra. Prove 8 theorems covering identity preservation, inverse preservation, and composition. Output: ProofChecker/GroupHom.lean module with complete proofs.
- **Status**: [NOT STARTED]
- **Estimated Hours**: 8-12 hours
- **Complexity Score**: 51.0
- **Structure Level**: 0
- **Estimated Phases**: 3
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**:
  - [Mathlib Research](../reports/001-mathlib-research.md)
  - [Proof Patterns](../reports/002-proof-patterns.md)
- **Lean File**: /home/user/ProofChecker/ProofChecker/GroupHom.lean
- **Lean Project**: /home/user/ProofChecker/
```

**Field Details**:

- **Scope Field**: Provides mathematical context for formalization plans
  - Mathematical domain (algebra, analysis, topology, etc.)
  - Specific theorem category being formalized
  - Formalization methodology (blueprint-based, interactive, etc.)
  - Expected deliverables (theorem count, module names)

- **Complexity Score**: Calculated based on formalization characteristics
  - Base: 15 (new), 10 (extend), 7 (refactor)
  - Plus: (Theorems × 3) + (Files × 2) + (Complex Proofs × 5)

- **Lean File** (Tier 2): Global fallback when phase-specific file not specified
- **Lean Project**: Project root for `lake build` and dependency resolution

### Phase Routing Summary

Plans include a Phase Routing Summary table after the "## Implementation Phases" heading to indicate which implementer agent should handle each phase. This enables `/lean-implement` to route phases upfront without parsing the entire plan.

**Format**:

```markdown
## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | lean | lean-implementer |
| 2 | software | implementer-coordinator |
| 3 | lean | lean-implementer |
```

**Phase Types**:
- **lean**: Theorem proving, formalization, or Lean code development
- **software**: Tooling, infrastructure, test setup, or non-Lean tasks

**Routing Logic**:
- Phases with `lean_file:` field and theorem lists → `lean` type
- Phases involving project setup, testing, or documentation → `software` type

### Theorem Phase Structure

Each phase represents one or more theorems with specifications:

```markdown
### Phase 1: Identity Preservation [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/GroupHom.lean
dependencies: []

**Objective**: Prove group homomorphisms preserve identity element

**Complexity**: Low

**Theorems**:
- [ ] `theorem_hom_preserves_zero`: Prove f(0) = 0 for group homomorphisms
  - Goal: `∀ (f : G → H), IsGroupHom f → f 0 = 0`
  - Strategy: Use `GroupHom.map_zero` from Mathlib via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours

**Testing**:
```bash
lake build
grep -c "sorry" ProofChecker/GroupHom.lean
```

**Expected Duration**: 0.5 hours

---
```

**Key Components**:
- **Implementer**: Agent type ("lean" or "software") for phase routing
- **Lean File**: Absolute path to .lean file (Tier 1 discovery, for lean phases)
- **Goal**: Formal Lean 4 type signature (what to prove)
- **Strategy**: Proof approach with specific tactics and Mathlib theorems
- **Complexity**: Simple/Medium/Complex effort estimate
- **Dependencies**: Phase prerequisite tracking for wave execution

**Implementer Field**:
- Appears immediately after phase heading
- Values: `implementer: lean` (theorem proving) or `implementer: software` (tooling/infrastructure)
- Used by `/lean-implement` to route phases to appropriate agent

### Dependency Syntax

Phase dependencies enable wave-based parallel execution:

```markdown
### Phase 1: Basic Properties [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/Groups.lean
dependencies: []

### Phase 2: Derived Properties [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/Groups.lean
dependencies: [1]  # Depends on Phase 1

### Phase 3: Composition [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/Groups.lean
dependencies: [1, 2]  # Depends on both Phases 1 and 2
```

**Wave Execution**:
- **Wave 1**: Phase 1 (no dependencies)
- **Wave 2**: Phase 2 (depends on Wave 1 completion)
- **Wave 3**: Phase 3 (depends on Waves 1 and 2 completion)

Phases within same wave execute in parallel for 40-60% time savings.

---

## Migrating to Per-Phase File Specifications

Existing plans with only Tier 2 (global `**Lean File**`) metadata continue working via fallback mechanism. Migration to Tier 1 (per-phase `lean_file:`) is OPTIONAL and only needed for multi-file formalization workflows.

### When to Migrate

**Migrate to Tier 1 when**:
- Adding theorems in multiple different .lean files
- Evolving from single-file to multi-module structure
- Need precise file targeting per phase
- Want to enable file-based parallelization

**Keep Tier 2 when**:
- All theorems in single .lean file
- Simple project with one primary module
- No need for per-phase file customization

### Migration Steps

**Step 1: Identify Phase File Targets**

For each phase, determine which .lean file contains its theorems:

```bash
# Review existing plan
cat .claude/specs/*/plans/*.md

# Identify distinct files needed
# Phase 1: TaskFrame.lean
# Phase 2: WorldHistory.lean
# Phase 3: Truth.lean
```

**Step 2: Add `lean_file:` to Each Phase**

Add `lean_file:` field immediately after phase heading, before `dependencies:`:

**Before** (Tier 2 only):
```markdown
### Phase 1: Task Frame Theorems [NOT STARTED]
dependencies: []

**Objective**: Prove basic task execution properties
```

**After** (Tier 1 + Tier 2):
```markdown
### Phase 1: Task Frame Theorems [NOT STARTED]
lean_file: /home/user/ProofChecker/ProofChecker/TaskFrame.lean
dependencies: []

**Objective**: Prove basic task execution properties
```

**Step 3: Keep Global Metadata for Fallback**

Retain Tier 2 global `**Lean File**` for backward compatibility:

```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Task execution framework
- **Lean File**: /home/user/ProofChecker/ProofChecker/TaskFrame.lean  # Tier 2 fallback
- **Lean Project**: /home/user/ProofChecker/
```

**Step 4: Validate Tier 1 Discovery**

Test that `/lean-build` correctly discovers phase-specific files:

```bash
# Run plan with /lean-build (dry-run to verify file discovery)
/lean .claude/specs/*/plans/*.md --verify

# Check logs for Tier 1 discovery messages:
# "Phase 1: Using Tier 1 file: /path/to/TaskFrame.lean"
# "Phase 2: Using Tier 1 file: /path/to/WorldHistory.lean"
```

### Migration Example

**Original Plan** (Tier 2 only):

```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Formalize group theory
- **Status**: [NOT STARTED]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**: none
- **Lean File**: /home/user/ProofChecker/ProofChecker/Groups.lean
- **Lean Project**: /home/user/ProofChecker/

### Phase 1: Basic Properties [NOT STARTED]
dependencies: []

### Phase 2: Homomorphisms [NOT STARTED]
dependencies: [1]
```

**Migrated Plan** (Tier 1 + Tier 2):

```markdown
## Metadata
- **Date**: 2025-12-04
- **Feature**: Formalize group theory
- **Status**: [NOT STARTED]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**: none
- **Lean File**: /home/user/ProofChecker/ProofChecker/Groups/Basic.lean  # Tier 2 fallback
- **Lean Project**: /home/user/ProofChecker/

### Phase 1: Basic Properties [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/Groups/Basic.lean
dependencies: []

### Phase 2: Homomorphisms [NOT STARTED]
implementer: lean
lean_file: /home/user/ProofChecker/ProofChecker/Groups/Hom.lean
dependencies: [1]
```

**Result**: Phase 1 uses `Groups/Basic.lean`, Phase 2 uses `Groups/Hom.lean` (Tier 1 discovery). If any phase is missing `lean_file:`, falls back to Tier 2 (`Groups/Basic.lean`).

### Validation After Migration

Verify plan format correctness:

```bash
# Check phase-level lean_file: format (no blank lines after heading)
grep -A 1 "^### Phase" .claude/specs/*/plans/*.md | grep "lean_file:"

# Verify absolute paths (no relative paths)
grep "^lean_file:" .claude/specs/*/plans/*.md | grep -v "^lean_file: /"

# Run standards validation
bash .claude/scripts/validate-all-standards.sh --plans
```

---

## Troubleshooting

### Error: No Lean project found

**Symptom**:
```
ERROR: No Lean project found
No lakefile.toml detected in current directory or parent directories
Use --project flag to specify Lean project path
```

**Cause**: Not in a Lean project directory and no `--project` flag

**Solutions**:
1. Change to project directory: `cd ~/ProofChecker`
2. Use `--project` flag: `/lean-plan "formalize theorems" --project ~/ProofChecker`
3. Create Lean project: `lake init ProofChecker`

### Error: Invalid Lean project structure

**Symptom**:
```
ERROR: Invalid Lean project structure: /path/to/project
No lakefile.toml or lakefile.lean found in project directory
```

**Cause**: Specified path is not a valid Lean project

**Solutions**:
1. Verify path: `ls /path/to/project/lakefile.toml`
2. Initialize project: `cd /path/to/project && lake init`

### Warning: Plan missing **Lean File** metadata

**Symptom**:
```
WARNING: Plan missing **Lean File** metadata (Tier 1 discovery will fail)
```

**Cause**: lean-plan-architect didn't include **Lean File** field in metadata

**Impact**: `/lean` command will fall back to Tier 2 discovery (slower)

**Solutions**:
1. Manually add to plan:
   ```markdown
   - **Lean File**: /absolute/path/to/file.lean
   ```
2. Re-run `/lean-plan` to regenerate plan

### Error: Circular dependencies detected

**Symptom**:
```
ERROR: Circular theorem dependencies detected
Phase 2 depends on Phase 3 which depends on Phase 2
```

**Cause**: Plan has circular phase dependencies

**Impact**: Wave-based execution cannot determine order

**Solutions**:
1. Review dependency structure in plan
2. Break dependency cycle by reordering theorems
3. Manually edit plan to fix `dependencies:` fields

### Warning: Not all theorems have goal specifications

**Symptom**:
```
WARNING: Not all theorems have goal specifications (5/8)
```

**Cause**: Some theorems missing `- Goal:` field

**Impact**: `/lean` cannot generate formal Lean types for proving

**Solutions**:
1. Manually add goal specifications:
   ```markdown
   - [ ] `theorem_name`: Description
     - Goal: `∀ a b : Nat, a + b = b + a`
   ```
2. Re-run `/lean-plan` with higher complexity for better specifications

### Research phase failures

**Symptom**:
```
ERROR: Research phase failed to create report files
```

**Cause**: lean-research-specialist agent encountered errors

**Solutions**:
1. Check error log: `/errors --command /lean-plan --type agent_error --limit 5`
2. Verify Lean project structure
3. Re-run with lower complexity: `/lean-plan "..." --complexity 2`
4. Check network connectivity (WebSearch failures)

### Empty or incomplete research reports

**Symptom**:
```
ERROR: Research report(s) too small (< 100 bytes)
```

**Cause**: Mathlib search failed or agent error

**Solutions**:
1. Check agent output for errors
2. Try higher complexity level for deeper research
3. Manually add Mathlib references to research reports

### Troubleshooting Lean File Discovery

#### Error: Lean file not found (Tier 1)

**Symptom**:
```
ERROR: Phase 2 Lean file not found: /home/user/ProofChecker/ProofChecker/NonExistent.lean
Tier 1 discovery returned invalid path
```

**Cause**: Phase-specific `lean_file:` points to non-existent file

**Solutions**:
1. Verify file path exists:
   ```bash
   ls -la /home/user/ProofChecker/ProofChecker/NonExistent.lean
   ```
2. Fix path in plan (correct typo or use existing file)
3. Create missing file if needed:
   ```bash
   touch /home/user/ProofChecker/ProofChecker/NonExistent.lean
   ```
4. Remove `lean_file:` to fall back to Tier 2 global metadata

#### Error: Tier 1 discovery failed (format issue)

**Symptom**:
```
WARNING: Tier 1 discovery empty for Phase 2
Falling back to Tier 2 global metadata
```

**Cause**: Blank lines between phase heading and `lean_file:`, or incorrect format

**Common Format Errors**:

❌ **WRONG** (blank line after heading):
```markdown
### Phase 1: Basic Properties [NOT STARTED]

lean_file: /path/to/file.lean
dependencies: []
```

✅ **CORRECT** (no blank line):
```markdown
### Phase 1: Basic Properties [NOT STARTED]
lean_file: /path/to/file.lean
dependencies: []
```

❌ **WRONG** (wrong indentation):
```markdown
### Phase 1: Basic Properties [NOT STARTED]
  lean_file: /path/to/file.lean  # Indented
dependencies: []
```

✅ **CORRECT** (no indentation):
```markdown
### Phase 1: Basic Properties [NOT STARTED]
lean_file: /path/to/file.lean
dependencies: []
```

**Solutions**:
1. Remove blank lines between phase heading and `lean_file:`
2. Ensure no indentation before `lean_file:`
3. Verify format: `lean_file: /absolute/path` (space after colon)
4. Check validation:
   ```bash
   grep -A 2 "^### Phase" plan.md | grep "^lean_file:"
   ```

#### Error: Tier 2 fallback failed

**Symptom**:
```
ERROR: No Lean file found for Phase 2
Tier 1 discovery: empty
Tier 2 discovery: empty
Cannot proceed without file specification
```

**Cause**: Both Tier 1 and Tier 2 discovery returned empty (no file metadata)

**Solutions**:
1. Add Tier 2 global metadata:
   ```markdown
   ## Metadata
   - **Lean File**: /absolute/path/to/file.lean
   - **Lean Project**: /absolute/path/to/project/
   ```
2. Add Tier 1 per-phase metadata:
   ```markdown
   ### Phase 2: Properties [NOT STARTED]
   lean_file: /absolute/path/to/file.lean
   dependencies: []
   ```
3. Re-run `/lean-plan` to regenerate plan with proper metadata

#### Warning: Relative path detected

**Symptom**:
```
WARNING: Relative path detected in lean_file: ProofChecker/Basics.lean
Use absolute paths for Tier 1 discovery
```

**Cause**: `lean_file:` uses relative path instead of absolute

**Solutions**:
1. Convert to absolute path:
   ```bash
   # Get absolute path
   readlink -f ProofChecker/Basics.lean
   ```
2. Update plan with absolute path:
   ```markdown
   lean_file: /home/user/ProofChecker/ProofChecker/Basics.lean
   ```

#### Debugging Tier 1/Tier 2 Discovery

To debug which tier is being used:

```bash
# Test Tier 1 discovery for Phase 1
awk -v target="1" '
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
' plan.md

# Test Tier 2 discovery
grep "^- \*\*Lean File\*\*:" plan.md | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//'

# If Tier 1 returns empty, Tier 2 is used as fallback
```

---

## Advanced Usage

### Custom Lean Style Guide Integration

If your project has `LEAN_STYLE_GUIDE.md`, it's automatically extracted and provided to lean-plan-architect:

```bash
# Create style guide in Lean project root
cat > ~/ProofChecker/LEAN_STYLE_GUIDE.md <<EOF
# Lean Style Guide

## Theorem Naming
- Use snake_case: theorem_add_comm
- Include operation: theorem_mul_assoc
- Include property: theorem_distributivity

## Proof Style
- Use exact for direct applications
- Prefer simp over manual rewrites
- Document complex tactics
EOF

# Run /lean-plan (style guide automatically used)
/lean-plan "formalize theorems" --project ~/ProofChecker
```

### Multi-File Formalization

For large formalizations spanning multiple Lean files, plan one file at a time:

```bash
# File 1: Basic properties
/lean-plan "formalize basic group properties in Groups/Basic.lean" --complexity 3

# File 2: Homomorphisms (depends on Basic)
/lean-plan "formalize group homomorphisms in Groups/Hom.lean" --complexity 3

# File 3: Quotients (depends on both)
/lean-plan "formalize quotient groups in Groups/Quotient.lean" --complexity 4
```

Each plan includes **Lean File** metadata pointing to different files.

### Incremental Planning

Start with low complexity, iterate with higher complexity:

```bash
# Quick initial plan (complexity 2)
/lean-plan "formalize ring theorems" --complexity 2

# Review plan
cat .claude/specs/*/plans/*.md

# If more detail needed, revise with higher complexity
/revise .claude/specs/*/plans/*.md "Add more Mathlib references and proof strategies" --complexity 4
```

---

## See Also

- [Lean Command Guide](.claude/docs/guides/commands/lean-command-guide.md) - Executing Lean plans
- [Plan Command Guide](.claude/docs/guides/commands/plan-command-guide.md) - General planning workflow
- [Lean Infrastructure Research](.claude/specs/032_lean_plan_command/reports/001-lean-infrastructure-research.md) - Lean planning research
- [Blueprint Methodology](https://leanprover-community.github.io/blueprint/) - Theorem-level formalization approach
